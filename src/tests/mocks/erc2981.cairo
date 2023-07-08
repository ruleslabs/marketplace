#[starknet::interface]
trait IERC2981<TContractState> {
  fn royalty_info(self: @TContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256);
}

#[starknet::contract]
mod ERC2981 {
  // locals
  use rules_marketplace::royalties::erc2981::IERC2981_ID;

  //
  // Storage
  //

  #[storage]
  struct Storage {
    _receiver: starknet::ContractAddress,
    _amount: u256,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState, receiver_: starknet::ContractAddress, amount_: u256) {
    self.initializer(:receiver_, :amount_);
  }

  //
  // ERC2981 impl
  //

  impl IERC2981Impl of super::IERC2981<ContractState> {
    fn royalty_info(self: @ContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
      let receiver_ = self._receiver.read();
      let amount_ = self._amount.read();

      (receiver_, amount_)
    }
  }

  // ERC165

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
    interface_id == IERC2981_ID
  }

  //
  // Helper impl
  //

  #[generate_trait]
  impl HelperImpl of HelperTrait {
    fn initializer(ref self: ContractState, receiver_: starknet::ContractAddress, amount_: u256) {
      self._receiver.write(receiver_);
      self._amount.write(amount_);
    }
  }
}
