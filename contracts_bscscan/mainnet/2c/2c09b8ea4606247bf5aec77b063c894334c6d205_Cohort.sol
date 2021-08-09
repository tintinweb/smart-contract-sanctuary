/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/access/Context.sol

// SPDX-License-Identifier: MIT;

pragma solidity ^0.7.6;

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
  function _msgSender()
    internal
    view
    virtual
    returns (address payable)
  {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File contracts/access/Pausable.sol

pragma solidity >=0.6.0 <=0.8.0;

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
  constructor() {
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

// File contracts/access/Ownable.sol

pragma solidity >=0.6.0 <=0.8.0;

abstract contract Ownable is Pausable {
  address public _owner;
  address public _admin;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor(address ownerAddress) {
    _owner = ownerAddress;
    _admin = ownerAddress;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(
      _owner == _msgSender(),
      "Ownable: caller is not the owner"
    );
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyAdmin() {
    require(
      _admin == _msgSender(),
      "Ownable: caller is not the Admin"
    );
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyAdmin {
    emit OwnershipTransferred(_owner, _admin);
    _owner = _admin;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner)
    public
    virtual
    onlyOwner
  {
    require(
      newOwner != address(0),
      "Ownable: new owner is the zero address"
    );
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File contracts/abstract/CohortStaking.sol

pragma solidity ^0.7.6;

abstract contract CohortStaking {
  struct tokenInfo {
    bool isExist;
    uint8 decimal;
    uint256 userMinStake;
    uint256 userMaxStake;
    uint256 totalMaxStake;
    uint256 lockableDays;
    bool optionableStatus;
  }

  mapping(address => tokenInfo) public tokenDetails;
  mapping(address => uint256) public totalStaking;
  mapping(address => address[]) public tokensSequenceList;

  mapping(address => mapping(address => uint256))
    public tokenDailyDistribution;

  mapping(address => mapping(address => bool))
    public tokenBlockedStatus;

  uint256 public refPercentage;
  uint256 public poolStartTime;
  uint256 public stakeDuration;

  function viewStakingDetails(address _user)
    public
    view
    virtual
    returns (
      address[] memory,
      address[] memory,
      bool[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    );

  function safeWithdraw(address tokenAddress, uint256 amount)
    public
    virtual;

  function transferOwnership(address newOwner) public virtual;
}

// File contracts/libraries/SafeMath.sol

pragma solidity ^0.7.6;

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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File contracts/interfaces/IERC20.sol

pragma solidity ^0.7.6;

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
  function transfer(address recipient, uint256 amount)
    external
    returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
  function approve(address spender, uint256 amount)
    external
    returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File contracts/interfaces/ICohort.sol

pragma solidity ^0.7.6;

interface ICohort {
  function setupCohort(uint256[] memory _intervalDays, bool _isSwapfy)
    external
    returns (bool);
}

// File contracts/Cohort.sol

pragma solidity ^0.7.6;

/**
 * @title Unifarm Cohort Unstake Handler Contract
 * @author Opendefi by OroPocket
 */

contract Cohort is Ownable, ICohort {
  /// @notice LockableToken struct for storing token lockable details
  struct LockableTokens {
    uint256 lockableDays;
    bool optionableStatus;
  }

  /// @notice Wrappers over Solidity's arithmetic operations
  using SafeMath for uint256;

  /// @notice totalStaking of a specfic tokenAddress.
  mapping(address => uint256) public totalUnStaking;

  /// @notice tokens old to new token swap
  mapping(address => address) public tokens;

  /// @notice unStakeStatus of a user.
  mapping(address => mapping(uint256 => bool)) public unStakeStatus;

  /// @notice tokenBlocked status.
  mapping(address => bool) public tokenBlockedStatus;

  /// @notice lockable token mapping
  mapping(address => LockableTokens) public lockableDetails;

  /// @notice cohort instance.
  CohortStaking public cohort;

  /// @notice DAYS is equal to 86400.
  uint256 public DAYS = 1 days;

  /// @notice HOURS is equal to 3600.
  uint256 public HOURS = 1 hours;

  /// @notice intervalDays
  uint256[] public intervalDays;

  /// @notice poolStartTime
  uint256 public poolStartTime;

  /// @notice stakeDuration
  uint256 public stakeDuration;

  /// @notice isSwapify
  bool public swapiFy;

  /// @notice factory
  address public factory;

  event LockableTokenDetails(
    address indexed tokenAddress,
    uint256 lockableDys,
    bool optionalbleStatus,
    uint256 updatedTime
  );

  event WithdrawDetails(
    address indexed tokenAddress,
    uint256 withdrawalAmount,
    uint256 time
  );

  event Claim(
    address indexed userAddress,
    address indexed stakedTokenAddress,
    address indexed tokenAddress,
    uint256 claimRewards,
    uint256 time
  );

  event UnStake(
    address indexed userAddress,
    address indexed unStakedtokenAddress,
    uint256 unStakedAmount,
    uint256 time,
    uint256 stakeId
  );

  event ReferralEarn(
    address indexed userAddress,
    address indexed callerAddress,
    address indexed rewardTokenAddress,
    uint256 rewardAmount,
    uint256 time
  );

  event IntervalDaysDetails(uint256[] updatedIntervals, uint256 time);

  /**
   * @notice construct the cohort unstake handler.
   * @param cohortAddress specfic cohortAddress.
   * @param ownerAddress owner Address of a cohort.
   */

  constructor(
    address cohortAddress,
    address ownerAddress,
    address factoryAddress
  ) Ownable(ownerAddress) {
    require(
      cohortAddress != address(0),
      "Cohort: invalid cohortAddress"
    );
    cohort = CohortStaking(cohortAddress);
    factory = factoryAddress;
  }

  function setupCohort(uint256[] memory _intervalDays, bool _isSwapfy)
    external
    override
    returns (bool)
  {
    require(_msgSender() == factory, "Cohort: permission denied");
    swapiFy = _isSwapfy;
    poolStartTime = cohort.poolStartTime();
    stakeDuration = cohort.stakeDuration();
    updateIntervalDays(_intervalDays);
    return true;
  }

  function setTokenBlockedStatus(address tokenAddress, bool status)
    external
    onlyOwner
    returns (bool)
  {
    tokenBlockedStatus[tokenAddress] = status;
    return true;
  }

  // make sure about ownership things before call this function.
  function init(address[] memory tokenAddress)
    external
    onlyOwner
    returns (bool)
  {
    for (uint256 i = 0; i < tokenAddress.length; i++) {
      transferFromCohort(tokenAddress[i]);
    }

    return true;
  }

  function transferFromCohort(address tokenAddress) internal {
    uint256 bal = IERC20(tokenAddress).balanceOf(address(cohort));
    if (bal > 0) cohort.safeWithdraw(tokenAddress, bal);
  }

  function updateCohort(address _newCohortAddress)
    external
    onlyOwner
    returns (bool)
  {
    cohort = CohortStaking(_newCohortAddress);
    return true;
  }

  function setSwapTokens(
    address[] memory oldTokenAddresses,
    address[] memory newTokenAddresses
  ) external onlyOwner returns (bool) {
    require(
      oldTokenAddresses.length == newTokenAddresses.length,
      "Invalid Input Tokens"
    );
    for (uint8 m = 0; m < oldTokenAddresses.length; m++) {
      tokens[oldTokenAddresses[m]] = newTokenAddresses[m];
    }
    return true;
  }

  function updateTotalUnStaking(
    address[] memory tokenAddresses,
    uint256[] memory overAllUnStakedTokens
  ) external onlyOwner returns (bool) {
    require(
      tokenAddresses.length == overAllUnStakedTokens.length,
      "Cohort: Invalid Inputs"
    );
    for (uint8 n = 0; n < tokenAddresses.length; n++) {
      require(
        tokenAddresses[n] != address(0),
        "Cohort: invalid poolAddress"
      );
      require(
        overAllUnStakedTokens[n] > 0,
        "Cohort: emptied overAllStaked"
      );
      totalUnStaking[tokenAddresses[n]] = overAllUnStakedTokens[n];
    }
    return true;
  }

  function updateIntervalDays(uint256[] memory _interval) public {
    require(
      _msgSender() == factory || _msgSender() == _owner,
      "Cohort: permission denied"
    );
    intervalDays = new uint256[](0);
    for (uint8 i = 0; i < _interval.length; i++) {
      uint256 noD = stakeDuration.div(DAYS);
      require(noD > _interval[i], "Invalid Interval Day");
      intervalDays.push(_interval[i]);
    }

    emit IntervalDaysDetails(intervalDays, block.timestamp);
  }

  function lockableToken(
    address tokenAddress,
    uint8 lockableStatus,
    uint256 lockedDays,
    bool optionableStatus
  ) external onlyOwner {
    require(
      lockableStatus == 1 ||
        lockableStatus == 2 ||
        lockableStatus == 3,
      "Invalid Lockable Status"
    );

    (bool tokenExist, , , , , , ) = cohort.tokenDetails(tokenAddress);

    require(tokenExist == true, "Token Not Exist");

    if (lockableStatus == 1) {
      lockableDetails[tokenAddress].lockableDays = block
        .timestamp
        .add(lockedDays);
    } else if (lockableStatus == 2)
      lockableDetails[tokenAddress].lockableDays = 0;
    else if (lockableStatus == 3)
      lockableDetails[tokenAddress]
        .optionableStatus = optionableStatus;

    emit LockableTokenDetails(
      tokenAddress,
      lockableDetails[tokenAddress].lockableDays,
      lockableDetails[tokenAddress].optionableStatus,
      block.timestamp
    );
  }

  function reclaimOwnership(address newOwner)
    external
    onlyOwner
    returns (bool)
  {
    cohort.transferOwnership(newOwner);
    return true;
  }

  function safeWithdraw(address tokenAddress, uint256 amount)
    external
    onlyOwner
  {
    require(
      IERC20(tokenAddress).balanceOf(address(this)) >= amount,
      "SAFEWITHDRAW: Insufficient Balance"
    );

    require(
      IERC20(tokenAddress).transfer(_owner, amount) == true,
      "SAFEWITHDRAW: Transfer failed"
    );

    emit WithdrawDetails(tokenAddress, amount, block.timestamp);
  }

  function getTokenAddress(address tokenAddress)
    internal
    view
    returns (address)
  {
    if (swapiFy) {
      address newAddress = tokens[tokenAddress] == address(0)
        ? tokenAddress
        : tokens[tokenAddress];
      return (newAddress);
    } else {
      return (tokenAddress);
    }
  }

  /**
   * @notice Claim accumulated rewards
   * @param userAddress user Address through he staked.
   * @param stakeId Stake ID of the user
   * @param totalStake total Staking.
   */

  function claimRewards(
    address userAddress,
    uint256 stakeId,
    uint256 totalStake
  ) internal {
    // Local variables
    uint256 interval;
    uint256 endOfProfit;

    (
      address[] memory referrar,
      address[] memory tokenAddresses,
      ,
      ,
      uint256[] memory stakedAmount,
      uint256[] memory startTime
    ) = cohort.viewStakingDetails(userAddress);

    interval = poolStartTime.add(stakeDuration);
    // Interval calculation
    if (interval > block.timestamp) endOfProfit = block.timestamp;
    else endOfProfit = poolStartTime.add(stakeDuration);

    interval = endOfProfit.sub(startTime[stakeId]);

    uint256 refPercentage = cohort.refPercentage();
    uint256[3] memory stakeData;

    stakeData[0] = (stakedAmount[stakeId]);
    stakeData[1] = (totalStake);
    stakeData[2] = (refPercentage);

    // Reward calculation
    if (interval >= HOURS)
      _rewardCalculation(
        userAddress,
        tokenAddresses[stakeId],
        referrar[stakeId],
        stakeData,
        interval
      );
  }

  function _rewardCalculation(
    address userAddress,
    address tokenAddress,
    address referrer,
    uint256[3] memory stakingData,
    uint256 interval
  ) internal {
    uint256 rewardsEarned;
    uint256 refEarned;
    uint256[2] memory noOfDays;

    noOfDays[1] = interval.div(HOURS);
    noOfDays[0] = interval.div(DAYS);

    rewardsEarned = noOfDays[1].mul(
      getOneDayReward(
        stakingData[0],
        tokenAddress,
        tokenAddress,
        stakingData[1]
      )
    );

    address stakedToken = getTokenAddress(tokenAddress);

    // Referrer Earning
    if (referrer != address(0)) {
      refEarned = (rewardsEarned.mul(stakingData[2])).div(100 ether);
      rewardsEarned = rewardsEarned.sub(refEarned);

      require(
        IERC20(stakedToken).transfer(referrer, refEarned) == true,
        "Transfer Failed"
      );

      emit ReferralEarn(
        referrer,
        _msgSender(),
        stakedToken,
        refEarned,
        block.timestamp
      );
    }
    //  Rewards Send
    sendToken(userAddress, stakedToken, stakedToken, rewardsEarned);

    uint8 i = 1;

    while (i < intervalDays.length) {
      if (noOfDays[0] >= intervalDays[i]) {
        uint256 reductionHours = (intervalDays[i].sub(1)).mul(24);
        uint256 balHours = noOfDays[1].sub(reductionHours);
        address rewardToken = cohort.tokensSequenceList(
          tokenAddress,
          i
        );

        if (
          rewardToken != tokenAddress &&
          cohort.tokenBlockedStatus(tokenAddress, rewardToken) ==
          false
        ) {
          rewardsEarned = balHours.mul(
            getOneDayReward(
              stakingData[0],
              tokenAddress,
              rewardToken,
              stakingData[1]
            )
          );

          address rewardToken1 = getTokenAddress(rewardToken);
          // Referrer Earning

          if (referrer != address(0)) {
            refEarned = (rewardsEarned.mul(stakingData[2])).div(
              100 ether
            );
            rewardsEarned = rewardsEarned.sub(refEarned);

            require(
              IERC20(rewardToken1).transfer(referrer, refEarned) ==
                true,
              "Transfer Failed"
            );

            emit ReferralEarn(
              referrer,
              _msgSender(),
              rewardToken1,
              refEarned,
              block.timestamp
            );
          }
          //  Rewards Send
          sendToken(
            userAddress,
            tokenAddress,
            rewardToken1,
            rewardsEarned
          );
        }
        i = i + 1;
      } else {
        break;
      }
    }
  }

  /**
   * @notice Get rewards for one day
   * @param stakedAmount Stake amount of the user
   * @param stakedToken Staked token address of the user
   * @param rewardToken Reward token address
   * @return reward One dayh reward for the user
   */

  function getOneDayReward(
    uint256 stakedAmount,
    address stakedToken,
    address rewardToken,
    uint256 totalStake
  ) public view returns (uint256 reward) {
    reward = (
      stakedAmount.mul(
        cohort.tokenDailyDistribution(stakedToken, rewardToken)
      )
    ).div(totalStake);
  }

  /**
   * @notice Get rewards for one day
   * @param stakedToken Stake amount of the user
   * @param tokenAddress Reward token address
   * @param amount Amount to be transferred as reward
   */

  function sendToken(
    address userAddress,
    address stakedToken,
    address tokenAddress,
    uint256 amount
  ) internal {
    // Checks
    if (tokenAddress != address(0)) {
      require(
        IERC20(tokenAddress).balanceOf(address(this)) >= amount,
        "SEND : Insufficient Reward Balance"
      );

      require(
        IERC20(tokenAddress).transfer(userAddress, amount),
        "Transfer failed"
      );

      // Emit state changes
      emit Claim(
        userAddress,
        stakedToken,
        tokenAddress,
        amount,
        block.timestamp
      );
    }
  }

  function getTotalStaking(address tokenAddress)
    public
    view
    returns (uint256)
  {
    uint256 totalStaking = cohort.totalStaking(tokenAddress);
    uint256 actualStaking = totalStaking.add(
      totalUnStaking[tokenAddress]
    );
    return actualStaking;
  }

  /**
   * @notice Unstake and claim rewards
   * @param stakeId Stake ID of the user
   */
  function unStake(address userAddress, uint256 stakeId)
    external
    whenNotPaused
    returns (bool)
  {
    require(
      _msgSender() == userAddress || _msgSender() == _owner,
      "UNSTAKE: Invalid User Entry"
    );

    // view the staking details
    (
      ,
      address[] memory tokenAddress,
      bool[] memory isActive,
      ,
      uint256[] memory stakedAmount,
      uint256[] memory startTime
    ) = cohort.viewStakingDetails(userAddress);

    uint256 totalStaking = getTotalStaking(tokenAddress[stakeId]);
    address stakedToken = getTokenAddress(tokenAddress[stakeId]);

    // lockableDays check
    require(
      lockableDetails[stakedToken].lockableDays <= block.timestamp,
      "UNSTAKE: Token Locked"
    );

    // optional lock check
    if (lockableDetails[stakedToken].optionableStatus == true)
      require(
        startTime[stakeId].add(stakeDuration) <= block.timestamp,
        "UNSTAKE: Locked in optional lock"
      );

    // Checks
    require(
      stakedAmount[stakeId] > 0 &&
        isActive[stakeId] == true &&
        unStakeStatus[userAddress][stakeId] == false,
      "UNSTAKE : Already Claimed (or) Insufficient Staked"
    );

    // update the state
    unStakeStatus[userAddress][stakeId] = true;

    // Balance check
    require(
      IERC20(stakedToken).balanceOf(address(this)) >=
        stakedAmount[stakeId],
      "UNSTAKE : Insufficient Balance"
    );

    // Transfer staked token back to user
    if (tokenBlockedStatus[tokenAddress[stakeId]] == false) {
      IERC20(stakedToken).transfer(
        userAddress,
        stakedAmount[stakeId]
      );
    }

    claimRewards(userAddress, stakeId, totalStaking);
    // Emit state changes
    emit UnStake(
      userAddress,
      stakedToken,
      stakedAmount[stakeId],
      block.timestamp,
      stakeId
    );

    return true;
  }

  function emergencyUnstake(
    uint256 stakeId,
    address userAddress,
    address[] memory rewardtokens,
    uint256[] memory amount
  ) external onlyOwner {
    // view the staking details
    (
      address[] memory referrer,
      address[] memory tokenAddress,
      bool[] memory isActive,
      ,
      uint256[] memory stakedAmount,

    ) = cohort.viewStakingDetails(userAddress);

    require(
      stakedAmount[stakeId] > 0 &&
        isActive[stakeId] == true &&
        unStakeStatus[userAddress][stakeId] == false,
      "EMERGENCY : Already Claimed (or) Insufficient Staked"
    );

    address stakedToken = getTokenAddress(tokenAddress[stakeId]);
    // Balance check
    require(
      IERC20(stakedToken).balanceOf(address(this)) >=
        stakedAmount[stakeId],
      "EMERGENCY : Insufficient Balance"
    );

    unStakeStatus[userAddress][stakeId] = true;

    IERC20(stakedToken).transfer(userAddress, stakedAmount[stakeId]);

    uint256 refPercentage = cohort.refPercentage();

    for (uint256 i; i < rewardtokens.length; i++) {
      uint256 rewardsEarned = amount[i];

      if (referrer[stakeId] != address(0)) {
        uint256 refEarned = (rewardsEarned.mul(refPercentage)).div(
          100 ether
        );
        rewardsEarned = rewardsEarned.sub(refEarned);

        require(
          IERC20(rewardtokens[i]).transfer(
            referrer[stakeId],
            refEarned
          ),
          "EMERGENCY : Transfer Failed"
        );

        emit ReferralEarn(
          referrer[stakeId],
          userAddress,
          rewardtokens[i],
          refEarned,
          block.timestamp
        );
      }

      sendToken(
        userAddress,
        tokenAddress[stakeId],
        rewardtokens[i],
        rewardsEarned
      );
    }

    // Emit state changes
    emit UnStake(
      userAddress,
      tokenAddress[stakeId],
      stakedAmount[stakeId],
      block.timestamp,
      stakeId
    );
  }

  function pause() external onlyOwner returns (bool) {
    _pause();
    return true;
  }

  function unpause() external onlyOwner returns (bool) {
    _unpause();
    return true;
  }
}