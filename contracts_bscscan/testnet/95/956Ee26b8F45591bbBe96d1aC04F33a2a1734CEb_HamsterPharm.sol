/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a + b) >= b, "SafeMath: Add Overflow");
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a - b) <= a, "SafeMath: Underflow");
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b == 0 || (c = a * b) / b == a, "SafeMath: Mul Overflow");
  }

  function to128(uint256 a) internal pure returns (uint128 c) {
    require(a <= type(uint128).max, "SafeMath: uint128 Overflow");
    c = uint128(a);
  }

  function to64(uint256 a) internal pure returns (uint64 c) {
    require(a <= type(uint64).max, "SafeMath: uint64 Overflow");
    c = uint64(a);
  }

  function to32(uint256 a) internal pure returns (uint32 c) {
    require(a <= type(uint32).max, "SafeMath: uint32 Overflow");
    c = uint32(a);
  }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }
}

library SignedSafeMath {
  int256 constant private _INT256_MIN = -2**255;

  function mul(int256 a, int256 b) internal pure returns (int256) {
    if (a == 0) return 0;

    require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

    int256 c = a * b;
    require(c / a == b, "SignedSafeMath: multiplication overflow");

    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "SignedSafeMath: division by zero");
    require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

    int256 c = a / b;

    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  function toUInt256(int256 a) internal pure returns (uint256) {
    require(a >= 0, "Integer < 0");
    return uint256(a);
  }
}

interface IERC20 {
  function balanceOf(address _account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

contract HamsterPharm {
  using SafeMath for uint256;
  using SafeMath128 for uint128;
  using SignedSafeMath for int256;

  mapping(address => bool) public owners;

  // Struct
  struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
  }

  struct PoolInfo {
    uint128 accRewardPerShare;
    uint64 lastRewardBlock;
    uint256 totalEmission;
  }

  // Constant
  uint256 private constant REWARD_PER_BLOCK = 3500 * 1e6; // 3500 VACCINE per block
  uint256 private constant REWARD_EMISSION_LIMIT = 36500 * 1e6; // 36,500 VACCINE for the year
  uint256 private constant REWARD_PRECISION = 1e12;

  // Project Variables
  IERC20 public rewardToken;
  IERC20 public lpToken;

  mapping(address => UserInfo) public userInfo;
  PoolInfo public pool;

  // Events
  event Deposit(address indexed user, uint256 amount, address indexed to);
  event Withdraw(address indexed user, uint256 amount, address indexed to);
  event EmergencyWithdraw(address indexed user, uint256 amount, address indexed to);
  event Harvest(address indexed user, uint256 amount);
  event LogUpdatePool(uint64 lastRewardBlock, uint256 lpSupply, uint256 accSushiPerShare);

  // Modifiers
  modifier onlyOwner() {
    require(owners[msg.sender], "HamsterPharm: Token: No owner privilege");
    _;
  }

  constructor() {
    owners[msg.sender] = true;
    pool = PoolInfo({
      lastRewardBlock: block.number.to64(),
      accRewardPerShare: 0,
      totalEmission: 0
    });
  }

  // Admin
  function setOwner(address _owner) external onlyOwner returns (bool) {
    owners[_owner] = true;
    return true;
  }

  function removeOwner(address _owner) external onlyOwner returns (bool) {
    owners[_owner] = false;
    return true;
  }

  function init(address _rewardToken, address _lpToken) external returns (bool) {
    rewardToken = IERC20(_rewardToken);
    lpToken = IERC20(_lpToken);
    return true;
  }

  // View
  function pendingReward(address _user) external view returns (uint256 pending) {
    UserInfo storage user = userInfo[_user];
    uint256 accRewardPerShare = pool.accRewardPerShare;
    uint256 lpSupply = lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 blocks = block.number.sub(pool.lastRewardBlock);
      uint256 reward = blocks.mul(REWARD_PER_BLOCK);
      accRewardPerShare = accRewardPerShare.add(reward.mul(REWARD_PRECISION) / lpSupply);
    }
    pending = int256(user.amount.mul(accRewardPerShare) / REWARD_PRECISION).sub(user.rewardDebt).toUInt256();
  }

  // External
  function updatePool() public returns (bool) {
    if (block.number > pool.lastRewardBlock) {
      uint256 lpSupply = lpToken.balanceOf(address(this));
      if (lpSupply > 0) {
        uint256 blocks = block.number.sub(pool.lastRewardBlock);
        uint256 reward = blocks.mul(REWARD_PER_BLOCK);
        pool.totalEmission = pool.totalEmission.add(reward);
        if (pool.totalEmission.add(reward) <= REWARD_EMISSION_LIMIT) {
          pool.accRewardPerShare = pool.accRewardPerShare.add((reward.mul(REWARD_PRECISION) / lpSupply).to128());
        }
      }
      pool.lastRewardBlock = block.number.to64();
      emit LogUpdatePool(pool.lastRewardBlock, lpSupply, pool.accRewardPerShare);
    }
    return true;
  }

  function deposit(uint256 _amount, address _to) external payable returns (bool) {
    _deposit(_amount, msg.sender, _to);
    return true;
  }

  function withdraw(uint256 _amount, address _to) external returns (bool) {
    updatePool();
    UserInfo storage user = userInfo[msg.sender];

    // Effects
    user.rewardDebt = user.rewardDebt.sub(int256(_amount.mul(pool.accRewardPerShare) / REWARD_PRECISION));
    user.amount = user.amount.sub(_amount);

    // Interactions
    lpToken.transfer(_to, _amount);

    emit Withdraw(msg.sender, _amount, _to);
    
    return true;
  }

  function harvest(address _to) external {
    updatePool();
    UserInfo storage user = userInfo[msg.sender];
    int256 accumulatedReward = int256(user.amount.mul(pool.accRewardPerShare) / REWARD_PRECISION);
    uint256 _pendingReward = accumulatedReward.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedReward;

    // Interactions
    if (_pendingReward != 0) {
      rewardToken.transfer(_to, _pendingReward);
    }

    emit Harvest(msg.sender, _pendingReward);
  }

  function withdrawAndHarvest(uint256 _amount, address _to) external {
    updatePool();
    UserInfo storage user = userInfo[msg.sender];
    int256 accumulatedReward = int256(user.amount.mul(pool.accRewardPerShare) / REWARD_PRECISION);
    uint256 _pendingReward = accumulatedReward.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedReward.sub(int256(_amount.mul(pool.accRewardPerShare) / REWARD_PRECISION));
    user.amount = user.amount.sub(_amount);
        
    // Interactions
    rewardToken.transfer(_to, _pendingReward);
    lpToken.transfer(_to, _amount);

    emit Withdraw(msg.sender, _amount, _to);
    emit Harvest(msg.sender, _pendingReward);
  }

  function emergencyWithdraw(address _to) external {
    UserInfo storage user = userInfo[msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    lpToken.transfer(_to, amount);
    emit EmergencyWithdraw(msg.sender, amount, _to);
  }

  function adminWithdraw(address _token, address _to, uint256 _amount) external {
    IERC20 token = IERC20(_token);
    if(_amount > 0) {
      token.transfer(_to, _amount);
    } else {
      token.transfer(_to, token.balanceOf(address(this)));
    }
  }

  function _deposit(uint256 _amount, address _from, address _to) private returns (bool) {
    updatePool();
    UserInfo storage user = userInfo[_to];

    // Effects
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.rewardDebt.add(int256(_amount.mul(pool.accRewardPerShare) / REWARD_PRECISION));

    // Interactions
    if(_from != address(this)) lpToken.transferFrom(_from, address(this), _amount);

    emit Deposit(_from, _amount, _to);

    return true;
  }
}