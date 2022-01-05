/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract UpdateOwner {
    string public a = "Playground labs";
    uint256 private password;
    address public owner;

    function updateOwner(address _owner) external {
        owner = _owner;
    }
}