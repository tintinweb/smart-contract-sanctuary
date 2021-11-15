// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Test {
    uint256 myNumber;
    address owner;

    constructor() {
        myNumber = 10;
        owner = msg.sender;
    }

    function getNumber() public view returns (uint256) {
        return myNumber;
    }

    function changeNumber(uint256 newValue) external {
        require(msg.sender == owner, "Only the owner can call this function");
        myNumber = newValue;
    }

}

