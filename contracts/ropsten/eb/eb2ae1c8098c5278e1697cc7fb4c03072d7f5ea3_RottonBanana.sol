/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;
 
 contract RottonBanana {
     uint256 s;
     address owner;
     constructor (uint256 init) public{
         s = init;
         owner = msg.sender;
     }
     
     function add(uint256 value) public {
         require(msg.sender == owner);
         s += value;
     }
     
      function getVal() public view returns(uint256) {
        return s;
     }   
 }