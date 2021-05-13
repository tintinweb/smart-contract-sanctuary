/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

contract Bank {

    function saveMoney(address payable addr) public payable{
         addr.transfer(msg.value);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}