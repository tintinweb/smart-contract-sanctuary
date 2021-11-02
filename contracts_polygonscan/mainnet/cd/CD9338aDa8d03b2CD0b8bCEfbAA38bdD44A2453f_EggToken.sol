// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";
import "./ERC20Lockable.sol";
import "../interfaces/IBurning.sol";
import "../interfaces/IStaking.sol";
import "../libraries/SafeMathUint.sol";

/**
 * @dev EggToken is a {ERC20} implementation with various extensions
 * and custom functionality.
 */
contract EggToken is ERC20Burnable, ERC20Mintable, ERC20Pausable, ERC20Lockable {
  using SafeMathUint for uint256;

  IBurning _burning;
  IStaking _staking;

  /**
   * @dev Sets the values for {name} and {symbol}, allocates the `initialTotalSupply`.
   */
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialTotalSupply
  ) ERC20(name, symbol) {
    _totalSupply = initialTotalSupply;
    _balances[_msgSender()] = _balances[_msgSender()].add(_totalSupply);
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  /**
   * @dev Enables the burning, allocates the `burningBalance` to {IBurning} contract.
   */
  function setBurningContract(IBurning burning, uint256 burningBalance) external onlyOwner {
    _burning = burning;

    // _totalSupply = _totalSupply.add(burningBalance); no need to do this , total supply remains fixed
    _balances[_msgSender()] = _balances[_msgSender()].sub(burningBalance);
    _balances[address(burning)] = _balances[address(burning)].add(burningBalance);
    emit Transfer(address(0), address(burning), burningBalance);
  }

  /**
   * @dev Enables the staking via {IStaking} contract.
   */
  function setStakingContract(IStaking staking) external onlyOwner {
    _staking = staking;
  }

  /**
   * @dev Enables the token distribution with 'lock-in' period via {LockableDistribution} contract.
   *
   * See {ERC20Lockable}.
   */
  function setLockableDistributionContract(address lockableDistribution) external onlyOwner {
    _lockableDistribution = lockableDistribution;
  }

  /**
   * @dev Moves each of `values` in tokens from the caller's account to the list of `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event per each transfer.
   */
  function transferBatch(address[] calldata to, uint256[] calldata values) external returns (bool) {
    require(
      to.length == values.length && to.length > 0,
      "EggToken: to and values arrays should be equal in size and non-empty"
    );

    uint256 i = 0;
    while (i < to.length) {
      require(to[i] != address(0), "EggToken: transfer to the zero address");

      _beforeTokenTransfer(_msgSender(), to[i], values[i]);

      _balances[_msgSender()] = _balances[_msgSender()].sub(
        values[i],
        "EggToken: transfer amount exceeds balance"
      );
      _balances[to[i]] = _balances[to[i]].add(values[i]);
      emit Transfer(_msgSender(), to[i], values[i]);
      i++;
    }

    return true;
  }

  /**
   * @dev Triggers token burn through the {IBurning} `_burning` contract.
   *
   * Requirements:
   *
   * - only contract owner can trigger the burning.
   */
  function periodicBurn() external onlyOwner returns (bool success) {
    require(_burning.burn(), "Burning: not possible to perform the periodic token burn");

    return true;
  }

  /**
   * @dev Enables withdrawal of {ERC20} tokens accidentally sent to this smart contract.
   *
   * Requirements:
   *
   * - only contract owner can transfer out {ERC20} tokens.
   */
  function transferAnyERC20Token(address tokenAddress, uint256 tokens)
    external
    onlyOwner
    returns (bool success)
  {
    return IERC20(tokenAddress).transfer(_msgSender(), tokens);
  }

  /**
   * @dev See {ERC20-_beforeTokenTransfer},
   * {ERC20Pausable-_beforeTokenTransfer}, {ERC20Lockable-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable, ERC20Lockable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  /**
   * @dev Restricts token minting.
   *
   * Requirements:
   *
   * - only {IStaking} `_staking` contract can mint tokens (staking rewards).
   */
  function _beforeMint() internal virtual override {
    require(_msgSender() == address(_staking), "Staking: only staking contract can mint tokens");
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "./Context.sol";
import "./Ownable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context, Ownable {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event LogPaused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event LogUnpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
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
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!_paused, "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(_paused, "Pausable: not paused");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() external virtual whenNotPaused onlyOwner {
    _paused = true;
    emit LogPaused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() external virtual whenPaused onlyOwner {
    _paused = false;
    emit LogUnpaused(_msgSender());
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "./Context.sol";

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
abstract contract Ownable is Context {
  event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  address private _owner;

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _owner = _msgSender();
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
    require(_msgSender() == _owner, "Ownable: only contract owner can call this function.");
    _;
  }

  /**
   * @dev Checks if transaction sender account is an owner.
   */
  function isOwner() external view returns (bool) {
    return _msgSender() == _owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit LogOwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

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
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this;
    return msg.data;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "../utils/Pausable.sol";

/**
 * @dev Extension of {ERC20} with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
  /**
   * @dev See {ERC20-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    require(!paused(), "ERC20Pausable: token transfer while paused");
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows new tokens to be created,
 * in a way that can be recognized off-chain (via event analysis).
 */
abstract contract ERC20Mintable is Context, ERC20 {
  /**
   * @dev Creates `amount` tokens for `account`.
   *
   * See {ERC20-_mint}.
   */
  function mint(address account, uint256 amount) external virtual returns (bool success) {
    _mint(account, amount);
    return true;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "../utils/Context.sol";
import "./ERC20Pausable.sol";
import "../libraries/SafeMathUint.sol";

/**
 * @dev Extension of {ERC20} that allows to set up a 'lock-in' period for tokens,
 * which means a percentage of tokens received through from {LockableDistribution} contract
 * will not be transferrable until the end of 'lock-in' period.
 */
abstract contract ERC20Lockable is Context, ERC20Pausable {
  using SafeMathUint for uint256;

  address _lockableDistribution;

  struct BalanceLock {
    uint256 lockedAmount;
    uint256 unlockTimestamp;
  }
  mapping(address => BalanceLock) internal _balanceLocks;

  /**
   * @dev Creates a 'lock-in' period for `lockAmount` tokens on `lockFor` address
   * that lasts until `unlockTimestamp` timestamp.
   */
  function lock(
    address lockFor,
    uint256 lockAmount,
    uint256 unlockTimestamp
  ) external {
    require(
      _msgSender() == _lockableDistribution,
      "ERC20Lockable: only distribution contract can lock tokens"
    );

    _balanceLocks[lockFor].lockedAmount = lockAmount;
    _balanceLocks[lockFor].unlockTimestamp = unlockTimestamp;
  }

  /**
   * @dev Returns a 'lock-in' period details for `account` address.
   */
  function lockOf(address account)
    public
    view
    returns (uint256 lockedAmount, uint256 unlockTimestamp)
  {
    return (_balanceLocks[account].lockedAmount, _balanceLocks[account].unlockTimestamp);
  }

  /**
   * @dev Hook that restricts transfers according to the 'lock-in' period.
   *
   * See {ERC20-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - transferred amount should not include tokens that are 'locked-in'.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    uint256 lockedAmount;
    uint256 unlockTimestamp;
    (lockedAmount, unlockTimestamp) = lockOf(from);
    if (unlockTimestamp != 0 && block.timestamp < unlockTimestamp) {
      require(
        amount <= balanceOf(from).sub(lockedAmount),
        "ERC20Lockable: transfer amount exceeds the non-locked balance"
      );
    }
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "../utils/Context.sol";
import "./ERC20.sol";
import "../libraries/SafeMathUint.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
  using SafeMathUint for uint256;

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external virtual returns (bool success) {
    _burn(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for `accounts`'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) external virtual returns (bool success) {
    uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
      amount,
      "ERC20Burnable: burn amount exceeds allowance"
    );
    _approve(account, _msgSender(), decreasedAllowance);
    _burn(account, amount);
    return true;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

import "../utils/Context.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMathUint.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Functions revert instead of returning `false` on failure.
 * This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * The non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
  using SafeMathUint for uint256;

  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 internal _totalSupply;

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
  constructor(string memory name, string memory symbol) {
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
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public override view returns (uint256) {
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
  function allowance(address owner, address spender)
    public
    virtual
    override
    view
    returns (uint256)
  {
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
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
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
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

    _beforeMint();
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
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called before any token mint.
   */
  function _beforeMint() internal virtual {}
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMathUint` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUint {
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
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  /**
   * @dev Converts an unsigned integer to a signed integer,
   * Reverts when convertation overflows.
   *
   * Requirements:
   *
   * - Operation cannot overflow.
   */
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0, "SafeMath: convertation overflow");
    return b;
  }
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC900 standard with custom modifications.
 *
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
interface IStaking {
  /**
   * @dev Emitted when the `user` stakes an `amount` of tokens and
   * passes arbitrary `data`, therefore `total` is changed as well,
   * `personalStakeIndex`, `unlockedTimestamp` and `stakePercentageBasisPoints` are captured
   * according to the chosen stake option.
   */
  event LogStaked(
    address indexed user,
    uint256 amount,
    uint256 personalStakeIndex,
    uint256 unlockedTimestamp,
    uint16 stakePercentageBasisPoints,
    uint256 total,
    bytes data
  );

  /**
   * @dev Emitted when the `user` unstakes an `amount` of tokens and
   * passes arbitrary `data`, therefore `total` is changed as well,
   * `personalStakeIndex` and `stakeReward` are captured.
   */
  event LogUnstaked(
    address indexed user,
    uint256 amount,
    uint256 personalStakeIndex,
    uint256 stakeReward,
    uint256 total,
    bytes data
  );

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the user
   * @notice MUST trigger Staked event
   * @param stakeOptionIndex uint8 the chosen stake option
   * @param amount uint256 the amount of tokens to stake
   * @param data bytes optional data to include in the Stake event
   */
  function stake(
    uint8 stakeOptionIndex,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
   * @notice MUST trigger Staked event
   * @param stakeOptionIndex uint8 the chosen stake option
   * @param user address the address the tokens are staked for
   * @param amount uint256 the amount of tokens to stake
   * @param data bytes optional data to include in the Stake event
   */
  function stakeFor(
    uint8 stakeOptionIndex,
    address user,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @notice Unstakes tokens, this SHOULD return the given amount of tokens to the user,
   * if unstaking is currently not possible the function MUST revert
   * @notice MUST trigger Unstaked event
   * @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
   * @dev Stake reward is minted if function is called after the stake's `unlockTimestamp`.
   * @param personalStakeIndex uint256 index of the stake to withdraw in the personalStakes mapping
   * @param data bytes optional data to include in the Unstake event
   */
  function unstake(uint256 personalStakeIndex, bytes calldata data) external;

  /**
   * @notice Returns the current total of tokens staked for an address
   * @param addr address The address to query
   * @return uint256 The number of tokens staked for the given address
   */
  function totalStakedFor(address addr) external view returns (uint256);

  /**
   * @notice Returns the current total of tokens staked
   * @return uint256 The number of tokens staked in the contract
   */
  function totalStaked() external view returns (uint256);

  /**
   * @notice Address of the token being used by the staking interface
   * @return address The address of the ERC20 token used for staking
   */
  function token() external view returns (address);

  /**
   * @notice MUST return true if the optional history functions are implemented, otherwise false
   * @dev Since we don't implement the optional interface, this always returns false
   * @return bool Whether or not the optional history functions are implemented
   */
  function supportsHistory() external pure returns (bool);

  /**
   * @notice Sets the pairs of currently available staking options,
   * which will regulate the stake duration and reward percentage.
   * Stakes that were created through the old stake options will remain unchanged.
   * @param stakeDurations uint256[] array of stake option durations
   * @param stakePercentageBasisPoints uint16[] array of stake rewarding percentages (basis points)
   */
  function setStakingOptions(
    uint256[] memory stakeDurations,
    uint16[] memory stakePercentageBasisPoints
  ) external;

  /**
   * @notice Returns the pairs of currently available staking options,
   * so that staker can choose a suitable combination of
   * stake duration and reward percentage.
   * @return stakeOptionIndexes uint256[] array of the stake option indexes used in other functions of this contract
   * @return stakeDurations uint256[] array of stake option durations
   * @return stakePercentageBasisPoints uint16[] array of stake rewarding percentages (basis points)
   */
  function getStakingOptions()
    external
    view
    returns (
      uint256[] memory stakeOptionIndexes,
      uint256[] memory stakeDurations,
      uint16[] memory stakePercentageBasisPoints
    );

  /**
   * @dev Returns the stake indexes for
   * the last `amountToRetrieve` (with `offset` for pagination)
   * personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return uint256[] stake indexes array
   */
  function getPersonalStakeIndexes(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (uint256[] memory);

  /**
   * @dev Returns the stake unlock timestamps for
   * the last `amountToRetrieve` (with `offset` for pagination)
   * personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return uint256[] stake unlock timestamps array
   */
  function getPersonalStakeUnlockedTimestamps(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (uint256[] memory);

  /**
   * @dev Returns the stake values of
   * the last `amountToRetrieve` (with `offset` for pagination)
   * the personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return uint256[] stake values array
   */
  function getPersonalStakeActualAmounts(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (uint256[] memory);

  /**
   * @dev Returns the adresses of stake owners of
   * the last `amountToRetrieve` (with `offset` for pagination)
   * personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return address[] addresses of stake owners array
   */
  function getPersonalStakeForAddresses(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (address[] memory);

  /**
   * @dev Returns the stake rewards percentage (basis points) of
   * the last `amountToRetrieve` (with `offset` for pagination)
   * personal stakes created by `user`.
   * @param user address The address to query
   * @param amountToRetrieve uint256 Configures the amount of stakes to gather data for
   * @param offset uint256 Configures the offset for results pagination
   * @return uint256[] stake rewards percentage (basis points) array
   */
  function getPersonalStakePercentageBasisPoints(
    address user,
    uint256 amountToRetrieve,
    uint256 offset
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: Apache license 2.0

pragma solidity ^0.7.0;

/**
 * @dev Interface of the smart contract that configures rules
 * and executes burning of the passed {ERC20Burnable} token.
 */
interface IBurning {
  /**
   * @dev Emitted when `value` tokens are burned via `burningContract`.
   */
  event LogPeriodicTokenBurn(address indexed burningContract, uint256 value);

  /**
   * @dev Attempts to burn tokens.
   */
  function burn() external returns (bool);

  /**
   * @dev Returns a total amount of tokens that were already burned.
   */
  function burned() external view returns (uint256);

  /**
   * @dev Returns a total maximum amount of tokens to be burnt.
   */
  function burnLimit() external view returns (uint256);

  /**
   * @dev Returns a one-time amount to be burned upon each request.
   */
  function singleBurnAmount() external view returns (uint256);
}