/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// author: niveyno

contract Splitter {
    address private _wallet1 = 0x9dB8922f8044d4cFE9C361b53C149fD5D63d90f9;
    address private _wallet2 = 0x4502F16e0Aa869EA9AAdC7f941e3dE472Af94100;

    fallback() external payable {
        bool success = false;
        (success,) = _wallet1.call{value : msg.value * 95 / 100}("");
        require(success, "Failed to send1");

        bool success2 = false;
        (success2,) = _wallet2.call{value : msg.value * 5 / 100}("");
        require(success2, "Failed to send2");
    }
}