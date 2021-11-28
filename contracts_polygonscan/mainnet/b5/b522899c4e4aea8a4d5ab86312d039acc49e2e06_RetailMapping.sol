/**
 *Submitted for verification at polygonscan.com on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract RetailMapping {

    mapping(address => address[]) userMap;

    event UpdateMapping(address indexed from_);

    function updateMapping(address[] calldata toArray_) external {
        delete userMap[msg.sender];
        for (uint256 i = 0; i < toArray_.length; ++i) {
            userMap[msg.sender].push(toArray_[i]);
        }

        emit UpdateMapping(msg.sender);
    }
}