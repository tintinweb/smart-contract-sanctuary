/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract RetailMapping {

    mapping(address => address[]) public userMap;

    event UpdateMapping(address indexed from_);

    function updateMapping(address[] calldata toArray_) external {
        delete userMap[msg.sender];
        for (uint256 i = 0; i < toArray_.length; ++i) {
            if (toArray_[i] == msg.sender) {
                continue;
            }

            bool contains = false;
            for (uint256 j = 0; j < userMap[msg.sender].length; ++j) {
                if (userMap[msg.sender][j] == toArray_[i]) {
                    contains = true;
                    break;
                }
            }

            if (contains) {
                continue;
            }
            
            userMap[msg.sender].push(toArray_[i]);
        }
        
        emit UpdateMapping(msg.sender);
    }
}