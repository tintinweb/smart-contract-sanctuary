/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.8.3;
contract NftArt {
string public name = 'Nft'; 
//Token Name
string public symbol = 'hc'; 
//Token Symbol
address public deplo_add = msg.sender;
mapping (address => uint) balances; 
//a key-value pair to store addresses and their account balances
event Transfer(address _from, address _to, uint256 _value); 
// declaration of an event. Event will not do anything but add a record to the log
constructor() public { 
//when the contract is created, the constructor will be called automatically
balances[msg.sender] = 10000; 
//set the balances of creator account to be 10000. Please feel free to change it to any number you want.

}
function sendArt(address _receiver, uint _amount) public returns(bool sufficient) {
if (balances[msg.sender] < _amount) return false;  
// validate transfer
balances[msg.sender] -= _amount;
balances[_receiver] += _amount;
emit Transfer(msg.sender, _receiver, _amount); 
// complete coin transfer and call event to record the log
return true;
}
function getBalance(address _addr) public view returns(uint) { 
//balance check
return balances[_addr];
}
}