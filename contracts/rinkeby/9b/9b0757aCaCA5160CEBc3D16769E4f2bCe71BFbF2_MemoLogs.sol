/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// File: MemoLogs.sol

contract MemoLogs {
    event MemoLog(string message);

    function memo(string memory message) public {
        //bytes memory bytesArray = new bytes(32);
        //for (uint256 i; i < 32; i++) {
        //    bytesArray[i] = message[i];
       // }
        //emit MemoLog(string(abi.encodePacked(message)));
        emit MemoLog(message);
    }

}