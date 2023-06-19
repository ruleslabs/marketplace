#[contract]
mod ERC1155Lazy {
  use array::{ ArrayTrait, SpanTrait };

  // locals
  use super::super::erc1155_lazy_extension::{ ERC1155LazyExtension, Voucher };
  use marketplace::utils::serde::SpanSerde;
  use super::super::erc1155::ERC1155;

  //
  // Constructor
  //

  #[constructor]
  fn constructor() {}

  // LAZY

  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>) {
    ERC1155LazyExtension::redeem_voucher_to(:to, :voucher, :signature);
  }

  // ERC165

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC1155::supports_interface(:interface_id)
  }

  // ERC1155

  #[view]
  fn balance_of(account: starknet::ContractAddress, id: u256) -> u256 {
    ERC1155::balance_of(:account, :id)
  }

  #[external]
  fn mint(to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
    ERC1155::mint(:to, :id, :amount, :data);
  }
}
