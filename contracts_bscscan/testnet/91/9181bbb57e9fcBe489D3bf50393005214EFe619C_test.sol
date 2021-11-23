/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

pragma solidity ^0.8.7;

contract test {
    mapping (address => uint256) myBalance;
    
    function getBalance() view public returns(uint256) {
        return myBalance[msg.sender];
    }
    function myAddress() view public returns(address) {
        return msg.sender;
    }
    function deposit() payable public {
        myBalance[msg.sender] += msg.value;
    }
    function withdraw(address payable _to, uint _amount) public {
        if (_amount > myBalance[msg.sender]) _amount = myBalance[msg.sender];
        myBalance[msg.sender] -= _amount;
        _to.transfer(_amount);
    }
    function getContractBalance() view public returns(uint) {
        return address(this).balance;
    }
}