/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PiggyBank {
    uint public goal;

    constructor(uint _goal) {
        goal = _goal;
    }

    receive() external payable {}

    function getMyBalance() public view returns (uint) {
        return address(this).balance;
    }

// deposit
// withdraw

    function withdraw() public {
        if(getMyBalance() > goal) {
            selfdestruct(payable(msg.sender));
        }
    }
}