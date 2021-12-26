/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.1;

contract SendMoneyExample {

    uint public balanceReceived;

    function receiveMoney() public payable {
            balanceReceived += msg.value;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());

    }

    function withdrawMoneyTo(address payable _to) public {
        _to.transfer(getBalance());
    }
}