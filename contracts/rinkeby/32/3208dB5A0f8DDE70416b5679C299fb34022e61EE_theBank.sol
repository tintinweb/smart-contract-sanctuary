/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract theBank {
    
    mapping(address => uint) public isVerified;
    
    uint private balance;
    
    bool public bankLockStatus;
    
    constructor() {
        bankLockStatus = false;
        isVerified[msg.sender] = 1;
    }
    
    function deposit() payable public {
        balance += msg.value;
    }
    
    function withdrawl(uint _weiAmount) public {
        require(isVerified[msg.sender] >= 1);
        require(_weiAmount <= balance);
        balance -= _weiAmount;
        payable(msg.sender).transfer(_weiAmount);
    }
    
    function verifiy() public {
        require(!bankLockStatus);
        isVerified[msg.sender] = 1;
    }
    
    function lockBank() public {
        require(!bankLockStatus);
        require(isVerified[msg.sender] >= 1);
        bankLockStatus = true;
    }
    
    function unlockBank() public {
        require(bankLockStatus);
        require(isVerified[msg.sender] >= 1);
        bankLockStatus = false;
    }

}