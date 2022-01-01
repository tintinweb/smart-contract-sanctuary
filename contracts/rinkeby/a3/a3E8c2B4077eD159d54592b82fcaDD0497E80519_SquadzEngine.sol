//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEngine} from "../../IEngine.sol";
import {ISquadzEngine} from "./ISquadzEngine.sol";
import {IShellFramework, MintEntry} from "../../IShellFramework.sol";
import {IShellERC721, StringStorage, IntStorage, MintOptions, StorageLocation} from "../../IShellERC721.sol";
import {IPersonalizedDescriptor} from "./IPersonalizedDescriptor.sol";
import {NoRoyaltiesEngine} from "../../engines/NoRoyaltiesEngine.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * Insert standard reference to shell here
 */

// NOTE If an engine is built without a need for many of its own events, this makes it much easier to spin up UIs, since the app 
// can depend on the existing shell subgraph.

// NOTE "fan" NFTs can be implemented as an independent lego, since they grant no priviliges and should be a separate collection

contract SquadzEngine is ISquadzEngine, NoRoyaltiesEngine {

    //===== Engine State =====//

    IPersonalizedDescriptor public immutable defaultDescriptor;

    //===== Constructor =====//

    constructor(address descriptorAddress) {
        IPersonalizedDescriptor descriptor = IPersonalizedDescriptor(descriptorAddress);
        require(
            descriptor.supportsInterface(type(IPersonalizedDescriptor).interfaceId),
            "SQUADZ: invalid descriptor address"
        );
        defaultDescriptor = descriptor;
    }

    //===== External Functions =====//

    // Called by the framework following an engine install. Can be used by the
    // engine to block (by reverting) installation if needed.
    // The engine MUST assert msg.sender == collection address!!
    // TODO Check IERC721Upgradeable as well, because this does not check inherited functions
    function afterInstallEngine(IShellFramework collection) external view {
        require(
            collection.supportsInterface(type(IShellERC721).interfaceId) &&
            collection.supportsInterface(type(IERC721Upgradeable).interfaceId),
            "SQUADZ: collection must support IShellERC721"
        );
    }

    function afterInstallEngine(IShellFramework, uint256) external pure {
        revert("SQUADZ: cannot install engine to individual tokens");
    }

    // Get the name for this engine
    function getEngineName() external pure returns (string memory) {
        return "SQUADZ v0.0.0";
    }

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory) {
        IPersonalizedDescriptor descriptor;
        IShellERC721 token = IShellERC721(address(collection));
        if (isAdminToken(token, tokenId)) {
            descriptor = getDescriptor(collection, true);
        } else {
            descriptor = getDescriptor(collection, false);
        }
        if (address(descriptor) == address(0)) descriptor = defaultDescriptor;
        return descriptor.getTokenURI(
            address(collection),
            tokenId,
            token.ownerOf(tokenId)
        );
    }

    // Called by the collection during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    function beforeTokenTransfer(
        IShellFramework collection,
        address,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external {
        require(msg.sender == address(collection), "SQUADZ: beforeTokenTransfer caller not collection");
        // if token is admin, increment and decrement adminTokenCount appropriately
        if (tokenIds.length == 0) return;
        require(tokenIds.length == amounts.length, "SQUADZ: array length mismatch");
        // TODO if multiple tokens can be transferred at the same time, do a loop here
        if (isAdminToken(IShellERC721(address(collection)), tokenIds[0])) {
            _decrementAdminTokenCount(collection, from);
            _incrementAdminTokenCount(collection, to);
        }
    }

    function setDescriptor(IShellERC721 collection, address descriptorAddress, bool admin) external {
        require(
            collection.owner() == msg.sender,
            "SQUADZ: sender not collection owner"
        );
        IPersonalizedDescriptor descriptor = IPersonalizedDescriptor(descriptorAddress);
        require(
            descriptor.supportsInterface(type(IPersonalizedDescriptor).interfaceId),
            "SQUADZ: invalid descriptor address"
        );
        if (admin == true) {
            collection.writeCollectionInt(
                StorageLocation.ENGINE,
                _adminDescriptorKey(),
                uint256(uint160(descriptorAddress))
            );
        } else {
            collection.writeCollectionInt(
                StorageLocation.ENGINE,
                _memberDescriptorKey(),
                uint256(uint160(descriptorAddress))
            );
        }
    }

    function mint(
        IShellERC721 collection,
        address to,
        bool admin
    ) external returns (uint256) {
        require(
            isAdmin(collection, msg.sender) || collection.owner() == msg.sender,
            "SQUADZ: only collection owner or admin token holder can mint"
        );
        return _mint(collection, to, admin);
    }

    // NOTE I think the interface batchMint that uses an array of MintEntries might not be neccessary, and is kind of annoying to implement 
    // I would have to create an array of mint entries here rather than getting to reuse my mint function, right?
    function batchMint(
        IShellERC721 collection,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) external returns (uint256[] memory) {
        require(toAddresses.length == adminBools.length, "SQUADZ: toAddresses and adminBools arrays have different lengths");
        require(
            isAdmin(collection, msg.sender) || collection.owner() == msg.sender,
            "SQUADZ: only collection owner or admin token holder can mint"
        );
        uint256[] memory ids = new uint256[](adminBools.length);
        for (uint256 i = 0; i < adminBools.length; i++) {
            ids[i] = _mint(collection, toAddresses[i], adminBools[i]);
        }
        return ids;
    }

    function mintedTo(IShellFramework collection, uint256 tokenId) external view returns (address) {
        return address(uint160(
          collection.readTokenInt(
              StorageLocation.FRAMEWORK,
              tokenId,
              "mintedTo"
          )
        ));
    }

    // TODO burn -- need this to be implemented in ShellERC721 first, I think

    //===== Public Functions =====//

    // does not show a token exists (will return false for non-existant tokens)
    function isAdminToken(IShellERC721 collection, uint256 tokenId) public view returns (bool) {
        return collection.readTokenInt(StorageLocation.MINT_DATA, tokenId, _adminTokenKey()) == 1;
    }

    function isAdmin(IShellFramework collection, address address_) public view returns (bool) {
        if (_adminTokenCount(collection, address_) > 0) return true;
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IEngine).interfaceId ||
            interfaceId == type(ISquadzEngine).interfaceId;
    }

    function getDescriptor(IShellFramework collection, bool admin) public view returns (IPersonalizedDescriptor) {
        IPersonalizedDescriptor descriptor;
        if (admin == true) {
            descriptor = IPersonalizedDescriptor(address(uint160(
                collection.readCollectionInt(
                    StorageLocation.ENGINE,
                    _adminDescriptorKey()
                )
            )));
        } else {
            descriptor = IPersonalizedDescriptor(address(uint160(
                collection.readCollectionInt(
                    StorageLocation.ENGINE,
                    _memberDescriptorKey()
                )
            )));
        }
        return descriptor;
    }

    //===== Internal Functions =====//

    function _mint(
        IShellERC721 collection,
        address to,
        bool admin
    ) internal returns (uint256) {

        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](1);
        if (admin == true) {
          intData[0].key = _adminTokenKey();
          intData[0].value = 1;
          // does beforeTokenTransfer cover this? 
          // Nope, it doesn't, because the token won't be an admin token before it's been minted, 
          // and beforeTokenTransfer gets called before the mint (i.e. transfer)
          _incrementAdminTokenCount(collection, to);
        }

        uint256 tokenId = collection.mint(MintEntry({
            to: to,
            amount: 1,
            options:
                // minimal storage for minimal gas cost
                MintOptions({
                    storeEngine: false,
                    storeMintedTo: true,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        return tokenId;
    }

    //===== Private Functions =====//

    function _adminTokenKey() private pure returns (string memory) {
        return "ADMIN_TOKEN";
    }

    function _adminTokenCountKey(address address_) private pure returns (string memory) {
        return string(abi.encodePacked(address_, "ADMIN_TOKEN_COUNT"));
    }

    function _adminDescriptorKey() private pure returns (string memory) {
        return "ADMIN_DESCRIPTOR_KEY";
    }

    function _memberDescriptorKey() private pure returns (string memory) {
        return "MEMBER_DESCRIPTOR_KEY";
    }

    function _adminTokenCount(IShellFramework collection, address address_) private view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, _adminTokenCountKey(address_));
    }

    function _setAdminTokenCount(IShellFramework collection, address address_, uint256 value) private {
        collection.writeCollectionInt(StorageLocation.ENGINE, _adminTokenCountKey(address_), value);
    }

    function _incrementAdminTokenCount(IShellFramework collection, address address_) private {
        uint256 count = _adminTokenCount(collection, address_);
        _setAdminTokenCount(collection, address_, count + 1);
    }

    function _decrementAdminTokenCount(IShellFramework collection, address address_) private {
        uint256 count = _adminTokenCount(collection, address_);
        require(count > 0, "SQUADZ: cannot decrement admin token count of 0");
        _setAdminTokenCount(collection, address_, count - 1);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IShellFramework.sol";

// Required interface for framework engines
// interfaceId = 0x805590d2
interface IEngine is IERC165 {
    // Get the name for this engine
    function getEngineName() external pure returns (string memory);

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
    //
    // The engine MUST assert msg.sender == collection address!!
    //
    function beforeTokenTransfer(
        IShellFramework collection,
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    // Called by the framework following an engine install to a collection. Can
    // be used by the engine to block (by reverting) installation if needed.
    //
    // The engine MUST assert msg.sender == collection address!!
    //
    function afterInstallEngine(IShellFramework collection) external;

    // Called by the framework following an engine install to specific token.
    // Can be used by the engine to block (by reverting) installation if needed.
    //
    // The engine MUST assert msg.sender == collection address!!
    //
    function afterInstallEngine(IShellFramework collection, uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IShellERC721} from "../../IShellERC721.sol";
import {IEngine} from "../../IEngine.sol";

interface ISquadzEngine is IEngine {
    function setDescriptor(IShellERC721 collection, address descriptorAddress, bool admin) external;

    function mint(
        IShellERC721 collection,
        address to,
        bool admin
    ) external returns (uint256);

    function batchMint(
        IShellERC721 collection,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) external returns (uint256[] memory);
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
    FRAMEWORK
}

// publish flag
enum PublishChannel {
    INVALID,
    // events created by anybody
    PUBLIC,
    // events created by engine
    ENGINE
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

// Interface for every collection launched by shell.
// Concrete implementations must return true on ERC165 checks for this interface
// (as well as erc165 / 2981)
// interfaceId = 0x46877bbc
interface IShellFramework is IERC165, IERC2981, IOwnable {
    // ---
    // Framework events
    // ---

    // A new engine was installed
    event EngineInstalled(IEngine engine);

    // A new engine was installed for a token
    event TokenEngineInstalled(uint256 tokenId, IEngine engine);

    // ---
    // Storage events
    // ---

    // A string was stored in the collection
    event CollectionStringUpdated(
        StorageLocation location,
        string key,
        string value
    );

    // A string was stored in a token
    event TokenStringUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        string value
    );

    // A uint256 was stored in the collection
    event CollectionIntUpdated(
        StorageLocation location,
        string key,
        uint256 value
    );

    // A uint256 was stored in a token
    event TokenIntUpdated(
        StorageLocation location,
        uint256 tokenId,
        string key,
        uint256 value
    );

    // ---
    // Published events
    // ---

    // A string was published from the collection
    event CollectionStringPublished(
        PublishChannel location,
        string key,
        string value
    );

    // A string was published from a token
    event TokenStringPublished(
        PublishChannel location,
        uint256 tokenId,
        string key,
        string value
    );

    // A uint256 was published from the collection
    event CollectionIntPublished(
        PublishChannel location,
        string key,
        uint256 value
    );

    // A uint256 was published from a token
    event TokenIntPublished(
        PublishChannel location,
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

    // collection name
    function name() external view returns (string memory);

    // collection name
    function symbol() external view returns (string memory);

    // next token id serial number
    function nextTokenId() external view returns (uint256);

    // ---
    // NFT owner functionaltiy
    // ---

    // override a token's engine. Only callable by NFT owner
    function installTokenEngine(uint256 tokenId, IEngine engine) external;

    // ---
    // Collection owner (admin) functionaltiy
    // ---

    // Hot swap the collection's engine. Only callable by contract owner
    function installEngine(IEngine engine) external;

    // the currently installed engine for this collection
    function installedEngine() external view returns (IEngine);

    // ---
    // Engine functionality
    // ---

    // mint new tokens. Only callable by engine
    function mint(MintEntry calldata entry) external returns (uint256);

    // mint new tokens. Only callable by engine
    function batchMint(MintEntry[] calldata entries)
        external
        returns (uint256[] memory);

    // ---
    // Storage writes
    // ---

    // Write a string to collection storage
    function writeCollectionString(
        StorageLocation location,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to token storage
    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external;

    // Write a string to collection storage
    function writeCollectionInt(
        StorageLocation location,
        string calldata key,
        uint256 value
    ) external;

    // Write a string to token storage
    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external;

    // ---
    // Event publishing
    // ---

    // publish a string from the collection
    function publishCollectionString(
        PublishChannel channel,
        string calldata topic,
        string calldata value
    ) external;

    // publish a string from a specific token
    function publishTokenString(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        string calldata value
    ) external;

    // publish a uint256 from the collection
    function publishCollectionInt(
        PublishChannel channel,
        string calldata topic,
        uint256 value
    ) external;

    // publish a uint256 from a specific token
    function publishTokenInt(
        PublishChannel channel,
        uint256 tokenId,
        string calldata topic,
        uint256 value
    ) external;

    // ---
    // Storage reads
    // ---

    // Read a string from collection storage
    function readCollectionString(StorageLocation location, string calldata key)
        external
        view
        returns (string memory);

    // Read a string from token storage
    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory);

    // Read a uint256 from collection storage
    function readCollectionInt(StorageLocation location, string calldata key)
        external
        view
        returns (uint256);

    // Read a uint256 from token storage
    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IShellFramework.sol";

// All shell erc721s must implement this interface
interface IShellERC721 is IShellFramework, IERC721Upgradeable {
    // need to reconcile collision between non-upgradeable and upgradeable
    // flavors of the openzep interfaces
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(IERC165, IERC165Upgradeable)
        returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPersonalizedDescriptor is IERC165 {
    // return a token URI that incorporates unique information about the collection and token owner
    function getTokenURI(address collection, uint256 tokenId, address owner) 
        external
        view
        returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IEngine.sol";

abstract contract NoRoyaltiesEngine is IEngine {
    function getRoyaltyInfo(
        IShellFramework,
        uint256,
        uint256
    ) external pure returns (address receiver, uint256 royaltyAmount) {
        receiver = address(0);
        royaltyAmount = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
interface IERC165Upgradeable {
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