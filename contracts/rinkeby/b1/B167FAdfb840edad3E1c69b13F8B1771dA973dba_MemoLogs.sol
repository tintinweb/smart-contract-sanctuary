/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: MemoLogs.sol

contract MemoLogs {
    event MemoLog(string message);
    event MemoWithTitle(string title, string message);

    function memo(string memory message) public {
        emit MemoLog(message);
    }

    function memoTitle(string memory title, string memory message) public {
        emit MemoWithTitle(title, message);
    }
}