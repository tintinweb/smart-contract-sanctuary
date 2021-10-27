/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: MemoLogs.sol

contract MemoLogs {
    event MemoLog(string Memo);
    event MemoWithTitle(string Title, string Memo);
    event MemosWithTitle(string Title, string[] Memos);

    function memo(string memory memo_) public {
        emit MemoLog(memo_);
    }

    function memoWithTitle(string memory title, string memory memo_) public {
        emit MemoWithTitle(title, memo_);
    }

    function memosWithTitle(string memory title, string[] memory memos_)
        public
    {
        emit MemosWithTitle(title, memos_);
    }
}