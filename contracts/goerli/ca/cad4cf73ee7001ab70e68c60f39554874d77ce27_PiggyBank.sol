/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.8.0;

contract PiggyBank {

    uint public goal;
    constructor (uint _goal) {
        goal = _goal;
    }

    receive() external payable {}

    function getMyBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withDraw() public {
        if ( getMyBalance() > goal) {
            selfdestruct(msg.sender);   // 銷毀合約並把錢轉給msg.sender
        }
    }
}