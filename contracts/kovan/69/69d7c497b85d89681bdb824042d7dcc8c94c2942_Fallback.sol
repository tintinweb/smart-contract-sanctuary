/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;


contract Fallback {
    event Log(uint gas);

    // fallback 函數必須宣告為 external 外部的
    // 宣告為 payable 則預設為可收款
    fallback() external payable {
        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)
        // 紀錄交易燃料餘額
        emit Log(gasleft());
    }

    // 取得餘額
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}