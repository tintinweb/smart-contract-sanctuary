/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract Bank {
    uint public goal;

    constructor(uint _goal) {
        goal = _goal;
    }

    receive() external payable {}

    function getMyBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public {
        if (getMyBalance() > goal) {
            selfdestruct(msg.sender);
        }
    }
}