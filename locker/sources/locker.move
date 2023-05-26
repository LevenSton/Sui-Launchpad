module locker::locker {

    use sui::balance::{Self, Balance};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin, value, split, destroy_zero};
    use sui::url::{Self, Url};
    use sui::object_table::{Self, ObjectTable};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, from_ascii, String};
    use sui::clock::{Self, Clock};
    use std::type_name::{get, into_string};
    use sui::transfer;
    use sui::event;
    use sui::package;
    use sui::pay;
    use std::vector;

    struct LOCKER has drop {}
    /// Represents a lock of coins until some specified unlock time. Afterward, the recipient can claim the coins.
    struct Lock<phantom CoinType> has key, store {
        id: UID,
        name: String,
        logo_url: Url,
        owner: address,
        token_address: String,
        decimals: u64,
        amount: u64,
        balance: Balance<CoinType>,
        unlock_time: u64,
        is_claim: bool
    }

    struct LockItem has key, store {
        id: UID,
        lock_id: ID
    }

    struct Locks has key, store {
        id: UID,
        lock_tab: ObjectTable<ID, LockItem>
    }

    // ======= Events =======
    struct CreateLockerEvent has copy, drop {
        creator: address,
        amount: u64,
        create_time: u64,
        coin_type_info: String,
    }
    /// Event emitted when a recipient claims unlocked coins.
    struct ClaimEvent has copy, drop {
        recipient: address,
        amount: u64,
        claimed_time: u64,
    }

    // Error codes
    /// No locked coins found to claim.
    const ELOCK_NOT_FOUND: u64 = 1;
    /// Lockup has not expired yet.
    const ELOCKUP_HAS_NOT_EXPIRED: u64 = 2;
    /// Can only create one active lock per recipient at once.
    const ELOCK_ALREADY_CLAIM: u64 = 3;
    /// The length of the recipients list doesn't match the amounts.
    const EINVALID_RECIPIENTS_LIST_LENGTH: u64 = 3;
    const EINVALID_TIME: u64 = 4;
    const EINSUFFICIENT_BALANCE: u64 = 5;

    // ======= Publishing =======
    fun init(otw: LOCKER, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx);
        transfer::share_object(Locks {
            id: object::new(ctx),
            lock_tab: object_table::new<ID, LockItem>(ctx)
        })
    }

    public entry fun create_locked_coins<CoinType>(
        locks: &mut Locks, 
        clock: &Clock,
        name: vector<u8>,
        logo_url: vector<u8>,
        token_address: vector<u8>,
        decimals: u64,
        unlock_time: u64, 
        coins: vector<Coin<CoinType>>,
        value: u64,
        ctx: &mut TxContext
    ) {
        assert!(unlock_time > clock::timestamp_ms(clock), EINVALID_TIME);
        let merged_coins_in = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coins_in, coins);
        assert!(value(&merged_coins_in) >= value, EINSUFFICIENT_BALANCE);
        
        let coin_in = split(&mut merged_coins_in, value, ctx);
        
        let user_addr = tx_context::sender(ctx);
        let user_info_id = object::new(ctx);
        let id_copy = object::uid_to_inner(&user_info_id);

        let lock = Lock<CoinType> {
            id: user_info_id,
            name: string::utf8(name),
            logo_url: url::new_unsafe_from_bytes(logo_url),
            owner: user_addr,
            token_address: string::utf8(token_address),
            decimals: decimals,
            amount: value,
            balance: coin::into_balance(coin_in),
            unlock_time: unlock_time,
            is_claim: false,
        };
        transfer::transfer(lock, user_addr);
        object_table::add(&mut locks.lock_tab, id_copy, LockItem{
            id: object::new(ctx),
            lock_id: id_copy
        });
        if (value(&merged_coins_in) > 0) {
            transfer::public_transfer(
                merged_coins_in,
                tx_context::sender(ctx)
            )
        } else {
            destroy_zero(merged_coins_in)
        };
        event::emit(
            CreateLockerEvent {
                creator: user_addr,
                amount: value,
                create_time: clock::timestamp_ms(clock),
                coin_type_info: from_ascii(into_string(get<CoinType>())),
            }
        );
    }

    public entry fun add_coins_toLocker<CoinType>(
        lock: &mut Lock<CoinType>,
        coins: vector<Coin<CoinType>>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let merged_coins_in = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coins_in, coins);
        assert!(value(&merged_coins_in) >= amount, EINSUFFICIENT_BALANCE);
        
        let locked_coin = coin::split(&mut merged_coins_in, amount, ctx);
        let locked_balance = coin::into_balance(locked_coin);
        
        // Update lock information
        balance::join(&mut lock.balance, locked_balance);
        lock.amount = lock.amount + amount;
        if (value(&merged_coins_in) > 0) {
            transfer::public_transfer(
                merged_coins_in,
                tx_context::sender(ctx)
            )
        } else {
            destroy_zero(merged_coins_in)
        }
    }

    public entry fun claim<CoinType>(
        lock_info: &mut Lock<CoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!lock_info.is_claim, ELOCK_ALREADY_CLAIM);
        assert!(clock::timestamp_ms(clock) >= lock_info.unlock_time, ELOCKUP_HAS_NOT_EXPIRED);

        let locked_balance = balance::value<CoinType>(&lock_info.balance);
        let claim = coin::take<CoinType>(&mut lock_info.balance, locked_balance, ctx);
        transfer::public_transfer(claim, lock_info.owner);
        lock_info.is_claim = true;

        event::emit(
            ClaimEvent {
                recipient: lock_info.owner,
                amount: locked_balance,
                claimed_time: clock::timestamp_ms(clock),
            }
        );
    }

    public entry fun update_name<CoinType>(
        lock_info: &mut Lock<CoinType>,
        name: String,
        _ctx: &mut TxContext
    ) {
       lock_info.name = name;
    }

    public entry fun update_time<CoinType>(
        lock_info: &mut Lock<CoinType>,
        unlock_time: u64,
        _ctx: &mut TxContext
    ) {
        assert!(unlock_time > lock_info.unlock_time, EINVALID_TIME);
        lock_info.unlock_time = unlock_time;
    }
}
