/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.6.9;

interface IQuota {
    function getUserQuota(address user) external view returns (int);
}

contract UserQuota is IQuota {

    mapping(address => uint256) public userQuota;
    
    event SetQuota(address user, uint256 amount);
    address public owner;
    constructor() public {
        owner = msg.sender;
    }

    function setUserQuota(address[] memory users, uint256[] memory quotas) external {
        require(msg.sender == owner, "Not owner");
        require(users.length == quotas.length, "PARAMS_LENGTH_NOT_MATCH");
        for(uint256 i = 0; i< users.length; i++) {
            require(users[i] != address(0), "USER_INVALID");
            userQuota[users[i]] = quotas[i];
        }
    }

    function getUserQuota(address user) override external view returns (int) {
        return int(userQuota[user]);
    }
}