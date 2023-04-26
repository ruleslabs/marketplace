%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

// Libraries

from libraries.Marketplace import Marketplace

from ruleslabs.Libraries.Ownable import Ownable

//
// Initializer
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt,
  _tax_address: felt,
  _rules_tokens_address: felt,
  _ether_address: felt
) {
  Ownable.initialize(owner);

  Marketplace.initializer(owner, _tax_address, _rules_tokens_address, _ether_address);
  return ();
}

//
// Getters
//

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
  let (owner) = Ownable.owner();
  return (owner,);
}

@view
func get_version() -> (version: felt) {
  let (version) = Marketplace.get_version();
  return (version,);
}

// Other contracts

@view
func rulesTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  address: felt
) {
  let (address) = Marketplace.rules_tokens();
  return (address,);
}

@view
func taxAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  address: felt
) {
  let (address) = Marketplace.tax_address();
  return (address,);
}

// Offers

@view
func offerFor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(cardId: Uint256) -> (
  price: felt
) {
  let (price) = Marketplace.offer_for(cardId);
  return (price,);
}

//
// Setters
//

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  implementation: felt
) {
  // modifiers
  Ownable.only_owner();

  // body
  Marketplace.upgrade(implementation);
  return ();
}

@external
func setTaxAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) {
  // modifiers
  Ownable.only_owner();

  // body
  Marketplace.set_tax_address(address);
  return ();
}

//
// Business logic
//

@external
func createOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  cardId: Uint256, price: felt
) {
  Marketplace.create_offer(cardId, price);
  return ();
}

@external
func cancelOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(cardId: Uint256) {
  Marketplace.cancel_offer(cardId);
  return ();
}

@external
func acceptOffer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(cardId: Uint256) {
  Marketplace.accept_offer(cardId);
  return ();
}

// Ownership

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  new_owner: felt
) -> (new_owner: felt) {
  Ownable.transfer_ownership(new_owner);
  return (new_owner,);
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
  Ownable.renounce_ownership();
  return ();
}
