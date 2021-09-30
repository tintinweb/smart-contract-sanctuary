/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/interfaces/UniswapRouterV2.sol


pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}


// File contracts/interfaces/BakeryRouterV2.sol


pragma solidity ^0.8.0;

interface IBakeryV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactBNBForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForBNB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}


// File contracts/interfaces/DODOV2Proxy.sol


pragma solidity ^0.8.0;

interface IDODOV2Proxy {
    function dodoSwapV2ETHToToken(
        address toToken,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function dodoSwapV2TokenToETH(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV1(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);
}


// File contracts/interfaces/VyperSwap.sol


pragma solidity ^0.8.0;

interface IVyperSwap {
    function exchange(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external;
}


// File contracts/interfaces/VyperUnderlyingSwap.sol


pragma solidity ^0.8.0;

interface IVyperUnderlyingSwap {
    function exchange(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange_underlying(
        int128 tokenIndexFrom,
        int128 tokenIndexTo,
        uint256 dx,
        uint256 minDy
    ) external;
}


// File contracts/interfaces/DoppleSwap.sol


pragma solidity ^0.8.0;

interface IDoppleSwap {
    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
}


// File contracts/ArkenDex.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;



// import 'hardhat/console.sol';






contract ArkenDex {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant DEADLINE = 2**256 - 1;
    IERC20 constant ETHER_ERC20 =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    enum RouterInterface {
        UNISWAP,
        BAKERY,
        VYPER,
        VYPER_UNDERLYING,
        DOPPLE,
        DODO_V2,
        DODO_V1,
        DFYN
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    struct TradeRoute {
        address[] paths;
        address[] dodoPairs;
        uint256 dodoDirection;
        address dexAddr;
        RouterInterface dexInterface;
        uint256 part;
    }

    struct MultiSwapDesctiption {
        IERC20 srcToken;
        IERC20 dstToken;
        TradeRoute[] routes;
        uint256 amountIn;
        uint256 amountOutMin;
        address payable to;
    }

    event Swapped(
        address srcToken,
        address dstToken,
        uint256 amountIn,
        uint256 returnAmount
    );

    event UpdateVyper(address dexAddr, address[] tokens);

    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    address public ownerAddress;
    address payable public feeWalletAddress;

    struct Config {
        address dodoApproveAddress;
        IERC20 wrapperEtherERC20;
        IERC20 wrapperEtherERC20Dfyn;
        mapping(address => mapping(address => int128)) vyperCoinsMap;
    }
    Config config;

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, 'Not owner');
        _;
    }

    struct VyperConstructor {
        address[] dexAddress;
        address[][] tokenAddress;
    }

    struct ConstructorParams {
        address payable _feeWalletAddress;
        address _owner;
        IERC20 _wrappedEther;
        IERC20 _wrappedEtherDfyn;
        address _dodoApproveAddress;
        VyperConstructor _vyperParams;
    }

    constructor(ConstructorParams memory params) {
        ownerAddress = params._owner;
        feeWalletAddress = params._feeWalletAddress;
        config.wrapperEtherERC20 = params._wrappedEther;
        config.wrapperEtherERC20Dfyn = params._wrappedEtherDfyn;
        config.dodoApproveAddress = params._dodoApproveAddress;
        _initializeVyper(params._vyperParams);
    }

    function _initializeVyper(VyperConstructor memory params) private {
        address[] memory dexAddrs = params.dexAddress;
        address[][] memory tokenAddrs = params.tokenAddress;
        require(
            dexAddrs.length == tokenAddrs.length,
            'vyper params dexAddress and tokenAddress and tokenIndex has to be the same length'
        );
        for (uint32 i = 0; i < dexAddrs.length; i++) {
            for (int128 j = 0; uint128(j) < tokenAddrs[i].length; j++) {
                config.vyperCoinsMap[dexAddrs[i]][
                    tokenAddrs[i][uint128(j)]
                ] = j;
            }
        }
    }

    /**
     * External Functions
     */
    function updateVyper(address dexAddress, address[] calldata tokens)
        external
        onlyOwner
    {
        for (int128 j = 0; uint128(j) < tokens.length; j++) {
            config.vyperCoinsMap[dexAddress][tokens[uint128(j)]] = j;
        }
        emit UpdateVyper(dexAddress, tokens);
    }

    function multiTrade(MultiSwapDesctiption memory desc)
        external
        payable
        returns (uint256 returnAmount, uint256 blockNumber)
    {
        IERC20 dstToken = desc.dstToken;
        IERC20 srcToken = desc.srcToken;
        uint256 beforeTradeUserDstTokenAmount;
        if (ETHER_ERC20 == desc.dstToken) {
            beforeTradeUserDstTokenAmount = msg.sender.balance;
        } else {
            beforeTradeUserDstTokenAmount = dstToken.balanceOf(msg.sender);
        }
        (returnAmount, blockNumber) = _trade(desc);
        if (ETHER_ERC20 == desc.dstToken) {
            (bool sent, ) = desc.to.call{value: returnAmount}('');
            require(sent, 'Failed to send Ether');
        } else {
            dstToken.safeTransfer(msg.sender, returnAmount);
        }
        uint256 afterTradeUserDstTokenAmount;
        if (ETHER_ERC20 == desc.dstToken) {
            afterTradeUserDstTokenAmount = msg.sender.balance;
        } else {
            afterTradeUserDstTokenAmount = dstToken.balanceOf(msg.sender);
        }
        uint256 userDstTokenReceivedAmount = afterTradeUserDstTokenAmount.sub(
            beforeTradeUserDstTokenAmount
        );
        require(
            userDstTokenReceivedAmount > desc.amountOutMin,
            'Received token is not enough'
        );

        emit Swapped(
            address(srcToken),
            address(dstToken),
            desc.amountIn,
            returnAmount
        );
    }

    function testTransfer(MultiSwapDesctiption memory desc)
        external
        payable
        returns (uint256 returnAmount, uint256 blockNumber)
    {
        IERC20 dstToken = desc.dstToken;
        (returnAmount, blockNumber) = _trade(desc);
        uint256 beforeAmount = dstToken.balanceOf(msg.sender);
        dstToken.safeTransfer(msg.sender, returnAmount);
        uint256 afterAmount = dstToken.balanceOf(msg.sender);
        uint256 got = afterAmount.sub(beforeAmount);
        require(got == returnAmount, 'ArkenTester: Has Tax');
    }

    function getVyperData(address dexAddress, address token)
        external
        view
        returns (int128)
    {
        return config.vyperCoinsMap[dexAddress][token];
    }

    /**
     * Trade Logic
     */

    function _trade(MultiSwapDesctiption memory desc)
        internal
        returns (uint256 returnAmount, uint256 blockNumber)
    {
        require(desc.amountIn > 0, 'Amount-in needs to be more than zero');
        blockNumber = block.number;

        IERC20 srcToken = desc.srcToken;

        if (ETHER_ERC20 == desc.srcToken) {
            require(msg.value == desc.amountIn, 'Value not match amountIn');
        } else {
            uint256 allowance = srcToken.allowance(msg.sender, address(this));
            require(allowance >= desc.amountIn, 'Allowance not enough');
            srcToken.safeTransferFrom(msg.sender, address(this), desc.amountIn);
        }

        TradeRoute[] memory routes = desc.routes;
        uint256 srcTokenAmount;

        for (uint256 i = 0; i < routes.length; i++) {
            TradeRoute memory route = routes[i];
            IERC20 startToken = ERC20(route.paths[0]);
            IERC20 endToken = ERC20(route.paths[route.paths.length - 1]);
            if (ETHER_ERC20 == startToken) {
                srcTokenAmount = address(this).balance;
            } else {
                srcTokenAmount = startToken.balanceOf(address(this));
            }
            uint256 inputAmount = srcTokenAmount.mul(route.part).div(100000000); // 1% = 10^6
            require(
                route.part <= 100000000,
                'Route percentage can not exceed 100000000'
            );
            // uint256[] memory amounts;
            if (route.dexInterface == RouterInterface.BAKERY) {
                // amounts =
                _tradeIBakery(
                    startToken,
                    endToken,
                    inputAmount,
                    0,
                    route.paths,
                    address(this),
                    route.dexAddr
                );
            } else if (route.dexInterface == RouterInterface.VYPER) {
                // amounts =
                _tradeVyper(
                    startToken,
                    endToken,
                    inputAmount,
                    0,
                    route.dexAddr
                );
            } else if (route.dexInterface == RouterInterface.VYPER_UNDERLYING) {
                // amounts =
                _tradeVyperUnderlying(
                    startToken,
                    endToken,
                    inputAmount,
                    0,
                    route.dexAddr
                );
            } else if (route.dexInterface == RouterInterface.DOPPLE) {
                // amounts =
                _tradeDopple(
                    startToken,
                    endToken,
                    inputAmount,
                    0,
                    route.dexAddr
                );
            } else if (route.dexInterface == RouterInterface.DODO_V2) {
                // DODO doesn't allow zero min amount
                // amount =
                _tradeIDODOV2(
                    startToken,
                    endToken,
                    inputAmount,
                    1,
                    route.dodoPairs,
                    route.dodoDirection,
                    route.dexAddr
                );
            } else if (route.dexInterface == RouterInterface.DODO_V1) {
                // DODO doesn't allow zero min amount
                // amount =
                _tradeIDODOV1(
                    startToken,
                    endToken,
                    inputAmount,
                    1,
                    route.dodoPairs,
                    route.dodoDirection,
                    route.dexAddr
                );
            } else if (route.dexInterface == RouterInterface.DFYN) {
                // amounts =
                _tradeIDfyn(
                    startToken,
                    endToken,
                    inputAmount,
                    0,
                    route.paths,
                    address(this),
                    route.dexAddr
                );
            } else {
                // amounts =
                _tradeIUniswap(
                    startToken,
                    endToken,
                    inputAmount,
                    0,
                    route.paths,
                    address(this),
                    route.dexAddr
                );
            }
            // for (uint256 idx = 0; idx < amounts.length; idx++) {
            //     console.log('\tamount[%d]: %d', idx, amounts[idx]);
            // }
        }

        if (ETHER_ERC20 == desc.dstToken) {
            returnAmount = address(this).balance;
        } else {
            returnAmount = desc.dstToken.balanceOf(address(this));
        }

        returnAmount = _collectFee(returnAmount, desc.dstToken);
        // console.log(
        //     'after fee: %d ,, out min: %d',
        //     returnAmount,
        //     desc.amountOutMin
        // );
        require(
            returnAmount >= desc.amountOutMin,
            'Return amount is not enough'
        );
    }

    /**
     * Internal Functions
     */

    function _collectFee(uint256 amount, IERC20 token)
        private
        returns (
            uint256 // remaining amount to swap
        )
    {
        uint256 fee = amount.div(1000); // 0.1%
        // console.log('fee: %s from %s on %s', fee, amount, address(token));
        require(fee < amount, 'Fee exceeds amount');
        if (ETHER_ERC20 == token) {
            feeWalletAddress.transfer(fee);
        } else {
            token.safeTransfer(feeWalletAddress, fee);
        }
        return amount.sub(fee);
    }

    function _tradeIUniswap(
        IERC20 _src,
        IERC20 _dest,
        uint256 inputAmount,
        uint256 minOutputAmount,
        address[] memory paths,
        address to,
        address dexAddr
    ) private returns (uint256[] memory amounts) {
        IUniswapV2Router uniRouter = IUniswapV2Router(dexAddr);
        if (_src == ETHER_ERC20) {
            // ETH => TOKEN
            if (paths[0] == address(ETHER_ERC20)) {
                paths[0] = address(config.wrapperEtherERC20);
            }
            amounts = uniRouter.swapExactETHForTokens{value: inputAmount}(
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        } else if (_dest == ETHER_ERC20) {
            // TOKEN => ETH
            if (paths[paths.length - 1] == address(ETHER_ERC20)) {
                paths[paths.length - 1] = address(config.wrapperEtherERC20);
            }
            _src.safeApprove(dexAddr, inputAmount);
            amounts = uniRouter.swapExactTokensForETH(
                inputAmount,
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        } else {
            // TOKEN => TOKEN
            _src.safeApprove(dexAddr, inputAmount);
            amounts = uniRouter.swapExactTokensForTokens(
                inputAmount,
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        }
    }

    function _tradeIDfyn(
        IERC20 _src,
        IERC20 _dest,
        uint256 inputAmount,
        uint256 minOutputAmount,
        address[] memory paths,
        address to,
        address dexAddr
    ) private returns (uint256[] memory amounts) {
        IUniswapV2Router uniRouter = IUniswapV2Router(dexAddr);
        if (_src == ETHER_ERC20) {
            // ETH => TOKEN
            if (paths[0] == address(ETHER_ERC20)) {
                paths[0] = address(config.wrapperEtherERC20Dfyn);
            }
            amounts = uniRouter.swapExactETHForTokens{value: inputAmount}(
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        } else if (_dest == ETHER_ERC20) {
            // TOKEN => ETH
            if (paths[paths.length - 1] == address(ETHER_ERC20)) {
                paths[paths.length - 1] = address(config.wrapperEtherERC20Dfyn);
            }
            _src.safeApprove(dexAddr, inputAmount);
            amounts = uniRouter.swapExactTokensForETH(
                inputAmount,
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        } else {
            // TOKEN => TOKEN
            _src.safeApprove(dexAddr, inputAmount);
            amounts = uniRouter.swapExactTokensForTokens(
                inputAmount,
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        }
    }

    function _tradeIDODOV2(
        IERC20 _src,
        IERC20 _dest,
        uint256 inputAmount,
        uint256 minOutputAmount,
        address[] memory dodoPairs,
        uint256 direction,
        address dexAddr
    ) private returns (uint256 amount) {
        IDODOV2Proxy dodoProxy = IDODOV2Proxy(dexAddr);
        if (_src == ETHER_ERC20) {
            // ETH => TOKEN
            amount = dodoProxy.dodoSwapV2ETHToToken{value: inputAmount}(
                address(_dest),
                minOutputAmount,
                dodoPairs,
                direction,
                false,
                DEADLINE
            );
        } else if (_dest == ETHER_ERC20) {
            // TOKEN => ETH
            _src.safeApprove(config.dodoApproveAddress, inputAmount);
            amount = dodoProxy.dodoSwapV2TokenToETH(
                address(_src),
                inputAmount,
                minOutputAmount,
                dodoPairs,
                direction,
                false,
                DEADLINE
            );
        } else {
            // TOKEN => TOKEN
            _src.safeApprove(config.dodoApproveAddress, inputAmount);
            amount = dodoProxy.dodoSwapV2TokenToToken(
                address(_src),
                address(_dest),
                inputAmount,
                minOutputAmount,
                dodoPairs,
                direction,
                false,
                DEADLINE
            );
        }
    }

    function _tradeIDODOV1(
        IERC20 _src,
        IERC20 _dest,
        uint256 inputAmount,
        uint256 minOutputAmount,
        address[] memory dodoPairs,
        uint256 direction,
        address dexAddr
    ) private returns (uint256 amount) {
        IDODOV2Proxy dodoProxy = IDODOV2Proxy(dexAddr);
        IERC20 src = _src;
        IERC20 dest = _dest;
        if (_src != ETHER_ERC20) {
            _src.safeApprove(config.dodoApproveAddress, inputAmount);
        }
        // console.log('dodo v1 addr: %s , %s', address(src), address(dest));
        // console.log('dodo v1 amt: %d , %d', inputAmount, minOutputAmount);
        amount = dodoProxy.dodoSwapV1(
            address(src),
            address(dest),
            inputAmount,
            minOutputAmount,
            dodoPairs,
            direction,
            false,
            DEADLINE
        );
        // console.log('dodo v1 amount: %d', amount);
    }

    function _tradeIBakery(
        IERC20 _src,
        IERC20 _dest,
        uint256 inputAmount,
        uint256 minOutputAmount,
        address[] memory paths,
        address to,
        address dexAddr
    ) private returns (uint256[] memory amounts) {
        IBakeryV2Router bakeryRouter = IBakeryV2Router(dexAddr);
        if (_src == ETHER_ERC20) {
            // ETH => TOKEN
            if (paths[0] == address(ETHER_ERC20)) {
                paths[0] = address(config.wrapperEtherERC20);
            }
            amounts = bakeryRouter.swapExactBNBForTokens{value: inputAmount}(
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        } else if (_dest == ETHER_ERC20) {
            // TOKEN => ETH
            if (paths[paths.length - 1] == address(ETHER_ERC20)) {
                paths[paths.length - 1] = address(config.wrapperEtherERC20);
            }
            _src.safeApprove(dexAddr, inputAmount);
            amounts = bakeryRouter.swapExactTokensForBNB(
                inputAmount,
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        } else {
            // TOKEN => TOKEN
            _src.safeApprove(dexAddr, inputAmount);
            amounts = bakeryRouter.swapExactTokensForTokens(
                inputAmount,
                minOutputAmount,
                paths,
                to,
                DEADLINE
            );
        }
    }

    function _tradeVyper(
        IERC20 _src,
        IERC20 _dest,
        uint256 inputAmount,
        uint256 minOutputAmount,
        address dexAddr
    ) private {
        IVyperSwap vyperSwap = IVyperSwap(dexAddr);
        _src.safeApprove(dexAddr, inputAmount);
        int128 tokenIndexFrom = config.vyperCoinsMap[dexAddr][address(_src)];
        // console.log('tokenIndexFrom: %d', uint128(tokenIndexFrom));
        int128 tokenIndexTo = config.vyperCoinsMap[dexAddr][address(_dest)];
        // console.log('tokenIndexTo: %d', uint128(tokenIndexTo));
        vyperSwap.exchange(
            tokenIndexFrom,
            tokenIndexTo,
            inputAmount,
            minOutputAmount
        );
    }

    function _tradeVyperUnderlying(
        IERC20 _src,
        IERC20 _dest,
        uint256 inputAmount,
        uint256 minOutputAmount,
        address dexAddr
    ) private {
        IVyperUnderlyingSwap vyperSwap = IVyperUnderlyingSwap(dexAddr);
        _src.safeApprove(dexAddr, inputAmount);
        int128 tokenIndexFrom = config.vyperCoinsMap[dexAddr][address(_src)];
        // console.log('tokenIndexFrom: %d', uint128(tokenIndexFrom));
        int128 tokenIndexTo = config.vyperCoinsMap[dexAddr][address(_dest)];
        // console.log('tokenIndexTo: %d', uint128(tokenIndexTo));
        vyperSwap.exchange_underlying(
            tokenIndexFrom,
            tokenIndexTo,
            inputAmount,
            minOutputAmount
        );
    }

    function _tradeDopple(
        IERC20 _src,
        IERC20 _dest,
        uint256 inputAmount,
        uint256 minOutputAmount,
        address dexAddr
    ) private returns (uint256 amount) {
        IDoppleSwap doppleSwap = IDoppleSwap(dexAddr);
        _src.safeApprove(dexAddr, inputAmount);
        // console.log('getTokenIndex: %s %s', address(_src), address(_dest));
        uint8 tokenIndexFrom = doppleSwap.getTokenIndex(address(_src));
        // console.log('tokenIndexFrom: %d', uint128(tokenIndexFrom));
        uint8 tokenIndexTo = doppleSwap.getTokenIndex(address(_dest));
        // console.log('tokenIndexTo: %d', uint128(tokenIndexTo));
        amount = doppleSwap.swap(
            tokenIndexFrom,
            tokenIndexTo,
            inputAmount,
            minOutputAmount,
            DEADLINE
        );
    }
}