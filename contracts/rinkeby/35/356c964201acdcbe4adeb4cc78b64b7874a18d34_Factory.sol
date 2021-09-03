/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Factory {
  function deploy(bytes memory code, bytes32 salt) public returns (address addr) {
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) { revert(0, 0) }
    }
  }
}