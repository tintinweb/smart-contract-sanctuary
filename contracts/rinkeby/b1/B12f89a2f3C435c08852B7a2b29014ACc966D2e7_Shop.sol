/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract Shop {
    address private owner;
    constructor(){
        owner = msg.sender;
    }
    modifier checkMaster(){
        require(msg.sender == owner,"[001] Sorry, you are not allowed");
        _;
    }
    event new_payment(string itemID, uint amount);
    function payment(string memory itemID) public payable {
        require(msg.value>0,"[002] Money must not be zero");
        emit new_payment(itemID, msg.value);
    }
    function withdraw(address user) public checkMaster {
        require(address(this).balance > 0,"[003] Sorry, do not have money to withdraw");
        payable(user).transfer(address(this).balance);
    }
}