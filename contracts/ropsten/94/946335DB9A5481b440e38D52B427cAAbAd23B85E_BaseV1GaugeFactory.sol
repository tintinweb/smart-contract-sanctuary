// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "Math.sol";

interface erc20 {
  function totalSupply() external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address) external view returns (uint256);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);
}

interface ve {
  function token() external view returns (address);

  function balanceOfNFT(uint256) external view returns (uint256);

  function isApprovedOrOwner(address, uint256) external view returns (bool);

  function ownerOf(uint256) external view returns (address);

  function transferFrom(
    address,
    address,
    uint256
  ) external;
}

interface IBaseV1Factory {
  function isPair(address) external view returns (bool);
}

interface IBaseV1Core {
  function claimFees() external returns (uint256, uint256);

  function tokens() external returns (address, address);
}

interface IBribe {
  function notifyRewardAmount(address token, uint256 amount) external;
}

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Gauge {
  address public immutable stake; // the LP token that needs to be staked for rewards
  address public immutable _ve; // the ve token used for gauges
  address public immutable bribe;
  address public immutable voter;

  uint256 public derivedSupply;
  mapping(address => uint256) public derivedBalances;

  uint256 constant DURATION = 7 days; // rewards are released over 7 days
  uint256 constant PRECISION = 10**18;

  // default snx staking contract implementation
  mapping(address => uint256) public rewardRate;
  mapping(address => uint256) public periodFinish;
  mapping(address => uint256) public lastUpdateTime;
  mapping(address => uint256) public rewardPerTokenStored;

  mapping(address => mapping(address => uint256)) public lastEarn;
  mapping(address => mapping(address => uint256))
    public userRewardPerTokenStored;
  mapping(address => mapping(address => uint256)) public userRewards;

  mapping(address => uint256) public tokenIds;

  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;

  address[] public rewards;
  mapping(address => bool) public isReward;

  function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
    (claimed0, claimed1) = IBaseV1Core(stake).claimFees();
    (address _token0, address _token1) = IBaseV1Core(stake).tokens();
    _safeApprove(_token0, bribe, claimed0);
    _safeApprove(_token1, bribe, claimed1);
    IBribe(bribe).notifyRewardAmount(_token0, claimed0);
    IBribe(bribe).notifyRewardAmount(_token1, claimed1);
  }

  /// @notice A checkpoint for marking balance
  struct Checkpoint {
    uint256 timestamp;
    uint256 balanceOf;
  }

  /// @notice A checkpoint for marking reward rate
  struct RewardPerTokenCheckpoint {
    uint256 timestamp;
    uint256 rewardPerToken;
  }

  /// @notice A checkpoint for marking supply
  struct SupplyCheckpoint {
    uint256 timestamp;
    uint256 supply;
  }

  /// @notice A record of balance checkpoints for each account, by index
  mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint256) public numCheckpoints;

  /// @notice A record of balance checkpoints for each token, by index
  mapping(uint256 => SupplyCheckpoint) public supplyCheckpoints;

  /// @notice The number of checkpoints
  uint256 public supplyNumCheckpoints;

  /// @notice A record of balance checkpoints for each token, by index
  mapping(address => mapping(uint256 => RewardPerTokenCheckpoint))
    public rewardPerTokenCheckpoints;

  /// @notice The number of checkpoints for each token
  mapping(address => uint256) public rewardPerTokenNumCheckpoints;

  // simple re-entrancy check
  uint256 _unlocked = 1;
  modifier lock() {
    require(_unlocked == 1);
    _unlocked = 2;
    _;
    _unlocked = 1;
  }

  constructor(
    address _stake,
    address _bribe,
    address __ve,
    address _voter
  ) {
    stake = _stake;
    bribe = _bribe;
    _ve = __ve;
    voter = _voter;
  }

  /**
   * @notice Determine the prior balance for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param timestamp The timestamp to get the balance at
   * @return The balance the account had as of the given block
   */
  function getPriorBalanceIndex(address account, uint256 timestamp)
    public
    view
    returns (uint256)
  {
    uint256 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].timestamp <= timestamp) {
      return (nCheckpoints - 1);
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].timestamp > timestamp) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.timestamp == timestamp) {
        return center;
      } else if (cp.timestamp < timestamp) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return lower;
  }

  function getPriorSupplyIndex(uint256 timestamp)
    public
    view
    returns (uint256)
  {
    uint256 nCheckpoints = supplyNumCheckpoints;
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (supplyCheckpoints[nCheckpoints - 1].timestamp <= timestamp) {
      return (nCheckpoints - 1);
    }

    // Next check implicit zero balance
    if (supplyCheckpoints[0].timestamp > timestamp) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      SupplyCheckpoint memory cp = supplyCheckpoints[center];
      if (cp.timestamp == timestamp) {
        return center;
      } else if (cp.timestamp < timestamp) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return lower;
  }

  function getPriorRewardPerToken(address token, uint256 timestamp)
    public
    view
    returns (uint256, uint256)
  {
    uint256 nCheckpoints = rewardPerTokenNumCheckpoints[token];
    if (nCheckpoints == 0) {
      return (0, 0);
    }

    // First check most recent balance
    if (
      rewardPerTokenCheckpoints[token][nCheckpoints - 1].timestamp <= timestamp
    ) {
      return (
        rewardPerTokenCheckpoints[token][nCheckpoints - 1].rewardPerToken,
        rewardPerTokenCheckpoints[token][nCheckpoints - 1].timestamp
      );
    }

    // Next check implicit zero balance
    if (rewardPerTokenCheckpoints[token][0].timestamp > timestamp) {
      return (0, 0);
    }

    uint256 lower = 0;
    uint256 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      RewardPerTokenCheckpoint memory cp = rewardPerTokenCheckpoints[token][
        center
      ];
      if (cp.timestamp == timestamp) {
        return (cp.rewardPerToken, cp.timestamp);
      } else if (cp.timestamp < timestamp) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return (
      rewardPerTokenCheckpoints[token][lower].rewardPerToken,
      rewardPerTokenCheckpoints[token][lower].timestamp
    );
  }

  function _writeCheckpoint(address account, uint256 balance) internal {
    uint256 _timestamp = block.timestamp;
    uint256 _nCheckPoints = numCheckpoints[account];

    if (
      _nCheckPoints > 0 &&
      checkpoints[account][_nCheckPoints - 1].timestamp == _timestamp
    ) {
      checkpoints[account][_nCheckPoints - 1].balanceOf = balance;
    } else {
      checkpoints[account][_nCheckPoints] = Checkpoint(_timestamp, balance);
      numCheckpoints[account] = _nCheckPoints + 1;
    }
  }

  function _writeRewardPerTokenCheckpoint(
    address token,
    uint256 reward,
    uint256 timestamp
  ) internal {
    uint256 _nCheckPoints = rewardPerTokenNumCheckpoints[token];

    if (
      _nCheckPoints > 0 &&
      rewardPerTokenCheckpoints[token][_nCheckPoints - 1].timestamp == timestamp
    ) {
      rewardPerTokenCheckpoints[token][_nCheckPoints - 1]
        .rewardPerToken = reward;
    } else {
      rewardPerTokenCheckpoints[token][
        _nCheckPoints
      ] = RewardPerTokenCheckpoint(timestamp, reward);
      rewardPerTokenNumCheckpoints[token] = _nCheckPoints + 1;
    }
  }

  function _writeSupplyCheckpoint() internal {
    uint256 _nCheckPoints = supplyNumCheckpoints;
    uint256 _timestamp = block.timestamp;

    if (
      _nCheckPoints > 0 &&
      supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp
    ) {
      supplyCheckpoints[_nCheckPoints - 1].supply = derivedSupply;
    } else {
      supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(
        _timestamp,
        derivedSupply
      );
      supplyNumCheckpoints = _nCheckPoints + 1;
    }
  }

  function rewardsListLength() external view returns (uint256) {
    return rewards.length;
  }

  // returns the last time the reward was modified or periodFinish if the reward has ended
  function lastTimeRewardApplicable(address token)
    public
    view
    returns (uint256)
  {
    return Math.min(block.timestamp, periodFinish[token]);
  }

  function batchUserRewards(
    address token,
    address account,
    uint256 maxRuns
  ) external {
    (
      rewardPerTokenStored[token],
      lastUpdateTime[token]
    ) = _updateRewardPerToken(token);
    (userRewards[token][account], lastEarn[token][account]) = _batchUserRewards(
      token,
      account,
      maxRuns
    );
  }

  function getReward(address account, address[] memory tokens) public lock {
    require(msg.sender == account || msg.sender == voter);
    for (uint256 i = 0; i < tokens.length; i++) {
      (
        rewardPerTokenStored[tokens[i]],
        lastUpdateTime[tokens[i]]
      ) = _updateRewardPerToken(tokens[i]);

      uint256 _reward = earned(tokens[i], account);
      userRewards[tokens[i]][account] = 0;
      lastEarn[tokens[i]][account] = block.timestamp;
      userRewardPerTokenStored[tokens[i]][account] = rewardPerTokenStored[
        tokens[i]
      ];
      if (_reward > 0) _safeTransfer(tokens[i], account, _reward);
    }

    uint256 _derivedBalance = derivedBalances[account];
    derivedSupply -= _derivedBalance;
    _derivedBalance = derivedBalance(account);
    derivedBalances[account] = _derivedBalance;
    derivedSupply += _derivedBalance;

    _writeCheckpoint(account, derivedBalances[account]);
    _writeSupplyCheckpoint();
  }

  function rewardPerToken(address token) public view returns (uint256) {
    if (derivedSupply == 0) {
      return rewardPerTokenStored[token];
    }
    return
      rewardPerTokenStored[token] +
      (((lastTimeRewardApplicable(token) -
        Math.min(lastUpdateTime[token], periodFinish[token])) *
        rewardRate[token] *
        PRECISION) / derivedSupply);
  }

  function derivedBalance(address account) public view returns (uint256) {
    uint256 _tokenId = tokenIds[account];
    uint256 _balance = balanceOf[account];
    uint256 _derived = (_balance * 40) / 100;
    uint256 _adjusted = 0;
    if (account == ve(_ve).ownerOf(_tokenId)) {
      _adjusted = ve(_ve).balanceOfNFT(_tokenId);
      _adjusted =
        (((totalSupply * _adjusted) / erc20(_ve).totalSupply()) * 60) /
        100;
    }
    return Math.min((_derived + _adjusted), _balance);
  }

  function _batchUserRewards(
    address token,
    address account,
    uint256 maxRuns
  ) internal view returns (uint256, uint256) {
    uint256 _startTimestamp = lastEarn[token][account];
    if (numCheckpoints[account] == 0) {
      return (userRewards[token][account], _startTimestamp);
    }

    uint256 _startIndex = getPriorBalanceIndex(account, _startTimestamp);
    uint256 _endIndex = Math.min(numCheckpoints[account] - 1, maxRuns);

    uint256 reward = userRewards[token][account];
    for (uint256 i = _startIndex; i < _endIndex; i++) {
      Checkpoint memory cp0 = checkpoints[account][i];
      Checkpoint memory cp1 = checkpoints[account][i + 1];
      (uint256 _rewardPerTokenStored0, ) = getPriorRewardPerToken(
        token,
        cp0.timestamp
      );
      (uint256 _rewardPerTokenStored1, ) = getPriorRewardPerToken(
        token,
        cp1.timestamp
      );
      reward +=
        (cp0.balanceOf * (_rewardPerTokenStored1 - _rewardPerTokenStored0)) /
        PRECISION;
      _startTimestamp = cp1.timestamp;
    }

    return (reward, _startTimestamp);
  }

  function batchRewardPerToken(address token, uint256 maxRuns) external {
    (rewardPerTokenStored[token], lastUpdateTime[token]) = _batchRewardPerToken(
      token,
      maxRuns
    );
  }

  function _batchRewardPerToken(address token, uint256 maxRuns)
    internal
    returns (uint256, uint256)
  {
    uint256 _startTimestamp = lastUpdateTime[token];
    uint256 reward = rewardPerTokenStored[token];

    if (supplyNumCheckpoints == 0) {
      return (reward, _startTimestamp);
    }

    uint256 _startIndex = getPriorSupplyIndex(_startTimestamp);
    uint256 _endIndex = Math.min(supplyNumCheckpoints - 1, maxRuns);

    for (uint256 i = _startIndex; i < _endIndex; i++) {
      SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
      if (sp0.supply > 0) {
        SupplyCheckpoint memory sp1 = supplyCheckpoints[i + 1];
        (uint256 _reward, uint256 _endTime) = _calcRewardPerToken(
          token,
          sp1.timestamp,
          sp0.timestamp,
          sp0.supply,
          _startTimestamp
        );
        reward += _reward;
        _writeRewardPerTokenCheckpoint(token, reward, _endTime);
        _startTimestamp = _endTime;
      }
    }

    return (reward, _startTimestamp);
  }

  function _calcRewardPerToken(
    address token,
    uint256 timestamp1,
    uint256 timestamp0,
    uint256 supply,
    uint256 startTimestamp
  ) internal view returns (uint256, uint256) {
    uint256 endTime = Math.max(timestamp1, startTimestamp);
    return (
      (((Math.min(endTime, periodFinish[token]) -
        Math.min(Math.max(timestamp0, startTimestamp), periodFinish[token])) *
        rewardRate[token] *
        PRECISION) / supply),
      endTime
    );
  }

  function _updateRewardPerToken(address token)
    internal
    returns (uint256, uint256)
  {
    uint256 _startTimestamp = lastUpdateTime[token];
    uint256 reward = rewardPerTokenStored[token];

    if (supplyNumCheckpoints == 0) {
      return (reward, _startTimestamp);
    }

    uint256 _startIndex = getPriorSupplyIndex(_startTimestamp);
    uint256 _endIndex = supplyNumCheckpoints - 1;

    if (_endIndex - _startIndex > 1) {
      for (uint256 i = _startIndex; i < _endIndex - 1; i++) {
        SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
        if (sp0.supply > 0) {
          SupplyCheckpoint memory sp1 = supplyCheckpoints[i + 1];
          (uint256 _reward, uint256 _endTime) = _calcRewardPerToken(
            token,
            sp1.timestamp,
            sp0.timestamp,
            sp0.supply,
            _startTimestamp
          );
          reward += _reward;
          _writeRewardPerTokenCheckpoint(token, reward, _endTime);
          _startTimestamp = _endTime;
        }
      }
    }

    SupplyCheckpoint memory sp = supplyCheckpoints[_endIndex];
    if (sp.supply > 0) {
      (uint256 _reward, ) = _calcRewardPerToken(
        token,
        lastTimeRewardApplicable(token),
        Math.max(sp.timestamp, _startTimestamp),
        sp.supply,
        _startTimestamp
      );
      reward += _reward;
      _writeRewardPerTokenCheckpoint(token, reward, block.timestamp);
      _startTimestamp = block.timestamp;
    }

    return (reward, _startTimestamp);
  }

  // earned is an estimation, it won't be exact till the supply > rewardPerToken calculations have run
  function earned(address token, address account)
    public
    view
    returns (uint256)
  {
    uint256 _startTimestamp = lastEarn[token][account];
    if (numCheckpoints[account] == 0) {
      return userRewards[token][account];
    }

    uint256 _startIndex = getPriorBalanceIndex(account, _startTimestamp);
    uint256 _endIndex = numCheckpoints[account] - 1;

    uint256 reward = userRewards[token][account];

    if (_endIndex - _startIndex > 1) {
      for (uint256 i = _startIndex; i < _endIndex - 1; i++) {
        Checkpoint memory cp0 = checkpoints[account][i];
        Checkpoint memory cp1 = checkpoints[account][i + 1];
        (uint256 _rewardPerTokenStored0, ) = getPriorRewardPerToken(
          token,
          cp0.timestamp
        );
        (uint256 _rewardPerTokenStored1, ) = getPriorRewardPerToken(
          token,
          cp1.timestamp
        );
        reward +=
          (cp0.balanceOf * (_rewardPerTokenStored1 - _rewardPerTokenStored0)) /
          PRECISION;
      }
    }

    Checkpoint memory cp = checkpoints[account][_endIndex];
    (uint256 _rewardPerTokenStored, ) = getPriorRewardPerToken(
      token,
      cp.timestamp
    );
    reward +=
      (cp.balanceOf *
        (rewardPerToken(token) -
          Math.max(
            _rewardPerTokenStored,
            userRewardPerTokenStored[token][account]
          ))) /
      PRECISION;

    return reward;
  }

  function deposit(uint256 amount, uint256 tokenId) public lock {
    tokenIds[msg.sender] = tokenId;
    _safeTransferFrom(stake, msg.sender, address(this), amount);
    totalSupply += amount;
    balanceOf[msg.sender] += amount;

    uint256 _derivedBalance = derivedBalances[msg.sender];
    derivedSupply -= _derivedBalance;
    _derivedBalance = derivedBalance(msg.sender);
    derivedBalances[msg.sender] = _derivedBalance;
    derivedSupply += _derivedBalance;

    _writeCheckpoint(msg.sender, _derivedBalance);
    _writeSupplyCheckpoint();
  }

  function withdraw(uint256 amount) public lock {
    tokenIds[msg.sender] = 0;
    totalSupply -= amount;
    balanceOf[msg.sender] -= amount;
    _safeTransfer(stake, msg.sender, amount);

    uint256 _derivedBalance = derivedBalances[msg.sender];
    derivedSupply -= _derivedBalance;
    _derivedBalance = derivedBalance(msg.sender);
    derivedBalances[msg.sender] = _derivedBalance;
    derivedSupply += _derivedBalance;

    _writeCheckpoint(msg.sender, derivedBalances[msg.sender]);
    _writeSupplyCheckpoint();
  }

  function left(address token) external view returns (uint256) {
    if (block.timestamp >= periodFinish[token]) return 0;
    uint256 _remaining = periodFinish[token] - block.timestamp;
    return _remaining * rewardRate[token];
  }

  function notifyRewardAmount(address token, uint256 amount) external lock {
    (
      rewardPerTokenStored[token],
      lastUpdateTime[token]
    ) = _updateRewardPerToken(token);

    if (block.timestamp >= periodFinish[token]) {
      _safeTransferFrom(token, msg.sender, address(this), amount);
      rewardRate[token] = amount / DURATION;
    } else {
      uint256 _remaining = periodFinish[token] - block.timestamp;
      uint256 _left = _remaining * rewardRate[token];
      require(amount > _left);
      _safeTransferFrom(token, msg.sender, address(this), amount);
      rewardRate[token] = (amount + _left) / DURATION;
    }
    require(rewardRate[token] > 0);
    periodFinish[token] = block.timestamp + DURATION;
    if (!isReward[token]) {
      isReward[token] = true;
      rewards.push(token);
    }
  }

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(erc20.transfer.selector, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function _safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function _safeApprove(
    address token,
    address spender,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(erc20.approve.selector, spender, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }
}

contract BaseV1GaugeFactory {
  address public last_gauge;
  address[] public gauges;
  uint256 public gaugesLength;
  mapping(address => address[]) public gaugesByPoolAddress;
  mapping(address => address[]) public gaugesByBribeAddress;
  mapping(address => address[]) public gaugesByVeAddress;
  mapping(address => address[]) public gaugesByVoterAddress;
  mapping(address => uint256) public gaugesByPoolAddressLength;
  mapping(address => uint256) public gaugesByBribeAddressLength;
  mapping(address => uint256) public gaugesByVeAddressLength;
  mapping(address => uint256) public gaugesByVoterAddressLength;

  function createGauge(
    address _pool,
    address _bribe,
    address _ve
  ) external returns (address) {
    last_gauge = address(new Gauge(_pool, _bribe, _ve, msg.sender));
    registerGauge(last_gauge, _pool, _bribe, _ve, msg.sender);
    return last_gauge;
  }

  function registerGauge(
    address _gauge,
    address _pool,
    address _bribe,
    address _ve,
    address _voter
  ) internal {
    gauges.push(_gauge);
    gaugesByPoolAddress[_pool].push(_gauge);
    gaugesByBribeAddress[_bribe].push(_gauge);
    gaugesByVeAddress[_ve].push(_gauge);
    gaugesByVoterAddress[_voter].push(_gauge);
    gaugesLength++;
    gaugesByPoolAddressLength[_pool]++;
    gaugesByBribeAddressLength[_bribe]++;
    gaugesByVeAddressLength[_ve]++;
    gaugesByVoterAddressLength[_voter]++;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  function cbrt(uint256 n) internal pure returns (uint256) {
    unchecked {
      uint256 x = 0;
      for (uint256 y = 1 << 255; y > 0; y >>= 3) {
        x <<= 1;
        uint256 z = 3 * x * (x + 1) + 1;
        if (n / y >= z) {
          n -= y * z;
          x += 1;
        }
      }
      return x;
    }
  }
}