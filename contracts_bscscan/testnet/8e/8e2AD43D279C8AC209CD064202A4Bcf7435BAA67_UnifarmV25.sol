// SPDX-License-Identifier:MIT;

pragma solidity ^0.7.6;

/**
 * @title Unifarm Contract
 * @author OroPocket
 */

import "./abstract/Admin.sol";

contract UnifarmV25 is Admin {
    // Wrappers over Solidity's arithmetic operations
    using SafeMath for uint256;

    // Stores Stake Details
    struct stakeInfo {
        address user;
        bool[] isActive;
        address[] referrer;
        address[] tokenAddress;
        uint256[] stakeId;
        uint256[] stakedAmount;
        uint256[] startTime;
    }

    // Mapping
    mapping(address => stakeInfo) public stakingDetails;
    mapping(address => mapping(address => uint256)) public userTotalStaking;
    mapping(address => uint256) public totalStaking;
    uint256 public poolStartTime;

    // Events
    event Stake(
        address indexed userAddress,
        uint256 stakeId,
        address indexed referrerAddress,
        address indexed tokenAddress,
        uint256 stakedAmount,
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

    constructor(address _trustedForwarder) Admin(_msgSender()) {
        poolStartTime = block.timestamp;
        trustedForwarder = _trustedForwarder;
    }

    /**
     * @notice Stake tokens to earn rewards
     * @param tokenAddress Staking token address
     * @param amount Amount of tokens to be staked
     */

    function stake(
        address referrerAddress,
        address tokenAddress,
        uint256 amount
    ) external whenNotPaused {
        // checks
        require(
            _msgSender() != referrerAddress,
            "STAKE: invalid referrer address"
        );
        require(
            tokenDetails[tokenAddress].isExist,
            "STAKE : Token is not Exist"
        );
        require(
            userTotalStaking[_msgSender()][tokenAddress].add(amount) >=
                tokenDetails[tokenAddress].userMinStake,
            "STAKE : Min Amount should be within permit"
        );
        require(
            userTotalStaking[_msgSender()][tokenAddress].add(amount) <=
                tokenDetails[tokenAddress].userMaxStake,
            "STAKE : Max Amount should be within permit"
        );
        require(
            totalStaking[tokenAddress].add(amount) <=
                tokenDetails[tokenAddress].totalMaxStake,
            "STAKE : Maxlimit exceeds"
        );

        require(
            poolStartTime.add(stakeDuration) > block.timestamp,
            "STAKE: Staking Time Completed"
        );

        // Storing stake details
        stakingDetails[_msgSender()].stakeId.push(
            stakingDetails[_msgSender()].stakeId.length
        );
        stakingDetails[_msgSender()].isActive.push(true);
        stakingDetails[_msgSender()].user = _msgSender();
        stakingDetails[_msgSender()].referrer.push(referrerAddress);
        stakingDetails[_msgSender()].tokenAddress.push(tokenAddress);
        stakingDetails[_msgSender()].startTime.push(block.timestamp);

        // Update total staking amount
        stakingDetails[_msgSender()].stakedAmount.push(amount);
        totalStaking[tokenAddress] = totalStaking[tokenAddress].add(amount);
        userTotalStaking[_msgSender()][tokenAddress] = userTotalStaking[
            _msgSender()
        ][tokenAddress].add(amount);

        // Transfer tokens from user to contract
        require(
            IERC20(tokenAddress).transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "Transfer Failed"
        );

        // Emit state changes
        emit Stake(
            _msgSender(),
            (stakingDetails[_msgSender()].stakeId.length.sub(1)),
            referrerAddress,
            tokenAddress,
            amount,
            block.timestamp
        );
    }

    /**
     * @notice Claim accumulated rewards
     * @param stakeId Stake ID of the user
     * @param stakedAmount Staked amount of the user
     */

    function claimRewards(
        address userAddress,
        uint256 stakeId,
        uint256 stakedAmount,
        uint256 totalStake
    ) internal {
        // Local variables
        uint256 interval;
        uint256 endOfProfit;

        interval = poolStartTime.add(stakeDuration);

        // Interval calculation
        if (interval > block.timestamp) endOfProfit = block.timestamp;
        else endOfProfit = poolStartTime.add(stakeDuration);

        interval = endOfProfit.sub(
            stakingDetails[userAddress].startTime[stakeId]
        );
        uint256[2] memory stakeData;
        stakeData[0] = (stakedAmount);
        stakeData[1] = (totalStake);

        // Reward calculation
        if (interval >= HOURS)
            _rewardCalculation(userAddress, stakeId, stakeData, interval);
    }

    function _rewardCalculation(
        address userAddress,
        uint256 stakeId,
        uint256[2] memory stakingData,
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
                stakingDetails[userAddress].tokenAddress[stakeId],
                stakingDetails[userAddress].tokenAddress[stakeId],
                stakingData[1]
            )
        );

        // Referrer Earning
        if (stakingDetails[userAddress].referrer[stakeId] != address(0)) {
            refEarned = (rewardsEarned.mul(refPercentage)).div(100 ether);
            rewardsEarned = rewardsEarned.sub(refEarned);

            require(
                IERC20(stakingDetails[userAddress].tokenAddress[stakeId])
                    .transfer(
                        stakingDetails[userAddress].referrer[stakeId],
                        refEarned
                    ) == true,
                "Transfer Failed"
            );

            emit ReferralEarn(
                stakingDetails[userAddress].referrer[stakeId],
                _msgSender(),
                stakingDetails[userAddress].tokenAddress[stakeId],
                refEarned,
                block.timestamp
            );
        }

        //  Rewards Send
        sendToken(
            userAddress,
            stakingDetails[userAddress].tokenAddress[stakeId],
            stakingDetails[userAddress].tokenAddress[stakeId],
            rewardsEarned
        );

        uint8 i = 1;

        while (i < intervalDays.length) {
            if (noOfDays[0] >= intervalDays[i]) {
                uint256 reductionHours = (intervalDays[i].sub(1)).mul(24);
                uint256 balHours = noOfDays[1].sub(reductionHours);

                address rewardToken = tokensSequenceList[
                    stakingDetails[userAddress].tokenAddress[stakeId]
                ][i];

                if (
                    rewardToken !=
                    stakingDetails[userAddress].tokenAddress[stakeId] &&
                    tokenBlockedStatus[
                        stakingDetails[userAddress].tokenAddress[stakeId]
                    ][rewardToken] ==
                    false
                ) {
                    rewardsEarned = balHours.mul(
                        getOneDayReward(
                            stakingData[0],
                            stakingDetails[userAddress].tokenAddress[stakeId],
                            rewardToken,
                            stakingData[1]
                        )
                    );

                    // Referrer Earning

                    if (
                        stakingDetails[userAddress].referrer[stakeId] !=
                        address(0)
                    ) {
                        refEarned = (rewardsEarned.mul(refPercentage)).div(
                            100 ether
                        );
                        rewardsEarned = rewardsEarned.sub(refEarned);

                        require(
                            IERC20(rewardToken).transfer(
                                stakingDetails[userAddress].referrer[stakeId],
                                refEarned
                            ) == true,
                            "Transfer Failed"
                        );

                        emit ReferralEarn(
                            stakingDetails[userAddress].referrer[stakeId],
                            _msgSender(),
                            stakingDetails[userAddress].tokenAddress[stakeId],
                            refEarned,
                            block.timestamp
                        );
                    }

                    //  Rewards Send
                    sendToken(
                        userAddress,
                        stakingDetails[userAddress].tokenAddress[stakeId],
                        rewardToken,
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
        uint256 lockBenefit;

        if (tokenDetails[stakedToken].optionableStatus) {
            stakedAmount = stakedAmount.mul(optionableBenefit);
            lockBenefit = stakedAmount.mul(optionableBenefit.sub(1));
            reward = (
                stakedAmount.mul(
                    tokenDailyDistribution[stakedToken][rewardToken]
                )
            ).div(totalStake.add(lockBenefit));
        } else {
            reward = (
                stakedAmount.mul(
                    tokenDailyDistribution[stakedToken][rewardToken]
                )
            ).div(totalStake);
        }
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
                rewardCap[tokenAddress] >= amount,
                "SEND : Insufficient Reward Balance"
            );
            // Transfer of rewards
            rewardCap[tokenAddress] = rewardCap[tokenAddress].sub(amount);

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

        address stakedToken = stakingDetails[userAddress].tokenAddress[stakeId];

        // lockableDays check
        require(
            tokenDetails[stakedToken].lockableDays <= block.timestamp,
            "UNSTAKE: Token Locked"
        );

        // optional lock check
        if (tokenDetails[stakedToken].optionableStatus)
            require(
                stakingDetails[userAddress].startTime[stakeId].add(
                    stakeDuration
                ) <= block.timestamp,
                "UNSTAKE: Locked in optional lock"
            );

        // Checks
        require(
            stakingDetails[userAddress].stakedAmount[stakeId] > 0 ||
                stakingDetails[userAddress].isActive[stakeId] == true,
            "UNSTAKE : Already Claimed (or) Insufficient Staked"
        );

        // State updation
        uint256 stakedAmount = stakingDetails[userAddress].stakedAmount[
            stakeId
        ];
        uint256 totalStaking1 = totalStaking[stakedToken];

        stakingDetails[userAddress].stakedAmount[stakeId] = 0;
        stakingDetails[userAddress].isActive[stakeId] = false;

        // Balance check
        require(
            IERC20(stakingDetails[userAddress].tokenAddress[stakeId]).balanceOf(
                address(this)
            ) >= stakedAmount,
            "UNSTAKE : Insufficient Balance"
        );

        // Transfer staked token back to user
        IERC20(stakingDetails[userAddress].tokenAddress[stakeId]).transfer(
            userAddress,
            stakedAmount
        );

        claimRewards(userAddress, stakeId, stakedAmount, totalStaking1);

        // Emit state changes
        emit UnStake(
            userAddress,
            stakingDetails[userAddress].tokenAddress[stakeId],
            stakedAmount,
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
        // Checks
        require(
            stakingDetails[userAddress].stakedAmount[stakeId] > 0 &&
                stakingDetails[userAddress].isActive[stakeId] == true,
            "EMERGENCY : Already Claimed (or) Insufficient Staked"
        );

        // Balance check
        require(
            IERC20(stakingDetails[userAddress].tokenAddress[stakeId]).balanceOf(
                address(this)
            ) >= stakingDetails[userAddress].stakedAmount[stakeId],
            "EMERGENCY : Insufficient Balance"
        );

        uint256 stakeAmount = stakingDetails[userAddress].stakedAmount[stakeId];
        stakingDetails[userAddress].isActive[stakeId] = false;
        stakingDetails[userAddress].stakedAmount[stakeId] = 0;

        IERC20(stakingDetails[userAddress].tokenAddress[stakeId]).transfer(
            userAddress,
            stakeAmount
        );

        for (uint256 i; i < rewardtokens.length; i++) {
            uint256 rewardsEarned = amount[i];

            if (stakingDetails[userAddress].referrer[stakeId] != address(0)) {
                uint256 refEarned = (rewardsEarned.mul(refPercentage)).div(
                    100 ether
                );
                rewardsEarned = rewardsEarned.sub(refEarned);

                require(
                    IERC20(rewardtokens[i]).transfer(
                        stakingDetails[userAddress].referrer[stakeId],
                        refEarned
                    ),
                    "EMERGENCY : Transfer Failed"
                );

                emit ReferralEarn(
                    stakingDetails[userAddress].referrer[stakeId],
                    userAddress,
                    rewardtokens[i],
                    refEarned,
                    block.timestamp
                );
            }

            sendToken(
                userAddress,
                stakingDetails[userAddress].tokenAddress[stakeId],
                rewardtokens[i],
                rewardsEarned
            );
        }

        // Emit state changes
        emit UnStake(
            userAddress,
            stakingDetails[userAddress].tokenAddress[stakeId],
            stakeAmount,
            block.timestamp,
            stakeId
        );
    }

    /**
     * @notice View staking details
     * @param _user User address
     */
    function viewStakingDetails(address _user)
        public
        view
        returns (
            address[] memory,
            address[] memory,
            bool[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            stakingDetails[_user].referrer,
            stakingDetails[_user].tokenAddress,
            stakingDetails[_user].isActive,
            stakingDetails[_user].stakeId,
            stakingDetails[_user].stakedAmount,
            stakingDetails[_user].startTime
        );
    }

    /**
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    function updateTrustForwarder(address _newTrustForwarder)
        external
        onlyOwner
    {
        trustedForwarder = _newTrustForwarder;
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

// SPDX-License-Identifier:MIT;

pragma solidity ^0.7.0;

import "./Ownable.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol";

abstract contract Admin is Ownable {
  struct tokenInfo {
    bool isExist;
    uint8 decimal;
    uint256 userMinStake;
    uint256 userMaxStake;
    uint256 totalMaxStake;
    uint256 lockableDays;
    bool optionableStatus;
  }

  using SafeMath for uint256;
  address[] public tokens;
  mapping(address => address[]) public tokensSequenceList;
  mapping(address => tokenInfo) public tokenDetails;
  mapping(address => uint256) public rewardCap;
  mapping(address => mapping(address => uint256)) public tokenDailyDistribution;
  mapping(address => mapping(address => bool)) public tokenBlockedStatus;
  uint256[] public intervalDays = [1, 8, 15, 22, 28];
  uint256 public constant DAYS = 1 days;
  uint256 public constant HOURS = 1 hours;
  uint256 public stakeDuration;
  uint256 public refPercentage;
  uint256 public optionableBenefit;

  event TokenDetails(
    address indexed tokenAddress,
    uint256 userMinStake,
    uint256 userMaxStake,
    uint256 totalMaxStake,
    uint256 updatedTime
  );

  event LockableTokenDetails(
    address indexed tokenAddress,
    uint256 lockableDys,
    bool optionalbleStatus,
    uint256 updatedTime
  );

  event DailyDistributionDetails(
    address indexed stakedTokenAddress,
    address indexed rewardTokenAddress,
    uint256 rewards,
    uint256 time
  );

  event SequenceDetails(
    address indexed stakedTokenAddress,
    address[] rewardTokenSequence,
    uint256 time
  );

  event StakeDurationDetails(uint256 updatedDuration, uint256 time);
  event OptionableBenefitDetails(uint256 updatedBenefit, uint256 time);
  event ReferrerPercentageDetails(uint256 updatedRefPercentage, uint256 time);
  event IntervalDaysDetails(uint256[] updatedIntervals, uint256 time);

  event BlockedDetails(
    address indexed stakedTokenAddress,
    address indexed rewardTokenAddress,
    bool blockedStatus,
    uint256 time
  );

  event WithdrawDetails(
    address indexed tokenAddress,
    uint256 withdrawalAmount,
    uint256 time
  );

  constructor(address _owner) Ownable(_owner) {
    stakeDuration = 180 days;
    refPercentage = 2500000000000000000;
    optionableBenefit = 2;
  }

  function addToken(
    address tokenAddress,
    uint256 userMinStake,
    uint256 userMaxStake,
    uint256 totalStake,
    uint8 decimal
  ) public onlyOwner returns (bool) {
    if (!(tokenDetails[tokenAddress].isExist)) tokens.push(tokenAddress);

    tokenDetails[tokenAddress].isExist = true;
    tokenDetails[tokenAddress].decimal = decimal;
    tokenDetails[tokenAddress].userMinStake = userMinStake;
    tokenDetails[tokenAddress].userMaxStake = userMaxStake;
    tokenDetails[tokenAddress].totalMaxStake = totalStake;

    emit TokenDetails(
      tokenAddress,
      userMinStake,
      userMaxStake,
      totalStake,
      block.timestamp
    );
    return true;
  }

  function setDailyDistribution(
    address[] memory stakedToken,
    address[] memory rewardToken,
    uint256[] memory dailyDistribution
  ) public onlyOwner {
    require(
      stakedToken.length == rewardToken.length &&
        rewardToken.length == dailyDistribution.length,
      "Invalid Input"
    );

    for (uint8 i = 0; i < stakedToken.length; i++) {
      require(
        tokenDetails[stakedToken[i]].isExist &&
          tokenDetails[rewardToken[i]].isExist,
        "Token not exist"
      );
      tokenDailyDistribution[stakedToken[i]][
        rewardToken[i]
      ] = dailyDistribution[i];

      emit DailyDistributionDetails(
        stakedToken[i],
        rewardToken[i],
        dailyDistribution[i],
        block.timestamp
      );
    }
  }

  function updateSequence(
    address stakedToken,
    address[] memory rewardTokenSequence
  ) public onlyOwner {
    tokensSequenceList[stakedToken] = new address[](0);
    require(tokenDetails[stakedToken].isExist, "Staked Token Not Exist");
    for (uint8 i = 0; i < rewardTokenSequence.length; i++) {
      require(rewardTokenSequence.length <= tokens.length, "Invalid Input");
      require(
        tokenDetails[rewardTokenSequence[i]].isExist,
        "Reward Token Not Exist"
      );
      tokensSequenceList[stakedToken].push(rewardTokenSequence[i]);
    }

    emit SequenceDetails(
      stakedToken,
      tokensSequenceList[stakedToken],
      block.timestamp
    );
  }

  function updateToken(
    address tokenAddress,
    uint256 userMinStake,
    uint256 userMaxStake,
    uint256 totalStake
  ) public onlyOwner {
    require(tokenDetails[tokenAddress].isExist, "Token Not Exist");
    tokenDetails[tokenAddress].userMinStake = userMinStake;
    tokenDetails[tokenAddress].userMaxStake = userMaxStake;
    tokenDetails[tokenAddress].totalMaxStake = totalStake;

    emit TokenDetails(
      tokenAddress,
      userMinStake,
      userMaxStake,
      totalStake,
      block.timestamp
    );
  }

  function lockableToken(
    address tokenAddress,
    uint8 lockableStatus,
    uint256 lockedDays,
    bool optionableStatus
  ) public onlyOwner {
    require(
      lockableStatus == 1 || lockableStatus == 2 || lockableStatus == 3,
      "Invalid Lockable Status"
    );
    require(tokenDetails[tokenAddress].isExist == true, "Token Not Exist");

    if (lockableStatus == 1) {
      tokenDetails[tokenAddress].lockableDays = block.timestamp.add(lockedDays);
    } else if (lockableStatus == 2) tokenDetails[tokenAddress].lockableDays = 0;
    else if (lockableStatus == 3)
      tokenDetails[tokenAddress].optionableStatus = optionableStatus;

    emit LockableTokenDetails(
      tokenAddress,
      tokenDetails[tokenAddress].lockableDays,
      tokenDetails[tokenAddress].optionableStatus,
      block.timestamp
    );
  }

  function updateStakeDuration(uint256 durationTime) public onlyOwner {
    stakeDuration = durationTime;

    emit StakeDurationDetails(stakeDuration, block.timestamp);
  }

  function updateOptionableBenefit(uint256 benefit) public onlyOwner {
    optionableBenefit = benefit;

    emit OptionableBenefitDetails(optionableBenefit, block.timestamp);
  }

  function updateRefPercentage(uint256 refPer) public onlyOwner {
    refPercentage = refPer;
    emit ReferrerPercentageDetails(refPercentage, block.timestamp);
  }

  function updateIntervalDays(uint256[] memory _interval) public onlyOwner {
    intervalDays = new uint256[](0);

    for (uint8 i = 0; i < _interval.length; i++) {
      uint256 noD = stakeDuration.div(DAYS);
      require(noD > _interval[i], "Invalid Interval Day");
      intervalDays.push(_interval[i]);
    }

    emit IntervalDaysDetails(intervalDays, block.timestamp);
  }

  function changeTokenBlockedStatus(
    address stakedToken,
    address rewardToken,
    bool status
  ) public onlyOwner {
    require(
      tokenDetails[stakedToken].isExist && tokenDetails[rewardToken].isExist,
      "Token not exist"
    );
    tokenBlockedStatus[stakedToken][rewardToken] = status;

    emit BlockedDetails(
      stakedToken,
      rewardToken,
      tokenBlockedStatus[stakedToken][rewardToken],
      block.timestamp
    );
  }

  function safeWithdraw(address tokenAddress, uint256 amount) public onlyOwner {
    require(
      IERC20(tokenAddress).balanceOf(address(this)) >= amount,
      "Insufficient Balance"
    );
    require(IERC20(tokenAddress).transfer(_owner, amount), "Transfer failed");
    emit WithdrawDetails(tokenAddress, amount, block.timestamp);
  }

  function viewTokensCount() external view returns (uint256) {
    return tokens.length;
  }

  function setRewardCap(
    address[] memory tokenAddresses,
    uint256[] memory rewards
  ) external onlyOwner returns (bool) {
    require(tokenAddresses.length == rewards.length, "Invalid elements");
    for (uint8 v = 0; v < tokenAddresses.length; v++) {
      require(tokenDetails[tokenAddresses[v]].isExist, "Token is not exist");
      require(rewards[v] > 0, "Invalid Reward Amount");
      rewardCap[tokenAddresses[v]] = rewards[v];
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT;

pragma solidity >=0.6.0 <=0.8.0;

import "./Pausable.sol";

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
        _owner = _msgSender();
        _admin = ownerAddress;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(_admin == _msgSender(), "Ownable: caller is not the Admin");
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier:MIT;

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier:MIT;

pragma solidity ^0.7.0;

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
    event Transfer(address indexed from, address indexed to, uint256 value);

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

// SPDX-License-Identifier: MIT;

pragma solidity >=0.6.0 <=0.8.0;

import "../forwarder/BaseRelayRecipient.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */

abstract contract Pausable is BaseRelayRecipient {
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

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(
            msg.sender == address(trustedForwarder),
            "Function can only be called through the trusted Forwarder"
        );
        _;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        override
        returns (bool)
    {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender()
        internal
        view
        virtual
        override
        returns (address payable ret)
    {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address payable);

    function versionRecipient() external view virtual returns (string memory);
}