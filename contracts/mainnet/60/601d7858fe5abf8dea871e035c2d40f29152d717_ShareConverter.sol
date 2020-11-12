// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

interface IShareConverter {
    function convert_shares_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);

    function convert_shares(address _input, address _output, uint _inputAmount) external returns (uint _outputAmount);
}

interface IValueVaultMaster {
    function bank(address) view external returns (address);
    function isVault(address) view external returns (bool);
    function isController(address) view external returns (bool);
    function isStrategy(address) view external returns (bool);

    function slippage(address) view external returns (uint);
    function convertSlippage(address _input, address _output) view external returns (uint);

    function valueToken() view external returns (address);
    function govVault() view external returns (address);
    function insuranceFund() view external returns (address);
    function performanceReward() view external returns (address);

    function govVaultProfitShareFee() view external returns (uint);
    function gasFee() view external returns (uint);
    function insuranceFee() view external returns (uint);
    function withdrawalProtectionFee() view external returns (uint);
}

// 0: DAI, 1: USDC, 2: USDT
interface IStableSwap3Pool {
    function get_virtual_price() external view returns (uint);
    function balances(uint) external view returns (uint);
    function calc_token_amount(uint[3] calldata amounts, bool deposit) external view returns (uint);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint);
    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
}

interface IDepositBUSD {
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function add_liquidity(uint[4] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
}

// 0: DAI, 1: USDC, 2: USDT, 3: BUSD
interface IStableSwapBUSD {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[4] calldata amounts, bool deposit) external view returns (uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
}

interface IDepositSUSD {
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function add_liquidity(uint[4] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
}

// 0: DAI, 1: USDC, 2: USDT, 3: sUSD
interface IStableSwapSUSD {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[4] calldata amounts, bool deposit) external view returns (uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
}

interface IDepositHUSD {
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function calc_token_amount(uint[4] calldata amounts, bool deposit) external view returns (uint);
    function add_liquidity(uint[4] calldata amounts, uint min_mint_amount) external returns (uint);
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external returns (uint);
}

// 0: hUSD, 1: 3Crv
interface IStableSwapHUSD {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[2] calldata amounts, bool deposit) external view returns (uint);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
    function calc_withdraw_one_coin(uint amount, int128 i) external view returns (uint);
    function remove_liquidity_one_coin(uint amount, int128 i, uint minAmount) external returns (uint);
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external returns (uint);
}

interface IDepositCompound {
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
}

// 0: DAI, 1: USDC
interface IStableSwapCompound {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[2] calldata amounts, bool deposit) external view returns (uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
}

interface yTokenInterface {
    function getPricePerFullShare() external view returns (uint);
}

interface CTokenInterface {
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
}

// 0. 3pool [DAI, USDC, USDT]                  ## APY: 0.88% +8.53% (CRV)                  ## Vol: $16,800,095  ## Liquidity: $163,846,738  (https://etherscan.io/address/0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7)
// 1. BUSD [(y)DAI, (y)USDC, (y)USDT, (y)BUSD] ## APY: 2.54% +11.16%                       ## Vol: $6,580,652   ## Liquidity: $148,930,780  (https://etherscan.io/address/0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27)
// 2. sUSD [DAI, USDC, USDT, sUSD]             ## APY: 2.59% +2.19% (SNX) +13.35% (CRV)    ## Vol: $11,854,566  ## Liquidity: $53,575,781   (https://etherscan.io/address/0xA5407eAE9Ba41422680e2e00537571bcC53efBfD)
// 3. husd [HUSD, 3pool]                       ## APY: 0.53% +8.45% (CRV)                  ## Vol: $0           ## Liquidity: $1,546,077    (https://etherscan.io/address/0x3eF6A01A0f81D6046290f3e2A8c5b843e738E604)
// 4. Compound [(c)DAI, (c)USDC]               ## APY: 3.97% +9.68% (CRV)                  ## Vol: $2,987,370   ## Liquidity: $121,783,878  (https://etherscan.io/address/0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56)
// 5. Y [(y)DAI, (y)USDC, (y)USDT, (y)TUSD]    ## APY: 3.37% +8.39% (CRV)                  ## Vol: $8,374,971   ## Liquidity: $176,470,728  (https://etherscan.io/address/0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51)
// 6. Swerve [(y)DAI...(y)TUSD]                ## APY: 0.43% +6.05% (CRV)                  ## Vol: $1,567,681   ## Liquidity: $28,631,966   (https://etherscan.io/address/0x329239599afB305DA0A2eC69c58F8a6697F9F88d)
contract ShareConverter is IShareConverter {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20[3] public pool3CrvTokens; // DAI, USDC, USDT
    yTokenInterface[4] public poolBUSDyTokens; // yDAI, yUSDC, yUSDT, yBUSD
    CTokenInterface[2] public poolCompoundCTokens;
    IERC20 public token3CRV; // 3Crv

    IERC20 public tokenBUSD; // BUSD
    IERC20 public tokenBCrv; // BCrv (yDAI+yUSDC+yUSDT+yBUSD)

    IERC20 public tokenSUSD; // sUSD
    IERC20 public tokenSCrv; // SCrv (DAI/USDC/USDT/sUSD)

    IERC20 public tokenHUSD; // hUSD
    IERC20 public tokenHCrv; // HCrv (hUSD/3CRV)

    IERC20 public tokenCCrv; // cDAI+cUSDC ((c)DAI+(c)USDC)

    address public governance;

    IStableSwap3Pool public stableSwap3Pool;

    IDepositBUSD public depositBUSD;
    IStableSwapBUSD public stableSwapBUSD;

    IDepositSUSD public depositSUSD;
    IStableSwapSUSD public stableSwapSUSD;

    IDepositHUSD public depositHUSD;
    IStableSwapHUSD public stableSwapHUSD;

    IDepositCompound public depositCompound;
    IStableSwapCompound public stableSwapCompound;

    IValueVaultMaster public vaultMaster;

    // tokens: 0. BUSD, 1. sUSD, 2. hUSD
    // tokenCrvs: 0. BCrv, 1. SCrv, 2. HCrv, 3. CCrv
    // depositUSD: 0. depositBUSD, 1. depositSUSD, 2. depositHUSD, 3. depositCompound
    // stableSwapUSD: 0. stableSwapBUSD, 1. stableSwapSUSD, 2. stableSwapHUSD, 3. stableSwapCompound
    constructor (
        IERC20 _tokenDAI, IERC20 _tokenUSDC, IERC20 _tokenUSDT, IERC20 _token3CRV,
        IERC20[] memory _tokens, IERC20[] memory _tokenCrvs,
        address[] memory _depositUSD, address[] memory _stableSwapUSD,
        yTokenInterface[4] memory _yTokens,
        CTokenInterface[2] memory _cTokens,
        IStableSwap3Pool _stableSwap3Pool,
        IValueVaultMaster _vaultMaster) public {
        pool3CrvTokens[0] = _tokenDAI;
        pool3CrvTokens[1] = _tokenUSDC;
        pool3CrvTokens[2] = _tokenUSDT;

        poolBUSDyTokens = _yTokens;
        poolCompoundCTokens = _cTokens;

        token3CRV = _token3CRV;
        tokenBUSD = _tokens[0];
        tokenBCrv = _tokenCrvs[0];
        tokenSUSD = _tokens[1];
        tokenSCrv = _tokenCrvs[1];
        tokenHUSD = _tokens[2];
        tokenHCrv = _tokenCrvs[2];
        tokenCCrv = _tokenCrvs[3];

        stableSwap3Pool = _stableSwap3Pool;

        depositBUSD = IDepositBUSD(_depositUSD[0]);
        stableSwapBUSD = IStableSwapBUSD(_stableSwapUSD[0]);

        depositSUSD = IDepositSUSD(_depositUSD[1]);
        stableSwapSUSD = IStableSwapSUSD(_stableSwapUSD[1]);

        depositHUSD = IDepositHUSD(_depositUSD[2]);
        stableSwapHUSD = IStableSwapHUSD(_stableSwapUSD[2]);

        depositCompound = IDepositCompound(_depositUSD[3]);
        stableSwapCompound = IStableSwapCompound(_stableSwapUSD[3]);

        for (uint i = 0; i < 3; i++) {
            pool3CrvTokens[i].safeApprove(address(stableSwap3Pool), type(uint256).max);
            pool3CrvTokens[i].safeApprove(address(stableSwapBUSD), type(uint256).max);
            pool3CrvTokens[i].safeApprove(address(depositBUSD), type(uint256).max);
            pool3CrvTokens[i].safeApprove(address(stableSwapSUSD), type(uint256).max);
            pool3CrvTokens[i].safeApprove(address(depositSUSD), type(uint256).max);
            pool3CrvTokens[i].safeApprove(address(stableSwapHUSD), type(uint256).max);
            pool3CrvTokens[i].safeApprove(address(depositHUSD), type(uint256).max);
            if (i < 2) { // DAI && USDC
                pool3CrvTokens[i].safeApprove(address(depositCompound), type(uint256).max);
                pool3CrvTokens[i].safeApprove(address(stableSwapCompound), type(uint256).max);
            }
        }

        token3CRV.safeApprove(address(stableSwap3Pool), type(uint256).max);

        tokenBUSD.safeApprove(address(stableSwapBUSD), type(uint256).max);
        tokenBCrv.safeApprove(address(stableSwapBUSD), type(uint256).max);
        tokenBCrv.safeApprove(address(depositBUSD), type(uint256).max);

        tokenSUSD.safeApprove(address(stableSwapSUSD), type(uint256).max);
        tokenSCrv.safeApprove(address(stableSwapSUSD), type(uint256).max);
        tokenSCrv.safeApprove(address(depositSUSD), type(uint256).max);

        tokenHCrv.safeApprove(address(stableSwapHUSD), type(uint256).max);
        tokenHCrv.safeApprove(address(depositHUSD), type(uint256).max);

        tokenCCrv.safeApprove(address(depositCompound), type(uint256).max);
        tokenCCrv.safeApprove(address(stableSwapCompound), type(uint256).max);

        vaultMaster = _vaultMaster;
        governance = msg.sender;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setVaultMaster(IValueVaultMaster _vaultMaster) external {
        require(msg.sender == governance, "!governance");
        vaultMaster = _vaultMaster;
    }

    function approveForSpender(IERC20 _token, address _spender, uint _amount) external {
        require(msg.sender == governance, "!governance");
        _token.safeApprove(_spender, _amount);
    }

    function convert_shares_rate(address _input, address _output, uint _inputAmount) external override view returns (uint _outputAmount) {
        if (_output == address(token3CRV)) {
            if (_input == address(tokenBCrv)) { // convert from BCrv -> 3CRV
                uint[3] memory _amounts;
                _amounts[1] = depositBUSD.calc_withdraw_one_coin(_inputAmount, 1); // BCrv -> USDC
                _outputAmount = stableSwap3Pool.calc_token_amount(_amounts, true); // USDC -> 3CRV
            } else if (_input == address(tokenSCrv)) { // convert from SCrv -> 3CRV
                uint[3] memory _amounts;
                _amounts[1] = depositSUSD.calc_withdraw_one_coin(_inputAmount, 1); // SCrv -> USDC
                _outputAmount = stableSwap3Pool.calc_token_amount(_amounts, true); // USDC -> 3CRV
            } else if (_input == address(tokenHCrv)) { // convert from HCrv -> 3CRV
                _outputAmount = stableSwapHUSD.calc_withdraw_one_coin(_inputAmount, 1); // HCrv -> 3CRV
            } else if (_input == address(tokenCCrv)) { // convert from CCrv -> 3CRV
                uint[3] memory _amounts;
                uint usdc = depositCompound.calc_withdraw_one_coin(_inputAmount, 1); // CCrv -> USDC
                _amounts[1] = usdc;//convert_usdc_to_cusdc(usdc); // TODO: to implement
                _outputAmount = stableSwap3Pool.calc_token_amount(_amounts, true); // USDC -> 3CRV
            }
        } else if (_output == address(tokenBCrv)) {
            if (_input == address(token3CRV)) { // convert from 3CRV -> BCrv
                uint[4] memory _amounts;
                uint usdc = stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, 1); // 3CRV -> USDC
                _amounts[1] = _convert_underlying_to_ytoken_rate(poolBUSDyTokens[1], usdc); // USDC -> yUSDC
                _outputAmount = stableSwapBUSD.calc_token_amount(_amounts, true); // yUSDC -> BCrv
            } else if (_input == address(tokenSCrv)) { // convert from SCrv -> BCrv
                uint[4] memory _amounts;
                uint usdc = depositSUSD.calc_withdraw_one_coin(_inputAmount, 1); // SCrv -> USDC
                _amounts[1] = _convert_underlying_to_ytoken_rate(poolBUSDyTokens[1], usdc); // USDC -> yUSDC
                _outputAmount = stableSwapBUSD.calc_token_amount(_amounts, true); // yUSDC -> BCrv
            } else if (_input == address(tokenHCrv)) { // convert from HCrv -> BCrv
                uint[4] memory _amounts;
                uint usdc = depositHUSD.calc_withdraw_one_coin(_inputAmount, 2); // HCrv -> USDC
                _amounts[1] = _convert_underlying_to_ytoken_rate(poolBUSDyTokens[1], usdc); // USDC -> yUSDC
                _outputAmount = stableSwapBUSD.calc_token_amount(_amounts, true); // yUSDC -> BCrv
            } else if (_input == address(tokenCCrv)) { // convert from CCrv -> BCrv
                uint[4] memory _amounts;
                uint usdc = depositCompound.calc_withdraw_one_coin(_inputAmount, 1); // CCrv -> USDC
                _amounts[1] = _convert_underlying_to_ytoken_rate(poolBUSDyTokens[1], usdc); // USDC -> yUSDC
                _outputAmount = stableSwapBUSD.calc_token_amount(_amounts, true); // yUSDC -> BCrv
            }
        } else if (_output == address(tokenSCrv)) {
            if (_input == address(token3CRV)) { // convert from 3CRV -> SCrv
                uint[4] memory _amounts;
                _amounts[1] = stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, 1); // 3CRV -> USDC
                _outputAmount = stableSwapSUSD.calc_token_amount(_amounts, true); // USDC -> BCrv
            } else if (_input == address(tokenBCrv)) { // convert from BCrv -> SCrv
                uint[4] memory _amounts;
                _amounts[1] = depositBUSD.calc_withdraw_one_coin(_inputAmount, 1); // BCrv -> USDC
                _outputAmount = stableSwapSUSD.calc_token_amount(_amounts, true); // USDC -> SCrv
            } else if (_input == address(tokenHCrv)) { // convert from HCrv -> SCrv
                uint[4] memory _amounts;
                _amounts[1] = depositHUSD.calc_withdraw_one_coin(_inputAmount, 2); // HCrv -> USDC
                _outputAmount = stableSwapSUSD.calc_token_amount(_amounts, true); // USDC -> SCrv
            } else if (_input == address(tokenCCrv)) { // convert from CCrv -> SCrv
                uint[4] memory _amounts;
                _amounts[1] = depositCompound.calc_withdraw_one_coin(_inputAmount, 1); // CCrv -> USDC
                _outputAmount = stableSwapSUSD.calc_token_amount(_amounts, true); // USDC -> SCrv
            }
        } else if (_output == address(tokenHCrv)) {
            if (_input == address(token3CRV)) { // convert from 3CRV -> HCrv
                uint[2] memory _amounts;
                _amounts[1] = _inputAmount;
                _outputAmount = stableSwapHUSD.calc_token_amount(_amounts, true); // 3CRV -> HCrv
            } else if (_input == address(tokenBCrv)) { // convert from BCrv -> HCrv
                uint[4] memory _amounts;
                _amounts[2] = depositBUSD.calc_withdraw_one_coin(_inputAmount, 1); // BCrv -> USDC
                _outputAmount = depositHUSD.calc_token_amount(_amounts, true); // USDC -> HCrv
            } else if (_input == address(tokenSCrv)) { // convert from SCrv -> HCrv
                uint[4] memory _amounts;
                _amounts[2] = depositSUSD.calc_withdraw_one_coin(_inputAmount, 1); // SCrv -> USDC
                _outputAmount = depositHUSD.calc_token_amount(_amounts, true); // USDC -> HCrv
            } else if (_input == address(tokenCCrv)) { // convert from CCrv -> HCrv
                uint[4] memory _amounts;
                _amounts[2] = depositCompound.calc_withdraw_one_coin(_inputAmount, 1); // CCrv -> USDC
                _outputAmount = depositHUSD.calc_token_amount(_amounts, true); // USDC -> HCrv
            }
        } else if (_output == address(tokenCCrv)) {
            if (_input == address(token3CRV)) { // convert from 3CRV -> CCrv
                uint[2] memory _amounts;
                uint usdc = stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, 1); // 3CRV -> USDC
                _amounts[1] = _convert_underlying_to_ctoken(poolCompoundCTokens[1], usdc); // USDC -> cUSDC
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true); // cUSDC -> CCrv
            } else if (_input == address(tokenBCrv)) { // convert from BCrv -> CCrv
                uint[2] memory _amounts;
                uint usdc = depositBUSD.calc_withdraw_one_coin(_inputAmount, 1); // BCrv -> USDC
                _amounts[1] = _convert_underlying_to_ctoken(poolCompoundCTokens[1], usdc); // USDC -> cUSDC
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true); // cUSDC -> CCrv
            } else if (_input == address(tokenSCrv)) { // convert from SCrv -> CCrv
                uint[2] memory _amounts;
                uint usdc = depositSUSD.calc_withdraw_one_coin(_inputAmount, 1); // SCrv -> USDC
                _amounts[1] = _convert_underlying_to_ctoken(poolCompoundCTokens[1], usdc); // USDC -> cUSDC
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true); // cUSDC -> CCrv
            } else if (_input == address(tokenHCrv)) { // convert from HCrv -> CCrv
                uint[2] memory _amounts;
                uint usdc = depositHUSD.calc_withdraw_one_coin(_inputAmount, 2); // HCrv -> USDC
                _amounts[1] = _convert_underlying_to_ctoken(poolCompoundCTokens[1], usdc); // USDC -> cUSDC
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true); // cUSDC -> CCrv
            }
        }
        if (_outputAmount > 0) {
            uint _slippage = _outputAmount.mul(vaultMaster.convertSlippage(_input, _output)).div(10000);
            _outputAmount = _outputAmount.sub(_slippage);
        }
    }

    function convert_shares(address _input, address _output, uint _inputAmount) external override returns (uint _outputAmount) {
        require(vaultMaster.isVault(msg.sender) || vaultMaster.isController(msg.sender) || msg.sender == governance, "!(governance||vault||controller)");
        if (_output == address(token3CRV)) {
            if (_input == address(tokenBCrv)) { // convert from BCrv -> 3CRV
                uint[3] memory _amounts;
                _amounts[1] = _convert_bcrv_to_usdc(_inputAmount);

                uint _before = token3CRV.balanceOf(address(this));
                stableSwap3Pool.add_liquidity(_amounts, 1);
                uint _after = token3CRV.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenSCrv)) { // convert from SCrv -> 3CRV
                uint[3] memory _amounts;
                _amounts[1] = _convert_scrv_to_usdc(_inputAmount);

                uint _before = token3CRV.balanceOf(address(this));
                stableSwap3Pool.add_liquidity(_amounts, 1);
                uint _after = token3CRV.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenHCrv)) { // convert from HCrv -> 3CRV
                _outputAmount = _convert_hcrv_to_3crv(_inputAmount);
            } else if (_input == address(tokenCCrv)) { // convert from CCrv -> 3CRV
                uint[3] memory _amounts;
                _amounts[1] = _convert_ccrv_to_usdc(_inputAmount);

                uint _before = token3CRV.balanceOf(address(this));
                stableSwap3Pool.add_liquidity(_amounts, 1);
                uint _after = token3CRV.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            }
        } else if (_output == address(tokenBCrv)) {
            if (_input == address(token3CRV)) { // convert from 3CRV -> BCrv
                uint[4] memory _amounts;
                _amounts[1] = _convert_3crv_to_usdc(_inputAmount);

                uint _before = tokenBCrv.balanceOf(address(this));
                depositBUSD.add_liquidity(_amounts, 1);
                uint _after = tokenBCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenSCrv)) { // convert from SCrv -> BCrv
                uint[4] memory _amounts;
                _amounts[1] = _convert_scrv_to_usdc(_inputAmount);

                uint _before = tokenBCrv.balanceOf(address(this));
                depositBUSD.add_liquidity(_amounts, 1);
                uint _after = tokenBCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenHCrv)) { // convert from HCrv -> BCrv
                uint[4] memory _amounts;
                _amounts[1] = _convert_hcrv_to_usdc(_inputAmount);

                uint _before = tokenBCrv.balanceOf(address(this));
                depositBUSD.add_liquidity(_amounts, 1);
                uint _after = tokenBCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenCCrv)) { // convert from CCrv -> BCrv
                uint[4] memory _amounts;
                _amounts[1] = _convert_ccrv_to_usdc(_inputAmount);

                uint _before = tokenBCrv.balanceOf(address(this));
                depositBUSD.add_liquidity(_amounts, 1);
                uint _after = tokenBCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            }
        } else if (_output == address(tokenSCrv)) {
            if (_input == address(token3CRV)) { // convert from 3CRV -> SCrv
                uint[4] memory _amounts;
                _amounts[1] = _convert_3crv_to_usdc(_inputAmount);

                uint _before = tokenSCrv.balanceOf(address(this));
                depositSUSD.add_liquidity(_amounts, 1);
                uint _after = tokenSCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenBCrv)) { // convert from BCrv -> SCrv
                uint[4] memory _amounts;
                _amounts[1] = _convert_bcrv_to_usdc(_inputAmount);

                uint _before = tokenSCrv.balanceOf(address(this));
                depositSUSD.add_liquidity(_amounts, 1);
                uint _after = tokenSCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenHCrv)) { // convert from HCrv -> SCrv
                uint[4] memory _amounts;
                _amounts[1] = _convert_hcrv_to_usdc(_inputAmount);

                uint _before = tokenSCrv.balanceOf(address(this));
                depositSUSD.add_liquidity(_amounts, 1);
                uint _after = tokenSCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenCCrv)) { // convert from CCrv -> SCrv
                uint[4] memory _amounts;
                _amounts[1] = _convert_ccrv_to_usdc(_inputAmount);

                uint _before = tokenSCrv.balanceOf(address(this));
                depositSUSD.add_liquidity(_amounts, 1);
                uint _after = tokenSCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            }
        } else if (_output == address(tokenHCrv)) {
            // todo: re-check
            if (_input == address(token3CRV)) { // convert from 3CRV -> HCrv
                uint[2] memory _amounts;
                _amounts[1] = _inputAmount;

                uint _before = tokenHCrv.balanceOf(address(this));
                stableSwapHUSD.add_liquidity(_amounts, 1);
                uint _after = tokenHCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenBCrv)) { // convert from BCrv -> HCrv
                uint[4] memory _amounts;
                _amounts[2] = _convert_bcrv_to_usdc(_inputAmount);

                uint _before = tokenHCrv.balanceOf(address(this));
                depositHUSD.add_liquidity(_amounts, 1);
                uint _after = tokenHCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenSCrv)) { // convert from SCrv -> HCrv
                uint[4] memory _amounts;
                _amounts[2] = _convert_scrv_to_usdc(_inputAmount);

                uint _before = tokenHCrv.balanceOf(address(this));
                depositHUSD.add_liquidity(_amounts, 1);
                uint _after = tokenHCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenCCrv)) { // convert from CCrv -> HCrv
                uint[4] memory _amounts;
                _amounts[2] = _convert_ccrv_to_usdc(_inputAmount);

                uint _before = tokenHCrv.balanceOf(address(this));
                depositHUSD.add_liquidity(_amounts, 1);
                uint _after = tokenHCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            }
        } else if (_output == address(tokenCCrv)) {
            if (_input == address(token3CRV)) { // convert from 3CRV -> CCrv
                uint[2] memory _amounts;
                _amounts[1] = _convert_3crv_to_usdc(_inputAmount);

                uint _before = tokenCCrv.balanceOf(address(this));
                depositCompound.add_liquidity(_amounts, 1);
                uint _after = tokenCCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenBCrv)) { // convert from BCrv -> CCrv
                uint[2] memory _amounts;
                _amounts[1] = _convert_bcrv_to_usdc(_inputAmount);

                uint _before = tokenCCrv.balanceOf(address(this));
                depositCompound.add_liquidity(_amounts, 1);
                uint _after = tokenCCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenSCrv)) { // convert from SCrv -> BCrv
                uint[2] memory _amounts;
                _amounts[1] = _convert_scrv_to_usdc(_inputAmount);

                uint _before = tokenCCrv.balanceOf(address(this));
                depositCompound.add_liquidity(_amounts, 1);
                uint _after = tokenCCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            } else if (_input == address(tokenHCrv)) { // convert from HCrv -> BCrv
                uint[2] memory _amounts;
                _amounts[1] = _convert_hcrv_to_usdc(_inputAmount);

                uint _before = tokenCCrv.balanceOf(address(this));
                depositCompound.add_liquidity(_amounts, 1);
                uint _after = tokenCCrv.balanceOf(address(this));

                _outputAmount = _after.sub(_before);
            }
        }
        if (_outputAmount > 0) {
            IERC20(_output).safeTransfer(msg.sender, _outputAmount);
        }
        return _outputAmount;
    }

    function _convert_underlying_to_ctoken(CTokenInterface ctoken, uint _amount) internal view returns (uint _outputAmount) {
        _outputAmount = _amount.mul(10 ** 18).div(ctoken.exchangeRateStored());
    }

    function _convert_underlying_to_ytoken_rate(yTokenInterface yToken, uint _inputAmount) internal view returns (uint _outputAmount) {
        return _inputAmount.mul(1e18).div(yToken.getPricePerFullShare());
    }

    function _convert_3crv_to_usdc(uint _inputAmount) internal returns (uint _outputAmount) {
        // 3CRV -> USDC
        uint _before = pool3CrvTokens[1].balanceOf(address(this));
        stableSwap3Pool.remove_liquidity_one_coin(_inputAmount, 1, 1);
        _outputAmount = pool3CrvTokens[1].balanceOf(address(this)).sub(_before);
    }

    function _convert_bcrv_to_usdc(uint _inputAmount) internal returns (uint _outputAmount) {
        // BCrv -> USDC
        uint _before = pool3CrvTokens[1].balanceOf(address(this));
        depositBUSD.remove_liquidity_one_coin(_inputAmount, 1, 1);
        _outputAmount = pool3CrvTokens[1].balanceOf(address(this)).sub(_before);
    }

    function _convert_scrv_to_usdc(uint _inputAmount) internal returns (uint _outputAmount) {
        // SCrv -> USDC
        uint _before = pool3CrvTokens[1].balanceOf(address(this));
        depositSUSD.remove_liquidity_one_coin(_inputAmount, 1, 1);
        _outputAmount = pool3CrvTokens[1].balanceOf(address(this)).sub(_before);
    }

    function _convert_hcrv_to_usdc(uint _inputAmount) internal returns (uint _outputAmount) {
        // HCrv -> USDC
        uint _before = pool3CrvTokens[1].balanceOf(address(this));
        depositHUSD.remove_liquidity_one_coin(_inputAmount, 2, 1);
        _outputAmount = pool3CrvTokens[1].balanceOf(address(this)).sub(_before);
    }

    function _convert_ccrv_to_usdc(uint _inputAmount) internal returns (uint _outputAmount) {
        // CCrv -> USDC
        uint _before = pool3CrvTokens[1].balanceOf(address(this));
        depositCompound.remove_liquidity_one_coin(_inputAmount, 1, 1);
        _outputAmount = pool3CrvTokens[1].balanceOf(address(this)).sub(_before);
    }

    function _convert_hcrv_to_3crv(uint _inputAmount) internal returns (uint _outputAmount) {
        // HCrv -> 3CRV
        uint _before = token3CRV.balanceOf(address(this));
        stableSwapHUSD.remove_liquidity_one_coin(_inputAmount, 1, 1);
        _outputAmount = token3CRV.balanceOf(address(this)).sub(_before);
    }

    function governanceRecoverUnsupported(IERC20 _token, uint _amount, address _to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(_to, _amount);
    }
}