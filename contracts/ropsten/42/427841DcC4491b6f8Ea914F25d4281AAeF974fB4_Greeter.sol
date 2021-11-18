/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/Greeter.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    constructor() {}

    function getMessage() public pure returns (string memory) {
        string memory message = "hi there";
        return message;
    }
}