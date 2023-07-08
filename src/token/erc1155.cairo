use array::SpanSerde;

#[starknet::interface]
trait IERC1155<TContractState> {
  fn safe_transfer_from(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );
}
