const IERC2981_ID: u32 = 0x2a55205a;

#[starknet::interface]
trait IERC2981<TContractState> {
  fn royalty_info(ref self: TContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256);
}
