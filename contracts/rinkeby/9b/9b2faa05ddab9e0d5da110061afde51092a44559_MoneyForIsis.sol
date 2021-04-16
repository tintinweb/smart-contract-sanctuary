/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MoneyForIsis {

    uint256 id; 
    mapping(uint256=> UserBalance) userbalances;
    
    struct UserBalance {
        address recipient; 
        uint256 expectedDate;
        uint256 balance;
    }
    
    

    function sendMoney(address recipient, uint256 expectedDate) external payable {
        userbalances[id] = UserBalance(recipient, expectedDate, msg.value);
        id++;
        
    } 
    
    function retrieveMoney(uint256 id) external { 
        UserBalance memory userbalance = userbalances[id]; 
        require(block.number >= userbalance.expectedDate,"too soon too soon");
        require(msg.sender==userbalance.recipient);
        payable(userbalance.recipient).transfer(userbalance.balance);
    }

}