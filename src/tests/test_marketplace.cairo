use array::ArrayTrait;
use traits::Into;
use starknet::testing;

// locals
use marketplace::marketplace::Marketplace;
use marketplace::marketplace::order::{ Order, Item };
use super::constants::{
  CHAIN_ID,
  BLOCK_TIMESTAMP,
  OWNER,
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
};
use super::utils;
use super::mocks::signer::Signer;
use super::mocks::erc20::{ ERC20, IERC20Dispatcher, IERC20DispatcherTrait };
use super::mocks::erc1155::{ ERC1155, IERC1155Dispatcher, IERC1155DispatcherTrait };

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

  assert_state_before_order(:order);

  testing::set_block_timestamp(BLOCK_TIMESTAMP() + 1);
  testing::set_caller_address(offeree.contract_address);
  Marketplace::fulfill_order(offerer: offerer.contract_address, :order, :signature);

  assert_state_after_order(:order);
}

//
// Helpers
//

fn assert_state_before_order(order: Order) {
  let offerer = OFFERER_DEPLOYED_ADDRESS();
  let offeree = OFFEREE_DEPLOYED_ADDRESS();

  assert_item_balance(item: order.offer_item, owner: offerer, other: offeree, error: 'Offer item balance before');
  assert_item_balance(
    item: order.consideration_item,
    owner: offeree,
    other: offerer,
    error: 'Offer item balance before'
  );
}

fn assert_state_after_order(order: Order) {
  let offerer = OFFERER_DEPLOYED_ADDRESS();
  let offeree = OFFEREE_DEPLOYED_ADDRESS();

  assert_item_balance(item: order.offer_item, owner: offeree, other: offerer, error: 'Offer item balance after');
  assert_item_balance(
    item: order.consideration_item,
    owner: offerer,
    other: offeree,
    error: 'Offer item balance after'
  );
}

fn assert_item_balance(item: Item, owner: starknet::ContractAddress, other: starknet::ContractAddress, error: felt252) {
  match item {
    Item::ERC20(erc20_item) => {
      let erc20 = IERC20Dispatcher { contract_address: erc20_item.token };

      assert(erc20.balance_of(owner) == erc20_item.amount, error);
      assert(erc20.balance_of(other) == 0.into(), error);
    },

    Item::ERC1155(erc1155_item) => {
      let erc1155 = IERC1155Dispatcher { contract_address: erc1155_item.token };

      assert(erc1155.balance_of(owner, erc1155_item.identifier) == erc1155_item.amount, error);
      assert(erc1155.balance_of(other, erc1155_item.identifier) == 0.into(), error);
    },
  }
}
