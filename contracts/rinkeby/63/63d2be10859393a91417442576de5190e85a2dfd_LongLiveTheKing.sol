/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-v2-or-later
pragma solidity ^0.8.2;

contract LongLiveTheKing {
    address payable immutable owner;
    constructor(address payable _owner) {
        owner = _owner;
    }

    function contribute(address payable king) external payable {
        king.transfer(msg.value);
    }
    function abdicate() external {
        selfdestruct(owner);
    }
    receive() external payable {
        revert();
    }
}