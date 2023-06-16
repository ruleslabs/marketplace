use array::SpanTrait;
use zeroable::Zeroable;
use rules_erc1155::utils::serde::SpanSerde;
use messages::typed_data::typed_data::Domain;

// locals
use super::order::Order;

fn DOMAIN() -> Domain {
  Domain {
    name: 'Rules Marketplace',
    version: '1.0',
  }
}

#[abi]
trait MarketplaceMessagesABI {
  #[external]
  fn consume_valid_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) -> felt252;
}

#[contract]
mod MarketplaceMessages {
  use array::{ ArrayTrait, SpanTrait };
  use zeroable::Zeroable;
  use messages::messages::Messages;
  use messages::typed_data::TypedDataTrait;

  // locals
  use super::DOMAIN;
  use super::super::order::Order;
  use rules_erc1155::utils::serde::SpanSerde;
  use rules_tokens::utils::zeroable::{ U64Zeroable };
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
    fn consume_valid_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) -> felt252 {
      // compute voucher message hash
      let hash = order.compute_hash_from(:from, domain: DOMAIN());

      // assert order has not been already consumed and consume it
      assert(!Messages::_is_message_consumed(:hash), 'Order already consumed');
      Messages::_consume_message(:hash);

      // assert order signature is valid
      assert(Messages::_is_message_signature_valid(:hash, :signature, signer: from), 'Invalid order signature');

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
  fn consume_valid_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>) -> felt252 {
    MarketplaceMessages::consume_valid_order_from(:from, :order, :signature)
  }
}
