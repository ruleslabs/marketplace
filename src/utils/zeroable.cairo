use zeroable::Zeroable;

// locals
use marketplace::marketplace::interface::DeploymentData;
use super::partial_eq::DeploymentDataEq;

impl DeploymentDataZeroable of Zeroable<DeploymentData> {
  fn zero() -> DeploymentData {
    DeploymentData {
      public_key: 0,
      class_hash: starknet::class_hash_const::<0>(),
      calldata_hash: 0,
      deployer: starknet::contract_address_const::<0>(),
    }
  }

  #[inline(always)]
  fn is_zero(self: DeploymentData) -> bool {
    self == DeploymentDataZeroable::zero()
  }

  #[inline(always)]
  fn is_non_zero(self: DeploymentData) -> bool {
    self != DeploymentDataZeroable::zero()
  }
}
