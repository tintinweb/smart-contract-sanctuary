/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LucasDemo {
    uint256 public total;
    
    constructor(uint256 num){
        total = num;
    }
    
    receive() external payable {}

    
    function getBalance() public view returns(uint256){
        
        return address(this).balance;
    }
    
        
    function withdraw() private {
        if(getBalance() > total){
            selfdestruct(payable(msg.sender));
        }
    }
    
}