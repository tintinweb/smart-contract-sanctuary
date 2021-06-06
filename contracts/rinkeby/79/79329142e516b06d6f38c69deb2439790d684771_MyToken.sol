/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.4.0;
contract MyToken {
 address public creator;
 uint256 public totalSupply;
 mapping (address => uint256) public balances;
function MyToken() public {
   creator = msg.sender;
   totalSupply = 10000;
   balances[creator] = totalSupply;
}
 function balanceOf(address owner) public constant returns(uint256){
   return balances[owner];
 }
 
 function sendTokens(address receiver, uint256 amount) 
 public returns(bool){
   address owner = msg.sender;
   
   require(amount > 0);
   require(balances[owner] >= amount);
   
   balances[owner] -= amount;
   balances[receiver] += amount;
   return true;
 }
}