/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {

    string _message; // ตัวแปรที่จะ store ไว้ใน blockchain จะเสียค่า gas

    constructor(string memory message) {
        _message = message;
    }

    function Message() public view returns(string memory) {
        return _message;
    }

    function Hello() public pure returns(string memory) {
        return "Hello World";
    }
}