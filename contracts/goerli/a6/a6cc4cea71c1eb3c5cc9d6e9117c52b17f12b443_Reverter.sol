/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity ^0.6.12;

contract Reverter {
  function testRevert(bool shouldRevert) pure public {
    if(shouldRevert) {
      revert("shouldRevert = true");
    }
  }
}