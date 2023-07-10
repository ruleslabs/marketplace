#[starknet::contract]
mod ERC1155RoyaltiesLazy {
  use array::{ ArrayTrait, SpanTrait, SpanSerde };

  // locals
  use super::super::erc1155_lazy_extension::{ ERC1155LazyExtension, ILazy, Voucher };

  use super::super::erc1155::ERC1155;
  use super::super::erc1155::ERC1155::{ ERC1155ABI, IMockERC1155 };

  use super::super::erc2981::{ ERC2981, IERC2981 };
  use super::super::erc2981::ERC2981::{ HelperTrait as ERC2981HelperTrait };

  use rules_marketplace::introspection::erc165::IERC165;

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

    erc2981_self.initializer(:receiver_, :amount_);
  }

  // ERC2981

  #[external(v0)]
  fn royalty_info(self: @ContractState, token_id: u256, sale_price: u256) -> (starknet::ContractAddress, u256) {
    let erc2981_self = ERC2981::unsafe_new_contract_state();

    erc2981_self.royalty_info(:token_id, :sale_price)
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

    erc1155_lazy_extension_self.redeem_voucher_to(:to, :voucher, :signature);
  }

  // ERC165

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
    let erc1155_self = ERC1155::unsafe_new_contract_state();
    let erc2981_self = ERC2981::unsafe_new_contract_state();

    erc1155_self.supports_interface(:interface_id) |
    erc2981_self.supports_interface(:interface_id)
  }

  // ERC1155

  #[external(v0)]
  fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
    let erc1155_self = ERC1155::unsafe_new_contract_state();

    erc1155_self.balance_of(:account, :id)
  }

  #[external(v0)]
  fn mint(ref self: ContractState, to: starknet::ContractAddress, id: u256, amount: u256) {
    let mut erc1155_self = ERC1155::unsafe_new_contract_state();

    erc1155_self.mint(:to, :id, :amount);
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

    erc1155_self.safe_transfer_from(:from, :to, :id, :amount, :data)
  }
}
