// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.2;

import {FacetCut} from "contracts/shared/diamond/LibDiamond.sol";
import {LibAccessControl} from "contracts/shared/utility/LibAccessControl.sol";
import {LibMeta} from "contracts/shared/utility/LibMeta.sol";

struct AppStorage {
    string uriBase;
    address ChannelImplementation;
    address CollabImplementation;
    address ERC721Implementation;
    address ERC1155Implementation;
    uint256 masterfileCut;
    FacetCut[] requiredFacets;
    mapping(address => uint256) channelCollectionNonce;
    // Tracks if an address is a whitelisted ERC20 token that can be used for payments
    mapping(address => bool) isWhitelisted;
    // Tracks if address is a channel
    mapping(address => bool) isChannel;
    mapping(bytes4 => FacetCut) erc1155Feature;
    mapping(bytes4 => FacetCut) erc721Feature;
    // Stores which channel owns which collection
    mapping(address => address) collectionOwner;
}

struct DiamondArgs {
    address[] tokenWhitelist;
    address ChannelImplementation;
    address CollabImplementation;
    address ERC721Implementation;
    address ERC1155Implementation;
    string uriBase;
}

/**
 * @dev This is the base storage and interal functions of the Masterfile protocol
 * @custom:masterfile-hub This contract is part of the Masterfile Hub implementation
 */
library LibMasterfile {
    /**
     * @dev Calling this function give access to the state storage of the Masterfile protocol
     * @dev Since the storage here is implemented at slot 0, any contract that inherits `AppBase` can access a state variable by calling s.xxx
     */
    function appStorage() internal pure returns (AppStorage storage state) {
        // bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            state.slot := 0
        }
    }
}

/**
    @dev Base contract that Masterfile Facets inherit. Adds permissions and access to AppStorage
 */
contract AppBase {
    AppStorage internal s;

    /**
     * @notice Allows only channels who have been created through the Channel Factory to call
     */
    modifier onlyChannel() {
        require(s.isChannel[msg.sender]);
        _;
    }

    /**
     * @notice Allows only users with `Role` role to call function
     */
    modifier onlyRole(bytes32 role) {
        LibAccessControl._checkRole(role, LibMeta.msgSender());
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {AppBase, AppStorage} from "contracts/masterfile/LibMasterfile.sol";
import {IBazaar} from "./IBazaar.sol";
import {LibBazaar, BazaarStorage} from "./LibBazaar.sol";
import {LibMeta} from "contracts/shared/utility/LibMeta.sol";
import {Asset, Listing, FORGED_ASSET_STATUS, MINTED_ASSET_STATUS, DIRECT_LISTING_TYPE} from "contracts/shared/Schema.sol";
import {ITokenIssuance} from "contracts/token/ITokenIssuance.sol";

/**
 * @title Bazaar
 * @dev only handles straight sales with a set price. All other sale (Auctions, etc) will be handled in a different facet.
 */
contract Bazaar is AppBase, IBazaar {
    /**
     * @notice Get the identifier of a specific asset
     * @param asset Asset object to query. See `Schema.sol`
     * @return assetId Identifier of the Asset. Can be calculated in advance
     */
    function getAssetId(Asset memory asset)
        public
        pure
        override
        returns (bytes8 assetId)
    {
        return LibBazaar._getAssetId(asset);
    }

    /**
     * @notice Get Asset by assetId
     * @param assetId Identifier of the asset. Can be calculated in advance
     * @return asset Asset object. See `Schema.sol`
     */
    function getAsset(bytes8 assetId) public view returns (Asset memory asset) {
        return LibBazaar.bazaarStorage().assets[assetId];
    }

    /**
     * @notice Get identifier of a specific Listing
     * @param assetId Identifier of an asset. Can be calculated in advance
     * @param lister Address of the listing's initiator
     * @return listingId Identifier of the Listing. See `Schema.sol`
     */
    function getListingId(bytes8 assetId, address lister)
        public
        pure
        override
        returns (bytes8 listingId)
    {
        return LibBazaar._getListingId(assetId, lister);
    }

    /**
     * @notice Get Listing by listingId
     * @param listingId Identifier of the listing. Can be calculated in advance
     * @return listing Listing object. See `Schema.sol`
     */
    function getListing(bytes8 listingId)
        public
        view
        returns (Listing memory listing)
    {
        return LibBazaar.bazaarStorage().listings[listingId];
    }

    /**
     * @notice Create new Listing
     * @dev Returns identifiers of asset and listing
     * @dev Creates new listing and store in Bazaar storage
     * @param asset Asset object. See `Schema.sol`
     * @param listing Listing object. See `Schema.sol`
     * @return assetId Identifier of the Asset. Can be calculated in advance
     * @return listingId Identifier of the Listing. Can be calculated in advance
     */
    function createListing(Asset memory asset, Listing memory listing)
        public
        override
        returns (bytes8 assetId, bytes8 listingId)
    {
        // Error check listing
        require(listing.quantity > 0, "Bazaar Error: Invalid quantity");
        require(
            listing.endDate > listing.startDate &&
                listing.endDate > block.timestamp,
            "Bazaar Error: Invalid Dates"
        );
        require(
            s.isWhitelisted[listing.paymentToken],
            "Bazaar Error: Payment Token"
        );
        // Error checking of assetClass is done in `_checkBalance`
        // Error checking of assetStatus is done below

        // Error checking of listingType is also done when executing listing (buying or bidding).
        require(
            // TODO: Add more checks as we add listing types
            listing.listingType == DIRECT_LISTING_TYPE,
            "Bazaar: Invalid Listing Type"
        );
        address lister = LibMeta.msgSender();

        BazaarStorage storage store = LibBazaar.bazaarStorage();

        assetId = LibBazaar._getAssetId(asset);

        // override provided assetId
        listing.assetId = assetId;

        listingId = LibBazaar._getListingId(assetId, lister);

        if (asset.assetStatus == FORGED_ASSET_STATUS) {
            // Make sure channel owns collection
            require(
                s.collectionOwner[asset.collection] == lister,
                "Bazaar Error: Invalid Collection"
            );

            // Make sure listing quantity is less than or equal to remaining quanity
            require(
                ITokenIssuance(asset.collection).getRemainingQuantity(
                    asset.tokenNonceOrId
                ) >= listing.quantity,
                "Bazaar Error: Invalid quantity"
            );
        } else if (asset.assetStatus == MINTED_ASSET_STATUS) {
            // Make sure collection exsists
            require(
                s.collectionOwner[asset.collection] != address(0),
                "Bazaar Error: Invalid Collection"
            );

            // Move asset to Bazaar
            require(
                LibBazaar._transferAsset(
                    asset.collection,
                    address(this),
                    lister,
                    asset.tokenNonceOrId,
                    listing.quantity,
                    asset.assetClass
                ),
                "Bazaar Error: Invalid transfer"
            );
        } else {
            revert("Invalid Asset Status");
        }
        // store asset details
        store.assets[assetId] = asset;
        // store listing
        store.listings[listingId] = listing;
        store.listingOwner[listingId] = lister;

        emit ListingCreated(assetId, listingId, asset, listing, lister);
    }

    /**
     * @notice Update existing Listing
     * @param listingId Identifier of the Listing to update
     * @param newListing Updated Listing object. See `Schema.sol`
     */
    function updateListing(bytes8 listingId, Listing memory newListing)
        public
        override
    {
        address lister = LibMeta.msgSender();
        BazaarStorage storage store = LibBazaar.bazaarStorage();
        Listing memory listing = store.listings[listingId];
        Asset memory asset = store.assets[listing.assetId];
        // Check that caller owns listing
        require(
            store.listingOwner[listingId] == lister,
            "Bazaar: Invalid listing owner"
        );
        // Check that auctions aren't active
        require(!store.liveAuction[listingId], "Bazaar: Live Auction");
        // Check that new listing is for same assetId
        require(
            listing.assetId == newListing.assetId,
            "Bazaar: Invalid assetId"
        );

        // Check that lister owns at least quantity
        if (asset.assetStatus == FORGED_ASSET_STATUS) {
            // TODO: How to handle?
        } else if (asset.assetStatus == MINTED_ASSET_STATUS) {
            if (newListing.quantity == 0) {
                revert("Bazaar: Invalid quantity");
            } else if (newListing.quantity > listing.quantity) {
                // If increasing quantity, transfer difference to Bazaar
                require(
                    LibBazaar._transferAsset(
                        asset.collection,
                        address(this),
                        lister,
                        asset.tokenNonceOrId,
                        (newListing.quantity - listing.quantity),
                        asset.assetClass
                    ),
                    "Bazaar Error: Invalid transfer"
                );
            } else if (listing.quantity > newListing.quantity) {
                // If increasing quantity, transfer difference back to lister
                require(
                    LibBazaar._transferAsset(
                        asset.collection,
                        lister,
                        address(this),
                        asset.tokenNonceOrId,
                        (listing.quantity - newListing.quantity),
                        asset.assetClass
                    ),
                    "Bazaar Error: Invalid transfer"
                );
            } else {
                // Just in case something slips through
                revert("Invalid Asset Status");
            }
        }

        // Update listing
        store.listings[listingId] = newListing;
        emit ListingUpdated(listingId, newListing);
    }

    /**
     * @notice Remove existing Listing
     * @param listingId Identifier of the Listing. Can be calculated in advance
     */
    function removeListing(bytes8 listingId) public override {
        address lister = LibMeta.msgSender();
        BazaarStorage storage store = LibBazaar.bazaarStorage();
        Listing memory listing = store.listings[listingId];
        Asset memory asset = store.assets[listing.assetId];
        // Check that caller owns listing
        require(
            LibBazaar._getListingId(listing.assetId, lister) == listingId,
            "Bazaar: Invalid listing"
        );
        // Check that auctions aren't active
        require(!store.liveAuction[listingId], "Bazaar: Live Auction");

        // Transfer back to lister
        // Check that lister owns at least quantity
        if (asset.assetStatus == FORGED_ASSET_STATUS) {
            // TODO: How to handle?
        } else if (asset.assetStatus == MINTED_ASSET_STATUS) {
            require(
                LibBazaar._transferAsset(
                    asset.collection,
                    lister,
                    address(this),
                    asset.tokenNonceOrId,
                    listing.quantity,
                    asset.assetClass
                ),
                "Bazaar Error: Invalid transfer"
            );
        }

        // remove listing
        delete store.listings[listingId];
        emit ListingRemoved(listingId);
    }

    // TODO: Make non-reentrant
    function executeDirectListing(bytes8 listingId, uint256 quantity) public {
        address buyer = LibMeta.msgSender();
        BazaarStorage storage store = LibBazaar.bazaarStorage();
        Listing memory listing = store.listings[listingId];
        Asset memory asset = store.assets[listing.assetId];
        // Check this is a direct listing
        require(
            listing.listingType == DIRECT_LISTING_TYPE,
            "Bazaar: Not a direct listing"
        );
        // Check still valid listing
        require(
            listing.startDate <= block.timestamp &&
                listing.endDate >= block.timestamp,
            "Bazaar: Outside listing timeframe"
        );
        require(listing.quantity >= quantity, "Bazaar: Invalid order quantity");

        // Update listing
        if (listing.quantity == quantity) {
            // sold out, delete listing
            delete store.listings[listingId];
        } else {
            listing.quantity = listing.quantity - quantity;
            store.listings[listingId] = listing;
        }

        address seller = store.listingOwner[listingId];

        // Process sale
        LibBazaar._processSale(
            asset,
            buyer,
            seller,
            quantity,
            listing.initialPrice,
            listing.paymentToken
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Asset, Listing} from "contracts/shared/Schema.sol";

interface IBazaar {
    event ListingCreated(
        bytes8 indexed assetId,
        bytes8 indexed listingId,
        Asset asset,
        Listing listing,
        address indexed lister
    );
    event ListingUpdated(bytes8 indexed listingId, Listing listing);
    event ListingRemoved(bytes8 indexed listingId);

    function getAssetId(Asset memory asset) external returns (bytes8 assetId);

    function getListingId(bytes8 assetId, address lister)
        external
        returns (bytes8 listingId);

    function createListing(Asset memory asset, Listing memory listing)
        external
        returns (bytes8 assetId, bytes8 listingId);

    function updateListing(bytes8 listingId, Listing memory newListing)
        external;

    function removeListing(bytes8 listingId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {LibMasterfile} from "contracts/masterfile/LibMasterfile.sol";
import {Asset, Listing, ASSET_TYPEHASH, LISTING_ID_TYPEHASH, ERC20_ASSET_CLASS, ERC721_ASSET_CLASS, ERC1155_ASSET_CLASS, FORGED_ASSET_STATUS, MINTED_ASSET_STATUS} from "contracts/shared/Schema.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC2981} from "contracts/token/royalties/IERC2981.sol";
import {ITokenIssuance} from "contracts/token/ITokenIssuance.sol";

struct BazaarStorage {
    // assetId => asset
    mapping(bytes8 => Asset) assets;
    // listingId => listing
    mapping(bytes8 => Listing) listings;
    // listingId => listingOwner
    mapping(bytes8 => address) listingOwner;
    // listingId => live auction (Place holder)
    mapping(bytes8 => bool) liveAuction;
}

library LibBazaar {
    bytes32 constant BAZAAR_STORAGE_POSITION =
        keccak256("masterfile.app.bazaar");

    function bazaarStorage()
        internal
        pure
        returns (BazaarStorage storage state)
    {
        bytes32 position = BAZAAR_STORAGE_POSITION;
        assembly {
            state.slot := position
        }
    }

    /**
     * @notice Get the identifier of a specific asset
     * @param asset Asset object to query. See `Schema.sol`
     * @return assetId Identifier of the Asset. Can be calculated in advance
     */
    function _getAssetId(Asset memory asset)
        internal
        pure
        returns (bytes8 assetId)
    {
        // Using bytes8 to avoid collsions because I am paranoid
        return bytes8(keccak256((abi.encode(ASSET_TYPEHASH, asset))));
    }

    /**
     * @notice Get identifier of a specific Listing
     * @param assetId Identifier of an asset. Can be calculated in advance
     * @param lister Address of the listing's initiator
     * @return listingId Identifier of the Listing. See `Schema.sol`
     */
    function _getListingId(bytes8 assetId, address lister)
        internal
        pure
        returns (bytes8 listingId)
    {
        // Using bytes8 to avoid collsions because I am paranoid
        return
            bytes8(
                keccak256((abi.encode(LISTING_ID_TYPEHASH, assetId, lister)))
            );
    }

    /**
     * @notice Check Token Balance
     * @dev test all plase
     * @param collection Asset collection address
     * @param user Address to check balance
     * @param tokenId Identifier of the token
     * @param assetClass ERC20 | ERC721 | ERC1155 Asset classes
     * @return balance Token balance of the user
     */
    function _checkBalance(
        address collection,
        address user,
        uint256 tokenId,
        bytes4 assetClass
    ) internal view returns (uint256 balance) {
        if (assetClass == ERC20_ASSET_CLASS) {
            return IERC20(collection).balanceOf(user);
        } else if (assetClass == ERC721_ASSET_CLASS) {
            if (user == IERC721(collection).ownerOf(tokenId)) {
                return 1;
            } else {
                return 0;
            }
        } else if (assetClass == ERC1155_ASSET_CLASS) {
            return IERC1155(collection).balanceOf(user, tokenId);
        } else {
            revert("Invalid Asset Class");
        }
    }

    /**
     * @notice Transfer ERC20 | ERC721 | ERC1155 Asset
     * @param collection Asset collection address
     * @param to Asset recipient
     * @param from Asset sender
     * @param tokenId Token identifier of an asset
     * @param quantity Quantity to transfer
     * @param assetClass Class type of an asset ERC20 | ERC721 | ERC1155
     * @return transferComplete True if transfer is successful otherwise false
     */
    function _transferAsset(
        address collection,
        address to,
        address from,
        uint256 tokenId,
        uint256 quantity,
        bytes4 assetClass
    ) internal returns (bool transferComplete) {
        uint256 initialBal;
        uint256 finalBal;

        if (assetClass == ERC20_ASSET_CLASS) {
            initialBal = IERC20(collection).balanceOf(to);
            IERC20(collection).transferFrom(from, to, quantity);
            finalBal = IERC20(collection).balanceOf(to);
            require(
                finalBal == initialBal + quantity,
                "Transfer Error: Quantity not transfered"
            );
        } else if (assetClass == ERC721_ASSET_CLASS) {
            require(quantity == 1, "Transfer Error: Invalid quantity");
            require(
                from == IERC721(collection).ownerOf(tokenId),
                "TransferError: Invalid Owner"
            );
            IERC721(collection).safeTransferFrom(from, to, tokenId);
            require(
                to == IERC721(collection).ownerOf(tokenId),
                "TransferError: Invalid Owner"
            );
        } else if (assetClass == ERC1155_ASSET_CLASS) {
            initialBal = IERC1155(collection).balanceOf(to, tokenId);
            IERC1155(collection).safeTransferFrom(
                from,
                to,
                tokenId,
                quantity,
                bytes("0x0")
            );
            finalBal = IERC1155(collection).balanceOf(to, tokenId);
            require(
                finalBal == initialBal + quantity,
                "Transfer Error: Quantity not transfered"
            );
        } else {
            revert("Invalid Asset Class");
        }

        return true;
    }

    /**
     * @notice Process the sale of an Asset
     * @param asset Asset object. See `Schema.sol`
     * @param buyer Buyer of the asset
     * @param seller Seller of the asset
     * @param assetQuantity Quantity of asset for sale
     * @param unitPayment Payment per unit of the asset
     * @param paymentToken Token address for the payment
     */
    function _processSale(
        Asset memory asset,
        address buyer,
        address seller,
        uint256 assetQuantity,
        uint256 unitPayment,
        address paymentToken
    ) internal {
        uint256 totalPayment = unitPayment * assetQuantity;
        uint256 remainingPayment = totalPayment;
        {
            // process sale fee
            uint256 saleFee = (remainingPayment *
                LibMasterfile.appStorage().masterfileCut) / 100000;

            _transferAsset(
                paymentToken,
                address(this),
                buyer,
                0,
                saleFee,
                ERC20_ASSET_CLASS
            );

            remainingPayment -= saleFee;
        }

        // process remaining payments
        if (asset.assetStatus == FORGED_ASSET_STATUS) {
            {
                (address royaltyRecipient, ) = IERC2981(asset.collection)
                .royaltyInfo(asset.tokenNonceOrId << 128, totalPayment);
                // The << 128 mimics this tokenNonce as a tokenId

                // Send all to royalty recipient since this is an initial sale
                _transferAsset(
                    paymentToken,
                    royaltyRecipient,
                    buyer,
                    0,
                    remainingPayment,
                    ERC20_ASSET_CLASS
                );

                // mint asset to buyer
                ITokenIssuance(asset.collection).mintTokensFor(
                    asset.tokenNonceOrId,
                    buyer,
                    assetQuantity,
                    bytes("0x0")
                );
            }
        } else if (asset.assetStatus == MINTED_ASSET_STATUS) {
            {
                // process royalties
                (address royaltyRecipient, uint256 royaltyAmount) = IERC2981(
                    asset.collection
                ).royaltyInfo(asset.tokenNonceOrId, totalPayment);

                // Send all to royalty recipient since this is an initial sale
                _transferAsset(
                    paymentToken,
                    royaltyRecipient,
                    buyer,
                    0,
                    royaltyAmount,
                    ERC20_ASSET_CLASS
                );
                remainingPayment -= royaltyAmount;
                // send remaining payment to seller
                _transferAsset(
                    paymentToken,
                    seller,
                    buyer,
                    0,
                    remainingPayment,
                    ERC20_ASSET_CLASS
                );

                // send asset to buyer
                _transferAsset(
                    asset.collection,
                    buyer,
                    seller,
                    asset.tokenNonceOrId,
                    assetQuantity,
                    asset.assetClass
                );
            }
        } else {
            revert("Invalid Asset Class");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

struct Signature {
    bytes32 sigR;
    bytes32 sigS;
    uint8 sigV;
}

// Yoinked from Rarible: https://github.com/rariblecom/protocol-contracts/blob/master/royalties/contracts/LibPart.sol
struct Part {
    address payable account;
    uint96 value;
}

struct TokenDetail {
    string arweaveHash;
    uint256 maxQuantity;
    address payable royaltyRecipient;
    uint96 royaltyBps;
}

struct Roles {
    bytes32[] roles;
}

struct InitialSaleListing {
    address collection;
    uint256 startDate;
    uint256 endDate;
}

bytes32 constant ASSET_TYPEHASH = keccak256(
    "Asset(bytes4 assetClass,bytes4 assetStatus,address collection,uint256 tokenNonceOrId)"
);

bytes4 constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
bytes4 constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
bytes4 constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
bytes4 constant FORGED_ASSET_STATUS = bytes4(keccak256("FORGED"));
bytes4 constant MINTED_ASSET_STATUS = bytes4(keccak256("MINTED"));

struct Asset {
    // assetClass Options:
    // - ERC721: bytes4(keccak256("ERC721"));
    // - ERC1155: bytes4(keccak256("ERC1155"));
    bytes4 assetClass;
    // assetStatus Options:
    // - Forged (Not yet minted): bytes4(keccak256("FORGED"));
    // - Minted: bytes4(keccak256("MINTED"));
    bytes4 assetStatus;
    // Address where token is deployed
    address collection;
    // If issued, this is tokenNonce
    // If minted, this is tokenId
    uint256 tokenNonceOrId;
}

bytes32 constant LISTING_TYPEHASH = keccak256(
    "Listing(bytes4 assetId,bytes4 listingType,uint256 startDate,uint256 endDate,uint256 quantity,uint256 initialPrice,address paymentToken)"
);

bytes32 constant LISTING_ID_TYPEHASH = keccak256(
    "ListingId(bytes4 assetId,address lister)"
);

bytes4 constant DIRECT_LISTING_TYPE = bytes4(keccak256("DIRECT"));

// Goal is to make this listing type as extensible as possible
// i.e. be able to be used for direct listings, auctions, etc.
struct Listing {
    // Hashed asset selector
    bytes8 assetId;
    // listingType Options:
    // - Direct (One asking price): bytes4(keccak256("DIRECT"));
    bytes4 listingType;
    uint256 startDate;
    uint256 endDate;
    // usually one except for initial listings. Also leaves options open for semi-fungible tokens in the future
    uint256 quantity;
    // Called initial price because it may act like a reserve (english auction), price to decrease from (dutch auction), or just unit price (direct listing)
    uint256 initialPrice;
    address paymentToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// import { IDiamondCut } from "./IDiamondCut.sol";

enum FacetCutAction {
    Add,
    Replace,
    Remove
}

struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
}

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // If diamond has been initialized
        bool initialized;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        if (selectorCount & 7 > 0) {
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @notice Add, Replace, Remove a Facet Selector from/to a Diamond
     * @param _selectorCount Number of selectors
     * @param _selectorSlot Slots of the selectors
     * @param _newFacetAddress New facet address of the selectors
     * @param _action Facet action Add | Replace | Remove
     * @param _selectors Selectors to add/replace/remove
     * @dev Returns _selectorCount and _selectorSlot
     */
    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(
            _selectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        if (_action == FacetCutAction.Add) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Add facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibDiamondCut: Can't add function that already exists"
                );
                // add facet for selector
                ds.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == FacetCutAction.Replace) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "LibDiamondCut: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "LibDiamondCut: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "LibDiamondCut: Can't replace function that doesn't exist"
                );
                // replace old facet address
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "LibDiamondCut: Remove facet address must be address(0)"
            );
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibDiamondCut: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibDiamondCut: Can't remove immutable function"
                    );
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    /**
     * @notice Initialize a new diamond cut
     * @param _init Address of the contract or facet to execute _calldata
     * @param _calldata Data to delegateCall to the `_init` address
     */
    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }
    /**
     * @notice Require the contract to have a code data
     * @param _contract Contract address
     * @param _errorMessage Custom Error message if code is not found
     */
    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0 || _contract == address(this), _errorMessage);
    }
}

/**
 * @title DiamondBase
 */
contract DiamondBase {
    modifier initializer() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(!ds.initialized, "DiamondError: Already initialize");
        ds.initialized = true;
        _;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    /**
     * @notice all non-Diamond function calls are caught but this fallback and then, if it is an approved Facet function, delegated to that function. Context is always kept from this Contract address/memory
     */
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { LibMeta } from "./LibMeta.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct RoleData {
  mapping(address => bool) members;
  bytes32 adminRole;
}

struct AccessControlStorage {
  mapping(bytes32 => RoleData) _roles;
}

library LibAccessControl {
  bytes32 constant APP_STORAGE_POSITION =
    keccak256("masterfile.app.accessControl");

  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  function accessControlStorage()
    internal
    pure
    returns (AccessControlStorage storage state)
  {
    bytes32 position = APP_STORAGE_POSITION;
    assembly {
      state.slot := position
    }
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   * @param role Hash of role's name
   * @param account Account to check if it has the role
   * @return doesHaveRole true if account has the role otherwise false
   */
  function _hasRole(bytes32 role, address account)
    internal
    view
    returns (bool)
  {
    return accessControlStorage()._roles[role].members[account];
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   *
   * @param role Hash of the role's name
   * @return admin 
   */
  function _getRoleAdmin(bytes32 role) internal view returns (bytes32) {
    return LibAccessControl.accessControlStorage()._roles[role].adminRole;
  }

  function _checkSenderRole(bytes32 role) internal view {
    _checkRole(role, LibMeta.msgSender());
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
   */
  function _checkRole(bytes32 role, address account) internal view {
    if (!_hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            "AccessControl: account ",
            Strings.toHexString(uint160(account), 20),
            " is missing role ",
            Strings.toHexString(uint256(role), 32)
          )
        )
      );
    }
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   */
  function _setupRole(bytes32 role, address account) internal {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
    emit RoleAdminChanged(role, _getRoleAdmin(role), adminRole);
    accessControlStorage()._roles[role].adminRole = adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   * 
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   * @param role Hash of the role's name
   * @param account Account to be granted a role with
   */
  function _grantRole(bytes32 role, address account) internal {
    if (!_hasRole(role, account)) {
      accessControlStorage()._roles[role].members[account] = true;
      emit RoleGranted(role, account, LibMeta.msgSender());
    }
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   * @param role Hash of the role's name
   * @param account Account to be renounced a role with
   */
  function _renounceRole(bytes32 role, address account) internal {
    require(
      account == LibMeta.msgSender(),
      "AccessControl: can only renounce roles for self"
    );
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   * @param role Hash of the role's name
   * @param account Account to be revoked a role with
   */
  function _revokeRole(bytes32 role, address account) internal {
    if (_hasRole(role, account)) {
      accessControlStorage()._roles[role].members[account] = false;
      emit RoleRevoked(role, account, LibMeta.msgSender());
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

struct MetaStorage {
  bytes32 domainSeparator;
  mapping(address => uint256) nonces; // Meta transaction nonces
}

library LibMeta {
  bytes32 constant APP_STORAGE_POSITION =
    keccak256("masterfile.app.metatransactions");
  bytes32 constant META_TRANSACTION_TYPEHASH =
    keccak256(
      bytes(
        "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
      )
    );

  function metaStorage() internal pure returns (MetaStorage storage state) {
    bytes32 position = APP_STORAGE_POSITION;
    assembly {
      state.slot := position
    }
  }

  function _getChainID() internal view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function _verify(
    address owner,
    uint256 nonce,
    uint256 chainID,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) internal view returns (bool) {
    bytes32 hash = prefixed(
      keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
    );
    address signer = ecrecover(hash, sigV, sigR, sigS);
    require(signer != address(0), "Invalid signature");
    return (owner == signer);
  }

  // Builds a prefixed hash to mimic the behavior of eth_sign.
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  function msgSender() internal view returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      return msg.sender;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TokenDetail} from "contracts/shared/Schema.sol";

/**
 * @notice A shared issuance interface between ERC721 and ERC1155 contracts
 */
interface ITokenIssuance {
    /**
     * @dev emitted every time a channel issues a new token
     */
    event ForgingCreated(uint256 tokenNonce, TokenDetail tokenDetail);

    function getForgingIdFromToken(uint256 tokenId)
        external
        view
        returns (uint256 nonce);

    function getForgingIdsFromTokens(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory nonce);

    function getDetailsByForging(uint256 nonce)
        external
        returns (TokenDetail memory details);

    function getDetailsById(uint256 tokenId)
        external
        returns (TokenDetail memory details);

    function getTokenEdition(uint256 tokenId)
        external
        returns (uint256 edition);

    function getRemainingQuantity(uint256 tokenNonce)
        external
        returns (uint256 remaining);

    function createForging(TokenDetail memory tokenDetail)
        external
        returns (uint256 tokenNonce);

    function mintTokensFor(
        uint256 tokenNonce,
        address to,
        uint256 quantity,
        bytes memory data
    ) external returns (uint256[] memory tokenIds);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

}

