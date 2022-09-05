import os
import math

import inspect
import periphery
import ruleslabs
import openzeppelin

from pathlib import Path
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode
from starkware.starknet.business_logic.execution.objects import Event
from starkware.starknet.compiler.compile import get_selector_from_name
from starkware.starknet.business_logic.state.state import BlockInfo


_root = Path(__file__).parent.parent.parent


MIN_PRICE = 10 ** 13
MAX_PRICE = 10 ** 32
TAX_PERCENT = 50_000 # 5%


def to_starknet_args(data):
  items = []
  values = data.values() if type(data) is dict else data
  for d in values:
    if type(d) is dict:
      items.extend([*to_starknet_args(d)])
    elif type(d) is tuple:
      items.extend([*to_starknet_args(d)])
    elif type(d) is list:
      items.append(len(d))
      items.extend([*to_starknet_args(tuple(d))])
    else:
      items.append(d)

  return tuple(items)


def get_contract_class(path):
  """Returns the contract class from src or libraries"""
  if path.startswith("periphery/"):
    path = os.path.abspath(os.path.dirname(inspect.getfile(periphery))) + "/" + path.replace('periphery/', '')
  elif path.startswith("ruleslabs/"):
    path = os.path.abspath(os.path.dirname(inspect.getfile(ruleslabs))) + "/" + path.replace('ruleslabs/', '')
  elif path.startswith("openzeppelin/"):
    path = os.path.abspath(os.path.dirname(inspect.getfile(openzeppelin))) + "/" + path.replace('openzeppelin/', '')

  contract_class = compile_starknet_files(
    files=[path],
    debug_info=True,
    cairo_path=[str(_root / 'src')],
  )
  return contract_class


proxy_class = get_contract_class('periphery/proxy/Proxy.cairo')


def str_to_felt(text):
  b_text = bytes(text, 'UTF-8')
  return int.from_bytes(b_text, "big")


def uint(a, b=0):
  return a, b


async def assert_revert(expression, expected_message=None, expected_code=None):
  if expected_code is None:
    expected_code = StarknetErrorCode.TRANSACTION_FAILED
  try:
    await expression
    assert False
  except StarkException as err:
    _, error = err.args
    assert error['code'] == expected_code
    if expected_message is not None:
      assert expected_message in error['message']


def assert_event_emmited(tx_exec_info, from_address, name, data = []):
  if not data:
    raw_events = [Event(from_address=event.from_address, keys=event.keys, data=[]) for event in tx_exec_info.raw_events]
  else:
    raw_events = tx_exec_info.raw_events

  assert Event(
    from_address=from_address,
    keys=[get_selector_from_name(name)],
    data=data,
  ) in raw_events


async def declare(starknet, path):
  contract_class = get_contract_class(path)
  declared_class = await starknet.declare(contract_class=contract_class)
  return declared_class


async def deploy_proxy(starknet, abi, params=None):
  params = params or []
  deployed_proxy = await starknet.deploy(contract_class=proxy_class, constructor_calldata=params)
  wrapped_proxy = StarknetContract(
    state=starknet.state,
    abi=abi,
    contract_address=deployed_proxy.contract_address,
    deploy_execution_info=deployed_proxy.deploy_execution_info
  )

  return wrapped_proxy


def serialize_contract(contract, abi):
  return dict(
    abi=abi,
    contract_address=contract.contract_address,
    deploy_execution_info=contract.deploy_execution_info
  )


def unserialize_contract(starknet_state, serialized_contract):
  return StarknetContract(state=starknet_state, **serialized_contract)


def set_block_timestamp(starknet_state, timestamp):
  starknet_state.state.block_info = BlockInfo.create_for_testing(
    starknet_state.state.block_info.block_number, timestamp
  )


def tax(amount):
  return math.floor(amount / 1_000_000 * TAX_PERCENT)
