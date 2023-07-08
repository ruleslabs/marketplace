use array::SpanSerde;
use rules_tokens::core::voucher::Voucher;

// locals
use super::deployment_data::DeploymentData;
use super::order::Order;

//
// Interfaces
//

#[starknet::interface]
trait IMarketplace<TContractState> {
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

#[starknet::interface]
trait IMarketplaceMessages<TContractState> {
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
