pragma solidity ^0.4.18;
contract Pimp {
string public name = &#39;Pimp Token&#39;; 
string public symbol = &#39;pt&#39;; 
mapping (address => uint) balances; 
event Transfer(address _from, address _to, uint256 _value); 
function Pimp()  { 
balances[msg.sender] = 50000; 

}
function sendCoin(address _receiver, uint _amount) public returns(bool sufficient) {
if (balances[msg.sender] < _amount) return false;  
balances[msg.sender] -= _amount;
balances[_receiver] += _amount;
Transfer (msg.sender, _receiver, _amount); 
return true;
}
function getBalance(address _addr) public view returns(uint) { 
return balances[_addr];
}
}