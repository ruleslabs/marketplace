#[starknet::contract]
mod Signer {
  use array::ArrayTrait;

  // locals
  use rules_account::account::Account;
  use rules_account::account::Account::{ InternalTrait as AccountInternalTrait };
  use rules_account::account::interface::ISRC6_ID;

  //
  // Storage
  //

  #[storage]
  struct Storage {
    _public_key: felt252,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState, public_key_: felt252) {
    self._public_key.write(public_key_);
  }

  //
  // impls
  //

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
    if (interface_id == ISRC6_ID) {
      true
    } else {
      false
    }
  }

  #[external(v0)]
  fn is_valid_signature(self: @ContractState, message: felt252, signature: Array<felt252>) -> felt252 {
    let account_self = Account::unsafe_new_contract_state();

    if (
      account_self._is_valid_signature(hash: message, signature: signature.span(), public_key: self._public_key.read())
    ) {
      starknet::VALIDATED
    } else {
      0
    }
  }
}
