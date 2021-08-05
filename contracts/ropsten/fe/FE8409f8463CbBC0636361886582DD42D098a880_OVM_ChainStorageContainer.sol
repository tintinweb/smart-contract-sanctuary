// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_RingBuffer } from "../../libraries/utils/Lib_RingBuffer.sol";
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/* Interface Imports */
import { iOVM_ChainStorageContainer } from "../../iOVM/chain/iOVM_ChainStorageContainer.sol";

/**
 * @title OVM_ChainStorageContainer
 * @dev The Chain Storage Container provides its owner contract with read, write and delete functionality.
 * This provides gas efficiency gains by enabling it to overwrite storage slots which can no longer be used
 * in a fraud proof due to the fraud window having passed, and the associated chain state or
 * transactions being finalized.
 * Three distinct Chain Storage Containers will be deployed on Layer 1:
 * 1. Stores transaction batches for the Canonical Transaction Chain
 * 2. Stores queued transactions for the Canonical Transaction Chain
 * 3. Stores chain state batches for the State Commitment Chain
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract OVM_ChainStorageContainer is iOVM_ChainStorageContainer, Lib_AddressResolver {

    /*************
     * Libraries *
     *************/

    using Lib_RingBuffer for Lib_RingBuffer.RingBuffer;


    /*************
     * Variables *
     *************/

    string public owner;
    Lib_RingBuffer.RingBuffer internal buffer;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     * @param _owner Name of the contract that owns this container (will be resolved later).
     */
    constructor(
        address _libAddressManager,
        string memory _owner
    )
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
            "OVM_ChainStorageContainer: Function can only be called by the owner."
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function setGlobalMetadata(
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        return buffer.setExtraData(_globalMetadata);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function getGlobalMetadata()
        override
        public
        view
        returns (
            bytes27
        )
    {
        return buffer.getExtraData();
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function length()
        override
        public
        view
        returns (
            uint256
        )
    {
        return uint256(buffer.getLength());
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function push(
        bytes32 _object
    )
        override
        public
        onlyOwner
    {
        buffer.push(_object);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function push(
        bytes32 _object,
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        buffer.push(_object, _globalMetadata);
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function get(
        uint256 _index
    )
        override
        public
        view
        returns (
            bytes32
        )
    {
        return buffer.get(uint40(_index));
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function deleteElementsAfterInclusive(
        uint256 _index
    )
        override
        public
        onlyOwner
    {
        buffer.deleteElementsAfterInclusive(
            uint40(_index)
        );
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function deleteElementsAfterInclusive(
        uint256 _index,
        bytes27 _globalMetadata
    )
        override
        public
        onlyOwner
    {
        buffer.deleteElementsAfterInclusive(
            uint40(_index),
            _globalMetadata
        );
    }

    /**
     * @inheritdoc iOVM_ChainStorageContainer
     */
    function setNextOverwritableIndex(
        uint256 _index
    )
        override
        public
        onlyOwner
    {
        buffer.nextOverwritableIndex = _index;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title iOVM_ChainStorageContainer
 */
interface iOVM_ChainStorageContainer {

    /********************
     * Public Functions *
     ********************/

    /**
     * Sets the container's global metadata field. We're using `bytes27` here because we use five
     * bytes to maintain the length of the underlying data structure, meaning we have an extra
     * 27 bytes to store arbitrary data.
     * @param _globalMetadata New global metadata to set.
     */
    function setGlobalMetadata(
        bytes27 _globalMetadata
    )
        external;

    /**
     * Retrieves the container's global metadata field.
     * @return Container global metadata field.
     */
    function getGlobalMetadata()
        external
        view
        returns (
            bytes27
        );

    /**
     * Retrieves the number of objects stored in the container.
     * @return Number of objects in the container.
     */
    function length()
        external
        view
        returns (
            uint256
        );

    /**
     * Pushes an object into the container.
     * @param _object A 32 byte value to insert into the container.
     */
    function push(
        bytes32 _object
    )
        external;

    /**
     * Pushes an object into the container. Function allows setting the global metadata since
     * we'll need to touch the "length" storage slot anyway, which also contains the global
     * metadata (it's an optimization).
     * @param _object A 32 byte value to insert into the container.
     * @param _globalMetadata New global metadata for the container.
     */
    function push(
        bytes32 _object,
        bytes27 _globalMetadata
    )
        external;

    /**
     * Retrieves an object from the container.
     * @param _index Index of the particular object to access.
     * @return 32 byte object value.
     */
    function get(
        uint256 _index
    )
        external
        view
        returns (
            bytes32
        );

    /**
     * Removes all objects after and including a given index.
     * @param _index Object index to delete from.
     */
    function deleteElementsAfterInclusive(
        uint256 _index
    )
        external;

    /**
     * Removes all objects after and including a given index. Also allows setting the global
     * metadata field.
     * @param _index Object index to delete from.
     * @param _globalMetadata New global metadata for the container.
     */
    function deleteElementsAfterInclusive(
        uint256 _index,
        bytes27 _globalMetadata
    )
        external;

    /**
     * Marks an index as overwritable, meaing the underlying buffer can start to write values over
     * any objects before and including the given index.
     */
    function setNextOverwritableIndex(
        uint256 _index
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {

    /**********
     * Events *
     **********/

    event AddressSet(
        string _name,
        address _newAddress
    );


    /*************
     * Variables *
     *************/

    mapping (bytes32 => address) private addresses;


    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(
        string memory _name,
        address _address
    )
        external
        onlyOwner
    {
        addresses[_getNameHash(_name)] = _address;

        emit AddressSet(
            _name,
            _address
        );
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(
        string memory _name
    )
        external
        view
        returns (
            address
        )
    {
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
    function _getNameHash(
        string memory _name
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

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
    constructor(
        address _libAddressManager
    ) {
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
    function resolve(
        string memory _name
    )
        public
        view
        returns (
            address
        )
    {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

library Lib_RingBuffer {
    using Lib_RingBuffer for RingBuffer;

    /***********
     * Structs *
     ***********/

    struct Buffer {
        uint256 length;
        mapping (uint256 => bytes32) buf;
    }

    struct RingBuffer {
        bytes32 contextA;
        bytes32 contextB;
        Buffer bufferA;
        Buffer bufferB;
        uint256 nextOverwritableIndex;
    }

    struct RingBufferContext {
        // contextA
        uint40 globalIndex;
        bytes27 extraData;

        // contextB
        uint64 currBufferIndex;
        uint40 prevResetIndex;
        uint40 currResetIndex;
    }


    /*************
     * Constants *
     *************/

    uint256 constant MIN_CAPACITY = 16;


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Pushes a single element to the buffer.
     * @param _self Buffer to access.
     * @param _value Value to push to the buffer.
     * @param _extraData Optional global extra data.
     */
    function push(
        RingBuffer storage _self,
        bytes32 _value,
        bytes27 _extraData
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();
        Buffer storage currBuffer = _self.getBuffer(ctx.currBufferIndex);

        // Set a minimum capacity.
        if (currBuffer.length == 0) {
            currBuffer.length = MIN_CAPACITY;
        }

        // Check if we need to expand the buffer.
        if (ctx.globalIndex - ctx.currResetIndex >= currBuffer.length) {
            if (ctx.currResetIndex < _self.nextOverwritableIndex) {
                // We're going to overwrite the inactive buffer.
                // Bump the buffer index, reset the delete offset, and set our reset indices.
                ctx.currBufferIndex++;
                ctx.prevResetIndex = ctx.currResetIndex;
                ctx.currResetIndex = ctx.globalIndex;

                // Swap over to the next buffer.
                currBuffer = _self.getBuffer(ctx.currBufferIndex);
            } else {
                // We're not overwriting yet, double the length of the current buffer.
                currBuffer.length *= 2;
            }
        }

        // Index to write to is the difference of the global and reset indices.
        uint256 writeHead = ctx.globalIndex - ctx.currResetIndex;
        currBuffer.buf[writeHead] = _value;

        // Bump the global index and insert our extra data, then save the context.
        ctx.globalIndex++;
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Pushes a single element to the buffer.
     * @param _self Buffer to access.
     * @param _value Value to push to the buffer.
     */
    function push(
        RingBuffer storage _self,
        bytes32 _value
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();

        _self.push(
            _value,
            ctx.extraData
        );
    }

    /**
     * Retrieves an element from the buffer.
     * @param _self Buffer to access.
     * @param _index Element index to retrieve.
     * @return Value of the element at the given index.
     */
    function get(
        RingBuffer storage _self,
        uint256 _index
    )
        internal
        view
        returns (
            bytes32
        )
    {
        RingBufferContext memory ctx = _self.getContext();

        require(
            _index < ctx.globalIndex,
            "Index out of bounds."
        );

        Buffer storage currBuffer = _self.getBuffer(ctx.currBufferIndex);
        Buffer storage prevBuffer = _self.getBuffer(ctx.currBufferIndex + 1);

        if (_index >= ctx.currResetIndex) {
            // We're trying to load an element from the current buffer.
            // Relative index is just the difference from the reset index.
            uint256 relativeIndex = _index - ctx.currResetIndex;

            // Shouldn't happen but why not check.
            require(
                relativeIndex < currBuffer.length,
                "Index out of bounds."
            );

            return currBuffer.buf[relativeIndex];
        } else {
            // We're trying to load an element from the previous buffer.
            // Relative index is the difference from the reset index in the other direction.
            uint256 relativeIndex = ctx.currResetIndex - _index;

            // Condition only fails in the case that we deleted and flipped buffers.
            require(
                ctx.currResetIndex > ctx.prevResetIndex,
                "Index out of bounds."
            );

            // Make sure we're not trying to read beyond the array.
            require(
                relativeIndex <= prevBuffer.length,
                "Index out of bounds."
            );

            return prevBuffer.buf[prevBuffer.length - relativeIndex];
        }
    }

    /**
     * Deletes all elements after (and including) a given index.
     * @param _self Buffer to access.
     * @param _index Index of the element to delete from (inclusive).
     * @param _extraData Optional global extra data.
     */
    function deleteElementsAfterInclusive(
        RingBuffer storage _self,
        uint40 _index,
        bytes27 _extraData
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();

        require(
            _index < ctx.globalIndex && _index >= ctx.prevResetIndex,
            "Index out of bounds."
        );

        if (_index < ctx.currResetIndex) {
            // We're switching back to the previous buffer.
            // Reduce the buffer index, set the current reset index back to match the previous one.
            // We use the equality of these two values to prevent reading beyond this buffer.
            ctx.currBufferIndex--;
            ctx.currResetIndex = ctx.prevResetIndex;
        }

        // Set our global index and extra data, save the context.
        ctx.globalIndex = _index;
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Deletes all elements after (and including) a given index.
     * @param _self Buffer to access.
     * @param _index Index of the element to delete from (inclusive).
     */
    function deleteElementsAfterInclusive(
        RingBuffer storage _self,
        uint40 _index
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();
        _self.deleteElementsAfterInclusive(
            _index,
            ctx.extraData
        );
    }

    /**
     * Retrieves the current global index.
     * @param _self Buffer to access.
     * @return Current global index.
     */
    function getLength(
        RingBuffer storage _self
    )
        internal
        view
        returns (
            uint40
        )
    {
        RingBufferContext memory ctx = _self.getContext();
        return ctx.globalIndex;
    }

    /**
     * Changes current global extra data.
     * @param _self Buffer to access.
     * @param _extraData New global extra data.
     */
    function setExtraData(
        RingBuffer storage _self,
        bytes27 _extraData
    )
        internal
    {
        RingBufferContext memory ctx = _self.getContext();
        ctx.extraData = _extraData;
        _self.setContext(ctx);
    }

    /**
     * Retrieves the current global extra data.
     * @param _self Buffer to access.
     * @return Current global extra data.
     */
    function getExtraData(
        RingBuffer storage _self
    )
        internal
        view
        returns (
            bytes27
        )
    {
        RingBufferContext memory ctx = _self.getContext();
        return ctx.extraData;
    }

    /**
     * Sets the current ring buffer context.
     * @param _self Buffer to access.
     * @param _ctx Current ring buffer context.
     */
    function setContext(
        RingBuffer storage _self,
        RingBufferContext memory _ctx
    )
        internal
    {
        bytes32 contextA;
        bytes32 contextB;

        uint40 globalIndex = _ctx.globalIndex;
        bytes27 extraData = _ctx.extraData;
        assembly {
            contextA := globalIndex
            contextA := or(contextA, extraData)
        }

        uint64 currBufferIndex = _ctx.currBufferIndex;
        uint40 prevResetIndex = _ctx.prevResetIndex;
        uint40 currResetIndex = _ctx.currResetIndex;
        assembly {
            contextB := currBufferIndex
            contextB := or(contextB, shl(64, prevResetIndex))
            contextB := or(contextB, shl(104, currResetIndex))
        }

        if (_self.contextA != contextA) {
            _self.contextA = contextA;
        }

        if (_self.contextB != contextB) {
            _self.contextB = contextB;
        }
    }

    /**
     * Retrieves the current ring buffer context.
     * @param _self Buffer to access.
     * @return Current ring buffer context.
     */
    function getContext(
        RingBuffer storage _self
    )
        internal
        view
        returns (
            RingBufferContext memory
        )
    {
        bytes32 contextA = _self.contextA;
        bytes32 contextB = _self.contextB;

        uint40 globalIndex;
        bytes27 extraData;
        assembly {
            globalIndex := and(contextA, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            extraData   := and(contextA, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000)
        }

        uint64 currBufferIndex;
        uint40 prevResetIndex;
        uint40 currResetIndex;
        assembly {
            currBufferIndex :=          and(contextB, 0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF)
            prevResetIndex  := shr(64,  and(contextB, 0x00000000000000000000000000000000000000FFFFFFFFFF0000000000000000))
            currResetIndex  := shr(104, and(contextB, 0x0000000000000000000000000000FFFFFFFFFF00000000000000000000000000))
        }

        return RingBufferContext({
            globalIndex: globalIndex,
            extraData: extraData,
            currBufferIndex: currBufferIndex,
            prevResetIndex: prevResetIndex,
            currResetIndex: currResetIndex
        });
    }

    /**
     * Retrieves the a buffer from the ring buffer by index.
     * @param _self Buffer to access.
     * @param _which Index of the sub buffer to access.
     * @return Sub buffer for the index.
     */
    function getBuffer(
        RingBuffer storage _self,
        uint256 _which
    )
        internal
        view
        returns (
            Buffer storage
        )
    {
        return _which % 2 == 0 ? _self.bufferA : _self.bufferB;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}