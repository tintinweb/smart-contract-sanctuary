// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
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

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
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

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
contract Governed is Context {
    address public governor;
    address private proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev Initializes the contract setting the deployer as the initial governor.
     */
    constructor() {
        address msgSender = _msgSender();
        governor = msgSender;
        emit UpdatedGovernor(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor {
        require(governor == _msgSender(), "caller-is-not-the-governor");
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address _proposedGovernor) external onlyGovernor {
        //solhint-disable-next-line reason-string
        require(_proposedGovernor != address(0), "proposed-governor-is-zero-address");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        //solhint-disable-next-line reason-string
        require(proposedGovernor == _msgSender(), "caller-is-not-the-proposed-governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 */
contract Pausable is Context {
    event Paused(address account);
    event Shutdown(address account);
    event Unpaused(address account);
    event Open(address account);

    bool public paused;
    bool public stopEverything;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier whenNotShutdown() {
        require(!stopEverything, "Pausable: shutdown");
        _;
    }

    modifier whenShutdown() {
        require(stopEverything, "Pausable: not shutdown");
        _;
    }

    /// @dev Pause contract operations, if contract is not paused.
    function _pause() internal virtual whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    /// @dev Unpause contract operations, allow only if contract is paused and not shutdown.
    function _unpause() internal virtual whenPaused whenNotShutdown {
        paused = false;
        emit Unpaused(_msgSender());
    }

    /// @dev Shutdown contract operations, if not already shutdown.
    function _shutdown() internal virtual whenNotShutdown {
        stopEverything = true;
        paused = true;
        emit Shutdown(_msgSender());
    }

    /// @dev Open contract operations, if contract is in shutdown state
    function _open() internal virtual whenShutdown {
        stopEverything = false;
        emit Open(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IAddressList {
    function add(address a) external returns (bool);

    function remove(address a) external returns (bool);

    function get(address a) external view returns (uint256);

    function contains(address a) external view returns (bool);

    function length() external view returns (uint256);

    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IAddressListFactory {
    function ours(address a) external view returns (bool);

    function listCount() external view returns (uint256);

    function listAt(uint256 idx) external view returns (address);

    function createList() external returns (address listaddr);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IStrategy {
    function rebalance() external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function feeCollector() external view returns (address);

    function isReservedToken(address _token) external view returns (bool);

    function migrate(address _newStrategy) external;

    function token() external view returns (address);

    function totalValue() external view returns (uint256);

    function pool() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Governed.sol";
import "../Pausable.sol";
import "../interfaces/bloq/IAddressList.sol";
import "../interfaces/bloq/IAddressListFactory.sol";

/// @title Holding pool share token
// solhint-disable no-empty-blocks
abstract contract PoolShareToken is ERC20Permit, Pausable, ReentrancyGuard, Governed {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    IAddressList public immutable feeWhitelist;
    uint256 public constant MAX_BPS = 10_000;
    address public feeCollector; // fee collector address
    uint256 public withdrawFee; // withdraw fee for this pool

    event Deposit(address indexed owner, uint256 shares, uint256 amount);
    event Withdraw(address indexed owner, uint256 shares, uint256 amount);
    event UpdatedFeeCollector(address indexed previousFeeCollector, address indexed newFeeCollector);
    event UpdatedWithdrawFee(uint256 previousWithdrawFee, uint256 newWithdrawFee);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) ERC20Permit(_name) ERC20(_name, _symbol) {
        token = IERC20(_token);
        IAddressListFactory factory = IAddressListFactory(0xded8217De022706A191eE7Ee0Dc9df1185Fb5dA3);
        IAddressList _feeWhitelist = IAddressList(factory.createList());
        feeWhitelist = _feeWhitelist;
    }

    /**
     * @notice Update fee collector address for this pool
     * @param _newFeeCollector new fee collector address
     */
    function updateFeeCollector(address _newFeeCollector) external onlyGovernor {
        require(_newFeeCollector != address(0), "fee-collector-address-is-zero");
        require(feeCollector != _newFeeCollector, "same-fee-collector");
        emit UpdatedFeeCollector(feeCollector, _newFeeCollector);
        feeCollector = _newFeeCollector;
    }

    /**
     * @notice Update withdraw fee for this pool
     * @dev Format: 1500 = 15% fee, 100 = 1%
     * @param _newWithdrawFee new withdraw fee
     */
    function updateWithdrawFee(uint256 _newWithdrawFee) external onlyGovernor {
        require(feeCollector != address(0), "fee-collector-not-set");
        require(_newWithdrawFee <= 10000, "withdraw-fee-limit-reached");
        require(withdrawFee != _newWithdrawFee, "same-withdraw-fee");
        emit UpdatedWithdrawFee(withdrawFee, _newWithdrawFee);
        withdrawFee = _newWithdrawFee;
    }

    /**
     * @notice Deposit ERC20 tokens and receive pool shares depending on the current share price.
     * @param _amount ERC20 token amount.
     */
    function deposit(uint256 _amount) external virtual nonReentrant whenNotPaused {
        _deposit(_amount);
    }

    /**
     * @notice Deposit ERC20 tokens with permit aka gasless approval.
     * @param _amount ERC20 token amount.
     * @param _deadline The time at which signature will expire
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual nonReentrant whenNotPaused {
        IERC20Permit(address(token)).permit(_msgSender(), address(this), _amount, _deadline, _v, _r, _s);
        _deposit(_amount);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * Withdraw fee, if any, will be deduced from given shares and transferred to feeCollector.
     * Burn remaining shares and return collateral.
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function withdraw(uint256 _shares) external virtual nonReentrant whenNotShutdown {
        _withdraw(_shares);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * @dev Burn shares and return collateral. No withdraw fee will be assessed
     * when this function is called. Only some white listed address can call this function.
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function whitelistedWithdraw(uint256 _shares) external virtual nonReentrant whenNotShutdown {
        require(feeWhitelist.contains(_msgSender()), "not-a-white-listed-address");
        _withdrawWithoutFee(_shares);
    }

    /**
     * @notice Transfer tokens to multiple recipient
     * @dev Address array and amount array are 1:1 and are in order.
     * @param _recipients array of recipient addresses
     * @param _amounts array of token amounts
     * @return true/false
     */
    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool) {
        require(_recipients.length == _amounts.length, "input-length-mismatch");
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(transfer(_recipients[i], _amounts[i]), "multi-transfer-failed");
        }
        return true;
    }

    /**
     * @notice Get price per share
     * @dev Return value will be in token defined decimals.
     */
    function pricePerShare() public view returns (uint256) {
        if (totalSupply() == 0 || totalValue() == 0) {
            return convertFrom18(1e18);
        }
        return (totalValue() * 1e18) / totalSupply();
    }

    /// @dev Convert from 18 decimals to token defined decimals. Default no conversion.
    function convertFrom18(uint256 _amount) public view virtual returns (uint256) {
        return _amount;
    }

    /// @dev Returns the token stored in the pool. It will be in token defined decimals.
    function tokensHere() public view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Returns sum of token locked in other contracts and token stored in the pool.
     * Default tokensHere. It will be in token defined decimals.
     */
    function totalValue() public view virtual returns (uint256);

    /**
     * @dev Hook that is called just before burning tokens. This withdraw collateral from withdraw queue
     * @param _share Pool share in 18 decimals
     */
    function _beforeBurning(uint256 _share) internal virtual returns (uint256) {}

    /**
     * @dev Hook that is called just after burning tokens.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _afterBurning(uint256 _amount) internal virtual returns (uint256) {
        token.safeTransfer(_msgSender(), _amount);
        return _amount;
    }

    /**
     * @dev Hook that is called just before minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred from user to this contract.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _beforeMinting(uint256 _amount) internal virtual {
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /**
     * @dev Hook that is called just after minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred to a different contract.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _afterMinting(uint256 _amount) internal virtual {}

    /**
     * @dev Calculate shares to mint based on the current share price and given amount.
     * @param _amount Collateral amount in collateral token defined decimals.
     * @return share amount in 18 decimal
     */
    function _calculateShares(uint256 _amount) internal view returns (uint256) {
        require(_amount != 0, "amount-is-0");
        uint256 _share = ((_amount * 1e18) / pricePerShare());
        return _amount > ((_share * pricePerShare()) / 1e18) ? _share + 1 : _share;
    }

    /// @dev Deposit incoming token and mint pool token i.e. shares.
    function _deposit(uint256 _amount) internal {
        uint256 _shares = _calculateShares(_amount);
        _beforeMinting(_amount);
        _mint(_msgSender(), _shares);
        _afterMinting(_amount);
        emit Deposit(_msgSender(), _shares, _amount);
    }

    /// @dev Burns shares and returns the collateral value, after fee, of those.
    function _withdraw(uint256 _shares) internal {
        if (withdrawFee == 0) {
            _withdrawWithoutFee(_shares);
        } else {
            require(_shares != 0, "share-is-0");
            uint256 _fee = (_shares * withdrawFee) / MAX_BPS;
            uint256 _sharesAfterFee = _shares - _fee;
            uint256 _amountWithdrawn = _beforeBurning(_sharesAfterFee);
            // Recalculate proportional share on actual amount withdrawn
            uint256 _proportionalShares = _calculateShares(_amountWithdrawn);

            // Using convertFrom18() to avoid dust.
            // Pool share token is in 18 decimal and collatoral token decimal is <=18.
            // Anything less than 10**(18-collortalTokenDecimal) is dust.
            if (convertFrom18(_proportionalShares) < convertFrom18(_sharesAfterFee)) {
                // Recalculate shares to withdraw, fee and shareAfterFee
                _shares = (_proportionalShares * MAX_BPS) / (MAX_BPS - withdrawFee);
                _fee = _shares - _proportionalShares;
                _sharesAfterFee = _proportionalShares;
            }
            _burn(_msgSender(), _sharesAfterFee);
            _transfer(_msgSender(), feeCollector, _fee);
            _afterBurning(_amountWithdrawn);
            emit Withdraw(_msgSender(), _shares, _amountWithdrawn);
        }
    }

    /// @dev Burns shares and returns the collateral value of those.
    function _withdrawWithoutFee(uint256 _shares) internal {
        require(_shares != 0, "share-is-0");
        uint256 _amountWithdrawn = _beforeBurning(_shares);
        uint256 _proportionalShares = _calculateShares(_amountWithdrawn);
        if (convertFrom18(_proportionalShares) < convertFrom18(_shares)) {
            _shares = _proportionalShares;
        }
        _burn(_msgSender(), _shares);
        _afterBurning(_amountWithdrawn);
        emit Withdraw(_msgSender(), _shares, _amountWithdrawn);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./PoolShareToken.sol";
import "../interfaces/vesper/IStrategy.sol";

contract VTokenBase is PoolShareToken {
    using SafeERC20 for IERC20;

    struct StrategyConfig {
        bool active;
        uint256 interestFee; // Strategy fee
        uint256 debtRate; //strategy can not borrow large amount in short durations. Can set big limit for trusted strategy
        uint256 lastRebalance;
        uint256 totalDebt; // Total outstanding debt strategy has
        uint256 totalLoss; // Total loss that strategy has realized
        uint256 totalProfit; // Total gain that strategy has realized
        uint256 debtRatio; // % of asset allocation
    }

    mapping(address => StrategyConfig) public strategy;
    uint256 public totalDebtRatio; // this will keep some buffer amount in pool
    uint256 public totalDebt;
    address[] public strategies;
    address[] public withdrawQueue;

    IAddressList public keepers;
    IAddressList public maintainers;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    event StrategyAdded(address indexed strategy, uint256 interestFee, uint256 debtRatio, uint256 debtRate);
    event StrategyMigrated(
        address indexed oldStrategy,
        address indexed newStrategy,
        uint256 interestFee,
        uint256 debtRatio,
        uint256 debtRate
    );
    event UpdatedInterestFee(address indexed strategy, uint256 interestFee);
    event UpdatedStrategyDebtParams(address indexed strategy, uint256 debtRatio, uint256 debtRate);
    event EarningReported(
        address indexed strategy,
        uint256 profit,
        uint256 loss,
        uint256 payback,
        uint256 strategyDebt,
        uint256 poolDebt,
        uint256 creditLine
    );

    constructor(
        string memory name,
        string memory symbol,
        address _token // solhint-disable-next-line no-empty-blocks
    ) PoolShareToken(name, symbol, _token) {}

    modifier onlyKeeper() {
        require(keepers.contains(_msgSender()), "caller-is-not-a-keeper");
        _;
    }

    modifier onlyMaintainer() {
        require(maintainers.contains(_msgSender()), "caller-is-not-maintainer");
        _;
    }

    modifier onlyStrategy() {
        require(strategy[_msgSender()].active, "caller-is-not-active-strategy");
        _;
    }

    ///////////////////////////// Only Keeper ///////////////////////////////
    function pause() external onlyKeeper {
        _pause();
    }

    function unpause() external onlyKeeper {
        _unpause();
    }

    function shutdown() external onlyKeeper {
        _shutdown();
    }

    function open() external onlyKeeper {
        _open();
    }

    ///////////////////////////////////////////////////////////////////////////

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Create keeper and maintainer list
     * @dev Create lists and add governor into the list.
     * NOTE: Any function with onlyKeeper and onlyMaintainer modifier will not work until this function is called.
     * NOTE: Due to gas constraint this function cannot be called in constructor.
     */
    function init() external onlyGovernor {
        require(address(keepers) == address(0), "list-already-created");
        IAddressListFactory _factory = IAddressListFactory(0xded8217De022706A191eE7Ee0Dc9df1185Fb5dA3);
        keepers = IAddressList(_factory.createList());
        maintainers = IAddressList(_factory.createList());
        // List creator i.e. governor can do job of keeper and maintainer.
        keepers.add(governor);
        maintainers.add(governor);
    }

    /**
     * @notice Add given address in provided address list.
     * @dev Use it to add keeper in keepers list and to add address in feeWhitelist
     * @param _listToUpdate address of AddressList contract.
     * @param _addressToAdd address which we want to add in AddressList.
     */
    function addInList(address _listToUpdate, address _addressToAdd) external onlyKeeper {
        require(IAddressList(_listToUpdate).add(_addressToAdd), "add-in-list-failed");
    }

    /**
     * @notice Remove given address from provided address list.
     * @dev Use it to remove keeper from keepers list and to remove address from feeWhitelist
     * @param _listToUpdate address of AddressList contract.
     * @param _addressToRemove address which we want to remove from AddressList.
     */
    function removeFromList(address _listToUpdate, address _addressToRemove) external onlyKeeper {
        require(IAddressList(_listToUpdate).remove(_addressToRemove), "remove-from-list-failed");
    }

    /// @dev Add strategy
    function addStrategy(
        address _strategy,
        uint256 _interestFee,
        uint256 _debtRatio,
        uint256 _debtRate
    ) public onlyGovernor {
        require(_strategy != address(0), "strategy-address-is-zero");
        require(!strategy[_strategy].active, "strategy-already-added");
        totalDebtRatio = totalDebtRatio + _debtRatio;
        require(totalDebtRatio <= MAX_BPS, "totalDebtRatio-above-max_bps");
        require(_interestFee <= MAX_BPS, "interest-fee-above-max_bps");
        StrategyConfig memory newStrategy =
            StrategyConfig({
                active: true,
                interestFee: _interestFee,
                debtRatio: _debtRatio,
                totalDebt: 0,
                totalProfit: 0,
                totalLoss: 0,
                debtRate: _debtRate,
                lastRebalance: block.number
            });
        strategy[_strategy] = newStrategy;
        strategies.push(_strategy);
        withdrawQueue.push(_strategy);
        emit StrategyAdded(_strategy, _interestFee, _debtRatio, _debtRate);
    }

    function migrateStrategy(address _old, address _new) external onlyGovernor {
        require(_new != address(0), "new-address-is-zero");
        require(_old != address(0), "old-address-is-zero");
        require(IStrategy(_new).pool() == address(this), "not-valid-new-strategy");
        require(IStrategy(_old).pool() == address(this), "not-valid-old-strategy");
        require(strategy[_old].active, "strategy-already-migrated");
        require(!strategy[_new].active, "strategy-already-added");
        StrategyConfig memory _newStrategy =
            StrategyConfig({
                active: true,
                interestFee: strategy[_old].interestFee,
                debtRatio: strategy[_old].debtRatio,
                totalDebt: strategy[_old].totalDebt,
                totalProfit: 0,
                totalLoss: 0,
                debtRate: strategy[_old].debtRate,
                lastRebalance: strategy[_old].lastRebalance
            });
        strategy[_old].debtRatio = 0;
        strategy[_old].totalDebt = 0;
        strategy[_old].debtRate = 0;
        strategy[_old].active = false;
        strategy[_new] = _newStrategy;

        IStrategy(_old).migrate(_new);

        // Strategies and withdrawQueue has same length but we still want
        // to iterate over them in different loop.
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i] == _old) {
                strategies[i] = _new;
                break;
            }
        }
        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] == _old) {
                withdrawQueue[i] = _new;
                break;
            }
        }
        emit StrategyMigrated(
            _old,
            _new,
            strategy[_new].interestFee,
            strategy[_new].debtRatio,
            strategy[_new].debtRate
        );
    }

    function updateInterestFee(address _strategy, uint256 _interestFee) external onlyGovernor {
        require(_strategy != address(0), "strategy-address-is-zero");
        require(strategy[_strategy].active, "strategy-not-active");
        require(_interestFee <= MAX_BPS, "interest-fee-above-max_bps");
        strategy[_strategy].interestFee = _interestFee;
        emit UpdatedInterestFee(_strategy, _interestFee);
    }

    /**
     * @dev Update debt ratio.  A strategy is retired when debtRatio is 0
     */
    function updateDebtRatio(address _strategy, uint256 _debtRatio) external onlyMaintainer {
        require(strategy[_strategy].active, "strategy-not-active");
        totalDebtRatio = totalDebtRatio - strategy[_strategy].debtRatio + _debtRatio;
        require(totalDebtRatio <= MAX_BPS, "totalDebtRatio-above-max_bps");
        strategy[_strategy].debtRatio = _debtRatio;
        emit UpdatedStrategyDebtParams(_strategy, _debtRatio, strategy[_strategy].debtRate);
    }

    /**
     * @dev Update debtRate per block.
     */
    function updateDebtRate(address _strategy, uint256 _debtRate) external onlyKeeper {
        require(strategy[_strategy].active, "strategy-not-active");
        strategy[_strategy].debtRate = _debtRate;
        emit UpdatedStrategyDebtParams(_strategy, strategy[_strategy].debtRatio, _debtRate);
    }

    /// @dev update withdrawal queue
    function updateWithdrawQueue(address[] memory _withdrawQueue) external onlyMaintainer {
        uint256 _length = _withdrawQueue.length;
        require(_length > 0, "withdrawal-queue-blank");
        require(_length == withdrawQueue.length && _length == strategies.length, "incorrect-withdraw-queue-length");
        for (uint256 i = 0; i < _length; i++) {
            require(strategy[_withdrawQueue[i]].active, "invalid-strategy");
        }
        withdrawQueue = _withdrawQueue;
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     @dev Strategy call this in regular interval.
     @param _profit yield generated by strategy. Strategy get performance fee on this amount
     @param _loss  Reduce debt ,also reduce debtRatio, increase loss in record.
     @param _payback strategy willing to payback outstanding above debtLimit. no performance fee on this amount. 
      when governance has reduced debtRatio of strategy, strategy will report profit and payback amount separately. 
     */
    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external onlyStrategy {
        require(token.balanceOf(_msgSender()) >= (_profit + _payback), "insufficient-balance-in-strategy");
        if (_loss != 0) {
            _reportLoss(_msgSender(), _loss);
        }

        uint256 _overLimitDebt = _excessDebt(_msgSender());
        uint256 _actualPayback = _min(_overLimitDebt, _payback);
        if (_actualPayback != 0) {
            strategy[_msgSender()].totalDebt -= _actualPayback;
            totalDebt -= _actualPayback;
        }
        uint256 _creditLine = _availableCreditLimit(_msgSender());
        if (_creditLine != 0) {
            strategy[_msgSender()].totalDebt += _creditLine;
            totalDebt += _creditLine;
        }
        uint256 _totalPayback = _profit + _actualPayback;
        if (_totalPayback < _creditLine) {
            token.safeTransfer(_msgSender(), _creditLine - _totalPayback);
        } else if (_totalPayback > _creditLine) {
            token.safeTransferFrom(_msgSender(), address(this), _totalPayback - _creditLine);
        }
        if (_profit != 0) {
            strategy[_msgSender()].totalProfit += _profit;
            _transferInterestFee(_profit);
        }
        emit EarningReported(
            _msgSender(),
            _profit,
            _loss,
            _actualPayback,
            strategy[_msgSender()].totalDebt,
            totalDebt,
            _creditLine
        );
    }

    /**
     * @dev Transfer given ERC20 token to feeCollector
     * @param _fromToken Token address to sweep
     */
    function sweepERC20(address _fromToken) external virtual onlyKeeper {
        require(_fromToken != address(token), "not-allowed-to-sweep");
        require(feeCollector != address(0), "fee-collector-not-set");
        IERC20(_fromToken).safeTransfer(feeCollector, IERC20(_fromToken).balanceOf(address(this)));
    }

    /**
    @dev debt above current debt limit
    */
    function excessDebt(address _strategy) external view returns (uint256) {
        return _excessDebt(_strategy);
    }

    /**
    @dev available credit limit is calculated based on current debt of pool and strategy, current debt limit of pool and strategy. 
    // credit available = min(pool's debt limit, strategy's debt limit, max debt per rebalance)
    // when some strategy do not pay back outstanding debt, this impact credit line of other strategy if totalDebt of pool >= debtLimit of pool
    */
    function availableCreditLimit(address _strategy) external view returns (uint256) {
        return _availableCreditLimit(_strategy);
    }

    /**
     * @notice Get total debt of given strategy
     */
    function totalDebtOf(address _strategy) external view returns (uint256) {
        return strategy[_strategy].totalDebt;
    }

    /// @dev Returns total value of vesper pool, in terms of collateral token
    function totalValue() public view override returns (uint256) {
        return totalDebt + tokensHere();
    }

    function _withdrawCollateral(uint256 _amount) internal virtual {
        // Withdraw amount from queue
        uint256 _debt;
        uint256 _balanceAfter;
        uint256 _balanceBefore;
        uint256 _amountWithdrawn;
        uint256 _amountNeeded = _amount;
        uint256 _totalAmountWithdrawn;
        for (uint256 i; i < withdrawQueue.length; i++) {
            _debt = strategy[withdrawQueue[i]].totalDebt;
            if (_debt == 0) {
                continue;
            }
            if (_amountNeeded > _debt) {
                // Should not withdraw more than current debt of strategy.
                _amountNeeded = _debt;
            }
            _balanceBefore = tokensHere();
            //solhint-disable no-empty-blocks
            try IStrategy(withdrawQueue[i]).withdraw(_amountNeeded) {} catch {
                continue;
            }
            _balanceAfter = tokensHere();
            _amountWithdrawn = _balanceAfter - _balanceBefore;
            // Adjusting totalDebt. Assuming that during next reportEarning(), strategy will report loss if amountWithdrawn < _amountNeeded
            strategy[withdrawQueue[i]].totalDebt -= _amountWithdrawn;
            totalDebt -= _amountWithdrawn;
            _totalAmountWithdrawn += _amountWithdrawn;
            if (_totalAmountWithdrawn >= _amount) {
                // withdraw done
                break;
            }
            _amountNeeded = _amount - _totalAmountWithdrawn;
        }
    }

    /**
     * @dev Before burning hook.
     * withdraw amount from strategies
     */
    function _beforeBurning(uint256 _share) internal override returns (uint256 actualWithdrawn) {
        uint256 _amount = (_share * pricePerShare()) / 1e18;
        uint256 _balanceNow = tokensHere();
        if (_amount > _balanceNow) {
            _withdrawCollateral(_amount - _balanceNow);
            _balanceNow = tokensHere();
        }
        actualWithdrawn = _balanceNow < _amount ? _balanceNow : _amount;
    }

    /**
    @dev when a strategy report loss, its debtRatio decrease to get fund back quickly.
    */
    function _reportLoss(address _strategy, uint256 _loss) internal {
        uint256 _currentDebt = strategy[_strategy].totalDebt;
        require(_currentDebt >= _loss, "loss-too-high");
        strategy[_strategy].totalLoss += _loss;
        strategy[_strategy].totalDebt -= _loss;
        totalDebt -= _loss;
        uint256 _deltaDebtRatio = _min((_loss * MAX_BPS) / totalValue(), strategy[_strategy].debtRatio);
        strategy[_strategy].debtRatio -= _deltaDebtRatio;
        totalDebtRatio -= _deltaDebtRatio;
    }

    function _excessDebt(address _strategy) internal view returns (uint256) {
        uint256 _currentDebt = strategy[_strategy].totalDebt;
        if (stopEverything) {
            return _currentDebt;
        }
        uint256 _maxDebt = (strategy[_strategy].debtRatio * totalValue()) / MAX_BPS;
        return _currentDebt > _maxDebt ? (_currentDebt - _maxDebt) : 0;
    }

    function _availableCreditLimit(address _strategy) internal view returns (uint256) {
        if (stopEverything) {
            return 0;
        }
        uint256 _totalValue = totalValue();
        uint256 _maxDebt = (strategy[_strategy].debtRatio * _totalValue) / MAX_BPS;
        uint256 _currentDebt = strategy[_strategy].totalDebt;
        if (_currentDebt >= _maxDebt) {
            return 0;
        }
        uint256 _poolDebtLimit = (totalDebtRatio * _totalValue) / MAX_BPS;
        if (totalDebt >= _poolDebtLimit) {
            return 0;
        }
        uint256 _available = _maxDebt - _currentDebt;
        _available = _min(_min(tokensHere(), _available), _poolDebtLimit - totalDebt);
        _available = _min(
            (block.number - strategy[_strategy].lastRebalance) * strategy[_strategy].debtRate,
            _available
        );
        return _available;
    }

    /**
    @dev strategy get interest fee in pool share token
    */
    function _transferInterestFee(uint256 _profit) internal {
        uint256 _fee = (_profit * strategy[_msgSender()].interestFee) / MAX_BPS;
        if (_fee != 0) {
            _fee = _calculateShares(_fee);
            _mint(_msgSender(), _fee);
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VTokenBase.sol";

//solhint-disable no-empty-blocks
contract VUSDC is VTokenBase {
    string public constant VERSION = "3.0.0";

    // USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    constructor() VTokenBase("vUSDC Pool", "vUSDC", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) {}

    /// @dev Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _value) public pure override returns (uint256) {
        return _value / (10**12);
    }
}

