// SPDX-License-Identifier: MIT

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDispatcher Interface
/// @author Enzyme Council <[email protected]>
interface IDispatcher {
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external;

    function claimOwnership() external;

    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external returns (address vaultProxy_);

    function executeMigration(address _vaultProxy, bool _bypassFailure) external;

    function getCurrentFundDeployer() external view returns (address currentFundDeployer_);

    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        returns (address fundDeployer_);

    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        );

    function getMigrationTimelock() external view returns (uint256 migrationTimelock_);

    function getNominatedOwner() external view returns (address nominatedOwner_);

    function getOwner() external view returns (address owner_);

    function getSharesTokenSymbol() external view returns (string memory sharesTokenSymbol_);

    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        returns (uint256 secondsRemaining_);

    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasExecutableRequest_);

    function hasMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasMigrationRequest_);

    function removeNominatedOwner() external;

    function setCurrentFundDeployer(address _nextFundDeployer) external;

    function setMigrationTimelock(uint256 _nextTimelock) external;

    function setNominatedOwner(address _nextNominatedOwner) external;

    function setSharesTokenSymbol(string calldata _nextSymbol) external;

    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IMigratableVault Interface
/// @author Enzyme Council <[email protected]>
/// @dev DO NOT EDIT CONTRACT
interface IMigratableVault {
    function canMigrate(address _who) external view returns (bool canMigrate_);

    function init(
        address _owner,
        address _accessor,
        string calldata _fundName
    ) external;

    function setAccessor(address _nextAccessor) external;

    function setVaultLib(address _nextVaultLib) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./VaultLibBaseCore.sol";

/// @title VaultLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice The first implementation of VaultLibBaseCore, with additional events and storage
/// @dev All subsequent implementations should inherit the previous implementation,
/// e.g., `VaultLibBase2 is VaultLibBase1`
/// DO NOT EDIT CONTRACT.
abstract contract VaultLibBase1 is VaultLibBaseCore {
    event AssetWithdrawn(address indexed asset, address indexed target, uint256 amount);

    event TrackedAssetAdded(address asset);

    event TrackedAssetRemoved(address asset);

    address[] internal trackedAssets;
    mapping(address => bool) internal assetToIsTracked;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../utils/IMigratableVault.sol";
import "./utils/ProxiableVaultLib.sol";
import "./utils/SharesTokenBase.sol";

/// @title VaultLibBaseCore Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and
/// required functions for a VaultLib implementation
/// @dev DO NOT EDIT CONTRACT. If new events or storage are necessary, they should be added to
/// a numbered VaultLibBaseXXX that inherits the previous base. See VaultLibBase1.
abstract contract VaultLibBaseCore is IMigratableVault, ProxiableVaultLib, SharesTokenBase {
    event AccessorSet(address prevAccessor, address nextAccessor);

    event MigratorSet(address prevMigrator, address nextMigrator);

    event OwnerSet(address prevOwner, address nextOwner);

    event VaultLibSet(address prevVaultLib, address nextVaultLib);

    address internal accessor;
    address internal creator;
    address internal migrator;
    address internal owner;

    // EXTERNAL FUNCTIONS

    /// @notice Initializes the VaultProxy with core configuration
    /// @param _owner The address to set as the fund owner
    /// @param _accessor The address to set as the permissioned accessor of the VaultLib
    /// @param _fundName The name of the fund
    /// @dev Serves as a per-proxy pseudo-constructor
    function init(
        address _owner,
        address _accessor,
        string calldata _fundName
    ) external override {
        require(creator == address(0), "init: Proxy already initialized");
        creator = msg.sender;
        sharesName = _fundName;

        __setAccessor(_accessor);
        __setOwner(_owner);

        emit VaultLibSet(address(0), getVaultLib());
    }

    /// @notice Sets the permissioned accessor of the VaultLib
    /// @param _nextAccessor The address to set as the permissioned accessor of the VaultLib
    function setAccessor(address _nextAccessor) external override {
        require(msg.sender == creator, "setAccessor: Only callable by the contract creator");

        __setAccessor(_nextAccessor);
    }

    /// @notice Sets the VaultLib target for the VaultProxy
    /// @param _nextVaultLib The address to set as the VaultLib
    /// @dev This function is absolutely critical. __updateCodeAddress() validates that the
    /// target is a valid Proxiable contract instance.
    /// Does not block _nextVaultLib from being the same as the current VaultLib
    function setVaultLib(address _nextVaultLib) external override {
        require(msg.sender == creator, "setVaultLib: Only callable by the contract creator");

        address prevVaultLib = getVaultLib();

        __updateCodeAddress(_nextVaultLib);

        emit VaultLibSet(prevVaultLib, _nextVaultLib);
    }

    // PUBLIC FUNCTIONS

    /// @notice Checks whether an account is allowed to migrate the VaultProxy
    /// @param _who The account to check
    /// @return canMigrate_ True if the account is allowed to migrate the VaultProxy
    function canMigrate(address _who) public view virtual override returns (bool canMigrate_) {
        return _who == owner || _who == migrator;
    }

    /// @notice Gets the VaultLib target for the VaultProxy
    /// @return vaultLib_ The address of the VaultLib target
    function getVaultLib() public view returns (address vaultLib_) {
        assembly {
            // solium-disable-line
            vaultLib_ := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
        return vaultLib_;
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper to set the permissioned accessor of the VaultProxy.
    /// Does not prevent the prevAccessor from being the _nextAccessor.
    function __setAccessor(address _nextAccessor) internal {
        require(_nextAccessor != address(0), "__setAccessor: _nextAccessor cannot be empty");
        address prevAccessor = accessor;

        accessor = _nextAccessor;

        emit AccessorSet(prevAccessor, _nextAccessor);
    }

    /// @dev Helper to set the owner of the VaultProxy
    function __setOwner(address _nextOwner) internal {
        require(_nextOwner != address(0), "__setOwner: _nextOwner cannot be empty");
        address prevOwner = owner;
        require(_nextOwner != prevOwner, "__setOwner: _nextOwner is the current owner");

        owner = _nextOwner;

        emit OwnerSet(prevOwner, _nextOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ProxiableVaultLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract that defines the upgrade behavior for VaultLib instances
/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967
/// Code position in storage is `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`,
/// which is "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc".
abstract contract ProxiableVaultLib {
    /// @dev Updates the target of the proxy to be the contract at _nextVaultLib
    function __updateCodeAddress(address _nextVaultLib) internal {
        require(
            bytes32(0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5) ==
                ProxiableVaultLib(_nextVaultLib).proxiableUUID(),
            "__updateCodeAddress: _nextVaultLib not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
                _nextVaultLib
            )
        }
    }

    /// @notice Returns a unique bytes32 hash for VaultLib instances
    /// @return uuid_ The bytes32 hash representing the UUID
    /// @dev The UUID is `bytes32(keccak256('mln.proxiable.vaultlib'))`
    function proxiableUUID() public pure returns (bytes32 uuid_) {
        return 0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./VaultLibSafeMath.sol";

/// @title StandardERC20 Contract
/// @author Enzyme Council <[email protected]>
/// @notice Contains the storage, events, and default logic of an ERC20-compliant contract.
/// @dev The logic can be overridden by VaultLib implementations.
/// Adapted from OpenZeppelin 3.2.0.
/// DO NOT EDIT THIS CONTRACT.
abstract contract SharesTokenBase {
    using VaultLibSafeMath for uint256;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    string internal sharesName;
    string internal sharesSymbol;
    uint256 internal sharesTotalSupply;
    mapping(address => uint256) internal sharesBalances;
    mapping(address => mapping(address => uint256)) internal sharesAllowances;

    // EXTERNAL FUNCTIONS

    /// @dev Standard implementation of ERC20's approve(). Can be overridden.
    function approve(address _spender, uint256 _amount) public virtual returns (bool) {
        __approve(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev Standard implementation of ERC20's transfer(). Can be overridden.
    function transfer(address _recipient, uint256 _amount) public virtual returns (bool) {
        __transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /// @dev Standard implementation of ERC20's transferFrom(). Can be overridden.
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual returns (bool) {
        __transfer(_sender, _recipient, _amount);
        __approve(
            _sender,
            msg.sender,
            sharesAllowances[_sender][msg.sender].sub(
                _amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    // EXTERNAL FUNCTIONS - VIEW

    /// @dev Standard implementation of ERC20's allowance(). Can be overridden.
    function allowance(address _owner, address _spender) public view virtual returns (uint256) {
        return sharesAllowances[_owner][_spender];
    }

    /// @dev Standard implementation of ERC20's balanceOf(). Can be overridden.
    function balanceOf(address _account) public view virtual returns (uint256) {
        return sharesBalances[_account];
    }

    /// @dev Standard implementation of ERC20's decimals(). Can not be overridden.
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /// @dev Standard implementation of ERC20's name(). Can be overridden.
    function name() public view virtual returns (string memory) {
        return sharesName;
    }

    /// @dev Standard implementation of ERC20's symbol(). Can be overridden.
    function symbol() public view virtual returns (string memory) {
        return sharesSymbol;
    }

    /// @dev Standard implementation of ERC20's totalSupply(). Can be overridden.
    function totalSupply() public view virtual returns (uint256) {
        return sharesTotalSupply;
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper for approve(). Can be overridden.
    function __approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        sharesAllowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /// @dev Helper to burn tokens from an account. Can be overridden.
    function __burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: burn from the zero address");

        sharesBalances[_account] = sharesBalances[_account].sub(
            _amount,
            "ERC20: burn amount exceeds balance"
        );
        sharesTotalSupply = sharesTotalSupply.sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /// @dev Helper to mint tokens to an account. Can be overridden.
    function __mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");

        sharesTotalSupply = sharesTotalSupply.add(_amount);
        sharesBalances[_account] = sharesBalances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    /// @dev Helper to transfer tokens between accounts. Can be overridden.
    function __transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        sharesBalances[_sender] = sharesBalances[_sender].sub(
            _amount,
            "ERC20: transfer amount exceeds balance"
        );
        sharesBalances[_recipient] = sharesBalances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title VaultLibSafeMath library
/// @notice A narrowed, verbatim implementation of OpenZeppelin 3.2.0 SafeMath
/// for use with VaultLib
/// @dev Preferred to importing from npm to guarantee consistent logic and revert reasons
/// between VaultLib implementations
/// DO NOT EDIT THIS CONTRACT
library VaultLibSafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "VaultLibSafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "VaultLibSafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "VaultLibSafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "VaultLibSafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "VaultLibSafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../persistent/utils/IMigratableVault.sol";

/// @title IVault Interface
/// @author Enzyme Council <[email protected]>
interface IVault is IMigratableVault {
    function addTrackedAsset(address) external;

    function approveAssetSpender(
        address,
        address,
        uint256
    ) external;

    function burnShares(address, uint256) external;

    function callOnContract(address, bytes calldata) external;

    function getAccessor() external view returns (address);

    function getOwner() external view returns (address);

    function getTrackedAssets() external view returns (address[] memory);

    function isTrackedAsset(address) external view returns (bool);

    function mintShares(address, uint256) external;

    function removeTrackedAsset(address) external;

    function transferShares(
        address,
        address,
        uint256
    ) external;

    function withdrawAssetTo(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../../persistent/dispatcher/IDispatcher.sol";
import "../../../../persistent/vault/VaultLibBase1.sol";
import "./IVault.sol";

/// @title VaultLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice The per-release proxiable library contract for VaultProxy
/// @dev The difference in terminology between "asset" and "trackedAsset" is intentional.
/// A fund might actually have asset balances of un-tracked assets,
/// but only tracked assets are used in gav calculations.
/// Note that this contract inherits VaultLibSafeMath (a verbatim Open Zeppelin SafeMath copy)
/// from SharesTokenBase via VaultLibBase1
contract VaultLib is VaultLibBase1, IVault {
    using SafeERC20 for ERC20;

    // Before updating TRACKED_ASSETS_LIMIT in the future, it is important to consider:
    // 1. The highest tracked assets limit ever allowed in the protocol
    // 2. That the next value will need to be respected by all future releases
    uint256 private constant TRACKED_ASSETS_LIMIT = 20;

    modifier onlyAccessor() {
        require(msg.sender == accessor, "Only the designated accessor can make this call");
        _;
    }

    /////////////
    // GENERAL //
    /////////////

    /// @notice Sets the account that is allowed to migrate a fund to new releases
    /// @param _nextMigrator The account to set as the allowed migrator
    /// @dev Set to address(0) to remove the migrator.
    function setMigrator(address _nextMigrator) external {
        require(msg.sender == owner, "setMigrator: Only the owner can call this function");
        address prevMigrator = migrator;
        require(_nextMigrator != prevMigrator, "setMigrator: Value already set");

        migrator = _nextMigrator;

        emit MigratorSet(prevMigrator, _nextMigrator);
    }

    ///////////
    // VAULT //
    ///////////

    /// @notice Adds a tracked asset to the fund
    /// @param _asset The asset to add
    /// @dev Allows addition of already tracked assets to fail silently.
    function addTrackedAsset(address _asset) external override onlyAccessor {
        if (!isTrackedAsset(_asset)) {
            require(
                trackedAssets.length < TRACKED_ASSETS_LIMIT,
                "addTrackedAsset: Limit exceeded"
            );

            assetToIsTracked[_asset] = true;
            trackedAssets.push(_asset);

            emit TrackedAssetAdded(_asset);
        }
    }

    /// @notice Grants an allowance to a spender to use the fund's asset
    /// @param _asset The asset for which to grant an allowance
    /// @param _target The spender of the allowance
    /// @param _amount The amount of the allowance
    function approveAssetSpender(
        address _asset,
        address _target,
        uint256 _amount
    ) external override onlyAccessor {
        ERC20 assetContract = ERC20(_asset);
        if (assetContract.balanceOf(_target) > 0) {
            assetContract.safeApprove(_target, 0);
        }
        assetContract.safeApprove(_target, _amount);
    }

    /// @notice Makes an arbitrary call with this contract as the sender
    /// @param _contract The contract to call
    /// @param _callData The call data for the call
    function callOnContract(address _contract, bytes calldata _callData)
        external
        override
        onlyAccessor
    {
        (bool success, bytes memory returnData) = _contract.call(_callData);
        require(success, string(returnData));
    }

    /// @notice Removes a tracked asset from the fund
    /// @param _asset The asset to remove
    function removeTrackedAsset(address _asset) external override onlyAccessor {
        __removeTrackedAsset(_asset);
    }

    /// @notice Withdraws an asset from the VaultProxy to a given account
    /// @param _asset The asset to withdraw
    /// @param _target The account to which to withdraw the asset
    /// @param _amount The amount of asset to withdraw
    function withdrawAssetTo(
        address _asset,
        address _target,
        uint256 _amount
    ) external override onlyAccessor {
        ERC20(_asset).safeTransfer(_target, _amount);

        emit AssetWithdrawn(_asset, _target, _amount);
    }

    /// @dev Helper to the get the Vault's balance of a given asset
    function __getAssetBalance(address _asset) private view returns (uint256 balance_) {
        return ERC20(_asset).balanceOf(address(this));
    }

    /// @dev Helper to remove an asset from a fund's tracked assets.
    /// Allows removal of non-tracked asset to fail silently.
    function __removeTrackedAsset(address _asset) private {
        if (isTrackedAsset(_asset)) {
            assetToIsTracked[_asset] = false;

            uint256 trackedAssetsCount = trackedAssets.length;
            for (uint256 i = 0; i < trackedAssetsCount; i++) {
                if (trackedAssets[i] == _asset) {
                    if (i < trackedAssetsCount - 1) {
                        trackedAssets[i] = trackedAssets[trackedAssetsCount - 1];
                    }
                    trackedAssets.pop();
                    break;
                }
            }

            emit TrackedAssetRemoved(_asset);
        }
    }

    ////////////
    // SHARES //
    ////////////

    /// @notice Burns fund shares from a particular account
    /// @param _target The account for which to burn shares
    /// @param _amount The amount of shares to burn
    function burnShares(address _target, uint256 _amount) external override onlyAccessor {
        __burn(_target, _amount);
    }

    /// @notice Mints fund shares to a particular account
    /// @param _target The account for which to burn shares
    /// @param _amount The amount of shares to mint
    function mintShares(address _target, uint256 _amount) external override onlyAccessor {
        __mint(_target, _amount);
    }

    /// @notice Transfers fund shares from one account to another
    /// @param _from The account from which to transfer shares
    /// @param _to The account to which to transfer shares
    /// @param _amount The amount of shares to transfer
    function transferShares(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyAccessor {
        __transfer(_from, _to, _amount);
    }

    // ERC20 overrides

    /// @dev Disallows the standard ERC20 approve() function
    function approve(address, uint256) public override returns (bool) {
        revert("Unimplemented");
    }

    /// @notice Gets the `symbol` value of the shares token
    /// @return symbol_ The `symbol` value
    /// @dev Defers the shares symbol value to the Dispatcher contract
    function symbol() public view override returns (string memory symbol_) {
        return IDispatcher(creator).getSharesTokenSymbol();
    }

    /// @dev Disallows the standard ERC20 transfer() function
    function transfer(address, uint256) public override returns (bool) {
        revert("Unimplemented");
    }

    /// @dev Disallows the standard ERC20 transferFrom() function
    function transferFrom(
        address,
        address,
        uint256
    ) public override returns (bool) {
        revert("Unimplemented");
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `accessor` variable
    /// @return accessor_ The `accessor` variable value
    function getAccessor() external view override returns (address accessor_) {
        return accessor;
    }

    /// @notice Gets the `creator` variable
    /// @return creator_ The `creator` variable value
    function getCreator() external view returns (address creator_) {
        return creator;
    }

    /// @notice Gets the `migrator` variable
    /// @return migrator_ The `migrator` variable value
    function getMigrator() external view returns (address migrator_) {
        return migrator;
    }

    /// @notice Gets the `owner` variable
    /// @return owner_ The `owner` variable value
    function getOwner() external view override returns (address owner_) {
        return owner;
    }

    /// @notice Gets the `trackedAssets` variable
    /// @return trackedAssets_ The `trackedAssets` variable value
    function getTrackedAssets() external view override returns (address[] memory trackedAssets_) {
        return trackedAssets;
    }

    /// @notice Check whether an address is a tracked asset of the fund
    /// @param _asset The address to check
    /// @return isTrackedAsset_ True if the address is a tracked asset of the fund
    function isTrackedAsset(address _asset) public view override returns (bool isTrackedAsset_) {
        return assetToIsTracked[_asset];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IIntegrationManager interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for the IntegrationManager
interface IIntegrationManager {
    enum SpendAssetsHandleType {None, Approve, Transfer, Remove}
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../IIntegrationManager.sol";

/// @title Integration Adapter interface
/// @author Enzyme Council <[email protected]>
/// @notice Interface for all integration adapters
interface IIntegrationAdapter {
    function identifier() external pure returns (string memory identifier_);

    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
        external
        view
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        );
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../../../../core/fund/vault/VaultLib.sol";
import "../utils/AdapterBase.sol";

/// @title TrackedAssetsAdapter Contract
/// @author Enzyme Council <[email protected]>
/// @notice Adapter to add tracked assets to a fund (useful e.g. to handle token airdrops)
contract TrackedAssetsAdapter is AdapterBase {
    constructor(address _integrationManager) public AdapterBase(_integrationManager) {}

    /// @notice Add multiple assets to the Vault's list of tracked assets
    /// @dev No need to perform any validation or implement any logic
    function addTrackedAssets(
        address,
        bytes calldata,
        bytes calldata
    ) external view {}

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "TRACKED_ASSETS";
    }

    /// @notice Parses the expected assets to receive from a call on integration
    /// @param _selector The function selector for the callOnIntegration
    /// @param _encodedCallArgs The encoded parameters for the callOnIntegration
    /// @return spendAssetsHandleType_ A type that dictates how to handle granting
    /// the adapter access to spend assets (`None` by default)
    /// @return spendAssets_ The assets to spend in the call
    /// @return spendAssetAmounts_ The max asset amounts to spend in the call
    /// @return incomingAssets_ The assets to receive in the call
    /// @return minIncomingAssetAmounts_ The min asset amounts to receive in the call
    function parseAssetsForMethod(bytes4 _selector, bytes calldata _encodedCallArgs)
        external
        view
        override
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_,
            uint256[] memory minIncomingAssetAmounts_
        )
    {
        require(
            _selector == ADD_TRACKED_ASSETS_SELECTOR,
            "parseAssetsForMethod: _selector invalid"
        );

        incomingAssets_ = __decodeCallArgs(_encodedCallArgs);

        minIncomingAssetAmounts_ = new uint256[](incomingAssets_.length);
        for (uint256 i; i < minIncomingAssetAmounts_.length; i++) {
            minIncomingAssetAmounts_[i] = 1;
        }

        return (
            spendAssetsHandleType_,
            spendAssets_,
            spendAssetAmounts_,
            incomingAssets_,
            minIncomingAssetAmounts_
        );
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to decode the encoded call arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (address[] memory incomingAssets_)
    {
        return abi.decode(_encodedCallArgs, (address[]));
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../IIntegrationAdapter.sol";
import "./IntegrationSelectors.sol";

/// @title AdapterBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base contract for integration adapters
abstract contract AdapterBase is IIntegrationAdapter, IntegrationSelectors {
    using SafeERC20 for ERC20;

    address internal immutable INTEGRATION_MANAGER;

    /// @dev Provides a standard implementation for transferring assets between
    /// the fund's VaultProxy and the adapter, by wrapping the adapter action.
    /// This modifier should be implemented in almost all adapter actions, unless they
    /// do not move assets or can spend and receive assets directly with the VaultProxy
    modifier fundAssetsTransferHandler(
        address _vaultProxy,
        bytes memory _encodedAssetTransferArgs
    ) {
        (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType,
            address[] memory spendAssets,
            uint256[] memory spendAssetAmounts,
            address[] memory incomingAssets
        ) = __decodeEncodedAssetTransferArgs(_encodedAssetTransferArgs);

        // Take custody of spend assets (if necessary)
        if (spendAssetsHandleType == IIntegrationManager.SpendAssetsHandleType.Approve) {
            for (uint256 i = 0; i < spendAssets.length; i++) {
                ERC20(spendAssets[i]).safeTransferFrom(
                    _vaultProxy,
                    address(this),
                    spendAssetAmounts[i]
                );
            }
        }

        // Execute call
        _;

        // Transfer remaining assets back to the fund's VaultProxy
        __transferContractAssetBalancesToFund(_vaultProxy, incomingAssets);
        __transferContractAssetBalancesToFund(_vaultProxy, spendAssets);
    }

    modifier onlyIntegrationManager {
        require(
            msg.sender == INTEGRATION_MANAGER,
            "Only the IntegrationManager can call this function"
        );
        _;
    }

    constructor(address _integrationManager) public {
        INTEGRATION_MANAGER = _integrationManager;
    }

    // INTERNAL FUNCTIONS

    /// @dev Helper for adapters to approve their integratees with the max amount of an asset.
    /// Since everything is done atomically, and only the balances to-be-used are sent to adapters,
    /// there is no need to approve exact amounts on every call.
    function __approveMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        if (ERC20(_asset).allowance(address(this), _target) < _neededAmount) {
            ERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }

    /// @dev Helper to decode the _encodedAssetTransferArgs param passed to adapter call
    function __decodeEncodedAssetTransferArgs(bytes memory _encodedAssetTransferArgs)
        internal
        pure
        returns (
            IIntegrationManager.SpendAssetsHandleType spendAssetsHandleType_,
            address[] memory spendAssets_,
            uint256[] memory spendAssetAmounts_,
            address[] memory incomingAssets_
        )
    {
        return
            abi.decode(
                _encodedAssetTransferArgs,
                (IIntegrationManager.SpendAssetsHandleType, address[], uint256[], address[])
            );
    }

    /// @dev Helper to transfer full contract balances of assets to the specified VaultProxy
    function __transferContractAssetBalancesToFund(address _vaultProxy, address[] memory _assets)
        private
    {
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 postCallAmount = ERC20(_assets[i]).balanceOf(address(this));
            if (postCallAmount > 0) {
                ERC20(_assets[i]).safeTransfer(_vaultProxy, postCallAmount);
            }
        }
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `INTEGRATION_MANAGER` variable
    /// @return integrationManager_ The `INTEGRATION_MANAGER` variable value
    function getIntegrationManager() external view returns (address integrationManager_) {
        return INTEGRATION_MANAGER;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IntegrationSelectors Contract
/// @author Enzyme Council <[email protected]>
/// @notice Selectors for integration actions
/// @dev Selectors are created from their signatures rather than hardcoded for easy verification
abstract contract IntegrationSelectors {
    bytes4 public constant ADD_TRACKED_ASSETS_SELECTOR = bytes4(
        keccak256("addTrackedAssets(address,bytes,bytes)")
    );

    // Asset approval
    bytes4 public constant APPROVE_ASSETS_SELECTOR = bytes4(
        keccak256("approveAssets(address,bytes,bytes)")
    );

    // Trading
    bytes4 public constant TAKE_ORDER_SELECTOR = bytes4(
        keccak256("takeOrder(address,bytes,bytes)")
    );

    // Lending
    bytes4 public constant LEND_SELECTOR = bytes4(keccak256("lend(address,bytes,bytes)"));
    bytes4 public constant REDEEM_SELECTOR = bytes4(keccak256("redeem(address,bytes,bytes)"));

    // Staking
    bytes4 public constant STAKE_SELECTOR = bytes4(keccak256("stake(address,bytes,bytes)"));
    bytes4 public constant UNSTAKE_SELECTOR = bytes4(keccak256("unstake(address,bytes,bytes)"));

    // Rewards
    bytes4 public constant CLAIM_REWARDS_SELECTOR = bytes4(
        keccak256("claimRewards(address,bytes,bytes)")
    );

    // Combined
    bytes4 public constant CLAIM_REWARDS_AND_REINVEST_SELECTOR = bytes4(
        keccak256("claimRewardsAndReinvest(address,bytes,bytes)")
    );
    bytes4 public constant CLAIM_REWARDS_AND_SWAP_SELECTOR = bytes4(
        keccak256("claimRewardsAndSwap(address,bytes,bytes)")
    );
    bytes4 public constant LEND_AND_STAKE_SELECTOR = bytes4(
        keccak256("lendAndStake(address,bytes,bytes)")
    );
    bytes4 public constant UNSTAKE_AND_REDEEM_SELECTOR = bytes4(
        keccak256("unstakeAndRedeem(address,bytes,bytes)")
    );
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "details": {
      "constantOptimizer": true,
      "cse": true,
      "deduplicate": true,
      "jumpdestRemover": true,
      "orderLiterals": true,
      "peephole": true,
      "yul": false
    },
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}