use traits::Into;
use box::BoxTrait;
use messages::typed_data::common::hash_u256;
use messages::typed_data::Message;

// sn_keccak('Order(offerItem:Item,considerationItem:Item,endTime:felt252,salt:felt252)Item(token:felt252,identifier:u256,amount:u256,itemType:felt252)u256(low:felt252,high:felt252)')
const ORDER_TYPE_HASH: felt252 = 0xf5cb0008ccf4df0ea7c494dc3453108b2cc44f5baac3214bab30fbfbe1bf40;

// sn_keccak('Item(token:felt252,identifier:u256,amount:u256,itemType:felt252)u256(low:felt252,high:felt252)')
const ITEM_TYPE_HASH: felt252 = 0x2f28211a4b264a061fc03d701a04b11e2a0a6d97c4f26fd564b3af79dfb9c1d;

#[derive(Serde, Copy, Drop)]
struct Order {
  offer_item: Item,
  consideration_item: Item,
  end_time: u64,
  salt: felt252,
}

#[derive(Serde, Copy, Drop)]
struct ERC20_Item {
  token: starknet::ContractAddress,
  amount: u256,
}

#[derive(Serde, Copy, Drop)]
struct ERC1155_Item {
  token: starknet::ContractAddress,
  identifier: u256,
  amount: u256,
}

#[derive(Serde, Copy, Drop)]
enum Item {
  Native: (),
  ERC20: ERC20_Item,
  ERC721: (),
  ERC1155: ERC1155_Item,
}

impl OrderMessage of Message<Order> {
  #[inline(always)]
  fn compute_hash(self: @Order) -> felt252 {
    let mut hash = pedersen::pedersen(0, ORDER_TYPE_HASH);
    hash = pedersen::pedersen(hash, hash_item(*self.offer_item));
    hash = pedersen::pedersen(hash, hash_item(*self.consideration_item));
    hash = pedersen::pedersen(hash, (*self).end_time.into());
    hash = pedersen::pedersen(hash, *self.salt);

    pedersen::pedersen(hash, 5)
  }
}

fn hash_item(item: Item) -> felt252 {
  let mut hash = pedersen::pedersen(0, ITEM_TYPE_HASH);

  match item {
    Item::Native(()) => { panic_with_felt252('Unsupported item type'); },

    Item::ERC20(erc_20_item) => {
      hash = pedersen::pedersen(hash, erc_20_item.token.into());
      hash = pedersen::pedersen(hash, hash_u256(u256 { low: 0, high: 0 }));
      hash = pedersen::pedersen(hash, hash_u256(erc_20_item.amount));
      hash = pedersen::pedersen(hash, 1);
    },

    Item::ERC721(()) => { panic_with_felt252('Unsupported item type'); },

    Item::ERC1155(erc_1155_item) => {
      hash = pedersen::pedersen(hash, erc_1155_item.token.into());
      hash = pedersen::pedersen(hash, hash_u256(erc_1155_item.identifier));
      hash = pedersen::pedersen(hash, hash_u256(erc_1155_item.amount));
      hash = pedersen::pedersen(hash, 3);
    },
  }

  pedersen::pedersen(hash, 5)
}
