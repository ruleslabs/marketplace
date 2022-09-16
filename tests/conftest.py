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

artist1 = uint(str_to_felt('artist1'))
artist2 = uint(str_to_felt('artist2'))
artist3 = uint(str_to_felt('artist3'))

cardModel1 = (artist1, 1, 0) # (artist, season, scarcity)
cardModel2 = (artist2, 1, 0)
cardModel3 = (artist3, 1, 0)

metadata = (1, 1, 0x1220)


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

  rules_data_class = await declare(starknet, 'ruleslabs/contracts/RulesData/RulesData.cairo')
  rules_cards_class = await declare(starknet, 'ruleslabs/contracts/RulesCards/RulesCards.cairo')
  rules_packs_class = await declare(starknet, 'ruleslabs/contracts/RulesPacks/RulesPacks.cairo')
  rules_tokens_class = await declare(starknet, 'ruleslabs/contracts/RulesTokens/RulesTokens.cairo')

  erc20_class = await declare(starknet, 'openzeppelin/token/erc20/presets/ERC20Upgradeable.cairo')

  marketplace_class = await declare(starknet, 'src/marketplace/Marketplace.cairo')

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

  rules_data = await deploy_proxy(
    starknet,
    rules_data_class.abi,
    [
      rules_data_class.class_hash,
      initialize_selector,
      1,
      accounts.owner.contract_address
    ],
  )
  rules_cards = await deploy_proxy(
    starknet,
    rules_cards_class.abi,
    [
      rules_cards_class.class_hash,
      initialize_selector,
      2,
      accounts.owner.contract_address,
      rules_data.contract_address,
    ],
  )
  rules_packs = await deploy_proxy(
    starknet,
    rules_packs_class.abi,
    [
      rules_packs_class.class_hash,
      initialize_selector,
      3,
      accounts.owner.contract_address,
      rules_data.contract_address,
      rules_cards.contract_address,
    ],
  )
  rules_tokens = await deploy_proxy(
    starknet,
    rules_tokens_class.abi,
    [
      rules_tokens_class.class_hash,
      initialize_selector,
      5,
      0x52756C6573,
      0x52554C4553,
      accounts.owner.contract_address,
      rules_cards.contract_address,
      rules_packs.contract_address,
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
      rules_tokens.contract_address,
      ether.contract_address,
    ],
  )

  # Access control
  owner_sender = TransactionSender(accounts.owner, signers['owner'])

  await owner_sender.send_transaction([
    (rules_cards.contract_address, 'addMinter', [rules_tokens.contract_address]),
    (rules_packs.contract_address, 'addMinter', [rules_tokens.contract_address]),
  ])

  # Create artists/card

  await owner_sender.send_transaction([
    (rules_data.contract_address, 'createArtist', [*artist1]),
    (rules_data.contract_address, 'createArtist', [*artist2]),
    (rules_data.contract_address, 'createArtist', [*artist3]),

    (rules_tokens.contract_address, 'createAndMintCard', [
      *to_starknet_args(cardModel1),
      1,
      *metadata,
      accounts.rando1.contract_address,
    ]),
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
      rules_data=serialize_contract(rules_data, rules_data_class.abi),
      rules_cards=serialize_contract(rules_cards, rules_cards_class.abi),
      rules_packs=serialize_contract(rules_packs, rules_packs_class.abi),
      rules_tokens=serialize_contract(rules_tokens, rules_tokens_class.abi),
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
