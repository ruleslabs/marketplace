#[contract]
mod ERC1155RoyaltiesLazy {
  use array::{ ArrayTrait, SpanTrait };

  // locals
  use super::super::erc1155_lazy_extension::{ ERC1155LazyExtension, Voucher };
  use super::super::erc1155::ERC1155;
  use super::super::erc2981::ERC2981;
  use marketplace::utils::serde::SpanSerde;

  //
  // Constructor
  //

  #[constructor]
  fn constructor(receiver_: starknet::ContractAddress, amount_: u256) {
    ERC2981::constructor(:receiver_, :amount_);
  }

  // ERC2981

  #[view]
  fn royalty_info(token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
    ERC2981::royalty_info(:token_id, :sale_price)
  }

  // LAZY

  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>) {
    ERC1155LazyExtension::redeem_voucher_to(:to, :voucher, :signature);
  }

  // ERC165

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC1155::supports_interface(:interface_id) | ERC2981::supports_interface(:interface_id)
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

  #[external]
  fn safe_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    ERC1155::safe_transfer_from(:from, :to, :id, :amount, :data)
  }
}
