/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.8;

interface IENS {
    function owner(bytes32 _node) external view returns (address);
}

/**
 * @title PublicationRoles
 * @author MirrorXYZ
 */
contract PublicationRoles {
    // Immutable data
    address public immutable ens;

    // Mutable data

    // A flat mapping of the hash of the ENS node with the contributor
    // address to the hash of the role.
    mapping(bytes32 => bytes32) public roles;

    // Modifiers

    modifier onlyPublicationOwner(bytes32 publicationNode) {
        require(
            ownsPublication(publicationNode, msg.sender),
            "Sender must be publication owner"
        );
        _;
    }

    // Events
    event ModifiedRole(
        bytes32 indexed publicationNode,
        address indexed contributor,
        string roleName
    );

    // Constructor

    constructor(address ens_) public {
        ens = ens_;
    }

    // Modifies data.

    function modifyRole(
        address contributor,
        // sha256(dev.mirror.xyz)
        bytes32 publicationNode,
        string calldata roleName
    ) external onlyPublicationOwner(publicationNode) {
        bytes32 role = encodeRole(roleName);
        roles[getContributorId(contributor, publicationNode)] = role;

        emit ModifiedRole(publicationNode, contributor, roleName);
    }

    function getContributorId(
        address contributor,
        // sha256(dev.mirror.xyz)
        bytes32 publicationNode
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(contributor, publicationNode));
    }

    function getRole(address contributor, bytes32 publicationNode)
        external
        view
        returns (bytes32)
    {
        return roles[getContributorId(contributor, publicationNode)];
    }

    // Convenient for encoding roles consistently.
    function encodeRole(string memory roleName) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(roleName));
    }

    function ownsPublication(bytes32 publicationNode, address account)
        public
        view
        returns (bool)
    {
        return publicationOwner(publicationNode) == account;
    }

    function publicationOwner(bytes32 publicationNode)
        public
        view
        returns (address)
    {
        return IENS(ens).owner(publicationNode);
    }
}