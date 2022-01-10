/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Funding {

    uint public totalAmount;
    uint public currentAmount;
    address payable owner;

    constructor() {
        totalAmount = 1000 ether;
        currentAmount = 0 ether;
        owner = payable(msg.sender);
    }

    function fund() public payable {
        require(msg.value >= 0.1 ether, "Must be greater than 0.1 ADA");
        currentAmount += msg.value;
    }

    function changeTotalAmount(uint amount) public {
        require(
            msg.sender == owner,
            "you are not an owner!"
            );
        totalAmount = amount;
    }


    function widthdrawFunds() public {
        require(
            msg.sender == owner,
            "You are not the owner!"
            );
        require(
            currentAmount >= totalAmount, "Target amount not reached yet"
        );
        owner.transfer(address(this).balance);
  }
}