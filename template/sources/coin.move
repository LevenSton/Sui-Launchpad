module template::tmp {
    use std::vector;
    use std::ascii;
    use std::option;
    use sui::coin::{Self, TreasuryCap, Coin, value, split, destroy_zero};
    use sui::transfer;
    use sui::url::{Self};
    use sui::tx_context::{Self, TxContext};
    use sui::pay;
    //use std::string::{Self};

    const SYMBOL: vector<u8> = b"TMP";
    const NAME: vector<u8> = b"Template Token";
    const TOTAL_SUPPLY: u64 = 100_000_000_000_000_000; // 100_000_000 * 10^9
    const DESCRIPTION: vector<u8> = b"TMP tmp coin!";
    const DECIMAL: u8 = 9;
    const ICON_URL: vector<u8> = b"https://www.suiland.com/tmp.png";

    /// Name of the coin. By convention, this type has the same name as its parent module
    /// and has no fields. The full type of the coin defined by this module will be `COIN<TMP>`.
    struct TMP has drop {}

    // Register the managed currency to acquire its `TreasuryCap`. Because
    // this is a module initializer, it ensures the currency only gets
    // registered once.
    fun init(witness: TMP, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<TMP>(
            witness, 
            DECIMAL, 
            SYMBOL, 
            NAME, 
            DESCRIPTION, 
            option::some(url::new_unsafe(ascii::string(ICON_URL))), 
            ctx
        );
        transfer::public_freeze_object(metadata);
        coin::mint_and_transfer(&mut treasury_cap, TOTAL_SUPPLY, tx_context::sender(ctx), ctx);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx))
        
        //coin::mint_and_transfer(&mut treasury, TOTAL_SUPPLY, tx_context::sender(ctx), ctx);
        //transfer::public_freeze_object(treasury);
        //transfer::public_freeze_object(metadata);
        //transfer::public_transfer(treasury, tx_context::sender(ctx));
        //transfer::share_object(metadata)
    }

    /// Manager can mint new coins
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<TMP>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    /// Manager can burn coins
    public entry fun burn(treasury_cap: &mut TreasuryCap<TMP>, coin: vector<Coin<TMP>>, value: u64, ctx: &mut TxContext) {
        // 1. merge coins
        let merged_coins_in = vector::pop_back(&mut coin);
        pay::join_vec(&mut merged_coins_in, coin);
        let coin_in = split(&mut merged_coins_in, value, ctx);

        // 2. burn coin
        coin::burn(treasury_cap, coin_in);

        // 3. handle remain coin
        if (value(&merged_coins_in) > 0) {
            transfer::public_transfer(
                merged_coins_in,
                tx_context::sender(ctx)
            )
        } else {
            destroy_zero(merged_coins_in)
        }
    }

    /// Manager can renounce ownership
    public entry fun renounce_ownership(
        treasury_cap: TreasuryCap<TMP>, _ctx: &mut TxContext
    ) {
        transfer::public_freeze_object(treasury_cap);
    }
}