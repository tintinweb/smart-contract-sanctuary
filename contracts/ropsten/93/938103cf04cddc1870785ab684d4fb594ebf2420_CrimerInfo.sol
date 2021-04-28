/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

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

// File: contracts/Storage.sol

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

// File: contracts/Governable.sol

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
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
        //(bool success, ) = recipient.call{ value: amount }("");
        (bool success, ) = recipient.call.value( amount )("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        //(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        (bool success, bytes memory returndata) = target.call.value( weiValue )(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract CrimeCash is ERC20, ERC20Detailed, ERC20Mintable, Governable {

  mapping(uint256=>address) private holders;
  uint256 public _max_holders;
  mapping(address=>mapping(uint256=>address)) private _holder_allowances;
  mapping(address=>uint256) private _max_allowances;
  
  constructor(address _storage) public ERC20Detailed("CrimeCash", "CCASH", 2) Governable(_storage) {
    // msg.sender should not be a minter
    renounceMinter();
    // governance will become the only minter
    _addMinter(governance());
  }

  function addMinter(address _minter) public onlyGovernance {
    super.addMinter(_minter);
  }

  function approve(address spender_, uint256 amount_) public returns (bool) {
    if (isExists(_msgSender(), spender_) == false) {
      _holder_allowances[_msgSender()][_max_allowances[_msgSender()]] = spender_;
      _max_allowances[_msgSender()]++;
    }
    super.approve(spender_, amount_);
    return true;
  }
  
  function transfer(address recipient, uint256 amount) public returns (bool) {
    if ( balanceOf(recipient) == 0 && isNewHolder(recipient) ) {
      holders[_max_holders] = recipient;
      _max_holders++;
    }
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    if ( balanceOf(recipient) == 0 && isNewHolder(recipient) ) {
      holders[_max_holders] = recipient;
      _max_holders++;
    }
    super.transferFrom(sender, recipient, amount);
    return true;
  }
  
  function mint(address account, uint256 amount) public onlyMinter returns (bool) {
    if ( balanceOf(account) == 0 && isNewHolder(account) ) {
      holders[_max_holders] = account;
      _max_holders++;
    }
    super.mint(account, amount);
    return true;
  }
  
  function burn(address _from, uint256 amount) public {
    _burn(_from, amount);
  }
  
  function resetCrimCashSupply() public onlyMinter {
    for(uint256 i=0;i<_max_holders;i++) {
      for(uint256 j=0;j<_max_allowances[holders[i]];j++) {
        _approve(holders[i], _holder_allowances[holders[i]][j], 0);
      }
      _burn(holders[i], balanceOf(holders[i]));
    }
  }
  
  function isNewHolder(address holder_) internal view returns(bool) {
    for(uint256 i=0;i<_max_holders;i++) {
      if ( holders[i] == holder_ ) return false;
    }
    return true;
  }
  
  function isExists(address owner_, address spender_) internal view returns (bool) {
    if (_max_allowances[owner_]==0) return false;
    for(uint256 i=0;i<_max_allowances[owner_];i++) {
      if ( _holder_allowances[owner_][i] == spender_ ) return true;
    }
    return false;
  }
}

contract CrimeGold is ERC20, ERC20Detailed, ERC20Mintable, Governable {

  constructor(address _storage) public ERC20Detailed("CrimeGold", "CGOLD", 18) Governable(_storage) {
    // msg.sender should not be a minter
    renounceMinter();
    // governance will become the only minter
    _addMinter(governance());
  }

  /**
  * Overrides adding new minters so that only governance can authorized them.
  */
  function addMinter(address _minter) public onlyGovernance {
    super.addMinter(_minter);
  }
  
}

contract CrimeCashGame is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address;
  
  struct PoolInfo {
    bool isCrimeCash;                    // is crimecash contract?
    IERC20 lpToken;                      // lptoken contract
    uint256 totalStaked;                 // total staked lp token amount
    uint256 stakers;                     // total staker count
    uint8   openDay;
    mapping(uint256=>address) players;   // staker address
    mapping(address=>uint256) balances;  // each user's staked amount
    uint256[30] apy_rate;
    bool exists;                        
  }
  mapping(uint256 => PoolInfo) pools;
  uint256[] public poolIndexes;
  
  CrimeGold public crimegoldToken;
  address crimerInfo;
  
  struct Asset {
    uint256 power;
    uint256 cost;
  }
  mapping(uint256=>Asset) Attack;
  mapping(uint256=>Asset) Defense;
  mapping(uint256=>Asset) Boost;
  mapping(uint256=>Asset) Protect;
  
  bool    public isRoundOpening;
  uint8   public roundDay;
  
  uint256 public goldSupply;
  uint256 public goldForTeam;
  uint256 public goldForCrimer;
  
  address public cfoAddress;
  address payable public ethAddress;
  
  event eventStartRound(uint256 goldForTeam, uint256 goldForCrimer);
  event eventUpdatedAsset(uint8 assetType, uint256 assetIndex, uint256 assetValue, uint256 assetCost);
  event eventDeletedAsset(uint8 assetType, uint256 assetIndex);
  event addNewPool(uint256 poolIndex);
  event removePool(uint256 poolIndex);
  event stakeLpToken(uint256 poolIndex, address crimer, uint256 amount);
  event unstakeLpToken(uint256 poolIndex, address crimer, uint256 amount);
  event eventRequestBuyCcash(address crimer, uint8 buyOptionIndex);
  event eventDistributeGold(address[] crimer, uint256[] amount);
  event eventFinishRound();
  
  constructor(CrimeGold _crimegold, address _ceo) public {
    crimegoldToken = _crimegold;
    
    cfoAddress = _ceo;
    ethAddress = address(uint160(_ceo));
    
    goldSupply = 1000*1e18;
    goldForTeam = goldSupply.mul(3).div(100);
    goldForCrimer   = goldSupply.sub(goldForTeam);
    isRoundOpening = false;
    roundDay = 0;
  }
  function setCrimerInfoAddress(address _crimerInfo) public onlyOwner {
    crimerInfo = _crimerInfo;
  }
  function setCfoAddress(address _cfoAddress) public onlyOwner {
    require(isRoundOpening == false, "Error: There is an opened round currently");
    cfoAddress = address(uint160(_cfoAddress));
  }
  
  function setRecipientEthAddress(address _address) public onlyOwner {
    require(isRoundOpening == false, "Error: There is an opened round currently");
    ethAddress = address(uint160(_address));
  }
  
  function setSupplyGold(uint256 _goldSupply, uint8 _rate) public onlyOwner {
    require(isRoundOpening == false, "Error: There is an opened round currently");
    goldSupply = _goldSupply;
    goldForTeam = goldSupply.mul(uint256(_rate)).div(100);
    goldForCrimer = goldSupply.sub(goldForTeam);
  }
  
  function setTotalSupplyGold(uint256 _goldSupply) public onlyOwner {
    require(isRoundOpening == false, "Error: There is an opened round currently");
    goldSupply = _goldSupply;
  }
  
  function addAsset(uint8 _type, uint256 _index, uint256 _value, uint256 _cost) public onlyOwner {
    require(isRoundOpening == false, "Error: There is not an opened round currently");
    if ( _type == 1 ) Attack[_index] = Asset({power: _value, cost: _cost});
    if ( _type == 2 ) Defense[_index] = Asset({power: _value, cost: _cost});
    if ( _type == 3 ) Boost[_index] = Asset({power: _value, cost: _cost});
    if ( _type == 4 ) Protect[_index] = Asset({power: _value, cost: _cost});
    emit eventUpdatedAsset(_type, _index, _value, _cost);
  }
  function removeAsset(uint8 _type, uint256 _index) public onlyOwner {
    require(isRoundOpening == false, "Error: There is not an opened round currently");
    if ( _type == 1 ) delete Attack[_index];
    if ( _type == 2 ) delete Defense[_index];
    if ( _type == 3 ) delete Boost[_index];
    if ( _type == 4 ) delete Protect[_index];
    emit eventDeletedAsset(_type, _index);
  }
  function getAsset(uint8 _type, uint256 _index) public view returns(uint256 power, uint256 cost) {
    if ( _type == 1 ) { power = Attack[_index].power;  cost = Attack[_index].cost; }
    if ( _type == 2 ) { power = Defense[_index].power;  cost = Defense[_index].cost; }
    if ( _type == 3 ) { power = Boost[_index].power;  cost = Boost[_index].cost; }
    if ( _type == 4 ) { power = Protect[_index].power;  cost = Protect[_index].cost; }
  }
  /******************* pool-related functions start *******************/
  function addPool(uint256 _poolIndex, uint8 isCrimeCash, address _lpToken, uint8 _openDay) public onlyOwner {
    if (pools[_poolIndex].exists == false) {
      PoolInfo memory _newPool;
      _newPool.exists = true;
      _newPool.lpToken = IERC20(_lpToken);
      _newPool.totalStaked = 0;
      _newPool.isCrimeCash = isCrimeCash == 1;
      _newPool.openDay = _openDay;
      pools[_poolIndex] = _newPool;
      poolIndexes.push(_poolIndex);
    }
    else {
      pools[_poolIndex].exists = true;
      pools[_poolIndex].lpToken = IERC20(_lpToken);
      pools[_poolIndex].totalStaked = 0;
      pools[_poolIndex].isCrimeCash = isCrimeCash == 1;
      pools[_poolIndex].openDay = _openDay;
    }
    emit addNewPool(_poolIndex);
  }
  function setApyRate(uint256 _poolIndex, uint256[30] memory _rates) public onlyOwner {
    for(uint8 i=0;i<30;i++) {
      pools[_poolIndex].apy_rate[i] = _rates[i];
    }
  }
  function getApyRate(uint256 _poolIndex) public view returns(uint256[30] memory rates) {
    for(uint8 i=0;i<30;i++) {
      rates[i] = pools[_poolIndex].apy_rate[i];
    }
  }
  function deletePool(uint256 _poolIndex) public onlyOwner {
    require( pools[_poolIndex].exists == true, "Error: This pool doesn't exist" );
    
    pools[_poolIndex].exists = false;
    delete pools[_poolIndex].apy_rate;
    for(uint256 i=0;i<pools[_poolIndex].stakers;i++) {
      delete pools[_poolIndex].balances[pools[_poolIndex].players[i]];
      delete pools[_poolIndex].players[i];
    }
    delete pools[_poolIndex];
    emit removePool(_poolIndex);
  }
  function poolLength() external view returns (uint256) {
    return poolIndexes.length;
  }
  function getPool(uint256 _poolIndex) public view returns(uint256 totalStaked, uint256 stakers, bool isCrimeCash, uint8 openDay ) {
    require(pools[_poolIndex].exists == true, "Error: This pool doesn't exists");
    totalStaked = pools[_poolIndex].totalStaked;
    stakers     = pools[_poolIndex].stakers;
    isCrimeCash = pools[_poolIndex].isCrimeCash;
    openDay     = pools[_poolIndex].openDay;
  }
  function getPoolOpenDay(uint256 _poolIndex) public view returns(uint8) {
    require(pools[_poolIndex].exists == true, "Error: This pool doesn't exists");
    return pools[_poolIndex].openDay;
  }
  function playerStakedBalance(uint256 _poolIndex, address _crimer) public view returns(uint256) {
    require(pools[_poolIndex].exists == true, "Error: This pool doesn't exist");
    return pools[_poolIndex].balances[_crimer];
  }
  /***************************** Farm page function start *****************************/
  function stakeLp(uint256 _poolIndex, uint256 _amount) public onlyCrimer {
    require(pools[_poolIndex].isCrimeCash == false, "Error: Not allowed lp staking");
    pools[_poolIndex].lpToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
    pools[_poolIndex].totalStaked = pools[_poolIndex].totalStaked.add(_amount);
    pools[_poolIndex].balances[address(_msgSender())] = pools[_poolIndex].balances[address(_msgSender())].add(_amount);
    
    if ( !isExistsPlayerInPool(_poolIndex, _msgSender()) ) {
      pools[_poolIndex].players[pools[_poolIndex].stakers] = _msgSender();
      pools[_poolIndex].stakers++;
    }
    emit stakeLpToken(_poolIndex, address(_msgSender()), _amount);
  }
  function stakeCash(uint256 _poolIndex, address _crimer, uint256 _amount) public fromCrimerInfo {
    require(pools[_poolIndex].isCrimeCash == true, "Error: Not allowed cash staking");
    pools[_poolIndex].totalStaked = pools[_poolIndex].totalStaked.add(_amount);
    pools[_poolIndex].balances[address(_crimer)] = pools[_poolIndex].balances[address(_crimer)].add(_amount);
    
    if ( !isExistsPlayerInPool(_poolIndex, _crimer) ) {
      pools[_poolIndex].players[pools[_poolIndex].stakers] = _msgSender();
      pools[_poolIndex].stakers++;
    }
  }
  function unstake(uint256 _poolIndex, uint256 _amount) public onlyCrimer {
    require(pools[_poolIndex].isCrimeCash == false, "invalid unstaking");
    require(pools[_poolIndex].balances[address(_msgSender())] >= _amount, "insufficient balance");
    require(pools[_poolIndex].openDay <= roundDay, "Pool doesn't open yet");
    pools[_poolIndex].totalStaked = pools[_poolIndex].totalStaked.sub(_amount);
    pools[_poolIndex].balances[address(_msgSender())] = pools[_poolIndex].balances[address(_msgSender())].sub(_amount);
    pools[_poolIndex].lpToken.safeTransfer(address(_msgSender()), _amount);
    emit unstakeLpToken(_poolIndex, address(_msgSender()), _amount);
  }
  function getClaimAmount(uint256 _poolIndex, address _crimer, uint256 _boost) public view returns(uint256) {
    require(roundDay >= 1 && roundDay <= 30, "Error: Invalid round day");
    uint256 claimBalance = 0;
    if ( pools[_poolIndex].isCrimeCash ) {
      claimBalance = pools[_poolIndex].balances[_crimer].mul(uint256(pools[_poolIndex].apy_rate[roundDay-1])).div(100);
    }
    else {
      uint256 reward = uint256(pools[_poolIndex].apy_rate[roundDay-1]).mul(pools[_poolIndex].stakers);
      uint256 liquid_share_rate = pools[_poolIndex].balances[_crimer].div(pools[_poolIndex].totalStaked).mul(100);
      uint256 burnable_rate = 0;
      if ( pools[_poolIndex].stakers >= 10000 ) {
        if ( liquid_share_rate >= 50 ) {
          burnable_rate = 95;
        }
        else if ( liquid_share_rate >= 30 ) {
          burnable_rate = 90;
        }
        else if ( liquid_share_rate >= 10 ) {
          burnable_rate = 80;
        }
        else if ( liquid_share_rate >= 5 ) {
          burnable_rate = 50;
        }
        else {
          burnable_rate = 0;
        }
      }
      else if ( pools[_poolIndex].stakers >= 1000 ) {
        if ( liquid_share_rate >= 50 ) {
          burnable_rate = 90;
        }
        else if ( liquid_share_rate >= 30 ) {
          burnable_rate = 80;
        }
        else if ( liquid_share_rate >= 10 ) {
          burnable_rate = 50;
        }
        else {
          burnable_rate = 0;
        }
      }
      else if ( pools[_poolIndex].stakers >= 100 ) {
        if ( liquid_share_rate >= 50 ) {
          burnable_rate = 80;
        }
        else if ( liquid_share_rate >= 30 ) {
          burnable_rate = 50;
        }
        else if ( liquid_share_rate >= 10 ) {
          burnable_rate = 20;
        }
        else {
          burnable_rate = 0;
        }
      }
      else {
        burnable_rate = 0;
      }
      claimBalance = reward.sub(reward.mul(burnable_rate).div(100));
    }
    claimBalance = claimBalance.add(claimBalance.mul(_boost).div(100));
    return claimBalance;
  }
  
  function requestBuyCcash(uint8 _buyOptionIndex) public onlyCrimer payable {
    if (msg.value > 0) {
      ethAddress.transfer(msg.value);
    }
    else {
      revert();
    }
    emit eventRequestBuyCcash(_msgSender(), _buyOptionIndex);
  }
  
  function closeAllPool() public onlyOwner {
    for(uint256 i=0;i<poolIndexes.length;i++) {
      if ( pools[poolIndexes[i]].exists = true ) {
        for(uint256 j=0;j<pools[poolIndexes[i]].stakers;j++) {
          if ( pools[poolIndexes[i]].players[i] != address(0) ) {
            if ( pools[poolIndexes[i]].isCrimeCash == false ) {
              pools[poolIndexes[i]].lpToken.safeTransfer(address(pools[poolIndexes[i]].players[j]), pools[poolIndexes[i]].balances[pools[poolIndexes[i]].players[j]]);
            }
            delete pools[poolIndexes[i]].balances[pools[poolIndexes[i]].players[j]];
            delete pools[poolIndexes[i]].players[j];
          }
        }
        pools[poolIndexes[i]].stakers = 0;
        pools[poolIndexes[i]].totalStaked = 0;
      }
    }
  }
  
  //round-related functions
  function startRound() public onlyOwner {
    require(isRoundOpening == false, "Error: There is an opened round currently");
    isRoundOpening = true;
    roundDay = 1;
    crimegoldToken.mint(address(cfoAddress), goldForTeam); //transfer 3% crimegold token to core team when round starts.
    crimegoldToken.mint(address(this), goldForCrimer); //transfer 97% crimegold token to players when round ends.
    emit eventStartRound(goldForTeam, goldForCrimer);
  }
  function distributeGold(uint256 crimerCount, address[] memory _crimer, uint256[] memory amount) public onlyOwner returns (bool) {
    require(isRoundOpening == true, "Error: There is not an opened round currently");
    require(crimegoldToken.balanceOf(address(this))>0, "Error: There is not enough balance to distribute");
    uint256 _amount;
    for(uint256 i=0;i<crimerCount;i++) {
      if ( crimegoldToken.balanceOf(address(this)) < amount[i] )
        _amount = crimegoldToken.balanceOf(address(this));
      else
        _amount = amount[i];
      
      crimegoldToken.transfer(address(_crimer[i]), _amount);  
    }
    
    emit eventDistributeGold(_crimer, amount);
    return true;
  }
  function updateRoundDay() public fromCrimerInfo {
    require(roundDay >= 1 && roundDay < 30, "Error: Invalid round day");
    roundDay++;
  }
  function finishRound() public onlyOwner {
    require(isRoundOpening == true, "Error: There is not an opened round currently");
    closeAllPool();
    isRoundOpening = false;
    roundDay = 0;
    emit eventFinishRound();
  }
  function isExistsPlayerInPool(uint256 _poolIndex, address _player) public view returns (bool) {
    for(uint256 i=0;i<pools[_poolIndex].stakers;i++) {
      if ( pools[_poolIndex].players[i] == _player ) return true;
    }
    return false;
  }
  function contractAddress() public view returns (address) {
    return address(this);
  }
  modifier onlyCrimer() {
    require(_msgSender() != owner(), "Error: owner doens't allow");
    require(_msgSender() != address(0), "Error: zero address doesn't allow");
    require(isRoundOpening == true, "Error: There is not an opened round currently");
    _;
  }
  modifier fromCrimerInfo() {
    require(_msgSender() != address(0) && _msgSender() == crimerInfo, "Error: Not allowed.");
    _;
  }
}

contract CrimerInfo is Ownable {
  
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address;
  
  CrimeCashGame gameEngine;
  CrimeCash public crimecashToken;
  
  uint8   public maxStolenCountLimit = 5;
  uint8   public maxBuyLimit = 10;
  uint256 public minLimit = 10;
  uint256 public maxLimit = 50;
  uint256 public initBank = 500;
  uint256 public initCash = 500;
  uint256 public initAttack = 750;
  uint256 public initDefense = 500;
  
  struct Crimer {
    bool    exist;
    uint256 bank;
    uint256 cash;
    uint256 attack;
    uint256 defense;
    uint256 boost;
    uint256 referrals;
    uint256 protectedUntil;
    uint256[] boosts;
  }
  mapping(address=>Crimer) public crimers;
  mapping(address=>mapping(address=>uint8)) public stolenCount;
  mapping(uint256=>address) public crimer_addresses;
  uint256 public criminals;
  
  event eventAddNewCrimer(address crimer);
  event eventAddNewCrimerByReferral(address crimer, address byReferral);
  event eventMoveToBank(address crimer, uint256 amount);
  event eventMoveToCash(address crimer, uint256 amount);
  event eventDeposit(address crimer, uint256 amount);
  event eventClaim(address crimer, uint256 poolIndex, uint8 payout_mode, uint256 amount);
  event eventWithdraw(address crimer, uint256 _amount);
  event eventBuyAsset(address crimer, uint8 assetType, uint256 assetIndex, uint8 count, uint256 cost_amount);
  event eventStealCash(address crimer, address other, uint256 stolenCash, uint256 stolenRate);
  event stakeCashToken(uint256 poolIndex, address crimer, uint256 amount);
  event eventClearCrimers();
  event eventBoughtCcashToCrimer(address crimer, uint256 amount);
  
  constructor(CrimeCashGame _gameEngine, CrimeCash _crimecashToken) public {
    gameEngine = _gameEngine;
    crimecashToken = _crimecashToken;
  }
  
  function setInitCrimerParams(uint256 _bank, uint256 _cash, uint256 _attack, uint256 _defense) public onlyOwner {
    if (_bank > 0) initBank = _bank;
    if (_cash > 0) initCash = _cash;
    if (_attack > 0) initAttack = _attack;
    if (_defense > 0) initDefense = _defense;
  }
  function setLimitParams(uint256 _minLimit, uint256 _maxLimit) public onlyOwner {
    if (_minLimit > 0) minLimit = _minLimit;
    if (_maxLimit > 0) maxLimit = _maxLimit;
  }
  function setBuyLimit(uint8 _maxBuyLimit) public onlyOwner {
    if (_maxBuyLimit>0) maxBuyLimit = _maxBuyLimit;
  }
  function setStolenCountLimit(uint8 _maxStolenCountLimit) public onlyOwner {
    if (_maxStolenCountLimit>0) maxStolenCountLimit = _maxStolenCountLimit;
  }
  function createNewCrimer() public onlyCrimer {
    _createNewCrimer(_msgSender());
    emit eventAddNewCrimer(_msgSender());
  }
  function createNewCrimerByReferral(address byReferral) public onlyOwner {
    require(byReferral!=address(0), "Error: Invalid referral user");
    require(_msgSender() != byReferral, "Error: Something went wrong");
    require(crimers[byReferral].exist==true, "Error: Invalid crimer");
    
    _createNewCrimer(_msgSender());
    crimers[byReferral].referrals = crimers[byReferral].referrals.add(1);
    emit eventAddNewCrimerByReferral(_msgSender(), byReferral);
  }
  function _createNewCrimer(address crimerAddress) private {
    if (isNewCrimer(crimerAddress)) {
      Crimer memory _crimer;
      _crimer.exist = true;
      _crimer.bank = initBank;
      _crimer.cash = initCash;
      _crimer.attack = initAttack;
      _crimer.defense = initDefense;
      _crimer.boost = 0;
      _crimer.referrals = 0;
      _crimer.protectedUntil = now+ (15 minutes);
     
      crimers[crimerAddress] = _crimer;
      crimer_addresses[criminals] = crimerAddress;
      criminals++;
    }
    else {
      crimers[crimerAddress].exist = true;
      crimers[crimerAddress].bank = initBank;
      crimers[crimerAddress].cash = initCash;
      crimers[crimerAddress].attack = initAttack;
      crimers[crimerAddress].defense = initDefense;
      crimers[crimerAddress].boost = 0;
      crimers[crimerAddress].referrals = 0;
      crimers[crimerAddress].protectedUntil = now + (15 minutes);
    }
    crimecashToken.mint(address(this), initBank.add(initCash));
  }
  function crimerBoosts(address _crimer) public view returns(uint256[] memory boosts) {
    if (!isNewCrimer(_crimer)) {
      boosts = crimers[_crimer].boosts;
    }
  }
  function crimerList(address[] memory _crimers, address stealer, uint8 crimerCount) public view returns(address[] memory crimer, uint256[] memory cash, uint256[] memory power, uint256[] memory protectedUntil, uint256[] memory totalStolenCount) {
    for(uint8 i=0;i<crimerCount;i++) {
      crimer[i] = _crimers[i];
      cash[i] = crimers[_crimers[i]].bank.add(crimers[_crimers[i]].cash);
      power[i] = crimers[_crimers[i]].attack.add(crimers[_crimers[i]].defense);
      protectedUntil[i] = crimers[_crimers[i]].protectedUntil;
      totalStolenCount[i] = stealer == address(0) ? 0 : stolenCount[_crimers[i]][stealer];
    }
  }
  
  function deposit(uint256 _amount) public onlyCrimer {
    require(crimecashToken.balanceOf(_msgSender()) >= _amount, "Error: Insufficient balance");
    crimers[_msgSender()].bank = crimers[_msgSender()].bank.add(_amount);
    crimecashToken.transferFrom(address(_msgSender()), address(this), _amount);
    emit eventDeposit(_msgSender(), _amount);
  }
  function withdraw(uint256 _amount) public onlyCrimer {
    require(crimecashToken.balanceOf(address(this)) >= _amount, "Error: There is not enough balance to withdraw");
    require(crimers[_msgSender()].bank >= _amount, "Error: InInsufficient balance");
    
    crimers[_msgSender()].bank = crimers[_msgSender()].bank.sub(_amount);
    crimecashToken.transferFrom(address(this), address(_msgSender()), _amount);
    emit eventWithdraw(_msgSender(), _amount);
  }
  function moveToBank(uint256 _amount) public onlyCrimer {
    require(crimers[_msgSender()].cash >= _amount, "Error: There is not enough balance to move fund");
    
    crimers[_msgSender()].bank = crimers[_msgSender()].bank.add(_amount);
    crimers[_msgSender()].cash = crimers[_msgSender()].cash.sub(_amount);
    emit eventMoveToBank(_msgSender(), _amount);
  }
  function moveToCash(uint256 _amount) public onlyCrimer {
    require(crimers[_msgSender()].bank >= _amount, "Error: There is not enough balance to move fund");
    
    crimers[_msgSender()].cash = crimers[_msgSender()].cash.add(_amount);
    crimers[_msgSender()].bank = crimers[_msgSender()].bank.sub(_amount);
    emit eventMoveToCash(_msgSender(), _amount);
  }
  function buyAsset(uint8 assetType, uint256 assetIndex, uint8 _count) public onlyCrimer {
    require(_count <= maxBuyLimit, "Error: Something went wrong. unallocated crimer");
    uint256 _cost_amount;
    (uint256 power, uint256 cost) = gameEngine.getAsset(assetType, assetIndex);
    _cost_amount = cost.mul(uint256(_count));
    require(crimers[_msgSender()].cash >= _cost_amount, "Error: There is not enough balance to buy asset");
    if ( assetType == 1 ) {
      crimers[_msgSender()].attack = crimers[_msgSender()].attack.add(power.mul(uint256(_count)));
    }
    else if ( assetType == 2 ) {
      crimers[_msgSender()].defense = crimers[_msgSender()].defense.add(power.mul(uint256(_count)));
    }
    else if ( assetType == 3 ) {
      require(isAlreadyHasBoost(_msgSender(), assetIndex) == false, "Error: This boost is already exist");
      crimers[_msgSender()].boost = crimers[_msgSender()].boost.add(power);
      crimers[_msgSender()].boosts.push(assetIndex);
    }
    else {
      crimers[_msgSender()].protectedUntil = now + power;
    }
    crimers[_msgSender()].cash = crimers[_msgSender()].cash.sub(_cost_amount);
    emit eventBuyAsset(_msgSender(), assetType, assetIndex, _count, _cost_amount);
  }
  function isAlreadyHasBoost(address _crimer, uint256 boost) private view returns(bool) {
    for(uint256 i=0;i<crimers[_crimer].boosts.length;i++) {
      if ( crimers[_crimer].boosts[i] == boost ) return true;
    }
    return false;
  }
  
  function stealCash(address _crimer) public onlyCrimer {
    require(crimers[_crimer].protectedUntil <= now, "Error: This crimer is being at protected now");
    require(stolenCount[_crimer][_msgSender()]<=maxStolenCountLimit, "Error: You can no longer steal this player's cash");
    require(crimers[_crimer].cash >= 100, "Error: This crimer's cash is not enough to steal");
    require(crimerPower(_msgSender())>=crimerPower(_crimer), "Error: Your power is lower than this player's power");
    uint256 stolenRate = random(_msgSender(), _crimer);
    uint256 stolenCash = crimers[_crimer].cash.mul(stolenRate).div(100);
    crimers[_crimer].cash = crimers[_crimer].cash.sub(stolenCash);
    stolenCount[_crimer][_msgSender()]++;
    crimers[_msgSender()].cash = crimers[_msgSender()].cash.add(stolenCash);
    emit eventStealCash(_msgSender(), _crimer, stolenCash, stolenRate);
  }
  function random(address stealer, address crimer) public view returns(uint256) {
    return uint256(keccak256(abi.encodePacked(now, block.difficulty, stealer, crimer, address(this)))).mod(maxLimit.sub(minLimit))+minLimit;
  }
  function stakeCash(uint256 _poolIndex, uint256 _amount) public onlyCrimer {
    require(crimers[_msgSender()].bank>=_amount, "Error: There is not enough balance for staking");
    crimers[_msgSender()].bank = crimers[_msgSender()].bank.sub(_amount);
    
    gameEngine.stakeCash(_poolIndex, _msgSender(), _amount);
    emit stakeCashToken(_poolIndex, address(_msgSender()), _amount);
  }
  function claim(uint256 _poolIndex, uint8 _payout_mode) public onlyCrimer {
    require(gameEngine.getPoolOpenDay(_poolIndex) <= gameEngine.roundDay(), "Pool doesn't open yet");
    uint256 _amount = gameEngine.getClaimAmount(_poolIndex, _msgSender(), crimers[_msgSender()].boost);
    require(gameEngine.playerStakedBalance(_poolIndex, _msgSender())>0, "Error: Something went wrong");
    
    if ( _payout_mode == 1 ) {
      crimers[_msgSender()].bank = crimers[_msgSender()].bank.add(_amount);
    }
    else {
      _amount = _amount.mul(2);
      crimers[_msgSender()].cash = crimers[_msgSender()].cash.add(_amount);
    }
    crimecashToken.mint(address(this), _amount);
    emit eventClaim(_msgSender(), _poolIndex, _payout_mode, _amount);
  }
  
  //
  function sendBoughtCcashToCrimer(address _crimer, uint256 _amount) public onlyOwner {
    require(_amount>0, "Something went wrong. Invalid amount");
    crimecashToken.mint(address(_crimer), _amount);
    emit eventBoughtCcashToCrimer(_crimer, _amount);
  }
  
  function resetCrimeCash() public onlyOwner {
    crimecashToken.resetCrimCashSupply();
  }
  function crimerPower(address _crimer) public view returns(uint256) {
    if ( isNewCrimer(_crimer) ) return 0;
    return crimers[_crimer].attack.add(crimers[_crimer].defense);
  }
  
  function isNewCrimer(address _player) private view returns(bool) {
    for(uint256 i=0;i<criminals;i++) {
      if ( crimer_addresses[i] == _player ) return false;
    }
    return true;
  }
  
  function resetStolenCount() public onlyOwner {
    for(uint256 i=0;i<criminals;i++) {
      for(uint256 j=0;j<criminals;j++) {
        delete stolenCount[crimer_addresses[i]][crimer_addresses[j]];
      }
    }
    gameEngine.updateRoundDay();
  }
  function initCrimers() public onlyOwner {
    for(uint256 i=0;i<criminals;i++) {
      crimers[crimer_addresses[i]].exist = false;
      crimers[crimer_addresses[i]].bank = 0;
      crimers[crimer_addresses[i]].cash = 0;
      crimers[crimer_addresses[i]].attack = 0;
      crimers[crimer_addresses[i]].defense = 0;
      crimers[crimer_addresses[i]].boost = 0;
      crimers[crimer_addresses[i]].referrals = 0;
      crimers[crimer_addresses[i]].protectedUntil = 0;
      delete crimers[crimer_addresses[i]].boosts;
    }
    criminals = 0;
    emit eventClearCrimers();
  }
  modifier onlyCrimer() {
    require(_msgSender() != owner(), "Error: owner doens't allow");
    require(_msgSender() != address(0), "Error: zero address doesn't allow");
    require(gameEngine.isRoundOpening() == true, "Error: There is not an opened round currently");
    _;
  }
}