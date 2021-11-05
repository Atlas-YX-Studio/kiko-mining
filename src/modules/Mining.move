address 0x222 {
module Mining {
    use 0x1::STC::STC;
    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Event;
    use 0x1::Signer;
    use 0x1::BCS;
    use 0x1::Compare;
    use 0x100::SwapPair::{Self, LPToken};
    use 0x111::KIKO::{Self, KIKO};

    const PERMISSION_DENIED: u64 = 100001;

    const OWNER: address = @0x222;

    struct Config has key, store {
        // manager, can harvest reward
        manager: address,
        // stc gas fee
        stc_gas: u128,
    }

    struct Trading has key, store {
        // event
        trading_harvest_event: Event::EventHandle<TradingHarvestEvent>,
    }

    // event emitted when harvest trading profit
    struct TradingHarvestEvent has drop, store {
        sender: address,
        // to user
        to: address,
        // amount
        amount: u128,
    }


    // init config and trading
    public fun init(sender: &signer, manager: address, stc_gas: u128) {
        assert(Signer::address_of(sender) == OWNER, PERMISSION_DENIED);
        if (!exists<Config>(OWNER)) {
            move_to<Config>(sender,
                Config {
                    manager: manager,
                    stc_gas: stc_gas,
            });
        };
        if (!exists<Trading>(OWNER)) {
            move_to<Trading>(sender,
                Trading {
                    trading_harvest_event: Event::new_event_handle<TradingHarvestEvent>(sender),
            });
        };
    }

    public fun update_config(sender: &signer, manager: address, stc_gas: u128) acquires Config {
        assert(Signer::address_of(sender) == OWNER, PERMISSION_DENIED);
        if (!exists<Config>(OWNER)) {
            move_to<Config>(sender, Config{
                manager: manager,
                stc_gas: stc_gas,
            });
        } else {
            let config = borrow_global_mut<Config>(OWNER);
            config.manager = manager;
            config.stc_gas = stc_gas;
        }
    }

    // harvest trading profit
    public fun trading_harvest(sender: &signer, to: address, amount: u128) acquires Config {
        assert_manager(sender);
        let tokens = KIKO::withdraw_amount_by_linear(sender, amount);
        // take gas
        let config = borrow_global_mut<Config>(OWNER);
        let kiko_gas = get_kiko_gas(config.stc_gas);
        if (kiko_gas >= Token::value(&tokens)) {
            Account::deposit(OWNER, tokens);
            return
        } else {
            let gas_tokens = Token::withdraw(&mut tokens, kiko_gas);
            Account::deposit(OWNER, gas_tokens);
        };
        // deposit to user
        Account::deposit(to, tokens);
    }

    fun assert_manager(sender: &signer) acquires Config {
        assert(Signer::address_of(sender) == OWNER, PERMISSION_DENIED);
        let config = borrow_global_mut<Config>(OWNER);
        assert(Signer::address_of(sender) == config.manager, PERMISSION_DENIED);
    }

    fun get_kiko_gas(stc_amount: u128) : u128 {
        if (get_token_order<STC, KIKO>() == 1) {
            let (reserve0, reserve1) = SwapPair::get_reserves<STC, KIKO>();
            stc_amount * reserve1 / reserve0
        } else {
            let (reserve1, reserve0) = SwapPair::get_reserves<KIKO, STC>();
            stc_amount * reserve1 / reserve0
        }
    }

    fun get_token_order<X: store, Y: store>(): u8 {
        let x_bytes = BCS::to_bytes<Token::TokenCode>(&Token::token_code<X>());
        let y_bytes = BCS::to_bytes<Token::TokenCode>(&Token::token_code<Y>());
        Compare::cmp_bcs_bytes(&x_bytes, &y_bytes)
    }

    // ******************** LPToken stake ********************

    struct StakePool<X: store, Y: store> has key, store {
        // lp tokens
        lp_tokens: Token::Token<LPToken<X, Y>>,
        // event
        lp_stake_event: Event::EventHandle<LPStakeEvent>,
        lp_unstake_event: Event::EventHandle<LPUnstakeEvent>,
        lp_harvest_event: Event::EventHandle<LPHarvestEvent>,
    }

    // event emitted when stake lp token
    struct LPStakeEvent has drop, store {
        sender: address,
        // token code of X type
        x_token_code: Token::TokenCode,
        // token code of X type
        y_token_code: Token::TokenCode,
        // staking amount
        amount: u128,
    }

    // event emitted when unstake lp token
    struct LPUnstakeEvent has drop, store {
        sender: address,
        // token code of X type
        x_token_code: Token::TokenCode,
        // token code of X type
        y_token_code: Token::TokenCode,
        // staking amount
        amount: u128,
    }

    // event emitted when harvest lp stake profit
    struct LPHarvestEvent has drop, store {
        sender: address,
        // to user
        to: address,
        // token code of X type
        x_token_code: Token::TokenCode,
        // token code of X type
        y_token_code: Token::TokenCode,
        // amount
        amount: u128,
    }

    public fun lp_init<X: store, Y: store>(_sender: &signer) {

    }

    public fun lp_stake<X: store, Y: store>(_sender: &signer, _amount: u128) {

    }

    public fun lp_unstake<X: store, Y: store>(_sender: &signer, _amount: u128) {

    }

    public fun lp_harvest<X: store, Y: store>(_sender: &signer) {

    }

}
}
