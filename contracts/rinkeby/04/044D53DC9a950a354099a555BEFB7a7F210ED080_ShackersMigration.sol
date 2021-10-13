// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

interface IShackers is IERC721 {
    function mint(uint256 tokenId, address to, uint256 season) external;
}

contract ShackersMigration is ERC1155Receiver {
    address internal constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    IERC1155 public immutable OPENSEA_STORE;
    IShackers public immutable SHACKERS;
    uint160 internal immutable MAKER;

    event ShackerMigrated(address account, uint256 legacyTokenId, uint256 tokenId);

    constructor(
        address shackersAddress,
        address openSeaStoreAddress,
        address makerAddress
    ) {
        SHACKERS = IShackers(shackersAddress);
        OPENSEA_STORE = IERC1155(openSeaStoreAddress);
        MAKER = uint160(makerAddress);
    }

    // migration of a single shacker
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns(bytes4) {
        migrateLegacyShacker(id, from);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    // migration of multiple shackers
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns(bytes4) {
        for (uint256 i; i < ids.length; i++) {
            migrateLegacyShacker(ids[i], from);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice Migrates an OpenSea OG Shacker to this contract. The OG Shacker must have been transferred to this
     *   contract before. This method should only be called from `onERC1155Received` or `onERC1155BatchReceived`.
     */
    function migrateLegacyShacker(uint256 legacyTokenId, address owner) internal {
        uint256 tokenId = convertLegacyId(legacyTokenId);

        // burn OpenSea OG shacker
        OPENSEA_STORE.safeTransferFrom(address(this), BURN_ADDRESS, legacyTokenId, 1, "");

        // mint shiny new shacker
        // OG shackers were all in season 1
        SHACKERS.mint(tokenId, owner, 1);
        emit ShackerMigrated(owner, legacyTokenId, tokenId);
    }

    /**
     * Retrieves the token ID from a legacy token ID in OpenSea format.
     * - Requires the format of the legacyTokenId to match OpenSea format.
     * - Requires the encoded maker address to be S.H.A.C.K..
     *
     * @return Token ID; reverts if the legacy token ID did not match an OG Shacker.
     *
     * Thanks CyberKongz for the insights into OpenSea IDs!
     */
    function convertLegacyId(uint256 legacyTokenId) view public returns (uint256) {
        // first 20 bytes: check maker address
        if (uint160(legacyTokenId >> 96) != MAKER) {
            revert("Invalid Token (maker)");
        }

        // last 5 bytes: should always be 1
        if (legacyTokenId & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1) {
            revert("Invalid Token (checksum)");
        }

        // middle 7 bytes: nft id (serial for all NFTs maker minted)
        uint256 _id = (legacyTokenId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;

        // here comes the fun part; mapping of the legacy NFT IDs to IDs in this contract
        // OG Shackers 0-100 will be mapped to token IDs 1-101
        // Babies come thereafter
        if (_id > 203 && _id < 218) { // 204-217
            return _id - 117;
        } else if (_id > 10 && _id < 18) { // 11-17
            return _id - 3;
        } else if (_id > 77 && _id < 86) { // 78-85
            return _id - 35;
        } else if (_id > 51 && _id < 59) { // 52-58
            return _id - 24;
        } else if (_id > 18 && _id < 24) { // 19-23
            return _id - 4;
        } else if (_id > 68 && _id < 73) { // 69-72
            return _id - 32;
        } else if (_id > 5 && _id < 10) { // 6-9
            return _id - 2;
        } else if (_id > 0 && _id < 5) { // 1-4
            return _id - 1;
        } else if (_id > 137 && _id < 141) { // 138-140
            return _id - 70;
        } else if (_id > 111 && _id < 115) { // 112-114
            return _id - 55;
        } else if (_id > 28 && _id < 32) { // 29-31
            return _id - 7;
        } else if (_id > 58 && _id < 62) { // 59-61
            return _id + 47;
        } else if (_id > 171 && _id < 175) { // 172-174
            return _id - 57;
        } else if (_id == 26) {
            return 20;
        } else if (_id == 27) {
            return 21;
        } else if (_id == 34) {
            return 25;
        } else if (_id == 35) {
            return 26;
        } else if (_id == 50) {
            return 27;
        } else if (_id == 62) {
            return 35;
        } else if (_id == 67) {
            return 36;
        } else if (_id == 75) {
            return 41;
        } else if (_id == 76) {
            return 42;
        } else if (_id == 90) {
            return 51;
        } else if (_id == 91) {
            return 52;
        } else if (_id == 101) {
            return 53;
        } else if (_id == 103) {
            return 54;
        } else if (_id == 105) {
            return 55;
        } else if (_id == 108) {
            return 56;
        } else if (_id == 117) {
            return 60;
        } else if (_id == 119) {
            return 61;
        } else if (_id == 121) {
            return 62;
        } else if (_id == 123) {
            return 63;
        } else if (_id == 125) {
            return 64;
        } else if (_id == 127) {
            return 65;
        } else if (_id == 131) {
            return 66;
        } else if (_id == 135) {
            return 67;
        } else if (_id == 143) {
            return 71;
        } else if (_id == 145) {
            return 72;
        } else if (_id == 147) {
            return 73;
        } else if (_id == 148) {
            return 74;
        } else if (_id == 151) {
            return 75;
        } else if (_id == 162) {
            return 76;
        } else if (_id == 171) {
            return 77;
        } else if (_id == 180) {
            return 78;
        } else if (_id == 182) {
            return 79;
        } else if (_id == 189) {
            return 80;
        } else if (_id == 192) {
            return 81;
        } else if (_id == 193) {
            return 82;
        } else if (_id == 197) {
            return 83;
        } else if (_id == 199) {
            return 84;
        } else if (_id == 201) {
            return 85;
        } else if (_id == 202) {
            return 86;
        } else if (_id == 5) {
            return 101;
        } else if (_id == 10) {
            return 102;
        } else if (_id == 18) {
            return 103;
        } else if (_id == 32) {
            return 104;
        } else if (_id == 36) {
            return 105;
        } else if (_id == 92) {
            return 109;
        } else if (_id == 93) {
            return 110;
        } else if (_id == 102) {
            return 111;
        } else if (_id == 106) {
            return 112;
        } else if (_id == 107) {
            return 113;
        } else if (_id == 132) {
            return 114;
        } else if (_id == 177) {
            return 118;
        } else if (_id == 178) {
            return 119;
        } else if (_id == 200) {
            return 120; // max id for migration; must be same as initial _tokenIdCounter value
        }

        // reaching this means no valid legacy ID was matched
        revert("Invalid Token (no OG)");
    }
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

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}