/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol

pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

pragma solidity >=0.6.0 <0.8.0;




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


// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

pragma solidity >=0.6.0 <0.8.0;

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

// File: node_modules\@openzeppelin\contracts\token\ERC20\ERC20.sol

pragma solidity >=0.6.0 <0.8.0;




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
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * Requirements:
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
     * Requirements:
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

// File: @openzeppelin\contracts\token\ERC20\ERC20Burnable.sol

pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

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

// File: contracts\ENERGY.sol

pragma solidity 0.7.6;




contract ENERGY is ERC20Burnable {
  using SafeMath for uint256;

  uint256 public constant initialSupply = 89099136 * 10 ** 3;
  uint256 public lastWeekTime;
  uint256 public weekCount;
  //staking start when week count set to 1 -> rewards calculated before just updating week
  uint256 public constant totalWeeks = 100;
  address public stakingContrAddr;
  address public liquidityContrAddr;
  uint256 public constant timeStep = 1 weeks;
  
  modifier onlyStaking() {
    require(_msgSender() == stakingContrAddr, "Not staking contract");
    _;
  }

  constructor (address _liquidityContrAddr) ERC20("ENERGY", "NRGY") {
    //89099.136 coins
    _setupDecimals(6);
    lastWeekTime = block.timestamp;
    liquidityContrAddr = _liquidityContrAddr;
    _mint(_msgSender(), initialSupply.mul(4).div(10)); //40%
    _mint(liquidityContrAddr, initialSupply.mul(6).div(10)); //60%
  }

  function mintNewCoins(uint256[3] memory lastWeekRewards) public onlyStaking returns(bool) {
    if(weekCount >= 1) {
        uint256 newMint = lastWeekRewards[0].add(lastWeekRewards[1]).add(lastWeekRewards[2]);
        uint256 liquidityMint = (newMint.mul(20)).div(100);
        _mint(liquidityContrAddr, liquidityMint);
        _mint(stakingContrAddr, newMint);
    } else {
        _mint(liquidityContrAddr, initialSupply);
    }
    return true;
  }

  //updates only at end of week
  function updateWeek() public onlyStaking {
    weekCount++;
    lastWeekTime = block.timestamp;
  }

  function updateStakingContract(address _stakingContrAddr) public {
    require(stakingContrAddr == address(0), "Staking contract is already set");
    stakingContrAddr = _stakingContrAddr;
  }

  function burnOnUnstake(address account, uint256 amount) public onlyStaking {
      _burn(account, amount);
  }

  function getLastWeekUpdateTime() public view returns(uint256) {
    return lastWeekTime;
  }

  function isMintingCompleted() public view returns(bool) {
    if(weekCount > totalWeeks) {
      return true;
    } else {
      return false;
    }
  }

  function isGreaterThanAWeek() public view returns(bool) {
    if(block.timestamp > getLastWeekUpdateTime().add(timeStep)) {
      return true;
    } else {
      return false;
    }
  }
}

// File: contracts\NRGYMarketMaker.sol

pragma solidity 0.7.6;



contract NRGYMarketMaker  {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    struct UserData {
        address user;
        bool isActive;
        uint256 rewards;
        uint256 feeRewards;
        uint256 depositTime;
        uint256 share;
        //update when user came first time or after unstaking to stake
        uint256 startedWeek;
        //update everytime whenever user comes to unstake
        uint256 endedWeek;
        mapping(uint256 => uint256) shareByWeekNo;
    }
    
    struct FeeRewardData {
        uint256 value;
        uint256 timeStamp;
        uint256 totalStakersAtThatTime;
        uint256 weekGiven;
        mapping(address => bool) isClaimed;
    }

    ENERGY public energy;
    IERC20 public lpToken;
    uint256 public totalShares;
    //initially it will be 27000
    uint256[] public stakingLimit;
    uint256 public constant minStakeForFeeRewards = 25 * 10 ** 6;
    uint256 public totalRewards;
    uint256 public totalFeeRewards;
    uint256 public rewardsAvailableInContract;
    uint256 public feeRewardsAvailableInContract;
    uint256 public feeRewardsCount;
    uint256 public totalStakeUsers;
    uint256 public constant percentageDivider = 100;
    //10%, 30%, 60%
    uint256[3] private rewardPercentages = [10, 30, 60];
    //7.5%
    uint256 public constant unstakeFees = 75;
    //total weeks
    uint256 public totalWeeks;
    
    //user informations
    mapping(uint256 => address) public userList;
    mapping(address => UserData) public userInfo;
    mapping (address => bool) public smartContractStakers;
    
    //contract info
    mapping(uint256 => uint256) private stakePerWeek;
    mapping(uint256 => uint256) private totalSharesByWeek;
    mapping(uint256 => uint256[3]) private rewardByWeek;
    mapping(uint256 => FeeRewardData) private feeRewardData;

    event Staked(address indexed _user, uint256 _amountStaked, uint256 _balanceOf);
    event Withdrawn(address indexed _user,
                    uint256 _amountTransferred,
                    uint256 _amountUnstaked,
                    uint256 _shareDeducted,
                    uint256 _rewardsDeducted,
                    uint256 _feeRewardsDeducted);
    event RewardDistributed(uint256 _weekNo, uint256[3] _lastWeekRewards);
    event FeeRewardDistributed(uint256 _amount, uint256 _totalFeeRewards);

    constructor(address _energy) {
        energy = ENERGY(_energy);
        lpToken = IERC20(_energy);
        totalWeeks = energy.totalWeeks();
        stakingLimit.push(27000 * 10 ** 6);
    }

    // stake the coins
    function stake(uint256 amount) public {
        _stake(amount, tx.origin);
    }
    
    function stakeOnBehalf(uint256 amount, address _who) public {
        _stake(amount, _who);
    }

    function _stake(uint256 _amount, address _who) internal {
        uint256 _weekCount = energy.weekCount();
        bool isWeekOver = energy.isGreaterThanAWeek();

        if((_weekCount >= 1 && !isWeekOver) || _weekCount == 0) {
            require(!isStakingLimitReached(_amount, _weekCount), "Stake limit has been reached");
        }

        //if week over or week is 0
        if(!isWeekOver || _weekCount == 0) {
            //add current week stake
            stakePerWeek[_weekCount] = getStakeByWeekNo(_weekCount).add(_amount);
            // update current week cumulative stake
            //store total shares by week no at time of stake
            totalSharesByWeek[_weekCount] = totalShares.add(_amount);
            userInfo[_who].shareByWeekNo[_weekCount] = getUserShareByWeekNo(_who, _weekCount).add(_amount);

            //if current week share is 0 get share for previous week
            if(_weekCount == 0) {
                if(stakingLimit[0] == totalShares.add(_amount)) {
                    setStakingLimit(_weekCount, stakingLimit[0]);
                    energy.mintNewCoins(getRewardsByWeekNo(0));
                    energy.updateWeek();
                }
            }
        } else/*is week is greater than 1 and is over */ {
            //update this week shae by adding previous week share
            userInfo[_who].shareByWeekNo[_weekCount.add(1)] = getUserShareByWeekNo(_who, _weekCount).add(_amount);
            //update next week stake
            stakePerWeek[_weekCount.add(1)] = getStakeByWeekNo(_weekCount.add(1)).add(_amount);
            //update next week cumulative stake
            //store total shares of next week no at time of stake
            totalSharesByWeek[_weekCount.add(1)] = totalShares.add(_amount);
            setStakingLimit(_weekCount, totalShares);
            energy.updateWeek();
            //if week over update followings and greater than 1
            /*give rewards only after week end and till 3 more weeks of total weeks */
            if(_weekCount <= totalWeeks.add(3)) {
                //store rewards generated that week by week no at end of week
                //eg: when week 1 is over, it will store rewards generated that week before week changed from 1 to 2
                setRewards(_weekCount);
                uint256 rewardDistributed = (rewardByWeek[_weekCount][0])
                                .add(rewardByWeek[_weekCount][1])
                                .add(rewardByWeek[_weekCount][2]);
                totalRewards = totalRewards.add(rewardDistributed);
                energy.mintNewCoins(getRewardsByWeekNo(_weekCount));
                rewardsAvailableInContract = rewardsAvailableInContract.add(rewardDistributed);
                emit RewardDistributed(_weekCount, getRewardsByWeekNo(_weekCount));
            }
        }
        
        //if user not active, set current week as his start week
        if(!getUserStatus(_who)) {
            userInfo[_who].isActive = true;
            if(getUserShare(_who) < minStakeForFeeRewards) {
                userInfo[_who].startedWeek = _weekCount;
                userInfo[_who].depositTime = block.timestamp;
            }
        }
        
        if(!isUserPreviouslyStaked(_who)) {
            userList[totalStakeUsers] = _who;
            totalStakeUsers++;
            smartContractStakers[_who] = true;
            userInfo[_who].user = _who;
        }
        
        userInfo[_who].share = userInfo[_who].share.add(_amount);
        //update total shares in the end
        totalShares = totalShares.add(_amount);
        
        //if-> user is directly staking
        if(msg.sender == tx.origin) {
            // now we can issue shares
            lpToken.safeTransferFrom(_who, address(this), _amount);
        } else /*through liquity contract */ {
            // now we can issue shares
            //transfer from liquidty contract
            lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        }
        emit Staked(_who, _amount, claimedBalanceOf(_who));
    }
    
    function setStakingLimit(uint256 _weekCount, uint256 _share) internal {
        uint256 lastWeekStakingLeft = stakingLimit[_weekCount].sub(getStakeByWeekNo(_weekCount));
        // first 4 weeks are: 0,1,2,3
        if(_weekCount <= 3) {
            //32%
            stakingLimit.push((_share.mul(32)).div(percentageDivider));
        }
        if(_weekCount > 3) {
            //0.04%
            stakingLimit.push((_share.mul(4)).div(percentageDivider));
        }
        stakingLimit[_weekCount.add(1)] = stakingLimit[_weekCount.add(1)].add(lastWeekStakingLeft);
    }
    
    function setRewards(uint256 _weekCount) internal {
        (rewardByWeek[_weekCount][0],
        rewardByWeek[_weekCount][1],
        rewardByWeek[_weekCount][2]) = calculateRewardsByWeekCount(_weekCount);
    }
    
    function calculateRewards() public view returns(uint256 _lastWeekReward, uint256 _secondLastWeekReward, uint256 _thirdLastWeekReward) {
        return calculateRewardsByWeekCount(energy.weekCount());
    }
    
    function calculateRewardsByWeekCount(uint256 _weekCount) public view returns(uint256 _lastWeekReward, uint256 _secondLastWeekReward, uint256 _thirdLastWeekReward) {
        bool isLastWeek = (_weekCount >= totalWeeks);
        if(isLastWeek) {
            if(_weekCount.sub(totalWeeks) == 0) {
                _lastWeekReward = (getStakeByWeekNo(_weekCount).mul(rewardPercentages[0])).div(percentageDivider);
                _secondLastWeekReward = (getStakeByWeekNo(_weekCount.sub(1)).mul(rewardPercentages[1])).div(percentageDivider);
                _thirdLastWeekReward = (getStakeByWeekNo(_weekCount.sub(2)).mul(rewardPercentages[2])).div(percentageDivider);
            } else if(_weekCount.sub(totalWeeks) == 1) {
                _secondLastWeekReward = (getStakeByWeekNo(_weekCount.sub(1)).mul(rewardPercentages[1])).div(percentageDivider);
                _thirdLastWeekReward = (getStakeByWeekNo(_weekCount.sub(2)).mul(rewardPercentages[2])).div(percentageDivider);
            } else if(_weekCount.sub(totalWeeks) == 2) {
                _thirdLastWeekReward = (getStakeByWeekNo(_weekCount.sub(2)).mul(rewardPercentages[2])).div(percentageDivider);
            }
        } else {
            if(_weekCount == 1) {
                _lastWeekReward = (getStakeByWeekNo(_weekCount).mul(rewardPercentages[0])).div(percentageDivider);
            } else if(_weekCount == 2) {
                _lastWeekReward = (getStakeByWeekNo(_weekCount).mul(rewardPercentages[0])).div(percentageDivider);
                _secondLastWeekReward = (getStakeByWeekNo(_weekCount.sub(1)).mul(rewardPercentages[1])).div(percentageDivider);
            } else if(_weekCount >= 3) {
                _lastWeekReward = (getStakeByWeekNo(_weekCount).mul(rewardPercentages[0])).div(percentageDivider);
                _secondLastWeekReward = (getStakeByWeekNo(_weekCount.sub(1)).mul(rewardPercentages[1])).div(percentageDivider);
                _thirdLastWeekReward = (getStakeByWeekNo(_weekCount.sub(2)).mul(rewardPercentages[2])).div(percentageDivider);
            }
        }
    }
    function isStakingLimitReached(uint256 _amount, uint256 _weekCount) public view returns(bool) {
        return (getStakeByWeekNo(_weekCount).add(_amount) > stakingLimit[_weekCount]);
    }

    function remainingStakingLimit(uint256 _weekCount) public view returns(uint256) {
        return (stakingLimit[_weekCount].sub(getStakeByWeekNo(_weekCount)));
    }

    function distributeFees(uint256 _amount) public {
        uint256 _weekCount = energy.weekCount();
        FeeRewardData storage _feeRewardData = feeRewardData[feeRewardsCount];
        _feeRewardData.value = _amount;
        _feeRewardData.timeStamp = block.timestamp;
        _feeRewardData.totalStakersAtThatTime = totalStakeUsers;
        _feeRewardData.weekGiven = _weekCount;
        feeRewardsCount++;
        totalFeeRewards = totalFeeRewards.add(_amount);
        feeRewardsAvailableInContract = feeRewardsAvailableInContract.add(_amount);
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit FeeRewardDistributed(_amount, totalFeeRewards);
    }

    ///unstake the coins
    function unstake(uint256 _amount) public {
        UserData storage _user = userInfo[msg.sender];
        uint256 _weekCount = energy.weekCount();
        //get user rewards till date(week) and add to claimed rewards
        userInfo[msg.sender].rewards = _user.rewards
                                        .add(getUserRewardsByWeekNo(msg.sender, _weekCount));
        //get user fee rewards till date(week) and add to claimed fee rewards
        userInfo[msg.sender].feeRewards = _user.feeRewards.add(_calculateFeeRewards(msg.sender));
        require(_amount <= claimedBalanceOf(msg.sender), "Unstake amount is greater than user balance");
        //calculate unstake fee
        uint256 _fees = (_amount.mul(unstakeFees)).div(1000);
        //calulcate amount to transfer to user
        uint256 _toTransfer = _amount.sub(_fees);
        //burn unstake fees
        energy.burnOnUnstake(address(this), _fees);
        lpToken.safeTransfer(msg.sender, _toTransfer);
        //if amount can be paid from rewards
        if(_amount <= getUserTotalRewards(msg.sender)) {
            //if amount can be paid from rewards
            if(_user.rewards >= _amount) {
                _user.rewards = _user.rewards.sub(_amount);
                rewardsAvailableInContract = rewardsAvailableInContract.sub(_amount);
                emit Withdrawn(msg.sender, _toTransfer, _amount, 0, _amount, 0);
            } else/*else take sum of fee rewards and rewards */ {
                //get remaining amount less than rewards
                uint256 remAmount = _amount.sub(_user.rewards);
                rewardsAvailableInContract = rewardsAvailableInContract.sub(_user.rewards);
                feeRewardsAvailableInContract = feeRewardsAvailableInContract.sub(remAmount);
                emit Withdrawn(msg.sender, _toTransfer, _amount, 0, _user.rewards, remAmount);
                //update fee rewards from remaining amount
                _user.rewards = 0;
                _user.feeRewards = _user.feeRewards.sub(remAmount);
            }
        } else/* take from total shares*/ {
            //get remaining amount less than rewards
            uint256 remAmount = _amount.sub(getUserTotalRewards(msg.sender));
            rewardsAvailableInContract = rewardsAvailableInContract.sub(_user.rewards);
            feeRewardsAvailableInContract = feeRewardsAvailableInContract.sub(_user.feeRewards);
            emit Withdrawn(msg.sender, _toTransfer, _amount, remAmount, _user.rewards, _user.feeRewards);
            _user.rewards = 0;
            _user.feeRewards = 0;
            //update user share from remaining amount
            _user.share = _user.share.sub(remAmount);
            //update total shares
            totalShares = totalShares.sub(remAmount);
            //update total shares by week no at time of unstake
            totalSharesByWeek[_weekCount] = totalSharesByWeek[_weekCount].sub(remAmount);
        }
        lpToken.safeApprove(address(this), 0);
        //set user status to false
        _user.isActive = false;
        //update user end(unstake) week
        _user.endedWeek = _weekCount == 0 ? _weekCount : _weekCount.sub(1);
    }
    
    function _calculateFeeRewards(address _who) internal returns(uint256) {
        uint256 _accumulatedRewards;
        //check if user have minimum share too claim fee rewards
        if(getUserShare(_who) >= minStakeForFeeRewards) {
            //loop through all the rewards
            for(uint256 i = 0; i < feeRewardsCount; i++) {
                //if rewards week and timestamp is greater than user deposit time and rewards. 
                //Also only if user has not claimed particular fee rewards
                if(getUserStartedWeek(_who) <= feeRewardData[i].weekGiven
                    && getUserLastDepositTime(_who) < feeRewardData[i].timeStamp 
                    && !feeRewardData[i].isClaimed[_who]) {
                    _accumulatedRewards = _accumulatedRewards.add(feeRewardData[i].value.div(feeRewardData[i].totalStakersAtThatTime));
                    feeRewardData[i].isClaimed[_who] = true;
                }
            }
        }
        return _accumulatedRewards;
    }

    /*
    *   ------------------Getter inteface for user---------------------
    *
    */
    
    function getUserUnclaimedFeesRewards(address _who) public view returns(uint256) {
        uint256 _accumulatedRewards;
        //check if user have minimum share too claim fee rewards
        if(getUserShare(_who) >= minStakeForFeeRewards) {
            //loop through all the rewards
            for(uint256 i = 0; i < feeRewardsCount; i++) {
                //if rewards week and timestamp is greater than user deposit time and rewards. 
                //Also only if user has not claimed particular fee rewards
                if(getUserStartedWeek(_who) <= feeRewardData[i].weekGiven
                    && getUserLastDepositTime(_who) < feeRewardData[i].timeStamp 
                    && !feeRewardData[i].isClaimed[_who]) {
                    _accumulatedRewards = _accumulatedRewards.add(feeRewardData[i].value.div(feeRewardData[i].totalStakersAtThatTime));
                }
            }
        }
        return _accumulatedRewards;
    }
    
    //return rewards till weekcount passed
    function getUserCurrentRewards(address _who) public view returns(uint256) {
        uint256 _weekCount = energy.weekCount();
        uint256[3] memory thisWeekReward;
        (thisWeekReward[0],
        thisWeekReward[1],
        thisWeekReward[2]) = calculateRewardsByWeekCount(_weekCount);
        uint256 userShareAtThatWeek = getUserPercentageShareByWeekNo(_who, _weekCount);
        return getUserRewardsByWeekNo(_who, _weekCount)
                .add(_calculateRewardByUserShare(thisWeekReward, userShareAtThatWeek))
                .add(getUserRewards(_who));
    }
    
    //return rewards till one week less than the weekcount passed
    //calculate rewards till previous week and deduct rewards claimed at time of unstake
    //return rewards available to claim
    function getUserRewardsByWeekNo(address _who, uint256 _weekCount) public view returns(uint256) {
        uint256 rewardsAccumulated;
        uint256 userEndWeek = getUserEndedWeek(_who);
        //clculate rewards only if user is active or user share is greater than 1
        if(getUserStatus(_who) || (getUserShare(_who) > 0)) {
            for(uint256 i = userEndWeek.add(1); i < _weekCount; i++) {
                uint256 userShareAtThatWeek = getUserPercentageShareByWeekNo(_who, i);
                rewardsAccumulated = rewardsAccumulated.add(_calculateRewardByUserShare(getRewardsByWeekNo(i), userShareAtThatWeek));
            }
        }
        return rewardsAccumulated;
    }
    
    function _calculateRewardByUserShare(uint256[3] memory rewardAtThatWeek, uint256 userShareAtThatWeek) internal pure returns(uint256) {
        return (((rewardAtThatWeek[0]
                    .add(rewardAtThatWeek[1])
                    .add(rewardAtThatWeek[2]))
                    .mul(userShareAtThatWeek))
                    .div(percentageDivider.mul(percentageDivider)));
    }

    function getUserPercentageShareByWeekNo(address _who, uint256 _weekCount) public view returns(uint256) {
        return _getUserPercentageShareByValue(getSharesByWeekNo(_weekCount), getUserShareByWeekNo(_who, _weekCount));
    }

    function _getUserPercentageShareByValue(uint256 _totalShares, uint256 _userShare) internal pure returns(uint256) {
        if(_totalShares == 0 || _userShare == 0) {
            return 0;
        } else {
            //two times percentageDivider multiplied because of decimal percentage which are less than 1
            return (_userShare.mul(percentageDivider.mul(percentageDivider))).div(_totalShares);
        }
    }

    //give sum of share(staked amount) + rewards is user have a claimed it through unstaking
    function claimedBalanceOf(address _who) public view returns(uint256) {
        return getUserShare(_who).add(getUserRewards(_who)).add(getUserFeeRewards(_who));
    }
    
    function getUserRewards(address _who) public view returns(uint256) {
        return userInfo[_who].rewards;
    }

    function getUserFeeRewards(address _who) public view returns(uint256) {
        return userInfo[_who].feeRewards;
    }
    
    function getUserTotalRewards(address _who) public view returns(uint256) {
        return userInfo[_who].feeRewards.add(userInfo[_who].rewards);
    }

    function getUserShare(address _who) public view returns(uint256) {
        return userInfo[_who].share;
    }
    
    function getUserShareByWeekNo(address _who, uint256 _weekCount) public view returns(uint256) {
        if(getUserStatus(_who)) {
            return (_userShareByWeekNo(_who, _weekCount) > 0 || _weekCount == 0)
                    ? _userShareByWeekNo(_who, _weekCount)
                    : getUserShareByWeekNo(_who, _weekCount.sub(1));
        } else if(getUserShare(_who) > 0) {
            return getUserShare(_who);            
        }
        return 0;
    }
    
    function _userShareByWeekNo(address _who, uint256 _weekCount) internal view returns(uint256) {
        return userInfo[_who].shareByWeekNo[_weekCount];
    }

    function getUserStatus(address _who) public view returns(bool) {
        return userInfo[_who].isActive;
    }
    
    function getUserStartedWeek(address _who) public view returns(uint256) {
        return userInfo[_who].startedWeek;
    }
    
    function getUserEndedWeek(address _who) public view returns(uint256) {
        return userInfo[_who].endedWeek;
    }
    
    function getUserLastDepositTime(address _who) public view returns(uint256) {
        return userInfo[_who].depositTime;
    }

    function isUserPreviouslyStaked(address _who) public view returns(bool) {
        return smartContractStakers[_who];
    }
    
    function getUserFeeRewardClaimStatus(address _who, uint256 _index) public view returns(bool) {
        return feeRewardData[_index].isClaimed[_who];
    }
    
    /*
    *   ------------------Getter inteface for contract---------------------
    *
    */
    
    function getRewardsByWeekNo(uint256 _weekCount) public view returns(uint256[3] memory) {
        return rewardByWeek[_weekCount];
    }
    
    function getFeeRewardsByIndex(uint256 _index) public view returns(uint256, uint256, uint256, uint256) {
        return (feeRewardData[_index].value,
                feeRewardData[_index].timeStamp,
                feeRewardData[_index].totalStakersAtThatTime,
                feeRewardData[_index].weekGiven);
    }
    
    function getRewardPercentages() public view returns(uint256[3] memory) {
        return rewardPercentages;
    }
    
    function getStakeByWeekNo(uint256 _weekCount) public view returns(uint256) {
        return stakePerWeek[_weekCount];
    }
    
    function getSharesByWeekNo(uint256 _weekCount) public view returns(uint256) {
        return totalSharesByWeek[_weekCount];
    }
}