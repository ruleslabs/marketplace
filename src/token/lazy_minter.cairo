// locals
use rules_utils::utils::serde::SpanSerde;
use marketplace::marketplace::interface::Voucher;

#[abi]
trait ILazyMinter {
  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>);
}
