/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract Echo {
    function echo(string memory message) public pure returns (string memory) {
        return message;
    }
}