/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

// Part: BankConfig

interface BankConfig {
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

    function getReserveBps() external view returns (uint256);

    function getLiquidateBps() external view returns (uint256);
}

// Part: ERC20Interface

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint);
}

// Part: Goblin

interface Goblin {

    /// @dev Work on a (potentially new) position. Optionally send surplus token back to Bank.
    function work(uint256 id, address user, address borrowToken, uint256 borrow, uint256 debt, bytes calldata data) external payable;

    /// @dev Return the amount of ETH wei to get back if we are to liquidate the position.
    function health(uint256 id, address borrowToken) external view returns (uint256);

    /// @dev Liquidate the given position to token need. Send all ETH back to Bank.
    function liquidate(uint256 id, address user, address borrowToken) external;
}

// Part: Initializable

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(
      _initializing || _isConstructor() || !_initialized,
      'Initializable: contract is already initialized'
    );

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function _isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint cs;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      cs := extcodesize(self)
    }
    return cs == 0;
  }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Math

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// Part: OpenZeppelin/[email protected]/SafeMath

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


// Part: Governable

contract Governable is Initializable {
  address public governor; // The current governor.
  address public pendingGovernor; // The address pending to become the governor once accepted.

  modifier onlyGov() {
    require(msg.sender == governor, 'not the governor');
    _;
  }

  /// @dev Initialize the bank smart contract, using msg.sender as the first governor.
  function __Governable__init() internal initializer {
    governor = msg.sender;
    pendingGovernor = address(0);
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param _pendingGovernor The address to become the pending governor.
  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'not the pending governor');
    pendingGovernor = address(0);
    governor = msg.sender;
  }
}

// Part: OpenZeppelin/[email protected]/ERC20

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
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) override public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) override public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) override public returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) override public returns (bool) {
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

// Part: ReentrancyGuardUpgradeSafe

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
  // counter to allow mutex lock with only one SSTORE operation
  uint private _guardCounter;

  function __ReentrancyGuardUpgradeSafe__init() internal initializer {
    // The counter starts at one to prevent changing it from zero to a non-zero
    // value, which is a more expensive operation.
    _guardCounter = 1;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter, 'ReentrancyGuard: reentrant call');
  }

  uint[50] private ______gap;
}

// Part: SafeToken

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 val) internal {
        (bool success, ) = to.call{value:val}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

pragma solidity ^0.6.0;

contract IBToken is ERC20, Ownable {
    using SafeToken for address;
    using SafeMath for uint256;

    string public name = "";
    string public symbol = "";
    uint8 public decimals = 18;

    event Mint(address sender, address account, uint amount);
    event Burn(address sender, address account, uint amount);

    constructor(string memory _symbol) public {
        name = _symbol;
        symbol = _symbol;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
        emit Mint(msg.sender, account, amount);
    }

    function burn(address account, uint256 value) public onlyOwner {
        _burn(account, value);
        emit Burn(msg.sender, account, value);
    }
}

contract IBTokenFactory {
    function genIBToken(string memory _symbol) public returns(address) {
        return address(new IBToken(_symbol));
    }
}

pragma experimental ABIEncoderV2;

contract Bank is Initializable, ReentrancyGuardUpgradeSafe, Governable,IBTokenFactory {
      /// @notice Libraries
  using SafeToken for address;
  using SafeMath for uint;
  
    /// @notice Events
    event AddDebt(uint indexed id, uint debtShare);
    event RemoveDebt(uint indexed id, uint debtShare);
    event Work(uint256 indexed id, uint256 debt, uint back);
    event Kill(uint256 indexed id, address indexed killer, uint256 prize, uint256 left);
    uint256 constant GLO_VAL = 10000;
    
    struct TokenBank {
        address tokenAddr; 
        address ibTokenAddr; 
        bool isOpen;
        bool canDeposit; 
        bool canWithdraw; 
        uint256 totalVal;
        uint256 totalDebt;
        uint256 totalDebtShare;
        uint256 totalReserve;
        uint256 lastInterestTime;
    }
    
    struct Production {
        address coinToken;
        address currencyToken; 
        address borrowToken;
        bool isOpen;
        bool canBorrow;
        address goblin;
        uint256 minDebt;
        uint256 maxDebt;
        uint256 openFactor;
        uint256 liquidateFactor;
    }
    
    struct Position {
        address owner; 
        uint256 productionId;
        uint256 debtShare;
    }
    
    BankConfig public config;
    mapping(address => TokenBank) public banks;
    
    mapping(uint256 => Production) public productions;
    uint256 public currentPid;
    
    mapping(uint256 => Position) public positions;
    uint256 public currentPos;
    
    mapping(address => uint256[]) public userPosition;


    struct Pos{
        uint256 posid;
        address token0;
        address token1;
        address borrowToken;
        uint256 positionsValue;
        uint256 totalValue;
        address goblin;
    }
    
    mapping(address => bool) public killWhitelist;
    address public devAddr;
    
    function initialize(BankConfig _config) external initializer {
        __Governable__init();
        __ReentrancyGuardUpgradeSafe__init();
        config = _config;
        currentPid = 1;
        currentPos = 1;
    }

    /// @dev Require that the caller must be an EOA account to avoid flash loans.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, 'not eoa');
        _;
     }
      
    function getUserPosition(address user) view external returns(Pos[] memory){
        uint256[] memory userPos = userPosition[user];
        Pos[] memory p = new Pos[](userPos.length);
        for (uint256 i = 0;i<userPos.length;i++){
                p[i] = getPos(userPos[i]);
        }
        return p;
    }
    
    function getAllPosition()view external returns(Pos[] memory){
        Pos[] memory p = new Pos[](currentPos);
        uint256 index;
        for (uint256 i = 0;i<p.length;i++){
            if(positions[i+1].debtShare > 0){
                p[index] = getPos(i+1);
                index = index.add(1);
            }
        }
        return p;
    }
    
    function getPos(uint256 posid) view internal returns(Pos memory){
         Position memory pos = positions[posid];
            Production memory pro = productions[pos.productionId];
                (, uint256 asset, uint256 loan, ) = positionInfo(posid);
                return Pos({
                    posid:posid,
                    token0:pro.coinToken,
                    token1:pro.currencyToken,
                    borrowToken:pro.borrowToken,
                    positionsValue:asset,
                    totalValue:loan,
                    goblin:pro.goblin
                });
            
    }
    
    /// @dev Return the BNB debt value given the debt share. Be careful of unaccrued interests.
    /// @param debtShare The debt share to be converted.
    function debtShareToVal(address token, uint256 debtShare) public view returns (uint256) {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');
        if (bank.totalDebtShare == 0) return debtShare;
        return debtShare.mul(bank.totalDebt).div(bank.totalDebtShare);
    }
    
    /// @dev Return the debt share for the given debt value. Be careful of unaccrued interests.
    /// @param debtVal The debt value to be converted.
    function debtValToShare(address token, uint256 debtVal) public view returns (uint256) {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');
        if (bank.totalDebt == 0) return debtVal;
        return debtVal.mul(bank.totalDebtShare).div(bank.totalDebt);
    }
    
    function totalToken(address token) public view returns (uint256) {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');    
        uint balance = token == address(0) ? address(this).balance : SafeToken.myBalance(token);
        balance = bank.totalVal < balance? bank.totalVal: balance;
        return balance.add(bank.totalDebt).sub(bank.totalReserve);
    }
    
    function positionInfo(uint256 posId) public view returns (uint256, uint256, uint256, address) {
        Position storage pos = positions[posId];
        Production storage prod = productions[pos.productionId];
        return (pos.productionId, Goblin(prod.goblin).health(posId, prod.borrowToken),
            debtShareToVal(prod.borrowToken, pos.debtShare), pos.owner);
    }
    
    function deposit(address token, uint256 amount) external payable nonReentrant {
        TokenBank storage bank = banks[token];
        require(bank.isOpen && bank.canDeposit, 'Token not exist or cannot deposit');

        calInterest(token); 
        if (token == address(0)) {
            amount = msg.value;
        } else {
            SafeToken.safeTransferFrom(token, msg.sender, address(this), amount);
        }
        bank.totalVal = bank.totalVal.add(amount);
        uint256 total = totalToken(token).sub(amount); 
        uint256 ibTotal = IBToken(bank.ibTokenAddr).totalSupply();
        uint256 ibAmount = (total == 0 || ibTotal == 0) ? amount: amount.mul(ibTotal).div(total);
        IBToken(bank.ibTokenAddr).mint(msg.sender, ibAmount);
    }
    
    function withdraw(address token, uint256 pAmount) external nonReentrant {
        TokenBank storage bank = banks[token];
        require(bank.isOpen && bank.canWithdraw, 'Token not exist or cannot withdraw');

        calInterest(token);
        uint256 amount = pAmount.mul(totalToken(token)).div(IBToken(bank.ibTokenAddr).totalSupply());
        bank.totalVal = bank.totalVal.sub(amount);
        IBToken(bank.ibTokenAddr).burn(msg.sender, pAmount);
        if (token == address(0)) {
            SafeToken.safeTransferETH(msg.sender, amount);
        } else {
            SafeToken.safeTransfer(token, msg.sender, amount);
        }
    }
    
    function work(uint256 posId, uint256 pid, uint256 borrow, bytes calldata data)
    external payable onlyEOA nonReentrant {

        if (posId == 0) { 
            posId = currentPos;
            currentPos ++;
            positions[posId].owner = msg.sender;
            positions[posId].productionId = pid;
            positions[posId].debtShare = 0;
            
            userPosition[msg.sender].push(posId);
        } else { 
            require(posId < currentPos, "bad position id");
            require(positions[posId].owner == msg.sender, "not position owner");
            pid = positions[posId].productionId; 
        }
 
        Production storage production = productions[pid];
        require(production.isOpen, 'Production not exists');
        require(borrow == 0 || production.canBorrow, "Production can not borrow");

        calInterest(production.borrowToken);

        uint256 debt = _removeDebt(posId, production).add(borrow);
        bool isBorrowBNB = production.borrowToken == address(0);

        uint256 sendBNB = msg.value;
        uint256 beforeToken = 0;
        if (isBorrowBNB) {
            sendBNB = sendBNB.add(borrow);
            require(sendBNB <= address(this).balance && debt <= banks[production.borrowToken].totalVal, "insufficient BNB in the bank");
            beforeToken = address(this).balance.sub(sendBNB);
        } else {
            beforeToken = SafeToken.myBalance(production.borrowToken);
            require(borrow <= beforeToken && debt <= banks[production.borrowToken].totalVal, "insufficient borrowToken in the bank");
            beforeToken = beforeToken.sub(borrow);
            SafeToken.safeApprove(production.borrowToken, production.goblin, borrow);
        }

        Goblin(production.goblin).work{value:sendBNB}(posId, msg.sender, production.borrowToken, borrow, debt, data);

        uint256 backToken = isBorrowBNB? (address(this).balance.sub(beforeToken)) :
            SafeToken.myBalance(production.borrowToken).sub(beforeToken);

        if(backToken > debt) { // 没有借款
            backToken = backToken.sub(debt);
            debt = 0;

            isBorrowBNB? SafeToken.safeTransferETH(msg.sender, backToken):
                SafeToken.safeTransfer(production.borrowToken, msg.sender, backToken);

        }else if (debt > backToken) { // 有借款 
            debt = debt.sub(backToken);
            backToken = 0;

            require(debt >= production.minDebt && debt <= production.maxDebt, "Debt scale is out of scope");
            uint256 health = Goblin(production.goblin).health(posId, production.borrowToken);
            require(health.mul(production.openFactor) >= debt.mul(GLO_VAL), "bad work factor");
        
            _addDebt(posId, production, debt);
        }
        emit Work(posId, debt, backToken);
    }
    
    function kill(uint256 posId) external payable onlyEOA nonReentrant {
        require(killWhitelist[msg.sender],"Not Whitelist");
        
        Position storage pos = positions[posId];
        require(pos.debtShare > 0, "no debt");
        Production storage production = productions[pos.productionId];

        uint256 debt = _removeDebt(posId, production);

        uint256 health = Goblin(production.goblin).health(posId, production.borrowToken);
        require(health.mul(production.liquidateFactor) < debt.mul(GLO_VAL), "can't liquidate");
        bool isBNB = production.borrowToken == address(0);
        uint256 before = isBNB? address(this).balance: SafeToken.myBalance(production.borrowToken);
        
        Goblin(production.goblin).liquidate(posId, pos.owner, production.borrowToken);
        
        uint256 back = isBNB? address(this).balance: SafeToken.myBalance(production.borrowToken);
        back = back.sub(before);

        uint256 prize = back.mul(config.getLiquidateBps()).div(GLO_VAL);
        uint256 rest = back.sub(prize);
        uint256 left = 0;

        if (prize > 0) {
            isBNB? SafeToken.safeTransferETH(devAddr, prize): SafeToken.safeTransfer(production.borrowToken, devAddr, prize);
        }
        if (rest > debt) {
            left = rest.sub(debt);
            isBNB? SafeToken.safeTransferETH(pos.owner, left): SafeToken.safeTransfer(production.borrowToken, pos.owner, left);
        } else {
            banks[production.borrowToken].totalVal = banks[production.borrowToken].totalVal.sub(debt).add(rest);
        }
        emit Kill(posId, msg.sender, prize, left);
    }
    
    function _addDebt(uint256 posId, Production storage production, uint256 debtVal) internal {
        if (debtVal == 0) {
            return;
        }
        TokenBank storage bank = banks[production.borrowToken];
        Position storage pos = positions[posId];
        uint256 debtShare = debtValToShare(production.borrowToken, debtVal);
        pos.debtShare = pos.debtShare.add(debtShare);
        bank.totalVal = bank.totalVal.sub(debtVal);
        bank.totalDebtShare = bank.totalDebtShare.add(debtShare);
        bank.totalDebt = bank.totalDebt.add(debtVal);
        emit AddDebt(posId, debtShare);
    }
    
    function _removeDebt(uint256 posId, Production storage production) internal returns (uint256) {
        TokenBank storage bank = banks[production.borrowToken];
        Position storage pos = positions[posId];
        uint256 debtShare = pos.debtShare;
        if (debtShare > 0) {
            uint256 debtVal = debtShareToVal(production.borrowToken, debtShare);
            pos.debtShare = 0;
            bank.totalVal = bank.totalVal.add(debtVal);
            bank.totalDebtShare = bank.totalDebtShare.sub(debtShare);
            bank.totalDebt = bank.totalDebt.sub(debtVal);
            emit RemoveDebt(posId, debtShare);
            return debtVal;
        } else {
            return 0;
        }
    }
    
    function updateConfig(BankConfig _config) external onlyGov {
        config = _config;
    }
    
    function addBank(address token, string calldata _symbol) external onlyGov {
        TokenBank storage bank = banks[token];
        require(!bank.isOpen, 'token already exists');

        bank.isOpen = true;
        address ibToken = genIBToken(_symbol);
        bank.tokenAddr = token;
        bank.ibTokenAddr = ibToken;
        bank.canDeposit = true;
        bank.canWithdraw = true;
        bank.totalVal = 0;
        bank.totalDebt = 0;
        bank.totalDebtShare = 0;
        bank.totalReserve = 0;
        bank.lastInterestTime = now;
    }
    
    function createProduction(
        uint256 pid,
        bool isOpen, 
        bool canBorrow,
        address coinToken, 
        address currencyToken, 
        address borrowToken, 
        address goblin,
        uint256 minDebt, 
        uint256 maxDebt,
        uint256 openFactor, 
        uint256 liquidateFactor
        ) external onlyGov {

        if(pid == 0){
            pid = currentPid;
            currentPid ++;
        } else {
            require(pid < currentPid, "bad production id");
        }
        
        Production storage production = productions[pid];
        production.isOpen = isOpen;
        production.canBorrow = canBorrow;
        production.coinToken = coinToken;
        production.currencyToken = currencyToken;
        production.borrowToken = borrowToken;
        production.goblin = goblin;

        production.minDebt = minDebt;
        production.maxDebt = maxDebt;
        production.openFactor = openFactor;
        production.liquidateFactor = liquidateFactor;
    }
        
    function calInterest(address token) public {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');
        if (now > bank.lastInterestTime) {
            uint256 timePast = now.sub(bank.lastInterestTime);
            
            uint256 totalDebt = bank.totalDebt;
            uint256 totalBalance = totalToken(token);
            
            uint256 ratePerSec = config.getInterestRate(totalDebt, totalBalance);
            uint256 interest = ratePerSec.mul(timePast).mul(totalDebt).div(1e18);
            
            uint256 toReserve = interest.mul(config.getReserveBps()).div(GLO_VAL);
            
            bank.totalReserve = bank.totalReserve.add(toReserve);
            bank.totalDebt = bank.totalDebt.add(interest);
            bank.lastInterestTime = now;
        }
    }
    
    function withdrawReserve(address token, address to, uint256 value) external onlyGov nonReentrant {
        TokenBank storage bank = banks[token];
        require(bank.isOpen, 'token not exists');

        uint balance = token == address(0)? address(this).balance: SafeToken.myBalance(token);
        if(balance >= bank.totalVal.add(value)) {
           
        } else {
            bank.totalReserve = bank.totalReserve.sub(value);
            bank.totalVal = bank.totalVal.sub(value);
        }

        if (token == address(0)) {
            SafeToken.safeTransferETH(to, value);
        } else {
            SafeToken.safeTransfer(token, to, value);
        }
    }
    
    function ibTokenCalculation(address token, uint256 amount) view external returns(uint256){
        TokenBank memory bank = banks[token];
        uint256 total = totalToken(token).sub(amount); 
        uint256 ibTotal = IBToken(bank.ibTokenAddr).totalSupply();
        return (total == 0 || ibTotal == 0) ? amount: amount.mul(ibTotal).div(total);
    }
    
    function createkillWhitelist(address addr,bool status) external onlyGov {
        require(addr != address(0));
        killWhitelist[addr] = status;
    }
    
    function setDevAddr(address addr) external onlyGov{
        require(addr != address(0));
        devAddr = addr;
    }
    
    receive() external payable {}
}