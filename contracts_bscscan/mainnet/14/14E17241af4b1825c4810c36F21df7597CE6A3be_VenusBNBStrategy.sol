/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/GSN/Context.sol


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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
// File: @openzeppelin/contracts/utils/Pausable.sol

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);
}


interface IUnitroller {
    function claimVenus(address holder) external;
    function enterMarkets(address[] memory _vtokens) external;
    function exitMarket(address _vtoken) external;
    function getAssetsIn(address account) view external returns (address[] memory);
    function getAccountLiquidity(address account) view external returns (uint, uint, uint);
}


interface IVBNB {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
}


interface IWBNB is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}


/**
 * @title Strategy Venus BNB
 * @author sirbeefalot & superbeefyboy
 * @dev It maximizes yields doing leveraged lending with BNB on Venus.
 */
contract VenusBNBStrategy is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev Tokens Used:
     * {wbnb}  - Token that the strategy maximizes. 
     * {venus} - Token earned through farming.
     * {vbnb}  - Venus BNB. We interact with it to mint/redem/borrow/repay BNB.
     */
    address constant public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant public venus = address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63);
    address constant public vbnb = address(0xA07c5b74C9B40447a954e1466938b865b6BBea36);

    /**
     * @dev Third Party Contracts:
     * {unirouter}  - Pancakeswap unirouter. Has the most liquidity for {venus}.
     * {unitroller} - Controller contract for the {venus} rewards.
     */
    address constant public unirouter  = address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    address constant public unitroller = address(0xfD36E2c2a6789Db23113685031d7F16329158384);

   /**
     * @dev M7Finance Contracts:
     * {vault} - Address of the vault that controls the strategy's funds.
     */
    address public vault;
   /**
     * @dev Distribution of fees earned. This allocations relative to the % implemented on chargeFees().
     * Current implementation separates 1% total for fees.
     *
     * {VAULT_HOLDERS_FEE} - 1.5% goes to VAULT holders dividend pool.
     * {TRADING_COMP_FEE} - 0.5% goes to trading comp prize pool.
     * {TREASURY_FEE} - 1% goes to the platform and team.
     * {MAX_FEE} - Aux const used to safely calc the correct amounts.
     * 
     * {WITHDRAWAL_FEE} - Fee taxed when a user withdraws funds. 5 === 0.05% fee.
     * {WITHDRAWAL_MAX} - Aux const used to safely calc the correct amounts.
     */
    uint256 public VAULT_HOLDERS_FEE  = 15;
    uint256 public TRADING_COMP_FEE   = 5;
    uint256 public TREASURY_FEE       = 10;
    uint256 constant public MAX_FEE      = 1000;

    uint256 public WITHDRAWAL_FEE = 5;
    uint256 constant public WITHDRAWAL_MAX = 10000;
    
    bool public takeFee = true;
    
    uint256 private dividendsCollected;
    uint256 private vaultTokensSwappedFor;
    uint256 private initialBalanceForAPR;
    uint256 private apr;
    uint256 private reinvestmentPeriods = 4380; //12 reinvestment periods a day for a 365 day year
    
    address private tradingCompWallet;
    address private vaultRewardsPool;
    address private treasuryWallet;

    /**
     * @dev Routes we take to swap tokens using the {unirouter}.
     * {venusToWbnbRoute} - Route we take to go from {venus} into {wbnb}.
     */
    address[] public venusToWbnbRoute = [venus, wbnb];

    /**
     * @dev Variables that can be changed to config profitability and risk:
     * {borrowRate}          - What % of our collateral do we borrow per leverage level.
     * {borrowDepth}         - How many levels of leverage do we take. 
     * {BORROW_RATE_MAX}     - A limit on how much we can push borrow risk.
     * {BORROW_DEPTH_MAX}    - A limit on how many steps we can leverage.
     * {MIN_LEVERAGE_AMOUNT} - The minimum amount of collateral required to leverage.
     */
    uint256 public borrowRate = 58;
    uint256 public borrowDepth = 4;
    uint256 constant public BORROW_RATE_MAX = 58;
    uint256 constant public BORROW_DEPTH_MAX = 10;
    uint256 constant public MIN_LEVERAGE_AMOUNT = 1e12;

    /** 
     * @dev We keep and update a cache of the strat's bnb deposited in venus. Contract
     * functions that use this value always update it first. We use it to keep the UI helper
     * functions as view only.  
     */
    uint256 public depositedBalance;

    /**
     * @dev Events that the contract emits
     */
    event StratHarvest(address indexed harvester);
    event StratRebalance(uint256 _borrowRate, uint256 _borrowDepth);

    /**
     * @notice Initializes the strategy
     */
    constructor(
        address[4] memory addresses_, 
        address[] memory _markets
    )  {
        vault = addresses_[0];
        vaultRewardsPool = addresses_[1];
        tradingCompWallet = addresses_[2];
        treasuryWallet = addresses_[3];
        
        IERC20(venus).safeApprove(unirouter, ~uint256(0));
        IERC20(wbnb).safeApprove(unirouter, ~uint256(0));

        IUnitroller(unitroller).enterMarkets(_markets);
    }
    
    receive () external payable {}
    
    
    /**
     * @dev Function to calculate the total underlaying {wbnb} and bnb held by the strat.
     * It takes into account both the funds at hand, and the funds allocated in the {vbnb} contract.
     * It uses a cache of the balances stored in {depositedBalance} to enable a few UI helper functions
     * to exist. Sensitive functions should call 'updateBalance()' first to make sure the data is up to date.
     * @return total {wbnb} and bnb held by the strat.
     */
    function balanceOf() public view returns (uint256) {
        return balanceOfStrat().add(depositedBalance);
    }

    /**
     * @dev It calculates how much BNB the contract holds.
     * @return The sum of {wbnb} and bnb in the contract.
     */
    function balanceOfStrat() public view returns (uint256) {
        uint256 bnbBal = address(this).balance;
        uint256 wbnbBal = IERC20(wbnb).balanceOf(address(this));
        return bnbBal.add(wbnbBal);
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone deposits in the strategy's vault. It does {borrowDepth} 
     * levels of compound lending. It also updates the helper {depositedBalance} variable.
     */
    function deposit() public whenNotPaused {
        uint256 wbnbBal = IERC20(wbnb).balanceOf(address(this));

        if (wbnbBal > 0) {
            IWBNB(wbnb).withdraw(wbnbBal);
            _leverage(wbnbBal);
        }

        updateBalance();
    }

    /**
     * @dev Repeatedly supplies and borrows bnb following the configured {borrowRate} and {borrowDepth}
     * @param _amount amount of bnb to leverage
     */
    function _leverage(uint256 _amount) internal {
        if (_amount < MIN_LEVERAGE_AMOUNT) { return; }

        for (uint i = 0; i < borrowDepth; i++) {
            IVBNB(vbnb).mint{value: _amount}();
            _amount = _amount.mul(borrowRate).div(100);
            IVBNB(vbnb).borrow(_amount);
        }
    } 

    /**
     * @dev Incrementally alternates between paying part of the debt and withdrawing part of the supplied 
     * collateral. Continues to do this until it repays the entire debt and withdraws all the supplied bnb 
     * from the system
     */
    function _deleverage() internal {
        uint256 bnbBal = address(this).balance;
        uint256 borrowBal = IVBNB(vbnb).borrowBalanceCurrent(address(this));

        while (bnbBal < borrowBal) {
            IVBNB(vbnb).repayBorrow{value: bnbBal}();

            borrowBal = IVBNB(vbnb).borrowBalanceCurrent(address(this));
            uint256 targetUnderlying = borrowBal.mul(100).div(borrowRate);
            uint256 balanceOfUnderlying = IVBNB(vbnb).balanceOfUnderlying(address(this));

            IVBNB(vbnb).redeemUnderlying(balanceOfUnderlying.sub(targetUnderlying));
            bnbBal = address(this).balance;
        }

        IVBNB(vbnb).repayBorrow{value: borrowBal}();

        uint256 vbnbBal = IERC20(vbnb).balanceOf(address(this));
        IVBNB(vbnb).redeem(vbnbBal);
    }

    /**
     * @dev Extra safety measure that allows us to manually unwind one level. In case we somehow get into 
     * as state where the cost of unwinding freezes the system. We can manually unwind a few levels 
     * with this function and then 'rebalance()' with new {borrowRate} and {borrowConfig} values. 
     * @param _borrowRate configurable borrow rate in case it's required to unwind successfully
     */
    function deleverageOnce(uint _borrowRate) external onlyOwner {
        require(_borrowRate <= BORROW_RATE_MAX, "!safe");
        
        uint256 bnbBal = address(this).balance;
        IVBNB(vbnb).repayBorrow{value: bnbBal}();

        uint256 borrowBal = IVBNB(vbnb).borrowBalanceCurrent(address(this));
        uint256 targetUnderlying = borrowBal.mul(100).div(_borrowRate);
        uint256 balanceOfUnderlying = IVBNB(vbnb).balanceOfUnderlying(address(this));

        IVBNB(vbnb).redeemUnderlying(balanceOfUnderlying.sub(targetUnderlying));

        updateBalance();
    }

    /**
     * @dev Updates the risk profile and rebalances the vault funds accordingly.
     * @param _borrowRate percent to borrow on each leverage level.
     * @param _borrowDepth how many levels to leverage the funds.
     */
    function rebalance(uint256 _borrowRate, uint256 _borrowDepth) external onlyOwner {
        require(_borrowRate <= BORROW_RATE_MAX, "!rate");
        require(_borrowDepth <= BORROW_DEPTH_MAX, "!depth");

        _deleverage();
        borrowRate = _borrowRate;
        borrowDepth = _borrowDepth;
        _leverage(address(this).balance);

        emit StratRebalance(_borrowRate, _borrowDepth);
    }
    
    
    /**
     * @dev It helps mantain a cached version of the bnb deposited in venus. 
     * We use it to be able to keep the vault's 'balance()' function and 
     * 'getPricePerFullShare()' with view visibility. 
     */
    function updateBalance() public {
        uint256 supplyBal = IVBNB(vbnb).balanceOfUnderlying(address(this));
        uint256 borrowBal = IVBNB(vbnb).borrowBalanceCurrent(address(this));
        depositedBalance = supplyBal.sub(borrowBal);
    }
    
    
    /**
     * @dev Withdraws funds and sends them back to the vault. It deleverages from venus first,
     * and then deposits again after the withdraw to make sure it mantains the desired ratio. 
     * @param _amount How much {wbnb} to withdraw.
     */
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wbnbBal = IERC20(wbnb).balanceOf(address(this));

        if (wbnbBal < _amount) {
            _deleverage();
            IWBNB(wbnb).deposit{value: _amount.sub(wbnbBal)}();
            wbnbBal = IERC20(wbnb).balanceOf(address(this));
        }

        if (wbnbBal > _amount) {
            wbnbBal = _amount;    
        }

        uint256 withdrawalFee = wbnbBal.mul(WITHDRAWAL_FEE).div(WITHDRAWAL_MAX);
        IERC20(wbnb).safeTransfer(vault, wbnbBal.sub(withdrawalFee));

        if (!paused()) {
            _leverage(address(this).balance);
        }
        
        updateBalance();
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * 1. It claims {venus} rewards from the Unitroller.
     * 3. It charges the system fee and sends it to M7Vault stakers.
     * 4. It swaps the remaining rewards into more {wbnb}.
     * 4. It re-invests the remaining profits.
     */
    function harvest() external whenNotPaused onlyOwner{
        require(!Address.isContract(msg.sender), "!contract");

        IUnitroller(unitroller).claimVenus(address(this));
        _chargeFees();
        _swapRewards();
        deposit();

        emit StratHarvest(msg.sender);
    }
    
    

    /**
     * @dev Takes out 3% as system fees from the rewards. 
     * 1% -> Comp Fee
     * 0.5% -> Treasury fee
     * 1.5% -> Holders
     */
    function _chargeFees() internal {
        uint256 toWbnb = IERC20(venus).balanceOf(address(this));
        
        uint256 vaultHoldersFee = toWbnb.mul(VAULT_HOLDERS_FEE).div(MAX_FEE);
        IUniswapRouter(unirouter).swapExactTokensForTokens(vaultHoldersFee, 0, venusToWbnbRoute, vaultRewardsPool, block.timestamp.add(300));
        
        uint256 tradingCompFee = toWbnb.mul(TRADING_COMP_FEE).div(MAX_FEE);
        IUniswapRouter(unirouter).swapExactTokensForTokens(tradingCompFee, 0, venusToWbnbRoute, tradingCompWallet, block.timestamp.add(300));

        uint256 treasuryFee = toWbnb.mul(TREASURY_FEE).div(MAX_FEE);
        IUniswapRouter(unirouter).swapExactTokensForTokens(treasuryFee, 0, venusToWbnbRoute, treasuryWallet, block.timestamp.add(300));
    }

    /**
     * @dev Swaps {venus} rewards earned for more {wbnb}.
     */
    function _swapRewards() internal {
        uint256 venusBal = IERC20(venus).balanceOf(address(this));
        initialBalanceForAPR = balanceOf();
        
        IUniswapRouter(unirouter).swapExactTokensForTokens(venusBal, 0, venusToWbnbRoute, address(this), block.timestamp.add(600));
        
        vaultTokensSwappedFor = vaultTokensSwappedFor.add(balanceOf().sub(initialBalanceForAPR));
        apr = ((balanceOf().sub(initialBalanceForAPR)).mul(10000)).div(initialBalanceForAPR);
        dividendsCollected = dividendsCollected.add(venusBal);
    }

    


    /**
     * @dev Function that has to be called as part of strat migration. It pauses the strat and
     *  sends all the available funds back to the vault, ready to be migrated to the new strat.
     */ 
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        _pause();

        IERC20(venus).safeApprove(unirouter, 0);
        IERC20(wbnb).safeApprove(unirouter, 0);

        _deleverage();
        IWBNB(wbnb).deposit{value: address(this).balance}();

        uint256 wbnbBal = IERC20(wbnb).balanceOf(address(this));
        IERC20(wbnb).transfer(vault, wbnbBal);
    }

    /**
     * @dev Pauses deposits. Withdraws all funds from the Venus Platform.
     */
    function panic() public onlyOwner {
        pause();
        _deleverage();
        IWBNB(wbnb).deposit{value: address(this).balance}();
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() public onlyOwner {
        _pause();

        IERC20(venus).safeApprove(unirouter, 0);
        IERC20(wbnb).safeApprove(unirouter, 0);
    }

    /**
     * @dev Unpauses the strat. It also puts the funds to work again.
     */
    function unpause() external onlyOwner {
        _unpause();

        IERC20(venus).safeApprove(unirouter, ~uint256(0));
        IERC20(wbnb).safeApprove(unirouter, ~uint256(0));

        deposit();
    }

    
    /**
     * @dev Updates parent vault.
     * @param _vault new vault address.
     */
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /**
     * @dev Change the vault holders fee
     */
    function setVaultHoldersFee(uint256 _fee) external onlyOwner {
        require(VAULT_HOLDERS_FEE != _fee, "Can't set VAULT_HOLDERS_FEE to same value");
        require(_fee > 0 && _fee <= 100, "Fee must be between 0 and 100 (10%)");
        VAULT_HOLDERS_FEE = _fee;
    }
    
    /**
     * @dev Change the trading comp fee
     */
    function setTradingCompFee(uint256 _fee) external onlyOwner {
        require(TRADING_COMP_FEE != _fee, "Can't set TRADING_COMP_FEE to same value");
        require(_fee > 0 && _fee <= 100, "Fee must be between 0 and 100 (10%)");
        TRADING_COMP_FEE = _fee;
    }
    
    /**
     * @dev Change the treasury fee
     */
    function setTreasuryFee(uint256 _fee) external onlyOwner {
        require(TREASURY_FEE != _fee, "Can't set TREASURY_FEE to same value");
        require(_fee > 0 && _fee <= 100, "Fee must be between 0 and 100 (10%)");
        TREASURY_FEE = _fee;
    }
    
    
    /**
     * @dev If the vault reward pool needs to be changed this allows that
     */
    function setVaultRewardsPool(address _address) external onlyOwner {
        require(vaultRewardsPool != _address, "Can't set current vaultRewardsPool to same address");
        vaultRewardsPool = _address;
    }
    
    /**
     * @dev If the vault reward pool needs to be changed this allows that
     */
    function setTradingCompWallet(address _address) external onlyOwner {
        require(tradingCompWallet != _address, "Can't set current tradingCompWallet to same address");
        tradingCompWallet = _address;
    }
    
    /**
     * @dev If the vault reward pool needs to be changed this allows that
     */
    function setTreasuryWallet(address _address) external onlyOwner {
        require(treasuryWallet != _address, "Can't set current treasuryWallet to same address");
        treasuryWallet = _address;
    }
    
    /**
     * @dev Returns the total amount of {rewardToken} the strategy has accumulated.
     */
    function getDividendsCollected() external view returns (uint256) {
        return dividendsCollected;
    }
    
    /**
     * @dev Returns the total amount of {vaultToken} that the strategy has swapped the {rewardToken} for.
     */
    function getVaultTokensSwappedFor() external view returns (uint256) {
        return vaultTokensSwappedFor;
    }

    /**
     * @dev Returns the calculated apr at this point in time.
     */
    function getAPR() external view returns (uint256) {
        return apr;
    }
    
    /**
     * @dev Returns the number of investment periods in a 365 day year.
     */
    function getReinvestmentPeriods() external view returns (uint256) {
        return reinvestmentPeriods;
    }

    /**
     * @dev Returns the current initial balance for calculating APR.
     */
    function getInitialBalanceForAPR() external view returns (uint256) {
        return initialBalanceForAPR;
    }
}