// locals
use marketplace::utils::serde::SpanSerde;
use marketplace::marketplace::interface::Voucher;

#[abi]
trait ILazyMinter {
  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>);
}

#[abi]
trait IERC165 {
  fn supports_interface(interface_id: u32) -> bool;
}

#[contract]
mod ERC1155Lazy {
  use array::{ ArrayTrait, SpanTrait };

  // locals
  use marketplace::utils::serde::SpanSerde;
  use super::super::erc1155::ERC1155;
  use super::Voucher;

  //
  // Constructor
  //

  #[constructor]
  fn constructor() {}

  //
  // Interface impl
  //

  impl LazyMinter of super::ILazyMinter {
    fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>) {
      ERC1155::mint(:to, id: voucher.token_id, amount: voucher.amount, data: ArrayTrait::<felt252>::new().span());
    }
  }

  // VOUCHER

  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>) {
    LazyMinter::redeem_voucher_to(:to, :voucher, :signature);
  }

  // ERC1155

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    ERC1155::supports_interface(:interface_id)
  }

  #[view]
  fn balance_of(account: starknet::ContractAddress, id: u256) -> u256 {
    ERC1155::balance_of(:account, :id)
  }

  #[external]
  fn mint(to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
    ERC1155::mint(:to, :id, :amount, :data);
  }
}
