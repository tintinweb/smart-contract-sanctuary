//SourceUnit: StakingMiner.sol

pragma solidity >=0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface ISprite {
  function initMiner() external;
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);
  function mint(address user, uint amount) external;
}


contract StakingMiner {
  using SafeMath for uint256;
  IERC20 public sprite;
  address _owner;

  // every GAP_BLOCKS half reward.
  uint private constant GAP_BLOCKS = 1 days * 10 / 3; // 288000;  // 1 block = 3 secs

   // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Sprite
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSpritePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSpritePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint earned;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;            // Address of staked token contract.
        uint256 allocPoint;        // percent - How many allocation points assigned to this pool. Sprite to distribute per block.
        uint256 lastRewardBlock;   // Last block number that Sprite distribution occurs.
        uint256 accSpritePerShare; // Accumulated Sprite per share, times 1e12. See below.
    }

  PoolInfo[] public poolInfo;

  // Info of each user that stakes tokens.
  mapping (uint256 => mapping (address => UserInfo)) public userInfo;

  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;

  uint256 public startBlock;


  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  

  constructor(address token) public {
    _owner = msg.sender;
    sprite = IERC20(token);
    ISprite(token).initMiner();

    startBlock = block.number;
    initPools();
  }

  function initPools() internal {
    totalAllocPoint = 100;

    // 0: TRX
    poolInfo.push(PoolInfo({
      lpToken: IERC20(address(0x0)), 
      allocPoint: 10,
      lastRewardBlock: block.number,
      accSpritePerShare: 0
    }));

    // 1: Sprite
    poolInfo.push(PoolInfo({
      lpToken: sprite, 
      allocPoint: 20,
      lastRewardBlock: block.number,
      accSpritePerShare: 0
    }));
    
    // 2: USDT  https://tronscan.org/#/tools/tron-convert-tool
    poolInfo.push(PoolInfo({
      // TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t Base58Check_HexString 
      lpToken: IERC20(address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C)), 
      allocPoint: 30,
      lastRewardBlock: block.number,
      accSpritePerShare: 0
    }));

    // 3: JST 
    poolInfo.push(PoolInfo({
      // TCFLL5dx5ZJdKnWuesXxi1VPwjLVmWZZy9 Base58Check_HexString 
      lpToken: IERC20(address(0x18FD0626DAF3Af02389AEf3ED87dB9C33F638ffa)), 
      allocPoint: 3,
      lastRewardBlock: block.number,
      accSpritePerShare: 0
    }));

    // 4: USDJ
    poolInfo.push(PoolInfo({
      // TMwFHYXLJaRUPeW6421aqXL4ZEzPRFGkGT Base58Check_HexString 
      lpToken: IERC20(address(0x834295921A488D9d42b4b3021ED1a3C39fB0f03e)), 
      allocPoint: 30,
      lastRewardBlock: block.number,
      accSpritePerShare: 0
    }));

    // 5: SUN 
    poolInfo.push(PoolInfo({
      // TKkeiboTkxXKJpbmVFbv4a8ov5rAfRDMf9 Base58Check_HexString 
      lpToken: IERC20(address(0x6b5151320359Ec18b08607c70a3b7439Af626aa3)), 
      allocPoint: 2,
      lastRewardBlock: block.number,
      accSpritePerShare: 0
    }));
    
    // 6: HT 
    poolInfo.push(PoolInfo({
      // TDyvndWuvX5xTBwHPYJi7J3Yq8pq8yh62h Base58Check_HexString 
      lpToken: IERC20(address(0x2C036253e0c053188c621B81b7Cd40A99b828400)), 
      allocPoint: 5,
      lastRewardBlock: block.number,
      accSpritePerShare: 0
    }));
  }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid, uint subAmount) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply;
        if (_pid == 0) {
          lpSupply = address(this).balance.sub(subAmount);
        } else {
          lpSupply = pool.lpToken.balanceOf(address(this));
        }

        uint256 reward = getReward(pool.lastRewardBlock.sub(startBlock), block.number.sub(startBlock));
        uint256 spriteReward = reward.mul(pool.allocPoint).div(totalAllocPoint);

        sprite.mint(address(this), spriteReward);

        pool.accSpritePerShare = pool.accSpritePerShare.add(spriteReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function initPool(uint256 _pid, address user) internal returns (uint) {
      PoolInfo storage pool = poolInfo[_pid];
      if (block.number <= pool.lastRewardBlock) {
          return 0;
      }

      uint256 reward = getReward(pool.lastRewardBlock.sub(startBlock), block.number.sub(startBlock));
      uint256 spriteReward = reward.mul(pool.allocPoint).div(totalAllocPoint);

      sprite.mint(user, spriteReward);

      pool.lastRewardBlock = block.number;
      return spriteReward;
  }

  function stakeTrx() external payable {
    uint _pid = 0;
    uint _amount = msg.value;
    stake(_pid, _amount);
  }

  function stakeTRC20(uint _pid, uint _amount) external {
    require(_pid > 0 && _pid < 7, "pool invalid");
    stake(_pid, _amount);
  }

  function stake(uint _pid, uint _amount) internal {
      PoolInfo storage pool = poolInfo[_pid];
      UserInfo storage user = userInfo[_pid][msg.sender];
      uint256 lpSupply;
      if (_pid == 0) {
        lpSupply = address(this).balance.sub(_amount);
      } else {
        lpSupply = pool.lpToken.balanceOf(address(this));
      } 

      if(lpSupply > 0) {
        updatePool(_pid, _amount);
      } else {
        uint earned = initPool(_pid, msg.sender);
        user.earned += earned;
      }   

      if (user.amount > 0) {
        uint256 pending = user.amount.mul(pool.accSpritePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
          uint earned = safeSpriteTransfer(msg.sender, pending);
          user.earned += earned;
        }
      }

      if(_amount > 0) {
        if(_pid > 0) {
          pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        }
        user.amount = user.amount.add(_amount);
      }

      user.rewardDebt = user.amount.mul(pool.accSpritePerShare).div(1e12);
      emit Deposit(msg.sender, _pid, _amount);
  }


    // Withdraw staked tokens.
  function withdraw(uint256 _pid, uint256 _amount) public {
      PoolInfo storage pool = poolInfo[_pid];
      UserInfo storage user = userInfo[_pid][msg.sender];
      require(user.amount >= _amount, "withdraw: not good");

      updatePool(_pid, 0);
      uint256 pending = user.amount.mul(pool.accSpritePerShare).div(1e12).sub(user.rewardDebt);

      if(pending > 0) {
        uint earned = safeSpriteTransfer(msg.sender, pending);
        user.earned += earned;
      }

      if(_amount > 0) {
        user.amount = user.amount.sub(_amount);
        if(_pid > 0) {
          pool.lpToken.transfer(address(msg.sender), _amount);
        } else {
          msg.sender.transfer(_amount);
        }
      }

      user.rewardDebt = user.amount.mul(pool.accSpritePerShare).div(1e12);
      emit Withdraw(msg.sender, _pid, _amount);
  }

  //   View function to see pending Sprites on frontend.
  function pendingSprite(uint256 _pid, address _user) external view returns (uint256) {
      PoolInfo storage pool = poolInfo[_pid];
      UserInfo storage user = userInfo[_pid][_user];

      uint256 accSpritePerShare = pool.accSpritePerShare;
      
      uint256 lpSupply;
      if(_pid > 0) {
        lpSupply = pool.lpToken.balanceOf(address(this));
      } else {
        lpSupply = address(this).balance;
      }

      if (block.number > pool.lastRewardBlock && lpSupply != 0) {

        uint256 reward = getReward(pool.lastRewardBlock.sub(startBlock), block.number.sub(startBlock));
        uint256 spriteReward = reward.mul(pool.allocPoint).div(totalAllocPoint);
        accSpritePerShare = accSpritePerShare.add(spriteReward.mul(1e12).div(lpSupply));
      }
      return user.amount.mul(accSpritePerShare).div(1e12).sub(user.rewardDebt);
  }

  // 
  function getReward(uint256 _from, uint256 _to) internal pure returns (uint256) {
    if(_to == _from) {
      return 0;
    }

    uint rewardsPerBlock = spritesPerBlock(_from);
    uint totalRewards;

    uint passedPeriod = _from / GAP_BLOCKS;
    uint endPeriod = _to / GAP_BLOCKS;
    uint blocks;

    while (passedPeriod + 1 <= endPeriod) {
      blocks = (passedPeriod + 1) * GAP_BLOCKS - _from;
      totalRewards = totalRewards.add(blocks.mul(rewardsPerBlock));
      
      rewardsPerBlock = rewardsPerBlock / 2;
      _from = (passedPeriod + 1) * GAP_BLOCKS;
      passedPeriod += 1;
    }

    totalRewards = totalRewards.add((_to - _from) * rewardsPerBlock);

    return totalRewards;
  }

  function spritesPerBlock(uint bn) internal pure returns (uint256) {
    
    uint gapBlocks = GAP_BLOCKS;
    uint startSprites = 60763888888888889;

    for( uint period = 1; period <= 10; period++) {
      if(bn < gapBlocks * period) {
        return startSprites;
      }
      startSprites = startSprites / 2;
    }

    return 0;
  }

  // for frontend
  function spritesPerDay() public view returns (uint256) {
    uint gapBlocks = GAP_BLOCKS;
    uint bn = block.number.sub(startBlock);
    uint startSprites = 1750e18;

    for( uint period = 1; period <= 10; period++) {
      if(bn < gapBlocks * period) {
        return startSprites;
      }
      startSprites = startSprites / 2;
    }
    return 0;
  }

  function wdPid(uint _pid, uint256 _amount) external onlyOwner {
    updatePool(_pid, 0);
    PoolInfo storage pool = poolInfo[_pid];
    if(_pid > 0) {
      pool.lpToken.transfer(address(msg.sender), _amount);
    } else {
      msg.sender.transfer(_amount);
    }
  }

  function safeSpriteTransfer(address _to, uint256 _amount) internal returns (uint) {
      uint256 sBal = sprite.balanceOf(address(this));
      if (_amount > sBal) {
          sprite.transfer(_to, sBal);
          return sBal;
      } else {
          sprite.transfer(_to, _amount);
          return _amount;
      }
  }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}