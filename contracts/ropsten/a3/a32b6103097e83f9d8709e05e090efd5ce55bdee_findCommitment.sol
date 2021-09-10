/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.4.25;

contract findCommitment {
  bytes32 public commitment;

  constructor(bool choice, uint256 nonce) public {
    commitment = keccak256(abi.encodePacked(choice, nonce));
  }
}