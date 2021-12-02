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
 *    AccountFactory.sol :: 0x8D448530F982EAf6Fe1d6A510DdF9f1c09b33a01
 *    goerli.etherscan.io verified 2021-12-01
 */ 

/// @title Brink account factory
/// @notice This is a factory contract used for deployment of Brink proxy accounts
contract AccountFactory {
  /// @dev Salt used for salted deployment of Proxy accounts
  bytes32 constant SALT = 0xa673c34e43742984a277506c967311f8de686653b0232a554cf57699fa5dc522;

  /// @dev Deploys a Proxy account for the given owner
  /// @param owner Owner of the Proxy account
  /// @return account Address of the deployed Proxy account
  /// @notice This deploys a "minimal proxy" contract (https://eips.ethereum.org/EIPS/eip-1167) with the proxy owner
  /// address added to the deployed bytecode. The owner address can be read within a delegatecall by using `extcodecopy`
  function deployAccount(address owner) external returns (address account) {
    bytes memory initCode = abi.encodePacked(
      //  [*** constructor **] [**** eip-1167 ****] [******* implementation_address *******] [********* eip-1167 *********]
      hex'3d604180600a3d3981f3_363d3d373d3d3d363d73_4711b476a2397123c28b73c5447b7c5b09178abf_5af43d82803e903d91602b57fd5bf3',
      owner
    );
    assembly {
      account := create2(0, add(initCode, 0x20), mload(initCode), SALT)
    }
  }
}