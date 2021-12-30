/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Token {

    address private owner;
    uint256 users;

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    function addName(uint256 name) public{
        require(msg.sender == owner, "owner only");
        users = name;
    }

    function get() public view returns (uint256){
        return users;
    }

}