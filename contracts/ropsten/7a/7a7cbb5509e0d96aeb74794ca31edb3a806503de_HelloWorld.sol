/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {

    address owner;
    string text;

    constructor () {
        owner = msg.sender;
        text = "Hello World";
    }

    function setText(string memory newText) public {
        require(owner == msg.sender);
        text = newText;
    }

    function getText() public view returns (string memory) {
        return text;
    }

    function giveOwnership(address newOwner) public {
        require(owner == msg.sender);
        owner = newOwner;
    }
}