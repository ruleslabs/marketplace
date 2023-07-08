#[starknet::interface]
trait IERC20<TContractState> {
  fn transferFrom(
    ref self: TContractState,
    sender: starknet::ContractAddress,
    recipient: starknet::ContractAddress,
    amount: u256
  ) -> bool;
}
