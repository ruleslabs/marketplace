use traits::{ Into, TryInto };
use option::OptionTrait;
use starknet::Felt252TryIntoContractAddress;

const CONTRACT_ADDRESS_PREFIX: felt252 = 'STARKNET_CONTRACT_ADDRESS';

#[derive(Serde, Copy, Drop)]
struct DeploymentData {
  public_key: felt252,
  class_hash: starknet::ClassHash,
  calldata_hash: felt252,
  deployer: starknet::ContractAddress,
}

#[generate_trait]
impl DeploymentDataImpl of DeploymentDataTrait {
  fn compute_address(self: @DeploymentData) -> starknet::ContractAddress {
    let mut address = pedersen::pedersen(0, CONTRACT_ADDRESS_PREFIX);
    address = pedersen::pedersen(address, (*self.deployer).into());
    address = pedersen::pedersen(address, *self.public_key);
    address = pedersen::pedersen(address, (*self.class_hash).into());
    address = pedersen::pedersen(address, *self.calldata_hash);

    pedersen::pedersen(address, 5).try_into().unwrap()
  }
}
