use core::traits::Into;
use array::ArrayTrait;
use starknet::testing;

// locals
use marketplace::marketplace::messages::MarketplaceMessages;
use super::constants::{
  CHAIN_ID,
  BLOCK_TIMESTAMP,
  ORDER_SIGNER_DEPLOYED_ADDRESS,
  ORDER_1,
  ORDER_HASH_1,
  ORDER_SIGNATURE_1,
  ORDER_SIGNER_PUBLIC_KEY,
  ORDER_NEVER_ENDING_1,
  ORDER_NEVER_ENDING_SIGNATURE_1,
};
use super::utils;
use super::mocks::signer::Signer;

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

fn setup() {
  // setup block timestamp
  testing::set_block_timestamp(BLOCK_TIMESTAMP());

  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  MarketplaceMessages::constructor();
}

fn setup_signer(public_key: felt252) -> AccountABIDispatcher {
  let mut calldata = ArrayTrait::new();
  calldata.append(public_key);

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);

  assert(signer_address == ORDER_SIGNER_DEPLOYED_ADDRESS(), 'signer setup failed');

  AccountABIDispatcher { contract_address: signer_address }
}

// ORDER

#[test]
#[available_gas(20000000)]
fn test_consume_valid_order_from_valid() {
  setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  let order = ORDER_1();
  let hash = ORDER_HASH_1();
  let signature = ORDER_SIGNATURE_1();

  assert(
    MarketplaceMessages::consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature) == hash,
    'Invalid order hash'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid order signature',))]
fn test_consume_valid_order_from_invalid() {
  setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  let mut order = ORDER_1();
  order.salt += 1;
  let signature = ORDER_SIGNATURE_1();

  MarketplaceMessages::consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_consume_valid_order_from_already_consumed() {
  setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  let order = ORDER_1();
  let hash = ORDER_HASH_1();
  let signature = ORDER_SIGNATURE_1();

  assert(
    MarketplaceMessages::consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature) == hash,
    'Invalid order hash'
  );
  MarketplaceMessages::consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order ended',))]
fn test_consume_valid_order_from_ended() {
  setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  testing::set_block_timestamp(BLOCK_TIMESTAMP() + 1);

  let order = ORDER_1();
  let signature = ORDER_SIGNATURE_1();

  MarketplaceMessages::consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
fn test_consume_valid_order_from_never_ending() {
  setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  testing::set_block_timestamp(1);

  let order = ORDER_NEVER_ENDING_1();
  let signature = ORDER_NEVER_ENDING_SIGNATURE_1();

  MarketplaceMessages::consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature, );
}

// #[test]
// #[available_gas(20000000)]
// fn test_consume_valid_order_from_undeployed() {
//   setup();

//   let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

//   testing::set_block_timestamp(1);

//   let order = ORDER_NEVER_ENDING_1();
//   let signature = ORDER_NEVER_ENDING_SIGNATURE_1();

//   MarketplaceMessages::consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature, );
// }
