/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CellSubscription {
    uint256 public monthlyCost;
    address payable public receiver;

    event Received(address, uint);

    constructor() {
        monthlyCost = 26;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function isBalanceCurrent(uint256 monthsElapsed) public view returns (bool) {
        return monthlyCost * monthsElapsed == address(this).balance;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBalance(uint256 amount) public {
        require(address(this).balance >= amount, "Balance insufficient!");
        receiver.transfer(amount);
    }

    function sendEther(address payable _to) public payable {
        (bool sent,) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}