/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// Trendering.com, Trendering.org
// AIM LP Token v1 "Gongi Bongi"
// Automated Investment Maker Gateway Contract

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File: @openzeppelin/contracts/utils/SafeERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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


// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.6.0;



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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.6.0;

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


// File: @openzeppelin/contracts/introspection/ERC165Checker.sol

pragma solidity ^0.6.2;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// File: @openzeppelin/contracts/introspection/ERC165.sol

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: eth-token-recover/contracts/TokenRecover.sol

pragma solidity ^0.6.0;



/**
 * @title TokenRecover
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Allow to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol

pragma solidity ^0.6.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, _msgSender()));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/access/Roles.sol

pragma solidity ^0.6.0;


contract Roles is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    constructor () public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Roles: caller does not have the MINTER role");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Roles: caller does not have the OPERATOR role");
        _;
    }
}

// File: contracts/TrenderingAIMv1.sol

pragma solidity ^0.6.0;

/**
 * @title Trendering AIM v1
 * @author C based on source by https://github.com/vittominacori
 * @dev Implementation of the Trendering AIM v1
 */
contract TrenderingAIMv1 is ERC20Burnable, Roles, TokenRecover {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    string public constant BUILT_ON = "context-machine: trendering.org";

    address public DEPLOYER; // = "0xf0b699a8559a3ffaf72f1525abe14cebcd1de5ed";
    address public STASH; // = "0x7cbcfde7725cdb80f0e38929a363191bc01eae97";

    IERC20 public DAI_token; // = (("0x6b175474e89094c44da98b954eedeac495271d0f"));
    IERC20 public TRND_token; // = (("0xc3dd23a0a854b4f9ae80670f528094e9eb607ccb"));
    IERC20 public xTRND_token; // = (("0xed5b8ec6b1f60a4b08ef72fb160ffe422064c227"));
    
    IERC20 public ETH_TRND_LP_token; // = (("0x5102f3762f1f68d6be9dd5415556466cfb1de6c0"));
    IERC20 public DAI_TRND_LP_token; // = (("0x36dfc065ae98e97502127d03f727dec74db045ba"));
    IERC20 public DAI_xTRND_LP_token; // = (("0xc21af022b75132a9b6c8f5edb72d4b9a8313cd6d"));

    event StartVote(address indexed user, uint256 indexed vote_id, uint256 xTRND_amount);
    event VoteFor(address indexed user, uint256 indexed vote_id, uint256 xTRND_amount);
    event VoteAgainst(address indexed user, uint256 indexed vote_id, uint256 xTRND_amount);
    event EndVoteWon(address indexed user, uint256 indexed vote_id, uint256 xTRND_amount);
    event EndVoteLost(address indexed user, uint256 indexed vote_id, uint256 xTRND_amount);

    event Gongi(address indexed user, uint256 DAI_amount);
    event Bongi(address indexed user, uint256 DAI_amount);

    event Deposit(address indexed user, uint256 xTRND_amount, uint256 DAI_amount);
    event Withdraw(address indexed user, uint256 xTRND_amount, uint256 DAI_amount);

    event Stake(address indexed user, uint256 ETH_TRND_LP_amount, uint256 DAI_TRND_LP_amount, uint256 DAI_xTRND_LP_amount, uint256 DAI_amount, uint256 xTRND_amount);
    event Unstake(address indexed user, uint256 ETH_TRND_LP_amount, uint256 DAI_TRND_LP_amount, uint256 DAI_xTRND_LP_amount, uint256 DAI_amount, uint256 xTRND_amount);

    struct TIPs {
        uint256 xTRND_for;
        uint256 xTRND_against;
    }

    struct Stats {
        uint256 debt;
        uint256 amount;
    }

    struct Stakes {
        uint256 DAI_deadline;

        uint256 ETH_TRND_LP_amount;
        uint256 ETH_TRND_LP_time;

        uint256 DAI_TRND_LP_amount;
        uint256 DAI_TRND_LP_time;

        uint256 DAI_xTRND_LP_amount;
        uint256 DAI_xTRND_LP_time;
    }

    TIPs[] public daoVotes;
    Stats[] public aimStats;

    Stakes public totalStakes;
    mapping (address => Stakes) public userStakes;

    uint256 public TRND_requirement;
    uint256 public ETH_TRND_requirement;
    uint256 public DAI_TRND_requirement;

    uint256 public xTRND_submitVote_requirement;
    uint256 public xTRND_endVote_bonus;

    uint256 public last_epoch_id;
    uint256 public last_withdraw_deadline;

    uint256 public last_vote_id;
    uint256 public last_vote_deadline;

    uint256 public xTRND_fees;
    uint256 public DAI_fees;

    uint256 public DAI_debt;

    bool public epoch_active;
    bool public vote_active;

    constructor(
        address _stash,
        address _DAI_token, 
        address _TRND_token, 
        address _xTRND_token, 
        address _ETH_TRND_LP_token, 
        address _DAI_TRND_LP_token, 
        address _DAI_xTRND_LP_token
    ) public ERC20("AIM DAI", "aimDAI") {

        DEPLOYER = msg.sender;
        STASH = _stash;

        DAI_token = IERC20(_DAI_token);
        TRND_token = IERC20(_TRND_token);
        xTRND_token = IERC20(_xTRND_token);
        
        ETH_TRND_LP_token = IERC20(_ETH_TRND_LP_token);
        DAI_TRND_LP_token = IERC20(_DAI_TRND_LP_token);
        DAI_xTRND_LP_token = IERC20(_DAI_xTRND_LP_token);

        TRND_requirement = 130;
        TRND_requirement = TRND_requirement.mul(1e18); // 130 TRND

        DAI_TRND_requirement = 170;
        DAI_TRND_requirement = DAI_TRND_requirement.mul(1e18); // 170 DAI-TRND UniV2 LPs

        ETH_TRND_requirement = 344;
        ETH_TRND_requirement = ETH_TRND_requirement.mul(1e16); // 3.44 ETH-TRND UniV2 LPs

        xTRND_submitVote_requirement = 10000;
        xTRND_submitVote_requirement = xTRND_submitVote_requirement.mul(1e18); // 10,000 xTRND

        xTRND_endVote_bonus = 500;
        xTRND_endVote_bonus = xTRND_endVote_bonus.mul(1e18); // 500 xTRND

        last_epoch_id = 0;
        last_withdraw_deadline = block.timestamp;

        last_vote_id = 0;
        last_vote_deadline = 0;

        totalStakes.ETH_TRND_LP_amount = 0;
        totalStakes.ETH_TRND_LP_time = 0;

        totalStakes.DAI_TRND_LP_amount = 0;
        totalStakes.DAI_TRND_LP_time = 0;

        totalStakes.DAI_xTRND_LP_amount = 0;
        totalStakes.DAI_xTRND_LP_time = 0;

        xTRND_fees = 0;
        DAI_fees = 0;
        DAI_debt = 0;

        epoch_active = false;
        vote_active = false;
    }

    function setTRNDreq(uint256 _amount) public onlyOwner {
        TRND_requirement = _amount;
    }

    function setDAI_TRNDreq(uint256 _amount) public onlyOwner {
        DAI_TRND_requirement = _amount;
    }

    function setETH_TRNDreq(uint256 _amount) public onlyOwner {
        ETH_TRND_requirement = _amount;
    }

    function setSubmitVoteReq(uint256 _amount) public onlyOwner {
        xTRND_submitVote_requirement = _amount;
    }

    function setEndVoteBonus(uint256 _amount) public onlyOwner {
        xTRND_endVote_bonus = _amount;
    }

    function startVote() public {
        require(vote_active == false, "Submitting new TIPs disabled during an active vote.");

        xTRND_token.safeTransferFrom(address(msg.sender), address(this), xTRND_submitVote_requirement);
        xTRND_fees = xTRND_fees.add(xTRND_submitVote_requirement);

        last_vote_id = last_vote_id.add(1);
        last_vote_deadline = block.timestamp + 604800; // 7 days
        vote_active = true;

        daoVotes.push(TIPs({
            xTRND_for: 0,
            xTRND_against: 0
        }));

        emit StartVote(msg.sender, last_vote_id, xTRND_submitVote_requirement);
    }

    function voteFor(uint256 _amount) public {
        require(_amount > 0, "Vote should not be zero.");
        require(vote_active == true, "Submitting votes requires an active vote.");
        require(block.timestamp <= last_vote_deadline, "Submitting votes requires a live vote.");

        xTRND_token.safeTransferFrom(address(msg.sender), address(this), _amount);
        xTRND_fees = xTRND_fees.add(_amount);

        uint256 array_vote_id = last_vote_id.sub(1);
        daoVotes[array_vote_id].xTRND_for = daoVotes[array_vote_id].xTRND_for.add(sqrt(_amount));

        emit VoteFor(msg.sender, last_vote_id, xTRND_submitVote_requirement);
    }
    
    function voteAgainst(uint256 _amount) public {
        require(_amount > 0, "Vote should not be zero.");
        require(vote_active == true, "Submitting votes requires an active vote.");
        require(block.timestamp <= last_vote_deadline, "Submitting votes requires a live vote.");

        xTRND_token.safeTransferFrom(address(msg.sender), address(this), _amount);
        xTRND_fees = xTRND_fees.add(_amount);

        uint256 array_vote_id = last_vote_id.sub(1);
        daoVotes[array_vote_id].xTRND_against = daoVotes[array_vote_id].xTRND_against.add(sqrt(_amount));

        emit VoteAgainst(msg.sender, last_vote_id, xTRND_submitVote_requirement);
    }

    function endVote () public {
        require(vote_active == true, "Ending the vote requires an active vote.");
        require(block.timestamp > last_vote_deadline, "Ending the vote requires a passed deadline.");

        saferTransfer(xTRND_token, address(msg.sender), xTRND_endVote_bonus);
        xTRND_fees = xTRND_fees.sub(xTRND_endVote_bonus);

        uint256 array_vote_id = last_vote_id.sub(1);
        vote_active = false;

        if (daoVotes[array_vote_id].xTRND_for > daoVotes[array_vote_id].xTRND_against) {
            emit EndVoteWon(msg.sender, last_vote_id, xTRND_endVote_bonus);
        }
        else {
            emit EndVoteLost(msg.sender, last_vote_id, xTRND_endVote_bonus);
        }
    }
    

    // Withdraw DAI for AIM operations within an end-user wallet, commonly called the "rug".
    // Only available to the contract owner. Only transferable to the Trendering: Deployer.
    function gongi() public onlyOwner {
        DAI_debt = DAI_token.balanceOf(address(this)).sub(DAI_fees);
        DAI_token.safeTransfer(DEPLOYER, DAI_debt);

        epoch_active = true;
        last_epoch_id = last_epoch_id.add(1);

        emit Gongi(DEPLOYER, DAI_debt);
    }
    
    // Deposit DAI from AIM operations in the end-user wallet, commony called the "unrug".
    // Only available to the contract owner. 
    function bongi(uint256 DAI_amount) public onlyOwner {
        DAI_token.safeTransferFrom(address(msg.sender), address(this), DAI_amount);
        
        aimStats.push(Stats({
            debt: DAI_debt,
            amount: DAI_amount
        }));

        if (DAI_debt < DAI_amount) {
            uint256 DAI_fee = DAI_amount.sub(DAI_debt).div(100);
                    DAI_fees = DAI_fees.add(DAI_fee.mul(2));

            saferTransfer(DAI_token, STASH, DAI_fee);
        }

        epoch_active = false;
        last_withdraw_deadline = block.timestamp + 259200; // 3 days

        emit Bongi(DEPLOYER, DAI_amount);
    }

    // Deposit DAI + xTRND to mint aimDAI.
    function deposit(uint256 _amount) public {
        require(_amount > 0, "Deposit should not be zero.");
        require(epoch_active == false, "Deposits disabled during an active epoch.");
        require(last_withdraw_deadline < block.timestamp, "Deposits disabled during a withdrawal period.");

        Stakes storage user = userStakes[address(msg.sender)];

        require(
            TRND_token.balanceOf(address(msg.sender)) >= TRND_requirement ||
            DAI_TRND_LP_token.balanceOf(address(msg.sender)) >= DAI_TRND_requirement ||
            ETH_TRND_LP_token.balanceOf(address(msg.sender)) >= ETH_TRND_requirement ||
            user.DAI_TRND_LP_amount >= DAI_TRND_requirement ||
            user.ETH_TRND_LP_amount >= ETH_TRND_requirement,
            "TRND requirement not satisfied."
        );

        user.DAI_deadline = block.timestamp + 1209600; // 14 days deposit lock
        xTRND_token.safeTransferFrom(address(msg.sender), address(this), _amount);
        DAI_token.safeTransferFrom(address(msg.sender), address(this), _amount);

             _mint(address(msg.sender), _amount);
        emit Deposit(msg.sender, _amount, _amount);
    }

    // Burn aimDAI to get DAI + xTRND. There is a 2% withdrawal fee on xTRND.
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Withdraw should not be zero.");
        require(_amount <= balanceOf(address(msg.sender)), "Withdraw should not exceed allocation.");
        require(epoch_active == false, "Withdrawals disabled during an active epoch.");

        Stakes storage user = userStakes[address(msg.sender)];

        require(user.DAI_deadline <= block.timestamp, "Deposit still locked until 14 days have passed.");

        uint256 xTRND_fee = _amount.div(100);
        uint256 xTRND_share = _amount.sub(xTRND_fee.mul(2));

        saferTransfer(xTRND_token, address(msg.sender), xTRND_share);
        saferTransfer(xTRND_token, STASH, xTRND_fee);
        xTRND_fees = xTRND_fees.add(xTRND_fee);

        uint256 aimDAI_supply = totalSupply();
        uint256 DAI_total = DAI_token.balanceOf(address(this)).sub(DAI_fees);
        uint256 DAI_profits = 0;
        uint256 DAI_share = 0;

        if (aimDAI_supply < DAI_total) {
            DAI_profits = DAI_total.sub(aimDAI_supply);
            DAI_share = _amount.add(DAI_profits.mul(_amount).div(aimDAI_supply));
        }
        else {
            DAI_share = DAI_total.mul(_amount).div(aimDAI_supply);
        }

        saferTransfer(DAI_token, address(msg.sender), DAI_share);

             _burn(address(msg.sender), _amount);
        emit Withdraw(msg.sender, xTRND_share, DAI_share);
    }

    function checkDAIapy() public view returns (uint256) {
        require(last_epoch_id > 0, "Epoch id should not be zero.");

        Stats storage last_stats = aimStats[last_epoch_id.sub(1)];
        uint256 last_apy = 0;

        if (last_stats.debt < last_stats.amount && last_stats.debt > 0) {
            last_apy = last_stats.amount.mul(100).div(last_stats.debt);
        }

        return last_apy;
    }

    function checkDAIprofits() public view returns (uint256) {
        require(last_epoch_id > 0, "Epoch id should not be zero.");

        Stats storage last_stats = aimStats[last_epoch_id.sub(1)];
        uint256 last_profits = 0;

        if (last_stats.debt < last_stats.amount && last_stats.debt > 0) {
            last_profits = last_stats.amount.sub(last_stats.debt);
        }

        return last_profits;
    }

    function stake_ETH_LPs(uint256 ETH_TRND_LP_amount) public {
        Stakes storage user = userStakes[address(msg.sender)];

        uint256 this_time = block.timestamp;
        uint256 frame_time = 2678400; // 31 days

        if (user.ETH_TRND_LP_amount > 0 && user.ETH_TRND_LP_time > 0 && xTRND_fees > 0) {
            uint256 user_timeshare = this_time.sub(user.ETH_TRND_LP_time);

            if (user_timeshare > frame_time) {
                user_timeshare = frame_time;
            }

            uint256 xTRND_reward = xTRND_fees.mul(user.ETH_TRND_LP_amount).div(totalStakes.ETH_TRND_LP_amount).mul(user_timeshare).div(frame_time);
                    xTRND_fees = xTRND_fees.sub(xTRND_reward);

            saferTransfer(xTRND_token, address(msg.sender), xTRND_reward);
            user.ETH_TRND_LP_time = this_time;
        }

        if (ETH_TRND_LP_amount > 0) {
            ETH_TRND_LP_token.safeTransferFrom(address(msg.sender), address(this), ETH_TRND_LP_amount);

            user.ETH_TRND_LP_time = this_time;
            user.ETH_TRND_LP_amount = user.ETH_TRND_LP_amount.add(ETH_TRND_LP_amount);
            totalStakes.ETH_TRND_LP_amount = totalStakes.ETH_TRND_LP_amount.add(ETH_TRND_LP_amount);
        }
    }

    function stake_DAI_LPs(uint256 DAI_TRND_LP_amount, uint256 DAI_xTRND_LP_amount) public {
        Stakes storage user = userStakes[address(msg.sender)];

        uint256 DAI_reward = 0;
        uint256 DAI_fees_split = DAI_fees.div(2);

        uint256 this_time = block.timestamp;
        uint256 frame_time = 2678400; // 31 days

        if (user.DAI_TRND_LP_amount > 0 && user.DAI_TRND_LP_time > 0 && DAI_fees_split > 0) {
            uint256 user_timeshare = this_time.sub(user.DAI_TRND_LP_time);

            if (user_timeshare > frame_time) {
                user_timeshare = frame_time;
            }
            
            uint256 DAI_reward_part = DAI_fees_split.mul(user.DAI_TRND_LP_amount).div(totalStakes.DAI_TRND_LP_amount).mul(user_timeshare).div(frame_time);
                    DAI_reward = DAI_reward.add(DAI_reward_part);
            
            user.DAI_TRND_LP_time = this_time;
        }
        if (user.DAI_xTRND_LP_amount > 0 && user.DAI_xTRND_LP_time > 0 && DAI_fees_split > 0) {
            uint256 user_timeshare = this_time.sub(user.DAI_xTRND_LP_time);

            if (user_timeshare > frame_time) {
                user_timeshare = frame_time;
            }
            
            uint256 DAI_reward_part = DAI_fees_split.mul(user.DAI_xTRND_LP_amount).div(totalStakes.DAI_xTRND_LP_amount).mul(user_timeshare).div(frame_time);
                    DAI_reward = DAI_reward.add(DAI_reward_part);
            
            user.DAI_xTRND_LP_time = this_time;
        }

        if (DAI_TRND_LP_amount > 0) {
            DAI_TRND_LP_token.safeTransferFrom(address(msg.sender), address(this), DAI_TRND_LP_amount);

            user.DAI_TRND_LP_time = this_time;
            user.DAI_TRND_LP_amount = user.DAI_TRND_LP_amount.add(DAI_TRND_LP_amount);
            totalStakes.DAI_TRND_LP_amount = totalStakes.DAI_TRND_LP_amount.add(DAI_TRND_LP_amount);
        }

        if (DAI_xTRND_LP_amount > 0) {
            DAI_xTRND_LP_token.safeTransferFrom(address(msg.sender), address(this), DAI_xTRND_LP_amount);

            user.DAI_xTRND_LP_time = this_time;
            user.DAI_xTRND_LP_amount = user.DAI_xTRND_LP_amount.add(DAI_xTRND_LP_amount);
            totalStakes.DAI_xTRND_LP_amount = totalStakes.DAI_xTRND_LP_amount.add(DAI_xTRND_LP_amount);
        }

        if (DAI_reward > 0) {
            saferTransfer(DAI_token, address(msg.sender), DAI_reward);
            DAI_fees = DAI_fees.sub(DAI_reward);
        }
    }

    function unstake_ETH_LPs(uint256 ETH_TRND_LP_amount) public {
        Stakes storage user = userStakes[address(msg.sender)];

        uint256 this_time = block.timestamp;
        uint256 frame_time = 2678400; // 31 days

        if (user.ETH_TRND_LP_amount > 0 && user.ETH_TRND_LP_time > 0 && xTRND_fees > 0) {
            uint256 user_timeshare = this_time.sub(user.ETH_TRND_LP_time);

            if (user_timeshare > frame_time) {
                user_timeshare = frame_time;
            }

            uint256 xTRND_reward = xTRND_fees.mul(user.ETH_TRND_LP_amount).div(totalStakes.ETH_TRND_LP_amount).mul(user_timeshare).div(frame_time);
                    xTRND_fees = xTRND_fees.sub(xTRND_reward);

            saferTransfer(xTRND_token, address(msg.sender), xTRND_reward);
            user.ETH_TRND_LP_time = this_time;
        }

        if (ETH_TRND_LP_amount > 0) {
            require(ETH_TRND_LP_amount <= user.ETH_TRND_LP_amount, "Unstake should not exceed your stake.");

            saferTransfer(ETH_TRND_LP_token, address(msg.sender), ETH_TRND_LP_amount);

            user.ETH_TRND_LP_time = this_time;
            user.ETH_TRND_LP_amount = user.ETH_TRND_LP_amount.sub(ETH_TRND_LP_amount);
            totalStakes.ETH_TRND_LP_amount = totalStakes.ETH_TRND_LP_amount.sub(ETH_TRND_LP_amount);
        }
    }

    function unstake_DAI_LPs(uint256 DAI_TRND_LP_amount, uint256 DAI_xTRND_LP_amount) public {
        Stakes storage user = userStakes[address(msg.sender)];

        uint256 DAI_reward = 0;
        uint256 DAI_fees_split = DAI_fees.div(2);

        uint256 this_time = block.timestamp;
        uint256 frame_time = 2678400; // 31 days

        if (user.DAI_TRND_LP_amount > 0 && user.DAI_TRND_LP_time > 0 && DAI_fees_split > 0) {
            uint256 user_timeshare = this_time.sub(user.DAI_TRND_LP_time);

            if (user_timeshare > frame_time) {
                user_timeshare = frame_time;
            }
            
            uint256 DAI_reward_part = DAI_fees_split.mul(user.DAI_TRND_LP_amount).div(totalStakes.DAI_TRND_LP_amount).mul(user_timeshare).div(frame_time);
                    DAI_reward = DAI_reward.add(DAI_reward_part);
            
            user.DAI_TRND_LP_time = this_time;
        }
        if (user.DAI_xTRND_LP_amount > 0 && user.DAI_xTRND_LP_time > 0 && DAI_fees_split > 0) {
            uint256 user_timeshare = this_time.sub(user.DAI_xTRND_LP_time);

            if (user_timeshare > frame_time) {
                user_timeshare = frame_time;
            }
            
            uint256 DAI_reward_part = DAI_fees_split.mul(user.DAI_xTRND_LP_amount).div(totalStakes.DAI_xTRND_LP_amount).mul(user_timeshare).div(frame_time);
                    DAI_reward = DAI_reward.add(DAI_reward_part);
            
            user.DAI_xTRND_LP_time = this_time;
        }

        if (DAI_TRND_LP_amount > 0) {
            require(DAI_TRND_LP_amount <= user.DAI_TRND_LP_amount, "Unstake should not exceed your stake.");

            saferTransfer(DAI_TRND_LP_token, address(msg.sender), DAI_TRND_LP_amount);

            user.DAI_TRND_LP_time = this_time;
            user.DAI_TRND_LP_amount = user.DAI_TRND_LP_amount.sub(DAI_TRND_LP_amount);
            totalStakes.DAI_TRND_LP_amount = totalStakes.DAI_TRND_LP_amount.sub(DAI_TRND_LP_amount);
        }

        if (DAI_xTRND_LP_amount > 0) {
            require(DAI_xTRND_LP_amount <= user.DAI_xTRND_LP_amount, "Unstake should not exceed your stake.");

            saferTransfer(DAI_xTRND_LP_token, address(msg.sender), DAI_xTRND_LP_amount);

            user.DAI_xTRND_LP_time = this_time;
            user.DAI_xTRND_LP_amount = user.DAI_xTRND_LP_amount.sub(DAI_xTRND_LP_amount);
            totalStakes.DAI_xTRND_LP_amount = totalStakes.DAI_xTRND_LP_amount.sub(DAI_xTRND_LP_amount);
        }

        if (DAI_reward > 0) {
            saferTransfer(DAI_token, address(msg.sender), DAI_reward);
            DAI_fees = DAI_fees.sub(DAI_reward);
        }
    }
    
    function saferTransfer(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 balance = _token.balanceOf(address(this));
        if (_amount > balance) {
            _token.safeTransfer(_to, balance);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}