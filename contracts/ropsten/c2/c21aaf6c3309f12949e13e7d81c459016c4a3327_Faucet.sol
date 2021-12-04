/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Faucet{
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000);
        //msg.sender.transfer;
        payable(msg.sender).transfer(withdraw_amount);
        
    }
    fallback () external payable{}
}