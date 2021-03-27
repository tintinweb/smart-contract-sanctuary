/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.12;


// 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// 
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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

// 
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// 
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

// 
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

// 
interface ICToken {
    /// @notice Contract which oversees inter-cToken operations
    function comptroller() external view returns (IComptroller);

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external returns (uint);

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external returns (uint);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint);

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /// @notice Underlying asset for this CToken
    function underlying() external view returns (address);
}

interface IComptroller {
    /// @notice The COMP accrued but not yet transferred to each user
    function compAccrued(address holder) external view returns (uint256);

    /**
     * @notice Claim all the comp accrued by holder in all markets
     * @param holder The address to claim COMP for
     */
    function claimComp(address holder) external;

    /**
     * @notice Claim all the comp accrued by holder in the specified markets
     * @param holder The address to claim COMP for
     * @param cTokens The list of markets to claim COMP in
     */
    function claimComp(address holder, ICToken[] memory cTokens) external;

    /**
     * @notice Claim all comp accrued by the holders
     * @param holders The addresses to claim COMP for
     * @param cTokens The list of markets to claim COMP in
     * @param borrowers Whether or not to claim COMP earned by borrowing
     * @param suppliers Whether or not to claim COMP earned by supplying
     */
    function claimComp(address[] memory holders, ICToken[] memory cTokens, bool borrowers, bool suppliers) external;

    /// @notice The portion of compRate that each market currently receives
    function compSpeeds(address cToken) external view returns (uint256);

    /**
     * @notice Return the address of the COMP token
     * @return The address of COMP
     */
    function getCompAddress() external view returns (address);
}

// 
interface IContinuousRewardToken {
  /// @notice Emitted when a user supplies underlying token
  event Supply(address indexed sender, address indexed receiver, uint256 amount);
  /// @notice Emitted when a CRT token holder redeems balance
  event Redeem(address indexed sender, address indexed receiver, uint256 amount);
  /// @notice Emitted when current or previous reward owners claim their rewards
  event Claim(address indexed sender, address indexed receiver, address indexed rewardToken, uint256 amount);
  /// @notice Emitted when an admin changes current reward owner
  event DelegateUpdated(address indexed oldDelegate, address indexed newDelegate);
  /// @notice Emitted when an admin role is transferred by current admin
  event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

  /**
   * @notice The address of underlying token
   * @return underlying token
   */
  function underlying() external view returns (address);

  /**
   * @notice Reward tokens that may be accrued as rewards
   * @return Exhaustive list of all reward token addresses
   */
  function rewardTokens() external view returns (address[] memory);

  /**
   * @notice Balance of accrued reward token for account
   * @param rewardToken Reward token address
   * @return Balance of accrued reward token for account
   */
  function balanceOfReward(address rewardToken, address account) external view returns (uint256);

  /**
   * @notice Annual Percentage Reward for the specific reward token. Measured in relation to the base units of the underlying asset vs base units of the accrued reward token.
   * @param rewardToken Reward token address
   * @return APY times 10^18
   */
  function rate(address rewardToken) external view returns (uint256);

  /**
   * @notice Supply a specified amount of underlying tokens and receive back an equivalent quantity of CB-CR-XX-XX tokens
   * @param receiver Account to credit CB-CR-XX-XX tokens to
   * @param amount Amount of underlying token to supply
   */
  function supply(
    address receiver,
    uint256 amount
  ) external;

  /**
   * @notice Redeem a specified amount of underlying tokens by burning an equivalent quantity of CB-CR-XX-XX tokens. Does not redeem reward tokens
   * @param receiver Account to credit underlying tokens to
   * @param amount Amount of underlying token to redeem
   */
  function redeem(
    address receiver,
    uint256 amount
  ) external;

  /**
   * @notice Claim accrued reward in one or reward tokens
   * @dev All params must have the same array length
   * @param receivers List of accounts to credit claimed tokens to
   * @param tokens Reward token addresses
   * @param amounts Amounts of each reward token to claim
   */
  function claim(
    address[] memory receivers,
    address[] memory tokens,
    uint256[] memory amounts
  ) external;

  /**
   * @notice Atomic redeem and claim in a single transaction
   * @dev receivers.length[0] corresponds to the address that the underlying token is redeemed to. receivers.length[1:n-1] hold the to addresses for the reward tokens respectively.
   * @param receivers       List of accounts to credit tokens to
   * @param amounts         List of amounts to credit
   * @param claimTokens     Reward token addresses
   */
  function redeemAndClaim(
    address[] calldata receivers,
    uint256[] calldata amounts,
    address[] calldata claimTokens
  ) external;

  /**
   * @notice Snapshots reward owner balance and update reward owner address
   * @dev Only callable by admin
   * @param newDelegate New reward owner address
   */
  function updateDelegate(address newDelegate) external;

  /**
   * @notice Get the current delegate (receiver of rewards)
   * @return the address of the current delegate
   */
  function delegate() external view returns (address);

  /**
   * @notice Get the current admin
   * @return the address of the current admin
   */
  function admin() external view returns (address);

  /**
   * @notice Updates the admin address
   * @dev Only callable by admin
   * @param newAdmin New admin address
   */
  function transferAdmin(address newAdmin) external;
}

// 
/**
 * @title ContinuousRewardToken contract
 * @notice ERC20 token which wraps underlying protocol rewards
 * @author
 */
abstract contract ContinuousRewardToken is ERC20, IContinuousRewardToken {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice The address of underlying token
  address public override underlying;
  /// @notice The admin of reward token
  address public override admin;
  /// @notice The current owner of all rewards
  address public override delegate;
  /// @notice Unclaimed rewards of all previous owners: reward token => (owner => amount)
  mapping(address => mapping(address => uint256)) public unclaimedRewards;
  /// @notice Total amount of unclaimed rewards: (reward token => amount)
  mapping(address => uint256) public totalUnclaimedRewards;

  /**
   * @notice Construct a new Continuous reward token
   * @param _underlying The address of underlying token
   * @param _delegate The address of reward owner
   */
  constructor(address _underlying, address _delegate) public {
    admin = msg.sender;
    require(_underlying != address(0), "ContinuousRewardToken: invalid underlying address");
    require(_delegate != address(0), "ContinuousRewardToken: invalid delegate address");

    delegate = _delegate;
    underlying = _underlying;
  }

  /**
   * @notice Supply a specified amount of underlying tokens and receive back an equivalent quantity of CB-CR-XX-XX tokens
   * @param receiver Account to credit CB-CR-XX-XX tokens to
   * @param amount Amount of underlying token to supply
   */
  function supply(address receiver, uint256 amount) override external {
    IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);

    _mint(receiver, amount);
    _supply(amount);

    emit Supply(msg.sender, receiver, amount);
  }

  function _supply(uint256 amount) virtual internal;

  /**
   * @notice Reward tokens that may be accrued as rewards
   * @return Exhaustive list of all reward token addresses
   */
  function rewardTokens() override external view returns (address[] memory) {
    return _rewardTokens();
  }

  function _rewardTokens() virtual internal view returns (address[] memory);

  /**
   * @notice Amount of reward for the given reward token
   * @param rewardToken The address of reward token
   * @param account The account for which reward balance is checked
   * @return reward balance of token the specified account has
   */
  function balanceOfReward(address rewardToken, address account) override public view returns (uint256) {
    if (account == delegate) {
      return _balanceOfReward(rewardToken).sub(totalUnclaimedRewards[rewardToken]);
    }
    return unclaimedRewards[rewardToken][account];
  }

  function _balanceOfReward(address rewardToken) virtual internal view returns (uint256);

  /**
   * @notice Redeem a specified amount of underlying tokens by burning an equivalent quantity of CB-CR-XX-XX tokens. Does not redeem reward tokens
   * @param receiver Account to credit underlying tokens to
   * @param amount Amount of underlying token to redeem
   */
  function redeem(
    address receiver,
    uint256 amount
  ) override public {
    _burn(msg.sender, amount);
    _redeem(amount);

    IERC20(underlying).safeTransfer(receiver, amount);

    emit Redeem(msg.sender, receiver, amount);
  }

  function _redeem(uint256 amount) virtual internal;

  /**
   * @notice Claim accrued reward in one or more reward tokens
   * @dev All params must have the same array length
   * @param receivers List of accounts to credit claimed tokens to
   * @param tokens Reward token addresses
   * @param amounts Amounts of each reward token to claim
   */
  function claim(
    address[] calldata receivers,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) override public {
    require(receivers.length == tokens.length && receivers.length == amounts.length, "ContinuousRewardToken: lengths dont match");

    for (uint256 i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      address claimToken = tokens[i];
      uint256 amount = amounts[i];
      uint256 rewardBalance = balanceOfReward(claimToken, msg.sender);

      uint256 claimAmount = amount == uint256(-1) ? rewardBalance : amount;
      require(rewardBalance >= claimAmount, "ContinuousRewardToken: insufficient claimable");

      // If caller is one of previous owners, update unclaimed rewards data
      if (msg.sender != delegate) {
        unclaimedRewards[claimToken][msg.sender] = rewardBalance.sub(claimAmount);
        totalUnclaimedRewards[claimToken] = totalUnclaimedRewards[claimToken].sub(claimAmount);
      }

      _claim(claimToken, claimAmount);

      IERC20(claimToken).safeTransfer(receiver, claimAmount);

      emit Claim(msg.sender, receiver, claimToken, claimAmount);
    }
  }

  function _claim(address claimToken, uint256 amount) virtual internal;

  /**
   * @notice Atomic redeem and claim in a single transaction
   * @dev receivers[0] corresponds to the address that the underlying token is redeemed to. receivers[1:n-1] hold the to addresses for the reward tokens respectively.
   * @param receivers       List of accounts to credit tokens to
   * @param amounts         List of amounts to credit
   * @param claimTokens     Reward token addresses
   */
  function redeemAndClaim(
    address[] calldata receivers,
    uint256[] calldata amounts,
    address[] calldata claimTokens
  ) override external {
    redeem(receivers[0], amounts[0]);
    claim(receivers[1:], claimTokens, amounts[1:]);
  }

  /**
   * @notice Updates reward owner address
   * @dev Only callable by admin
   * @param newDelegate New reward owner address
   */
  function updateDelegate(address newDelegate) override external onlyAdmin {
    require(newDelegate != delegate, "ContinuousRewardToken: new reward owner is the same as old one");
    require(newDelegate != address(0), "ContinuousRewardToken: invalid new delegate address");

    address oldDelegate = delegate;

    address[] memory allRewardTokens = _rewardTokens();
    for (uint256 i = 0; i < allRewardTokens.length; i++) {
      address rewardToken = allRewardTokens[i];

      uint256 rewardBalance = balanceOfReward(rewardToken, oldDelegate);
      unclaimedRewards[rewardToken][oldDelegate] = rewardBalance;
      totalUnclaimedRewards[rewardToken] = totalUnclaimedRewards[rewardToken].add(rewardBalance);

      // If new owner used to be reward owner in the past, transfer back his unclaimed rewards to himself
      uint256 prevBalance = unclaimedRewards[rewardToken][newDelegate];
      if (prevBalance > 0) {
        unclaimedRewards[rewardToken][newDelegate] = 0;
        totalUnclaimedRewards[rewardToken] = totalUnclaimedRewards[rewardToken].sub(prevBalance);
      }
    }

    delegate = newDelegate;

    emit DelegateUpdated(oldDelegate, newDelegate);
  }

  /**
   * @notice Updates the admin address
   * @dev Only callable by admin
   * @param newAdmin New admin address
   */
  function transferAdmin(address newAdmin) override external onlyAdmin {
    require(newAdmin != admin, "ContinuousRewardToken: new admin is the same as old one");
    address previousAdmin = admin;

    admin = newAdmin;

    emit AdminTransferred(previousAdmin, newAdmin);
  }

  modifier onlyAdmin {
    require(msg.sender == admin, "ContinuousRewardToken: not an admin");
    _;
  }
}

// 
/**
 * @title CompoundRewardToken contract
 * @notice ERC20 token which wraps Compound underlying and COMP rewards
 * @author
 */
contract CompoundRewardToken is ContinuousRewardToken {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 constant private BASE = 1e18;
  uint256 constant private DAYS_PER_YEAR = 365;
  uint256 constant private BLOCKS_PER_DAY = 5760;// at a rate of 15 seconds per block, https://github.com/compound-finance/compound-protocol/blob/23eac9425accafb82551777c93896ee7678a85a3/contracts/JumpRateModel.sol#L18
  uint256 constant private BLOCKS_PER_YEAR = BLOCKS_PER_DAY * DAYS_PER_YEAR;

  /// @notice The address of cToken contract
  ICToken public cToken;
  /// @notice The address of COMP token
  address public comp;

  /**
   * @notice Construct a new Compound reward token
   * @param name ERC-20 name of this token
   * @param symbol ERC-20 symbol of this token
   * @param _cToken The address of cToken contract
   * @param delegate The address of reward owner
   */
  constructor(
    string memory name,
    string memory symbol,
    ICToken _cToken,
    address delegate
  ) ERC20(name, symbol) ContinuousRewardToken(_cToken.underlying(), delegate) public {
    cToken = _cToken;
    comp = cToken.comptroller().getCompAddress();

    // This contract doesn't support cComp or cEther, use special case contract for them
    require(underlying != comp, "CompoundRewardToken: does not support cComp usecase");

    IERC20(underlying).approve(address(cToken), uint256(-1));
  }

  function _rewardTokens() override internal view returns (address[] memory) {
    address[] memory tokens = new address[](2);
    (tokens[0], tokens[1]) = (underlying, comp);
    return tokens;
  }

  function _balanceOfReward(address rewardToken) override internal view returns (uint256) {
    require(rewardToken == underlying || rewardToken == comp, "CompoundRewardToken: not reward token");
    if (rewardToken == underlying) {
      // get the value of this contract's cTokens in the underlying, and subtract total CRT mint amount to get interest
      uint256 underlyingBalance = balanceOfCTokenUnderlying(address(this));
      uint256 totalSupply = totalSupply();
      // Due to rounding errors, it is possible the total supply is greater than the underlying balance by 1 wei, return 0 in this case
      // This is a transient case which will resolve itself once rewards are earned
      return totalSupply > underlyingBalance ? 0 : underlyingBalance.sub(totalSupply);
    } else {
      return getCompRewards();
    }
  }

  /**
   * @notice Annual Percentage Reward for the specific reward token. Measured in relation to the base units of the underlying asset vs base units of the accrued reward token.
   * @param rewardToken Reward token address
   * @dev Underlying asset rate is an APY, Comp rate is an APR
   * @return APY times 10^18
   */
  function rate(address rewardToken) override external view returns (uint256) {
    require(rewardToken == underlying || rewardToken == comp, "CompoundRewardToken: not reward token");
    if (rewardToken == underlying) {
      return getUnderlyingRate();
    } else {
      return getCompRate();
    }
  }

  function _supply(uint256 amount) override internal {
    require(cToken.mint(amount) == 0, "CompoundRewardToken: minting cToken failed");
  }

  function _redeem(uint256 amount) override internal {
    require(cToken.redeemUnderlying(amount) == 0, "CompoundRewardToken: redeeming cToken failed");
  }

  function _claim(address claimToken, uint256 amount) override internal {
    require(claimToken == underlying || claimToken == comp, "CompoundRewardToken: not reward token");
    if (claimToken == underlying) {
      require(cToken.redeemUnderlying(amount) == 0, "CompoundRewardToken: redeemUnderlying failed");
    } else {
      claimComp();
    }
  }

  /*** Compound Interface ***/

  //@dev Only shows the COMP accrued up until the last interaction with the cToken.
  function getCompRewards() internal view returns (uint256) {
    uint256 compAccrued = cToken.comptroller().compAccrued(address(this));
    return IERC20(comp).balanceOf(address(this)).add(compAccrued);
  }

  function claimComp() internal {
    ICToken[] memory cTokens = new ICToken[](1);
    cTokens[0] = cToken;
    cToken.comptroller().claimComp(address(this), cTokens);
  }

  function getUnderlyingRate() internal view returns (uint256) {
    uint256 supplyRatePerBlock = cToken.supplyRatePerBlock();
    return rateToAPY(supplyRatePerBlock);
  }

  // @dev APY = (1 + rate) ^ 365 - 1
  function rateToAPY(uint apr) internal pure returns (uint256) {
    uint256 ratePerDay = apr.mul(BLOCKS_PER_DAY).add(BASE);
    uint256 acc = ratePerDay;
    for (uint256 i = 1; i < DAYS_PER_YEAR; i++) {
      acc = acc.mul(ratePerDay).div(BASE);
    }
    return acc.sub(BASE);
  }

  function getCompRate() internal view returns (uint256) {
    IComptroller comptroller = cToken.comptroller();
    uint256 compForMarketPerYear = comptroller.compSpeeds(address(cToken)).mul(BLOCKS_PER_YEAR);
    uint256 exchangeRate = cToken.exchangeRateStored();
    uint256 totalSupply = cToken.totalSupply();
    uint256 totalUnderlying = totalSupply.mul(exchangeRate).div(BASE);
    return compForMarketPerYear.mul(BASE).div(totalUnderlying);
  }

  // @dev returns the amount of underlying that this contract's cTokens can be redeemed for
  function balanceOfCTokenUnderlying(address owner) internal view returns (uint256) {
    uint256 exchangeRate = cToken.exchangeRateStored();
    uint256 scaledMantissa = exchangeRate.mul(cToken.balanceOf(owner));
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return scaledMantissa /  BASE;
  }
}