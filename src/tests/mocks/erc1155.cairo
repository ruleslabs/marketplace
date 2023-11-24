use array::SpanSerde;

#[starknet::interface]
trait MockERC1155ABI<TContractState> {
  fn balance_of(self: @TContractState, account: starknet::ContractAddress, id: u256) -> u256;

  fn mint(ref self: TContractState, to: starknet::ContractAddress, id: u256, amount: u256);

  fn transfer_from(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
  );
}

#[starknet::contract]
mod ERC1155 {
  use array::{ SpanSerde, ArrayTrait };
  use erc1155::erc1155::erc1155::{ ERC1155, ERC1155ABI };
  use erc1155::erc1155::erc1155::ERC1155::InternalTrait as ERC1155InternalTrait;
  use erc1155::erc1155::interface::{ IERC1155, IERC1155Metadata };
  use rules_utils::introspection::interface::ISRC5;

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
  // IERC1155 impl
  //

  #[external(v0)]
  impl IERC1155Impl of ERC1155ABI<ContractState> {
    fn uri(self: @ContractState, token_id: u256) -> Span<felt252> {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.uri(:token_id)
    }

    fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.supports_interface(:interface_id)
    }

    fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.balance_of(:account, :id)
    }

    fn balance_of_batch(
      self: @ContractState,
      accounts: Span<starknet::ContractAddress>,
      ids: Span<u256>
    ) -> Span<u256> {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.balance_of_batch(:accounts, :ids)
    }

    fn is_approved_for_all(self: @ContractState,
      account: starknet::ContractAddress,
      operator: starknet::ContractAddress
    ) -> bool {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.is_approved_for_all(:account, :operator)
    }

    fn set_approval_for_all(ref self: ContractState, operator: starknet::ContractAddress, approved: bool) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.set_approval_for_all(:operator, :approved);
    }

    fn safe_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.safe_transfer_from(:from, :to, :id, :amount, :data);
    }

    fn safe_batch_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.safe_batch_transfer_from(:from, :to, :ids, :amounts, :data);
    }

    fn transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      // skip owner/approve check by using the internal `_transfer_from`
      erc1155_self._transfer_from(:from, :to, :id, :amount);
    }

    fn batch_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.batch_transfer_from(:from, :to, :ids, :amounts);
    }
  }

  //
  // impls
  //

  #[generate_trait]
  #[external(v0)]
  impl IMockERC1155Impl of IMockERC1155 {
    fn mint(ref self: ContractState, to: starknet::ContractAddress, id: u256, amount: u256) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self._mint(:to, :id, :amount, data: array![].span());
    }
  }
}
