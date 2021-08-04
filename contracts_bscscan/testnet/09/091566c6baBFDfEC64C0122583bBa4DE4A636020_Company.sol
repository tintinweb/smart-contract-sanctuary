// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./UserMapping.sol";

contract Company is SuperAdmin {
    UserMapping userMappings;

    constructor(address userMapping_contract) {
        require(userMapping_contract != address(0),"Contracts cannot be 0x address");
        userMappings = UserMapping(userMapping_contract);
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

    // create company
    function addCompany(string memory companyId, string memory dataCompany, string memory userMappingId, string memory dataUserMapping) public {
        address sender = msg.sender;
        userMappings.addUserMappingCompany(userMappingId, dataUserMapping, sender);
        companies.push(CompanyEntity(companyId, dataCompany, "n"));
        companyUsers.push(CompanyUser(companyId, userMappingId, "Admin", "edit", "y", "y"));
    }

    // edit company
    function editCompany(string memory companyId, string memory dataCompany) public {
        uint i = iCompany(companyId);
        companies[i].dataCompany = dataCompany;
    }

    // delete company
    function deleteCompany(string memory companyId) public {
        for (uint i = 0; i < companies.length; i++) {
            if ((keccak256(abi.encodePacked(companies[i].companyId)) == keccak256(abi.encodePacked(companyId))) &&
                (keccak256(abi.encodePacked(companies[i].deleted)) == keccak256(abi.encodePacked("n")))) {
                    companies[i].deleted = "y";
                    break;
            }
        }
        revert('Can not delete company');
    }

    // get company detail by id
    function getCompanyDetailById(string memory _companyId) view external onlySuperAdmin returns(
        string memory companyId,
        string memory dataCompany,
        string memory deleted) {
        uint i = iCompany(_companyId);
        companyId = companies[i].companyId;
        dataCompany = companies[i].dataCompany;
        deleted = companies[i].deleted;
    }

    // get company user detail by companyId and user_sender0
    function getCompanyUserDetail(string memory _companyId) view external returns(
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
        address sender = msg.sender;
        string memory _userMappingId = userMappings.getUserMappingId(sender);
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
    function addMultiUserToCompany(CompanyUser[] memory _companyUsers) public {
        for (uint i = 0; i < _companyUsers.length; i++) {
            companyUsers.push(_companyUsers[i]);
        }
    }

    // edit company user
    function editCompanyUser(string memory companyId, string memory userMappingId, string memory role, string memory permission) public {
        for (uint i = 0; i < companyUsers.length; i++) {
            if ((keccak256(abi.encodePacked(companyUsers[i].companyId)) == keccak256(abi.encodePacked(companyId))) &&
                (keccak256(abi.encodePacked(companyUsers[i].userMappingId)) == keccak256(abi.encodePacked(userMappingId)))) {
                companyUsers[i].role = role;
                companyUsers[i].permission = permission;
            }
        }
        revert('Can not edit company user');
    }

    
    function changeActiveUser(string memory companyId, string memory userMappingId) public {
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
        revert('Can not active/inactive user from company');
    }

    // remove user from company
    function removeUserFromCompany(string memory companyId, string memory userMappingId) public {
        for (uint i = 0; i < companyUsers.length; i++) {
            if ((keccak256(abi.encodePacked(companyUsers[i].companyId)) == keccak256(abi.encodePacked(companyId))) &&
                (keccak256(abi.encodePacked(companyUsers[i].userMappingId)) == keccak256(abi.encodePacked(userMappingId)))) {
                delete companyUsers[i];
            }
        }
        revert('Can not remove user from company');
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
}