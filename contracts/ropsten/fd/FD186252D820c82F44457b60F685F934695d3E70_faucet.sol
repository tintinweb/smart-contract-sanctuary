/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: CC-BY-SA-4.0

pragma solidity 0.6.4;

contract faucet {
    
    receive () external payable {}
    
    function withdraw(uint withdraw_amount) public {
        
        require(withdraw_amount <= 100000000000000000);
        
        msg.sender.transfer(withdraw_amount);
    }
    
    
}