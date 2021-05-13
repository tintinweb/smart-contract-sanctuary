/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.16;
/// @title Voting with delegation.

contract Helloworld {

  string public greeting = 'hello world';
  
 
  
  
  
  function changeGreeting (string memory _greeting) public returns(bool) {
            
      greeting = _greeting;
      return true;
  }

  function getGreeting () public view returns (string memory) {
      return greeting;
  }

    
}