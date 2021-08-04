// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Entity.sol";

contract Package is SuperAdmin {
    Entity entities;

    constructor(address entity_contract) {
        require(entity_contract != address(0),"Contracts cannot be 0x address");
        entities = Entity(entity_contract);
    }

    struct PackageEntity {
        string packageId;
        string entityId;
        string dataPackage;
        string deleted; // default: n / y
    }
    PackageEntity[] private packages;

    // create package
    function addPackage(string memory packageId, string memory _entityId, string memory dataPackage) public {
        string memory entityId = entities.findEntityId(_entityId);
        packages.push(PackageEntity(packageId, entityId, dataPackage, "n"));
    }

    // edit package
    function editPackage(string memory packageId, string memory dataPackage) public {
        uint i = iPackage(packageId);
        packages[i].dataPackage = dataPackage;
    }

    // delete package
    function deletePackage(string memory packageId) public {
        for (uint i = 0; i < packages.length; i++) {
            if ((keccak256(abi.encodePacked(packages[i].packageId)) == keccak256(abi.encodePacked(packageId))) &&
                (keccak256(abi.encodePacked(packages[i].deleted)) == keccak256(abi.encodePacked("n")))) {
                    packages[i].deleted = "y";
                    break;
            }
        }
        revert('Can not delete package');
    }

    // get package detail by id
    function getPackageDetailById(string memory _packageId) view external onlySuperAdmin returns (
        string memory,
        string memory,
        string memory,
        string memory) {
        string memory packageId;
        string memory entityId;
        string memory dataPackage;
        string memory deleted;
        uint i = iPackage(_packageId);
        packageId = packages[i].packageId;
        entityId = packages[i].entityId;
        dataPackage = packages[i].dataPackage;
        deleted = packages[i].deleted;
        return(packageId, entityId, dataPackage, deleted);
    }

    // get entityId of package
    function getEntityIdByPackageId(string memory _packageId) public view returns(string memory) {
        uint i = iPackage(_packageId);
        return packages[i].entityId;
    }

    // return id in array
    function iPackage(string memory packageId) private view returns(uint) {
        for (uint i = 0; i < packages.length; i++) {
            if (keccak256(abi.encodePacked(packages[i].packageId)) == keccak256(abi.encodePacked(packageId))) {
                return i;
            }
        }
        revert('Package does not exist');
    }
    
    // return true packageId - check valid packageId
    function findPackageId(string memory packageId) external view returns(string memory) {
        for (uint i = 0; i < packages.length; i++) {
            if (keccak256(abi.encodePacked(packages[i].packageId)) == keccak256(abi.encodePacked(packageId))) {
                return packages[i].packageId;
            }
        }
        revert('PackageId does not exist');
    }




}