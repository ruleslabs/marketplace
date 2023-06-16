// locals
use marketplace::utils::serde::SpanSerde;
use marketplace::marketplace::interface::Voucher;

#[abi]
trait ILazyMinter {
  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>);
}

#[contract]
mod LazyMinter {
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

  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>) {
    LazyMinter::redeem_voucher_to(:to, :voucher, :signature);
  }
}
