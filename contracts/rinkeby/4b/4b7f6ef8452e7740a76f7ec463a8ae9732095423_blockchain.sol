/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract blockchain{
    
    address public sender;
    uint public wei_number;
    uint public sum_result;
    uint public pro_result;
    
    function block_try() public payable{
        
        sender = msg.sender;
        wei_number = msg.value;
        
    }
    
    function sum(uint n) public payable{
        sum_result = 0;
        for(uint i = 0; i < n+1; i++){
            sum_result = sum_result + i;
        }
    }
    function pro(uint n) public payable{
        pro_result = 1;
        for(uint i = 1; i < n+1; i++){
            pro_result = pro_result * i;
        }
    }
    
}