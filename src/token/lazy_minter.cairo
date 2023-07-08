use array::SpanSerde;

// locals
use rules_marketplace::marketplace::interface::Voucher;

#[starknet::interface]
trait ILazyMinter<TContractState> {
  fn redeem_voucher_to(
    ref self: TContractState,
    to: starknet::ContractAddress,
    voucher: Voucher,
    signature: Span<felt252>
  );
}
