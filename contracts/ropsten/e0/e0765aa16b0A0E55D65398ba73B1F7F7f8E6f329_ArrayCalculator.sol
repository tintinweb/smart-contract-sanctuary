/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

interface iCalculator {
    function add(int _a, int _b) external pure returns(int);
    function mul(int _a, int _b) external pure returns(int);
}

contract ArrayCalculator {
    address calculator_address;

    constructor(address _calculator_address) {
        calculator_address = _calculator_address;
    }

    function countSum(int[] memory arr) public view returns(int) {
        int sum = 0;
        for (uint i = 0; i < arr.length; ++i) {
            sum = iCalculator(calculator_address).add(sum, arr[i]);
        }
        return sum;
    }

    function countMul(int[] memory arr) public view returns(int) {
        int res = 1;
        for (uint i = 0; i < arr.length; ++i) {
            res = iCalculator(calculator_address).mul(res, arr[i]);
        }
        return res;
    }
}