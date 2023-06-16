use array::ArrayTrait;

// locals
use marketplace::marketplace::order::{ Order, Item, ERC20_Item, ERC1155_Item };

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

fn ORDER_SIGNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<'order signer'>()
}

fn ORDER_SIGNATURE_1() -> Span<felt252> {
  let mut signature = ArrayTrait::new();

  signature.append(876402741576646565148770586865873811316250132106631758270158427849694173024);
  signature.append(514159716373770259544679914962644045541061449832249102721974179788564699846);

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
