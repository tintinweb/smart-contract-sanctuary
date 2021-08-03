/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

pragma solidity 0.5.1;


contract Factory {
  function deploy(bytes memory code, bytes32 salt) public returns (address addr) {
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) { revert(0, 0) }
    }
  }
}