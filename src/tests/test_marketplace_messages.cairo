use traits::Into;
use array::ArrayTrait;
use starknet::testing;

// locals
use rules_marketplace::marketplace::messages::MarketplaceMessages;
use rules_marketplace::marketplace::messages::MarketplaceMessages::{
  ContractState as MarketplaceMessagesContractState,
  IMarketplaceMessages,
};
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
  ORDER_UNDELPOYED_SIGNATURE_1,
  ORDER_SIGNER_DEPLOYMENT_DATA,
  UNDEPLOYED_ORDER_SIGNER,
  ORDER_UNDEPLOYED_HASH_1,
};
use super::utils;
use super::mocks::signer::Signer;

// dispatchers
use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

fn setup() -> MarketplaceMessagesContractState {
  // setup block timestamp
  testing::set_block_timestamp(BLOCK_TIMESTAMP());

  // setup chain id to compute vouchers hashes
  testing::set_chain_id(CHAIN_ID());

  let marketplace_messages = MarketplaceMessages::unsafe_new_contract_state();

  marketplace_messages
}

fn setup_signer(public_key: felt252) -> AccountABIDispatcher {
  let calldata = array![public_key];

  let signer_address = utils::deploy(Signer::TEST_CLASS_HASH, calldata);

  assert(signer_address == ORDER_SIGNER_DEPLOYED_ADDRESS(), 'signer setup failed');

  AccountABIDispatcher { contract_address: signer_address }
}

// ORDER

#[test]
#[available_gas(20000000)]
fn test_consume_valid_order_from_valid() {
  let mut marketplace_messages = setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  let order = ORDER_1();
  let hash = ORDER_HASH_1();
  let signature = ORDER_SIGNATURE_1();

  assert(
    marketplace_messages.consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature) == hash,
    'Invalid order hash'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid order signature',))]
fn test_consume_valid_order_from_invalid() {
  let mut marketplace_messages = setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  let mut order = ORDER_1();
  order.salt += 1;
  let signature = ORDER_SIGNATURE_1();

  marketplace_messages.consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order already consumed',))]
fn test_consume_valid_order_from_already_consumed() {
  let mut marketplace_messages = setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  let order = ORDER_1();
  let hash = ORDER_HASH_1();
  let signature = ORDER_SIGNATURE_1();

  assert(
    marketplace_messages.consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature) == hash,
    'Invalid order hash'
  );
  marketplace_messages.consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Order ended',))]
fn test_consume_valid_order_from_ended() {
  let mut marketplace_messages = setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  testing::set_block_timestamp(BLOCK_TIMESTAMP() + 1);

  let order = ORDER_1();
  let signature = ORDER_SIGNATURE_1();

  marketplace_messages.consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature);
}

#[test]
#[available_gas(20000000)]
fn test_consume_valid_order_from_never_ending() {
  let mut marketplace_messages = setup();

  let signer = setup_signer(ORDER_SIGNER_PUBLIC_KEY());

  testing::set_block_timestamp(1);

  let order = ORDER_NEVER_ENDING_1();
  let signature = ORDER_NEVER_ENDING_SIGNATURE_1();

  marketplace_messages.consume_valid_order_from_deployed(from: signer.contract_address, :order, :signature, );
}

#[test]
#[available_gas(20000000)]
fn test_consume_valid_order_from_undeployed() {
  let mut marketplace_messages = setup();

  let signer = UNDEPLOYED_ORDER_SIGNER();

  let order = ORDER_1();
  let hash = ORDER_UNDEPLOYED_HASH_1();
  let signature = ORDER_UNDELPOYED_SIGNATURE_1();
  let offerer_deployment_data = ORDER_SIGNER_DEPLOYMENT_DATA();

  assert(
    marketplace_messages.consume_valid_order_from(
      from: signer,
      deployment_data: offerer_deployment_data,
      :order,
      :signature
    ) == hash,
    'Invalid order hash'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Invalid deployment data',))]
fn test_consume_valid_order_from_undeployed_invalid() {
  let mut marketplace_messages = setup();

  let signer = UNDEPLOYED_ORDER_SIGNER();

  let order = ORDER_1();
  let signature = ORDER_UNDELPOYED_SIGNATURE_1();
  let mut offerer_deployment_data = ORDER_SIGNER_DEPLOYMENT_DATA();
  offerer_deployment_data.public_key += 1;

  marketplace_messages.consume_valid_order_from(
    from: signer,
    deployment_data: offerer_deployment_data,
    :order,
    :signature
  );
}
