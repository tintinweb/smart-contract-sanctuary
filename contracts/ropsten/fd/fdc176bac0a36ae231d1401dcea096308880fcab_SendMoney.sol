/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract SendMoney {
    
    uint public activeBalance;
    uint public nextWithdrawTime;
    
    function receiveMoney() public payable {
        activeBalance += msg.value;
        nextWithdrawTime = block.timestamp + 1 minutes;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function withdrawMoney() public {
        if (nextWithdrawTime < block.timestamp) {
            address payable toAddress = payable(msg.sender);
            activeBalance -= getBalance();
            toAddress.transfer(getBalance());
        }
    }
    
    function withdrawMoneyTo(address payable _to) public {
        if (nextWithdrawTime < block.timestamp) {
            activeBalance -= getBalance();
            _to.transfer(getBalance());
        }

    }
}