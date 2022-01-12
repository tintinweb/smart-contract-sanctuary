/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

//  SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

//  MIT

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


// File @openzeppelin/contracts/utils/[email protected]

//  MIT

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

//  MIT

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


// File @openzeppelin/contracts/utils/[email protected]

//  MIT

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

//  MIT

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

//  MIT

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/security/[email protected]

//  MIT

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

    constructor() {
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


// File contracts/lib/DataTypes.sol

//  BUSL-1.1


pragma solidity 0.8.10;

library DataTypes {
    
    uint public constant LUT_SIZE = 9; // Lookup Table size
     
    struct Store {
        Data data;
        
        uint state; // Bitmask of bool //
        FinalState finalState; // only valid after FinishUp is called
        
        Subscriptions subscriptions;
        Guaranteed guaranteed;
        Lottery lottery;
        OverSubscriptions overSubscription;
        Live live;
        Vesting vesting;
        Lp lp;
        History history;
        
        ReturnFunds returnFunds; // When IDO did not meet softCap 
    }
    
     // Data //
    struct Data {
        address token; // The IDO token. Can be zero address if this is a seed raise without LP provision.
        uint subStart; // Subscription Starts
        uint subEnd;   // Subscription Ends
        uint idoStart; // Ido Starts
        uint idoEnd;   // Ido Ends
        uint softCap;  // Unit in currency
        uint hardCap;  // Unit in currency
        uint tokenSalesQty; // Total tokens for sales
        uint minBuyLimitPublic; // min and max buy limit for Public open sales (after subscription). Unit in currency.
        uint maxBuyLimitPublic; // Unit in currency
        uint snapShotId;    // SnapshotId
        address currency; // The raised currency
        address svLaunchAddress;
        address eggAddress;
        
        uint feePcnt; // In 1e6
        
        // Cache
        uint tokensPerCapital;
    }
    
    // Subscription
    struct SubscriptionResultParams {
        bool resultAvailable;
        bool guaranteed;
        uint guaranteedAmount;
        bool wonLottery;
        uint lotteryAmount;
        bool wonOverSub;
        uint overSubAmount;
        uint priority;
        uint eggBurnAmount;
    }
    
    struct SubscriptionParams {
        bool guaranteed;
        uint guaranteedAmount;
        bool inLottery;
        uint lotteryAmount;
        uint overSubAmount;
        uint priority;
        uint eggBurnAmount;
    }
    
    struct SubItem {
        uint paidCapital; // Unit in currency
        bool refundedUnusedCapital; // Has user gets back his un-used capital ?
    }

    struct Subscriptions {
        mapping(address=> DataTypes.SubItem)  items;
        uint count;
    }
    
    struct Guaranteed {
        mapping(address=> uint) subscribedAmount;
        
        uint svLaunchSupplyAtSnapShot;
        uint totalSubscribed; // Unit in currency.
    }

    // Lottery Info
    struct LotteryItem {
        uint index;       
        bool exist;    
    }
  
    struct TallyLotteryResult {
        uint numWinners;
        uint leftOverAmount;
        uint winnerStartIndex;
    }

    struct TallyLotteryRandom {
        bool initialized;
        uint requestTime;
        uint value;
        bool valid;
    }
    
    struct LotteryData {
        uint totalAllocatedAmount; // Unit in currency.
        uint eachAllocationAmount; // Unit in currency.
        bool tallyCompleted;
    }
    struct Lottery {
        mapping(address=>LotteryItem) items;
        uint count;
        
        LotteryData data;
        TallyLotteryRandom random;
        TallyLotteryResult result;
    }

    // Over Subscription
    struct TallyOverSubResult {
        bool tallyCompleted;
        uint winningBucket;
        uint firstLoserIndex;
        uint leftOverAmount;
        uint burnableEggs;
    }

    struct OverSubItem {
        uint amount;        // Amount of over-subscribe tokens. Max is 0.5% of total sales qty.
        uint priority;      // 0 - 100
        uint index;
        uint cumulativeEggBurn; // Cummulative amount of egg burns in the bucket that this user belongs to. As each items is pushed into the array,
                                // this cummulative value increases.
    }

    struct Bucket {
        address[] users;    // This is users address, secondary priority is FCFS
        uint total;         // Precalculated total for optimization.
        uint totalEggs;     // Precalculated total Eggs for optimization.
        
        // Quick lookup-table for pre-calculated total at specific intervals 
        uint[][LUT_SIZE] fastLookUp; // Provide a fast look-up of the total amount at specific indices. 10s, 100s, 1000s, 10,000s, 100,000s, 1,000,000s
    }
    
    struct OverSubscriptions {
        mapping(address=> OverSubItem) items;
        mapping(uint => Bucket) buckets; // 0-100 buckets of address[]

        OverSubData data;

        uint allocatedAmount;
        uint totalOverSubAmount;  // Keep tracks of the total over-subscribed amount
        uint totalMaxBurnableEggs;  // Keep track of the total egg burns amount
        
        TallyOverSubResult result;
    }
    
    struct OverSubData {
        uint stdOverSubQty; // Unit in currency
        uint stdEggBurnQty; // Unit in Egg
    }
    
    struct Live {
        
        LiveData data;
        
        uint allocLeftAtOpen; // This is the amount of allocation (in Currency unit) remaining at Live opening (after subscription)
        uint allocSoldInLiveSoFar; // This is the amount of allocation (in Currency unit) sold in Live, so far.
        
        mapping(uint=>mapping(address=>bool)) whitelistMap;
         
         // Record of user's purchases 
        mapping(address=>uint)  whitelistPurchases; // record of sales in whitelist round 
        mapping(address=>uint)  publicPurchases;    // record of sales in publc round 
    }
    
    // Live: Tier system for Whitelist FCFS
    struct Tier {
        uint minBuyAmount;
        uint maxBuyAmount; 
    }
    
    struct LiveData {
        uint whitelistFcfsDuration; // 0 if whitelist is not turned on
        Tier[] tiers; // if has at least 1 tier, then the WhitelistFcfs is enabled 
    }
    
    struct LockInfo {
        uint[] pcnts;
        uint[] durations;
        DataTypes.VestingReleaseType releaseType;
    }
    
    struct ClaimInfo {
        bool[] claimed;
        uint amount;
    }
    
    struct ClaimRecords {
        mapping(address=>ClaimInfo) team;
    }
    
    struct Vesting {
       VestData data;
        ClaimRecords claims;
    }
    
    struct VestData {
        LockInfo    teamLock;
        uint        teamLockAmount; // Total vested amount
        uint desiredUnlockTime;
    }
    
    struct ClaimIntervalResult {
        uint claimedSoFar;
        uint claimable;
        uint nextLockedAmount;
        uint claimStartIndex;
        uint numClaimableSlots;
        uint nextUnlockIndex;
        uint nextUnlockTime;
    }
    
    struct ClaimLinearResult {
        uint claimedSoFar;
        uint claimable;
        uint lockedAmount;
        uint newStartTime;
        uint endTime;
    }
    
    struct ReturnFunds {
        mapping(address=>uint)  amount;
    }
    
    struct PurchaseDetail {
        uint guaranteedAmount;
        uint lotteryAmount;
        uint overSubscribeAmount;
        uint liveWlFcfsAmount;
        uint livePublicAmount;
        uint total;
        bool hasReturnedFund;
    }
    
    // LP 
    struct Lp {
        LpData data;
        LpLocks locks;
        LpResult result;
        bool enabled;

        LpSwap swap;
    }
    struct LpData {
        DataTypes.LpSize  size;
        uint sizeParam;
        uint rate;
        uint softCap;
        uint hardCap;
       
        // DEX routers and factory
        address[] routers;
        address[] factory;
        
        uint[] splits;
        address tokenA;
        address currency; // The raised currency 
    }
    
    struct LpLocks {
        uint[]  pcnts;
        uint[]  durations;
        uint    startTime;
    }
    
    struct LpResult {
        uint[] tokenAmountUsed;
        uint[] currencyAmountUsed;
        uint[] lpTokenAmount;
        bool[] claimed;
        bool created;
    }
    
    struct LpSwap {
       bool needSwap;
       bool swapped;
       uint newCurrencyAmount;
    }
    
    // History
    enum ActionType {
        FundIn,
        FundOut,
        Subscribe,
        RefundExcess,
        BuyTokens,
        ReturnFund,
        ClaimFund,
        ClaimLp
    }
    
    struct Action {
        uint128     actionType;
        uint128     time;
        uint256     data1;
        uint256     data2;
    }
   
    struct History {
        mapping(address=>Action[]) investor;
        mapping(address=>Action[]) campaignOwner;

        // Keep track of all investor's address for exporting purpose
        address[] allInvestors;
        mapping(address => bool) invested;
    }
    
    // ENUMS
    enum Ok {
        BasicSetup,
        Config,
        Finalized,
        FundedIn,
        Tally,
        FinishedUp,
        LpCreated
    }
    
    enum FinalState {
        Invalid,
        Success, // met soft cap
        Failure, // did not meet soft cap
        Aborted  // when a campaign is cancelled
    }
    
    enum LpProvider {
        PancakeSwap,
        ApeSwap,
        WaultFinance
    }
    
    enum FundType {
        Currency,
        Token,
        WBnb,
        Egg
    }
    
    enum LpSize {
        Zero,       // No Lp provision
        Min,        // SoftCap
        Max,        // As much as we can raise above soft-cap. It can be from soft-cap all the way until hard-cap
        MaxCapped   // As much as we can raise above soft-cap, but capped at a % of hardcap. Eg 90% of hardcap.
    }
    
    enum VestingReleaseType {
        ByIntervals,
        ByLinearContinuous
    }
    
    // Period according to timeline
    enum Period {
        None,
        Setup,
        Subscription,
        IdoWhitelisted,
        IdoPublic,
        IdoEnded
    }
}


// File contracts/lib/Constant.sol

//  BUSL-1.1


pragma solidity 0.8.10;

library Constant {

    uint    public constant FACTORY_VERSION = 1;
    address public constant ZERO_ADDRESS    = address(0);
    
    string public constant  BNB_NAME        = "BNB";
    uint    public constant VALUE_E18       = 1e18;
    uint    public constant VALUE_MAX_SVLAUNCH = 10_000e18;
    uint    public constant VALUE_MIN_SVLAUNCH = 40e18;
    uint    public constant PCNT_100        = 1e6;
    uint    public constant PCNT_10         = 1e5;
    uint    public constant PCNT_50         = 5e5;
    uint    public constant MAX_PCNT_FEE    = 3e5; // 30% fee is max we can set //
    uint    public constant PRIORITY_MAX    = 100;

    uint    public constant BNB_SWAP_MAX_SLIPPAGE_PCNT = 3e4; // Max slippage is set to 3%

    // Chainlink VRF Support
    uint    public constant VRF_FEE = 2e17; // 0.2 LINK
    uint    public constant VRF_TIME_WINDOW = 60; // The randome value will only be acccep within 60 sec

}


// File contracts/lib/Error.sol

//  BUSL-1.1

pragma solidity 0.8.10;

library Error {
    
    enum Code {
        ValidationError,
        NoBasicSetup,
        UnApprovedConfig,
        InvalidCurrency,
        AlreadySubscribed,
        AlreadyCalledFinishUp,
        AlreadyCreated,
        AlreadyClaimed,
        AlreadyExist,
        InvalidIndex,
        InvalidAmount,
        InvalidAddress,
        InvalidArray,
        InvalidFee,
        InvalidRange,
        CannotInitialize,
        CannotConfigure,
        CannotCreateLp,
        CannotBuyToken,
        CannotRefundExcess,
        CannotReturnFund,
        NoRights,
        IdoNotEndedYet,
        SoftCapNotMet,
        SingleItemRequired,
        ClaimFailed,
        WrongValue,
        NotReady,
        NotEnabled,
        NotWhitelisted,
        ValueExceeded,
        LpNotCreated,
        Aborted,
        SwapExceededMaxSlippage
    }

    
    function str(Code err) internal pure returns (string memory) {
        uint value = uint(err);
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
}


// File @openzeppelin/contracts/utils/math/[email protected]

//  MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

//  MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

//  MIT

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

//  MIT

pragma solidity ^0.8.0;



/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}


// File contracts/logic/Guaranteed.sol

//  BUSL-1.1

pragma solidity 0.8.10;




library Guaranteed {
    
    function subscribe(DataTypes.Guaranteed storage param, uint amount, uint maxAlloc) internal {
        _require(param.subscribedAmount[msg.sender] == 0, Error.Code.AlreadySubscribed); // User can only subscribe once only //
        _require(amount <= maxAlloc, Error.Code.ValueExceeded);
        
        param.subscribedAmount[msg.sender] = amount; 
        param.totalSubscribed += amount;
    }

    // uint : the guaranteed amount if guaranteed is true. Or else the amount will be the minFloorAmount. Unit in currency.
    // bool : Guaranteed.
    function getGuaranteedAmt(DataTypes.Store storage param, address user) view internal returns (uint, bool) {
        DataTypes.Guaranteed storage gtd = param.guaranteed;
        DataTypes.Lottery storage lottery = param.lottery;
        
        // Get svLaunch balance of user
        uint sv = ERC20Snapshot(param.data.svLaunchAddress).balanceOfAt(user, param.data.snapShotId);

        if (gtd.svLaunchSupplyAtSnapShot == 0 || sv < Constant.VALUE_MIN_SVLAUNCH) {
            return (0, false);
        }
        
        if (sv > Constant.VALUE_MAX_SVLAUNCH) {
            sv = Constant.VALUE_MAX_SVLAUNCH;
        }
            
        // If the guaranteed amt is less than the _minGuaranteedFloorAmt, then it is not guaranteed.
        uint alloc = (sv * param.data.hardCap) / gtd.svLaunchSupplyAtSnapShot;
       
        bool guaranteed;
        if (alloc >= lottery.data.eachAllocationAmount) {
            guaranteed = true;
        } else {
            alloc = lottery.data.eachAllocationAmount; // This is the min allocation, But no guarantee.
        }
  
        return (alloc, guaranteed);
    }
    
    // uint : amount subscribed
    // bool : guaranteed (true), or pending lottery (false)
    function getGuaranteedSubscription(DataTypes.Store storage param, address user) view internal returns (uint, bool) {
        (, bool guaranteed) = getGuaranteedAmt(param, user);
        return (param.guaranteed.subscribedAmount[user], guaranteed); 
    }
       
    function _require(bool condition, Error.Code err) pure private {
        require(condition, Error.str(err));
    }
}


// File contracts/logic/Lottery.sol

//  BUSL-1.1

pragma solidity 0.8.10;



library Lottery {

    function subscribe(DataTypes.Lottery storage param, uint amtForCheck) external {
        DataTypes.LotteryItem memory item = param.items[msg.sender];
        _require(!item.exist, Error.Code.AlreadyExist);
        _require(amtForCheck == param.data.eachAllocationAmount, Error.Code.InvalidAmount);
        
        param.items[msg.sender] = DataTypes.LotteryItem(param.count, true);
        param.count++;
    }
    
    function getTotal(DataTypes.Lottery storage param) external view returns (uint) {
        return param.data.eachAllocationAmount * param.count;
    }

    function initRandomValue(DataTypes.Lottery storage param) external {
        param.random.requestTime = block.timestamp;
        param.random.initialized = true;
    }

    function readyForTally(DataTypes.Lottery storage param) public view returns (bool) {
        bool elapsed = param.random.initialized && (block.timestamp - param.random.requestTime) > Constant.VRF_TIME_WINDOW;
        return ( param.random.valid || elapsed);
    }

    function setRandomValue(DataTypes.Lottery storage param, uint value) external {
        // If the random value came after the time-window, the this value will not be used
        bool onTime = (block.timestamp - param.random.requestTime) < Constant.VRF_TIME_WINDOW;

        // If random value is > 0
        param.random.value = onTime ? value : 0;
        param.random.valid = onTime;
    }

    function tally(DataTypes.Lottery storage param, uint allocAmt) external {

        // Has chainlink provided the random number ? Or has time window elapsed ?
        _require(readyForTally(param), Error.Code.NotReady);

        _require(!param.data.tallyCompleted, Error.Code.NotReady);
        param.data.tallyCompleted = true;

        param.result.leftOverAmount = allocAmt; // default value in case no one in lottery //
        param.data.totalAllocatedAmount = allocAmt;
        
        uint numWinners = allocAmt / param.data.eachAllocationAmount;
        if (numWinners==0 || param.count==0) {
            return;
        }
        
        if (numWinners > param.count) {
            numWinners = param.count;
        }

        param.result.numWinners = numWinners;
        param.result.leftOverAmount = allocAmt - (numWinners * param.data.eachAllocationAmount);
        
        // pick random index if needed //
        if (numWinners < param.count) {
            param.result.winnerStartIndex = param.random.value % param.count; 
        }
    }
    
    function getFinalLeftOver(DataTypes.Lottery storage param) external view returns (uint) {
        return param.result.leftOverAmount;
    } 
  
    
    // bool : Participated?
    // bool : Won?
    // uint : Amount (ie the value of eachAllocationAmt, regardless of whether user win or lose)
    function isWinner(DataTypes.Lottery storage param, address user) public view returns (bool, bool, uint) {
        DataTypes.LotteryItem memory item = param.items[user];
        bool participated = item.exist;
        if (!participated || !param.data.tallyCompleted || param.count==0 || param.result.numWinners==0) {
            return (participated, false, 0);
        }
        
        uint winAmt = param.data.eachAllocationAmount;
        
        // Everyone wins ?
        if (param.result.numWinners==param.count) {
            return (true, true, winAmt);
        }
    
        // Not everyone wins
        uint start = param.result.winnerStartIndex;
        uint end = start + param.result.numWinners - 1;
        
        bool won = item.index >= start && item.index <= end;
        if (!won && end >= param.count) {
            end -= param.count; // wrap around
            won = item.index <= end;
        }
        return (true, won,  winAmt);
    } 
    
    function getRefundable(DataTypes.Lottery storage param, address user) external view returns(uint) {
        (bool participated, bool won, uint amt) = isWinner(param, user);
        return ( (participated && !won) ? amt : 0 );
    }


    function _require(bool condition, Error.Code err) pure private {
        require(condition, Error.str(err));
    }
}


// File contracts/logic/OverSubscribe.sol

//  BUSL-1.1

pragma solidity 0.8.10;



library OverSubscribe {
    

    // Note: totalEgg is for checking
    function subscribe (DataTypes.OverSubscriptions storage param, uint amount, uint priority, uint totalEgg) external {
        _require(amount > 0 && 
            amount <= param.data.stdOverSubQty &&
            priority <= Constant.PRIORITY_MAX, Error.Code.ValidationError);
        
        // already subscribed ??
        DataTypes.OverSubItem memory item = param.items[msg.sender];
        _require(item.amount == 0, Error.Code.AlreadySubscribed);
        
        // Get total egg to burn //
        uint eggsRequired = getEggBurnQty(param, amount, priority);
        _require(eggsRequired==totalEgg, Error.Code.InvalidAmount);
        
        // Update Bucket system
        insertIntoBucket(param, msg.sender, priority, amount, totalEgg);
    }
    
    function getEggBurnQty(DataTypes.OverSubscriptions storage param, uint amount, uint priority) public view returns (uint) {
        return (param.data.stdEggBurnQty * amount * (Constant.PCNT_100 + (Constant.PCNT_10 * priority))) / (param.data.stdOverSubQty * Constant.PCNT_100);
    }

   function getTotal(DataTypes.OverSubscriptions storage param) external view returns (uint) {
        uint total;
        for (uint n=0; n<=Constant.PRIORITY_MAX; n++) {
            total += param.buckets[n].total;
        }
        return total;
    }

    function tally(DataTypes.OverSubscriptions storage param, uint allocAmt) external {
        param.allocatedAmount = allocAmt;
        // Use the priority buckets and FastLookup table to determine the last person that won the over-subscribe
    
        // If under-subscribed
        if (param.totalOverSubAmount <= param.allocatedAmount ) {
            param.result.winningBucket = 0;
            param.result.firstLoserIndex = param.buckets[0].users.length;
            param.result.leftOverAmount = param.allocatedAmount - param.totalOverSubAmount;
            param.result.burnableEggs = param.totalMaxBurnableEggs;
        } else {
            // Over-subscribed. We need to perform FCFS 
            (uint bucket, uint amtLeft, uint eggUsedSoFar) = traverseToLast(param);
            param.result.winningBucket = bucket;
            (param.result.firstLoserIndex, param.result.leftOverAmount, param.result.burnableEggs) = findFirstLoserIndex(param, bucket, amtLeft);
            param.result.burnableEggs += eggUsedSoFar;
        }
        param.result.tallyCompleted = true;
    }
    
    // bool : has subscribed 
    // uint : amount Over-subscribed
    // uint : priority
    // uint : eggBurn Qty
    function getSubscription(DataTypes.OverSubscriptions storage param, address user) external view returns (bool, uint, uint, uint) {
        
        DataTypes.OverSubItem memory item = param.items[user];
        bool hasSubscribed = (item.amount > 0);
        uint totalEggsBurn;
        
        if (hasSubscribed) {
            totalEggsBurn = getEggBurnQty(param, item.amount, item.priority );
        }
        return (hasSubscribed, item.amount, item.priority, totalEggsBurn);
    }
    
    // bool : participated ?
    // bool : won ? 
    // uint : amount (Os),  (regardless of whether user win or lose)
    // uint : amount (egg), (regardless of whether user win or lose)
    // uint : priority      (regardless of whether user win or lose)
    function isWinner(DataTypes.OverSubscriptions storage param, address user) public view returns (bool, bool, uint, uint, uint) {
        DataTypes.OverSubItem memory item = param.items[user];
        bool participated = (item.amount > 0);
        
        if (!participated || !param.result.tallyCompleted) {
            return (participated, false, 0, 0, 0);
        }
        
        // Is user in the required priority bucket ?
        bool won = (item.priority > param.result.winningBucket);
        if (item.priority == param.result.winningBucket) {
            won = (item.index < param.result.firstLoserIndex);
        }
        uint eggBurn = getEggBurnQty(param, item.amount, item.priority);
        
        return (participated, won, item.amount, eggBurn, item.priority);
    }
    
    // uint : currency refundable
    // uint : eggs refundable
    function getRefundable(DataTypes.OverSubscriptions storage param, address user) external view returns(uint, uint) {
        
        (bool participated, bool won, uint amtFund, uint amtEgg, ) = isWinner(param, user);
        
        if (!participated) {
            return (0,0);
        }
        // Refund if user participate in Oversubscribe but didn't gets allocated due to priority.
        return won ? (0, 0) : (amtFund, amtEgg);
    }
    
    function getBurnableEggs(DataTypes.OverSubscriptions storage param, address user) external view returns (uint) {
        (bool participated, bool won, , uint amtEgg, ) = isWinner(param, user);
        return (participated && won) ? amtEgg : 0;
    }
    
    function getFinalLeftOver(DataTypes.OverSubscriptions storage param) external view returns (uint) {
        return param.result.leftOverAmount;
    } 
    
    function getResult(DataTypes.OverSubscriptions storage param) external view returns (uint, uint, uint) {
        return (param.result.winningBucket, param.result.firstLoserIndex, param.result.leftOverAmount);
    }
    
    function getBurnableEggsAfterTally(DataTypes.OverSubscriptions storage param) external view returns (uint) {
        return param.result.tallyCompleted ? param.result.burnableEggs : 0;
    }
    
    // Helpers
    function insertIntoBucket(DataTypes.OverSubscriptions storage param, address user, uint priority, uint amount, uint totalEgg) private {
        DataTypes.Bucket storage bucket = param.buckets[priority];
        uint index = bucket.users.length;
        bucket.users.push(user);
        bucket.total += amount;
        bucket.totalEggs += totalEgg;
        
         // Update info
        DataTypes.OverSubItem storage item = param.items[user];
        item.amount = amount;
        item.priority = priority;
        item.index = index;
        item.cumulativeEggBurn = bucket.totalEggs; // save the current cummulative amount of egg Burn.
        
        param.totalOverSubAmount += amount;
        param.totalMaxBurnableEggs += totalEgg;
      
       // Update the Fast Lookup table
       // Example :
       // [0] : 0-9, 10-19, ...
       // [1] : 0-99, 100-199, ...
       // [2] : 0-999, 1000-1999, ...
       // ...
       index++;
       for (uint n=1; n<= DataTypes.LUT_SIZE; n++) {
           if (index % (10**n) == 0) {
               bucket.fastLookUp[n-1].push(bucket.total);
           } else {
               return;
           }
       }
    }
    
    // Note: this is only needed when the allocatedAmount is NOT enough to cover all over-subscriptions
    // uint : bucket
    // uint : amtLeft
    // uint : eggUsed
    function traverseToLast(DataTypes.OverSubscriptions storage param) private view returns (uint, uint, uint) {
        uint amtLeft = param.allocatedAmount; 
        uint totalInBucket;
        uint totalEggUsed;
    
        // Priority from 0 to 100. A total of 101 levels.
        // Careful for n-- underflow //
        for (uint n=Constant.PRIORITY_MAX+1; n>0; n--) {
              
            totalInBucket = param.buckets[n-1].total;
            
            if ( amtLeft < totalInBucket) {
                return (n-1, amtLeft, totalEggUsed);
            } else {
                amtLeft -= totalInBucket;
                totalEggUsed += param.buckets[n-1].totalEggs;
            }
        }
        return (0, amtLeft, totalEggUsed); // Should not happen, as we have checked for condition : param.totalOverSubAmt > param.allocatedAmt
    }
    
    struct FindParam {
        uint foundAt; 
        uint startAt;
        uint len; 
        uint value; 
        uint crossed; 
        uint amtAt; 
        uint jumpToIndex;
        uint userAmt;
        uint end;
    }
    // uint : firstLoserIndex, 
    // uint : leftOverAmount
    // uint : eggUsed
    function findFirstLoserIndex(DataTypes.OverSubscriptions storage param, uint index, uint leftOver) private view returns (uint, uint, uint) {
        // Edge condition: If nothing is left 
        if (leftOver == 0) {
            return (0,0,0);
        }
        
        // Proceed to find the FirstLoserIndex
        DataTypes.Bucket memory bucket = param.buckets[index];
        
        FindParam memory p;
        uint n;
        uint m;
       
        // Careful for n-- underflow //
        for (n = DataTypes.LUT_SIZE; n > 0; n--) {
            
            p.len = bucket.fastLookUp[n-1].length;
            p.crossed = 0;
            p.startAt = p.foundAt / (10**n);
            for (m=p.startAt; m<p.len; m++) {
                
                p.value = bucket.fastLookUp[n-1][m];
                if (p.value < leftOver) {
                  p.crossed = m+1;
                  p.amtAt = p.value;
                } else {
                    break;
                }
            }
            
            if (p.crossed > 0) {
                p.jumpToIndex = (10**n) * p.crossed;
                p.foundAt += p.jumpToIndex;
            }
       }
       
       // We are at the last LookupTable offset. We have found "foundAt" & "amtAt".
       // So we just need to find the firstLoserIndex by looping a max of 10 items 
       uint bucketLen = bucket.users.length;
       p.end = p.foundAt + 10;
       if (p.end > bucketLen) {
           p.end = bucketLen;
       }
       
       for (n = p.foundAt; n < p.end; n++) {
           
           p.userAmt = param.items[bucket.users[n]].amount;
           p.amtAt += p.userAmt;
           if (p.amtAt >= leftOver) {
               // We found it //
               
               if (p.amtAt==leftOver) {
                   return (n+1, 0, param.items[bucket.users[n]].cumulativeEggBurn);
               } else {
                   
                   uint cummulative;
                   if (n>0) {
                       cummulative = param.items[bucket.users[n-1]].cumulativeEggBurn;
                   }
                   return (n, leftOver + p.userAmt - p.amtAt, cummulative);
               }
           }
       }
       
       // This should not happen
      assert(false);
      return(0,0,0);
    }
    
    function _require(bool condition, Error.Code err) pure private {
        require(condition, Error.str(err));
    }
    
}


// File contracts/logic/Generic.sol

//  BUSL-1.1

pragma solidity 0.8.10;






library Generic {

    using Guaranteed for DataTypes.Store;
    using Lottery for DataTypes.Lottery;
    using OverSubscribe for DataTypes.OverSubscriptions;
    
    function initialize(
        DataTypes.Store storage store,
        address token,  // If it is a Seed round, the token address can be zero-address and there will not be LP provision.
        uint[4] calldata dates, // subStart, subEnd, idoStart, idoEnd //
        uint[2] calldata caps, //softCap, hardCap
        uint tokenSalesQty,
        uint[4] calldata subInfo, // snapShotId, lotteryAmt, stdOverSubscribeAmt, eggBurnForOverSubscribe   
        uint[2] calldata buyLimitsPublic, // min, max
        address currency, 
        uint feePcnt,
        address svLaunchAddress, 
        address eggAddress
    ) external {
        _require(dates[0]<dates[1] && dates[2]<dates[3], Error.Code.ValidationError);
        _require(caps[0] > 0 && caps[1] > 0 && caps[0]<caps[1], Error.Code.ValidationError);
        _require(tokenSalesQty > 0, Error.Code.InvalidAmount);
        
        _require(buyLimitsPublic[0] > 0 && buyLimitsPublic[0] < buyLimitsPublic[1], Error.Code.ValidationError);
        _require(subInfo[0] > 0 && subInfo[1] > 0 && subInfo[2] > 0, Error.Code.ValidationError);
        _require(feePcnt <= Constant.PCNT_100, Error.Code.ValidationError);

        // After this setup, the basic config is done.
        DataTypes.Data storage data = store.data;
        DataTypes.Guaranteed storage guaranteed = store.guaranteed;
        DataTypes.OverSubscriptions storage overSub = store.overSubscription;
         
        data.svLaunchAddress = svLaunchAddress;
        data.eggAddress = eggAddress;
        
        data.token = token;
        data.subStart = dates[0];
        data.subEnd = dates[1];
        data.idoStart = dates[2];
        data.idoEnd = dates[3];
        data.softCap = caps[0];
        data.hardCap = caps[1];
        data.tokenSalesQty = tokenSalesQty;
        data.minBuyLimitPublic = buyLimitsPublic[0];
        data.maxBuyLimitPublic = buyLimitsPublic[1];
        data.feePcnt = feePcnt;
        data.snapShotId = subInfo[0];
        
        // To support differnt dp (eg dp9), tokensPerCapital is multiplied by e18 to avoid truncational error.
        data.tokensPerCapital = (tokenSalesQty * Constant.VALUE_E18) / data.hardCap;
        
        // Setup Guaranteed     
        guaranteed.svLaunchSupplyAtSnapShot = ERC20Snapshot(store.data.svLaunchAddress).totalSupplyAt(data.snapShotId);
        
        // Setup Lottery
        store.lottery.data.eachAllocationAmount = subInfo[1];
        
        // Setup OverSubscribe 
        overSub.data.stdOverSubQty = subInfo[2];
        overSub.data.stdEggBurnQty = subInfo[3];
        
        // Currency
        store.data.currency = currency;
    }
    
    function getSubscriptionResult(DataTypes.Store storage store, address user) external view returns (DataTypes.SubscriptionResultParams memory) {
        DataTypes.SubscriptionResultParams memory p;
        p.resultAvailable = true;
            
        (p.guaranteedAmount, p.guaranteed) = store.getGuaranteedSubscription(user);
            
        bool participated;
        bool won;
        uint amountFund;
        uint amountEgg;
        (participated, won, amountFund) = store.lottery.isWinner(user);
        if (participated) {
            p.wonLottery = won;
            p.lotteryAmount = won ? amountFund : 0;
        }
            
        ( participated, won, amountFund, amountEgg, ) =  store.overSubscription.isWinner(user);
        if (participated) {
            p.wonOverSub = won;
            p.overSubAmount = won ? amountFund : 0;
            p.eggBurnAmount = won ? amountEgg : 0;
        }
        return p;
    }
    
    function getPurchaseDetail(DataTypes.Store storage store, address user, bool tallyOk, bool includeRefundable) external view returns (DataTypes.PurchaseDetail memory) {
        DataTypes.PurchaseDetail memory p;
        
        p.guaranteedAmount = store.guaranteed.subscribedAmount[user];
        p.lotteryAmount = store.lottery.items[user].exist ? store.lottery.data.eachAllocationAmount : 0;
        p.overSubscribeAmount = store.overSubscription.items[user].amount;
        p.liveWlFcfsAmount = store.live.whitelistPurchases[user];
        p.livePublicAmount = store.live.publicPurchases[user];
        p.hasReturnedFund =  store.returnFunds.amount[user] > 0;
        
        // If subscription tally completed, we exclude any refund amount in lottery & over-subscribe
        if (!includeRefundable && tallyOk) {
            
            bool participated;
            bool won;
            uint amt;

            (participated, won, amt) = store.lottery.isWinner(user);
            if (participated && !won) {
                p.lotteryAmount = 0;
            }

            (participated, won, amt, , ) = store.overSubscription.isWinner(user);
            if (participated && !won) {
                p.overSubscribeAmount = 0;
            }
        }
        p.total = (p.guaranteedAmount + p.lotteryAmount + p.overSubscribeAmount + p.liveWlFcfsAmount + p.livePublicAmount);
        return p;
    }
    
    
    function _require(bool condition, Error.Code err) pure private {
        require(condition, Error.str(err));
    }
}


// File contracts/core/DataStore.sol

//  BUSL-1.1

pragma solidity 0.8.10;




contract DataStore {
        
    using Generic for *;
        
    DataTypes.Store private _dataStore;
    
    event ApproveConfig(bool approve);

    //--------------------//
    // EXTERNAL FUNCTIONS //
    //--------------------//

    function getCampaignInfo() external view returns (
        DataTypes.Data memory, 
        DataTypes.OverSubData memory,
        uint, // lotteryAmount
        uint, //whitelistFcfsDuration
        uint //desiredUnlockTime
        ){
            return (_dataStore.data, 
                _dataStore.overSubscription.data,
                _dataStore.lottery.data.eachAllocationAmount,
                _dataStore.live.data.whitelistFcfsDuration,
                _dataStore.vesting.data.desiredUnlockTime);
    }

    function getVestingInfo() external view returns (uint count, DataTypes.VestingReleaseType releaseType) {
        count = _dataStore.vesting.data.teamLock.pcnts.length;
        releaseType = _dataStore.vesting.data.teamLock.releaseType;
    }
        
    function getVestingData(uint index) external view returns (uint, uint) {
        return (_dataStore.vesting.data.teamLock.pcnts[index], _dataStore.vesting.data.teamLock.durations[index]); 
    }
    
    function getWhitelistTiersInfo() external view returns (uint, uint) {
        return (_live().data.whitelistFcfsDuration, _live().data.tiers.length);
    }
    
    function getWhitelistTiersData(uint index) external view returns (uint, uint) {
        return (_live().data.tiers[index].minBuyAmount, _live().data.tiers[index].maxBuyAmount);
    }
    
    function getLpInfo() external view returns ( DataTypes.LpSize, uint, uint, uint, uint, uint, bool, bool,  uint) {
        return (_dataStore.lp.data.size, 
            _dataStore.lp.data.sizeParam, 
            _dataStore.lp.data.rate, 
            _dataStore.lp.data.splits.length,
            _dataStore.lp.locks.startTime,
            _dataStore.lp.locks.pcnts.length,
            _dataStore.lp.swap.needSwap,
            _dataStore.lp.swap.swapped,
            _dataStore.lp.swap.newCurrencyAmount);
    }
    
    function getLpRouterSplits(uint index) external view returns (address, address, uint) {
        return (_dataStore.lp.data.routers[index], _dataStore.lp.data.factory[index], _dataStore.lp.data.splits[index]);
    }
        
    function getLpLock(uint index) external view returns (uint, uint) {
        return (_dataStore.lp.locks.pcnts[index], _dataStore.lp.locks.durations[index]);
    }

    
    //--------------------//
    // PUBLIC FUNCTIONS   //
    //--------------------//

    
    function getAllocLeftForLive() public view returns (uint) {
        return _hasOpened() ? _dataStore.live.allocLeftAtOpen - _dataStore.live.allocSoldInLiveSoFar : 0;
    }
    
    function getState(DataTypes.Ok stat) public view returns (bool) {
        return (_dataStore.state & (1 << uint8(stat))) > 0;
    }
    
    function getFinalState() external view returns (DataTypes.FinalState) {
        return _dataStore.finalState;
    }
    
    function getTokensForCapital(uint capital) public view returns (uint) {
        return (_dataStore.data.tokensPerCapital * capital)/Constant.VALUE_E18;
    }
    
    // Get the current total sales in raised currency 
    function getTotalAllocSold() public view returns (uint) {
        return _hasOpened() ? _dataStore.data.hardCap - getAllocLeftForLive() : 0;
    }
    
    function getCurrentPeriod() public view returns (DataTypes.Period) {
        if (!getState(DataTypes.Ok.BasicSetup)) {
            return DataTypes.Period.None;
        }
        // IDO Ended ?
        if (block.timestamp >= _dataStore.data.idoEnd) {
            return DataTypes.Period.IdoEnded;
        }
        // IDO Period ?
        if (block.timestamp >= _dataStore.data.idoStart && block.timestamp < _dataStore.data.idoEnd) {
            uint duration = _dataStore.live.data.whitelistFcfsDuration;
            if (duration > 0) {
                if (block.timestamp <= (_dataStore.data.idoStart + duration)) {
                    return DataTypes.Period.IdoWhitelisted;
                }
            }
            return DataTypes.Period.IdoPublic;
        }
        // Subscriptio Period ?
        if (block.timestamp >= _dataStore.data.subStart && block.timestamp < _dataStore.data.subEnd) {
            return DataTypes.Period.Subscription;
        }
        return DataTypes.Period.Setup;
    }
    
    
    //--------------------//
    // INTERNAL FUNCTIONS //
    //--------------------//
    function _store() internal view returns (DataTypes.Store storage) {
        return _dataStore;
    }
    
    function _data() internal view returns (DataTypes.Data storage) {
        return _dataStore.data;
    }
    
    function _subscriptions() internal view returns (DataTypes.Subscriptions storage) {
        return _dataStore.subscriptions;
    }
 
    function _guaranteed() internal view returns (DataTypes.Guaranteed storage) {
        return _dataStore.guaranteed;
    }
    
    function _lottery() internal view returns (DataTypes.Lottery storage) {
        return _dataStore.lottery;
    }
 
    function _overSubscriptions() internal view returns (DataTypes.OverSubscriptions storage) {
        return _dataStore.overSubscription;
    }
    
    function _live() internal view returns (DataTypes.Live storage) {
        return _dataStore.live;
    }
    
    function _vesting() internal view returns (DataTypes.Vesting storage) {
        return _dataStore.vesting;
    }
    
    function _lp() internal view returns (DataTypes.Lp storage) {
        return _dataStore.lp;
    }
    
    function _history() internal view returns (DataTypes.History storage) {
        return _dataStore.history;
    }
    
    function _setState(DataTypes.Ok stat, bool on) internal {
        if (on) {
            _dataStore.state |= (1 << uint8(stat));
        } else {
            _dataStore.state &= ~(1 << uint8(stat));
        }
    }
    
    function _setConfigApproved(bool approved) internal {
        _setState(DataTypes.Ok.Config, approved);
        emit ApproveConfig(approved);
    }

    function _isBnbCurrency() internal view returns (bool) {
        return _dataStore.data.currency == address(0);
    }

    function _canInitialize() internal view returns (bool) {
        return (!getState(DataTypes.Ok.Finalized) && _isPeriod(DataTypes.Period.None));
    }
    
    function _canConfigure() internal view returns (bool) {
        return (getState(DataTypes.Ok.BasicSetup) && !getState(DataTypes.Ok.Finalized) && _isPeriod(DataTypes.Period.Setup));
    }
    
    function _canTally() internal view returns (bool) {
        return (getState(DataTypes.Ok.Finalized) && !getState(DataTypes.Ok.Tally) && _isPeriod(DataTypes.Period.Setup));
    }
    
    function _isAborted() internal view returns (bool) {
        return _dataStore.finalState == DataTypes.FinalState.Aborted;
    }

    function _isLivePeriod() internal view returns (bool) {
        return (getState(DataTypes.Ok.Tally) && block.timestamp >= _dataStore.data.idoStart && block.timestamp < _dataStore.data.idoEnd);
    }
    
    function _isPeriod(DataTypes.Period period) internal view returns (bool) {
        return (period == getCurrentPeriod());
    }
    
    function _hasOpened() internal view returns (bool) {
        return (getState(DataTypes.Ok.Tally) && block.timestamp >= _dataStore.data.idoStart);
    }
    
    function _raisedAmount(bool deductFee) internal view returns (uint) {
        uint raised = _hasOpened() ? _dataStore.data.hardCap - getAllocLeftForLive() : 0;
        
        if (deductFee && _dataStore.data.feePcnt > 0) {
            raised = (raised * (Constant.PCNT_100 - _dataStore.data.feePcnt))/Constant.PCNT_100;
        }
        return raised;
    }
    
    function _getFeeAmount(uint totalAmount) internal view returns (uint) {
        return (totalAmount * _dataStore.data.feePcnt) / Constant.PCNT_100;
    }
    
    
    // Used to optimise bytecode size
    function _require(bool condition, Error.Code err) pure internal {
        require(condition, Error.str(err));
    }
}


// File contracts/interfaces/IRoleAccess.sol

//  BUSL-1.1

pragma solidity 0.8.10;

interface IRoleAccess {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}


// File contracts/interfaces/IRandomProvider.sol

//  BUSL-1.1

pragma solidity 0.8.10;


interface IRandomProvider {
    function requestRandom() external;
    function grantAccess(address campaign) external;
}


// File contracts/interfaces/IBnbOracle.sol

//  BUSL-1.1

pragma solidity 0.8.10;


interface IBnbOracle {
    function getRate(address currency) external view returns (int, uint8);
}


// File contracts/interfaces/IManager.sol

//  BUSL-1.1

pragma solidity 0.8.10;



interface IManager {
    function addCampaign(address newContract, address projectOwner) external;
    function getFeeVault() external view returns (address);
    function getSvLaunchAddress() external view returns (address);
    function getEggAddress() external view returns (address);
    function getRoles() external view returns (IRoleAccess);
    function getRandomProvider() external view returns (IRandomProvider);
    function getBnbOracle() external view returns (IBnbOracle);
}


// File contracts/interfaces/ILpProvider.sol

//  BUSL-1.1

pragma solidity 0.8.10;

interface ILpProvider {
    function getLpProvider(DataTypes.LpProvider provider) external view returns (address, address);
    function checkLpProviders(DataTypes.LpProvider[] calldata providers) external view returns (bool);
    function getWBnb() external view returns (address);
}


// File contracts/logic/Live.sol

//  BUSL-1.1

pragma solidity 0.8.10;


library Live {
    
    event SetupWhiteListFcfs(uint duration, uint[] minAmt, uint[] maxAmt);
    event AddRemoveWhitelistFcfs(address[] addresses, uint tier, bool add);

    // Note: At least 1 tier (min, max) is required
    function setupWhiteListFcfs(
        DataTypes.Live storage param,
        uint duration,
        uint[] calldata minAmt,
        uint[] calldata maxAmt) external {
        
        _require(minAmt.length > 0 && minAmt.length == maxAmt.length, Error.Code.InvalidArray);
    
        // Remove existing tiers if exists //
        uint len = param.data.tiers.length;
        for (uint n=0; n<len; n++) {
            param.data.tiers.pop();
        }
        
        param.data.whitelistFcfsDuration = duration;
        
        len = minAmt.length;
        for (uint n=0; n<len; n++) {
            param.data.tiers.push(DataTypes.Tier(minAmt[n], maxAmt[n]));
        }

        emit SetupWhiteListFcfs(duration, minAmt, maxAmt);
    }
    
     // Note: If a user appears in multiple whitelist tier, we will only take the first tier found
    function isWhitelisted(DataTypes.Live storage param, address user) public view returns (bool, uint) {
        uint len = param.data.tiers.length;
        for (uint n=0; n<len; n++) {
            if ( param.whitelistMap[n][user] == true ) {
                return (true, n);
            }
        }
        return (false,0);
    }
    
    // bool : whitelisted
    // uint : tier
    // uint : min buy limit
    // uint : max buy limit
    function getUserWhitelistInfo(DataTypes.Live storage param, address user) public view returns (bool, uint, uint, uint) {
        (bool whitelisted, uint tierNum) =  isWhitelisted(param, user);
        if (whitelisted) {
            DataTypes.Tier memory tier = param.data.tiers[tierNum];
            return (true, tierNum, tier.minBuyAmount, tier.maxBuyAmount);
        }
        return (false,0,0,0);
    }
    
    function addRemoveWhitelistFcfs(DataTypes.Live storage param, address[] calldata addresses, uint tier, bool add) external {
        uint len = addresses.length;
        _require(len>0 && tier<param.data.tiers.length, Error.Code.ValidationError);
        
        for (uint n=0; n<len; n++) {
            param.whitelistMap[tier][addresses[n]] = add;
        }

        emit  AddRemoveWhitelistFcfs(addresses, tier, add);
    }
    
    function getAllocLeftForLive(DataTypes.Live storage param) public view returns (uint) {
        if (param.allocSoldInLiveSoFar > 0) {
            return param.allocLeftAtOpen - param.allocSoldInLiveSoFar;
        }
        return param.allocLeftAtOpen;
    }
    
    // Returns the fundAmt
    function buyTokens(DataTypes.Store storage store, uint fund, bool isWhitelistPeriod) external {
        bool whitelisted;
        uint minLimit;
        uint maxLimit;
        uint bought;

        DataTypes.Live storage live = store.live;
        DataTypes.Data storage data = store.data;
        
        if (isWhitelistPeriod) {
            ( whitelisted, , minLimit, maxLimit) = getUserWhitelistInfo(live, msg.sender);
            _require(whitelisted, Error.Code.NotWhitelisted);
            bought = live.whitelistPurchases[msg.sender];
        } else {
            (minLimit, maxLimit) = (data.minBuyLimitPublic, data.maxBuyLimitPublic);
            bought = live.publicPurchases[msg.sender];
        }
        
        // If the amount of tokens left for sales is less than minLimit, it is ok to buy
        if (getAllocLeftForLive(live) > minLimit) {
            _require(fund >= minLimit, Error.Code.ValidationError);
        }
        _require(fund <= maxLimit, Error.Code.ValidationError);
    
        if (data.currency == address(0)) {
            _require(fund==msg.value, Error.Code.WrongValue);
        }
        
        // Are we able to buy or exceeded limit ?
        // User can buy in WL round and then public round 
        uint finalAmount =  bought + fund;
        _require(finalAmount <= maxLimit, Error.Code.ValueExceeded);
        
        // Proceed to buy 
        if (isWhitelistPeriod) {
            live.whitelistPurchases[msg.sender] = finalAmount;
        } else {
            live.publicPurchases[msg.sender] = finalAmount;
        }

        live.allocSoldInLiveSoFar += fund;
    }
    
    function _require(bool condition, Error.Code err) pure private {
        require(condition, Error.str(err));
    }
}


// File contracts/logic/Vesting.sol

//  BUSL-1.1

pragma solidity 0.8.10;




library Vesting {
    
    using Math for uint256;
    
    event SetupVestingPeriods(
        DataTypes.VestingReleaseType teamReleaseType,
        uint desiredUnlockTime,
        uint[] teamLockPcnts,   
        uint[] teamLockDurations
    );

    function setup(
        DataTypes.Vesting storage param,
        DataTypes.VestingReleaseType teamReleaseType,
        uint desiredUnlockTime,
        uint[] calldata teamLockPcnts,
        uint[] calldata teamLockDurations
    ) external {
        _require( (teamLockPcnts.length > 0) &&
            (teamLockPcnts.length == teamLockDurations.length) && 
            (desiredUnlockTime > 0), Error.Code.ValidationError);
        
        // If the release type is ByLinearContinuous, then we will have only 1 item in the array of tokens, durations 
        if (teamReleaseType == DataTypes.VestingReleaseType.ByLinearContinuous) {
            _require(teamLockPcnts.length == 1, Error.Code.SingleItemRequired);
        }
        
        param.data.desiredUnlockTime = desiredUnlockTime;
        param.data.teamLock.pcnts = teamLockPcnts;
        param.data.teamLock.durations = teamLockDurations;
        param.data.teamLock.releaseType = teamReleaseType;

         emit SetupVestingPeriods( 
             teamReleaseType, 
             desiredUnlockTime, 
             teamLockPcnts, 
             teamLockDurations
        );
    }
    
    // Note: This is used to override the desiredUnlockTime to current time. This is triggered from AddAndLockLP only.
    function setVestingTimeNow(DataTypes.Vesting storage param) external {
        // Vesting unlock time should not have started yet
        _require(param.data.desiredUnlockTime > block.timestamp, Error.Code.ValidationError);
        param.data.desiredUnlockTime = block.timestamp;
    }
    
    
    // uint claimedSoFar; // 1E6 means 100%
    // uint claimable;    // 1E6 means 100%
    // uint lockedAmount;  // 1E6 means 100%
    // uint newStartTime;
    // uint endTime;
    function getClaimableByLinear(DataTypes.Vesting storage param, address user) public view returns (DataTypes.ClaimLinearResult memory) {
        DataTypes.ClaimLinearResult memory result;
         
        DataTypes.LockInfo storage lock = param.data.teamLock;
        if (lock.releaseType != DataTypes.VestingReleaseType.ByLinearContinuous ||
            lock.durations.length == 0 ||
            lock.durations[0] == 0 ||
            block.timestamp < param.data.desiredUnlockTime) {
            return result;
        }
        
        result.newStartTime = block.timestamp;
        result.endTime = param.data.desiredUnlockTime + lock.durations[0];
        
        DataTypes.ClaimInfo storage item =  param.claims.team[user];
        uint timeElapsed = block.timestamp - param.data.desiredUnlockTime;
        uint totalClaimPointer = Math.min(Constant.PCNT_100, (Constant.PCNT_100 * timeElapsed) / lock.durations[0]); // 1E6 means 100%
        result.claimedSoFar = item.amount;
        result.claimable = totalClaimPointer - item.amount; // 1E6 means 100% //
        result.lockedAmount = Constant.PCNT_100 - totalClaimPointer;
        
        return result;
    }


    // uint claimedSoFar;   // 1E6 means 100%
    // uint claimable;      // 1E6 means 100%
    // uint nextLockedAmount;// 1E6 means 100%
    // uint claimStartIndex;
    // uint numClaimableSlots;
    // uint nextUnlockIndex;
    // uint nextUnlockTime;
    function getClaimableByIntervals(DataTypes.Vesting storage param, address user) public view returns (DataTypes.ClaimIntervalResult memory) {
        DataTypes.ClaimIntervalResult memory result;
        
        DataTypes.LockInfo storage lock = param.data.teamLock;
        if (lock.releaseType != DataTypes.VestingReleaseType.ByIntervals ||
            block.timestamp < param.data.desiredUnlockTime ||
            lock.durations.length == 0) {
            return result;
        }
         
        DataTypes.ClaimInfo storage item =  param.claims.team[user];
        
        result.claimedSoFar = item.amount;
        uint startIndex = firstFalseIndex(item.claimed);
        result.claimStartIndex = startIndex;
        
        // Find the claimable info
        uint len = lock.durations.length;
        uint lockedSlotIndex = len; // default at the end+1 of the array //
        for (uint n=startIndex; n< len; n++) {
            if (block.timestamp >= (param.data.desiredUnlockTime + lock.durations[n])) {
                result.claimable += lock.pcnts[n];
                result.numClaimableSlots++;
            } else {
                lockedSlotIndex = n;
                break;
            }
        }
        
        if ( lockedSlotIndex < len) {
            result.nextLockedAmount = lock.pcnts[lockedSlotIndex];
            result.nextUnlockIndex = lockedSlotIndex;
            result.nextUnlockTime = param.data.desiredUnlockTime + lock.durations[lockedSlotIndex];
        }
        return result;
    }

    function scaleBy(DataTypes.ClaimIntervalResult memory param, uint amount) external pure returns (DataTypes.ClaimIntervalResult memory) {
        param.claimedSoFar = (param.claimedSoFar*amount)/Constant.PCNT_100;
        param.claimable = (param.claimable*amount)/Constant.PCNT_100;
        param.nextLockedAmount = (param.nextLockedAmount*amount)/Constant.PCNT_100;
        return param;
    }

    function scaleBy(DataTypes.ClaimLinearResult memory param, uint amount) external pure returns (DataTypes.ClaimLinearResult memory) {
        param.claimedSoFar = (param.claimedSoFar*amount)/Constant.PCNT_100;
        param.claimable = (param.claimable*amount)/Constant.PCNT_100;
        param.lockedAmount = (param.lockedAmount*amount)/Constant.PCNT_100;
        return param;
    }
    
    function updateClaim(DataTypes.Vesting storage param, address user) external returns (uint) {
        bool ok;
        uint releasePcnt;
        DataTypes.LockInfo storage lock = param.data.teamLock;
        DataTypes.ClaimInfo storage item = param.claims.team[user];
         
        if (lock.releaseType == DataTypes.VestingReleaseType.ByLinearContinuous) {
            if (lock.durations[0] > 0) {
              
                DataTypes.ClaimLinearResult memory result = getClaimableByLinear(param, user);
                releasePcnt = result.claimable;
                ok = true;
            }
        } else {
            
            DataTypes.ClaimIntervalResult memory result = getClaimableByIntervals(param, user);
            // Check to make sure the specified claim index is same as underlying data
            if (result.numClaimableSlots > 0) {
                uint from = result.claimStartIndex;
                uint to = result.claimStartIndex + result.numClaimableSlots - 1;
                // Check whether claimed before ?
                _require(from == item.claimed.length, Error.Code.AlreadyClaimed);
                    
                for (uint n=from; n<=to; n++) {
                    item.claimed.push(true);
                }
                releasePcnt = result.claimable;
                ok = true;
            }
        }
        item.amount += releasePcnt;
        _require(ok, Error.Code.ClaimFailed);
        return (releasePcnt);
    }
    
    function hasTeamVesting(DataTypes.Vesting storage param) external view returns (bool) {
        return (param.data.teamLock.pcnts.length > 0);
    }
    
    function firstFalseIndex(bool[] storage values) private view returns (uint) {
        uint len = values.length;
        for (uint n=0; n<len; n++) {
            if(values[n] == false) {
                return n;
            }
        }
        return len;
    }
    
    function _require(bool condition, Error.Code err) pure private {
        require(condition, Error.str(err));
    }
}


// File contracts/interfaces/IUniswapV2Router02.sol

//  BUSL-1.1

pragma solidity 0.8.10;

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    

    function WETH() external pure returns (address);
 
  
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


// File contracts/interfaces/IUniswapV2Factory.sol

//  BUSL-1.1

pragma solidity 0.8.10;


interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


// File contracts/logic/LpProvision.sol

//  BUSL-1.1

pragma solidity 0.8.10;









library LpProvision {
    
    using SafeERC20 for ERC20;
                
    event SetupLP(
        DataTypes.LpSize size,
        uint sizeParam,
        uint rate, 
        uint softCap,
        uint hardCap,
        address tokenA,
        address currency,
        bool swapToBnbBasedLp
    );

    event SetupLPLocks(
        DataTypes.LpProvider[] providers, 
        uint[] splits, 
        uint[] lockPcnts, 
        uint[] lockDurations,
        ILpProvider provider
    );

    event SwapCurrencyToWBnb(
        uint fundAmt, 
        uint minWBnbAmountOut, 
        ILpProvider provider
    );

    function setup(
        DataTypes.Lp storage param,
        DataTypes.LpSize size,
        uint sizeParam,         // Used for LpSize.MaxCapped. 
        uint rate, 
        uint softCap,
        uint hardCap,
        address tokenA,
        address currency,
        bool swapToBnbBasedLp
    ) external 
    {
         // Make sure that the project token is valid address
        _require(tokenA != Constant.ZERO_ADDRESS, Error.Code.ValidationError);

        reset(param); // If we have previously setupLP, we will reset it.

        param.data.size = size;
        param.data.sizeParam = sizeParam;
        param.data.rate = rate;
        param.data.softCap = softCap;
        param.data.hardCap = hardCap;
        param.data.tokenA = tokenA;
        param.data.currency = currency;
        param.enabled = true;
                
        // Need swap before LP provision ?
        // Currently, we only support swap from raised currency to BNB
        param.swap.needSwap = swapToBnbBasedLp;

        emit SetupLP( size, sizeParam, rate, softCap, hardCap, tokenA, currency, swapToBnbBasedLp);
    }
    
    function setupLocks(
        DataTypes.Lp storage param,
        DataTypes.LpProvider[] calldata providers,  // Support multiple LP pools
        uint[] calldata splits,                     // The % splits going into these LP pools
        uint[] calldata lockPcnts, 
        uint[] calldata lockDurations,
        ILpProvider provider
    ) external
    {
        uint len = providers.length;
        _require(len > 0 && len == splits.length && isTotal100Percent(splits), Error.Code.ValidationError);
        
        // Cache router & factory
        address router;
        address factory;
        for (uint n=0; n<len;n++) {
            (router, factory) = provider.getLpProvider(providers[n]);
            param.data.routers.push(router);
            param.data.factory.push(factory);
        }
        
        len = lockPcnts.length;
        _require(len > 0 && len == lockDurations.length && isTotal100Percent(lockPcnts), Error.Code.ValidationError);
        
        param.data.splits = splits;
        param.locks.pcnts = lockPcnts;
        param.locks.durations = lockDurations;
        
        for (uint n=0; n<len;n++) {
            param.result.claimed.push(false);
        }
        emit   SetupLPLocks( providers, splits, lockPcnts, lockDurations, provider);
    }
    
    function reset(DataTypes.Lp storage param) private {
        // Reset if exists
        uint len = param.data.routers.length;
        for (uint n = 0; n< len; n++) {
            param.data.routers.pop();
            param.data.factory.pop();
        }
      
        len = param.locks.pcnts.length;
        for (uint n = 0; n< len; n++) {
            param.locks.pcnts.pop();
            param.locks.durations.pop();
            param.result.claimed.pop();
        }
        param.enabled = false;
    }
    
    // Note: when ignoreSwap is set to true, then we can create LP without strictly requiring a swap to BNB (which can fail)
    function create(DataTypes.Lp storage param, uint fundAmt, bool bypassSwap) external returns (uint, uint) {
        
        // Safety check
        if (!bypassSwap && param.swap.needSwap) {
            _require(param.swap.swapped, Error.Code.CannotCreateLp);
        }
        
        _require(param.enabled, Error.Code.NotEnabled);
        _require(!param.result.created, Error.Code.AlreadyCreated);
        param.result.created = true;
        
        
        // bool bnbBase = param.swap.swapped || param.data.currency == address(0);
        (uint totalTokens, uint totalFund) = getRequiredTokensQty(param, fundAmt);
        
        // If we have swapped to bnb currency using PCS, then we use the swapped BNB amount
        bool usesWBnb;
        if (param.swap.swapped) {
            totalFund = param.swap.newCurrencyAmount;
            usesWBnb = true;
        }
        
        // Create each LP 
        uint tokensRequired;
        uint fundRequired;
        uint len = param.data.routers.length;

        for (uint n=0; n<len; n++) {
            tokensRequired = (param.data.splits[n] * totalTokens) / Constant.PCNT_100;
            fundRequired = (param.data.splits[n] * totalFund) / Constant.PCNT_100;
            
            (bool ok, uint tokenUsed, uint currencyUsed) = create1LP(param, n, tokensRequired, fundRequired, usesWBnb);
            _require(ok, Error.Code.CannotCreateLp);
            totalTokens -= tokenUsed;
            totalFund -= currencyUsed;
        }
        
        // Lock if needed
        if (param.locks.durations.length > 0) {
             param.locks.startTime = block.timestamp;
        }
        
        // Returns the amount of un-used tokens and funds.
        return (totalTokens, totalFund);
    }
    
    function create1LP(DataTypes.Lp storage param, uint index, uint tokenAmt, uint fundAmt, bool useWBnb) private returns (bool, uint, uint) {
        
        address router = param.data.routers[index];

        if (!ERC20(param.data.tokenA).approve(router, tokenAmt)) { return (false,0,0); } // Uniswap doc says this is required //
 
        uint tokenAmtUsed;
        uint currencyAmtUsed;
        uint lpTokenAmt;
        // Using native BNB ?
        if ( !useWBnb && param.data.currency == address(0)) {
            
            (tokenAmtUsed, currencyAmtUsed, lpTokenAmt) = IUniswapV2Router02(router).addLiquidityETH
                {value : fundAmt}
                (param.data.tokenA,
                tokenAmt,
                0,
                0,
                address(this),
                block.timestamp + 100000000);
                
        } else {
            
            address tokenB = useWBnb ? IUniswapV2Router02(router).WETH() : param.data.currency;
            if (!ERC20(tokenB).approve(router, fundAmt)) { return (false,0,0); } // Uniswap doc says this is required //
       
            (tokenAmtUsed, currencyAmtUsed, lpTokenAmt) = IUniswapV2Router02(router).addLiquidity
                (param.data.tokenA,
                tokenB,
                tokenAmt,
                fundAmt,
                0,
                0,
                address(this),
                block.timestamp + 100000000);
        }
        
        param.result.tokenAmountUsed.push(tokenAmtUsed);
        param.result.currencyAmountUsed.push(currencyAmtUsed);
        param.result.lpTokenAmount.push(lpTokenAmt);
        return (true, tokenAmtUsed, currencyAmtUsed);
    }


    // Use PCS to swap the base currency into BNB
    function swapCurrencyToWBnb(DataTypes.Lp storage param, uint fundAmt, uint maxSlippagePercent, IBnbOracle oracle, ILpProvider provider) external returns (bool) {
        
        // Can only swap 1 time successfully
        _require(param.swap.needSwap && !param.swap.swapped, Error.Code.ValidationError);
        _require( maxSlippagePercent <= Constant.BNB_SWAP_MAX_SLIPPAGE_PCNT, Error.Code.SwapExceededMaxSlippage);

        // Use pancakeswap to swap
        (address router, ) = provider.getLpProvider(DataTypes.LpProvider.PancakeSwap);
    
        address wbnb = IUniswapV2Router02(router).WETH();
        if (param.data.currency == address(0) || param.data.currency == wbnb) {
            return false;
        }
        
        address[] memory path = new address[](2);
        path[0] = param.data.currency;
        path[1] = wbnb;
        
        (int rate, uint8 dp) = oracle.getRate(param.data.currency);
        uint minWBnbOut = (fundAmt * uint(rate) * (Constant.PCNT_100 - maxSlippagePercent)) / (10**dp * Constant.PCNT_100);

        if (!ERC20(param.data.currency).approve(router, fundAmt)) { return false; }
        
        (uint[] memory amounts) = IUniswapV2Router02(router).swapExactTokensForTokens(
            fundAmt,
            minWBnbOut,
            path,
            address(this),
            block.timestamp + 100000000);
           
        _require(amounts.length == 2, Error.Code.InvalidArray);
        
        // Update
        param.swap.swapped = true;
        param.swap.newCurrencyAmount = amounts[1];

        emit SwapCurrencyToWBnb(fundAmt, minWBnbOut, provider);
        return true;
    }

  

    
    // Note: This is the max amount needed. Any extra will be refunded.
    function getMinMaxFundRequiredForLp(DataTypes.Lp storage param) private view returns (uint, uint) {
        if (param.enabled) {
            if (param.data.size == DataTypes.LpSize.Min) {
                return (param.data.softCap, param.data.softCap);
            } else if (param.data.size == DataTypes.LpSize.Max) {
                return (param.data.softCap, param.data.hardCap);
            } else if (param.data.size == DataTypes.LpSize.MaxCapped) {
                uint cap = (param.data.hardCap * param.data.sizeParam) / Constant.PCNT_100;
                return (param.data.softCap, cap);
            }
        }
        return (0,0);
    }
    
    
    // Note : Find out how many tokens and fund are required for the LP provision
    function getRequiredTokensQty(DataTypes.Lp storage param, uint fundAmt) public view returns (uint, uint) {
        (, uint max) = getMinMaxFundRequiredForLp(param);
      
        uint lpFund = (fundAmt > max) ? max : fundAmt; // Useful for .maxCapped mode
        uint lpTokens = (lpFund * param.data.rate) / Constant.VALUE_E18;
        return (lpTokens, lpFund);
    }
    
    // Find out the max amount of tokens and fund required for the LP provision
    function getMaxRequiredTokensQty(DataTypes.Lp storage param) public view returns (uint, uint) {
       ( ,uint max) = getMinMaxFundRequiredForLp(param);
       return getRequiredTokensQty(param, max);
    }
    
    function isLockExpired(DataTypes.Lp storage param, uint index) public view returns (bool) {
        uint len = param.locks.durations.length;
        
        _require(index < len, Error.Code.InvalidIndex);
        return ( block.timestamp > (param.locks.startTime + param.locks.durations[index]));
    }
    
    function getunlockAmt(DataTypes.Lp storage param, uint provider, uint index) public view returns (uint) {
        uint totalLp = param.result.lpTokenAmount[provider];
        uint pcnt = param.locks.pcnts[index];
        uint amount = (pcnt * totalLp) / Constant.PCNT_100;
    
        return amount;
    }
    
    function isClaimed(DataTypes.Lp storage param, uint index) public view returns (bool) {
        return param.result.claimed[index];
    }
    
    function claimUnlockedLp(DataTypes.Lp storage param, uint index) external returns (uint amount) {
        _require(isLockExpired(param, index), Error.Code.NotReady);
        _require(!isClaimed(param, index), Error.Code.AlreadyClaimed);
        
        uint len = param.data.routers.length;
         
        address lpToken;
        address tokenB;
        uint releaseAmt;
        uint temp;
            
        for (uint n=0; n<len; n++) {
            
            address router = param.data.routers[index];
            address factory = param.data.factory[index];
            
            tokenB = param.data.currency;
            if (tokenB == address(0) || param.swap.swapped) {
                tokenB = IUniswapV2Router02(router).WETH();
            }
        
            lpToken = IUniswapV2Factory(factory).getPair(param.data.tokenA, tokenB);
            
            temp = getunlockAmt(param, n, index);
            releaseAmt += temp;

            ERC20(lpToken).safeTransfer(msg.sender, temp);
        }
        // Update
        param.result.claimed[index] = true;
        return (releaseAmt) ;
    }
    
    function isTotal100Percent(uint[] calldata amounts) private pure returns (bool) {
        uint temp;
        uint len = amounts.length;
        for (uint n=0; n<len; n++) {
            temp += amounts[n];
        }
        return temp==Constant.PCNT_100;
    }
        
    function _require(bool condition, Error.Code err) pure private {
        require(condition, Error.str(err));
    }
}


// File contracts/logic/History.sol

//  BUSL-1.1


pragma solidity 0.8.10;

library History {
    
    function record(DataTypes.History storage param, DataTypes.ActionType actType, address user, uint data1, bool isInvestor) internal {
       record(param, actType, user, data1, 0, isInvestor);
    }
    
    function record(DataTypes.History storage param, DataTypes.ActionType actType, address user, uint data1, uint data2, bool isInvestor) internal {
        DataTypes.Action memory act = DataTypes.Action(uint128(actType), uint128(block.timestamp), data1, data2);
        if (isInvestor) {
            param.investor[user].push(act);

            // Record unique users
            if (!param.invested[user]) {
                param.invested[user] = true;
                param.allInvestors.push(user);
            }
        } else {
            param.campaignOwner[user].push(act);
        }
    }
}


// File contracts/core/MainWorkflow.sol

//  BUSL-1.1

pragma solidity 0.8.10;













contract MainWorkflow is DataStore, ReentrancyGuard {
    
    using SafeERC20 for ERC20;
    using Generic for *;
    using Guaranteed for *;
    using Lottery for DataTypes.Lottery;
    using OverSubscribe for DataTypes.OverSubscriptions;
    using Live for *;
    using Vesting for *;
    using LpProvision for DataTypes.Lp;
    using History for DataTypes.History;

    IManager internal _manager;
    address internal _campaignOwner; 
  
    modifier notAborted() {
        _require(!_isAborted(), Error.Code.Aborted);
        _;
    }
    
    constructor(IManager manager, address campaignOwner) {
        _manager = manager;
        _campaignOwner = campaignOwner;
    }
    
    //--------------------//
    // EXTERNAL FUNCTIONS //
    //--------------------//
   

    // uint : Guaranteed Amount or Lottery Amount
    // bool : bool guaranteed or pending
    // uint : over-subscribe max amount
    function getSubscribable(address user) external view returns (uint amount, bool guaranteed, uint overSubAmt) {
        if (getState(DataTypes.Ok.Finalized)) {
            (amount, guaranteed) = _store().getGuaranteedAmt(user);
            overSubAmt = _store().overSubscription.data.stdOverSubQty;
        }
    }

    function subscribe(uint amtBasic, uint amtOverSub, uint priority, uint eggTotalQty) external payable {
        DataTypes.Subscriptions storage subs = _subscriptions();
        bool subscribed = subs.items[msg.sender].paidCapital != 0; 
        uint capital = amtBasic + amtOverSub;
        
        _require(!_isAborted() && !subscribed && capital > 0 && _isPeriod(DataTypes.Period.Subscription), Error.Code.ValidationError);
        _transferIn(capital, DataTypes.FundType.Currency);
        
        // Try to subscribe with checks on amounts 
        (uint maxAlloc, bool isGuaranteed) = _store().getGuaranteedAmt(msg.sender);
        
        if (isGuaranteed) {
            _guaranteed().subscribe(amtBasic, maxAlloc);
        } else {
            _lottery().subscribe(amtBasic);
        }
   
        // Over-subscribe & Egg transfer in. 
        if (amtOverSub > 0) {
            _overSubscriptions().subscribe(amtOverSub, priority, eggTotalQty);
            _transferIn(eggTotalQty, DataTypes.FundType.Egg);
        }
      
        // Record
        _recordSubscription(subs, capital);
        
        // History
        // Data1 : Bit 0: Guaranteed | Bit 1 onwards: Amount in Currency
        // Data2 : 120 bits: OverSub Amt, 120 bits: EggBurnAmt, 16 bits: Priority 
         _require(amtBasic <= type(uint256).max >> 1 && amtOverSub <= type(uint120).max && priority <= type(uint16).max && eggTotalQty <= type(uint120).max, Error.Code.ValidationError);
         uint pack1 = (amtBasic << 1) | (isGuaranteed ? 1 : 0);
         uint pack2 = (amtOverSub) | (eggTotalQty << 120) | (priority << 240);
        _history().record(DataTypes.ActionType.Subscribe, msg.sender, pack1, pack2, true);
    }
    
    function getSubscriptionResult(address user) external view returns (DataTypes.SubscriptionResultParams memory p) {
        if (getState(DataTypes.Ok.Tally)) {
            p = _store().getSubscriptionResult(user);
        }
    }
    
    function getSubscription(address user) external view returns (DataTypes.SubscriptionParams memory p) {
        (p.guaranteedAmount, p.guaranteed) = _store().getGuaranteedSubscription(user);
        p.inLottery = _lottery().items[user].exist;
        p.lotteryAmount = _lottery().data.eachAllocationAmount;
        (, p.overSubAmount, p.priority, p.eggBurnAmount) = _overSubscriptions().getSubscription(user);
    }
    
    function getSubscribersCount() external view returns (uint) {
        return _subscriptions().count;
    }
    
    function getUserWhitelistInfo(address user) external view returns (bool, uint, uint, uint) {
        return _live().getUserWhitelistInfo(user);
    }
    
    function getHistory(address user, bool investor) external view returns (DataTypes.Action[] memory) {
        return (investor ?  _history().investor[user] : _history().campaignOwner[user]);
    }
    
    // Note: finishUp can only be called once
    // If a campaign is aborted, the campaignOwner will have o call fundOut() to get back their tokens.
    function finishUp() external nonReentrant {
        
         // Can call finishUp only after Public IDO ended OR hardCap is met //
         bool ok = (!_isAborted() && 
            !getState(DataTypes.Ok.FinishedUp) &&
            (_isPeriod(DataTypes.Period.IdoEnded) || (_hasOpened() && _live().getAllocLeftForLive() == 0)) );
         _require(ok, Error.Code.ValidationError);
        
        // Set state. Only called once.
        _setState(DataTypes.Ok.FinishedUp, true);
   
        // Dev note: The fund-in amount is only for LP provision
        uint fundInTokens = getFundInTokenRequired();
        
        // Has met SoftCap ?
        (bool softCapMet, uint fee, uint totalAfterFeeLp, uint unusedLpTokensQty) = _getFinishUpStats();
        _store().finalState = softCapMet ?  DataTypes.FinalState.Success : DataTypes.FinalState.Failure;    
        
        if (softCapMet) {
            // Send fee
            _transferOut(_manager.getFeeVault(), fee, DataTypes.FundType.Currency);
        
            // Project owner can get back the raised proceeding if there's no team vesting
            if (!_vesting().hasTeamVesting() ) {
                _transferOut(_campaignOwner, totalAfterFeeLp, DataTypes.FundType.Currency);
            } else {
                _vesting().data.teamLockAmount = totalAfterFeeLp;
            }
        
            // Return unused-lp tokens
            _transferOut(_campaignOwner, unusedLpTokensQty, DataTypes.FundType.Token);
        
            // Burn Used Eggs in over-subscription 
            uint burnAmt = _overSubscriptions().getBurnableEggsAfterTally();
            if (burnAmt>0) {
                ERC20Burnable(_manager.getEggAddress()).burn(burnAmt);
            }
        } else {
            // Refund all fundIn tokens to campaign Owner
            _transferOut(_campaignOwner, fundInTokens, DataTypes.FundType.Token);
        }
    }
    
    function buyTokens(uint fund) external payable {
        uint available = getAllocLeftForLive();
        _require(!_isAborted() && _isLivePeriod() && fund > 0 && available > 0 && fund <= available, Error.Code.CannotBuyToken);
        _store().buyTokens(fund, _isPeriod(DataTypes.Period.IdoWhitelisted));
    
        _transferIn(fund, DataTypes.FundType.Currency);
        _history().record(DataTypes.ActionType.BuyTokens, msg.sender, fund, true);
    }

     // Refund any excess/un-used fund from subscription //
    function refundExcess() external nonReentrant {
        (bool refunded, uint capital, uint egg) = getRefundable(msg.sender);
        _require(!refunded && getState(DataTypes.Ok.Tally), Error.Code.CannotRefundExcess);

        _subscriptions().items[msg.sender].refundedUnusedCapital = true;
        _history().record(DataTypes.ActionType.RefundExcess, msg.sender, capital, egg, true);

        _transferOut(msg.sender, capital, DataTypes.FundType.Currency);
        _transferOut(msg.sender, egg, DataTypes.FundType.Egg);
    }
    
    // Note: when a campaign did not hit softCap, or cancelled, users get a full refund.
    function returnFund() external nonReentrant {
        _require( (_store().finalState == DataTypes.FinalState.Failure ||
            _store().finalState == DataTypes.FinalState.Aborted) && 
            _store().returnFunds.amount[msg.sender]==0, Error.Code.CannotReturnFund);
      
        bool hasTally = getState(DataTypes.Ok.Tally);
        // If not yet Tally (eg when a  campaign is cancelled before Tally is called), we also need to return the subscription
        DataTypes.PurchaseDetail memory purchase = getPurchaseDetail(msg.sender, !hasTally);
    
        // Get total user purchase in currency
        uint total = purchase.total;
            
        if (total > 0) {
            _transferOut(msg.sender, total, DataTypes.FundType.Currency);
                
            uint egg;
            if (hasTally) {
                // Returns Egg if user has successfully subscribed in Over-subscription & Tally
                egg = _overSubscriptions().getBurnableEggs(msg.sender);
            } else {
                // if a campaign is cancelled before Tally, we need to return the egg amount
                (, , , egg) = _overSubscriptions().getSubscription(msg.sender);
            }
            _transferOut(msg.sender, egg, DataTypes.FundType.Egg);
                
            // Update 
           _store().returnFunds.amount[msg.sender] = total;
           
           _history().record(DataTypes.ActionType.ReturnFund, msg.sender, total, egg, true);
        }
    }
    
    function getClaimableByIntervals(address user) external view returns (DataTypes.ClaimIntervalResult memory) {
        uint total = _vesting().data.teamLockAmount;
        return _vesting().getClaimableByIntervals(user).scaleBy(total);
    }
    
    function getClaimableByLinear(address user) external view returns (DataTypes.ClaimLinearResult memory) {
        uint total = _vesting().data.teamLockAmount;
        return _vesting().getClaimableByLinear(user).scaleBy(total);
    }
    
    
    //--------------------//
    // PUBLIC FUCNTIONS   //
    //--------------------//
    
    function getFundInTokenRequired() public view  returns(uint) {
        (uint lpTokensNeeded, ) = _lp().getMaxRequiredTokensQty();
        return lpTokensNeeded;
    }
    
    function getPurchaseDetail(address user, bool includeRefundable) public view returns (DataTypes.PurchaseDetail memory) {
        return _store().getPurchaseDetail(user, getState(DataTypes.Ok.Tally), includeRefundable);
    }
    
    // uint : Amount subscribed by Guaranteed
    // uint : Max amount from lottery
    // uint : Max amount from over-subscribe
    function peekTally() public view returns (uint, uint, uint) {
        return (_guaranteed().totalSubscribed, _lottery().getTotal(), _overSubscriptions().getTotal());
    }
    
    // bool : refunded ?
    // uint : Refundable capital (if not yet refund), or the refunded Amount
    // uint : Refundable eggs (if not yet refund), or the refunded Eggs
    function getRefundable(address user) public view returns(bool refunded, uint capital, uint eggs) {
        // can only refund when tally is done //
        if (getState(DataTypes.Ok.Tally)) {
            refunded = _subscriptions().items[user].refundedUnusedCapital;
        
            uint lotteryRefund = _lottery().getRefundable(user);
            (capital, eggs) = _overSubscriptions().getRefundable(user);
            capital += lotteryRefund;
        }
    }
    
    // Get the fund currency needed for the LP provision. This amount is "after fee"
    function getLpFund() public view returns (uint fund) {
        (, fund) = _lp().getRequiredTokensQty(_raisedAmount(true));
    }
    
    //--------------------//
    // INTERNAL FUNCTIONS //
    //--------------------//
    
    function _fundIn(uint amtAcknowledged) internal {
        _require(!getState(DataTypes.Ok.FundedIn) &&
            getState(DataTypes.Ok.Finalized) &&
            _isPeriod(DataTypes.Period.Setup) &&
            getFundInTokenRequired() == amtAcknowledged, Error.Code.ValidationError);

        _setState(DataTypes.Ok.FundedIn, true);
        _transferIn(amtAcknowledged, DataTypes.FundType.Token);
        _history().record(DataTypes.ActionType.FundIn, msg.sender, amtAcknowledged, false);
    }
    
    // Note : CampaignOwner can fund out in these situations
    // 1. During setup Period
    // 2. When IDO ended & softcap not met 
    // 3. Aborted campaign
    function _fundOut(uint amtAcknowledged) internal nonReentrant {
        _require( getState(DataTypes.Ok.FundedIn) && 
            (_isPeriod(DataTypes.Period.Setup) || _store().finalState == DataTypes.FinalState.Failure || _isAborted()) && 
            getFundInTokenRequired() == amtAcknowledged, Error.Code.ValidationError);
      
        _setState(DataTypes.Ok.FundedIn, false);
        _transferOut(msg.sender, amtAcknowledged, DataTypes.FundType.Token);
        _history().record(DataTypes.ActionType.FundOut, msg.sender, amtAcknowledged, false);
    }

    
    //--------------------//
    // INTERNAL FUCNTIONS //
    //--------------------//

    function _tallySubscription(uint splitRatio) internal {
        _require(_canTally() && splitRatio<=Constant.PCNT_100, Error.Code.ValidationError);
        
        // Amount left after Guranteed has gotten their allocation
        uint amtLeft = _data().hardCap - _guaranteed().totalSubscribed;

        // Split the amount according to the splitRatio sent in by FE/Deployer
        uint amtForLottery = (amtLeft * splitRatio) / Constant.PCNT_100;
 
        // allocate to lottery & over-subcription
        _lottery().tally(amtForLottery);
        _overSubscriptions().tally(amtLeft - amtForLottery);

        // Final left over
        _live().allocLeftAtOpen = _lottery().getFinalLeftOver() + _overSubscriptions().getFinalLeftOver();
        _setState(DataTypes.Ok.Tally, true);
    }

    function _claim() internal nonReentrant {
        _claim(_vesting().updateClaim(msg.sender));
    }

    function _transferIn(uint amount, DataTypes.FundType fundType) internal {
        if (amount > 0) {
           
            if (fundType == DataTypes.FundType.Currency && _isBnbCurrency()) {
                _require(amount == msg.value, Error.Code.InvalidAmount);
            } else {
                ERC20(_getAddress(fundType)).safeTransferFrom(msg.sender, address(this), amount); 
            }
        }
    }
    
    function _transferOut(address to, uint amount, DataTypes.FundType fundType) internal  {
        _transferOut(to, _getAddress(fundType), amount);
    }
    
    function _transferOut(address to, address token, uint amount) internal  {
        
        if (amount > 0 && to != Constant.ZERO_ADDRESS) {
             
            if (token == Constant.ZERO_ADDRESS) {
                (bool success, ) = to.call{ value: amount}("");
                _require(success, Error.Code.ValidationError);
            } else {
                 ERC20(token).safeTransfer(to, amount); 
            }
        }
    }
    
    function _getLpInterface() internal view returns (ILpProvider) {
        return ILpProvider(address(_manager));
    }
    

    //--------------------//
    // PRIVATE FUCNTIONS //
    //--------------------//
    
    
    function _getAddress(DataTypes.FundType fundType) private view returns (address) {
        if (fundType == DataTypes.FundType.Currency) {
            return _data().currency;
        } else if (fundType == DataTypes.FundType.Token) {
            return _data().token;
        } else if (fundType == DataTypes.FundType.Egg) {
            return _manager.getEggAddress();
        } else if (fundType == DataTypes.FundType.WBnb) {
            return _getLpInterface().getWBnb();
        }
        return Constant.ZERO_ADDRESS;
    }
    
    // releasePcnt: 1E6 means 100%
    function _claim(uint releasePcnt) private {
        
        // Can only claim when softcap met
       _require(_store().finalState == DataTypes.FinalState.Success, Error.Code.SoftCapNotMet);
    
        uint total;
        if (releasePcnt>0) {
           
            total = (_vesting().data.teamLockAmount * releasePcnt) / Constant.PCNT_100;
            _transferOut(msg.sender, total, DataTypes.FundType.Currency);
            
            _history().record(DataTypes.ActionType.ClaimFund, msg.sender, total, 0, false);
        }
    }
    
    // bool : softcap met ?
    // uint : Fee amt : In currency unit
    // uint : TotalAfterFeeLp : Total raised, after deducting for fee & Lp. In currency unit
    // uint : UnusedLpTokensQty
    // uint : UnsoldTokensQty
    function _getFinishUpStats() private view returns(bool softCapMet, uint feeAmt, uint totalAfterFeeLp, uint unusedLpTokensQty) {

        uint total = getTotalAllocSold();
        
        // Has met SoftCap ?
        softCapMet = total >= _data().softCap;
        if (softCapMet) {
            if (_data().feePcnt > 0 ) {
                feeAmt = _getFeeAmount(total);
                total -= feeAmt;
            }
            
            // Deduct for LP ?
            DataTypes.Lp storage lp = _lp();
            if (lp.enabled) {
                
                (uint totalLpTokens, ) = _lp().getMaxRequiredTokensQty();
        
                // LP creation is based on the totalRaisedAmount after deducting for fee first
                (uint lpTokensUsed, uint lpFundUsed) = lp.getRequiredTokensQty(total);
                total -= lpFundUsed;
                unusedLpTokensQty = totalLpTokens - lpTokensUsed;
            }
        } 
        totalAfterFeeLp = total;
    }
    
    function _getTotalPurchased(address user) internal view returns (uint) {
        return getPurchaseDetail(user, false).total;
    }
    
    function _recordSubscription(DataTypes.Subscriptions storage param, uint capital) private {
        param.items[msg.sender] = DataTypes.SubItem(capital, false);
        param.count++ ;
    }
}


// File contracts/interfaces/ICampaign.sol

//  BUSL-1.1

pragma solidity 0.8.10;

interface ICampaign {
    function cancelCampaign() external;
    function daoMultiSigEmergencyWithdraw(address tokenAddress, address to, uint amount) external;
    function sendRandomValueForLottery(uint value) external;
}


// File contracts/CampaignWithDeed.sol

//  BUSL-1.1

pragma solidity 0.8.10;



contract CampaignWithDeed is ICampaign, MainWorkflow {

    using Generic for *;
    using Lottery for *;
    using Live for DataTypes.Live;
    using LpProvision for DataTypes.Lp;
    using Vesting for DataTypes.Vesting;
    using History for DataTypes.History;

    constructor(IManager manager, address campaignOwner) MainWorkflow(manager, campaignOwner) { }
    
    modifier init() {
        _require(_isConfigurator() && _canInitialize(), Error.Code.CannotInitialize);
        _;
        _setConfigApproved(false);
        _setState(DataTypes.Ok.BasicSetup, true);
    }
    
    modifier configure() {
        _require(_isConfigurator() && _canConfigure(), Error.Code.CannotConfigure);
        _;
        _setConfigApproved(false);
    }
    
    modifier onlyCampaignOwner() {
        _require(_campaignOwner == msg.sender, Error.Code.NoRights);
        _;
    }
     
    modifier onlyDeployer() {
        _require(_manager.getRoles().isDeployer(msg.sender), Error.Code.NoRights);
        _;
    }
    
    modifier campaignOwnerOrConfigurator() {
        _require(_campaignOwner == msg.sender || _isConfigurator(), Error.Code.NoRights);
        _;
    }

    event Finalize();
    event FundIn(uint amount);
    event FundOut(uint amount);
    event TallySubscriptionAuto();
    event TallySubscriptionManual(uint splitRatio);
    event AddAndLockLP(bool overrideStartVest, bool bypassSwap);
    event ClaimFunds();
    event ClaimUnlockedLP(uint index);
    
    //--------------------//
    // EXTERNAl FUNCTIONS //
    //--------------------//
    
    function initialize( 
        address token,
        uint[4] calldata dates, // subStart, subEnd, idoStart, idoEnd //
        uint[2] calldata caps, //softCap, hardCap
        uint tokenSalesQty,
        uint[4] calldata subInfo, // snapShotId, lotteryAmt, stdOverSubscribeAmt, eggBurnForOverSubscribe
        uint[2] calldata buyLimitsPublic, // the min and max buy limit for public round
        address currency,
        uint feePcnt
    ) external init {
        _store().initialize(token, dates, caps, tokenSalesQty, subInfo, buyLimitsPublic, currency, feePcnt, 
            _manager.getSvLaunchAddress(), _manager.getEggAddress());
    }
    
    function setupLp(
        DataTypes.LpSize size,
        uint sizeParam,
        uint rate, // in 1E18
        DataTypes.LpProvider[] calldata providers,
        uint[] calldata splits,
        uint[] calldata lockPcnts, 
        uint[] calldata lockDurations,
        bool swapToBnbBasedLp
    ) external configure {
        _lp().setup(size, sizeParam, rate, _data().softCap, _data().hardCap ,_data().token, _data().currency, swapToBnbBasedLp);
        _lp().setupLocks(providers, splits, lockPcnts, lockDurations, _getLpInterface());
    }
    
    function setupVestingPeriods(
        DataTypes.VestingReleaseType teamReleaseType,
        uint desiredUnlockTime,
        uint[] calldata teamLockPcnts,      // 1E6 is 100%
        uint[] calldata teamLockDurations
    ) external configure {
        _vesting().setup(teamReleaseType, desiredUnlockTime, teamLockPcnts, teamLockDurations);
    }

    function setupWhitelistFcfs(uint duration, uint[] calldata minAmt, uint[] calldata maxAmt) external configure {
        _live().setupWhiteListFcfs(duration, minAmt, maxAmt);
    }

    function approveConfig() external {
        _require (_manager.getRoles().isApprover(msg.sender) && getState(DataTypes.Ok.BasicSetup), Error.Code.ValidationError);
        _setConfigApproved(true);
    }
    
    function finalize() external onlyDeployer notAborted {
        _require(getState(DataTypes.Ok.Config), Error.Code.UnApprovedConfig);
        _setState(DataTypes.Ok.Finalized, true);
        emit Finalize();
    }
    
    // Dev Note: Fund in amount is only for the LP requirement. All token release will be from SuperDeed v2.
    function fundIn(uint amtAcknowledged) external onlyCampaignOwner {
        _fundIn(amtAcknowledged);
        emit FundIn(amtAcknowledged);
    }
    
    function fundOut(uint amtAcknowledged) external onlyCampaignOwner {
        _fundOut(amtAcknowledged);
        emit FundOut(amtAcknowledged);
    }
    
    function tallyPrepare() external onlyDeployer notAborted {
        // Call chainlink VRF to get a random number for the Lottery winner index.
        // Note: This request has a time window. If network is congested & data arrived late, 0 index will be used.
        _lottery().initRandomValue();
        _manager.getRandomProvider().requestRandom();
    }

    function tallySubscriptionAuto() external onlyDeployer notAborted {
        (, uint a, uint b) = peekTally();
        uint ratio = (a==0 && b==0) ? Constant.PCNT_50 : (a * Constant.PCNT_100) / (a + b);
        _tallySubscription(ratio);
        emit TallySubscriptionAuto();
    }
    
    function tallySubscriptionManual(uint splitRatio) external onlyDeployer notAborted {
        _tallySubscription(splitRatio);
        emit TallySubscriptionManual(splitRatio);
    }

    function addRemovePrivateWhitelist(address[] calldata addresses, uint tier, bool add) external campaignOwnerOrConfigurator {
        _live().addRemoveWhitelistFcfs(addresses, tier, add);
    }
   
    // To swap the amount used for LP to BNB with the purpose of creating a XYZ/BNB Pair LP token.
    function swapToWBnbBase(uint maxSlippagePercent) external onlyDeployer {
        IBnbOracle oracle = _manager.getBnbOracle();
        _lp().swapCurrencyToWBnb(getLpFund(), maxSlippagePercent, oracle, _getLpInterface());
    }
    
    // Note: overrideStartVest: if set to true, will change the vesting's desiredUnlockTime to current time once LP is provided.
    function addAndLockLP(bool overrideStartVest, bool bypassSwap) external onlyDeployer {
        _require(getState(DataTypes.Ok.FinishedUp), Error.Code.CannotCreateLp);
        
        // Note: getLpFund() will return the raisedAmount after deducting for fee
        (uint tokenUnsed, uint fundUnused) = _lp().create(getLpFund(), bypassSwap);  
        _setState(DataTypes.Ok.LpCreated, true);
        
        if (overrideStartVest) {
            _vesting().setVestingTimeNow();
        }
        
        // In the event that after LP provision, there is some amount left, we need to return this amount to campaign owner
         _transferOut(_campaignOwner, tokenUnsed, DataTypes.FundType.Token);
        // return un-used fund in either WBNB (if swapped) or in currency
        _transferOut(_campaignOwner, fundUnused, _lp().swap.swapped ? DataTypes.FundType.WBnb : DataTypes.FundType.Currency);
    
        emit AddAndLockLP(overrideStartVest, bypassSwap);
    }
    
    function claimFunds() external onlyCampaignOwner  {
        _claim();
        emit ClaimFunds();
    }
    
    function claimUnlockedLp(uint index) external onlyCampaignOwner notAborted {
        _require(getState(DataTypes.Ok.LpCreated), Error.Code.LpNotCreated);
        uint amt = _lp().claimUnlockedLp(index);
        _history().record(DataTypes.ActionType.ClaimLp, msg.sender, index, amt, false);

        emit ClaimUnlockedLP(index);
    }
    
    // Implements ICampaign
    function cancelCampaign() external override {
        // Can only cancel a campaign when finishUp() is not yet called.
        _require(msg.sender == address(_manager) && !getState(DataTypes.Ok.FinishedUp), Error.Code.ValidationError);
        
        // When a campaign is cancelled, the campaignOwner can take back his token & user can get back their fund using
        // RefundExcess() & returnFund()
        _store().finalState = DataTypes.FinalState.Aborted;
    }
    
    // Note: Only daoMultiSig address can perform emergenctWithdraw via the Manager contract.
    // The withdrawn fund will go directly into the dao MultiSig address only.
    function daoMultiSigEmergencyWithdraw(address tokenAddress, address to, uint amount) external override {
        _require(msg.sender == address(_manager), Error.Code.NoRights);
        _transferOut(to, tokenAddress, amount);
    }

    // Call from RandomProvider when chainlink returns a random number from VRF
    function sendRandomValueForLottery(uint value) external {
        // Check that it is called from RandomProvider
        _require(msg.sender == address(_manager.getRandomProvider()), Error.Code.NoRights);

        // Update the result for Lottery //
         _lottery().setRandomValue(value);
    }

    function getExportCount() external view returns (uint) {
        return _history().allInvestors.length;
    }

    // Allow deployer to export the current winners. This should be done after campaign finished.
    function export(uint from, uint to) external view returns (address[] memory, uint[] memory)  {
        _require(getState(DataTypes.Ok.Tally),  Error.Code.NotReady);

        uint len = _history().allInvestors.length;
        _require((to >= from) && (to < len),  Error.Code.InvalidRange);
   
        uint size = to - from + 1;
        address[] memory users = new address[](size);
        uint[] memory totals = new uint[](size);

        address user;
        for (uint n = from; n <= to; n++) {
            user = _history().allInvestors[n];
            users[n-from]= user;
            totals[n-from] = getPurchaseDetail(user, false).total;
        }
        return (users, totals);
    }

    //--------------------//
    // PRIVATE FUNCTIONS //
    //--------------------//
    
    // Roles helper
    function _isConfigurator() private view returns (bool) {
        return _manager.getRoles().isConfigurator(msg.sender);
    }
    
}


// File contracts/Factory.sol

//  BUSL-1.1

pragma solidity 0.8.10;

contract Factory {
    
    IManager private _manager;


    event CreateCampaign(uint index, address projectOwner, address newCampaign);

    constructor(IManager manager) {
        _manager = manager;
    }

    function createCampaign(uint index, address projectOwner) external {
        if (_manager.getRoles().isDeployer(msg.sender) && projectOwner != address(0)) {
            bytes32 salt = keccak256(abi.encodePacked(index, projectOwner, msg.sender));
            address newAddress = address(new CampaignWithDeed{salt: salt}(_manager, projectOwner));
            _manager.addCampaign(newAddress, projectOwner);
            emit CreateCampaign(index, projectOwner, newAddress);
        }
    }

    function version() external pure returns (uint) {
        return Constant.FACTORY_VERSION;
    }
}