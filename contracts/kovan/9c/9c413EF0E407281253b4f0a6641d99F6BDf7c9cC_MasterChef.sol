/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;


// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol
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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol
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

// File: @openzeppelin/contracts/GSN/Context.sol
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

// File: @openzeppelin/contracts/utils/Address.sol
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
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
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
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
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

        // _beforeTokenTransfer(sender, recipient, amount);

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

        // _beforeTokenTransfer(address(0), account, amount);

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

        // _beforeTokenTransfer(account, address(0), amount);

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
    // function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol
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

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol
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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts/access/Ownable.sol
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
contract Ownable is ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function init(address sender) public initializer {
        _owner = sender;
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
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// MasterChef is the master of ASTR. He can make ASTR and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ASTR is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
interface Dao {
    function getVotingStatus(address _user) external view returns (bool);
}

contract MasterChef is Ownable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt;
        bool cooldown;
        uint256 timestamp;
        uint256 totalUserBaseMul;
        uint256 totalReward;
        uint256 cooldowntimestamp;
        uint256 preBlockReward;
        uint256 totalClaimedReward;
        uint256 claimedToday;
        uint256 claimedTimestamp;
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that ASTRs distribution occurs.
        uint256 accASTRPerShare; // Accumulated ASTRs per share, times 1e12. See below.
        uint256 totalBaseMultiplier; // Total rm count of all user
    }

    // The ASTR TOKEN!
    address public ASTR;
    // Lm pool contract address
    address public lmpooladdr;
    // DAA contract address
    address public daaAddress;
    // DAO contract address
    address public daoAddress;
    // Dev address.
    address public devaddr;
    // Block number when bonus ASTR period ends.
    uint256 public bonusEndBlock;
    // ASTR tokens created per block.
    uint256 public ASTRPerBlock;
    // Bonus muliplier for early ASTR makers.
    uint256 public constant BONUS_MULTIPLIER = 1; //no Bonus
    // Pool lptokens info
    mapping(IERC20 => bool) public lpTokensStatus;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // The block number when ASTR mining starts.
    uint256 public startBlock;
    // The TimeLock Address!
    address public timelock;
    // The vault list
    mapping(uint256 => bool) public vaultList;

    //staking info structure
    struct StakeInfo {
        uint256 amount;
        uint256 totalAmount;
        uint256 timestamp;
        uint256 vault;
        bool deposit;
    }

    //stake in mapping
    mapping(uint256 => mapping(address => uint256)) private userStakingTrack;
    mapping(uint256 => mapping(address => mapping(uint256 => StakeInfo)))
        public stakeInfo;
    //mapping cooldown period on Withdraw
    mapping(uint256 => mapping(address => uint256)) public coolDownStart;
    //staking variables
    uint256 private dayseconds = 86400;
    mapping(uint256 => address[]) public userAddressesInPool;
    enum RewardType {INDIVIDUAL, FLAT, TVL_ADJUSTED}
    uint256 public ASTRPoolId;
    uint256 private ABP = 6500;

    //highest staked users
    struct HighestAstaStaker {
        uint256 deposited;
        address addr;
    }
    mapping(uint256 => HighestAstaStaker[]) public highestStakerInPool;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyDaaOrDAO() {
        require(
            daaAddress == _msgSender() || daoAddress == _msgSender(),
            "depositFromDaaAndDAO: caller is not the DAA/DAO"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the dao contract.
     */
    modifier onlyDao() {
        require(daoAddress == _msgSender(), "Caller is not the DAO");
        _;
    }

    /**
     * @dev Throws if called by any account other than the lm pool contract.
     */
    modifier onlyLmPool() {
        require(lmpooladdr == _msgSender(), "Caller is not the LmPool");
        _;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /**
    @notice This function is used for initializing the contract with sort of parameter
    @param _astr : astra contract address
    @param _devaddr : dev address or owner address 
    @param _ASTRPerBlock : ASTR rewards per block
    @param _startBlock : start block number for starting rewars distribution
    @param _bonusEndBlock : end block number for ending reward distribution
    @dev Description :
    This function is basically used to initialize the necessary things of chef contract and set the owner of the
    contract. This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function initialize(
        address _astr,
        address _devaddr,
        uint256 _ASTRPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external initializer {
        require(_astr != address(0), "Zero Address");
        require(_devaddr != address(0), "Zero Address");
        Ownable.init(_devaddr);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ASTR = _astr;
        devaddr = _devaddr;
        ASTRPerBlock = _ASTRPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    /**
    @notice Fetching the count of pools are already created
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
    @notice Fetching the list of top astra stakers 
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function getStakerList(uint256 _pid) public view returns (HighestAstaStaker[] memory) {
        return highestStakerInPool[_pid];
    }

    /**
    @notice Add a new pool for iToken and astra. Can only be called by the owner.
    @param _lpToken : iToken or astra contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function add(IERC20 _lpToken) external onlyOwner {
        require(address(_lpToken) != address(0), "Zero Address");
        require(lpTokensStatus[_lpToken] != true, "LP token already added");
        if (ASTR == address(_lpToken)) {
            ASTRPoolId = poolInfo.length;
        }
        // Here if the current block number is greater than start block then the lastRewardBlock will be current block
        // otherwise it will the same as start block.
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        // Pushing the pool info object after setting the all neccessary values.
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                lastRewardBlock: lastRewardBlock,
                accASTRPerShare: 0,
                totalBaseMultiplier: 0
            })
        );
        // Setting the lp token status true becuase pool is active.
        lpTokensStatus[_lpToken] = true;
    }

    /**
    @notice Add voult month. Can only be called by the owner.
    @param val : value of month like 0, 3, 6, 9, 12
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function addVault(uint256 val) external onlyOwner {
        vaultList[val] = true;
    }

    /**
    @notice Set lm pool address. Can only be called by the owner.
    @param _lmpooladdr : lm pool contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setLmPoolAddress(address _lmpooladdr) external onlyOwner {
        require(_lmpooladdr != address(0), "Zero Address");
        lmpooladdr = _lmpooladdr;
    }

    /**
    @notice Set DAO address. Can only be called by the owner.
    @param _daoAddress : DAO contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setDaoAddress(address _daoAddress) external onlyOwner {
        require(_daoAddress != address(0), "Zero Address");
        daoAddress = _daoAddress;
    }

    /**
    @notice Set timelock address. Can only be called by the owner.
    @param _timeLock : timelock contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setTimeLockAddress(address _timeLock) external onlyOwner {
        require(_timeLock != address(0), "Zero Address");
        timelock = _timeLock;
    }

    /**
    @notice Set Daa address. Can only be called by the owner.
    @param _address : Daa contract address
    @dev    this function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function setDaaAddress(address _address) external {
        require(_address != address(0), "Zero Address");
        require(
            msg.sender == owner() || msg.sender == address(timelock),
            "Can only be called by the owner/timelock"
        );
        require(daaAddress != _address, "Already updated");
        daaAddress = _address;
    }

    /**
    @notice Return reward multiplier over the given _from to _to block.
    @param _from : from block number
    @param _to : to block number
    @dev Description :
    This function is just used for getting the diffrence betweem start and end block for block reward calculation.
    This function definition is marked "public" because this fuction is called from outside and inside the contract.
    */
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    /**
    @notice Reward Multiplier from staked amount
    @param _pid : LM pool id
    @param _user : user account address
    @dev Description :
    Depending on users’ staking scores and whether they’ve decided to move Astra tokens to one of the
    lockups vaults, users will get up to 2.5x higher rewards and voting power
    */
    function getRewardMultiplier(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        //Lockup period
        //12months  Threshold/requirement  Staking/LM rewaryds multiplication xx1.8
        //9months   Threshold/requirement  Staking/LM rewards multiplication  x1.3
        //6months   Threshold/requirement  Staking/LM rewards multiplication  x1.2
        uint256 lockupMultiplier = vaultMultiplier(_pid, _user);

        //staking score threshold
        //800k  Threshold/requirement  Staking/LM rewards multiplication  xx1.7
        //300k  Threshold/requirement  Staking/LM rewards multiplication  x1.3
        //100k  Threshold/requirement  Staking/LM rewards multiplication  x1.2
        uint256 stakingscoreMultiplier = 10;
        uint256 stakingscoreval = stakingScore(_pid, _user);
        // Multiplied the value with 10**18 becuase eth network accept the values with 10**18. otherwise below value will
        // be counted after dividing by 10**18.
        uint256 eightk = 800000 * 10**18;
        uint256 threek = 300000 * 10**18;
        uint256 onek = 100000 * 10**18;

        if (stakingscoreval >= eightk) {
            stakingscoreMultiplier = 17;
        } else if (stakingscoreval >= threek) {
            stakingscoreMultiplier = 13;
        } else if (stakingscoreval >= onek) {
            stakingscoreMultiplier = 12;
        }
        // for calculating reward multiplier we need to add staking multiplier and lockupmultiplier
        // and then substract it by 10
        // RM = RM1 + RM2
        return stakingscoreMultiplier.add(lockupMultiplier).sub(10);
    }

    /**
    @notice Calculating the average vault multiplier for multiple vault staking.
    @param _pid : pool id
    @param _user : user address
    @dev Description :
    Here the logic is added to calculate the average vaultMultiplier if user stakes the amount with multiple lockup vaults
    As staking details managed in StakeInfo struct. So from there vault month gets fatched and then the average is calculated
    for all vault period. Let's take an example
    If user has staked the amount in two vaults like 6 and 9 months then vault multiplier would be 11 and 13(it would be
    divided by 10 when we use it) and then the avarage gets calculated as below
    averageVaultMul = (VM1 + VM2)/2 = (11 + 13)/2 = 12, So it would be 1.2 after dividing by 10.
    This function definition is marked "public" because this fuction is called from outside and inside the contract.
    */
    function vaultMultiplier(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        // final vaultMultiplier value
        uint256 vaultMul;
        // count of the user staking record in which deposit true
        uint256 depositCount;
        uint256 countofstake = userStakingTrack[_pid][_user];
        // Applied the loop for getting the vault value from stake info object and the add it and then
        // divide it with depositCount.
        for (uint256 i = 1; i <= countofstake; i++) {
            StakeInfo memory stkInfo = stakeInfo[_pid][_user][i];
            if (stkInfo.deposit == true) {
                depositCount++;
                if (stkInfo.vault == 12) {
                    vaultMul = vaultMul.add(18);
                } else if (stkInfo.vault == 9) {
                    vaultMul = vaultMul.add(13);
                } else if (stkInfo.vault == 6) {
                    vaultMul = vaultMul.add(11);
                } else {
                    vaultMul = vaultMul.add(10);
                }
            }
        }
        // If deposit count is more than zero then it returns average otherwise it returns 10 means 1.
        if (depositCount > 0) {
            return vaultMul.div(depositCount);
        } else {
            return 10;
        }
    }

    /**
    @notice This function is used to get premium payout bonus percentage.
    @param _pid : pool id
    @param _user : user account address
    @dev Description :
    The basic logic for calculating the premium payout bonus percentage is totally on the basis of user staking score. It 
    will vary as the user staking score gets increased. Here 10 multiplier is used beacause solidity does not supports
    float value. It will be divided by 10 wherever it will be used
    */
    function getPremiumPayoutBonus(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        // staking score threshold
        uint256 stakingscoreaddition;
        uint256 stakingscorevalue = stakingScore(_pid, _user);
        // Multiplied the value with 10**18 becuase eth network accept the values with 10**18. otherwise below value will
        // be counted after dividing by 10**18.
        uint256 eightk = 800000 * 10**18;
        uint256 threek = 300000 * 10**18;
        uint256 onek = 100000 * 10**18;

        // Here premium payout bonus percentage is calculated on the basis of staking score
        // If staking score is greater than and equal to 800k the premium payout bonus percentage will be 2.
        // If staking score is greater than and equal to 800k the premium payout bonus percentage will be 1.
        // If staking score is greater than and equal to 800k the premium payout bonus percentage will be 0.5.
        if (stakingscorevalue >= eightk) {
            stakingscoreaddition = 20;
        } else if (stakingscorevalue >= threek) {
            stakingscoreaddition = 10;
        } else if (stakingscorevalue >= onek) {
            stakingscoreaddition = 5;
        }
        return stakingscoreaddition;
    }

    /**
    @notice Deposit/Stake iTokens and astra token to MasterChef.
    @param _pid : pool id
    @param _amount : amount to be deposited
    @param vault : vault months
    @dev Description :
    Deposit/Stake the amount by user. On chef contract user can stake iToken and astra token for getting the ASTRA rewards.
    This function definition is marked "external" because this fuction is called only from outside the contract.
    */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        uint256 vault
    ) external nonReentrant{
        require(vaultList[vault] == true, "no vault");
        PoolInfo storage pool = poolInfo[_pid];
        // This function is called for updating the total reward value which user is getting through block rewards
        updateBlockReward(_pid, msg.sender);
        UserInfo storage user = userInfo[_pid][msg.sender];
        // This function is called to keep record of who is staking the tokens on the chef contract with pool id.
        addUserAddress(msg.sender, _pid);
        if (_amount > 0) {
            // Here if entered amount is greater than 0 then that amount would be transferred from user account to
            // chef contract
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        // Updating staking score structure after staking the tokens
        userStakingTrack[_pid][msg.sender] = userStakingTrack[_pid][msg.sender]
            .add(1);
        // Set the id of user staking info.
        uint256 userstakeid = userStakingTrack[_pid][msg.sender];
        // Fetch the stakeInfo which saved on stake id.
        StakeInfo storage staker = stakeInfo[_pid][msg.sender][userstakeid];
        // Here sets the below values in the object.
        staker.amount = _amount;
        staker.totalAmount = user.amount;
        staker.timestamp = block.timestamp;
        staker.vault = vault;
        staker.deposit = true;

        //user timestamp
        user.timestamp = block.timestamp;
        // update hishest staker array
        addHighestStakedUser(_pid, user.amount, msg.sender);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
    @notice Deposit iTokens to MasterChef from DAA contract for ASTR allocation.
    @param _pid : pool id
    @param _amount : amount to be deposited
    @param vault : vault months
    @param _sender : spender address
    @param isPremium : premium option choice
    @dev Description : deposit/stake the amount by user from DAA contract. this function definition is marked 
         "external" because this fuction is called only from outside the contract.
    */
    function depositFromDaaAndDAO(
        uint256 _pid,
        uint256 _amount,
        uint256 vault,
        address _sender,
        bool isPremium
    ) external onlyDaaOrDAO nonReentrant{
        require(vaultList[vault] == true, "no vault");
        PoolInfo storage pool = poolInfo[_pid];
        updateBlockReward(_pid, _sender);
        UserInfo storage user = userInfo[_pid][_sender];
        addUserAddress(_sender, _pid);
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            uint256 bonusAmount =
                getBonusAmount(_pid, _sender, _amount, isPremium);
            _amount = _amount.add(bonusAmount);            
            user.amount = user.amount.add(_amount);
        }
        //deposit staking score structure update
        userStakingTrack[_pid][_sender] = userStakingTrack[_pid][_sender].add(
            1
        );
        // Set the id of user staking info.
        uint256 userstakeid = userStakingTrack[_pid][_sender];
        // Fetch the stakeInfo which saved on stake id.
        StakeInfo storage staker = stakeInfo[_pid][_sender][userstakeid];
        // Here sets the below values in the object.
        staker.amount = _amount;
        staker.totalAmount = user.amount;
        staker.timestamp = block.timestamp;
        staker.vault = vault;
        staker.deposit = true;

        //user timestamp
        user.timestamp = block.timestamp;
        // update hishest staker array
        addHighestStakedUser(_pid, user.amount, _sender);
        emit Deposit(_sender, _pid, _amount);
    }

    /**
    @notice Getting the premium pay ou bonus amount.
    @param _pid : pool id
    @param _user : spender address
    @param _amount : amount to be deposited
    @param isPremium : premium option choice
    @dev Description : Calculate the premium bonus amount which needs to be paid to user who are premium users.
         This function definition is marked "private" because this fuction is called only from inside the contract.
    */
    function getBonusAmount(
        uint256 _pid,
        address _user,
        uint256 _amount,
        bool isPremium
    ) private view returns (uint256) {
        uint256 ppb;
        if (isPremium) {
            ppb = getPremiumPayoutBonus(_pid, _user).add(20);
        } else {
            ppb = getPremiumPayoutBonus(_pid, _user);
        }
        uint256 bonusAmount = _amount.mul(ppb).div(1000);
        return bonusAmount;
    }

    /**
    @notice Withdraw the staked/deposited amount from the pool.
    @param _pid : pool id
    @param _withStake : withdraw the amount with or without stake.
    @dev Description :
    Withdraw the staked/deposited amount and astra reward from chef contract. This function definition is marked"external"
    because this fuction is called only from outside the contract.
    */
    function withdraw(uint256 _pid, bool _withStake) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = viewEligibleAmount(_pid, msg.sender);
        require(_amount > 0, "withdraw: not good");
        //Instead of transferring to a standard staking vault, Astra tokens can be locked (meaning that staker forfeits the right to unstake them for a fixed period of time). There are following lockups vaults: 6,9 and 12 months.
        if (user.cooldown == false) {
            user.cooldown = true;
            user.cooldowntimestamp = block.timestamp;
            return;
        } else {
            // Stakers willing to withdraw tokens from the staking pool will need to go through 7 days
            // of cool-down period. After 7 days, if the user fails to confirm the unstake transaction in the 24h time window, the cooldown period will be reset.
            if (
                block.timestamp > user.cooldowntimestamp.add(dayseconds.mul(8))
            ) {
                user.cooldown = true;
                user.cooldowntimestamp = block.timestamp;
                return;
            } else {
                require(user.cooldown == true, "withdraw: cooldown status");
                require(
                    block.timestamp >=
                        user.cooldowntimestamp.add(dayseconds.mul(7)),
                    "withdraw: cooldown period"
                );
                require(
                    block.timestamp <=
                        user.cooldowntimestamp.add(dayseconds.mul(8)),
                    "withdraw: open window"
                );
                // Calling withdraw function after all the validation like cooldown period, eligible amount etc.
                _withdraw(_pid, _withStake);
            }
        }
    }

    /**
    @notice Withdraw the staked/deposited amount from the pool.
    @param _pid : pool id
    @param _withStake : withdraw the amount with or without stake.
    @dev Description :
    Withdraw the staked/deposited amount and astra reward. This function definition is marked "private" because
    this fuction is called only from inside the contract.
    */
    function _withdraw(uint256 _pid, bool _withStake) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // Calling withdrawASTRReward for claiming the ASTRA reward with or without staking it.
        withdrawASTRReward(_pid, _withStake);
        // Calling the function to check the eligible amount and update accordingly
        uint256 _amount = checkEligibleAmount(_pid, msg.sender, true);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accASTRPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        //update user cooldown status
        user.cooldown = false;
        user.cooldowntimestamp = 0;
        user.totalUserBaseMul = 0;
        // update hishest staker array
        removeHighestStakedUser(_pid, user.amount, msg.sender);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
    @notice View the eligible amount which is able to withdraw.
    @param _pid : pool id
    @param _user : user address
    @dev Description :
    View the eligible amount which needs to be withdrawn if user deposits amount in multiple vaults. This function
    definition is marked "public" because this fuction is called from outside and inside the contract.
    */
    function viewEligibleAmount(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        uint256 eligibleAmount = 0;
        // Getting count of stake which is managed at the time of deposit
        uint256 countofstake = userStakingTrack[_pid][_user];
        // This loop is applied for calculating the eligible withdrawn amount. This will fetch the user StakeInfo and calculate
        // the eligible amount which needs to be withdrawn
        for (uint256 i = 1; i <= countofstake; i++) {
            // Single stake info by stake id.
            StakeInfo storage stkInfo = stakeInfo[_pid][_user][i];
            // Checking the deposit variable is true
            if (stkInfo.deposit == true) {
                uint256 mintsec = 86400;
                uint256 vaultdays = stkInfo.vault.mul(30);
                uint256 timeaftervaultmonth =
                    stkInfo.timestamp.add(vaultdays.mul(mintsec));
                // Checking if the duration of vault month is passed.
                if (block.timestamp >= timeaftervaultmonth) {
                    eligibleAmount = eligibleAmount.add(stkInfo.amount);
                }
            }
        }
        return eligibleAmount;
    }

    /**
    @notice Check the eligible amount which is able to withdraw.
    @param _pid : pool id
    @param _user : user address
    @param _withUpdate : with update
    @dev Description :
    This function is like viewEligibleAmount just here we update the state of stakeInfo object. This function definition
    is marked "private" because this fuction is called only from inside the contract.
    */
    function checkEligibleAmount(
        uint256 _pid,
        address _user,
        bool _withUpdate
    ) private returns (uint256) {
        uint256 eligibleAmount = 0;
        // Getting count of stake which is managed at the time of deposit
        uint256 countofstake = userStakingTrack[_pid][_user];
        // This loop is applied for calculating the eligible withdrawn amount. This will fetch the user StakeInfo and
        // calculate the eligible amount which needs to be withdrawn and StakeInfo is getting updated in this function.
        // Means if amount is eligible then false value needs to be set in deposit varible.
        for (uint256 i = 1; i <= countofstake; i++) {
            // Single stake info by stake id.
            StakeInfo storage stkInfo = stakeInfo[_pid][_user][i];
            // Checking the deposit variable is true
            if (stkInfo.deposit == true) {
                uint256 mintsec = 86400;
                uint256 vaultdays = stkInfo.vault.mul(30);
                uint256 timeaftervaultmonth =
                    stkInfo.timestamp.add(vaultdays.mul(mintsec));
                // Checking if the duration of vault month is passed.
                if (block.timestamp >= timeaftervaultmonth) {
                    eligibleAmount = eligibleAmount.add(stkInfo.amount);
                    if (_withUpdate) {
                        stkInfo.deposit = false;
                    }
                }
            }
        }
        return eligibleAmount;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        user.amount = 0;
        user.totalReward = 0;
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    /**
    @notice Withdraw ASTR Tokens from MasterChef address.
    @param recipient : recipient address
    @param amount : amount
    @dev Description :
    Withdraw ASTR Tokens from MasterChef address. This function definition is marked "external" because this fuction
    is called only from outside the contract.
    */
    function emergencyWithdrawASTR(address recipient, uint256 amount)
        external
        onlyOwner
    {
        require(
            amount > 0 && recipient != address(0),
            "amount and recipient address can not be 0"
        );
        safeASTRTransfer(recipient, amount);
    }

    /**
    @notice Safe ASTR transfer function, just in case if rounding error causes pool to not have enough ASTRs.
    @param _to : recipient address
    @param _amount : amount
    @dev Description :
    Transfer ASTR Tokens from MasterChef address to the recipient. This function definition is marked "internal"
    because this fuction is called only from inside the contract.
    */
    function safeASTRTransfer(address _to, uint256 _amount) internal {
        uint256 ASTRBal = IERC20(ASTR).balanceOf(address(this));
        require(!(_amount > ASTRBal), "Insufficient amount on chef contract");
        IERC20(ASTR).safeTransfer(_to, _amount);
    }

    /**
    @notice Update dev address by the previous dev.
    @param _devaddr : dev address
    @dev Description :
    Update dev address by the previous dev. This function definition is marked "external" because this fuction is
    called only from outside the contract.
    */
    function dev(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    /**
    @notice staking score from staked amount
    @param _pid :  pool id
    @param _userAddress : user account address
    @dev Description :
    The staking score is calculated using average holdings over the last 60 days.
    The idea of staking score is to recognise the value of a long term holding even if held assets are small. This is illustrated by below example:
    Holder who stakes 1000 tokens for the last 60 days has an average staking score of 1000
    Holder who stakes 60 000 tokens for 1 day, also has average staking score of 1000
    */
    function stakingScore(uint256 _pid, address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 timeofstakes;
        uint256 amountstaked;
        uint256 daysecondss = 86400;
        uint256 daysOfStakingscore = 60;
        UserInfo storage user = userInfo[_pid][_userAddress];
        uint256 countofstake = userStakingTrack[_pid][_userAddress];
        uint256 stakingscorenett = 0;
        uint256 userStakingScores = 0;

        for (uint256 i = 1; i <= countofstake; i++) {
            // Fetching stake info
            StakeInfo memory stkInfo = stakeInfo[_pid][_userAddress][i];
            if (stkInfo.deposit == true) {
                // timestamp when user deposited/staked the amount
                timeofstakes = stkInfo.timestamp;
                // amount is staked by the user.
                amountstaked = stkInfo.amount;
                //get staking vault
                uint256 vaultMonth = stkInfo.vault;
                // Calling this function for calculating the staking score for each deposit
                stakingscorenett = calcstakingscore(
                    timeofstakes,
                    vaultMonth,
                    amountstaked,
                    stakingscorenett,
                    daysOfStakingscore,
                    daysecondss
                );
                // Once we got the staking score single deposit then we add those into a one varible and get the total 
                // staking score of a user.
                userStakingScores = userStakingScores.add(stakingscorenett);
                if (userStakingScores > user.amount) {
                    userStakingScores = user.amount;
                }
            } else {
                userStakingScores = 0;
            }
        }
        return userStakingScores;
    }

    /**
    @notice Staking score calculation
    @param timeofstakes : time of stake
    @param vaultMonth : vault of month
    @param amountstaked : Amount month
    @param stakingscorenett : vault of month
    @param daysOfStakingscore : days Of Stakingscore
    @param daysecondss : day seconds
    @dev Description :The staking score formaula calculation
    */
    function calcstakingscore(
        uint256 timeofstakes,
        uint256 vaultMonth,
        uint256 amountstaked,
        uint256 stakingscorenett,
        uint256 daysOfStakingscore,
        uint256 daysecondss
    ) internal view returns (uint256) {
        uint256 stakeIndays = 0;
        uint256 month = 12;
        // daysOfStakingscore / month (60 / 12) = 5
        uint256 daysByMonthConstant = daysOfStakingscore.div(month);
        uint256 diffInTimestamp = block.timestamp.sub(timeofstakes);
        if (diffInTimestamp > daysecondss) {
            stakeIndays = diffInTimestamp.div(daysecondss);
        } else {
            stakeIndays = 0;
        }

        // This means that if user exceeds the 60 day time period user staking score will remain the same
        if (stakeIndays > 60) {
            stakeIndays = 60;
        }

        //staking score calculation
        if (vaultMonth == 12) {
            if (stakeIndays == 0) {
                amountstaked = 0;
            }
            stakingscorenett = amountstaked;
        } else {
            // on 0 vault not required calcation to get staking days
            if (vaultMonth != 0) {
                daysOfStakingscore = daysOfStakingscore.sub(
                    daysByMonthConstant.mul(vaultMonth)
                );
            }
            stakingscorenett = amountstaked.mul(stakeIndays).div(
                daysOfStakingscore
            );
        }
        return stakingscorenett;
    }

    /**
    @notice Manage the all user address wrt to chef contract pool.
    @param _pid : pool id
    @dev Description :
    Manage the all user address wrt to chef contract pool. Its store all the user address in a map where key is
    pool id and value is array of user address. It is basically used for calculating the every user reward share.
    */
    function addUserAddress(address _user, uint256 _pid) private {
        address[] storage adds = userAddressesInPool[_pid];
        if (userStakingTrack[_pid][_user] == 0) {
            adds.push(_user);
        }
    }

    /**
    @notice Distribute Individual, Flat and TVL adjusted reward
    @param _pid : pool id
    @param _type : reward type 
    @param _amount : amount which needs to be distributed
    @dev Requirements:
        Reward type should not except 0, 1, 2.
        0 - INDIVIDUAL Reward
        1 - FLAT Reward
        2 - TVL ADJUSTED Reward
    */
    function distributeReward(
        uint256 _pid,
        RewardType _type,
        uint256 _amount
    ) external onlyOwner {
        if (_type == RewardType.INDIVIDUAL) {
            distributeIndividualReward(_pid, _amount);
        } else if (_type == RewardType.FLAT) {
            distributeFlatReward(_amount);
        } else if (_type == RewardType.TVL_ADJUSTED) {
            distributeTvlAdjustedReward(_amount);
        }
    }

    /**
    @notice Distribute Individual reward to user
    @param _pid : pool id
    @param _amount : amount which needs to be distributed
    @dev Description :
    In individual reward, all base value is calculated in a single iToken pool and calculate the share for every user by
    dividing pool base multiplier with user base mulitiplier.
    UBM1 = stakedAmount * rewardMultiplier.
    PBM = UBM1+UBM2
    share % for single S1 = UBM1*100/PBM
    reward amount = S1*amount/100
    */
    function distributeIndividualReward(uint256 _pid, uint256 _amount) private {
        uint256 poolBaseMul = 0;
        address[] memory adds = userAddressesInPool[_pid];
        // Applied this loop for updating the user base multiplier for each user and adding all base multiplier for a
        // single pool and updating the poolBaseMul local variable.
        // User base multiplier  = stakedAmount * rewardMultiplier.
        // poolBaseMultiplier = sum of all user base multiplier in the same pool.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            uint256 mul = getRewardMultiplier(ASTRPoolId, adds[i]);
            user.totalUserBaseMul = user.amount.mul(mul);
            poolBaseMul = poolBaseMul.add(user.totalUserBaseMul);
        }
        // Applied this loop for calculating the reward share percentage for each user and update the totalReward variable
        // with actual distributed reward.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            uint256 sharePercentage =
                user.totalUserBaseMul.mul(10000).div(poolBaseMul);
            user.totalReward = user.totalReward.add(
                (_amount.mul(sharePercentage)).div(10000)
            );
        }
    }

    /**
    @notice Distribute Flat reward to user
    @param _amount : amount which needs to be distributed
    @dev Description :
    In Flat reward distribution, here base value is calculated for all pools and calculate the share for each user from
    each pool.
    allPBM = UBM1+UBM2
    share % for single S1 = UBM1*100/allPBM
    reward amount = S1*amount/100
    */
    function distributeFlatReward(uint256 _amount) private {
        uint256 allPoolBaseMul = 0;
        // Applied the loop on all pool array for getting the all users address list.
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            address[] memory adds = userAddressesInPool[pid];
            // Applied this loop to update user base multiplier and and add all pool base multiplier by adding all user
            // base multiplier and updating that allPoolBaseMul variable.
            for (uint256 i = 0; i < adds.length; i++) {
                UserInfo storage user = userInfo[pid][adds[i]];
                uint256 mul = getRewardMultiplier(ASTRPoolId, adds[i]);
                user.totalUserBaseMul = user.amount.mul(mul);
                allPoolBaseMul = allPoolBaseMul.add(user.totalUserBaseMul);
            }
        }

        // Applied the loop on all pool array for getting the all users address list.
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            address[] memory adds = userAddressesInPool[pid];
            // Applied this loop for calculating the reward share percentage for each user and update the totalReward
            // variable with actual distributed reward.
            for (uint256 i = 0; i < adds.length; i++) {
                UserInfo storage user = userInfo[pid][adds[i]];
                uint256 sharePercentage =
                    user.totalUserBaseMul.mul(10000).div(allPoolBaseMul);
                user.totalReward = user.totalReward.add(
                    (_amount.mul(sharePercentage)).div(10000)
                );
            }
        }
    }

    /**
    @notice Distribute TVL adjusted reward to user
    @param _amount : amount which needs to be distributed
    @dev Description :
        In TVL reward, First it needs to calculate the reward share for each on the basis of 
        total value locked of each pool.
        totTvl = TVL1+TVL2
        reward share = TVL1*100/totTvl
        user reward will happen like individual reward after calculating the reward share.
    */
    function distributeTvlAdjustedReward(uint256 _amount) private {
        uint256 totalTvl = 0;
        // Applied the loop for calculating the TVL(total value locked) and updating that in totalTvl variable.
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 tvl = pool.lpToken.balanceOf(address(this));
            totalTvl = totalTvl.add(tvl);
        }
        // Applied the loop for calculating the reward share for each pool and the distribute the share with all users.
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            uint256 tvl = pool.lpToken.balanceOf(address(this));
            uint256 poolRewardShare = tvl.mul(10000).div(totalTvl);
            uint256 reward = (_amount.mul(poolRewardShare)).div(10000);
            // After getting the pool reward share then it will same as individual reward.
            distributeIndividualReward(pid, reward);
        }
    }

    /**
    @notice store Highest 100 staked users
    @param _pid : pool id
    @param _amount : amount
    @dev Description :
    During the first 60 days after Astra network goes live date, DAO governance will be performed by the
    top 100 wallets with the highest amount of staked Astra tokens. After the first 90 days, DAO governors
    will be based on the staking score, without any limitations.
    */
    function addHighestStakedUser(
        uint256 _pid,
        uint256 _amount,
        address user
    ) private {
        uint256 i;
        // Getting the array of Highest staker as per pool id.
        HighestAstaStaker[] storage higheststaker = highestStakerInPool[_pid];
        //for loop to check if the staking address exist in array
        for (i = 0; i < higheststaker.length; i++) {
            if (higheststaker[i].addr == user) {
                higheststaker[i].deposited = _amount;
                // Called the function for sorting the array in ascending order.
                quickSort(_pid, 0, higheststaker.length - 1);
                return;
            }
        }

        if (higheststaker.length < 100) {
            // Here if length of highest staker is less than 100 than we just push the object into array.
            higheststaker.push(HighestAstaStaker(_amount, user));
        } else {
            // Otherwise we check the last staker amount in the array with new one.
            if (higheststaker[0].deposited < _amount) {
                // If the last staker deposited amount is less than new then we put the greater one in the array.
                higheststaker[0].deposited = _amount;
                higheststaker[0].addr = user;
            }
        }
        // Called the function for sorting the array in ascending order.
        quickSort(_pid, 0, higheststaker.length - 1);
    }

    /**
    @notice Astra staking track the Highest 100 staked users
    @param _pid : pool id
    @param user : user address
    @dev Description :
    During the first 60 days after Astra network goes live date, DAO governance will be performed by the
    top 100 wallets with the highest amount of staked Astra tokens. 
    */
    function checkHighestStaker(uint256 _pid, address user)
        external
        view
        returns (bool)
    {
        HighestAstaStaker[] storage higheststaker = highestStakerInPool[_pid];
        uint256 i = 0;
        // Applied the loop to check the user in the highest staker list.
        for (i; i < higheststaker.length; i++) {
            if (higheststaker[i].addr == user) {
                // If user is exists in the list then we return true otherwise false.
                return true;
            }
        }
    }

    /**
    @notice check Staking Score For Delegation
    @param _pid : pool id
    @param user : user
    @dev Description :After the first 90 days, DAO governors
      will be based on the staking score.
    */
    function checkStakingScoreForDelegation(uint256 _pid, address user)
        external
        view
        returns (bool)
    {
        uint256 sscore = stakingScore(_pid, user);
        uint256 onek = 100000 * 10**18;
        //Any ecosystem member with a staking score higher than [X] can submit a voting proposal.
        //On doc there not staking score value fixed yet for now taking One hundred K Token
        if (sscore == onek) {
            return true;
        } else {
            return false;
        }
    }

    /**
    @notice Update the block reward for a single user, all have the access for this function.
    @param _pid : pool id
    @dev Description :
        It calculates the total block reward with defined astr per block and the distribution will be
        calculated with current user reward multiplier, total user mulplier and total pool multiplier.
        PBM = UBM1+UBM2
        share % for single S1 = UBM1*100/PBM
        reward amount = S1*amount/100
    */
    function updateBlockReward(uint256 _pid, address _sender) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // PoolEndBlock is nothing just contains the value of end block.
        uint256 PoolEndBlock = block.number;
        if (block.number > bonusEndBlock) {
            // If current block number is greater than bonusEndBlock than PoolEndBlock will have the bonusEndBlock value.
            // otherwise it will have current block number value.
            PoolEndBlock = bonusEndBlock;
        }
        // Here we are checking the balance of chef contract in behalf of itokens/astra token.
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            // If it is 0 the we just update the last Reward block value in pool and return without doing anything.
            pool.lastRewardBlock = PoolEndBlock;
            return;
        }
        // multiplier would be the diffirence between last reward block and end block.
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, PoolEndBlock);
        // block reward would be multiplication of multiplier and astra per block value.
        uint256 blockReward = multiplier.mul(ASTRPerBlock);
        UserInfo storage currentUser = userInfo[_pid][_sender];
        uint256 totalPoolBaseMul = 0;
        // Getting the user list of pool.
        address[] memory adds = userAddressesInPool[_pid];
        // Applied the for upadating the pool base multiplier and get the reward mulplier for each user.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            if (user.amount > 0) {
                uint256 mul = getRewardMultiplier(ASTRPoolId, adds[i]);
                if (_sender != adds[i]) {
                    user.preBlockReward = user.preBlockReward.add(blockReward);
                }
                totalPoolBaseMul = totalPoolBaseMul.add(user.amount.mul(mul));
            }
        }
        // Called the fuction to update the total raward with shared block reward for the current user.
        updateCurBlockReward(
            currentUser,
            blockReward,
            totalPoolBaseMul,
            _sender
        );
        pool.lastRewardBlock = PoolEndBlock;
    }

    /**
    @notice Update the current block reward for a single user.
    @param currentUser : current user info obj
    @param blockReward : block reward
    @param totalPoolBaseMul : total base multiplier
    @param _sender : sender address
    @dev Description :
        It calculates the total block reward with defined astr per block and the distribution will be
        calculated with current user reward multiplier, total user mulplier and total pool multiplier.
        PBM = UBM1+UBM2
        share % for single S1 = UBM1*100/PBM
        reward amount = S1*amount/100
        This function definition is marked "private" because this fuction is called only from inside the contract.

    */
    function updateCurBlockReward(
        UserInfo storage currentUser,
        uint256 blockReward,
        uint256 totalPoolBaseMul,
        address _sender
    ) private {
        uint256 userBaseMul =
            currentUser.amount.mul(getRewardMultiplier(ASTRPoolId, _sender));
        uint256 totalBlockReward = blockReward.add(currentUser.preBlockReward);
        // Calculating the shared percentage for reward.
        uint256 sharePercentage = userBaseMul.mul(10000).div(totalPoolBaseMul);
        currentUser.totalReward = currentUser.totalReward.add(
            (totalBlockReward.mul(sharePercentage).div(totalPoolBaseMul)).div(10000)
        );
        currentUser.preBlockReward = 0;
    }

    /**
    @notice View the total user reward in the particular pool.
    @param _pid : pool id
    */
    function viewRewardInfo(uint256 _pid) external view returns (uint256) {
        UserInfo memory currentUser = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        uint256 totalReward = currentUser.totalReward;
        // Here we are checking the balance of chef contract in behalf of itokens/astra token.
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            // If it is 0 the we just update the last Reward block value in pool and return total reward of user.
            pool.lastRewardBlock = block.number;
            return totalReward;
        }

        if (block.number <= pool.lastRewardBlock) {
            return totalReward;
        }

        // PoolEndBlock is nothing just contains the value of end block.
        uint256 PoolEndBlock = block.number;
        if (block.number > bonusEndBlock) {
            // If current block number is greater than bonusEndBlock than PoolEndBlock will have the bonusEndBlock value.
            // otherwise it will have current block number value.
            PoolEndBlock = bonusEndBlock;
        }
        // multiplier would be the diffirence between last reward block and end block.
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, PoolEndBlock);
        // block reward would be multiplication of multiplier and astra per block value.
        uint256 blockReward = multiplier.mul(ASTRPerBlock);

        uint256 totalPoolBaseMul = 0;
        // Getting the user list of pool.
        address[] memory adds = userAddressesInPool[_pid];
        // Applied the loop for updating  totalPoolBaseMul and get the reward mulplier for each user.
        for (uint256 i = 0; i < adds.length; i++) {
            UserInfo storage user = userInfo[_pid][adds[i]];
            uint256 mul = getRewardMultiplier(ASTRPoolId, adds[i]);
            totalPoolBaseMul = totalPoolBaseMul.add(user.amount.mul(mul));
        }
        uint256 userBaseMul =
            currentUser.amount.mul(getRewardMultiplier(ASTRPoolId, msg.sender));
        uint256 totalBlockReward = blockReward.add(currentUser.preBlockReward);
        // Calculting the share percentage for the currenct user.
        uint256 sharePercentage = userBaseMul.mul(10000).div(totalPoolBaseMul);
        return
            currentUser.totalReward.add(
                (totalBlockReward.mul(sharePercentage)).div(10000)
            );
    }

    /**
    @notice Distributing the exit fee share
    @param _amount : amount ro be distributed
    @dev Description :
        It is used for ditributing exit fee share and it called from DAA contract. This function definition is marked
        "external" because this fuction is called only from outside the contract.
    */
    function distributeExitFeeShare(uint256 _amount) external {
        require(_amount > 0, "Amount should not be zero");
        distributeIndividualReward(ASTRPoolId, _amount);
    }

    /**
    @notice Sorting the highes astra staker in pool
    @param _pid : pool id
    @param left : left
    @param right : right
    @dev Description :
        It is used for sorting the highes astra staker in pool. This function definition is marked
        "internal" because this fuction is called only from inside the contract.
    */
    function quickSort(
        uint256 _pid,
        uint256 left,
        uint256 right
    ) internal {
        HighestAstaStaker[] storage arr = highestStakerInPool[_pid];
        if (left >= right) return;
        uint256 divtwo = 2;
        uint256 p = arr[(left + right) / divtwo].deposited; // p = the pivot element
        uint256 i = left;
        uint256 j = right;
        while (i < j) {
            // HighestAstaStaker memory a;
            // HighestAstaStaker memory b;
            while (arr[i].deposited < p) ++i;
            while (arr[j].deposited > p) --j; // arr[j] > p means p still to the left, so j > 0
            if (arr[i].deposited > arr[j].deposited) {
                (arr[i].deposited, arr[j].deposited) = (
                    arr[j].deposited,
                    arr[i].deposited
                );
                (arr[i].addr, arr[j].addr) = (arr[j].addr, arr[i].addr);
            } else ++i;
        }
        // Note --j was only done when a[j] > p.  So we know: a[j] == p, a[<j] <= p, a[>j] > p
        if (j > left) quickSort(_pid, left, j - 1); // j > left, so j > 0
        quickSort(_pid, j + 1, right);
    }

    /**
    @notice Remove highest staker from the staker array
    @param _pid : pool id
    @param user : user address
    @dev Description :
    This function is basically called from the withdraw function and update the highest staker list. It is used to remove
    highest staker from the staker array. This function definition is marked "private" because this fuction is called only
    from inside the contract.
    */
    function removeHighestStakedUser(uint256 _pid, uint256 _amount, address user) private {
        // Getting Highest staker list as per the pool id
        HighestAstaStaker[] storage highestStaker = highestStakerInPool[_pid];
        // Applied this loop is just to find the staker
        for (uint256 i = 0; i < highestStaker.length; i++) {
            if (highestStaker[i].addr == user) {
                // Deleting the staker from the array.
                delete highestStaker[i];
                if(_amount > 0) {
                    // If amount is greater than 0 than we need to add this again in the hisghest staker list.
                    addHighestStakedUser(_pid, _amount, user);
                }
                return;
            }
        }
    }

    /**
    @notice voting power calculation
    @param _pid : pool id
    @param _user : user address
    @dev Description :
        Voting power is expressed in voting points (VP). One voting point is equivalent to one staking score
        point. Staking score multipliers apply to voting power.. 
    */
    function votingPower(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        //User get x1.3 from the start for locking funds  on 6 month lockup vault.
        //with pool id and user address call the staking score
        uint256 stakingsScore = stakingScore(_pid, _user);

        //User unlocks additional x1.2 for staking score higher or equal than 100k.
        // Accumulated mulitpliers are now x1.5 (1 + 0.3 + 0.2)
        //User unlocks higher bonus  for staking score higher or equal than 300k.
        //Accumulated mulitpliers are now x1.6 (1 + 0.3 + 0.3)
        uint256 rewardMult = getRewardMultiplier(_pid, _user);
        uint256 votingpower = (stakingsScore.mul(rewardMult)).div(10);
        return votingpower;
    }

    /**
    @notice Claim ASTR reward by user
    @param _pid : pool id
    @param _withStake : with or without stake
    @dev Description :
        Here User can claim the claimable ASTR reward. There is two option for claiming the reward with
        or without staking the ASTR token. If user wants to claim 100% then he needs to stake the ASTR
        to ASTR pool. Otherwise some ASTR amount would be deducted as a fee.
    */
    function withdrawASTRReward(uint256 _pid, bool _withStake) public nonReentrant{
        // bool isValid = Dao(daoAddress).getVotingStatus(msg.sender);
        // require(isValid==true, "should vote active proposal");

        // Update the block reward for the current user.
        updateBlockReward(_pid, msg.sender);
        UserInfo storage currentUser = userInfo[_pid][msg.sender];
        if (_withStake) {
            // If user choses to withdraw the ASTRA with staking it in to astra.
            uint256 _amount = currentUser.totalReward;
            // Called this function for staking the ASTRA rewards in astra pool.
            _stakeASTRReward(msg.sender, ASTRPoolId, _amount);
            updateClaimedReward(currentUser, _amount);
        } else {
            // Else we will slash some fee and send the amount to user account.
            uint256 dayInSecond = 86400;
            uint256 dayCount =
                (block.timestamp.sub(currentUser.timestamp)).div(dayInSecond);
            if (dayCount >= 90) {
                dayCount = 90;
            }
            // Called this function for slashing fee from reward if claim is happend with in 90 days.
            slashExitFee(currentUser, _pid, dayCount);
        }
        // Updating the total reward to 0 in UserInfo object.
        currentUser.totalReward = 0;
    }

    /**
    @notice Staking the ASTR reward in ASTR pool. Called only from Lm pool contract
    @param _pid : pool id
    @param _currUserAddr : current user address
    @param _amount : amount for staking
    @dev Description :
        This function is called from withdrawASTRReward If user choose to stake the 100% reward. In this function
        the amount will be staked in ASTR pool. This function is only called from Lm pool contract.
    */
    function stakeASTRReward(
        address _currUserAddr,
        uint256 _pid,
        uint256 _amount
    ) external onlyLmPool {
        _stakeASTRReward(_currUserAddr, _pid, _amount);
    }

    /**
    @notice Staking the ASTR reward in ASTR pool.
    @param _pid : pool id
    @param _currUserAddr : current user address
    @param _amount : amount for staking
    @dev Description :
        This function is called from withdrawASTRReward If user choose to stake the 100% reward. In this function
        the amount will be staked in ASTR pool.
    */
    function _stakeASTRReward(
        address _currUserAddr,
        uint256 _pid,
        uint256 _amount
    ) private {
        UserInfo storage currentUser = userInfo[_pid][_currUserAddr];
        addUserAddress(_currUserAddr, _pid);
        if (_amount > 0) {
            currentUser.amount = currentUser.amount.add(_amount);
            // staking score structure update
            userStakingTrack[_pid][_currUserAddr] = userStakingTrack[_pid][
                _currUserAddr
            ]
                .add(1);
            uint256 userstakeid = userStakingTrack[_pid][_currUserAddr];
            StakeInfo storage staker =
                stakeInfo[_pid][_currUserAddr][userstakeid];
            staker.amount = _amount;
            staker.totalAmount = currentUser.amount;
            staker.timestamp = block.timestamp;
            staker.vault = 3;
            staker.deposit = true;

            //user timestamp
            currentUser.timestamp = block.timestamp;
        }
    }

    /**
    @notice Send the ASTR reward to user account
    @param _pid : pool id
    @param currentUser : current user address
    @param dayCount : day on which user wants to withdraw reward
    @dev Description :
        This function is called from withdrawASTRReward If user choose to withdraw the reward amount. In this function
        the amount will be sent to user account after deducting applicable fee.
        leftDayCount = 90 - days
        fee  = totalReward*leftDayCount/100
        claimableReward = totalReward-fee
    */
    function slashExitFee(
        UserInfo storage currentUser,
        uint256 _pid,
        uint256 dayCount
    ) private {
        uint256 totalReward = currentUser.totalReward;
        uint256 sfr = uint256(90).sub(dayCount);
        // Here fee is calculated on the basis of how days is left in 90 days.
        uint256 fee = totalReward.mul(sfr).div(100);
        // Claimable reward is calculated by substracting the fee from total reward.
        uint256 claimableReward = totalReward.sub(fee);
        if (claimableReward > 0) {
            safeASTRTransfer(msg.sender, claimableReward);
            currentUser.totalReward = 0;
        }
        // Deducted fee would be distribute as reward to the same pool user as individual reward
        // with reward multiplier logic.
        distributeIndividualReward(_pid, fee);
        updateClaimedReward(currentUser, claimableReward);
    }

    /**
    @notice This function is used to updated total claimed and claimed in one day rewards.
    @param currentUser : current user address
    @param _amount : amount is to be claimed
    @dev Description :
    This function is called from withdrawASTRReward function for manegaing the total claimed amount and cliamed amount 
    in one day. This function definition is marked "private" because this fuction is called only from inside the contract.
    */
    function updateClaimedReward(UserInfo storage currentUser, uint256 _amount) private {
        // Adding the amount in total claimed reward.
        currentUser.totalClaimedReward = currentUser.totalClaimedReward.add(_amount);
        // Calculating the difference between the current and last claimed day.
        uint256 day = block.timestamp.sub(currentUser.claimedTimestamp).div(dayseconds);
        if(day == 0) {
            // If day is 0 then user is claiming the reward on the current day.
            currentUser.claimedToday = currentUser.claimedToday.add(_amount);
        }else{
            // Otherwise we update the today date in claimed timestamp and amount in claimed amount.
            currentUser.claimedToday = _amount;
            uint256 todayDaySeconds = block.timestamp % dayseconds;
            currentUser.claimedTimestamp = block.timestamp.sub(todayDaySeconds);
        }
    }

    /**
    @notice This function is used view the today's claimed reward.
    @param _pid : pool id
    @dev Description :
    This function is used for getting the today's claimed reward. This function definition is marked "private" because
    this fuction is called only from inside the contract.
    */
    function getTodayReward(uint256 _pid) external view returns (uint256) {
        UserInfo memory currentUser = userInfo[_pid][msg.sender];
        // Calculating the difference between the current and last claimed day.
        uint256 day = block.timestamp.sub(currentUser.claimedTimestamp).div(dayseconds);
        uint256 claimedToday;
        if(day == 0) {
            // If diffrence is 0 then it returns the claimedToday value from UserInfo object
            claimedToday = currentUser.claimedToday;
        }else{
            // Otherwise it returns 0 because the claimed value celongs to other previous day not for today.
            claimedToday = 0;
        }
        return claimedToday;
    }
}