/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL:3.0

pragma solidity ^0.8.0;

// my first project :)

/// @title first
/// @author Duke
contract MyFirst {
    string public name = "test";
    /// @notice this function changes the name of the name variable
    function updateName(string memory _newName) public {
        name = _newName;
    }
}