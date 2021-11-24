/**
 *Submitted for verification at polygonscan.com on 2021-11-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract NameMemory {
    string private name;

    constructor(string memory _name) {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function setName(string memory _name) public {
        name = _name;
    }
}