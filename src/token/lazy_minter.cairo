use rules_tokens::core::voucher::Voucher;

// locals
use marketplace::utils::serde::SpanSerde;

#[abi]
trait ILazyMinter {
  #[external]
  fn redeem_voucher_to(to: starknet::ContractAddress, voucher: Voucher, signature: Span<felt252>);
}
