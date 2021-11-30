/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-14
*/

/* Bloxxter Token Contract, for more information, please visit https://bloxxter.com/de/downloads */

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol



/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol


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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol


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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: @openzeppelin/contracts/access/Roles.sol


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/MinterRole.sol




contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Mintable.sol




/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Capped.sol



/**
 * @dev Extension of {ERC20Mintable} that adds a cap to the supply of tokens.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20Mintable-mint}.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}

// File: @openzeppelin/contracts/access/roles/PauserRole.sol




contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: @openzeppelin/contracts/lifecycle/Pausable.sol




/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
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
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Pausable.sol




/**
 * @title Pausable token
 * @dev ERC20 with pausable transfers and allowances.
 *
 * Useful if you want to stop trades until the end of a crowdsale, or have
 * an emergency switch for freezing all token transfers in the event of a large
 * bug.
 */
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistAdminRole.sol




/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: @openzeppelin/contracts/access/roles/WhitelistedRole.sol





/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: contracts/access/roles/CloserRole.sol




contract CloserRole is Context {
    using Roles for Roles.Role;

    event CloserAdded(address indexed account);
    event CloserRemoved(address indexed account);

    Roles.Role private _closers;

    constructor () internal {
        _addCloser(_msgSender());
    }

    modifier onlyCloser() {
        require(isCloser(_msgSender()), "CloserRole: caller does not have the Closer role");
        _;
    }

    function isCloser(address account) public view returns (bool) {
        return _closers.has(account);
    }

    function addCloser(address account) public onlyCloser {
        _addCloser(account);
    }

    function renounceCloser() public {
        _removeCloser(_msgSender());
    }

    function _addCloser(address account) internal {
        _closers.add(account);
        emit CloserAdded(account);
    }

    function _removeCloser(address account) internal {
        _closers.remove(account);
        emit CloserRemoved(account);
    }
}

// File: contracts/lifecycle/Closable.sol




/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotClosed` and `whenClosed`, which can be applied to
 * the functions of your contract. Note that they will not be closable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Closable is Context, CloserRole {
    /**
     * @dev Emitted when the close is triggered by a closer (`account`).
     */
    event Closed(address account);

    /**
     * @dev Emitted when the close is lifted by a closer (`account`).
     */
    // event Unclosed(address account);

    bool private _closed;

    /**
     * @dev Initializes the contract in unclosed state. Assigns the Closer role
     * to the deployer.
     */
    constructor () internal {
        _closed = false;
    }

    /**
     * @dev Returns true if the contract is closed, and false otherwise.
     */
    function closed() public view returns (bool) {
        return _closed;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not closed.
     */
    modifier whenNotClosed() {
        require(!_closed, "Closable: closed");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is closed.
     */
    modifier whenClosed() {
        require(_closed, "Closable: not closed");
        _;
    }

    /**
     * @dev Called by a closer to close, triggers stopped state.
     */
    function close() public onlyCloser whenNotClosed {
        _closed = true;
        emit Closed(_msgSender());
    }

    /**
     * @dev Called by a closer to unclose, returns to normal state.
     */
    // function unclose() public onlyCloser whenClosed {
    //     _closed = false;
    //     emit Unclosed(_msgSender());
    // }
}

// File: contracts/access/roles/DestroyerRole.sol




contract DestroyerRole is Context {
    using Roles for Roles.Role;

    event DestroyerAdded(address indexed account);
    event DestroyerRemoved(address indexed account);

    Roles.Role private _destroyers;

    constructor () internal {
        _addDestroyer(_msgSender());
    }

    modifier onlyDestroyer() {
        require(isDestroyer(_msgSender()), "DestroyerRole: caller does not have the Destroyer role");
        _;
    }

    function isDestroyer(address account) public view returns (bool) {
        return _destroyers.has(account);
    }

    function addDestroyer(address account) public onlyDestroyer {
        _addDestroyer(account);
    }

    function renounceDestroyer() public {
        _removeDestroyer(_msgSender());
    }

    function _addDestroyer(address account) internal {
        _destroyers.add(account);
        emit DestroyerAdded(account);
    }

    function _removeDestroyer(address account) internal {
        _destroyers.remove(account);
        emit DestroyerRemoved(account);
    }
}

// File: contracts/access/roles/DocumentStorerRole.sol




contract DocumentStorerRole is Context {
    using Roles for Roles.Role;

    event DocumentStorerAdded(address indexed account);
    event DocumentStorerRemoved(address indexed account);

    Roles.Role private _documentStorers;

    constructor () internal {
        _addDocumentStorer(_msgSender());
    }

    modifier onlyDocumentStorer() {
        require(isDocumentStorer(_msgSender()), "DocumentStorerRole: caller does not have the DocumentStorer role");
        _;
    }

    function isDocumentStorer(address account) public view returns (bool) {
        return _documentStorers.has(account);
    }

    function addDocumentStorer(address account) public onlyDocumentStorer {
        _addDocumentStorer(account);
    }

    function renounceDocumentStorer() public {
        _removeDocumentStorer(_msgSender());
    }

    function _addDocumentStorer(address account) internal {
        _documentStorers.add(account);
        emit DocumentStorerAdded(account);
    }

    function _removeDocumentStorer(address account) internal {
        _documentStorers.remove(account);
        emit DocumentStorerRemoved(account);
    }
}

// File: contracts/access/roles/FreezerRole.sol




contract FreezerRole is Context {
    using Roles for Roles.Role;

    event FreezerAdded(address indexed account);
    event FreezerRemoved(address indexed account);

    Roles.Role private _freezers;

    constructor () internal {
        _addFreezer(_msgSender());
    }

    modifier onlyFreezer() {
        require(isFreezer(_msgSender()), "FreezerRole: caller does not have the Freezer role");
        _;
    }

    function isFreezer(address account) public view returns (bool) {
        return _freezers.has(account);
    }

    function addFreezer(address account) public onlyFreezer {
        _addFreezer(account);
    }

    function renounceFreezer() public {
        _removeFreezer(_msgSender());
    }

    function _addFreezer(address account) internal {
        _freezers.add(account);
        emit FreezerAdded(account);
    }

    function _removeFreezer(address account) internal {
        _freezers.remove(account);
        emit FreezerRemoved(account);
    }
}

// File: contracts/access/roles/FrozenRole.sol





contract FrozenRole is Context, FreezerRole {
    using Roles for Roles.Role;

    event FrozenAdded(address indexed account);
    event FrozenRemoved(address indexed account);

    Roles.Role private _frozens;

    modifier onlyFrozen() {
        require(isFrozen(_msgSender()), "FrozenRole: caller does not have the Frozen role");
        _;
    }

    function isFrozen(address account) public view returns (bool) {
        return _frozens.has(account);
    }

    function addFrozen(address account) public onlyFreezer {
        _addFrozen(account);
    }

    function removeFrozen(address account) public onlyFreezer {
        _removeFrozen(account);
    }

    // function renounceFrozen() public {
    //     _removeFrozen(_msgSender());
    // }

    function _addFrozen(address account) internal {
        _frozens.add(account);
        emit FrozenAdded(account);
    }

    function _removeFrozen(address account) internal {
        _frozens.remove(account);
        emit FrozenRemoved(account);
    }
}

// File: contracts/access/roles/LimiterRole.sol




contract LimiterRole is Context {
    using Roles for Roles.Role;

    event LimiterAdded(address indexed account);
    event LimiterRemoved(address indexed account);

    Roles.Role private _limiters;

    constructor () internal {
        _addLimiter(_msgSender());
    }

    modifier onlyLimiter() {
        require(isLimiter(_msgSender()), "LimiterRole: caller does not have the Limiter role");
        _;
    }

    function isLimiter(address account) public view returns (bool) {
        return _limiters.has(account);
    }

    function addLimiter(address account) public onlyLimiter {
        _addLimiter(account);
    }

    function renounceLimiter() public {
        _removeLimiter(_msgSender());
    }

    function _addLimiter(address account) internal {
        _limiters.add(account);
        emit LimiterAdded(account);
    }

    function _removeLimiter(address account) internal {
        _limiters.remove(account);
        emit LimiterRemoved(account);
    }
}

// File: contracts/access/roles/TokenReassignerRole.sol




contract TokenReassignerRole is Context {
    using Roles for Roles.Role;

    event TokenReassignerAdded(address indexed account);
    event TokenReassignerRemoved(address indexed account);

    Roles.Role private _tokenReassigners;

    constructor () internal {
        _addTokenReassigner(_msgSender());
    }

    modifier onlyTokenReassigner() {
        require(isTokenReassigner(_msgSender()), "TokenReassignerRole: caller does not have the TokenReassigner role");
        _;
    }

    function isTokenReassigner(address account) public view returns (bool) {
        return _tokenReassigners.has(account);
    }

    function addTokenReassigner(address account) public onlyTokenReassigner {
        _addTokenReassigner(account);
    }

    function renounceTokenReassigner() public {
        _removeTokenReassigner(_msgSender());
    }

    function _addTokenReassigner(address account) internal {
        _tokenReassigners.add(account);
        emit TokenReassignerAdded(account);
    }

    function _removeTokenReassigner(address account) internal {
        _tokenReassigners.remove(account);
        emit TokenReassignerRemoved(account);
    }
}

// File: contracts/BlxToken.sol













contract RmlaToken is
    ERC20Detailed,
    ERC20Capped,
    ERC20Pausable,
    Ownable,
    WhitelistedRole,
    Closable,
    DestroyerRole,
    DocumentStorerRole,
    FrozenRole,
    LimiterRole,
    TokenReassignerRole
{
    struct Document {
        uint256 timestamp;
        string hash;
    }

    // ----- Contract variables

    uint256 public transferFloor;

    uint256 public transferCap;

    bool public whitelistIsActive;

    mapping(address => uint256) private _frozenAmount;

    Document[] private _documents;

    // ----- Contract events

    event BatchMint(address[] account, uint256[] amounts);
    event BatchDestroy(address[] account, uint256[] amounts);

    event WhitelistActivated(address account);
    event WhitelistDeactivated(address account);

    event TransferFloorChanged(
        uint256 indexed previousValue,
        uint256 indexed newValue
    );

    event TransferCapChanged(
        uint256 indexed previousValue,
        uint256 indexed newValue
    );

    event TokensReassigned(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event DocumentAdded(string hash, uint256 indexed index);

    // ----- Contract initialization

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap
    )
        public
        ERC20Detailed(name, symbol, decimals)
        ERC20Capped(cap)
        ERC20Pausable()
        Ownable()
        WhitelistedRole()
        Closable()
        DestroyerRole()
        DocumentStorerRole()
        FrozenRole()
        LimiterRole()
        TokenReassignerRole()
    {
        transferFloor = 100 * 1e18;
        transferCap = 100e3 * 1e18;
        whitelistIsActive = false;
    }

    // ----- Contract functionality

    // --- Whitelisting

    function isWhitelisted(address account) public view returns (bool) {
        return !whitelistIsActive || super.isWhitelisted(account);
    }

    function activateWhitelist() external onlyWhitelistAdmin returns (bool) {
        require(!whitelistIsActive, "Whitelist is already active");

        whitelistIsActive = true;

        emit WhitelistActivated(msg.sender);

        return true;
    }

    function deactivateWhitelist() external onlyWhitelistAdmin returns (bool) {
        require(whitelistIsActive, "Whitelist is not active");

        whitelistIsActive = false;

        emit WhitelistDeactivated(msg.sender);

        return true;
    }

    function batchAddWhitelisted(address[] calldata account)
        external
        onlyWhitelistAdmin
        returns (bool)
    {
        uint256 toLength = account.length;

        for (uint256 i = 0; i < toLength; i++) {
            super.addWhitelisted(account[i]);
        }

        return true;
    }

    // --- Minting

    // Intercepts token mints
    function _mint(address account, uint256 amount) internal whenNotClosed {
        super._mint(account, amount);

        // An address can be minted for multiple times
        if (!super.isWhitelisted(account)) {
            addWhitelisted(account);
        }
    }

    // Mints tokens for a list of addresses
    function batchMint(address[] calldata accounts, uint256[] calldata amounts)
        external
        onlyMinter
        returns (bool)
    {
        uint256 accountCount = accounts.length;

        require(
            accountCount == amounts.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < accountCount; i++) {
            _mint(accounts[i], amounts[i]);
        }

        emit BatchMint(accounts, amounts);

        return true;
    }

    // --- Destroying

    function destroy(address account, uint256 amount)
        external
        onlyDestroyer
        returns (bool)
    {
        _burn(account, amount);

        return true;
    }

    // Destroys tokens for a list of addresses
    function batchDestroy(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyDestroyer returns (bool) {
        uint256 accountCount = accounts.length;

        require(
            accountCount == amounts.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < accountCount; i++) {
            _burn(accounts[i], amounts[i]);
        }

        emit BatchDestroy(accounts, amounts);

        return true;
    }

    // --- Transfer cap and floor

    // Sets the minimum transfer amount
    function setTransferFloor(uint256 floor)
        external
        onlyLimiter
        returns (bool)
    {
        require(
            floor < transferCap,
            "Transfer floor must be less than transfer cap"
        );

        emit TransferFloorChanged(transferFloor, floor);

        transferFloor = floor;

        return true;
    }

    // Sets the maximum transfer amount
    function setTransferCap(uint256 cap) external onlyLimiter returns (bool) {
        require(
            transferFloor < cap,
            "Transfer cap must be greater than transfer floor"
        );

        emit TransferCapChanged(transferCap, cap);

        transferCap = cap;

        return true;
    }

    // Intercepts secondary token transfers (mint and destroy excluded)
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotClosed {
        require(
            amount >= transferFloor,
            "Transfer amount under the transfer floor"
        );
        require(amount <= transferCap, "Transfer amount over the transfer cap");

        require(isWhitelisted(recipient), "Recipient is not whitelisted");

        require(!isFrozen(sender), "Sender's account is frozen");

        require(
            _frozenAmount[sender] + amount <= balanceOf(sender),
            "Transfer amount exceeds unfrozen balance"
        );

        super._transfer(sender, recipient, amount);
    }

    // --- Token reassigning

    // Transfers the entire balance from an address to another
    function tokenReassign(address from, address to)
        external
        whenNotClosed
        onlyTokenReassigner
        returns (bool)
    {
        uint256 amount = balanceOf(from);

        super._transfer(from, to, amount);

        emit TokensReassigned(from, to, amount);

        return true;
    }

    // --- Special Token transfer for "Invite a friend" incentives

    function transferIncentiveToken(
        address sender,
        address recipient,
        uint256 amount
    ) external whenNotClosed onlyLimiter returns (bool) {
        require(amount <= transferCap, "Transfer amount over the transfer cap");

        require(isWhitelisted(recipient), "Recipient is not whitelisted");

        require(!isFrozen(sender), "Sender's account is frozen");

        require(
            _frozenAmount[sender] + amount <= balanceOf(sender),
            "Transfer amount exceeds unfrozen balance"
        );

        super._transfer(sender, recipient, amount);

        return true;
    }

    // --- Account freezing

    function batchAddFrozen(address[] calldata accounts) external onlyFreezer {
        uint256 accountCount = accounts.length;

        for (uint256 i = 0; i < accountCount; i++) {
            addFrozen(accounts[i]);
        }
    }

    function batchRemoveFrozen(address[] calldata accounts)
        external
        onlyFreezer
    {
        uint256 accountCount = accounts.length;

        for (uint256 i = 0; i < accountCount; i++) {
            removeFrozen(accounts[i]);
        }
    }

    function setFrozenAmount(address account, uint256 amount)
        external
        onlyFreezer
    {
        _frozenAmount[account] = amount;
    }

    // --- Document registry

    function addDocument(string calldata hash) external onlyDocumentStorer {
        require(bytes(hash).length > 0, "Invalid document hash");

        Document memory document = Document({
            timestamp: block.timestamp,
            hash: hash
        });

        _documents.push(document);

        emit DocumentAdded(hash, _documents.length.sub(1));
    }

    function currentDocument()
        external
        view
        returns (
            uint256 timestamp,
            string memory hash,
            uint256 index
        )
    {
        require(_documents.length > 0, "No documents exist");

        uint256 last = _documents.length.sub(1);

        Document storage document = _documents[last];

        return (document.timestamp, document.hash, last);
    }

    function getDocument(uint256 index)
        external
        view
        returns (
            uint256 timestamp,
            string memory hash,
            uint256 inputIndex
        )
    {
        require(index < _documents.length, "Invalid document index");

        Document storage document = _documents[index];

        return (document.timestamp, document.hash, index);
    }

    function documentCount() external view returns (uint256) {
        return _documents.length;
    }
}