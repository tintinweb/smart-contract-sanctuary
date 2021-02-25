pragma solidity 0.5.8;

import "./Capper.sol";
import "./Pauser.sol";
import "./Prohibiter.sol";

contract Admin is Capper, Prohibiter {
    address public admin = address(0);

    event CapperChanged(address indexed oldCapper, address indexed newCapper, address indexed sender);
    event PauserChanged(address indexed oldPauser, address indexed newPauser, address indexed sender);
    event ProhibiterChanged(address indexed oldProhibiter, address indexed newProhibiter, address indexed sender);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "the sender is not the admin");
        _;
    }

    function changeCapper(address _account) public onlyAdmin whenNotPaused isNotZeroAddress(_account) {
        address old = capper;
        capper = _account;
        emit CapperChanged(old, capper, msg.sender);
    }

    /**
     * Change Pauser
     * @dev "whenNotPaused" modifier should not be used here
     */
    function changePauser(address _account) public onlyAdmin isNotZeroAddress(_account) {
        address old = pauser;
        pauser = _account;
        emit PauserChanged(old, pauser, msg.sender);
    }

    function changeProhibiter(address _account) public onlyAdmin whenNotPaused isNotZeroAddress(_account) {
        address old = prohibiter;
        prohibiter = _account;
        emit ProhibiterChanged(old, prohibiter, msg.sender);
    }
}

pragma solidity 0.5.8;

import "./Common.sol";

contract Capper is Common {
    uint256 public capacity = 0;
    address public capper = address(0);

    event Cap(uint256 indexed newCapacity, address indexed sender);

    modifier onlyCapper() {
        require(msg.sender == capper, "the sender is not the capper");
        _;
    }

    modifier notMoreThanCapacity(uint256 _amount) {
        require(_amount <= capacity, "this amount is more than capacity");
        _;
    }

    function _cap(uint256 _amount) internal {
        capacity = _amount;
        emit Cap(capacity, msg.sender);
    }
}

pragma solidity 0.5.8;

contract Common {
    modifier isNotZeroAddress(address _account) {
        require(_account != address(0), "this account is the zero address");
        _;
    }

    modifier isNaturalNumber(uint256 _amount) {
        require(0 < _amount, "this amount is not a natural number");
        _;
    }
}

pragma solidity 0.5.8;

import "./Pauser.sol";

contract Minter is Pauser {
    address public minter = address(0);

    modifier onlyMinter() {
        require(msg.sender == minter, "the sender is not the minter");
        _;
    }
}

pragma solidity 0.5.8;

import "./Minter.sol";

contract MinterAdmin is Minter {
    address public minterAdmin = address(0);

    event MinterChanged(address indexed oldMinter, address indexed newMinter, address indexed sender);

    modifier onlyMinterAdmin() {
        require(msg.sender == minterAdmin, "the sender is not the minterAdmin");
        _;
    }

    function changeMinter(address _account) public onlyMinterAdmin whenNotPaused isNotZeroAddress(_account) {
        address old = minter;
        minter = _account;
        emit MinterChanged(old, minter, msg.sender);
    }
}

pragma solidity 0.5.8;

import "./Admin.sol";
import "./MinterAdmin.sol";

contract Owner is Admin, MinterAdmin {
    address public owner = address(0);

    event OwnerChanged(address indexed oldOwner, address indexed newOwner, address indexed sender);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin, address indexed sender);
    event MinterAdminChanged(address indexed oldMinterAdmin, address indexed newMinterAdmin, address indexed sender);

    modifier onlyOwner() {
        require(msg.sender == owner, "the sender is not the owner");
        _;
    }

    function changeOwner(address _account) public onlyOwner whenNotPaused isNotZeroAddress(_account) {
        address old = owner;
        owner = _account;
        emit OwnerChanged(old, owner, msg.sender);
    }

    /**
     * Change Admin
     * @dev "whenNotPaused" modifier should not be used here
     */
    function changeAdmin(address _account) public onlyOwner isNotZeroAddress(_account) {
        address old = admin;
        admin = _account;
        emit AdminChanged(old, admin, msg.sender);
    }

    function changeMinterAdmin(address _account) public onlyOwner whenNotPaused isNotZeroAddress(_account) {
        address old = minterAdmin;
        minterAdmin = _account;
        emit MinterAdminChanged(old, minterAdmin, msg.sender);
    }
}

pragma solidity 0.5.8;

import "./Common.sol";

contract Pauser is Common {
    address public pauser = address(0);
    bool public paused = false;

    event Pause(bool status, address indexed sender);

    modifier onlyPauser() {
        require(msg.sender == pauser, "the sender is not the pauser");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "this is a paused contract");
        _;
    }

    modifier whenPaused() {
        require(paused, "this is not a paused contract");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        paused = true;
        emit Pause(paused, msg.sender);
    }

    function unpause() public onlyPauser whenPaused {
        paused = false;
        emit Pause(paused, msg.sender);
    }
}

pragma solidity 0.5.8;

import "./Pauser.sol";

contract Prohibiter is Pauser {
    address public prohibiter = address(0);
    mapping(address => bool) public prohibiteds;

    event Prohibition(address indexed prohibited, bool status, address indexed sender);

    modifier onlyProhibiter() {
        require(msg.sender == prohibiter, "the sender is not the prohibiter");
        _;
    }

    modifier onlyNotProhibited(address _account) {
        require(!prohibiteds[_account], "this account is prohibited");
        _;
    }

    modifier onlyProhibited(address _account) {
        require(prohibiteds[_account], "this account is not prohibited");
        _;
    }

    function prohibit(address _account) public onlyProhibiter whenNotPaused isNotZeroAddress(_account) onlyNotProhibited(_account) {
        prohibiteds[_account] = true;
        emit Prohibition(_account, prohibiteds[_account], msg.sender);
    }

    function unprohibit(address _account) public onlyProhibiter whenNotPaused isNotZeroAddress(_account) onlyProhibited(_account) {
        prohibiteds[_account] = false;
        emit Prohibition(_account, prohibiteds[_account], msg.sender);
    }
}

pragma solidity 0.5.8;

import "./Common.sol";

contract Wiper is Common  {
    address public wiper = address(0);
    
    modifier onlyWiper() {
        require(msg.sender == wiper, "the sender is not the wiper");
        _;
    }

    function initializeWiper(address _account) public isNotZeroAddress(_account) {
        require(wiper == address(0), "the wiper can only be initiated once");
        wiper = _account;
    }
}

pragma solidity 0.5.8;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./Roles/Owner.sol";

contract Token_v1 is Initializable, ERC20, Owner {
    string public name;
    string public symbol;
    uint8 public decimals;

    event Mint(address indexed mintee, uint256 amount, address indexed sender);
    event Burn(address indexed burnee, uint256 amount, address indexed sender);

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owner,
        address _admin,
        address _capper,
        address _prohibiter,
        address _pauser,
        address _minterAdmin,
        address _minter
        ) public initializer {
            require(_owner != address(0), "_owner is the zero address");
            require(_admin != address(0), "_admin is the zero address");
            require(_capper != address(0), "_capper is the zero address");
            require(_prohibiter != address(0), "_prohibiter is the zero address");
            require(_pauser != address(0), "_pauser is the zero address");
            require(_minterAdmin != address(0), "_minterAdmin is the zero address");
            require(_minter != address(0), "_minter is the zero address");
            name = _name;
            symbol = _symbol;
            decimals = _decimals;
            owner = _owner;
            admin = _admin;
            capper = _capper;
            prohibiter = _prohibiter;
            pauser = _pauser;
            minterAdmin = _minterAdmin;
            minter = _minter;
    }

    function cap(uint256 _amount) public onlyCapper whenNotPaused isNaturalNumber(_amount) {
        require(totalSupply() <= _amount, "this amount is less than the totalySupply");
        _cap(_amount);
    }

    function mint(address _account, uint256 _amount) public onlyMinter whenNotPaused notMoreThanCapacity(totalSupply().add(_amount)) isNaturalNumber(_amount) {
        _mint(_account, _amount);
        emit Mint(_account, _amount, msg.sender);
    }

    function transfer(address _recipient, uint256 _amount) public whenNotPaused onlyNotProhibited(msg.sender) isNaturalNumber(_amount) returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public whenNotPaused onlyNotProhibited(_sender) isNaturalNumber(_amount) returns (bool) {
        return super.transferFrom(_sender, _recipient, _amount);
    }

    function burn(uint256 _amount) public isNaturalNumber(_amount) {
        _burn(msg.sender, _amount);
        emit Burn(msg.sender, _amount, msg.sender);
    }
}

pragma solidity 0.5.8;

import "./Token_v1.sol";
import "./Roles/Wiper.sol";

contract Token_v2 is Token_v1, Wiper {

    event Wipe(address indexed addr, uint256 amount);
    event WiperChanged(address indexed oldWiper, address indexed newWiper, address indexed sender);

    // only admin can change wiper
    function changeWiper(address _account) public onlyAdmin whenNotPaused isNotZeroAddress(_account) {
        address old = wiper;
        wiper = _account;
        emit WiperChanged(old, wiper, msg.sender);
    }

    // wipe balance of prohibited address
    function wipe(address _account) public whenNotPaused onlyWiper onlyProhibited(_account) {
        uint256 _balance = balanceOf(_account);
        _burn(_account, _balance);
        emit Wipe(_account, _balance);
    }
}

pragma solidity >=0.4.24 <0.6.0;


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
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
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

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
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
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}