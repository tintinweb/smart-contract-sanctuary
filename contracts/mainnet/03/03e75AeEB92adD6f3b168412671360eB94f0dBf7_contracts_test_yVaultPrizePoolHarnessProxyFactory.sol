pragma solidity >=0.6.0 <0.7.0;

import "./yVaultPrizePoolHarness.sol";
import "../external/openzeppelin/ProxyFactory.sol";

/// @title Compound Prize Pool Proxy Factory
/// @notice Minimal proxy pattern for creating new Compound Prize Pools
contract yVaultPrizePoolHarnessProxyFactory is ProxyFactory {

  /// @notice Contract template for deploying proxied Prize Pools
  yVaultPrizePoolHarness public instance;

  /// @notice Initializes the Factory with an instance of the Compound Prize Pool
  constructor () public {
    instance = new yVaultPrizePoolHarness();
  }

  /// @notice Creates a new Compound Prize Pool as a proxy of the template instance
  /// @return A reference to the new proxied Compound Prize Pool
  function create() external returns (yVaultPrizePoolHarness) {
    return yVaultPrizePoolHarness(deployMinimal(address(instance), ""));
  }
}
