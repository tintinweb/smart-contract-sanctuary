pragma solidity ^0.8.0;

import "./interfaces/ICollectionRegistry.sol";

contract CollectionRegistry is ICollectionRegistry {

    struct Record {
        address owner;
        address addr;
    }

    // mapping from collectionId into collection address
    mapping(bytes32 => Record) records;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyRecordOwner(bytes32 collectionId) {
        require(records[collectionId].owner == msg.sender, "Ownable: caller is not the record owner");
        _;
    }

    /**
     * @dev Adds a new record for a collection.
     * @param collectionId_ The new collection to set.
     * @param owner_ The address of the owner.
     * @param collectionAddress_ The address of the collection contract.
     */
    function registerCollection(bytes32 collectionId_, address owner_, address collectionAddress_) external virtual override {
        require(!recordExists(collectionId_), "Collection already exists");
        _setOwner(collectionId_, owner_);
        _setAddress(collectionId_, collectionAddress_);
        emit NewCollection(collectionId_, owner_, collectionAddress_);
    }

    /**
     * @dev Transfers ownership of a collection to a new address. May only be called by the current owner of the node.
     * @param collectionId_ The collection to transfer ownership of.
     * @param owner_ The address of the new owner.
     */
    function setOwner(bytes32 collectionId_, address owner_) external virtual override onlyRecordOwner(collectionId_) {
        _setOwner(collectionId_, owner_);
        emit TransferOwnership(collectionId_, owner_);
    }

    /**
    * @dev Sets the address for the specified collection.
    * @param collectionId_ The collection to update.
    * @param address_ The address of the collection.
    */
    function setAddress(bytes32 collectionId_, address address_) external virtual override onlyRecordOwner(collectionId_) {
        emit NewAddress(collectionId_, address_);
        records[collectionId_].addr = address_;
    }

    /**
    * @dev Returns the address that owns the specified node.
    * @param collectionId_ The specified node.
    * @return address of the owner.
    */
    function ownerOf(bytes32 collectionId_) external virtual override view returns (address) {
        address addr = records[collectionId_].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
    * @dev Returns the collection address for the specified collection.
    * @param collectionId_ The specified collection.
    * @return address of the collection.
    */
    function addressOf(bytes32 collectionId_) external virtual override view returns (address) {
        return records[collectionId_].addr;
    }

    /**
    * @dev Returns whether a record has been imported to the registry.
    * @param collectionId_ The specified node.
    * @return Bool if record exists
    */
    function recordExists(bytes32 collectionId_) public virtual override view returns (bool) {
        return records[collectionId_].owner != address(0x0);
    }

    function _setOwner(bytes32 collectionId_, address owner_) internal virtual {
        records[collectionId_].owner = owner_;
    }

    function _setAddress(bytes32 collectionId_, address collectionAddress_) internal {
        records[collectionId_].addr = collectionAddress_;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ICollectionRegistry {

    // Logged when new record is created.
    event NewCollection(bytes32 indexed collectionId, address owner, address addr);

    // Logged when the owner of a node transfers ownership to a new account.
    event TransferOwnership(bytes32 indexed collectionId, address owner);

    // Logged when the resolver for a node changes.
    event NewAddress(bytes32 indexed collectionId, address addr);


    function registerCollection(bytes32 collectionId_, address owner_, address collectionAddress_)  external;
    function setAddress(bytes32 collectionId_, address address_) external;
    function setOwner(bytes32 collectionId_, address owner_) external;
    function ownerOf(bytes32 collectionId_) external view returns (address);
    function addressOf(bytes32 collectionId_) external view returns (address);
    function recordExists(bytes32 collectionId_) external view returns (bool);
}