use traits::PartialEq;

// locals
use marketplace::marketplace::interface::DeploymentData;

// We avoid using to many bitwise operators
impl DeploymentDataEq of PartialEq<DeploymentData> {
  fn eq(lhs: DeploymentData, rhs: DeploymentData) -> bool {
    if (lhs.public_key != rhs.public_key) {
      false
    } else if (lhs.class_hash != rhs.class_hash) {
      false
    } else if (lhs.calldata_hash != rhs.calldata_hash) {
      false
    } else if (lhs.deployer != rhs.deployer) {
      false
    } else {
      true
    }
  }

  #[inline(always)]
  fn ne(lhs: DeploymentData, rhs: DeploymentData) -> bool {
    !(lhs == rhs)
  }
}
