%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

#
# Storage
#

# Initialization

@storage_var
func contract_initialized() -> (initialized: felt):
end

@external
func initialize{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> ():
  # assert not already initialized
  let (initialized) = contract_initialized.read()
  with_attr error_message("Mock: contract already initialized"):
      assert initialized = FALSE
  end
  contract_initialized.write(TRUE)

  return ()
end

@external
func reset{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> ():
  contract_initialized.write(FALSE)
  return ()
end
