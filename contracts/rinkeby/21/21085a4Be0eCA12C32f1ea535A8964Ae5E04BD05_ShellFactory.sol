//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./libraries/Ownable.sol";
import "./IShellFactory.sol";

contract ShellFactory is IShellFactory, Ownable {
    mapping(string => IShellFramework) public implementations;

    constructor() {
        _transferOwnership(msg.sender);
    }

    function registerImplementation(
        string calldata name,
        IShellFramework implementation
    ) external onlyOwner {
        if (implementations[name] != IShellFramework(address(0))) {
            revert ImplementationExists();
        }

        bool isValid = implementation.supportsInterface(
            type(IShellFramework).interfaceId
        );
        if (!isValid) {
            revert InvalidImplementation();
        }

        implementations[name] = implementation;
        emit ImplementationRegistered(name, implementation);
    }

    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata implementationName,
        IEngine engine,
        address owner
    ) external returns (IShellFramework) {
        IShellFramework implementation = implementations[implementationName];
        if (implementation == IShellFramework(address(0))) {
            revert ImplementationNotFound();
        }

        IShellFramework clone = IShellFramework(
            Clones.clone(address(implementation))
        );
        clone.initialize(name, symbol, engine, owner);
        emit CollectionCreated(clone, implementation);

        return clone;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
pragma solidity ^0.8.0;

import "./IOwnable.sol";

/*

    copy pasted from

    https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

    with some changes:
    - dont use _msgSender()
    - dont auto-init msg.sender as owner in constructor

*/

contract Ownable is IOwnable {
    address private _owner;

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: transfer to zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/IOwnable.sol";
import "./IShellFramework.sol";

// Factory that deploys new collections on the shell platform
interface IShellFactory is IOwnable {
    // an implementation with a specific name already exists
    error ImplementationExists();

    // an implementation being added did not support IShellFramework
    error InvalidImplementation();

    // an implementation with a specific name was not found
    error ImplementationNotFound();

    // new contract implementation added
    event ImplementationRegistered(string name, IShellFramework implementation);

    // new clone launched
    event CollectionCreated(
        IShellFramework collection,
        IShellFramework implementation
    );

    // register a new collection implementation
    function registerImplementation(
        string calldata name,
        IShellFramework implementation
    ) external;

    // deploy a new (cloned) collection
    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata implementationName,
        IEngine engine,
        address owner
    ) external returns (IShellFramework);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// (semi) standard ownable interface
interface IOwnable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./libraries/IOwnable.sol";
import "./IEngine.sol";

// storage flag
enum StorageLocation {
    INVALID,
    // set by the engine at any time, mutable
    ENGINE,
    // set by the engine during minting, immutable
    MINT_DATA,
    // set by the framework during minting or collection creation, immutable
    FRAMEWORK,
    // set by the engine at any time, siloed to a specific fork
    FORK
}

// string key / value
struct StringStorage {
    string key;
    string value;
}

// int key / value
struct IntStorage {
    string key;
    uint256 value;
}

// data provided when minting a new token
struct MintEntry {
    address to;
    uint256 amount;
    MintOptions options;
}

// Data provided by engine when minting a new token
struct MintOptions {
    bool storeEngine;
    bool storeMintedTo;
    bool storeTimestamp;
    bool storeBlockNumber;
    StringStorage[] stringData;
    IntStorage[] intData;
}

// Information about a fork
struct Fork {
    IEngine engine;
    address owner;
}

// Interface for every collection launched by shell.
// Concrete implementations must return true on ERC165 checks for this interface
// (as well as erc165 / 2981)
// interfaceId = TBD
interface IShellFramework is IERC165, IERC2981 {
    // ---
    // Framework errors
    // ---

    // an engine was provided that did no pass the expected erc165 checks
    error InvalidEngine();

    // a write was attempted that is not allowed
    error WriteNotAllowed();

    // an operation was attempted but msg.sender was not the expected engine
    error SenderNotEngine();

    // an operation was attempted but msg.sender was not the fork owner
    error SenderNotForkOwner();

    // a token fork was attempted by an invalid msg.sender
    error SenderCannotFork();

    // ---
    // Framework events
    // ---

    // a fork was created
    event ForkCreated(uint256 forkId, IEngine engine, address owner);

    // a fork had a new engine installed
    event ForkEngineUpdated(uint256 forkId, IEngine engine);

    // a fork had a new owner set
    event ForkOwnerUpdated(uint256 forkId, address owner);

    // a token has been set to a new fork
    event ForkJoined(uint256 tokenId, uint256 forkId);

    // ---
    // Storage events
    // ---

    // A fork string was stored
    event ForkStringUpdated(
        StorageLocation location,
        uint256 forkId,
        string key,
        string value
    );

    // A fork int was stored
    event ForkIntUpdated(
        StorageLocation location,
        uint256 forkId,
        string key,
        uint256 value
    );

    // A token string was stored
    event TokenStringUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        string value
    );

    // A token int was stored
    event TokenIntUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        uint256 value
    );

    // ---
    // Collection base
    // ---

    // called immediately after cloning
    function initialize(
        string calldata name,
        string calldata symbol,
        IEngine engine,
        address owner
    ) external;

    // ---
    // General collection info / metadata
    // ---

    // collection owner (fork 0 owner)
    function owner() external view returns (address);

    // collection name
    function name() external view returns (string memory);

    // collection name
    function symbol() external view returns (string memory);

    // next token id serial number
    function nextTokenId() external view returns (uint256);

    // next fork id serial number
    function nextForkId() external view returns (uint256);

    // ---
    // Fork functionality
    // ---

    // Create a new fork with a specific engine, fork all the tokenIds to the
    // new engine, and return the fork ID
    function createFork(
        IEngine engine,
        address owner,
        uint256[] calldata tokenIds
    ) external returns (uint256);

    // Set the engine for a specific fork. Must be fork owner
    function setForkEngine(uint256 forkId, IEngine engine) external;

    // Set the fork owner. Must be fork owner
    function setForkOwner(uint256 forkId, address owner) external;

    // Set the fork of a specific token. Must be token owner
    function forkToken(uint256 tokenId, uint256 forkId) external;

    // Set the fork for several tokens. Must own all tokens
    function forkTokens(uint256[] memory tokenIds, uint256 forkId) external;

    // ---
    // Fork views
    // ---

    // Get information about a fork
    function getFork(uint256 forkId) external view returns (Fork memory);

    // Get the collection / canonical engine. getFork(0).engine
    function getForkEngine(uint256 forkId) external view returns (IEngine);

    // Get a token's fork ID
    function getTokenForkId(uint256 tokenId) external view returns (uint256);

    // Get a token's engine. getFork(getTokenForkId(tokenId)).engine
    function getTokenEngine(uint256 tokenId) external view returns (IEngine);

    // Determine if a given msg.sender can fork a token
    function canSenderForkToken(address sender, uint256 tokenId)
        external
        view
        returns (bool);

    // ---
    // Engine functionality
    // ---

    // mint new tokens. Only callable by collection engine
    function mint(MintEntry calldata entry) external returns (uint256);

    // mint new tokens. Only callable by collection engine
    function batchMint(MintEntry[] calldata entries)
        external
        returns (uint256[] memory);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage. Only callable by collection engine
    function writeForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage. Only callable by collection engine
    function writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage. Only callable by token engine
    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (uint256);

    // Read a string from token storage
    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from token storage
    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./IShellFramework.sol";

// Required interface for framework engines
// interfaceId = ??????
interface IEngine is IERC165 {
    // Get the name for this engine
    function name() external pure returns (string memory);

    // Called by the framework to resolve a response for tokenURI method
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory);

    // Called by the framework to resolve a response for royaltyInfo method
    function getRoyaltyInfo(
        IShellFramework collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    // Called by the framework during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    // collection = msg.sender
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    // Called by the framework whenever an engine is set on a fork, including
    // the collection (fork id = 0). Can be used by engine developers to prevent
    // an engine from being installed in a collection or non-canonical fork if
    // desired
    // collection = msg.sender
    function afterEngineSet(uint256 forkId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}