#[abi]
trait IERC165 {
  #[view]
  fn supports_interface(interface_id: u32) -> bool;
}
