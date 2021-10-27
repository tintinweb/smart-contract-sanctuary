/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// File: simplestorage.sol

contract SimpleStorage {
    uint256 favouriteNumber;

    function store(uint256 _number) public {
        favouriteNumber = _number;
    }

    function retrive() public view returns (uint256) {
        return favouriteNumber;
    }
}