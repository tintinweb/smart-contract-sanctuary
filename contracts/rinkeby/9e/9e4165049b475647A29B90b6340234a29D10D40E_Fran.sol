/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Fran {

  address payable heredero;
  address owner;
  address oracle;
  constructor(address _oracle, address payable _heredero) public{
      owner = msg.sender;
      heredero = _heredero;
      oracle = _oracle;
  }
  function colocarPlata() payable public {
      
  }
  function murio() public{
      require(msg.sender == oracle);
      heredero.transfer(address(this).balance);
      
  }
  
}