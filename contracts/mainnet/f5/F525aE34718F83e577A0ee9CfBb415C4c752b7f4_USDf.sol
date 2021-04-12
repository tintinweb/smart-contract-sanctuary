/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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

pragma solidity ^0.6.0;


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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;






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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;


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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: contracts/gaia/usdf.sol

pragma solidity ^0.6.0;







interface TwapOracle {
    function update() external;
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function changePeriod(uint256 seconds_) external;
}

interface IGaia {
    function burn(address from, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

contract USDf is ERC20UpgradeSafe, OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;

    uint256 constant public MAX_RESERVE_RATIO = 100 * 10 ** 9;
    uint256 private constant DECIMALS = 9;
    uint256 private _lastRefreshReserve;
    uint256 private _minimumRefreshTime;
    uint256 public gaiaDecimals;
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private extraVar;
    uint256 private _totalSupply;
    uint256 private _mintFee;
    uint256 private _withdrawFee;
    uint256 private _minimumDelay;                        // how long a user must wait between actions
    uint256 public MIN_RESERVE_RATIO;
    uint256 private _reserveRatio;
    uint256 private _stepSize;

    address public gaia;            
    address public synthOracle;
    address public gaiaOracle;
    address public usdcAddress;
    
    address[] private collateralArray;

    AggregatorV3Interface internal usdcPrice;

    mapping(address => uint256) private _synthBalance;
    mapping(address => uint256) private _lastAction;
    mapping (address => mapping (address => uint256)) private _allowedSynth;
    mapping (address => bool) public acceptedCollateral;
    mapping (address => uint256) public collateralDecimals;
    mapping (address => address) public collateralOracle;
    mapping (address => bool) public seenCollateral;
    mapping (address => uint256) public _burnedSynth;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    modifier sync() {
        if (_totalSupply > 0) {
            updateOracles();

            if (now - _lastRefreshReserve >= _minimumRefreshTime) {
                TwapOracle(gaiaOracle).update();
                TwapOracle(synthOracle).update();
                if (getSynthOracle() > 1 * 10 ** 9) {
                    setReserveRatio(_reserveRatio.sub(_stepSize));
                } else {
                    setReserveRatio(_reserveRatio.add(_stepSize));
                }

                _lastRefreshReserve = now;
            }
        }
        
        _;
    }

    event NewReserveRate(uint256 reserveRatio);
    event Mint(address gaia, address receiver, address collateral, uint256 collateralAmount, uint256 gaiaAmount, uint256 synthAmount);
    event Withdraw(address gaia, address receiver, address collateral, uint256 collateralAmount, uint256 gaiaAmount, uint256 synthAmount);
    event NewMinimumRefreshTime(uint256 minimumRefreshTime);
    event MintFee(uint256 fee);
    event WithdrawFee(uint256 fee);
    event NewStepSize(uint256 stepSize);

    // constructor ============================================================
    function initialize(address gaia_, uint256 gaiaDecimals_, address usdcAddress_, address usdcOracleChainLink_) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();

        ERC20UpgradeSafe.__ERC20_init('USDf', 'USDf');
        ERC20UpgradeSafe._setupDecimals(9);

        gaia = gaia_;
        _minimumRefreshTime = 3600 * 1;      // 1 hours by default
        _minimumDelay = 5 * 60;              // 5 minutes or 300 seconds
        gaiaDecimals = gaiaDecimals_;
        usdcPrice = AggregatorV3Interface(usdcOracleChainLink_);
        usdcAddress = usdcAddress_;
        _reserveRatio = 100 * 10 ** 9;   // 100% reserve at first
        _totalSupply = 0;
        _stepSize = 1 * 10 ** 8;         // 0.1% step size

        MIN_RESERVE_RATIO = 99 * 10 ** 9;
    }

    // public view functions ============================================================
    function getCollateralByIndex(uint256 index_) external view returns (address) {
        return collateralArray[index_];
    }
    
    function stepSize() external view returns (uint256) {
        return _stepSize;
    }

    function burnedSynth(address user_) external view returns (uint256) {
        return _burnedSynth[user_];
    }

    function lastAction(address user_) external view returns (uint256) {
        return _lastAction[user_];
    }

    function getCollateralUsd(address collateral_) public view returns (uint256) {
        // price is $Y / USD (10 ** 8 decimals)
        ( , int price, , uint timeStamp, ) = usdcPrice.latestRoundData();
        require(timeStamp > 0, "Rounds not complete");

        if (address(collateral_) == address(usdcAddress)) {
            return uint256(price).mul(10);
        } else {
            return uint256(price).mul(10 ** 10).div((TwapOracle(collateralOracle[collateral_]).consult(usdcAddress, 10 ** 6)).mul(10 ** 9).div(10 ** collateralDecimals[collateral_]));
        }
    }

    function globalCollateralValue() public view returns (uint256) {
        uint256 totalCollateralUsd = 0; 

        for (uint i = 0; i < collateralArray.length; i++){ 
            // Exclude null addresses
            if (collateralArray[i] != address(0)){
                totalCollateralUsd += IERC20(collateralArray[i]).balanceOf(address(this)).mul(10 ** 9).div(10 ** collateralDecimals[collateralArray[i]]).mul(getCollateralUsd(collateralArray[i])).div(10 ** 9); // add stablecoin balance
            }
        }
        return totalCollateralUsd;
    }

    function usdfInfo() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            _totalSupply,
            _reserveRatio,
            globalCollateralValue(),
            _mintFee,
            _withdrawFee,
            _minimumDelay,
            getGaiaOracle(),
            getSynthOracle(),
            _lastRefreshReserve,
            _minimumRefreshTime
        );
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public override view returns (uint256) {
        return _synthBalance[who];
    }

    function allowance(address owner_, address spender) public override view returns (uint256) {
        return _allowedSynth[owner_][spender];
    }

    function getGaiaOracle() public view returns (uint256) {
        uint256 gaiaTWAP = TwapOracle(gaiaOracle).consult(usdcAddress, 1 * 10 ** 6);

        ( , int price, , uint timeStamp, ) = usdcPrice.latestRoundData();

        require(timeStamp > 0, "rounds not complete");

        return uint256(price).mul(10).mul(10 ** DECIMALS).div(gaiaTWAP);
    }

    function getSynthOracle() public view returns (uint256) {
        uint256 synthTWAP = TwapOracle(synthOracle).consult(usdcAddress, 1 * 10 ** 6);

        ( , int price, , uint timeStamp, ) = usdcPrice.latestRoundData();

        require(timeStamp > 0, "rounds not complete");

        return uint256(price).mul(10).mul(10 ** DECIMALS).div(synthTWAP);
    }

    function consultSynthRatio(uint256 synthAmount, address collateral) public view returns (uint256, uint256) {
        require(synthAmount != 0, "must use valid USDf amount");
        require(seenCollateral[collateral], "must be seen collateral");

        uint256 collateralAmount = synthAmount.mul(_reserveRatio).div(MAX_RESERVE_RATIO).mul(10 ** collateralDecimals[collateral]).div(10 ** DECIMALS);

        if (_totalSupply == 0) {
            return (collateralAmount, 0);
        } else {
            collateralAmount = collateralAmount.mul(10 ** 9).div(getCollateralUsd(collateral)); // get real time price
            uint256 gaiaUsd = getGaiaOracle();                         
            uint256 synthPrice = getSynthOracle();                      

            uint256 synthPart2 = synthAmount.mul(MAX_RESERVE_RATIO.sub(_reserveRatio)).div(MAX_RESERVE_RATIO);
            uint256 gaiaAmount = synthPart2.mul(synthPrice).div(gaiaUsd);

            return (collateralAmount, gaiaAmount);
        }
    }

    // public functions ============================================================
    function updateOracles() public {
        for (uint i = 0; i < collateralArray.length; i++) {
            if (acceptedCollateral[collateralArray[i]]) TwapOracle(collateralOracle[collateralArray[i]]).update();
        } 
    }

    function transfer(address to, uint256 value) public override validRecipient(to) sync() returns (bool) {
        _synthBalance[msg.sender] = _synthBalance[msg.sender].sub(value);
        _synthBalance[to] = _synthBalance[to].add(value);
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override validRecipient(to) sync() returns (bool) {
        _allowedSynth[from][msg.sender] = _allowedSynth[from][msg.sender].sub(value);

        _synthBalance[from] = _synthBalance[from].sub(value);
        _synthBalance[to] = _synthBalance[to].add(value);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public override sync() returns (bool) {
        _allowedSynth[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowedSynth[msg.sender][spender] = _allowedSynth[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedSynth[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedSynth[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedSynth[msg.sender][spender] = 0;
        } else {
            _allowedSynth[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedSynth[msg.sender][spender]);
        return true;
    }

    function mint(uint256 synthAmount, address collateral) public nonReentrant sync() {
        require(acceptedCollateral[collateral], "must be an accepted collateral");

        (uint256 collateralAmount, uint256 gaiaAmount) = consultSynthRatio(synthAmount, collateral);
        require(collateralAmount <= IERC20(collateral).balanceOf(msg.sender), "sender has insufficient collateral balance");
        require(gaiaAmount <= IERC20(gaia).balanceOf(msg.sender), "sender has insufficient gaia balance");

        SafeERC20.safeTransferFrom(IERC20(collateral), msg.sender, address(this), collateralAmount);

        if (gaiaAmount != 0) IGaia(gaia).burn(msg.sender, gaiaAmount);

        synthAmount = synthAmount.sub(synthAmount.mul(_mintFee).div(100 * 10 ** DECIMALS));

        _totalSupply = _totalSupply.add(synthAmount);
        _synthBalance[msg.sender] = _synthBalance[msg.sender].add(synthAmount);

        emit Transfer(address(0x0), msg.sender, synthAmount);
        emit Mint(gaia, msg.sender, collateral, collateralAmount, gaiaAmount, synthAmount);
    }

    function withdraw(uint256 synthAmount) public nonReentrant sync() {
        require(synthAmount == 0, "temporarily disabled");
        require(synthAmount <= _synthBalance[msg.sender], "insufficient balance");

        _totalSupply = _totalSupply.sub(synthAmount);
        _synthBalance[msg.sender] = _synthBalance[msg.sender].sub(synthAmount);

        // record keeping
        _burnedSynth[msg.sender] = _burnedSynth[msg.sender].add(synthAmount);

        _lastAction[msg.sender] = now;

        emit Transfer(msg.sender, address(0x0), synthAmount);
    }

    function completeWithdrawal(address collateral, uint256 synthAmount) public nonReentrant sync() {
        require(now.sub(_lastAction[msg.sender]) > _minimumDelay, "action too soon");
        require(seenCollateral[collateral], "invalid collateral");
        require(synthAmount != 0);
        require(synthAmount <= _burnedSynth[msg.sender]);

        _burnedSynth[msg.sender] = _burnedSynth[msg.sender].sub(synthAmount);

        (uint256 collateralAmount, uint256 gaiaAmount) = consultSynthRatio(synthAmount, collateral);

        collateralAmount = collateralAmount.sub(collateralAmount.mul(_withdrawFee).div(100 * 10 ** DECIMALS));
        gaiaAmount = gaiaAmount.sub(gaiaAmount.mul(_withdrawFee).div(100 * 10 ** DECIMALS));

        require(collateralAmount <= IERC20(collateral).balanceOf(address(this)), "insufficient collateral");

        SafeERC20.safeTransfer(IERC20(collateral), msg.sender, collateralAmount);
        if (gaiaAmount != 0) IGaia(gaia).mint(msg.sender, gaiaAmount);

        _lastAction[msg.sender] = now;

        emit Withdraw(gaia, msg.sender, collateral, collateralAmount, gaiaAmount, synthAmount);
    }

    // governance functions ============================================================
    function burnGaia(uint256 amount) external onlyOwner {
        require(amount <= IERC20(gaia).balanceOf(msg.sender));
        IGaia(gaia).burn(msg.sender, amount);
    }

    function setBurnedSynth(address user_, uint256 value_) external onlyOwner {
        _burnedSynth[user_] = value_;
    }

    function setDelay(uint256 val_) external onlyOwner {
        _minimumDelay = val_;
    }

    function setStepSize(uint256 _step) external onlyOwner {
        _stepSize = _step;
        emit NewStepSize(_step);
    }

    // function used to add
    function addCollateral(address collateral_, uint256 collateralDecimal_, address oracleAddress_) external onlyOwner {
        collateralArray.push(collateral_);
        acceptedCollateral[collateral_] = true;
        seenCollateral[collateral_] = true;
        collateralDecimals[collateral_] = collateralDecimal_;
        collateralOracle[collateral_] = oracleAddress_;
    }

    function setCollateralOracle(address collateral_, address oracleAddress_) external onlyOwner {
        collateralOracle[collateral_] = oracleAddress_;
    }

    function removeCollateral(address collateral_) external onlyOwner {
        delete acceptedCollateral[collateral_];
        delete collateralOracle[collateral_];

        for (uint i = 0; i < collateralArray.length; i++){ 
            if (collateralArray[i] == collateral_) {
                collateralArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
    }

    function setSynthOracle(address oracle_) external onlyOwner returns (bool)  {
        synthOracle = oracle_;
        
        return true;
    }

    function setGaiaOracle(address oracle_) external onlyOwner returns (bool) {
        gaiaOracle = oracle_;

        return true;
    }

    function editMintFee(uint256 fee_) external onlyOwner {
        _mintFee = fee_;
        emit MintFee(fee_);
    }

    function editWithdrawFee(uint256 fee_) external onlyOwner {
        _withdrawFee = fee_;
        emit WithdrawFee(fee_);
    }

    function setSeenCollateral(address collateral_, bool val_) external onlyOwner {
        seenCollateral[collateral_] = val_;
    }

    function setMinReserveRate(uint256 rate_) external onlyOwner {
        require(rate_ != 0);
        require(rate_ <= 100 * 10 ** 9, "rate high");

        MIN_RESERVE_RATIO = rate_;
    }

    function setReserveRatioAdmin(uint256 newRatio_) external onlyOwner {
        require(newRatio_ != 0);

        if (newRatio_ >= MIN_RESERVE_RATIO && newRatio_ <= MAX_RESERVE_RATIO) {
            _reserveRatio = newRatio_;
            emit NewReserveRate(_reserveRatio);
        }
    }

    function setMinimumRefreshTime(uint256 val_) external onlyOwner returns (bool) {
        require(val_ != 0);

        _minimumRefreshTime = val_;

        for (uint i = 0; i < collateralArray.length; i++) {
            if (acceptedCollateral[collateralArray[i]]) TwapOracle(collateralOracle[collateralArray[i]]).changePeriod(val_);
        }

        emit NewMinimumRefreshTime(val_);
        return true;
    }

    // multi-purpose function for investing, managing treasury
    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public payable onlyOwner returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success);

        return returnData;
    }

    // internal private functions ============================================================
    function setReserveRatio(uint256 newRatio_) private {
        require(newRatio_ != 0);

        if (newRatio_ >= MIN_RESERVE_RATIO && newRatio_ <= MAX_RESERVE_RATIO) {
            _reserveRatio = newRatio_;
            emit NewReserveRate(_reserveRatio);
        }
    }
}