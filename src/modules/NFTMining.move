address 0x222 {
module NFTMining {

    use 0x1::Token;
    use 0x1::Account;
    use 0x1::Event;
    use 0x1::Signer;
    use 0x1::Vector;
    use 0x1::Option::{Self, Option};
    use 0x1::NFT::NFT;
    use 0x1::NFTGallery;
    use 0x111::KIKO;

    const PERMISSION_DENIED: u64 = 100001;
    const NFT_NOT_SURPPORT: u64 = 100002;
    const NFT_NOT_EXISTS: u64 = 100003;
    const STAKE_GALLERY_NOT_EXISTS: u64 = 100004;
    const ORDER_TOO_HIGH: u64 = 100005;
    const ORDER_ALREADY_EXISTS: u64 = 100006;

    const OWNER: address = @0x222;

    // ******************** NFT harvest ********************

    struct NFTConfig has key, store {
        // max size
        max_size: u64,
        // event
        harvest_event: Event::EventHandle<NFTHarvestEvent>,
    }

    // event emitted when harvest trading profit
    struct NFTHarvestEvent has drop, store {
        sender: address,
        // to user
        to: address,
        // amount
        amount: u128,
        // fee
        fee: u128,
    }

    // init nft config
    public fun init_config(sender: &signer, max_size: u64) {
        assert_manager(sender);
        if (!exists<NFTConfig>(OWNER)) {
            move_to<NFTConfig>(sender,
                NFTConfig {
                    max_size: max_size,
                    harvest_event: Event::new_event_handle<NFTHarvestEvent>(sender),
                });
        };
    }

    // harvest trading profit
    public fun nft_mining_harvest(sender: &signer, to: address, amount: u128, fee: u128) acquires NFTConfig {
        assert_manager(sender);
        harvest(sender, to, amount, fee);
        let config = borrow_global_mut<NFTConfig>(OWNER);
        Event::emit_event(
            &mut config.harvest_event,
            NFTHarvestEvent {
                sender: Signer::address_of(sender),
                to: to,
                amount: amount,
                fee: fee,
            }
        );
    }

    fun harvest(sender: &signer, to: address, amount: u128, fee: u128) {
        let tokens = KIKO::withdraw_amount_by_linear(sender, amount);
        // take gas
        if (fee >= amount) {
            Account::deposit(OWNER, tokens);
            return
        } else if (fee > 0) {
            let fee_tokens = Token::withdraw(&mut tokens, fee);
            Account::deposit(OWNER, fee_tokens);
        };
        // deposit to user
        Account::deposit(to, tokens);
    }

    fun assert_manager(sender: &signer) {
        assert(Signer::address_of(sender) == OWNER, PERMISSION_DENIED);
    }

    // ******************** NFT stake ********************

    // store in owner
    struct NFTStakeEvents<NFTMeta: store + drop, NFTBody: store + drop> has key, store {
        stake_events: Event::EventHandle<NFTStakeEvent<NFTMeta, NFTBody>>,
        unstake_events: Event::EventHandle<NFTUnstakeEvent<NFTMeta, NFTBody>>,
    }

    // store in user
    struct NFTStakeOrder has key, store {
        orders: vector<u64>,
    }

    // store in user
    struct NFTStakeGallery<NFTMeta: store + drop, NFTBody: store + drop> has key, store {
        items: vector<NFTStakeInfo<NFTMeta, NFTBody>>,
    }

    // nft stake info
    struct NFTStakeInfo<NFTMeta: store, NFTBody: store> has store {
        // nft item
        nft: Option<NFT<NFTMeta, NFTBody>>,
        // nft id
        nft_id: u64,
        // order id
        order: u64,
    }

    // NFT stake event
    struct NFTStakeEvent<NFTMeta: store + drop, NFTBody: store + drop> has drop, store {
        sender: address,
        nft_id: u64,
        order: u64,
    }

    // NFT unstake event
    struct NFTUnstakeEvent<NFTMeta: store + drop, NFTBody: store + drop> has drop, store {
        sender: address,
        nft_id: u64,
        order: u64,
    }

    // init nft stake events
    public fun nft_init<NFTMeta: store + drop, NFTBody: store + drop>(sender: &signer) {
        assert_manager(sender);
        if (!exists<NFTStakeEvents<NFTMeta, NFTBody>>(OWNER)) {
            move_to<NFTStakeEvents<NFTMeta, NFTBody>>(sender,
                NFTStakeEvents<NFTMeta, NFTBody> {
                    stake_events: Event::new_event_handle<NFTStakeEvent<NFTMeta, NFTBody>>(sender),
                    unstake_events: Event::new_event_handle<NFTUnstakeEvent<NFTMeta, NFTBody>>(sender),
                });
        };
    }

    // stake nft
    public fun nft_stake<NFTMeta: copy + store + drop, NFTBody: copy + store + drop>(sender: &signer, nft_id: u64, order: u64)
    acquires NFTConfig, NFTStakeOrder, NFTStakeGallery, NFTStakeEvents {
        assert(exists<NFTStakeEvents<NFTMeta, NFTBody>>(OWNER), NFT_NOT_SURPPORT);
        // get nft from gallery
        let nft_option = NFTGallery::withdraw<NFTMeta, NFTBody>(sender, nft_id);
        assert(Option::is_none(&mut nft_option), NFT_NOT_EXISTS);
        // check size
        let config = borrow_global<NFTConfig>(OWNER);
        assert(order <= config.max_size, ORDER_TOO_HIGH);
        let sender_address = Signer::address_of(sender);
        // check order
        if (!exists<NFTStakeOrder>(sender_address)) {
            move_to<NFTStakeOrder>(sender,
                NFTStakeOrder {
                    orders: Vector::empty(),
                });
            let stake_order = borrow_global_mut<NFTStakeOrder>(sender_address);
            Vector::push_back(&mut stake_order.orders, order);
        } else {
            let stake_order = borrow_global_mut<NFTStakeOrder>(sender_address);
            let len = Vector::length(&mut stake_order.orders);
            // order cannot exists
            if (len > 0) {
                let i = 0;
                while(i < len) {
                    let tmp_order = Vector::borrow(&mut stake_order.orders, i);
                    assert(*tmp_order != order, ORDER_ALREADY_EXISTS);
                    i = i + 1;
                };
            };
            Vector::push_back(&mut stake_order.orders, order);
        };
        // deposit
        if (!exists<NFTStakeGallery<NFTMeta, NFTBody>>(sender_address)) {
            move_to<NFTStakeGallery<NFTMeta, NFTBody>>(sender,
                NFTStakeGallery<NFTMeta, NFTBody> {
                    items: Vector::empty(),
                });
        };
        let stake_gallery = borrow_global_mut<NFTStakeGallery<NFTMeta, NFTBody>>(sender_address);
        let stake_info = NFTStakeInfo<NFTMeta, NFTBody> {
            nft: nft_option,
            nft_id: nft_id,
            order: order,
        };
        Vector::push_back(&mut stake_gallery.items, stake_info);
        // emit event
        let stake_events = borrow_global_mut<NFTStakeEvents<NFTMeta, NFTBody>>(OWNER);
        Event::emit_event(
            &mut stake_events.stake_events,
            NFTStakeEvent {
                sender: sender_address,
                nft_id: nft_id,
                order: order,
            }
        );
    }

    // unstake nft
    public fun nft_unstake<NFTMeta: copy + store + drop, NFTBody: copy + store + drop>(sender: &signer, order: u64)
    acquires NFTStakeOrder, NFTStakeGallery, NFTStakeEvents {
        let sender_address = Signer::address_of(sender);
        // withdraw nft
        assert(exists<NFTStakeGallery<NFTMeta, NFTBody>>(sender_address), STAKE_GALLERY_NOT_EXISTS);
        let stake_gallery = borrow_global_mut<NFTStakeGallery<NFTMeta, NFTBody>>(sender_address);
        let len = Vector::length(&mut stake_gallery.items);
        let nft_id = 0;
        if (len > 0) {
            let i = 0;
            while(i < len) {
                let staking_info = Vector::borrow_mut(&mut stake_gallery.items, i);
                if (staking_info.order == order) {
                    nft_id = staking_info.nft_id;
                    let nft = Option::extract(&mut staking_info.nft);
                    NFTGallery::deposit(sender, nft);
                    let NFTStakeInfo<NFTMeta, NFTBody> {
                        nft,
                        nft_id: _,
                        order: _,
                    } = Vector::remove<NFTStakeInfo<NFTMeta, NFTBody>>(&mut stake_gallery.items, i);
                    Option::destroy_none(nft);
                    break
                };
                assert(i > 0, NFT_NOT_EXISTS);
                i = i + 1;
            };
        };
        // remove order
        let stake_order = borrow_global_mut<NFTStakeOrder>(sender_address);
        let len = Vector::length(&mut stake_order.orders);
        if (len > 0) {
            let i = 0;
            while(i < len) {
                let tmp_order = Vector::borrow(&mut stake_order.orders, i);
                if (*tmp_order == order) {
                    Vector::remove(&mut stake_order.orders, i);
                    break
                };
                i = i + 1;
            };
        };
        // emit event
        let stake_events = borrow_global_mut<NFTStakeEvents<NFTMeta, NFTBody>>(OWNER);
        Event::emit_event(
            &mut stake_events.unstake_events,
            NFTUnstakeEvent {
                sender: sender_address,
                nft_id: nft_id,
                order: order,
            }
        );
    }

    // change nft
    public fun nft_change<NFTMetaIn: copy + store + drop, NFTBodyIn: copy + store + drop,
                          NFTMetaOut: copy + store + drop, NFTBodyOut: copy + store + drop>
    (sender: &signer, nft_in_id: u64, order: u64)
    acquires NFTConfig, NFTStakeOrder, NFTStakeGallery, NFTStakeEvents {
        // unstake
        nft_unstake<NFTMetaOut, NFTBodyOut>(sender, order);
        // stake nft
        nft_stake<NFTMetaIn, NFTBodyIn>(sender, nft_in_id, order);
    }

}
}
