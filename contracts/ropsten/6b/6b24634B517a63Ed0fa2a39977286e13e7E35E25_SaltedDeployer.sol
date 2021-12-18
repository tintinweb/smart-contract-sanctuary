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
 *    SaltedDeployer.sol :: 0x6b24634B517a63Ed0fa2a39977286e13e7E35E25
 *    etherscan.io verified 2021-12-18
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
  bytes32 constant SALT = 0xd2a5b1e84cb7a6df481438c61ec4144631172d3d29b2a30fe7c5f0fbf4e51735;

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
    return account.code.length > 0;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

interface ISingletonFactory {
  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract);
}