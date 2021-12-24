// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { Lib_Buffer } from "../../libraries/utils/Lib_Buffer.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/* Interface Imports */
import { IChainStorageContainer } from "./IChainStorageContainer.sol";

/**
 * @title ChainStorageContainer
 * @dev The Chain Storage Container provides its owner contract with read, write and delete
 * functionality. This provides gas efficiency gains by enabling it to overwrite storage slots which
 * can no longer be used in a fraud proof due to the fraud window having passed, and the associated
 * chain state or transactions being finalized.
 * Three distinct Chain Storage Containers will be deployed on Layer 1:
 * 1. Stores transaction batches for the Canonical Transaction Chain
 * 2. Stores queued transactions for the Canonical Transaction Chain
 * 3. Stores chain state batches for the State Commitment Chain
 *
 */
contract ChainStorageContainer is IChainStorageContainer, Lib_AddressResolver {
    /*************
     * Libraries *
     *************/

    using Lib_Buffer for Lib_Buffer.Buffer;

    /*************
     * Variables *
     *************/

    string public owner;
    Lib_Buffer.Buffer internal buffer;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     * @param _owner Name of the contract that owns this container (will be resolved later).
     */
    constructor(address _libAddressManager, string memory _owner)
        Lib_AddressResolver(_libAddressManager)
    {
        owner = _owner;
    }

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyOwner() {
        require(
            msg.sender == resolve(owner),
            "ChainStorageContainer: Function can only be called by the owner."
        );
        _;
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * @inheritdoc IChainStorageContainer
     */
    // slither-disable-next-line external-function
    function setGlobalMetadata(bytes27 _globalMetadata) public onlyOwner {
        return buffer.setExtraData(_globalMetadata);
    }

    /**
     * @inheritdoc IChainStorageContainer
     */
    // slither-disable-next-line external-function
    function getGlobalMetadata() public view returns (bytes27) {
        return buffer.getExtraData();
    }

    /**
     * @inheritdoc IChainStorageContainer
     */
    // slither-disable-next-line external-function
    function length() public view returns (uint256) {
        return uint256(buffer.getLength());
    }

    /**
     * @inheritdoc IChainStorageContainer
     */
    // slither-disable-next-line external-function
    function push(bytes32 _object) public onlyOwner {
        buffer.push(_object);
    }

    /**
     * @inheritdoc IChainStorageContainer
     */
    // slither-disable-next-line external-function
    function push(bytes32 _object, bytes27 _globalMetadata) public onlyOwner {
        buffer.push(_object, _globalMetadata);
    }

    /**
     * @inheritdoc IChainStorageContainer
     */
    // slither-disable-next-line external-function
    function get(uint256 _index) public view returns (bytes32) {
        return buffer.get(uint40(_index));
    }

    /**
     * @inheritdoc IChainStorageContainer
     */
    // slither-disable-next-line external-function
    function deleteElementsAfterInclusive(uint256 _index) public onlyOwner {
        buffer.deleteElementsAfterInclusive(uint40(_index));
    }

    /**
     * @inheritdoc IChainStorageContainer
     */
    // slither-disable-next-line external-function
    function deleteElementsAfterInclusive(uint256 _index, bytes27 _globalMetadata)
        public
        onlyOwner
    {
        buffer.deleteElementsAfterInclusive(uint40(_index), _globalMetadata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_Buffer
 * @dev This library implements a bytes32 storage array with some additional gas-optimized
 * functionality. In particular, it encodes its length as a uint40, and tightly packs this with an
 * overwritable "extra data" field so we can store more information with a single SSTORE.
 */
library Lib_Buffer {
    /*************
     * Libraries *
     *************/

    using Lib_Buffer for Buffer;

    /***********
     * Structs *
     ***********/

    struct Buffer {
        bytes32 context;
        mapping(uint256 => bytes32) buf;
    }

    struct BufferContext {
        // Stores the length of the array. Uint40 is way more elements than we'll ever reasonably
        // need in an array and we get an extra 27 bytes of extra data to play with.
        uint40 length;
        // Arbitrary extra data that can be modified whenever the length is updated. Useful for
        // squeezing out some gas optimizations.
        bytes27 extraData;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Pushes a single element to the buffer.
     * @param _self Buffer to access.
     * @param _value Value to push to the buffer.
     * @param _extraData Global extra data.
     */
    function push(
        Buffer storage _self,
        bytes32 _value,
        bytes27 _extraData
    ) internal {
        BufferContext memory ctx = _self.getContext();

        _self.buf[ctx.length] = _value;

        // Bump the global index and insert our extra data, then save the context.
        ctx.length++;
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Pushes a single element to the buffer.
     * @param _self Buffer to access.
     * @param _value Value to push to the buffer.
     */
    function push(Buffer storage _self, bytes32 _value) internal {
        BufferContext memory ctx = _self.getContext();

        _self.push(_value, ctx.extraData);
    }

    /**
     * Retrieves an element from the buffer.
     * @param _self Buffer to access.
     * @param _index Element index to retrieve.
     * @return Value of the element at the given index.
     */
    function get(Buffer storage _self, uint256 _index) internal view returns (bytes32) {
        BufferContext memory ctx = _self.getContext();

        require(_index < ctx.length, "Index out of bounds.");

        return _self.buf[_index];
    }

    /**
     * Deletes all elements after (and including) a given index.
     * @param _self Buffer to access.
     * @param _index Index of the element to delete from (inclusive).
     * @param _extraData Optional global extra data.
     */
    function deleteElementsAfterInclusive(
        Buffer storage _self,
        uint40 _index,
        bytes27 _extraData
    ) internal {
        BufferContext memory ctx = _self.getContext();

        require(_index < ctx.length, "Index out of bounds.");

        // Set our length and extra data, save the context.
        ctx.length = _index;
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Deletes all elements after (and including) a given index.
     * @param _self Buffer to access.
     * @param _index Index of the element to delete from (inclusive).
     */
    function deleteElementsAfterInclusive(Buffer storage _self, uint40 _index) internal {
        BufferContext memory ctx = _self.getContext();
        _self.deleteElementsAfterInclusive(_index, ctx.extraData);
    }

    /**
     * Retrieves the current global index.
     * @param _self Buffer to access.
     * @return Current global index.
     */
    function getLength(Buffer storage _self) internal view returns (uint40) {
        BufferContext memory ctx = _self.getContext();
        return ctx.length;
    }

    /**
     * Changes current global extra data.
     * @param _self Buffer to access.
     * @param _extraData New global extra data.
     */
    function setExtraData(Buffer storage _self, bytes27 _extraData) internal {
        BufferContext memory ctx = _self.getContext();
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Retrieves the current global extra data.
     * @param _self Buffer to access.
     * @return Current global extra data.
     */
    function getExtraData(Buffer storage _self) internal view returns (bytes27) {
        BufferContext memory ctx = _self.getContext();
        return ctx.extraData;
    }

    /**
     * Sets the current buffer context.
     * @param _self Buffer to access.
     * @param _ctx Current buffer context.
     */
    function setContext(Buffer storage _self, BufferContext memory _ctx) internal {
        bytes32 context;
        uint40 length = _ctx.length;
        bytes27 extraData = _ctx.extraData;
        assembly {
            context := length
            context := or(context, extraData)
        }

        if (_self.context != context) {
            _self.context = context;
        }
    }

    /**
     * Retrieves the current buffer context.
     * @param _self Buffer to access.
     * @return Current buffer context.
     */
    function getContext(Buffer storage _self) internal view returns (BufferContext memory) {
        bytes32 context = _self.context;
        uint40 length;
        bytes27 extraData;
        assembly {
            length := and(
                context,
                0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF
            )
            extraData := and(
                context,
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000
            )
        }

        return BufferContext({ length: length, extraData: extraData });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_AddressResolver
 */
abstract contract Lib_AddressResolver {
    /*************
     * Variables *
     *************/

    Lib_AddressManager public libAddressManager;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(address _libAddressManager) {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Resolves the address associated with a given name.
     * @param _name Name to resolve an address for.
     * @return Address associated with the given name.
     */
    function resolve(string memory _name) public view returns (address) {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title IChainStorageContainer
 */
interface IChainStorageContainer {
    /********************
     * Public Functions *
     ********************/

    /**
     * Sets the container's global metadata field. We're using `bytes27` here because we use five
     * bytes to maintain the length of the underlying data structure, meaning we have an extra
     * 27 bytes to store arbitrary data.
     * @param _globalMetadata New global metadata to set.
     */
    function setGlobalMetadata(bytes27 _globalMetadata) external;

    /**
     * Retrieves the container's global metadata field.
     * @return Container global metadata field.
     */
    function getGlobalMetadata() external view returns (bytes27);

    /**
     * Retrieves the number of objects stored in the container.
     * @return Number of objects in the container.
     */
    function length() external view returns (uint256);

    /**
     * Pushes an object into the container.
     * @param _object A 32 byte value to insert into the container.
     */
    function push(bytes32 _object) external;

    /**
     * Pushes an object into the container. Function allows setting the global metadata since
     * we'll need to touch the "length" storage slot anyway, which also contains the global
     * metadata (it's an optimization).
     * @param _object A 32 byte value to insert into the container.
     * @param _globalMetadata New global metadata for the container.
     */
    function push(bytes32 _object, bytes27 _globalMetadata) external;

    /**
     * Retrieves an object from the container.
     * @param _index Index of the particular object to access.
     * @return 32 byte object value.
     */
    function get(uint256 _index) external view returns (bytes32);

    /**
     * Removes all objects after and including a given index.
     * @param _index Object index to delete from.
     */
    function deleteElementsAfterInclusive(uint256 _index) external;

    /**
     * Removes all objects after and including a given index. Also allows setting the global
     * metadata field.
     * @param _index Object index to delete from.
     * @param _globalMetadata New global metadata for the container.
     */
    function deleteElementsAfterInclusive(uint256 _index, bytes27 _globalMetadata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {
    /**********
     * Events *
     **********/

    event AddressSet(string indexed _name, address _newAddress, address _oldAddress);

    /*************
     * Variables *
     *************/

    mapping(bytes32 => address) private addresses;

    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(string memory _name, address _address) external onlyOwner {
        bytes32 nameHash = _getNameHash(_name);
        address oldAddress = addresses[nameHash];
        addresses[nameHash] = _address;

        emit AddressSet(_name, _address, oldAddress);
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(string memory _name) external view returns (address) {
        return addresses[_getNameHash(_name)];
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}