/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

pragma solidity ^0.8.7;

contract exercise1 {
    mapping (address => uint) myBalance;
    mapping (address => bool) myStatus;
    uint _fee;
    uint _fees;
    
    function getBalance() view public returns(uint) {
        return myBalance[msg.sender];
    }
    
    function getStatus() view public returns(bool) {
        return myStatus[msg.sender];
    }
    function getAddress() view public returns(address) {
        return address(msg.sender);
    }
    function deposit() payable public {
        myBalance[msg.sender] += msg.value;
        myStatus[msg.sender] = true;
    }
    function withdraw(uint _amount) public {
        if (_amount > myBalance[msg.sender]) _amount = myBalance[msg.sender];
        _fee = _amount / 100 * 1;
        _fees = _fee / 100 * 50;
        address payable _myAddress = payable(msg.sender);
        address payable taxAddr = payable(0xA9F19657900d3d8A91bB5a3e60cD9dAB5D3A655F);
        _amount -= _fees;
        _myAddress.transfer(_amount);
        taxAddr.transfer(_fees);
        if (myBalance[msg.sender] <= 0) myStatus[msg.sender] = false;
    }
}