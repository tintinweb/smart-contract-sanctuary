// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract ReceiveTest {
    event Received(uint256 amount, address from);
    
    receive() external payable {
        emit Received(msg.value, msg.sender);
    }
   
   function getBalance() external view returns (uint256 balance) {
       return address(this).balance;
   }
   
}