/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.6.6;

contract DonationOfBank {
  address owner;
  mapping (address =>uint) balances;
  
  constructor() public {
    owner = msg.sender;
  }
    
  function deposit() public payable{
    balances[msg.sender] = balances[msg.sender]+msg.value;	
  }
    
  function transferTo(address payable to, uint amount) public payable {
    require(tx.origin == owner);
    to.transfer(amount);
  }
 
  function kill() public {
    require(msg.sender == owner);
    selfdestruct(msg.sender);
  }
  function BalanceOf() public view returns (uint) {
  
        return address(this).balance;
    }
}