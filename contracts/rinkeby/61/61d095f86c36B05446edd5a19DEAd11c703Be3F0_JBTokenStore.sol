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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';

import './interfaces/IJBToken.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

contract JBToken is IJBToken, ERC20, ERC20Permit, Ownable {
  constructor(string memory _name, string memory _symbol)
    ERC20(_name, _symbol)
    ERC20Permit(_name)
  {}

  function mint(address _account, uint256 _amount) external override onlyOwner {
    return _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount) external override onlyOwner {
    return _burn(_account, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './interfaces/IJBTokenStore.sol';
import './abstract/JBOperatable.sol';
import './abstract/JBTerminalUtility.sol';

import './libraries/JBOperations.sol';

import './JBToken.sol';

/** 
  @notice 
  Manage Token minting, burning, and account balances.

  @dev
  Tokens can be either represented internally staked, or as unstaked ERC-20s.
  This contract manages these two representations and the conversion between the two.

  @dev
  The total supply of a project's tokens and the balance of each account are calculated in this contract.
*/
contract JBTokenStore is JBTerminalUtility, JBOperatable, IJBTokenStore {
  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /// @notice The Projects contract which mints ERC-721's that represent project ownership and transfers.
  IJBProjects public immutable override projects;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  // Each project's ERC20 Token tokens.
  mapping(uint256 => IJBToken) public override tokenOf;

  // Each holder's balance of staked Tokens for each project.
  mapping(address => mapping(uint256 => uint256)) public override stakedBalanceOf;

  // The total supply of staked tokens for each project.
  mapping(uint256 => uint256) public override stakedTotalSupplyOf;

  // The amount of each holders tokens that are locked.
  mapping(address => mapping(uint256 => uint256)) public override lockedBalanceOf;

  // The amount of each holders tokens that are locked by each address.
  mapping(address => mapping(address => mapping(uint256 => uint256)))
    public
    override lockedBalanceBy;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
      @notice 
      The total supply of tokens for each project, including staked and unstaked tokens.

      @param _projectId The ID of the project to get the total supply of.

      @return supply The total supply.
    */
  function totalSupplyOf(uint256 _projectId) external view override returns (uint256 supply) {
    supply = stakedTotalSupplyOf[_projectId];
    IJBToken _token = tokenOf[_projectId];
    if (_token != IJBToken(address(0))) supply = supply + _token.totalSupply();
  }

  /** 
      @notice 
      The total balance of tokens a holder has for a specified project, including staked and unstaked tokens.

      @param _holder The token holder to get a balance for.
      @param _projectId The project to get the `_hodler`s balance of.

      @return balance The balance.
    */
  function balanceOf(address _holder, uint256 _projectId)
    external
    view
    override
    returns (uint256 balance)
  {
    balance = stakedBalanceOf[_holder][_projectId];
    IJBToken _token = tokenOf[_projectId];
    if (_token != IJBToken(address(0))) balance = balance + _token.balanceOf(_holder);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
      @param _projects A Projects contract which mints ERC-721's that represent project ownership and transfers.
      @param _operatorStore A contract storing operator assignments.
      @param _directory A directory of a project's current Juicebox terminal to receive payments in.
    */
  constructor(
    IJBProjects _projects,
    IJBOperatorStore _operatorStore,
    IJBDirectory _directory
  ) JBOperatable(_operatorStore) JBTerminalUtility(_directory) {
    projects = _projects;
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
        @notice 
        Issues an owner's ERC-20 Tokens that'll be used when unstaking tokens.

        @dev 
        Deploys an owner's Token ERC-20 token contract.

        @param _projectId The ID of the project being issued tokens.
        @param _name The ERC-20's name.
        @param _symbol The ERC-20's symbol.
    */
  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  )
    external
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.ISSUE)
    returns (IJBToken token)
  {
    // There must be a name.
    require((bytes(_name).length > 0), 'EMPTY_NAME');

    // There must be a symbol.
    require((bytes(_symbol).length > 0), 'EMPTY_SYMBOL');

    // Only one ERC20 token can be issued.
    require(tokenOf[_projectId] == IJBToken(address(0)), 'ALREADY_ISSUED');

    // Deploy the token contract.
    token = new JBToken(_name, _symbol);

    // Store the token contract.
    tokenOf[_projectId] = token;

    emit Issue(_projectId, token, _name, _symbol, msg.sender);
  }

  /** 
      @notice 
      Mint new tokens.

      @dev
      Only a project's current terminal can mint its tokens.

      @param _holder The address receiving the new tokens.
      @param _projectId The project to which the tokens belong.
      @param _amount The amount to mint.
      @param _preferUnstakedTokens Whether ERC20's should be converted automatically if they have been issued.
    */
  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferUnstakedTokens
  ) external override onlyTerminal(_projectId) {
    // An amount must be specified.
    require(_amount > 0, 'JBTokenStore::mint: NO_OP');

    // Get a reference to the project's ERC20 tokens.
    IJBToken _token = tokenOf[_projectId];

    // If there exists ERC-20 tokens and the caller prefers these unstaked tokens.
    bool _shouldUnstakeTokens = _preferUnstakedTokens && _token != IJBToken(address(0));

    if (_shouldUnstakeTokens) {
      // Mint the equivalent amount of ERC20s.
      _token.mint(_holder, _amount);
    } else {
      // Add to the staked balance and total supply.
      stakedBalanceOf[_holder][_projectId] = stakedBalanceOf[_holder][_projectId] + _amount;
      stakedTotalSupplyOf[_projectId] = stakedTotalSupplyOf[_projectId] + _amount;
    }

    emit Mint(
      _holder,
      _projectId,
      _amount,
      _shouldUnstakeTokens,
      _preferUnstakedTokens,
      msg.sender
    );
  }

  /** 
      @notice 
      Burns tokens.

      @dev
      Only a project's current terminal can burn its tokens.

      @param _holder The address that owns the tokens being burned.
      @param _projectId The ID of the project of the tokens being burned.
      @param _amount The amount of tokens being burned.
      @param _preferUnstakedTokens If the preference is to burn tokens that have been converted to ERC-20s.
    */
  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferUnstakedTokens
  ) external override onlyTerminal(_projectId) {
    // Get a reference to the project's ERC20 tokens.
    IJBToken _token = tokenOf[_projectId];

    // Get a reference to the staked amount.
    uint256 _unlockedStakedBalance = stakedBalanceOf[_holder][_projectId] -
      lockedBalanceOf[_holder][_projectId];

    // Get a reference to the number of tokens there are.
    uint256 _unstakedBalanceOf = _token == IJBToken(address(0)) ? 0 : _token.balanceOf(_holder);

    // There must be enough tokens.
    // Prevent potential overflow by not relying on addition.
    require(
      (_amount < _unstakedBalanceOf && _amount < _unlockedStakedBalance) ||
        (_amount >= _unstakedBalanceOf && _unlockedStakedBalance >= _amount - _unstakedBalanceOf) ||
        (_amount >= _unlockedStakedBalance &&
          _unstakedBalanceOf >= _amount - _unlockedStakedBalance),
      'INSUFFICIENT_FUNDS'
    );

    // The amount of tokens to burn.
    uint256 _unstakedTokensToBurn;

    // If there's no balance, redeem no tokens.
    if (_unstakedBalanceOf == 0) {
      _unstakedTokensToBurn = 0;
      // If prefer converted, redeem tokens before redeeming staked tokens.
    } else if (_preferUnstakedTokens) {
      _unstakedTokensToBurn = _unstakedBalanceOf >= _amount ? _amount : _unstakedBalanceOf;
      // Otherwise, redeem staked tokens before unstaked tokens.
    } else {
      _unstakedTokensToBurn = _unlockedStakedBalance >= _amount
        ? 0
        : _amount - _unlockedStakedBalance;
    }

    // The amount of staked tokens to redeem.
    uint256 _stakedTokensToBurn = _amount - _unstakedTokensToBurn;

    // burn the tokens.
    if (_unstakedTokensToBurn > 0) _token.burn(_holder, _unstakedTokensToBurn);
    if (_stakedTokensToBurn > 0) {
      // Reduce the holders balance and the total supply.
      stakedBalanceOf[_holder][_projectId] =
        stakedBalanceOf[_holder][_projectId] -
        _stakedTokensToBurn;
      stakedTotalSupplyOf[_projectId] = stakedTotalSupplyOf[_projectId] - _stakedTokensToBurn;
    }

    emit Burn(
      _holder,
      _projectId,
      _amount,
      _unlockedStakedBalance,
      _preferUnstakedTokens,
      msg.sender
    );
  }

  /**
      @notice 
      Stakes ERC20 tokens by burning their supply and creating an internal staked version.

      @dev
      Only a ticket holder or an operator can stake its tokens.

      @param _holder The owner of the tokens to stake.
      @param _projectId The ID of the project whos tokens are being staked.
      @param _amount The amount of tokens to stake.
     */
  function stakeFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  )
    external
    override
    requirePermissionAllowingWildcardDomain(_holder, _projectId, JBOperations.STAKE)
  {
    // Get a reference to the project's ERC20 tokens.
    IJBToken _token = tokenOf[_projectId];

    // Tokens must have been issued.
    require(_token != IJBToken(address(0)), 'NOT_FOUND');

    // Get a reference to the holder's current balance.
    uint256 _unstakedBalanceOf = _token.balanceOf(_holder);

    // There must be enough balance to stake.
    require(_unstakedBalanceOf >= _amount, 'INSUFFICIENT_FUNDS');

    // Burn the equivalent amount of ERC20s.
    _token.burn(_holder, _amount);

    // Add the staked amount from the holder's balance.
    stakedBalanceOf[_holder][_projectId] = stakedBalanceOf[_holder][_projectId] + _amount;

    // Add the staked amount from the project's total supply.
    stakedTotalSupplyOf[_projectId] = stakedTotalSupplyOf[_projectId] + _amount;

    emit Stake(_holder, _projectId, _amount, msg.sender);
  }

  /**
      @notice 
      Unstakes internal tokens by creating and distributing ERC20 tokens.

      @dev
      Only a token holder or an operator can unstake its tokens.

      @param _holder The owner of the tokens to unstake.
      @param _projectId The ID of the project whos tokens are being unstaked.
      @param _amount The amount of tokens to unstake.
     */
  function unstakeFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  )
    external
    override
    requirePermissionAllowingWildcardDomain(_holder, _projectId, JBOperations.UNSTAKE)
  {
    // Get a reference to the project's ERC20 tokens.
    IJBToken _token = tokenOf[_projectId];

    // Tokens must have been issued.
    require(_token != IJBToken(address(0)), 'NOT_FOUND');

    // Get a reference to the amount of unstaked tokens.
    uint256 _unlockedStakedTokens = stakedBalanceOf[_holder][_projectId] -
      lockedBalanceOf[_holder][_projectId];

    // There must be enough unlocked staked tokens to unstake.
    require(_unlockedStakedTokens >= _amount, 'INSUFFICIENT_FUNDS');

    // Subtract the unstaked amount from the holder's balance.
    stakedBalanceOf[_holder][_projectId] = stakedBalanceOf[_holder][_projectId] - _amount;

    // Subtract the unstaked amount from the project's total supply.
    stakedTotalSupplyOf[_projectId] = stakedTotalSupplyOf[_projectId] - _amount;

    // Mint the equivalent amount of ERC20s.
    _token.mint(_holder, _amount);

    emit Unstake(_holder, _projectId, _amount, msg.sender);
  }

  /** 
      @notice 
      Lock a project's tokens, preventing them from being redeemed and from converting to ERC20s.

      @dev
      Only a ticket holder or an operator can lock its tokens.

      @param _holder The holder to lock tokens from.
      @param _projectId The ID of the project whos tokens are being locked.
      @param _amount The amount of tokens to lock.
    */
  function lockFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  )
    external
    override
    requirePermissionAllowingWildcardDomain(_holder, _projectId, JBOperations.LOCK)
  {
    // Amount must be greater than 0.
    require(_amount > 0, 'NO_OP');

    // The holder must have enough tokens to lock.
    require(
      stakedBalanceOf[_holder][_projectId] - lockedBalanceOf[_holder][_projectId] >= _amount,
      'INSUFFICIENT_FUNDS'
    );

    // Update the lock.
    lockedBalanceOf[_holder][_projectId] = lockedBalanceOf[_holder][_projectId] + _amount;
    lockedBalanceBy[msg.sender][_holder][_projectId] =
      lockedBalanceBy[msg.sender][_holder][_projectId] +
      _amount;

    emit Lock(_holder, _projectId, _amount, msg.sender);
  }

  /** 
      @notice 
      Unlock a project's tokens.

      @dev
      The address that locked the tokens must be the address that unlocks the tokens.

      @param _holder The holder to unlock tokens from.
      @param _projectId The ID of the project whos tokens are being unlocked.
      @param _amount The amount of tokens to unlock.
    */
  function unlockFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external override {
    // Amount must be greater than 0.
    require(_amount > 0, 'NO_OP');

    // There must be enough locked tokens to unlock.
    require(lockedBalanceBy[msg.sender][_holder][_projectId] >= _amount, 'INSUFFICIENT_FUNDS');

    // Update the lock.
    lockedBalanceOf[_holder][_projectId] = lockedBalanceOf[_holder][_projectId] - _amount;
    lockedBalanceBy[msg.sender][_holder][_projectId] =
      lockedBalanceBy[msg.sender][_holder][_projectId] -
      _amount;

    emit Unlock(_holder, _projectId, _amount, msg.sender);
  }

  /** 
      @notice 
      Allows a ticket holder to transfer its tokens to another account, without unstaking to ERC-20s.

      @dev
      Only a ticket holder or an operator can transfer its tokens.

      @param _recipient The recipient of the tokens.
      @param _holder The holder to transfer tokens from.
      @param _projectId The ID of the project whos tokens are being transfered.
      @param _amount The amount of tokens to transfer.
    */
  function transferTo(
    address _recipient,
    address _holder,
    uint256 _projectId,
    uint256 _amount
  )
    external
    override
    requirePermissionAllowingWildcardDomain(_holder, _projectId, JBOperations.TRANSFER)
  {
    // Can't transfer to the zero address.
    require(_recipient != address(0), 'ZERO_ADDRESS');

    // An address can't transfer to itself.
    require(_holder != _recipient, 'IDENTITY');

    // There must be an amount to transfer.
    require(_amount > 0, 'NO_OP');

    // Get a reference to the amount of unlocked staked tokens.
    uint256 _unlockedStakedTokens = stakedBalanceOf[_holder][_projectId] -
      lockedBalanceOf[_holder][_projectId];

    // There must be enough unlocked staked tokens to transfer.
    require(_amount <= _unlockedStakedTokens, 'INSUFFICIENT_FUNDS');

    // Subtract from the holder.
    stakedBalanceOf[_holder][_projectId] = stakedBalanceOf[_holder][_projectId] - _amount;

    // Add the tokens to the recipient.
    stakedBalanceOf[_recipient][_projectId] = stakedBalanceOf[_recipient][_projectId] + _amount;

    emit Transfer(_holder, _projectId, _recipient, _amount, msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.
*/
abstract contract JBOperatable is IJBOperatable {
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    require(
      msg.sender == _account ||
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex),
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  modifier requirePermissionAllowingWildcardDomain(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    require(
      msg.sender == _account ||
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) ||
        operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex),
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  modifier requirePermissionAcceptingAlternateAddress(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    address _alternate
  ) {
    require(
      msg.sender == _account ||
        operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) ||
        msg.sender == _alternate,
      'Operatable: UNAUTHORIZED'
    );
    _;
  }

  /// @notice A contract storing operator assignments.
  IJBOperatorStore public immutable override operatorStore;

  /** 
      @param _operatorStore A contract storing operator assignments.
    */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBTerminalUtility.sol';

abstract contract JBTerminalUtility is IJBTerminalUtility {
  modifier onlyTerminal(uint256 _projectId) {
    require(
      address(directory.terminalOf(_projectId, address(0))) == msg.sender,
      'TerminalUtility: UNAUTHORIZED'
    );
    _;
  }

  // modifier onlyTerminalOrBootloader(uint256 _projectId) {
  //     require(
  //         msg.sender == address(directory.terminalOf(_projectId)) ||
  //             msg.sender == bootloader,
  //         "TerminalUtility: UNAUTHORIZED"
  //     );
  //     _;
  // }

  /// @notice The direct deposit terminals.
  IJBDirectory public immutable override directory;

  /// @notice The direct deposit terminals.
  // address public immutable override bootloader;

  /** 
      @param _directory A directory of a project's current Juicebox terminal to receive payments in.
    */
  constructor(IJBDirectory _directory) {
    directory = _directory;
    // bootloader = _bootloader;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetTerminal(uint256 indexed projectId, IJBTerminal indexed terminal, address caller);

  function projects() external view returns (IJBProjects);

  function terminalOf(uint256 _projectId, address _token) external view returns (IJBTerminal);

  function terminalsOf(uint256 _projectId) external view returns (IJBTerminal[] memory);

  function isTerminalOf(uint256 _projectId, address _terminal) external view returns (bool);

  function addTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  // function setTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  function transferTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

struct OperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(OperatorData calldata _operatorData) external;

  function setOperators(OperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBTerminal.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    bytes32 indexed handle,
    string uri,
    address caller
  );

  event SetHandle(uint256 indexed projectId, bytes32 indexed handle, address caller);

  event SetUri(uint256 indexed projectId, string uri, address caller);

  event TransferHandle(
    uint256 indexed projectId,
    address indexed transferAddress,
    bytes32 indexed handle,
    bytes32 newHandle,
    address caller
  );

  event ClaimHandle(
    uint256 indexed projectId,
    address indexed transferAddress,
    bytes32 indexed handle,
    address caller
  );

  event ChallengeHandle(
    bytes32 indexed handle,
    uint256 indexed projectId,
    uint256 challengeExpiry,
    address caller
  );

  event RenewHandle(bytes32 indexed handle, uint256 indexed projectId, address caller);

  function count() external view returns (uint256);

  function uriOf(uint256 _projectId) external view returns (string memory);

  function handleOf(uint256 _projectId) external returns (bytes32 handle);

  function idFor(bytes32 _handle) external returns (uint256 projectId);

  function transferAddressFor(bytes32 _handle) external returns (address receiver);

  function challengeExpiryOf(bytes32 _handle) external returns (uint256);

  function createFor(
    address _owner,
    bytes32 _handle,
    string calldata _uri
  ) external returns (uint256 id);

  function setHandleOf(uint256 _projectId, bytes32 _handle) external;

  function setUriOf(uint256 _projectId, string calldata _uri) external;

  function transferHandleOf(
    uint256 _projectId,
    address _transferAddress,
    bytes32 _newHandle
  ) external returns (bytes32 _handle);

  function claimHandle(
    bytes32 _handle,
    address _for,
    uint256 _projectId
  ) external;

  function challengeHandle(bytes32 _handle) external;

  function renewHandleOf(uint256 _projectId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';

interface IJBTerminal {
  function pay(
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTickets,
    bool _preferUnstakedTickets,
    string calldata _memo,
    bytes calldata _delegateMetadata
  ) external payable returns (uint256 fundingCycleId);

  function addToBalanceOf(uint256 _projectId, string memory _memo) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';

interface IJBTerminalUtility {
  function directory() external view returns (IJBDirectory);

  // function bootloader() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IJBToken is IERC20 {
  function mint(address _account, uint256 _amount) external;

  function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );
  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool shouldUnstakeTokens,
    bool preferUnstakedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 unlockedStakedBalance,
    bool preferUnstakedTokens,
    address caller
  );

  event Stake(address indexed holder, uint256 indexed projectId, uint256 amount, address caller);

  event Unstake(address indexed holder, uint256 indexed projectId, uint256 amount, address caller);

  event Lock(address indexed holder, uint256 indexed projectId, uint256 amount, address caller);

  event Unlock(address indexed holder, uint256 indexed projectId, uint256 amount, address caller);

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function lockedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function lockedBalanceBy(
    address _operator,
    address _holder,
    uint256 _projectId
  ) external view returns (uint256);

  function stakedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function stakedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferUnstakedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferUnstakedTokens
  ) external;

  function stakeFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function unstakeFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function lockFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function unlockFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferTo(
    address _recipient,
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBOperations {
  uint256 public constant CONFIGURE = 1;
  uint256 public constant PRINT_PREMINED_TOKENS = 2;
  uint256 public constant REDEEM = 3;
  uint256 public constant MIGRATE = 4;
  uint256 public constant SET_HANDLE = 5;
  uint256 public constant SET_URI = 6;
  uint256 public constant CLAIM_HANDLE = 7;
  uint256 public constant RENEW_HANDLE = 8;
  uint256 public constant ISSUE = 9;
  uint256 public constant STAKE = 10;
  uint256 public constant UNSTAKE = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant LOCK = 13;
  uint256 public constant SET_TERMINAL = 14;
  uint256 public constant USE_ALLOWANCE = 15;
  uint256 public constant BURN = 16;
  uint256 public constant MINT = 17;
  uint256 public constant SET_SPLITS = 18;
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 10000
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