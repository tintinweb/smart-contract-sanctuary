/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-19
*/

// SPDX-License-Identifier: NONE

// Eleven.finance bigfoot platform
// Telegram: @ElevenFinance


pragma solidity 0.5.17;


// Part: BankConfig

interface BankConfig {
  /// @dev Return minimum bankCurrency debt size per position.
  function minDebtSize() external view returns (uint);

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint debt, uint floating) external view returns (uint);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint);

  /// @dev Return whether the given address is a bigfoot.
  function isBigfoot(address bigfoot) external view returns (bool);

  /// @dev Return whether the given bigfoot accepts more debt. Revert on non-bigfoot.
  function acceptDebt(address bigfoot) external view returns (bool);

  /// @dev Return the work factor for the bigfoot + bankCurrency debt, using 1e4 as denom. Revert on non-bigfoot.
  function workFactor(address bigfoot, uint debt) external view returns (uint);

  /// @dev Return the kill factor for the bigfoot + bankCurrency debt, using 1e4 as denom. Revert on non-bigfoot.
  function killFactor(address bigfoot, uint debt) external view returns (uint);
}

// Part: ERC20Interface

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint);
}

// Part: Bigfoot

interface Bigfoot {
  /// @dev Work on a (potentially new) position. Optionally send bankCurrency back to Bank.
  function work(
    uint id,
    address user,
    uint debt,
    bytes calldata data
  ) external;

  /// @dev Return the amount of bankCurrency wei to get back if we are to liquidate the position.
  function health(uint id) external view returns (uint);

  /// @dev Liquidate the given position to bankCurrency. Send all bankCurrency back to Bank.
  function liquidate(uint id) external;
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
  function myBalance(address token) internal view returns (uint) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint) {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeApprove');
  }

  function safeTransfer(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransfer');
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransferFrom');
  }

  function safeTransferBNB(address to, uint value) internal {
    (bool success, ) = to.call.value(value)(new bytes(0));
    require(success, '!safeTransferBNB');
  }
}

interface IElevenVault{
    function depositAll() external;
    function withdraw(uint amount) external;
    function withdrawAll() external;
    function getPricePerFullShare() external view returns(uint);
}

interface CurvePool{
  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint256);
}

contract Bank is Initializable, ERC20, ReentrancyGuardUpgradeSafe, Governable {
  /// @notice Libraries
  using SafeToken for address;
  using SafeMath for uint;

  /// @notice Events
  event AddDebt(uint indexed id, uint debtShare);
  event RemoveDebt(uint indexed id, uint debtShare);
  event Work(uint indexed id, uint loan);
  event Kill(uint indexed id, address indexed killer, uint prize, uint left);

  // @notice Graveyard
  struct Death{
      uint height;
      uint id;
      uint debt;
      uint size;
      uint returned;
  }
  
  mapping(address=>Death[]) public graveyard;

  address public bankcurrency;
  address public vault;

  string public name;
  string public symbol;
  uint8 public decimals;

  struct Position {
    address bigfoot;
    address owner;
    uint debtShare;
  }

  BankConfig public config;
  
  mapping(uint => Position) public positions;
  
  uint public nextPositionID;

  uint public glbDebtShare;
  uint public glbDebtVal;
  uint public lastAccrueTime;
  uint public reservePool;

  /// @dev Require that the caller must be an EOA account to avoid flash loans.
  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'not eoa');
    _;
  }

  /// @dev Add more debt to the global debt pool.
  modifier accrue(uint msgValue) {
    if (now > lastAccrueTime) {
      uint interest = pendingInterest(msgValue);
      uint toReserve = interest.mul(config.getReservePoolBps()).div(10000);
      reservePool = reservePool.add(toReserve);
      glbDebtVal = glbDebtVal.add(interest);
      lastAccrueTime = now;
    }
    _;
  }
  

  function initialize(BankConfig _config, address _bankToken, address _vault, string calldata _name, string calldata _symbol, uint8 _decimals) external initializer {
    bankcurrency = _bankToken;
    vault = _vault;
    __Governable__init();
    __ReentrancyGuardUpgradeSafe__init();
    config = _config;
    lastAccrueTime = now;
    nextPositionID = 1;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    approve();
  }
  
  // @dev approve tokens to be spent by contracts
  function approve() internal{
    bankcurrency.safeApprove(vault, uint(-1));
  }


  // @dev deposit unutilized funds to vault
  function depositToVault() internal{
    IElevenVault(vault).depositAll();
  }

  // @dev just in case dev forgot something or has to recover something
  function additionalApprove(address _token, address _spender) onlyGov external{
    require(_token != bankcurrency && _token != vault, "no rugs allowed");
    _token.safeApprove(_spender, uint(-1));
  }
  
  // @dev bank currency in vault
  function insideVaultBankCurrency() public view returns(uint){
    uint bal = vault.myBalance();
    uint pps = IElevenVault(vault).getPricePerFullShare();
    return bal.mul(pps).div(1e18);
  }
  
  // @dev getpricepershare, used in front
  function getPricePerFullShare() public view returns(uint){
      return uint(1 ether).mul(totalBankCurrency()).div(totalSupply());
  }
  
  // @dev withdraws from vault with no errors
  function safeWithdrawFromFarm(uint _amount) internal{
    if(_amount < insideVaultBankCurrency()) IElevenVault(vault).withdraw(_amount.mul(1e18).div(IElevenVault(vault).getPricePerFullShare().add(1)));
    else IElevenVault(vault).withdrawAll();
  }
  
  
  // @dev transfer from bank currency and/or 11unusedbankcurrency with no errors
  function safeTransferBankCurrency(address _receiver, uint _amount) internal{
    uint inside = bankcurrency.myBalance();
    if(inside>=_amount) bankcurrency.safeTransfer(_receiver, _amount);
    else {
      safeWithdrawFromFarm(_amount.sub(inside));
      if(bankcurrency.myBalance()<_amount)
        bankcurrency.safeTransfer(_receiver, bankcurrency.myBalance());
      else
        bankcurrency.safeTransfer(_receiver, _amount);
    }
  }
  

  // @dev Total bank currency inside the contract bankCurrencyer on the vault or not
  function bankCurrencyBalance() public view returns (uint) {
    return bankcurrency.myBalance().add(insideVaultBankCurrency());
  }

  /// @dev Return the pending interest that will be accrued in the next call.
  /// @param msgValue Balance value to subtract off pool3Balance() when called from payable functions.
  function pendingInterest(uint msgValue) public view returns (uint) {
    if (now > lastAccrueTime) {
      uint timePast = now.sub(lastAccrueTime);
      uint balance = bankCurrencyBalance().sub(msgValue);
      uint ratePerSec = config.getInterestRate(glbDebtVal, balance);
      return ratePerSec.mul(glbDebtVal).mul(timePast).div(1e18);
    } else {
      return 0;
    }
  }

  /// @dev Return the bankCurrency debt value given the debt share. Be careful of unaccrued interests.
  /// @param debtShare The debt share to be converted.
  function debtShareToVal(uint debtShare) public view returns (uint) {
    if (glbDebtShare == 0) return debtShare; // When there's no share, 1 share = 1 val.
    return debtShare.mul(glbDebtVal).div(glbDebtShare);
  }

  /// @dev Return the debt share for the given debt value. Be careful of unaccrued interests.
  /// @param debtVal The debt value to be converted.
  function debtValToShare(uint debtVal) public view returns (uint) {
    if (glbDebtShare == 0) return debtVal; // When there's no share, 1 share = 1 val.
    return debtVal.mul(glbDebtShare).div(glbDebtVal).add(1);
  }

  /// @dev Return bankCurrency value and debt of the given position. Be careful of unaccrued interests.
  /// @param id The position ID to query.
  function positionInfo(uint id) public view returns (uint, uint) {
    Position storage pos = positions[id];
    return (Bigfoot(pos.bigfoot).health(id), debtShareToVal(pos.debtShare));
  }

  /// @dev Return the total bankCurrency entitled to the token holders. Be careful of unaccrued interests.
  function totalBankCurrency() public view returns (uint) {
    return bankCurrencyBalance().add(glbDebtVal).sub(reservePool);
  }
  


  /// @dev Add more bankCurrency to the bank. Hope to get some good returns.
  function deposit(uint[] calldata amounts) external accrue(0)  nonReentrant {
    uint total = totalBankCurrency();
    uint diff = transferBankCurrency(amounts);
    uint share = total == 0 ? diff : diff.mul(totalSupply()).div(total);
    _mint(msg.sender, share);
    require(totalSupply() >= 1e6, 'deposit: total supply too low');
    depositToVault();
  }

  /// @dev Withdraw bankCurrency from the bank by burning the share tokens.
  function withdraw(uint share, uint8) external accrue(0) nonReentrant {
    uint amount = share.mul(totalBankCurrency()).div(totalSupply());
    require(amount <= bankCurrencyBalance(), "Utilization too high, withdraw an smaller amount");
    _burn(msg.sender, share);
    safeTransferBankCurrency(msg.sender, amount);
    uint supply = totalSupply();
    require(supply == 0 || supply >= 1e6, 'withdraw: total supply too low');
  }
  
  // @dev Don't do this unless you know what you're doing
  function emergencyWithdraw() external{
    uint share = balanceOf(msg.sender);
    uint amount = share.mul(totalBankCurrency()).div(totalSupply());
    _burn(msg.sender, share);
    safeTransferBankCurrency(msg.sender, amount);
  }
  
  // @dev Deposit dollars, convert to bankCurrency and stake in vault
  function transferBankCurrency(uint[] memory amounts) internal returns(uint){
    uint bfrbankCurrency = bankcurrency.myBalance();
    if(amounts[0]>0) bankcurrency.safeTransferFrom(msg.sender, address(this), amounts[0]);
    uint aftrbankCurrency = bankcurrency.myBalance();
    return (aftrbankCurrency.sub(bfrbankCurrency));
  }
  
  /// @dev Create a new farming position to unlock your yield farming potential.
  /// @param id The ID of the position to unlock the earning. Use ZERO for new position.
  /// @param bigfoot The address of the authorized bigfoot to work for this position.
  /// @param loan The amount of bankCurrency to borrow from the pool.
  /// @param maxReturn The max amount of bankCurrency to return to the pool.
  /// @param data The calldata to pass along to the bigfoot for more working context.
  function work(
    uint id,
    address bigfoot,
    uint loan,
    uint maxReturn,
    uint[] calldata amounts,
    bytes calldata data
  ) external onlyEOA nonReentrant accrue(0){ 
    // 1. Sanity check the input position, or add a new position of ID is 0.
    if (id == 0) {
      id = nextPositionID++;
      positions[id].bigfoot = bigfoot;
      positions[id].owner = msg.sender;
    } else {
      require(id < nextPositionID, 'bad position id');
      require(positions[id].bigfoot == bigfoot, 'bad position bigfoot');
      require(positions[id].owner == msg.sender, 'not position owner');
    }
    emit Work(id, loan);
    // 2. Make sure the bigfoot can accept more debt and remove the existing debt.
    require(config.isBigfoot(bigfoot), 'not a bigfoot');
    require(loan == 0 || config.acceptDebt(bigfoot), 'bigfoot not accept more debt');
    uint debt = _removeDebt(id).add(loan);
    // 3. Perform the actual work, using a new scope to avoid stack-too-deep errors.
    uint back;
    {
      uint sendBankCurrency = transferBankCurrency(amounts).add(loan);
      require(sendBankCurrency <= bankCurrencyBalance(), 'insufficient CURRENCY in the bank');
      uint beforeBankCurrency = bankCurrencyBalance().sub(sendBankCurrency);
      safeTransferBankCurrency(bigfoot, sendBankCurrency);
      Bigfoot(bigfoot).work(id, msg.sender, debt, data);
      back = bankCurrencyBalance().sub(beforeBankCurrency);
    }
    // 4. Check and update position debt.
    uint lessDebt = Math.min(debt, Math.min(back, maxReturn));
    debt = debt.sub(lessDebt);
    if (debt > 0) {
      require(debt >= config.minDebtSize(), 'too small debt size');
      uint health = Bigfoot(bigfoot).health(id);
      uint workFactor = config.workFactor(bigfoot, debt);
      require(health.mul(workFactor) >= debt.mul(10000), 'bad work factor');
      _addDebt(id, debt);
    }
    // 5. Return excess bankCurrency back.
    if (back > lessDebt) safeTransferBankCurrency(msg.sender, back - lessDebt);
    // 6. Deposit back unused to vault
    depositToVault();
    // 7. Check total debt share/value not too small
    require(glbDebtShare >= 1e6, 'remaining global debt share too small');
    require(glbDebtVal >= 1e6, 'remaining global debt value too small');
  }

  /// @dev Kill the given to the position. Liquidate it immediately if killFactor condition is met.
  /// @param id The position ID to be killed.
  function kill(uint id) external onlyEOA accrue(0) nonReentrant {
    // 1. Verify that the position is eligible for liquidation.
    Position storage pos = positions[id];
    require(pos.debtShare > 0, 'no debt');
    uint debt = _removeDebt(id);
    uint health = Bigfoot(pos.bigfoot).health(id);
    uint killFactor = config.killFactor(pos.bigfoot, debt);
    require(health.mul(killFactor) < debt.mul(10000), "can't liquidate");
    
    // 2. Perform liquidation and compute the amount of bankCurrency received.
    uint beforeBankCurrency = bankCurrencyBalance();
    Bigfoot(pos.bigfoot).liquidate(id);
    uint back = bankCurrencyBalance().sub(beforeBankCurrency);
    uint prize = back.mul(config.getKillBps()).div(10000);
    uint rest = back.sub(prize);
    // 3. Clear position debt and return funds to liquidator and position owner.
    if (prize > 0) safeTransferBankCurrency(msg.sender, prize);
    uint left = rest > debt ? rest - debt : 0;
    if (left > 0) safeTransferBankCurrency(pos.owner, left);
    // 4. Deposit remaining to vault
    depositToVault();
    emit Kill(id, msg.sender, prize, left);
    graveyard[pos.owner].push(Death(block.number, id, debt, health, left));
  }

  /// @dev Internal function to add the given debt value to the given position.
  function _addDebt(uint id, uint debtVal) internal {
    Position storage pos = positions[id];
    uint debtShare = debtValToShare(debtVal);
    pos.debtShare = pos.debtShare.add(debtShare);
    glbDebtShare = glbDebtShare.add(debtShare);
    glbDebtVal = glbDebtVal.add(debtVal);
    emit AddDebt(id, debtShare);
  }

  /// @dev Internal function to clear the debt of the given position. Return the debt value.
  function _removeDebt(uint id) internal returns (uint) {
    Position storage pos = positions[id];
    uint debtShare = pos.debtShare;
    if (debtShare > 0) {
      uint debtVal = debtShareToVal(debtShare);
      pos.debtShare = 0;
      glbDebtShare = glbDebtShare.sub(debtShare);
      glbDebtVal = glbDebtVal.sub(debtVal);
      emit RemoveDebt(id, debtShare);
      return debtVal;
    } else {
      return 0;
    }
  }

  
  /// @dev Update bank configuration to a new address. Must only be called by owner.
  /// @param _config The new configurator address.
  function updateConfig(BankConfig _config) external onlyGov {
    config = _config;
  }
  /// @dev Withdraw bankCurrency reserve for underwater positions to the given address.
  /// @param to The address to transfer bankCurrency to.
  /// @param value The number of bankCurrency tokens to withdraw. Must not exceed `reservePool`.
  function withdrawReserve(address to, uint value) external onlyGov nonReentrant {
    reservePool = reservePool.sub(value);
    require(value<=bankCurrencyBalance(), "not enough funds");
    safeTransferBankCurrency(to, value);
  }

  
  /// @dev Reduce bankCurrency reserve, effectively giving them to the depositors.
  /// @param value The number of bankCurrency reserve to reduce.
  function reduceReserve(uint value) external onlyGov {
    reservePool = reservePool.sub(value);
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyGov nonReentrant {
    token.safeTransfer(to, value);
  }
}