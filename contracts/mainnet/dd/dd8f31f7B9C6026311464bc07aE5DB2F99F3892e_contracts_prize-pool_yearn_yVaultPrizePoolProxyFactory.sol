// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./yVaultPrizePool.sol";
import "../../external/openzeppelin/ProxyFactory.sol";

/// @title yVault Prize Pool Proxy Factory
/// @notice Minimal proxy pattern for creating new yVault Prize Pools
contract yVaultPrizePoolProxyFactory is ProxyFactory {

  /// @notice Contract template for deploying proxied Prize Pools
  yVaultPrizePool public instance;

  /// @notice Initializes the Factory with an instance of the yVault Prize Pool
  constructor () public {
    instance = new yVaultPrizePool();
  }

  /// @notice Creates a new yVault Prize Pool as a proxy of the template instance
  /// @return A reference to the new proxied yVault Prize Pool
  function create() external returns (yVaultPrizePool) {
    return yVaultPrizePool(deployMinimal(address(instance), ""));
  }
}
