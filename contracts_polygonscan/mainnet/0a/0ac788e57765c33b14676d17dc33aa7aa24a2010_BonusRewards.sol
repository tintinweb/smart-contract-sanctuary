// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IBonusRewards.sol";

/**
 * @title Cover Protocol Bonus Token Rewards contract
 * @author crypto-pumpkin
 * @notice ETH is not allowed to be an bonus token, use wETH instead
 * @notice We support multiple bonus tokens for each pool. However, each pool will have 1 bonus token normally, may have 2 in rare cases
 */
contract BonusRewards is IBonusRewards, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  bool public paused;
  uint256 private constant WEEK = 7 days;
  // help calculate rewards/bonus PerToken only. 1e12 will allow meaningful $1 deposit in a $1bn pool  
  uint256 private constant CAL_MULTIPLIER = 1e30;
  // use array to allow convinient replacement. Size of responders should be very small to 0 till a reputible responder multi-sig within DeFi or Yearn ecosystem is established
  address[] private responders;
  address[] private poolList;
  // lpToken => Pool
  mapping(address => Pool) private pools;
  // lpToken => User address => User data
  mapping(address => mapping(address => User)) private users;
  // use array to allow convinient replacement. Size of Authorizers should be very small (one or two partner addresses for the pool and bonus)
  // lpToken => bonus token => [] allowed authorizers to add bonus tokens
  mapping(address => mapping(address => address[])) private allowedTokenAuthorizers;
  // bonusTokenAddr => 1, used to avoid collecting bonus token when not ready
  mapping(address => uint8) private bonusTokenAddrMap;

  modifier notPaused() {
    require(!paused, "BonusRewards: paused");
    _;
  }

  function claimRewardsForPools(address[] calldata _lpTokens) external override nonReentrant notPaused {
    for (uint256 i = 0; i < _lpTokens.length; i++) {
      address lpToken = _lpTokens[i];
      User memory user = users[lpToken][msg.sender];
      if (user.amount == 0) continue;
      _updatePool(lpToken);
      _claimRewards(lpToken, user);
      _updateUserWriteoffs(lpToken);
    }
  }

  function deposit(address _lpToken, uint256 _amount) external override nonReentrant notPaused {
    require(pools[_lpToken].lastUpdatedAt > 0, "Blacksmith: pool does not exists");
    require(IERC20(_lpToken).balanceOf(msg.sender) >= _amount, "Blacksmith: insufficient balance");

    _updatePool(_lpToken);
    User storage user = users[_lpToken][msg.sender];
    _claimRewards(_lpToken, user);

    IERC20 token = IERC20(_lpToken);
    uint256 balanceBefore = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 received = token.balanceOf(address(this)) - balanceBefore;

    user.amount = user.amount + received;
    _updateUserWriteoffs(_lpToken);
    emit Deposit(msg.sender, _lpToken, received);
  }

  /// @notice withdraw up to all user deposited
  function withdraw(address _lpToken, uint256 _amount) external override nonReentrant notPaused {
    require(pools[_lpToken].lastUpdatedAt > 0, "Blacksmith: pool does not exists");
    _updatePool(_lpToken);

    User storage user = users[_lpToken][msg.sender];
    _claimRewards(_lpToken, user);
    uint256 amount = user.amount > _amount ? _amount : user.amount;
    user.amount = user.amount - amount;
    _updateUserWriteoffs(_lpToken);

    _safeTransfer(_lpToken, amount);
    emit Withdraw(msg.sender, _lpToken, amount);
  }

  /// @notice withdraw all without rewards
  function emergencyWithdraw(address[] calldata _lpTokens) external override nonReentrant {
    for (uint256 i = 0; i < _lpTokens.length; i++) {
      User storage user = users[_lpTokens[i]][msg.sender];
      uint256 amount = user.amount;
      user.amount = 0;
      _safeTransfer(_lpTokens[i], amount);
      emit Withdraw(msg.sender, _lpTokens[i], amount);
    }
  }

  /// @notice called by authorizers only
  function addBonus(
    address _lpToken,
    address _bonusTokenAddr,
    uint48 _startTime,
    uint256 _weeklyRewards,
    uint256 _transferAmount
  ) external override nonReentrant notPaused {
    require(_isAuthorized(allowedTokenAuthorizers[_lpToken][_bonusTokenAddr]), "BonusRewards: not authorized caller");
    require(_startTime >= block.timestamp, "BonusRewards: startTime in the past");

    // make sure the pool is in the right state (exist with no active bonus at the moment) to add new bonus tokens
    Pool memory pool = pools[_lpToken];
    require(pool.lastUpdatedAt > 0, "BonusRewards: pool does not exist");
    Bonus[] memory bonuses = pool.bonuses;
    for (uint256 i = 0; i < bonuses.length; i++) {
      if (bonuses[i].bonusTokenAddr == _bonusTokenAddr) {
        // when there is alreay a bonus program with the same bonus token, make sure the program has ended properly
        require(bonuses[i].endTime + WEEK < block.timestamp, "BonusRewards: last bonus period hasn't ended");
        require(bonuses[i].remBonus == 0, "BonusRewards: last bonus not all claimed");
      }
    }

    IERC20 bonusTokenAddr = IERC20(_bonusTokenAddr);
    uint256 balanceBefore = bonusTokenAddr.balanceOf(address(this));
    bonusTokenAddr.safeTransferFrom(msg.sender, address(this), _transferAmount);
    uint256 received = bonusTokenAddr.balanceOf(address(this)) - balanceBefore;
    // endTime is based on how much tokens transfered v.s. planned weekly rewards
    uint48 endTime = uint48(received * WEEK / _weeklyRewards + _startTime);

    pools[_lpToken].bonuses.push(Bonus({
      bonusTokenAddr: _bonusTokenAddr,
      startTime: _startTime,
      endTime: endTime,
      weeklyRewards: _weeklyRewards,
      accRewardsPerToken: 0,
      remBonus: received
    }));
  }

  /// @notice called by authorizers only, update weeklyRewards (if not ended), or update startTime (only if rewards not started, 0 is ignored)
  function updateBonus(
    address _lpToken,
    address _bonusTokenAddr,
    uint256 _weeklyRewards,
    uint48 _startTime
  ) external override nonReentrant notPaused {
    require(_isAuthorized(allowedTokenAuthorizers[_lpToken][_bonusTokenAddr]), "BonusRewards: not authorized caller");
    require(_startTime == 0 || _startTime > block.timestamp, "BonusRewards: startTime in the past");

    // make sure the pool is in the right state (exist with no active bonus at the moment) to add new bonus tokens
    Pool memory pool = pools[_lpToken];
    require(pool.lastUpdatedAt > 0, "BonusRewards: pool does not exist");
    Bonus[] memory bonuses = pool.bonuses;
    for (uint256 i = 0; i < bonuses.length; i++) {
      if (bonuses[i].bonusTokenAddr == _bonusTokenAddr && bonuses[i].endTime > block.timestamp) {
        Bonus storage bonus = pools[_lpToken].bonuses[i];
        _updatePool(_lpToken); // update pool with old weeklyReward to this block
        if (bonus.startTime >= block.timestamp) {
          // only honor new start time, if program has not started
          if (_startTime >= block.timestamp) {
            bonus.startTime = _startTime;
          }
          bonus.endTime = uint48(bonus.remBonus * WEEK / _weeklyRewards + bonus.startTime);
        } else {
          // remaining bonus to distribute * week
          uint256 remBonusToDistribute = (bonus.endTime - block.timestamp) * bonus.weeklyRewards;
          bonus.endTime = uint48(remBonusToDistribute / _weeklyRewards + block.timestamp);
        }
        bonus.weeklyRewards = _weeklyRewards;
      }
    }
  }

  /// @notice extend the current bonus program, the program has to be active (endTime is in the future)
  function extendBonus(
    address _lpToken,
    uint256 _poolBonusId,
    address _bonusTokenAddr,
    uint256 _transferAmount
  ) external override nonReentrant notPaused {
    require(_isAuthorized(allowedTokenAuthorizers[_lpToken][_bonusTokenAddr]), "BonusRewards: not authorized caller");

    Bonus memory bonus = pools[_lpToken].bonuses[_poolBonusId];
    require(bonus.bonusTokenAddr == _bonusTokenAddr, "BonusRewards: bonus and id dont match");
    require(bonus.endTime > block.timestamp, "BonusRewards: bonus program ended, please start a new one");

    IERC20 bonusTokenAddr = IERC20(_bonusTokenAddr);
    uint256 balanceBefore = bonusTokenAddr.balanceOf(address(this));
    bonusTokenAddr.safeTransferFrom(msg.sender, address(this), _transferAmount);
    uint256 received = bonusTokenAddr.balanceOf(address(this)) - balanceBefore;
    // endTime is based on how much tokens transfered v.s. planned weekly rewards
    uint48 endTime = uint48(received * WEEK / bonus.weeklyRewards + bonus.endTime);

    pools[_lpToken].bonuses[_poolBonusId].endTime = endTime;
    pools[_lpToken].bonuses[_poolBonusId].remBonus = bonus.remBonus + received;
  }

  /// @notice add pools and authorizers to add bonus tokens for pools, combine two calls into one. Only reason we add pools is when bonus tokens will be added
  function addPoolsAndAllowBonus(
    address[] calldata _lpTokens,
    address[] calldata _bonusTokenAddrs,
    address[] calldata _authorizers
  ) external override onlyOwner notPaused {
    // add pools
    uint256 currentTime = block.timestamp;
    for (uint256 i = 0; i < _lpTokens.length; i++) {
      address _lpToken = _lpTokens[i];
      require(IERC20(_lpToken).decimals() <= 18, "BonusRewards: lptoken decimals > 18");
      if (pools[_lpToken].lastUpdatedAt == 0) {
        pools[_lpToken].lastUpdatedAt = currentTime;
        poolList.push(_lpToken);
      }

      // add bonus tokens and their authorizers (who are allowed to add the token to pool)
      for (uint256 j = 0; j < _bonusTokenAddrs.length; j++) {
        address _bonusTokenAddr = _bonusTokenAddrs[j];
        require(pools[_bonusTokenAddr].lastUpdatedAt == 0, "BonusRewards: lpToken, not allowed");
        allowedTokenAuthorizers[_lpToken][_bonusTokenAddr] = _authorizers;
        bonusTokenAddrMap[_bonusTokenAddr] = 1;
      }
    }
  }

  /// @notice collect bonus token dust to treasury
  function collectDust(address _token, address _lpToken, uint256 _poolBonusId) external override onlyOwner {
    require(pools[_token].lastUpdatedAt == 0, "BonusRewards: lpToken, not allowed");

    if (_token == address(0)) { // token address(0) = ETH
      payable(owner()).transfer(address(this).balance);
    } else {
      uint256 balance = IERC20(_token).balanceOf(address(this));
      if (bonusTokenAddrMap[_token] == 1) {
        // bonus token
        Bonus memory bonus = pools[_lpToken].bonuses[_poolBonusId];
        require(bonus.bonusTokenAddr == _token, "BonusRewards: wrong pool");
        require(bonus.endTime + WEEK < block.timestamp, "BonusRewards: not ready");
        balance = bonus.remBonus;
        pools[_lpToken].bonuses[_poolBonusId].remBonus = 0;
      }

      IERC20(_token).transfer(owner(), balance);
    }
  }

  function setResponders(address[] calldata _responders) external override onlyOwner {
    responders = _responders;
  }

  function setPaused(bool _paused) external override {
    require(_isAuthorized(responders), "BonusRewards: caller not responder");
    paused = _paused;
  }

  function getPool(address _lpToken) external view override returns (Pool memory) {
    return pools[_lpToken];
  }

  function getUser(address _lpToken, address _account) external view override returns (User memory, uint256[] memory) {
    return (users[_lpToken][_account], viewRewards(_lpToken, _account));
  }

  function getAuthorizers(address _lpToken, address _bonusTokenAddr) external view override returns (address[] memory) {
    return allowedTokenAuthorizers[_lpToken][_bonusTokenAddr];
  }

  function getResponders() external view override returns (address[] memory) {
    return responders;
  }

  function viewRewards(address _lpToken, address _user) public view override returns (uint256[] memory) {
    Pool memory pool = pools[_lpToken];
    User memory user = users[_lpToken][_user];
    uint256[] memory rewards = new uint256[](pool.bonuses.length);
    if (user.amount <= 0) return rewards;

    uint256 rewardsWriteoffsLen = user.rewardsWriteoffs.length;
    for (uint256 i = 0; i < rewards.length; i ++) {
      Bonus memory bonus = pool.bonuses[i];
      if (bonus.startTime < block.timestamp && bonus.remBonus > 0) {
        uint256 lpTotal = IERC20(_lpToken).balanceOf(address(this));
        uint256 bonusForTime = _calRewardsForTime(bonus, pool.lastUpdatedAt);
        uint256 bonusPerToken = bonus.accRewardsPerToken + bonusForTime / lpTotal;
        uint256 rewardsWriteoff = rewardsWriteoffsLen <= i ? 0 : user.rewardsWriteoffs[i];
        uint256 reward = user.amount * bonusPerToken / CAL_MULTIPLIER - rewardsWriteoff;
        rewards[i] = reward < bonus.remBonus ? reward : bonus.remBonus;
      }
    }
    return rewards;
  }


  function getPoolList() external view override returns (address[] memory) {
    return poolList;
  }

  /// @notice update pool's bonus per staked token till current block timestamp, do nothing if pool does not exist
  function _updatePool(address _lpToken) private {
    Pool storage pool = pools[_lpToken];
    uint256 poolLastUpdatedAt = pool.lastUpdatedAt;
    if (poolLastUpdatedAt == 0 || block.timestamp <= poolLastUpdatedAt) return;
    pool.lastUpdatedAt = block.timestamp;
    uint256 lpTotal = IERC20(_lpToken).balanceOf(address(this));
    if (lpTotal == 0) return;

    for (uint256 i = 0; i < pool.bonuses.length; i ++) {
      Bonus storage bonus = pool.bonuses[i];
      if (poolLastUpdatedAt < bonus.endTime && bonus.startTime < block.timestamp) {
        uint256 bonusForTime = _calRewardsForTime(bonus, poolLastUpdatedAt);
        bonus.accRewardsPerToken = bonus.accRewardsPerToken + bonusForTime / lpTotal;
      }
    }
  }

  function _updateUserWriteoffs(address _lpToken) private {
    Bonus[] memory bonuses = pools[_lpToken].bonuses;
    User storage user = users[_lpToken][msg.sender];
    for (uint256 i = 0; i < bonuses.length; i++) {
      // update writeoff to match current acc rewards per token
      if (user.rewardsWriteoffs.length == i) {
        user.rewardsWriteoffs.push(user.amount * bonuses[i].accRewardsPerToken / CAL_MULTIPLIER);
      } else {
        user.rewardsWriteoffs[i] = user.amount * bonuses[i].accRewardsPerToken / CAL_MULTIPLIER;
      }
    }
  }

  /// @notice tranfer upto what the contract has
  function _safeTransfer(address _token, uint256 _amount) private returns (uint256 _transferred) {
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(address(this));
    if (balance > _amount) {
      token.safeTransfer(msg.sender, _amount);
      _transferred = _amount;
    } else if (balance > 0) {
      token.safeTransfer(msg.sender, balance);
      _transferred = balance;
    }
  }

  function _calRewardsForTime(Bonus memory _bonus, uint256 _lastUpdatedAt) internal view returns (uint256) {
    if (_bonus.endTime <= _lastUpdatedAt) return 0;

    uint256 calEndTime = block.timestamp > _bonus.endTime ? _bonus.endTime : block.timestamp;
    uint256 calStartTime = _lastUpdatedAt > _bonus.startTime ? _lastUpdatedAt : _bonus.startTime;
    uint256 timePassed = calEndTime - calStartTime;
    return _bonus.weeklyRewards * CAL_MULTIPLIER * timePassed / WEEK;
  }

  function _claimRewards(address _lpToken, User memory _user) private {
    // only claim if user has deposited before
    if (_user.amount == 0) return;
    uint256 rewardsWriteoffsLen = _user.rewardsWriteoffs.length;
    Bonus[] memory bonuses = pools[_lpToken].bonuses;
    for (uint256 i = 0; i < bonuses.length; i++) {
      uint256 rewardsWriteoff = rewardsWriteoffsLen <= i ? 0 : _user.rewardsWriteoffs[i];
      uint256 bonusSinceLastUpdate = _user.amount * bonuses[i].accRewardsPerToken / CAL_MULTIPLIER - rewardsWriteoff;
      uint256 toTransfer = bonuses[i].remBonus < bonusSinceLastUpdate ? bonuses[i].remBonus : bonusSinceLastUpdate;
      if (toTransfer == 0) continue;
      uint256 transferred = _safeTransfer(bonuses[i].bonusTokenAddr, toTransfer);
      pools[_lpToken].bonuses[i].remBonus = bonuses[i].remBonus - transferred;
    }
  }

  // only owner or authorized users from list
  function _isAuthorized(address[] memory checkList) private view returns (bool) {
    if (msg.sender == owner()) return true;

    for (uint256 i = 0; i < checkList.length; i++) {
      if (msg.sender == checkList[i]) {
        return true;
      }
    }
    return false;
  }
}