//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IReverseRecords} from "./IReverseRecords.sol";
import {IEngine} from "../../IEngine.sol";
import {IShellFramework, MintEntry} from "../../IShellFramework.sol";
import {IShellERC721, StringStorage, IntStorage, MintOptions, StorageLocation} from "../../IShellERC721.sol";
import {SimpleRoyaltiesEngine} from "../SimpleRoyaltiesEngine.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * Insert standard reference to shell here
 */

/**
 * ===== SIMPLE NAME SYSTEM =====//
 *
 * A simple name system that partially matches the Ethereum Name System's interfaces without implementing the entire system.
 * Simply lets each address claim one name at a time.
 * Intended to be used to let NFTs display user names on Squadz pages on networks where ENS is unavailable (i.e. not mainnet).
 * Matches the same pattern for reverse name look up for ENS' reverse record contract (getNames)
 *
 */

contract SNS is IReverseRecords {
    //===== State =====//

    SNSEngine private immutable _engine;
    IShellFramework public immutable collection;

    //===== Constructor =====//

    constructor(address engine, address collection_) {
        _engine = SNSEngine(engine);
        collection = IShellFramework(collection_);
    }

    //===== External Functions

    function getNames(address[] calldata addresses) external view override returns (string[] memory) {
        string[] memory r = new string[](addresses.length);
        for(uint i = 0; i < addresses.length; i++) {
            uint256 tokenId = _engine.getNameId(collection, addresses[i]);
            string memory name_ = _engine.getNameFromTokenId(collection, tokenId);
            if (bytes(name_).length == 0) {
                continue;
            }
            r[i] = name_;
        }
        return r;
    }
}

// TODO set some royalties in constructor

contract SNSEngine is IEngine, SimpleRoyaltiesEngine {
    //===== State =====//

    uint256 constant MAX_INT = 2**256-1;

    //===== External Functions =====//

    // Get the name for this engine
    function getEngineName() external pure returns (string memory) {
        return "SNS v0.0.0";
    }

    // Called by the framework following an engine install. Can be used by the
    // engine to block (by reverting) installation if needed.
    // The engine MUST assert msg.sender == collection address!!
    function afterInstallEngine(IShellFramework collection) external {
        require(
            collection.supportsInterface(type(IShellERC721).interfaceId) &&
            collection.supportsInterface(type(IERC721Upgradeable).interfaceId),
            "SNS: collection must support IShellERC721"
        );
        require(msg.sender == address(collection), "SNS: msg.sender not collection");
        address snsAddr = address(new SNS(address(this), address(collection)));
        _setSNS(collection, snsAddr);
        // start with a price too expensive to buy so the owner can do a "fair release" at a lower price later
        setPrice(collection, MAX_INT);
    }

    function afterInstallEngine(IShellFramework, uint256) external pure {
        revert("SNS: cannot install engine to individual tokens");
    }

    function mintAndSet(IShellERC721 collection, string calldata name_) external payable returns (uint256) {
        // TODO re-entrancy guard might be needed in someone can reenter on receiving an ERC721?
        uint256 tokenId = mint(collection, msg.sender, name_);
        setName(collection, msg.sender, name_);
        return tokenId;
    }

    function withdraw(IShellERC721 collection) external {
        address owner = collection.owner();
        uint256 balance = getBalance(collection);
        _setBalance(collection, 0);
        // TODO re-entrancy guard to prevent re-entrancy on receiving ether?
        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "Failed to send Ether");
        // TODO send WETH if ETH fails
    }

    // Called by the collection to resolve a response for tokenURI
    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory) {
        return getNameFromTokenId(collection, tokenId);
    }

    // Called by the framework during a transfer, including mints (from=0) and
    // burns (to=0). Cannot break transfer even in the case of reverting, as the
    // collection will wrap the downstream call in a try/catch
    // The engine MUST assert msg.sender == collection address!!
    function beforeTokenTransfer(
        IShellFramework,
        address,
        address,
        address,
        uint256[] memory,
        uint256[] memory
    ) external pure {
        // TODO make it optional to add implementation here?
        return;
    }

    /**
     * From ENS: https://github.com/ensdomains/ens/blob/ff0f41747c05f1598973b0fe7ad0d9e09565dfcd/contracts/ReverseRegistrar.sol
     */
    function sha3HexAddress(address addr) external pure returns (bytes32 ret) {
        addr;
        ret; // Stop warning us about unused variables
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

            for { let i := 40 } gt(i, 0) { } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    //===== Public Functions

    function mint(IShellERC721 collection, address to, string calldata name_) public payable returns (uint256) {
        uint256 price = getPrice(collection);
        require(msg.value == price, "SNS: wrong msg.value");
        _setBalance(collection, getBalance(collection) + price);
        return _mint(collection, to, name_);
    }

    function setName(IShellERC721 collection, address holder, string calldata name_) public {
        uint256 tokenId = _getIdFromName(collection, name_);
        address tokenOwner = collection.ownerOf(tokenId);
        require(tokenOwner == holder, "SNS: name can only be set to its holder");
        address snsAddr = getSNSAddr(collection);
        require(snsAddr != address(0), "SNS: missing SNS address--call init");
        _setName(collection, holder, tokenId);
    }

    function getNames(IShellERC721 collection, address[] calldata holders) public view returns (string[] memory) {
        SNS sns = SNS(getSNSAddr(collection));
        return sns.getNames(holders);
    }

    function getSNSAddr(IShellERC721 collection) public view returns (address) {
        return address(uint160(
            collection.readCollectionInt(StorageLocation.ENGINE, _snsKey())
        ));
    }

    function getPrice(IShellERC721 collection) public view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, _priceKey());
    }

    function setPrice(IShellFramework collection, uint256 price) public {
        require(
            msg.sender == collection.owner() ||
            msg.sender == address(collection),
            "SNS: msg.sender not collection nor collection owner"
        );
        collection.writeCollectionInt(StorageLocation.ENGINE, _priceKey(), price);
    }

    function getBalance(IShellERC721 collection) public view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, _balanceKey(collection));
    }

    function getNameFromTokenId(IShellFramework collection, uint256 tokenId) public view returns (string memory) {
        return collection.readTokenString(StorageLocation.MINT_DATA, tokenId, _idToNameKey());
    }

    function getNameId(IShellFramework collection, address holder) public view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, _nameKey(holder));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IEngine).interfaceId;
    }

    //===== Private Functions =====//

    function _mint(IShellERC721 collection, address to, string calldata name_) private returns (uint256) {
        require(_getIdFromName(collection, name_) == 0, "SNS: name already minted");

        StringStorage[] memory stringData = new StringStorage[](1);
        stringData[0].key = _idToNameKey();
        stringData[0].value = name_;
        IntStorage[] memory intData = new IntStorage[](0);

        uint256 tokenId = collection.mint(MintEntry({
            to: to,
            amount: 1,
            options:
                // minimal storage for minimal gas cost
                MintOptions({
                    storeEngine: false,
                    storeMintedTo: false,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        collection.writeCollectionInt(StorageLocation.ENGINE, name_, tokenId);

        return tokenId;
    }

    // needs burn
    // function _burnNameOf(address nameHolder) private {}

    // needs burn
    // function _burnName(string calldata name) private {}

    function _snsKey() private pure returns (string memory) {
        return "SNS";
    }

    function _setSNS(IShellFramework collection, address snsAddr) private {
        collection.writeCollectionInt(
            StorageLocation.ENGINE,
            _snsKey(),
            uint256(uint160(snsAddr))
        );
    }

    function _priceKey() private pure returns (string memory) {
        return "PRICE";
    }

    function _balanceKey(IShellERC721 collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "BALANCE"));
    }

    function _setBalance(IShellERC721 collection, uint256 value) private {
        collection.writeCollectionInt(StorageLocation.ENGINE, _balanceKey(collection), value);
    }

    function _nameKey(address holder) private pure returns (string memory) {
        return string(abi.encodePacked(holder));
    }

    function _setName(IShellERC721 collection, address holder, uint256 tokenId) private {
        collection.writeCollectionInt(StorageLocation.ENGINE, _nameKey(holder), tokenId);
    }

    function _idToNameKey() private pure returns (string memory) {
        return "NAME";
    }

    function _getIdFromName(IShellERC721 collection, string calldata name_) private view returns (uint256) {
        return collection.readCollectionInt(StorageLocation.ENGINE, name_);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IReverseRecords {
    function getNames(address[] calldata) external view virtual returns (string[] memory r);
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

import "../IEngine.sol";
import {IShellFramework, StorageLocation} from "../IShellFramework.sol";

/**
 * Adds simple royalties into an engine: one royalties receiver with a stable percentage royalty in basis points
 */

abstract contract SimpleRoyaltiesEngine is IEngine {
    //===== External Functions =====//

    function getRoyaltyInfo(
        IShellFramework collection,
        uint256,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = address(uint160(
            collection.readCollectionInt(StorageLocation.ENGINE, _royaltyReceiverKey(collection))
        ));
        uint256 basisPoints = collection.readCollectionInt(StorageLocation.ENGINE, _royaltyBasisKey(collection));
        royaltyAmount = salePrice * basisPoints / 10000;
    }

    //===== Public Functions =====//

    function setRoyaltyInfo(
        IShellFramework collection,
        address receiver,
        uint256 royaltyBasisPoints
    ) public {
        require(msg.sender == collection.owner(), "SNS: msg.sender not collection owner");
        collection.writeCollectionInt(
            StorageLocation.ENGINE,
            _royaltyReceiverKey(collection),
            uint256(uint160(receiver))
        );
        collection.writeCollectionInt(StorageLocation.ENGINE, _royaltyBasisKey(collection), royaltyBasisPoints);
    }

    //===== Private Functions =====//

    function _royaltyReceiverKey(IShellFramework collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "ROYALTY_RECEIVER"));
    }

    function _royaltyBasisKey(IShellFramework collection) private pure returns (string memory) {
        return string(abi.encodePacked(address(collection), "ROYALTY_BASIS"));
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