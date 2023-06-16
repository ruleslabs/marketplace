#[abi]
trait IERC20 {
  #[external]
  fn transferFrom(sender: starknet::ContractAddress, recipient: starknet::ContractAddress, amount: u256) -> bool;
}
