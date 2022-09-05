%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

# Libraries

from marketplace.library import Marketplace

from ruleslabs.lib.Ownable_base import (
  Ownable_get_owner,

  Ownable_initializer,
  Ownable_only_owner,
  Ownable_transfer_ownership,
)

#
# Initializer
#

@external
func initialize{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(owner: felt, _tax_address: felt, _rules_tokens_address: felt, _ether_address: felt):
  Ownable_initializer(owner)

  Marketplace.initializer(owner, _tax_address, _rules_tokens_address, _ether_address)
  return ()
end

#
# Getters
#

@view
func owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (owner: felt):
  let (owner) = Ownable_get_owner()
  return (owner)
end

@view
func get_version() -> (version: felt):
  let (version) = Marketplace.get_version()
  return (version)
end

# Other contracts

@view
func rulesTokens{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (address: felt):
  let (address) = Marketplace.rules_tokens()
  return (address)
end

@view
func taxAddress{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (address: felt):
  let (address) = Marketplace.tax_address()
  return (address)
end

# Offers

@view
func offerFor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(cardId: Uint256) -> (price: felt):
  let (price) = Marketplace.offer_for(cardId)
  return (price)
end

#
# Setters
#

@external
func upgrade{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(implementation: felt):
  Ownable_only_owner()
  Marketplace.upgrade(implementation)
  return ()
end

@external
func setTaxAddress{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(address: felt):
  Ownable_only_owner()
  Marketplace.set_tax_address(address)
  return ()
end

#
# Business logic
#

@external
func createOffer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(cardId: Uint256, price: felt):
  Marketplace.create_offer(cardId, price)
  return ()
end

@external
func cancelOffer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(cardId: Uint256):
  Marketplace.cancel_offer(cardId)
  return ()
end

@external
func acceptOffer{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(cardId: Uint256):
  Marketplace.accept_offer(cardId)
  return ()
end

# Ownership

@external
func transferOwnership{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(new_owner: felt) -> (new_owner: felt):
  Ownable_transfer_ownership(new_owner)
  return (new_owner)
end

@external
func renounceOwnership{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }():
  Ownable_transfer_ownership(0)
  return ()
end
