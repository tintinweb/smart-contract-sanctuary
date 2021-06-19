/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    string public user_name;
    address payable public user_address;
    uint256 start_time;
    constructor(string memory name){
        user_name = name;
        user_address = payable(msg.sender);
        start_time = block.timestamp;
    }
    
    fallback() external payable{
        
    }
    
    receive() external payable{
        
    }
    
    function Destroy() external{
        if(block.timestamp >= start_time + 365  * 1 days){
            selfdestruct(user_address);
        }

        
    }
}