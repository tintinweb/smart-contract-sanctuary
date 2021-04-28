/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4 ;
contract Aesson{
    address public senderAddress;
    uint public blockNumber;
    uint public additionNum;
    uint public n=10;
    uint public value;
    function addition() public payable{
            senderAddress = msg.sender;
            blockNumber = block.number;
            value = msg.value;	
            additionNum = 0;
            for(uint i=0;i<=n;i++){
                additionNum = i + additionNum;
            }
                
        }

}