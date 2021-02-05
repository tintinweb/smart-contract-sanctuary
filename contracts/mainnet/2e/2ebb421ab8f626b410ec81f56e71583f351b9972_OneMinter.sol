/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
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

    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
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

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


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

    uint256[44] private __gap;
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
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
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function __Governable_init_unchained(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    modifier governance() {
        require(msg.sender == governor);
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {

    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    
    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfig(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfig(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}

//import '@uniswap/lib/contracts/libraries/FixedPoint.sol';
//import './FullMath.sol';

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}


//import './Babylonian.sol';
// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

//import './BitMath.sol';
library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

//import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//import '../libraries/UniswapV2Library.sol';
library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

library EmaOracle {
    using FixedPoint for *;
    using SafeMath for uint;

    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
        uint emaPrice0;
        uint emaPrice1;
    }
    
    struct Observations {
        address factory;
        mapping(uint => mapping(address => Observation)) ppos;
    }
    
    function initialize(Observations storage os, address factory, uint period, address tokenA, address tokenB) internal {
        os.factory = factory;
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        Observation storage o = os.ppos[period][pair];
        o.timestamp = blockTimestampLast;
        o.price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        o.price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        o.emaPrice0 = FixedPoint.fraction(reserve1, reserve0)._x;
        o.emaPrice1 = FixedPoint.fraction(reserve0, reserve1)._x;
    }
    
    function calcEmaPrice(uint period, uint timestampStart, uint priceCumulativeStart, uint emaPriceStart, uint timestampEnd, uint priceCumulativeEnd) internal pure returns (uint) {
        uint timeElapsed = timestampEnd.sub(timestampStart);
        if(timeElapsed == 0)
            return emaPriceStart;
        uint priceAverage = priceCumulativeEnd.sub(priceCumulativeStart).div(timeElapsed);
        if(timeElapsed >= period)
            return priceAverage;
        else
            return period.sub(timeElapsed).mul(emaPriceStart).add(timeElapsed.mul(priceAverage)) / period;
    }
    
    function update(Observations storage os, uint period, address tokenA, address tokenB) internal {
        address pair = UniswapV2Library.pairFor(os.factory, tokenA, tokenB);
        Observation storage o = os.ppos[period][pair];
        uint timeElapsed = block.timestamp.sub(o.timestamp);
        if (timeElapsed > period) {
            (uint price0Cumulative, uint price1Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            o.emaPrice0    = calcEmaPrice(period, o.timestamp, o.price0Cumulative, o.emaPrice0, block.timestamp, price0Cumulative);
            o.emaPrice1    = calcEmaPrice(period, o.timestamp, o.price1Cumulative, o.emaPrice1, block.timestamp, price1Cumulative);
            o.timestamp = block.timestamp;
            o.price0Cumulative = price0Cumulative;
            o.price1Cumulative = price1Cumulative;
        }
    }

    function consultEma(Observations storage os, uint period, address tokenIn, uint amountIn, address tokenOut) internal view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(os.factory, tokenIn, tokenOut);
        Observation storage o = os.ppos[period][pair];
        (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        if (token0 == tokenIn)
            amountOut = FixedPoint.uq112x112(uint224(o.emaPrice0)).mul(amountIn).decode144();
        else
            amountOut = FixedPoint.uq112x112(uint224(o.emaPrice1)).mul(amountIn).decode144();
    }

    function consultNow(Observations storage os, address tokenIn, uint amountIn, address tokenOut) internal view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(os.factory, tokenIn, tokenOut);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        if (token0 == tokenIn)
            amountOut = FixedPoint.fraction(reserve1, reserve0).mul(amountIn).decode144();
        else
            amountOut = FixedPoint.fraction(reserve0, reserve1).mul(amountIn).decode144();
    }

    function consultHi(Observations storage os, uint period, address tokenIn, uint amountIn, address tokenOut) internal view returns (uint amountOut) {
        uint amountOutEma = consultEma(os, period, tokenIn, amountIn, tokenOut);
        uint amountOutNow = consultNow(os, tokenIn, amountIn, tokenOut);
        amountOut = Math.max(amountOutEma, amountOutNow);
    }

    function consultLo(Observations storage os, uint period, address tokenIn, uint amountIn, address tokenOut) internal view returns (uint amountOut) {
        uint amountOutEma = consultEma(os, period, tokenIn, amountIn, tokenOut);
        uint amountOutNow = consultNow(os, tokenIn, amountIn, tokenOut);
        amountOut = Math.min(amountOutEma, amountOutNow);
    }
}

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract ExampleOracleSimple {
    using FixedPoint for *;

    uint public constant PERIOD = 24 hours;

    IUniswapV2Pair immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    constructor(address factory, address tokenA, address tokenB) public {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        //IUniswapV2Pair _pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA, tokenB));
        //require(address(_pair) != address(0), 'Not exist pair');
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'ExampleOracleSimple: NO_RESERVES'); // ensure that there's liquidity in the pair
    }

    function update() external {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'ExampleOracleSimple: PERIOD_NOT_ELAPSED');

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint amountOut) {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, 'ExampleOracleSimple: INVALID_TOKEN');
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}

// sliding window oracle that uses observations collected over a window to provide moving price averages in the past
// `windowSize` with a precision of `windowSize / granularity`
// note this is a singleton oracle and only needs to be deployed once per desired parameters, which
// differs from the simple oracle which must be deployed once per pair.
contract ExampleSlidingWindowOracle {
    using FixedPoint for *;
    using SafeMath for uint;

    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    address public immutable factory;
    // the desired amount of time over which the moving average should be computed, e.g. 24 hours
    uint public immutable windowSize;
    // the number of observations stored for each pair, i.e. how many price observations are stored for the window.
    // as granularity increases from 1, more frequent updates are needed, but moving averages become more precise.
    // averages are computed over intervals with sizes in the range:
    //   [windowSize - (windowSize / granularity) * 2, windowSize]
    // e.g. if the window size is 24 hours, and the granularity is 24, the oracle will return the average price for
    //   the period:
    //   [now - [22 hours, 24 hours], now]
    uint8 public immutable granularity;
    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint public immutable periodSize;

    // mapping from pair address to a list of price observations of that pair
    mapping(address => Observation[]) public pairObservations;

    constructor(address factory_, uint windowSize_, uint8 granularity_) public {
        require(granularity_ > 1, 'SlidingWindowOracle: GRANULARITY');
        require(
            (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
            'SlidingWindowOracle: WINDOW_NOT_EVENLY_DIVISIBLE'
        );
        factory = factory_;
        windowSize = windowSize_;
        granularity = granularity_;
    }

    // returns the index of the observation corresponding to the given timestamp
    function observationIndexOf(uint timestamp) public view returns (uint8 index) {
        uint epochPeriod = timestamp / periodSize;
        return uint8(epochPeriod % granularity);
    }

    // returns the observation from the oldest epoch (at the beginning of the window) relative to the current time
    function getFirstObservationInWindow(address pair) private view returns (Observation storage firstObservation) {
        uint8 observationIndex = observationIndexOf(block.timestamp);
        // no overflow issue. if observationIndex + 1 overflows, result is still zero.
        uint8 firstObservationIndex = (observationIndex + 1) % granularity;
        firstObservation = pairObservations[pair][firstObservationIndex];
    }

    // update the cumulative price for the observation at the current timestamp. each observation is updated at most
    // once per epoch period.
    function update(address tokenA, address tokenB) external {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

        // populate the array with empty observations (first call only)
        for (uint i = pairObservations[pair].length; i < granularity; i++) {
            pairObservations[pair].push();
        }

        // get the observation for the current period
        uint8 observationIndex = observationIndexOf(block.timestamp);
        Observation storage observation = pairObservations[pair][observationIndex];

        // we only want to commit updates once per period (i.e. windowSize / granularity)
        uint timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            observation.timestamp = block.timestamp;
            observation.price0Cumulative = price0Cumulative;
            observation.price1Cumulative = price1Cumulative;
        }
    }

    // given the cumulative prices of the start and end of a period, and the length of the period, compute the average
    // price in terms of how much amount out is received for the amount in
    function computeAmountOut(
        uint priceCumulativeStart, uint priceCumulativeEnd,
        uint timeElapsed, uint amountIn
    ) private pure returns (uint amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    // returns the amount out corresponding to the amount in for a given token using the moving average over the time
    // range [now - [windowSize, windowSize - periodSize * 2], now]
    // update must have been called for the bucket corresponding to timestamp `now - windowSize`
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        Observation storage firstObservation = getFirstObservationInWindow(pair);

        uint timeElapsed = block.timestamp - firstObservation.timestamp;
        require(timeElapsed <= windowSize, 'SlidingWindowOracle: MISSING_HISTORICAL_OBSERVATION');
        // should never happen.
        require(timeElapsed >= windowSize - periodSize * 2, 'SlidingWindowOracle: UNEXPECTED_TIME_ELAPSED');

        (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            return computeAmountOut(firstObservation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(firstObservation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }
}

contract ApprovedERC20 is ERC20UpgradeSafe, Configurable {
    address public operator;

	function __ApprovedERC20_init_unchained(address operator_) public governance {
		operator = operator_;
	}
	
	modifier onlyOperator {
	    require(msg.sender == operator, 'called only by operator');
	    _;
	}

    function transferFrom_(address sender, address recipient, uint256 amount) external onlyOperator returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
}

contract MintableERC20 is ApprovedERC20 {
	function mint_(address acct, uint amt) external onlyOperator {
	    _mint(acct, amt);
	}
	
	function burn_(address acct, uint amt) external onlyOperator {
	    _burn(acct, amt);
	}
}

contract ONE is MintableERC20 {
	function __ONE_init(address governor_, address vault_, address oneMine) external initializer {
        __Context_init_unchained();
		__ERC20_init_unchained("One Eth", "ONE");
		__Governable_init_unchained(governor_);
		__ApprovedERC20_init_unchained(vault_);
		__ONE_init_unchained(oneMine);
	}
	
	function __ONE_init_unchained(address oneMine) public governance {
		_mint(oneMine, 100 * 10 ** uint256(decimals()));
	}
	
}

contract ONS is ApprovedERC20 {
	function __ONS_init(address governor_, address oneMinter_, address onsMine, address offering, address timelock) external initializer {
        __Context_init_unchained();
		__ERC20_init("One Share", "ONS");
		__Governable_init_unchained(governor_);
		__ApprovedERC20_init_unchained(oneMinter_);
		__ONS_init_unchained(onsMine, offering, timelock);
	}
	
	function __ONS_init_unchained(address onsMine, address offering, address timelock) public governance {
		_mint(onsMine, 90000 * 10 ** uint256(decimals()));		// 90%
		_mint(offering, 5000 * 10 ** uint256(decimals()));		//  5%
		_mint(timelock, 5000 * 10 ** uint256(decimals()));		//  5%
	}

}

contract ONB is MintableERC20 {
	function __ONB_init(address governor_, address vault_) virtual external initializer {
        __Context_init_unchained();
		__ERC20_init("One Bond", "ONB");
		__Governable_init_unchained(governor_);
		__ApprovedERC20_init_unchained(vault_);
	}

    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        require(from == address(0) || to == address(0), 'ONB is untransferable');
    }
}

contract Offering is Configurable {
	using SafeMath for uint;
	using SafeERC20 for IERC20;
	
	bytes32 internal constant _quota_      = 'quota';
	bytes32 internal _quota_0              = '';            // placeholder
	
	IERC20 public token;
	IERC20 public currency;
	uint public price;
	address public vault;
	uint public begin;
	uint public span;
	mapping (address => uint) public offeredOf;
	
	function __Offering_init(address governor_, address _token, address _currency, uint _price, uint _quota, address _vault, uint _begin, uint _span) external initializer {
		__Governable_init_unchained(governor_);
		__Offering_init_unchained(_token, _currency, _price, _quota, _vault, _begin, _span);
	}
	
	function __Offering_init_unchained(address _token, address _currency, uint _price, uint _quota, address _vault, uint _begin, uint _span) public governance {
		token = IERC20(_token);
		currency = IERC20(_currency);
		price = _price;
		vault = _vault;
		begin = _begin;
		span = _span;
		config[_quota_] = _quota;
	}
	
	function offer(uint vol) external {
		require(now >= begin, 'Not begin');
		if(now > begin.add(span))
			if(token.balanceOf(address(this)) > 0)
				token.safeTransfer(vault, token.balanceOf(address(this)));
			else
				revert('offer over');
		require(offeredOf[msg.sender] < config[_quota_], 'out of quota');
		vol = Math.min(Math.min(vol, config[_quota_].sub(offeredOf[msg.sender])), token.balanceOf(address(this)));
		offeredOf[msg.sender] = offeredOf[msg.sender].add(vol);
		uint amt = vol.mul(price).div(1e18);
		currency.safeTransferFrom(msg.sender, address(this), amt);
		currency.approve(vault, amt);
		IVault(vault).receiveAEthFrom(address(this), amt);
		token.safeTransfer(msg.sender, vol);
	}
}

interface IVault {
    function receiveAEthFrom(address from, uint vol) external;
}

contract Timelock is Configurable {
	using SafeMath for uint;
	using SafeERC20 for IERC20;
	
	IERC20 public token;
	address public recipient;
	uint public begin;
	uint public span;
	uint public times;
	uint public total;
	
	function start(address _token, address _recipient, uint _begin, uint _span, uint _times) external governance {
		require(address(token) == address(0), 'already start');
		token = IERC20(_token);
		recipient = _recipient;
		begin = _begin;
		span = _span;
		times = _times;
		total = token.balanceOf(address(this));
	}

    function unlockCapacity() public view returns (uint) {
       if(begin == 0 || now < begin)
            return 0;
            
        for(uint i=1; i<=times; i++)
            if(now < span.mul(i).div(times).add(begin))
                return token.balanceOf(address(this)).sub(total.mul(times.sub(i)).div(times));
                
        return token.balanceOf(address(this));
    }
    
    function unlock() public {
        token.safeTransfer(recipient, unlockCapacity());
    }
    
    fallback() external {
        unlock();
    }
}

interface IAETH is IERC20 {
    function ratio() external view returns (uint256);
}

contract Constant {
    bytes32 internal constant _ratioAEthWhenMint_       = 'ratioAEthWhenMint';
}

contract Vault is Constant, Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using EmaOracle for EmaOracle.Observations;
    
    bytes32 internal constant _periodTwapOne_           = 'periodTwapOne';
    bytes32 internal constant _periodTwapOns_           = 'periodTwapOns';
    bytes32 internal constant _periodTwapAEth_          = 'periodTwapAEth';
    //bytes32 internal constant _thresholdReserve_        = 'thresholdReserve';
    bytes32 internal constant _initialMintQuota_        = 'initialMintQuota';
    bytes32 internal constant _rebaseInterval_          = 'rebaseInterval';
    bytes32 internal constant _rebaseThreshold_         = 'rebaseThreshold';
    bytes32 internal constant _rebaseCap_               = 'rebaseCap';
    
    address public oneMinter;
    ONE public one;
    ONS public ons;
    address public onb;
    IAETH public aEth;
    address public WETH;
    uint public begin;
    uint public span;
    EmaOracle.Observations public twapOne;
    EmaOracle.Observations public twapOns;
    EmaOracle.Observations public twapAEth;
    uint public totalEthValue;
    uint public rebaseTime;
    
	function __Vault_init(address governor_, address _oneMinter, ONE _one, ONS _ons, address _onb, IAETH _aEth, address _WETH, uint _begin, uint _span) external initializer {
		__Governable_init_unchained(governor_);
		__Vault_init_unchained(_oneMinter, _one, _ons, _onb, _aEth, _WETH, _begin, _span);
	}
	
	function __Vault_init_unchained(address _oneMinter, ONE _one, ONS _ons, address _onb, IAETH _aEth, address _WETH, uint _begin, uint _span) public governance {
		oneMinter = _oneMinter;
		one = _one;
		ons = _ons;
		onb = _onb;
		aEth = _aEth;
		WETH = _WETH;
		begin = _begin;
		span = _span;
		//config[_thresholdReserve_]  = 0.8 ether;
		config[_ratioAEthWhenMint_] = 0.9 ether;
		config[_periodTwapOne_]     =  8 hours;
		config[_periodTwapOns_]     = 15 minutes;
		config[_periodTwapAEth_]    = 15 minutes;
		config[_initialMintQuota_]  = 10000 ether;
		config[_rebaseInterval_]    = 8 hours;
		config[_rebaseThreshold_]   = 1.05 ether;
		config[_rebaseCap_]         = 0.05 ether;   // 5%
		rebaseTime = now;
	}
	
	function twapInit(address swapFactory) external governance {
		twapOne.initialize(swapFactory, config[_periodTwapOne_], address(one), address(aEth));
		twapOns.initialize(swapFactory, config[_periodTwapOns_], address(ons), address(aEth));
		twapAEth.initialize(swapFactory, config[_periodTwapAEth_], address(aEth), WETH);
	}
		
    modifier updateTwap {
        twapOne.update(config[_periodTwapOne_], address(one), address(aEth));
        twapOns.update(config[_periodTwapOns_], address(ons), address(aEth));
        twapAEth.update(config[_periodTwapAEth_], address(aEth), WETH);
        _;
    }
    
    //function updateTWAP() external updateTwap {
    //    
    //}
    
    //function mintONE(uint amt) external updateTwap {
    //    if(now < begin || now > begin.add(span)) {
    //        uint quota = IERC20(one).totalSupply().sub0(IERC20(aEth).balanceOf(address(this)).mul(1e18).div(config[_thresholdReserve_]));
    //        require(quota > 0 , 'mintONE only when aEth.balanceOf(this)/one.totalSupply() < 80%');
    //        amt = Math.min(amt, quota);
    //    }
    //    
    //    IERC20(aEth).safeTransferFrom(msg.sender, address(this), amt.mul(config[_ratioAEthWhenMint_]).div(1e18));
    //    
    //    uint vol = amt.mul(uint(1e18).sub(config[_ratioAEthWhenMint_])).div(1e18);
    //    vol = twapOns.consultHi(config[_periodTwapOns_], address(aEth), vol, address(ons));
    //    ons.transferFrom_(msg.sender, address(this), vol);
    //    
    //    one.mint_(msg.sender, amt);
    //}
    
    function E2B(uint vol) external {
        
    }
    
    function B2E(uint vol) external {
        
    }
    
    function burnONE(uint amt) external {
        
    }
    
    function burnONB(uint vol) external {
        
    }
    
    function onePriceNow() public view returns (uint price) {
        price = twapOne.consultNow( address(one), 1 ether, address(aEth));
        price = twapAEth.consultNow(address(aEth), price,  address(WETH));
    }
    function onePriceEma() public view returns (uint price) {
        price = twapOne.consultEma( config[_periodTwapOne_],  address(one), 1 ether, address(aEth));
        price = twapAEth.consultEma(config[_periodTwapAEth_], address(aEth), price,  address(WETH));
    }
    function onePriceHi() public view returns (uint) {
        return Math.max(onePriceNow(), onePriceEma());
    }
    function onePriceLo() public view returns (uint) {
        return Math.min(onePriceNow(), onePriceEma());
    }
    
    function onsPriceNow() public view returns (uint price) {
        price = twapOns.consultNow( address(ons), 1 ether, address(aEth));
        price = twapAEth.consultNow(address(aEth), price,  address(WETH));
    }
    function onsPriceEma() public view returns (uint price) {
        price = twapOns.consultEma( config[_periodTwapOns_],  address(ons), 1 ether, address(aEth));
        price = twapAEth.consultEma(config[_periodTwapAEth_], address(aEth), price,  address(WETH));
    }
    function onsPriceHi() public view returns (uint) {
        return Math.max(onsPriceNow(), onsPriceEma());
    }
    function onsPriceLo() public view returns (uint) {
        return Math.min(onsPriceNow(), onsPriceEma());
    }
    
    function rebaseable() public view returns (uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol) {
        uint aEthPrice = 1e36 / aEth.ratio();
        uint onsPrice  = onsPriceLo();
        uint aEthBalance = aEth.balanceOf(oneMinter);
        uint onsBalance  = ons.balanceOf(oneMinter);
        uint oneVolAEth = aEthBalance.mul(aEthPrice).div(config[_ratioAEthWhenMint_]);
        uint oneVolOns  = onsBalance.mul(onsPrice).div(uint(1e18).sub(config[_ratioAEthWhenMint_]));
        oneVol = one.totalSupply().mul(config[_rebaseCap_]).div(1e18);
        oneVol = Math.min(Math.min(oneVol, oneVolAEth), oneVolOns);
        if(oneVol == 0)
            return (0, 0, 0, 0, 0);
        //aEthVol = oneVol.mul(config[_ratioAEthWhenMint_]).div(aEthPrice);
        //onsVol  = oneVol.mul(uint(1e18).sub(config[_ratioAEthWhenMint_])).div(onsPrice);
        aEthRatio = oneVol.mul(1e18).div(oneVolAEth);
        onsRatio  = oneVol.mul(1e18).div(oneVolOns);
        aEthVol = aEthBalance.mul(aEthRatio).div(1e18);
        onsVol  = onsBalance.mul(onsRatio).div(1e18);
    }
    
    function rebase() public updateTwap returns (uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol) {
        if(now < begin)
            return (0, 0, 0, 0, 0);
        else if (now > begin.add(span) || one.totalSupply() >= config[_initialMintQuota_]) {
            uint interval = config[_rebaseInterval_];
            if(now / interval <= rebaseTime / interval)
                return (0, 0, 0, 0, 0);
            uint price = onePriceLo();
            if(price < config[_rebaseThreshold_])
                return (0, 0, 0, 0, 0);
        }        
        (aEthVol, aEthRatio, onsVol, onsRatio, oneVol) = rebaseable();
        if(oneVol == 0)
            return (0, 0, 0, 0, 0);
            
        receiveAEthFrom(address(oneMinter), aEthVol);
        ons.transferFrom(address(oneMinter), address(this), onsVol);
        one.mint_(address(oneMinter), oneVol);
        rebaseTime = now;
        emit Rebase(aEthVol, aEthRatio, onsVol, onsRatio, oneVol);
    }
    event Rebase(uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol);
    
    function receiveAEthFrom(address from, uint vol) public {
        aEth.transferFrom(from, address(this), vol);
        totalEthValue = totalEthValue.add(vol.mul(1e18).div(aEth.ratio()));
    }
    
    function _sendAEthTo(address to, uint vol) internal {
        totalEthValue = totalEthValue.sub(vol.mul(1e18).div(aEth.ratio()));
        aEth.transfer(to, vol);
    }
    
    function interests() public view returns (uint) {
        return aEth.balanceOf(address(this)).mul(1e18).div(aEth.ratio()).sub(totalEthValue);
    }
}

contract OneMinter is Constant, Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint internal constant INITIAL_INPUT = 1e27;

    Vault public vault;
    ONE public one;
    ONS public ons;
    IAETH public aEth;
    
    mapping (address => uint) internal _aEthBalances;
    mapping (address => uint) internal _onsBalances;
    mapping (address => uint) internal _aEthRIOs;
    mapping (address => uint) internal _onsRIOs;
    mapping (uint => uint) internal _aEthRioIn;
    mapping (uint => uint) internal _onsRioIn;
    uint internal _aEthRound;
    uint internal _onsRound;

    function __OneMinter_init(address governor_, address vault_) external initializer {
        __Governable_init_unchained(governor_);
        __OneMinter_init_unchained(vault_);
    }
    
	function __OneMinter_init_unchained(address vault_) public governance {
		vault = Vault(vault_);
		one = ONE(vault.one());
		ons = ONS(vault.ons());
		aEth = IAETH(vault.aEth());
		aEth.approve(address(vault), uint(-1));
		ons.approve(address(vault), uint(-1));
        _aEthRound = _onsRound = 1;
        _aEthRioIn[1] = packRIO(1, INITIAL_INPUT, 0);
        _onsRioIn [1] = packRIO(1, INITIAL_INPUT, 0);
	}
	
    //struct RIO {
    //    uint32  round;
    //    uint112 input;
    //    uint112 output;
    //}

    function packRIO(uint256 round, uint256 input, uint256 output) internal pure virtual returns (uint256) {
        require(round <= uint32(-1) && input <= uint112(-1) && output <= uint112(-1), 'RIO OVERFLOW');
        return round << 224 | input << 112 | output;
    }
    
    function unpackRIO(uint256 rio) internal pure virtual returns (uint256 round, uint256 input, uint256 output) {
        round  = rio >> 224;
        input  = uint112(rio >> 112);
        output = uint112(rio);
    }
    
    function totalSupply() external view returns (uint aEthSupply, uint onsSupply) {
        aEthSupply = aEth.balanceOf(address(this));
        onsSupply  =  ons.balanceOf(address(this));
    }
    
    function balanceOf_(address acct) public returns (uint aEthBal, uint onsBal) {
        _rebase();
        return balanceOf(acct);
    }
    
    function balanceOf(address acct) public view returns (uint aEthBal, uint onsBal) {
        uint rio = _aEthRIOs[acct];
        (uint r, uint i, ) = unpackRIO(rio);
        uint RIO = _aEthRioIn[r];
        if(RIO != rio) {
            (, uint I, ) = unpackRIO(RIO);
            aEthBal = _aEthBalances[acct].mul(I).div(i);
        } else
            aEthBal = _aEthBalances[acct];

        rio = _onsRIOs[acct];
        (r, i, ) = unpackRIO(rio);
        RIO = _onsRioIn[r];
        if(RIO != rio) {
            (, uint I, ) = unpackRIO(RIO);
            onsBal = _onsBalances[acct].mul(I).div(i);
        } else
            onsBal = _onsBalances[acct];
    }
    
    function mintInitial(uint aEthVol, uint onsVol) external {
        purchase(aEthVol, onsVol);
        //mint();
        cancel(uint(-1), uint(-1));
    }
    
    function purchase(uint aEthVol, uint onsVol) public {
        mint();
        
        aEth.transferFrom(msg.sender, address(this), aEthVol);
        ons.transferFrom_(msg.sender, address(this), onsVol);
        _aEthBalances[msg.sender] = _aEthBalances[msg.sender].add(aEthVol);
        _onsBalances [msg.sender] = _onsBalances [msg.sender].add(onsVol);
        
        emit Purchase(msg.sender, aEthVol, onsVol);
    }
    event Purchase(address acct, uint aEthVol, uint onsVol);
    
    function cancel(uint aEthVol, uint onsVol) public {
        mint();
        
        if(aEthVol == uint(-1))
            aEthVol = _aEthBalances[msg.sender];
        if(onsVol == uint(-1))
            onsVol = _onsBalances[msg.sender];
        _aEthBalances[msg.sender] = _aEthBalances[msg.sender].sub(aEthVol);
        _onsBalances [msg.sender] = _onsBalances [msg.sender].sub(onsVol);
        aEth.transfer(msg.sender, aEthVol);
        ons.transfer (msg.sender, onsVol);
        
        emit Cancel(msg.sender, aEthVol, onsVol);
    }
    event Cancel(address acct, uint aEthVol, uint onsVol);
    
    function mintable_(address acct) public returns (uint) {
        _rebase();
        return mintable(acct);
    }
    
    function mintable(address acct) public view returns (uint vol) {
        uint rio = _aEthRIOs[acct];
        (uint r, uint i, uint o) = unpackRIO(rio);
        uint RIO = _aEthRioIn[r];
        if(rio == RIO)
            return 0;
        
        uint bal = _aEthBalances[acct];
        (, , uint O) = unpackRIO(RIO);
        vol = O.sub(o).mul(bal).div(i);

        rio = _onsRIOs[acct];
        (r, i, o) = unpackRIO(rio);
        RIO = _onsRioIn[r];
        (, , O) = unpackRIO(RIO);
        vol = O.sub(o).mul(bal).div(i).add(vol);
    }
    
    function mint() public {
        _rebase();
        
        (uint aEthBal, uint onsBal) = balanceOf(msg.sender);
        uint oneVol = mintable(msg.sender);
        
        uint RIO = _aEthRioIn[_aEthRound];
        uint rio = _aEthRIOs[msg.sender];
        if(rio != RIO) {
            _aEthRIOs[msg.sender] = RIO;
            _onsRIOs [msg.sender] = _onsRioIn[_onsRound];
        }
            
        _aEthBalances[msg.sender] = aEthBal;
        _onsBalances [msg.sender] = onsBal;
        one.transfer(msg.sender, oneVol);
        emit Mint(msg.sender, oneVol);
    }
    event Mint(address acct, uint oneVol);
    
    function _rebase() internal {
        (uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol) = vault.rebase();
        if(oneVol == 0)
            return;
            
        uint ratioAEthWhenMint = vault.getConfig(_ratioAEthWhenMint_);
        (uint round, uint input, uint output) = unpackRIO(_aEthRioIn[_aEthRound]);
        output = oneVol.mul(ratioAEthWhenMint).div(aEthVol).mul(input.mul(aEthRatio).div(1e18)).div(1e18).add(output);
        input = uint(1e18).sub(aEthRatio).mul(input).div(1e18);
        _aEthRioIn[round] = packRIO(round, input, output);
        if(input == 0)
            _aEthRioIn[++_aEthRound] = packRIO(++round, INITIAL_INPUT, 0);
            
        (round, input, output) = unpackRIO(_onsRioIn[_onsRound]);
        output = oneVol.mul(uint(1e18).sub(ratioAEthWhenMint)).div(onsVol).mul(input.mul(onsRatio).div(1e18)).div(1e18).add(output);
        input = uint(1e18).sub(onsRatio).mul(input).div(1e18);
        _onsRioIn[round] = packRIO(round, input, output);
        if(input == 0)
            _onsRioIn[++_onsRound] = packRIO(++round, INITIAL_INPUT, 0);
            
        emit Rebase(aEthVol, aEthRatio, onsVol, onsRatio, oneVol);
    }
    event Rebase(uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol);
}