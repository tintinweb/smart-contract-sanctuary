/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
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
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// Calling setTotalRewardPerBlock, addPool or setReward, pending rewards will be changed.
// Since all pools are likely to get accrued every hour or so, this is an acceptable deviation.
// Accruing all pools here may consume too much gas.
// up to the point of exceeding the gas limit if there are too many pools.

contract MasterPool is Ownable {

  struct UserInfo {
    uint amount;
    uint rewardDebt;
  }

  // Info of each pool.
  struct Pool {
    IERC20 lpToken;        // Address of LP token contract.
    uint points;      // How many allocation points assigned to this pool. RewardTokens to distribute per block.
    uint lastRewardBlock;  // Last block number that RewardTokens distribution occurs.
    uint accRewardTokenPerShare; // Accumulated RewardTokens per share, times 1e12. See below.
  }

  struct PoolPosition {
    uint pid;
    bool added; // To prevent duplicates.
  }

  IERC20 public rewardToken;
  uint public totalRewardPerBlock;

  // Info of each pool.
  Pool[] public pools;
  // Info of each user that stakes LP tokens.
  mapping (uint => mapping (address => UserInfo)) public userInfo;
  mapping (address => PoolPosition) public pidByToken;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint public totalPoints;

  event RewardRateUpdate(uint value);
  event Deposit(address indexed user, uint indexed pid, uint amount);
  event Withdraw(address indexed user, uint indexed pid, uint amount);
  event EmergencyWithdraw(address indexed user, uint indexed pid, uint amount);

  event PoolUpdate(
    address indexed lpToken,
    uint    indexed pid,
    uint            points
  );

  constructor(
    IERC20 _rewardToken,
    uint _totalRewardPerBlock
  ) {
    rewardToken = _rewardToken;
    totalRewardPerBlock = _totalRewardPerBlock;
  }

  function poolLength() external view returns (uint) {
    return pools.length;
  }

  // Pending rewards will be changed. See class comments.
  function addPool(address _lpToken, uint _points) external onlyOwner {

    require(pidByToken[_lpToken].added == false, "MasterPool: already added");

    totalPoints = totalPoints + _points;

    pools.push(Pool({
      lpToken: IERC20(_lpToken),
      points: _points,
      lastRewardBlock: block.number,
      accRewardTokenPerShare: 0
    }));

    uint pid = pools.length - 1;

    pidByToken[_lpToken] = PoolPosition({
      pid: pid,
      added: true
    });

    emit PoolUpdate(_lpToken, pid, _points);
  }

  // Pending rewards will be changed. See class comments.
  function setReward(uint _pid, uint _points) external onlyOwner {

    accruePool(_pid);

    totalPoints = totalPoints - pools[_pid].points + _points;
    pools[_pid].points = _points;

    emit PoolUpdate(address(pools[_pid].lpToken), _pid, _points);
  }

  // Pending rewards will be changed. See class comments.
  function setTotalRewardPerBlock(uint _value) external onlyOwner {
    totalRewardPerBlock = _value;
    emit RewardRateUpdate(_value);
  }

  // View function to see pending RewardTokens on frontend.
  function pendingRewards(uint _pid, address _user) external view returns (uint) {

    Pool storage pool = pools[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint accRewardTokenPerShare = pool.accRewardTokenPerShare;
    uint lpSupply = pool.lpToken.balanceOf(address(this));

    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint multiplier = block.number - pool.lastRewardBlock;
      uint rewardTokenReward = multiplier * totalRewardPerBlock * pool.points / totalPoints;
      accRewardTokenPerShare += rewardTokenReward * 1e12 / lpSupply;
    }

    return (user.amount * accRewardTokenPerShare / 1e12) - user.rewardDebt;
  }

  function accrueAllPools() public {
      uint length = pools.length;
      for (uint pid = 0; pid < length; ++pid) {
        accruePool(pid);
      }
  }

  // Update reward variables of the given pool to be up-to-date.
  function accruePool(uint _pid) public {
    Pool storage pool = pools[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint multiplier = block.number - pool.lastRewardBlock;
    uint rewardTokenReward = multiplier * totalRewardPerBlock * pool.points / totalPoints;
    pool.accRewardTokenPerShare += rewardTokenReward * 1e12 / lpSupply;
    pool.lastRewardBlock = block.number;
  }

  function deposit(uint _pid, uint _amount) external {
    Pool storage pool = pools[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    accruePool(_pid);

    if (user.amount > 0) {
      uint pending = (user.amount * pool.accRewardTokenPerShare / 1e12) - user.rewardDebt;
      _safeRewardTokenTransfer(msg.sender, pending);
    }

    pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
    user.amount += _amount;
    user.rewardDebt = user.amount * pool.accRewardTokenPerShare / 1e12;
    emit Deposit(msg.sender, _pid, _amount);
  }

  function withdraw(uint _pid, uint _amount) external {
    Pool storage pool = pools[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "MasterPool: user.amount >= _amount");
    accruePool(_pid);
    uint pending = (user.amount * pool.accRewardTokenPerShare / 1e12) - user.rewardDebt;
    _safeRewardTokenTransfer(msg.sender, pending);
    user.amount = user.amount - _amount;
    user.rewardDebt = user.amount * pool.accRewardTokenPerShare / 1e12;
    pool.lpToken.transfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  function emergencyWithdraw(uint _pid) external {
    Pool storage pool = pools[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.transfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // Allows to migrate rewards to a new staking contract.
  function migrateRewards(address _recipient, uint _amount) external onlyOwner {
    rewardToken.transfer(_recipient, _amount);
  }

  // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough RewardTokens.
  function _safeRewardTokenTransfer(address _to, uint _amount) internal {
    uint rewardTokenBal = rewardToken.balanceOf(address(this));
    if (_amount > rewardTokenBal) {
      rewardToken.transfer(_to, rewardTokenBal);
    } else {
      rewardToken.transfer(_to, _amount);
    }
  }
}