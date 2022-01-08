//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NFTStorage {
    string[] public nftStorage = ["1", "2", "3", "4", "5"];

    function getArrayLength() external view returns(uint256) {
        return nftStorage.length;
    }
}