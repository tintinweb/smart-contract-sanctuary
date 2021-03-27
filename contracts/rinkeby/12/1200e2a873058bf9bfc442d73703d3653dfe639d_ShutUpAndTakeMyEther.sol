/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: GPL-v2-or-later
pragma solidity ^0.8.2;

contract ShutUpAndTakeMyEther {
    function bequeath(address payable target) payable external {
        (bool result, bytes memory data) = target.call{value: msg.value}("");
        result; data; // or not; I don't care
    }
}