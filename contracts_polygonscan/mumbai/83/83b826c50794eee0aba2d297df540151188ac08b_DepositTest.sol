/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

// SPDX-License-Identifier: KwstasG
pragma solidity ^0.8.7;

contract DepositTest {

    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
}