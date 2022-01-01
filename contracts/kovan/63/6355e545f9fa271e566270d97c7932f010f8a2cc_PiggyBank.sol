/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

// 小豬撲滿合約
// 1. 建立合約時可以設定儲蓄目標
// 2. 能查詢儲蓄目標
// 3. 能查詢當前儲蓄金額
// 4. 能收取 ether
// 5. 提領時, 儲蓄的總金額需大於儲蓄目標, 並銷毀撲滿
contract PiggyBank {
    // 可供查詢的儲蓄目標
    uint public _goal;

    // 建構函式
    constructor(uint goal) {
        // 建立合約時設定儲蓄目標
        _goal = goal;
    }

    // 取得目前儲蓄金額
    function getMyBalance() public view returns(uint) {
        return address(this).balance;
    }

    // 外部呼叫的收款方法
    receive() external payable {}

    // 提款方法
    function withdraw() public {
        // 當儲蓄的總金額大於儲蓄目標時, 提款後, 銷毀合約
        if (getMyBalance() > _goal) {
            // 銷毀合約
            selfdestruct(msg.sender);
        }
    }

    
}