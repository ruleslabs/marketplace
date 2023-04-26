import pytest

from utils.TransactionSender import TransactionSender
from utils.misc import (
  assert_revert, uint, assert_event_emmited, str_to_felt, declare, MAX_PRICE, MIN_PRICE, tax
)

from conftest import cardModel1


VERSION = str_to_felt('0.2.0')


#
# Offer creation
#

@pytest.mark.asyncio
async def test_create_offer_for_invalid_card(ctx_factory):
  ctx = ctx_factory()
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])
  rando2_sender = TransactionSender(ctx.rando2, ctx.signers['rando2'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id

  # create offer for card that do not exists
  await assert_revert(
    rando1_sender.send_transaction([(ctx.marketplace.contract_address, 'createOffer', [1, 1, MIN_PRICE])]),
    'Marketplace: caller does not own card'
  )

  # create offer for card that marketplace can transfer but is owned by another acount
  await assert_revert(
    rando2_sender.send_transaction([
      (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MIN_PRICE]),
    ]),
    'Marketplace: caller does not own card'
  )


@pytest.mark.asyncio
async def test_create_offer_with_invalid_price(ctx_factory):
  ctx = ctx_factory()
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id

  # create offer with price too low
  await assert_revert(
    rando1_sender.send_transaction([
      (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MIN_PRICE - 1]),
    ]),
    'Marketplace: invalid price'
  )

  # create offer with price too high
  await assert_revert(
    rando1_sender.send_transaction([
      (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MAX_PRICE + 1]),
    ]),
    'Marketplace: invalid price'
  )


@pytest.mark.asyncio
async def test_create_and_update_offer(ctx_factory):
  ctx = ctx_factory()
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id

  # create valid offer
  tx_exec_info = await rando1_sender.send_transaction([
    (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MIN_PRICE]),
  ])

  # check offer creation event
  assert_event_emmited(
    tx_exec_info,
    from_address=ctx.marketplace.contract_address,
    name='OfferCreated',
    data=[card1_1_id.low, card1_1_id.high, ctx.rando1.contract_address, MIN_PRICE]
  )

  # check offer price
  assert (await ctx.marketplace.offerFor(card1_1_id).call()).result.price == MIN_PRICE

  # update offer price
  tx_exec_info = await rando1_sender.send_transaction([
    (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MAX_PRICE]),
  ])

  # check offer creation event
  assert_event_emmited(
    tx_exec_info,
    from_address=ctx.marketplace.contract_address,
    name='OfferCreated',
    data=[card1_1_id.low, card1_1_id.high, ctx.rando1.contract_address, MAX_PRICE]
  )

  # check offer price
  assert (await ctx.marketplace.offerFor(card1_1_id).call()).result.price == MAX_PRICE


#
# Offer cancelation
#

@pytest.mark.asyncio
async def test_cancel_invalid_offer(ctx_factory):
  ctx = ctx_factory()
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])
  rando2_sender = TransactionSender(ctx.rando2, ctx.signers['rando2'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id

  # cancel offer that does not exists
  await assert_revert(
    rando1_sender.send_transaction([
      (ctx.marketplace.contract_address, 'cancelOffer', [card1_1_id.low, card1_1_id.high]),
    ]),
    'Marketplace: offer does not exists'
  )

  # create offer
  await rando1_sender.send_transaction([
    (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MIN_PRICE]),
  ])

  # cancel offer created by another account
  await assert_revert(
    rando2_sender.send_transaction([
      (ctx.marketplace.contract_address, 'cancelOffer', [card1_1_id.low, card1_1_id.high]),
    ]),
    'Marketplace: caller is not the offer creator'
  )


@pytest.mark.asyncio
async def test_create_and_cancel_offer(ctx_factory):
  ctx = ctx_factory()
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id

  # create offer
  await rando1_sender.send_transaction([
    (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MIN_PRICE]),
  ])

  # cancel offer
  tx_exec_info = await rando1_sender.send_transaction([
    (ctx.marketplace.contract_address, 'cancelOffer', [card1_1_id.low, card1_1_id.high]),
  ])

  # check offer cancelation event
  assert_event_emmited(
    tx_exec_info,
    from_address=ctx.marketplace.contract_address,
    name='OfferCanceled',
    data=[card1_1_id.low, card1_1_id.high]
  )

  # check offer price
  assert (await ctx.marketplace.offerFor(card1_1_id).call()).result.price == 0


#
# Offer accpetation
#

@pytest.mark.asyncio
async def test_create_and_accept_invalid_offer(ctx_factory):
  ctx = ctx_factory()
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])
  rando2_sender = TransactionSender(ctx.rando2, ctx.signers['rando2'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id

  # create offer
  await rando1_sender.send_transaction([
    (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MIN_PRICE]),
  ])

  # transfer ETH to buyer's address
  await owner_sender.send_transaction([
    (ctx.ether.contract_address, 'transfer', [ctx.rando2.contract_address, MIN_PRICE, 0]),
  ])

  # allow marketplace
  await rando2_sender.send_transaction([
    (ctx.ether.contract_address, 'increaseAllowance', [ctx.marketplace.contract_address, MIN_PRICE - 1, 0]),
  ])

  # accept offer without enough ETH allowed
  await assert_revert(
    rando2_sender.send_transaction([
      (ctx.marketplace.contract_address, 'acceptOffer', [card1_1_id.low, card1_1_id.high]),
    ])
  )

  # transfer ETH to buyer's address
  await owner_sender.send_transaction([
    (ctx.ether.contract_address, 'transfer', [ctx.rando1.contract_address, MIN_PRICE, 0]),
  ])

  # accept their own offer
  await assert_revert(
    rando1_sender.send_transaction([
      (ctx.marketplace.contract_address, 'acceptOffer', [card1_1_id.low, card1_1_id.high]),
    ]),
    'Marketplace: offer creator cannot accept their own offer'
  )

  # allow marketplace / accept offer
  await rando2_sender.send_transaction([
    (ctx.ether.contract_address, 'increaseAllowance', [ctx.marketplace.contract_address, 1, 0]),
    (ctx.marketplace.contract_address, 'acceptOffer', [card1_1_id.low, card1_1_id.high]),
  ])

  # accept already accepted offer
  await assert_revert(
    owner_sender.send_transaction([
      (ctx.ether.contract_address, 'increaseAllowance', [ctx.marketplace.contract_address, MIN_PRICE, 0]),
      (ctx.marketplace.contract_address, 'acceptOffer', [card1_1_id.low, card1_1_id.high]),
    ]),
    'Marketplace: offer does not exists'
  )


@pytest.mark.asyncio
async def test_create_and_accept_offer_with_tricky_price(ctx_factory):
  ctx = ctx_factory()
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])
  rando2_sender = TransactionSender(ctx.rando2, ctx.signers['rando2'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id
  price = MIN_PRICE + 19

  # create offer
  await rando1_sender.send_transaction([
    (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, price]),
  ])

  # transfer ETH to buyer's address
  await owner_sender.send_transaction([
    (ctx.ether.contract_address, 'transfer', [ctx.rando2.contract_address, price, 0]),
  ])

  # allow marketplace / accept offer
  await rando2_sender.send_transaction([
    (ctx.ether.contract_address, 'increaseAllowance', [ctx.marketplace.contract_address, price, 0]),
    (ctx.marketplace.contract_address, 'acceptOffer', [card1_1_id.low, card1_1_id.high]),
  ])

  # check balances
  assert (await ctx.ether.balanceOf(ctx.rando1.contract_address).call()).result.balance == uint(price - tax(price))
  assert (await ctx.ether.balanceOf(ctx.tax.contract_address).call()).result.balance == uint(tax(price))


@pytest.mark.asyncio
async def test_create_and_accept_offer(ctx_factory):
  ctx = ctx_factory()
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])
  rando2_sender = TransactionSender(ctx.rando2, ctx.signers['rando2'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id

  # create offer
  await rando1_sender.send_transaction([
    (ctx.marketplace.contract_address, 'createOffer', [card1_1_id.low, card1_1_id.high, MIN_PRICE]),
  ])

  # transfer ETH to buyer's address
  await owner_sender.send_transaction([
    (ctx.ether.contract_address, 'transfer', [ctx.rando2.contract_address, MIN_PRICE, 0]),
  ])

  # allow marketplace
  await rando2_sender.send_transaction([
    (ctx.ether.contract_address, 'increaseAllowance', [ctx.marketplace.contract_address, MIN_PRICE, 0]),
  ])

  # accept offer
  tx_exec_info = await rando2_sender.send_transaction([
    (ctx.marketplace.contract_address, 'acceptOffer', [card1_1_id.low, card1_1_id.high]),
  ])

  # check offer accpetation event
  assert_event_emmited(
    tx_exec_info,
    from_address=ctx.marketplace.contract_address,
    name='OfferAccepted',
    data=[card1_1_id.low, card1_1_id.high, ctx.rando2.contract_address]
  )

  # check balances
  assert (await ctx.ether.balanceOf(ctx.rando1.contract_address).call()).result.balance == uint(MIN_PRICE - tax(MIN_PRICE))
  assert (await ctx.ether.balanceOf(ctx.tax.contract_address).call()).result.balance == uint(tax(MIN_PRICE))
  assert (await ctx.ether.balanceOf(ctx.rando2.contract_address).call()).result.balance == uint(0)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando2.contract_address, card1_1_id).call()).result.balance == uint(1)


#
# Tax address
#

@pytest.mark.asyncio
async def test_update_tax_address(ctx_factory):
  ctx = ctx_factory()
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])

  # check tax address
  assert (await ctx.marketplace.taxAddress().call()).result.address == ctx.tax.contract_address

  # update tax address with non owner caller
  await assert_revert(
    rando1_sender.send_transaction([(ctx.marketplace.contract_address, 'setTaxAddress', [ctx.rando1.contract_address])])
  )

  await owner_sender.send_transaction([
    (ctx.marketplace.contract_address, 'setTaxAddress', [ctx.rando1.contract_address]),
  ])

  # check tax address
  assert (await ctx.marketplace.taxAddress().call()).result.address == ctx.rando1.contract_address


#
# Contract upgrade
#

@pytest.mark.asyncio
async def test_upgrade(ctx_factory):
  ctx = ctx_factory()
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])

  upgrade_impl = await declare(ctx.starknet, 'src/test/upgrade.cairo')

  # should revert with non owner upgrade
  await assert_revert(
    rando1_sender.send_transaction([(ctx.marketplace.contract_address, 'upgrade', [upgrade_impl.class_hash])]),
  )

  # should revert with null upgrade
  await assert_revert(
    owner_sender.send_transaction([(ctx.marketplace.contract_address, 'upgrade', [0])]),
    'Marketplace: new implementation cannot be null'
  )

  # should revert with double initialization
  await assert_revert(
    owner_sender.send_transaction([(ctx.marketplace.contract_address, 'initialize', [1, 1, 1, 1])]),
    'Marketplace: contract already initialized'
  )

  await owner_sender.send_transaction([(ctx.marketplace.contract_address, 'upgrade', [upgrade_impl.class_hash])])

  # should still revert with double initialization after upgrade
  await assert_revert(
    owner_sender.send_transaction([(ctx.marketplace.contract_address, 'initialize', [])]),
    'Mock: contract already initialized'
  )

  await owner_sender.send_transaction([(ctx.marketplace.contract_address, 'reset', [])])
  await owner_sender.send_transaction([(ctx.marketplace.contract_address, 'initialize', [])])

  # should revert with double initialization
  await assert_revert(
    owner_sender.send_transaction([(ctx.marketplace.contract_address, 'initialize', [])]),
    'Mock: contract already initialized'
  )
