// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    SaltedDeployer.sol :: 0x06520213Ce8c4d71BB9394DdE67FD5b6Fb18224f
 *    goerli.etherscan.io verified 2021-12-01
 */ 

import "../Interfaces/ISingletonFactory.sol";

/// @title Deploys contracts using the canonical SingletonFactory and a hardcoded bytes32 salt. Includes custom events
/// and errors.
contract SaltedDeployer {
  /// @dev Emit when contract is deployed successfully
  event Deployed(address deployAddress);

  /// @dev Revert when SingletonFactory deploy returns 0 address
  error DeployFailed();

  /// @dev Revert when initCode is already deployed
  error DeploymentExists();

  /// @dev Salt used for salted deployments
  bytes32 constant SALT = 0x5175f702e5f6e1a12f068fa2dd37cd29f87e0815d094cb39c88bbb0667c8714f;

  /// @dev Canonical SingletonFactory address
  /// @notice https://eips.ethereum.org/EIPS/eip-2470
  ISingletonFactory constant SINGLETON_FACTORY = ISingletonFactory(0xce0042B868300000d44A59004Da54A005ffdcf9f);

  /// @dev Computes the salted deploy address of contract with initCode
  /// @return deployAddress Address where the contract with initCode will be deployed
  function getDeployAddress (bytes memory initCode) public pure returns (address deployAddress) {
    bytes32 hash = keccak256(
      abi.encodePacked(bytes1(0xff), address(SINGLETON_FACTORY), SALT, keccak256(initCode))
    );
    deployAddress = address(uint160(uint(hash)));
  }

  /// @dev Deploys the contract with initCode
  /// @param initCode The initCode to deploy
  function deploy(bytes memory initCode) external {
    if (_isContract(getDeployAddress(initCode))) {
      revert DeploymentExists();
    }
    address deployAddress = SINGLETON_FACTORY.deploy(initCode, SALT);
    if (deployAddress == address(0)) {
      revert DeployFailed();
    }
    emit Deployed(deployAddress);
  }

  function _isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in construction, since the code is only stored
    // at the end of the constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

interface ISingletonFactory {
  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract);
}