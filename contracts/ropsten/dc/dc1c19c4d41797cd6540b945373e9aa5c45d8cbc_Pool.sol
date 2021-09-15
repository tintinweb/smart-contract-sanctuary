/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract Pool {

    uint public balanceReceived;
    address public sender;

    

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public {
        address payable to = payable(sender);
        to.transfer(getBalance());
    }

    function withdrawMoneyTo(address payable _to) public {
        _to.transfer(getBalance()*50/100);
    }
    
    function receiveMoney() public payable {
        balanceReceived += msg.value;
        sender = msg.sender;
        withdrawMoneyTo(payable(sender));
    }
}