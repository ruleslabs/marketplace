import pytest
import asyncio
import dill
import sys
import time
from types import SimpleNamespace

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import get_selector_from_name

from utils.Signer import Signer
from utils.misc import (
  declare, deploy_proxy, serialize_contract, unserialize_contract,
  set_block_timestamp, uint, str_to_felt, to_starknet_args,
)
from utils.TransactionSender import TransactionSender


# pytest-xdest only shows stderr
sys.stdout = sys.stderr

initialize_selector = get_selector_from_name('initialize')
initializer_selector = get_selector_from_name('initializer')

BASE_URI = 0x42

card1 = (uint(str_to_felt('artist1')), 1, 0, 1) # (artist, season, scarcity)
card2 = (uint(str_to_felt('artist2')), 1, 0, 1)
card3 = (uint(str_to_felt('artist3')), 1, 0, 1)

metadata = (1, 0x1220)


@pytest.fixture(scope='session')
def event_loop():
  return asyncio.new_event_loop()


async def build_copyable_deployment():
  starknet = await Starknet.empty()

  # initialize realistic timestamp
  set_block_timestamp(starknet.state, round(time.time()))

  signers = dict(
    owner=Signer(987654321123456789),
    tax=Signer(123456789987654321),
    rando1=Signer(111111111),
    rando2=Signer(222222222),
  )

  account_class = await declare(starknet, 'periphery/account/Account.cairo')

  rules_class = await declare(starknet, 'ruleslabs/Rules.cairo')

  erc20_class = await declare(starknet, 'openzeppelin/token/erc20/presets/ERC20Upgradeable.cairo')

  marketplace_class = await declare(starknet, 'src/Marketplace.cairo')

  accounts = SimpleNamespace(
    **{
      name: (await deploy_proxy(
        starknet,
        account_class.abi,
        [account_class.class_hash, initialize_selector, 2, signer.public_key, 0]
      ))
      for name, signer in signers.items()
    }
  )

  rules = await deploy_proxy(
    starknet,
    rules_class.abi,
    [
      rules_class.class_hash,
      initialize_selector,
      3,
      1,
      BASE_URI,
      accounts.owner.contract_address,
    ],
  )

  ether = await deploy_proxy(
    starknet,
    erc20_class.abi,
    [
      erc20_class.class_hash,
      initializer_selector,
      7,
      str_to_felt('Ether'),
      str_to_felt('ETH'),
      18,
      2 ** 128 - 1,
      0,
      accounts.owner.contract_address,
      accounts.owner.contract_address,
    ],
  )

  marketplace = await deploy_proxy(
    starknet,
    marketplace_class.abi,
    [
      marketplace_class.class_hash,
      initialize_selector,
      4,
      accounts.owner.contract_address,
      accounts.tax.contract_address,
      rules.contract_address,
      ether.contract_address,
    ],
  )

  # Access control
  owner_sender = TransactionSender(accounts.owner, signers['owner'])

  # Setup Rules

  await owner_sender.send_transaction([
    (rules.contract_address, 'createAndMintCard', [
      accounts.rando1.contract_address,
      *to_starknet_args(card1),
      *metadata,
    ]),

    (rules.contract_address, 'setMarketplace', [marketplace.contract_address]),
  ])

  return SimpleNamespace(
    starknet=starknet,
    signers=signers,
    serialized_accounts=dict(
      owner=serialize_contract(accounts.owner, account_class.abi),
      tax=serialize_contract(accounts.tax, account_class.abi),
      rando1=serialize_contract(accounts.rando1, account_class.abi),
      rando2=serialize_contract(accounts.rando2, account_class.abi),
    ),
    serialized_contracts=dict(
      rules=serialize_contract(rules, rules_class.abi),
      marketplace=serialize_contract(marketplace, marketplace_class.abi),
      ether=serialize_contract(ether, erc20_class.abi),
    ),
  )


@pytest.fixture(scope='session')
async def copyable_deployment(request):
  CACHE_KEY='deployment'
  val = request.config.cache.get(CACHE_KEY, None)

  if val is None:
    val = await build_copyable_deployment()
    res = dill.dumps(val).decode('cp437')
    request.config.cache.set(CACHE_KEY, res)
  else:
    val = dill.loads(val.encode('cp437'))

  return val


@pytest.fixture(scope='session')
async def ctx_factory(copyable_deployment):
  serialized_contracts = copyable_deployment.serialized_contracts
  serialized_accounts = copyable_deployment.serialized_accounts
  signers = copyable_deployment.signers

  def make():
    starknet_state = copyable_deployment.starknet.state.copy()
    contracts = {
      name: unserialize_contract(starknet_state, serialized_contract)
      for name, serialized_contract in serialized_contracts.items()
    }
    accounts = {
      name: unserialize_contract(starknet_state, serialized_account)
      for name, serialized_account in serialized_accounts.items()
    }

    return SimpleNamespace(
      starknet=Starknet(starknet_state),
      signers=signers,
      **accounts,
      **contracts
    )

  return make
