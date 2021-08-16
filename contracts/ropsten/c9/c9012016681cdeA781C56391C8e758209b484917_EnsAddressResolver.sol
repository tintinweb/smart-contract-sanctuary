/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// File: @ensdomains/ens-contracts/contracts/registry/ENS.sol

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

// File: @ensdomains/ens-contracts/contracts/resolvers/ResolverBase.sol

pragma solidity >=0.8.4;
abstract contract ResolverBase {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) virtual public pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

// File: contracts/EnsAddressResolver.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;




contract EnsAddressResolver is ResolverBase {
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private ADDRESS_INTERFACE_ID = 0xf1cb7e06;

    string public version;
    ENS public ens;
    mapping(bytes32 => address) addresses; // node => address
    /**
     * A mapping of approved operators per owner.
     * An address that is authorised for an address may make any changes to the name that the owner could,
     * but may not update the set of authorisations.
     */
    mapping(address => mapping(address => bool)) private operatorApprovals; // (owner, operator) => approved

    constructor(ENS _ens, string memory _version) {
        version = _version;
        ens = _ens;
    }

    function setAddr(bytes32 node, address a) external authorised(node) {
        addresses[node] = a;
        emit AddressChanged(node, a);
    }
    event AddressChanged(bytes32 indexed node, address newAddress);

    function addr(bytes32 node) public view returns (address) { return addresses[node]; }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == ADDR_INTERFACE_ID || interfaceID == ADDRESS_INTERFACE_ID || super.supportsInterface(interfaceID);
    }

    /**
     * See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function isAuthorised(bytes32 node) internal override view returns (bool) {
        address owner = ens.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    /**
     * See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {  return operatorApprovals[account][operator]; }

}