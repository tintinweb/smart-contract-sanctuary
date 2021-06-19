/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity ^0.5.13;

contract FunctionsExample {
    
    mapping(address => uint) public balanceRecieved;
    
    function recieveMoney() public payable {
        assert(balanceRecieved[msg.sender] + msg.value >= balanceRecieved[msg.sender]);
        balanceRecieved[msg.sender] += msg.value;
    }
    
    function withdrawMoney(address payable _to, uint _amount) public {
        require(_amount <= balanceRecieved[msg.sender], "not enough funds.");
        assert(balanceRecieved[msg.sender] >= balanceRecieved[msg.sender] - _amount);
        balanceRecieved[msg.sender] -= _amount;
        _to.transfer(_amount);
    }
    
    function () external payable{
        recieveMoney();
    }
}