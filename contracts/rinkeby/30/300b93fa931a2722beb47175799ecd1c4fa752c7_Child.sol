/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.4.6;
contract Child {
  address owner;

  function Child() {
    owner = msg.sender;
  }
  function random() public returns (uint256){
      return uint256(keccak256(abi.encodePacked(blockhash(1))));
  }
}