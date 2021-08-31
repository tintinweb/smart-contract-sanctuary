/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: GPL-3.0-or-later


// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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



contract Token is Context, ERC20 {
    constructor() ERC20("PetsToken", "Pets") {
        _mint(_msgSender(), 1000000 * (10**uint256(decimals())));
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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


// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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


// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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



// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: @openzeppelin/contracts/utils/Counters.sol



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: CrateNFT.sol


pragma solidity ^0.8.0;








/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

contract CrateNFT is Context, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _crateIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct RoleData { // my code
        mapping(address => bool) members;
        bytes32 adminRole;
    } 

    
    address private _organiser;
	address private _marketAddress;
    uint256[] private soldCrates;
    uint256 private _cratePrice;
	uint256 private _hatchPrice;

    mapping(address => uint256[]) private purchasedCrates;
    mapping(bytes32 => RoleData) private _roles; //my code

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        uint256 cratePrice,
		uint256 hatchPrice,
        address organiser
    ) ERC721(TokenName, TokenSymbol) {
        _setupRole(MINTER_ROLE, organiser);

        _cratePrice = cratePrice;
		_hatchPrice = hatchPrice;
        _organiser = organiser;
    }

    modifier isMinterRole {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "User must have minter role to mint"
        );
        _;
    } 
		
    /**
     * my code
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
    
	function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }
	
	function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }
	
	/**
     * my code
     * Grant the owner role to new user(Change the owner of the contract)
     */
	function changeOwner(address account) public{
		if (msg.sender == _organiser && hasRole(MINTER_ROLE, msg.sender)){
			_grantRole(MINTER_ROLE, account);
		}		
	}
	
    /**
     * my code
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /*
     * Mint new crates and assign it to operator
     * Access controlled by minter only
     * Returns new crateId
     */
    function mint(address operator)
        internal
        virtual
        isMinterRole
        returns (uint256)
    {
        _crateIds.increment();
        uint256 newCrateId = _crateIds.current();
        _mint(operator, newCrateId);

        return newCrateId;
    }

    /*
     * Bulk mint specified number of crates to assign it to a operator
     * Modifier to check the crate count is less than total supply
     */
    function bulkMintCrates(uint256 numOfCrates, address operator)
        public
        virtual
    {
		_marketAddress = operator;
        for (uint256 i = 0; i < numOfCrates; i++) {
            mint(operator);
        }
    }

    /*
     * Primary purchase for the crates
     * Adds new customer if not exists
     * Adds buyer to crates mapping
     * Update crate details
     */
    function transferCrate(address buyer, uint256 crateId) public {
        //The organiser is not allowed to purchase the crate
        require(
            !isSoldCrate(crateId),
            "The crate has already sold."
        );
				
        transferFrom(ownerOf(crateId), buyer, crateId);
        purchasedCrates[buyer].push(crateId);
		soldCrates.push(crateId);
    }

	/*
     * Stimulate the crate and get the dog
     * Adds new customer if not exists
     * Adds buyer to crates mapping
     * Remove crate from the seller and from sale
     * Update crate details
     */
    function hatchCrate(address seller, uint256 crateId)
        public
    {
        removeCrateFromCustomer(seller, crateId);
    }    

    // Get crate actual price
    function getCratePrice() public view returns (uint256) {
        return _cratePrice;
    }
	
	// Get hatch actual price
    function getHatchPrice() public view returns (uint256) {
        return _hatchPrice;
    }

    // Get organiser's address
    function getOrganiser() public view returns (address) {
        return _organiser;
    }

    // Get total number of crates
    function crateCounts() public view returns (uint256) {
        return _crateIds.current();
    }

    // Get all sold crates
    function getSoldCrates() public view returns (uint256[] memory) {
        return soldCrates;
    }

    // Get all crates owned by a customer
    function getCratesOfCustomer(address customer)
        public
        view
        returns (uint256[] memory)
    {
        return purchasedCrates[customer];
    }
	
	// Utility function used to check if the crate is already for sale
    function isSoldCrate(uint256 crateId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < soldCrates.length; i++) {
            if (soldCrates[i] == crateId) {
                return true;
            }
        }
        return false;
    }

    // Utility function to remove crate owned by customer from customer to crate mapping
    function removeCrateFromCustomer(address customer, uint256 crateId)
        internal
    {
        uint256 numOfCrates = purchasedCrates[customer].length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfCrates; i++) {
            if (purchasedCrates[customer][i] == crateId) {                
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfCrates; j++) {
				purchasedCrates[customer][j - 1] = purchasedCrates[customer][j];
			}
			purchasedCrates[customer].pop();
		}
    }
	
}

// File: Market.sol


pragma solidity ^0.8.0;



contract AkitaNFT is Context, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _akitaIds;
    Counters.Counter private _saleAkitaId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct AkitaDetails {
        uint256 purchasePrice;
        uint256 sellingPrice;
        bool forSale;
    }
    struct RoleData { // my code
        mapping(address => bool) members;
        bytes32 adminRole;
    } 

    
    address private _organiser;
    uint256[] private akitasForSale;
    uint256 private _akitaPrice;

    mapping(uint256 => AkitaDetails) private _akitaDetails;
    mapping(address => uint256[]) private purchasedAkitas;
    mapping(bytes32 => RoleData) private _roles; //my code

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        uint256 akitaPrice,
        address organiser
    ) ERC721(TokenName, TokenSymbol) {
        _setupRole(MINTER_ROLE, organiser);

        _akitaPrice = akitaPrice;
        _organiser = organiser;
    }

    modifier isMinterRole {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "User must have minter role to mint"
        );
        _;
    }
    
    /**
     * my code
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
    function _setupRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    /**
     * my code
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /*
     * Mint new akitas and assign it to operator
     * Access controlled by minter only
     * Returns new akitaId
     */
    function mint(address operator)
        internal
        virtual
        isMinterRole
        returns (uint256)
    {
        _akitaIds.increment();
        uint256 newAkitaId = _akitaIds.current();
        _mint(operator, newAkitaId);

        _akitaDetails[newAkitaId] = AkitaDetails({
            purchasePrice: _akitaPrice,
            sellingPrice: 0,
            forSale: false
        });

        return newAkitaId;
    }

    /*
     * Bulk mint specified number of akitas to assign it to a operator
     * Modifier to check the akita count is less than total supply
     */
    function bulkMintAkitas(uint256 numOfAkitas, address operator)
        public
        virtual
    {        
        for (uint256 i = 0; i < numOfAkitas; i++) {
            mint(operator);
        }
    }

    /*
     * Primary purchase for the akitas
     * Adds new customer if not exists
     * Adds buyer to akitas mapping
     * Update akita details
     */
    function transferAkita(address buyer) public {
        _saleAkitaId.increment();
        uint256 saleAkitaId = _saleAkitaId.current();

        require(
            msg.sender == ownerOf(saleAkitaId),
            "Only initial purchase allowed"
        );

        transferFrom(ownerOf(saleAkitaId), buyer, saleAkitaId);

        purchasedAkitas[buyer].push(saleAkitaId);
    }

    /*
     * Secondary purchase for the akitas
     * Modifier to validate that the selling price shouldn't exceed 110% of purchase price for peer to peer transfers
     * Adds new customer if not exists
     * Adds buyer to akitas mapping
     * Remove akita from the seller and from sale
     * Update akita details
     */
    function secondaryTransferAkita(address buyer, uint256 saleAkitaId)
        public
    {
        address seller = ownerOf(saleAkitaId);
        uint256 sellingPrice = _akitaDetails[saleAkitaId].sellingPrice;

        transferFrom(seller, buyer, saleAkitaId);

        purchasedAkitas[buyer].push(saleAkitaId);

        removeAkitaFromCustomer(seller, saleAkitaId);
        removeAkitaFromSale(saleAkitaId);

        _akitaDetails[saleAkitaId] = AkitaDetails({
            purchasePrice: sellingPrice,
            sellingPrice: 0,
            forSale: false
        });
    }

    /*
     * Add akita for sale with its details
     * Validate that the selling price shouldn't exceed 110% of purchase price
     * Organiser can not use secondary market sale
     */
    function setSaleDetails(
        uint256 akitaId,
        uint256 sellingPrice,
        address operator
    ) public {
        uint256 purchasePrice = _akitaDetails[akitaId].purchasePrice;

        require(
            purchasePrice + ((purchasePrice * 110) / 100) > sellingPrice,
            "Re-selling price is more than 110%"
        );

        _akitaDetails[akitaId].sellingPrice = sellingPrice;
        _akitaDetails[akitaId].forSale = true;

        if (!isSaleAkitaAvailable(akitaId)) {
            akitasForSale.push(akitaId);
        }

        approve(operator, akitaId);
    }

    // Get akita actual price
    function getAkitaPrice() public view returns (uint256) {
        return _akitaPrice;
    }
	
    // Get organiser's address
    function getOrganiser() public view returns (address) {
        return _organiser;
    }

    // Get current akitaId
    function akitaCounts() public view returns (uint256) {
        return _akitaIds.current();
    }

    // Get next sale akitaId
    function getNextSaleAkitaId() public view returns (uint256) {
        return _saleAkitaId.current();
    }

    // Get selling price for the akita
    function getSellingPrice(uint256 akitaId) public view returns (uint256) {
        return _akitaDetails[akitaId].sellingPrice;
    }

    // Get all akitas available for sale
    function getAkitasForSale() public view returns (uint256[] memory) {
        return akitasForSale;
    }

    // Get akita details
    function getAkitaDetails(uint256 akitaId)
        public
        view
        returns (
            uint256 purchasePrice,
            uint256 sellingPrice,
            bool forSale
        )
    {
        return (
            _akitaDetails[akitaId].purchasePrice,
            _akitaDetails[akitaId].sellingPrice,
            _akitaDetails[akitaId].forSale
        );
    }

    // Get all akitas owned by a customer
    function getAkitasOfCustomer(address customer)
        public
        view
        returns (uint256[] memory)
    {
        return purchasedAkitas[customer];
    }

    // Utility function used to check if akita is already for sale
    function isSaleAkitaAvailable(uint256 akitaId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < akitasForSale.length; i++) {
            if (akitasForSale[i] == akitaId) {
                return true;
            }
        }
        return false;
    }

    // Utility function to remove akita owned by customer from customer to akita mapping
    function removeAkitaFromCustomer(address customer, uint256 akitaId)
        internal
    {
        uint256 numOfAkitas = purchasedAkitas[customer].length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfAkitas; i++) {
            if (purchasedAkitas[customer][i] == akitaId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfAkitas; j++) {
				purchasedAkitas[customer][j - 1] = purchasedAkitas[customer][j];
			}
			purchasedAkitas[customer].pop();
		}
    }

    // Utility function to remove akita from sale list
    function removeAkitaFromSale(uint256 akitaId) internal {
        uint256 numOfAkitas = akitasForSale.length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfAkitas; i++) {
            if (akitasForSale[i] == akitaId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfAkitas; j++) {
				akitasForSale[j - 1] = akitasForSale[j];
			}
			akitasForSale.pop();
		}
    }
}

contract KishuNFT is Context, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _kishuIds;
    Counters.Counter private _saleKishuId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct KishuDetails {
        uint256 purchasePrice;
        uint256 sellingPrice;
        bool forSale;
    }
    struct RoleData { // my code
        mapping(address => bool) members;
        bytes32 adminRole;
    } 

    
    address private _organiser;
    uint256[] private kishusForSale;
    uint256 private _kishuPrice;

    mapping(uint256 => KishuDetails) private _kishuDetails;
    mapping(address => uint256[]) private purchasedKishus;
    mapping(bytes32 => RoleData) private _roles; //my code

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        uint256 kishuPrice,
        address organiser
    ) ERC721(TokenName, TokenSymbol) {
        _setupRole(MINTER_ROLE, organiser);

        _kishuPrice = kishuPrice;
        _organiser = organiser;
    }

    modifier isMinterRole {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "User must have minter role to mint"
        );
        _;
    }
    
    /**
     * my code
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
    function _setupRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    /**
     * my code
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /*
     * Mint new kishus and assign it to operator
     * Access controlled by minter only
     * Returns new kishuId
     */
    function mint(address operator)
        internal
        virtual
        isMinterRole
        returns (uint256)
    {
        _kishuIds.increment();
        uint256 newKishuId = _kishuIds.current();
        _mint(operator, newKishuId);

        _kishuDetails[newKishuId] = KishuDetails({
            purchasePrice: _kishuPrice,
            sellingPrice: 0,
            forSale: false
        });

        return newKishuId;
    }

    /*
     * Bulk mint specified number of kishus to assign it to a operator
     * Modifier to check the kishu count is less than total supply
     */
    function bulkMintKishus(uint256 numOfKishus, address operator)
        public
        virtual
    {        
        for (uint256 i = 0; i < numOfKishus; i++) {
            mint(operator);
        }
    }

    /*
     * Primary purchase for the kishus
     * Adds new customer if not exists
     * Adds buyer to kishus mapping
     * Update kishu details
     */
    function transferKishu(address buyer) public {
        _saleKishuId.increment();
        uint256 saleKishuId = _saleKishuId.current();

        require(
            msg.sender == ownerOf(saleKishuId),
            "Only initial purchase allowed"
        );

        transferFrom(ownerOf(saleKishuId), buyer, saleKishuId);

        purchasedKishus[buyer].push(saleKishuId);
    }

    /*
     * Secondary purchase for the kishus
     * Modifier to validate that the selling price shouldn't exceed 110% of purchase price for peer to peer transfers
     * Adds new customer if not exists
     * Adds buyer to kishus mapping
     * Remove kishu from the seller and from sale
     * Update kishu details
     */
    function secondaryTransferKishu(address buyer, uint256 saleKishuId)
        public
    {
        address seller = ownerOf(saleKishuId);
        uint256 sellingPrice = _kishuDetails[saleKishuId].sellingPrice;

        transferFrom(seller, buyer, saleKishuId);

        purchasedKishus[buyer].push(saleKishuId);

        removeKishuFromCustomer(seller, saleKishuId);
        removeKishuFromSale(saleKishuId);

        _kishuDetails[saleKishuId] = KishuDetails({
            purchasePrice: sellingPrice,
            sellingPrice: 0,
            forSale: false
        });
    }

    /*
     * Add kishu for sale with its details
     * Validate that the selling price shouldn't exceed 110% of purchase price
     * Organiser can not use secondary market sale
     */
    function setSaleDetails(
        uint256 kishuId,
        uint256 sellingPrice,
        address operator
    ) public {
        uint256 purchasePrice = _kishuDetails[kishuId].purchasePrice;

        require(
            purchasePrice + ((purchasePrice * 110) / 100) > sellingPrice,
            "Re-selling price is more than 110%"
        );

        _kishuDetails[kishuId].sellingPrice = sellingPrice;
        _kishuDetails[kishuId].forSale = true;

        if (!isSaleKishuAvailable(kishuId)) {
            kishusForSale.push(kishuId);
        }

        approve(operator, kishuId);
    }

    // Get kishu actual price
    function getKishuPrice() public view returns (uint256) {
        return _kishuPrice;
    }
	
    // Get organiser's address
    function getOrganiser() public view returns (address) {
        return _organiser;
    }

    // Get current kishuId
    function kishuCounts() public view returns (uint256) {
        return _kishuIds.current();
    }

    // Get next sale kishuId
    function getNextSaleKishuId() public view returns (uint256) {
        return _saleKishuId.current();
    }

    // Get selling price for the kishu
    function getSellingPrice(uint256 kishuId) public view returns (uint256) {
        return _kishuDetails[kishuId].sellingPrice;
    }

    // Get all kishus available for sale
    function getKishusForSale() public view returns (uint256[] memory) {
        return kishusForSale;
    }

    // Get kishu details
    function getKishuDetails(uint256 kishuId)
        public
        view
        returns (
            uint256 purchasePrice,
            uint256 sellingPrice,
            bool forSale
        )
    {
        return (
            _kishuDetails[kishuId].purchasePrice,
            _kishuDetails[kishuId].sellingPrice,
            _kishuDetails[kishuId].forSale
        );
    }

    // Get all kishus owned by a customer
    function getKishusOfCustomer(address customer)
        public
        view
        returns (uint256[] memory)
    {
        return purchasedKishus[customer];
    }

    // Utility function used to check if kishu is already for sale
    function isSaleKishuAvailable(uint256 kishuId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < kishusForSale.length; i++) {
            if (kishusForSale[i] == kishuId) {
                return true;
            }
        }
        return false;
    }

    // Utility function to remove kishu owned by customer from customer to kishu mapping
    function removeKishuFromCustomer(address customer, uint256 kishuId)
        internal
    {
        uint256 numOfKishus = purchasedKishus[customer].length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfKishus; i++) {
            if (purchasedKishus[customer][i] == kishuId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfKishus; j++) {
				purchasedKishus[customer][j - 1] = purchasedKishus[customer][j];
			}
			purchasedKishus[customer].pop();
		}
    }

    // Utility function to remove kishu from sale list
    function removeKishuFromSale(uint256 kishuId) internal {
        uint256 numOfKishus = kishusForSale.length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfKishus; i++) {
            if (kishusForSale[i] == kishuId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfKishus; j++) {
				kishusForSale[j - 1] = kishusForSale[j];
			}
			kishusForSale.pop();
		}
    }
}

contract HokkaidoNFT is Context, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _hokkaidoIds;
    Counters.Counter private _saleHokkaidoId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct HokkaidoDetails {
        uint256 purchasePrice;
        uint256 sellingPrice;
        bool forSale;
    }
    struct RoleData { // my code
        mapping(address => bool) members;
        bytes32 adminRole;
    } 

    
    address private _organiser;
    uint256[] private hokkaidosForSale;
    uint256 private _hokkaidoPrice;

    mapping(uint256 => HokkaidoDetails) private _hokkaidoDetails;
    mapping(address => uint256[]) private purchasedHokkaidos;
    mapping(bytes32 => RoleData) private _roles; //my code

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        uint256 hokkaidoPrice,
        address organiser
    ) ERC721(TokenName, TokenSymbol) {
        _setupRole(MINTER_ROLE, organiser);

        _hokkaidoPrice = hokkaidoPrice;
        _organiser = organiser;
    }

    modifier isMinterRole {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "User must have minter role to mint"
        );
        _;
    }
    
    /**
     * my code
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
    function _setupRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    /**
     * my code
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /*
     * Mint new hokkaidos and assign it to operator
     * Access controlled by minter only
     * Returns new hokkaidoId
     */
    function mint(address operator)
        internal
        virtual
        isMinterRole
        returns (uint256)
    {
        _hokkaidoIds.increment();
        uint256 newHokkaidoId = _hokkaidoIds.current();
        _mint(operator, newHokkaidoId);

        _hokkaidoDetails[newHokkaidoId] = HokkaidoDetails({
            purchasePrice: _hokkaidoPrice,
            sellingPrice: 0,
            forSale: false
        });

        return newHokkaidoId;
    }

    /*
     * Bulk mint specified number of hokkaidos to assign it to a operator
     * Modifier to check the hokkaido count is less than total supply
     */
    function bulkMintHokkaidos(uint256 numOfHokkaidos, address operator)
        public
        virtual
    {        
        for (uint256 i = 0; i < numOfHokkaidos; i++) {
            mint(operator);
        }
    }

    /*
     * Primary purchase for the hokkaidos
     * Adds new customer if not exists
     * Adds buyer to hokkaidos mapping
     * Update hokkaido details
     */
    function transferHokkaido(address buyer) public {
        _saleHokkaidoId.increment();
        uint256 saleHokkaidoId = _saleHokkaidoId.current();

        require(
            msg.sender == ownerOf(saleHokkaidoId),
            "Only initial purchase allowed"
        );

        transferFrom(ownerOf(saleHokkaidoId), buyer, saleHokkaidoId);

        purchasedHokkaidos[buyer].push(saleHokkaidoId);
    }

    /*
     * Secondary purchase for the hokkaidos
     * Modifier to validate that the selling price shouldn't exceed 110% of purchase price for peer to peer transfers
     * Adds new customer if not exists
     * Adds buyer to hokkaidos mapping
     * Remove hokkaido from the seller and from sale
     * Update hokkaido details
     */
    function secondaryTransferHokkaido(address buyer, uint256 saleHokkaidoId)
        public
    {
        address seller = ownerOf(saleHokkaidoId);
        uint256 sellingPrice = _hokkaidoDetails[saleHokkaidoId].sellingPrice;

        transferFrom(seller, buyer, saleHokkaidoId);

        purchasedHokkaidos[buyer].push(saleHokkaidoId);

        removeHokkaidoFromCustomer(seller, saleHokkaidoId);
        removeHokkaidoFromSale(saleHokkaidoId);

        _hokkaidoDetails[saleHokkaidoId] = HokkaidoDetails({
            purchasePrice: sellingPrice,
            sellingPrice: 0,
            forSale: false
        });
    }

    /*
     * Add hokkaido for sale with its details
     * Validate that the selling price shouldn't exceed 110% of purchase price
     * Organiser can not use secondary market sale
     */
    function setSaleDetails(
        uint256 hokkaidoId,
        uint256 sellingPrice,
        address operator
    ) public {
        uint256 purchasePrice = _hokkaidoDetails[hokkaidoId].purchasePrice;

        require(
            purchasePrice + ((purchasePrice * 110) / 100) > sellingPrice,
            "Re-selling price is more than 110%"
        );

        _hokkaidoDetails[hokkaidoId].sellingPrice = sellingPrice;
        _hokkaidoDetails[hokkaidoId].forSale = true;

        if (!isSaleHokkaidoAvailable(hokkaidoId)) {
            hokkaidosForSale.push(hokkaidoId);
        }

        approve(operator, hokkaidoId);
    }

    // Get hokkaido actual price
    function getHokkaidoPrice() public view returns (uint256) {
        return _hokkaidoPrice;
    }
	
    // Get organiser's address
    function getOrganiser() public view returns (address) {
        return _organiser;
    }

    // Get current hokkaidoId
    function hokkaidoCounts() public view returns (uint256) {
        return _hokkaidoIds.current();
    }

    // Get next sale hokkaidoId
    function getNextSaleHokkaidoId() public view returns (uint256) {
        return _saleHokkaidoId.current();
    }

    // Get selling price for the hokkaido
    function getSellingPrice(uint256 hokkaidoId) public view returns (uint256) {
        return _hokkaidoDetails[hokkaidoId].sellingPrice;
    }

    // Get all hokkaidos available for sale
    function getHokkaidosForSale() public view returns (uint256[] memory) {
        return hokkaidosForSale;
    }

    // Get hokkaido details
    function getHokkaidoDetails(uint256 hokkaidoId)
        public
        view
        returns (
            uint256 purchasePrice,
            uint256 sellingPrice,
            bool forSale
        )
    {
        return (
            _hokkaidoDetails[hokkaidoId].purchasePrice,
            _hokkaidoDetails[hokkaidoId].sellingPrice,
            _hokkaidoDetails[hokkaidoId].forSale
        );
    }

    // Get all hokkaidos owned by a customer
    function getHokkaidosOfCustomer(address customer)
        public
        view
        returns (uint256[] memory)
    {
        return purchasedHokkaidos[customer];
    }

    // Utility function used to check if hokkaido is already for sale
    function isSaleHokkaidoAvailable(uint256 hokkaidoId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < hokkaidosForSale.length; i++) {
            if (hokkaidosForSale[i] == hokkaidoId) {
                return true;
            }
        }
        return false;
    }

    // Utility function to remove hokkaido owned by customer from customer to hokkaido mapping
    function removeHokkaidoFromCustomer(address customer, uint256 hokkaidoId)
        internal
    {
        uint256 numOfHokkaidos = purchasedHokkaidos[customer].length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfHokkaidos; i++) {
            if (purchasedHokkaidos[customer][i] == hokkaidoId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfHokkaidos; j++) {
				purchasedHokkaidos[customer][j - 1] = purchasedHokkaidos[customer][j];
			}
			purchasedHokkaidos[customer].pop();
		}
    }

    // Utility function to remove hokkaido from sale list
    function removeHokkaidoFromSale(uint256 hokkaidoId) internal {
        uint256 numOfHokkaidos = hokkaidosForSale.length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfHokkaidos; i++) {
            if (hokkaidosForSale[i] == hokkaidoId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfHokkaidos; j++) {
				hokkaidosForSale[j - 1] = hokkaidosForSale[j];
			}
			hokkaidosForSale.pop();
		}
	}
}

contract ShibaNFT is Context, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _shibaIds;
    Counters.Counter private _saleShibaId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct ShibaDetails {
        uint256 purchasePrice;
        uint256 sellingPrice;
        bool forSale;
    }
    struct RoleData { // my code
        mapping(address => bool) members;
        bytes32 adminRole;
    } 

    
    address private _organiser;
    uint256[] private shibasForSale;
    uint256 private _shibaPrice;

    mapping(uint256 => ShibaDetails) private _shibaDetails;
    mapping(address => uint256[]) private purchasedShibas;
    mapping(bytes32 => RoleData) private _roles; //my code

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        uint256 shibaPrice,
        address organiser
    ) ERC721(TokenName, TokenSymbol) {
        _setupRole(MINTER_ROLE, organiser);

        _shibaPrice = shibaPrice;
        _organiser = organiser;
    }

    modifier isMinterRole {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "User must have minter role to mint"
        );
        _;
    }
    
    /**
     * my code
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
    function _setupRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    /**
     * my code
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /*
     * Mint new shibas and assign it to operator
     * Access controlled by minter only
     * Returns new shibaId
     */
    function mint(address operator)
        internal
        virtual
        isMinterRole
        returns (uint256)
    {
        _shibaIds.increment();
        uint256 newShibaId = _shibaIds.current();
        _mint(operator, newShibaId);

        _shibaDetails[newShibaId] = ShibaDetails({
            purchasePrice: _shibaPrice,
            sellingPrice: 0,
            forSale: false
        });

        return newShibaId;
    }

    /*
     * Bulk mint specified number of shibas to assign it to a operator
     * Modifier to check the shiba count is less than total supply
     */
    function bulkMintShibas(uint256 numOfShibas, address operator)
        public
        virtual
    {        
        for (uint256 i = 0; i < numOfShibas; i++) {
            mint(operator);
        }
    }

    /*
     * Primary purchase for the shibas
     * Adds new customer if not exists
     * Adds buyer to shibas mapping
     * Update shiba details
     */
    function transferShiba(address buyer) public {
        _saleShibaId.increment();
        uint256 saleShibaId = _saleShibaId.current();

        require(
            msg.sender == ownerOf(saleShibaId),
            "Only initial purchase allowed"
        );

        transferFrom(ownerOf(saleShibaId), buyer, saleShibaId);

        purchasedShibas[buyer].push(saleShibaId);
    }

    /*
     * Secondary purchase for the shibas
     * Modifier to validate that the selling price shouldn't exceed 110% of purchase price for peer to peer transfers
     * Adds new customer if not exists
     * Adds buyer to shibas mapping
     * Remove shiba from the seller and from sale
     * Update shiba details
     */
    function secondaryTransferShiba(address buyer, uint256 saleShibaId)
        public
    {
        address seller = ownerOf(saleShibaId);
        uint256 sellingPrice = _shibaDetails[saleShibaId].sellingPrice;

        transferFrom(seller, buyer, saleShibaId);

        purchasedShibas[buyer].push(saleShibaId);

        removeShibaFromCustomer(seller, saleShibaId);
        removeShibaFromSale(saleShibaId);

        _shibaDetails[saleShibaId] = ShibaDetails({
            purchasePrice: sellingPrice,
            sellingPrice: 0,
            forSale: false
        });
    }

    /*
     * Add shiba for sale with its details
     * Validate that the selling price shouldn't exceed 110% of purchase price
     * Organiser can not use secondary market sale
     */
    function setSaleDetails(
        uint256 shibaId,
        uint256 sellingPrice,
        address operator
    ) public {
        uint256 purchasePrice = _shibaDetails[shibaId].purchasePrice;

        require(
            purchasePrice + ((purchasePrice * 110) / 100) > sellingPrice,
            "Re-selling price is more than 110%"
        );

        _shibaDetails[shibaId].sellingPrice = sellingPrice;
        _shibaDetails[shibaId].forSale = true;

        if (!isSaleShibaAvailable(shibaId)) {
            shibasForSale.push(shibaId);
        }

        approve(operator, shibaId);
    }

    // Get shiba actual price
    function getShibaPrice() public view returns (uint256) {
        return _shibaPrice;
    }
	
    // Get organiser's address
    function getOrganiser() public view returns (address) {
        return _organiser;
    }

    // Get current shibaId
    function shibaCounts() public view returns (uint256) {
        return _shibaIds.current();
    }

    // Get next sale shibaId
    function getNextSaleShibaId() public view returns (uint256) {
        return _saleShibaId.current();
    }

    // Get selling price for the shiba
    function getSellingPrice(uint256 shibaId) public view returns (uint256) {
        return _shibaDetails[shibaId].sellingPrice;
    }

    // Get all shibas available for sale
    function getShibasForSale() public view returns (uint256[] memory) {
        return shibasForSale;
    }

    // Get shiba details
    function getShibaDetails(uint256 shibaId)
        public
        view
        returns (
            uint256 purchasePrice,
            uint256 sellingPrice,
            bool forSale
        )
    {
        return (
            _shibaDetails[shibaId].purchasePrice,
            _shibaDetails[shibaId].sellingPrice,
            _shibaDetails[shibaId].forSale
        );
    }

    // Get all shibas owned by a customer
    function getShibasOfCustomer(address customer)
        public
        view
        returns (uint256[] memory)
    {
        return purchasedShibas[customer];
    }

    // Utility function used to check if shiba is already for sale
    function isSaleShibaAvailable(uint256 shibaId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < shibasForSale.length; i++) {
            if (shibasForSale[i] == shibaId) {
                return true;
            }
        }
        return false;
    }

    // Utility function to remove shiba owned by customer from customer to shiba mapping
    function removeShibaFromCustomer(address customer, uint256 shibaId)
        internal
    {
        uint256 numOfShibas = purchasedShibas[customer].length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfShibas; i++) {
            if (purchasedShibas[customer][i] == shibaId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfShibas; j++) {
				purchasedShibas[customer][j - 1] = purchasedShibas[customer][j];
			}
			purchasedShibas[customer].pop();
		}
    }

    // Utility function to remove shiba from sale list
    function removeShibaFromSale(uint256 shibaId) internal {
        uint256 numOfShibas = shibasForSale.length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfShibas; i++) {
            if (shibasForSale[i] == shibaId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfShibas; j++) {
				shibasForSale[j - 1] = shibasForSale[j];
			}
			shibasForSale.pop();
		}
    }
}

contract MicroNFT is Context, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _microIds;
    Counters.Counter private _saleMicroId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct MicroDetails {
        uint256 purchasePrice;
        uint256 sellingPrice;
        bool forSale;
    }
    struct RoleData { // my code
        mapping(address => bool) members;
        bytes32 adminRole;
    } 

    
    address private _organiser;
    uint256[] private microsForSale;
    uint256 private _microPrice;

    mapping(uint256 => MicroDetails) private _microDetails;
    mapping(address => uint256[]) private purchasedMicros;
    mapping(bytes32 => RoleData) private _roles; //my code

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        uint256 microPrice,
        address organiser
    ) ERC721(TokenName, TokenSymbol) {
        _setupRole(MINTER_ROLE, organiser);

        _microPrice = microPrice;
        _organiser = organiser;
    }

    modifier isMinterRole {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "User must have minter role to mint"
        );
        _;
    }
    
    /**
     * my code
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
    function _setupRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
        }
    }

    /**
     * my code
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /*
     * Mint new micros and assign it to operator
     * Access controlled by minter only
     * Returns new microId
     */
    function mint(address operator)
        internal
        virtual
        isMinterRole
        returns (uint256)
    {
        _microIds.increment();
        uint256 newMicroId = _microIds.current();
        _mint(operator, newMicroId);

        _microDetails[newMicroId] = MicroDetails({
            purchasePrice: _microPrice,
            sellingPrice: 0,
            forSale: false
        });

        return newMicroId;
    }

    /*
     * Bulk mint specified number of micros to assign it to a operator
     * Modifier to check the micro count is less than total supply
     */
    function bulkMintMicros(uint256 numOfMicros, address operator)
        public
        virtual
    {        
        for (uint256 i = 0; i < numOfMicros; i++) {
            mint(operator);
        }
    }

    /*
     * Primary purchase for the micros
     * Adds new customer if not exists
     * Adds buyer to micros mapping
     * Update micro details
     */
    function transferMicro(address buyer) public {
        _saleMicroId.increment();
        uint256 saleMicroId = _saleMicroId.current();

        require(
            msg.sender == ownerOf(saleMicroId),
            "Only initial purchase allowed"
        );

        transferFrom(ownerOf(saleMicroId), buyer, saleMicroId);

        purchasedMicros[buyer].push(saleMicroId);
    }

    /*
     * Secondary purchase for the micros
     * Modifier to validate that the selling price shouldn't exceed 110% of purchase price for peer to peer transfers
     * Adds new customer if not exists
     * Adds buyer to micros mapping
     * Remove micro from the seller and from sale
     * Update micro details
     */
    function secondaryTransferMicro(address buyer, uint256 saleMicroId)
        public
    {
        address seller = ownerOf(saleMicroId);
        uint256 sellingPrice = _microDetails[saleMicroId].sellingPrice;

        transferFrom(seller, buyer, saleMicroId);

        purchasedMicros[buyer].push(saleMicroId);

        removeMicroFromCustomer(seller, saleMicroId);
        removeMicroFromSale(saleMicroId);

        _microDetails[saleMicroId] = MicroDetails({
            purchasePrice: sellingPrice,
            sellingPrice: 0,
            forSale: false
        });
    }

    /*
     * Add micro for sale with its details
     * Validate that the selling price shouldn't exceed 110% of purchase price
     * Organiser can not use secondary market sale
     */
    function setSaleDetails(
        uint256 microId,
        uint256 sellingPrice,
        address operator
    ) public {
        uint256 purchasePrice = _microDetails[microId].purchasePrice;

        require(
            purchasePrice + ((purchasePrice * 110) / 100) > sellingPrice,
            "Re-selling price is more than 110%"
        );

        _microDetails[microId].sellingPrice = sellingPrice;
        _microDetails[microId].forSale = true;

        if (!isSaleMicroAvailable(microId)) {
            microsForSale.push(microId);
        }

        approve(operator, microId);
    }

    // Get micro actual price
    function getMicroPrice() public view returns (uint256) {
        return _microPrice;
    }
	
    // Get organiser's address
    function getOrganiser() public view returns (address) {
        return _organiser;
    }

    // Get current microId
    function microCounts() public view returns (uint256) {
        return _microIds.current();
    }

    // Get next sale microId
    function getNextSaleMicroId() public view returns (uint256) {
        return _saleMicroId.current();
    }

    // Get selling price for the micro
    function getSellingPrice(uint256 microId) public view returns (uint256) {
        return _microDetails[microId].sellingPrice;
    }

    // Get all micros available for sale
    function getMicrosForSale() public view returns (uint256[] memory) {
        return microsForSale;
    }

    // Get micro details
    function getMicroDetails(uint256 microId)
        public
        view
        returns (
            uint256 purchasePrice,
            uint256 sellingPrice,
            bool forSale
        )
    {
        return (
            _microDetails[microId].purchasePrice,
            _microDetails[microId].sellingPrice,
            _microDetails[microId].forSale
        );
    }

    // Get all micros owned by a customer
    function getMicrosOfCustomer(address customer)
        public
        view
        returns (uint256[] memory)
    {
        return purchasedMicros[customer];
    }

    // Utility function used to check if micro is already for sale
    function isSaleMicroAvailable(uint256 microId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < microsForSale.length; i++) {
            if (microsForSale[i] == microId) {
                return true;
            }
        }
        return false;
    }

    // Utility function to remove micro owned by customer from customer to micro mapping
    function removeMicroFromCustomer(address customer, uint256 microId)
        internal
    {
        uint256 numOfMicros = purchasedMicros[customer].length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfMicros; i++) {
            if (purchasedMicros[customer][i] == microId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfMicros; j++) {
				purchasedMicros[customer][j - 1] = purchasedMicros[customer][j];
			}
			purchasedMicros[customer].pop();
		}
    }

    // Utility function to remove micro from sale list
    function removeMicroFromSale(uint256 microId) internal {
        uint256 numOfMicros = microsForSale.length;
		uint256 label = 0;
        for (uint256 i = 0; i < numOfMicros; i++) {
            if (microsForSale[i] == microId) {
                label = i + 1;
            }
        }
		if (label != 0){
			for (uint256 j = label; j < numOfMicros; j++) {
				microsForSale[j - 1] = microsForSale[j];
			}
			microsForSale.pop();
		}
    }
}

contract Market {
    Token private _token;
    CrateNFT private _crate;
    AkitaNFT private _akita;
    KishuNFT private _kishu;
    HokkaidoNFT private _hokkaido;
    ShibaNFT private _shiba;
    MicroNFT private _micro;

    address private _organiser;

    constructor(Token token, CrateNFT crate, AkitaNFT akita, KishuNFT kishu, HokkaidoNFT hokkaido, ShibaNFT shiba, MicroNFT micro) {
        _token = token;
        _crate = crate;
		_akita = akita;
		_kishu = kishu;
		_hokkaido = hokkaido;
		_shiba = shiba;
		_micro = micro;
        _organiser = _crate.getOrganiser();
    }

    //event Purchase(address indexed buyer, address seller, uint256 crateId);

    function purchaseCrate(uint256 crateId) public {
        address buyer = msg.sender;

        _token.transferFrom(buyer, _organiser, _crate.getCratePrice());

        _crate.transferCrate(buyer, crateId);
    }
	event Purchase(address indexed buyer, address seller, uint256 crateId);
	
	// Stimulate crate and get the dog
    function stimulateCrate(uint256 crateId, uint256 dog_type) public {
        address seller = _crate.ownerOf(crateId);
        
        _token.transferFrom(seller, _organiser, _crate.getHatchPrice());
		// remove the crateId from the customer and sale list
        _crate.hatchCrate(seller, crateId);
		
		if (dog_type == 1) {		_akita.transferAkita(seller);		}
		if (dog_type == 2) {		_kishu.transferKishu(seller);		}
		if (dog_type == 3) {		_hokkaido.transferHokkaido(seller);		}
		if (dog_type == 4) {		_shiba.transferShiba(seller);		}
		if (dog_type == 5) {		_micro.transferMicro(seller);		}
    }
	
	// Purchase the dog from the secondary market hosted by organiser
    function secondaryPurchase(uint256 dogId, uint256 dog_type) public {
        address seller;
        uint sellingPrice;
		if (dog_type == 1){
			seller = _akita.ownerOf(dogId);
			sellingPrice = _akita.getSellingPrice(dogId);
		} 
		if (dog_type == 2){
			seller = _kishu.ownerOf(dogId);
			sellingPrice = _kishu.getSellingPrice(dogId);
		} 
		if (dog_type == 3){
			seller = _hokkaido.ownerOf(dogId);
			sellingPrice = _hokkaido.getSellingPrice(dogId);
		} 
		if (dog_type == 4){
			seller = _shiba.ownerOf(dogId);
			sellingPrice = _shiba.getSellingPrice(dogId);
		} 
		if (dog_type == 5){
			seller = _micro.ownerOf(dogId);
			sellingPrice = _micro.getSellingPrice(dogId);
		} 		
        
        address buyer = msg.sender;        
        uint256 commision = (sellingPrice * 10) / 100;
	
        _token.transferFrom(buyer, seller, sellingPrice - commision);
        _token.transferFrom(buyer, _organiser, commision);

        if (dog_type == 1) {		_akita.secondaryTransferAkita(buyer, dogId);		}
		if (dog_type == 2) {		_kishu.secondaryTransferKishu(buyer, dogId);		}
		if (dog_type == 3) {		_hokkaido.secondaryTransferHokkaido(buyer, dogId);		}
		if (dog_type == 4) {		_shiba.secondaryTransferShiba(buyer, dogId);		}
		if (dog_type == 5) {		_micro.secondaryTransferMicro(buyer, dogId);		}

        emit Purchase(buyer, seller, dogId);
    }	

}