/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

// 可付款的合約
contract Payable {
    // 宣告 payable 的地址可以接收乙太幣
    address payable public owner;

    // 宣告 payable 的建構函式讓 Owner 可接收乙太幣
    constructor() payable {
        owner = payable(msg.sender);
    }

    // 存乙太幣進入此合約的函數
    // 用一些乙太幣使用此函數後, 合約內的餘額將會變動
    function deposit() public payable {}

    // 用一些乙太幣使用此函數後, 此函數會丟出錯誤
    // (因為已宣告此合約為可付款的)
    function notPayable() public {}

    // Owner 用來從合約提款的函數
    function withdraw() public {
        // 取得此合約的餘額
        uint amount = address(this).balance;

        // 將合約中的餘額發送給 Owner
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // 將指定金額發送給指定地址
    function transfer(address payable _to, uint _amount) public {
        // 需要注意的是 _to 地址變數有宣告為 payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
}