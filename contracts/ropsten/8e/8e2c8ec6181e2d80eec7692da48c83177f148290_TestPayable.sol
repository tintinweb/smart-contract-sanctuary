/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.8.0;

contract TestPayable{
    
  function test() public view returns(uint256){
      return block.timestamp;
  }
   
}