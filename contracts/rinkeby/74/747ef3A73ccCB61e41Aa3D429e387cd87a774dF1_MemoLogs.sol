/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: MemoLogs.sol

contract MemoLogs {
    event MemoLog(string Message);
    event MemoWithTitle(string Title, string Message);
    event MemosWithTitle(string Title, string[] Messages);

    //event MemoLog2(string Title, string Message1, string Message2);
    //event MemoLog3(string Title, string Message1, string Message2, string Message3);

    function memo(string memory message) public {
        emit MemoLog(message);
    }

    function memoWithTitle(string memory title, string memory message) public {
        emit MemoWithTitle(title, message);
    }

    function memosWithTitle(string memory title, string[] memory messages)
        public
    {
        emit MemosWithTitle(title, messages);
    }
}