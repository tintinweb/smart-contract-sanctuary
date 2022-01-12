/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Executor {
    event Result(bool success, bytes result);

    function execute(address target, bytes memory data) external payable {
        // Make the function call
        (bool success, bytes memory result) = target.call{value: msg.value}(data);

        // success is false if the call reverts, true otherwise
        require(success, "Call failed");

        // result contains whatever has returned the function
        emit Result(success, result);
    }
}