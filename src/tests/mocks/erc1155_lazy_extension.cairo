// locals
use marketplace::marketplace::interface::Voucher;
use rules_utils::utils::serde::SpanSerde;

#[abi]
trait ILazy {
  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>);
}

#[contract]
mod ERC1155LazyExtension {
  use array::{ ArrayTrait, SpanTrait };

  // locals
  use super::{ Voucher, SpanSerde, ILazy };
  use super::super::erc1155::ERC1155;

  //
  // Constructor
  //

  #[constructor]
  fn constructor() {}

  //
  // Interface impl
  //

  impl Lazy of ILazy {
    fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>) {
      ERC1155::mint(:to, id: voucher.token_id, amount: voucher.amount, data: ArrayTrait::<felt252>::new().span());
    }
  }

  // LAZY

  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>) {
    Lazy::redeem_voucher_to(:to, :voucher, :signature);
  }
}
