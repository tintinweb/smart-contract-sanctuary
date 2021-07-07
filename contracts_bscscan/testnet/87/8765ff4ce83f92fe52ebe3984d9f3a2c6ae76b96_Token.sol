/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.8.0;

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

// File: openzeppelin-solidity/contracts/token/ERC20/extensions/IERC20Metadata.sol


pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: openzeppelin-solidity/contracts/utils/Context.sol


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol


pragma solidity ^0.8.0;




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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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

// File: openzeppelin-solidity/contracts/utils/math/SafeMath.sol


pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol


pragma solidity ^0.8.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: openzeppelin-solidity/contracts/security/Pausable.sol


pragma solidity ^0.8.0;


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
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// File: contracts/Lockable.sol

pragma solidity >=0.4.22 <0.9.0;



contract Lockable is Ownable, Pausable {
  mapping(address => uint256) public lockingList;

  event LockUpdated(address indexed account, uint256 releaseDate);

  function _updateLock(address account, uint256 releaseDate) internal {
    lockingList[account] = releaseDate;
    emit LockUpdated(account, releaseDate);
  }

  function isLocked(address account) external view returns (bool) {
    uint256 releaseDate = lockingList[account];
    return releaseDate == 0 ? false : releaseDate > block.timestamp;
  }

  function updateLock(address account, uint256 releaseDate) external onlyOwner whenNotPaused {
    _updateLock(account, releaseDate);
  }

  function updateLocks(address[] memory accounts, uint256[] memory releaseDates) external onlyOwner whenNotPaused {
    require(accounts.length == releaseDates.length, "Invalid operation");

    for (uint256 i = 0; i < accounts.length; i++) {
      _updateLock(accounts[i], releaseDates[i]);
    }
  }
}

// File: contracts/Base.sol

pragma solidity >=0.4.22 <0.9.0;




contract Base is ERC20, Lockable {
  using SafeMath for uint256;

  uint256 public constant _MAX_SUPPLY = 100000000000 ether;
  uint256 public immutable _CREATION_DATE;
  mapping(bytes32 => uint256) public _minted;

  event Mint(address indexed account, uint256 amount);
  event Burn(address indexed account, uint256 amount);

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    _CREATION_DATE = block.timestamp;
  }

  modifier canMint(address _toAccount, uint256 amount) {
    require(_toAccount != address(0), "Please specify an account");
    require(amount > 0, "Please specify an amount");
    _;
  }

  function _beforeTokenTransfer(
    address from,
    address,
    uint256
  ) internal view override whenNotPaused {
    require(this.isLocked(from) == false, "Your tokens are locked");
  }

  function getOwner() external view returns (address) {
    return super.owner();
  }

  function hash(bytes32 value) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(value));
  }

  function batchTransfer(
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 releaseDate
  ) external onlyOwner {
    require(accounts.length == amounts.length, "Invalid input");

    for (uint256 i = 0; i < accounts.length; i++) {
      super._transfer(super._msgSender(), accounts[i], amounts[i]);

      if (releaseDate > 0) {
        _updateLock(accounts[i], releaseDate);
      }
    }
  }

  function burn(uint256 amount) external whenNotPaused {
    super._burn(super._msgSender(), amount);
    emit Burn(super._msgSender(), amount);
  }

  function pause() external onlyOwner {
    super._pause();
  }

  function unpause() external onlyOwner {
    super._unpause();
  }
}

// File: contracts/Token.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract Token is Base {
  using SafeMath for uint256;

  constructor(string memory name, string memory symbol) Base(name, symbol) {
    this;
  }

  function _mintTokens(address toAccount, uint256 amount) private whenNotPaused {
    super._mint(toAccount, amount);
    emit Mint(toAccount, amount);
  }

  function calculateSeedTokenRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(300000).div(10000000); // 3% of the supply

    uint256 yearsPassed = block.timestamp.sub(_CREATION_DATE).div(360 days);
    uint256 monthsPassed = block.timestamp.sub(_CREATION_DATE).div(30 days);

    bool[5] memory vested = [true, monthsPassed >= 6, monthsPassed >= 9, yearsPassed >= 1, yearsPassed >= 2];
    uint256[5] memory mintablePercent = [uint256(100000), uint256(100000), uint256(300000), uint256(300000), uint256(200000)];

    uint256 maximum = 0;

    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(1000000));
      }
    }

    return maximum;
  }

  function mintSeedTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("SEED_FUND");

    uint256 canRelease = this.calculateSeedTokenRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function mintAirdropTokens() external onlyOwner {
    bytes32 key = this.hash("AIR_DROP");
    uint256 allocation = _MAX_SUPPLY.mul(100000).div(10000000); // 1% of the supply

    require(_minted[key] == 0, "Attempt to exceed allocation");

    _minted[key] = allocation;
    _mintTokens(super._msgSender(), allocation);
  }

  function mintPresaleTokens() external onlyOwner {
    bytes32 key = this.hash("PRE_SALE");
    uint256 allocation = _MAX_SUPPLY.mul(900000).div(10000000); // 1% of the supply

    require(_minted[key] == 0, "Attempt to exceed allocation");

    _minted[key] = allocation;
    _mintTokens(super._msgSender(), allocation);
  }

  function calculateIFOTokenRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(500000).div(10000000); // 5% of the supply
    uint256 monthsPassed = block.timestamp.sub(_CREATION_DATE).div(30 days);

    bool[2] memory vested = [monthsPassed >= 6, monthsPassed >= 9];
    uint256[2] memory mintablePercent = [uint256(5000000), uint256(5000000)];

    uint256 maximum = 0;

    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(10000000));
      }
    }

    return maximum;
  }

  function mintIFOTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("IFO");

    uint256 canRelease = this.calculateIFOTokenRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function calculateLegalTokenRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(300000).div(10000000); // 3% of the supply
    uint256 yearsPassed = block.timestamp.sub(_CREATION_DATE).div(360 days);

    bool[5] memory vested = [yearsPassed >= 1, yearsPassed >= 2, yearsPassed >= 3, yearsPassed >= 4, yearsPassed >= 6];
    uint256[5] memory mintablePercent = [uint256(1000000), uint256(2000000), uint256(2000000), uint256(3000000), uint256(2000000)];

    uint256 maximum = 0;

    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(10000000));
      }
    }

    return maximum;
  }

  function mintLegalTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("LEGAL");

    uint256 canRelease = this.calculateLegalTokenRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function calculateGrantTokenRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(1200000).div(10000000); // 12% of the supply
    uint256 yearsPassed = block.timestamp.sub(_CREATION_DATE).div(360 days);

    bool[5] memory vested = [yearsPassed >= 1, yearsPassed >= 2, yearsPassed >= 3, yearsPassed >= 4, yearsPassed >= 6];
    uint256[5] memory mintablePercent = [uint256(1000000), uint256(2000000), uint256(2000000), uint256(3000000), uint256(2000000)];

    uint256 maximum = 0;

    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(10000000));
      }
    }

    return maximum;
  }

  function mintGrantTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("GRANT");

    uint256 canRelease = this.calculateGrantTokenRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function calculateMarketingTokenRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(500000).div(10000000); // 5% of the supply
    uint256 yearsPassed = block.timestamp.sub(_CREATION_DATE).div(360 days);

    bool[5] memory vested = [yearsPassed >= 1, yearsPassed >= 2, yearsPassed >= 3, yearsPassed >= 4, yearsPassed >= 6];
    uint256[5] memory mintablePercent = [uint256(1000000), uint256(2000000), uint256(2000000), uint256(3000000), uint256(2000000)];

    uint256 maximum = 0;

    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(10000000));
      }
    }

    return maximum;
  }

  function mintMarketingTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("MARKETING");

    uint256 canRelease = this.calculateMarketingTokenRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function calculateTeamTokenRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(1150000).div(10000000); // 11.5% of the supply
    uint256 yearsPassed = block.timestamp.sub(_CREATION_DATE).div(360 days);

    bool[5] memory vested = [yearsPassed >= 1, yearsPassed >= 2, yearsPassed >= 3, yearsPassed >= 4, yearsPassed >= 6];
    uint256[5] memory mintablePercent = [uint256(500000), uint256(1000000), uint256(1500000), uint256(3000000), uint256(4000000)];

    uint256 maximum = 0;

    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(10000000));
      }
    }

    return maximum;
  }

  function mintTeamTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("TEAM");

    uint256 canRelease = this.calculateTeamTokenRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function calculateBountyTokenRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(400000).div(10000000); // 4% of the supply
    uint256 yearsPassed = block.timestamp.sub(_CREATION_DATE).div(360 days);

    bool[4] memory vested = [yearsPassed >= 1, yearsPassed >= 2, yearsPassed >= 3, yearsPassed >= 4];
    uint256[4] memory mintablePercent = [uint256(3000000), uint256(2000000), uint256(2000000), uint256(3000000)];

    uint256 maximum = 0;

    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(10000000));
      }
    }

    return maximum;
  }

  function mintBountyTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("BOUNTY");

    uint256 canRelease = this.calculateBountyTokenRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function calculateLiquidityPoolIncentivesRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(400000).div(10000000); // 4% of the supply
    uint256 monthsPassed = block.timestamp.sub(_CREATION_DATE).div(30 days);

    bool[2] memory vested = [monthsPassed >= 6, monthsPassed >= 9];
    uint256[2] memory mintablePercent = [uint256(5000000), uint256(5000000)];

    uint256 maximum = 0;
    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(10000000));
      }
    }

    return maximum;
  }

  function mintLiquidityPoolIncentiveTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("LIQUIDITY_POOL_INCENTIVES");

    uint256 canRelease = this.calculateLiquidityPoolIncentivesRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function calculateProtocolTokenRelease() external view returns (uint256) {
    uint256 allocation = _MAX_SUPPLY.mul(3500000).div(10000000); // 35% of the supply
    uint256 yearsPassed = block.timestamp.sub(_CREATION_DATE).div(360 days);

    bool[5] memory vested = [yearsPassed >= 1, yearsPassed >= 2, yearsPassed >= 3, yearsPassed >= 4, yearsPassed >= 6];
    uint256[5] memory mintablePercent = [uint256(1000000), uint256(2000000), uint256(2000000), uint256(3000000), uint256(2000000)];

    uint256 maximum = 0;

    for (uint256 i = 0; i < vested.length; i++) {
      if (vested[i]) {
        maximum = maximum.add(allocation.mul(mintablePercent[i]).div(10000000));
      }
    }

    return maximum;
  }

  function mintProtocolTokens(address toAccount, uint256 amount) external onlyOwner canMint(toAccount, amount) {
    bytes32 key = this.hash("PROTOCOL_REWARDS");

    uint256 canRelease = this.calculateProtocolTokenRelease();

    require(canRelease >= _minted[key].add(amount), "Attempt to exceed allocation");

    _minted[key] = _minted[key].add(amount);
    _mintTokens(toAccount, amount);
  }

  function mintLiquidityPoolTokens() external onlyOwner {
    bytes32 key = this.hash("LIQUIDITY_POOL");
    uint256 allocation = _MAX_SUPPLY.mul(750000).div(10000000); // 7.5% of the supply

    require(_minted[key] == 0, "Attempt to exceed allocation");

    _minted[key] = allocation;
    _mintTokens(super._msgSender(), allocation);
  }
}