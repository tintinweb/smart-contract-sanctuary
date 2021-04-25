/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HODL{
    address payable HODL_addess;
    uint256 HODL_balance;
    uint256 mature_time;
    
    constructor(uint256 mature_date){
        HODL_addess = payable(msg.sender);
        uint256 mature_seconds = mature_date * 24 * 60 * 60;
        mature_time = block.timestamp + mature_seconds;
    }
    
    function get_balance() public view returns(uint256){
        return address(this).balance;
    }
    
    function remain_time() public view returns(uint256){
        if(block.timestamp < mature_time){
            return mature_time - block.timestamp;
        }else{
            return 0;
        }
    }
    
    function end_contract() public payable{
        if(block.timestamp >= mature_time){
            selfdestruct(HODL_addess);
        }
    }
    
    
    fallback() external payable {
    }
    
    receive() external payable {
    }
}