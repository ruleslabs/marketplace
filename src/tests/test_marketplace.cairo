use array::ArrayTrait;
use traits::{ Into, TryInto };
use option::OptionTrait;
use starknet::testing;

// locals
use marketplace::marketplace::Marketplace;
use marketplace::marketplace::order::{ Order, Item };
use marketplace::marketplace::interface::Voucher;
use super::constants::{
  CHAIN_ID,
  BLOCK_TIMESTAMP,
  OWNER,
  OTHER,
  ZERO,
  OFFERER_PUBLIC_KEY,
  OFFEREE_PUBLIC_KEY,
  OFFERER_DEPLOYED_ADDRESS,
  OFFEREE_DEPLOYED_ADDRESS,
  ERC20_AMOUNT,
  ERC1155_IDENTIFIER,
  ERC1155_AMOUNT,
  ERC20_ERC1155_ORDER,
  ERC20_ERC1155_ORDER_SIGNATURE,
  ERC1155_ERC20_ORDER,
  ERC1155_ERC20_ORDER_SIGNATURE,
  ERC1155_VOUCHER,
  ERC1155_VOUCHER_SIGNATURE,
  ROYALTIES_RECEIVER,
  ROYALTIES_AMOUNT,
};
use super::utils;
use super::mocks::signer::Signer;
use super::mocks::erc20::{ ERC20, IERC20Dispatcher, IERC20DispatcherTrait };
use super::mocks::erc1155::{ ERC1155, IERC1155Dispatcher, IERC1155DispatcherTrait };
use super::mocks::erc1155_lazy::ERC1155Lazy;
use super::mocks::erc1155_royalties_lazy::ERC1155RoyaltiesLazy;

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

// SETUP

fn setup() {
  // setup block timestamp
  testing::set_block_timestamp(BLOCK_TIMESTAMP());

  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  Marketplace::constructor(OWNER());
}

fn deploy_signer(public_key: felt252) -> AccountABIDispatcher {
  let mut calldata = ArrayTrait::new();
  calldata.append(public_key);

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);
  AccountABIDispatcher { contract_address: signer_address }
}

fn deploy_offerer() -> AccountABIDispatcher {
  let offerer_address = deploy_signer(OFFERER_PUBLIC_KEY());

  assert(offerer_address.contract_address == OFFERER_DEPLOYED_ADDRESS(), 'offerer setup failed');

  offerer_address
}

fn deploy_offeree() -> AccountABIDispatcher {
  let offeree_address = deploy_signer(OFFEREE_PUBLIC_KEY());

  assert(offeree_address.contract_address == OFFEREE_DEPLOYED_ADDRESS(), 'offeree setup failed');

  offeree_address
}

fn deploy_erc20(recipient: starknet::ContractAddress, initial_supply: u256) -> IERC20Dispatcher {
  let mut calldata = ArrayTrait::<felt252>::new();

  calldata.append(initial_supply.low.into());
  calldata.append(initial_supply.high.into());
  calldata.append(recipient.into());

  let address = utils::deploy(ERC20::TEST_CLASS_HASH, calldata);
  IERC20Dispatcher { contract_address: address }
}

fn deploy_erc1155(recipient: starknet::ContractAddress) -> IERC1155Dispatcher {
  let address = utils::deploy(ERC1155::TEST_CLASS_HASH, calldata: ArrayTrait::<felt252>::new());
  let erc1155 = IERC1155Dispatcher { contract_address: address };

  erc1155.mint(
    to: recipient,
    id: ERC1155_IDENTIFIER(),
    amount: ERC1155_AMOUNT(),
    data: ArrayTrait::<felt252>::new().span()
  );

  erc1155
}

fn deploy_erc1155_lazy(recipient: starknet::ContractAddress) -> IERC1155Dispatcher {
  let address = utils::deploy(ERC1155Lazy::TEST_CLASS_HASH, calldata: ArrayTrait::<felt252>::new());
  let erc1155_lazy = IERC1155Dispatcher { contract_address: address };

  erc1155_lazy.mint(
    to: recipient,
    id: ERC1155_IDENTIFIER(),
    amount: ERC1155_AMOUNT(),
    data: ArrayTrait::<felt252>::new().span()
  );

  erc1155_lazy
}

fn deploy_erc1155_royalties_lazy(recipient: starknet::ContractAddress) -> IERC1155Dispatcher {
  let mut calldata = ArrayTrait::<felt252>::new();

  let royalties_receiver = ROYALTIES_RECEIVER();
  let royalties_amount = ROYALTIES_AMOUNT();

  calldata.append(royalties_receiver.into());
  calldata.append(royalties_amount.low.into());
  calldata.append(royalties_amount.high.into());

  let address = utils::deploy(ERC1155RoyaltiesLazy::TEST_CLASS_HASH, :calldata);
  let erc1155_royalties = IERC1155Dispatcher { contract_address: address };

  erc1155_royalties.mint(
    to: recipient,
    id: ERC1155_IDENTIFIER(),
    amount: ERC1155_AMOUNT(),
    data: ArrayTrait::<felt252>::new().span()
  );

  erc1155_royalties
}

// Upgrade

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_upgrade_unauthorized() {
  setup();

  testing::set_caller_address(OTHER());
  Marketplace::upgrade(new_implementation: 'new implementation'.try_into().unwrap());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Caller is the zero address',))]
fn test_upgrade_from_zero() {
  setup();

  testing::set_caller_address(ZERO());
  Marketplace::upgrade(new_implementation: 'new implementation'.try_into().unwrap());
}

// Cancel order

#[test]
#[available_gas(20000000)]
fn test_cancel_order() {
  setup();

  let offerer = deploy_offerer();

  let order = ERC20_ERC1155_ORDER();
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  testing::set_caller_address(offerer.contract_address);
  Marketplace::cancel_order(:order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_cancel_order_already_canceled() {
  setup();

  let offerer = deploy_offerer();

  let order = ERC20_ERC1155_ORDER();
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  testing::set_caller_address(offerer.contract_address);
  Marketplace::cancel_order(:order, :signature);
  Marketplace::cancel_order(:order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid order signature',))]
fn test_cancel_order_unauthorized() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let order = ERC20_ERC1155_ORDER();
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  testing::set_caller_address(offeree.contract_address);
  Marketplace::cancel_order(:order, :signature);
}

// ERC20 - ERC1155

#[test]
#[available_gas(20000000)]
fn test_fulfill_order_erc20_erc1155() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc20 = deploy_erc20(recipient: offerer.contract_address, initial_supply: ERC20_AMOUNT());
  let erc1155 = deploy_erc1155(recipient: offeree.contract_address);

  let order = ERC20_ERC1155_ORDER();
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  assert_state_before_order(:order);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);

  assert_state_after_order(:order);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_fulfill_order_erc20_erc1155_already_consumed() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc20 = deploy_erc20(recipient: offerer.contract_address, initial_supply: ERC20_AMOUNT());
  let erc1155 = deploy_erc1155(recipient: offeree.contract_address);

  let order = ERC20_ERC1155_ORDER();
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid order signature',))]
fn test_fulfill_order_erc20_erc1155_invalid_signature() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc20 = deploy_erc20(recipient: offerer.contract_address, initial_supply: ERC20_AMOUNT());
  let erc1155 = deploy_erc1155(recipient: offeree.contract_address);

  let mut order = ERC20_ERC1155_ORDER();
  order.salt += 1;
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order ended',))]
fn test_fulfill_order_erc20_erc1155_ended() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc20 = deploy_erc20(recipient: offerer.contract_address, initial_supply: ERC20_AMOUNT());
  let erc1155 = deploy_erc1155(recipient: offeree.contract_address);

  let order = ERC20_ERC1155_ORDER();
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  testing::set_block_timestamp(BLOCK_TIMESTAMP() + 1);
  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_fulfill_order_erc20_erc1155_cancelled() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc20 = deploy_erc20(recipient: offerer.contract_address, initial_supply: ERC20_AMOUNT());
  let erc1155 = deploy_erc1155(recipient: offeree.contract_address);

  let order = ERC20_ERC1155_ORDER();
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  testing::set_caller_address(offerer.contract_address);
  Marketplace::cancel_order(:order, :signature);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
}

// ERC1155 - ERC20

#[test]
#[available_gas(20000000)]
fn test_fulfill_order_erc1155_erc20() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155 = deploy_erc1155(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let order = ERC1155_ERC20_ORDER();
  let signature = ERC1155_ERC20_ORDER_SIGNATURE();

  assert_state_before_order(:order);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);

  assert_state_after_order(:order);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_fulfill_order_erc1155_erc20_already_consumed() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155 = deploy_erc1155(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let order = ERC1155_ERC20_ORDER();
  let signature = ERC1155_ERC20_ORDER_SIGNATURE();

  assert_state_before_order(:order);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid order signature',))]
fn test_fulfill_order_erc1155_erc20_invalid_signature() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155 = deploy_erc1155(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let mut order = ERC1155_ERC20_ORDER();
  order.salt += 1;
  let signature = ERC1155_ERC20_ORDER_SIGNATURE();

  assert_state_before_order(:order);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order ended',))]
fn test_fulfill_order_erc1155_erc20_ended() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155 = deploy_erc1155(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let order = ERC1155_ERC20_ORDER();
  let signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_block_timestamp(BLOCK_TIMESTAMP() + 1);
  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_fulfill_order_erc1155_erc20_cancelled() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155 = deploy_erc1155(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let order = ERC1155_ERC20_ORDER();
  let signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_caller_address(offerer.contract_address);
  Marketplace::cancel_order(:order, :signature);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);
}

// Lazy ERC1155 - ERC20

#[test]
#[available_gas(20000000)]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_lazy = deploy_erc1155_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let voucher = ERC1155_VOUCHER();
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let order = ERC1155_ERC20_ORDER();
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  assert_state_before_order(:order);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);

  assert_state_after_voucher_and_order(:voucher, :order);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher and order match',))]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20_invalid_voucher_token_id() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_lazy = deploy_erc1155_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let mut voucher = ERC1155_VOUCHER();
  voucher.token_id += 1;
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let order = ERC1155_ERC20_ORDER();
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid voucher and order match',))]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20_invalid_voucher_amount() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_lazy = deploy_erc1155_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let mut voucher = ERC1155_VOUCHER();
  voucher.amount += 1;
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let order = ERC1155_ERC20_ORDER();
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid order signature',))]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20_invalid_voucher_recipient() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_lazy = deploy_erc1155_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let mut voucher = ERC1155_VOUCHER();
  voucher.receiver = offeree.contract_address;
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let order = ERC1155_ERC20_ORDER();
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20_already_consumed() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_lazy = deploy_erc1155_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let voucher = ERC1155_VOUCHER();
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let order = ERC1155_ERC20_ORDER();
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);

}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid order signature',))]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20_invalid_signature() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_lazy = deploy_erc1155_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let voucher = ERC1155_VOUCHER();
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let mut order = ERC1155_ERC20_ORDER();
  order.salt += 1;
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order ended',))]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20_ended() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_lazy = deploy_erc1155_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let voucher = ERC1155_VOUCHER();
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let order = ERC1155_ERC20_ORDER();
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_block_timestamp(BLOCK_TIMESTAMP() + 1);
  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20_cancelled() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_lazy = deploy_erc1155_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let voucher = ERC1155_VOUCHER();
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let order = ERC1155_ERC20_ORDER();
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  testing::set_caller_address(offerer.contract_address);
  Marketplace::cancel_order(:order, signature: order_signature);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);
}

// ERC20 - ERC1155_2981

#[test]
#[available_gas(20000000)]
fn test_fulfill_order_erc20_erc1155_with_royalties() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc20 = deploy_erc20(recipient: offerer.contract_address, initial_supply: ERC20_AMOUNT());
  let erc1155_royalties_lazy = deploy_erc1155_royalties_lazy(recipient: offeree.contract_address);

  let order = ERC20_ERC1155_ORDER();
  let signature = ERC20_ERC1155_ORDER_SIGNATURE();

  let royalties_receiver = ROYALTIES_RECEIVER();
  let royalties_amount = ROYALTIES_AMOUNT();

  assert_state_before_order(:order);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);

  assert_state_after_order_with_royalties(:order, receiver: royalties_receiver, amount: royalties_amount);
}

// ERC1155_2981 - ERC20

#[test]
#[available_gas(20000000)]
fn test_fulfill_order_erc1155_erc20_with_royalties() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_royalties_lazy = deploy_erc1155_royalties_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let order = ERC1155_ERC20_ORDER();
  let signature = ERC1155_ERC20_ORDER_SIGNATURE();

  let royalties_receiver = ROYALTIES_RECEIVER();
  let royalties_amount = ROYALTIES_AMOUNT();

  assert_state_before_order(:order);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);

  assert_state_after_order_with_royalties(:order, receiver: royalties_receiver, amount: royalties_amount);
}

// Lazy ERC1155_2981 - ERC20

#[test]
#[available_gas(20000000)]
fn test_redeem_voucher_and_fulfill_order_erc1155_erc20_with_royalties() {
  setup();

  let offerer = deploy_offerer();
  let offeree = deploy_offeree();

  let erc1155_royalties_lazy = deploy_erc1155_royalties_lazy(recipient: offerer.contract_address);
  let erc20 = deploy_erc20(recipient: offeree.contract_address, initial_supply: ERC20_AMOUNT());

  let voucher = ERC1155_VOUCHER();
  let voucher_signature = ERC1155_VOUCHER_SIGNATURE();

  let order = ERC1155_ERC20_ORDER();
  let order_signature = ERC1155_ERC20_ORDER_SIGNATURE();

  let royalties_receiver = ROYALTIES_RECEIVER();
  let royalties_amount = ROYALTIES_AMOUNT();

  assert_state_before_order(:order);

  testing::set_caller_address(offeree.contract_address);
  Marketplace::redeem_voucher_and_fulfill_order(:voucher, :voucher_signature, :order, :order_signature);

  assert_state_after_voucher_and_order_with_royalties(
    :voucher,
    :order,
    receiver: royalties_receiver,
    amount: royalties_amount
  );
}

// TODO

//
// Helpers
//

fn assert_state_before_order(order: Order) {
  let offerer = OFFERER_DEPLOYED_ADDRESS();
  let offeree = OFFEREE_DEPLOYED_ADDRESS();

  assert_item_balance(
    item: order.offer_item,
    owner: offerer,
    other: offeree,
    other_balance: 0.into(),
    error: 'Offer item balance after'
  );
  assert_item_balance(
    item: order.consideration_item,
    owner: offeree,
    other: offerer,
    other_balance: 0.into(),
    error: 'Cons item balance after'
  );
}

fn assert_state_after_order(order: Order) {
  let offerer = OFFERER_DEPLOYED_ADDRESS();
  let offeree = OFFEREE_DEPLOYED_ADDRESS();

  assert_item_balance(
    item: order.offer_item,
    owner: offeree,
    other: offerer,
    other_balance: 0.into(),
    error: 'Offer item balance after'
  );
  assert_item_balance(
    item: order.consideration_item,
    owner: offerer,
    other: offeree,
    other_balance: 0.into(),
    error: 'Cons item balance after'
  );
}

fn assert_state_after_voucher_and_order(voucher: Voucher, order: Order) {
  assert_state_after_voucher_and_order_with_royalties(
    :voucher,
    :order,
    receiver: starknet::contract_address_const::<0>(),
    amount: 0
  )
}

fn assert_state_after_voucher_and_order_with_royalties(
  voucher: Voucher,
  order: Order,
  receiver: starknet::ContractAddress,
  amount: u256
) {
  let offerer = OFFERER_DEPLOYED_ADDRESS();
  let offeree = OFFEREE_DEPLOYED_ADDRESS();

  assert_item_balance_with_royalties(
    item: order.offer_item,
    owner: offeree,
    other: offerer,
    other_balance: voucher.amount,
    error: 'Offer item balance after',
    royalties_receiver: receiver,
    royalties_amount: amount
  );
  assert_item_balance_with_royalties(
    item: order.consideration_item,
    owner: offerer,
    other: offeree,
    other_balance: 0.into(),
    error: 'Cons item balance after',
    royalties_receiver: receiver,
    royalties_amount: amount
  );
}

fn assert_state_after_order_with_royalties(order: Order, receiver: starknet::ContractAddress, amount: u256) {
  let offerer = OFFERER_DEPLOYED_ADDRESS();
  let offeree = OFFEREE_DEPLOYED_ADDRESS();

  assert_item_balance_with_royalties(
    item: order.offer_item,
    owner: offeree,
    other: offerer,
    other_balance: 0.into(),
    error: 'Offer item balance after',
    royalties_receiver: receiver,
    royalties_amount: amount
  );
  assert_item_balance_with_royalties(
    item: order.consideration_item,
    owner: offerer,
    other: offeree,
    other_balance: 0.into(),
    error: 'Cons item balance after',
    royalties_receiver: receiver,
    royalties_amount: amount
  );
}

fn assert_item_balance(
  item: Item,
  owner: starknet::ContractAddress,
  other: starknet::ContractAddress,
  other_balance: u256,
  error: felt252,
) {
  assert_item_balance_with_royalties(
    :item,
    :owner,
    :other,
    :other_balance,
    :error,
    royalties_receiver: starknet::contract_address_const::<0>(),
    royalties_amount: 0
  )
}

fn assert_item_balance_with_royalties(
  item: Item,
  owner: starknet::ContractAddress,
  other: starknet::ContractAddress,
  other_balance: u256,
  error: felt252,
  royalties_receiver: starknet::ContractAddress,
  royalties_amount: u256
) {
  match item {
    Item::Native(()) => { panic_with_felt252('Unsupported item type'); },

    Item::ERC20(erc20_item) => {
      let erc20 = IERC20Dispatcher { contract_address: erc20_item.token };

      assert(erc20.balance_of(owner) == erc20_item.amount - royalties_amount, error);
      assert(erc20.balance_of(other) == other_balance, error);

      assert(erc20.balance_of(royalties_receiver) == royalties_amount, 'Invalid royalties amount')
    },

    Item::ERC721(()) => { panic_with_felt252('Unsupported item type'); },

    Item::ERC1155(erc1155_item) => {
      let erc1155 = IERC1155Dispatcher { contract_address: erc1155_item.token };

      assert(erc1155.balance_of(owner, erc1155_item.identifier) == erc1155_item.amount, error);
      assert(erc1155.balance_of(other, erc1155_item.identifier) == other_balance, error);
    },
  }
}
