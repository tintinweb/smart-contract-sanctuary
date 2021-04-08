/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v2.3.0/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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



// File: LockedGoldOracle.sol

pragma solidity 0.5.16;





// Simple contract regulating the total supply of gold locked at any
// given time so that the Cache contract can't over mint tokens
contract LockedGoldOracle is Ownable {

  using SafeMath for uint256;

  uint256 private _lockedGold;
  address private _cacheContract;

  event LockEvent(uint256 amount);
  event UnlockEvent(uint256 amount);

  function setCacheContract(address cacheContract) external onlyOwner {
    _cacheContract = cacheContract;
  }

  function lockAmount(uint256 amountGrams) external onlyOwner {
    _lockedGold = _lockedGold.add(amountGrams);
    emit LockEvent(amountGrams);
  }

  // Can only unlock amount of gold if it would leave the
  // total amount of locked gold greater than or equal to the
  // number of tokens in circulation
  function unlockAmount(uint256 amountGrams) external onlyOwner {
    _lockedGold = _lockedGold.sub(amountGrams);
    require(_lockedGold >= CacheGold(_cacheContract).totalCirculation());
    emit UnlockEvent(amountGrams);
  }

  function lockedGold() external view returns(uint256) {
    return _lockedGold;
  }

  function cacheContract() external view returns(address) {
    return _cacheContract;
  }
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v2.3.0/contracts/math/SafeMath.sol

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

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v2.3.0/contracts/token/ERC20/IERC20.sol

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


// File: CacheGold.sol

pragma solidity 0.5.16;






/// @title The CacheGold Token Contract
/// @author Cache Pte Ltd
contract CacheGold is IERC20, Ownable {

  using SafeMath for uint256;

  // ERC20 Detailed Info
  /* solhint-disable */
  string public constant name = "CACHE Gold";
  string public constant symbol = "CGT";
  uint8 public constant decimals = 8;
  /* solhint-enable */

  // 10^8 shortcut
  uint256 private constant TOKEN = 10 ** uint256(decimals);

  // Seconds in a day
  uint256 private constant DAY = 86400;

  // Days in a year
  uint256 private constant YEAR = 365;

  // The maximum transfer fee is 10 basis points
  uint256 private constant MAX_TRANSFER_FEE_BASIS_POINTS = 10;

  // Basis points means divide by 10,000 to get decimal
  uint256 private constant BASIS_POINTS_MULTIPLIER = 10000;

  // The storage fee of 0.25%
  uint256 private constant STORAGE_FEE_DENOMINATOR = 40000000000;

  // The inactive fee of 0.50%
  uint256 private constant INACTIVE_FEE_DENOMINATOR = 20000000000;

  // The minimum balance that would accrue a storage fee after 1 day
  uint256 private constant MIN_BALANCE_FOR_FEES = 146000;

  // Initial basis points for transfer fee
  uint256 private _transferFeeBasisPoints = 10;

  // Cap on total number of tokens that can ever be produced
  uint256 public constant SUPPLY_CAP = 8133525786 * TOKEN;

  // How many days need to pass before late fees can be collected (3 years)
  uint256 public constant INACTIVE_THRESHOLD_DAYS = 1095;

  // Token balance of each address
  mapping (address => uint256) private _balances;

  // Allowed transfer from address
  mapping (address => mapping (address => uint256)) private _allowances;

  // Last time storage fee was paid
  mapping (address => uint256) private _timeStorageFeePaid;

  // Last time the address produced a transaction on this contract
  mapping (address => uint256) private _timeLastActivity;

  // Amount of inactive fees already paid
  mapping (address => uint256) private _inactiveFeePaid;

  // If address doesn't have any activity for INACTIVE_THRESHOLD_DAYS
  // we can start deducting chunks off the address so that
  // full balance can be recouped after 200 years. This is likely
  // to happen if the user loses their private key.
  mapping (address => uint256) private _inactiveFeePerYear;

  // Addresses not subject to transfer fees
  mapping (address => bool) private _transferFeeExempt;

  // Address is not subject to storage fees
  mapping (address => bool) private _storageFeeExempt;

  // Save grace period on storage fees for an address
  mapping (address => uint256) private _storageFeeGracePeriod;

  // Current total number of tokens created
  uint256 private _totalSupply;

  // Address where storage and transfer fees are collected
  address private _feeAddress;

  // The address for the "backed treasury". When a bar is locked into the
  // vault for tokens to be minted, they are created in the backed_treasury
  // and can then be sold from this address.
  address private _backedTreasury;

  // The address for the "unbacked treasury". The unbacked treasury is a
  // storing address for excess tokens that are not locked in the vault
  // and therefore do not correspond to any real world value. If new bars are
  // locked in the vault, tokens will first be moved from the unbacked
  // treasury to the backed treasury before minting new tokens.
  //
  // This address only accepts transfers from the _backedTreasury or _redeemAddress
  // the general public should not be able to manipulate this balance.
  address private _unbackedTreasury;

  // The address for the LockedGoldOracle that determines the maximum number of
  // tokens that can be in circulation at any given time
  address private _oracle;

  // A fee-exempt address that can be used to collect gold tokens in exchange
  // for redemption of physical gold
  address private _redeemAddress;

  // An address that can force addresses with overdue storage or inactive fee to pay.
  // This is separate from the contract owner, because the owner will change
  // to a multisig address after deploy, and we want to be able to write
  // a script that can sign "force-pay" transactions with a single private key
  address private _feeEnforcer;

  // Grace period before storage fees kick in
  uint256 private _storageFeeGracePeriodDays = 0;

  // When gold bars are locked, we add tokens to circulation either
  // through moving them from the unbacked treasury or minting new ones,
  // or some combination of both
  event AddBackedGold(uint256 amount);

  // Before gold bars can be unlocked (removed from circulation), they must
  // be moved to the unbacked treasury, we emit an event when this happens
  // to signal a change in the circulating supply
  event RemoveGold(uint256 amount);

  // When an account has no activity for INACTIVE_THRESHOLD_DAYS
  // it will be flagged as inactive
  event AccountInactive(address indexed account, uint256 feePerYear);

  // If an previoulsy dormant account is reactivated
  event AccountReActive(address indexed account);

  /**
   * @dev Contructor for the CacheGold token sets internal addresses
   * @param unbackedTreasury The address of the unbacked treasury
   * @param backedTreasury The address of the backed treasury
   * @param feeAddress The address where fees are collected
   * @param redeemAddress The address where tokens are send to redeem physical gold
   * @param oracle The address of the LockedGoldOracle
   */
  constructor(address unbackedTreasury,
              address backedTreasury,
              address feeAddress,
              address redeemAddress,
              address oracle) public {
    _unbackedTreasury = unbackedTreasury;
    _backedTreasury = backedTreasury;
    _feeAddress = feeAddress;
    _redeemAddress = redeemAddress;
    _feeEnforcer = owner();
    _oracle = oracle;
    setFeeExempt(_feeAddress);
    setFeeExempt(_redeemAddress);
    setFeeExempt(_backedTreasury);
    setFeeExempt(_unbackedTreasury);
    setFeeExempt(owner());
  }

  /**
   * @dev Throws if called by any account other than THE ENFORCER
   */
  modifier onlyEnforcer() {
    require(msg.sender == _feeEnforcer);
    _;
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) external returns (bool) {
    // Update activity for the sender
    _updateActivity(msg.sender);

    // Can opportunistically mark an account inactive if someone
    // sends money to it
    if (_shouldMarkInactive(to)) {
      _setInactive(to);
    }

    _transfer(msg.sender, to, value);
    return true;
  }

  /**
  * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
  * Beware that changing an allowance with this method brings the risk that someone may use both the old
  * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
  * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
  * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
  * @param spender The address which will spend the funds.
  * @param value The amount of tokens to be spent.
  */
  function approve(address spender, uint256 value) external returns (bool) {
    _updateActivity(msg.sender);
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
  * @dev Transfer tokens from one address to another.
  * Note that while this function emits an Approval event, this is not required as per the specification,
  * and other compliant implementations may not emit the event.
  * Also note that even though balance requirements are not explicitly checked,
  * any transfer attempt over the approved amount will automatically fail due to
  * SafeMath revert when trying to subtract approval to a negative balance
  * @param from address The address which you want to send tokens from
  * @param to address The address which you want to transfer to
  * @param value uint256 the amount of tokens to be transferred
  */
  function transferFrom(address from, address to, uint256 value) external returns (bool) {
    _updateActivity(msg.sender);
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
    return true;
  }

  /**
  * @dev Increase the amount of tokens that an owner allowed to a spender.
  * approve should be called when allowed_[_spender] == 0. To increment
  * allowed value is better to use this function to avoid 2 calls (and wait until
  * the first transaction is mined)
  * From MonolithDAO Token.sol
  * Emits an Approval event.
  * @param spender The address which will spend the funds.
  * @param addedValue The amount of tokens to increase the allowance by.
  */
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    _updateActivity(msg.sender);
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
  * @dev Decrease the amount of tokens that an owner allowed to a spender.
  * approve should be called when allowed_[_spender] == 0. To decrement
  * allowed value is better to use this function to avoid 2 calls (and wait until
  * the first transaction is mined)
  * From MonolithDAO Token.sol
  * Emits an Approval event.
  * @param spender The address which will spend the funds.
  * @param subtractedValue The amount of tokens to decrease the allowance by.
  */
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    _updateActivity(msg.sender);
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  /**
  * @dev Function to add a certain amount of backed tokens. This will first
  * take any tokens from the _unbackedTreasury address and move them to the
  * _backedTreasury. Any remaining tokens will actually be minted.
  * This operation will fail if there is not a sufficient supply of locked gold
  * as determined by the LockedGoldOracle
  *
  * @param value The amount of tokens to add to the backed treasury
  * @return A boolean that indicates if the operation was successful.
  */
  function addBackedTokens(uint256 value) external onlyOwner returns (bool)
  {
    uint256 unbackedBalance = _balances[_unbackedTreasury];

    // Use oracle to check if there is actually enough gold
    // in custody to validate this operation
    uint256 lockedGrams =  LockedGoldOracle(_oracle).lockedGold();

    // Should reject mint if it would make the total supply
    // exceed the amount actually locked in vault
    require(lockedGrams >= totalCirculation().add(value),
            "Insufficent grams locked in LockedGoldOracle to complete operation");

    // If we have sufficient balance, just move from the unbacked to backed
    // treasury address
    if (value <= unbackedBalance) {
      _transfer(_unbackedTreasury, _backedTreasury, value);
    } else {
      if (unbackedBalance > 0) {
        // There is no sufficient balance, so we have to both transfer and mint new tokens
        // Transfer the remaining unbacked treasury balance to backed treasury
        _transfer(_unbackedTreasury, _backedTreasury, unbackedBalance);
      }

      // And mint the remaining to the backed treasury
      _mint(value.sub(unbackedBalance));
    }
    emit AddBackedGold(value);
    return true;
  }

  /**
  * @dev Manually pay storage fees on senders address. Exchanges may want to
  * periodically call this function to pay owed storage fees. This is a
  * cheaper option than 'send to self', which would also trigger paying
  * storage fees
  *
  * @return A boolean that indicates if the operation was successful.
  */
  function payStorageFee() external returns (bool) {
    _updateActivity(msg.sender);
    _payStorageFee(msg.sender);
    return true;
  }

  function setAccountInactive(address account) external onlyEnforcer returns (bool) {
    require(_shouldMarkInactive(account), "Account not eligible to be marked inactive");
    _setInactive(account);
  }

  /**
  * @dev Contract allows the forcible collection of storage fees on an address
  * if it is has been more than than 365 days since the last time storage fees
  * were paid on this address.
  *
  * Alternatively inactive fees may also be collected periodically on a prorated
  * basis if the account is currently marked as inactive.
  *
  * @param account The address to pay storage fees on
  * @return A boolean that indicates if the operation was successful.
  */
  function forcePayFees(address account) external onlyEnforcer returns(bool) {
    require(account != address(0));
    require(_balances[account] > 0,
            "Account has no balance, cannot force paying fees");

    // If account is inactive, pay inactive fees
    if (isInactive(account)) {
      uint256 paid = _payInactiveFee(account);
      require(paid > 0);
    } else if (_shouldMarkInactive(account)) {
      // If it meets inactive threshold, but hasn't been set yet, set it.
      // This will also trigger automatic payment of owed storage fees
      // before starting inactive fees
      _setInactive(account);
    } else {
      // Otherwise just force paying owed storage fees, which can only
      // be called if they are more than 365 days overdue
      require(daysSincePaidStorageFee(account) >= YEAR,
              "Account has paid storage fees more recently than 365 days");
      uint256 paid = _payStorageFee(account);
      require(paid > 0, "No appreciable storage fees due, will refund gas");
    }
  }

  /**
  * @dev Set the address that can force collecting fees from users
  * @param enforcer The address to force collecting fees
  * @return An bool representing successfully changing enforcer address
  */
  function setFeeEnforcer(address enforcer) external onlyOwner returns(bool) {
    require(enforcer != address(0));
    _feeEnforcer = enforcer;
    setFeeExempt(_feeEnforcer);
    return true;
  }

  /**
  * @dev Set the address to collect fees
  * @param newFeeAddress The address to collect storage and transfer fees
  * @return An bool representing successfully changing fee address
  */
  function setFeeAddress(address newFeeAddress) external onlyOwner returns(bool) {
    require(newFeeAddress != address(0));
    require(newFeeAddress != _unbackedTreasury,
            "Cannot set fee address to unbacked treasury");
    _feeAddress = newFeeAddress;
    setFeeExempt(_feeAddress);
    return true;
  }

  /**
  * @dev Set the address to deposit tokens when redeeming for physical locked bars.
  * @param newRedeemAddress The address to redeem tokens for bars
  * @return An bool representing successfully changing redeem address
  */
  function setRedeemAddress(address newRedeemAddress) external onlyOwner returns(bool) {
    require(newRedeemAddress != address(0));
    require(newRedeemAddress != _unbackedTreasury,
            "Cannot set redeem address to unbacked treasury");
    _redeemAddress = newRedeemAddress;
    setFeeExempt(_redeemAddress);
    return true;
  }

  /**
  * @dev Set the address of backed treasury
  * @param newBackedAddress The address of backed treasury
  * @return An bool representing successfully changing backed address
  */
  function setBackedAddress(address newBackedAddress) external onlyOwner returns(bool) {
    require(newBackedAddress != address(0));
    require(newBackedAddress != _unbackedTreasury,
            "Cannot set backed address to unbacked treasury");
    _backedTreasury = newBackedAddress;
    setFeeExempt(_backedTreasury);
    return true;
  }

  /**
  * @dev Set the address to unbacked treasury
  * @param newUnbackedAddress The address of unbacked treasury
  * @return An bool representing successfully changing unbacked address
  */
  function setUnbackedAddress(address newUnbackedAddress) external onlyOwner returns(bool) {
    require(newUnbackedAddress != address(0));
    require(newUnbackedAddress != _backedTreasury,
            "Cannot set unbacked treasury to backed treasury");
    require(newUnbackedAddress != _feeAddress,
            "Cannot set unbacked treasury to fee address ");
    require(newUnbackedAddress != _redeemAddress,
            "Cannot set unbacked treasury to fee address ");
    _unbackedTreasury = newUnbackedAddress;
    setFeeExempt(_unbackedTreasury);
    return true;
  }

  /**
  * @dev Set the LockedGoldOracle address
  * @param oracleAddress The address for oracle
  * @return An bool representing successfully changing oracle address
  */
  function setOracleAddress(address oracleAddress) external onlyOwner returns(bool) {
    require(oracleAddress != address(0));
    _oracle = oracleAddress;
    return true;
  }

  /**
  * @dev Set the number of days before storage fees begin accruing.
  * @param daysGracePeriod The global setting for the grace period before storage
  * fees begin accruing. Note that calling this will not change the grace period
  * for addresses already actively inside a grace period
  */
  function setStorageFeeGracePeriodDays(uint256 daysGracePeriod) external onlyOwner {
    _storageFeeGracePeriodDays = daysGracePeriod;
  }

  /**
  * @dev Set this account as being exempt from transfer fees. This may be used
  * in special circumstance for cold storage addresses owed by Cache, exchanges, etc.
  * @param account The account to exempt from transfer fees
  */
  function setTransferFeeExempt(address account) external onlyOwner {
    _transferFeeExempt[account] = true;
  }

  /**
  * @dev Set this account as being exempt from storage fees. This may be used
  * in special circumstance for cold storage addresses owed by Cache, exchanges, etc.
  * @param account The account to exempt from storage fees
  */
  function setStorageFeeExempt(address account) external onlyOwner {
    _storageFeeExempt[account] = true;
  }

  /**
  * @dev Set account is no longer exempt from all fees
  * @param account The account to reactivate fees
  */
  function unsetFeeExempt(address account) external onlyOwner {
    _transferFeeExempt[account] = false;
    _storageFeeExempt[account] = false;
  }

  /**
  * @dev Set a new transfer fee in basis points, must be less than or equal to 10 basis points
  * @param fee The new transfer fee in basis points
  */
  function setTransferFeeBasisPoints(uint256 fee) external onlyOwner {
    require(fee <= MAX_TRANSFER_FEE_BASIS_POINTS,
            "Transfer fee basis points must be an integer between 0 and 10");
    _transferFeeBasisPoints = fee;
  }

  /**
  * @dev Gets the balance of the specified address deducting owed fees and
  * accounting for the maximum amount that could be sent including transfer fee
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount sendable by the passed address
  * including transaction and storage fees
  */
  function balanceOf(address owner) external view returns (uint256) {
    return calcSendAllBalance(owner);
  }

  /**
  * @dev Gets the balance of the specified address not deducting owed fees.
  * this returns the 'traditional' ERC-20 balance that represents the balance
  * currently stored in contract storage.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount stored in passed address
  */
  function balanceOfNoFees(address owner) external view returns (uint256) {
    return _balances[owner];
  }

  /**
  * @dev Total number of tokens in existence. This includes tokens
  * in the unbacked treasury that are essentially unusable and not
  * in circulation
  * @return A uint256 representing the total number of minted tokens
  */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Function to check the amount of tokens that an owner allowed to a spender.
  * @param owner address The address which owns the funds.
  * @param spender address The address which will spend the funds.
  * @return A uint256 specifying the amount of tokens still available for the spender.
  */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
  * @return address that can force paying overdue inactive fees
  */
  function feeEnforcer() external view returns(address) {
    return _feeEnforcer;
  }

  /**
   * @return address where fees are collected
   */
  function feeAddress() external view returns(address) {
    return _feeAddress;
  }

  /**
   * @return address for redeeming tokens for gold bars
   */
  function redeemAddress() external view returns(address) {
    return _redeemAddress;
  }

  /**
   * @return address for backed treasury
   */
  function backedTreasury() external view returns(address) {
    return _backedTreasury;
  }

  /**
  * @return address for unbacked treasury
  */
  function unbackedTreasury() external view returns(address) {
    return _unbackedTreasury;
  }

  /**
  * @return address for oracle contract
  */
  function oracleAddress() external view returns(address) {
    return _oracle;
  }

  /**
  * @return the current number of days and address is exempt
  * from storage fees upon receiving tokens
  */
  function storageFeeGracePeriodDays() external view returns(uint256) {
    return _storageFeeGracePeriodDays;
  }

  /**
  * @return the current transfer fee in basis points [0-10]
  */
  function transferFeeBasisPoints() external view returns(uint256) {
    return _transferFeeBasisPoints;
  }

  /**
  * @dev Simulate the transfer from one address to another see final balances and associated fees
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  * @return See _simulateTransfer function
  */
  function simulateTransfer(address from, address to, uint256 value) external view returns (uint256[5] memory) {
    return _simulateTransfer(from, to, value);
  }

  /**
  * @dev Set this account as being exempt from all fees. This may be used
  * in special circumstance for cold storage addresses owed by Cache, exchanges, etc.
  * @param account The account to exempt from storage and transfer fees
  */
  function setFeeExempt(address account) public onlyOwner {
    _transferFeeExempt[account] = true;
    _storageFeeExempt[account] = true;
  }

  /**
  * @dev Check if the address given is extempt from storage fees
  * @param account The address to check
  * @return A boolean if the address passed is exempt from storage fees
  */
  function isStorageFeeExempt(address account) public view returns(bool) {
    return _storageFeeExempt[account];
  }

  /**
  * @dev Check if the address given is extempt from transfer fees
  * @param account The address to check
  * @return A boolean if the address passed is exempt from transfer fees
  */
  function isTransferFeeExempt(address account) public view returns(bool) {
    return _transferFeeExempt[account];
  }

  /**
  * @dev Check if the address given is extempt from transfer fees
  * @param account The address to check
  * @return A boolean if the address passed is exempt from transfer fees
  */
  function isAllFeeExempt(address account) public view returns(bool) {
    return _transferFeeExempt[account] && _storageFeeExempt[account];
  }

  /**
  * @dev Check if the address is considered inactive for not having transacted with
  * the contract for INACTIVE_THRESHOLD_DAYS
  * @param account The address to check
  * @return A boolean if the address passed is considered inactive
  */
  function isInactive(address account) public view returns(bool) {
    return _inactiveFeePerYear[account] > 0;
  }

  /**
  * @dev Total number of tokens that are actually in circulation, which is
  * total tokens excluding the unbacked treasury
  * @return A uint256 representing the total number of tokens in circulation
  */
  function totalCirculation() public view returns (uint256) {
    return _totalSupply.sub(_balances[_unbackedTreasury]);
  }

  /**
  * @dev Get the number of days since the account last paid storage fees
  * @param account The address to check
  * @return A uint256 representing the number of days since storage fees where last paid
  */
  function daysSincePaidStorageFee(address account) public view returns(uint256) {
    if (isInactive(account) || _timeStorageFeePaid[account] == 0) {
      return 0;
    }
    return block.timestamp.sub(_timeStorageFeePaid[account]).div(DAY);
  }

  /**
  * @dev Get the days since the account last sent a transaction to the contract (activity)
  * @param account The address to check
  * @return A uint256 representing the number of days since the address last had activity
  * with the contract
  */
  function daysSinceActivity(address account) public view returns(uint256) {
    if (_timeLastActivity[account] == 0) {
      return 0;
    }
    return block.timestamp.sub(_timeLastActivity[account]).div(DAY);
  }

  /**
  * @dev Returns the total number of fees owed on a particular address
  * @param account The address to check
  * @return The total storage and inactive fees owed on the address
  */
  function calcOwedFees(address account) public view returns(uint256) {
    return calcStorageFee(account).add(calcInactiveFee(account));
  }

  /**
   * @dev Calculate the current storage fee owed for a given address
   * @param account The address to check
   * @return A uint256 representing current storage fees for the address
   */
  function calcStorageFee(address account) public view returns(uint256) {

    // If an account is in an inactive state those fees take over and
    // storage fees are effectively paused
    uint256 balance = _balances[account];
    if (isInactive(account) || isStorageFeeExempt(account) || balance == 0) {
      return 0;
    }

    uint256 daysSinceStoragePaid = daysSincePaidStorageFee(account);
    uint256 daysInactive = daysSinceActivity(account);
    uint256 gracePeriod = _storageFeeGracePeriod[account];

    // If there is a grace period, we can deduct it from the daysSinceStoragePaid
    if (gracePeriod > 0) {
      if (daysSinceStoragePaid > gracePeriod) {
        daysSinceStoragePaid = daysSinceStoragePaid.sub(gracePeriod);
      } else {
        daysSinceStoragePaid = 0;
      }
    }

    if (daysSinceStoragePaid == 0) {
      return 0;
    }

    // This is an edge case where the account has not yet been marked inactive, but
    // will be marked inactive whenever there is a transaction allowing it to be marked.
    // Therefore we know storage fees will only be valid up to a point, and inactive
    // fees will take over.
    if (daysInactive >= INACTIVE_THRESHOLD_DAYS) {
      // This should not be at risk of being negative, because its impossible to force paying
      // storage fees without also setting the account to inactive, so if we are here it means
      // the last time storage fees were paid was BEFORE the account became eligible to be inactive
      // and it's always the case that daysSinceStoragePaid > daysInactive.sub(INACTIVE_THRESHOLD_DAYS)
      daysSinceStoragePaid = daysSinceStoragePaid.sub(daysInactive.sub(INACTIVE_THRESHOLD_DAYS));
    }

    // The normal case with normal storage fees
    return storageFee(balance, daysSinceStoragePaid);
  }

  /**
   * @dev Calculate the current inactive fee for a given address
   * @param account The address to check
   * @return A uint256 representing current inactive fees for the address
   */
  function calcInactiveFee(address account) public view returns(uint256) {
    uint256 balance = _balances[account];
    uint256 daysInactive = daysSinceActivity(account);

    // if the account is marked inactive already, can use the snapshot balance
    if (isInactive(account)) {
      return _calcInactiveFee(balance,
                          daysInactive,
                          _inactiveFeePerYear[account],
                          _inactiveFeePaid[account]);
    } else if (_shouldMarkInactive(account)) {
      // Account has not yet been marked inactive in contract, but the inactive fees will still be due.
      // Just assume snapshotBalance will be current balance after fees
      uint256 snapshotBalance = balance.sub(calcStorageFee(account));
      return _calcInactiveFee(snapshotBalance,                          // current balance
                              daysInactive,                             // number of days inactive
                              _calcInactiveFeePerYear(snapshotBalance), // the inactive fee per year based on balance
                              0);                                       // fees paid already
    }
    return 0;
  }

  /**
   * @dev Calculate the amount that would clear the balance from the address
   * accounting for owed storage and transfer fees
   * accounting for storage and transfer fees
   * @param account The address to check
   * @return A uint256 representing total amount an address has available to send
   */
  function calcSendAllBalance(address account) public view returns (uint256) {
    require(account != address(0));

    // Internal addresses pay no fees, so they can send their entire balance
    uint256 balanceAfterStorage = _balances[account].sub(calcOwedFees(account));
    if (_transferFeeBasisPoints == 0 || isTransferFeeExempt(account)) {
      return balanceAfterStorage;
    }

    // Edge cases where remaining balance is 0.00000001, but is effectively 0
    if (balanceAfterStorage <= 1) {
      return 0;
    }

    // Calculate the send all amount including storage fee
    // Send All = Balance / 1.001
    // and round up 0.00000001
    uint256 divisor = TOKEN.add(_transferFeeBasisPoints.mul(BASIS_POINTS_MULTIPLIER));
    uint256 sendAllAmount = balanceAfterStorage.mul(TOKEN).div(divisor).add(1);

    // Calc transfer fee on send all amount
    uint256 transFee = sendAllAmount.mul(_transferFeeBasisPoints).div(BASIS_POINTS_MULTIPLIER);

    // Fix to include rounding errors
    if (sendAllAmount.add(transFee) > balanceAfterStorage) {
      return sendAllAmount.sub(1);
    }

    return sendAllAmount;
  }

  /*
   * @dev Calculate the transfer fee on an amount
   * @param value The value being sent
   * @return A uint256 representing the transfer fee on sending the value given
   */
  function calcTransferFee(address account, uint256 value) public view returns(uint256) {
    if (isTransferFeeExempt(account)) {
      return 0;
    }
    // Basis points -> decimal multiplier:
    // f(x) = x / 10,0000 (10 basis points is 0.001)
    // So transfer fee working with integers =
    // f(balance, basis) = (balance * TOKEN) / (10,000 * TOKEN / basis)
    return value.mul(_transferFeeBasisPoints).div(BASIS_POINTS_MULTIPLIER);
  }

  /*
   * @dev Calculate the storage fee for a given balance after a certain number of
   * days have passed since the last time fees were paid.
   * @param balance The current balance of the address
   * @param daysSinceStoragePaid The number days that have passed since fees where last paid
   * @return A uint256 representing the storage fee owed
   */
  function storageFee(uint256 balance, uint256 daysSinceStoragePaid) public pure returns(uint256) {
    uint256 fee = balance.mul(TOKEN).mul(daysSinceStoragePaid).div(YEAR).div(STORAGE_FEE_DENOMINATOR);
    if (fee > balance) {
      return balance;
    }
    return fee;
  }

  /**
   * @dev Approve an address to spend another addresses' tokens.
   * @param owner The address that owns the tokens.
   * @param spender The address that will spend the tokens.
   * @param value The number of tokens that can be spent.
   */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
  * @dev Transfer token for a specified addresses. Transfer is modified from a
  * standard ERC20 contract in that it must also process transfer and storage fees
  * for the token itself. Additionally there are certain internal addresses that
  * are not subject to fees.
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {

    _transferRestrictions(to, from);

    // If the account was previously inactive and initiated the transfer, the
    // inactive fees and storage fees have already been paid by the time we get here
    // via the _updateActivity() call
    uint256 storageFeeFrom = calcStorageFee(from);
    uint256 storageFeeTo = 0;
    uint256 allFeeFrom = storageFeeFrom;
    uint256 balanceFromBefore = _balances[from];
    uint256 balanceToBefore = _balances[to];

    // If not sending to self can pay storage and transfer fee
    if (from != to) {
      // Need transfer fee and storage fee for receiver if not sending to self
      allFeeFrom = allFeeFrom.add(calcTransferFee(from, value));
      storageFeeTo = calcStorageFee(to);
      _balances[from] = balanceFromBefore.sub(value).sub(allFeeFrom);
      _balances[to] = balanceToBefore.add(value).sub(storageFeeTo);
      _balances[_feeAddress] = _balances[_feeAddress].add(allFeeFrom).add(storageFeeTo);

    } else {
      // Only storage fee if sending to self
      _balances[from] = balanceFromBefore.sub(storageFeeFrom);
      _balances[_feeAddress] = _balances[_feeAddress].add(storageFeeFrom);
    }

    // Regular Transfer
    emit Transfer(from, to, value);

    // Fee transfer on `from` address
    if (allFeeFrom > 0) {
      emit Transfer(from, _feeAddress, allFeeFrom);
      if (storageFeeFrom > 0) {
        _timeStorageFeePaid[from] = block.timestamp;
        _endGracePeriod(from);
      }
    }

    // If first time receiving coins, set the grace period
    // and start the the activity clock and storage fee clock
    if (_timeStorageFeePaid[to] == 0) {
      // We may change the grace period in the future so we want to
      // preserve it per address so there is no retroactive deduction
      _storageFeeGracePeriod[to] = _storageFeeGracePeriodDays;
      _timeLastActivity[to] = block.timestamp;
      _timeStorageFeePaid[to] = block.timestamp;
    }

    // Fee transfer on `to` address
    if (storageFeeTo > 0) {
      emit Transfer(to, _feeAddress, storageFeeTo);
      _timeStorageFeePaid[to] = block.timestamp;
      _endGracePeriod(to);
    } else if (balanceToBefore < MIN_BALANCE_FOR_FEES) {
      // MIN_BALANCE_FOR_FEES is the minimum amount in which a storage fee
      // would be due after a sigle day, so if the balance is above that,
      // the storage fee would always be greater than 0.
      //
      // This avoids the following condition:
      // 1. User receives tokens
      // 2. Users sends all but a tiny amount to another address
      // 3. A year later, the user receives more tokens. Because
      // their previous balance was super small, there were no appreciable
      // storage fee, therefore the storage fee clock was not reset
      // 4. User now owes storage fees on entire balance, as if they
      // held tokens for 1 year, instead of resetting the clock to now.
      _timeStorageFeePaid[to] = block.timestamp;
    }

    // If transferring to unbacked treasury, tokens are being taken from
    // circulation, because gold is being 'unlocked' from the vault
    if (to == _unbackedTreasury) {
      emit RemoveGold(value);
    }
  }

  /**
  * @dev Function to mint tokens to backed treasury. In general this method
  * will not be called on it's own, but instead will be called from
  * addBackedTokens.
  * @param value The amount of tokens to mint to backed treasury
  * @return A boolean that indicates if the operation was successful.
  */
  function _mint(uint256 value) internal returns(bool) {

    // Can't break supply cap
    require(_totalSupply.add(value) <= SUPPLY_CAP, "Call would exceed supply cap");

    // Can only mint if the unbacked treasury balance is 0
    require(_balances[_unbackedTreasury] == 0, "The unbacked treasury balance is not 0");

    // Can only mint to the backed treasury
    _totalSupply = _totalSupply.add(value);
    _balances[_backedTreasury] = _balances[_backedTreasury].add(value);
    emit Transfer(address(0), _backedTreasury, value);
    return true;
  }

  /**
   * @dev Apply storage fee deduction
   * @param account The account to pay storage fees
   * @return A uint256 representing the storage fee paid
   */
  function _payStorageFee(address account) internal returns(uint256) {
    uint256 storeFee = calcStorageFee(account);
    if (storeFee == 0) {
      return 0;
    }

    // Reduce account balance and add to fee address
    _balances[account] = _balances[account].sub(storeFee);
    _balances[_feeAddress] = _balances[_feeAddress].add(storeFee);
    emit Transfer(account, _feeAddress, storeFee);
    _timeStorageFeePaid[account] = block.timestamp;
    _endGracePeriod(account);
    return storeFee;
  }

  /**
   * @dev Apply inactive fee deduction
   * @param account The account to pay inactive fees
   * @return A uint256 representing the inactive fee paid
   */
  function _payInactiveFee(address account) internal returns(uint256) {
    uint256 fee = _calcInactiveFee(
        _balances[account],
        daysSinceActivity(account),
        _inactiveFeePerYear[account],
        _inactiveFeePaid[account]);

    if (fee == 0) {
      return 0;
    }

    _balances[account] = _balances[account].sub(fee);
    _balances[_feeAddress] = _balances[_feeAddress].add(fee);
    _inactiveFeePaid[account] = _inactiveFeePaid[account].add(fee);
    emit Transfer(account, _feeAddress, fee);
    return fee;
  }

  function _shouldMarkInactive(address account) internal view returns(bool) {
    // Can only mark an account as inactive if
    //
    // 1. it's not fee exempt
    // 2. it has a balance
    // 3. it's been over INACTIVE_THRESHOLD_DAYS since last activity
    // 4. it's not already marked inactive
    // 5. the storage fees owed already consume entire balance
    if (account != address(0) &&
        _balances[account] > 0 &&
        daysSinceActivity(account) >= INACTIVE_THRESHOLD_DAYS &&
        !isInactive(account) &&
        !isAllFeeExempt(account) &&
        _balances[account].sub(calcStorageFee(account)) > 0) {
      return true;
    }
    return false;
  }

  /**
  * @dev Mark an account as inactive. The function will automatically deduct
  * owed storage fees and inactive fees in one go.
  *
  * @param account The account to mark inactive
  */
  function _setInactive(address account) internal {

    // First get owed storage fees
    uint256 storeFee = calcStorageFee(account);
    uint256 snapshotBalance = _balances[account].sub(storeFee);

    // all _setInactive calls are wrapped in _shouldMarkInactive, which
    // already checks this, so we shouldn't hit this condition
    assert(snapshotBalance > 0);

    // Set the account inactive on deducted balance
    _inactiveFeePerYear[account] = _calcInactiveFeePerYear(snapshotBalance);
    emit AccountInactive(account, _inactiveFeePerYear[account]);
    uint256 inactiveFees = _calcInactiveFee(snapshotBalance,
                                            daysSinceActivity(account),
                                            _inactiveFeePerYear[account],
                                            0);

    // Deduct owed storage and inactive fees
    uint256 fees = storeFee.add(inactiveFees);
    _balances[account] = _balances[account].sub(fees);
    _balances[_feeAddress] = _balances[_feeAddress].add(fees);
    _inactiveFeePaid[account] = _inactiveFeePaid[account].add(inactiveFees);
    emit Transfer(account, _feeAddress, fees);

    // Reset storage fee clock if storage fees paid
    if (storeFee > 0) {
      _timeStorageFeePaid[account] = block.timestamp;
      _endGracePeriod(account);
    }
  }

  /**
  * @dev Update the activity clock on an account thats originated a transaction.
  * If the account has previously been marked inactive or should have been
  * marked inactive, it will opportunistically collect those owed fees.
  *
  * @param account The account to update activity
  */
  function _updateActivity(address account) internal {
    // Cache has the ability to force collecting storage and inactivity fees,
    // but in the event an address was missed, can we still detect if the
    // account was inactive when they next transact
    //
    // Here we simply set the account as being inactive, collect the previous
    // storage and inactive fees that were owed, and then reactivate the account
    if (_shouldMarkInactive(account)) {
      // Call will pay existing storage fees before marking inactive
      _setInactive(account);
    }

    // Pay remaining fees and reset fee clocks
    if (isInactive(account)) {
      _payInactiveFee(account);
      _inactiveFeePerYear[account] = 0;
      _timeStorageFeePaid[account] = block.timestamp;
      emit AccountReActive(account);
    }

    // The normal case will just hit this and update
    // the activity clock for the account
    _timeLastActivity[account] = block.timestamp;
  }

  /**
   * @dev Turn off storage fee grace period for an address the first
   * time storage fees are paid (after grace period has ended)
   * @param account The account to turn off storage fee grace period
   */
  function _endGracePeriod(address account) internal {
    if (_storageFeeGracePeriod[account] > 0) {
      _storageFeeGracePeriod[account] = 0;
    }
  }

  /**
  * @dev Enforce the rules of which addresses can transfer to others
  * @param to The sending address
  * @param from The receiving address
  */
  function _transferRestrictions(address to, address from) internal view {
    require(from != address(0));
    require(to != address(0));
    require(to != address(this), "Cannot transfer tokens to the contract");

    // unbacked treasury can only transfer to backed treasury
    if (from == _unbackedTreasury) {
      require(to == _backedTreasury,
              "Unbacked treasury can only transfer to backed treasury");
    }

    // redeem address can only transfer to unbacked or backed treasury
    if (from == _redeemAddress) {
      require((to == _unbackedTreasury) || (to == _backedTreasury),
              "Redeem address can only transfer to treasury");
    }

    // Only the backed treasury  and redeem address
    // can transfer to unbacked treasury
    if (to == _unbackedTreasury) {
      require((from == _backedTreasury) || (from == _redeemAddress),
              "Unbacked treasury can only receive from redeem address and backed treasury");
    }

    // Only the unbacked treasury can transfer to the backed treasury
    if (to == _backedTreasury) {
      require((from == _unbackedTreasury) || (from == _redeemAddress),
              "Only unbacked treasury and redeem address can transfer to backed treasury");
    }
  }

  /**
   * @dev Simulate the transfer from one address to another see final balances and associated fees
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @return a uint256 array of 5 values representing the
   * [0] storage fees `from`
   * [1] storage fees `to`
   * [2] transfer fee `from`
   * [3] final `from` balance
   * [4] final `to` balance
   */
  function _simulateTransfer(address from, address to, uint256 value) internal view returns (uint256[5] memory) {
    uint256[5] memory ret;
    // Return value slots
    // 0 - fees `from`
    // 1 - fees `to`
    // 2 - transfer fee `from`
    // 3 - final `from` balance
    // 4 - final `to` balance
    ret[0] = calcOwedFees(from);
    ret[1] = 0;
    ret[2] = 0;

    // Don't double charge storage fee sending to self
    if (from != to) {
      ret[1] = calcOwedFees(to);
      ret[2] = calcTransferFee(from, value);
      ret[3] = _balances[from].sub(value).sub(ret[0]).sub(ret[2]);
      ret[4] = _balances[to].add(value).sub(ret[1]);
    } else {
      ret[3] = _balances[from].sub(ret[0]);
      ret[4] = ret[3];
    }
    return ret;
  }

  /**
  * @dev Calculate the amount of inactive fees due per year on the snapshot balance.
  * Should return 50 basis points or 1 token minimum.
  *
  * @param snapshotBalance The balance of the account when marked inactive
  * @return uint256 the inactive fees due each year
  */
  function _calcInactiveFeePerYear(uint256 snapshotBalance) internal pure returns(uint256) {
    uint256 inactiveFeePerYear = snapshotBalance.mul(TOKEN).div(INACTIVE_FEE_DENOMINATOR);
    if (inactiveFeePerYear < TOKEN) {
      return TOKEN;
    }
    return inactiveFeePerYear;
  }

  /**
  * @dev Calcuate inactive fees due on an account
  * @param balance The current account balance
  * @param daysInactive The number of days the account has been inactive
  * @param feePerYear The inactive fee per year based on snapshot balance
  * @param paidAlready The amount of inactive fees that have been paid already
  * @return uint256 for inactive fees due
  */
  function _calcInactiveFee(uint256 balance,
                        uint256 daysInactive,
                        uint256 feePerYear,
                        uint256 paidAlready) internal pure returns(uint256) {
    uint256 daysDue = daysInactive.sub(INACTIVE_THRESHOLD_DAYS);
    uint256 totalDue = feePerYear.mul(TOKEN).mul(daysDue).div(YEAR).div(TOKEN).sub(paidAlready);

    // The fee per year can be off by 0.00000001 so we can collect
    // the final dust after 200 years
    if (totalDue > balance || balance.sub(totalDue) <= 200) {
      return balance;
    }
    return totalDue;
  }
}