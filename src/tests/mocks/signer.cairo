#[contract]
mod Signer {
  use array::ArrayTrait;

  // locals
  use rules_account::account;
  use rules_account::account::Account;

  struct Storage {
    _public_key: felt252,
  }

  #[constructor]
  fn constructor(public_key_: felt252) {
    _public_key::write(public_key_);
  }

  #[view]
  fn is_valid_signature(message: felt252, signature: Array<felt252>) -> u32 {
    if (Account::_is_valid_signature(:message, signature: signature.span(), public_key: _public_key::read())) {
      account::interface::ERC1271_VALIDATED
    } else {
      0_u32
    }
  }
}
