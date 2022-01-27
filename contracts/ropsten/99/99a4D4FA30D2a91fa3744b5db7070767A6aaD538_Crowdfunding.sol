//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    address public owner;
    address[] public funders;
    mapping(address => uint256) addressToAmountFunded;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only contract owner can withdraw funds.");
        _;
    }

    function fund() payable public {
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function withDraw() payable public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}