//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract NDepositV1 {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
    }

    function withdraw() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}