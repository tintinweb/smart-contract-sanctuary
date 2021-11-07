// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

library SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b);
        return a - b;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
    }

    function div(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0);
        return a / b;
    }
}