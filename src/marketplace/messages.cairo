use rules_account::account::account::Account::HelperTrait;
use array::SpanSerde;
use messages::typed_data::typed_data::Domain;

// locals
use super::interface::{ Order, DeploymentData };

fn DOMAIN() -> Domain {
  Domain {
    name: 'Rules Marketplace',
    version: '1.0',
  }
}

#[starknet::interface]
trait MarketplaceMessagesABI<TContractState> {
  fn consume_valid_order_from_deployed(
    ref self: TContractState,
    from: starknet::ContractAddress,
    order: Order,
    signature: Span<felt252>
  ) -> felt252;

  fn consume_valid_order_from(
    ref self: TContractState,
    from: starknet::ContractAddress,
    deployment_data: DeploymentData,
    order: Order,
    signature: Span<felt252>
  ) -> felt252;
}

#[starknet::contract]
mod MarketplaceMessages {
  use array::{ ArrayTrait, SpanTrait, SpanSerde };
  use zeroable::Zeroable;
  use integer::U64Zeroable;
  use messages::messages::Messages;
  use messages::messages::Messages::{ HelperTrait as MessagesHelperTrait };
  use messages::typed_data::TypedDataTrait;
  use rules_account::account::Account;
  use rules_account::account::Account::{ HelperTrait as AccountHelperTrait };

  // locals
  use rules_marketplace::marketplace;
  use super::{ DOMAIN, Order, DeploymentData };
  use super::super::deployment_data::DeploymentDataTrait;
  use rules_marketplace::utils::zeroable::{ DeploymentDataZeroable };
  use super::super::interface::{ IMarketplaceMessages };

  // dispatchers
  use rules_account::account::{ AccountABIDispatcher, AccountABIDispatcherTrait };

  //
  // Storage
  //

  #[storage]
  struct Storage { }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState) { }

  //
  // impls
  //

  #[external(v0)]
  impl IMarketplaceMessagesImpl of marketplace::interface::IMarketplaceMessages<ContractState> {
    fn consume_valid_order_from_deployed(
      ref self: ContractState,
      from: starknet::ContractAddress,
      order: Order,
      signature: Span<felt252>
    ) -> felt252 {
      self.consume_valid_order_from(:from, deployment_data: DeploymentDataZeroable::zero(), :order, :signature)
    }

    fn consume_valid_order_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      deployment_data: DeploymentData,
      order: Order,
      signature: Span<felt252>
    ) -> felt252 {
      let mut messages_self = Messages::unsafe_new_contract_state();

      // compute voucher message hash
      let hash = order.compute_hash_from(:from, domain: DOMAIN());

      // assert order has not been already consumed and consume it
      assert(!messages_self._is_message_consumed(:hash), 'Order already consumed');
      messages_self._consume_message(:hash);

      // assert order signature is valid
      if (deployment_data.is_zero()) {
        assert(
          messages_self._is_message_signature_valid(:hash, :signature, signer: from),
          'Invalid order signature'
        );
      } else {
        let account_self = Account::unsafe_new_contract_state();

        let computed_signer = deployment_data.compute_address();
        assert(computed_signer == from, 'Invalid deployment data');

        assert(
          account_self._is_valid_signature(message: hash, :signature, public_key: deployment_data.public_key),
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
}
