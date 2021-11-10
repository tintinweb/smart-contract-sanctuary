/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Factory {
  event Deployed(address deployed);

  function deploy(bytes memory code, bytes32 salt) public returns (address addr) {
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) { revert(0, 0) }
    }
    emit Deployed(addr);
  }

    function computeAddress(
        bytes32 bytecodeHash,
        bytes32 salt) public view returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}