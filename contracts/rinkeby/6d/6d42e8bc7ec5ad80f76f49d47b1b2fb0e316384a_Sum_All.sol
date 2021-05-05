/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Sum_All
{
    address public address_sender;
    uint public value_sender;
    
    function sum_all(uint input_n) public payable
    {
        uint sum = 0;
        for(uint i = 1; i <= input_n; i ++)
        {
            sum += i;
        }
        value_sender = msg.value;
        address_sender = msg.sender;
    }
}