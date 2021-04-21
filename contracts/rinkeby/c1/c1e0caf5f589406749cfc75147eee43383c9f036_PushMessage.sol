/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
contract PushMessage{
    uint public msgvalue;
    uint public timestamp;
    
    function buy() public payable{
        msgvalue = msg.value;
        timestamp = block.timestamp;
    }
}