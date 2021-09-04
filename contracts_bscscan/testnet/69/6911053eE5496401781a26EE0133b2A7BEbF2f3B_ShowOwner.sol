/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

pragma solidity >=0.8.1;

contract ShowOwner{
  
  address private owner;

  constructor(){
      owner = msg.sender;
  }

  function getOwner() public view returns(address){
      return owner;
  }
}