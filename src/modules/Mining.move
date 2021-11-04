address 0x222 {
module Mining {
    use 0x100::SwapPair::LPToken;

    const OWNER: address = @0x222;

    struct Config has key, store {
        manager: address,
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

    public fun update_config(sender: &signer, manager: address) {

    }

    public fun trading_init(sender: &signer) {

    }

    // harvest trading profit
    public fun trading_harvest(sender: &signer) {

    }

    // ******************** LPToken stake ********************

    struct Staking<X: store, Y: store> has key, store {
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

    public fun lp_init<X: store, Y: store>(sender: &signer) {

    }

    public fun lp_stake<X: store, Y: store>(sender: &signer, amount: u128) {

    }

    public fun lp_unstake<X: store, Y: store>(sender: &signer, amount: u128) {

    }

    public fun lp_harvest<X: store, Y: store>(sender: &signer) {

    }

}
}
