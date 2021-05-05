/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;                 //版本宣告(需與編譯器版本相同)
contract Lesson{                        //宣告合約名稱
    
    address public senderAddress;
    uint public value;
    uint public ans;
    uint private x;
    
    
    function computeN(uint n) public payable{
        senderAddress = msg.sender;     //消息發送者(呼叫該合約的address)
        value = msg.value;              //隨著交易發送的wei的數量
        x=1;
        do {
            ans += x;
            x+=1;
        } while (x <= n);
    }
}