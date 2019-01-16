pragma solidity ^0.5.2;
contract HelloCoin {
string public name = &#39;HelloCoin&#39;; 
//currency name. Please feel free to change it
string public symbol = &#39;hc&#39;; 
//choose a currency symbol. Please feel free to change it
mapping (address => uint) balances; 
//a key-value pair to store addresses and their account balances
event Transfer(address _from, address _to, uint256 _value); 
// declaration of an event. Event will not do anything but add a record to the log
constructor() public { 
//when the contract is created, the constructor will be called automatically
balances[msg.sender] = 10000; 
//set the balances of creator account to be 10000. Please feel free to change it to any number you want.
}
function sendCoin(address _receiver, uint _amount) public returns(bool sufficient) {
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