address 0x111 {
/// KIKO is the token of Starcoin blockchain.
/// It uses apis defined in the `Token` module.
module KIKO {
    use 0x1::Token::{Self, Token};
    use 0x1::Timestamp;
    use 0x1::Math;

    /// KIKO token marker.
    struct KIKO has copy, drop, store { }

    /// precision of KIKO token.
    const PRECISION: u8 = 9;

    /// Burn capability of KIKO.
    struct SharedBurnCapability has key, store {
        cap: Token::BurnCapability<KIKO>,
    }

    struct Config has key, store {
        freed_amount: u128,
        start_time: u64,
        period_delay: u128,
        rate: u64,
        genesis_month_yield: u128
    }

    fun liner_amount(config: &Config): u128 {
        let current = Timestamp::now_seconds();

        let free_amount = 0u128;
        let period = ((current - config.start_time) as u128) / config.period_delay;
        let offset = ((current - config.start_time) as u128) % config.period_delay;
        let i = 0u64;
        while ((i as u128) < period) {
            let n = Math::mul_div(config.genesis_month_yield, Math::pow(config.rate, i), Math::pow(10000, i));
            free_amount = free_amount + n;
            i = i + 1;
        };
        let current_mount = Math::mul_div(config.genesis_month_yield, Math::pow(config.rate, i), Math::pow(10000, i));
        free_amount = free_amount + Math::mul_div(current_mount, offset, config.period_delay);
        return free_amount - config.freed_amount
    }

    public fun withdraw_amount_by_linear(account: &signer, amount: u128): (Token<KIKO>) acquires Config {
        let token_address = Token::token_address<KIKO>();

        let config = borrow_global_mut<Config>(token_address);
        let can_withdraw = liner_amount(config);
        assert(amount < can_withdraw, 121);
        let tokens = Token::mint<KIKO>(account, amount);
        config.freed_amount = config.freed_amount + Token::value<KIKO>(&tokens);
        return tokens
    }

    /// KIKO initialization.
    public fun initialize(
        account: &signer
    ) {
        Token::register_token<KIKO>(account, PRECISION);
        move_to(account, Config{
            freed_amount: 0u128,
            start_time: Timestamp::now_seconds(),
            period_delay: 2592000u128,
            rate: 9800u64,
            genesis_month_yield: 10000000000000000u128
        });
        let burn_cap = Token::remove_burn_capability<KIKO>(account);
        move_to(account, SharedBurnCapability { cap: burn_cap });
    }

    spec initialize {
        include Token::RegisterTokenAbortsIf<KIKO>{precision: PRECISION};
    }

    /// Returns true if `TokenType` is `KIKO::KIKO`
    public fun is_kiko<TokenType: store>(): bool {
        Token::is_same_token<KIKO, TokenType>()
    }

    spec is_kiko {
    }

    /// Burn KIKO tokens.
    /// It can be called by anyone.
    public fun burn(token: Token<KIKO>) acquires SharedBurnCapability {
        let cap = borrow_global<SharedBurnCapability>(token_address());
        Token::burn_with_capability(&cap.cap, token);
    }

    spec burn {
        aborts_if Token::spec_abstract_total_value<KIKO>() - token.value < 0;
        aborts_if !exists<SharedBurnCapability>(Token::SPEC_TOKEN_TEST_ADDRESS());
    }

    /// Return KIKO token address.
    public fun token_address(): address {
        Token::token_address<KIKO>()
    }

    spec token_address {
    }
}
}