#[starknet::contract]
mod ERC1155RoyaltiesLazy {
  use array::{ ArrayTrait, SpanTrait, SpanSerde };

  // locals
  use super::super::erc1155_lazy_extension::{ ERC1155LazyExtension, Voucher };
  use super::super::erc1155::ERC1155;
  use super::super::erc2981::ERC2981;

  //
  // Storage
  //

  #[storage]
  struct Storage { }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState, receiver_: starknet::ContractAddress, amount_: u256) {
    let mut erc2981_self = ERC2981::unsafe_new_contract_state();

    ERC2981::HelperImpl::initializer(ref self: erc2981_self, :receiver_, :amount_);
  }

  // ERC2981

  #[external(v0)]
  fn royalty_info(self: @ContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
    let erc2981_self = ERC2981::unsafe_new_contract_state();

    ERC2981::IERC2981Impl::royalty_info(self: @erc2981_self, :token_id, :sale_price)
  }

  // LAZY

  #[external(v0)]
  fn redeem_voucher_to(
    ref self: ContractState,
    to: starknet::ContractAddress,
    voucher: Voucher,
    signature: Span<felt252>
  ) {
    let mut erc1155_lazy_extension_self = ERC1155LazyExtension::unsafe_new_contract_state();

    ERC1155LazyExtension::ILazyImpl::redeem_voucher_to(
      ref self: erc1155_lazy_extension_self,
      :to,
      :voucher,
      :signature
    );
  }

  // ERC165

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
    let erc1155_self = ERC1155::unsafe_new_contract_state();
    let erc2981_self = ERC2981::unsafe_new_contract_state();

    ERC1155::supports_interface(self: @erc1155_self, :interface_id) |
    ERC2981::supports_interface(self: @erc2981_self, :interface_id)
  }

  // ERC1155

  #[external(v0)]
  fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
    let erc1155_self = ERC1155::unsafe_new_contract_state();

    ERC1155::IERC1155Impl::balance_of(self: @erc1155_self, :account, :id)
  }

  #[external(v0)]
  fn mint(ref self: ContractState, to: starknet::ContractAddress, id: u256, amount: u256, data: Span<felt252>) {
    let mut erc1155_self = ERC1155::unsafe_new_contract_state();

    ERC1155::IERC1155Impl::mint(ref self: erc1155_self, :to, :id, :amount, :data);
  }

  #[external(v0)]
  fn safe_transfer_from(
    ref self: ContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  ) {
    let mut erc1155_self = ERC1155::unsafe_new_contract_state();

    ERC1155::IERC1155Impl::safe_transfer_from(ref self: erc1155_self, :from, :to, :id, :amount, :data)
  }
}
