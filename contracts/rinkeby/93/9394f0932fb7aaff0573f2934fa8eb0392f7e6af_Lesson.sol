/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;                 //版本宣告(需與編譯器版本相同)
contract Lesson{                        //宣告合約名稱
    
    address public senderAddress;
    uint public blockNumber;
    
    function search() public payable{
        senderAddress = msg.sender;     //消息發送者(呼叫該合約的address)
        blockNumber = block.number;     //當前區塊編號
    }
}