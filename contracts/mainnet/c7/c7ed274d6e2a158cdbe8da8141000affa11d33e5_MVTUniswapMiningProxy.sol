/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// Sources flattened with hardhat v2.1.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 ;

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


// File @openzeppelin/contracts/access/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 ;
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 ;

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


// File @openzeppelin/contracts/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 ;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 ;
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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


// File contracts/MovementToken.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
contract MovementToken is ERC20, Ownable{
    constructor() public ERC20("The Movement", "MVT")  {

    }

    function mint(address _to, uint _amount) public onlyOwner{
        _mint(_to, _amount);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 ;
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


// File contracts/MVTUniswapMiningStorage.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract OwnableStorage{
    address internal _owner;
}
 
contract PausableStorage{
    bool internal _paused;
}

contract MVTUniswapMiningStorage {
  using SafeMath for uint256;

  bool constant public isMVTUniswapMining = true;
  bool public initiated = false;

  // proxy storage
  address public admin;
  address public implementation;
  
  ERC20 public LPToken;
  ERC20 public MVTToken;
  
  uint public startMiningBlockNum = 0;
  uint public totalMiningBlockNum = 2400000;
  uint public endMiningBlockNum = startMiningBlockNum + totalMiningBlockNum;
  uint public MVTPerBlock = 83333333333333333;
  
  uint public constant stakeInitialIndex = 1e36;
  
  uint public miningStateBlock = startMiningBlockNum;
  uint public miningStateIndex = stakeInitialIndex;


  
  struct Stake{
    uint amount;
    uint lockedUntil;
    uint lockPeriod;
    uint stakePower;
    bool exists;
  }

  mapping (address => Stake[]) public stakes;
  mapping (address => uint) public stakeCount;
  uint public totalStaked;
  uint public totalStakedPower;

  mapping (address => uint) public stakeHolders;
  mapping (address => uint) public stakerPower;
  mapping (address => uint) public stakerIndexes;
  mapping (address => uint) public stakerClaimed;
  uint public totalClaimed;

}


// File contracts/MVTUniswapMining.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
contract MVTUniswapMining is Ownable, Pausable, MVTUniswapMiningStorage {
  
  event Staked(address indexed user, uint256 amount, uint256 total, uint256 lockedUntil);
  event Unstaked(address indexed user, uint256 amount, uint256 total);
  event ClaimedMVT(address indexed user, uint amount, uint total);

  function initiate(uint _startMiningBlocknum, uint _totalMiningBlockNum, uint _MVTPerBlock, ERC20 _MVT, ERC20 _lp) public onlyOwner{
    require(initiated==false, "contract is already initiated");
    initiated = true;

    require(_totalMiningBlockNum >= 100, "_totalMiningBlockNum is too small");

    if(_startMiningBlocknum == 0){
      _startMiningBlocknum = block.number;
    }

    _MVT.totalSupply(); //sanity check
    _lp.totalSupply(); //sanity check

    startMiningBlockNum = _startMiningBlocknum;
    totalMiningBlockNum = _totalMiningBlockNum;
    endMiningBlockNum = startMiningBlockNum + totalMiningBlockNum;
    miningStateBlock = startMiningBlockNum;
    MVTPerBlock = _MVTPerBlock;
    MVTToken = _MVT;
    LPToken = _lp;

  }

  // @notice stake some LP tokens
  // @param _amount some amount of LP tokens, requires enought allowance from LP token smart contract
  // @param _locked the locking period; option: 0, 30 days (2592000), 90 days (7776000), 180 days (15552000), 360 days (31104000)
  function stake(uint256 _amount, uint256 _locked) public whenNotPaused{
      
      createStake(msg.sender, _amount, _locked);
  }
  
  // @notice internal function for staking
  function createStake(
    address _address,
    uint256 _amount,
    uint256 _locked
  )
    internal
  {

    claimMVT();
    
    require(block.number<endMiningBlockNum, "staking period has ended");
    require(_locked == 0 || _locked == 30 days || _locked == 90 days || _locked == 180 days || _locked == 360 days  , "invalid locked period" );
      
    require(
      LPToken.transferFrom(_address, address(this), _amount),
      "Stake required");

    uint _lockedUntil = block.timestamp.add(_locked);
    uint _powerRatio;
    uint _power;

    if(_locked == 0){
        _powerRatio = 1;
    } else if(_locked == 30 days){
        _powerRatio = 2;
    } else if(_locked == 90 days){
        _powerRatio = 3;
    } else if(_locked == 180 days){
        _powerRatio = 4;
    } else if(_locked == 360 days){
        _powerRatio = 5;
    }

    _power = _amount.mul(_powerRatio);

    Stake memory _stake = Stake(_amount, _lockedUntil, _locked, _power, true);
    stakes[_address].push(_stake);
    stakeCount[_address] = stakeCount[_address].add(1);
    stakerPower[_address] = stakerPower[_address].add(_power);

    stakeHolders[_address] = stakeHolders[_address].add(_amount);
    totalStaked = totalStaked.add(_amount);
    totalStakedPower = totalStakedPower.add(_power);

    emit Staked(
      _address,
      _amount,
      stakeHolders[_address],
      _lockedUntil);
  }
  
  // @notice unstake LP token
  // @param _index the index of stakes array
  function unstake(uint256 _index, uint256 _amount) public whenNotPaused{

    require(stakes[msg.sender][_index].exists == true, "stake index doesn't exist");
    require(stakes[msg.sender][_index].amount == _amount, "stake amount doesn't match");

    withdrawStake(msg.sender, _index);
      
  }

  // @notice internal function for removing stake and reorder the array
  function removeStake(address _address, uint index) internal {
      for (uint i = index; i < stakes[_address].length-1; i++) {
          stakes[_address][i] = stakes[_address][i+1];
      }
      stakes[_address].pop();
  }
  
  // @notice internal function for unstaking
  function withdrawStake(
    address _address,
    uint256 _index
  )
    internal
  {

    claimMVT();

    if(block.number <= endMiningBlockNum){ //if current block is lower than endMiningBlockNum, check lockedUntil
      require(stakes[_address][_index].lockedUntil <= block.timestamp, "the stake is still locked");
    }

    uint _amount = stakes[_address][_index].amount;
    uint _power = stakes[_address][_index].stakePower;

    if(_amount > stakeHolders[_address]){ //if amount is larger than owned
      _amount = stakeHolders[_address];
    }

    require(
      LPToken.transfer(_address, _amount),
      "Unable to withdraw stake");
    
    removeStake(_address, _index);
    stakeCount[_address] = stakeCount[_address].sub(1);
    
    stakerPower[_address] = stakerPower[_address].sub(_power);
    totalStakedPower = totalStakedPower.sub(_power);
    stakeHolders[_address] = stakeHolders[_address].sub(_amount);
    totalStaked = totalStaked.sub(_amount);

    updateMiningState();

    emit Unstaked(
      _address,
      _amount,
      stakeHolders[_address]);
  }
  
  // @notice internal function for updating mining state
  function updateMiningState() internal{
    
    if(miningStateBlock == endMiningBlockNum){ //if miningStateBlock is already the end of program, dont update state
        return;
    }
    
    (miningStateIndex, miningStateBlock) = getMiningState(block.number);
    
  }
  
  // @notice calculate current mining state
  function getMiningState(uint _blockNum) public view returns(uint, uint){

    require(_blockNum >= miningStateBlock, "_blockNum must be >= miningStateBlock");
      
    uint blockNumber = _blockNum;
      
    if(_blockNum>endMiningBlockNum){ //if current block.number is bigger than the end of program, only update the state to endMiningBlockNum
        blockNumber = endMiningBlockNum;   
    }
      
    uint deltaBlocks = blockNumber.sub(miningStateBlock);
    
    uint _miningStateBlock = miningStateBlock;
    uint _miningStateIndex = miningStateIndex;
    
    if (deltaBlocks > 0 && totalStaked > 0) {
        uint MVTAccrued = deltaBlocks.mul(MVTPerBlock);
        uint ratio = MVTAccrued.mul(1e18).div(totalStakedPower); //multiple ratio to 1e18 to prevent rounding error
        _miningStateIndex = miningStateIndex.add(ratio); //index is 1e18 precision
        _miningStateBlock = blockNumber;
    } 
    
    return (_miningStateIndex, _miningStateBlock);
    
  }
  
  // @notice claim MVT based on current state 
  function claimMVT() public whenNotPaused {
      
      updateMiningState();
      
      uint claimableMVT = claimableMVT(msg.sender);
      
      stakerIndexes[msg.sender] = miningStateIndex;
      
      if(claimableMVT > 0){
          
          stakerClaimed[msg.sender] = stakerClaimed[msg.sender].add(claimableMVT);
          totalClaimed = totalClaimed.add(claimableMVT);
          MVTToken.transfer(msg.sender, claimableMVT);
          emit ClaimedMVT(msg.sender, claimableMVT, stakerClaimed[msg.sender]);
          
      }
  }
  
  // @notice calculate claimable MVT based on current state
  function claimableMVT(address _address) public view returns(uint){
      uint stakerIndex = stakerIndexes[_address];
        
        // if it's the first stake for user and the first stake for entire mining program, set stakerIndex as stakeInitialIndex
        if (stakerIndex == 0 && totalStaked == 0) {
            stakerIndex = stakeInitialIndex;
        }
        
        //else if it's the first stake for user, set stakerIndex as current miningStateIndex
        if(stakerIndex == 0){
            stakerIndex = miningStateIndex;
        }
      
      uint deltaIndex = miningStateIndex.sub(stakerIndex);
      uint MVTDelta = deltaIndex.mul(stakerPower[_address]).div(1e18);
      
      return MVTDelta;
          
  }

    // @notice test function
    function doNothing() public{
    }

    /*======== admin functions =========*/

    // @notice admin function to pause the contract
    function pause() public onlyOwner{
      _pause();
    }

    // @notice admin function to unpause the contract
    function unpause() public onlyOwner{
      _unpause();
    }

    // @notice admin function to send MVT to external address, for emergency use
    function sendMVT(address _to, uint _amount) public onlyOwner{
      MVTToken.transfer(_to, _amount);
    }
    
}


// File contracts/MVTUniswapMiningProxy.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
contract MVTUniswapMiningProxy is OwnableStorage, PausableStorage, MVTUniswapMiningStorage {
 
    event NewImplementation(address oldImplementation, address newImplementation);

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(MVTUniswapMining newImplementation) public {

        admin = msg.sender;
        _owner = msg.sender;

        require(newImplementation.isMVTUniswapMining() == true, "invalid implementation");
        implementation = address(newImplementation);

        emit NewImplementation(address(0), implementation);
    }

    /*** Admin Functions ***/
    function _setImplementation(MVTUniswapMining  newImplementation) public {

        require(msg.sender==admin, "UNAUTHORIZED");

        require(newImplementation.isMVTUniswapMining() == true, "invalid implementation");

        address oldImplementation = implementation;

        implementation = address(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

    }


    /**
      * @notice Transfer of admin rights
      * @dev Admin function to change admin
      * @param newAdmin New admin.
      */
    function _setAdmin(address newAdmin) public {
        // Check caller = admin
        require(msg.sender==admin, "UNAUTHORIZED");

        // Save current value, if any, for inclusion in log
        address oldAdmin = admin;

        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);

    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() external {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }
}


// File contracts/UniswapV2Pair.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
contract UniswapV2Pair is ERC20, Ownable{
    constructor() public ERC20("Uniswap V2", "UNI-V2")  {

    }

    function mint(address _to, uint _amount) public onlyOwner{
        _mint(_to, _amount);
    }
}


// File contracts/Migrations.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;
 
  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}