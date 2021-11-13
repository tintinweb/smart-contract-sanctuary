/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

// File: contracts/InclusiveFeevault.sol

pragma solidity =0.6.2;


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
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Vault is Initializable, OwnableUpgradeSafe {
    using SafeMath for uint256;

    // How many lockToken tokens each user has
    mapping (address => uint256) public amountLocked;
    // The price when you extracted your earnings so we can whether you got new earnings or not
    mapping (address => uint256) public lastPriceEarningsExtracted;
    // When the user started locking his lockToken tokens
    mapping (address => uint256) public depositStarts;
    mapping (address => uint256) public lockingTime;
    // The uniswap lockToken token contract
    address public lockToken;
    // The reward token that people receive based on the staking time
    address public rewardToken;
    // How many lockToken tokens are locked
    uint256 public totalLiquidityLocked;
    // The total lockTokenFee generated
    uint256 public totalLockTokenFeeMined;
    uint256 public lockTokenFeePrice;
    uint256 public accomulatedRewards;
    uint256 public pricePadding;
    address payable public devTreasury;
    uint256 public minTimeLock;
    uint256 public maxTimeLock;
    uint256 public minDevTreasuryPercentage;
    uint256 public maxDevTreasuryPercentage;
    // The last block number when fee was updated
    uint256 public lastBlockFee;
    uint256 public rewardPerBlock;

    // increase the lockTokenFeePrice
    receive() external payable {
        addFeeAndUpdatePrice(msg.value);
    }

    function initialize(address _lockToken, address _rewardToken, address payable _devTreasury) public initializer {
        __Ownable_init();
        lockToken = _lockToken;
        pricePadding = 1e18;
        devTreasury = _devTreasury;
        minTimeLock = 1 days;
        maxTimeLock = 365 days;
        minDevTreasuryPercentage = 60e18;
        maxDevTreasuryPercentage = 1e18;
        lastBlockFee = 0;
        rewardToken = _rewardToken;
        rewardPerBlock = 6e15;
    }

    function setLockToken(address _lockToken) external onlyOwner {
        lockToken = _lockToken;
    }

    // Must be in 1e18 since it's using the pricePadding
    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
      rewardPerBlock = _rewardPerBlock;
    }

    function setDevTreasury(address payable _devTreasury) external onlyOwner {
        devTreasury = _devTreasury;
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
    }

    // Must be in seconds
    function setTimeLocks(uint256 _minTimeLock, uint256 _maxTimeLock) external onlyOwner {
        minTimeLock = _minTimeLock;
        maxTimeLock = _maxTimeLock;
    }

    function setDevPercentages(uint256 _minDevTreasuryPercentage, uint256 _maxDevTreasuryPercentage) external onlyOwner {
        require(minDevTreasuryPercentage > maxDevTreasuryPercentage, 'Vault: The min % must be larger');
        minDevTreasuryPercentage = _minDevTreasuryPercentage;
        maxDevTreasuryPercentage = _maxDevTreasuryPercentage;
    }

    /// @notice When ETH is added, the price is increased
    /// Price is = (feeIn / totalLockTokenFeeDistributed) + currentPrice
    /// padded with 18 zeroes that get removed after the calculations
    /// if there are no locked lockTokens, the price is 0
    function addFeeAndUpdatePrice(uint256 _feeIn) internal {
        accomulatedRewards = accomulatedRewards.add(_feeIn);
        if (totalLiquidityLocked == 0) {
          lockTokenFeePrice = 0;
        } else {
          lockTokenFeePrice = (_feeIn.mul(pricePadding).div(totalLiquidityLocked)).add(lockTokenFeePrice);
        }
    }

    /// @notice To calculate how much fee should be added based on time
    function updateFeeIn() internal {
        // setup the intial block instead of getting rewards right away
        if (lastBlockFee != 0) {
            // Use it
            uint256 blocksPassed = block.number - lastBlockFee;
            // We don't need to divide by the padding since we want the result padded since the CESS token has 18 decimals
            uint256 feeIn = blocksPassed.mul(rewardPerBlock);
            if (feeIn > 0) addFeeAndUpdatePrice(feeIn);
            // Update it
        }
        lastBlockFee = block.number;
    }

    // The time lock is reset every new deposit
    function lockLiquidity(uint256 _amount, uint256 _timeLock) public {
        updateFeeIn();
        require(_amount > 0, 'Vault: Amount must be larger than zero');
        require(_timeLock >= minTimeLock && _timeLock <= maxTimeLock, 'Vault: You must setup a locking time between the ranges');
        // Transfer lockToken tokens inside here while earning fees from every transfer
        uint256 approval = IERC20(lockToken).allowance(msg.sender, address(this));
        require(approval >= _amount, 'Vault: You must approve the desired amount of lockToken tokens to this contract first');
        
        //FIX for inclusive fee tokens
        uint256 initialAmount = IERC20(lockToken).balanceOf(address(this));                 
        IERC20(lockToken).transferFrom(msg.sender, address(this), _amount);
        _amount = IERC20(lockToken).balanceOf(address(this)).sub(initialAmount);   
        totalLiquidityLocked = totalLiquidityLocked.add(_amount);
        // Extract earnings in case the user is not a new Locked lockToken
        if (lastPriceEarningsExtracted[msg.sender] != 0 && lastPriceEarningsExtracted[msg.sender] != lockTokenFeePrice) {
            extractEarnings();
        }
        // Set the initial price
        if (lockTokenFeePrice == 0) {
            lockTokenFeePrice = accomulatedRewards.mul(pricePadding).div(_amount).add(1e18);
            lastPriceEarningsExtracted[msg.sender] = 1e18;
        } else {
            lastPriceEarningsExtracted[msg.sender] = lockTokenFeePrice;
        }
        // The price doesn't change when locking lockToken. It changes when fees are generated from transfers
        amountLocked[msg.sender] = amountLocked[msg.sender].add(_amount);
        // Notice that the locking time is reset when new lockToken is added
        depositStarts[msg.sender] = now;
        lockingTime[msg.sender] = _timeLock;
    }

    // We check for new earnings by seeing if the price the user last extracted his earnings
    // is the same or not to determine whether he can extract new earnings or not
    function extractEarnings() public {
      updateFeeIn();
      require(amountLocked[msg.sender] > 0, 'Vault: You must have locked lockToken provider tokens to extract your earnings');
      require(lockTokenFeePrice != lastPriceEarningsExtracted[msg.sender], 'Vault: You have already extracted your earnings');
      // The amountLocked price minus the last price extracted
      uint256 myPrice = lockTokenFeePrice.sub(lastPriceEarningsExtracted[msg.sender]);
      uint256 earnings = amountLocked[msg.sender].mul(myPrice).div(pricePadding);
      lastPriceEarningsExtracted[msg.sender] = lockTokenFeePrice;
      accomulatedRewards = accomulatedRewards.sub(earnings);
      uint256 devTreasuryPercentage = calcDevTreasuryPercentage(lockingTime[msg.sender]);
      uint256 devTreasuryEarnings = earnings.mul(devTreasuryPercentage).div(1e20);
      uint256 remaining = earnings.sub(devTreasuryEarnings);

      // Transfer the earnings
      IERC20(rewardToken).transfer(devTreasury, devTreasuryEarnings);
      IERC20(rewardToken).transfer(msg.sender, remaining);
    }

    // The user must lock the lockToken for 1 year and only then can extract his Locked lockToken tokens
    // he must extract all the lockTokens for simplicity and security purposes
    function extractLiquidity() public {
      updateFeeIn();
      require(amountLocked[msg.sender] > 0, 'Vault: You must have locked lockTokens to extract them');
      require(now.sub(depositStarts[msg.sender]) >= lockingTime[msg.sender], 'Vault: You must wait the specified locking time to extract your lockToken provider tokens');
      // Extract earnings in case there are some
      if (lastPriceEarningsExtracted[msg.sender] != 0 && lastPriceEarningsExtracted[msg.sender] != lockTokenFeePrice) {
          extractEarnings();
      }
      uint256 locked = amountLocked[msg.sender];
      amountLocked[msg.sender] = 0;
      depositStarts[msg.sender] = now;
      lastPriceEarningsExtracted[msg.sender] = 0;
      totalLiquidityLocked = totalLiquidityLocked.sub(locked);
      IERC20(lockToken).transfer(msg.sender, locked);
    }

    /// Returns the treasury percentage padded with 18 zeroes
    function calcDevTreasuryPercentage(uint256 _lockingTime) public view returns(uint256) {
        require(_lockingTime >= minTimeLock && _lockingTime <= maxTimeLock, 'Vault: You must setup a locking time between the ranges');
        if (_lockingTime == maxTimeLock) {
            return maxDevTreasuryPercentage;
        }
        if (_lockingTime == minTimeLock) {
            return minDevTreasuryPercentage;
        }
        uint256 padding = 1e18;
        uint256 combinedDays = maxTimeLock.sub(minTimeLock);
        uint256 combinedFee = minDevTreasuryPercentage.sub(maxDevTreasuryPercentage);
        // There's no risk of a ratio == 0 since we return the right percentage when lockTime == minLockTime
        uint256 ratio = (_lockingTime.sub(minTimeLock)).mul(padding).div(combinedDays);
        return minDevTreasuryPercentage.sub(ratio.mul(combinedFee).div(padding));
    }

    function getAmountLocked(address _user) external view returns(uint256) {
        return amountLocked[_user];
    }

    function extractTokensIfStuck(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function extractETHIfStruck() external onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }
}