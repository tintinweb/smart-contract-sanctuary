/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract DummyController {
    function withdraw(address vault, uint amount) external {}
    function earn(address vault, uint amount) external {}
    function want(address vault) external view returns (address) {
        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
    function balanceOf(address vault) external view returns (uint) {
        return 0;
    }
}