/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract hashtest {
    function hash(string memory _text, uint _num, address _addr) public pure returns (bytes32) {
        return keccak256(abi.encode(_text, _num, _addr));
    }

    function hashTransaction(address sender, uint256 qty, string memory nonce) public pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
        "test",
        keccak256(abi.encodePacked(sender, qty, nonce)))
      );
        return hash;
  }
}