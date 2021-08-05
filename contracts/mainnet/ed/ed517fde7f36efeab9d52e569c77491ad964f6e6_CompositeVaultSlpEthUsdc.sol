/**
 *Submitted for verification at Etherscan.io on 2020-11-19
*/

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

interface Converter {
    function convert(address) external returns (uint);
}

interface ICompositeVault {
    function cap() external view returns (uint);
    function getConverter() external view returns (address);
    function getVaultMaster() external view returns (address);
    function balance() external view returns (uint);
    function tvl() external view returns (uint); // total dollar value
    function token() external view returns (address);
    function available() external view returns (uint);
    function accept(address _input) external view returns (bool);

    function earn() external;
    function harvest(address reserve, uint amount) external;
    function addNewCompound(uint, uint) external;

    function withdraw_fee(uint _shares) external view returns (uint);
    function calc_token_amount_deposit(address _input, uint _amount) external view returns (uint);
    function calc_add_liquidity(uint _amount0, uint _amount1) external view returns (uint);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint);
    function calc_remove_liquidity(uint _shares) external view returns (uint _amount0, uint _amount1);

    function getPricePerFullShare() external view returns (uint);
    function get_virtual_price() external view returns (uint); // average dollar value of vault share token


    function deposit(address _input, uint _amount, uint _min_mint_amount) external returns (uint);
    function depositFor(address _account, address _to, address _input, uint _amount, uint _min_mint_amount) external returns (uint _mint_amount);
    function addLiquidity(uint _amount0, uint _amount1, uint _min_mint_amount) external returns (uint);
    function addLiquidityFor(address _account, address _to, uint _amount0, uint _amount1, uint _min_mint_amount) external returns (uint _mint_amount);
    function withdraw(uint _shares, address _output, uint _min_output_amount) external returns (uint);
    function withdrawFor(address _account, uint _shares, address _output, uint _min_output_amount) external returns (uint _output_amount);

    function harvestStrategy(address _strategy) external;
    function harvestAllStrategies() external;
}

interface IVaultMaster {
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

interface IController {
    function vault() external view returns (address);

    function strategyLength() external view returns (uint);
    function strategyBalance() external view returns (uint);

    function getStrategyCount() external view returns(uint);
    function strategies(uint _stratId) external view returns (address _strategy, uint _quota, uint _percent);
    function getBestStrategy() external view returns (address _strategy);

    function want() external view returns (address);

    function balanceOf() external view returns (uint);
    function withdraw_fee(uint _amount) external view returns (uint); // eg. 3CRV => pJar: 0.5% (50/10000)
    function investDisabled() external view returns (bool);

    function withdraw(uint) external returns (uint _withdrawFee);
    function earn(address _token, uint _amount) external;

    function harvestStrategy(address _strategy) external;
    function harvestAllStrategies() external;
}

interface ILpPairConverter {
    function lpPair() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);

    function accept(address _input) external view returns (bool);
    function get_virtual_price() external view returns (uint);

    function convert_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);
    function calc_add_liquidity(uint _amount0, uint _amount1) external view returns (uint);
    function calc_remove_liquidity(uint _shares) external view returns (uint _amount0, uint _amount1);

    function convert(address _input, address _output, address _to) external returns (uint _outputAmount);
    function add_liquidity(address _to) external returns (uint _outputAmount);
    function remove_liquidity(address _to) external returns (uint _amount0, uint _amount1);
}

abstract contract CompositeVaultBase is ERC20UpgradeSafe, ICompositeVault {
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public basedToken;

    IERC20 public token0;
    IERC20 public token1;

    uint public min = 9500;
    uint public constant max = 10000;

    uint public earnLowerlimit = 1; // minimum to invest
    uint public depositLimit = 0; // limit for each deposit (set 0 to disable)
    uint private totalDepositCap = 0; // initial cap (set 0 to disable)

    address public governance;
    address public controller;

    IVaultMaster vaultMaster;
    ILpPairConverter public basedConverter; // converter for basedToken (SLP or BPT or UNI)

    mapping(address => address) public converterMap; // non-core token => converter

    bool public acceptContractDepositor = false;
    mapping(address => bool) public whitelistedContract;
    bool private _mutex;

    uint public totalPendingCompound;
    uint public startReleasingCompoundBlk;
    uint public endReleasingCompoundBlk;

    function initialize(IERC20 _basedToken, IERC20 _token0, IERC20 _token1, IVaultMaster _vaultMaster) public initializer {
        __ERC20_init(_getName(), _getSymbol());
        basedToken = _basedToken;
        token0 = _token0;
        token1 = _token1;
        vaultMaster = _vaultMaster;
        governance = msg.sender;
    }

    function _getName() internal virtual view returns (string memory);

    function _getSymbol() internal virtual view returns (string memory);

    /**
     * @dev Throws if called by a not-whitelisted contract while we do not accept contract depositor.
     */
    modifier checkContract(address _account) {
        if (!acceptContractDepositor && !whitelistedContract[_account]) {
            require(!address(_account).isContract() && _account == tx.origin, "contract not support");
        }
        _;
    }

    modifier _non_reentrant_() {
        require(!_mutex, "reentry");
        _mutex = true;
        _;
        _mutex = false;
    }

    function setAcceptContractDepositor(bool _acceptContractDepositor) external {
        require(msg.sender == governance, "!governance");
        acceptContractDepositor = _acceptContractDepositor;
    }

    function whitelistContract(address _contract) external {
        require(msg.sender == governance, "!governance");
        whitelistedContract[_contract] = true;
    }

    function unwhitelistContract(address _contract) external {
        require(msg.sender == governance, "!governance");
        whitelistedContract[_contract] = false;
    }

    function cap() external override view returns (uint) {
        return totalDepositCap;
    }

    function getConverter() external override view returns (address) {
        return address(basedConverter);
    }

    function getVaultMaster() external override view returns (address) {
        return address(vaultMaster);
    }

    function accept(address _input) external override view returns (bool) {
        return basedConverter.accept(_input);
    }

    function addNewCompound(uint _newCompound, uint _blocksToReleaseCompound) external override {
        require(msg.sender == governance || vaultMaster.isStrategy(msg.sender), "!authorized");
        if (_blocksToReleaseCompound == 0) {
            totalPendingCompound = 0;
            startReleasingCompoundBlk = 0;
            endReleasingCompoundBlk = 0;
        } else {
            totalPendingCompound = pendingCompound().add(_newCompound);
            startReleasingCompoundBlk = block.number;
            endReleasingCompoundBlk = block.number.add(_blocksToReleaseCompound);
        }
    }

    function pendingCompound() public view returns (uint) {
        if (totalPendingCompound == 0 || endReleasingCompoundBlk <= block.number) return 0;
        return totalPendingCompound.mul(endReleasingCompoundBlk.sub(block.number)).div(endReleasingCompoundBlk.sub(startReleasingCompoundBlk).add(1));
    }

    function balance() public override view returns (uint _balance) {
        _balance = basedToken.balanceOf(address(this)).add(IController(controller).balanceOf()).sub(pendingCompound());
    }

    function tvl() public override view returns (uint) {
        return balance().mul(basedConverter.get_virtual_price()).div(1e18);
    }

    function setMin(uint _min) external {
        require(msg.sender == governance, "!governance");
        min = _min;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        require(IController(_controller).want() == address(basedToken), "!token");
        controller = _controller;
    }

    function setConverter(ILpPairConverter _converter) external {
        require(msg.sender == governance, "!governance");
        require(_converter.lpPair() == address(basedToken), "!token");
        basedConverter = _converter;
    }

    function setConverterMap(address _token, address _converter) external {
        require(msg.sender == governance, "!governance");
        converterMap[_token] = _converter;
    }

    function setVaultMaster(IVaultMaster _vaultMaster) external {
        require(msg.sender == governance, "!governance");
        vaultMaster = _vaultMaster;
    }

    function setEarnLowerlimit(uint _earnLowerlimit) external {
        require(msg.sender == governance, "!governance");
        earnLowerlimit = _earnLowerlimit;
    }

    function setCap(uint _cap) external {
        require(msg.sender == governance, "!governance");
        totalDepositCap = _cap;
    }

    function setDepositLimit(uint _limit) external {
        require(msg.sender == governance, "!governance");
        depositLimit = _limit;
    }

    function token() public override view returns (address) {
        return address(basedToken);
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public override view returns (uint) {
        return basedToken.balanceOf(address(this)).mul(min).div(max);
    }

    function earn() public override {
        if (controller != address(0)) {
            IController _contrl = IController(controller);
            if (!_contrl.investDisabled()) {
                uint _bal = available();
                if (_bal >= earnLowerlimit) {
                    basedToken.safeTransfer(controller, _bal);
                    _contrl.earn(address(basedToken), _bal);
                }
            }
        }
    }

    // Only allows to earn some extra yield from non-core tokens
    function earnExtra(address _token) external {
        require(msg.sender == governance, "!governance");
        require(converterMap[_token] != address(0), "!converter");
        require(address(_token) != address(basedToken), "token");
        require(address(_token) != address(this), "share");
        uint _amount = IERC20(_token).balanceOf(address(this));
        address _converter = converterMap[_token];
        IERC20(_token).safeTransfer(_converter, _amount);
        Converter(_converter).convert(_token);
    }

    function withdraw_fee(uint _shares) public override view returns (uint) {
        return (controller == address(0)) ? 0 : IController(controller).withdraw_fee(_shares);
    }

    function calc_token_amount_deposit(address _input, uint _amount) external override view returns (uint) {
        return basedConverter.convert_rate(_input, address(basedToken), _amount).mul(1e18).div(getPricePerFullShare());
    }

    function calc_add_liquidity(uint _amount0, uint _amount1) external override view returns (uint) {
        return basedConverter.calc_add_liquidity(_amount0, _amount1).mul(1e18).div(getPricePerFullShare());
    }

    function _calc_shares_to_amount_withdraw(uint _shares) internal view returns (uint) {
        uint _withdrawFee = withdraw_fee(_shares);
        if (_withdrawFee > 0) {
            _shares = _shares.sub(_withdrawFee);
        }
        uint _totalSupply = totalSupply();
        return (_totalSupply == 0) ? _shares : (balance().mul(_shares)).div(_totalSupply);
    }

    function calc_token_amount_withdraw(uint _shares, address _output) external override view returns (uint) {
        uint r = _calc_shares_to_amount_withdraw(_shares);
        if (_output != address(basedToken)) {
            r = basedConverter.convert_rate(address(basedToken), _output, r);
        }
        return r.mul(getPricePerFullShare()).div((1e18));
    }

    function calc_remove_liquidity(uint _shares) external override view returns (uint _amount0, uint _amount1) {
        uint r = _calc_shares_to_amount_withdraw(_shares);
        (_amount0, _amount1) = basedConverter.calc_remove_liquidity(r);
        uint _getPricePerFullShare = getPricePerFullShare();
        _amount0 = _amount0.mul(_getPricePerFullShare).div((1e18));
        _amount1 = _amount1.mul(_getPricePerFullShare).div((1e18));
    }

    function deposit(address _input, uint _amount, uint _min_mint_amount) external override returns (uint) {
        return depositFor(msg.sender, msg.sender, _input, _amount, _min_mint_amount);
    }

    function depositFor(address _account, address _to, address _input, uint _amount, uint _min_mint_amount) public override checkContract(_account) _non_reentrant_ returns (uint _mint_amount) {
        require(msg.sender == _account || msg.sender == vaultMaster.bank(address(this)), "!bank && !yourself");
        uint _pool = balance();
        require(totalDepositCap == 0 || _pool <= totalDepositCap, ">totalDepositCap");
        uint _before = basedToken.balanceOf(address(this));
        if (_input == address(basedToken)) {
            basedToken.safeTransferFrom(_account, address(this), _amount);
        } else {
            // require(basedConverter.convert_rate(_input, address(basedToken), _amount) > 0, "rate=0");
            uint _before0 = token0.balanceOf(address(this));
            uint _before1 = token1.balanceOf(address(this));
            IERC20(_input).safeTransferFrom(_account, address(basedConverter), _amount);
            uint _after0 = token0.balanceOf(address(this));
            uint _after1 = token1.balanceOf(address(this));
            if (_after0 > _before0) {
                token0.safeTransfer(_account, _after0.sub(_before0));
            }
            if (_after1 > _before1) {
                token1.safeTransfer(_account, _after1.sub(_before1));
            }
            basedConverter.convert(_input, address(basedToken), address(this));
        }
        uint _after = basedToken.balanceOf(address(this));
        _amount = _after.sub(_before); // additional check for deflationary tokens
        require(depositLimit == 0 || _amount <= depositLimit, ">depositLimit");
        require(_amount > 0, "no token");
        _mint_amount = _deposit(_to, _pool, _amount);
        require(_mint_amount >= _min_mint_amount, "slippage");
    }

    function addLiquidity(uint _amount0, uint _amount1, uint _min_mint_amount) external override returns (uint) {
        return addLiquidityFor(msg.sender, msg.sender, _amount0, _amount1, _min_mint_amount);
    }

    function addLiquidityFor(address _account, address _to, uint _amount0, uint _amount1, uint _min_mint_amount) public override checkContract(_account) _non_reentrant_ returns (uint _mint_amount) {
        require(msg.sender == _account || msg.sender == vaultMaster.bank(address(this)), "!bank && !yourself");
        uint _pool = balance();
        require(totalDepositCap == 0 || _pool <= totalDepositCap, ">totalDepositCap");
        uint _beforeToken = basedToken.balanceOf(address(this));
        uint _before0 = token0.balanceOf(address(this));
        uint _before1 = token1.balanceOf(address(this));
        token0.safeTransferFrom(_account, address(basedConverter), _amount0);
        token1.safeTransferFrom(_account, address(basedConverter), _amount1);
        basedConverter.add_liquidity(address(this));
        uint _afterToken = basedToken.balanceOf(address(this));
        uint _after0 = token0.balanceOf(address(this));
        uint _after1 = token1.balanceOf(address(this));
        uint _totalDepositAmount = _afterToken.sub(_beforeToken); // additional check for deflationary tokens
        require(depositLimit == 0 || _totalDepositAmount <= depositLimit, ">depositLimit");
        require(_totalDepositAmount > 0, "no token");
        if (_after0 > _before0) {
            token0.safeTransfer(_account, _after0.sub(_before0));
        }
        if (_after1 > _before1) {
            token1.safeTransfer(_account, _after1.sub(_before1));
        }
        _mint_amount = _deposit(_to, _pool, _totalDepositAmount);
        require(_mint_amount >= _min_mint_amount, "slippage");
    }

    function _deposit(address _mintTo, uint _pool, uint _amount) internal returns (uint _shares) {
        if (totalSupply() == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount.mul(totalSupply())).div(_pool);
        }

        if (_shares > 0) {
            earn();
            _mint(_mintTo, _shares);
        }
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint amount) external override {
        require(msg.sender == controller, "!controller");
        require(reserve != address(basedToken), "basedToken");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    function harvestStrategy(address _strategy) external override {
        require(msg.sender == governance || msg.sender == vaultMaster.bank(address(this)), "!governance && !bank");
        IController(controller).harvestStrategy(_strategy);
    }

    function harvestAllStrategies() external override {
        require(msg.sender == governance || msg.sender == vaultMaster.bank(address(this)), "!governance && !bank");
        IController(controller).harvestAllStrategies();
    }

    function withdraw(uint _shares, address _output, uint _min_output_amount) external override returns (uint) {
        return withdrawFor(msg.sender, _shares, _output, _min_output_amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdrawFor(address _account, uint _shares, address _output, uint _min_output_amount) public override _non_reentrant_ returns (uint _output_amount) {
        _output_amount = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        uint _withdrawalProtectionFee = vaultMaster.withdrawalProtectionFee();
        if (_withdrawalProtectionFee > 0) {
            uint _withdrawalProtection = _output_amount.mul(_withdrawalProtectionFee).div(10000);
            _output_amount = _output_amount.sub(_withdrawalProtection);
        }

        // Check balance
        uint b = basedToken.balanceOf(address(this));
        if (b < _output_amount) {
            uint _toWithdraw = _output_amount.sub(b);
            uint _withdrawFee = IController(controller).withdraw(_toWithdraw);
            uint _after = basedToken.balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _toWithdraw) {
                _output_amount = b.add(_diff);
            }
            if (_withdrawFee > 0) {
                _output_amount = _output_amount.sub(_withdrawFee, "_output_amount < _withdrawFee");
            }
        }

        if (_output == address(basedToken)) {
            require(_output_amount >= _min_output_amount, "slippage");
            basedToken.safeTransfer(_account, _output_amount);
        } else {
            // require(basedConverter.convert_rate(address(basedToken), _output, _output_amount) > 0, "rate=0");
            uint _received = basedConverter.convert(address(basedToken), _output, msg.sender);
            require(_received >= _min_output_amount, "slippage");
            IERC20(_output).safeTransfer(_account, _received);
        }
    }

    function getPricePerFullShare() public override view returns (uint) {
        return (totalSupply() == 0) ? 1e18 : balance().mul(1e18).div(totalSupply());
    }

    // @dev average dollar value of vault share token
    function get_virtual_price() external override view returns (uint) {
        return basedConverter.get_virtual_price().mul(getPricePerFullShare()).div(1e18);
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(IERC20 _token, uint amount, address to) external {
        require(msg.sender == governance, "!governance");
        require(address(_token) != address(basedToken), "token");
        require(address(_token) != address(this), "share");
        _token.safeTransfer(to, amount);
    }
}

contract CompositeVaultSlpEthUsdc is CompositeVaultBase {
    function _getName() internal override view returns (string memory) {
        return "CompositeVault:SlpEthUsdc";
    }

    function _getSymbol() internal override view returns (string memory) {
        return "cvETH-USDC:BPT";
    }
}