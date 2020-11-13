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

interface IVaultManager {
    function yax() external view returns (address);
    function vaults(address) external view returns (bool);
    function controllers(address) external view returns (bool);
    function strategies(address) external view returns (bool);
    function stakingPool() external view returns (address);
    function profitSharer() external view returns (address);
    function treasuryWallet() external view returns (address);
    function performanceReward() external view returns (address);
    function stakingPoolShareFee() external view returns (uint);
    function gasFee() external view returns (uint);
    function insuranceFee() external view returns (uint);
    function withdrawalProtectionFee() external view returns (uint);
}

interface IController {
    function vaults(address) external view returns (address);
    function want(address) external view returns (address);
    function balanceOf(address) external view returns (uint);
    function withdraw(address, uint) external;
    function earn(address, uint) external;
    function withdrawFee(address, uint) external view returns (uint); // pJar: 0.5% (50/10000)
    function investEnabled() external view returns (bool);
}

interface IConverter {
    function token() external returns (address _share);
    function convert(address _input, address _output, uint _inputAmount) external returns (uint _outputAmount);
    function convert_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);
    function convert_stables(uint[3] calldata amounts) external returns (uint _shareAmount); // 0: DAI, 1: USDC, 2: USDT
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint);
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external returns (uint dy);
    function calc_token_amount(uint[3] calldata amounts, bool deposit) external view returns (uint _shareAmount);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint _outputAmount);
}

interface IMetaVault {
    function balance() external view returns (uint);
    function setController(address _controller) external;
    function claimInsurance() external;
    function token() external view returns (address);
    function available() external view returns (uint);
    function withdrawFee(uint _amount) external view returns (uint);
    function earn() external;
    function calc_token_amount_deposit(uint[3] calldata amounts) external view returns (uint);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint);
    function convert_rate(address _input, uint _amount) external view returns (uint);
    function deposit(uint _amount, address _input, uint _min_mint_amount, bool _isStake) external;
    function harvest(address reserve, uint amount) external;
    function withdraw(uint _shares, address _output) external;
    function want() external view returns (address);
    function getPricePerFullShare() external view returns (uint);
}

// @dev This metavault will pay YAX incentive for depositors and stakers
// It does not need minter key of YAX. Governance multisig will mint total of 34000 YAX and send into the vault in the beginning
contract yAxisMetaVault is ERC20, IMetaVault {
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20[4] public inputTokens; // DAI, USDC, USDT, 3Crv

    IERC20 public token3CRV;
    IERC20 public tokenYAX;

    uint public min = 9500;
    uint public constant max = 10000;

    uint public earnLowerlimit = 5 ether; // minimum to invest is 5 3CRV
    uint public totalDepositCap = 10000000 ether; // initial cap set at 10 million dollar

    address public governance;
    address public controller;
    uint public insurance;
    IVaultManager public vaultManager;
    IConverter public converter;

    bool public acceptContractDepositor = false; // dont accept contract at beginning

    struct UserInfo {
        uint amount;
        uint yaxRewardDebt;
        uint accEarned;
    }

    uint public lastRewardBlock;
    uint public accYaxPerShare;

    uint public yaxPerBlock;

    mapping(address => UserInfo) public userInfo;

    address public treasuryWallet = 0x362Db1c17db4C79B51Fe6aD2d73165b1fe9BaB4a;

    uint public constant BLOCKS_PER_WEEK = 46500;

    // Block number when each epoch ends.
    uint[5] public epochEndBlocks;

    // Reward multipler for each of 5 epoches (epochIndex: reward multipler)
    uint[6] public epochRewardMultiplers = [86000, 64000, 43000, 21000, 10000, 1];

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);

    constructor (IERC20 _tokenDAI, IERC20 _tokenUSDC, IERC20 _tokenUSDT, IERC20 _token3CRV, IERC20 _tokenYAX,
        uint _yaxPerBlock, uint _startBlock) public ERC20("yAxis.io:MetaVault:3CRV", "MVLT") {
        inputTokens[0] = _tokenDAI;
        inputTokens[1] = _tokenUSDC;
        inputTokens[2] = _tokenUSDT;
        inputTokens[3] = _token3CRV;
        token3CRV = _token3CRV;
        tokenYAX = _tokenYAX;
        yaxPerBlock = _yaxPerBlock; // supposed to be 0.000001 YAX (1000000000000 = 1e12 wei)
        lastRewardBlock = (_startBlock > block.number) ? _startBlock : block.number; // supposed to be 11,163,000 (Sat Oct 31 2020 06:30:00 GMT+0)
        epochEndBlocks[0] = lastRewardBlock + BLOCKS_PER_WEEK * 2; // weeks 1-2
        epochEndBlocks[1] = epochEndBlocks[0] + BLOCKS_PER_WEEK * 2; // weeks 3-4
        epochEndBlocks[2] = epochEndBlocks[1] + BLOCKS_PER_WEEK * 4; // month 2
        epochEndBlocks[3] = epochEndBlocks[2] + BLOCKS_PER_WEEK * 8; // month 3-4
        epochEndBlocks[4] = epochEndBlocks[3] + BLOCKS_PER_WEEK * 8; // month 5-6
        governance = msg.sender;
    }

    /**
     * @dev Throws if called by a contract and we are not allowing.
     */
    modifier checkContract() {
        if (!acceptContractDepositor) {
            require(!address(msg.sender).isContract() && msg.sender == tx.origin, "Sorry we do not accept contract!");
        }
        _;
    }

    // Ignore insurance fund for balance calculations
    function balance() public override view returns (uint) {
        uint bal = token3CRV.balanceOf(address(this));
        if (controller != address(0)) bal = bal.add(IController(controller).balanceOf(address(token3CRV)));
        return bal.sub(insurance);
    }

    function setMin(uint _min) external {
        require(msg.sender == governance, "!governance");
        min = _min;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) public override {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setConverter(IConverter _converter) public {
        require(msg.sender == governance, "!governance");
        require(_converter.token() == address(token3CRV), "!token3CRV");
        converter = _converter;
    }

    function setVaultManager(IVaultManager _vaultManager) public {
        require(msg.sender == governance, "!governance");
        vaultManager = _vaultManager;
    }

    function setEarnLowerlimit(uint _earnLowerlimit) public {
        require(msg.sender == governance, "!governance");
        earnLowerlimit = _earnLowerlimit;
    }

    function setTotalDepositCap(uint _totalDepositCap) public {
        require(msg.sender == governance, "!governance");
        totalDepositCap = _totalDepositCap;
    }

    function setAcceptContractDepositor(bool _acceptContractDepositor) public {
        require(msg.sender == governance, "!governance");
        acceptContractDepositor = _acceptContractDepositor;
    }

    function setYaxPerBlock(uint _yaxPerBlock) public {
        require(msg.sender == governance, "!governance");
        updateReward();
        yaxPerBlock = _yaxPerBlock;
    }

    function setEpochEndBlock(uint8 _index, uint256 _epochEndBlock) public {
        require(msg.sender == governance, "!governance");
        require(_index < 5, "_index out of range");
        require(_epochEndBlock > block.number, "Too late to update");
        require(epochEndBlocks[_index] > block.number, "Too late to update");
        epochEndBlocks[_index] = _epochEndBlock;
    }

    function setEpochRewardMultipler(uint8 _index, uint256 _epochRewardMultipler) public {
        require(msg.sender == governance, "!governance");
        require(_index > 0 && _index < 6, "Index out of range");
        require(epochEndBlocks[_index - 1] > block.number, "Too late to update");
        epochRewardMultiplers[_index] = _epochRewardMultipler;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        for (uint8 epochId = 5; epochId >= 1; --epochId) {
            if (_to >= epochEndBlocks[epochId - 1]) {
                if (_from >= epochEndBlocks[epochId - 1]) return _to.sub(_from).mul(epochRewardMultiplers[epochId]);
                uint256 multiplier = _to.sub(epochEndBlocks[epochId - 1]).mul(epochRewardMultiplers[epochId]);
                if (epochId == 1) return multiplier.add(epochEndBlocks[0].sub(_from).mul(epochRewardMultiplers[0]));
                for (epochId = epochId - 1; epochId >= 1; --epochId) {
                    if (_from >= epochEndBlocks[epochId - 1]) return multiplier.add(epochEndBlocks[epochId].sub(_from).mul(epochRewardMultiplers[epochId]));
                    multiplier = multiplier.add(epochEndBlocks[epochId].sub(epochEndBlocks[epochId - 1]).mul(epochRewardMultiplers[epochId]));
                }
                return multiplier.add(epochEndBlocks[0].sub(_from).mul(epochRewardMultiplers[0]));
            }
        }
        return _to.sub(_from).mul(epochRewardMultiplers[0]);
    }

    function setTreasuryWallet(address _treasuryWallet) public {
        require(msg.sender == governance, "!governance");
        treasuryWallet = _treasuryWallet;
    }

    function claimInsurance() external override {
        // if claim by controller for auto-compounding (current insurance will stay to increase sharePrice)
        // otherwise send the fund to treasuryWallet
        if (msg.sender != controller) {
            // claim by governance for insurance
            require(msg.sender == governance, "!governance");
            token3CRV.safeTransfer(treasuryWallet, insurance);
        }
        insurance = 0;
    }

    function token() public override view returns (address) {
        return address(token3CRV);
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public override view returns (uint) {
        return token3CRV.balanceOf(address(this)).mul(min).div(max);
    }

    function withdrawFee(uint _amount) public override view returns (uint) {
        return (controller == address(0)) ? 0 : IController(controller).withdrawFee(address(token3CRV), _amount);
    }

    function earn() public override {
        if (controller != address(0)) {
            IController _contrl = IController(controller);
            if (_contrl.investEnabled()) {
                uint _bal = available();
                token3CRV.safeTransfer(controller, _bal);
                _contrl.earn(address(token3CRV), _bal);
            }
        }
    }

    function calc_token_amount_deposit(uint[3] calldata amounts) external override view returns (uint) {
        return converter.calc_token_amount(amounts, true);
    }

    function calc_token_amount_withdraw(uint _shares, address _output) external override view returns (uint) {
        uint _withdrawFee = withdrawFee(_shares);
        if (_withdrawFee > 0) {
            _shares = _shares.mul(10000 - _withdrawFee).div(10000);
        }
        uint r = (balance().mul(_shares)).div(totalSupply());
        if (_output == address(token3CRV)) {
            return r;
        }
        return converter.calc_token_amount_withdraw(r, _output);
    }

    function convert_rate(address _input, uint _amount) external override view returns (uint) {
        return converter.convert_rate(_input, address(token3CRV), _amount);
    }

    function deposit(uint _amount, address _input, uint _min_mint_amount, bool _isStake) external override checkContract {
        require(_amount > 0, "!_amount");
        uint _pool = balance();
        uint _before = token3CRV.balanceOf(address(this));
        if (_input == address(token3CRV)) {
            token3CRV.safeTransferFrom(msg.sender, address(this), _amount);
        } else if (converter.convert_rate(_input, address(token3CRV), _amount) > 0) {
            IERC20(_input).safeTransferFrom(msg.sender, address(converter), _amount);
            converter.convert(_input, address(token3CRV), _amount);
        }
        uint _after = token3CRV.balanceOf(address(this));
        require(totalDepositCap == 0 || _after <= totalDepositCap, ">totalDepositCap");
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        require(_amount >= _min_mint_amount, "slippage");
        if (_amount > 0) {
            if (!_isStake) {
                _deposit(msg.sender, _pool, _amount);
            } else {
                uint _shares = _deposit(address(this), _pool, _amount);
                _stakeShares(_shares);
            }
        }
    }

    // Transfers tokens of all kinds
    // 0: DAI, 1: USDT, 2: USDC, 3: 3CRV
    function depositAll(uint[4] calldata _amounts, uint _min_mint_amount, bool _isStake) external checkContract {
        uint _pool = balance();
        uint _before = token3CRV.balanceOf(address(this));
        bool hasStables = false;
        for (uint8 i = 0; i < 4; i++) {
            uint _inputAmount = _amounts[i];
            if (_inputAmount > 0) {
                if (i == 3) {
                    inputTokens[i].safeTransferFrom(msg.sender, address(this), _inputAmount);
                } else if (converter.convert_rate(address(inputTokens[i]), address(token3CRV), _inputAmount) > 0) {
                    inputTokens[i].safeTransferFrom(msg.sender, address(converter), _inputAmount);
                    hasStables = true;
                }
            }
        }
        if (hasStables) {
            uint[3] memory _stablesAmounts;
            _stablesAmounts[0] = _amounts[0];
            _stablesAmounts[1] = _amounts[1];
            _stablesAmounts[2] = _amounts[2];
            converter.convert_stables(_stablesAmounts);
        }
        uint _after = token3CRV.balanceOf(address(this));
        require(totalDepositCap == 0 || _after <= totalDepositCap, ">totalDepositCap");
        uint _totalDepositAmount = _after.sub(_before); // Additional check for deflationary tokens
        require(_totalDepositAmount >= _min_mint_amount, "slippage");
        if (_totalDepositAmount > 0) {
            if (!_isStake) {
                _deposit(msg.sender, _pool, _totalDepositAmount);
            } else {
                uint _shares = _deposit(address(this), _pool, _totalDepositAmount);
                _stakeShares(_shares);
            }
        }
    }

    function stakeShares(uint _shares) external {
        uint _before = balanceOf(address(this));
        IERC20(address(this)).transferFrom(msg.sender, address(this), _shares);
        uint _after = balanceOf(address(this));
        _shares = _after.sub(_before);
        // Additional check for deflationary tokens
        _stakeShares(_shares);
    }

    function _deposit(address _mintTo, uint _pool, uint _amount) internal returns (uint _shares) {
        if (address(vaultManager) != address(0)) {
            // expected 0.1% of deposits go into an insurance fund (or auto-compounding if called by controller) in-case of negative profits to protect withdrawals
            // it is updated by governance (community vote)
            uint _insuranceFee = vaultManager.insuranceFee();
            if (_insuranceFee > 0) {
                uint _insurance = _amount.mul(_insuranceFee).div(10000);
                _amount = _amount.sub(_insurance);
                insurance = insurance.add(_insurance);
            }
        }

        if (totalSupply() == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount.mul(totalSupply())).div(_pool);
        }
        if (_shares > 0) {
            if (token3CRV.balanceOf(address(this)) > earnLowerlimit) {
                earn();
            }
            _mint(_mintTo, _shares);
        }
    }

    function _stakeShares(uint _shares) internal {
        UserInfo storage user = userInfo[msg.sender];
        updateReward();
        _getReward();
        user.amount = user.amount.add(_shares);
        user.yaxRewardDebt = user.amount.mul(accYaxPerShare).div(1e12);
        emit Deposit(msg.sender, _shares);
    }

    // View function to see pending YAXs on frontend.
    function pendingYax(address _account) public view returns (uint _pending) {
        UserInfo storage user = userInfo[_account];
        uint _accYaxPerShare = accYaxPerShare;
        uint lpSupply = balanceOf(address(this));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
            _accYaxPerShare = accYaxPerShare.add(_multiplier.mul(yaxPerBlock).mul(1e12).div(lpSupply));
        }
        _pending = user.amount.mul(_accYaxPerShare).div(1e12).sub(user.yaxRewardDebt);
    }

    function updateReward() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint lpSupply = balanceOf(address(this));
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
        accYaxPerShare = accYaxPerShare.add(_multiplier.mul(yaxPerBlock).mul(1e12).div(lpSupply));
        lastRewardBlock = block.number;
    }

    function _getReward() internal {
        UserInfo storage user = userInfo[msg.sender];
        uint _pendingYax = user.amount.mul(accYaxPerShare).div(1e12).sub(user.yaxRewardDebt);
        if (_pendingYax > 0) {
            user.accEarned = user.accEarned.add(_pendingYax);
            safeYaxTransfer(msg.sender, _pendingYax);
            emit RewardPaid(msg.sender, _pendingYax);
        }
    }

    function withdrawAll(address _output) external {
        unstake(userInfo[msg.sender].amount);
        withdraw(balanceOf(msg.sender), _output);
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint amount) external override {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token3CRV), "token3CRV");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    // call unstake(0) for getting reward
    function unstake(uint _amount) public {
        updateReward();
        _getReward();
        UserInfo storage user = userInfo[msg.sender];
        if (_amount > 0) {
            require(user.amount >= _amount, "stakedBal < _amount");
            user.amount = user.amount.sub(_amount);
            IERC20(address(this)).transfer(msg.sender, _amount);
        }
        user.yaxRewardDebt = user.amount.mul(accYaxPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint _shares, address _output) public override {
        uint _userBal = balanceOf(msg.sender);
        if (_shares > _userBal) {
            uint _need = _shares.sub(_userBal);
            require(_need <= userInfo[msg.sender].amount, "_userBal+staked < _shares");
            unstake(_need);
        }
        uint r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        if (address(vaultManager) != address(0)) {
            // expected 0.1% of withdrawal go back to vault (for auto-compounding) to protect withdrawals
            // it is updated by governance (community vote)
            uint _withdrawalProtectionFee = vaultManager.withdrawalProtectionFee();
            if (_withdrawalProtectionFee > 0) {
                uint _withdrawalProtection = r.mul(_withdrawalProtectionFee).div(10000);
                r = r.sub(_withdrawalProtection);
            }
        }

        // Check balance
        uint b = token3CRV.balanceOf(address(this));
        if (b < r) {
            uint _toWithdraw = r.sub(b);
            if (controller != address(0)) {
                IController(controller).withdraw(address(token3CRV), _toWithdraw);
            }
            uint _after = token3CRV.balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _toWithdraw) {
                r = b.add(_diff);
            }
        }

        if (_output == address(token3CRV)) {
            token3CRV.safeTransfer(msg.sender, r);
        } else {
            require(converter.convert_rate(address(token3CRV), _output, r) > 0, "rate=0");
            token3CRV.safeTransfer(address(converter), r);
            uint _outputAmount = converter.convert(address(token3CRV), _output, r);
            IERC20(_output).safeTransfer(msg.sender, _outputAmount);
        }
    }

    function want() external override view returns (address) {
        return address(token3CRV);
    }

    function getPricePerFullShare() external override view returns (uint) {
        return balance().mul(1e18).div(totalSupply());
    }

    // Safe YAX transfer, ensure we have enough balance.
    function safeYaxTransfer(address _to, uint _amount) internal {
        uint _tokenBal = tokenYAX.balanceOf(address(this));
        tokenYAX.safeTransfer(_to, (_tokenBal < _amount) ? _tokenBal : _amount);
    }

    // Only allows to earn some extra yield from non-core tokens - and auto-compounding the bought 3CRV
    function earnExtra(address _token) public {
        require(msg.sender == governance, "!governance");
        require(address(_token) != address(token3CRV), "3crv");
        require(address(_token) != address(this), "mlvt");
        uint _amount = IERC20(_token).balanceOf(address(this));
        require(converter.convert_rate(_token, address(token3CRV), _amount) > 0, "rate=0");
        IERC20(_token).safeTransfer(address(converter), _amount);
        converter.convert(_token, address(token3CRV), _amount);
    }
}