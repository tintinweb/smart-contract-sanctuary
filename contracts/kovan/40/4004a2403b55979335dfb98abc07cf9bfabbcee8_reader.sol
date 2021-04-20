/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStorage {
    event change_value(uint256 value);
    function store(uint256) external;
    function retrieve() external view returns(uint256);
}

contract reader {
    IStorage t = IStorage(0x6740ACEd2d9358B78Df5bD7707E58f6be2831a3D);
    function readit() external view returns(uint256) {
        return t.retrieve();
    }
}