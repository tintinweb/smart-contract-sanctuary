/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.11;

contract UpdateOwner {
    string public a = "Playground labs";
    uint256 private immutable password;
    address public owner;

    constructor() {
        password = 0x1234;
    }

    function updateOwner(address _owner) external {
        owner = _owner;
    }
}