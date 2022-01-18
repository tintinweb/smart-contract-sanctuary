pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";

contract Registry is IRegistry {

    struct Record {
        address owner;
        address resolver;
    }

    mapping(bytes32 => Record) records;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyRecordOwner(bytes32 node) {
        require(records[node].owner == msg.sender, "Ownable: caller is not the record owner");
        _;
    }

    /**
     * @dev Adds a new record for a node.
     * @param node_ The node to update.
     * @param owner_ The address of the new owner.
     * @param resolver_ The address of the resolver.
     */
    function setRecord(bytes32 node_, address owner_, address resolver_) external virtual override {
        require(!recordExists(node_), "Node already exists");
        _setOwner(node_, owner_);
        _setResolver(node_, resolver_);
        emit NewRecord(node_, owner_, resolver_);
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node_ The node to transfer ownership of.
     * @param owner_ The address of the new owner.
     */
    function setOwner(bytes32 node_, address owner_) external virtual override onlyRecordOwner(node_) {
        _setOwner(node_, owner_);
        emit Transfer(node_, owner_);
    }

    /**
    * @dev Sets the resolver address for the specified node.
    * @param node_ The node to update.
    * @param resolver_ The address of the resolver.
    */
    function setResolver(bytes32 node_, address resolver_) external virtual override onlyRecordOwner(node_) {
        emit NewResolver(node_, resolver_);
        records[node_].resolver = resolver_;
    }

    /**
    * @dev Returns the address that owns the specified node.
    * @param node_ The specified node.
    * @return address of the owner.
    */
    function owner(bytes32 node_) external virtual override view returns (address) {
        address addr = records[node_].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
    * @dev Returns the address of the resolver for the specified node.
    * @param node_ The specified node.
    * @return address of the resolver.
    */
    function resolver(bytes32 node_) external virtual override view returns (address) {
        return records[node_].resolver;
    }

    /**
    * @dev Returns whether a record has been imported to the registry.
    * @param node_ The specified node.
    * @return Bool if record exists
    */
    function recordExists(bytes32 node_) public virtual override view returns (bool) {
        return records[node_].owner != address(0x0);
    }

    function _setOwner(bytes32 node_, address owner_) internal virtual {
        records[node_].owner = owner_;
    }

    function _setResolver(bytes32 node_, address resolver_) internal {
        records[node_].resolver = resolver_;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IRegistry {

    // Logged when new record is created.
    event NewRecord(bytes32 indexed node, address owner, address resolver);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);


    function setRecord(bytes32 node_, address owner_, address resolver_) external;
    function setResolver(bytes32 node_, address resolver_) external;
    function setOwner(bytes32 node_, address owner_) external;
    function owner(bytes32 node_) external view returns (address);
    function resolver(bytes32 node_) external view returns (address);
    function recordExists(bytes32 node_) external view returns (bool);
}