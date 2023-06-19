const IERC2981_ID: u32 = 0x2a55205a;

#[abi]
trait IERC2981 {
  #[view]
  fn royalty_info(token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256);
}
