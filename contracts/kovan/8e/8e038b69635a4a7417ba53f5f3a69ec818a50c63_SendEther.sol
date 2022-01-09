/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract SendEther {

    // 用 Transfer 發送
    function sendViaTransfer(address payable _to) public payable {
        // 不要再使用此函數來發送乙太幣
        _to.transfer(msg.value);
    }

    // 用 Send 發送
    function sendViaSend(address payable _to) public payable {
        // 回傳 boolean 代表成功或失敗
        // 不要再使用此函數來發送乙太幣
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");
    }

    // 用 Call 發送
    function sendViaCall(address payable _to) public payable {
        // 回傳 boolean 代表成功或失敗
        // 目前最推薦發送乙太幣的函數
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}