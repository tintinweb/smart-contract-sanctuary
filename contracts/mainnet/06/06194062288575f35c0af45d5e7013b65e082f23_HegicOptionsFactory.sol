// SPDX-License-Identifier: GPL-3.0-or-later
// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

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
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
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
    function sub(uint a, uint b) internal pure returns (uint) {
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
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

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
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
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
    function div(uint a, uint b) internal pure returns (uint) {
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
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
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
    function mod(uint a, uint b) internal pure returns (uint) {
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
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.6.2;

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
    function sendValue(address payable recipient, uint amount) internal {
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
    function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint weiValue, string memory errorMessage) private returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


pragma solidity ^0.6.0;





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
    using SafeMath for uint;
    using Address for address;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;

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
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint) {
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
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint amount) internal virtual {
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
    function _mint(address account, uint amount) internal virtual {
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
    function _burn(address account, uint amount) internal virtual {
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
    function _approve(address owner, address spender, uint amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

interface IHegicOptions {
    event Create(
        uint indexed id,
        address indexed account,
        uint totalFee
    );

    event Exercise(uint indexed id, uint profit);
    event Expire(uint indexed id, uint premium);
    enum State {Inactive, Active, Exercised, Expired}
    enum OptionType {Invalid, Put, Call}

    struct Option {
        State state;
        uint lockID;
        address payable holder;
        uint strike;
        uint amount;
        uint lockedAmount;
        uint premium;
        uint expiration;
        OptionType optionType;
    }

    function options(uint) external view returns (
        State state,
        uint lockID,
        address payable holder,
        uint strike,
        uint amount,
        uint lockedAmount,
        uint premium,
        uint expiration,
        OptionType optionType
    );
}

interface IUniswapV2SlidingOracle {
    function quote(address tokenIn, uint amountIn, address tokenOut, uint granularity) external view returns (uint amountOut);
}

interface ICurveFi {
    function get_virtual_price() external view returns (uint);

    function add_liquidity(
        // sBTC pool
        uint[3] calldata amounts,
        uint min_mint_amount
    ) external;
}
interface IyVault {
    function getPricePerFullShare() external view returns (uint);
    function depositAll() external;
    function balanceOf(address owner) external view returns (uint);
}

interface IHegicERCPool {
    function lock(uint id, uint amount, uint premium) external;
    function unlock(uint id) external;
    function send(uint id, address payable to, uint amount) external;
    function getNextID() external view returns (uint);
    function RESERVE() external view returns (address);
}

// File: contracts/Options/HegicOptions.sol

pragma solidity 0.6.12;

/**
 * Hegic
 * Copyright (C) 2020 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */



/**
 * @author 0mllwntrmt3 & @andrecronje
 * @title Hegic Generic Bidirectional (Call and Put) Options
 * @notice Hegic Protocol Options Contract
 */
contract HegicOptions is IHegicOptions {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    mapping(address => uint[]) public optionsIndexes;
    Option[] public override options;
    uint immutable public impliedVolRate;
    uint immutable internal contractCreationTimestamp;
    
    
    uint internal constant IV_DECIMALS = 1e8;
    IUniswapV2SlidingOracle public constant ORACLE = IUniswapV2SlidingOracle(0xCA2E2df6A7a7Cf5bd19D112E8568910a6C2D3885);
    uint8 constant public GRANULARITY = 8;
    
    IERC20 constant public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address constant public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    ICurveFi constant public CURVE = ICurveFi(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IyVault constant public YEARN = IyVault(0x9cA85572E6A3EbF24dEDd195623F188735A5179f);
    IERC20 constant public CRV3 = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    address immutable public ASSET;
    uint immutable public ONE;
    IHegicERCPool immutable public POOL;
    
    uint public cumulativeStrike;
    uint public cumulativeAmount;
    uint public cumulativeCalls;
    uint public cumulativePuts;
    
    constructor(
        IHegicERCPool _pool,
        address _asset
    ) public {
        POOL = _pool;
        ASSET = _asset;
        ONE = uint(10)**ERC20(_asset).decimals();
        impliedVolRate = 4500;
        contractCreationTimestamp = block.timestamp;
    }
    
    /**
     * @notice Provides a quote of how much output can be expected given the inputs
     * @param tokenIn the asset being received
     * @param amountIn the amount of tokenIn being provided
     * @return minOut the minimum amount of liquidity to send
     */
    function quote(address tokenIn, uint amountIn) public view returns (uint minOut) {
        if (tokenIn != WETH) {
            amountIn = ORACLE.quote(tokenIn, amountIn, WETH, GRANULARITY);
        }
        minOut = ORACLE.quote(WETH, amountIn, address(DAI), GRANULARITY);
    }
    
    function optionsLength() external view returns (uint) {
        return options.length;
    }
    
    function userOptionsLength(address owner) external view returns (uint) {
        return optionsIndexes[owner].length;
    }
    
    /**
     * @notice Creates a new option
     * @param period Option period in seconds (1 days <= period <= 4 weeks)
     * @param amount Option amount
     * @param strike Strike price of the option
     * @param optionType Call or Put option type
     * @return optionID Created option's ID
     */
    function create(
        address asset,
        uint period,
        uint amount, // amount of the underlying asset (address, amountIn)
        uint strike, // price in DAI as per quote(address, uint)
        uint maxFee,
        OptionType optionType
    ) external returns (uint optionID)  {
        require(
            asset == address(DAI) || asset == address(USDC) || asset == address(USDT), 
            "invalid asset"
        );
        require(
            optionType == OptionType.Call || optionType == OptionType.Put,
            "Wrong option type"
        );
        require(period >= 1 days, "Period is too short");
        require(period <= 4 weeks, "Period is too long");
        
        cumulativeAmount = cumulativeAmount.add(amount);
        cumulativeStrike = cumulativeStrike.add(strike.mul(amount));
        
        uint amountInDAI = quote(ASSET, amount);
        
        if (optionType == OptionType.Call) {
            cumulativeCalls = cumulativeCalls.add(amountInDAI);
        } else  {
            cumulativePuts = cumulativePuts.add(amountInDAI);
        }
        
        (uint total,, uint strikeFee, ) =
            fees(period, amountInDAI, strike, optionType);
        
        uint _fee = convertDAI2Asset(asset, total);
        
        require(amount > strikeFee, "price difference is too large");
        require(_fee < maxFee, "fee exceeds max fee");
        optionID = options.length;
        
        IERC20(asset).safeTransferFrom(msg.sender, address(this), _fee);
        convertToY3P();

        Option memory option = Option(
            State.Active, // state
            POOL.getNextID(), // lockID
            msg.sender, // holder
            strike,
            amount,
            DAI2Y3P(amountInDAI),
            YEARN.balanceOf(address(this)), // premium
            block.timestamp + period, // expiration
            optionType
        );

        
        
        options.push(option);
        POOL.lock(option.lockID, option.lockedAmount, option.premium);
        optionsIndexes[msg.sender].push(optionID);

        emit Create(optionID, msg.sender, total);
    }
    
    function convertDAI2Asset(address asset, uint total) public view returns (uint) {
        return total.mul(ERC20(asset).decimals()).div(ERC20(address(DAI)).decimals());
    }

    /**
     * @notice Transfers an active option
     * @param optionID ID of your option
     * @param newHolder Address of new option holder
     */
    function transfer(uint optionID, address payable newHolder) external {
        Option storage option = options[optionID];

        require(newHolder != address(0), "new holder address is zero");
        require(option.expiration >= block.timestamp, "Option has expired");
        require(option.holder == msg.sender, "Wrong msg.sender");
        require(option.state == State.Active, "Only active option could be transferred");

        option.holder = newHolder;
    }

    /**
     * @notice Exercises an active option
     * @param optionID ID of your option
     */
    function exercise(uint optionID) external {
        Option storage option = options[optionID];

        require(option.expiration >= block.timestamp, "Option has expired");
        require(option.holder == msg.sender, "Wrong msg.sender");
        require(option.state == State.Active, "Wrong state");

        option.state = State.Exercised;
        uint profit = _payProfit(optionID);
        
        cumulativeStrike = cumulativeStrike.sub(option.strike);
        cumulativeAmount = cumulativeAmount.sub(option.amount);
        if (option.optionType == OptionType.Call) {
            cumulativeCalls = cumulativeCalls.sub(option.lockedAmount);
        } else if (option.optionType == OptionType.Put) {
            cumulativePuts = cumulativePuts.sub(option.lockedAmount);
        }

        emit Exercise(optionID, profit);
    }

    /**
     * @notice Unlocks an array of options
     * @param optionIDs array of options
     */
    function unlockAll(uint[] calldata optionIDs) external {
        uint arrayLength = optionIDs.length;
        uint _cumulativeStrike;
        uint _cumulativeAmount;
        uint _cumulativeCalls; 
        uint _cumulativePuts;
        
        for (uint i = 0; i < arrayLength; i++) {
            (uint _strike, uint _amount, uint _calls, uint _puts) = _unlock(optionIDs[i]);
            _cumulativeStrike = _cumulativeStrike.add(_strike);
            _cumulativeAmount = _cumulativeAmount.add(_amount);
            _cumulativeCalls = _cumulativeCalls.add(_calls);
            _cumulativePuts = _cumulativePuts.add(_puts);
        }
        
        cumulativeStrike = cumulativeStrike.sub(_cumulativeStrike);
        cumulativeAmount = cumulativeAmount.sub(_cumulativeAmount);
        cumulativeCalls = cumulativeCalls.sub(_cumulativeCalls);
        cumulativePuts = cumulativePuts.sub(_cumulativePuts);
    }

    /**
     * @notice Allows the ERC pool contract to receive and send tokens
     */
    function approve() public {
        IERC20(POOL.RESERVE()).safeApprove(address(POOL), uint(0));
        
        DAI.safeApprove(address(CURVE), uint(0));
        USDT.safeApprove(address(CURVE), uint(0));
        USDC.safeApprove(address(CURVE), uint(0));
        CRV3.safeApprove(address(YEARN), uint(0));
        
        IERC20(POOL.RESERVE()).safeApprove(address(POOL), uint(-1));
        
        DAI.safeApprove(address(CURVE), uint(-1));
        USDT.safeApprove(address(CURVE), uint(-1));
        USDC.safeApprove(address(CURVE), uint(-1));
        CRV3.safeApprove(address(YEARN), uint(-1));
    }

    /**
     * @notice Used for getting the actual options prices
     * @param period Option period in seconds (1 days <= period <= 4 weeks)
     * @param amount Option amount
     * @param strike Strike price of the option
     * @return total Total price to be paid
     * @return settlementFee Amount to be distributed to the HEGIC token holders
     * @return strikeFee Amount that covers the price difference in the ITM options
     * @return periodFee Option period fee amount
     */
    function fees(
        uint period,
        uint amount,
        uint strike,
        OptionType optionType
    )
        public
        view
        returns (
            uint total,
            uint settlementFee,
            uint strikeFee,
            uint periodFee
        )
    {
        uint _cumulativeStrike = cumulativeStrike;
        uint currentPrice = quote(ASSET, ONE);
        uint _avgStrike = _cumulativeStrike == 0 ? currentPrice : _cumulativeStrike.div(cumulativeAmount);
        if (optionType == OptionType.Put) {
            currentPrice = currentPrice.add(currentPrice).sub(_avgStrike);
        } else if (optionType == OptionType.Call) {
            currentPrice = currentPrice.add(_avgStrike).sub(currentPrice);
        }
        settlementFee = getSettlementFee(amount);
        periodFee = getPeriodFee(amount, period, strike, currentPrice, optionType);
        strikeFee = getStrikeFee(amount, strike, currentPrice, optionType);
        total = periodFee.add(strikeFee).add(settlementFee);
        uint _cumulativePuts = cumulativePuts;
        uint _cumulativeCalls = cumulativeCalls;
        if (optionType == OptionType.Put && _cumulativePuts > 0) {
            total = total.mul(_cumulativePuts).div((_cumulativePuts.add(_cumulativeCalls)).div(2));
        } else if (cumulativeCalls > 0) {
            total = total.mul(_cumulativeCalls).div((_cumulativePuts.add(_cumulativeCalls)).div(2));
        }
    }

    /**
     * @notice Unlock funds locked in the expired options
     * @param optionID ID of the option
     */
    function unlock(uint optionID) external {
        (uint _strike, uint _amount, uint _calls, uint _puts) = _unlock(optionID);
        cumulativeStrike = cumulativeStrike.sub(_strike);
        cumulativeAmount = cumulativeAmount.sub(_amount);
        cumulativeCalls = cumulativeCalls.sub(_calls);
        cumulativePuts = cumulativePuts.sub(_puts);
    }
    
    function _unlock(uint optionID) internal returns (uint _strike, uint _amount, uint _calls, uint _puts) {
        Option storage option = options[optionID];
        require(option.expiration < block.timestamp, "Option has not expired yet");
        require(option.state == State.Active, "Option is not active");
        option.state = State.Expired;
        POOL.unlock(optionID);
        _strike = option.strike;
        _amount = option.amount;
        if (option.optionType == OptionType.Call) {
            _calls = option.lockedAmount;
        } else if (option.optionType == OptionType.Put) {
            _puts = option.lockedAmount;
        }
        
        emit Expire(optionID, option.premium);
    }
    
    function price() external view returns (uint) {
        return quote(ASSET, ONE);
    }

    /**
     * @notice Calculates settlementFee
     * @param amount Option amount
     * @return fee Settlement fee amount
     */
    function getSettlementFee(uint amount)
        internal
        pure
        returns (uint fee)
    {
        return amount / 100;
    }

    /**
     * @notice Calculates periodFee
     * @param amount Option amount
     * @param period Option period in seconds (1 days <= period <= 4 weeks)
     * @param strike Strike price of the option
     * @param currentPrice Current price of BTC
     * @return fee Period fee amount
     *
     * amount < 1e30        |
     * impliedVolRate < 1e10| => amount * impliedVolRate * strike < 1e60 < 2^uint
     * strike < 1e20 ($1T)  |
     *
     * in case amount * impliedVolRate * strike >= 2^256
     * transaction will be reverted by the SafeMath
     */
    function getPeriodFee(
        uint amount,
        uint period,
        uint strike,
        uint currentPrice,
        OptionType optionType
    ) internal view returns (uint fee) {
        if (optionType == OptionType.Put)
            return amount
                .mul(sqrt(period))
                .mul(impliedVolRate)
                .mul(strike)
                .div(currentPrice)
                .div(IV_DECIMALS);
        else
            return amount
                .mul(sqrt(period))
                .mul(impliedVolRate)
                .mul(currentPrice)
                .div(strike)
                .div(IV_DECIMALS);
    }

    /**
     * @notice Calculates strikeFee
     * @param amount Option amount
     * @param strike Strike price of the option
     * @param currentPrice Current price of BTC
     * @return fee Strike fee amount
     */
    function getStrikeFee(
        uint amount,
        uint strike,
        uint currentPrice,
        OptionType optionType
    ) internal pure returns (uint fee) {
        if (strike > currentPrice && optionType == OptionType.Put)
            return strike.sub(currentPrice).mul(amount).div(currentPrice);
        if (strike < currentPrice && optionType == OptionType.Call)
            return currentPrice.sub(strike).mul(amount).div(currentPrice);
        return 0;
    }

    /**
     * @notice Sends profits in RESERVE from the RESERVE pool to an option holder's address
     * @param optionID A specific option contract id
     */
    function _payProfit(uint optionID)
        internal
        returns (uint profit)
    {
        Option memory option = options[optionID];
        uint currentPrice = quote(ASSET, ONE);
        if (option.optionType == OptionType.Call) {
            require(option.strike <= currentPrice, "Current price is too low");
            profit = currentPrice.sub(option.strike).mul(option.amount);
        } else {
            require(option.strike >= currentPrice, "Current price is too high");
            profit = option.strike.sub(currentPrice).mul(option.amount);
        }
        if (profit > option.lockedAmount)
            profit = option.lockedAmount;
            
        profit = DAI2Y3P(profit);
        POOL.send(option.lockID, option.holder, profit);
    }
    
    function DAI2Y3P(uint amount) public view returns (uint _yearn) {
        uint _curve = amount.mul(1e18).div(CURVE.get_virtual_price());
        _yearn = _curve.mul(1e18).div(YEARN.getPricePerFullShare());
    }
    
    function convertToY3P() internal {
        CURVE.add_liquidity([DAI.balanceOf(address(this)), USDC.balanceOf(address(this)), USDT.balanceOf(address(this))], 0);
        YEARN.depositAll();
    }

    /**
     * @return result Square root of the number
     */
    function sqrt(uint x) private pure returns (uint result) {
        result = x;
        uint k = x.div(2).add(1);
        while (k < result) (result, k) = (k, x.div(k).add(k).div(2));
    }
}

contract HegicOptionsFactory {
    address public governance;
    address public pendingGovernance;
    
    mapping(address => address) public assetMap;
    mapping(address => bool) public optionExists;
    address[] public options;
    
    
    constructor() public {
        governance = msg.sender;
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "HegicOptionsFactory::setGovernance: !governance");
        pendingGovernance = _governance;
    }
    
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "HegicOptionsFactory::acceptGovernance: !pendingGovernance");
        governance = pendingGovernance;
    }
    
    function all() external view returns (address[] memory) {
        return options;
    }
    
    function deploy(IHegicERCPool _pool, address _asset) external {
        require(msg.sender == governance, "HegicOptionsFactory::deploy: !governance");
        require(!optionExists[_asset], "HegicOptionsFactory::deploy: !governance");
        address _option = address(new HegicOptions(_pool, _asset));
        assetMap[_asset] = _option;
        options.push(_asset);
        optionExists[_asset] = true;
    }
}