use array::SpanSerde;

// locals
use super::interface::{ Voucher, DeploymentData, Order };

#[starknet::interface]
trait MarketplaceABI<TContractState> {
  fn fulfill_order(
    ref self: TContractState,
    offerer: starknet::ContractAddress,
    order: Order,
    signature: Span<felt252>
  );

  fn cancel_order(ref self: TContractState, order: Order, signature: Span<felt252>);

  fn fulfill_order_with_voucher(
    ref self: TContractState,
    voucher: Voucher,
    voucher_signature: Span<felt252>,
    order: Order,
    order_signature: Span<felt252>,
    offerer_deployment_data: DeploymentData,
  );
}

#[starknet::contract]
mod Marketplace {
  use array::{ ArrayTrait, SpanTrait };
  use zeroable::Zeroable;
  use integer::U256Zeroable;

  // dispatchers
  use rules_utils::introspection::erc165::{ IERC165Dispatcher, IERC165DispatcherTrait };

  // locals
  use rules_marketplace::marketplace;
  use rules_marketplace::marketplace::interface::{ IMarketplace, IMarketplaceMessages, Order, Voucher, DeploymentData };

  use rules_marketplace::marketplace::messages::MarketplaceMessages;

  use rules_marketplace::access::ownable;
  use rules_marketplace::access::ownable::{ Ownable, IOwnable };
  use rules_marketplace::access::ownable::Ownable::{
    ModifierTrait as OwnableModifierTrait,
    HelperTrait as OwnableHelperTrait,
  };

  use rules_marketplace::marketplace::order::Item;

  // dispatchers
  use rules_marketplace::royalties::erc2981::{ IERC2981_ID, IERC2981Dispatcher, IERC2981DispatcherTrait };
  use rules_marketplace::token::erc20::{ IERC20Dispatcher, IERC20DispatcherTrait };
  use rules_marketplace::token::erc1155::{ IERC1155Dispatcher, IERC1155DispatcherTrait };
  use rules_marketplace::token::lazy_minter::{ ILazyMinterDispatcher, ILazyMinterDispatcherTrait };

  //
  // Storage
  //

  #[storage]
  struct Storage { }

  //
  // Events
  //

  #[event]
  #[derive(Drop, starknet::Event)]
  enum Event {
    FulfillOrder: FulfillOrder,
    CancelOrder: CancelOrder,
  }

  #[derive(Drop, starknet::Event)]
  struct FulfillOrder {
    hash: felt252,
    offerer: starknet::ContractAddress,
    offeree: starknet::ContractAddress,
    offer_item: Item,
    consideration_item: Item,
  }

  #[derive(Drop, starknet::Event)]
  struct CancelOrder {
    hash: felt252,
    offerer: starknet::ContractAddress,
    offer_item: Item,
    consideration_item: Item,
  }

  //
  // Modifiers
  //

  #[generate_trait]
  impl ModifierImpl of ModifierTrait {
    fn _only_owner(self: @ContractState) {
      let ownable_self = Ownable::unsafe_new_contract_state();

      ownable_self.assert_only_owner();
    }
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState, owner_: starknet::ContractAddress) {
    self.initializer(:owner_);
  }

  //
  // Upgrade
  //

  // TODO: use Upgradeable impl with more custom call after upgrade

  #[generate_trait]
  #[external(v0)]
  impl UpgradeImpl of UpgradeTrait {
    fn upgrade(ref self: ContractState, new_implementation: starknet::ClassHash) {
      // Modifiers
      self._only_owner();

      // Body

      // set new impl
      starknet::replace_class_syscall(new_implementation);
    }
  }

  //
  // Marketplace impl
  //

  #[external(v0)]
  impl MarketplaceImpl of marketplace::interface::IMarketplace<ContractState> {
    fn fulfill_order(
      ref self: ContractState,
      offerer: starknet::ContractAddress,
      order: Order,
      signature: Span<felt252>
    ) {
      let mut marketplace_messages_self = MarketplaceMessages::unsafe_new_contract_state();

      let hash = marketplace_messages_self.consume_valid_order_from_deployed(from: offerer, :order, :signature);

      // get potential royalties info
      let (royalties_receiver, royalties_amount) = self._royalty_info(
        offer_item: order.offer_item,
        consideration_item: order.consideration_item
      );

      // transfer offer to caller
      let caller = starknet::get_caller_address();

      self._transfer_item_with_royalties_from(
        from: offerer,
        to: caller,
        item: order.offer_item,
        :royalties_receiver,
        :royalties_amount
      );

      // transfer consideration to offerer
      self._transfer_item_with_royalties_from(
        from: caller,
        to: offerer,
        item: order.consideration_item,
        :royalties_receiver,
        :royalties_amount
      );

      // Events
      self.emit(
        Event::FulfillOrder(
          FulfillOrder {
            hash,
            offerer,
            offeree: caller,
            offer_item: order.offer_item,
            consideration_item: order.consideration_item,
          }
        )
      )
    }

    fn cancel_order(ref self: ContractState, order: Order, signature: Span<felt252>) {
      let mut marketplace_messages_self = MarketplaceMessages::unsafe_new_contract_state();

      let caller = starknet::get_caller_address();

      let hash = marketplace_messages_self.consume_valid_order_from_deployed(from: caller, :order, :signature);

      // Events
      self.emit(
        Event::CancelOrder(
          CancelOrder {
            hash,
            offerer: caller,
            offer_item: order.offer_item,
            consideration_item: order.consideration_item,
          }
        )
      )
    }

    fn fulfill_order_with_voucher(
      ref self: ContractState,
      voucher: Voucher,
      voucher_signature: Span<felt252>,
      order: Order,
      order_signature: Span<felt252>,
      offerer_deployment_data: DeploymentData,
    ) {
      let mut marketplace_messages_self = MarketplaceMessages::unsafe_new_contract_state();

      let mut hash = 0;
      let offerer = voucher.receiver;

      hash = marketplace_messages_self.consume_valid_order_from(
        from: offerer,
        deployment_data: offerer_deployment_data,
        :order,
        signature: order_signature
      );

      // assert voucher and order offer item match
      match order.offer_item {
        Item::Native(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC20(erc_20_item) => {
          assert(voucher.token_id.is_zero(), 'Invalid voucher and order match');
          assert(voucher.amount == erc_20_item.amount, 'Invalid voucher and order match');
        },

        Item::ERC721(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC1155(erc_1155_item) => {
          assert(voucher.token_id == erc_1155_item.identifier, 'Invalid voucher and order match');
          assert(voucher.amount == erc_1155_item.amount, 'Invalid voucher and order match');
        }
      }

      // get potential royalties info
      let (royalties_receiver, royalties_amount) = self._royalty_info(
        offer_item: order.offer_item,
        consideration_item: order.consideration_item
      );

      // mint offer to caller
      let caller = starknet::get_caller_address();

      self._transfer_item_with_voucher(to: caller, item: order.offer_item, :voucher, :voucher_signature);

      // transfer consideration to offerer
      self._transfer_item_with_royalties_from(
        from: caller,
        to: offerer,
        item: order.consideration_item,
        :royalties_receiver,
        :royalties_amount
      );

      // Events
      self.emit(
        Event::FulfillOrder(
          FulfillOrder {
            hash,
            offerer,
            offeree: caller,
            offer_item: order.offer_item,
            consideration_item: order.consideration_item,
          }
        )
      )
    }
  }

  //
  // Ownable impl
  //

  #[external(v0)]
  impl IOwnableImpl of ownable::IOwnable<ContractState> {
    fn owner(self: @ContractState) -> starknet::ContractAddress {
      let ownable_self = Ownable::unsafe_new_contract_state();

      ownable_self.owner()
    }

    fn transfer_ownership(ref self: ContractState, new_owner: starknet::ContractAddress) {
      let mut ownable_self = Ownable::unsafe_new_contract_state();

      ownable_self.transfer_ownership(:new_owner);
    }

    fn renounce_ownership(ref self: ContractState) {
      let mut ownable_self = Ownable::unsafe_new_contract_state();

      ownable_self.renounce_ownership();
    }
  }

  //
  // Internals
  //

  #[generate_trait]
  impl HelperImpl of HelperTrait {

    // Init

    fn initializer(ref self: ContractState, owner_: starknet::ContractAddress) {
      let mut ownable_self = Ownable::unsafe_new_contract_state();

      ownable_self._transfer_ownership(new_owner: owner_);
    }

    // Royalties

    fn _royalty_info(self: @ContractState, offer_item: Item, consideration_item: Item) -> (starknet::ContractAddress, u256) {
      match offer_item {
        Item::Native(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC20(erc_20_item) => {
          return self._item_royalty_info(item: consideration_item, sale_price: erc_20_item.amount);
        },

        Item::ERC721(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC1155(erc_1155_item) => {},
      }

      match consideration_item {
        Item::Native(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC20(erc_20_item) => {
          return self._item_royalty_info(item: offer_item, sale_price: erc_20_item.amount);
        },

        Item::ERC721(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC1155(erc_1155_item) => {},
      }

      self.ZERO_ROYALTIES()
    }

    fn _item_royalty_info(self: @ContractState, item: Item, sale_price: u256) -> (starknet::ContractAddress, u256) {
      match item {
        Item::Native(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC20(erc_20_item) => {},

        Item::ERC721(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC1155(erc_1155_item) => {
          let ERC165 = IERC165Dispatcher { contract_address: erc_1155_item.token };

          // check if token support ERC2981 royalties standard
          if (ERC165.supports_interface(IERC2981_ID)) {
            let ERC2981 = IERC2981Dispatcher { contract_address: erc_1155_item.token };

            // return royalty infos from token
            return ERC2981.royalty_info(token_id: erc_1155_item.identifier, :sale_price);
          }
        },
      }

      self.ZERO_ROYALTIES()
    }

    fn ZERO_ROYALTIES(self: @ContractState) -> (starknet::ContractAddress, u256) {
      (starknet::contract_address_const::<0>(), 0)
    }

    // Order

    fn _transfer_item_with_royalties_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      item: Item,
      royalties_receiver: starknet::ContractAddress,
      royalties_amount: u256
    ) {
      // TODO: add case fallback support

      match item {
        Item::Native(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC20(erc_20_item) => {
          let ERC20 = IERC20Dispatcher { contract_address: erc_20_item.token };

          ERC20.transferFrom(sender: from, recipient: to, amount: erc_20_item.amount - royalties_amount);

          // transfer royalties
          if (royalties_amount.is_non_zero()) {
            ERC20.transferFrom(sender: from, recipient: royalties_receiver, amount: royalties_amount);
          }
        },

        Item::ERC721(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC1155(erc_1155_item) => {
          let ERC1155 = IERC1155Dispatcher { contract_address: erc_1155_item.token };

          ERC1155.safe_transfer_from(
            :from,
            :to,
            id: erc_1155_item.identifier,
            amount: erc_1155_item.amount,
            data: ArrayTrait::<felt252>::new().span()
          );
        },
      }
    }

    fn _transfer_item_with_voucher(
      ref self: ContractState,
      to: starknet::ContractAddress,
      item: Item,
      voucher: Voucher,
      voucher_signature: Span<felt252>
    ) {
      // TODO: add case fallback support

      let mut token: starknet::ContractAddress = starknet::contract_address_const::<0>();

      match item {
        Item::Native(()) => { panic_with_felt252('Unsupported item type'); },

        // Does not support ERC20 redeem, otherwise we should implement a way to retrieve royalties
        Item::ERC20(erc_20_item) => { panic_with_felt252('Cannot redeem ERC20 voucher'); },

        Item::ERC721(()) => { panic_with_felt252('Unsupported item type'); },

        Item::ERC1155(erc_1155_item) => {
          token = erc_1155_item.token
        },
      }

      let LazyMinter = ILazyMinterDispatcher { contract_address: token };
      LazyMinter.redeem_voucher_to(:to, :voucher, signature: voucher_signature);
    }
  }
}
