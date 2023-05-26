module suilang::sale {
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin, CoinMetadata, value, split, destroy_zero};
    use sui::url::{Self, Url};
    use sui::object_table::{Self, ObjectTable};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::package::{Self, Publisher};
    use sui::transfer;
    use sui::sui::SUI;
    use sui::dynamic_object_field;
    use sui::event;
    use sui::pay;
    use std::vector;

    const ENotOwner: u64 = 0;

    struct SALE has drop {}

    struct GlobalConfig has key, store {
        id: UID,
        treasury_admin_address: address,
        fee_create_sale: u64,
        commission_fee: u64
    }

    struct UserPayment has key, store {
        id: UID,
        user: address,
        purchased_amount: u64,
        is_claim: bool
    }

    struct LaunchPool<phantom SaleCoinType, phantom PurchaseCoinType> has key, store {
        id: UID,
        fundraiser: address,
        decimals: u64,
        total_supply: u64,
        sale_amount: u64,
        sale_minum_amount: u64,
        sale_max_amount: u64,
        sale_rate: u64,
        start_time: u64,
        end_time: u64,
        soft_cap: u64,
        hard_cap: u64,
        lock_duration: u64,
        liquidity_lock_time: u64,
        raised_amount: u64,
        liquidity_percent: u64,
        listing_rate: u64,
        router: u64,
        to_sell: Balance<SaleCoinType>,
        to_liquidity: Balance<SaleCoinType>,
        raised: Balance<PurchaseCoinType>,
        buyers: ObjectTable<address, UserPayment>,
        is_successful: bool
    }

    struct PoolId has key, store {
        id: UID,
        item_id: ID
    }
    
    struct ListedLaunchPools has key, store {
        id: UID,
        pool_tables: ObjectTable<ID, PoolId>
    }

    struct BuyEvent has copy, drop {
        user: address,
        purchased: u64
    }
    struct ClaimEvent has copy, drop {
        user: address,
        claimCoin: u64
    }
    struct InitializePoolEvent has copy, drop {
        fundraiser: address,
        sale_amount: u64
    }
    struct DepositToSellEvent has copy, drop {
        fundraiser: address,
        dep_sale_amount: u64
    }
    struct WithdrawRaiseFundsEvent has copy, drop {
        fundraiser: address,
        raised_amount: u64,
        sale_amount: u64,
        sale_refunds_amount: u64,
        completed_percent: u64
    }

    const ESOFETCAP_NOTMATCH_HARDCAP: u64 = 0;
    const ESTARTTIME_NEEDLARGE_CURRENT: u64 = 1;
    const ELIQUIDITY_LOCKTIME_TOOSMALL: u64 = 2;
    const ELIQUIDITY_PERCENTAGE_TOOLOWER: u64 = 3;
    const EROUTER_NOT_EXIST: u64 = 4;
    const EINSUFFICIENT_BALANCE: u64 = 5;

    fun init(otw: SALE, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx);
        transfer::share_object(ListedLaunchPools {
            id: object::new(ctx),
            pool_tables: object_table::new<ID, PoolId>(ctx)
        })
    }

    public entry fun create_sale<SaleCoinType, PurchaseCoinType>(
        pools: &mut ListedLaunchPools, clock: &Clock, coinMetaData: &CoinMetadata<SaleCoinType>,
        sale_rate: u64, soft_cap: u64, hard_cap: u64,
        sale_minum_amount: u64, sale_max_amount: u64,
        start_time: u64, end_time: u64,
        lock_duration: u64, liquidity_lock_time: u64,
        liquidity_percent: u64, listing_rate: u64,
        router: u64, //coin: vector<Coin<SUI>>, 
        ctx: &mut TxContext
    ) {
        // assert!(soft_cap * 2 >= hard_cap, ESOFETCAP_NOTMATCH_HARDCAP);
        // assert!(start_time > clock::timestamp_ms(clock), ESTARTTIME_NEEDLARGE_CURRENT);
        // let sale = sale_rate;
    }

    public fun set_global_config<T>(
        pools: &mut ListedLaunchPools, 
        publisher: &Publisher, 
        ctx: &mut TxContext
    ) {
        // assert!(package::from_package<T>(publisher), ENotOwner);
        // let global_config = GlobalConfig{
        //     id: object::new(ctx),
        //     treasury_admin_address: tx_context::sender(ctx),
        //     fee_create_sale: 750000000000,
        //     commission_fee: 5
        // };
    }
}