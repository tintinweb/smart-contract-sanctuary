// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Friends {

    address owner;

    receive() external payable {}
    fallback() external payable {}

    constructor(){
        owner = msg.sender;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner");
        address _this = address(this);
        payable(owner).transfer(_this.balance);
    }

    function investInYourself() public payable{
        payable(msg.sender).transfer(msg.value);
    }
}