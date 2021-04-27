/**
 *Submitted for verification at Etherscan.io on 2021-04-26
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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol

pragma solidity ^0.6.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
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

// File: contracts/interface/IContractRegistry.sol

pragma solidity >=0.6.0;

interface IContractRegistry {
    function addressOf(bytes32 contractName) external view returns(address);
}

// File: contracts/interface/IBancorGovernance.sol

pragma solidity >=0.6.0;

interface IBancorGovernance {
    function voteFor(uint256 _id) external;
    function voteAgainst(uint256 _id) external;
    function stake(uint256 _amount) external;
    function unstake(uint256 _amount) external;
}

// File: contracts/interface/IStakingRewards.sol

pragma solidity >=0.6.0;

interface IDSToken {

}

interface IStakingRewards {
    // claims all rewards from providing address
    function claimRewards() external returns (uint256);
    // returns pending rewards from providing address
    function pendingRewards(address provider) external view returns (uint256);
    // returns all staked rewards and the ID of the new position
    function stakeRewards(uint256 maxAmount, IDSToken poolToken) external returns (uint256, uint256);
}

// File: contracts/interface/ILiquidityProtection.sol

pragma solidity >=0.6.0;


interface IConverterAnchor {

}

interface ILiquidityProtection {
    function addLiquidity(
        IConverterAnchor _poolAnchor,
        IERC20 _reserveToken,
        uint256 _amount
    ) external payable returns(uint);
    // returns id of deposit

    function removeLiquidity(uint256 _id, uint32 _portion) external;

    function removeLiquidityReturn(
        uint256 _id,
        uint32 _portion,
        uint256 _removeTimestamp
    ) external view returns (uint256, uint256, uint256);
    // returns amount in the reserve token
    // returns actual return amount in the reserve token
    // returns compensation in the network token

    // call 24 hours after removing liquidity
    function claimBalance(uint256 _startIndex, uint256 _endIndex) external;
}

// File: contracts/interface/ILiquidityProvider.sol

pragma solidity 0.6.2;



interface ILiquidityProvider {
    function initializeAndAddLiquidity(
        IContractRegistry _contractRegistry,
        address _xbntContract,
        IERC20 _bnt,
        IERC20 _vbnt,
        address _poolAnchor,
        uint256 _amount
    ) external returns(uint);
    function removeLiquidity(uint256 _id) external;
    function claimRewards() external returns(uint256);
    function claimBalance() external;
    function claimRewardsAndRemoveLiquidity() external returns(uint256);
    function claimAndRestake(address _poolToken) external returns(uint256, uint256);
    function pendingRewards() external view returns(uint256);
}

// File: contracts/interface/IMinimalProxyFactory.sol

pragma solidity ^0.6.0;

interface IMinimalProxyFactory {
    function deploy(uint256 salt, address implementation) external returns(address proxyAddress);
}

// File: contracts/interface/IDelegateRegistry.sol

pragma solidity 0.6.2;

interface IDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;
}

// File: contracts/interface/IxBNT.sol

pragma solidity 0.6.2;

interface IxBNT {
    function getProxyAddressDepositIds(address proxyAddress) external view returns(uint256[] memory);
}

// File: contracts/helpers/LiquidityProvider.sol

pragma solidity 0.6.2;





contract LiquidityProvider {
    bool private initialized;

    IContractRegistry private contractRegistry;
    IERC20 private bnt;
    IERC20 private vbnt;

    address private xbnt;
    uint256 public nextDepositIndexToClaimBalance;

    function initializeAndAddLiquidity(
        IContractRegistry _contractRegistry,
        address _xbnt,
        IERC20 _bnt,
        IERC20 _vbnt,
        address _poolToken,
        uint256 _amount
    ) external returns(uint256) {
        require(msg.sender == _xbnt, 'Invalid caller');
        require(!initialized, 'Already initialized');
        initialized = true;

        contractRegistry = _contractRegistry;
        xbnt = _xbnt;
        bnt = _bnt;
        vbnt = _vbnt;

        return _addLiquidity(_poolToken, _amount);
    }

    function _addLiquidity(
        address _poolToken,
        uint256 _amount
    ) private returns(uint256 id) {
        ILiquidityProtection lp = getLiquidityProtectionContract();
        bnt.approve(address(lp), uint(-1));

        id = lp.addLiquidity(IConverterAnchor(_poolToken), bnt, _amount);

        _retrieveVbntBalance();
    }

    /*
     * @notice Restake this proxy's rewards
     */
    function claimAndRestake(address _poolToken) external onlyXbntContract returns(uint256 newDepositId, uint256 restakedBal){
        (, newDepositId) = getStakingRewardsContract().stakeRewards(uint(-1), IDSToken(_poolToken));
        restakedBal = _retrieveVbntBalance();
    }

    function claimRewards() external onlyXbntContract returns(uint256 rewardsAmount){
        rewardsAmount = _claimRewards();
    }

    function _claimRewards() private returns(uint256 rewards){
        rewards = getStakingRewardsContract().claimRewards();
        _retrieveBntBalance();
    }

    function _removeLiquidity(ILiquidityProtection _lp, uint256 _id) private {
        _lp.removeLiquidity(_id, 1000000); // full PPM resolution
    }

    /*
     * @notice Initiate final exit from this proxy
     */
    function claimRewardsAndRemoveLiquidity() external onlyXbntContract returns(uint256 rewards) {
        rewards = _claimRewards();
        uint256[] memory depositIds = getDepositIds();

        ILiquidityProtection lp = getLiquidityProtectionContract();
        vbnt.approve(address(lp), uint(-1));

        for(uint256 i = 0; i < depositIds.length; i++){
            _removeLiquidity(lp, depositIds[i]);
        }
    }

    /*
     * @notice Called 24 hours after `claimRewardsAndRemoveLiquidity`
     */
    function claimBalance() external onlyXbntContract {
        getLiquidityProtectionContract().claimBalance(0, getDepositIds().length);
        _retrieveBntBalance();
    }

    function _retrieveBntBalance() private {
        bnt.transfer(xbnt, bnt.balanceOf(address(this)));
    }

    function _retrieveVbntBalance() private returns(uint256 vbntBal) {
        vbntBal = vbnt.balanceOf(address(this));
        vbnt.transfer(xbnt, vbntBal);
    }

    function pendingRewards() external view returns(uint){
        return getStakingRewardsContract().pendingRewards(address(this));
    }

    function getStakingRewardsContract() private view returns(IStakingRewards){
        return IStakingRewards(contractRegistry.addressOf('StakingRewards'));
    }

    function getLiquidityProtectionContract() private view returns(ILiquidityProtection){
        return ILiquidityProtection(contractRegistry.addressOf('LiquidityProtection'));
    }

    function getDepositIds() private view returns(uint256[] memory){
        return IxBNT(xbnt).getProxyAddressDepositIds(address(this));
    }

    modifier onlyXbntContract {
        require(msg.sender == xbnt, 'Invalid caller');
        _;
    }
}

// File: contracts/xBNT.sol

pragma solidity 0.6.2;















interface IBancorNetwork {
    function convertByPath(
        address[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _beneficiary,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);

    function rateByPath(address[] calldata _path, uint256 _amount)
        external
        view
        returns (uint256);

    function conversionPath(IERC20 _sourceToken, IERC20 _targetToken)
        external
        view
        returns (address[] memory);
}

contract xBNT is ERC20UpgradeSafe, OwnableUpgradeSafe, PausableUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private bnt;
    IERC20 private vbnt;
    IContractRegistry private contractRegistry;
    IBancorGovernance internal bancorGovernance;
    IMinimalProxyFactory private proxyFactory;

    bytes32 private constant bancorNetworkName = 'BancorNetwork';
    bytes32 private constant stakingRewardsName = 'StakingRewards';
    bytes32 private constant liquidityProtectionName = 'LiquidityProtection';

    uint32 private constant PPM = 1000000;
    uint256 private constant DEC_18 = 1e18;
    uint256 private constant BUFFER_TARGET = 20; // 5%
    uint256 private constant MAX_UINT = 2**256 - 1;
    uint256 private constant WAITING_PERIOD = 2 days;
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 10;
    uint256 private constant LIQUIDATION_TIME_PERIOD = 4 weeks;

    uint256 private lpImplementationChangedTimestamp;
    uint256 private governanceAddressChangedTimestamp;

    uint256 public adminActiveTimestamp;

    uint256 public lowestActiveProxyIndex;
    uint256 public nextProxyIndex;

    uint256 public totalAllocatedNav;
    uint256 public pendingRewardsContributionToNav;

    uint256 public withdrawableBntFees;

    address private manager;
    address private manager2;
    address internal liquidityProviderImplementation;

    address private queuedLiquidityProviderImplementation;
    address private queuedGovernanceAddress;

    address private constant ZERO_ADDRESS = address(0);

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    FeeDivisors public feeDivisors;

    struct Deposit {
        address proxyAddress;
        uint256 depositId;
        uint256 initialContribution;
        uint256 latestContributionToNav;
    }

    mapping(uint256 => Deposit) public depositIdToDeposit;

    struct ProxyData {
        uint256[] depositIds;
        uint256 pendingRewardsContributionToNav;
        uint256 deployedBnt;
        bool balanceClaimed;
    }

    mapping(address => ProxyData) private proxyAddressToData;
    mapping(uint256 => address) public proxyIndexToAddress;

    event AddLiquidity(
        address poolToken,
        uint256 amount,
        uint256 depositId,
        uint256 proxyIndex,
        uint256 timestamp
    );

    event ClaimRestake(
        uint256 proxyIndex,
        uint256 amount,
        uint256 depositId,
        uint256 timestamp
    );

    event ClaimRemove(uint256 proxyIndex, uint256 rewardsClaimed);

    event ClaimRewards(uint256 proxyIndex, uint256 rewardsClaimed);

    event ClaimBalance(uint256 proxyIndex);

    event RewardsNavUpdated(
        uint256 previousRewardsNav,
        uint256 newRewardsNav,
        uint256 timestamp
    );

    event KeyAddressChange();

    function initialize(
        IERC20 _bnt,
        IERC20 _vbnt,
        IContractRegistry _contractRegistry,
        IBancorGovernance _bancorGovernance,
        IMinimalProxyFactory _proxyFactory,
        address _liquidityProviderImplementation,
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor,
        string memory _symbol
    ) public initializer {
        __ERC20_init('xBNT', _symbol);
        __Ownable_init();
        __Pausable_init();

        bnt = _bnt;
        vbnt = _vbnt;
        contractRegistry = _contractRegistry;
        bancorGovernance = _bancorGovernance;
        proxyFactory = _proxyFactory;
        liquidityProviderImplementation = _liquidityProviderImplementation;

        _setFeeDivisors(_mintFeeDivisor, _burnFeeDivisor, _claimFeeDivisor);
        _updateAdminActiveTimestamp();
    }

    /* ========================================================================================= */
    /*                                          User-Facing                                      */
    /* ========================================================================================= */

    /*
     * @notice Mint xBNT using ETH
     * @param path: BancorNetwork trade path
     * @param minReturn: BancorNetwork trade minReturn
     */
    function mint(address[] calldata path, uint256 minReturn)
        external
        payable
        whenNotPaused
    {
        require(msg.value > 0, 'Must send ETH');

        uint256 incrementalBnt =
            IBancorNetwork(contractRegistry.addressOf(bancorNetworkName))
                .convertByPath{value: msg.value}(
                path,
                msg.value,
                minReturn,
                ZERO_ADDRESS,
                ZERO_ADDRESS,
                0
            );

        _mintInternal(incrementalBnt);
    }

    /*
     * @notice Mint xBNT using BNT
     * @notice Must run approval first
     * @param bntAmount: BNT amount
     */
    function mintWithToken(uint256 bntAmount) external whenNotPaused {
        require(bntAmount > 0, 'Must send BNT');

        bnt.transferFrom(msg.sender, address(this), bntAmount);

        _mintInternal(bntAmount);
    }

    function _mintInternal(uint256 _incrementalBnt) private {
        uint256 fee =
            _calculateAndIncrementFee(_incrementalBnt, feeDivisors.mintFee);

        uint256 mintAmount =
            calculateMintAmount(_incrementalBnt.sub(fee), totalSupply());

        super._mint(msg.sender, mintAmount);
    }

    function calculateMintAmount(uint256 incrementalBnt, uint256 totalSupply)
        public
        view
        returns (uint256 mintAmount)
    {
        if (totalSupply == 0)
            return incrementalBnt.mul(INITIAL_SUPPLY_MULTIPLIER);

        mintAmount = (incrementalBnt).mul(totalSupply).div(
            getNav().sub(incrementalBnt)
        );
    }

    /*
     * @notice Burn xBNT
     * @notice Will fail if pro rata BNT is more than buffer balance
     * @param redeemAmount: xBNT to burn
     * @param redeemForEth: Redeem for ETH or BNT
     * @param path: If redeem for ETH, BancorNetwork path
     * @param minReturn: If redeem for ETH, BancorNetwork minReturn
     */
    function burn(
        uint256 redeemAmount,
        bool redeemForEth,
        address[] memory path,
        uint256 minReturn
    ) public {
        require(redeemAmount > 0, 'Must send xBNT');

        uint256 bufferBalance = getBufferBalance();
        uint256 proRataBnt = getNav().mul(redeemAmount).div(totalSupply());
        require(
            proRataBnt <= bufferBalance,
            'Burn exceeds available liquidity'
        );

        super._burn(msg.sender, redeemAmount);
        uint256 fee =
            _calculateAndIncrementFee(proRataBnt, feeDivisors.burnFee);

        if (redeemForEth) {
            address bancorNetworkAddress =
                contractRegistry.addressOf(bancorNetworkName);
            _approveIfNecessary(bnt, bancorNetworkAddress); // in case registry addr has changed

            uint256 ethRedemption =
                IBancorNetwork(bancorNetworkAddress).convertByPath(
                    path,
                    proRataBnt.sub(fee),
                    minReturn,
                    ZERO_ADDRESS,
                    ZERO_ADDRESS,
                    0
                );
            (bool success, ) = msg.sender.call.value(ethRedemption)('');
            require(success, 'Transfer failed');
        } else {
            bnt.transfer(msg.sender, proRataBnt.sub(fee));
        }
    }

    /* ========================================================================================= */
    /*                                      Liquidity Provision                                  */
    /* ========================================================================================= */

    /*
     * @notice Makes BNT deposit on Bancor
     * @notice Deploys new proxy
     * @notice Allocates buffer BNT to allocated NAV
     * @param _poolAnchor: Address of liquidity pool
     * @param _amount: BNT amount
     */
    function addLiquidity(IConverterAnchor _poolAnchor, uint256 _amount)
        external
        onlyOwnerOrManager
    {
        uint256 salt =
            uint256(keccak256(abi.encodePacked(nextProxyIndex, _amount)));
        address liquidityProviderProxy =
            proxyFactory.deploy(salt, liquidityProviderImplementation);

        bnt.transfer(liquidityProviderProxy, _amount);

        uint256 depositId =
            ILiquidityProvider(liquidityProviderProxy)
                .initializeAndAddLiquidity(
                contractRegistry,
                address(this),
                bnt,
                vbnt,
                address(_poolAnchor),
                _amount
            );

        Deposit memory newDeposit =
            Deposit({
                proxyAddress: liquidityProviderProxy,
                depositId: depositId,
                initialContribution: _amount,
                latestContributionToNav: _amount
            });

        emit AddLiquidity(
            address(_poolAnchor),
            _amount,
            depositId,
            nextProxyIndex,
            block.timestamp
        );

        depositIdToDeposit[depositId] = newDeposit;

        ProxyData storage proxyData =
            proxyAddressToData[liquidityProviderProxy];
        proxyData.depositIds.push(depositId);
        proxyData.deployedBnt = _amount;

        proxyIndexToAddress[nextProxyIndex] = liquidityProviderProxy;
        nextProxyIndex++;

        totalAllocatedNav = totalAllocatedNav.add(_amount);

        _stake(_amount);
        _updateAdminActiveTimestamp();
    }

    /*
     * @notice Restakes rewards from current deposit into new deposit
     * @notice Deploys capital to same proxy as current deposit
     * @notice Allocates from rewards NAV to allocated NAV
     * @param proxyIndex: Proxy index
     * @param poolToken: Pool to restake rewards to
     */
    function claimAndRestake(uint256 proxyIndex, address poolToken)
        external
        onlyOwnerOrManager
    {
        address proxyAddress = proxyIndexToAddress[proxyIndex];
        ProxyData storage proxyData = proxyAddressToData[proxyAddress];

        ILiquidityProvider lpProxy = ILiquidityProvider(proxyAddress);

        (uint256 newDepositId, uint256 restakedBal) =
            lpProxy.claimAndRestake(poolToken);

        // fee effectively deducted from buffer balance
        // because full rewards are restaked without cycling through xBNT
        _calculateAndIncrementFee(restakedBal, feeDivisors.claimFee);

        proxyData.depositIds.push(newDepositId);
        proxyData.deployedBnt = proxyData.deployedBnt.add(restakedBal);

        // zero out restaked rewards
        pendingRewardsContributionToNav = pendingRewardsContributionToNav.sub(
            proxyData.pendingRewardsContributionToNav
        );
        proxyData.pendingRewardsContributionToNav = 0;

        // add restaked rewards back to nav
        totalAllocatedNav = totalAllocatedNav.add(restakedBal);

        depositIdToDeposit[newDepositId] = Deposit({
            proxyAddress: proxyAddress,
            depositId: newDepositId,
            initialContribution: restakedBal,
            latestContributionToNav: restakedBal
        });

        emit ClaimRestake(
            proxyIndex,
            restakedBal,
            newDepositId,
            block.timestamp
        );

        _stake(restakedBal);
        _updateAdminActiveTimestamp();
    }

    /*
     * @notice Iterates through proxies to calculate current available rewards
     * @notice Must be called daily or more to stay current with NAV
     * @notice We specify begin/end indices in case num proxies approaches gas limit
     * @param beginProxyIndexIterator: proxyIndex to begin iteration
     * @param endProxyIndexIterator: proxyIndex to end iteration
     */
    function updatePendingRewardsContributionToNav(
        uint256 beginProxyIndexIterator,
        uint256 endProxyIndexIterator
    ) external {
        require(
            beginProxyIndexIterator >= lowestActiveProxyIndex,
            'Invalid index'
        );
        require(endProxyIndexIterator <= nextProxyIndex, 'Invalid index');
        require(
            endProxyIndexIterator > beginProxyIndexIterator,
            'Invalid order'
        );

        IStakingRewards stakingRewards = getStakingRewardsContract();

        uint256 replacedPendingRewardsContributionToNav;
        uint256 updatedPendingRewardsContributionToNav;

        for (uint256 i = lowestActiveProxyIndex; i < nextProxyIndex; i++) {
            address proxyAddress = proxyIndexToAddress[i];
            replacedPendingRewardsContributionToNav = replacedPendingRewardsContributionToNav
                .add(
                proxyAddressToData[proxyAddress].pendingRewardsContributionToNav
            );

            uint256 newContributionToRewardsNav =
                stakingRewards.pendingRewards(proxyAddress);

            proxyAddressToData[proxyAddress]
                .pendingRewardsContributionToNav = newContributionToRewardsNav;
            updatedPendingRewardsContributionToNav = updatedPendingRewardsContributionToNav
                .add(newContributionToRewardsNav);
        }

        emit RewardsNavUpdated(
            pendingRewardsContributionToNav,
            updatedPendingRewardsContributionToNav,
            block.timestamp
        );

        pendingRewardsContributionToNav = pendingRewardsContributionToNav
            .add(updatedPendingRewardsContributionToNav)
            .sub(replacedPendingRewardsContributionToNav);
    }

    /*
     * @notice Updates NAV for value of deposits
     * @notice Needs to be called weekly at least
     * @notice Due to IL protection, allocated NAV is assumed to be the greater of value
     * of initial deposit or  removeLiquidityReturn
     * @notice We specify begin/end indices in case num deposits approaches gas limit
     * @param beginProxyIndexIterator: proxyIndex to begin iteration
     * @param endProxyIndexIterator: proxyIndex to end iteration
     */
    function updateTotalAllocatedNav(
        uint256 beginProxyIndexIterator,
        uint256 endProxyIndexIterator
    ) external {
        require(
            beginProxyIndexIterator >= lowestActiveProxyIndex,
            'Invalid index'
        );
        require(endProxyIndexIterator <= nextProxyIndex, 'Invalid index');

        ILiquidityProtection lp = getLiquidityProtectionContract();

        uint256[] memory depositIds;
        uint256 newContributionToAllocatedNav;

        for (
            uint256 i = beginProxyIndexIterator;
            i < endProxyIndexIterator;
            i++
        ) {
            depositIds = proxyAddressToData[proxyIndexToAddress[i]].depositIds;

            for (uint256 j = 0; j < depositIds.length; j++) {
                (newContributionToAllocatedNav, , ) = lp.removeLiquidityReturn(
                    depositIds[j],
                    PPM,
                    block.timestamp.add(100 days)
                );

                Deposit storage deposit = depositIdToDeposit[depositIds[j]];

                // we do this check here only modifying state if contribution is higher
                // than previous, implicitly capturing Bancor's IL protection framework
                if (
                    newContributionToAllocatedNav >
                    deposit.latestContributionToNav
                ) {
                    totalAllocatedNav = totalAllocatedNav
                        .sub(deposit.latestContributionToNav)
                        .add(newContributionToAllocatedNav);
                    deposit
                        .latestContributionToNav = newContributionToAllocatedNav;
                }
            }
        }
    }

    /*
     * @notice Removes all deposits from proxy at lowestActiveProxyIndex
     */
    function claimRewardsAndRemoveLiquidity() external onlyOwnerOrManager {
        _claimRewardsAndRemoveLiquidity();
        _updateAdminActiveTimestamp();
    }

    function emergencyClaimAndRemove() external liquidationTimeElapsed {
        _claimRewardsAndRemoveLiquidity();
    }

    function _claimRewardsAndRemoveLiquidity() private {
        address proxyAddress = proxyIndexToAddress[lowestActiveProxyIndex];
        ILiquidityProvider lpProxy = ILiquidityProvider(proxyAddress);
        ProxyData storage proxyData = proxyAddressToData[proxyAddress];

        // rewards nav reallocated implicitly to buffer balance
        pendingRewardsContributionToNav = pendingRewardsContributionToNav.sub(
            proxyData.pendingRewardsContributionToNav
        );
        proxyData.pendingRewardsContributionToNav = 0;

        _unstake(proxyData.deployedBnt);
        vbnt.transfer(proxyAddress, proxyData.deployedBnt);

        uint256 rewardsClaimed = lpProxy.claimRewardsAndRemoveLiquidity();
        _calculateAndIncrementFee(rewardsClaimed, feeDivisors.claimFee);

        emit ClaimRemove(lowestActiveProxyIndex, rewardsClaimed);

        // we don't deduct totalAllocatedNav yet because we need to wait
        // 24 hours to `claimBalance`. Only rewards are immediately retrieved

        lowestActiveProxyIndex++;
        _updateAdminActiveTimestamp();
    }

    /*
     * @notice Second step in removal process
     * @notice Claims deposits balance 24 hrs after `claimRewardsAndRemoveLiquidity` called
     * @param proxyIndex: proxyIndex
     */
    function claimBalance(uint256 proxyIndex) external onlyOwnerOrManager {
        _claimBalance(proxyIndex);
        _updateAdminActiveTimestamp();
    }

    function emergencyClaimBalance(uint256 proxyIndex)
        external
        liquidationTimeElapsed
    {
        _claimBalance(proxyIndex);
    }

    function _claimBalance(uint256 _proxyIndex) private {
        address proxyAddress = proxyIndexToAddress[_proxyIndex];
        ProxyData memory proxyData = proxyAddressToData[proxyAddress];

        require(!proxyData.balanceClaimed, 'Already claimed');
        proxyAddressToData[proxyAddress].balanceClaimed = true;

        ILiquidityProvider lpProxy = ILiquidityProvider(proxyAddress);
        lpProxy.claimBalance();

        uint256 contributionToTotalAllocatedNav;

        uint256[] memory depositIds = proxyData.depositIds;
        for (uint256 i = 0; i < depositIds.length; i++) {
            contributionToTotalAllocatedNav = contributionToTotalAllocatedNav
                .add(depositIdToDeposit[depositIds[i]].latestContributionToNav);
        }

        emit ClaimBalance(_proxyIndex);

        // allocatedNav now becomes bnt buffer balance
        totalAllocatedNav = totalAllocatedNav.sub(
            contributionToTotalAllocatedNav
        );
    }

    /*
     * @notice Claims rewards from a proxy without restaking
     * @notice Will reset rewards multiplier - use sparingly when buffer balance needed
     */
    function claimRewards(uint256 proxyIndex) external onlyOwnerOrManager {
        address proxyAddress = proxyIndexToAddress[lowestActiveProxyIndex];
        ILiquidityProvider lpProxy = ILiquidityProvider(proxyAddress);

        uint256 proxyContributionToRewardsNav =
            getProxyAddressRewardsContributionToNav(proxyAddress);
        pendingRewardsContributionToNav = pendingRewardsContributionToNav.sub(
            proxyContributionToRewardsNav
        );
        proxyAddressToData[proxyAddress].pendingRewardsContributionToNav = 0;

        uint256 rewards = lpProxy.claimRewards();
        _calculateAndIncrementFee(rewards, feeDivisors.claimFee);
        _updateAdminActiveTimestamp();

        emit ClaimRewards(proxyIndex, rewards);
    }

    function getLiquidityProtectionContract()
        public
        view
        returns (ILiquidityProtection)
    {
        return
            ILiquidityProtection(
                contractRegistry.addressOf(liquidityProtectionName)
            );
    }

    function getStakingRewardsContract() public view returns (IStakingRewards) {
        return IStakingRewards(contractRegistry.addressOf(stakingRewardsName));
    }

    /* ========================================================================================= */
    /*                                             Utils                                         */
    /* ========================================================================================= */

    function getProxyAddressDepositIds(address proxyAddress)
        public
        view
        returns (uint256[] memory)
    {
        return proxyAddressToData[proxyAddress].depositIds;
    }

    function getProxyAddressRewardsContributionToNav(address proxyAddress)
        public
        view
        returns (uint256)
    {
        return proxyAddressToData[proxyAddress].pendingRewardsContributionToNav;
    }

    function changeLiquidityProviderImplementation(address newImplementation)
        external
        onlyOwner
    {
        queuedLiquidityProviderImplementation = newImplementation;
        lpImplementationChangedTimestamp = block.timestamp;
        emit KeyAddressChange();
    }

    function confirmLiquidityProviderImplementationChange() external onlyOwner {
        require(
            block.timestamp >
                lpImplementationChangedTimestamp.add(WAITING_PERIOD),
            'Too soon'
        );
        liquidityProviderImplementation = queuedLiquidityProviderImplementation;
    }

    function changeGovernanceAddress(address newAddress) external onlyOwner {
        queuedGovernanceAddress = newAddress;
        governanceAddressChangedTimestamp = block.timestamp;
        emit KeyAddressChange();
    }

    function confirmGovernanceAddressChange() external onlyOwner {
        require(
            block.timestamp >
                governanceAddressChangedTimestamp.add(WAITING_PERIOD),
            'Too soon'
        );
        bancorGovernance = IBancorGovernance(queuedGovernanceAddress);
    }

    /* ========================================================================================= */
    /*                                           Governance                                      */
    /* ========================================================================================= */

    // we should probably have a setter in case bancor gov address changes
    function _stake(uint256 _amount) private {
        bancorGovernance.stake(_amount);
    }

    function _unstake(uint256 _amount) private {
        bancorGovernance.unstake(_amount);
    }

    /* ========================================================================================= */
    /*                                               NAV                                         */
    /* ========================================================================================= */

    function getTargetBufferBalance() public view returns (uint256) {
        return getNav().div(BUFFER_TARGET);
    }

    function getNav() public view returns (uint256) {
        return
            totalAllocatedNav.add(getRewardsContributionToNav()).add(
                getBufferBalance()
            );
    }

    function getRewardsContributionToNav() public view returns (uint256) {
        uint256 unassessedFees =
            pendingRewardsContributionToNav.div(feeDivisors.claimFee);
        return pendingRewardsContributionToNav.sub(unassessedFees);
    }

    function getBufferBalance() public view returns (uint256) {
        uint256 bntBal = bnt.balanceOf(address(this));
        if (bntBal < withdrawableBntFees) return 0;
        return bntBal.sub(withdrawableBntFees);
    }

    function _calculateFee(uint256 _value, uint256 _feeDivisor)
        internal
        pure
        returns (uint256 fee)
    {
        if (_feeDivisor > 0 && _value > 0) {
            fee = _value.div(_feeDivisor);
        }
    }

    function _incrementWithdrawableBntFees(uint256 _feeAmount) private {
        withdrawableBntFees = withdrawableBntFees.add(_feeAmount);
    }

    function _calculateAndIncrementFee(uint256 _value, uint256 _feeDivisor)
        private
        returns (uint256 fee)
    {
        fee = _calculateFee(_value, _feeDivisor);
        _incrementWithdrawableBntFees(fee);
    }

    function setDelegate(
        address delegateRegistry,
        bytes32 id,
        address delegate
    ) external onlyOwnerOrManager {
        IDelegateRegistry(delegateRegistry).setDelegate(id, delegate);
    }

    /* ========================================================================================= */
    /*                                              Utils                                        */
    /* ========================================================================================= */

    function _approveIfNecessary(IERC20 _token, address _toApprove) private {
        if (_token.allowance(address(this), _toApprove) == 0) {
            _token.safeApprove(_toApprove, MAX_UINT);
        }
    }

    function getBancorNetworkContract() public view returns (IBancorNetwork) {
        return IBancorNetwork(contractRegistry.addressOf(bancorNetworkName));
    }

    function approveVbnt(address _toApprove) external onlyOwnerOrManager {
        vbnt.approve(_toApprove, MAX_UINT);
    }

    function pauseContract() external onlyOwnerOrManager {
        _pause();
    }

    function unpauseContract() external onlyOwnerOrManager {
        _unpause();
    }

    modifier onlyOwnerOrManager {
        require(
            msg.sender == owner() ||
                msg.sender == manager ||
                msg.sender == manager2,
            'Non-admin caller'
        );
        _;
    }

    modifier liquidationTimeElapsed {
        require(
            adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD) < block.timestamp,
            'Liquidation time not elapsed'
        );
        _;
    }

    /*
     * @notice manager == alternative admin caller to owner
     */
    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    /*
     * @notice manager2 == alternative admin caller to owner
     */
    function setManager2(address _manager2) external onlyOwner {
        manager2 = _manager2;
    }

    /*
     * @notice Inverse of fee i.e., a fee divisor of 100 == 1%
     * @notice Three fee types
     * @dev Mint fee 0 or <= 2%
     * @dev Burn fee 0 or <= 1%
     * @dev Claim fee 0 <= 4%
     */
    function setFeeDivisors(
        uint256 mintFeeDivisor,
        uint256 burnFeeDivisor,
        uint256 claimFeeDivisor
    ) external onlyOwner {
        _setFeeDivisors(mintFeeDivisor, burnFeeDivisor, claimFeeDivisor);
    }

    function _setFeeDivisors(
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor
    ) private {
        require(_mintFeeDivisor == 0 || _mintFeeDivisor >= 50, 'Invalid fee');
        require(_burnFeeDivisor == 0 || _burnFeeDivisor >= 100, 'Invalid fee');
        require(_claimFeeDivisor >= 25, 'Invalid fee');
        feeDivisors.mintFee = _mintFeeDivisor;
        feeDivisors.burnFee = _burnFeeDivisor;
        feeDivisors.claimFee = _claimFeeDivisor;
    }

    /*
     * @notice Records admin activity
     * @notice If not certified for a period exceeding LIQUIDATION_TIME_PERIOD,
     * emergencyCooldown and emergencyRedeem become available to non-admin caller
     */
    function _updateAdminActiveTimestamp() private {
        adminActiveTimestamp = block.timestamp;
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Errant ETH deposit");
    }
}