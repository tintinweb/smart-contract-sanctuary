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
pragma solidity 0.8.7;

address constant LENDINGPOOL = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
address constant LENDINGPOOL_ADDRESSES_PROVIDER = 0xd05e3E715d945B59290df0ae8eF85c1BdB684744;
address constant PROTOCOL_DATA_PROVIDER = 0x7551b5D2763519d4e37e8B81929D336De671d46d;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

address constant GELATO = 0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA;
string constant OK = "OK";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

uint256 constant PROTECTION_FEE_BPS_CAP = 10; // 0.1%
uint256 constant DISCREPANCY_BPS_CAP = 500; // 5%
uint256 constant SLIPPAGE_BPS_CAP = 500; // 5%
uint256 constant TEN_THOUSAND_BPS = 1e4; // 100%

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

address constant MATIC = 0x0000000000000000000000000000000000001010;
address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ILendingPool} from "../interfaces/aave/ILendingPool.sol";
import {
    ILendingPoolAddressesProvider
} from "../interfaces/aave/ILendingPoolAddressesProvider.sol";
import {
    IProtocolDataProvider
} from "../interfaces/aave/IProtocolDataProvider.sol";
import {IPriceOracle} from "../interfaces/aave/IPriceOracle.sol";
import {
    IProtectionAction
} from "../interfaces/services/actions/IProtectionAction.sol";
import {PROTOCOL_DATA_PROVIDER} from "../constants/CAave.sol";
import {TEN_THOUSAND_BPS} from "../constants/CProtectionAction.sol";
import {
    ProtectionDataCompute,
    RepayAndFlashBorrowData,
    RepayAndFlashBorrowResult
} from "../structs/SProtection.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {_qmul, _wdiv, _wmul} from "../vendor/DSMath.sol";

function _getRepayAndFlashBorrowAmt(
    RepayAndFlashBorrowData memory _rAndWAmtData,
    ILendingPool _lendingPool,
    ILendingPoolAddressesProvider _lendingPoolAddressesProvider,
    IProtectionAction _protectionAction
) view returns (RepayAndFlashBorrowResult memory) {
    ProtectionDataCompute memory protectionDataCompute;

    protectionDataCompute.onBehalfOf = _rAndWAmtData.user;
    protectionDataCompute.colToken = _rAndWAmtData.colToken;
    protectionDataCompute.debtToken = _rAndWAmtData.debtToken;
    protectionDataCompute.wantedHealthFactor = _rAndWAmtData.wantedHealthFactor;

    (
        protectionDataCompute.totalCollateralETH,
        protectionDataCompute.totalBorrowsETH,
        ,
        protectionDataCompute.currentLiquidationThreshold,
        ,

    ) = _lendingPool.getUserAccountData(_rAndWAmtData.user);

    uint256[] memory pricesInETH;
    {
        address[] memory assets = new address[](2);
        assets[0] = _rAndWAmtData.colToken;
        assets[1] = _rAndWAmtData.debtToken;
        // index 0 is colToken to Eth price, and index 1 is debtToken to Eth price
        pricesInETH = IPriceOracle(
            _lendingPoolAddressesProvider.getPriceOracle()
        ).getAssetsPrices(assets);

        protectionDataCompute.colPrice = pricesInETH[0];
        protectionDataCompute.debtPrice = pricesInETH[1];
    }

    (
        ,
        ,
        protectionDataCompute.colLiquidationThreshold,
        ,
        ,
        ,
        ,
        ,
        ,

    ) = IProtocolDataProvider(PROTOCOL_DATA_PROVIDER)
        .getReserveConfigurationData(_rAndWAmtData.colToken);

    protectionDataCompute.protectionActionFeeBps = _protectionAction
        .protectionFeeBps();
    protectionDataCompute.flashloanPremiumBps = _lendingPool
        .FLASHLOAN_PREMIUM_TOTAL();

    return
        _amountToPaybackAndFlashBorrow(_rAndWAmtData.id, protectionDataCompute);
}

function _amountToPaybackAndFlashBorrow(
    bytes32 _id,
    ProtectionDataCompute memory _protectionDataCompute
) view returns (RepayAndFlashBorrowResult memory) {
    uint256 intermediateValue = _wdiv(
        (
            (
                (_wmul(
                    _protectionDataCompute.wantedHealthFactor,
                    _protectionDataCompute.totalBorrowsETH
                ) -
                    (
                        _qmul(
                            _protectionDataCompute.totalCollateralETH,
                            _protectionDataCompute.currentLiquidationThreshold
                        )
                    ))
            )
        ),
        _protectionDataCompute.wantedHealthFactor -
            _qmul(
                _protectionDataCompute.colLiquidationThreshold,
                (TEN_THOUSAND_BPS +
                    _protectionDataCompute.protectionActionFeeBps +
                    _protectionDataCompute.flashloanPremiumBps)
            ) *
            1e14
    );

    uint256 colTokenDecimals = ERC20(_protectionDataCompute.colToken)
        .decimals();
    uint256 debtTokenDecimals = ERC20(_protectionDataCompute.debtToken)
        .decimals();

    return
        RepayAndFlashBorrowResult(
            _id,
            _tokenToTokenPrecision(
                _wdiv(intermediateValue, _protectionDataCompute.colPrice),
                18,
                colTokenDecimals
            ),
            _tokenToTokenPrecision(
                _wdiv(intermediateValue, _protectionDataCompute.debtPrice),
                18,
                debtTokenDecimals
            ),
            "OK"
        );
}

function _tokenToTokenPrecision(
    uint256 _amount,
    uint256 _oldPrecision,
    uint256 _newPrecision
) pure returns (uint256) {
    return
        _oldPrecision > _newPrecision
            ? _amount / (10**(_oldPrecision - _newPrecision))
            : _amount * (10**(_newPrecision - _oldPrecision));
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ILendingPool} from "../interfaces/aave/ILendingPool.sol";
import {
    ILendingPoolAddressesProvider
} from "../interfaces/aave/ILendingPoolAddressesProvider.sol";
import {
    IProtectionAction
} from "../interfaces/services/actions/IProtectionAction.sol";
import {ISwapModule} from "../interfaces/services/module/ISwapModule.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../structs/SAave.sol";
import {GELATO} from "../constants/CAaveServices.sol";
import {TEN_THOUSAND_BPS} from "../constants/CProtectionAction.sol";
import {
    RepayAndFlashBorrowResult,
    RepayAndFlashBorrowData,
    ProtectionPayload,
    FlashLoanParamsData
} from "../structs/SProtection.sol";
import {_getRepayAndFlashBorrowAmt} from "./FProtection.sol";

function _checkRepayAndFlashBorrowAmt(
    ProtectionPayload memory _protectionPayload,
    ILendingPool _lendingPool,
    ILendingPoolAddressesProvider _lendingPoolAddressesProvider,
    IProtectionAction _protectionAction
) view {
    RepayAndFlashBorrowData memory rAndFAmtData;

    rAndFAmtData.user = _protectionPayload.onBehalfOf;
    rAndFAmtData.colToken = _protectionPayload.colToken;
    rAndFAmtData.debtToken = _protectionPayload.debtToken;
    rAndFAmtData.wantedHealthFactor = _protectionPayload.wantedHealthFactor;

    RepayAndFlashBorrowResult
        memory rAndFAmtResult = _getRepayAndFlashBorrowAmt(
            rAndFAmtData,
            _lendingPool,
            _lendingPoolAddressesProvider,
            _protectionAction
        );

    uint256 slippage = _slippage(
        rAndFAmtResult.amtOfDebtToRepay,
        _protectionAction.slippageInBps()
    );
    // Due to accrued aToken, we have some discrepancy we cap it to 1 BPS maximum.
    uint256 oneBpsDiscrepancy = _oneBpsDiscrepancy(
        rAndFAmtResult.amtToFlashBorrow
    );

    bool isFlashBorrowAmtOk = _protectionPayload.amtToFlashBorrow <=
        rAndFAmtResult.amtToFlashBorrow + oneBpsDiscrepancy;
    bool isAmtOfDebtToRepayOk = _protectionPayload.amtOfDebtToRepay >=
        rAndFAmtResult.amtOfDebtToRepay - slippage;

    if (isFlashBorrowAmtOk && isAmtOfDebtToRepayOk) return;
    if (isFlashBorrowAmtOk && !isAmtOfDebtToRepayOk)
        revert(
            "_checkRepayAndFlashBorrowAmt: OffChain amtOfDebtToRepay != onchain amtOfDebtToRepay, out of slippage range."
        );
    if (!isFlashBorrowAmtOk && isAmtOfDebtToRepayOk)
        revert(
            "_checkRepayAndFlashBorrowAmt: OffChain amtToFlashBorrow != onchain amtToFlashBorrow."
        );
    revert(
        "_checkRepayAndFlashBorrowAmt: OffChain amtOfDebtToRepay != onchain amtOfDebtToRepay, out of slippage range. OffChain amtToFlashBorrow != onchain amtToFlashBorrow."
    );
}

function _getProtectionPayload(
    bytes32 _taskHash,
    bytes memory _data,
    bytes memory _offChainData
) pure returns (ProtectionPayload memory) {
    ProtectionPayload memory protectionPayload;

    protectionPayload.taskHash = _taskHash;

    (
        protectionPayload.colToken,
        protectionPayload.debtToken,
        protectionPayload.rateMode,
        protectionPayload.wantedHealthFactor,
        protectionPayload.minimumHealthFactor,
        protectionPayload.onBehalfOf
    ) = abi.decode(
        _data,
        (address, address, uint256, uint256, uint256, address)
    );

    (
        protectionPayload.amtToFlashBorrow,
        protectionPayload.amtOfDebtToRepay,
        protectionPayload.swapActions,
        protectionPayload.swapDatas,
        protectionPayload.subBlockNumber,
        protectionPayload.isPermanent
    ) = abi.decode(
        _offChainData,
        (uint256, uint256, address[], bytes[], uint256, bool)
    );

    return protectionPayload;
}

function _flashLoan(
    ILendingPool _lendingPool,
    address receiverAddress,
    ProtectionPayload memory _protectionPayload
) {
    address[] memory flashBorrowTokens = new address[](1);
    flashBorrowTokens[0] = _protectionPayload.colToken;

    uint256[] memory amtToFlashBorrows = new uint256[](1);
    amtToFlashBorrows[0] = _protectionPayload.amtToFlashBorrow;

    _lendingPool.flashLoan(
        receiverAddress,
        flashBorrowTokens,
        amtToFlashBorrows,
        new uint256[](1),
        _protectionPayload.onBehalfOf,
        abi.encode(
            FlashLoanParamsData(
                _protectionPayload.minimumHealthFactor,
                _protectionPayload.taskHash,
                _protectionPayload.debtToken,
                _protectionPayload.amtOfDebtToRepay,
                _protectionPayload.rateMode,
                _protectionPayload.onBehalfOf,
                _protectionPayload.swapActions,
                _protectionPayload.swapDatas
            )
        ),
        0
    );
}

function _approveERC20Token(
    address _asset,
    address _spender,
    uint256 _amount
) {
    // Approves 0 first to comply with tokens that implement the anti frontrunning approval fix
    SafeERC20.safeApprove(IERC20(_asset), _spender, 0);
    SafeERC20.safeApprove(IERC20(_asset), _spender, _amount);
}

function _paybackToLendingPool(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amount,
    uint256 _rateMode,
    address _onBehalf
) {
    _approveERC20Token(_asset, address(_lendingPool), _amount);
    _lendingPool.repay(_asset, _amount, _rateMode, _onBehalf);
}

function _withdrawCollateral(
    ILendingPool _lendingPool,
    address _to,
    address _asset,
    uint256 _amount,
    address _onBehalf
) {
    DataTypes.ReserveData memory reserve = _lendingPool.getReserveData(_asset);

    SafeERC20.safeTransferFrom(
        IERC20(reserve.aTokenAddress),
        _onBehalf,
        _to,
        _amount
    );

    _lendingPool.withdraw(_asset, _amount, _to);
}

function _transferFees(address _asset, uint256 _amount) {
    SafeERC20.safeTransfer(IERC20(_asset), GELATO, _amount);
}

function _requirePositionSafe(
    uint256 _healthFactor,
    uint256 _discrepancyBps,
    uint256 _wantedHealthFactor
) pure {
    uint256 discrepancy = (_wantedHealthFactor * _discrepancyBps) /
        TEN_THOUSAND_BPS;

    require(
        _healthFactor < _wantedHealthFactor + discrepancy &&
            _healthFactor > _wantedHealthFactor - discrepancy &&
            _healthFactor > 1e18,
        "The user position isn't safe after the protection of the debt."
    );
}

function _requirePositionUnSafe(
    uint256 _currentHealthFactor,
    uint256 _minimumHealthFactor
) pure {
    require(
        _currentHealthFactor < _minimumHealthFactor,
        "The user position's health factor is above the minimum trigger health factor."
    );
}

function _transferDust(
    address _sender,
    address _asset,
    address _user
) {
    uint256 serviceBalance = IERC20(_asset).balanceOf(_sender);

    if (serviceBalance > 0) {
        SafeERC20.safeTransfer(IERC20(_asset), _user, serviceBalance);
    }
}

function _swap(
    address _this,
    ISwapModule _swapModule,
    address[] memory _swapActions,
    bytes[] memory _swapDatas,
    IERC20 _outputToken,
    IERC20 _inputToken,
    uint256 _inputAmt,
    uint256 _minReturn
) returns (uint256 receivedAmt) {
    uint256 outputTokenbalanceBSwap = _outputToken.balanceOf(_this);

    SafeERC20.safeTransfer(_inputToken, address(_swapModule), _inputAmt);
    _swapModule.swap(_swapActions, _swapDatas);

    receivedAmt = _outputToken.balanceOf(_this) - outputTokenbalanceBSwap;

    require(
        receivedAmt > _minReturn,
        "ProtectionAction.swap: received amount < minReturn."
    );
}

function _slippage(uint256 _amount, uint256 _slippageInBps)
    pure
    returns (uint256)
{
    return (_amount * _slippageInBps) / TEN_THOUSAND_BPS;
}

// Due to accrued aToken, we have some discrepancy.
function _oneBpsDiscrepancy(uint256 _amount) pure returns (uint256) {
    return _amount / TEN_THOUSAND_BPS;
}

function _checkSubmitterIsUser(
    ProtectionPayload memory _protectionPayload,
    bytes memory _payload
) pure {
    require(
        _protectionPayload.taskHash ==
            keccak256(
                abi.encode(
                    _protectionPayload.onBehalfOf,
                    _protectionPayload.subBlockNumber,
                    _payload,
                    _protectionPayload.isPermanent
                )
            ),
        "ProtectionAction._checkSubmitterIsUser: Task submitter != user"
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ProtectionPayload} from "../structs/SProtection.sol";

function _getProtectionPayload(
    bytes32 _taskHash,
    bytes memory _data,
    bytes memory _offChainData
) pure returns (ProtectionPayload memory) {
    ProtectionPayload memory protectionPayload;
    protectionPayload.taskHash = _taskHash;

    // On chain data decoding.
    (
        protectionPayload.wantedHealthFactor,
        protectionPayload.minimumHealthFactor,
        protectionPayload.onBehalfOf
    ) = abi.decode(_data, (uint256, uint256, address));

    // Stack too deep hack
    // Cannot do it in one time.
    // Off chain data decoding.
    (
        protectionPayload.colToken,
        protectionPayload.debtToken,
        protectionPayload.rateMode,
        protectionPayload.amtToFlashBorrow,
        protectionPayload.amtOfDebtToRepay,
        ,
        ,
        ,

    ) = abi.decode(
        _offChainData,
        (
            address,
            address,
            uint256,
            uint256,
            uint256,
            address[],
            bytes[],
            uint256,
            bool
        )
    );
    (
        ,
        ,
        ,
        ,
        ,
        protectionPayload.swapActions,
        protectionPayload.swapDatas,
        protectionPayload.subBlockNumber,
        protectionPayload.isPermanent
    ) = abi.decode(
        _offChainData,
        (
            address,
            address,
            uint256,
            uint256,
            uint256,
            address[],
            bytes[],
            uint256,
            bool
        )
    );

    return protectionPayload;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {
    ILendingPoolAddressesProvider
} from "./ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "./ILendingPool.sol";

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function ADDRESSES_PROVIDER()
        external
        view
        returns (ILendingPoolAddressesProvider);

    // solhint-disable-next-line func-name-mixedcase
    function LENDING_POOL() external view returns (ILendingPool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {
    ILendingPoolAddressesProvider
} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../../structs/SAave.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(),
     * receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral,
     * to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the
     * liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens,
     * `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function.
     * Since the function is internal, the event will actually be fired by the LendingPool contract.
     * The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve,
     * receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     * wants to receive them on his own wallet,
     * or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation,
     * for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve,
     * burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset,
     * provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit
     * delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address,
     * receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow:
     * - 1 for Stable,
     * - 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation,
     * for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt.
     * Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral,
     * or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve,
     * burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt
     * tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt
     * for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay:
     * - 1 for Stable,
     * - 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed.
     * Should be the address of the user calling the function
     * if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to
     * the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate,
     *        which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral,
     * `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt
     * of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral,
     * to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset
     * to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens,
     * `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers
     * of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds,
     * implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount
     *        flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed
     *        to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in
     * the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation,
     * for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);

    /// solhint-disable-next-line func-name-mixedcase
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol,
 * including permissioned roles
 * - Acting also as factory of proxies and admin of those,
 *   so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IProtocolDataProvider {
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAction {
    function exec(
        bytes32 _taskHash,
        bytes memory _data,
        bytes memory _offChainData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {IAction} from "./IAction.sol";

interface IProtectionAction is IAction {
    /// sohint-disable-next-line func-name-mixedcase
    function protectionFeeBps() external view returns (uint256);

    /// sohint-disable-next-line func-name-mixedcase
    function slippageInBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISwapModule {
    function swap(address[] memory _swapActions, bytes[] memory _swapDatas)
        external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IFlashLoanReceiver} from "../../interfaces/aave/IFlashLoanReceiver.sol";
import {ILendingPool} from "../../interfaces/aave/ILendingPool.sol";
import {
    ILendingPoolAddressesProvider
} from "../../interfaces/aave/ILendingPoolAddressesProvider.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
    // solhint-disable-next-line var-name-mixedcase
    ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    // solhint-disable-next-line var-name-mixedcase
    ILendingPool public immutable override LENDING_POOL;

    constructor(ILendingPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {
    IProtectionAction
} from "../../../interfaces/services/actions/IProtectionAction.sol";
import {
    Initializable
} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Proxied} from "../../../vendor/hardhat-deploy/Proxied.sol";
import {FlashLoanReceiverBase} from "../FlashLoanReceiverBase.sol";
import {
    ILendingPoolAddressesProvider
} from "../../../interfaces/aave/ILendingPoolAddressesProvider.sol";
import {
    ProtectionPayload,
    FlashLoanData,
    FlashLoanParamsData
} from "../../../structs/SProtection.sol";
import {
    _checkRepayAndFlashBorrowAmt,
    _getProtectionPayload,
    _flashLoan,
    _requirePositionSafe,
    _requirePositionUnSafe,
    _paybackToLendingPool,
    _withdrawCollateral,
    _swap,
    _approveERC20Token,
    _transferFees,
    _transferDust,
    _checkSubmitterIsUser
} from "../../../functions/FProtectionAction.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MATIC} from "../../../constants/CTokens.sol";
import {
    DISCREPANCY_BPS_CAP,
    PROTECTION_FEE_BPS_CAP,
    TEN_THOUSAND_BPS,
    SLIPPAGE_BPS_CAP
} from "../../../constants/CProtectionAction.sol";
import {ISwapModule} from "../../../interfaces/services/module/ISwapModule.sol";

/// @author Gelato Digital
/// @title Protection Action Contract.
/// @dev Perform protection by repaying the debt with collateral token.
contract ProtectionAction is
    IProtectionAction,
    Initializable,
    Proxied,
    FlashLoanReceiverBase
{
    uint256 public discrepancyBps;
    uint256 public override protectionFeeBps;
    uint256 public override slippageInBps;

    address internal immutable _aaveServices;
    ISwapModule internal immutable _swapModule;

    event LogProtectionAction(
        bytes32 taskHash,
        uint256 healthFactorBefore,
        uint256 protectionFee, // In Collateral Token
        uint256 flashloanFee, // In Collateral Token
        uint256 colNeededForProtection,
        uint256 debtRepaid,
        address onBehalfOf
    );

    modifier onlyLendingPool() {
        require(
            msg.sender == address(LENDING_POOL),
            "Only Lending Pool can call this function"
        );
        _;
    }

    modifier onlyAaveServices() {
        require(
            msg.sender == _aaveServices,
            "Only Aave Services can call this function"
        );
        _;
    }

    // solhint-disable no-empty-blocks
    constructor(
        ILendingPoolAddressesProvider _addressProvider,
        address __aaveServices,
        ISwapModule __swapModule
    ) FlashLoanReceiverBase(_addressProvider) {
        _aaveServices = __aaveServices;
        _swapModule = __swapModule;
    }

    function initialize() external initializer {
        discrepancyBps = 200;
        protectionFeeBps = 10;
        slippageInBps = 200;
    }

    /// @dev Set discrepancyBps of how far the final HF can be to the one wanted, capped to 5%.
    function setDiscrepancyBps(uint256 _discrepancyBps)
        external
        onlyProxyAdmin
    {
        require(
            _discrepancyBps <= DISCREPANCY_BPS_CAP,
            "ProtectionAction.setDiscrepancyBps: _discrepancyBps > 5%"
        );
        discrepancyBps = _discrepancyBps;
    }

    ///@dev Set protectionFeeBps, capped to 0.1%
    function setProtectionFeeBps(uint256 _protectionFeeBps)
        external
        onlyProxyAdmin
    {
        require(
            _protectionFeeBps <= PROTECTION_FEE_BPS_CAP,
            "ProtectionAction.setProtectionFeeBps: protectionFeeBps > 0.1%"
        );
        protectionFeeBps = _protectionFeeBps;
    }

    ///@dev Set slippageInBps, capped to 5%
    function setSlippageInBps(uint256 _slippageInBps) external onlyProxyAdmin {
        require(
            _slippageInBps <= SLIPPAGE_BPS_CAP,
            "ProtectionAction.setSlippageInBps: slippageInBps > 5%"
        );
        slippageInBps = _slippageInBps;
    }

    /// @dev Safety function for testing.
    function retrieveFunds(address _token, address _to)
        external
        onlyProxyAdmin
    {
        if (_token == MATIC) payable(_to).transfer(address(this).balance);
        else
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
    }

    /// Execution of Protection.
    /// @param _taskHash Task identifier.
    /// @param _data Data needed to perform Protection.
    /// @dev _data is on-chain data, one of the input to produce Task hash of Aave services.
    /// @param _offChainData Data computed off-chain and needed to perform Protection.
    /// @dev _offChainData include the amount of collateral to withdraw
    /// and the amount of debt token to repay, cannot be computed on-chain.
    // solhint-disable function-max-lines
    function exec(
        bytes32 _taskHash,
        bytes memory _data,
        bytes memory _offChainData
    ) external virtual override onlyAaveServices {
        ProtectionPayload memory protectionPayload = _getProtectionPayload(
            _taskHash,
            _data,
            _offChainData
        );

        // Check if the task submitter is the aave user.
        _checkSubmitterIsUser(protectionPayload, _data);

        // Check if AmtToFlashBorrow and AmtOfDebtToRepay are the one given by the formula.
        _checkRepayAndFlashBorrowAmt(
            protectionPayload,
            LENDING_POOL,
            ADDRESSES_PROVIDER,
            this
        );
        // Cannot give to executeOperation the path array through params bytes
        // => Stack too Deep error.

        _flashLoan(LENDING_POOL, address(this), protectionPayload);

        // Fetch User Data After Refinancing

        (, , , , , uint256 healthFactor) = LENDING_POOL.getUserAccountData(
            protectionPayload.onBehalfOf
        );

        // Check if the service didn't keep any dust amt.
        _transferDust(
            address(this),
            protectionPayload.debtToken,
            protectionPayload.onBehalfOf
        );

        // Check if position is safe.
        _requirePositionSafe(
            healthFactor,
            discrepancyBps,
            protectionPayload.wantedHealthFactor
        );
    }

    /// @dev function called by LendingPool after flash borrow.
    /// @param _assets borrowed tokens.
    /// @param _amounts borrowed amounts associated to borrowed tokens.
    /// @param _premiums premiums to repay.
    /// @param _params custom parameters.
    /// @dev _params contains collateral token, amount of Collateral to
    /// wiithdraw, borrow rate mode, the user who need protection and
    /// swap module used to swap collateral token into debt token.
    function executeOperation(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address,
        bytes calldata _params
    ) external override onlyLendingPool returns (bool) {
        FlashLoanData memory flashloanData = FlashLoanData(
            _assets,
            _amounts,
            _premiums,
            _params
        );
        return _executeOperation(flashloanData);
    }

    // solhint-disable function-max-lines
    // repay logic should be here.
    function _executeOperation(FlashLoanData memory _flashloanData)
        internal
        returns (bool)
    {
        FlashLoanParamsData memory paramsData = abi.decode(
            _flashloanData.params,
            (FlashLoanParamsData)
        );

        /// @notice Check if current health factor is below minimum health factor.
        (, , , , , uint256 healthFactorBefore) = LENDING_POOL
            .getUserAccountData(paramsData.onBehalfOf);
        _requirePositionUnSafe(
            healthFactorBefore,
            paramsData.minimumHealthFactor
        );

        /// @notice Swap Collateral token to debt token.

        uint256 debtRepaid = _swap(
            address(this),
            _swapModule,
            paramsData.swapActions,
            paramsData.swapDatas,
            IERC20(paramsData.debtToken),
            IERC20(_flashloanData.assets[0]),
            _flashloanData.amounts[0],
            paramsData.amtOfDebtToRepay
        );

        /// @notice Payback debt.

        _paybackToLendingPool(
            LENDING_POOL,
            paramsData.debtToken,
            debtRepaid,
            paramsData.rateMode,
            paramsData.onBehalfOf
        );

        /// @notice Withdraw collateral (including fees) and flashloan premium.

        uint256 fees = (_flashloanData.amounts[0] * protectionFeeBps) /
            TEN_THOUSAND_BPS;

        uint256 amtOfColToWithdraw = _flashloanData.amounts[0] +
            fees +
            _flashloanData.premiums[0];

        _withdrawCollateral(
            LENDING_POOL,
            address(this),
            _flashloanData.assets[0],
            amtOfColToWithdraw,
            paramsData.onBehalfOf
        );

        /// @notice Transfer Fees

        _transferFees(_flashloanData.assets[0], fees);

        /// @notice Approve to retrieve.

        _approveERC20Token(
            _flashloanData.assets[0],
            address(LENDING_POOL),
            _flashloanData.amounts[0] + _flashloanData.premiums[0]
        );

        emit LogProtectionAction(
            paramsData.taskHash,
            healthFactorBefore,
            fees,
            _flashloanData.premiums[0],
            amtOfColToWithdraw,
            debtRepaid,
            paramsData.onBehalfOf
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {
    ILendingPoolAddressesProvider
} from "../../../interfaces/aave/ILendingPoolAddressesProvider.sol";
import {ProtectionPayload} from "../../../structs/SProtection.sol";
import {
    _getProtectionPayload
} from "../../../functions/FProtectionActionV2.sol";
import {
    _checkRepayAndFlashBorrowAmt,
    _flashLoan,
    _requirePositionSafe,
    _transferDust,
    _checkSubmitterIsUser
} from "../../../functions/FProtectionAction.sol";
import {ISwapModule} from "../../../interfaces/services/module/ISwapModule.sol";
import {ProtectionAction} from "./ProtectionAction.sol";

/// @author Gelato Digital
/// @title ProtectionV2 Action Contract.
/// @dev Perform protection by repaying the debt with collateral token.
contract ProtectionActionV2 is ProtectionAction {
    event LogBestColAndDebtToken(
        bytes32 indexed taskHash,
        address colToken,
        address debtToken,
        uint256 rateMode
    );

    // solhint-disable no-empty-blocks
    constructor(
        ILendingPoolAddressesProvider _addressProvider,
        address __aaveServices,
        ISwapModule __swapModule
    ) ProtectionAction(_addressProvider, __aaveServices, __swapModule) {}

    /// Execution of Protection.
    /// @param _taskHash Task identifier.
    /// @param _data Data needed to perform Protection.
    /// @dev _data is on-chain data, one of the input to produce Task hash of Aave services.
    /// @param _offChainData Data computed off-chain and needed to perform Protection.
    /// @dev _offChainData include the amount of collateral to withdraw
    /// and the amount of debt token to repay, cannot be computed on-chain.
    // solhint-disable function-max-lines
    function exec(
        bytes32 _taskHash,
        bytes memory _data,
        bytes memory _offChainData
    ) external override onlyAaveServices {
        ProtectionPayload memory protectionPayload = _getProtectionPayload(
            _taskHash,
            _data,
            _offChainData
        );

        emit LogBestColAndDebtToken(
            _taskHash,
            protectionPayload.colToken,
            protectionPayload.debtToken,
            protectionPayload.rateMode
        );

        // Check if the task submitter is the aave user.
        _checkSubmitterIsUser(protectionPayload, _data);

        // Check if AmtToFlashBorrow and AmtOfDebtToRepay are the one given by the formula.
        _checkRepayAndFlashBorrowAmt(
            protectionPayload,
            LENDING_POOL,
            ADDRESSES_PROVIDER,
            this
        );

        // Cannot give to executeOperation the path array through params bytes
        // => Stack too Deep error.

        _flashLoan(LENDING_POOL, address(this), protectionPayload);

        // Fetch User Data After Refinancing

        (, , , , , uint256 healthFactor) = LENDING_POOL.getUserAccountData(
            protectionPayload.onBehalfOf
        );

        // Check if the service didn't keep any dust amt.
        _transferDust(
            address(this),
            protectionPayload.debtToken,
            protectionPayload.onBehalfOf
        );

        // Check if position is safe.
        _requirePositionSafe(
            healthFactor,
            discrepancyBps,
            protectionPayload.wantedHealthFactor
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

library DataTypes {
    // refer to the whitepaper,
    // section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

struct ProtectionPayload {
    bytes32 taskHash;
    address colToken;
    address debtToken;
    uint256 rateMode;
    uint256 amtToFlashBorrow;
    uint256 amtOfDebtToRepay;
    uint256 minimumHealthFactor;
    uint256 wantedHealthFactor;
    address onBehalfOf;
    address[] swapActions;
    bytes[] swapDatas;
    uint256 subBlockNumber;
    bool isPermanent;
}

struct ExecutionData {
    address user;
    address action;
    uint256 subBlockNumber;
    bytes data;
    bytes offChainData;
    bool isPermanent;
}

struct ProtectionDataCompute {
    address colToken;
    address debtToken;
    uint256 totalCollateralETH;
    uint256 totalBorrowsETH;
    uint256 currentLiquidationThreshold;
    uint256 colLiquidationThreshold;
    uint256 wantedHealthFactor;
    uint256 colPrice;
    uint256 debtPrice;
    address onBehalfOf;
    uint256 protectionActionFeeBps;
    uint256 flashloanPremiumBps;
}

struct FlashLoanData {
    address[] assets;
    uint256[] amounts;
    uint256[] premiums;
    bytes params;
}

struct FlashLoanParamsData {
    uint256 minimumHealthFactor;
    bytes32 taskHash;
    address debtToken;
    uint256 amtOfDebtToRepay;
    uint256 rateMode;
    address onBehalfOf;
    address[] swapActions;
    bytes[] swapDatas;
}

struct RepayAndFlashBorrowData {
    bytes32 id;
    address user;
    address colToken;
    address debtToken;
    uint256 wantedHealthFactor;
}

struct RepayAndFlashBorrowResult {
    bytes32 id;
    uint256 amtToFlashBorrow;
    uint256 amtOfDebtToRepay;
    string message;
}

struct CanExecData {
    bytes32 id;
    address user;
    uint256 minimumHF;
    address colToken;
    address spender;
}

struct CanExecResult {
    bytes32 id;
    bool isPositionUnSafe;
    bool isATokenAllowed;
    string message;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// solhint-disable
function _add(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}

function _sub(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}

function _mul(uint256 x, uint256 y) pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function _min(uint256 x, uint256 y) pure returns (uint256 z) {
    return x <= y ? x : y;
}

function _max(uint256 x, uint256 y) pure returns (uint256 z) {
    return x >= y ? x : y;
}

function _imin(int256 x, int256 y) pure returns (int256 z) {
    return x <= y ? x : y;
}

function _imax(int256 x, int256 y) pure returns (int256 z) {
    return x >= y ? x : y;
}

uint256 constant WAD = 10**18;
uint256 constant RAY = 10**27;
uint256 constant QUA = 10**4;

//rounds to zero if x*y < WAD / 2
function _wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), WAD / 2) / WAD;
}

//rounds to zero if x*y < WAD / 2
function _rmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), RAY / 2) / RAY;
}

//rounds to zero if x*y < WAD / 2
function _wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, WAD), y / 2) / y;
}

//rounds to zero if x*y < RAY / 2
function _rdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, RAY), y / 2) / y;
}

// This famous algorithm is called "exponentiation by squaring"
// and calculates x^n with x as fixed-point and n as regular unsigned.
//
// It's O(log n), instead of O(n) for naive repeated multiplication.
//
// These facts are why it works:
//
//  If n is even, then x^n = (x^2)^(n/2).
//  If n is odd,  then x^n = x * x^(n-1),
//   and applying the equation for even x gives
//    x^n = x * (x^2)^((n-1) / 2).
//
//  Also, EVM division is flooring and
//    floor[(n-1) / 2] = floor[n / 2].
//
function _rpow(uint256 x, uint256 n) pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
        x = _rmul(x, x);

        if (n % 2 != 0) {
            z = _rmul(z, x);
        }
    }
}

//rounds to zero if x*y < QUA / 2
function _qmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), QUA / 2) / QUA;
}

//rounds to zero if x*y < QUA / 2
function _qdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, QUA), y / 2) / y;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}

{
  "evmVersion": "london",
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