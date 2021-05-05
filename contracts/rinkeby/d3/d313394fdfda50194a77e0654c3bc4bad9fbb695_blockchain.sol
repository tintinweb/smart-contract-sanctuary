/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract blockchain{
    address public sender_address;
    uint public block_number;
    uint public wei_value;
    uint public s;
        
    function query() public payable{
        sender_address = msg.sender;
        block_number = block.number;
        wei_value = msg.value;
        
    }
    function sum(uint n) public payable{
        uint i;
        s = 0;
        for(i = 0; i < n+1; i++){
            s = s + i;
        }
    }

}