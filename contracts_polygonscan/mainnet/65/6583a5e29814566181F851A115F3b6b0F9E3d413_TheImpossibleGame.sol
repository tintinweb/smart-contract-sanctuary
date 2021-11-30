/**
 *Submitted for verification at polygonscan.com on 2021-11-30
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

// File: @openzeppelin/contracts/interfaces/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC1155.sol


// OpenZeppelin Contracts v4.4.0 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: Token.sol


pragma solidity ^0.8.0;








/**
 * @title TokenIdentifiers
 * support for authentication and metadata for token ids
 */
library TokenIdentifiers {
    uint8 constant ADDRESS_BITS = 160;
    uint8 constant INDEX_BITS = 56;
    uint8 constant SUPPLY_BITS = 40;
    
    uint256 constant SUPPLY_MASK =  0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF;
    uint256 constant INDEX_MASK =   0x0000000000000000000000000000000000000000FFFFFFFFFFFFFF0000000000;
    uint256 constant INDEX_INCR =   0x0000000000000000000000000000000000000000000000000000010000000000;
    uint256 constant CREATOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;

    function tokenVersion(uint256 _id) internal pure returns (uint256) {
        return _id & SUPPLY_MASK;
    }

    function tokenIndex(uint256 _id) internal pure returns (uint256) {
        return (_id >> SUPPLY_BITS) & INDEX_MASK;
    }

    function tokenCreator(uint256 _id) internal pure returns (address) {
        return address(uint160(_id >> (INDEX_BITS + SUPPLY_BITS)));
    }
    
    function nextIndex(uint256 _id) internal pure returns (uint256) {
        return _id + INDEX_INCR;
    }
    
    function minIndex(uint256 _id) internal pure returns (uint256) {
        return _id & CREATOR_MASK + 1;
    }
}

struct stakedNFT {
    address _contract;
    uint256 _id;
    uint128 _blockStart;
    uint64 _rarity;
    uint56 _usageFee;
    uint8 _contractType;
}

library stakedNFTHelper {
    uint8 public constant ERC721 = 0x01;
    uint8 public constant ERC1155 = 0x00;
    
    function currentValue(stakedNFT storage _nft) internal view returns (uint256) {
        return (block.number - _nft._blockStart) * _nft._rarity;
    }
}

struct IndexValue { uint256 keyIndex; stakedNFT value; }
struct KeyFlag { uint256 key; bool deleted; }

struct itmap {
    mapping(uint256 => IndexValue) data;
    KeyFlag[] keys;
    uint size;
}

library IterableMapping {
    function insert(itmap storage self, uint256 key, stakedNFT storage value) internal returns (bool replaced) {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(itmap storage self, uint256 key) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }
    
    function get(itmap storage self, uint256 key) internal view returns (stakedNFT storage value) {
        return self.data[key].value;
    }

    function contains(itmap storage self, uint256 key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterate_start(itmap storage self) internal view returns (uint256 keyIndex) {
        return iterate_next(self, type(uint).max);
    }

    function iterate_valid(itmap storage self, uint256 keyIndex) internal view returns (bool) {
        return keyIndex < self.keys.length;
    }

    function iterate_next(itmap storage self, uint256 keyIndex) internal view returns (uint256 r_keyIndex) {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }

    function iterate_get(itmap storage self, uint256 keyIndex) internal view returns (uint256 key, stakedNFT storage value) {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
}

contract ZXVCManager { }

contract ZXVC is Ownable, ERC20("ZXVC", "ZXVC") {
    mapping(address => bool) private _approvedMinters;
    
    mapping(address => address) private _managedTokens;
    
    event AddedStaker(address staker);
    event RemoveStaker(address staker);
    event MintedTokensFor(address account, uint256 quantity);
    
    constructor() {
        TheImpossibleGame _staker = new TheImpossibleGame(this, _msgSender());
        _approvedMinters[address(_msgSender())] = true;
        _approvedMinters[address(_staker)] = true;
        emit AddedStaker(address(_staker));
    }
    
    function createAccount(address _target) public {
        if(_managedTokens[_target] == address(0)) {
            _managedTokens[_target] = address(new ZXVCManager());
        }
    }
    
    function depositAddress(address _target) public view returns (address) {
        return _managedTokens[_target];
    }
    
    function batchMint(address[] calldata _targets, uint256[] calldata _quantities) public {
        require(_approvedMinters[_msgSender()]);
        require(_targets.length == _quantities.length);
        for(uint i = 0; i < _targets.length; i++) {
            mint(_targets[i], _quantities[i]);
        }
    }
    
    function mint(address _target, uint256 _quantity) public {
        require(_approvedMinters[_msgSender()]);
        createAccount(_target);
        _mint(_managedTokens[_target], _quantity);
        emit MintedTokensFor(_target, _quantity);
    }
    
    function burn(uint256 _quantity) public {
        require(_approvedMinters[_msgSender()]);
        _burn(_msgSender(), _quantity);
    }
    
    function managedTransfer(address _from, address _to, uint256 _quantity) public {
        require(_approvedMinters[_msgSender()]);
        require(balanceOf(_managedTokens[_from]) >= _quantity);
        _transfer(_managedTokens[_from], _to, _quantity);
    }
    
    function withdraw(address _target, uint256 _quantity) public {
        managedTransfer(_target,_target,_quantity);
    }
    
    function addMinter(address _staker) external {
        require(_msgSender() == owner());
        _approvedMinters[_staker] = true;
        emit AddedStaker(_staker);
    }
    
    function removeMinter(address _staker) external {
        require(_msgSender() == owner());
        _approvedMinters[_staker] = false;
        emit RemoveStaker(_staker);
    }
    
    function decimals() public view virtual override returns (uint8) {
      return 9;
    }
    
    function destroy() public {
        require(_msgSender() == owner());
        selfdestruct(payable(owner()));
    }
}

contract TheImpossibleGame is Ownable, IERC1155Receiver, IERC721Receiver, ERC165 {
    using TokenIdentifiers for uint256;
    using IterableMapping for itmap;
    using stakedNFTHelper for stakedNFT;
    
    mapping(uint256 => uint64) private _rarities;
    mapping(address => itmap) private _stakedNFTs;
    mapping(uint256 => address) public _stakedToOwner;
    mapping(address => uint256) public _mintbotTokens;
    
    mapping(address => bool) private _validSourceContracts; //linked NFT contract
    
    bool private _active = false;
    uint256 private _airDropMaxID;
    address private _airDropContract;
    mapping(uint256 => bool) public _airDropClaimed;
    
    ZXVC public _token;
    uint256 public _baseReward = 66667;

    uint256 public _mintbotTokenID = uint256(84436295188037170819729163282069840282005888216225721239977657117845741381392);
    uint256 public _currentMintbotPrice = uint256(100000000000);
    uint256 public _mintbotTokensSold = 0;
    uint256 public _mintbotPriceExp = 200;
    
    event NftStaked(address staker, address collection, uint256 tokenId, uint256 block, uint8 contractType);
    event NftUnStaked(address staker, address collection, uint256 tokenId, uint256 block, uint8 contractType);
    event AirdropClaimed(address collector, uint256 tokenId, uint256 value);
    event UsageFeeSet(address collector, uint256 tokenId, uint256 value);
    
    constructor(ZXVC token, address owner) {
        _token = token;
        _airDropContract = address(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        _validSourceContracts[_airDropContract] = true;
        transferOwnership(owner);
        IERC1155(_airDropContract).setApprovalForAll(owner, true);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function setActive(bool state) public {
        require(_msgSender() == owner());
        _active = state;
    }
    
    function setBaseRequest(uint64 baseReward) public {
        require(_msgSender() == owner());
        _baseReward = baseReward;
    }
    
    function setAirDropMaxID(uint256 tokenID) public {
        require(_msgSender() == owner());
        _active = true;
        _airDropMaxID = tokenID;
    }
    
    function addSourceContract(address _contract, uint8 _type) public {
        require(_msgSender() == owner());
        _validSourceContracts[_contract] = true;
        if(_type == stakedNFTHelper.ERC1155) {
            IERC1155(_contract).setApprovalForAll(owner(), true);
        } else if(_type == stakedNFTHelper.ERC721) {
            IERC721(_contract).setApprovalForAll(owner(), true);
        } else { require(false, "Impossible!"); }
    }
    
    function bulkAddTrippy(uint256[] memory _tokenIds) public {
        require(_msgSender() == owner());
        for(uint32 i = 0; i < _tokenIds.length; i++) {
            _rarities[_tokenIds[i]] = uint64(_baseReward);
        }
    }
    
    function bulkAddAnimated(uint256[] memory _tokenIds) public {
        require(_msgSender() == owner());
        for(uint32 i = 0; i < _tokenIds.length; i++) {
            _rarities[_tokenIds[i]] = uint64(_baseReward)*2;
        }
    }
    
    function bulkAddGilded(uint256[] memory _tokenIds) public {
        require(_msgSender() == owner());
        for(uint32 i = 0; i < _tokenIds.length; i++) {
            _rarities[_tokenIds[i]] = uint64(_baseReward)*4;
        }
    }
    
    function checkMinIndex(uint256 tokenID) public pure returns (uint256) {
        return tokenID.minIndex();
    }
    
    function checkNextIndex(uint256 tokenID) public pure returns (uint256) {
        return tokenID.nextIndex();
    }
    
    function claimableAirdrop(address _owner, uint256 tokenID) public view returns (bool) {
        require(_active, "Not yet Active");
        if(IERC1155(_airDropContract).balanceOf(_owner, tokenID) > 0) {
            if(address(0xbAad3fde86fAA3B42D6A047060308E49A24Ec9E7) == tokenID.tokenCreator()) {
                if(tokenID.tokenIndex() <= _airDropMaxID.tokenIndex()) {
                    if(!_airDropClaimed[tokenID]) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    function claimBatchAirDrop(address _owner, uint256[] calldata _tokenIds) public returns (uint256) {
        require(_active, "Not yet Active");
        uint256 _value = 0;
        for(uint8 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenID = _tokenIds[i];
            if(claimableAirdrop(_owner, tokenID)){
                _airDropClaimed[tokenID] = true;
                uint256 v = ((uint256(_rarities[tokenID])+_baseReward) / _baseReward) * uint256(1000000000000);
                _value += v;
                emit AirdropClaimed(_owner, tokenID, v);
            }
        }
        _token.mint(_owner, _value);
        return _value;
    }
    
    function claimAirDrop(address _owner, uint256 tokenID) public returns (uint256) {
        require(_active, "Not yet Active");
        require(address(0xbAad3fde86fAA3B42D6A047060308E49A24Ec9E7) == tokenID.tokenCreator(), "Not a valid NFT");
        require(IERC1155(_airDropContract).balanceOf(_owner, tokenID) > 0, "Not a valid NFT");
        require(tokenID.tokenIndex() <= _airDropMaxID.tokenIndex(), "Not a valid NFT");
        require(!_airDropClaimed[tokenID], "Airdrop Already Claimed");
        
        uint256 value = ((uint256(_rarities[tokenID])+_baseReward) / _baseReward) * uint256(1000000000000);
        _airDropClaimed[tokenID] = true;
        _token.mint(_owner, value);
        emit AirdropClaimed(_owner, tokenID, value);
        
        return value;
    }
    
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data) external override returns (bytes4) {
            operator; data;
            require(_active, "Not yet Active");
            require(address(0xbAad3fde86fAA3B42D6A047060308E49A24Ec9E7) == id.tokenCreator(), "Not a T.I.G. Card!");
            require(_validSourceContracts[_msgSender()], "Not a Validated Contract! ");
            
            _stakeNft(id, from, _msgSender(), stakedNFTHelper.ERC721);
            return IERC721Receiver.onERC721Received.selector;
    }
    
    function onERC1155Received(
        address operator, 
        address from, 
        uint256 id, 
        uint256 value,
        bytes calldata data) external override returns (bytes4) {
            operator; data;
            require(_active, "Not yet Active");
            require(address(0xbAad3fde86fAA3B42D6A047060308E49A24Ec9E7) == id.tokenCreator(), "Not a T.I.G. Card!");
            require(_validSourceContracts[_msgSender()], "Not a Validated Contract! ");

            if(id == _mintbotTokenID && _msgSender() == _airDropContract) {
                _depositMintbotToken(from, value);
            } else {
                _stakeNft(id, from, _msgSender(), stakedNFTHelper.ERC1155);
            }

            return IERC1155Receiver.onERC1155Received.selector;
    }
    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override pure returns (bytes4) {
        operator; from; ids; values; data;
        require(false, "no batch staking");
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function _setMintbotTokenPrice(uint256 price) public {
        require(_msgSender() == owner());
        _currentMintbotPrice = price;
    }

    function _purchaseMintbotToken(address _owner, uint256 _maxPrice) public {
        require(_msgSender() == owner() || _owner == _msgSender());
        require(_maxPrice >= _currentMintbotPrice, "Max price exceeded.");
        require(_token.balanceOf(_token.depositAddress(_owner)) >= _currentMintbotPrice, "Cannot afford purchase price");
        _token.managedTransfer(_owner, address(this), _currentMintbotPrice);
        _token.burn(_currentMintbotPrice);
        _mintbotTokens[_owner] = _mintbotTokens[_owner] + 1;
        _currentMintbotPrice = _currentMintbotPrice + _currentMintbotPrice / _mintbotPriceExp;
    }

    function _depositMintbotToken(address _owner, uint256 _quantity) internal {
        _mintbotTokens[_owner] = _mintbotTokens[_owner] + _quantity;
        IERC1155(_airDropContract).safeTransferFrom(address(this), owner(), _mintbotTokenID, _quantity, "");
    }

    function _withdrawMintbotToken(address _owner, uint256 _quantity) public {
        require(_msgSender() == owner() || _owner == _msgSender());
        require(_mintbotTokens[_owner] >= _quantity, "Not enough tokens to withdraw");
        _mintbotTokens[_owner] = _mintbotTokens[_owner] - _quantity;
        IERC1155(_airDropContract).safeTransferFrom(owner(), _owner, _mintbotTokenID, _quantity, "");
    }
    
    function _stakeNft(uint256 _tokenId, address _owner, address _contract, uint8 _type) internal {
        stakedNFT storage nft = _stakedNFTs[_owner].get(_tokenId);
        nft._blockStart = uint128(block.number);
        nft._id = _tokenId;
        nft._contract = _contract;
        nft._rarity = _rarities[_tokenId]+uint64(_baseReward);
        nft._contractType = _type;
        _stakedNFTs[_owner].insert(_tokenId, nft);
        _stakedToOwner[_tokenId] = _owner;
        emit NftStaked(_owner, _contract, _tokenId, block.number, _type);
    }
    
    function setUsageFee(address _owner, uint256 _tokenId, uint56 _fee) public {
        require(_msgSender() == owner() || _owner == _msgSender());
        require(_stakedNFTs[_owner].contains(_tokenId), "Not a staked NFT!");
        stakedNFT storage nft = _stakedNFTs[_owner].get(_tokenId);
        nft._usageFee = _fee;
        _stakedNFTs[_owner].insert(_tokenId, nft);
        emit UsageFeeSet(_owner, _tokenId, _fee);
    }
    
    function getStakedNFTData(uint256 _tokenId) public view returns (stakedNFT memory) {
        return _stakedNFTs[_stakedToOwner[_tokenId]].get(_tokenId);
    }
    
    function unStakeNFT(address _owner, uint256 _tokenId) public {
        require(_msgSender() == owner() || _owner == _msgSender());
        require(_stakedNFTs[_owner].contains(_tokenId), "Not a staked NFT!");
        stakedNFT storage nft = _stakedNFTs[_owner].get(_tokenId);
        _token.mint(_owner, nft.currentValue());
        address contractAddress = nft._contract;
        uint8 contractType = nft._contractType;
        _stakedNFTs[_owner].remove(_tokenId);
        _stakedToOwner[_tokenId] = address(0);
        
        if(contractType == stakedNFTHelper.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(address(this), _owner, _tokenId, 1, "");
        } else if(contractType == stakedNFTHelper.ERC721) {
            IERC721(contractAddress).safeTransferFrom(address(this), _owner, _tokenId, "");
        } else { require(false, "Impossible!"); }
        
        emit NftUnStaked(_owner, contractAddress, _tokenId, block.number, contractType);
    }
    
    function claimZXVC(address _owner, uint256 _tokenId) public {
        require(_msgSender() == owner() || _owner == _msgSender());
        require(_stakedNFTs[_owner].contains(_tokenId), "Not a staked NFT!");
        stakedNFT storage nft = _stakedNFTs[_owner].get(_tokenId);
        _token.mint(_owner, nft.currentValue());
        nft._blockStart = uint128(block.number);
        _stakedNFTs[_owner].insert(_tokenId, nft);
    }

    function claimAllZXVC(address _owner, uint256[] calldata _tokenId) public {
        require(_msgSender() == owner() || _owner == _msgSender());
        uint256 harvest = 0;
        for(uint i = 0; i < _tokenId.length; i++) {
            require(_stakedNFTs[_owner].contains(_tokenId[i]), "Not a staked NFT!");
            stakedNFT storage nft = _stakedNFTs[_owner].get(_tokenId[i]);
            harvest += nft.currentValue();
            nft._blockStart = uint128(block.number);
            _stakedNFTs[_owner].insert(_tokenId[i], nft);
        }
        _token.mint(_owner, harvest);
    }
    
    function destroy() public {
        require(_msgSender() == owner());
        selfdestruct(payable(owner()));
    }
}