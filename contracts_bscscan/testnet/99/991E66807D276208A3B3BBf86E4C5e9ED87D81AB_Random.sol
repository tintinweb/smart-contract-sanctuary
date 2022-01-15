/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface Token {
    function balanceOf(address account) external view returns (uint256);
}

contract Random {
    function getRandom() external view returns (uint256) {
        address wbnb = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        address holder = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        uint256 value = Token(wbnb).balanceOf(holder);
        return value;
    }
}