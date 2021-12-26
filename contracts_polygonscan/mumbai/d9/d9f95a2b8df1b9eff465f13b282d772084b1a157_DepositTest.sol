/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

// SPDX-License-Identifier: KwstasG
pragma solidity ^0.8.7;

contract DepositTest {

    event Deposited(address sender, uint256 weiAmount);

    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        emit Deposited(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
}