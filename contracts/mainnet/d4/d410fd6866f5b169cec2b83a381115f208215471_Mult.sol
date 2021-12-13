/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IFactory {
    function withdraw(uint256 salt, address token, address receiver) external returns (address wallet);
}

contract Mult {
    function withdraw(address factory, uint[] memory salt, address token, address receiver) external {
        uint arrayLength = salt.length;

        for (uint i=0; i<arrayLength; i++) {
            IFactory(factory).withdraw(salt[i], token, receiver);
        }
    }
}