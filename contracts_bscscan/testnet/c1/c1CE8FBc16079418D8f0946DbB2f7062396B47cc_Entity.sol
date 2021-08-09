// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Company.sol";

contract Entity {
    Company companies;

    constructor(address company_contract) {
        require(company_contract != address(0),"Contracts cannot be 0x address");
        companies = Company(company_contract);
    }

    struct Entities {
        string entityId;
        string companyId;
        string dataEntity;
        string deleted; // default: n / y
    }
    Entities[] private entities;

    struct EntityUser {
        string entityId; // key
        string userMappingId; // key
        string role;
        string permission; // default: viewer / edit
        string isOwner; // default: n / y
        string active; // default: n / y
    }
    EntityUser[] private entityUsers;

    // create entity
    function addEntity(string memory entityId, string memory _companyId, string memory dataEntity) external {
        string memory companyId = companies.findCompanyId(_companyId);
        address sender = msg.sender;
        string memory userMappingId = companies.getUserMappingId(sender);
        entities.push(Entities(entityId, companyId, dataEntity, "n"));
        entityUsers.push(EntityUser(entityId, userMappingId, "Admin", "edit", "y", "y"));
    }

    // edit entity
    function editEntity(string memory entityId, string memory dataEntity) external {
        uint i = iEntity(entityId);
        entities[i].dataEntity = dataEntity;
    }

    // delete entity
    function deleteEntity(string memory entityId) external {
        for (uint i = 0; i < entities.length; i++) {
            if ((keccak256(abi.encodePacked(entities[i].entityId)) == keccak256(abi.encodePacked(entityId))) &&
                (keccak256(abi.encodePacked(entities[i].deleted)) == keccak256(abi.encodePacked("n")))) {
                    entities[i].deleted = "y";
                    break;
            }
        }
    }

    // get entity detail by id
    function getEntityDetailById(string memory _entityId) view external returns(
        string memory entityId,
        string memory companyId,
        string memory dataEntity,
        string memory deleted) {
        uint i = iEntity(_entityId);
        entityId = entities[i].entityId;
        companyId = entities[i].companyId;
        dataEntity = entities[i].dataEntity;
        deleted = entities[i].deleted;
    }

    // get companyId of entity
    function getCompanyIdByEntityId(string memory _entityId) external view returns(string memory) {
        uint i = iEntity(_entityId);
        return entities[i].companyId;
    }

    // get entity user detail by entityId and user_sender
    function getEntityUserDetail(string memory _entityId, string memory _userMappingId) view external returns(
        string memory,
        string memory,
        string memory,
        string memory,
        string memory,
        string memory) {
        string memory entityId;
        string memory userMappingId;
        string memory role;
        string memory permission;
        string memory isOwner;
        string memory active;
        for (uint i = 0; i < entityUsers.length; i++) {
            if ((keccak256(abi.encodePacked(entityUsers[i].entityId)) == keccak256(abi.encodePacked(_entityId))) &&
                (keccak256(abi.encodePacked(entityUsers[i].userMappingId)) == keccak256(abi.encodePacked(_userMappingId)))) {
                entityId = entityUsers[i].entityId;
                userMappingId = entityUsers[i].userMappingId;
                role = entityUsers[i].role;
                permission = entityUsers[i].permission;
                isOwner = entityUsers[i].isOwner;
                active = entityUsers[i].active;
                break;
            }
        }
        return(entityId, userMappingId, role, permission, isOwner, active);
    }

    // add multi-user to entity
    function addMultiUserToEntity(EntityUser[] memory _entityUsers) external {
        for (uint i = 0; i < _entityUsers.length; i++) {
            entityUsers.push(_entityUsers[i]);
        }
    }

    // edit entity user
    function editEntityUser(string memory entityId, string memory userMappingId, string memory role, string memory permission) external {
        for (uint i = 0; i < entityUsers.length; i++) {
            if ((keccak256(abi.encodePacked(entityUsers[i].entityId)) == keccak256(abi.encodePacked(entityId))) &&
                (keccak256(abi.encodePacked(entityUsers[i].userMappingId)) == keccak256(abi.encodePacked(userMappingId)))) {
                entityUsers[i].role = role;
                entityUsers[i].permission = permission;
                break;
            }
        }
    }

    // active / inactive user
    function changeActiveUser(string memory entityId, string memory userMappingId) external {
        for (uint i = 0; i < entityUsers.length; i++) {
            if ((keccak256(abi.encodePacked(entityUsers[i].entityId)) == keccak256(abi.encodePacked(entityId))) &&
                (keccak256(abi.encodePacked(entityUsers[i].userMappingId)) == keccak256(abi.encodePacked(userMappingId)))) {
                if (keccak256(abi.encodePacked(entityUsers[i].active)) == keccak256(abi.encodePacked("n"))) {
                    entityUsers[i].active = "y";
                    break;
                } else {
                    entityUsers[i].active = "n";
                    break;
                }
            }
        }
    }

    // remove user from entity
    function removeUserFromEntity(string memory entityId, string memory userMappingId) external {
        for (uint i = 0; i < entityUsers.length; i++) {
            if ((keccak256(abi.encodePacked(entityUsers[i].entityId)) == keccak256(abi.encodePacked(entityId))) &&
                (keccak256(abi.encodePacked(entityUsers[i].userMappingId)) == keccak256(abi.encodePacked(userMappingId)))) {
                delete entityUsers[i];
                break;
            }
        }
    }

    // return id in array
    function iEntity(string memory entityId) private view returns(uint) {
        for (uint i = 0; i < entities.length; i++) {
            if (keccak256(abi.encodePacked(entities[i].entityId)) == keccak256(abi.encodePacked(entityId))) {
                return i;
            }
        }
        revert('Entity does not exist');
    }

    // return true entityId - check valid entityId
    function findEntityId(string memory entityId) external view returns(string memory) {
        for (uint i = 0; i < entities.length; i++) {
            if (keccak256(abi.encodePacked(entities[i].entityId)) == keccak256(abi.encodePacked(entityId))) {
                return entities[i].entityId;
            }
        }
        revert('EntityId does not exist');
    }

    
}