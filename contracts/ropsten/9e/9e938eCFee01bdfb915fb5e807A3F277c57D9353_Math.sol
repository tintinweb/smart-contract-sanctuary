/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Math {
    event Added(uint256 a, uint256 b, uint256 c);
    event Multiplied(uint256 a, uint256 b, uint256 c);
    address public master;
    address public owner;

    constructor() {
        master = address(this);
        owner = msg.sender;
    }

    uint256 public newAddedNumber;
    uint256 public newMultiplidNumber;

    function add(uint256 a, uint256 b) external returns (uint256) {
        newAddedNumber = a + b;
        emit Added(a, b, newAddedNumber);
        return newAddedNumber;
    }

    function mul(uint256 a, uint256 b) external returns (uint256) {
        emit Multiplied(a, b, a * b);
        return a * b;
    }
}