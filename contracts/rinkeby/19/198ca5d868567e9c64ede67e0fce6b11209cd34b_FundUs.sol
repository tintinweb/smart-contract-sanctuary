/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract FundUs {

    uint public totalAmount;
    uint public currentAmount;
    address payable owner;

    constructor() {
        totalAmount = 50 ether;
        currentAmount = 0 ether;
        owner = payable(msg.sender);
    }

    function fund() public payable {
        require(msg.value >= 0.001 ether, "Must be greater than 0.001 ETH");
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
        owner.transfer(address(this).balance);
  }
}