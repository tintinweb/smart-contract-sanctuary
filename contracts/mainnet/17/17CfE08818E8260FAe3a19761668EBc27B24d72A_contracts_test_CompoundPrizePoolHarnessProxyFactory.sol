pragma solidity >=0.6.0 <0.7.0;

import "./CompoundPrizePoolHarness.sol";
import "../external/openzeppelin/ProxyFactory.sol";

/// @title Compound Prize Pool Proxy Factory
/// @notice Minimal proxy pattern for creating new Compound Prize Pools
contract CompoundPrizePoolHarnessProxyFactory is ProxyFactory {

  /// @notice Contract template for deploying proxied Prize Pools
  CompoundPrizePoolHarness public instance;

  /// @notice Initializes the Factory with an instance of the Compound Prize Pool
  constructor () public {
    instance = new CompoundPrizePoolHarness();
  }

  /// @notice Creates a new Compound Prize Pool as a proxy of the template instance
  /// @return A reference to the new proxied Compound Prize Pool
  function create() external returns (CompoundPrizePoolHarness) {
    return CompoundPrizePoolHarness(deployMinimal(address(instance), ""));
  }
}
