// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IProjectICO.sol";
import "./utils/EmergencyWithdraw.sol";
import "./utils/DSMath.sol";

contract KingPadStakingV3 is OwnableUpgradeable, ReentrancyGuardUpgradeable, EmergencyWithdraw, DSMath {
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  struct UserInfo {
    address addr; // Address of user
    uint256 amount; // How many staked tokens the user has provided
    uint256 lastRewardTime; // Last reward time
    uint256 depositTime; // Last deposit time
    uint256 lockDuration; // Lock duration in seconds
    bool registered; // It will add user in address list on first deposit
  }

  struct UserLog {
    address addr; // Address of user
    uint256 amount1; // Raw amount of token
    uint256 amount2; // Amount after tax of token in Deposit case.
    uint256 amount3; // Pending reward
    bool isDeposit; // Deposit or withdraw
    uint256 logTime; // Log timestamp
  }

  // Percentage nominator: 1% = 100
  uint256 private constant _RATE_NOMINATOR = 10_000;
  // Total second in a year
  uint256 public constant SECONDS_YEAR = 365 days;

  // The reward token
  IERC20MetadataUpgradeable public rewardToken;
  // The staked token
  IERC20MetadataUpgradeable public stakedToken;

  // Info of each user that stakes tokens (stakedToken)
  mapping(address => UserInfo) public userInfo;
  // User list
  address[] public userList;
  // User logs
  UserLog[] private _userLogs;

  // Max reward tokens per pool
  uint256 public maxRewardPerPool;
  // Claimed reward tokens per pool
  uint256 public claimedRewardPerPool;
  // Max staked tokens per pool
  uint256 public maxStakedPerPool;
  // Whether a limit is set for users
  bool public hasUserLimit;
  // Max staked tokens per user (0 if none)
  uint256 public maxStakedPerUser;
  // Fixed APY, default is 100%
  uint256 public fixedAPY;
  // Pool mode: AUTO COMPOUND as default
  bool public isAutoCompound;

  // Current staked tokens per pool
  uint256 public currentStakedPerPool;
  // The Pool start time.
  uint256 public startTime;
  // The Pool end time.
  uint256 public endTime;
  // Freeze start time
  uint256 public freezeStartTime;
  // Freeze end time
  uint256 public freezeEndTime;
  // Minimum deposit amount
  uint256 public minDepositAmount;
  // Time for withdraw. Allow user can withdraw if block.timestamp >= withdrawTime
  uint256 public withdrawTime;
  // Withdraw mode
  // 0: Apply withdrawTime to both (stake + reward)
  // 1: Apply withdrawTime to stake
  // 2: Apply withdrawTime to reward
  uint256 public withdrawMode;
  // Global lock to user mode
  bool public enableLockToUser;
  // Global lock duration
  uint256 public lockDuration;

  // Count tier tickets
  // Config for tier sorted by min_stake DESC: [min_stake1,pool_weight1, ..., min_stake_i,pool_weight_i]
  uint256[] public tierConfigs;
  // Ticket per users: userTickets[address] = [tier1, tier2, tier3]
  mapping(address => uint256[]) public userTickets;
  // Total ticket per tier: [tier1, ..., tier_i]
  uint256[] public totalTickets;
  // ICO project
  address public icoProject;

  // Operator
  mapping(address => bool) public isOperator;

  event UserDeposit(address indexed user, uint256 amount);
  event UserWithdraw(address indexed user, uint256 amount);
  event NewStartAndEndTimes(uint256 startTime, uint256 endTime);
  event NewFreezeTimes(uint256 freezeStartTime, uint256 freezeEndTime);

  /**
   * @dev Upgradable initializer
   */
  function __KingPadStakingV3_init(
    IERC20MetadataUpgradeable _stakedToken,
    IERC20MetadataUpgradeable _rewardToken,
    uint256 _maxStakedPerPool,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _maxStakedPerUser,
    uint256 _minDepositAmount,
    uint256 _withdrawTime,
    uint256 _withdrawMode,
    uint256 _fixedAPY,
    bool _isAutoCompound,
    address _admin
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();

    stakedToken = _stakedToken;
    rewardToken = _rewardToken;
    maxStakedPerPool = _maxStakedPerPool;

    // 100% = 10000 = _RATE_NOMINATOR
    fixedAPY = _fixedAPY;
    isAutoCompound = _isAutoCompound;
    startTime = _startTime;
    endTime = _endTime;
    minDepositAmount = _minDepositAmount;
    withdrawTime = _withdrawTime;
    withdrawMode = _withdrawMode;

    if (_maxStakedPerUser > 0) {
      hasUserLimit = true;
      maxStakedPerUser = _maxStakedPerUser;
    }

    if (_admin != _msgSender()) {
      // Transfer ownership to the admin address who becomes owner of the contract
      transferOwnership(_admin);
    }
    enableLockToUser = true;
  }

  /*
   * @notice Update tier config
   * Without decimals
   * Sorted by min_stake DESC: [min_stake1,pool_weight1, ..., min_stake_i,pool_weight_i]
   */
  function setTierConfigs(uint256[] memory _tierConfigs) external onlyOwner {
    require(_tierConfigs.length % 2 == 0, "Length must be even number");
    if (tierConfigs.length != _tierConfigs.length) {
      tierConfigs = new uint256[](_tierConfigs.length);
      totalTickets = new uint256[](_tierConfigs.length / 2);
    }
    for (uint256 i = 0; i < _tierConfigs.length; i++) {
      tierConfigs[i] = _tierConfigs[i];
    }
  }

  /*
   * @notice Get tiers length
   */
  function getTotalTicketsLength() external view returns (uint256) {
    return totalTickets.length;
  }

  /*
   * @notice Update total tickets value
   * [tier1, tier2, tier3]
   */
  function setTotalTickets(uint256[] memory _totalTickets) external onlyOwner {
    if (totalTickets.length == _totalTickets.length && _totalTickets.length > 0) {
      for (uint256 i = 0; i < _totalTickets.length; i++) {
        totalTickets[i] = _totalTickets[i];
      }
    }
  }

  /*
   * @notice Update user tickets value
   * [tier1, tier2, tier3]
   */
  function setUserTickets(address _user, uint256[] memory _tickets) external onlyOwner {
    if (totalTickets.length == _tickets.length && _tickets.length > 0) {
      if (userTickets[_user].length == 0) userTickets[_user] = new uint256[](totalTickets.length);
      for (uint256 i = 0; i < _tickets.length; i++) {
        userTickets[_user][i] = _tickets[i];
      }
    }
  }

  /**
   * @dev Calculate tickets by amount and levels.
   * @notice Input without decimals
   */
  function getICOTickets(address _user) public view returns (uint256[] memory _tickets) {
    uint256[] memory rs_ = new uint256[](totalTickets.length);
    uint256 remain_ = userInfo[_user].amount / 10**stakedToken.decimals();
    for (uint256 i = 0; i < rs_.length; i++) {
      if (tierConfigs[i * 2] > 0) {
        rs_[i] = remain_ / tierConfigs[i * 2];
        remain_ %= tierConfigs[i * 2];
      }
    }
    return rs_;
  }

  /**
   * @dev Estimate amount per ticket
   * @notice Input without decimals and Output mul 1e18 as default
   */
  function estICOAmounts(address _user, uint256 _tokenForSale) external view returns (uint256 _amount) {
    uint256 rs_ = 0;
    uint256 totalWeights_ = 0;
    for (uint256 i = 0; i < totalTickets.length; i++) {
      // PoolWeightPerTier = totalTicketPerTier * weightPerTier
      totalWeights_ += tierConfigs[i * 2 + 1] * totalTickets[i];
    }
    if (totalWeights_ > 0) {
      for (uint256 i = 0; i < totalTickets.length; i++) {
        rs_ += (userTickets[_user][i] * (tierConfigs[i * 2 + 1] * _tokenForSale * 1e18)) / totalWeights_;
      }
    }
    return rs_;
  }

  /**
   * @dev Function to add a account to blacklist
   */
  function fSetOperator(address _pAccount, bool _pStatus) external onlyOwner {
    require(isOperator[_pAccount] != _pStatus, "Added");
    isOperator[_pAccount] = _pStatus;
  }

  /*
   * @notice Update ico project address
   * Set to address(0) to empty project
   */
  function setIcoProject(address _icoProject) external {
    require(_msgSender() == owner() || isOperator[_msgSender()], "Operator role");
    icoProject = _icoProject;
  }

  /*
   * @notice Compound mode is only enabled when stake token = reward token and isAutoCompound is true
   */
  function canCompound() public view returns (bool) {
    return address(stakedToken) == address(rewardToken) && isAutoCompound;
  }

  /*
   * @notice Update compound mode
   */
  function setCompound(bool _mode) external onlyOwner {
    isAutoCompound = _mode;
  }

  /*
   * @notice Get remaining reward
   */
  function getRemainingReward() public view returns (uint256) {
    if (maxRewardPerPool > claimedRewardPerPool) return maxRewardPerPool - claimedRewardPerPool;
    return 0;
  }

  /*
   * @notice View function to see pending reward on frontend.
   * @param _user: user address
   * @return Pending reward for a given user
   */
  function getPendingReward(address _user) public view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    uint userReward;
    if (block.timestamp > user.lastRewardTime && currentStakedPerPool != 0) {
      uint256 multiplier = _getMultiplier(user.lastRewardTime, block.timestamp);
      if (multiplier == 0) return 0;
      if (canCompound()) {
        // APY = 100% = 1
        // SecondsPerYear = 365 * 24 * 60 * 60 = 31536000  (365 days)
        // Duration = n
        // InitialAmount = P
        // FinalAmount = P * ( 1 + APY/SecondsPerYear )^n
        // Compounded interest = FinalAmount - P;
        uint rate = rpow(WAD + (fixedAPY * WAD) / SECONDS_YEAR / _RATE_NOMINATOR, multiplier, WAD);
        userReward = wmul(user.amount, rate - WAD);
      } else {
        // FinalAmount = P * APY/SecondsPerYear * n
        // Compounded interest = FinalAmount - P;
        userReward = (user.amount * fixedAPY * multiplier) / SECONDS_YEAR / _RATE_NOMINATOR;
      }
    }
    return userReward;
  }

  /*
   * @notice Deposit staked tokens and collect reward tokens (if any)
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function deposit(uint256 _amount) external nonReentrant {
    require(isFrozen() == false, "Deposit is frozen");
    if (maxStakedPerPool > 0) {
      require((currentStakedPerPool + _amount) <= maxStakedPerPool, "Exceed max staked tokens");
    }

    UserInfo storage user = userInfo[msg.sender];
    require((user.amount + _amount) >= minDepositAmount, "User amount below minimum");

    if (hasUserLimit) {
      require((_amount + user.amount) <= maxStakedPerUser, "User amount above limit");
    }

    user.depositTime = block.timestamp;

    uint256 pending;
    if (user.amount > 0) {
      pending = getPendingReward(msg.sender);
      if (pending > 0) {
        // If pool mode is non-compound -> transfer rewards to user
        // Otherwise, compound to user amount
        if (canCompound()) {
          user.amount += pending;
          currentStakedPerPool += pending;
          claimedRewardPerPool += pending;
        } else {
          _safeRewardTransfer(address(msg.sender), pending);
        }
        user.lastRewardTime = block.timestamp;
      }
    } else {
      if (user.registered == false) {
        userList.push(msg.sender);
        user.registered = true;
        user.addr = address(msg.sender);
        user.lastRewardTime = block.timestamp;
        // We're not apply lock per user this time
        user.lockDuration = 0;
      }
    }

    uint256 addedAmount_;
    if (_amount > 0) {
      // Check real amount to avoid taxed token
      uint256 previousBalance_ = stakedToken.balanceOf(address(this));
      stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
      uint256 newBalance_ = stakedToken.balanceOf(address(this));
      addedAmount_ = newBalance_ - previousBalance_;

      user.amount += addedAmount_;
      currentStakedPerPool += addedAmount_;
    }
    _addUserLog(msg.sender, _amount, addedAmount_, pending, true);

    // Update tier ticket
    _updateUserTickets();

    emit UserDeposit(msg.sender, _amount);
  }

  /*
   * @notice Withdraw staked tokens and collect reward tokens
   * @param _amount: amount to withdraw (in rewardToken)
   */
  function withdraw(uint256 _amount) external nonReentrant {
    require(isFrozen() == false, "Withdraw is frozen");
    bool isClaim = _amount == 0;

    UserInfo storage user = userInfo[msg.sender];
    if (withdrawMode == 0 || (withdrawMode == 1 && !isClaim) || (withdrawMode == 2 && isClaim)) {
      require(block.timestamp >= withdrawTime, "Withdraw not available");
      if (enableLockToUser) {
        require(block.timestamp >= user.depositTime + lockDuration, "Global lock");
      }
    }

    // Claim reward
    uint256 pending = getPendingReward(msg.sender);
    if (pending > 0) {
      // If pool mode is non-compound -> transfer rewards to user
      // Otherwise, compound to user amount
      if (canCompound()) {
        user.amount += pending;
        currentStakedPerPool += pending;
        claimedRewardPerPool += pending;
      } else {
        _safeRewardTransfer(address(msg.sender), pending);
      }
      user.lastRewardTime = block.timestamp;
    }

    // Unstake
    if (_amount > 0) {
      require(block.timestamp >= user.depositTime + user.lockDuration, "Locked");

      if (_amount > user.amount) {
        // Exit pool, withdraw all
        _amount = user.amount;
      }
      user.amount -= _amount;
      currentStakedPerPool -= _amount;
      stakedToken.safeTransfer(address(msg.sender), _amount);
    }

    _addUserLog(msg.sender, _amount, 0, pending, false);

    // Update tier ticket
    _updateUserTickets();

    emit UserWithdraw(msg.sender, _amount);
  }

  /*
   * @notice Update user ticket
   */
  function _updateUserTickets() private {
    if (totalTickets.length > 0) {
      if (userTickets[msg.sender].length == 0) {
        userTickets[msg.sender] = new uint256[](totalTickets.length);
      }
      uint256[] memory newTickets_ = getICOTickets(msg.sender);
      for (uint256 i = 0; i < totalTickets.length; i++) {
        totalTickets[i] += newTickets_[i];
        totalTickets[i] -= userTickets[msg.sender][i];
        userTickets[msg.sender][i] = newTickets_[i];
      }
    }
  }

  /*
   * @notice Add user log
   */
  function _addUserLog(
    address _addr,
    uint256 _amount1,
    uint256 _amount2,
    uint256 _amount3,
    bool _isDeposit
  ) private {
    _userLogs.push(UserLog(_addr, _amount1, _amount2, _amount3, _isDeposit, block.timestamp));
  }

  /*
   * @notice Return length of user logs
   */
  function getUserLogLength() external view returns (uint) {
    return _userLogs.length;
  }

  /*
   * @notice View function to get user logs.
   * @param _offset: offset for paging
   * @param _limit: limit for paging
   * @return get users, next offset and total users
   */
  function getUserLogsPaging(uint _offset, uint _limit)
    external
    view
    returns (
      UserLog[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = _userLogs.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    UserLog[] memory values = new UserLog[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = _userLogs[_offset + i];
    }

    return (values, _offset + _limit, totalUsers);
  }

  /*
   * @notice return length of user addresses
   */
  function getUserListLength() external view returns (uint) {
    return userList.length;
  }

  /*
   * @notice View function to get users.
   * @param _offset: offset for paging
   * @param _limit: limit for paging
   * @return get users, next offset and total users
   */
  function getUsersPaging(uint _offset, uint _limit)
    external
    view
    returns (
      UserInfo[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = userList.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    UserInfo[] memory values = new UserInfo[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = userInfo[userList[_offset + i]];
    }

    return (values, _offset + _limit, totalUsers);
  }

  /*
   * @notice isFrozed returns if contract is frozen, user cannot call deposit, withdraw, emergencyWithdraw function
   * If this pool link with another ico project, the pool will be frozen when it's raising
   */
  function isFrozen() public view returns (bool) {
    if (icoProject != address(0) && IProjectICO(icoProject).isICORaising()) {
      return true;
    }
    return block.timestamp >= freezeStartTime && block.timestamp <= freezeEndTime;
  }

  /*
   * @notice Reset user state
   * @dev Needs to be for emergency.
   */
  function resetUserState(
    address _userAddress,
    uint256 _amount,
    uint256 _lastRewardTime,
    uint256 _depositTime,
    uint256 _lockDuration,
    bool _registered
  ) external onlyOwner {
    UserInfo storage user = userInfo[msg.sender];
    user.addr = _userAddress;
    user.amount = _amount;
    user.lastRewardTime = _lastRewardTime;
    user.depositTime = _depositTime;
    user.lockDuration = _lockDuration;
    user.registered = _registered;
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner. Needs to be for emergency.
   */
  function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
    maxRewardPerPool -= _amount;
    rewardToken.safeTransfer(address(msg.sender), _amount);
  }

  /*
   * @dev Update lock to user mode
   */
  function setEnableLockToUser(bool _enable) external onlyOwner {
    enableLockToUser = _enable;
  }

  /*
   * @dev Update lock duration
   */
  function setLockDuration(uint256 _duration) external onlyOwner {
    lockDuration = _duration;
  }

  /*
   * @dev Reset user deposit time
   */
  function resetUserDepositTime(address _user, uint256 _time) external onlyOwner {
    userInfo[_user].depositTime = _time;
  }

  /**
   * @notice It allows the admin to reward tokens
   * @param _amount: amount of tokens
   * @dev This function is only callable by admin.
   */
  function addRewardTokens(uint256 _amount) external onlyOwner {
    // Check real amount to avoid taxed token
    uint256 previousBalance_ = rewardToken.balanceOf(address(this));
    rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    uint256 newBalance_ = rewardToken.balanceOf(address(this));
    uint256 addedAmount_ = newBalance_ - previousBalance_;

    maxRewardPerPool += addedAmount_;
  }

  /*
   * @notice Stop rewards
   * @dev Only callable by owner
   */
  function stopReward() external onlyOwner {
    endTime = block.timestamp;
  }

  /*
   * @notice Stop Freeze
   * @dev Only callable by owner
   */
  function stopFreeze() external onlyOwner {
    freezeStartTime = 0;
    freezeEndTime = 0;
  }

  /*
   * @notice Update pool limit per user
   * @dev Only callable by owner.
   * @param _hasUserLimit: whether the limit remains forced
   * @param _maxStakedPerUser: new pool limit per user
   */
  function updateMaxStakedPerUser(bool _hasUserLimit, uint256 _maxStakedPerUser) external onlyOwner {
    require(hasUserLimit, "Must be set");
    if (_hasUserLimit) {
      require(_maxStakedPerUser > maxStakedPerUser, "New limit must be higher");
      maxStakedPerUser = _maxStakedPerUser;
    } else {
      hasUserLimit = _hasUserLimit;
      maxStakedPerUser = 0;
    }
  }

  /*
   * @notice Update reward per block
   * @dev Only callable by owner.
   * @param _maxStakedPerPool: Max tokens can be staked to this pool
   */
  function updateMaxStakedPerPool(uint256 _maxStakedPerPool) external onlyOwner {
    maxStakedPerPool = _maxStakedPerPool;
  }

  /**
   * @notice It allows the admin to update start and end times
   * @dev This function is only callable by owner.
   * @param _startTime: the new start time
   * @param _endTime: the new end time
   */
  function updateStartAndEndTimes(uint256 _startTime, uint256 _endTime) external onlyOwner {
    require(block.timestamp > endTime, "Pool has started");
    require(_startTime < _endTime, "Invalid start and end time");
    endTime = _endTime;

    if (_startTime > block.timestamp) {
      startTime = _startTime;
    }
    emit NewStartAndEndTimes(_startTime, _endTime);
  }

  /**
   * @notice It allows the admin to update freeze start and end times
   * @dev This function is only callable by owner.
   * @param _freezeStartTime: the new freeze start time
   * @param _freezeEndTime: the new freeze end time
   */
  function updateFreezeTimes(uint256 _freezeStartTime, uint256 _freezeEndTime) external onlyOwner {
    require(_freezeStartTime < _freezeEndTime, "Invalid start and end time");
    require(block.timestamp < _freezeStartTime, "Invalid start and current");

    freezeStartTime = _freezeStartTime;
    freezeEndTime = _freezeEndTime;
    emit NewFreezeTimes(freezeStartTime, freezeEndTime);
  }

  /**
   * @notice Update minimum deposit amount
   * @dev This function is only callable by owner.
   * @param _minDepositAmount: the new minimum deposit amount
   */
  function updateMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
    minDepositAmount = _minDepositAmount;
  }

  /**
   * @dev Update withdraw config
   * @param _time: time for withdraw
   * @param _mode: withdraw mode
   * 0: Apply withdrawTime to both (stake + reward)
   * 1: Apply withdrawTime to stake
   * 2: Apply withdrawTime to reward
   */
  function updateWithdrawConfig(uint256 _time, uint256 _mode) external onlyOwner {
    withdrawTime = _time;
    withdrawMode = _mode;
  }

  /*
   * @notice Return reward multiplier over the given _from to _to time.
   * @param _from: time to start
   * @param _to: time to finish
   */
  function _getMultiplier(uint256 _from, uint256 _to) private view returns (uint256) {
    if (_from < startTime) _from = startTime;
    if (_to > endTime) _to = endTime;
    if (_from >= _to) return 0;
    return _to - _from;
  }

  /*
   * @notice transfer reward tokens.
   * @param _to: address where tokens will transfer
   * @param _amount: amount of tokens
   */
  function _safeRewardTransfer(address _to, uint256 _amount) private {
    uint256 rewardBal = rewardToken.balanceOf(address(this));
    uint256 remaining = getRemainingReward();
    if (remaining > rewardBal) {
      remaining = rewardBal;
    }

    if (_amount > remaining) {
      claimedRewardPerPool += remaining;
      rewardToken.safeTransfer(_to, remaining);
    } else {
      claimedRewardPerPool += _amount;
      rewardToken.safeTransfer(_to, _amount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address sender, uint amount);

  /**
   * @dev allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev get the eth balance on the contract
   * @return eth balance
   */
  function getEthBalance() external view returns (uint) {
    return address(this).balance;
  }

  /**
   * @dev withdraw eth balance
   */
  function emergencyWithdrawEthBalance(address _to, uint _amount) external onlyOwner {
    require(_to != address(0), "Invalid to");
    payable(_to).transfer(_amount);
  }

  /**
   * @dev get the token balance
   * @param _tokenAddress token address
   */
  function getTokenBalance(address _tokenAddress) external view returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev withdraw token balance
   * @param _tokenAddress token address
   */
  function emergencyWithdrawTokenBalance(
    address _tokenAddress,
    address _to,
    uint _amount
  ) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract DSMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint x, uint y) internal pure returns (uint z) {
    return x <= y ? x : y;
  }

  function max(uint x, uint y) internal pure returns (uint z) {
    return x >= y ? x : y;
  }

  function imin(int x, int y) internal pure returns (int z) {
    return x <= y ? x : y;
  }

  function imax(int x, int y) internal pure returns (int z) {
    return x >= y ? x : y;
  }

  uint internal constant WAD = 10**18;
  uint internal constant RAY = 10**27;

  //rounds to zero if x*y < WAD / 2
  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  //rounds to zero if x*y < WAD / 2
  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  //rounds to zero if x*y < RAY / 2
  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint x, uint n) internal pure returns (uint z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }

  // MATH Exponentiation
  // x ^ n using base b
  // EX: rpow(1.1 ether, 30e6, 1 ether) = (1.1 ^ 30e6) ether
  function rpow(
    uint x,
    uint n,
    uint b
  ) internal pure returns (uint z) {
    // solhint-disable no-inline-assembly
    assembly {
      switch x
      case 0 {
        switch n
        case 0 {
          z := b
        }
        default {
          z := 0
        }
      }
      default {
        switch mod(n, 2)
        case 0 {
          z := b
        }
        default {
          z := x
        }
        let half := div(b, 2) // for rounding.
        for {
          n := div(n, 2)
        } n {
          n := div(n, 2)
        } {
          let xx := mul(x, x)
          if iszero(eq(div(xx, x), x)) {
            revert(0, 0)
          }
          let xxRound := add(xx, half)
          if lt(xxRound, xx) {
            revert(0, 0)
          }
          x := div(xxRound, b)
          if mod(n, 2) {
            let zx := mul(z, x)
            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
              revert(0, 0)
            }
            let zxRound := add(zx, half)
            if lt(zxRound, zx) {
              revert(0, 0)
            }
            z := div(zxRound, b)
          }
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IProjectICO {
  function isICORaising() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}