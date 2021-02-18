/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

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
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
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

// File: contracts/token/ISimpleToken.sol

pragma solidity 0.6.12;


/** Interface for any Siren SimpleToken
 */
interface ISimpleToken is IERC20 {
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function selfDestructToken(address payable refundAddress) external;
}

// File: contracts/market/IMarket.sol

pragma solidity 0.6.12;



/** Interface for any Siren Market
 */
interface IMarket {
    /** Tracking the different states of the market */
    enum MarketState {
        /**
         * New options can be created
         * Redemption token holders can redeem their options for collateral
         * Collateral token holders can't do anything
         */
        OPEN,
        /**
         * No new options can be created
         * Redemption token holders can't do anything
         * Collateral tokens holders can re-claim their collateral
         */
        EXPIRED,
        /**
         * 180 Days after the market has expired, it will be set to a closed state.
         * Once it is closed, the owner can sweep any remaining tokens and destroy the contract
         * No new options can be created
         * Redemption token holders can't do anything
         * Collateral tokens holders can't do anything
         */
        CLOSED
    }

    /** Specifies the manner in which options can be redeemed */
    enum MarketStyle {
        /**
         * Options can only be redeemed 30 minutes prior to the option's expiration date
         */
        EUROPEAN_STYLE,
        /**
         * Options can be redeemed any time between option creation
         * and the option's expiration date
         */
        AMERICAN_STYLE
    }

    function state() external view returns (MarketState);

    function mintOptions(uint256 collateralAmount) external;

    function calculatePaymentAmount(uint256 collateralAmount)
        external
        view
        returns (uint256);

    function calculateFee(uint256 amount, uint16 basisPoints)
        external
        pure
        returns (uint256);

    function exerciseOption(uint256 collateralAmount) external;

    function claimCollateral(uint256 collateralAmount) external;

    function closePosition(uint256 collateralAmount) external;

    function recoverTokens(IERC20 token) external;

    function selfDestructMarket(address payable refundAddress) external;

    function updateRestrictedMinter(address _restrictedMinter) external;

    function marketName() external view returns (string memory);

    function priceRatio() external view returns (uint256);

    function expirationDate() external view returns (uint256);

    function collateralToken() external view returns (IERC20);

    function wToken() external view returns (ISimpleToken);

    function bToken() external view returns (ISimpleToken);

    function updateImplementation(address newImplementation) external;

    function initialize(
        string calldata _marketName,
        address _collateralToken,
        address _paymentToken,
        MarketStyle _marketStyle,
        uint256 _priceRatio,
        uint256 _expirationDate,
        uint16 _exerciseFeeBasisPoints,
        uint16 _closeFeeBasisPoints,
        uint16 _claimFeeBasisPoints,
        address _tokenImplementation
    ) external;
}

// File: contracts/market/IMarketsRegistry.sol

pragma solidity 0.6.12;



/** Interface for any Siren MarketsRegistry
 */
interface IMarketsRegistry {
    // function state() external view returns (MarketState);

    function markets(string calldata marketName)
        external
        view
        returns (address);

    function getMarketsByAssetPair(bytes32 assetPair)
        external
        view
        returns (address[] memory);

    function amms(bytes32 assetPair) external view returns (address);

    function initialize(
        address _tokenImplementation,
        address _marketImplementation,
        address _ammImplementation
    ) external;

    function updateTokenImplementation(address newTokenImplementation) external;

    function updateMarketImplementation(address newMarketImplementation)
        external;

    function updateAmmImplementation(address newAmmImplementation) external;

    function updateMarketsRegistryImplementation(
        address newMarketsRegistryImplementation
    ) external;

    function createMarket(
        string calldata _marketName,
        address _collateralToken,
        address _paymentToken,
        IMarket.MarketStyle _marketStyle,
        uint256 _priceRatio,
        uint256 _expirationDate,
        uint16 _exerciseFeeBasisPoints,
        uint16 _closeFeeBasisPoints,
        uint16 _claimFeeBasisPoints,
        address _amm
    ) external returns (address);

    function createAmm(
        AggregatorV3Interface _priceOracle,
        IERC20 _paymentToken,
        IERC20 _collateralToken,
        uint16 _tradeFeeBasisPoints,
        bool _shouldInvertOraclePrice
    ) external returns (address);

    function selfDestructMarket(IMarket market, address payable refundAddress)
        external;

    function updateImplementationForMarket(
        IMarket market,
        address newMarketImplementation
    ) external;

    function recoverTokens(IERC20 token, address destination) external;
}

// File: contracts/proxy/Proxiable.sol

pragma solidity 0.6.12;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    event CodeAddressUpdated(address newAddress);

    function _updateCodeAddress(address newAddress) internal {
        require(
            bytes32(PROXY_MEM_SLOT) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, newAddress)
        }

        emit CodeAddressUpdated(newAddress);
    }

    function getLogicAddress() public view returns (address logicAddress) {
        assembly {
            // solium-disable-line
            logicAddress := sload(PROXY_MEM_SLOT)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return bytes32(PROXY_MEM_SLOT);
    }
}

// File: contracts/proxy/Proxy.sol

pragma solidity 0.6.12;

contract Proxy {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT = 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    constructor(address contractLogic) public {
        // Verify a valid address was passed in
        require(contractLogic != address(0), "Contract Logic cannot be 0x0");

        // save the code address
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, contractLogic)
        }
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(PROXY_MEM_SLOT)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                ptr,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(ptr, 0, retSz)
            switch success
                case 0 {
                    revert(ptr, retSz)
                }
                default {
                    return(ptr, retSz)
                }
        }
    }
}

// File: contracts/libraries/Math.sol

pragma solidity 0.6.12;

// a library for performing various math operations

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        return b;
    }
}

// File: contracts/amm/InitializeableAmm.sol

pragma solidity 0.6.12;




interface InitializeableAmm {
    function initialize(
        IMarketsRegistry _registry,
        AggregatorV3Interface _priceOracle,
        IERC20 _paymentToken,
        IERC20 _collateralToken,
        address _tokenImplementation,
        uint16 _tradeFeeBasisPoints,
        bool _shouldInvertOraclePrice
    ) external;

    function transferOwnership(address newOwner) external;
}

// File: contracts/amm/MinterAmm.sol

pragma solidity 0.6.12;












/**
This is an implementation of a minting/redeeming AMM that trades a list of markets with the same
collateral and payment assets. For example, a single AMM contract can trade all strikes of WBTC/USDC calls

It uses on-chain Black-Scholes approximation and an Oracle price feed to calculate price of an option.
It then uses this price to bootstrap a constant product bonding curve to calculate slippage for a particular trade
given the amount of liquidity in the pool.

External users can buy bTokens with collateral (wToken trading is disabled in this version).
When they do this, the AMM will mint new bTokens and wTokens, sell off the side the user doesn't want,
and return value to the user.

External users can sell bTokens for collateral. When they do this, the AMM will sell a partial amount of assets
to get a 50/50 split between bTokens and wTokens, then redeem them for collateral and send back to the user.

LPs can provide collateral for liquidity. All collateral will be used to mint bTokens/wTokens for each trade.
They will be given a corresponding amount of lpTokens to track ownership. The amount of lpTokens is calculated based on
total pool value which includes collateral token, payment token, active b/wTokens and expired/unclaimed b/wTokens

LPs can withdraw collateral from liquidity. When withdrawing user can specify if they want their pro-rata b/wTokens
to be automatically sold to the pool for collateral. If the chose not to sell then they get pro-rata of all tokens
in the pool (collateral, payment, bToken, wToken). If they chose to sell then their bTokens and wTokens will be sold
to the pool for collateral incurring slippage.

All expired unclaimed wTokens are automatically claimed on each deposit or withdrawal

All conversions between bToken and wToken in the AMM will generate fees that will be send to the protocol fees pool
(disabled in this version)
 */
contract MinterAmm is InitializeableAmm, OwnableUpgradeSafe, Proxiable {
    /** Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;
    using SafeERC20 for ISimpleToken;
    /** Use safe math for uint256 */
    using SafeMath for uint256;

    /** @dev The token contract that will track lp ownership of the AMM */
    ISimpleToken public lpToken;

    /** @dev The ERC20 tokens used by all the Markets associated with this AMM */
    IERC20 public collateralToken;
    IERC20 public paymentToken;
    uint8 internal collateralDecimals;
    uint8 internal paymentDecimals;

    /** @dev The registry which the AMM will use to lookup individual Markets */
    IMarketsRegistry public registry;

    /** @dev The oracle used to fetch the most recent on-chain price of the collateralToken */
    AggregatorV3Interface internal priceOracle;

    /** @dev deprecated: this parameter does not work with large decimal collateralToken, and
     * so we inlined the logic
     */
    uint256 internal paymentAndCollateralConversionFactor;

    /** @dev Chainlink does not give inverse price pairs (i.e. it only gives a BTC / USD price of $14000, not
     * a USD / BTC price of 1 / 14000. Sidenote: yes it is confusing that their BTC / USD price is actually in
     * the inverse units of USD per BTC... but here we are!). So the initializer needs to specify if the price
     * oracle's units match the AMM's price calculation units (in which case shouldInvertOraclePrice == false).
     *
     * Example: If collateralToken == WBTC, and paymentToken = USDC, and we're using the Chainlink price oracle
     * with the .description() == 'BTC / USD', and latestAnswer = 1400000000000 ($14000) then
     * shouldInvertOraclePrice should equal false. If the collateralToken and paymentToken variable values are
     * switched, and we're still using the price oracle 'BTC / USD' (because remember, there is no inverse price
     * oracle) then shouldInvertOraclePrice should equal true.
     */
    bool internal shouldInvertOraclePrice;

    /** @dev Fees on trading */
    uint16 public tradeFeeBasisPoints;

    /** Volatility factor used in the black scholes approximation - can be updated by the owner */
    uint256 public volatilityFactor;

    /** @dev Flag to ensure initialization can only happen once */
    bool initialized = false;

    /** @dev This is the keccak256 hash of the concatenation of the collateral and
     * payment token address used to look up the markets in the registry
     */
    bytes32 public assetPair;

    /** Track whether enforcing deposit limits is turned on.  The Owner can update this. */
    bool public enforceDepositLimits;

    /** Amount that accounts are allowed to deposit if enforcement is turned on */
    uint256 public globalDepositLimit;

    uint256 public constant MINIMUM_TRADE_SIZE = 1000;

    /** Struct to track how whether user is allowed to deposit and the current amount they already have deposited */
    struct LimitAmounts {
        bool allowedToDeposit;
        uint256 currentDeposit;
    }

    /**
     * DISABLED: This variable is no longer being used, but is left it to support backwards compatibility of
     * updating older contracts if needed.  This variable can be removed once all historical contracts are updated.
     * If this variable is removed and an existing contract is graded, it will corrupt the memory layout.
     *
     * Mapping to track deposit limits.
     * This is intended to be a temporary feature and will only count amounts deposited by an LP.
     * If they withdraw collateral, it will not be subtracted from their current deposit limit to
     * free up collateral that they can deposit later.
     */
    mapping(address => LimitAmounts) public collateralDepositLimits;

    /** Emitted when the owner updates the enforcement flag */
    event EnforceDepositLimitsUpdated(bool isEnforced, uint256 globalLimit);

    /** Emitted when a deposit allowance is updated */
    event DepositAllowedUpdated(address lpAddress, bool allowed);

    /** Emitted when the amm is created */
    event AMMInitialized(ISimpleToken lpToken, address priceOracle);

    /** Emitted when an LP deposits collateral */
    event LpTokensMinted(
        address minter,
        uint256 collateralAdded,
        uint256 lpTokensMinted
    );

    /** Emitted when an LP withdraws collateral */
    event LpTokensBurned(
        address redeemer,
        uint256 collateralRemoved,
        uint256 paymentRemoved,
        uint256 lpTokensBurned
    );

    /** Emitted when a user buys bTokens from the AMM*/
    event BTokensBought(
        address buyer,
        uint256 bTokensBought,
        uint256 collateralPaid
    );

    /** Emitted when a user sells bTokens to the AMM */
    event BTokensSold(
        address seller,
        uint256 bTokensSold,
        uint256 collateralPaid
    );

    /** Emitted when a user buys wTokens from the AMM*/
    event WTokensBought(
        address buyer,
        uint256 wTokensBought,
        uint256 collateralPaid
    );

    /** Emitted when a user sells wTokens to the AMM */
    event WTokensSold(
        address seller,
        uint256 wTokensSold,
        uint256 collateralPaid
    );

    /** Emitted when the owner updates volatilityFactor */
    event VolatilityFactorUpdated(uint256 newVolatilityFactor);

    /** @dev Require minimum trade size to prevent precision errors at low values */
    modifier minTradeSize(uint256 tradeSize) {
        require(tradeSize >= MINIMUM_TRADE_SIZE, "Trade below min size");
        _;
    }

    function transferOwnership(address newOwner)
        public
        override(InitializeableAmm, OwnableUpgradeSafe)
    {
        super.transferOwnership(newOwner);
    }

    /** Initialize the contract, and create an lpToken to track ownership */
    function initialize(
        IMarketsRegistry _registry,
        AggregatorV3Interface _priceOracle,
        IERC20 _paymentToken,
        IERC20 _collateralToken,
        address _tokenImplementation,
        uint16 _tradeFeeBasisPoints,
        bool _shouldInvertOraclePrice
    ) public override {
        require(address(_registry) != address(0x0), "Invalid _registry");
        require(address(_priceOracle) != address(0x0), "Invalid _priceOracle");
        require(
            address(_paymentToken) != address(0x0),
            "Invalid _paymentToken"
        );
        require(
            address(_collateralToken) != address(0x0),
            "Invalid _collateralToken"
        );
        require(
            address(_collateralToken) != address(_paymentToken),
            "_collateralToken cannot equal _paymentToken"
        );
        require(
            _tokenImplementation != address(0x0),
            "Invalid _tokenImplementation"
        );

        // Enforce initialization can only happen once
        require(!initialized, "Contract can only be initialized once.");
        initialized = true;

        // Save off state variables
        registry = _registry;

        // Note! Here we're making an assumption that the _priceOracle argument
        // is for a price whose units are the same as the collateralToken and
        // paymentToken used in this AMM. If they are not then horrible undefined
        // behavior will ensue!
        priceOracle = _priceOracle;
        tradeFeeBasisPoints = _tradeFeeBasisPoints;

        // Save off market tokens
        collateralToken = _collateralToken;
        paymentToken = _paymentToken;
        assetPair = keccak256(
            abi.encode(address(collateralToken), address(paymentToken))
        );

        ERC20UpgradeSafe erc20CollateralToken =
            ERC20UpgradeSafe(address(collateralToken));
        ERC20UpgradeSafe erc20PaymentToken =
            ERC20UpgradeSafe(address(paymentToken));
        collateralDecimals = erc20CollateralToken.decimals();
        paymentDecimals = erc20PaymentToken.decimals();

        shouldInvertOraclePrice = _shouldInvertOraclePrice;

        // Create the lpToken and initialize it
        Proxy lpTokenProxy = new Proxy(_tokenImplementation);
        lpToken = ISimpleToken(address(lpTokenProxy));

        // AMM name will be <collateralToken>-<paymentToken>, e.g. WBTC-USDC
        string memory ammName =
            string(
                abi.encodePacked(
                    erc20CollateralToken.symbol(),
                    "-",
                    erc20PaymentToken.symbol()
                )
            );
        string memory lpTokenName = string(abi.encodePacked("LP-", ammName));
        lpToken.initialize(lpTokenName, lpTokenName, collateralDecimals);

        // Set default volatility
        // 0.4 * volInSeconds * 1e18
        volatilityFactor = 4000e10;

        __Ownable_init();

        emit AMMInitialized(lpToken, address(priceOracle));
    }

    /** The owner can set the flag to enforce deposit limits */
    function setEnforceDepositLimits(
        bool _enforceDepositLimits,
        uint256 _globalDepositLimit
    ) public onlyOwner {
        enforceDepositLimits = _enforceDepositLimits;
        globalDepositLimit = _globalDepositLimit;
        emit EnforceDepositLimitsUpdated(
            enforceDepositLimits,
            _globalDepositLimit
        );
    }

    /**
     * DISABLED: This feature has been disabled but left in for backwards compatibility.
     * Instead of allowing individual caps, there will be a global cap for deposited liquidity.
     *
     * The owner can update limits on any addresses
     */
    function setCapitalDepositLimit(
        address[] memory lpAddresses,
        bool[] memory allowedToDeposit
    ) public onlyOwner {
        // Feature is disabled
        require(false, "Feature not supported");

        require(
            lpAddresses.length == allowedToDeposit.length,
            "Invalid arrays"
        );

        for (uint256 i = 0; i < lpAddresses.length; i++) {
            collateralDepositLimits[lpAddresses[i]]
                .allowedToDeposit = allowedToDeposit[i];
            emit DepositAllowedUpdated(lpAddresses[i], allowedToDeposit[i]);
        }
    }

    /** The owner can set the volatility factor used to price the options */
    function setVolatilityFactor(uint256 _volatilityFactor) public onlyOwner {
        // Check lower bounds: 500e10 corresponds to ~7% annualized volatility
        require(_volatilityFactor > 500e10, "VolatilityFactor is too low");

        volatilityFactor = _volatilityFactor;
        emit VolatilityFactorUpdated(_volatilityFactor);
    }

    /**
     * The owner can update the contract logic address in the proxy itself to upgrade
     */
    function updateAmmImplementation(address newAmmImplementation)
        public
        onlyOwner
    {
        require(
            newAmmImplementation != address(0x0),
            "Invalid newAmmImplementation"
        );

        // Call the proxiable update
        _updateCodeAddress(newAmmImplementation);
    }

    /**
     * Ensure the value in the AMM is not over the limit.  Revert if so.
     */
    function enforceDepositLimit(uint256 poolValue) internal view {
        // If deposit limits are enabled, track and limit
        if (enforceDepositLimits) {
            // Do not allow open markets over the TVL
            require(poolValue <= globalDepositLimit, "Pool over deposit limit");
        }
    }

    /**
     * LP allows collateral to be used to mint new options
     * bTokens and wTokens will be held in this contract and can be traded back and forth.
     * The amount of lpTokens is calculated based on total pool value
     */
    function provideCapital(uint256 collateralAmount, uint256 lpTokenMinimum)
        public
    {
        // Move collateral into this contract
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );

        // If first LP, mint options, mint LP tokens, and send back any redemption amount
        if (lpToken.totalSupply() == 0) {
            // Ensure deposit limit is enforced
            enforceDepositLimit(collateralAmount);

            // Mint lp tokens to the user
            lpToken.mint(msg.sender, collateralAmount);

            // Emit event
            LpTokensMinted(msg.sender, collateralAmount, collateralAmount);

            // Bail out after initial tokens are minted - nothing else to do
            return;
        }

        // At any given moment the AMM can have the following reserves:
        // * collateral token
        // * active bTokens and wTokens for any market
        // * expired bTokens and wTokens for any market
        // * Payment token
        // In order to calculate correct LP amount we do the following:
        // 1. Claim expired wTokens
        // 2. Add value of all active bTokens and wTokens at current prices
        // 3. Add value of any payment token
        // 4. Add value of collateral

        claimAllExpiredTokens();

        uint256 poolValue = getTotalPoolValue(false);

        // Ensure deposit limit is enforced
        enforceDepositLimit(poolValue);

        // Mint LP tokens - the percentage added to bTokens should be same as lp tokens added
        uint256 lpTokenExistingSupply = lpToken.totalSupply();

        uint256 lpTokensNewSupply =
            (poolValue).mul(lpTokenExistingSupply).div(
                poolValue.sub(collateralAmount)
            );
        uint256 lpTokensToMint = lpTokensNewSupply.sub(lpTokenExistingSupply);
        require(
            lpTokensToMint >= lpTokenMinimum,
            "provideCapital: Slippage exceeded"
        );
        lpToken.mint(msg.sender, lpTokensToMint);

        // Emit event
        emit LpTokensMinted(msg.sender, collateralAmount, lpTokensToMint);
    }

    /**
     * LP can redeem their LP tokens in exchange for collateral
     * If `sellTokens` is true pro-rata active b/wTokens will be sold to the pool in exchange for collateral
     * All expired wTokens will be claimed
     * LP will get pro-rata collateral and payment assets
     * We return collateralTokenSent in order to give user ability to calculate the slippage via a call
     */
    function withdrawCapital(
        uint256 lpTokenAmount,
        bool sellTokens,
        uint256 collateralMinimum
    ) public {
        require(
            !sellTokens || collateralMinimum > 0,
            "withdrawCapital: collateralMinimum must be set"
        );
        // First get starting numbers
        uint256 redeemerCollateralBalance =
            collateralToken.balanceOf(msg.sender);
        uint256 redeemerPaymentBalance = paymentToken.balanceOf(msg.sender);

        // Get the lpToken supply
        uint256 lpTokenSupply = lpToken.totalSupply();

        // Burn the lp tokens
        lpToken.burn(msg.sender, lpTokenAmount);

        // Claim all expired wTokens
        claimAllExpiredTokens();

        // Send paymentTokens
        uint256 paymentTokenBalance = paymentToken.balanceOf(address(this));
        if (paymentTokenBalance > 0) {
            paymentToken.transfer(
                msg.sender,
                paymentTokenBalance.mul(lpTokenAmount).div(lpTokenSupply)
            );
        }

        uint256 collateralTokenBalance =
            collateralToken.balanceOf(address(this));

        // Withdraw pro-rata collateral and payment tokens
        // We withdraw this collateral here instead of at the end,
        // because when we sell the residual tokens to the pool we want
        // to exclude the withdrawn collateral
        uint256 ammCollateralBalance =
            collateralTokenBalance.sub(
                collateralTokenBalance.mul(lpTokenAmount).div(lpTokenSupply)
            );

        // Sell pro-rata active tokens or withdraw if no collateral left
        ammCollateralBalance = _sellOrWithdrawActiveTokens(
            lpTokenAmount,
            lpTokenSupply,
            msg.sender,
            sellTokens,
            ammCollateralBalance
        );

        // Send all accumulated collateralTokens
        collateralToken.transfer(
            msg.sender,
            collateralTokenBalance.sub(ammCollateralBalance)
        );

        uint256 collateralTokenSent =
            collateralToken.balanceOf(msg.sender).sub(
                redeemerCollateralBalance
            );

        require(
            !sellTokens || collateralTokenSent >= collateralMinimum,
            "withdrawCapital: Slippage exceeded"
        );

        // Emit the event
        emit LpTokensBurned(
            msg.sender,
            collateralTokenSent,
            paymentToken.balanceOf(msg.sender).sub(redeemerPaymentBalance),
            lpTokenAmount
        );
    }

    /**
     * Takes any wTokens from expired Markets the AMM may have and converts
     * them into collateral token which gets added to its liquidity pool
     */
    function claimAllExpiredTokens() public {
        address[] memory markets = getMarkets();
        for (uint256 i = 0; i < markets.length; i++) {
            IMarket optionMarket = IMarket(markets[i]);
            if (optionMarket.state() == IMarket.MarketState.EXPIRED) {
                uint256 wTokenBalance =
                    optionMarket.wToken().balanceOf(address(this));
                if (wTokenBalance > 0) {
                    claimExpiredTokens(optionMarket, wTokenBalance);
                }
            }
        }
    }

    /**
     * Claims the wToken on a single expired Market. wTokenBalance should be equal to
     * the amount of the expired Market's wToken owned by the AMM
     */
    function claimExpiredTokens(IMarket optionMarket, uint256 wTokenBalance)
        public
    {
        optionMarket.claimCollateral(wTokenBalance);
    }

    /**
     * During liquidity withdrawal we either sell pro-rata active tokens back to the pool
     * or withdraw them to the LP
     */
    function _sellOrWithdrawActiveTokens(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        address redeemer,
        bool sellTokens,
        uint256 collateralLeft
    ) internal returns (uint256) {
        address[] memory markets = getMarkets();

        for (uint256 i = 0; i < markets.length; i++) {
            IMarket optionMarket = IMarket(markets[i]);
            if (optionMarket.state() == IMarket.MarketState.OPEN) {
                uint256 bTokenToSell =
                    optionMarket
                        .bToken()
                        .balanceOf(address(this))
                        .mul(lpTokenAmount)
                        .div(lpTokenSupply);
                uint256 wTokenToSell =
                    optionMarket
                        .wToken()
                        .balanceOf(address(this))
                        .mul(lpTokenAmount)
                        .div(lpTokenSupply);
                if (!sellTokens || lpTokenAmount == lpTokenSupply) {
                    // Full LP token withdrawal for the last LP in the pool
                    // or if auto-sale is disabled
                    if (bTokenToSell > 0) {
                        optionMarket.bToken().transfer(redeemer, bTokenToSell);
                    }
                    if (wTokenToSell > 0) {
                        optionMarket.wToken().transfer(redeemer, wTokenToSell);
                    }
                } else {
                    // The LP sells their bToken and wToken to the AMM. The AMM
                    // pays the LP by reducing collateralLeft, which is what the
                    // AMM's collateral balance will be after executing this
                    // transaction (see MinterAmm.withdrawCapital to see where
                    // _sellOrWithdrawActiveTokens gets called)
                    uint256 collateralAmountB =
                        bTokenGetCollateralOutInternal(
                            optionMarket,
                            bTokenToSell,
                            collateralLeft
                        );

                    // Note! It's possible that either of the two `.sub` calls
                    // below will underflow and return an error. This will only
                    // happen if the AMM does not have sufficient collateral
                    // balance to buy the bToken and wToken from the LP. If this
                    // happens, this transaction will revert with a
                    // "SafeMath: subtraction overflow" error
                    collateralLeft = collateralLeft.sub(collateralAmountB);
                    uint256 collateralAmountW =
                        wTokenGetCollateralOutInternal(
                            optionMarket,
                            wTokenToSell,
                            collateralLeft
                        );
                    collateralLeft = collateralLeft.sub(collateralAmountW);
                }
            }
        }

        return collateralLeft;
    }

    /**
     * Get value of all assets in the pool.
     * Can specify whether to include the value of expired unclaimed tokens
     */
    function getTotalPoolValue(bool includeUnclaimed)
        public
        view
        returns (uint256)
    {
        address[] memory markets = getMarkets();

        // Note! This function assumes the price obtained from the onchain oracle
        // in getCurrentCollateralPrice is a valid market price in units of
        // collateralToken/paymentToken. If the onchain price oracle's value
        // were to drift from the true market price, then the bToken price
        // we calculate here would also drift, and will result in undefined
        // behavior for any functions which call getTotalPoolValue
        uint256 collateralPrice = getCurrentCollateralPrice();
        // First, determine the value of all residual b/wTokens
        uint256 activeTokensValue = 0;
        uint256 unclaimedTokensValue = 0;
        for (uint256 i = 0; i < markets.length; i++) {
            IMarket optionMarket = IMarket(markets[i]);
            if (optionMarket.state() == IMarket.MarketState.OPEN) {
                // value all active bTokens and wTokens at current prices
                uint256 bPrice =
                    getPriceForMarketInternal(optionMarket, collateralPrice);
                // wPrice = 1 - bPrice
                uint256 wPrice = uint256(1e18).sub(bPrice);
                uint256 bTokenBalance =
                    optionMarket.bToken().balanceOf(address(this));
                uint256 wTokenBalance =
                    optionMarket.wToken().balanceOf(address(this));

                activeTokensValue = activeTokensValue.add(
                    bTokenBalance
                        .mul(bPrice)
                        .add(wTokenBalance.mul(wPrice))
                        .div(1e18)
                );
            } else if (
                includeUnclaimed &&
                optionMarket.state() == IMarket.MarketState.EXPIRED
            ) {
                // Get pool wTokenBalance
                uint256 wTokenBalance =
                    optionMarket.wToken().balanceOf(address(this));
                uint256 wTokenSupply = optionMarket.wToken().totalSupply();
                if (wTokenBalance == 0 || wTokenSupply == 0) continue;

                // Get collateral token locked in the market
                uint256 unclaimedCollateral =
                    collateralToken
                        .balanceOf(address(optionMarket))
                        .mul(wTokenBalance)
                        .div(wTokenSupply);

                // Get value of payment token locked in the market
                uint256 unclaimedPayment =
                    paymentToken
                        .balanceOf(address(optionMarket))
                        .mul(wTokenBalance)
                        .div(wTokenSupply)
                        .mul(1e18)
                        .div(collateralPrice);

                unclaimedTokensValue = unclaimedTokensValue
                    .add(unclaimedCollateral)
                    .add(unclaimedPayment);
            }
        }

        // value any payment token
        uint256 paymentTokenValue =
            paymentToken.balanceOf(address(this)).mul(1e18).div(
                collateralPrice
            );

        // Add collateral value
        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        return
            activeTokensValue
                .add(unclaimedTokensValue)
                .add(paymentTokenValue)
                .add(collateralBalance);
    }

    /**
     * Get unclaimed collateral and payment tokens locked in expired wTokens
     */
    function getUnclaimedBalances() public view returns (uint256, uint256) {
        address[] memory markets = getMarkets();

        uint256 unclaimedCollateral = 0;
        uint256 unclaimedPayment = 0;

        for (uint256 i = 0; i < markets.length; i++) {
            IMarket optionMarket = IMarket(markets[i]);
            if (optionMarket.state() == IMarket.MarketState.EXPIRED) {
                // Get pool wTokenBalance
                uint256 wTokenBalance =
                    optionMarket.wToken().balanceOf(address(this));
                uint256 wTokenSupply = optionMarket.wToken().totalSupply();
                if (wTokenBalance == 0 || wTokenSupply == 0) continue;

                // Get collateral token locked in the market
                unclaimedCollateral = unclaimedCollateral.add(
                    collateralToken
                        .balanceOf(address(optionMarket))
                        .mul(wTokenBalance)
                        .div(wTokenSupply)
                );

                // Get payment token locked in the market
                unclaimedPayment = unclaimedPayment.add(
                    paymentToken
                        .balanceOf(address(optionMarket))
                        .mul(wTokenBalance)
                        .div(wTokenSupply)
                );
            }
        }

        return (unclaimedCollateral, unclaimedPayment);
    }

    /**
     * Calculate sale value of pro-rata LP b/wTokens
     */
    function getTokensSaleValue(uint256 lpTokenAmount)
        public
        view
        returns (uint256)
    {
        if (lpTokenAmount == 0) return 0;

        uint256 lpTokenSupply = lpToken.totalSupply();
        if (lpTokenSupply == 0) return 0;

        address[] memory markets = getMarkets();

        (uint256 unclaimedCollateral, ) = getUnclaimedBalances();
        // Calculate amount of collateral left in the pool to sell tokens to
        uint256 totalCollateral =
            unclaimedCollateral.add(collateralToken.balanceOf(address(this)));

        // Subtract pro-rata collateral amount to be withdrawn
        totalCollateral = totalCollateral
            .mul(lpTokenSupply.sub(lpTokenAmount))
            .div(lpTokenSupply);

        // Given remaining collateral calculate how much all tokens can be sold for
        uint256 collateralLeft = totalCollateral;
        for (uint256 i = 0; i < markets.length; i++) {
            IMarket optionMarket = IMarket(markets[i]);
            if (optionMarket.state() == IMarket.MarketState.OPEN) {
                uint256 bTokenToSell =
                    optionMarket
                        .bToken()
                        .balanceOf(address(this))
                        .mul(lpTokenAmount)
                        .div(lpTokenSupply);
                uint256 wTokenToSell =
                    optionMarket
                        .wToken()
                        .balanceOf(address(this))
                        .mul(lpTokenAmount)
                        .div(lpTokenSupply);

                uint256 collateralAmountB =
                    bTokenGetCollateralOutInternal(
                        optionMarket,
                        bTokenToSell,
                        collateralLeft
                    );

                collateralLeft = collateralLeft.sub(collateralAmountB);
                uint256 collateralAmountW =
                    wTokenGetCollateralOutInternal(
                        optionMarket,
                        wTokenToSell,
                        collateralLeft
                    );
                collateralLeft = collateralLeft.sub(collateralAmountW);
            }
        }

        return totalCollateral.sub(collateralLeft);
    }

    /**
     * List of market addresses that this AMM trades
     */
    function getMarkets() public view returns (address[] memory) {
        return registry.getMarketsByAssetPair(assetPair);
    }

    /**
     * Get market address by index
     */
    function getMarket(uint256 marketIndex) public view returns (IMarket) {
        return IMarket(getMarkets()[marketIndex]);
    }

    struct LocalVars {
        uint256 bTokenBalance;
        uint256 wTokenBalance;
        uint256 toSquare;
        uint256 collateralAmount;
        uint256 collateralAfterFee;
        uint256 bTokenAmount;
    }

    /**
     * This function determines reserves of a bonding curve for a specific market.
     * Given price of bToken we determine what is the largest pool we can create such that
     * the ratio of its reserves satisfy the given bToken price: Rb / Rw = (1 - Pb) / Pb
     */
    function getVirtualReserves(IMarket market)
        public
        view
        returns (uint256, uint256)
    {
        return
            getVirtualReservesInternal(
                market,
                collateralToken.balanceOf(address(this))
            );
    }

    function getVirtualReservesInternal(
        IMarket market,
        uint256 collateralTokenBalance
    ) internal view returns (uint256, uint256) {
        // Max amount of tokens we can get by adding current balance plus what can be minted from collateral
        uint256 bTokenBalanceMax =
            market.bToken().balanceOf(address(this)).add(
                collateralTokenBalance
            );
        uint256 wTokenBalanceMax =
            market.wToken().balanceOf(address(this)).add(
                collateralTokenBalance
            );

        uint256 bTokenPrice = getPriceForMarket(market);
        uint256 wTokenPrice = uint256(1e18).sub(bTokenPrice);

        // Balance on higher reserve side is the sum of what can be minted (collateralTokenBalance)
        // plus existing balance of the token
        uint256 bTokenVirtualBalance;
        uint256 wTokenVirtualBalance;

        if (bTokenPrice <= wTokenPrice) {
            // Rb >= Rw, Pb <= Pw
            bTokenVirtualBalance = bTokenBalanceMax;
            wTokenVirtualBalance = bTokenVirtualBalance.mul(bTokenPrice).div(
                wTokenPrice
            );

            // Sanity check that we don't exceed actual physical balances
            // In case this happens, adjust virtual balances to not exceed maximum
            // available reserves while still preserving correct price
            if (wTokenVirtualBalance > wTokenBalanceMax) {
                wTokenVirtualBalance = wTokenBalanceMax;
                bTokenVirtualBalance = wTokenVirtualBalance
                    .mul(wTokenPrice)
                    .div(bTokenPrice);
            }
        } else {
            // if Rb < Rw, Pb > Pw
            wTokenVirtualBalance = wTokenBalanceMax;
            bTokenVirtualBalance = wTokenVirtualBalance.mul(wTokenPrice).div(
                bTokenPrice
            );

            // Sanity check
            if (bTokenVirtualBalance > bTokenBalanceMax) {
                bTokenVirtualBalance = bTokenBalanceMax;
                wTokenVirtualBalance = bTokenVirtualBalance
                    .mul(bTokenPrice)
                    .div(wTokenPrice);
            }
        }

        return (bTokenVirtualBalance, wTokenVirtualBalance);
    }

    /**
     * Get current collateral price expressed in payment token
     */
    function getCurrentCollateralPrice() public view returns (uint256) {
        // TODO: Cache the Oracle price within transaction
        (, int256 latestAnswer, , , ) = priceOracle.latestRoundData();

        require(latestAnswer >= 0, "invalid value received from price oracle");

        if (shouldInvertOraclePrice) {
            return
                uint256(1e18)
                    .mul(uint256(10)**paymentDecimals)
                    .mul(uint256(10)**priceOracle.decimals())
                    .div(uint256(10)**collateralDecimals)
                    .div(uint256(latestAnswer));
        } else {
            return
                uint256(1e18)
                    .mul(uint256(10)**paymentDecimals)
                    .mul(uint256(latestAnswer))
                    .div(uint256(10)**collateralDecimals)
                    .div(uint256(10)**priceOracle.decimals());
        }
    }

    /**
     * @dev Get price of bToken for a given market
     */
    function getPriceForMarket(IMarket market) public view returns (uint256) {
        return getPriceForMarketInternal(market, getCurrentCollateralPrice());
    }

    function getPriceForMarketInternal(IMarket market, uint256 collateralPrice)
        private
        view
        returns (uint256)
    {
        return
            // Note! This function assumes the price obtained from the onchain oracle
            // in getCurrentCollateralPrice is a valid market price in units of
            // collateralToken/paymentToken. If the onchain price oracle's value
            // were to drift from the true market price, then the bToken price
            // we calculate here would also drift, and will result in undefined
            // behavior for any functions which call getPriceForMarket
            calcPrice(
                market.expirationDate().sub(now),
                market.priceRatio(),
                collateralPrice,
                volatilityFactor
            );
    }

    /**
     * @dev Calculate price of bToken based on Black-Scholes approximation.
     * Formula: 0.4 * ImplVol * sqrt(timeUntilExpiry) * currentPrice / strike
     */
    function calcPrice(
        uint256 timeUntilExpiry,
        uint256 strike,
        uint256 currentPrice,
        uint256 volatility
    ) public pure returns (uint256) {
        uint256 intrinsic = 0;
        if (currentPrice > strike) {
            intrinsic = currentPrice.sub(strike).mul(1e18).div(currentPrice);
        }

        uint256 timeValue =
            Math.sqrt(timeUntilExpiry).mul(volatility).mul(currentPrice).div(
                strike
            );

        return intrinsic.add(timeValue);
    }

    /**
     * @dev Buy bToken of a given market.
     * We supply market index instead of market address to ensure that only supported markets can be traded using this AMM
     * collateralMaximum is used for slippage protection
     */
    function bTokenBuy(
        uint256 marketIndex,
        uint256 bTokenAmount,
        uint256 collateralMaximum
    ) public minTradeSize(bTokenAmount) returns (uint256) {
        IMarket optionMarket = getMarket(marketIndex);
        require(
            optionMarket.state() == IMarket.MarketState.OPEN,
            "bTokenBuy must be open"
        );

        uint256 collateralAmount =
            bTokenGetCollateralIn(optionMarket, bTokenAmount);
        require(
            collateralAmount <= collateralMaximum,
            "bTokenBuy: slippage exceeded"
        );

        // Move collateral into this contract
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );

        // Mint new options only as needed
        ISimpleToken bToken = optionMarket.bToken();
        uint256 bTokenBalance = bToken.balanceOf(address(this));
        if (bTokenBalance < bTokenAmount) {
            // Approve the collateral to mint bTokenAmount of new options
            collateralToken.approve(address(optionMarket), bTokenAmount);
            optionMarket.mintOptions(bTokenAmount.sub(bTokenBalance));
        }

        // Send all bTokens back
        bToken.transfer(msg.sender, bTokenAmount);

        // Emit the event
        emit BTokensBought(msg.sender, bTokenAmount, collateralAmount);

        // Return the amount of collateral required to buy
        return collateralAmount;
    }

    /**
     * @dev Sell bToken of a given market.
     * We supply market index instead of market address to ensure that only supported markets can be traded using this AMM
     * collateralMaximum is used for slippage protection
     */
    function bTokenSell(
        uint256 marketIndex,
        uint256 bTokenAmount,
        uint256 collateralMinimum
    ) public minTradeSize(bTokenAmount) returns (uint256) {
        IMarket optionMarket = getMarket(marketIndex);
        require(
            optionMarket.state() == IMarket.MarketState.OPEN,
            "bTokenSell must be open"
        );

        // Get initial stats
        bTokenAmount = bTokenAmount;

        uint256 collateralAmount =
            bTokenGetCollateralOut(optionMarket, bTokenAmount);
        require(
            collateralAmount >= collateralMinimum,
            "bTokenSell: slippage exceeded"
        );

        // Move bToken into this contract
        optionMarket.bToken().safeTransferFrom(
            msg.sender,
            address(this),
            bTokenAmount
        );

        // Always be closing!
        uint256 bTokenBalance = optionMarket.bToken().balanceOf(address(this));
        uint256 wTokenBalance = optionMarket.wToken().balanceOf(address(this));
        uint256 closeAmount = Math.min(bTokenBalance, wTokenBalance);
        if (closeAmount > 0) {
            optionMarket.closePosition(closeAmount);
        }

        // Send the tokens to the seller
        collateralToken.transfer(msg.sender, collateralAmount);

        // Emit the event
        emit BTokensSold(msg.sender, bTokenAmount, collateralAmount);

        // Return the amount of collateral received during sale
        return collateralAmount;
    }

    /**
     * @dev Calculate amount of collateral required to buy bTokens
     */
    function bTokenGetCollateralIn(IMarket market, uint256 bTokenAmount)
        public
        view
        returns (uint256)
    {
        // Shortcut for 0 amount
        if (bTokenAmount == 0) return 0;

        LocalVars memory vars; // Holds all our calculation results

        // Get initial stats
        vars.bTokenAmount = bTokenAmount;
        (vars.bTokenBalance, vars.wTokenBalance) = getVirtualReserves(market);

        uint256 sumBalance = vars.bTokenBalance.add(vars.wTokenBalance);
        if (sumBalance > vars.bTokenAmount) {
            vars.toSquare = sumBalance.sub(vars.bTokenAmount);
        } else {
            vars.toSquare = vars.bTokenAmount.sub(sumBalance);
        }
        vars.collateralAmount = Math
            .sqrt(
            vars.toSquare.mul(vars.toSquare).add(
                vars.bTokenAmount.mul(vars.wTokenBalance).mul(4)
            )
        )
            .add(vars.bTokenAmount)
            .sub(vars.bTokenBalance)
            .sub(vars.wTokenBalance)
            .div(2);

        return vars.collateralAmount;
    }

    /**
     * @dev Calculate amount of collateral in exchange for selling bTokens
     */
    function bTokenGetCollateralOut(IMarket market, uint256 bTokenAmount)
        public
        view
        returns (uint256)
    {
        return
            bTokenGetCollateralOutInternal(
                market,
                bTokenAmount,
                collateralToken.balanceOf(address(this))
            );
    }

    function bTokenGetCollateralOutInternal(
        IMarket market,
        uint256 bTokenAmount,
        uint256 _collateralTokenBalance
    ) internal view returns (uint256) {
        // Shortcut for 0 amount
        if (bTokenAmount == 0) return 0;

        (uint256 bTokenBalance, uint256 wTokenBalance) =
            getVirtualReservesInternal(market, _collateralTokenBalance);

        uint256 toSquare = bTokenAmount.add(bTokenBalance).add(wTokenBalance);

        uint256 collateralAmount =
            toSquare
                .sub(
                Math.sqrt(
                    toSquare.mul(toSquare).sub(
                        bTokenAmount.mul(wTokenBalance).mul(4)
                    )
                )
            )
                .div(2);

        return collateralAmount;
    }

    /**
     * @dev Calculate amount of collateral in exchange for selling wTokens
     * This method is used internally when withdrawing liquidity with `sellTokens` set to true
     */
    function wTokenGetCollateralOutInternal(
        IMarket market,
        uint256 wTokenAmount,
        uint256 _collateralTokenBalance
    ) internal view returns (uint256) {
        // Shortcut for 0 amount
        if (wTokenAmount == 0) return 0;

        (uint256 bTokenBalance, uint256 wTokenBalance) =
            getVirtualReservesInternal(market, _collateralTokenBalance);

        uint256 toSquare = wTokenAmount.add(wTokenBalance).add(bTokenBalance);
        uint256 collateralAmount =
            toSquare
                .sub(
                Math.sqrt(
                    toSquare.mul(toSquare).sub(
                        wTokenAmount.mul(bTokenBalance).mul(4)
                    )
                )
            )
                .div(2);

        return collateralAmount;
    }
}