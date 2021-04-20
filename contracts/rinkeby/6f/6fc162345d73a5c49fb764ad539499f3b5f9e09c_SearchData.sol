/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;
contract SearchData{
    address public senderAddress;
    uint public blockNumber;
    
    function buy() public{
        senderAddress = msg.sender;
        blockNumber = block.number;
    }
}