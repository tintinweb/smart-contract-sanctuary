// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import './Core.sol';

contract AFTStaking is ICommonMaster, AccessControl, Pausable, Initializable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;
  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
  }

  // Info of each pool.
  struct PoolInfo {
    uint256 allocPoint; // How many allocation points assigned to this pool. TOKENs to distribute per block.
    uint256 lastRewardBlock; // Last block number that TOKENs distribution occurs.
    uint256 accTokenPerShare; // Accumulated TOKENs per share, times 1e22. See below.
    bool exists; //
  }
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;
  // The block number when TOKEN mining starts.
  uint256 public startBlock;
  // TOKEN tokens created per block.
  uint256 public tokenPerBlock;
  // Accumulated TOKENs per share, times 1e22.
  uint256 public constant accTokenPerShareMultiple = 1E22;
  // total TOKEN to be mint amount
  uint256 public totalToBeMintAmount = 0;
  // minted TOKEN amount
  uint256 public mintedAmount = 0;
  // The TOKEN TOKEN!
  ERC20 public token;
  address[] public poolAddresses;
  // Info of each pool.
  mapping(address => PoolInfo) public poolInfoMap;
  // Info of each user that stakes LP tokens.
  mapping(address => mapping(address => UserInfo)) public poolUserInfoMap;

  constructor() public {}

  modifier onlyOwner() {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      'Ownable: caller is not the owner'
    );
    _;
  }

  function initialize(
    address _token,
    uint256 _startBlock,
    uint256 _tokenPerBlock,
    uint256 _totalToBeMintAmount,
    address owner
  ) external override initializer {
    token = ERC20(_token);
    startBlock = _startBlock;
    tokenPerBlock = _tokenPerBlock;
    totalToBeMintAmount = _totalToBeMintAmount;
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
  }

  function setStartBlock(uint256 _startBlock) public onlyOwner {
    require(
      block.number <= _startBlock && startBlock >= block.number,
      'FORBIDDEN'
    );
    startBlock = _startBlock;
  }

  // *** POOL MANAGER ***
  function poolLength() external view override returns (uint256) {
    return poolAddresses.length;
  }

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    address _pair,
    bool _withUpdate
  ) external override onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    PoolInfo storage pool = poolInfoMap[_pair];
    require(!pool.exists, 'pool already exists');
    uint256 lastRewardBlock = block.number > startBlock
      ? block.number
      : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfoMap[_pair] = PoolInfo({
      allocPoint: _allocPoint,
      lastRewardBlock: lastRewardBlock,
      accTokenPerShare: 0,
      exists: true
    });
    poolAddresses.push(_pair);
  }

  // Update the given pool's TOKEN allocation point. Can only be called by the owner.
  function set(
    address _pair,
    uint256 _allocPoint,
    bool _withUpdate
  ) external override onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    PoolInfo storage pool = poolInfoMap[_pair];
    require(pool.exists, 'pool not exists');
    totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
    pool.allocPoint = _allocPoint;
  }

  function setLastRewardBlock(address _pair, uint256 _lastRewardBlock)
    external
    override
    onlyOwner
  {
    PoolInfo storage pool = poolInfoMap[_pair];
    require(pool.exists, 'pool not exists');
    require(
      pool.accTokenPerShare == 0 && _lastRewardBlock >= block.number,
      'err'
    );
    pool.lastRewardBlock = _lastRewardBlock;
  }

  // Return total reward over the given _from to _to block.
  function getTotalReward(uint256 _from, uint256 _to)
    public
    view
    override
    returns (uint256 totalReward)
  {
    if (_to <= startBlock || mintedAmount >= totalToBeMintAmount) {
      return 0;
    }
    if (_from < startBlock) {
      _from = startBlock;
    }
    return
      Math.min(
        totalToBeMintAmount.sub(mintedAmount),
        _to.sub(_from).mul(tokenPerBlock)
      );
  }

  // View function to see pending TOKENs on frontend.
  function pendingToken(address _pair, address _user)
    external
    view
    override
    returns (uint256)
  {
    PoolInfo memory pool = poolInfoMap[_pair];
    if (!pool.exists) {
      return 0;
    }
    UserInfo storage userInfo = poolUserInfoMap[_pair][_user];
    uint256 accTokenPerShare = pool.accTokenPerShare;
    uint256 stakeBalance = ERC20(_pair)
      .balanceOf(address(this))
      .mul(10**uint256(token.decimals()))
      .div(10**uint256(ERC20(_pair).decimals()));
    if (block.number > pool.lastRewardBlock && stakeBalance != 0) {
      uint256 totalReward = getTotalReward(pool.lastRewardBlock, block.number);
      uint256 tokenReward = totalReward.mul(pool.allocPoint).div(
        totalAllocPoint
      );
      accTokenPerShare = accTokenPerShare.add(
        tokenReward.mul(accTokenPerShareMultiple).div(stakeBalance)
      );
    }
    return
      userInfo
        .amount
        .mul(accTokenPerShare)
        .mul(10**uint256(token.decimals()))
        .div(10**uint256(ERC20(_pair).decimals()))
        .div(accTokenPerShareMultiple)
        .sub(userInfo.rewardDebt);
  }

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public override {
    uint256 length = poolAddresses.length;
    for (uint256 i = 0; i < length; ++i) {
      updatePool(poolAddresses[i]);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(address _pair) public override {
    PoolInfo storage pool = poolInfoMap[_pair];
    if (!pool.exists || block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 stakeBalance = ERC20(_pair)
      .balanceOf(address(this))
      .mul(10**uint256(token.decimals()))
      .div(10**uint256(ERC20(_pair).decimals()));
    if (stakeBalance == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    if (mintedAmount >= totalToBeMintAmount) {
      return;
    }
    uint256 totalReward = getTotalReward(pool.lastRewardBlock, block.number);
    uint256 tokenReward = totalReward.mul(pool.allocPoint).div(totalAllocPoint);
    mintedAmount = mintedAmount.add(tokenReward);
    pool.accTokenPerShare = pool.accTokenPerShare.add(
      tokenReward.mul(accTokenPerShareMultiple).div(stakeBalance)
    );
    pool.lastRewardBlock = block.number;
  }

  // Stake LP tokens to TokenMaster for TOKEN allocation.
  function stake(address _pair, uint256 _amount)
    external
    override
    whenNotPaused
  {
    PoolInfo storage pool = poolInfoMap[_pair];
    UserInfo storage userInfo = poolUserInfoMap[_pair][msg.sender];
    updatePool(_pair);
    if (userInfo.amount != 0) {
      uint256 pending = userInfo
        .amount
        .mul(pool.accTokenPerShare)
        .mul(10**uint256(token.decimals()))
        .div(10**uint256(ERC20(_pair).decimals()))
        .div(accTokenPerShareMultiple)
        .sub(userInfo.rewardDebt);
      if (pending != 0) {
        safeTokenTransfer(msg.sender, pending);
      }
    }
    if (_amount != 0) {
      ERC20(_pair).safeTransferFrom(
        address(msg.sender),
        address(this),
        _amount
      );
      userInfo.amount = userInfo.amount.add(_amount);
    }
    userInfo.rewardDebt = userInfo
      .amount
      .mul(pool.accTokenPerShare)
      .mul(10**uint256(token.decimals()))
      .div(10**uint256(ERC20(_pair).decimals()))
      .div(accTokenPerShareMultiple);
    emit Stake(msg.sender, _pair, _amount);
  }

  // Unstake LP tokens from TokenMaster.
  function unstake(address _pair, uint256 _amount) external override {
    PoolInfo storage pool = poolInfoMap[_pair];
    UserInfo storage userInfo = poolUserInfoMap[_pair][msg.sender];
    require(userInfo.amount >= _amount, 'withdraw: not good');
    updatePool(_pair);
    uint256 pending = userInfo
      .amount
      .mul(pool.accTokenPerShare)
      .mul(10**uint256(token.decimals()))
      .div(10**uint256(ERC20(_pair).decimals()))
      .div(accTokenPerShareMultiple)
      .sub(userInfo.rewardDebt);
    if (pending != 0) {
      safeTokenTransfer(msg.sender, pending);
    }
    if (_amount != 0) {
      userInfo.amount = userInfo.amount.sub(_amount);
      ERC20(_pair).safeTransfer(address(msg.sender), _amount);
    }
    userInfo.rewardDebt = userInfo
      .amount
      .mul(pool.accTokenPerShare)
      .mul(10**uint256(token.decimals()))
      .div(10**uint256(ERC20(_pair).decimals()))
      .div(accTokenPerShareMultiple);
    emit Unstake(msg.sender, _pair, _amount);
  }

  // Unstake without caring about rewards. EMERGENCY ONLY.
  function emergencyUnstake(address _pair, uint256 _amount) external override {
    UserInfo storage userInfo = poolUserInfoMap[_pair][msg.sender];
    PoolInfo memory pool = poolInfoMap[_pair];
    if (_amount == 0) {
      _amount = userInfo.amount;
    } else {
      _amount = Math.min(_amount, userInfo.amount);
    }
    ERC20(_pair).safeTransfer(address(msg.sender), _amount);
    emit EmergencyUnstake(msg.sender, _pair, _amount);
    if (_amount == userInfo.amount) {
      delete poolUserInfoMap[_pair][msg.sender];
    } else {
      userInfo.amount = userInfo.amount.sub(_amount);
      userInfo.rewardDebt = userInfo
        .amount
        .mul(pool.accTokenPerShare)
        .mul(10**uint256(token.decimals()))
        .div(10**uint256(ERC20(_pair).decimals()))
        .div(accTokenPerShareMultiple);
    }
  }

  // Safe token transfer function, just in case if rounding error causes pool to not have enough TOKENs.
  function safeTokenTransfer(address _to, uint256 _amount) internal {
    uint256 tokenBal = token.balanceOf(address(this));
    if (_amount > tokenBal) {
      token.transfer(_to, tokenBal);
    } else {
      token.transfer(_to, _amount);
    }
  }

  function pauseStake() external override onlyOwner whenNotPaused {
    _pause();
  }

  function unpauseStake() external override onlyOwner whenPaused {
    _unpause();
  }

  function setTokenPerBlock(uint256 _tokenPerBlock)
    external
    override
    onlyOwner
  {
    require(tokenPerBlock != _tokenPerBlock, ' NOT NEED UPDATE');
    emit SetTokenPerBlock(msg.sender, _tokenPerBlock);
    tokenPerBlock = _tokenPerBlock;
  }

  function setTotalToBeMintAmount(uint256 _totalToBeMintAmount)
    external
    override
    onlyOwner
  {
    require(totalToBeMintAmount != _totalToBeMintAmount, 'Not need update');
    emit SetTotalToBeMintAmount(
      msg.sender,
      totalToBeMintAmount,
      _totalToBeMintAmount
    );
    totalToBeMintAmount = _totalToBeMintAmount;
  }

  function withdrawUnMintToken(address to) external onlyOwner {
    uint256 unMintAmount = totalToBeMintAmount.sub(mintedAmount);
    mintedAmount = mintedAmount.add(unMintAmount);
    safeTokenTransfer(to, unMintAmount);
  }
}