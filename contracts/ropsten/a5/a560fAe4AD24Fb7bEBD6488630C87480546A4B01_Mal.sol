/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

// This code is hidden in a separate file
contract Mal {
    event Log(string message);

    fallback() external  {
        emit Log("Mal fallback was called");
    }

    // Actually we can execute the same exploit even if this function does
    // not exist by using the fallback
    function log() public {
        emit Log("Mal was called");
    }
}