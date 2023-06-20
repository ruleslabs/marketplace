use marketplace::marketplace::deployment_data::DeploymentDataTrait;
use array::SpanTrait;
use zeroable::Zeroable;
use rules_utils::utils::serde::SpanSerde;
use messages::typed_data::typed_data::Domain;

// locals
use super::interface::{ Order, DeploymentData };

fn DOMAIN() -> Domain {
  Domain {
    name: 'Rules Marketplace',
    version: '1.0',
  }
}

#[abi]
trait MarketplaceMessagesABI {
  #[external]
  fn consume_valid_order_from_deployed(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) -> felt252;

  #[external]
  fn consume_valid_order_from(
    from: starknet::ContractAddress,
    deployment_data: DeploymentData,
    order: Order,
    signature: Span<felt252>
  ) -> felt252;
}

#[contract]
mod MarketplaceMessages {
  use array::{ ArrayTrait, SpanTrait };
  use zeroable::Zeroable;
  use messages::messages::Messages;
  use messages::typed_data::TypedDataTrait;
  use rules_account::account::Account;
  use rules_utils::utils::zeroable::U64Zeroable;

  // locals
  use super::{ DOMAIN, Order, DeploymentData };
  use super::super::deployment_data::DeploymentDataTrait;
  use rules_utils::utils::serde::SpanSerde;
  use marketplace::utils::zeroable::{ DeploymentDataZeroable };
  use super::super::interface::{ IMarketplaceMessages };

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

  //
  // Constructor
  //

  #[constructor]
  fn constructor() {}

  //
  // impls
  //

  impl MarketplaceMessages of IMarketplaceMessages {
    fn consume_valid_order_from_deployed(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) -> felt252 {
      consume_valid_order_from(:from, deployment_data: DeploymentDataZeroable::zero(), :order, :signature)
    }

    fn consume_valid_order_from(
      from: starknet::ContractAddress,
      deployment_data: DeploymentData,
      order: Order,
      signature: Span<felt252>
    ) -> felt252 {
      // compute voucher message hash
      let hash = order.compute_hash_from(:from, domain: DOMAIN());

      // assert order has not been already consumed and consume it
      assert(!Messages::_is_message_consumed(:hash), 'Order already consumed');
      Messages::_consume_message(:hash);

      // assert order signature is valid
      if (deployment_data.is_zero()) {
        assert(Messages::_is_message_signature_valid(:hash, :signature, signer: from), 'Invalid order signature');
      } else {
        let computed_signer = deployment_data.compute_address();
        assert(computed_signer == from, 'Invalid deployment data');

        assert(
          Account::_is_valid_signature(message: hash, :signature, public_key: deployment_data.public_key),
          'Invalid order signature'
        );
      }

      // assert end time is not passed
      if (order.end_time.is_non_zero()) {
        let block_timestamp = starknet::get_block_timestamp();

        assert(block_timestamp < order.end_time, 'Order ended');
      }

      hash
    }
  }

  // Order

  #[external]
  fn consume_valid_order_from_deployed(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) -> felt252 {
    MarketplaceMessages::consume_valid_order_from_deployed(:from, :order, :signature)
  }

  #[externak]
  fn consume_valid_order_from(
    from: starknet::ContractAddress,
    deployment_data: DeploymentData,
    order: Order,
    signature: Span<felt252>
  ) -> felt252 {
    MarketplaceMessages::consume_valid_order_from(:from, :deployment_data, :order, :signature)
  }
}
