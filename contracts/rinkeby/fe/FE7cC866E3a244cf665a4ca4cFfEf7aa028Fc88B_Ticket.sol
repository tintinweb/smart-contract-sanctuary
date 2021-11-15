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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IControlledToken.sol";

/**
  * @title  PoolTogether V4 Controlled ERC20 Token
  * @author PoolTogether Inc Team
  * @notice  ERC20 Tokens with a controller for minting & burning
*/
contract ControlledToken is ERC20Permit, IControlledToken {

  /* ============ Global Variables ============ */

  /// @notice Interface to the contract responsible for controlling mint/burn
  address public override controller;

  /// @notice ERC20 controlled token decimals.
  uint8 private immutable _decimals;

  /* ============ Events ============ */

  /// @dev Emitted when contract is deployed
  event Deployed(
    string name,
    string symbol,
    uint8 decimals,
    address controller
  );

  /* ============ Modifiers ============ */

  /// @dev Function modifier to ensure that the caller is the controller contract
  modifier onlyController {
    require(msg.sender == address(controller), "ControlledToken/only-controller");
    _;
  }

  /* ============ Constructor ============ */

  /// @notice Deploy the Controlled Token with Token Details and the Controller
  /// @param _name The name of the Token
  /// @param _symbol The symbol for the Token
  /// @param decimals_ The number of decimals for the Token
  /// @param _controller Address of the Controller contract for minting & burning
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 decimals_,
    address _controller
  )
    ERC20Permit("PoolTogether ControlledToken")
    ERC20(_name, _symbol)
  {
    require(address(_controller) != address(0), "ControlledToken/controller-not-zero-address");
    controller = _controller;

    require(decimals_ > 0, "ControlledToken/decimals-gt-zero");
    _decimals = decimals_;

    emit Deployed(
      _name,
      _symbol,
      decimals_,
      _controller
    );
  }

  /* ============ External Functions ============ */

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param _user Address of the receiver of the minted tokens
  /// @param _amount Amount of tokens to mint
  function controllerMint(address _user, uint256 _amount) external virtual override onlyController {
    _mint(_user, _amount);
  }

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurn(address _user, uint256 _amount) external virtual override onlyController {
    _burn(_user, _amount);
  }

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param _operator Address of the operator performing the burn action via the controller contract
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurnFrom(address _operator, address _user, uint256 _amount) external virtual override onlyController {
    if (_operator != _user) {
      _approve(_user, _operator, allowance(_user, _operator) - _amount);
    }

    _burn(_user, _amount);
  }

  /// @notice Returns the ERC20 controlled token decimals.
  /// @dev This value should be equal to the decimals of the token used to deposit into the pool.
  /// @return uint8 decimals.
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./libraries/OverflowSafeComparator.sol";
import "./libraries/TwabLib.sol";
import "./interfaces/ITicket.sol";
import "./ControlledToken.sol";

/**
  * @title  PoolTogether V4 Ticket
  * @author PoolTogether Inc Team
  * @notice The Ticket extends the standard ERC20 and ControlledToken interfaces with time-weighed average balance functionality.
            The TWAB (time-weighed average balance) enables contract-to-contract lookups of a user's average balance
            between timestamps. The timestamp/balance checkpoints are stored in a ring buffer for each user Account.
            Historical searches of a TWAB(s) are limited to the storage of these checkpoints. A user's average balance can
            be delegated to an alternative address. When delegating the average weighted balance is added to the delegatee
            TWAB lookup and removed from the delegaters TWAB lookup.
*/
contract Ticket is ControlledToken, ITicket {
  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  /// @notice Record of token holders TWABs for each account.
  mapping (address => TwabLib.Account) internal userTwabs;

  /// @notice Record of tickets total supply and most recent TWAB index.
  TwabLib.Account internal totalSupplyTwab;

  /// @notice Mapping of delegates.  Each address can delegate their ticket power to another.
  mapping(address => address) internal delegates;

  /// @notice Each address's balance
  mapping(address => uint256) internal balances;

  /* ============ Constructor ============ */

  /** 
    * @notice Constructs Ticket with passed parameters.
    * @param _name ERC20 ticket token name.
    * @param _symbol ERC20 ticket token symbol.
    * @param decimals_ ERC20 ticket token decimals.
    * @param _controller ERC20 ticket controller address (ie: Prize Pool address).
  */
  constructor (
    string memory _name,
    string memory _symbol,
    uint8 decimals_,
    address _controller
  ) ControlledToken(
    _name,
    _symbol,
    decimals_,
    _controller
  ){}

  /* ============ External Functions ============ */

  /// @inheritdoc ITicket
  function getAccountDetails(address _user) external view override returns (TwabLib.AccountDetails memory) {
    return userTwabs[_user].details;
  }

  /// @inheritdoc ITicket
  function getTwab(address _user, uint16 _index) external view override returns (ObservationLib.Observation memory) {
    return userTwabs[_user].twabs[_index];
  }

 /// @inheritdoc ITicket
  function getBalanceAt(address _user, uint256 _target) external override view returns (uint256) {
    TwabLib.Account storage account = userTwabs[_user];
    return TwabLib.getBalanceAt(account.twabs, account.details, uint32(_target), uint32(block.timestamp));
  }

/// @inheritdoc ITicket
  function getAverageBalancesBetween(address user, uint32[] calldata startTimes, uint32[] calldata endTimes) external override view
    returns (uint256[] memory)
  {
    return _getAverageBalancesBetween(userTwabs[user], startTimes, endTimes);
  }

  /// @inheritdoc ITicket
  function getAverageTotalSuppliesBetween(uint32[] calldata startTimes, uint32[] calldata endTimes) external override view
    returns (uint256[] memory)
  {
    return _getAverageBalancesBetween(totalSupplyTwab, startTimes, endTimes);
  }

  /// @inheritdoc ITicket
  function getAverageBalanceBetween(address _user, uint256 _startTime, uint256 _endTime) external override view returns (uint256) {
    TwabLib.Account storage account = userTwabs[_user];
    return TwabLib.getAverageBalanceBetween(account.twabs, account.details, uint32(_startTime), uint32(_endTime), uint32(block.timestamp));
  }

  /// @inheritdoc ITicket
  function getBalancesAt(address _user, uint32[] calldata _targets) external override view returns (uint256[] memory) {
    uint256 length = _targets.length;
    uint256[] memory _balances = new uint256[](length);

    TwabLib.Account storage twabContext = userTwabs[_user];
    TwabLib.AccountDetails memory details = twabContext.details;

    for(uint256 i = 0; i < length; i++) {
      _balances[i] = TwabLib.getBalanceAt(twabContext.twabs, details, _targets[i], uint32(block.timestamp));
    }

    return _balances;
  }

  /// @inheritdoc ITicket
  function getTotalSupplyAt(uint32 _target) external override view returns (uint256) {
    return TwabLib.getBalanceAt(totalSupplyTwab.twabs, totalSupplyTwab.details, _target, uint32(block.timestamp));
  }

  /// @inheritdoc ITicket
  function getTotalSuppliesAt(uint32[] calldata _targets) external override view returns (uint256[] memory) {
    uint256 length = _targets.length;
    uint256[] memory totalSupplies = new uint256[](length);

    TwabLib.AccountDetails memory details = totalSupplyTwab.details;

    for(uint256 i = 0; i < length; i++) {
      totalSupplies[i] = TwabLib.getBalanceAt(totalSupplyTwab.twabs, details, _targets[i], uint32(block.timestamp));
    }

    return totalSupplies;
  }
  
  /// @inheritdoc ITicket
  function delegateOf(address _user) external view override returns (address) {
    return delegates[_user];
  }

  /// @inheritdoc IERC20
  function balanceOf(address _user) public view override returns (uint256) {
    return _balanceOf(_user);
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override returns (uint256) {
    return totalSupplyTwab.details.balance;
  }

  /// @inheritdoc ITicket
  function delegate(address to) external virtual override {
    uint224 balance = uint224(_balanceOf(msg.sender));
    address currentDelegate = delegates[msg.sender];

    if (currentDelegate != address(0)) {
      _decreaseUserTwab(msg.sender, currentDelegate, balance);
    } else {
      _decreaseUserTwab(msg.sender, msg.sender, balance);
    }

    if (to != address(0)) {
      _increaseUserTwab(msg.sender, to, balance);
    } else {
      _increaseUserTwab(msg.sender, msg.sender, balance);
    }

    delegates[msg.sender] = to;

    emit Delegated(msg.sender, to);
  }

  /* ============ Internal Functions ============ */

  /// @notice Returns the ERC20 ticket token balance of a ticket holder.
  /// @return uint256 `_user` ticket token balance.
  function _balanceOf(address _user) internal view returns (uint256) {
    return balances[_user];
  }

  function _getAverageBalancesBetween(
    TwabLib.Account storage _account,
    uint32[] calldata _startTimes,
    uint32[] calldata _endTimes
  ) internal view returns (uint256[] memory) {
    require(_startTimes.length == _endTimes.length, "Ticket/start-end-times-length-match");
    TwabLib.AccountDetails storage accountDetails = _account.details;
    uint256[] memory averageBalances = new uint256[](_startTimes.length);

    for (uint i = 0; i < _startTimes.length; i++) {
      averageBalances[i] = TwabLib.getAverageBalanceBetween(_account.twabs, accountDetails, _startTimes[i], _endTimes[i], uint32(block.timestamp));
    }

    return averageBalances;
  }

  /// @notice Overridding of the `_transfer` function of the base ERC20 contract.
  /// @dev `_sender` cannot be the zero address.
  /// @dev `_recipient` cannot be the zero address.
  /// @dev `_sender` must have a balance of at least `_amount`.
  /// @param _sender Address of the `_sender`that will send `_amount` of tokens.
  /// @param _recipient Address of the `_recipient`that will receive `_amount` of tokens.
  /// @param _amount Amount of tokens to be transferred from `_sender` to `_recipient`.
  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal override virtual {
    require(_sender != address(0), "ERC20: transfer from the zero address");
    require(_recipient != address(0), "ERC20: transfer to the zero address");

    uint224 amount = uint224(_amount);

    _beforeTokenTransfer(_sender, _recipient, _amount);

    if (_sender != _recipient) {

      // standard balance update
      uint256 senderBalance = balances[_sender];
      require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
      unchecked {
          balances[_sender] = senderBalance - amount;
      }
      balances[_recipient] += amount;

      // history update
      address senderDelegate = delegates[_sender];
      if (senderDelegate != address(0)) {
        _decreaseUserTwab(_sender, senderDelegate, _amount);
      } else {
        _decreaseUserTwab(_sender, _sender, _amount);
      }

      // history update
      address recipientDelegate = delegates[_recipient];
      if (recipientDelegate != address(0)) {
        _increaseUserTwab(_recipient, recipientDelegate, amount);
      } else {
        _increaseUserTwab(_recipient, _recipient, amount);
      }

    }

    emit Transfer(_sender, _recipient, _amount);

    _afterTokenTransfer(_sender, _recipient, _amount);
  }

  /// @notice Overridding of the `_mint` function of the base ERC20 contract.
  /// @dev `_to` cannot be the zero address.
  /// @param _to Address that will be minted `_amount` of tokens.
  /// @param _amount Amount of tokens to be minted to `_to`.
  function _mint(address _to, uint256 _amount) internal virtual override {
    require(_to != address(0), "ERC20: mint to the zero address");

    uint224 amount = _amount.toUint224();

    _beforeTokenTransfer(address(0), _to, _amount);

    balances[_to] += amount;

    (
      TwabLib.AccountDetails memory accountDetails,
      ObservationLib.Observation memory _totalSupply,
      bool tsIsNew
    ) = TwabLib.increaseBalance(totalSupplyTwab, amount, uint32(block.timestamp));
    totalSupplyTwab.details = accountDetails;
    if (tsIsNew) {
      emit NewTotalSupplyTwab(_totalSupply);
    }

    address toDelegate = delegates[_to];
    if (toDelegate != address(0)) {
      _increaseUserTwab(_to, toDelegate, amount);
    } else {
      _increaseUserTwab(_to, _to, amount);
    }

    emit Transfer(address(0), _to, _amount);

    _afterTokenTransfer(address(0), _to, _amount);
  }

  /// @notice Overridding of the `_burn` function of the base ERC20 contract.
  /// @dev `_from` cannot be the zero address.
  /// @dev `_from` must have at least `_amount` of tokens.
  /// @param _from Address that will be burned `_amount` of tokens.
  /// @param _amount Amount of tokens to be burnt from `_from`.
  function _burn(address _from, uint256 _amount) internal virtual override {
    require(_from != address(0), "ERC20: burn from the zero address");

    uint224 amount = _amount.toUint224();

    _beforeTokenTransfer(_from, address(0), _amount);

    (
      TwabLib.AccountDetails memory accountDetails,
      ObservationLib.Observation memory tsTwab,
      bool tsIsNew
    ) = TwabLib.decreaseBalance(
      totalSupplyTwab,
      amount,
      "ERC20: burn amount exceeds balance",
      uint32(block.timestamp)
    );
    totalSupplyTwab.details = accountDetails;
    if (tsIsNew) {
      emit NewTotalSupplyTwab(tsTwab);
    }

    uint256 accountBalance = balances[_from];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        balances[_from] = accountBalance - amount;
    }

    address fromDelegate = delegates[_from];
    if (fromDelegate != address(0)) {
      _decreaseUserTwab(_from, fromDelegate, amount);
    } else {
      _decreaseUserTwab(_from, _from, amount);
    }

    emit Transfer(_from, address(0), _amount);

    _afterTokenTransfer(_from, address(0), _amount);
  }

  function _increaseUserTwab(
    address _holder,
    address _user,
    uint256 _amount
  ) internal {
    TwabLib.Account storage _account = userTwabs[_user];
    (
      TwabLib.AccountDetails memory accountDetails,
      ObservationLib.Observation memory twab,
      bool isNew
    ) = TwabLib.increaseBalance(_account, _amount, uint32(block.timestamp));
    _account.details = accountDetails;
    if (isNew) {
      emit NewUserTwab(_holder, _user, twab);
    }
  }

  function _decreaseUserTwab(
    address _holder,
    address _user,
    uint256 _amount
  ) internal {
    TwabLib.Account storage _account = userTwabs[_user];
    (
      TwabLib.AccountDetails memory accountDetails,
      ObservationLib.Observation memory twab,
      bool isNew
    ) = TwabLib.decreaseBalance(_account, _amount, "ERC20: burn amount exceeds balance", uint32(block.timestamp));
    _account.details = accountDetails;
    if (isNew) {
      emit NewUserTwab(_holder, _user, twab);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Controlled ERC20 Token
/// @notice ERC20 Tokens with a controller for minting & burning
interface IControlledToken is IERC20 {

  /// @notice Interface to the contract responsible for controlling mint/burn
  function controller() external view returns (address);

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param user Address of the receiver of the minted tokens
  /// @param amount Amount of tokens to mint
  function controllerMint(address user, uint256 amount) external;

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param user Address of the holder account to burn tokens from
  /// @param amount Amount of tokens to burn
  function controllerBurn(address user, uint256 amount) external;

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param operator Address of the operator performing the burn action via the controller contract
  /// @param user Address of the holder account to burn tokens from
  /// @param amount Amount of tokens to burn
  function controllerBurnFrom(address operator, address user, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../libraries/TwabLib.sol";
interface ITicket {

  /**  
    * @notice A struct containing details for an Account
    * @param balance The current balance for an Account
    * @param nextTwabIndex The next available index to store a new twab
    * @param cardinality The number of recorded twabs (plus one!)
  */
  struct AccountDetails {
    uint224 balance;
    uint16 nextTwabIndex;
    uint16 cardinality;
  }

  /**  
    * @notice Combines account details with their twab history
    * @param details The account details
    * @param twabs The history of twabs for this account
  */
  struct Account {
    AccountDetails details;
    ObservationLib.Observation[65535] twabs;
  }

  event Delegated(
    address indexed user,
    address indexed delegate
  );

  /** 
    * @notice Emitted when ticket is initialized.
    * @param name Ticket name (eg: PoolTogether Dai Ticket (Compound)).
    * @param symbol Ticket symbol (eg: PcDAI).
    * @param decimals Ticket decimals.
    * @param controller Token controller address.
  */
  event TicketInitialized(
    string name,
    string symbol,
    uint8 decimals,
    address controller
  );

  /** 
    * @notice Emitted when a new TWAB has been recorded.
    * @param ticketHolder The Ticket holder address.
    * @param user The recipient of the ticket power (may be the same as the ticketHolder)
    * @param newTwab Updated TWAB of a ticket holder after a successful TWAB recording.
  */
  event NewUserTwab(
    address indexed ticketHolder,
    address indexed user,
    ObservationLib.Observation newTwab
  );

  /** 
    * @notice Emitted when a new total supply TWAB has been recorded.
    * @param newTotalSupplyTwab Updated TWAB of tickets total supply after a successful total supply TWAB recording.
  */
  event NewTotalSupplyTwab(
    ObservationLib.Observation newTotalSupplyTwab
  );

   /** 
    * @notice ADD DOCS
    * @param user Address
  */
  function delegateOf(address user) external view returns (address);

  /**
    * @notice Delegate time-weighted average balances to an alternative address.
    * @dev    Transfers (including mints) trigger the storage of a TWAB in delegatee(s) account, instead of the
              targetted sender and/or recipient address(s).
    * @dev    "to" reset the delegatee use zero address (0x000.000) 
    * @param  to Receipient of delegated TWAB
   */
  function delegate(address to) external;
  
  /** 
    * @notice Gets a users twab context.  This is a struct with their balance, next twab index, and cardinality.
    * @param user The user for whom to fetch the TWAB context
    * @return The TWAB context, which includes { balance, nextTwabIndex, cardinality }
  */
  function getAccountDetails(address user) external view returns (TwabLib.AccountDetails memory);
  
  /** 
    * @notice Gets the TWAB at a specific index for a user.
    * @param user The user for whom to fetch the TWAB
    * @param index The index of the TWAB to fetch
    * @return The TWAB, which includes the twab amount and the timestamp.
  */
  function getTwab(address user, uint16 index) external view returns (ObservationLib.Observation memory);

  /** 
    * @notice Retrieves `_user` TWAB balance.
    * @param user Address of the user whose TWAB is being fetched.
    * @param timestamp Timestamp at which the reserved TWAB should be for.
  */
  function getBalanceAt(address user, uint256 timestamp) external view returns(uint256);

  /** 
    * @notice Retrieves `_user` TWAB balances.
    * @param user Address of the user whose TWABs are being fetched.
    * @param timestamps Timestamps at which the reserved TWABs should be for.
    * @return uint256[] `_user` TWAB balances.
  */
  function getBalancesAt(address user, uint32[] calldata timestamps) external view returns(uint256[] memory);

  /** 
    * @notice Calculates the average balance held by a user for a given time frame.
    * @param user The user whose balance is checked
    * @param startTime The start time of the time frame.
    * @param endTime The end time of the time frame.
    * @return The average balance that the user held during the time frame.
  */
  function getAverageBalanceBetween(address user, uint256 startTime, uint256 endTime) external view returns (uint256);

  /** 
    * @notice Calculates the average balance held by a user for a given time frame.
    * @param user The user whose balance is checked
    * @param startTimes The start time of the time frame.
    * @param endTimes The end time of the time frame.
    * @return The average balance that the user held during the time frame.
  */
  function getAverageBalancesBetween(address user, uint32[] calldata startTimes, uint32[] calldata endTimes) external view returns (uint256[] memory);

  /** 
    * @notice Calculates the average total supply balance for a set of a given time frame.
    * @param timestamp Timestamp
    * @return The
  */
  function getTotalSupplyAt(uint32 timestamp) external view returns(uint256);

   /** 
    * @notice Calculates the average total supply balance for a set of a given time frame.
    * @param timestamps Timestamp
    * @return The
  */
  function getTotalSuppliesAt(uint32[] calldata timestamps) external view returns(uint256[] memory);

  /** 
    * @notice Calculates the average total supply balance for a set of given time frames.
    * @param startTimes Array of start times
    * @param endTimes Array of end times
    * @return The average total supplies held during the time frame.
  */
  function getAverageTotalSuppliesBetween(uint32[] calldata startTimes, uint32[] calldata endTimes) external view returns(uint256[] memory);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library ExtendedSafeCast {
    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./OverflowSafeComparator.sol";
import "./RingBuffer.sol";

/// @title Observation Library
/// @notice This library allows one to store an array of timestamped values and efficiently binary search them.
/// @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
/// @author PoolTogether Inc.
library ObservationLib {
  using OverflowSafeComparator for uint32;
  using SafeCast for uint256;

  /// @notice The maximum number of observations
  uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

  /// @notice Observation, which includes an amount and timestamp
  /// @param amount `amount` at `timestamp`.
  /// @param timestamp Recorded `timestamp`.
  struct Observation {
    uint224 amount;
    uint32 timestamp;
  }

  /// @notice Fetches Observations `beforeOrAt` and `atOrAfter` a `_target`, eg: where [`beforeOrAt`, `atOrAfter`] is satisfied.
  /// The result may be the same Observation, or adjacent Observations.
  /// @dev The answer must be contained in the array, used when the target is located within the stored Observation.
  /// boundaries: older than the most recent Observation and younger, or the same age as, the oldest Observation.
  /// @param _observations List of Observations to search through.
  /// @param _observationIndex Index of the Observation to start searching from.
  /// @param _target Timestamp at which the reserved Observation should be for.
  /// @return beforeOrAt Observation recorded before, or at, the target.
  /// @return atOrAfter Observation recorded at, or after, the target.
  function binarySearch(
    Observation[MAX_CARDINALITY] storage _observations,
    uint24 _observationIndex,
    uint24 _oldestObservationIndex,
    uint32 _target,
    uint24 _cardinality,
    uint32 _time
  ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
    uint256 leftSide = _oldestObservationIndex; // Oldest Observation
    uint256 rightSide = _observationIndex < leftSide ? leftSide + _cardinality - 1 : _observationIndex;
    uint256 currentIndex;

    while (true) {
      currentIndex = (leftSide + rightSide) / 2;
      beforeOrAt = _observations[uint24(RingBuffer.wrap(currentIndex, _cardinality))];
      uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

      // We've landed on an uninitialized timestamp, keep searching higher (more recently)
      if (beforeOrAtTimestamp == 0) {
        leftSide = currentIndex + 1;
        continue;
      }

      atOrAfter = _observations[uint24(RingBuffer.nextIndex(currentIndex, _cardinality))];

      bool targetAtOrAfter = beforeOrAtTimestamp.lte(_target, _time);

      // Check if we've found the corresponding Observation
      if (targetAtOrAfter && _target.lte(atOrAfter.timestamp, _time)) {
        break;
      }

      // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower
      if (!targetAtOrAfter) rightSide = currentIndex - 1;

      // Otherwise, we keep searching higher
      else leftSide = currentIndex + 1;
    }
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/// @title OverflowSafeComparator library to share comparator functions between contracts
/// @dev Code taken from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/3e88af408132fc957e3e406f65a0ce2b1ca06c3d/contracts/libraries/Oracle.sol
/// @author PoolTogether Inc.
library OverflowSafeComparator {
    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically < `_b`.
    function lt(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a < _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted < bAdjusted;
    }

    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically <= `_b`.
    function lte(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a <= _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice 32-bit timestamp subtractor
    /// @dev safe for 0 or 1 overflows, where `_a` and `_b` must be chronologically before or equal to time
    /// @param _a The subtraction left operand
    /// @param _b The subtraction right operand
    /// @param _timestamp The current time.  Expected to be chronologically after both.
    /// @return The difference between a and b, adjusted for overflow
    function checkedSub(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (uint32) {
        // No need to adjust if there hasn't been an overflow

        if (_a <= _timestamp && _b <= _timestamp) return _a - _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return uint32(aAdjusted - bAdjusted);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

library RingBuffer {

  /// @notice Returns TWAB index.
  /// @dev `twabs` is a circular buffer of `MAX_CARDINALITY` size equal to 32. So the array goes from 0 to 31.
  /// @dev In order to navigate the circular buffer, we need to use the modulo operator.
  /// @dev For example, if `_index` is equal to 32, `_index % MAX_CARDINALITY` will return 0 and will point to the first element of the array.
  /// @param _index Index used to navigate through `twabs` circular buffer.
  function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
    return _index % _cardinality;
  }

  function offset(uint256 _index, uint256 _amount, uint256 _cardinality) internal pure returns (uint256) {
    return (_index + _cardinality - _amount) % _cardinality;
  }

  /// @notice Returns the index of the last recorded TWAB
  /// @param _nextAvailableIndex The next available twab index.  This will be recorded to next.
  /// @param _cardinality The cardinality of the TWAB history.
  /// @return The index of the last recorded TWAB
  function mostRecentIndex(uint256 _nextAvailableIndex, uint256 _cardinality) internal pure returns (uint256) {
    if (_cardinality == 0) {
      return 0;
    }
    return (_nextAvailableIndex + uint256(_cardinality) - 1) % _cardinality;
  }

  function nextIndex(uint256 _currentIndex, uint256 _cardinality) internal pure returns (uint256) {
    return (_currentIndex + 1) % _cardinality;
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./ExtendedSafeCast.sol";
import "./OverflowSafeComparator.sol";
import "./RingBuffer.sol";
import "./ObservationLib.sol";

/// @title Time-Weighted Average Balance Library
/// @notice This library allows you to efficiently track a user's historic balance.  You can get a
/// @author PoolTogether Inc.
library TwabLib {
  using OverflowSafeComparator for uint32;
  using ExtendedSafeCast for uint256;

  /// @notice The maximum number of twab entries
  uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

  /// @notice A struct containing details for an Account
  /// @param balance The current balance for an Account
  /// @param nextTwabIndex The next available index to store a new twab
  /// @param cardinality The upper limit on the number of twabs.
  struct AccountDetails {
    uint208 balance;
    uint24 nextTwabIndex;
    uint24 cardinality;
  }

  /// @notice Combines account details with their twab history
  /// @param details The account details
  /// @param twabs The history of twabs for this account
  struct Account {
    AccountDetails details;
    ObservationLib.Observation[MAX_CARDINALITY] twabs;
  }

  /// @notice Increases an account's balance and records a new twab.
  /// @param _account The account whose balance will be increased
  /// @param _amount The amount to increase the balance by
  /// @param _currentTime The current time
  /// @return accountDetails The new AccountDetails
  /// @return twab The user's latest TWAB
  /// @return isNew Whether the TWAB is new
  function increaseBalance(
    Account storage _account,
    uint256 _amount,
    uint32 _currentTime
  ) internal returns (AccountDetails memory accountDetails, ObservationLib.Observation memory twab, bool isNew) {
    AccountDetails memory _accountDetails = _account.details;
    (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
    accountDetails.balance = (_accountDetails.balance + _amount).toUint208();
  }

  /// @notice Decreases an account's balance and records a new twab.
  /// @param _account The account whose balance will be decreased
  /// @param _amount The amount to decrease the balance by
  /// @param _revertMessage The revert message in the event of insufficient balance
  /// @return accountDetails The new AccountDetails
  /// @return twab The user's latest TWAB
  /// @return isNew Whether the TWAB is new
  function decreaseBalance(
    Account storage _account,
    uint256 _amount,
    string memory _revertMessage,
    uint32 _currentTime
  ) internal returns (AccountDetails memory accountDetails, ObservationLib.Observation memory twab, bool isNew) {
    AccountDetails memory _accountDetails = _account.details;
    require(_accountDetails.balance >= _amount, _revertMessage);
    (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
    accountDetails.balance = (_accountDetails.balance - _amount).toUint208();
  }

  /// @notice Calculates the average balance held by a user for a given time frame.
  /// @param _startTime The start time of the time frame.
  /// @param _endTime The end time of the time frame.
  /// @return The average balance that the user held during the time frame.
  function getAverageBalanceBetween(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _startTime,
    uint32 _endTime,
    uint32 _currentTime
  ) internal view returns (uint256) {
    uint32 endTime = _endTime > _currentTime ? _currentTime : _endTime;
    return _getAverageBalanceBetween(_twabs, _accountDetails, _startTime, endTime, _currentTime);
  }

  /// @notice Retrieves the oldest TWAB
  /// @param _twabs The storage array of twabs
  /// @param _accountDetails The TWAB account details
  /// @return index The index of the oldest TWAB in the twabs array
  /// @return twab The oldest TWAB
  function oldestTwab(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails
  ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
    index = _accountDetails.nextTwabIndex;
    twab = _twabs[_accountDetails.nextTwabIndex];
    // If the TWAB is not initialized we go to the beginning of the TWAB circular buffer at index 0
    if (twab.timestamp == 0) {
      index = 0;
      twab = _twabs[0];
    }
  }

  /// @notice Retrieves the newest TWAB
  /// @param _twabs The storage array of twabs
  /// @param _accountDetails The TWAB account details
  /// @return index The index of the newest TWAB in the twabs array
  /// @return twab The newest TWAB
  function newestTwab(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails
  ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
    index = uint24(RingBuffer.mostRecentIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY));
    twab = _twabs[index];
  }

  /// @notice Retrieves amount at `_target` timestamp
  /// @param _twabs List of TWABs to search through.
  /// @param _accountDetails Accounts details
  /// @param _target Timestamp at which the reserved TWAB should be for.
  /// @return uint256 TWAB amount at `_target`.
  function getBalanceAt(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _target,
    uint32 _currentTime
  ) internal view returns (uint256) {
    uint32 target = _target > _currentTime ? _currentTime : _target;
    return _getBalanceAt(_twabs, _accountDetails, target, _currentTime);
  }

  /// @notice Calculates the average balance held by a user for a given time frame.
  /// @param _startTime The start time of the time frame.
  /// @param _endTime The end time of the time frame.
  /// @return The average balance that the user held during the time frame.
  function _getAverageBalanceBetween(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _startTime,
    uint32 _endTime,
    uint32 _currentTime
  ) private view returns (uint256) {
    (uint24 oldestTwabIndex, ObservationLib.Observation memory oldTwab) = oldestTwab(_twabs, _accountDetails);
    (uint24 newestTwabIndex, ObservationLib.Observation memory newTwab) = newestTwab(_twabs, _accountDetails);

    ObservationLib.Observation memory startTwab = _calculateTwab(
      _twabs, _accountDetails, newTwab, oldTwab, newestTwabIndex, oldestTwabIndex, _startTime, _currentTime
    );

    ObservationLib.Observation memory endTwab = _calculateTwab(
      _twabs, _accountDetails, newTwab, oldTwab, newestTwabIndex, oldestTwabIndex, _endTime, _currentTime
    );

    // Difference in amount / time
    return (endTwab.amount - startTwab.amount) / (endTwab.timestamp - startTwab.timestamp);
  }

  /// @notice Retrieves amount at `_target` timestamp
  /// @param _twabs List of TWABs to search through.
  /// @param _accountDetails Accounts details
  /// @param _target Timestamp at which the reserved TWAB should be for.
  /// @return uint256 TWAB amount at `_target`.
  function _getBalanceAt(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _target,
    uint32 _currentTime
  ) private view returns (uint256) {
    uint24 newestTwabIndex;
    ObservationLib.Observation memory afterOrAt;
    ObservationLib.Observation memory beforeOrAt;
    (newestTwabIndex, beforeOrAt) = newestTwab(_twabs, _accountDetails);

    // If `_target` is chronologically after the newest TWAB, we can simply return the current balance
    if (beforeOrAt.timestamp.lte(_target, _currentTime)) {
      return _accountDetails.balance;
    }

    uint24 oldestTwabIndex;
    // Now, set before to the oldest TWAB
    (oldestTwabIndex, beforeOrAt) = oldestTwab(_twabs, _accountDetails);

    // If `_target` is chronologically before the oldest TWAB, we can early return
    if (_target.lt(beforeOrAt.timestamp, _currentTime)) {
      return 0;
    }

    // Otherwise, we perform the `binarySearch`
    (beforeOrAt, afterOrAt) = ObservationLib.binarySearch(
      _twabs,
      newestTwabIndex,
      oldestTwabIndex,
      _target,
      _accountDetails.cardinality,
      _currentTime
    );

    // Difference in amount / time
    uint224 differenceInAmount = afterOrAt.amount - beforeOrAt.amount;
    uint32 differenceInTime = afterOrAt.timestamp - beforeOrAt.timestamp;

    return differenceInAmount / differenceInTime;
  }

  /// @notice Calculates the TWAB for a given timestamp.  It interpolates as necessary.
  /// @param _twabs The TWAB history
  function _calculateTwab(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    ObservationLib.Observation memory _newestTwab,
    ObservationLib.Observation memory _oldestTwab,
    uint24 _newestTwabIndex,
    uint24 _oldestTwabIndex,
    uint32 targetTimestamp,
    uint32 _time
  ) private view returns (ObservationLib.Observation memory) {
    // If `targetTimestamp` is chronologically after the newest TWAB, we extrapolate a new one
    if (_newestTwab.timestamp.lt(targetTimestamp, _time)) {
      return ObservationLib.Observation({
        amount: _newestTwab.amount + _accountDetails.balance*(targetTimestamp - _newestTwab.timestamp),
        timestamp: targetTimestamp
      });
    }

    if (_newestTwab.timestamp == targetTimestamp) {
      return _newestTwab;
    }

    if (_oldestTwab.timestamp == targetTimestamp) {
      return _oldestTwab;
    }

    // If `targetTimestamp` is chronologically before the oldest TWAB, we create a zero twab
    if (targetTimestamp.lt(_oldestTwab.timestamp, _time)) {
      return ObservationLib.Observation({
        amount: 0,
        timestamp: targetTimestamp
      });
    }

    // Otherwise, both timestamps must be surrounded by twabs.
    (
      ObservationLib.Observation memory beforeOrAtStart,
      ObservationLib.Observation memory afterOrAtStart
    ) = ObservationLib.binarySearch(_twabs, _newestTwabIndex, _oldestTwabIndex, targetTimestamp, _accountDetails.cardinality, _time);

    uint224 heldBalance = (afterOrAtStart.amount - beforeOrAtStart.amount) / (afterOrAtStart.timestamp - beforeOrAtStart.timestamp);
    uint224 amount = beforeOrAtStart.amount + heldBalance * (targetTimestamp - beforeOrAtStart.timestamp);

    return ObservationLib.Observation({
      amount: amount,
      timestamp: targetTimestamp
    });
  }

  /// @notice Records a new TWAB.
  /// @param _currentBalance Current `amount`.
  /// @return New TWAB that was recorded.
  function _computeNextTwab(
    ObservationLib.Observation memory _currentTwab,
    uint256 _currentBalance,
    uint32 _time
  ) private pure returns (ObservationLib.Observation memory) {
    // New twab amount = last twab amount (or zero) + (current amount * elapsed seconds)
    return ObservationLib.Observation({
      amount: (uint256(_currentTwab.amount) + (_currentBalance * (_time.checkedSub(_currentTwab.timestamp, _time)))).toUint208(),
      timestamp: _time
    });
  }

  /// @notice Sets a new TWAB Observation at the next available index and returns the new account details.
  /// @param _twabs The twabs array to insert into
  /// @param _accountDetails The current account details
  /// @param _time The current time
  /// @return accountDetails The new account details
  /// @return twab The newest twab (may or may not be brand-new)
  /// @return isNew Whether the newest twab was created by this call
  function _nextTwab(
    ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
    AccountDetails memory _accountDetails,
    uint32 _time
  ) private returns (AccountDetails memory accountDetails, ObservationLib.Observation memory twab, bool isNew) {
    (, ObservationLib.Observation memory _newestTwab) = newestTwab(_twabs, _accountDetails);
    require(_time >= _newestTwab.timestamp, "TwabLib/twab-time-monotonic");

    // if we're in the same block, return
    if (_newestTwab.timestamp == _time) {
      return (_accountDetails, _newestTwab, false);
    }

    ObservationLib.Observation memory newTwab = _computeNextTwab(
      _newestTwab,
      _accountDetails.balance,
      _time
    );

    _twabs[_accountDetails.nextTwabIndex] = newTwab;

    _accountDetails.nextTwabIndex = uint24(RingBuffer.nextIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY));
    _accountDetails.cardinality += 1;

    return (_accountDetails, newTwab, true);
  }
}

