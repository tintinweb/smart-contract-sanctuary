/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract SearchBlockData{
    address public sendAddress;
    uint public blockNumber;
    
    function buy() public payable{
        sendAddress = msg.sender;
        blockNumber = block.number;
    }
}