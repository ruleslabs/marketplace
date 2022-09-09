%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_not_equal, unsigned_div_rem
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address

#
# Libraries
#

from periphery.proxy.library import Proxy

# Interfaces

from ruleslabs.contracts.RulesTokens.IRulesTokens import IRulesTokens#
from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

#
# Constants
#

const VERSION = '0.1.0'
const MIN_PRICE = 10 ** 13 # 0.00001 ETH
const MAX_PRICE = 10 ** 26 # 100,000,000 ETH

const TAX_PERCENT = 50000 # 5%
const TAX_DIVIDER = 1000000 / TAX_PERCENT

#
# Storage
#

@storage_var
func contract_initialized() -> (exists: felt):
end

# Other contracts

@storage_var
func rules_tokens_address_storage() -> (rules_cards_address: felt):
end

@storage_var
func ether_address_storage() -> (ether_address: felt):
end

# Tax

@storage_var
func tax_address_storage() -> (tax_address: felt):
end

# Offers

@storage_var
func offers_price_storage(card_id: Uint256) -> (price: felt):
end

@storage_var
func offers_owner_storage(card_id: Uint256) -> (owner: felt):
end

#
# Events
#

@event
func OfferCreated(card_id: Uint256, owner: felt, price: felt):
end

@event
func OfferCanceled(card_id: Uint256):
end

@event
func OfferAccepted(card_id: Uint256, buyer: felt):
end

namespace Marketplace:

  #
  # Initializer
  #

  func initializer{
      syscall_ptr : felt*,
      pedersen_ptr : HashBuiltin*,
      range_check_ptr
    }(owner: felt, _tax_address: felt, _rules_tokens_address: felt, _ether_address: felt):
    # assert not already initialized
    let (initialized) = contract_initialized.read()
    with_attr error_message("Marketplace: contract already initialized"):
        assert initialized = FALSE
    end
    contract_initialized.write(TRUE)

    # other contracts
    rules_tokens_address_storage.write(_rules_tokens_address)
    ether_address_storage.write(_ether_address)

    # tax
    tax_address_storage.write(_tax_address)

    return ()
  end

  #
  # Getters
  #

  func get_version() -> (version: felt):
    return (version=VERSION)
  end

  # Balances

  func offer_for{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(card_id: Uint256) -> (price: felt):
    # Check approve state
    let (owner) = offers_owner_storage.read(card_id)
    let (is_approve_valid) = _is_approve_valid(owner, card_id)

    if is_approve_valid == FALSE:
      return (0)
    end

    let (price) = offers_price_storage.read(card_id)
    return (price)
  end

  # Other contracts

  func rules_tokens{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }() -> (address: felt):
    let (address) = rules_tokens_address_storage.read()
    return (address)
  end

  # Other contracts

  func tax_address{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }() -> (address: felt):
    let (address) = tax_address_storage.read()
    return (address)
  end

  #
  # Setters
  #

  func upgrade{
      syscall_ptr : felt*,
      pedersen_ptr : HashBuiltin*,
      range_check_ptr
    }(implementation: felt):
    # make sure the target is not null
    with_attr error_message("Marketplace: new implementation cannot be null"):
      assert_not_zero(implementation)
    end

    # change implementation
    Proxy.set_implementation(implementation)

    return ()
  end

  func set_tax_address{
      syscall_ptr : felt*,
      pedersen_ptr : HashBuiltin*,
      range_check_ptr
    }(address: felt):
    # make sure the address is not null
    with_attr error_message("Marketplace: new tax address cannot be null"):
      assert_not_zero(address)
    end

    # change tax address
    tax_address_storage.write(address)

    return ()
  end

  #
  # Business logic
  #

  func create_offer{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(card_id: Uint256, price: felt):
    alloc_locals

    # Check if caller own the card and the marketplace is a valid operator
    let (local caller) = get_caller_address()
    let (is_approve_valid) = _is_approve_valid(owner=caller, card_id=card_id)

    with_attr error_message("Marketplace: not allowed to transfer given card from owner wallet"):
      assert is_approve_valid = TRUE
    end

    # Check price
    with_attr error_message("Marketplace: invalid price"):
      assert_le(price, MAX_PRICE)
      assert_le(MIN_PRICE, price)
    end

    offers_price_storage.write(card_id, price)
    offers_owner_storage.write(card_id, caller)

    OfferCreated.emit(card_id, caller, price)

    return ()
  end

  func cancel_offer{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(card_id: Uint256):
    # Check if offer exists and caller own the card
    let (caller) = get_caller_address()
    let (owner) = offers_owner_storage.read(card_id)

    with_attr error_message("Marketplace: offer does not exists"):
      assert_not_zero(owner)
    end

    with_attr error_message("Marketplace: caller is not the offer creator"):
      assert caller = owner
    end

    # reset offer storage
    offers_price_storage.write(card_id, 0)
    offers_owner_storage.write(card_id, 0)

    OfferCanceled.emit(card_id)

    return ()
  end

  func accept_offer{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(card_id: Uint256):
    alloc_locals

    let (caller) = get_caller_address()

    let (tax_address) = tax_address_storage.read()
    let (rules_tokens) = rules_tokens_address_storage.read()
    let (ether_address) = ether_address_storage.read()

    let (price) = offers_price_storage.read(card_id)
    let (owner) = offers_owner_storage.read(card_id)

    with_attr error_message("Marketplace: offer does not exists"):
      assert_not_zero(price)
    end

    with_attr error_message("Marketplace: offer creator cannot accept their own offer"):
      assert_not_equal(owner, caller)
    end

    # Calculate tax amount
    let (tax_amount, _) = unsigned_div_rem(price, TAX_DIVIDER)

    # transfer price amount to owner
    IERC20.transferFrom(ether_address, sender=caller, recipient=owner, amount=Uint256(price - tax_amount, 0))

    # transfer tax amount to owner
    IERC20.transferFrom(ether_address, sender=caller, recipient=tax_address, amount=Uint256(tax_amount, 0))

    # transfer card to caller
    let data = cast(0, felt*)
    IRulesTokens.safeTransferFrom(
      rules_tokens,
      _from=owner,
      to=caller,
      token_id=card_id,
      amount=Uint256(1, 0),
      data_len=0,
      data=data
    )

    # reset offer storage
    offers_price_storage.write(card_id, 0)
    offers_owner_storage.write(card_id, 0)

    OfferAccepted.emit(card_id, caller)

    return ()
  end

  #
  # Internals
  #

  func _is_approve_valid{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(owner: felt, card_id: Uint256) -> (res: felt):
    let (self) = get_contract_address()
    let (rules_tokens_address) = rules_tokens_address_storage.read()

    let (operator, amount) = IRulesTokens.getApproved(rules_tokens_address, owner=owner, token_id=card_id)

    if amount.low == 0:
      return (FALSE)
    end

    if operator != self:
      return (FALSE)
    end

    return (TRUE)
  end
end
