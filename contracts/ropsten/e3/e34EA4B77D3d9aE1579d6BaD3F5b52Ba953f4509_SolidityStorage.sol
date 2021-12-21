/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: SolodityStorage.sol

contract SolidityStorage {
    uint256 storeData = 5;

    function set(uint256 _x) public {
        storeData = _x;
    }

    function get() public view returns (uint256) {
        return storeData;
    }
}