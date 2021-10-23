// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        return msg.data;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Pool.sol";

/**
 * @title DefiMToken
 * @dev DefiMToken ERC20 Token, where all tokens are pre-assigned to the owner.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract ADefiMToken is ERC20("ADefiM Token", "DEFIM"), Pool, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20; 


    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 toClaim;
    }

    // Dev address.
    address payable public devaddr;    
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;


    uint256 totalClaimedAmount = 0;

    event Stake(address indexed user, uint256 indexed pid, uint256 amount);
    event UnStake(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

 

    function initialize(address _WETH, address _USD_token, address factory, address payable _devaddr) public initializer{
        
        initialize();

        UNISWAP_FACTORY = factory;
        devaddr =  _devaddr;
        addPool(100000 * 10**6, 0x0000000000000000000000000000000000000000, false);

        WETH = _WETH;
        USD_token = _USD_token;
        USD_decimals = IERC20Extented(USD_token).decimals();
        

        //Aded pool USD money
        moneyInfo.push(MoneyInfo({
            name : "USDT",
            moneyAdress: _USD_token,
            isActiv: true
        }));

        
    }


    function StopPool(uint256 _pid) external onlyOwner() {
        update(_pid);
        _stopPool(_pid);
    }

    function stake_eth(uint256 _pid) allowStake(_pid) external payable {
        require(_pid == 0, "Can only eth");
        require(msg.value > 0, "Cannot stake 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        update(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.rewardPerTokenStored).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                 user.toClaim += pending;
            }
        }

        user.amount = user.amount.add(msg.value);
        user.rewardDebt = user.amount.mul(pool.rewardPerTokenStored).div(1e12);
        emit Stake(msg.sender, _pid, msg.value);


    }


    function unstake_eth(uint256 _pid, uint256 _amount, uint256 _tipsPerc) public {
        require(_amount > 0, "Cannot unstake 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        update(_pid);

        uint256 pending = user.toClaim.add(user.amount.mul(pool.rewardPerTokenStored).div(1e12).add(user.rewardDebt));

        if(pending > 0) {
                user.toClaim = 0;
                _mint(msg.sender, pending);
                _mint(devaddr, pending / 20);
                pool.claimedAmount = pool.claimedAmount.add(pending);
        }   
  
        user.amount = user.amount.sub(_amount);

        if (_tipsPerc > 0) {
            uint256 tips = _amount.mul(_tipsPerc).div(10000);
            payable(msg.sender).transfer(_amount.sub(tips));
            devaddr.transfer(tips);
        } else {
            payable(msg.sender).transfer(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.rewardPerTokenStored).div(1e12);

        emit UnStake(msg.sender, _pid, _amount);

    }

    // View function to see pending DEFIMs on frontend.
    function pending(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        
        if (pool.lastRewardDay < block.timestamp){
           return 0;
        }

        uint256 totalSupply =  (_pid == 0) ?  address(this).balance : pool.token.balanceOf(address(this));

        uint256 multiplier = getMultiplier(pool.startDay, pool.lastRewardDay, block.timestamp);
        uint256 defimReward = multiplier.mul(pool.solosmPerDay);    
        uint256 rewardPerTokenStored = pool.rewardPerTokenStored.add(defimReward.mul(1e12).div(totalSupply));

        return user.toClaim.add(user.amount.mul(rewardPerTokenStored).div(1e12).sub(user.rewardDebt));
            
        

    }
 

    function stake(uint256 _pid, uint256 _amount) allowStake(_pid) external {

        require(_amount > 0, "Cannot stake 0");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        update(_pid);

       
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.rewardPerTokenStored).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                user.toClaim += pending;
            }
        }
        user.amount = user.amount.add(_amount);
        pool.token.safeTransferFrom(msg.sender, address(this), _amount);
        user.rewardDebt = user.amount.mul(pool.rewardPerTokenStored).div(1e12);
    }


    function unstake(uint256 _pid, uint256 _amount, uint256 _tipsPerc) public {

        require(_amount > 0, "Cannot unstake 0");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        update(_pid);
        uint256 pending = user.toClaim.add(user.amount.mul(pool.rewardPerTokenStored).div(1e12).sub(user.rewardDebt));

        if(pending > 0) {
                user.toClaim = 0;
                _mint(msg.sender, pending);
                _mint(devaddr, pending / 20);
                pool.claimedAmount = pool.claimedAmount.add(pending);
        }    

        user.amount = user.amount.sub(_amount);

        if (_tipsPerc > 0) {
            uint256 tips = _amount.mul(_tipsPerc).div(10000);
            pool.token.safeTransfer(address(msg.sender), _amount.sub(tips));
            pool.token.safeTransfer(devaddr, tips);
        } else {
            pool.token.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.rewardPerTokenStored).div(1e12);
        emit Claim(msg.sender, _pid, pending);
        emit UnStake(msg.sender, _pid, _amount);
    }


    function claim(uint256 _pid) public {
        update(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pending = user.toClaim.add(user.amount.mul(pool.rewardPerTokenStored).div(1e12).sub(user.rewardDebt));
        if (pending > 0) {
            user.toClaim = 0;
               _mint(msg.sender, pending);
               _mint(devaddr, pending / 20);
            pool.claimedAmount = pool.claimedAmount.add(pending);
        }

        user.rewardDebt = user.amount.mul(pool.rewardPerTokenStored).div(1e12);
        emit Claim(msg.sender, _pid, pending);
    } 


    // Update reward variables of the given pool to be up-to-date.
    function update(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 totalSupply =  (_pid == 0) ?  address(this).balance : pool.token.balanceOf(address(this));

        if (totalSupply == 0 || pool.stopped) {
           pool.lastRewardDay = block.timestamp;
           return;
        } 
        
        if (pool.lastRewardDay < block.timestamp){ 

            uint256 multiplier = getMultiplier(pool.startDay, pool.lastRewardDay, block.timestamp);
            uint256 defimReward = multiplier.mul(pool.solosmPerDay);    
            pool.rewardPerTokenStored = pool.rewardPerTokenStored.add(defimReward.mul(1e12).div(totalSupply));
            pool.lastRewardDay = block.timestamp;
        }

    }



    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _startDay, uint256 _from, uint256 _to) public pure override returns (uint256){
        return  getMultiplierSum(_to.sub(_startDay)).sub(getMultiplierSum(_from.sub(_startDay))).div(60 * 5); //div(60 * 60 * 24);
    }


    function getMultiplierSum(uint256 _day) public pure returns (uint256) {
        uint256 mult = 0;
        uint256 day = _day;
        if (day > 798 minutes) {
            day = 798 minutes;
        }
        if (day > 398 minutes) {
            mult += (day - 398 minutes);
            day = 398 minutes;
        }
        if (day > 198 minutes) {
            mult += (day - 198 minutes) * 2;
            day = 198 minutes;
        }
        if (day > 98 minutes) {
            mult += (day - 98 minutes) * 4;
            day = 98 minutes;
        }
        if (day > 42 minutes) {
            mult += (day - 42 minutes) * 10;
            day = 42 minutes;
        }
        if (day > 14 minutes) {
            mult += (day - 14 minutes) * 40;
            day = 14 minutes;
        }
        mult += day * 80;
        return mult;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/proxy/InitializeOwnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/interfaces/IERC20Extented.sol";


abstract contract MoneyPool is InitializeOwnable {

    struct MoneyInfo {
        string name;
        address moneyAdress;
        bool isActiv;
    }



    MoneyInfo[] public moneyInfo;
    address WETH;

    address public USD_token;
    uint256 public USD_decimals;



    function setUSDT(address _USD_token) public onlyOwner {
        USD_token = _USD_token;
        USD_decimals = IERC20Extented(USD_token).decimals();
    }


    function addMoney(string memory name, address moneyAdress, bool isActiv) public onlyOwner{
           moneyInfo.push(MoneyInfo({
                name : name,
                moneyAdress: moneyAdress,
                isActiv: isActiv
           }));
    }


    function isMoney(address _address) public view returns (bool){
          for (uint256 index = 0; index < moneyInfo.length; index++) {
              if (_address == moneyInfo[index].moneyAdress && moneyInfo[index].isActiv){
                  return true;
              }  
          }
          return false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/proxy/InitializeOwnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../libs/interfaces/IDefiStake.sol";
import "../libs/interfaces/IUniswapV2Pair.sol";
import "../libs/interfaces/IERC20Extented.sol";
import "./UniswapOracle.sol";
import "./MoneyPool.sol";



/**
 * @title DefiMToken
 * @dev DefiMToken ERC20 Token, where all tokens are pre-assigned to the owner.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
abstract contract Pool is  InitializeOwnable, UniswapOracle, MoneyPool { 
    using SafeMath for uint;

 
    struct PoolInfo {
        address tokenAddress;           // Address of LP token contract.
        IERC20 token;           // Address of LP token contract.
        uint256 totalSupply;       // How many allocation points assigned to this pool. DefiM to distribute per day.
        uint256 allocAmount;       // How many allocation points assigned to this pool. DefiM to distribute per day.
        uint256 claimedAmount;
        uint256 lastRewardDay;  // Last block number that DefiM distribution occurs.
        uint256 rewardPerTokenStored;
        uint256 solosmPerDay; //

        uint256 startDay; //
        uint256 stopDay; //
        bool isLP; //
        bool started; //
        bool stopped; //
    }

    PoolInfo[] public poolInfo;    

    // constructor (address _WETH, address _USD_token, address factory) UniswapOracle(factory) {
    //     WETH = _WETH;
    //     USD_token = _USD_token;
    //     USD_decimals = IERC20Extented(USD_token).decimals();
        
    //     moneyInfo.push(MoneyInfo({
    //         name : "USDT",
    //         moneyAdress: _USD_token,
    //         isActiv: true
    //     }));
    // }

    // function initialize (address _WETH, address _USD_token, address factory) initializer public{

    // }


    modifier allowStake(uint256 _pid){
        PoolInfo storage pool = poolInfo[_pid];
        require(!pool.stopped && (block.timestamp >= pool.startDay), "Cannot stake pooll is stopped"); 
        _;
        }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(uint256 _allocAmount, address _address, bool _isLP) public onlyOwner {

        require(_allocAmount <= 100000 * 10**6, "Cannot allocate more 1000000 tokens");
        uint256 startPoolTime = block.timestamp; 
       
        uint256 solosmPerDay = _allocAmount.div(4000);
        poolInfo.push(PoolInfo({
        tokenAddress : _address,
        token : IERC20(_address),
        allocAmount : _allocAmount,
        totalSupply: 0,
        claimedAmount: 0,
        lastRewardDay : startPoolTime,
        rewardPerTokenStored: 0,
        solosmPerDay : solosmPerDay,
        startDay: startPoolTime,
        stopDay: 0,
        isLP: _isLP,
        started: false,
        stopped: false
        }));
    }


    function _stopPool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.stopped = true;
    }


    function getPoolValueUSD(uint256 _pid) public view returns (uint256) {
        return convert(getPoolValueETH(_pid), WETH, USD_token).mul(10**6).div(10**USD_decimals);
    }

    function getTreasuryValueUSD() public view returns (uint256) {
        return convert(getTreasuryValueETH(), WETH, USD_token).mul(10**6).div(10**USD_decimals);
    }




    function getTreasuryValueETH() public view returns (uint256) {
        uint256 treasuryValue;
        for (uint i = 0; i < poolInfo.length; i++) {
            treasuryValue = treasuryValue.add(getPoolValueETH(i));
        }
        return treasuryValue;
    }


    function getPoolValueETH(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 totalSupply;
       
        if (_pid == 0){
            return address(this).balance;
        }

        totalSupply = IERC20(pool.tokenAddress).balanceOf(address(this)); 

        if (totalSupply == 0) {
            return 0;
        }


        if (pool.isLP == true) {
            IUniswapV2Pair pair = IUniswapV2Pair(pool.tokenAddress);
            if (pair.totalSupply() == 0) {
                return 0;
            }

            (uint reserve0, uint reserve1,) = pair.getReserves();
            uint256 value;

             
            if (pair.token0() == WETH) {
                value = totalSupply.mul(reserve0);
            } else if (pair.token1() == WETH) {
                value = totalSupply.mul(reserve1);
            } else if (isMoney(pair.token0())){
                value = convert(totalSupply.mul(reserve0), pair.token0(), WETH);
            } else if (isMoney(pair.token1())){
                value = convert(totalSupply.mul(reserve1), pair.token1(), WETH);
            }
            return value.mul(2).div(pair.totalSupply());

        } 

        else {
            return convert(totalSupply, pool.tokenAddress, WETH);
            }

        

    }


    function getPoolInfo(uint256 _pid) public view returns (
        uint256 allocAmount,
        uint256 todayAmount,
        uint256 alreadyAmount,
        uint256 claimedAmount,
        uint256 treasuryAmount,
        uint256 treasuryAmountETH,
        uint256 treasuryAmountUSD,
        uint256 startDay,
        uint256 stopDay,
        uint256 currentDay) {

        PoolInfo storage pool = poolInfo[_pid];

        currentDay = block.timestamp;
        allocAmount = pool.allocAmount;
        if (pool.started) {
            if (pool.stopped) {
                todayAmount = 0;
            } else {
                todayAmount = pool.solosmPerDay.mul(getMultiplier(pool.startDay, currentDay, currentDay.add(1)));
            }
            alreadyAmount = pool.solosmPerDay.mul(getMultiplier(pool.startDay, pool.startDay, currentDay));
            startDay = pool.startDay;
        } else {
            todayAmount = pool.solosmPerDay.mul(getMultiplier(currentDay, currentDay, currentDay.add(1)));
            alreadyAmount = 0;
            startDay = currentDay;
        }
        stopDay = pool.stopDay;
        claimedAmount = pool.claimedAmount;
        treasuryAmount = (_pid == 0) ?  address(this).balance : pool.token.balanceOf(address(this));
        treasuryAmountETH = getPoolValueETH(_pid);
        treasuryAmountUSD = getPoolValueUSD(_pid);

    }

    function getMultiplier(uint256 _startDay, uint256 _from, uint256 _to) public view virtual returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/interfaces/IUniswapV2Pair.sol";
import "../libs/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract UniswapOracle {

    using SafeMath for uint;

    address UNISWAP_FACTORY;

    // constructor (address factory){
    //     UNISWAP_FACTORY = factory;
    // }

// returns sorted token addresses, used to handle return values from pairs sorted in this order
    // function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    //     require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    //     (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    //     require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    // }

    // calculates the CREATE2 address for a pair without making any external calls
    // function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    //     (address token0, address token1) = sortTokens(tokenA, tokenB);
    //     pair = address(uint160(uint(keccak256(abi.encodePacked(
    //             hex'ff',
    //             factory,
    //             keccak256(abi.encodePacked(token0, token1)),
    //             //hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
    //             hex'2c66bf46213adfc84b60870356e121aee2b9877a75a365fbe9ff22d3486160a4'
    //         )))));
    // }



    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        address pairAddress = IUniswapV2Factory(factory).getPair(token0,token1);
 
        if (pairAddress == address(0)){
            reserveA = 0;
            reserveB = 0;
        } else {
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
            (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        }
        

    }


    function convert(uint256 _amount, address _token0, address _token1) public view returns (uint256) {
        (uint reserve0, uint reserve1) = getReserves(UNISWAP_FACTORY, _token0, _token1);
        if (reserve0 > 0) {
            return _amount.mul(reserve1).div(reserve0);
        } else {
            return 0;
        }
    }


}

pragma solidity ^0.8.0;

interface IDefiStake {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function stake(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function getPair(address a,address b) external view returns (address pair);
}

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";


abstract contract InitializeOwnable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize( ) internal {
        _owner = _msgSender();
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