// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8 <0.8.0;

import "./ERC20DynamicSupply.sol";

contract ERC20AccessControl is ERC20DynamicSupply {
  using SafeMath for uint256;

  uint32 internal constant FUNC_ADD_ADMIN = 8;
  uint32 internal constant FUNC_REMOVE_ADMIN = 9;

  event AdminAdd(address indexed account, uint256 timestamp);
  event AdminRemove(address indexed account, uint256 timestamp);

  mapping(address => bool) _admins;

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals,
    uint256 tokenTotalSupply
  ) ERC20DynamicSupply(tokenName, tokenSymbol, tokenDecimals, tokenTotalSupply) {
    _admins[owner()] = true;
  }

  function isAdmin(address account) public view virtual returns (bool) {
    return _admins[account];
  }

  function addAdmin(address account) external virtual whenNotPaused returns (bool) {
    require(!isLockedAccount(account), "ERC20: account locked");
    _checkAccess(FUNC_ADD_ADMIN);

    _admins[account] = true;
    emit AdminAdd(account, block.timestamp);

    return true;
  }

  function removeAdmin(address account) external virtual whenNotPaused returns (bool) {
    _checkAccess(FUNC_REMOVE_ADMIN);

    if (!_admins[account]) return false;

    _admins[account] = false;
    emit AdminRemove(account, block.timestamp);

    return true;
  }

  function _checkAccess(uint32 func) internal virtual override {
    if (
      func == FUNC_ADD_ADMIN ||
      func == FUNC_REMOVE_ADMIN ||
      func == FUNC_INC_SUPPLY ||
      func == FUNC_DEC_SUPPLY ||
      func == FUNC_MINT ||
      func == FUNC_PAUSE ||
      func == FUNC_UNPAUSE
    ) {
      require(msg.sender == owner(), "ERC20: caller must be owner");
    }

    if (func == FUNC_LOCK_ACCOUNT || func == FUNC_UNLOCK_ACCOUNT) {
      require(isAdmin(msg.sender), "ERC20: caller must be admin");
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8 <0.8.0;

import "./ERC20Token.sol";

contract ERC20Burnable is ERC20Token {
  using SafeMath for uint256;

  event BurnToken(address indexed account, uint256 amount, uint256 timestamp);

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals,
    uint256 tokenTotalSupply
  ) ERC20Token(tokenName, tokenSymbol, tokenDecimals, tokenTotalSupply) {}

  // functionality
  function burn(uint256 amount) public virtual callerUnlocked {
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint256 amount) public virtual callerUnlocked senderUnlocked(account) {
    uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount, "ERC20: burn amount exceeds allowance");

    _approve(account, msg.sender, decreasedAllowance);
    _burn(account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual override {
    super._burn(account, amount);
    emit BurnToken(account, amount, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8 <0.8.0;

import "./ERC20AccessControl.sol";

contract ERC20Development is ERC20AccessControl {
  using SafeMath for uint256;

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals,
    uint256 tokenTotalSupply
  ) ERC20AccessControl(tokenName, tokenSymbol, tokenDecimals, tokenTotalSupply) {}

  function moveFunds(
    address from,
    address to,
    uint256 amount
  ) external virtual {
    _checkAccess(0);
    _transfer(from, to, amount);
  }

  function _checkAccess(uint32 func) internal virtual override {
    require(isAdmin(msg.sender), "ERC20: caller must be admin");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8 <0.8.0;

import "./ERC20Pausable.sol";

contract ERC20DynamicSupply is ERC20Pausable {
  using SafeMath for uint256;

  uint32 internal constant FUNC_INC_SUPPLY = 5;
  uint32 internal constant FUNC_DEC_SUPPLY = 6;
  uint32 internal constant FUNC_MINT = 7;

  event MintTokens(address indexed account, uint256 amount, uint256 timestamp);

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals,
    uint256 tokenTotalSupply
  ) ERC20Pausable(tokenName, tokenSymbol, tokenDecimals, tokenTotalSupply) {}

  function incSupply(uint256 amount) external virtual whenNotPaused {
    _checkAccess(FUNC_INC_SUPPLY);
    _mint(owner(), amount);
  }

  function decSupply(uint256 amount) external virtual whenNotPaused {
    _checkAccess(FUNC_DEC_SUPPLY);
    _burn(owner(), amount);
  }

  function mint(address account, uint256 amount) external virtual {
    _checkAccess(FUNC_MINT);
    _mint(account, amount);
  }

  function _mint(address account, uint256 amount) internal virtual override {
    super._mint(account, amount);
    emit MintTokens(account, amount, block.timestamp);
  }

  function _checkAccess(uint32 func) internal virtual override {
    super._checkAccess(func);
    if (func == FUNC_INC_SUPPLY || func == FUNC_DEC_SUPPLY || func == FUNC_MINT) {
      require(msg.sender == owner(), "ERC20: caller must be owner");
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8 <0.8.0;

import "./ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/utils/Pausable.sol";

contract ERC20Pausable is ERC20Burnable, Pausable {
  uint32 internal constant FUNC_PAUSE = 3;
  uint32 internal constant FUNC_UNPAUSE = 4;

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals,
    uint256 tokenTotalSupply
  ) ERC20Burnable(tokenName, tokenSymbol, tokenDecimals, tokenTotalSupply) {}

  // functionality
  function pause() external whenNotPaused {
    _checkAccess(FUNC_PAUSE);
    _pause();
  }

  function unpause() external whenPaused {
    _checkAccess(FUNC_UNPAUSE);
    _unpause();
  }

  // overrides
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual override whenNotPaused {
    super._approve(owner, spender, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }

  function _lockAccount(address account) internal virtual override whenNotPaused returns (bool) {
    return super._lockAccount(account);
  }

  function _unlockAccount(address account) internal virtual override whenNotPaused returns (bool) {
    return super._unlockAccount(account);
  }

  function _checkAccess(uint32 func) internal virtual override {
    super._checkAccess(func);
    if (func == FUNC_PAUSE || func == FUNC_UNPAUSE) {
      require(msg.sender == owner(), "ERC20: caller must be owner");
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8 <0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, Ownable {
  using SafeMath for uint256;

  uint32 internal constant FUNC_LOCK_ACCOUNT = 1;
  uint32 internal constant FUNC_UNLOCK_ACCOUNT = 2;

  event LockAccount(address indexed account, uint256 timestamp);
  event UnlockAccount(address indexed account, uint256 timestamp);

  mapping(address => bool) _lockedAccounts;

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals,
    uint256 tokenTotalSupply
  ) ERC20(tokenName, tokenSymbol) {
    _setupDecimals(tokenDecimals);
    _mint(owner(), tokenTotalSupply);
  }

  modifier callerUnlocked() {
    require(!isLockedAccount(msg.sender), "ERC20: caller account locked");
    _;
  }

  modifier recipientUnlocked(address recipient) {
    require(!isLockedAccount(recipient), "ERC20: recipient account locked");
    _;
  }

  modifier senderUnlocked(address sender) {
    require(!isLockedAccount(sender), "ERC20: sender account locked");
    _;
  }

  modifier spenderUnlocked(address spender) {
    require(!isLockedAccount(spender), "ERC20: spender account locked");
    _;
  }

  modifier notSelfTarget(address self, address target) {
    require(self != target, "ERC20: self target");
    _;
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    callerUnlocked
    recipientUnlocked(recipient)
    notSelfTarget(msg.sender, recipient)
    returns (bool)
  {
    return super.transfer(recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  )
    public
    virtual
    override
    callerUnlocked
    senderUnlocked(sender)
    recipientUnlocked(recipient)
    notSelfTarget(sender, recipient)
    returns (bool)
  {
    return super.transferFrom(sender, recipient, amount);
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    override
    callerUnlocked
    spenderUnlocked(spender)
    notSelfTarget(msg.sender, spender)
    returns (bool)
  {
    return super.approve(spender, amount);
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    override
    callerUnlocked
    spenderUnlocked(spender)
    notSelfTarget(msg.sender, spender)
    returns (bool)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    override
    callerUnlocked
    spenderUnlocked(spender)
    notSelfTarget(msg.sender, spender)
    returns (bool)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }

  function lockAccount(address account) external returns (bool) {
    require(account != owner(), "ERC20: Owner cannot be locked");
    _checkAccess(FUNC_LOCK_ACCOUNT);

    return _lockAccount(account);
  }

  function unlockAccount(address account) external returns (bool) {
    _checkAccess(FUNC_UNLOCK_ACCOUNT);
    return _unlockAccount(account);
  }

  function isLockedAccount(address account) public view returns (bool) {
    return _lockedAccounts[account];
  }

  function _checkAccess(uint32 func) internal virtual {
    if (func == FUNC_LOCK_ACCOUNT || func == FUNC_UNLOCK_ACCOUNT) {
      require(msg.sender == owner(), "ERC20: caller must be owner");
    }
  }

  function _lockAccount(address account) internal virtual returns (bool) {
    if (isLockedAccount(account)) return true;

    _lockedAccounts[account] = true;
    emit LockAccount(account, block.timestamp);

    return false;
  }

  function _unlockAccount(address account) internal virtual returns (bool) {
    if (!isLockedAccount(account)) return false;

    _lockedAccounts[account] = false;
    emit UnlockAccount(account, block.timestamp);

    return true;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    require(amount > 0, "ERC20: amount zero");
    super._beforeTokenTransfer(from, to, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}

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
     *
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
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

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}