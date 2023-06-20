use traits::{ Into, TryInto };
use array::ArrayTrait;
use zeroable::Zeroable;
use option::OptionTrait;
use rules_tokens::core::voucher::Voucher;

// locals
use super::deployment_data::DeploymentData;
use super::order::Order;
use rules_utils::utils::serde::SpanSerde;

//
// Interfaces
//

#[abi]
trait IMarketplace {
  fn fulfill_order(offerer: starknet::ContractAddress, order: Order, signature: Span<felt252>);

  fn cancel_order(order: Order, signature: Span<felt252>);

  fn fulfill_order_with_voucher(
    voucher: Voucher,
    voucher_signature: Span<felt252>,
    order: Order,
    order_signature: Span<felt252>,
    offerer_deployment_data: DeploymentData,
  );
}

#[abi]
trait IMarketplaceMessages {
  fn consume_valid_order_from_deployed(
    from: starknet::ContractAddress,
    order: Order,
    signature: Span<felt252>
  ) -> felt252;

  fn consume_valid_order_from(
    from: starknet::ContractAddress,
    deployment_data: DeploymentData,
    order: Order,
    signature: Span<felt252>
  ) -> felt252;
}
