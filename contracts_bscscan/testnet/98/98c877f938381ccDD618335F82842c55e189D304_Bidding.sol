// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Package.sol";

contract Bidding {
    Entity entities;
    Package packages;

    constructor(address entity_contract, address package_contract) {
        require(entity_contract != address(0),"Contracts cannot be 0x address");
        require(package_contract != address(0),"Contracts cannot be 0x address");
        entities = Entity(entity_contract);
        packages = Package(package_contract);
    }

    struct BiddingEntity {
        string biddingId;
        string packageId;
        string entityId;
        string dataBidding;
        string deleted; // default: n / y
    }
    BiddingEntity[] private biddings;

    // add bidding
    function addBidding(string memory biddingId, string memory _packageId, string memory _entityId, string memory dataBidding) public {
        string memory packageId = packages.findPackageId(_packageId);
        string memory entityId = entities.findEntityId(_entityId);
        biddings.push(BiddingEntity(biddingId, packageId, entityId, dataBidding, "n"));
    }

    // edit bidding
    function editBidding(string memory biddingId, string memory dataBidding) public {
        uint i = iBidding(biddingId);
        biddings[i].dataBidding = dataBidding;
    }

    // delete bidding
    function deleteBidding(string memory biddingId) public {
        for (uint i = 0; i < biddings.length; i++) {
            if ((keccak256(abi.encodePacked(biddings[i].biddingId)) == keccak256(abi.encodePacked(biddingId)))) {
                    biddings[i].deleted = "y";
                    break;
            }
        }
    }

    // get bidding detail by id
    function getBiddingDetailById(string memory _biddingId) view external returns(
        string memory,
        string memory,
        string memory,
        string memory,
        string memory) {
        string memory biddingId;
        string memory packageId;
        string memory entityId;
        string memory dataBidding;
        string memory deleted;
        uint i = iBidding(_biddingId);
        biddingId = biddings[i].biddingId;
        packageId = biddings[i].packageId;
        entityId = biddings[i].entityId;
        dataBidding = biddings[i].dataBidding;
        deleted = biddings[i].deleted;
        return(biddingId, packageId, entityId, dataBidding, deleted);
    }

    // return id in array
    function iBidding(string memory biddingId) private view returns(uint) {
        for (uint i = 0; i < biddings.length; i++) {
            if (keccak256(abi.encodePacked(biddings[i].biddingId)) == keccak256(abi.encodePacked(biddingId))) {
                return i;
            }
        }
        revert('Bidding does not exist');
    }
}