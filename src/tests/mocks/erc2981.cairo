#[abi]
trait IERC2981 {
  #[view]
  fn supports_interface(interface_id: u32) -> bool;

  #[view]
  fn royalty_info(token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256);
}

#[contract]
mod ERC2981 {
  // locals
  use marketplace::royalties::erc2981::IERC2981_ID;

  //
  // Storage
  //

  struct Storage {
    _receiver: starknet::ContractAddress,
    _amount: u256,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(receiver_: starknet::ContractAddress, amount_: u256) {
    _receiver::write(receiver_);
    _amount::write(amount_);
  }

  //
  // Interface impl
  //

  impl ERC2981 of super::IERC2981 {
    fn supports_interface(interface_id: u32) -> bool {
      interface_id == IERC2981_ID
    }

    fn royalty_info(token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
      let receiver_ = _receiver::read();
      let amount_ = _amount::read();

      (receiver_, amount_)
    }
  }

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC2981::supports_interface(:interface_id)
  }

  #[view]
  fn royalty_info(token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
    ERC2981::royalty_info(:token_id, :sale_price)
  }
}
