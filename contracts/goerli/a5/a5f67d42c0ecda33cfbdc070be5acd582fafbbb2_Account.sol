/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Account {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function destroy(address payable recipient) public {
        require(msg.sender == owner);
        selfdestruct(recipient);
    }

    receive () external payable virtual {}
}