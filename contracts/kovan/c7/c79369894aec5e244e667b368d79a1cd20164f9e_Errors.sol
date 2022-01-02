/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract Errors {

    function testRequire(uint _i) public pure {
        // Require 通常用於驗證一些值或是條件
        // 1.驗證傳入參數
        // 2.執行方法前, 驗證條件
        // 3.傳值給其他方法前, 先驗證其值
        require(_i > 10, "Input must be greater than 10");
    }

    function testRevert(uint _i) public pure {
        // Revert 基本上跟 Require 一樣,
        // 只它用在更複雜的條件檢查時, 相較於 Require 方便許多
        // 下面的用法與上面的結果是一樣的
        if (_i <= 10) {
            revert("Input must be greater than 10");
        }
    }

    uint public num;

    function testAssert() public view {
        // Assert 應該只用於驗證方法內部的錯誤, 和檢查不變量(invariants)
        // 這邊我們斷言 num 應該永遠為 0, 因為沒有其他方法能夠變更其值
        assert(num == 0);
    }

    // 自定義錯誤類別
    error InsufficientBalance(uint balance, uint withdrawAmount);

    function testCustomError(uint _withdrawAmount) public view {
        uint bal = address(this).balance;

        // 當提款金額小於當前餘額時觸發
        if (bal < _withdrawAmount) {
            revert InsufficientBalance({balance: bal, withdrawAmount: _withdrawAmount});
        }
    }
}