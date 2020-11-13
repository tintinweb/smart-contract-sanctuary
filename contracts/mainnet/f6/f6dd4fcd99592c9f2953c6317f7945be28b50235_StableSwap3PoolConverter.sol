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

interface IMultiVaultConverter {
    function token() external returns (address);
    function get_virtual_price() external view returns (uint);

    function convert_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);
    function calc_token_amount_deposit(uint[] calldata _amounts) external view returns (uint _shareAmount);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint _outputAmount);

    function convert(address _input, address _output, uint _inputAmount) external returns (uint _outputAmount);
    function convertAll(uint[] calldata _amounts) external returns (uint _outputAmount);
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

// 0: DAI, 1: USDC, 2: USDT, 3: BUSD
interface IStableSwapBUSD {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[4] calldata amounts, bool deposit) external view returns (uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
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

// 0: DAI, 1: USDC, 2: USDT, 3: sUSD
interface IStableSwapSUSD {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[4] calldata amounts, bool deposit) external view returns (uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
}

// Supported Pool Tokens:
// 0. 3pool [DAI, USDC, USDT]
// 1. BUSD [(y)DAI, (y)USDC, (y)USDT, (y)BUSD]
// 2. sUSD [DAI, USDC, USDT, sUSD]
// 3. husd [HUSD, 3pool]
// 4. Compound [(c)DAI, (c)USDC]
// 5. Y [(y)DAI, (y)USDC, (y)USDT, (y)TUSD]
// 6. Swerve [(y)DAI...(y)TUSD]
contract StableSwap3PoolConverter is IMultiVaultConverter {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20[3] public pool3CrvTokens; // DAI, USDC, USDT
    IERC20 public token3Crv; // 3Crv

    IERC20 public tokenBUSD; // BUSD
    IERC20 public tokenBCrv; // BCrv (yDAI+yUSDC+yUSDT+yBUSD)

    IERC20 public tokenSUSD; // sUSD
    IERC20 public tokenSCrv; // sCrv (DAI/USDC/USDT/sUSD)

    IERC20 public tokenHUSD; // hUSD
    IERC20 public tokenHCrv; // hCrv (HUSD/3Crv)

    address public governance;

    IStableSwap3Pool public stableSwap3Pool;
    IStableSwapBUSD public stableSwapBUSD;
    IStableSwapSUSD public stableSwapSUSD;
    IStableSwapHUSD public stableSwapHUSD;

    IValueVaultMaster public vaultMaster;

    uint public defaultSlippage = 1; // very small 0.01%

    constructor (IERC20 _tokenDAI, IERC20 _tokenUSDC, IERC20 _tokenUSDT, IERC20 _token3Crv,
        IERC20 _tokenBUSD, IERC20 _tokenBCrv,
        IERC20 _tokenSUSD, IERC20 _tokenSCrv,
        IERC20 _tokenHUSD, IERC20 _tokenHCrv,
        IStableSwap3Pool _stableSwap3Pool,
        IStableSwapBUSD _stableSwapBUSD,
        IStableSwapSUSD _stableSwapSUSD,
        IStableSwapHUSD _stableSwapHUSD,
        IValueVaultMaster _vaultMaster) public {
        pool3CrvTokens[0] = _tokenDAI;
        pool3CrvTokens[1] = _tokenUSDC;
        pool3CrvTokens[2] = _tokenUSDT;
        token3Crv = _token3Crv;
        tokenBUSD = _tokenBUSD;
        tokenBCrv = _tokenBCrv;
        tokenSUSD = _tokenSUSD;
        tokenSCrv = _tokenSCrv;
        tokenHUSD = _tokenHUSD;
        tokenHCrv = _tokenHCrv;
        stableSwap3Pool = _stableSwap3Pool;
        stableSwapBUSD = _stableSwapBUSD;
        stableSwapSUSD = _stableSwapSUSD;
        stableSwapHUSD = _stableSwapHUSD;

        pool3CrvTokens[0].safeApprove(address(stableSwap3Pool), type(uint256).max);
        pool3CrvTokens[1].safeApprove(address(stableSwap3Pool), type(uint256).max);
        pool3CrvTokens[2].safeApprove(address(stableSwap3Pool), type(uint256).max);
        token3Crv.safeApprove(address(stableSwap3Pool), type(uint256).max);

        pool3CrvTokens[0].safeApprove(address(stableSwapBUSD), type(uint256).max);
        pool3CrvTokens[1].safeApprove(address(stableSwapBUSD), type(uint256).max);
        pool3CrvTokens[2].safeApprove(address(stableSwapBUSD), type(uint256).max);
        tokenBUSD.safeApprove(address(stableSwapBUSD), type(uint256).max);
        tokenBCrv.safeApprove(address(stableSwapBUSD), type(uint256).max);

        pool3CrvTokens[0].safeApprove(address(stableSwapSUSD), type(uint256).max);
        pool3CrvTokens[1].safeApprove(address(stableSwapSUSD), type(uint256).max);
        pool3CrvTokens[2].safeApprove(address(stableSwapSUSD), type(uint256).max);
        tokenSUSD.safeApprove(address(stableSwapSUSD), type(uint256).max);
        tokenSCrv.safeApprove(address(stableSwapSUSD), type(uint256).max);

        token3Crv.safeApprove(address(stableSwapHUSD), type(uint256).max);
        tokenHUSD.safeApprove(address(stableSwapHUSD), type(uint256).max);
        tokenHCrv.safeApprove(address(stableSwapHUSD), type(uint256).max);

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

    function setDefaultSlippage(uint _defaultSlippage) external {
        require(msg.sender == governance, "!governance");
        require(_defaultSlippage <= 100, "_defaultSlippage>1%");
        defaultSlippage = _defaultSlippage;
    }

    function token() external override returns (address) {
        return address(token3Crv);
    }

    // Average dollar value of pool token
    function get_virtual_price() external override view returns (uint) {
        return stableSwap3Pool.get_virtual_price();
    }

    function convert_rate(address _input, address _output, uint _inputAmount) public override view returns (uint _outputAmount) {
        if (_inputAmount == 0) return 0;
        if (_output == address(token3Crv)) { // convert to 3Crv
            uint[3] memory _amounts;
            for (uint8 i = 0; i < 3; i++) {
                if (_input == address(pool3CrvTokens[i])) {
                    _amounts[i] = _inputAmount;
                    _outputAmount = stableSwap3Pool.calc_token_amount(_amounts, true);
                    return _outputAmount.mul(10000 - defaultSlippage).div(10000);
                }
            }
            if (_input == address(tokenBUSD)) {
                _amounts[1] = stableSwapBUSD.get_dy_underlying(int128(3), int128(1), _inputAmount); // convert to USDC
                _outputAmount = stableSwap3Pool.calc_token_amount(_amounts, true); // USDC -> 3Crv
            }
            if (_input == address(tokenSUSD)) {
                _amounts[1] = stableSwapSUSD.get_dy_underlying(int128(3), int128(1), _inputAmount); // convert to USDC
                _outputAmount = stableSwap3Pool.calc_token_amount(_amounts, true); // USDC -> 3Crv
            }
            if (_input == address(tokenHUSD)) {
                _outputAmount = stableSwapHUSD.get_dy(int128(0), int128(1), _inputAmount); // HUSD -> 3Crv
            }
        } else if (_input == address(token3Crv)) { // convert from 3Crv
            for (uint8 i = 0; i < 3; i++) {
                if (_output == address(pool3CrvTokens[i])) {
                    // @dev this is for UI reference only, the actual share price (stable/CRV) will be re-calculated on-chain when we do convert()
                    _outputAmount = stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, i);
                    return _outputAmount.mul(10000 - defaultSlippage).div(10000);
                }
            }
            if (_output == address(tokenBUSD)) {
                uint _usdcAmount = stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, 1); // 3Crv -> USDC
                _outputAmount = stableSwapBUSD.get_dy_underlying(int128(1), int128(3), _usdcAmount); // USDC -> BUSD
            }
            if (_output == address(tokenSUSD)) {
                uint _usdcAmount = stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, 1); // 3Crv -> USDC
                _outputAmount = stableSwapSUSD.get_dy_underlying(int128(1), int128(3), _usdcAmount); // USDC -> BUSD
            }
            if (_output == address(tokenHUSD)) {
                _outputAmount = stableSwapHUSD.get_dy(int128(1), int128(0), _inputAmount); // 3Crv -> HUSD
            }
        }
        if (_outputAmount > 0) {
            uint _slippage = _outputAmount.mul(vaultMaster.convertSlippage(_input, _output)).div(10000);
            _outputAmount = _outputAmount.sub(_slippage);
        }
    }

    // 0: DAI, 1: USDC, 2: USDT, 3: 3Crv, 4: BUSD, 5: sUSD, 6: husd
    function calc_token_amount_deposit(uint[] calldata _amounts) external override view returns (uint _shareAmount) {
        _shareAmount = _amounts[3]; // 3Crv amount
        uint[3] memory _3poolAmounts;
        _3poolAmounts[0] = _amounts[0];
        _3poolAmounts[1] = _amounts[1];
        _3poolAmounts[2] = _amounts[2];
        uint _3poolTo3crv = stableSwap3Pool.calc_token_amount(_3poolAmounts, true);
        uint _busdTo3Crv = convert_rate(address(tokenBUSD), address(token3Crv), _amounts[4]);
        uint _susdTo3Crv = convert_rate(address(tokenSUSD), address(token3Crv), _amounts[5]);
        uint _husdTo3Crv = convert_rate(address(tokenHUSD), address(token3Crv), _amounts[6]);
        return _shareAmount.add(_3poolTo3crv).add(_busdTo3Crv).add(_susdTo3Crv).add(_husdTo3Crv);
    }

    // @dev we use curve function calc_withdraw_one_coin() for UI reference only
    // the actual share price (stable/CRV) will be re-calculated on-chain when we do convert()
    function calc_token_amount_withdraw(uint _shares, address _output) external override view returns (uint _outputAmount) {
        for (uint8 i = 0; i < 3; i++) {
            if (_output == address(pool3CrvTokens[i])) {
                return stableSwap3Pool.calc_withdraw_one_coin(_shares, i);
            }
        }
        if (_output == address(tokenBUSD)) {
            uint _usdcAmount = stableSwap3Pool.calc_withdraw_one_coin(_shares, 1); // 3Crv -> USDC
            _outputAmount = stableSwapBUSD.get_dy_underlying(int128(1), int128(3), _usdcAmount); // USDC -> BUSD
        } else if (_output == address(tokenSUSD)) {
            uint _usdcAmount = stableSwap3Pool.calc_withdraw_one_coin(_shares, 1); // 3Crv -> USDC
            _outputAmount = stableSwapSUSD.get_dy_underlying(int128(1), int128(3), _usdcAmount); // USDC -> SUSD
        } else if (_output == address(tokenHUSD)) {
            _outputAmount = stableSwapHUSD.get_dy(int128(1), int128(0), _shares); // 3Crv -> HUSD
        }
        if (_outputAmount > 0) {
            uint _slippage = _outputAmount.mul(vaultMaster.slippage(_output)).div(10000);
            _outputAmount = _outputAmount.sub(_slippage);
        }
    }

    function convert(address _input, address _output, uint _inputAmount) external override returns (uint _outputAmount) {
        require(vaultMaster.isVault(msg.sender) || vaultMaster.isController(msg.sender) || msg.sender == governance, "!(governance||vault||controller)");
        if (_output == address(token3Crv)) { // convert to 3Crv
            uint[3] memory amounts;
            for (uint8 i = 0; i < 3; i++) {
                if (_input == address(pool3CrvTokens[i])) {
                    amounts[i] = _inputAmount;
                    uint _before = token3Crv.balanceOf(address(this));
                    stableSwap3Pool.add_liquidity(amounts, 1);
                    uint _after = token3Crv.balanceOf(address(this));
                    _outputAmount = _after.sub(_before);
                    token3Crv.safeTransfer(msg.sender, _outputAmount);
                    return _outputAmount;
                }
            }
            if (_input == address(tokenBUSD)) {
                _outputAmount = _convert_busd_to_shares(_inputAmount);
                token3Crv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_input == address(tokenSUSD)) {
                _outputAmount = _convert_susd_to_shares(_inputAmount);
                token3Crv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_input == address(tokenHUSD)) {
                _outputAmount = _convert_husd_to_shares(_inputAmount);
                token3Crv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
        } else if (_input == address(token3Crv)) { // convert from 3Crv
            for (uint8 i = 0; i < 3; i++) {
                if (_output == address(pool3CrvTokens[i])) {
                    uint _before = pool3CrvTokens[i].balanceOf(address(this));
                    stableSwap3Pool.remove_liquidity_one_coin(_inputAmount, i, 1);
                    uint _after = pool3CrvTokens[i].balanceOf(address(this));
                    _outputAmount = _after.sub(_before);
                    pool3CrvTokens[i].safeTransfer(msg.sender, _outputAmount);
                    return _outputAmount;
                }
            }
            if (_output == address(tokenBUSD)) {
                // remove 3Crv to USDC
                uint _before = pool3CrvTokens[1].balanceOf(address(this));
                stableSwap3Pool.remove_liquidity_one_coin(_inputAmount, 1, 1);
                uint _after = pool3CrvTokens[1].balanceOf(address(this));
                _outputAmount = _after.sub(_before);

                // convert USDC to BUSD
                _before = tokenBUSD.balanceOf(address(this));
                stableSwapBUSD.exchange_underlying(int128(1), int128(3), _outputAmount, 1);
                _after = tokenBUSD.balanceOf(address(this));
                _outputAmount = _after.sub(_before);

                tokenBUSD.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_output == address(tokenSUSD)) {
                // remove 3Crv to USDC
                uint _before = pool3CrvTokens[1].balanceOf(address(this));
                stableSwap3Pool.remove_liquidity_one_coin(_inputAmount, 1, 1);
                uint _after = pool3CrvTokens[1].balanceOf(address(this));
                _outputAmount = _after.sub(_before);

                // convert USDC to SUSD
                _before = tokenSUSD.balanceOf(address(this));
                stableSwapSUSD.exchange_underlying(int128(1), int128(3), _outputAmount, 1);
                _after = tokenSUSD.balanceOf(address(this));
                _outputAmount = _after.sub(_before);

                tokenSUSD.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_output == address(tokenHUSD)) {
                _outputAmount = _convert_shares_to_husd(_inputAmount);
                tokenHUSD.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
        }
        return 0;
    }

    // @dev convert from BUSD to 3Crv (via USDC)
    function _convert_busd_to_shares(uint _amount) internal returns (uint _shares) {
        // convert to USDC
        uint[3] memory amounts;
        uint _before = pool3CrvTokens[1].balanceOf(address(this));
        stableSwapBUSD.exchange_underlying(int128(3), int128(1), _amount, 1);
        uint _after = pool3CrvTokens[1].balanceOf(address(this));
        amounts[1] = _after.sub(_before);

        // add USDC to 3pool to get back 3Crv
        _before = token3Crv.balanceOf(address(this));
        stableSwap3Pool.add_liquidity(amounts, 1);
        _after = token3Crv.balanceOf(address(this));

        _shares = _after.sub(_before);
    }

    // @dev convert from SUSD to 3Crv (via USDC)
    function _convert_susd_to_shares(uint _amount) internal returns (uint _shares) {
        // convert to USDC
        uint[3] memory amounts;
        uint _before = pool3CrvTokens[1].balanceOf(address(this));
        stableSwapSUSD.exchange_underlying(int128(3), int128(1), _amount, 1);
        uint _after = pool3CrvTokens[1].balanceOf(address(this));
        amounts[1] = _after.sub(_before);

        // add USDC to 3pool to get back 3Crv
        _before = token3Crv.balanceOf(address(this));
        stableSwap3Pool.add_liquidity(amounts, 1);
        _after = token3Crv.balanceOf(address(this));

        _shares = _after.sub(_before);
    }

    // @dev convert from HUSD to 3Crv
    function _convert_husd_to_shares(uint _amount) internal returns (uint _shares) {
        uint _before = token3Crv.balanceOf(address(this));
        stableSwapHUSD.exchange(int128(0), int128(1), _amount, 1);
        uint _after = token3Crv.balanceOf(address(this));

        _shares = _after.sub(_before);
    }

    // @dev convert from 3Crv to HUSD
    function _convert_shares_to_husd(uint _amount) internal returns (uint _husd) {
        uint _before = tokenHUSD.balanceOf(address(this));
        stableSwapHUSD.exchange(int128(1), int128(0), _amount, 1);
        uint _after = tokenHUSD.balanceOf(address(this));

        _husd = _after.sub(_before);
    }

    function convertAll(uint[] calldata _amounts) external override returns (uint _outputAmount) {
        require(vaultMaster.isVault(msg.sender) || vaultMaster.isController(msg.sender) || msg.sender == governance, "!(governance||vault||controller)");
        uint _before = token3Crv.balanceOf(address(this));
        if (_amounts[0] > 0 || _amounts[1] > 0 || _amounts[2] > 0) {
            uint[3] memory _3poolAmounts;
            _3poolAmounts[0] = _amounts[0];
            _3poolAmounts[1] = _amounts[1];
            _3poolAmounts[2] = _amounts[2];
            stableSwap3Pool.add_liquidity(_3poolAmounts, 1);
        }
        // if (_amounts[3] > 0) { // 3Crv
        // }
        if (_amounts[4] > 0) { // BUSD
            _convert_busd_to_shares(_amounts[4]);
        }
        if (_amounts[5] > 0) { // sUSD
            _convert_susd_to_shares(_amounts[5]);
        }
        if (_amounts[6] > 0) { // hUSD
            _convert_husd_to_shares(_amounts[6]);
        }
        uint _after = token3Crv.balanceOf(address(this));
        _outputAmount = _after.sub(_before);
        token3Crv.safeTransfer(msg.sender, _outputAmount);
        return _outputAmount;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint _amount, address _to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(_to, _amount);
    }
}