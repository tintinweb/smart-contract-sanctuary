/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

contract StakingContract {
    
    
    receive() external payable {

  	}

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    
}