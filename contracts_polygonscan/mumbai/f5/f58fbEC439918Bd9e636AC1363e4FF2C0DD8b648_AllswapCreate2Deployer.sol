/**
 *Submitted for verification at polygonscan.com on 2021-06-25
*/

// File: contracts/AllswapCreate2Deployer.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract AllswapCreate2Deployer {
  event Deployed(address addr, uint256 salt);

function deploy(bytes memory code, uint256 salt) public {
    address addr;
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }emit Deployed(addr, salt);
  }
}