use array::SpanSerde;

// locals
use rules_marketplace::marketplace::interface::Voucher;

#[starknet::interface]
trait ILazy<TContractState> {
  fn redeem_voucher_to(
    ref self: TContractState,
    to: starknet::ContractAddress,
    voucher: Voucher,
    signature: Span<felt252>
  );
}

#[starknet::contract]
mod ERC1155LazyExtension {
  use array::{ ArrayTrait, SpanTrait, SpanSerde };

  // locals
  use super::{ Voucher, ILazy };
  use super::super::erc1155::ERC1155;
  use super::super::erc1155::ERC1155::IMockERC1155;

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

  //
  // Interface impl
  //

  #[external(v0)]
  impl ILazyImpl of ILazy<ContractState> {
    fn redeem_voucher_to(
      ref self: ContractState,
      to: starknet::ContractAddress,
      voucher: Voucher,
      signature: Span<felt252>
    ) {
      let mut erc155_self = ERC1155::unsafe_new_contract_state();

      erc155_self.mint(:to, id: voucher.token_id, amount: voucher.amount);
    }
  }
}
