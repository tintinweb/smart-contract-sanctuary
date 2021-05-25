/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
  function initialize() external;
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract MasterPool is Ownable {

  struct UserInfo {
    uint amount;
    uint rewardDebt;
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken;        // Address of LP token contract.
    uint allocPoints;      // How many allocation points assigned to this pool. RewardTokens to distribute per block.
    uint lastRewardBlock;  // Last block number that RewardTokens distribution occurs.
    uint accRewardTokenPerShare; // Accumulated RewardTokens per share, times 1e12. See below.
  }

  struct PoolPosition {
    uint pid;
    bool added; // To prevent duplicates.
  }

  IERC20 public rewardToken;
  uint public rewardTokenPerBlock;

  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping (uint => mapping (address => UserInfo)) public userInfo;
  mapping (address => PoolPosition) public pidByToken;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint public totalAllocPoints;
  // The block number when RewardToken mining starts.
  uint public startBlock;

  event Deposit(address indexed user, uint indexed pid, uint amount);
  event Withdraw(address indexed user, uint indexed pid, uint amount);
  event EmergencyWithdraw(address indexed user, uint indexed pid, uint amount);

  event PoolUpdate(
    address indexed lpToken,
    uint    indexed pid,
    uint            allocPoints,
    bool    indexed withUpdate
  );

  constructor(
    IERC20 _rewardToken,
    uint _rewardTokenPerBlock,
    uint _startBlock
  ) {
    rewardToken = _rewardToken;
    rewardTokenPerBlock = _rewardTokenPerBlock;
    startBlock = _startBlock;
  }

  function poolLength() external view returns (uint) {
    return poolInfo.length;
  }

  // Add a new lp to the pool. Can only be called by the owner.
  function add(address _lpToken, uint _allocPoints, bool _withUpdate) public onlyOwner {

    require(pidByToken[_lpToken].added == false, "MasterPool: already added");

    if (_withUpdate) {
      massUpdatePools();
    }

    uint lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoints = totalAllocPoints + _allocPoints;
    poolInfo.push(PoolInfo({
      lpToken: IERC20(_lpToken),
      allocPoints: _allocPoints,
      lastRewardBlock: lastRewardBlock,
      accRewardTokenPerShare: 0
    }));

    pidByToken[_lpToken] = PoolPosition({
      pid: poolInfo.length - 1,
      added: true
    });

    emit PoolUpdate(_lpToken, poolInfo.length - 1, _allocPoints, _withUpdate);
  }

  // Update the given pool's RewardToken allocation point. Can only be called by the owner.
  function set(uint _pid, uint _allocPoints, bool _withUpdate) public onlyOwner {

    if (_withUpdate) {
      massUpdatePools();
    }

    totalAllocPoints = totalAllocPoints - poolInfo[_pid].allocPoints + _allocPoints;
    poolInfo[_pid].allocPoints = _allocPoints;

    emit PoolUpdate(address(poolInfo[_pid].lpToken), _pid, _allocPoints, _withUpdate);
  }

  // View function to see pending RewardTokens on frontend.
  function pendingRewards(uint _pid, address _user) external view returns (uint) {

    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint accRewardTokenPerShare = pool.accRewardTokenPerShare;
    uint lpSupply = pool.lpToken.balanceOf(address(this));

    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint multiplier = block.number - pool.lastRewardBlock;
      uint rewardTokenReward = multiplier * rewardTokenPerBlock * pool.allocPoints / totalAllocPoints;
      accRewardTokenPerShare += rewardTokenReward * 1e12 / lpSupply;
    }

    return (user.amount * accRewardTokenPerShare / 1e12) - user.rewardDebt;
  }

  // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
      uint length = poolInfo.length;
      for (uint pid = 0; pid < length; ++pid) {
        updatePool(pid);
      }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint multiplier = block.number - pool.lastRewardBlock;
    uint rewardTokenReward = multiplier * rewardTokenPerBlock * pool.allocPoints / totalAllocPoints;
    pool.accRewardTokenPerShare += rewardTokenReward * 1e12 / lpSupply;
    pool.lastRewardBlock = block.number;
  }

  function deposit(uint _pid, uint _amount) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);

    if (user.amount > 0) {
      uint pending = (user.amount * pool.accRewardTokenPerShare / 1e12) - user.rewardDebt;
      safeRewardTokenTransfer(msg.sender, pending);
    }

    pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
    user.amount += _amount;
    user.rewardDebt = user.amount * pool.accRewardTokenPerShare / 1e12;
    emit Deposit(msg.sender, _pid, _amount);
  }

  function withdraw(uint _pid, uint _amount) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "MasterPool: user.amount >= _amount");
    updatePool(_pid);
    uint pending = (user.amount * pool.accRewardTokenPerShare / 1e12) - user.rewardDebt;
    safeRewardTokenTransfer(msg.sender, pending);
    user.amount = user.amount - _amount;
    user.rewardDebt = user.amount * pool.accRewardTokenPerShare / 1e12;
    pool.lpToken.transfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  function emergencyWithdraw(uint _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.transfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // Allows to migrate rewards to a new staking contract.
  function migrateRewards(address _recipient, uint _amount) public onlyOwner {
    rewardToken.transfer(_recipient, _amount);
  }

  // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough RewardTokens.
  function safeRewardTokenTransfer(address _to, uint _amount) internal {
    uint rewardTokenBal = rewardToken.balanceOf(address(this));
    if (_amount > rewardTokenBal) {
      rewardToken.transfer(_to, rewardTokenBal);
    } else {
      rewardToken.transfer(_to, _amount);
    }
  }
}