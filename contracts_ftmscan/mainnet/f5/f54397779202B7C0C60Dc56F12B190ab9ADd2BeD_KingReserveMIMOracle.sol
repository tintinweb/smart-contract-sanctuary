// SPDX-License-Identifier: MIT

// 0xRektora

pragma solidity ^0.8.0;

contract KingReserveMIMOracle {
    function getExchangeRate(uint256 amount) external pure returns (uint256) {
        return amount - (amount * 10) / 100;
    }
}