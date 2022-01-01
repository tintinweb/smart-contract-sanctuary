/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract SimpleStorage {
    // 宣告一個區域變數
    uint public num;

    // 設定值
    function set(uint number) public {
        num = number;
    }

    // 取值
    function get() public view returns (uint) {
        return num;
    }
}