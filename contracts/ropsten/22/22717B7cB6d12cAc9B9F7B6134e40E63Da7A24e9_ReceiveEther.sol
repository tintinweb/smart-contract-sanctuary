/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ReceiveEther{ // Contract Address 1: 0x9719afc965Afa4a0d51fC405365C3c8703808d7c
                       // Contract Address 2: 0x22717B7cB6d12cAc9B9F7B6134e40E63Da7A24e9

    address public MyAddress;
    uint256 public Balance;

    constructor(){
        MyAddress = msg.sender;
    }

    receive() payable external{
        Balance = Balance + msg.value; 
    }
}