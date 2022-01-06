/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10 <0.9.0;

// 計算機合約
// 1. 加法
// 2. 減法
// 3. 乘法
// 4. 除法
contract Calc {
    int private result;

    // 加法
    function add(int a, int b) public returns (int c) {
        result = a + b;
        c = result;
    }

    // 減法
    function min(int a, int b) public returns (int) {
        result = a - b;
        return result;
    }

    // 乘法
    function mul(int a, int b) public returns (int) {
        result = a * b;
        return result;
    }

    // 除法
    function div(int a, int b) public returns (int) {
        result = a / b;
        return result;
    }

    // 取得儲存的結果值
    function getResult() public view returns (int) {
        return result;
    }
}