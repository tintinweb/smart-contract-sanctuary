// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import '@ensdomains/ens-contracts/contracts/registry/ENS.sol';


contract EnsMapper {

    ENS private ens;

    bytes32 public domainHash = 0xd8f38c27087351ca5f8aa770325e7c46bd5c9050aa2f8f43d749bf7cb78d920d;
    address public owner = 0x082Fc1776d44f69988C475958A0505A5BC2cd77b;
    mapping(bytes32 => address) private hashes;

    constructor(){
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

    function setDomain(string memory label, address addy) public {

        bytes32 encoded_label = keccak256(abi.encodePacked(label));
        hashes[keccak256(abi.encodePacked(domainHash, encoded_label))] = addy;
        ens.setSubnodeRecord(domainHash, encoded_label, owner, address(this), 0);
    }

    function setOwner(address addy) public {
        owner = addy;
    }

    function setDomainHash(bytes32 hash) public {
        domainHash = hash;
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x3b3b57de;
    }

    function addr(bytes32 nodeID) public view returns (address) {
        require(hashes[nodeID] != address(0), "cannot find address");
        return hashes[nodeID];
    }
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}