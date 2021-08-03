// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./User.sol";

contract UserMapping is SuperAdmin {
    User users;

    constructor(address user_contract) {
        require(user_contract != address(0),"Contracts cannot be 0x address");
        users = User(user_contract);
    }

    struct UserMappingEntity {
        string userMappingId;
        string dataUserMapping;
        uint userId;
    }
    UserMappingEntity[] private userMappings;

    // create user mapping
    function addUserMapping(string memory userMappingId, string memory dataUserMapping) public {
        address sender = msg.sender;
        uint userId = users.getUserId(sender);
        userMappings.push(UserMappingEntity(userMappingId, dataUserMapping, userId));
    }

    // edit company
    function editUserMapping(string memory userMappingId, string memory dataUserMapping) public {
        uint i = iUserMapping(userMappingId);
        userMappings[i].dataUserMapping = dataUserMapping;
    }

    // get company detail by id
    function getUserMappingDetailById(string memory _userMappingId) view external onlySuperAdmin returns(string memory userMappingId, string memory dataUserMapping, uint userId) {
        uint i = iUserMapping(_userMappingId);
        userMappingId = userMappings[i].userMappingId;
        dataUserMapping = userMappings[i].dataUserMapping;
        userId = userMappings[i].userId;
    }

    // return id in array
    function iUserMapping(string memory userMappingId) private view returns(uint) {
        for (uint i = 0; i < userMappings.length; i++) {
            if (keccak256(abi.encodePacked(userMappings[i].userMappingId)) == keccak256(abi.encodePacked(userMappingId))) {
                return i;
            }
        }
        revert('User Mapping does not exist');
    }

    function getUserMappingId(address sender) view external returns(string memory) {
        uint userId = users.getUserId(sender);
        for (uint i = 0; i < userMappings.length; i++) {
            if (userMappings[i].userId == userId) {
                return userMappings[i].userMappingId;
            }
        }
        revert('User Mapping does not exist');
    }
}