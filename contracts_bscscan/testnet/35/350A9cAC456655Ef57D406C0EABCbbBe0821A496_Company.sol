// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./User.sol";

contract Company {
    User users;

    constructor(address user_contract) {
        require(user_contract != address(0),"Contracts cannot be 0x address");
        users = User(user_contract);
    }

    struct CompanyEntity {
        string companyId;
        string dataCompany;
        string deleted; // default: n / y
    }
    CompanyEntity[] private companies;

    struct CompanyUser {
        string companyId; // key
        string userMappingId; // key
        string role;
        string permission; // default: viewer / edit
        string isOwner; // default: n / y
        string active; // default: n / y
    }
    CompanyUser[] private companyUsers;

    struct UserMappingEntity {
        string userMappingId;
        string dataUserMapping;
        uint userId;
    }
    UserMappingEntity[] private userMappings;

    // create company
    function addCompany(string memory companyId, string memory dataCompany, string memory userMappingId, string memory dataUserMapping) external {
        address sender = msg.sender;
        addOwnerToCompany(userMappingId, dataUserMapping, sender);
        companies.push(CompanyEntity(companyId, dataCompany, "n"));
        companyUsers.push(CompanyUser(companyId, userMappingId, "Admin", "edit", "y", "y"));
    }

    // edit company
    function editCompany(string memory companyId, string memory dataCompany) external {
        uint i = iCompany(companyId);
        companies[i].dataCompany = dataCompany;
    }

    // delete company
    function deleteCompany(string memory companyId) external {
        for (uint i = 0; i < companies.length; i++) {
            if ((keccak256(abi.encodePacked(companies[i].companyId)) == keccak256(abi.encodePacked(companyId))) &&
                (keccak256(abi.encodePacked(companies[i].deleted)) == keccak256(abi.encodePacked("n")))) {
                    companies[i].deleted = "y";
                    break;
            }
        }
    }

    // get company detail by id
    function getCompanyDetailById(string memory _companyId) view external returns (
        string memory companyId,
        string memory dataCompany,
        string memory deleted) {
        uint i = iCompany(_companyId);
        companyId = companies[i].companyId;
        dataCompany = companies[i].dataCompany;
        deleted = companies[i].deleted;
    }

    // get company user detail by companyId and user_sender0
    function getCompanyUserDetail(string memory _companyId, string memory _userMappingId) view external returns (
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory) {
        string memory companyId;
        string memory userMappingId;
        string memory role;
        string memory permission;
        string memory isOwner;
        string memory active;
        for (uint i = 0; i < companyUsers.length; i++) {
            if ((keccak256(abi.encodePacked(companyUsers[i].companyId)) == keccak256(abi.encodePacked(_companyId))) &&
                (keccak256(abi.encodePacked(companyUsers[i].userMappingId)) == keccak256(abi.encodePacked(_userMappingId)))) {
                companyId = companyUsers[i].companyId;
                userMappingId = companyUsers[i].userMappingId;
                role = companyUsers[i].role;
                permission = companyUsers[i].permission;
                isOwner = companyUsers[i].isOwner;
                active = companyUsers[i].active;
                break;
            }
        }
        return(companyId, userMappingId,role, permission, isOwner, active); 
    }

    // add multi-user to company
    function addMultiUserToCompany(UserMappingEntity[] memory _userMappingEntity, CompanyUser[] memory _companyUsers) external {
        for (uint i = 0; i < _userMappingEntity.length; i++) {
            userMappings.push(_userMappingEntity[i]);
        }
        for (uint i = 0; i < _companyUsers.length; i++) {
            companyUsers.push(_companyUsers[i]);
        }
    }

    // edit company user
    function editCompanyUser(string memory _companyId, string memory _userMappingId, string memory role, string memory permission) external {
        for (uint i = 0; i < companyUsers.length; i++) {
            if ((keccak256(abi.encodePacked(companyUsers[i].companyId)) == keccak256(abi.encodePacked(_companyId))) &&
                (keccak256(abi.encodePacked(companyUsers[i].userMappingId)) == keccak256(abi.encodePacked(_userMappingId)))) {
                companyUsers[i].role = role;
                companyUsers[i].permission = permission;
                break;
            }
        }
    }

    
    function changeActiveUser(string memory companyId, string memory userMappingId) external {
        for (uint i = 0; i < companyUsers.length; i++) {
            if ((keccak256(abi.encodePacked(companyUsers[i].companyId)) == keccak256(abi.encodePacked(companyId))) &&
                (keccak256(abi.encodePacked(companyUsers[i].userMappingId)) == keccak256(abi.encodePacked(userMappingId)))) {
                if (keccak256(abi.encodePacked(companyUsers[i].active)) == keccak256(abi.encodePacked("n"))) {
                    companyUsers[i].active = "y";
                    break;
                } else {
                    companyUsers[i].active = "n";
                    break;
                }
            }
        }
    }

    // remove user from company
    function removeUserFromCompany(string memory companyId, string memory userMappingId) external {
        for (uint i = 0; i < companyUsers.length; i++) {
            if ((keccak256(abi.encodePacked(companyUsers[i].companyId)) == keccak256(abi.encodePacked(companyId))) &&
                (keccak256(abi.encodePacked(companyUsers[i].userMappingId)) == keccak256(abi.encodePacked(userMappingId)))) {
                delete companyUsers[i];
            }
        }
    }

    // return id in array
    function iCompany(string memory companyId) private view returns(uint) {
        for (uint i = 0; i < companies.length; i++) {
            if (keccak256(abi.encodePacked(companies[i].companyId)) == keccak256(abi.encodePacked(companyId))) {
                return i;
            }
        }
        revert('Company does not exist');
    }

    // return true companyId - check valid companyId
    function findCompanyId(string memory companyId) external view returns(string memory) {
        for (uint i = 0; i < companies.length; i++) {
            if (keccak256(abi.encodePacked(companies[i].companyId)) == keccak256(abi.encodePacked(companyId))) {
                return companyUsers[i].companyId;
            }
        }
        revert('CompanyId does not exist');
    }


    // create user mapping original
    function addUserMapping(UserMappingEntity[] memory _userMappingEntity) external {
        for (uint i = 0; i < _userMappingEntity.length; i++) {
            userMappings.push(_userMappingEntity[i]);
        }
    }
    
    // create user mapping with address
    function addOwnerToCompany(string memory userMappingId, string memory dataUserMapping, address sender) private {
        uint userId = users.getUserId(sender);
        userMappings.push(UserMappingEntity(userMappingId, dataUserMapping, userId));
    }

    // edit company
    function editUserMapping(string memory userMappingId, string memory dataUserMapping, uint userId) external {
        uint i = iUserMapping(userMappingId);
        userMappings[i].dataUserMapping = dataUserMapping;
        userMappings[i].userId = userId;
    }

    // get company detail by id
    function getUserMappingDetailById(string memory _userMappingId) view external returns(string memory userMappingId, string memory dataUserMapping, uint userId) {
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