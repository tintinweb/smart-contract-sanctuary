// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 * ____________________________   _______ __
 * ___  __ )__  __ \___  _/__  | / /__  //_/
 * __  __  |_  /_/ /__  / __   |/ /__  ,<   
 * _  /_/ /_  _, _/__/ /  _  /|  / _  /| |  
 * /_____/ /_/ |_| /___/  /_/ |_/  /_/ |_| 
 * 
 * Brink - AccountFactory.sol - 0x70F86aBAdB35318131505432b5418b6222d06679
 * goerli.etherscan.io verified 2021-12-01
 */ 

/// @title Brink account factory
/// @notice This is a factory contract used for deployment of Brink proxy accounts
contract AccountFactory {
  /// @dev Salt used for salted deployment of Proxy accounts
  bytes32 constant SALT = 0x5175f702e5f6e1a12f068fa2dd37cd29f87e0815d094cb39c88bbb0667c8714f;

  /// @dev Deploys a Proxy account for the given owner
  /// @param owner Owner of the Proxy account
  /// @return account Address of the deployed Proxy account
  /// @notice This deploys a "minimal proxy" contract (https://eips.ethereum.org/EIPS/eip-1167) with the proxy owner
  /// address added to the deployed bytecode. The owner address can be read within a delegatecall by using `extcodecopy`
  function deployAccount(address owner) external returns (address account) {
    bytes memory initCode = abi.encodePacked(
      //  [*** constructor **] [**** eip-1167 ****] [******* implementation_address *******] [********* eip-1167 *********]
      hex'3d604180600a3d3981f3_363d3d373d3d3d363d73_02fea82359954725dec7b135764c4a2d988475e7_5af43d82803e903d91602b57fd5bf3',
      owner
    );
    assembly {
      account := create2(0, add(initCode, 0x20), mload(initCode), SALT)
    }
  }
}