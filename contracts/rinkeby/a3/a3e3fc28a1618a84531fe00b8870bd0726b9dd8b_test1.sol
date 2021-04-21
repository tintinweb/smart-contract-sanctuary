/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
contract test1{
    address public senderAddress;
    uint public blockNumber;
    
    function search() public{
        senderAddress = msg.sender;
        blockNumber = block.number;
    }
}