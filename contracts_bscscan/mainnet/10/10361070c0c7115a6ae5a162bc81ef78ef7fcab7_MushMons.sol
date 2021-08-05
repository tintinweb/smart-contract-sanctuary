/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity 0.6.12;

interface IController {
    function vaults(address) external view returns (address);

    function rewards() external view returns (address);

    function devfund() external view returns (address);

    function treasury() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function withdraw(address, uint256) external;

    function earn(address, uint256) external;
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

// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/53516bc555a454862470e7860a9b5254db4d00f5/contracts/token/ERC20/ERC20Permit.sol
/**
 * @author Georgios Konstantopoulos
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612} interface.
 */
abstract contract ERC20Permit is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable DOMAIN_SEPARATOR;
    constructor(string memory name_, string memory symbol_) internal ERC20(name_, symbol_) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name_)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev See {IERC2612-permit}.
     *
     * In cases where the free option is not a concern, deadline can simply be
     * set to uint(-1), so it should be seen as an optional parameter
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _approve(owner, spender, amount);
    }

}

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
contract ReentrancyGuard {
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
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    uint256 _status;

    constructor () internal {
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

interface IMasterchef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function bonusEndBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devFundDivRate() external view returns (uint256);

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingMM(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function mm() external view returns (address);

    function mmPerBlock() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accMMPerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setBonusEndBlock(uint256 _bonusEndBlock) external;

    function setDevFundDivRate(uint256 _devFundDivRate) external;

    function setMMPerBlock(uint256 _mmPerBlock) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;

    function notifyBuybackReward(uint256 _amount) external;
}

interface AggregatorV3Interface {
  
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
  
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    
    function decimals() external view returns (uint8);

}

interface UniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IVault is IERC20 {
    function token() external view returns (address);

    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    function getRatio() external view returns (uint256);

    function deposit(uint256) external;

    function withdraw(uint256) external;

    function earn() external;
	
    function balance() external view returns (uint256);
}

pragma experimental ABIEncoderV2;

struct TriggerQuery{
    // the user address who trigger this rebalancing
    address user;
    
    // the exposureToken for this rebalancing
    address exposureToken;
    
    // current market price for exposureToken, in USD denomination
    uint256 markUSDPrice;
    
    // recorded market price for exposureToken during last rebalancing, in USD denomination
    uint256 lastRebalancingUSDPrice;
    
    // recorded timestamp for last rebalancing
    uint256 lastRebalancingTimestamp;
    
    // current holding in exposureToken
    uint256 currentExposure;
    
    // current holding in stablecoin
    uint256 currentStable;
    
    // rebalancing leverage bps set by user (20000, i.e., 2X leverage)
    // the semantic of leverage is determined by underlying MushMon implementation
    uint256 currentLeverageBps;
    
    // decimal for markUSDPrice and lastRebalancingUSDPrice
    uint256 priceDecimal;
    
    // decimal for stablecoin token
    uint256 stableCoinDecimal;
    
    // extra data for this rebalancing, 
    // for example using abi.decode() to deserialize the params 
    // and abi.encode() to serialize the params
    bytes extraData;
}

struct TriggerResult{
    // if need to trigger rebalancing 
    bool trigger;
    
    // if need to increase exposure to exposureToken
    bool increase;
    
    // rebalancing amount denominated 
    // in either stablecoin (stableCoinDecimal) if increasing exposure 
    // or in exposureToken (ERC20(exposureToken).decimals()) if decreasing exposure
    uint256 amount;
    
    // rebalancing execution price, usually taken equally as for mark price simplicity
    uint256 markPrice;
}

interface RebalancingMon{
    // return the fee BPS if any, recommended value is 20, i.e., 0.2%
    function feeBps() external view returns(uint256);
    
    // return the fee destination if any
    function feeDestination() external view returns(address);
    
    // By evaluating given TriggerQuery parameter, this function would return a proper TriggerResult
    function triggerRebalancing(TriggerQuery calldata query) external view returns(TriggerResult memory);
    
    // configure user-specific rebalancing parameters for msg.sender and exposureToken, 
    // by default using abi.decode() to deserialize the params
    // and abi.encode() to serialize the params
    function configure(address exposureToken, bytes calldata params) external;
    
    // only available to mushmons
    function configureForUser(address user, address exposureToken, bytes calldata params) external;
}

contract MushMons is ReentrancyGuard, ERC20Permit {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    // deposit stablecoin like USDC or USDT
    IERC20 public immutable token;
    uint256 public tokenDecimalDivisor;
    uint256 public oracleSamples = 5;
    uint256 public swapSlippage = 100;
    uint256 public constant MAX_BPS = 10000;

    address public governance;
    address public timelock;
    address public swapDEX = 0x10ED43C718714eb63d5aA57B78B54704E256024E;  // bsc: pancakeswap route
    
    /////////////////////////
    // user states modified by rebalancing/deposit/withdrawal
    /////////////////////////
    
    // user address -> yield-farming vaults -> share
    mapping(address => mapping(address => uint256)) public yieldVaultShares;
    
    /////////////////////////
    // user states modified by rebalancing
    /////////////////////////

    // user address -> exposureToken(like BTC) -> mintedShare
    mapping(address => mapping(address => uint256)) public mintedShares;

    // user address -> exposureToken(like BTC) -> balance(stablecoin)
    mapping(address => mapping(address => uint256)) public tokenBalances;
    
    // user address -> exposureToken(like BTC) -> balance(exposureToken)
    mapping(address => mapping(address => uint256)) public exposureBalances;
    
    // user address -> exposureToken(like BTC) -> last rebalancing price
    mapping(address => mapping(address => uint256)) public lastRebalancingPrices;
    
    // user address -> exposureToken(like BTC) -> last rebalancing timestamp
    mapping(address => mapping(address => uint256)) public lastRebalancingTimestamp;
    
    /////////////////////////
    // user specific configurations
    /////////////////////////
    
    // user address -> exposureToken(like BTC) -> leverage
    mapping(address => mapping(address => uint256)) public exposureLeverageBps;
    
    // user address -> exposureToken(like BTC) -> RebalancingMon
    mapping(address => mapping(address => address)) public exposureRebalancingMons;
    
    // user address -> token -> yield-farming vaults
    mapping(address => mapping(address => address)) public yieldVaults;
    
    /////////////////////////
    // global configurations
    /////////////////////////
    
    // exposureToken(like BTC) -> minimum allowed balance(denominated in stablecoin)
    mapping(address => uint256) public exposureMinBalances;
    
    // exposureToken(like BTC) -> maximum allowed balance(denominated in stablecoin)
    mapping(address => uint256) public exposureMaxBalances;
    
    // exposureToken -> ChainLink oracles (exposureToken <-> USD)
    mapping(address => address) public exposureOracles;
    
    // mushmon address -> allowed or not
    mapping(address => bool) public validMushMons;
    
    // mushmon address -> mushmon fee destination
    mapping(address => address) public validMushMonFeeDestination;
    
    // mushmon address -> mushmon fee bps like 20, i.e., 0.2% of each rebalancing amount
    mapping(address => uint256) public validMushMonFeeBps;
    
    // token address -> yield farms -> allowed or not
    mapping(address => mapping(address => bool)) public validYieldFarms;
    
    // token address -> yield farms array
    mapping(address => address[]) internal _yieldFarms;
    
    // exposureToken(like BTC) -> allowed or not
    mapping(address => bool) internal _validExposureTokens;
    
    // exposureToken(like BTC) array
    address[] internal _exposureTokens;

    /////////////////////////
    // methods/events/modifiers
    /////////////////////////
    event Deposit(address _user, address _exposureToken, uint256 _amount, uint256 _exposureAmount, uint256 _markPrice, uint256 _share);
    event Withdraw(address _user, address _exposureToken, uint256 _amount, uint256 _exposureAmount, uint256 _markPrice, uint256 _share);
    event Rebalancing(address _user, address _exposureToken, bool _increase, uint256 _amount, uint256 _swappedAmount, uint256 _markPrice);
    event ChangeMushMon(address _user, address _exposureToken, address _oldMushMon, address _newMushMon);
    event ChangeYieldFarm(address _user, address _exposureToken, address _oldFarm, address _newFarm);
    event ChangeRebalancingLeverage(address _user, address _exposureToken, uint256 _oldLevBps, uint256 _newLevBps);

    modifier onlyGovernance(){
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor(address _token, address _governance, address _timelock)
        public
        ERC20Permit(
            string(abi.encodePacked("MushMon ", ERC20(_token).name())),
            string(abi.encodePacked("mm", ERC20(_token).symbol()))
        )
    {
        _setupDecimals(ERC20(_token).decimals());
        tokenDecimalDivisor = _decimalDivisor(ERC20(_token).decimals());
        
        token = IERC20(_token);
        governance = _governance;
        timelock = _timelock;
        
        IERC20(_token).safeApprove(swapDEX, uint256(-1));
    }
    
    /////////////////////////
    // getters
    /////////////////////////

    function exposureTokens() public view returns (address[] memory) {
        return _exposureTokens;
    }

    function getName() public pure returns(string memory){
        return "MushMonsV1";
    }
    
    // get Total Token Locked for this MushMon
    function balanceOfToken(address _token) public view returns (uint256) {
        uint256 _tokenBal;
        for (uint i = 0;i < _yieldFarms[_token].length;i++){
             address _farm = _yieldFarms[_token][i];
             uint256 _share = IERC20(_farm).balanceOf(address(this));
             _tokenBal = _tokenBal.add(_convertToToken(_farm, _share));
        }
        return _tokenBal.add(IERC20(_token).balanceOf(address(this)));
    }
    
    // get stablecoin token withdrawable for given _user and _exposure token
    function amountOfStableCoin(address _user, address _exposure) public view returns (uint256) {
        return amountOfTokenForShare(_user, address(token), mintedShares[_user][_exposure]);
    }
    
    // get exposure token withdrawable for given _user and _exposure token
    function amountOfExposureToken(address _user, address _exposure) public view returns (uint256) {
        return amountOfTokenForShare(_user, _exposure, mintedShares[_user][_exposure]);
    }
    
    // get token withdrawable for given _user and _exposure token and _share
    function amountOfTokenForShare(address _user, address _token, uint256 _share) public view returns (uint256) {
        address _tokenVault = yieldVaults[_user][_token];
        uint256 _shareTotal = _token == address(token)? balanceOf(_user) : mintedShares[_user][_token];
        
        require(_tokenVault != address(0), "!invalidVault");
        require(_share <= _shareTotal, "!invalidShare");
        
        uint256 _yieldShare = yieldVaultShares[_user][_tokenVault];
        _yieldShare = _yieldShare.mul(_share).div(_shareTotal);
        return _convertToToken(_tokenVault, _yieldShare);
    }
    
    /////////////////////////
    // setters
    /////////////////////////

    function setOracleSamples(uint256 _samples) public onlyGovernance{
        oracleSamples = _samples;
    }

    function setGovernance(address _governance) public onlyGovernance{
        governance = _governance;
    }

    function setSwapSlippage(uint256 _slippage) public onlyGovernance{
        swapSlippage = _slippage;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }
    
    // MushMon initiator combo for exposure token
    function addNewExposureToken(address _exposure, address _oracle, address _yieldVault, uint256 _minAllowed, uint256 _maxAllowed) public {
        addExposureToken(_exposure);
        setExposureOracle(_exposure, _oracle);
        addYieldFarm(_exposure, _yieldVault);
        setExposureAllowance(_exposure, _minAllowed, _maxAllowed);
    }
    
    /////////////////////////
    // MushMons global Setters via timelock
    /////////////////////////
    
    function setExposureAllowance(address _exposure, uint256 _min, uint256 _max) public {
        require(msg.sender == timelock && _validExposureTokens[_exposure] && _min < _max, "!_exposureToken");
        exposureMinBalances[_exposure] = _min;
        exposureMaxBalances[_exposure] = _max;
    }

    function setExposureOracle(address _exposure, address _oracle) public {
        require(msg.sender == timelock && _validExposureTokens[_exposure] && _oracle != address(0), "!_exposureToken");
        exposureOracles[_exposure] = _oracle;
    }

    function setUniRoute(address _route) external {
        require(msg.sender == governance, "!governance");
        
        IERC20(token).safeApprove(swapDEX, 0);
        IERC20(token).safeApprove(_route, uint256(-1));
        
        for (uint i = 0;i < _exposureTokens.length;i++){
             IERC20(_exposureTokens[i]).safeApprove(swapDEX, 0);
             IERC20(_exposureTokens[i]).safeApprove(_route, uint256(-1));
        }
        
        swapDEX = _route;
    }
    
    function addExposureToken(address _token) public {
        require(msg.sender == timelock && _token != address(0) && !_validExposureTokens[_token], "!timelock");
        _validExposureTokens[_token] = true;
        _exposureTokens.push(_token);
        IERC20(_token).safeApprove(swapDEX, uint256(-1));
    }
    
    function addYieldFarm(address _token, address _farm) public {
        require(msg.sender == timelock && _farm != address(0) && !validYieldFarms[_token][_farm], "!timelock");
        validYieldFarms[_token][_farm] = true;
        _yieldFarms[_token].push(_farm);
        IERC20(_token).safeApprove(_farm, uint256(-1));
    }
    
    function addMushMons(address _mushmon) public {
        require(msg.sender == timelock && _mushmon != address(0), "!timelock");
        validMushMons[_mushmon] = true;
        
        RebalancingMon _mon = RebalancingMon(_mushmon);
        
        require(_mon.feeDestination() != address(0), "!feeDestination");
        validMushMonFeeDestination[_mushmon] = _mon.feeDestination();
        
        require(_mon.feeBps() < MAX_BPS, "!feeBps");
        validMushMonFeeBps[_mushmon] = _mon.feeBps();
    }
    
    function removeMushMons(address _mushmon) public {
        require(msg.sender == governance, "!governance");
        validMushMons[_mushmon] = false;
        validMushMonFeeBps[_mushmon] = 0;
        validMushMonFeeDestination[_mushmon] = address(0);
    }
    
    /////////////////////////
    // MushMons Core methods
    /////////////////////////
    
    // MushMon initiator combo for user
    function initMushMon(address _exposureToken, 
                         address _tokenVault,  
                         address _exposureVault,  
                         address _mushmon, 
                         uint256 _levBps, 
                         bytes calldata _mushmonConfig
    ) public {
        changeMushMons(_exposureToken, _mushmon);
        changeRebalancingLeverage(_exposureToken, _levBps);
        changeYieldFarms(address(token), _tokenVault);
        changeYieldFarms(_exposureToken, _exposureVault);
        RebalancingMon(_mushmon).configureForUser(msg.sender, _exposureToken, _mushmonConfig);
    }
    
    // change the rebalancing leverage for user
    function changeRebalancingLeverage(address _token, uint256 _levBps) public {
        require(_levBps >= MAX_BPS, "!leverageBps");
        uint256 _oldLevBps = exposureLeverageBps[msg.sender][_token];
        exposureLeverageBps[msg.sender][_token] = _levBps;
        emit ChangeRebalancingLeverage(msg.sender, _token, _oldLevBps, _levBps); 
    }
    
    // change the yield-farming for user
    function changeMushMons(address _token, address _mushmon) public {
        require(validMushMons[_mushmon], "!invalidVault");
        address _oldMushMon = exposureRebalancingMons[msg.sender][_token];
        exposureRebalancingMons[msg.sender][_token] = _mushmon;
        emit ChangeMushMon(msg.sender, _token, _oldMushMon, _mushmon);
    }
    
    // change the yield-farming for user
    function changeYieldFarms(address _token, address _vault) public {
        require(validYieldFarms[_token][_vault], "!invalidVault");
        
        address _tokenVault = yieldVaults[msg.sender][_token];
        yieldVaults[msg.sender][_token] = _vault;
        
        if (_tokenVault != address(0)){
            uint256 vaultShare = yieldVaultShares[msg.sender][_tokenVault];
            if (vaultShare > 0){
                uint256 _migrated = _yieldFarmingWithdrawShare(msg.sender, _token, _tokenVault, vaultShare);
                if (_migrated > 0){
                    _yieldFarmingDeposit(msg.sender, _token, _vault, _migrated);
                }
            }
        }
        
        emit ChangeYieldFarm(msg.sender, _token, _tokenVault, _vault);
    }

    // allow user to ape in MushMon with 
    //  - Either _amount stablecoin
    //  - Or _exposureAmount _exposure token
    function deposit(uint256 _amount, address _exposure, uint256 _exposureAmount) public nonReentrant {
        require(_amount == 0 || _exposureAmount == 0, '!onlyOneAsset');
        
        require(_validExposureTokens[_exposure], '!invalidExposureToken');
        
        require(yieldVaults[msg.sender][address(token)] != address(0), '!invalidYieldVault');
        require(yieldVaults[msg.sender][_exposure] != address(0), '!invalidYieldVaultExposure');
        
        uint256 shares = _amount;
        TriggerResult memory tr;
        
        uint256 markPrice = getMarkPrice(_exposure);
        uint256 _amt;
        if (_amount > 0){
            _amt = _calculateDeposit(address(token), _amount);
            // record the principal for later rebalancing
            tokenBalances[msg.sender][_exposure] = tokenBalances[msg.sender][_exposure].add(_amt);
            tr = TriggerResult(true, true, _amt.div(2), markPrice);
        } else{
            _amt = _calculateDeposit(address(_exposure), _exposureAmount);
            exposureBalances[msg.sender][_exposure] = exposureBalances[msg.sender][_exposure].add(_amt);
            shares = _convertExposure2Stablecoin(_exposure, _amt, markPrice);
            tr = TriggerResult(true, false, _amt.div(2), markPrice);
        }
        
        // mint share according to stalecoin value
        _mint(msg.sender, shares);
        mintedShares[msg.sender][_exposure] = mintedShares[msg.sender][_exposure].add(shares);
        
        // rebalancing with 50-50 style in stablecoin and _exposure token
        uint256 delta = _parseTriggerResultAndSwap(msg.sender, _exposure, tr);
        
        // ensure total minted share (denominated stablecoin value) in acceptable range
        uint256 maxBal = exposureMaxBalances[_exposure];
        if (maxBal > 0){
            require(mintedShares[msg.sender][_exposure] <= maxBal, '!maxAllowedBalance');
        }
        uint256 minBal = exposureMinBalances[_exposure];
        if (minBal > 0){
            require(mintedShares[msg.sender][_exposure] >= minBal, '!minAllowedBalance');
        }
        
        // deposit in yield farming
        if (tr.increase){
            _yieldFarmingDeposit(msg.sender, address(token), yieldVaults[msg.sender][address(token)], tr.amount);
            _yieldFarmingDeposit(msg.sender, _exposure, yieldVaults[msg.sender][_exposure], delta);
        } else{
            _yieldFarmingDeposit(msg.sender, address(token), yieldVaults[msg.sender][address(token)], delta);
            _yieldFarmingDeposit(msg.sender, _exposure, yieldVaults[msg.sender][_exposure], tr.amount);
        }
        
        emit Deposit(msg.sender, _exposure, _amount, _exposureAmount, markPrice, shares);
    }
    
    function _calculateDeposit(address _asset, uint256 _amount) internal returns(uint256){
        uint256 _deposited = _amount;
        uint256 _before = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = IERC20(_asset).balanceOf(address(this));
        require(_after >= _before, '!mimatchDeposit');
        _deposited = _after.sub(_before);
        return _deposited;
    }
	
    function _convertToMToken(address _tokenVault, uint256 _want) internal view returns (uint256){
        require(_tokenVault != address(0), '!noYieldVault');
        return _want.mul(1e18).div(IVault(_tokenVault).getRatio());
    }
	
    function _convertToToken(address _tokenVault, uint256 _share) internal view returns (uint256){
        require(_tokenVault != address(0), '!noYieldVault');
        return _share.mul(IVault(_tokenVault).getRatio()).div(1e18);
    }
    
    function _getPriceDecimal(address _exposure) internal view returns(uint256){
        uint256 _decimals = AggregatorV3Interface(exposureOracles[_exposure]).decimals();
        return _decimalDivisor(_decimals);
    }
    
    function _convertExposure2Stablecoin(address _exposure, uint256 _exposureAmt, uint256 _price) internal view returns(uint256){
        uint256 _exposureDecimalDivisor = _decimalDivisor(ERC20(_exposure).decimals());
        return _exposureAmt.mul(_price).div(_getPriceDecimal(_exposure)).mul(tokenDecimalDivisor).div(_exposureDecimalDivisor);
    }
    
    function _convertStablecoin2Exposure(address _exposure, uint256 _stablecoinAmt, uint256 _price) internal view returns(uint256){
        uint256 _exposureDecimalDivisor = _decimalDivisor(ERC20(_exposure).decimals());
        return _stablecoinAmt.mul(_getPriceDecimal(_exposure)).div(_price).mul(_exposureDecimalDivisor).div(tokenDecimalDivisor);
    }
    
    function _decimalDivisor(uint256 _decimals) internal view returns(uint256){
        return (10 ** _decimals);
    }
    
    // function called by rebalancing bots for users
    function rebalance(address _user, address _exposure, bytes calldata _extraRebalancingData) public nonReentrant {
        
        require(_validExposureTokens[_exposure], '!invalidExposureToken');
        
        uint256 markPrice = getMarkPrice(_exposure);
        uint256 lastPrice = lastRebalancingPrices[_user][_exposure];
        
        require(lastPrice > 0, '!notInitializedUser'); 
        
        TriggerQuery memory tq = TriggerQuery(_user, _exposure, 
                                              markPrice, 
                                              lastPrice,
                                              lastRebalancingTimestamp[_user][_exposure], 
                                              exposureBalances[_user][_exposure], 
                                              tokenBalances[_user][_exposure], 
                                              exposureLeverageBps[_user][_exposure], 
                                              AggregatorV3Interface(exposureOracles[_exposure]).decimals(), 
                                              ERC20(address(token)).decimals(),
                                              _extraRebalancingData);
                  
        // trigger MushMon  
        address _mushmon = exposureRebalancingMons[_user][_exposure];
        require(validMushMons[_mushmon], '!invalidMushMon');
        TriggerResult memory tr = RebalancingMon(_mushmon).triggerRebalancing(tq);
        
        require(tr.trigger, '!rebalanceTriggered');
            
        // get required asset for rebalancing from yield farming if necessary
        uint256 _feePaid = tr.amount.mul(validMushMonFeeBps[_mushmon]).div(MAX_BPS);
            
        if (tr.increase){
            require(yieldVaults[_user][address(token)] != address(0), '!invalidYieldVault');
            _yieldFarmingWithdraw(_user, address(token), yieldVaults[_user][address(token)], tr.amount);
            IERC20(token).safeTransfer(validMushMonFeeDestination[_mushmon], _feePaid);
        } else{
            require(yieldVaults[_user][_exposure] != address(0), '!invalidYieldVaultExposure');
            _yieldFarmingWithdraw(_user, _exposure, yieldVaults[_user][_exposure], tr.amount);
            IERC20(_exposure).safeTransfer(validMushMonFeeDestination[_mushmon], _feePaid);
        }
            
        tr.amount = tr.amount.sub(_feePaid);
        
        // rebalancing the positions
        uint256 delta = _parseTriggerResultAndSwap(_user, _exposure, tr);
        
        // re-invest in yield-farming
        if (delta > 0){
            if (tr.increase){
                _yieldFarmingDeposit(_user, _exposure, yieldVaults[_user][_exposure], delta);
            } else{
                _yieldFarmingDeposit(_user, address(token), yieldVaults[_user][address(token)], delta);
            }
        }
    }
    
    function getMarkPrice(address _exposure) public view returns(uint256) {
        require(exposureOracles[_exposure] != address(0), '!noOracle');
        (uint roundId,int lastMarkPrice,,,) = AggregatorV3Interface(exposureOracles[_exposure]).latestRoundData(); 
        uint256 avgPrice = uint256(lastMarkPrice);
        for(uint i = 1;i < oracleSamples;i++){
            uint80 rID = uint80(roundId.sub(i));
            (,int answer,,,) = AggregatorV3Interface(exposureOracles[_exposure]).getRoundData(rID); 
            avgPrice = avgPrice.add(uint256(answer));
        }
        return avgPrice.div(oracleSamples);
    }

    // _withdrawType: 
    //    0 - withdraw in ONLY stablecoin, 
    //    1 - withdraw in ONLY expoureToken, 
    //    2 - withdraw in both
    function withdraw(uint256 _shares, address _exposure, uint256 _withdrawType) public nonReentrant {
        uint256 _balShare = mintedShares[msg.sender][_exposure];
        
        require(_validExposureTokens[_exposure], '!invalidExposureToken');
        require(_balShare >= _shares, '!invalidWithdrawShare');
        
        uint256 _stablecoinAmt = amountOfTokenForShare(msg.sender, address(token), _shares);
        uint256 _exposureAmt = amountOfTokenForShare(msg.sender, _exposure, _shares);
        
        // burn share
        _burn(msg.sender, _shares);
        mintedShares[msg.sender][_exposure] = mintedShares[msg.sender][_exposure].sub(_shares);
        
        // ensure the remaining share (denominated stablecoin value) in acceptable range
        uint256 minBal = exposureMinBalances[_exposure];
        if (minBal > 0){
            require(mintedShares[msg.sender][_exposure] >= minBal || mintedShares[msg.sender][_exposure] == 0, '!minAllowedBalance');
        }
        
        // get required asset for withdrawal from yield farming if necessary
        if (_stablecoinAmt > 0) {
            require(yieldVaults[msg.sender][address(token)] != address(0), '!invalidYieldVault');
            _yieldFarmingWithdraw(msg.sender, address(token), yieldVaults[msg.sender][address(token)], _stablecoinAmt);
        }
        
        if (_exposureAmt > 0) {
            require(yieldVaults[msg.sender][_exposure] != address(0), '!invalidYieldVaultExposure');
            _yieldFarmingWithdraw(msg.sender, _exposure, yieldVaults[msg.sender][_exposure], _exposureAmt);
        }
        
        uint256 markPrice = getMarkPrice(_exposure);
        if (_withdrawType == 0){
            uint256 delta = _swapInDex(_exposure, address(token), _exposureAmt, markPrice, true);
            _stablecoinAmt = _stablecoinAmt.add(delta);
            _exposureAmt = 0;
        } else if (_withdrawType == 1){
            uint256 delta = _swapInDex(address(token), _exposure, _stablecoinAmt, markPrice, false);
            _exposureAmt = _exposureAmt.add(delta);
            _stablecoinAmt = 0;
        }
        
        // update balances
        tokenBalances[msg.sender][_exposure] = tokenBalances[msg.sender][_exposure].mul(_balShare.sub(_shares)).div(_balShare);
        exposureBalances[msg.sender][_exposure] = exposureBalances[msg.sender][_exposure].mul(_balShare.sub(_shares)).div(_balShare);

        // final withdrawal to user
        if (_stablecoinAmt > 0) {
            uint256 _tBal = token.balanceOf(address(this));
            token.safeTransfer(msg.sender, _stablecoinAmt > _tBal? _tBal : _stablecoinAmt);
        }
        if (_exposureAmt > 0) {
            uint256 _eBal = IERC20(_exposure).balanceOf(address(this));
            IERC20(_exposure).safeTransfer(msg.sender, _exposureAmt > _eBal? _eBal : _exposureAmt);
        }
        
        emit Withdraw(msg.sender, _exposure, _stablecoinAmt, _exposureAmt, markPrice, _shares);
    }
    
    function _parseTriggerResultAndSwap(address _user, address _exposureToken, TriggerResult memory tr) internal returns(uint256){
        uint256 delta;
        if (tr.trigger){
            uint256 _executionPrice = tr.markPrice;
            uint256 _exposureDecimalDivisor = _decimalDivisor(ERC20(_exposureToken).decimals());
            uint256 _exposurePriceDecimalDivisor = _getPriceDecimal(_exposureToken);
            if (tr.increase){
                require(tokenBalances[_user][_exposureToken] >= tr.amount, '!notEnoughForIncExpo');
                tokenBalances[_user][_exposureToken] = tokenBalances[_user][_exposureToken].sub(tr.amount);
                delta = _swapInDex(address(token), _exposureToken, tr.amount, tr.markPrice, false);
                exposureBalances[_user][_exposureToken] = exposureBalances[_user][_exposureToken].add(delta);
                _executionPrice = tr.amount.mul(_exposureDecimalDivisor).div(delta).mul(_exposurePriceDecimalDivisor).div(tokenDecimalDivisor);
            } else{
                require(exposureBalances[_user][_exposureToken] >= tr.amount, '!notEnoughForDecExpo');
                exposureBalances[_user][_exposureToken] = exposureBalances[_user][_exposureToken].sub(tr.amount);
                delta = _swapInDex(_exposureToken, address(token), tr.amount, tr.markPrice, true);
                tokenBalances[_user][_exposureToken] = tokenBalances[_user][_exposureToken].add(delta);
                _executionPrice = delta.mul(_exposureDecimalDivisor).div(tr.amount).mul(_exposurePriceDecimalDivisor).div(tokenDecimalDivisor);
            }
            
            lastRebalancingPrices[_user][_exposureToken] = _executionPrice;
            lastRebalancingTimestamp[_user][_exposureToken] = now;
            
            emit Rebalancing(_user, _exposureToken, tr.increase, tr.amount, delta, _executionPrice);
        }
        return delta;
    }
    
    // move asset to yield farming if enabled
    function _yieldFarmingDeposit(address _user, address _token, address _tokenVault, uint256 _amount) internal returns(uint256){
        require(_tokenVault != address(0) && validYieldFarms[_token][_tokenVault], '!noYieldVault');
        uint256 _vaultShare;
        if (_amount > 0){
            _vaultShare = IERC20(_tokenVault).balanceOf(address(this));
            IVault(_tokenVault).deposit(_amount);
            uint256 _after = IERC20(_tokenVault).balanceOf(address(this));
            require(_after >= _vaultShare, '!mismatchYieldDeposit');
            _vaultShare = _after.sub(_vaultShare);
            
            yieldVaultShares[_user][_tokenVault] = yieldVaultShares[_user][_tokenVault].add(_vaultShare);
        }
        return _vaultShare;
    }
    
    // redeem asset from yield farming if any for given share
    function _yieldFarmingWithdrawShare(address _user, address _token, address _tokenVault, uint256 _share) internal returns(uint256){
        require(_tokenVault != address(0) && validYieldFarms[_token][_tokenVault], '!noYieldVault');
        uint256 _actual;
        if (_share > 0){
            _share = yieldVaultShares[_user][_tokenVault] > _share ? _share : yieldVaultShares[_user][_tokenVault];
            yieldVaultShares[_user][_tokenVault] = yieldVaultShares[_user][_tokenVault].sub(_share);
            
            _actual = IERC20(_token).balanceOf(address(this));
            IVault(_tokenVault).withdraw(_share);
            uint256 _after = IERC20(_token).balanceOf(address(this));
            require(_after >= _actual, '!mismatchYieldWithdraw');
            _actual = _after.sub(_actual);
        }
        return _actual;
    }
    
    // redeem asset from yield farming if any for given token amount
    function _yieldFarmingWithdraw(address _user, address _token, address _tokenVault, uint256 _want) internal returns(uint256){
        uint256 _vaultShare = _convertToMToken(_tokenVault, _want);
        return _yieldFarmingWithdrawShare(_user, _token, _tokenVault, _vaultShare);
    }
    
    function _swapInDex(address _from, address _to, uint256 _amountIn, uint256 _markPrice, bool _fromExposure) internal returns(uint256 amountOutput){
        if (_amountIn == 0){
            return 0; 
        }
        
        uint256 _bal = IERC20(_from).balanceOf(address(this));
        _amountIn = _amountIn > _bal? _bal : _amountIn;
        
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        
        uint256 _slippage = _fromExposure? _convertExposure2Stablecoin(_from, _amountIn, _markPrice) : _convertStablecoin2Exposure(_to, _amountIn, _markPrice);
        _slippage = _slippage.mul(MAX_BPS.sub(swapSlippage)).div(MAX_BPS);
        
        uint256[] memory outputs = UniswapRouterV2(swapDEX).swapExactTokensForTokens(_amountIn, _slippage, path, address(this), now);
        return outputs[1];
    }
    
    // this MushMon share token is not allowed to transfer
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender == recipient && sender == address(0), '!noShareTransferAllowed');
    }

}