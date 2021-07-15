/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Doubler {
    address public owner;
    event Received(address _sender, uint _amount);
    event LogDouble(address _sender, uint _amount);
    mapping (address => uint) pendingWithdrawals;
    error IncorrectAmountOfEther();
    error NoContribution();
    error OutOfFunds();
    error MustWithdrawFirst();
    
    constructor() payable {
        require(msg.value > 0, "the contract must be funded with eth");
        owner = msg.sender;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function sendToContract() public payable {
        if (msg.value != 10000000000000000 wei) revert IncorrectAmountOfEther();
        if (pendingWithdrawals[msg.sender] == 20000000000000000) revert MustWithdrawFirst();
        pendingWithdrawals[msg.sender] = 20000000000000000;
    }
    
    function withdrawFromContract() public {
        uint _amountUserCanWithdraw = pendingWithdrawals[msg.sender];
        if (_amountUserCanWithdraw == 0) revert NoContribution();
        
        if (_amountUserCanWithdraw < address(this).balance) {
            pendingWithdrawals[msg.sender] = 0; // prevent reentrancy attack
            payable(msg.sender).transfer(_amountUserCanWithdraw);
            emit LogDouble(msg.sender, _amountUserCanWithdraw);
        } else {
            revert OutOfFunds();
        }
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function refillContract() public payable onlyOwner {
        require(msg.value > 0, "must include ether");
    }
    
    function drainContract() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "only the creator of the contract can call this function");
        _; 
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}