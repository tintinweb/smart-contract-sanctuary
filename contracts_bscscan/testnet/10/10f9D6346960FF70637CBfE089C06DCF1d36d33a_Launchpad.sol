/**
 *Submitted for verification at BscScan.com on 2021-12-23
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
  function approve(address _spender, uint256 _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
  function transferAndFreeze(address _to, uint256 _amount) external returns (bool);
  function mint(address _to, uint256 _amount) external returns (bool);
}

interface IPancakeRouter {
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);
}

interface IPancakePair {
  function totalSupply() external view returns (uint256);
  function balanceOf(address _account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Launchpad {
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
  uint256 private constant REWARD_PER_BLOCK = 1e20;
  uint256 private constant REWARD_EMISSION_LIMIT = 30000000 * 1e18;
  uint256 private constant REWARD_PRECISION = 1e12;
  uint256 private constant BLOCKS_PER_YEAR = 365 days / 3;
  uint256 private constant MAX_INT = 2**256 - 1;

  // Project Variables
  IERC20 public wbnb;
  IERC20 public busd;
  IERC20 public bdx;
  IERC20 public badge;
  IPancakePair public bnbBusdPair;
  IPancakePair public badgeBnbPair;
  IPancakePair public lpToken;
  IPancakeRouter public pancakeRouter = IPancakeRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

  mapping(address => UserInfo) public userInfo;
  PoolInfo public pool;
  bool public poolLocked = true;
  uint256 public POOL_LIMIT = 180 * 1e18; // 180 BNB ($100,000)
  uint256 public SLIPPAGE = 10; // 10%

  // Events
  event Deposit(address indexed user, uint256 amount, address indexed to);
  event Withdraw(address indexed user, uint256 amount, address indexed to);
  event EmergencyWithdraw(address indexed user, uint256 amount, address indexed to);
  event Harvest(address indexed user, uint256 amount);
  event LogUpdatePool(uint64 lastRewardBlock, uint256 lpSupply, uint256 accSushiPerShare);
  event AddLiquidity(address from, address to, uint256 amountToken, uint256 amountETH, uint256 amountLpToken);
  event RemoveLiquidity(address from, address to, uint256 amountToken, uint256 amountETH, uint256 amountLpToken);

  // Modifiers
  modifier onlyOwner() {
    require(owners[msg.sender], "Launchpad: Token: No owner privilege");
    _;
  }

  modifier withdrawable() {
    require(!poolLocked, "Launchpad: locked");
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

  receive() external payable {
    // Do nothing
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

  function setTokens(address _badge, address _bdx, address _wbnb, address _busd) external onlyOwner returns (bool) {
    badge = IERC20(_badge);
    bdx = IERC20(_bdx);
    wbnb = IERC20(_wbnb);
    busd = IERC20(_busd);
    bdx.approve(address(pancakeRouter), MAX_INT);
    return true;
  }

  function setPairs(address _lpToken, address _bnbBusdPair, address _badgeBnbPair) external onlyOwner returns (bool) {
    lpToken = IPancakePair(_lpToken);
    bnbBusdPair = IPancakePair(_bnbBusdPair);
    badgeBnbPair = IPancakePair(_badgeBnbPair);
    return true;
  }

  function setPancakeRouter(address _pancakeRouter) external onlyOwner returns (bool) {
    pancakeRouter = IPancakeRouter(_pancakeRouter);
    return true;
  }

  function setPoolLocked(bool _poolLocked) external onlyOwner returns (bool) {
    poolLocked = _poolLocked;
    return true;
  }

  function setPoolLimit(uint256 _poolLimit) external onlyOwner returns (bool) {
    POOL_LIMIT = _poolLimit;
    return true;
  }

  // View
  function pendingReward(address _user) public view returns (uint256 pending) {
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

  function getPoolProgess() external view returns (uint256 progressBnb, uint256 maxBnb, uint256 progressUsd, uint256 maxUsd) {
    maxBnb = POOL_LIMIT;
    progressBnb = convertLpToBnb(lpToken.balanceOf(address(this)));
    maxUsd = convertBnbToUsd(maxBnb);
    progressUsd = convertBnbToUsd(progressBnb);
  }

  function getBonusProgess() external view returns (uint256 progress, uint256 max) {
    max = REWARD_EMISSION_LIMIT;
    progress = pool.totalEmission;
  }

  function getAssets(address _user) external view returns (
    uint256 badgeAsset,
    uint256 bdxAsset,
    uint256 bnbAsset,
    uint256 totalBnb,
    uint256 totalUsd,
    string memory status) {

    uint256 badgeBalance = badge.balanceOf(_user);
    uint256 bdxBalance = bdx.balanceOf(_user);
    uint256 bnbBalance = _user.balance;

    uint256 lpDeposit = userInfo[_user].amount;
    uint256 bnbDeposit = convertLpToBnb(lpDeposit) / 2;
    uint256 bdxDeposit = convertBnbToBdx(bnbDeposit);

    badgeAsset = badgeBalance + pendingReward(_user);
    bdxAsset = bdxBalance + bdxDeposit;
    bnbAsset = bnbBalance + bnbDeposit;

    totalBnb = convertBadgeToBnb(badgeAsset) + convertBdxToBnb(bdxAsset) + bnbAsset;
    totalUsd = convertBnbToUsd(totalBnb);

    status = poolLocked ? 'locked' : 'unlocked';
  }

  function getStats(address _user) external view returns (
    uint256 bnbBalance,
    uint256 bdxBalance,
    uint256 totalBonus,
    uint256 totalDepositBnb,
    uint256 totalEarningBnb,
    uint256 userDepositLp,
    uint256 userDepositUsd,
    uint256 userEarnedBadge,
    uint256 userEarnedUsd,
    string memory status) {

    bnbBalance = _user.balance;
    bdxBalance = bdx.balanceOf(_user);
    totalBonus = REWARD_EMISSION_LIMIT;

    uint256 lpSupply = lpToken.balanceOf(address(this));
    totalDepositBnb = convertLpToBnb(lpSupply);
    totalEarningBnb = convertBadgeToBnb(REWARD_PER_BLOCK * BLOCKS_PER_YEAR);

    userDepositLp = userInfo[_user].amount;
    userDepositUsd = convertBnbToUsd(convertLpToBnb(userDepositLp));
    userEarnedBadge = pendingReward(_user);
    userEarnedUsd = convertBnbToUsd(convertBadgeToBnb(userEarnedBadge));

    status = poolLocked ? 'locked' : 'unlocked';
  }

  // Conversion Utilities
  function convertBdxToBnb(uint256 _bdxAmount) public view returns (uint256 bnbAmount) {
    (uint112 reserve0, uint112 reserve1, ) = lpToken.getReserves();
    uint112 bdxReserve = address(bdx) < address(wbnb) ? reserve0 : reserve1;
    uint112 bnbReserve = address(bdx) < address(wbnb) ? reserve1 : reserve0;
    bnbAmount =  _bdxAmount * uint256(bnbReserve) / uint256(bdxReserve);
  }

  function convertBnbToBdx(uint256 _bnbAmount) public view returns (uint256 bdxAmount) {
    (uint112 reserve0, uint112 reserve1, ) = lpToken.getReserves();
    uint112 bdxReserve = address(bdx) < address(wbnb) ? reserve0 : reserve1;
    uint112 bnbReserve = address(bdx) < address(wbnb) ? reserve1 : reserve0;
    bdxAmount =  _bnbAmount * uint256(bdxReserve) / uint256(bnbReserve);
  }

  function convertBnbToUsd(uint256 _bnbAmount) public view returns (uint256 usdAmount) {
    (uint112 reserve0, uint112 reserve1, ) = bnbBusdPair.getReserves();
    uint112 busdReserve = address(busd) < address(wbnb) ? reserve0 : reserve1;
    uint112 wbnbReserve = address(busd) < address(wbnb) ? reserve1 : reserve0;
    usdAmount = _bnbAmount * busdReserve / wbnbReserve;
  }

  function convertUsdToBnb(uint256 _usdAmount) public view returns (uint256 bnbAmount) {
    (uint112 reserve0, uint112 reserve1, ) = bnbBusdPair.getReserves();
    uint112 busdReserve = address(busd) < address(wbnb) ? reserve0 : reserve1;
    uint112 wbnbReserve = address(busd) < address(wbnb) ? reserve1 : reserve0;
    bnbAmount = _usdAmount * wbnbReserve / busdReserve;
  }

  function convertBadgeToBnb(uint256 _badgeAmount) public view returns (uint256 bnbAmount) {
    (uint112 reserve0, uint112 reserve1, ) = badgeBnbPair.getReserves();
    uint112 badgeReserve = address(badge) < address(wbnb) ? reserve0 : reserve1;
    uint112 wbnbReserve = address(badge) < address(wbnb) ? reserve1 : reserve0;
    bnbAmount = _badgeAmount * wbnbReserve / badgeReserve;
  }

  function convertLpToBnb(uint256 _lpAmount) public view returns (uint256) {
    return address(lpToken).balance * _lpAmount * 2 / lpToken.totalSupply();
  }

  // External
  function updatePool() public returns (bool) {
    if (block.number > pool.lastRewardBlock) {
      uint256 lpSupply = lpToken.balanceOf(address(this));
      if (lpSupply > 0) {
        if (pool.totalEmission < REWARD_EMISSION_LIMIT) {
          uint256 blocks = block.number.sub(pool.lastRewardBlock);
          uint256 reward = blocks.mul(REWARD_PER_BLOCK);
          if (pool.totalEmission.add(reward) > REWARD_EMISSION_LIMIT) {
            reward = REWARD_EMISSION_LIMIT - pool.totalEmission;
          }
          pool.totalEmission = pool.totalEmission.add(reward);
          pool.accRewardPerShare = pool.accRewardPerShare.add((reward.mul(REWARD_PRECISION) / lpSupply).to128());
          pool.lastRewardBlock = block.number.to64();
        }
      }
      emit LogUpdatePool(pool.lastRewardBlock, lpSupply, pool.accRewardPerShare);
    }
    return true;
  }

  function deposit(uint256 _amount, address _to) external returns (bool) {
    uint256 pooledBnb = convertLpToBnb(lpToken.balanceOf(address(this))) / 2;
    uint256 amountBnb = convertLpToBnb(_amount) / 2;
    require(pooledBnb + amountBnb <= POOL_LIMIT, "Launchpad: exceeds pool limit");
    _deposit(_amount, msg.sender, _to);
    return true;
  }

 function addLiquidityAndDeposit() external payable returns (bool) {
    uint256 pooledBnb = convertLpToBnb(lpToken.balanceOf(address(this))) / 2;
    require(pooledBnb + msg.value <= POOL_LIMIT, "Launchpad: exceeds pool limit");

    uint256 bdxAmount = convertBnbToBdx(msg.value);
    uint256 bdxBalance = bdx.balanceOf(msg.sender);
    if(bdxBalance >= bdxAmount) {
      bdx.transferFrom(msg.sender, address(this), bdxAmount);
    } else {
      bdx.mint(address(this), bdxAmount - bdxBalance);
      if(bdxBalance > 0) bdx.transferFrom(msg.sender, address(this), bdxBalance);
    }

    // Add Liquidity
    // LpToken is sent to address(this)
    (uint amountBdx, uint amountBnb, uint liquidity) = pancakeRouter.addLiquidityETH{value:msg.value}(
      address(bdx),
      bdxAmount,
      bdxAmount * (100 - SLIPPAGE) / 100,
      msg.value * (100 - SLIPPAGE) / 100,
      address(this),
      block.timestamp + 1 hours);
    emit AddLiquidity(msg.sender, address(this), amountBdx, amountBnb, liquidity);

    // Refund
    if(bdxAmount > amountBdx) {
      bdx.transfer(msg.sender, bdxAmount - amountBdx);
    }

    // Deposit
    // _to is entitled for user.amount
    _deposit(liquidity, address(this), msg.sender);
    return true;
  }

  function harvest(address _to) external returns (bool) {
    updatePool();
    _harvest(msg.sender, _to);
    return true;
  }

  function withdraw(uint256 _amount, address _to) public withdrawable returns (bool) {
    updatePool();
    _withdraw(_amount, msg.sender, _to);
    return true;
  }

  function withdrawAndHarvest(uint256 _amount, address _to) external returns (bool) {
    updatePool();
    _harvest(msg.sender, _to);
    _withdraw(_amount, msg.sender, _to);
    return true;
  }

  function withdrawAndRemoveLiquidity(uint256 _amount, address _to) external withdrawable returns (bool) {
    _withdrawAndRemoveLiquidity(_amount, msg.sender, _to);
    return true;
  }

  function withdrawAndRemoveLiquidityByAdmin(address _from, address _to) external onlyOwner returns (bool) {
    _withdrawAndRemoveLiquidity(userInfo[_from].amount, _from, _to);
    return true;
  }

  function _withdrawAndRemoveLiquidity(uint256 _amount, address _from, address _to) private returns (bool) {
    require(_amount <= userInfo[_from].amount, "Launchpad: insufficient LP deposit");
    _harvest(_from, _to);

    (uint amountBdx, uint amountBnb) = pancakeRouter.removeLiquidityETH(
      address(bdx),
      _amount,
      0,
      0,
      _to,
      block.timestamp + 1 hours);

    emit RemoveLiquidity(address(this), _to, amountBdx, amountBnb, _amount);
    return true;
  }

  function emergencyWithdraw(address _to) external withdrawable returns (bool) {
    UserInfo storage user = userInfo[msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    lpToken.transfer(_to, amount);
    emit EmergencyWithdraw(msg.sender, amount, _to);
    return true;
  }

  function adminWithdraw(address _token, address _to, uint256 _amount) external onlyOwner returns (bool) {
    IERC20 token = IERC20(_token);
    if(_amount > 0) {
      token.transfer(_to, _amount);
    } else {
      token.transfer(_to, token.balanceOf(address(this)));
    }
    return true;
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

  function _harvest(address _from, address _to) private returns (bool) {
    UserInfo storage user = userInfo[_from];
    int256 accumulatedReward = int256(user.amount.mul(pool.accRewardPerShare) / REWARD_PRECISION);
    uint256 _pendingReward = accumulatedReward.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedReward;

    // Interactions
    if (_pendingReward != 0) {
      badge.transferAndFreeze(_to, _pendingReward);
    }

    emit Harvest(_from, _pendingReward);
    return true;
  }

  function _withdraw(uint256 _amount, address _from, address _to) private returns (bool) {
    UserInfo storage user = userInfo[_from];

    // Effects
    user.rewardDebt = user.rewardDebt.sub(int256(_amount.mul(pool.accRewardPerShare) / REWARD_PRECISION));
    user.amount = user.amount.sub(_amount);

    // Interactions
    lpToken.transfer(_to, _amount);

    emit Withdraw(_from, _amount, _to);
    return true;
  }
}