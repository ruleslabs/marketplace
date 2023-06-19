use array::{ ArrayTrait, SpanTrait };

// locals
use marketplace::marketplace::order::{ Order, Item, ERC20_Item, ERC1155_Item };
use marketplace::marketplace::interface::Voucher;

fn CHAIN_ID() -> felt252 {
  'SN_MAIN'
}

fn BLOCK_TIMESTAMP() -> u64 {
  103374042_u64
}

//
// ORDERS
//

fn ORDER_1() -> Order {
  Order {
    offer_item: Item::ERC1155(ERC1155_Item {
      token: starknet::contract_address_const::<'offer token 1'>(),
      identifier: u256 { low: 'offer id 1 low', high: 'offer id 1 high' },
      amount: u256 { low: 'offer qty 1 low', high: 'offer qty 1 high' },
    }),
    consideration_item: Item::ERC20(ERC20_Item {
      token: starknet::contract_address_const::<'consideration token 1'>(),
      amount: u256 { low: 'cons qty 1 low', high: 'cons qty 1 high' },
    }),
    end_time: BLOCK_TIMESTAMP() + 1,
    salt: 'salt 1',
  }
}

fn ORDER_NEVER_ENDING_1() -> Order {
  Order {
    offer_item: Item::ERC1155(ERC1155_Item {
      token: starknet::contract_address_const::<'offer token 1'>(),
      identifier: u256 { low: 'offer id 1 low', high: 'offer id 1 high' },
      amount: u256 { low: 'offer qty 1 low', high: 'offer qty 1 high' },
    }),
    consideration_item: Item::ERC20(ERC20_Item {
      token: starknet::contract_address_const::<'consideration token 1'>(),
      amount: u256 { low: 'cons qty 1 low', high: 'cons qty 1 high' },
    }),
    end_time: 0,
    salt: 'salt 1',
  }
}

fn ORDER_SIGNER_DEPLOYED_ADDRESS() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x1>()
}

fn ORDER_HASH_1() -> felt252 {
  0x5a13f4842d3a9b909b7427a4e5d69f78112aba6cccda56a026b8efd297c8383
}

fn ORDER_SIGNATURE_1() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(876402741576646565148770586865873811316250132106631758270158427849694173024);
  signature.append(514159716373770259544679914962644045541061449832249102721974179788564699846);

  signature.span()
}

fn ORDER_NEVER_ENDING_SIGNATURE_1() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(3210214247380703542994973286972689220748965902345806966092546787159936036487);
  signature.append(2690570938561731535554890091946750695329299952767417363992914417361837008483);

  signature.span()
}

fn ORDER_SIGNER_PUBLIC_KEY() -> felt252 {
  0x1766831fbcbc258a953dd0c0505ecbcd28086c673355c7a219bc031b710b0d6
}

// ADDRESSES

fn RECEIVER_DEPLOYED_ADDRESS() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x2>()
}

fn ZERO() -> starknet::ContractAddress {
  Zeroable::zero()
}

fn OWNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<10>()
}

fn OTHER() -> starknet::ContractAddress {
  starknet::contract_address_const::<20>()
}

// OFFERER

fn OFFERER_DEPLOYED_ADDRESS() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x1>()
}

fn OFFERER_PUBLIC_KEY() -> felt252 {
  0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa
}

// OFFEREE

fn OFFEREE_PUBLIC_KEY() -> felt252 {
  0x1766831fbcbc258a953dd0c0505ecbcd28086c673355c7a219bc031b710b0d6
}

fn OFFEREE_DEPLOYED_ADDRESS() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x2>()
}

// Token items

fn OFFER_ITEM() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x3>()
}

fn CONSIDERATION_TOKEN() -> starknet::ContractAddress {
  starknet::contract_address_const::<0x4>()
}

// ERC20

fn ERC20_AMOUNT() -> u256 {
  u256 { low: '20 amount low', high: '20 amount high' }
}

// ERC1155

fn ERC1155_IDENTIFIER() -> u256 {
  u256 { low: '1155 id low', high: '1155 id high' }
}

fn ERC1155_AMOUNT() -> u256 {
  u256 { low: '1155 amount low', high: '1155 amount high' }
}

// ERC20 - ERC1155 ORDER

fn ERC20_ERC1155_ORDER() -> Order {
  Order {
    offer_item: Item::ERC20(ERC20_Item {
      token: OFFER_ITEM(),
      amount: ERC20_AMOUNT(),
    }),
    consideration_item: Item::ERC1155(ERC1155_Item {
      token: CONSIDERATION_TOKEN(),
      amount: ERC1155_AMOUNT(),
      identifier: ERC1155_IDENTIFIER(),
    }),
    end_time: BLOCK_TIMESTAMP() + 1,
    salt: 'salt',
  }
}

fn ERC20_ERC1155_ORDER_SIGNATURE() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(1281060891488011359920073002560504883606194816097925964186379671190882885728);
  signature.append(2296517848558767532445805739597068093247967935247609606190417237188864783597);

  signature.span()
}

// ERC1155 - ERC20 ORDER

fn ERC1155_ERC20_ORDER() -> Order {
  Order {
    offer_item: Item::ERC1155(ERC1155_Item {
      token: OFFER_ITEM(),
      amount: ERC1155_AMOUNT(),
      identifier: ERC1155_IDENTIFIER(),
    }),
    consideration_item: Item::ERC20(ERC20_Item {
      token: CONSIDERATION_TOKEN(),
      amount: ERC20_AMOUNT(),
    }),
    end_time: BLOCK_TIMESTAMP() + 1,
    salt: 'salt',
  }
}

fn ERC1155_ERC20_ORDER_SIGNATURE() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(1726358592003144046973488050783226419285786675296765593625279726901622921655);
  signature.append(649274182830509636730150756499692063841191143164645540663386691975573923431);

  signature.span()
}

// VOUCHER

fn ERC1155_VOUCHER() -> Voucher {
  Voucher {
    receiver: OFFERER_DEPLOYED_ADDRESS(),
    token_id: ERC1155_IDENTIFIER(),
    amount: ERC1155_AMOUNT(),
    salt: 'salt',
  }
}

// Not verifyed but mocked lazy ERC1155
fn ERC1155_VOUCHER_SIGNATURE() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(0xdead);
  signature.append(0xdead);

  signature.span()
}

// ROYALTIES

fn ROYALTIES_RECEIVER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'royalties receiver'>()
}

fn ROYALTIES_AMOUNT() -> u256 {
  0x42
}
