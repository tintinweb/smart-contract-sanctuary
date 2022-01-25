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

interface IBaseV1GaugeFactory {
  function createGauge(
    address,
    address,
    address
  ) external returns (address);
}

interface IGauge {
  function notifyRewardAmount(address token, uint256 amount) external;

  function getReward(address account, address[] memory tokens) external;

  function claimFees() external returns (uint256 claimed0, uint256 claimed1);

  function left(address token) external view returns (uint256);
}

// Bribes pay out rewards for a given pool based on the votes that were received from the user (goes hand in hand with BaseV1Gauges.vote())
contract Bribe {
  address public immutable factory; // only factory can modify balances (since it only happens on vote())
  address public immutable _ve;

  uint256 public constant DURATION = 7 days; // rewards are released over 7 days
  uint256 public constant PRECISION = 10**18;

  // default snx staking contract implementation
  mapping(address => uint256) public rewardRate;
  mapping(address => uint256) public periodFinish;
  mapping(address => uint256) public lastUpdateTime;
  mapping(address => uint256) public rewardPerTokenStored;

  mapping(address => mapping(uint256 => uint256)) public lastEarn;
  mapping(address => mapping(uint256 => uint256))
    public userRewardPerTokenStored;
  mapping(address => mapping(uint256 => uint256)) public userRewards;

  address[] public rewards;
  mapping(address => bool) public isReward;

  uint256 public totalSupply;
  mapping(uint256 => uint256) public balanceOf;

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
  mapping(uint256 => mapping(uint256 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(uint256 => uint256) public numCheckpoints;

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

  constructor() {
    factory = msg.sender;
    _ve = BaseV1Voter(msg.sender)._ve();
  }

  /**
   * @notice Determine the prior balance for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param tokenId The token of the NFT to check
   * @param timestamp The timestamp to get the balance at
   * @return The balance the account had as of the given block
   */
  function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp)
    public
    view
    returns (uint256)
  {
    uint256 nCheckpoints = numCheckpoints[tokenId];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[tokenId][nCheckpoints - 1].timestamp <= timestamp) {
      return (nCheckpoints - 1);
    }

    // Next check implicit zero balance
    if (checkpoints[tokenId][0].timestamp > timestamp) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[tokenId][center];
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

  function _writeCheckpoint(uint256 tokenId, uint256 balance) internal {
    uint256 _timestamp = block.timestamp;
    uint256 _nCheckPoints = numCheckpoints[tokenId];

    if (
      _nCheckPoints > 0 &&
      checkpoints[tokenId][_nCheckPoints - 1].timestamp == _timestamp
    ) {
      checkpoints[tokenId][_nCheckPoints - 1].balanceOf = balance;
    } else {
      checkpoints[tokenId][_nCheckPoints] = Checkpoint(_timestamp, balance);
      numCheckpoints[tokenId] = _nCheckPoints + 1;
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
      supplyCheckpoints[_nCheckPoints - 1].supply = totalSupply;
    } else {
      supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(
        _timestamp,
        totalSupply
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
    uint256 tokenId,
    uint256 maxRuns
  ) external {
    (
      rewardPerTokenStored[token],
      lastUpdateTime[token]
    ) = _updateRewardPerToken(token);
    (userRewards[token][tokenId], lastEarn[token][tokenId]) = _batchUserRewards(
      token,
      tokenId,
      maxRuns
    );
  }

  // allows a user to claim rewards for a given token
  function getReward(uint256 tokenId, address[] memory tokens) public lock {
    require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId));
    for (uint256 i = 0; i < tokens.length; i++) {
      (
        rewardPerTokenStored[tokens[i]],
        lastUpdateTime[tokens[i]]
      ) = _updateRewardPerToken(tokens[i]);

      uint256 _reward = earned(tokens[i], tokenId);
      userRewards[tokens[i]][tokenId] = 0;
      lastEarn[tokens[i]][tokenId] = block.timestamp;
      userRewardPerTokenStored[tokens[i]][tokenId] = rewardPerTokenStored[
        tokens[i]
      ];
      if (_reward > 0) _safeTransfer(tokens[i], msg.sender, _reward);
    }
  }

  // used by BaseV1Voter to allow batched reward claims
  function getRewardForOwner(uint256 tokenId, address[] memory tokens)
    public
    lock
  {
    require(msg.sender == factory);
    address _owner = ve(_ve).ownerOf(tokenId);
    for (uint256 i = 0; i < tokens.length; i++) {
      (
        rewardPerTokenStored[tokens[i]],
        lastUpdateTime[tokens[i]]
      ) = _updateRewardPerToken(tokens[i]);

      uint256 _reward = earned(tokens[i], tokenId);
      userRewards[tokens[i]][tokenId] = 0;
      lastEarn[tokens[i]][tokenId] = block.timestamp;
      userRewardPerTokenStored[tokens[i]][tokenId] = rewardPerTokenStored[
        tokens[i]
      ];
      if (_reward > 0) _safeTransfer(tokens[i], _owner, _reward);
    }
  }

  function rewardPerToken(address token) public view returns (uint256) {
    if (totalSupply == 0) {
      return rewardPerTokenStored[token];
    }
    return
      rewardPerTokenStored[token] +
      (((lastTimeRewardApplicable(token) -
        Math.min(lastUpdateTime[token], periodFinish[token])) *
        rewardRate[token] *
        PRECISION) / totalSupply);
  }

  function _batchUserRewards(
    address token,
    uint256 tokenId,
    uint256 maxRuns
  ) internal view returns (uint256, uint256) {
    uint256 _startTimestamp = lastEarn[token][tokenId];
    if (numCheckpoints[tokenId] == 0) {
      return (userRewards[token][tokenId], _startTimestamp);
    }

    uint256 _startIndex = getPriorBalanceIndex(tokenId, _startTimestamp);
    uint256 _endIndex = Math.min(numCheckpoints[tokenId] - 1, maxRuns);

    uint256 reward = userRewards[token][tokenId];
    for (uint256 i = _startIndex; i < _endIndex; i++) {
      Checkpoint memory cp0 = checkpoints[tokenId][i];
      Checkpoint memory cp1 = checkpoints[tokenId][i + 1];
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
        (uint256 _reward, uint256 endTime) = _calcRewardPerToken(
          token,
          sp1.timestamp,
          sp0.timestamp,
          sp0.supply,
          _startTimestamp
        );
        reward += _reward;
        _writeRewardPerTokenCheckpoint(token, reward, endTime);
        _startTimestamp = endTime;
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

  function earned(address token, uint256 tokenId)
    public
    view
    returns (uint256)
  {
    uint256 _startTimestamp = lastEarn[token][tokenId];
    if (numCheckpoints[tokenId] == 0) {
      return userRewards[token][tokenId];
    }

    uint256 _startIndex = getPriorBalanceIndex(tokenId, _startTimestamp);
    uint256 _endIndex = numCheckpoints[tokenId] - 1;

    uint256 reward = userRewards[token][tokenId];

    if (_endIndex - _startIndex > 1) {
      for (uint256 i = _startIndex; i < _endIndex - 1; i++) {
        Checkpoint memory cp0 = checkpoints[tokenId][i];
        Checkpoint memory cp1 = checkpoints[tokenId][i + 1];
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

    Checkpoint memory cp = checkpoints[tokenId][_endIndex];
    (uint256 _rewardPerTokenStored, ) = getPriorRewardPerToken(
      token,
      cp.timestamp
    );
    reward +=
      (cp.balanceOf *
        (rewardPerToken(token) -
          Math.max(
            _rewardPerTokenStored,
            userRewardPerTokenStored[token][tokenId]
          ))) /
      PRECISION;

    return reward;
  }

  // This is an external function, but internal notation is used since it can only be called "internally" from BaseV1Gauges
  function _deposit(uint256 amount, uint256 tokenId) external {
    require(msg.sender == factory);
    totalSupply += amount;
    balanceOf[tokenId] += amount;

    _writeCheckpoint(tokenId, balanceOf[tokenId]);
    _writeSupplyCheckpoint();
  }

  function _withdraw(uint256 amount, uint256 tokenId) external {
    require(msg.sender == factory);
    totalSupply -= amount;
    balanceOf[tokenId] -= amount;

    _writeCheckpoint(tokenId, balanceOf[tokenId]);
    _writeSupplyCheckpoint();
  }

  // used to notify a gauge/bribe of a given reward, this can create griefing attacks by extending rewards
  // TODO: rework to weekly resets, _updatePeriod as per v1 bribes
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
}

contract BaseV1Voter {
  address public immutable _ve; // the ve token that governs these contracts
  address internal immutable factory; // the BaseV1Factory
  address internal immutable base;
  address internal immutable gaugefactory;

  uint256 public totalWeight; // total voting weight

  // simple re-entrancy check
  uint256 _unlocked = 1;
  modifier lock() {
    require(_unlocked == 1);
    _unlocked = 2;
    _;
    _unlocked = 1;
  }

  address[] public pools; // all pools viable for incentives
  mapping(address => address) public gauges; // pool => gauge
  mapping(address => address) public poolForGauge; // gauge => pool
  mapping(address => address) public bribes; // gauge => bribe
  mapping(address => uint256) public weights; // pool => weight
  mapping(uint256 => mapping(address => uint256)) public votes; // nft => pool => votes
  mapping(uint256 => address[]) public poolVote; // nft => pools
  mapping(uint256 => uint256) public usedWeights; // nft => total voting weight of user

  constructor(
    address __ve,
    address _factory,
    address _gauges
  ) {
    _ve = __ve;
    factory = _factory;
    base = ve(__ve).token();
    gaugefactory = _gauges;
  }

  function reset(uint256 _tokenId) external {
    _reset(_tokenId);
  }

  function _reset(uint256 _tokenId) internal {
    address[] storage _poolVote = poolVote[_tokenId];
    uint256 _poolVoteCnt = _poolVote.length;

    for (uint256 i = 0; i < _poolVoteCnt; i++) {
      address _pool = _poolVote[i];
      uint256 _votes = votes[_tokenId][_pool];

      if (_votes > 0) {
        _updateFor(gauges[_pool]);
        totalWeight -= _votes;
        weights[_pool] -= _votes;
        votes[_tokenId][_pool] = 0;
        Bribe(bribes[gauges[_pool]])._withdraw(_votes, _tokenId);
      }
    }

    delete poolVote[_tokenId];
  }

  function poke(uint256 _tokenId) public {
    address[] memory _poolVote = poolVote[_tokenId];
    uint256 _poolCnt = _poolVote.length;
    uint256[] memory _weights = new uint256[](_poolCnt);

    uint256 _prevUsedWeight = usedWeights[_tokenId];
    uint256 _weight = ve(_ve).balanceOfNFT(_tokenId);

    for (uint256 i = 0; i < _poolCnt; i++) {
      uint256 _prevWeight = votes[_tokenId][_poolVote[i]];
      _weights[i] = (_prevWeight * _weight) / _prevUsedWeight;
    }

    _vote(_tokenId, _poolVote, _weights);
  }

  function _vote(
    uint256 _tokenId,
    address[] memory _poolVote,
    uint256[] memory _weights
  ) internal {
    require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
    _reset(_tokenId);
    uint256 _poolCnt = _poolVote.length;
    uint256 _weight = ve(_ve).balanceOfNFT(_tokenId);
    uint256 _totalVoteWeight = 0;
    uint256 _usedWeight = 0;

    for (uint256 i = 0; i < _poolCnt; i++) {
      _totalVoteWeight += _weights[i];
    }

    for (uint256 i = 0; i < _poolCnt; i++) {
      address _pool = _poolVote[i];
      address _gauge = gauges[_pool];
      uint256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;

      if (_gauge != address(0x0)) {
        _updateFor(_gauge);
        _usedWeight += _poolWeight;
        totalWeight += _poolWeight;
        weights[_pool] += _poolWeight;
        poolVote[_tokenId].push(_pool);
        votes[_tokenId][_pool] = _poolWeight;
        Bribe(bribes[_gauge])._deposit(_poolWeight, _tokenId);
      }
    }

    usedWeights[_tokenId] = _usedWeight;
  }

  function vote(
    uint256 tokenId,
    address[] calldata _poolVote,
    uint256[] calldata _weights
  ) external {
    require(_poolVote.length == _weights.length);
    _vote(tokenId, _poolVote, _weights);
  }

  function createGauge(address _pool) external returns (address) {
    require(gauges[_pool] == address(0x0), "exists");
    require(IBaseV1Factory(factory).isPair(_pool), "!_pool");
    address _bribe = address(new Bribe());
    address _gauge = IBaseV1GaugeFactory(gaugefactory).createGauge(
      _pool,
      _bribe,
      _ve
    );
    erc20(base).approve(_gauge, type(uint256).max);
    bribes[_gauge] = _bribe;
    gauges[_pool] = _gauge;
    poolForGauge[_gauge] = _pool;
    _updateFor(_gauge);
    pools.push(_pool);
    return _gauge;
  }

  function length() external view returns (uint256) {
    return pools.length;
  }

  uint256 internal index;
  mapping(address => uint256) internal supplyIndex;
  mapping(address => uint256) public claimable;

  function notifyRewardAmount(uint256 amount) external lock {
    _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
    uint256 _ratio = (amount * 1e18) / totalWeight; // 1e18 adjustment is removed during claim
    if (_ratio > 0) {
      index += _ratio;
    }
  }

  function updateFor(address[] memory _gauges) external {
    for (uint256 i = 0; i < _gauges.length; i++) {
      _updateFor(_gauges[i]);
    }
  }

  function updateFor(uint256 start, uint256 end) public {
    for (uint256 i = start; i < end; i++) {
      _updateFor(gauges[pools[i]]);
    }
  }

  function updateAll() public {
    updateFor(0, pools.length);
  }

  function updateGauge(address _gauge) external {
    _updateFor(_gauge);
  }

  function _updateFor(address _gauge) internal {
    address _pool = poolForGauge[_gauge];
    uint256 _supplied = weights[_pool];
    if (_supplied > 0) {
      uint256 _supplyIndex = supplyIndex[_gauge];
      uint256 _index = index; // get global index0 for accumulated distro
      supplyIndex[_gauge] = _index; // update _gauge current position to global position
      uint256 _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
      if (_delta > 0) {
        uint256 _share = (_supplied * _delta) / 1e18; // add accrued difference for each supplied token
        claimable[_gauge] += _share;
      }
    } else {
      supplyIndex[_gauge] = index; // new users are set to the default global state
    }
  }

  function claimRewards(address[] memory _gauges, address[][] memory _tokens)
    external
  {
    for (uint256 i = 0; i < _gauges.length; i++) {
      IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
    }
  }

  function claimBribes(
    address[] memory _bribes,
    address[][] memory _tokens,
    uint256 _tokenId
  ) external {
    require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
    for (uint256 i = 0; i < _bribes.length; i++) {
      Bribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
    }
  }

  function claimFees(
    address[] memory _bribes,
    address[][] memory _tokens,
    uint256 _tokenId
  ) external {
    require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
    for (uint256 i = 0; i < _bribes.length; i++) {
      Bribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
    }
  }

  function distributeFees(address[] memory _gauges) external {
    for (uint256 i = 0; i < _gauges.length; i++) {
      IGauge(_gauges[i]).claimFees();
    }
  }

  function distribute(address _gauge) public lock {
    _updateFor(_gauge);
    uint256 _claimable = claimable[_gauge];
    uint256 _left = IGauge(_gauge).left(base);
    if (_claimable > _left) {
      claimable[_gauge] = 0;
      IGauge(_gauge).notifyRewardAmount(base, _claimable);
    }
  }

  function distro() external {
    distribute(0, pools.length);
  }

  function distribute() external {
    distribute(0, pools.length);
  }

  function distribute(uint256 start, uint256 finish) public {
    for (uint256 x = start; x < finish; x++) {
      distribute(gauges[pools[x]]);
    }
  }

  function distribute(address[] memory _gauges) external {
    for (uint256 x = 0; x < _gauges.length; x++) {
      distribute(_gauges[x]);
    }
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