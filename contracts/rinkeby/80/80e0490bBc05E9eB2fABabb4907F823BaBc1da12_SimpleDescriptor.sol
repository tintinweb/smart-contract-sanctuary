/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

contract SimpleDescriptor {
    string public desc;

    constructor() {
        desc = 'test';
    }

    function setDesc(string calldata _desc) public {
        desc = _desc;
    }
}