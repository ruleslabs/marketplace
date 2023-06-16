use marketplace::utils::serde::SpanSerde;

#[abi]
trait IERC1155 {
  #[external]
  fn safe_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );
}
