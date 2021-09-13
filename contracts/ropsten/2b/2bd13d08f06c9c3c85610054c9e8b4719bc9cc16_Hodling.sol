/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: GPL 3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodling{
    address payable my_address;
    uint start_time;
    
    constructor(){
        my_address = payable(msg.sender);
        start_time = block.timestamp;
    }
    
    function available_destory() public view returns(bool){
        if (block.timestamp - start_time > 365 days)
            return true;
        else
            return false;
    }
    
    function destory() external{
        if (available_destory()){
            selfdestruct(my_address);
        }
    }

}