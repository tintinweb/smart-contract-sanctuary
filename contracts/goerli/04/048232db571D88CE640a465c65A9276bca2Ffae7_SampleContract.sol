/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract SampleContract {
    constructor() {}

    function freeInteraction() public {}

    function paidInteraction() public payable {
        require(msg.value == 0.00005 ether, "invalid amount supplied");
    }
}