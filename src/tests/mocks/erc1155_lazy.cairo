#[starknet::contract]
mod ERC1155Lazy {
  use array::{ ArrayTrait, SpanTrait, SpanSerde };

  // locals
  use super::super::erc1155_lazy_extension::{ ERC1155LazyExtension, ILazy, Voucher };
  use super::super::erc1155::{ ERC1155, IERC1155 };
  use rules_marketplace::introspection::erc165::{ IERC165 };

  //
  // Storage
  //

  #[storage]
  struct Storage { }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState) { }

  // LAZY

  #[external(v0)]
  fn redeem_voucher_to(
    ref self: ContractState,
    to: starknet::ContractAddress,
    voucher: Voucher,
    signature: Span<felt252>
  ) {
    let mut erc1155_lazy_extension_self = ERC1155LazyExtension::unsafe_new_contract_state();

    erc1155_lazy_extension_self.redeem_voucher_to(:to, :voucher, :signature);
  }

  // ERC165

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
    let erc1155_self = ERC1155::unsafe_new_contract_state();

    erc1155_self.supports_interface(:interface_id)
  }

  // ERC1155

  #[external(v0)]
  fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
    let erc1155_self = ERC1155::unsafe_new_contract_state();

    erc1155_self.balance_of(:account, :id)
  }

  #[external(v0)]
  fn mint(ref self: ContractState, to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
    let mut erc1155_self = ERC1155::unsafe_new_contract_state();

    erc1155_self.mint(:to, :id, :amount, :data);
  }
}
