/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.1;
contract work{
    address public senderAddress;
    uint public blockNumber;
    
    function buy() public payable{
        senderAddress = msg.sender;
        blockNumber = block.number;
    }
}