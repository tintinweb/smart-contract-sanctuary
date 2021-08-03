/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

contract Hello {

    constructor() {
    }

    function hello() external pure returns (string memory) {
        return "Hello World";
    }

}