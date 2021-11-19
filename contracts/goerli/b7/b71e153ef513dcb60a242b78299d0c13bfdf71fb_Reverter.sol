/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity ^0.6.12;

contract Reverter {
  bool shouldRevert;
  
  constructor() public {
    shouldRevert = false;
  }

  function testRevert() view public {
    if(shouldRevert) {
      revert("shouldRevert = true");
    }
  }

  function toggleRevert() public {
    shouldRevert = !shouldRevert;
  }
}