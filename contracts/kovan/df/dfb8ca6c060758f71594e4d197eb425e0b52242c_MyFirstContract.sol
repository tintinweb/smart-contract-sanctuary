/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyFirstContract {

    event ReceivedMoneyEvent(address indexed _from, uint _amount);

    receive() external payable {

        emit ReceivedMoneyEvent(msg.sender, msg.value);

    }

}