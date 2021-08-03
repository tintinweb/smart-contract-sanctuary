/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: AGPL-3.0

// File contracts/dependencies/open-zeppelin/Context.sol

pragma solidity 0.7.5;

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


// File contracts/dependencies/open-zeppelin/IERC20.sol

pragma solidity 0.7.5;

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


// File contracts/dependencies/open-zeppelin/SafeMath.sol

pragma solidity 0.7.5;

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
    require(c >= a, 'SafeMath: addition overflow');

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
    return sub(a, b, 'SafeMath: subtraction overflow');
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
    return div(a, b, 'SafeMath: division by zero');
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    return mod(a, b, 'SafeMath: modulo by zero');
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


// File contracts/dependencies/open-zeppelin/Address.sol

pragma solidity 0.7.5;

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
    assembly {
      codehash := extcodehash(account)
    }
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}


// File contracts/dependencies/open-zeppelin/ERC20.sol

pragma solidity ^0.7.5;




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

    string internal _name;
    string internal _symbol;
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
    function name() virtual public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() virtual public view returns (string memory) {
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
    function decimals() virtual public view returns (uint8) {
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
}


// File contracts/dependencies/open-zeppelin/Ownable.sol

pragma solidity 0.7.5;

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


// File contracts/interfaces/IGovernancePowerDelegationERC20.sol

pragma solidity 0.7.5;

interface IGovernancePowerDelegationERC20 {

  enum DelegationType {
    VOTING_POWER,
    PROPOSITION_POWER
  }

  /**
   * @dev Emitted when a user delegates governance power to another user.
   *
   * @param  delegator       The delegator.
   * @param  delegatee       The delegatee.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  event DelegateChanged(
    address indexed delegator,
    address indexed delegatee,
    DelegationType delegationType
  );

  /**
   * @dev Emitted when an action changes the delegated power of a user.
   *
   * @param  user            The user whose delegated power has changed.
   * @param  amount          The new amount of delegated power for the user.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  event DelegatedPowerChanged(address indexed user, uint256 amount, DelegationType delegationType);

  /**
   * @dev Delegates a specific governance power to a delegatee.
   *
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function delegateByType(address delegatee, DelegationType delegationType) external virtual;

  /**
   * @dev Delegates all governance powers to a delegatee.
   *
   * @param  delegatee  The user to which the power will be delegated.
   */
  function delegate(address delegatee) external virtual;

  /**
   * @dev Returns the delegatee of an user.
   *
   * @param  delegator       The address of the delegator.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function getDelegateeByType(address delegator, DelegationType delegationType)
    external
    view
    virtual
    returns (address);

  /**
   * @dev Returns the current delegated power of a user. The current power is the power delegated
   *  at the time of the last snapshot.
   *
   * @param  user            The user whose power to query.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerCurrent(address user, DelegationType delegationType)
    external
    view
    virtual
    returns (uint256);

  /**
   * @dev Returns the delegated power of a user at a certain block.
   *
   * @param  user            The user whose power to query.
   * @param  blockNumber     The block number at which to get the user's power.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerAtBlock(
    address user,
    uint256 blockNumber,
    DelegationType delegationType
  )
    external
    view
    virtual
    returns (uint256);
}


// File contracts/governance/token/GovernancePowerDelegationERC20Mixin.sol

pragma solidity 0.7.5;



/**
 * @title GovernancePowerDelegationERC20Mixin
 * @author dYdX
 *
 * @dev Provides support for two types of governance powers, both endowed by the governance
 *  token, and separately delegatable. Provides functions for delegation and for querying a user's
 *  power at a certain block number.
 */
abstract contract GovernancePowerDelegationERC20Mixin is
  ERC20,
  IGovernancePowerDelegationERC20
{
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice EIP-712 typehash for delegation by signature of a specific governance power type.
  bytes32 public constant DELEGATE_BY_TYPE_TYPEHASH = keccak256(
    'DelegateByType(address delegatee,uint256 type,uint256 nonce,uint256 expiry)'
  );

  /// @notice EIP-712 typehash for delegation by signature of all governance powers.
  bytes32 public constant DELEGATE_TYPEHASH = keccak256(
    'Delegate(address delegatee,uint256 nonce,uint256 expiry)'
  );

  // ============ Structs ============

  /// @dev Snapshot of a value on a specific block, used to track voting power for proposals.
  struct Snapshot {
    uint128 blockNumber;
    uint128 value;
  }

  // ============ External Functions ============

  /**
   * @notice Delegates a specific governance power to a delegatee.
   *
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function delegateByType(
    address delegatee,
    DelegationType delegationType
  )
    external
    override
  {
    _delegateByType(msg.sender, delegatee, delegationType);
  }

  /**
   * @notice Delegates all governance powers to a delegatee.
   *
   * @param  delegatee  The address to delegate power to.
   */
  function delegate(
    address delegatee
  )
    external
    override
  {
    _delegateByType(msg.sender, delegatee, DelegationType.VOTING_POWER);
    _delegateByType(msg.sender, delegatee, DelegationType.PROPOSITION_POWER);
  }

  /**
   * @notice Returns the delegatee of a user.
   *
   * @param  delegator       The address of the delegator.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function getDelegateeByType(
    address delegator,
    DelegationType delegationType
  )
    external
    override
    view
    returns (address)
  {
    (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

    return _getDelegatee(delegator, delegates);
  }

  /**
   * @notice Returns the current power of a user. The current power is the power delegated
   *  at the time of the last snapshot.
   *
   * @param  user            The user whose power to query.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerCurrent(
    address user,
    DelegationType delegationType
  )
    external
    override
    view
    returns (uint256)
  {
    (
      mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotsCounts,
      // delegates
    ) = _getDelegationDataByType(delegationType);

    return _searchByBlockNumber(snapshots, snapshotsCounts, user, block.number);
  }

  /**
   * @notice Returns the power of a user at a certain block.
   *
   * @param  user            The user whose power to query.
   * @param  blockNumber     The block number at which to get the user's power.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerAtBlock(
    address user,
    uint256 blockNumber,
    DelegationType delegationType
  )
    external
    override
    view
    returns (uint256)
  {
    (
      mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotsCounts,
      // delegates
    ) = _getDelegationDataByType(delegationType);

    return _searchByBlockNumber(snapshots, snapshotsCounts, user, blockNumber);
  }

  // ============ Internal Functions ============

  /**
   * @dev Delegates one specific power to a delegatee.
   *
   * @param  delegator       The user whose power to delegate.
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function _delegateByType(
    address delegator,
    address delegatee,
    DelegationType delegationType
  )
    internal
  {
    require(
      delegatee != address(0),
      'INVALID_DELEGATEE'
    );

    (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

    uint256 delegatorBalance = balanceOf(delegator);

    address previousDelegatee = _getDelegatee(delegator, delegates);

    delegates[delegator] = delegatee;

    _moveDelegatesByType(previousDelegatee, delegatee, delegatorBalance, delegationType);
    emit DelegateChanged(delegator, delegatee, delegationType);
  }

  /**
   * @dev Moves power from one user to another.
   *
   * @param  from            The user from which delegated power is moved.
   * @param  to              The user that will receive the delegated power.
   * @param  amount          The amount of power to be moved.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function _moveDelegatesByType(
    address from,
    address to,
    uint256 amount,
    DelegationType delegationType
  )
    internal
  {
    if (from == to) {
      return;
    }

    (
      mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotsCounts,
      // delegates
    ) = _getDelegationDataByType(delegationType);

    if (from != address(0)) {
      uint256 previous = 0;
      uint256 fromSnapshotsCount = snapshotsCounts[from];

      if (fromSnapshotsCount != 0) {
        previous = snapshots[from][fromSnapshotsCount - 1].value;
      } else {
        previous = balanceOf(from);
      }

      uint256 newAmount = previous.sub(amount);
      _writeSnapshot(
        snapshots,
        snapshotsCounts,
        from,
        uint128(newAmount)
      );

      emit DelegatedPowerChanged(from, newAmount, delegationType);
    }

    if (to != address(0)) {
      uint256 previous = 0;
      uint256 toSnapshotsCount = snapshotsCounts[to];
      if (toSnapshotsCount != 0) {
        previous = snapshots[to][toSnapshotsCount - 1].value;
      } else {
        previous = balanceOf(to);
      }

      uint256 newAmount = previous.add(amount);
      _writeSnapshot(
        snapshots,
        snapshotsCounts,
        to,
        uint128(newAmount)
      );

      emit DelegatedPowerChanged(to, newAmount, delegationType);
    }
  }

  /**
   * @dev Searches for a balance snapshot by block number using binary search.
   *
   * @param  snapshots        The mapping of snapshots by user.
   * @param  snapshotsCounts  The mapping of the number of snapshots by user.
   * @param  user             The user for which the snapshot is being searched.
   * @param  blockNumber      The block number being searched.
   */
  function _searchByBlockNumber(
    mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
    mapping(address => uint256) storage snapshotsCounts,
    address user,
    uint256 blockNumber
  )
    internal
    view
    returns (uint256)
  {
    require(
      blockNumber <= block.number,
      'INVALID_BLOCK_NUMBER'
    );

    uint256 snapshotsCount = snapshotsCounts[user];

    if (snapshotsCount == 0) {
      return balanceOf(user);
    }

    // First check most recent balance
    if (snapshots[user][snapshotsCount - 1].blockNumber <= blockNumber) {
      return snapshots[user][snapshotsCount - 1].value;
    }

    // Next check implicit zero balance
    if (snapshots[user][0].blockNumber > blockNumber) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = snapshotsCount - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Snapshot memory snapshot = snapshots[user][center];
      if (snapshot.blockNumber == blockNumber) {
        return snapshot.value;
      } else if (snapshot.blockNumber < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return snapshots[user][lower].value;
  }

  /**
   * @dev Returns delegation data (snapshot, snapshotsCount, delegates) by delegation type.
   *
   *  Note: This mixin contract does not itself define any storage, and we require the inheriting
   *  contract to implement this method to provide access to the relevant mappings in storage.
   *  This pattern was implemented by Aave for legacy reasons and we have decided not to change it.
   *
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function _getDelegationDataByType(
    DelegationType delegationType
  )
    internal
    virtual
    view
    returns (
      mapping(address => mapping(uint256 => Snapshot)) storage, // snapshots
      mapping(address => uint256) storage, // snapshotsCount
      mapping(address => address) storage // delegates
    );

  /**
   * @dev Writes a snapshot of a user's token/power balance.
   *
   * @param  snapshots        The mapping of snapshots by user.
   * @param  snapshotsCounts  The mapping of the number of snapshots by user.
   * @param  owner            The user whose power to snapshot.
   * @param  newValue         The new balance to snapshot at the current block.
   */
  function _writeSnapshot(
    mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
    mapping(address => uint256) storage snapshotsCounts,
    address owner,
    uint128 newValue
  )
    internal
  {
    uint128 currentBlock = uint128(block.number);

    uint256 ownerSnapshotsCount = snapshotsCounts[owner];
    mapping(uint256 => Snapshot) storage ownerSnapshots = snapshots[owner];

    if (
      ownerSnapshotsCount != 0 &&
      ownerSnapshots[ownerSnapshotsCount - 1].blockNumber == currentBlock
    ) {
      // Doing multiple operations in the same block
      ownerSnapshots[ownerSnapshotsCount - 1].value = newValue;
    } else {
      ownerSnapshots[ownerSnapshotsCount] = Snapshot(currentBlock, newValue);
      snapshotsCounts[owner] = ownerSnapshotsCount + 1;
    }
  }

  /**
   * @dev Returns the delegatee of a user. If a user never performed any delegation, their
   *  delegated address will be 0x0, in which case we return the user's own address.
   *
   * @param  delegator  The address of the user for which return the delegatee.
   * @param  delegates  The mapping of delegates for a particular type of delegation.
   */
  function _getDelegatee(
    address delegator,
    mapping(address => address) storage delegates
  )
    internal
    view
    returns (address)
  {
    address previousDelegatee = delegates[delegator];

    if (previousDelegatee == address(0)) {
      return delegator;
    }

    return previousDelegatee;
  }
}


// File contracts/governance/token/DydxToken.sol

pragma solidity 0.7.5;




/**
 * @title DydxToken
 * @author dYdX
 *
 * @notice The dYdX governance token.
 */
contract DydxToken is
  GovernancePowerDelegationERC20Mixin,
  Ownable
{
  using SafeMath for uint256;

  // ============ Events ============

  /**
   * @dev Emitted when an address has been added to or removed from the token transfer allowlist.
   *
   * @param  account    Address that was added to or removed from the token transfer allowlist.
   * @param  isAllowed  True if the address was added to the allowlist, false if removed.
   */
  event TransferAllowlistUpdated(
    address account,
    bool isAllowed
  );

  /**
   * @dev Emitted when the transfer restriction timestamp is reassigned.
   *
   * @param  transfersRestrictedBefore  The new timestamp on and after which non-allowlisted
   *                                    transfers may occur.
   */
  event TransfersRestrictedBeforeUpdated(
    uint256 transfersRestrictedBefore
  );

  // ============ Constants ============

  string internal constant NAME = 'dYdX';
  string internal constant SYMBOL = 'DYDX';

  uint256 public constant INITIAL_SUPPLY = 1_000_000_000 ether;

  bytes32 public immutable DOMAIN_SEPARATOR;
  bytes public constant EIP712_VERSION = '1';
  bytes32 public constant EIP712_DOMAIN = keccak256(
    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
  );
  bytes32 public constant PERMIT_TYPEHASH = keccak256(
    'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
  );

  /// @notice Minimum time between mints.
  uint256 public constant MINT_MIN_INTERVAL = 365 days;

  /// @notice Cap on the percentage of the total supply that can be minted at each mint.
  ///  Denominated in percentage points (units out of 100).
  uint256 public immutable MINT_MAX_PERCENT;

  /// @notice The timestamp on and after which the transfer restriction must be lifted.
  uint256 public immutable TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN;

  // ============ Storage ============

  /// @dev Mapping from (owner) => (next valid nonce) for EIP-712 signatures.
  mapping(address => uint256) internal _nonces;

  mapping(address => mapping(uint256 => Snapshot)) public _votingSnapshots;
  mapping(address => uint256) public _votingSnapshotsCounts;
  mapping(address => address) public _votingDelegates;

  mapping(address => mapping(uint256 => Snapshot)) public _propositionPowerSnapshots;
  mapping(address => uint256) public _propositionPowerSnapshotsCounts;
  mapping(address => address) public _propositionPowerDelegates;

  /// @notice Snapshots of the token total supply, at each block where the total supply has changed.
  mapping(uint256 => Snapshot) public _totalSupplySnapshots;

  /// @notice Number of snapshots of the token total supply.
  uint256 public _totalSupplySnapshotsCount;

  /// @notice Allowlist of addresses which may send or receive tokens while transfers are
  ///  otherwise restricted.
  mapping(address => bool) public _tokenTransferAllowlist;

  /// @notice The timestamp on and after which minting may occur.
  uint256 public _mintingRestrictedBefore;

  /// @notice The timestamp on and after which non-allowlisted transfers may occur.
  uint256 public _transfersRestrictedBefore;

  // ============ Constructor ============

  /**
   * @notice Constructor.
   *
   * @param  distributor                           The address which will receive the initial supply of tokens.
   * @param  transfersRestrictedBefore             Timestamp, before which transfers are restricted unless the
   *                                               origin or destination address is in the allowlist.
   * @param  transferRestrictionLiftedNoLaterThan  Timestamp, which is the maximum timestamp that transfer
   *                                               restrictions can be extended to.
   * @param  mintingRestrictedBefore               Timestamp, before which minting is not allowed.
   * @param  mintMaxPercent                        Cap on the percentage of the total supply that can be minted at
   *                                               each mint.
   */
  constructor(
    address distributor,
    uint256 transfersRestrictedBefore,
    uint256 transferRestrictionLiftedNoLaterThan,
    uint256 mintingRestrictedBefore,
    uint256 mintMaxPercent
  )
    ERC20(NAME, SYMBOL)
  {
    uint256 chainId;

    // solium-disable-next-line
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712_DOMAIN,
        keccak256(bytes(NAME)),
        keccak256(bytes(EIP712_VERSION)),
        chainId,
        address(this)
      )
    );

    // Validate and set parameters.
    require(
      transfersRestrictedBefore > block.timestamp,
      'TRANSFERS_RESTRICTED_BEFORE_TOO_EARLY'
    );
    require(
      transfersRestrictedBefore <= transferRestrictionLiftedNoLaterThan,
      'MAX_TRANSFER_RESTRICTION_TOO_EARLY'
    );
    require(
      mintingRestrictedBefore > block.timestamp,
      'MINTING_RESTRICTED_BEFORE_TOO_EARLY'
    );
    _transfersRestrictedBefore = transfersRestrictedBefore;
    TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN = transferRestrictionLiftedNoLaterThan;
    _mintingRestrictedBefore = mintingRestrictedBefore;
    MINT_MAX_PERCENT = mintMaxPercent;

    // Mint the initial supply.
    _mint(distributor, INITIAL_SUPPLY);

    emit TransfersRestrictedBeforeUpdated(transfersRestrictedBefore);
  }

  // ============ Other Functions ============

  /**
   * @notice Adds addresses to the token transfer allowlist. Reverts if any of the addresses
   *  already exist in the allowlist. Only callable by owner.
   *
   * @param  addressesToAdd  Addresses to add to the token transfer allowlist.
   */
  function addToTokenTransferAllowlist(
    address[] calldata addressesToAdd
  )
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addressesToAdd.length; i++) {
      require(
        !_tokenTransferAllowlist[addressesToAdd[i]],
        'ADDRESS_EXISTS_IN_TRANSFER_ALLOWLIST'
      );
      _tokenTransferAllowlist[addressesToAdd[i]] = true;
      emit TransferAllowlistUpdated(addressesToAdd[i], true);
    }
  }

  /**
   * @notice Removes addresses from the token transfer allowlist. Reverts if any of the addresses
   *  don't exist in the allowlist. Only callable by owner.
   *
   * @param  addressesToRemove  Addresses to remove from the token transfer allowlist.
   */
  function removeFromTokenTransferAllowlist(
    address[] calldata addressesToRemove
  )
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addressesToRemove.length; i++) {
      require(
        _tokenTransferAllowlist[addressesToRemove[i]],
        'ADDRESS_DOES_NOT_EXIST_IN_TRANSFER_ALLOWLIST'
      );
      _tokenTransferAllowlist[addressesToRemove[i]] = false;
      emit TransferAllowlistUpdated(addressesToRemove[i], false);
    }
  }

  /**
   * @notice Updates the transfer restriction. Reverts if the transfer restriction has already passed,
   *  the new transfer restriction is earlier than the previous one, or the new transfer restriction is
   *  after the maximum transfer restriction.
   *
   * @param  transfersRestrictedBefore  The timestamp on and after which non-allowlisted transfers may occur.
   */
  function updateTransfersRestrictedBefore(
    uint256 transfersRestrictedBefore
  )
    external
    onlyOwner
  {
    uint256 previousTransfersRestrictedBefore = _transfersRestrictedBefore;
    require(
      block.timestamp < previousTransfersRestrictedBefore,
      'TRANSFER_RESTRICTION_ENDED'
    );
    require(
      previousTransfersRestrictedBefore <= transfersRestrictedBefore,
      'NEW_TRANSFER_RESTRICTION_TOO_EARLY'
    );
    require(
      transfersRestrictedBefore <= TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN,
      'AFTER_MAX_TRANSFER_RESTRICTION'
    );

    _transfersRestrictedBefore = transfersRestrictedBefore;

    emit TransfersRestrictedBeforeUpdated(transfersRestrictedBefore);
  }

  /**
   * @notice Mint new tokens. Only callable by owner after the required time period has elapsed.
   *
   * @param  recipient  The address to receive minted tokens.
   * @param  amount     The number of tokens to mint.
   */
  function mint(
    address recipient,
    uint256 amount
  )
    external
    onlyOwner
  {
    require(
      block.timestamp >= _mintingRestrictedBefore,
      'MINT_TOO_EARLY'
    );
    require(
      amount <= totalSupply().mul(MINT_MAX_PERCENT).div(100),
      'MAX_MINT_EXCEEDED'
    );

    // Update the next allowed minting time.
    _mintingRestrictedBefore = block.timestamp.add(MINT_MIN_INTERVAL);

    // Mint the amount.
    _mint(recipient, amount);
  }

  /**
   * @notice Implements the permit function as specified in EIP-2612.
   *
   * @param  owner     Address of the token owner.
   * @param  spender   Address of the spender.
   * @param  value     Amount of allowance.
   * @param  deadline  Expiration timestamp for the signature.
   * @param  v         Signature param.
   * @param  r         Signature param.
   * @param  s         Signature param.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
  {
    require(
      owner != address(0),
      'INVALID_OWNER'
    );
    require(
      block.timestamp <= deadline,
      'INVALID_EXPIRATION'
    );
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );

    require(
      owner == ecrecover(digest, v, r, s),
      'INVALID_SIGNATURE'
    );
    _nonces[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }

  /**
   * @notice Get the next valid nonce for EIP-712 signatures.
   *
   *  This nonce should be used when signing for any of the following functions:
   *   - permit()
   *   - delegateByTypeBySig()
   *   - delegateBySig()
   */
  function nonces(
    address owner
  )
    external
    view
    returns (uint256)
  {
    return _nonces[owner];
  }

  function transfer(
    address recipient,
    uint256 amount
  )
    public
    override
    returns (bool)
  {
    _requireTransferAllowed(_msgSender(), recipient);
    return super.transfer(recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  )
    public
    override
    returns (bool)
  {
    _requireTransferAllowed(sender, recipient);
    return super.transferFrom(sender, recipient, amount);
  }

  /**
   * @dev Override _mint() to write a snapshot whenever the total supply changes.
   *
   *  These snapshots are intended to be used by the governance strategy.
   *
   *  Note that the ERC20 _burn() function is never used. If desired, an official burn mechanism
   *  could be implemented external to this contract, and accounted for in the governance strategy.
   */
  function _mint(
    address account,
    uint256 amount
  )
    internal
    override
  {
    super._mint(account, amount);

    uint256 snapshotsCount = _totalSupplySnapshotsCount;
    uint128 currentBlock = uint128(block.number);
    uint128 newValue = uint128(totalSupply());

    // Note: There is no special case for the total supply being updated multiple times in the same
    // block. That should never occur.
    _totalSupplySnapshots[snapshotsCount] = Snapshot(currentBlock, newValue);
    _totalSupplySnapshotsCount = snapshotsCount.add(1);
  }

  function _requireTransferAllowed(
    address sender,
    address recipient
  )
    view
    internal
  {
    // Compare against the constant `TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN` first
    // to avoid additional gas costs from reading from storage.
    if (
      block.timestamp < TRANSFER_RESTRICTION_LIFTED_NO_LATER_THAN &&
      block.timestamp < _transfersRestrictedBefore
    ) {
      // While transfers are restricted, a transfer is permitted if either the sender or the
      // recipient is on the allowlist.
      require(
        _tokenTransferAllowlist[sender] || _tokenTransferAllowlist[recipient],
        'NON_ALLOWLIST_TRANSFERS_DISABLED'
      );
    }
  }

  /**
   * @dev Writes a snapshot before any transfer operation, including: _transfer, _mint and _burn.
   *  - On _transfer, it writes snapshots for both 'from' and 'to'.
   *  - On _mint, only for `to`.
   *  - On _burn, only for `from`.
   *
   * @param  from    The sender.
   * @param  to      The recipient.
   * @param  amount  The amount being transfered.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  )
    internal
    override
  {
    address votingFromDelegatee = _getDelegatee(from, _votingDelegates);
    address votingToDelegatee = _getDelegatee(to, _votingDelegates);

    _moveDelegatesByType(
      votingFromDelegatee,
      votingToDelegatee,
      amount,
      DelegationType.VOTING_POWER
    );

    address propPowerFromDelegatee = _getDelegatee(from, _propositionPowerDelegates);
    address propPowerToDelegatee = _getDelegatee(to, _propositionPowerDelegates);

    _moveDelegatesByType(
      propPowerFromDelegatee,
      propPowerToDelegatee,
      amount,
      DelegationType.PROPOSITION_POWER
    );
  }

  function _getDelegationDataByType(
    DelegationType delegationType
  )
    internal
    override
    view
    returns (
      mapping(address => mapping(uint256 => Snapshot)) storage, // snapshots
      mapping(address => uint256) storage, // snapshots count
      mapping(address => address) storage // delegatees list
    )
  {
    if (delegationType == DelegationType.VOTING_POWER) {
      return (_votingSnapshots, _votingSnapshotsCounts, _votingDelegates);
    } else {
      return (
        _propositionPowerSnapshots,
        _propositionPowerSnapshotsCounts,
        _propositionPowerDelegates
      );
    }
  }

  /**
   * @dev Delegates specific governance power from signer to `delegatee` using an EIP-712 signature.
   *
   * @param  delegatee       The address to delegate votes to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   * @param  nonce           The signer's nonce for EIP-712 signatures on this contract.
   * @param  expiry          Expiration timestamp for the signature.
   * @param  v               Signature param.
   * @param  r               Signature param.
   * @param  s               Signature param.
   */
  function delegateByTypeBySig(
    address delegatee,
    DelegationType delegationType,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
  {
    bytes32 structHash = keccak256(
      abi.encode(DELEGATE_BY_TYPE_TYPEHASH, delegatee, uint256(delegationType), nonce, expiry)
    );
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash));
    address signer = ecrecover(digest, v, r, s);
    require(
      signer != address(0),
      'INVALID_SIGNATURE'
    );
    require(
      nonce == _nonces[signer]++,
      'INVALID_NONCE'
    );
    require(
      block.timestamp <= expiry,
      'INVALID_EXPIRATION'
    );
    _delegateByType(signer, delegatee, delegationType);
  }

  /**
   * @dev Delegates both governance powers from signer to `delegatee` using an EIP-712 signature.
   *
   * @param  delegatee  The address to delegate votes to.
   * @param  nonce      The signer's nonce for EIP-712 signatures on this contract.
   * @param  expiry     Expiration timestamp for the signature.
   * @param  v          Signature param.
   * @param  r          Signature param.
   * @param  s          Signature param.
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    public
  {
    bytes32 structHash = keccak256(abi.encode(DELEGATE_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash));
    address signer = ecrecover(digest, v, r, s);
    require(
      signer != address(0),
      'INVALID_SIGNATURE'
    );
    require(
      nonce == _nonces[signer]++,
      'INVALID_NONCE'
    );
    require(
      block.timestamp <= expiry,
      'INVALID_EXPIRATION'
    );
    _delegateByType(signer, delegatee, DelegationType.VOTING_POWER);
    _delegateByType(signer, delegatee, DelegationType.PROPOSITION_POWER);
  }
}