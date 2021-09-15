/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// "SPDX-License-Identifier: UNLICENSED" for non-open-source code. Please see https://spdx.org for more information.
pragma solidity ^0.8.7;

contract calculator {
    uint256 public number1;
    uint256 public number2;
    uint256 public number3;
    function sum(uint256 _number1, uint256 _number2) external returns(uint256) {
        number1 = _number1;
        number2 = _number2;
        number3 = number1 + number2;
        return number3;
    }
}