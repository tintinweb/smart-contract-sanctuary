/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-12
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

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

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


contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function initialize(address governor_) virtual public initializer {
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


/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }
  
  receive () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() virtual internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() virtual internal {
      
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    if(OpenZeppelinUpgradesAddress.isContract(msg.sender) && msg.data.length == 0 && gasleft() <= 2300)         // for receive ETH only from other contract
        return;
    _willFallback();
    _delegate(_implementation());
  }
}


/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
abstract contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() override internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}


/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() virtual override internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    //super._willFallback();
  }
}

interface IAdminUpgradeabilityProxyView {
  function admin() external view returns (address);
  function implementation() external view returns (address);
}


/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
abstract contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
  
  //function _willFallback() virtual override internal {
    //super._willFallback();
  //}
}


/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _admin, address _logic, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
  
  function _willFallback() override(Proxy, BaseAdminUpgradeabilityProxy) internal {
    super._willFallback();
  }
}


/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
abstract contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}


/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _admin, address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
  
  function _willFallback() override(Proxy, BaseAdminUpgradeabilityProxy) internal {
    super._willFallback();
  }

}


interface IProxyFactory {
    function productImplementation() external view returns (address);
    function productImplementations(bytes32 name) external view returns (address);
}


/**
 * @title ProductProxy
 * @dev This contract implements a proxy that 
 * it is deploied by ProxyFactory, 
 * and it's implementation is stored in factory.
 */
contract ProductProxy is Proxy {
    
  /**
   * @dev Storage slot with the address of the ProxyFactory.
   * This is the keccak-256 hash of "eip1967.proxy.factory" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant FACTORY_SLOT = 0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1;

  function productName() virtual public pure returns (bytes32) {
    return 0x0;
  }

  /**
   * @dev Sets the factory address of the ProductProxy.
   * @param newFactory Address of the new factory.
   */
  function _setFactory(address newFactory) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newFactory), "Cannot set a factory to a non-contract address");

    bytes32 slot = FACTORY_SLOT;

    assembly {
      sstore(slot, newFactory)
    }
  }

  /**
   * @dev Returns the factory.
   * @return factory Address of the factory.
   */
  function _factory() internal view returns (address factory) {
    bytes32 slot = FACTORY_SLOT;
    assembly {
      factory := sload(slot)
    }
  }
  
  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() virtual override internal view returns (address) {
    address factory = _factory();
    if(OpenZeppelinUpgradesAddress.isContract(factory))
        return IProxyFactory(factory).productImplementations(productName());
    else
        return address(0);
  }

}


/**
 * @title InitializableProductProxy
 * @dev Extends ProductProxy with an initializer for initializing
 * factory and init data.
 */
contract InitializableProductProxy is ProductProxy {
  /**
   * @dev Contract initializer.
   * @param factory Address of the initial factory.
   * @param data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address factory, bytes memory data) public payable {
    require(_factory() == address(0));
    assert(FACTORY_SLOT == bytes32(uint256(keccak256('eip1967.proxy.factory')) - 1));
    _setFactory(factory);
    if(data.length > 0) {
      (bool success,) = _implementation().delegatecall(data);
      require(success);
    }
  }  
}


/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IWETH {
    function deposit() external payable;
    //function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract Constants {
    bytes32 internal constant _LongOption_      = 'LongOption';
    bytes32 internal constant _ShortOption_     = 'ShortOption';
    bytes32 internal constant _feeRate_         = 'feeRate';
    bytes32 internal constant _feeRecipient_    = 'feeRecipient';
    bytes32 internal constant _uniswapRounter_  = 'uniswapRounter';
    bytes32 internal constant _mintOnlyBy_      = 'mintOnlyBy';
}

contract OptionFactory is Configurable, Constants {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using HiLo for uint;

    mapping(bytes32 => address) public productImplementations;
    mapping(address => mapping(address => mapping(address => mapping(uint => mapping(uint => address))))) public longs;
    mapping(address => mapping(address => mapping(address => mapping(uint => mapping(uint => address))))) public shorts;
    address[] public allLongs;
    address[] public allShorts;
    
    function length() public view returns (uint) {
        return allLongs.length;
    }

    function initialize(address _governor, address _implLongOption, address _implShortOption, address _feeRecipient, address _mintOnlyBy) public initializer {
        super.initialize(_governor);
        productImplementations[_LongOption_]    = _implLongOption;
        productImplementations[_ShortOption_]   = _implShortOption;
        config[_feeRate_]                       = 0.005 ether;               //0.002 ether;        // 0.2%
        config[_feeRecipient_]                  = uint(_feeRecipient);
        config[_uniswapRounter_]                = uint(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        config[_mintOnlyBy_]                    = uint(_mintOnlyBy);
    }

    function upgradeProductImplementationsTo(address _implLongOption, address _implShortOption) external governance {
        productImplementations[_LongOption_] = _implLongOption;
        productImplementations[_ShortOption_] = _implShortOption;
    }
    
    function pack_maturity_expiry(uint maturity, uint expiry) public pure returns (uint) {
        return maturity.pack(expiry);
    }
    function unpack_maturity(uint maturity_expiry) public pure returns (uint) {
        return maturity_expiry.hi();
    }
    function unpack_expiry(uint maturity_expiry) public pure returns (uint) {
        return maturity_expiry.lo();
    }
    
    function createOption(bool _private, address _collateral, address _underlying, uint _strikePrice, uint _expiry) public returns (address long, address short) {
        require(_collateral != _underlying, 'IDENTICAL_ADDRESSES');
        require(_collateral != address(0) && _underlying != address(0), 'ZERO_ADDRESS');
        require(_strikePrice != 0, 'ZERO_STRIKE_PRICE');
        require(_expiry.hi() < _expiry.lo(), 'maturity must be before expiry');
        require(_expiry.lo() > now, 'Cannot create an expired option');

        address creator = _private ? tx.origin : address(0);
        require(longs[creator][_collateral][_underlying][_strikePrice][_expiry] == address(0), 'SHORT_PROXY_EXISTS');     // single check is sufficient

        bytes32 salt = keccak256(abi.encodePacked(creator, _collateral, _underlying, _strikePrice, _expiry));

        bytes memory bytecode = type(LongProxy).creationCode;
        assembly {
            long := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        InitializableProductProxy(payable(long)).initialize(address(this), abi.encodeWithSignature('initialize(address,address,address,uint256,uint256)', creator, _collateral, _underlying, _strikePrice, _expiry));
        
        bytecode = type(ShortProxy).creationCode;
        assembly {
            short := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        InitializableProductProxy(payable(short)).initialize(address(this), abi.encodeWithSignature('initialize(address,address,address,uint256,uint256)', creator, _collateral, _underlying, _strikePrice, _expiry));

        longs [creator][_collateral][_underlying][_strikePrice][_expiry] = long;
        shorts[creator][_collateral][_underlying][_strikePrice][_expiry] = short;
        allLongs.push(long);
        allShorts.push(short);
        emit OptionCreated(creator, _collateral, _underlying, _strikePrice, _expiry, long, short, allLongs.length);
    }
    event OptionCreated(address indexed creator, address indexed _collateral, address indexed _underlying, uint _strikePrice, uint _expiry, address long, address short, uint count);
    
    function _mint(address sender, bool _private, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume) internal returns (address long, address short, uint vol) {
        require(config[_mintOnlyBy_] == 0 || address(config[_mintOnlyBy_]) == sender, 'mint denied');
        address creator = _private ? tx.origin : address(0);
        long  = longs [creator][_collateral][_underlying][_strikePrice][_expiry];
        short = shorts[creator][_collateral][_underlying][_strikePrice][_expiry];
        if(short == address(0))                                                                      // single check is sufficient
            (long, short) = createOption(_private, _collateral, _underlying, _strikePrice, _expiry);
        
        IERC20(_collateral).safeTransferFrom(sender, short, volume);
        ShortOption(short).mint_(sender, volume);
        LongOption(long).mint_(sender, volume);
        vol = volume;
        
        emit Mint(sender, _private, _collateral, _underlying, _strikePrice, _expiry, long, short, vol);
    }
    event Mint(address indexed seller, bool _private, address indexed _collateral, address indexed _underlying, uint _strikePrice, uint _expiry, address long, address short, uint vol);

    function mint_(address sender, bool _private, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume) public governance returns (address long, address short, uint vol) {
        return _mint(sender, _private, _collateral, _underlying, _strikePrice, _expiry, volume);
    }
    
    function mint(bool _private, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume) public returns (address long, address short, uint vol) {
        return _mint(msg.sender, _private, _collateral, _underlying, _strikePrice, _expiry, volume);
    }
    
    function mint(address longOrShort, uint volume) external returns (address, address, uint) {
        LongOption long = LongOption(longOrShort);
        return mint(long.creator()!=address(0), long.collateral(), long.underlying(), long.strikePrice(), long.expiry(), volume);
    }

    function burn(address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume) public returns (address long, address short, uint vol) {
        long  = longs [_creator][_collateral][_underlying][_strikePrice][_expiry];
        short = shorts[_creator][_collateral][_underlying][_strikePrice][_expiry];
        require(short != address(0), 'ZERO_ADDRESS');                                        // single check is sufficient

        LongOption(long).burn_(msg.sender, volume);
        ShortOption(short).burn_(msg.sender, volume);
        vol = volume;
        
        emit Burn(msg.sender, _creator, _collateral, _underlying, _strikePrice, _expiry, vol);
    }
    event Burn(address indexed seller, address _creator, address indexed _collateral, address indexed _underlying, uint _strikePrice, uint _expiry, uint vol);

    function burn(address longOrShort, uint volume) external returns (address, address, uint) {
        LongOption long = LongOption(longOrShort);
        return burn(long.creator(), long.collateral(), long.underlying(), long.strikePrice(), long.expiry(), volume);
    }

    function calcExerciseAmount(address _long, uint volume) public view returns (uint) {
        return calcExerciseAmount(volume, LongOption(_long).strikePrice());
    }
    function calcExerciseAmount(uint volume, uint _strikePrice) public pure returns (uint) {
        return volume.mul(_strikePrice).div(1 ether);
    }
    
    function _exercise(address buyer, address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume, address[] memory path) internal returns (uint vol, uint fee, uint amt) {
        require(_expiry.hi() <= now, 'Immature');
        require(now <= _expiry.lo(), 'Expired');
        
        address long  = longs[_creator][_collateral][_underlying][_strikePrice][_expiry];
        LongOption(long).burn_(buyer, volume);
        
        address short = shorts[_creator][_collateral][_underlying][_strikePrice][_expiry];
        amt = calcExerciseAmount(volume, _strikePrice);
        if(path.length == 0) {
            IERC20(_underlying).safeTransferFrom(buyer, short, amt);
            (vol, fee) = ShortOption(short).exercise_(buyer, volume);
        } else {
            (vol, fee) = ShortOption(short).exercise_(address(this), volume);
            IERC20(_collateral).safeApprove(address(config[_uniswapRounter_]), vol);
            uint[] memory amounts = IUniswapV2Router01(config[_uniswapRounter_]).swapTokensForExactTokens(amt, vol, path, short, now);
            vol = vol.sub(amounts[0]);
            IERC20(_collateral).safeTransfer(buyer, vol);
            amt = 0;
        }
        emit Exercise(buyer, _collateral, _underlying, _strikePrice, _expiry, volume, vol, fee, amt);
    }
    event Exercise(address indexed buyer, address indexed _collateral, address indexed _underlying, uint _strikePrice, uint _expiry, uint volume, uint vol, uint fee, uint amt);
    
    function exercise_(address buyer, address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume, address[] calldata path) external returns (uint vol, uint fee, uint amt) {
        address long  = longs[_creator][_collateral][_underlying][_strikePrice][_expiry];
        require(msg.sender == long, 'Only LongOption');
        
        return _exercise(buyer, _creator, _collateral, _underlying, _strikePrice, _expiry, volume, path);
    }
    
    function exercise(address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume, address[] calldata path) external returns (uint vol, uint fee, uint amt) {
        return _exercise(msg.sender, _creator, _collateral, _underlying, _strikePrice, _expiry, volume, path);
    }
    
    function exercise(address _long, uint volume, address[] memory path) public returns (uint vol, uint fee, uint amt) {
        LongOption long = LongOption(_long);
        return _exercise(msg.sender, long.creator(), long.collateral(), long.underlying(), long.strikePrice(), long.expiry(), volume, path);
    }

    function exercise(address _long, uint volume) public returns (uint vol, uint fee, uint amt) {
        LongOption long = LongOption(_long);
        return _exercise(msg.sender, long.creator(), long.collateral(), long.underlying(), long.strikePrice(), long.expiry(), volume, new address[](0));
    }

    function exercise(address long, address[] calldata path) external returns (uint vol, uint fee, uint amt) {
        return exercise(long, LongOption(long).balanceOf(msg.sender), path);
    }

    function exercise(address long) external returns (uint vol, uint fee, uint amt) {
        return exercise(long, LongOption(long).balanceOf(msg.sender), new address[](0));
    }

    function settleable(address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume) public view returns (uint vol, uint col, uint fee, uint und) {
        address short = shorts[_creator][_collateral][_underlying][_strikePrice][_expiry];
        return ShortOption(short).settleable(volume);
    }
    function settleable(address short, uint volume) public view returns (uint vol, uint col, uint fee, uint und) {
        return ShortOption(short).settleable(volume);
    }
    function settleable(address seller, address short) public view returns (uint vol, uint col, uint fee, uint und) {
        return ShortOption(short).settleable(seller);
    }
    
    function settle(address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume) external returns (uint vol, uint col, uint fee, uint und) {
        address short = shorts[_creator][_collateral][_underlying][_strikePrice][_expiry];
        return settle(short, volume);
    }
    function settle_(address sender, address short, uint volume) public governance returns (uint vol, uint col, uint fee, uint und) {
        return ShortOption(short).settle_(sender, volume);
    }
    function settle(address short, uint volume) public returns (uint vol, uint col, uint fee, uint und) {
        return ShortOption(short).settle_(msg.sender, volume);
    }
    function settle(address short) external returns (uint vol, uint col, uint fee, uint und) {
        return settle(short, ShortOption(short).balanceOf(msg.sender));
    }
    
    function emitSettle(address seller, address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint vol, uint col, uint fee, uint und) external {
        address short  = shorts[_creator][_collateral][_underlying][_strikePrice][_expiry];
        require(msg.sender == short, 'Only ShortOption');
        emit Settle(seller, _creator, _collateral, _underlying, _strikePrice, _expiry, vol, col, fee, und);
    }
    event Settle(address indexed seller, address _creator, address indexed _collateral, address indexed _underlying, uint _strikePrice, uint _expiry, uint vol, uint col, uint fee, uint und);
}

contract LongProxy is InitializableProductProxy, Constants {
    function productName() override public pure returns (bytes32) {
        return _LongOption_;
    }
}

contract ShortProxy is InitializableProductProxy, Constants {
    function productName() override public pure returns (bytes32) {
        return _ShortOption_;
    }
}


contract LongOption is ERC20UpgradeSafe {
    using SafeMath for uint;
    
    address public factory;
    address public creator;
    address public collateral;
    address public underlying;
    uint public strikePrice;
    uint public expiry;

    function initialize(address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry) external initializer {
        (string memory name, string memory symbol) = spellNameAndSymbol(_collateral, _underlying, _strikePrice, _expiry);
        __ERC20_init(name, symbol);
        _setupDecimals(ERC20UpgradeSafe(_collateral).decimals());

        factory = msg.sender;
        creator = _creator;
        collateral = _collateral;
        underlying = _underlying;
        strikePrice = _strikePrice;
        expiry = _expiry;
    }
    
    //function spellNameAndSymbol(address _collateral, address _underlying, uint _strikePrice, uint _expiry) public view returns (string memory name, string memory symbol) {
    function spellNameAndSymbol(address, address, uint, uint) public view returns (string memory name, string memory symbol) {
        //return ('Helmet.Insure ETH long put option strike 500 USDC or USDC long call option strike 0.002 ETH expiry 2020/10/10', 'USDC(0.002ETH)201010');
        return('Helmet.Insure Long Option Token', 'Long');
    }
    
    function setErc20Param(string memory name, string memory symbol, uint8 decimals) external {
        require(msg.sender == OptionFactory(factory).governor());
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }


    modifier onlyFactory {
        require(msg.sender == factory, 'Only Factory');
        _;
    }
    
    function mint_(address _to, uint volume) external onlyFactory {
        _mint(_to, volume);
    }
    
    function burn_(address _from, uint volume) external onlyFactory {
        _burn(_from, volume);
    }
    
    function burn(uint volume) external {
        _burn(msg.sender, volume);
    }
    function burn() external {
        _burn(msg.sender, balanceOf(msg.sender));
    }
    
    function exercise(uint volume, address[] memory path) public returns (uint vol, uint fee, uint amt) {
        return OptionFactory(factory).exercise_(msg.sender, creator, collateral, underlying, strikePrice, expiry, volume, path);
    }

    function exercise(uint volume) public returns (uint vol, uint fee, uint amt) {
        return exercise(volume, new address[](0));
    }

    function exercise(address[] calldata path) external returns (uint vol, uint fee, uint amt) {
        return exercise(balanceOf(msg.sender), path);
    }

    function exercise() external returns (uint vol, uint fee, uint amt) {
        return exercise(balanceOf(msg.sender), new address[](0));
    }
}

contract ShortOption is ERC20UpgradeSafe, Constants {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using HiLo for uint;
    
    address public factory;
    address public creator;
    address public collateral;
    address public underlying;
    uint public strikePrice;
    uint public expiry;

    function initialize(address _creator, address _collateral, address _underlying, uint _strikePrice, uint _expiry) external initializer {
        (string memory name, string memory symbol) = spellNameAndSymbol(_collateral, _underlying, _strikePrice, _expiry);
        __ERC20_init(name, symbol);
        _setupDecimals(ERC20UpgradeSafe(_collateral).decimals());

        factory = msg.sender;
        creator = _creator;
        collateral = _collateral;
        underlying = _underlying;
        strikePrice = _strikePrice;
        expiry = _expiry;
    }

    //function spellNameAndSymbol(address _collateral, address _underlying, uint _strikePrice, uint _expiry) public view returns (string memory name, string memory symbol) {
    function spellNameAndSymbol(address, address, uint, uint) public view returns (string memory name, string memory symbol) {
        //return ('Helmet.Insure ETH short put option strike 500 USDC or USDC short call option strike 0.002 ETH expiry 2020/10/10', 'USDC(0.002ETH)201010s');
        return('Helmet.Insure Short Option Token', 'Short');
    }

    function setErc20Param(string memory name, string memory symbol, uint8 decimals) external {
        require(msg.sender == OptionFactory(factory).governor());
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    modifier onlyFactory {
        require(msg.sender == factory, 'Only Factory');
        _;
    }
    
    function mint_(address _to, uint volume) external onlyFactory {
        _mint(_to, volume);
    }
    
    function burn_(address _from, uint volume) external onlyFactory {
        _burn(_from, volume);
        IERC20(collateral).safeTransfer(_from, volume);
    }
    
    function calcFee(uint volume) public view returns (address recipient, uint fee) {
        uint feeRate = OptionFactory(factory).getConfig(_feeRate_);
        recipient = address(OptionFactory(factory).getConfig(_feeRecipient_));
        
        if(feeRate != 0 && recipient != address(0))
            fee = volume.mul(feeRate).div(1 ether);
        else
            fee = 0;
    }
    
    function _payFee(uint volume) internal returns (uint) {
        (address recipient, uint fee) = calcFee(volume);
        if(recipient != address(0) && fee > 0)
            IERC20(collateral).safeTransfer(recipient, fee);
        return fee;
    }
    
    function exercise_(address buyer, uint volume) external onlyFactory returns (uint vol, uint fee) {
        fee = _payFee(volume);
        vol = volume.sub(fee);
        IERC20(collateral).safeTransfer(buyer, vol);
    }
    
    function settle_(address seller, uint volume) external onlyFactory returns (uint vol, uint col, uint fee, uint und) {
        return _settle(seller, volume);
    }
    
    function settleable(address seller) public view returns (uint vol, uint col, uint fee, uint und) {
        return settleable(balanceOf(seller));
    }
    
    function settleable(uint volume) public view returns (uint vol, uint col, uint fee, uint und) {
        uint colla = IERC20(collateral).balanceOf(address(this));
        uint under = IERC20(underlying).balanceOf(address(this));
        if(now <= expiry.lo()) {
            address long  = OptionFactory(factory).longs(creator, collateral, underlying, strikePrice, expiry);
            uint waived = colla.sub(IERC20(long).totalSupply());
            uint exercised = totalSupply().sub(colla);
            uint we = waived.add(exercised);
            if(we == 0)
                return (0, 0, 0, 0);
            vol = volume <= we ? volume : we;
            col = waived.mul(vol).div(we);
            und = under.mul(vol).div(we);
        } else {
            vol = volume <= totalSupply() ? volume : totalSupply();
            col = colla.mul(vol).div(totalSupply());
            und = under.mul(vol).div(totalSupply());
        }
        (, fee) = calcFee(col);
        col = col.sub(fee);
    }
    
    function _settle(address seller, uint volume) internal returns (uint vol, uint col, uint fee, uint und) {
        (vol, col, fee, und) = settleable(volume);
        _burn(seller, vol);
        _payFee(col.add(fee));
        IERC20(collateral).safeTransfer(seller, col);
        IERC20(underlying).safeTransfer(seller, und);
        OptionFactory(factory).emitSettle(seller, creator, collateral, underlying, strikePrice, expiry, vol, col, fee, und);
    }
    
    function settle(uint volume) external returns (uint vol, uint col, uint fee, uint und) {
        return _settle(msg.sender, volume);
    }
    
    function settle() external returns (uint vol, uint col, uint fee, uint und) {
        return _settle(msg.sender, balanceOf(msg.sender));
    }
}


library HiLo {
    function pack(uint hi, uint lo) internal pure returns (uint) {
        require(hi < 2**128 && lo < 2**128, 'UintHiLo.pack overflow');
        return hi << 128 | lo;
    }
    
    function hi(uint u) internal pure returns (uint) {
        return u >> 128;
    }
    
    function lo(uint u) internal pure returns (uint) {
        return uint128(u);
    }
}