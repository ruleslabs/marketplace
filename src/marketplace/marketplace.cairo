use array::SpanTrait;
use zeroable::Zeroable;
use rules_erc1155::utils::serde::SpanSerde;

// locals
use super::order::Order;
use super::interface::Voucher;

#[abi]
trait MarketplaceABI {
  #[external]
  fn fulfill_order(offerer: starknet::ContractAddress, order: Order, signature: Span<felt252>);

  #[external]
  fn cancel_order(order: Order, signature: Span<felt252>);

  #[external]
  fn redeem_voucher_and_fulfill_order(
    voucher: Voucher,
    voucher_signature: Span<felt252>,
    order: Order,
    order_signature: Span<felt252>
  );
}

#[contract]
mod Marketplace {
  use array::{ ArrayTrait, SpanTrait };
  use zeroable::Zeroable;

  // locals
  use marketplace::access::ownable::Ownable;
  use marketplace::utils::zeroable::U256Zeroable;
  use super::super::interface::IMarketplace;
  use super::super::messages::MarketplaceMessages;
  use super::{ Order, Voucher };
  use super::super::order::Item;

  // dispatchers
  use marketplace::token::erc20::{ IERC20Dispatcher, IERC20DispatcherTrait };
  use marketplace::token::erc1155::{ IERC1155Dispatcher, IERC1155DispatcherTrait };
  use marketplace::token::lazy_minter::{ ILazyMinterDispatcher, ILazyMinterDispatcherTrait };

  //
  // Events
  //

  #[event]
  fn FulfillOrder(
    hash: felt252,
    offerer: starknet::ContractAddress,
    offeree: starknet::ContractAddress,
    offer_item: Item,
    consideration_item: Item,
  ) {}

  #[event]
  fn CancelOrder(
    hash: felt252,
    offerer: starknet::ContractAddress,
    offer_item: Item,
    consideration_item: Item,
  ) {}

  //
  // Constructor
  //

  #[constructor]
  fn constructor(owner_: starknet::ContractAddress) {
    initializer(:owner_);
  }

  //
  // impls
  //

  impl Marketplace of IMarketplace {
    fn fulfill_order(offerer: starknet::ContractAddress, order: Order, signature: Span<felt252>) {
      let hash = MarketplaceMessages::consume_valid_order_from(from: offerer, :order, :signature);

      // transfer offer to caller
      let caller = starknet::get_caller_address();

      _transfer_item_from(from: offerer, to: caller, item: order.offer_item);

      // transfer consideration to offerer
      _transfer_item_from(from: caller, to: offerer, item: order.consideration_item);

      // Events
      FulfillOrder(
        :hash,
        :offerer,
        offeree: caller,
        offer_item: order.offer_item,
        consideration_item: order.consideration_item
      );
    }

    fn cancel_order(order: Order, signature: Span<felt252>) {
      let caller = starknet::get_caller_address();

      let hash = MarketplaceMessages::consume_valid_order_from(from: caller, :order, :signature);

      // Events
      CancelOrder(
        :hash,
        offerer: caller,
        offer_item: order.offer_item,
        consideration_item: order.consideration_item
      );
    }

    fn redeem_voucher_and_fulfill_order(
      voucher: Voucher,
      voucher_signature: Span<felt252>,
      order: Order,
      order_signature: Span<felt252>
    ) {
      let offerer = voucher.receiver;
      MarketplaceMessages::consume_valid_order_from(from: offerer, :order, signature: order_signature);

      // assert voucher and order offer item match
      match order.offer_item {
        Item::ERC20(erc_20_item) => {
          assert(voucher.token_id.is_zero(), 'Invalid voucher and order match');
          assert(voucher.amount == erc_20_item.amount, 'Invalid voucher and order match');
        },

        Item::ERC1155(erc_1155_item) => {
          assert(voucher.token_id == erc_1155_item.identifier, 'Invalid voucher and order match');
          assert(voucher.amount == erc_1155_item.amount, 'Invalid voucher and order match');
        }
      }

      // mint offer to caller
      let caller = starknet::get_caller_address();

      _transfer_item_with_voucher(to: caller, item: order.offer_item, :voucher, :voucher_signature);

      // transfer consideration to offerer
      _transfer_item_from(from: caller, to: offerer, item: order.consideration_item);
    }
  }

  //
  // Upgrade
  //

  // TODO: use Upgradeable impl with more custom call after upgrade
  #[external]
  fn upgrade(new_implementation: starknet::ClassHash) {
    // Modifiers
    Ownable::assert_only_owner();

    // Body

    // set new impl
    starknet::replace_class_syscall(new_implementation);
  }

  // Getters

  #[view]
  fn owner() -> starknet::ContractAddress {
    Ownable::owner()
  }

  // Ownable

  #[external]
  fn transfer_ownership(new_owner: starknet::ContractAddress) {
    Ownable::transfer_ownership(:new_owner);
  }

  #[external]
  fn renounce_ownership() {
    Ownable::renounce_ownership();
  }

  // Order

  #[external]
  fn fulfill_order(offerer: starknet::ContractAddress, order: Order, signature: Span<felt252>) {
    Marketplace::fulfill_order(:offerer, :order, :signature);
  }

  #[external]
  fn cancel_order(order: Order, signature: Span<felt252>) {
    Marketplace::cancel_order(:order, :signature);
  }

  #[external]
  fn redeem_voucher_and_fulfill_order(
    voucher: Voucher,
    voucher_signature: Span<felt252>,
    order: Order,
    order_signature: Span<felt252>
  ) {
    Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
  }

  //
  // Internals
  //

  // Init

  #[internal]
  fn initializer(owner_: starknet::ContractAddress) {
    Ownable::_transfer_ownership(new_owner: owner_);
  }

  // Order

  #[internal]
  fn _transfer_item_from(from: starknet::ContractAddress, to: starknet::ContractAddress, item: Item) {
    // TODO: add case fallback support

    match item {
      Item::ERC20(erc_20_item) => {
        let ERC20 = IERC20Dispatcher { contract_address: erc_20_item.token };

        ERC20.transferFrom(sender: from, recipient: to, amount: erc_20_item.amount);
      },

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

  #[internal]
  fn _transfer_item_with_voucher(
    to: starknet::ContractAddress,
    item: Item,
    voucher: Voucher,
    voucher_signature: Span<felt252>
  ) {
    // TODO: add case fallback support

    let mut token: starknet::ContractAddress = starknet::contract_address_const::<0>();

    match item {
      Item::ERC20(erc_20_item) => {
        token = erc_20_item.token
      },

      Item::ERC1155(erc_1155_item) => {
        token = erc_1155_item.token
      },
    }

    let LazyMinter = ILazyMinterDispatcher { contract_address: token };
    LazyMinter.redeem_voucher_to(:to, :voucher, signature: voucher_signature);
  }
}
