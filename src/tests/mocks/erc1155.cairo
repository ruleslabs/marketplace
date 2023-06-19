use marketplace::utils::serde::SpanSerde;

const IERC1155_RECEIVER_ID: u32 = 0x4e2312e0_u32;
const ON_ERC1155_RECEIVED_SELECTOR: u32 = 0xf23a6e61_u32;

#[abi]
trait IERC1155 {
  #[view]
  fn balance_of(account: starknet::ContractAddress, id: u256) -> u256;

  #[external]
  fn mint(to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>);

  #[external]
  fn safe_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );
}

#[abi]
trait IERC1155Receiver {
  #[external]
  fn on_erc1155_received(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> u32;
}

#[abi]
trait IERC165 {
  fn supports_interface(interface_id: u32) -> bool;
}

#[contract]
mod ERC1155 {
  use array::{ Span, ArrayTrait, SpanTrait, ArrayDrop };
  use option::OptionTrait;
  use traits::{ Into, TryInto };
  use zeroable::Zeroable;
  use starknet::contract_address::ContractAddressZeroable;
  use rules_account::account;

  // local
  use marketplace::utils::serde::SpanSerde;

  // Dispatchers
  use super::{ IERC1155ReceiverDispatcher, IERC1155ReceiverDispatcherTrait, IERC165Dispatcher, IERC165DispatcherTrait };

  //
  // Storage
  //

  struct Storage {
    _balances: LegacyMap<(u256, starknet::ContractAddress), u256>,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor() {}

  //
  // Interface impl
  //

  impl ERC1155 of super::IERC1155 {
    fn balance_of(account: starknet::ContractAddress, id: u256) -> u256 {
      _balances::read((id, account))
    }

    fn mint(to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
      assert(to.is_non_zero(), 'ERC1155: mint to 0 addr');
      _update(from: Zeroable::zero(), :to, :id, :amount, :data);
    }

    fn safe_transfer_from(
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let caller = starknet::get_caller_address();

      _safe_transfer_from(:from, :to, :id, :amount, :data);
    }
  }

  #[view]
  fn supports_interface(interface_id: u32) -> bool {
    false
  }

  // Balance

  #[view]
  fn balance_of(account: starknet::ContractAddress, id: u256) -> u256 {
    ERC1155::balance_of(:account, :id)
  }

  // Transfer

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

  // Mint

  #[external]
  fn mint(to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
    ERC1155::mint(:to, :id, :amount, :data);
  }

  //
  // Internals
  //

  // Balances update

  #[internal]
  fn _update(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    mut id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    let operator = starknet::get_caller_address();

    // Decrease sender balance
    if (from.is_non_zero()) {
      let from_balance = _balances::read((id, from));
      assert(from_balance >= amount, 'ERC1155: insufficient balance');

      _balances::write((id, from), from_balance - amount);
    }

    // Increase recipient balance
    if (to.is_non_zero()) {
      let to_balance = _balances::read((id, to));
      _balances::write((id, to), to_balance + amount);
    }

    // Safe transfer check
    if (to.is_non_zero()) {
      _do_safe_transfer_acceptance_check(:operator, :from, :to, :id, :amount, :data);
    }
  }

  #[internal]
  fn _safe_transfer_from(
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    assert(to.is_non_zero(), 'ERC1155: transfer to 0 addr');
    assert(from.is_non_zero(), 'ERC1155: transfer from 0 addr');

    _update(:from, :to, :id, :amount, :data);
  }

  // Safe transfer check

  #[internal]
  fn _do_safe_transfer_acceptance_check(
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    let ERC165 = IERC165Dispatcher { contract_address: to };

    if (ERC165.supports_interface(super::IERC1155_RECEIVER_ID)) {
      // TODO: add casing fallback mechanism

      let ERC1155Receiver = IERC1155ReceiverDispatcher { contract_address: to };

      let response = ERC1155Receiver.on_erc1155_received(:operator, :from, :id, value: amount, :data);
      assert(response == super::ON_ERC1155_RECEIVED_SELECTOR, 'ERC1155: safe transfer failed');
    } else {
      assert(ERC165.supports_interface(account::interface::IACCOUNT_ID), 'ERC1155: safe transfer failed');
    }
  }
}
