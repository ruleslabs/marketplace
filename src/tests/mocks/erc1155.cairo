use array::SpanSerde;

const IERC1155_RECEIVER_ID: u32 = 0x4e2312e0_u32;
const ON_ERC1155_RECEIVED_SELECTOR: u32 = 0xf23a6e61_u32;

#[starknet::interface]
trait IERC1155<TContractState> {
  fn balance_of(self: @TContractState, account: starknet::ContractAddress, id: u256) -> u256;

  fn mint(ref self: TContractState, to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>);

  fn safe_transfer_from(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );
}

#[starknet::interface]
trait IERC1155Receiver<TContractState> {
  fn on_erc1155_received(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> u32;
}

#[starknet::interface]
trait IERC165<TContractState> {
  fn supports_interface(self: @TContractState, interface_id: u32) -> bool;
}

#[starknet::contract]
mod ERC1155 {
  use array::{ Span, ArrayTrait, SpanTrait, ArrayDrop, SpanSerde };
  use option::OptionTrait;
  use traits::{ Into, TryInto };
  use zeroable::Zeroable;
  use starknet::contract_address::ContractAddressZeroable;
  use rules_account::account;

  // locals
  // Dispatchers
  use super::{ IERC1155ReceiverDispatcher, IERC1155ReceiverDispatcherTrait, IERC165Dispatcher, IERC165DispatcherTrait };

  //
  // Storage
  //

  #[storage]
  struct Storage {
    _balances: LegacyMap<(u256, starknet::ContractAddress), u256>,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState) { }

  //
  // Interface impl
  //

  #[external(v0)]
  impl IERC1155Impl of super::IERC1155<ContractState> {
    fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
      self._balances.read((id, account))
    }

    fn mint(ref self: ContractState, to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
      assert(to.is_non_zero(), 'ERC1155: mint to 0 addr');
      self._update(from: Zeroable::zero(), :to, :id, :amount, :data);
    }

    fn safe_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let caller = starknet::get_caller_address();

      self._safe_transfer_from(:from, :to, :id, :amount, :data);
    }
  }

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
    false
  }

  //
  // Helpers
  //

  #[generate_trait]
  impl HelperImpl of HelperTrait {

    // Balances update

    fn _update(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      mut id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let operator = starknet::get_caller_address();

      // Decrease sender balance
      if (from.is_non_zero()) {
        let from_balance = self._balances.read((id, from));
        assert(from_balance >= amount, 'ERC1155: insufficient balance');

        self._balances.write((id, from), from_balance - amount);
      }

      // Increase recipient balance
      if (to.is_non_zero()) {
        let to_balance = self._balances.read((id, to));
        self._balances.write((id, to), to_balance + amount);
      }

      // Safe transfer check
      if (to.is_non_zero()) {
        self._do_safe_transfer_acceptance_check(:operator, :from, :to, :id, :amount, :data);
      }
    }

    fn _safe_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      assert(to.is_non_zero(), 'ERC1155: transfer to 0 addr');
      assert(from.is_non_zero(), 'ERC1155: transfer from 0 addr');

      self._update(:from, :to, :id, :amount, :data);
    }

    // Safe transfer check

    fn _do_safe_transfer_acceptance_check(
      ref self: ContractState,
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
}
