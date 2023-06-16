use traits::{ Into, TryInto };
use array::ArrayTrait;
use zeroable::Zeroable;
use option::OptionTrait;
use rules_tokens::core::voucher::Voucher;

use super::order::Order;
use marketplace::utils::serde::SpanSerde;

//
// Interfaces
//

#[abi]
trait IMarketplace {
  fn fulfill_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>);

  fn cancel_order(order: Order, signature: Span<felt252>);

  fn redeem_voucher_and_fulfill_order(
    voucher: Voucher,
    voucher_signature: Span<felt252>,
    order: Order,
    order_signature: Span<felt252>
  );
}

#[abi]
trait IMarketplaceMessages {
  fn consume_valid_order_from(from: starknet::ContractAddress, order: Order, signature: Span<felt252>);
}
