/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyHodl{
    uint256 start_time;
    uint256 balance;
    address payable private owner;
    constructor(){
      start_time = block.timestamp;
      owner = payable(msg.sender);
     }

    
    
    fallback() external payable {
    }
        
    receive() external payable {
    }
    
    function MyBalance() external view returns(uint256){
        return balance;
    }
    
    function Transfer(uint256 num) external returns(uint256){
        balance += num;
        return balance;
    }
    
    function WithdrawAll() external{
        
        //you have to hodl at least 365 days(one year) to WithdrawAll from this contract
        if(block.timestamp >= start_time + 365 * 1 days){
            selfdestruct(owner); 
        } 
         
        
    }
}