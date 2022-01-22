/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Faucet{

    receive() external payable {}

    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000, "Can't withdraw more than 0.1 eth");

        payable(msg.sender).transfer(withdraw_amount);
    }
}