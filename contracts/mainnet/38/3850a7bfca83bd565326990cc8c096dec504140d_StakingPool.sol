/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity 0.4.25;

/**
 * token contract functions
*/
contract Ierc20 {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract Owned {
        address public owner;
        event OwnerChanges(address newOwner);
        
        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner external {
            require(newOwner != address(0), "New owner is the zero address");
            owner = newOwner;
            emit OwnerChanges(newOwner);
        }
}

contract StakingPool is Owned {
    using SafeMath for uint256;
    
    Ierc20 public tswap;
    Ierc20 public rewardToken;
    uint256 poolDuration;
    uint256 totalRewards;
    uint256 rewardsWithdrawn;
    uint256 poolStartTime;
    uint256 poolEndTime;
    uint256 totalStaked;
    // Represents a single stake for a user. A user may have multiple.
    struct Stake {
        uint256 amount;
        uint256 stakingTime;
        uint256 lastWithdrawTime;
    }
    mapping (address => Stake[]) public userStaking;
    
    // Represents total staking of an user
    struct UserTotals {
        uint256 totalStaking;
        uint256 totalStakingTIme;
    }
    mapping (address => UserTotals) public userTotalStaking;
    
    struct Ris3Rewards {
        uint256 totalWithdrawn;
        uint256 lastWithdrawTime;
    }
    mapping(address => Ris3Rewards) public userRewardInfo;
    
    event OwnerSetReward(uint256 amount);
    event Staked(address userAddress, uint256 amount);
    event StakingWithdrawal(address userAddress, uint256 amount);
    event RewardWithdrawal(address userAddress, uint256 amount);
    event PoolDurationChange(uint256 poolDuration);
    
    /**
     * Constrctor function
    */
    constructor() public {
        tswap = Ierc20(0xCC4304A31d09258b0029eA7FE63d032f52e44EFe);
        rewardToken = Ierc20(0xe047705117Eb07e712C3d684f5B18E74577e83aC);
        poolDuration = 720 hours;
    }
    
    //Set pool rewards
    function ownerSetPoolRewards(uint256 _rewardAmount) external onlyOwner {
        require(poolStartTime == 0, "Pool rewards already set");
        require(_rewardAmount > 0, "Cannot create pool with zero amount");
        
        //set total rewards value
        totalRewards = _rewardAmount;
        
        poolStartTime = now;
        poolEndTime = now + poolDuration;
        
        //transfer tokens to contract
        rewardToken.transferFrom(msg.sender, this, _rewardAmount);
        emit OwnerSetReward(_rewardAmount);
    }
    
    //Stake function for users to stake SWAP token
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        require(now < poolEndTime, "Staking pool is closed"); //staking pool is closed for staking
        
        //add value in staking
        userTotalStaking[msg.sender].totalStaking = userTotalStaking[msg.sender].totalStaking.add(amount);
        
        //add new stake
        Stake memory newStake = Stake(amount, now, 0);
        userStaking[msg.sender].push(newStake);
        
        //add to total staked
        totalStaked = totalStaked.add(amount);
        
        tswap.transferFrom(msg.sender, this, amount);
        emit Staked(msg.sender, amount);
    }
    
    //compute rewards
    function computeNewReward(uint256 _rewardAmount, uint256 _stakedAmount, uint256 _stakeTimeSec) private view returns (uint256 _reward) {
        uint256 rewardPerSecond = totalRewards.mul(1 ether);
        if (rewardPerSecond != 0 ) {
            rewardPerSecond = rewardPerSecond.div(poolDuration);
        }
        
        if (rewardPerSecond > 0) {
            uint256 rewardPerSecForEachTokenStaked = rewardPerSecond.div(totalStaked);
            uint256 userRewards = rewardPerSecForEachTokenStaked.mul(_stakedAmount).mul(_stakeTimeSec);
                    userRewards = userRewards.div(1 ether);
            
            return _rewardAmount.add(userRewards);
        } else {
            return 0;
        }
    }
    
    //calculate your rewards
    function calculateReward(address _userAddress) public view returns (uint256 _reward) {
        // all user stakes
        Stake[] storage accountStakes = userStaking[_userAddress];
        
        // Redeem from most recent stake and go backwards in time.
        uint256 rewardAmount = 0;
        uint256 i = accountStakes.length;
        while (i > 0) {
            Stake storage userStake = accountStakes[i - 1];
            uint256 stakeTimeSec;
            
            //check if current time is more than pool ending time
            if (now > poolEndTime) {
                stakeTimeSec = poolEndTime.sub(userStake.stakingTime);
                if(userStake.lastWithdrawTime != 0){
                    stakeTimeSec = poolEndTime.sub(userStake.lastWithdrawTime);
                }
            } else {
                stakeTimeSec = now.sub(userStake.stakingTime);
                if(userStake.lastWithdrawTime != 0){
                    stakeTimeSec = now.sub(userStake.lastWithdrawTime);
                }
            }
            
            // fully redeem a past stake
            rewardAmount = computeNewReward(rewardAmount, userStake.amount, stakeTimeSec);
            i--;
        }
        
        return rewardAmount;
    }
    
    //Withdraw staking and rewards
    function withdrawStaking(uint256 amount) external {
        require(amount > 0, "Amount can not be zero");
        require(userTotalStaking[msg.sender].totalStaking >= amount, "You are trying to withdaw more than your stake");
        
        // 1. User Accounting
        Stake[] storage accountStakes = userStaking[msg.sender];
        
        // Redeem from most recent stake and go backwards in time.
        uint256 sharesLeftToBurn = amount;
        uint256 rewardAmount = 0;
        while (sharesLeftToBurn > 0) {
            Stake storage lastStake = accountStakes[accountStakes.length - 1];
            uint256 stakeTimeSec;
            //check if current time is more than pool ending time
            if (now > poolEndTime) {
                stakeTimeSec = poolEndTime.sub(lastStake.stakingTime);
                if(lastStake.lastWithdrawTime != 0){
                    stakeTimeSec = poolEndTime.sub(lastStake.lastWithdrawTime);
                }
            } else {
                stakeTimeSec = now.sub(lastStake.stakingTime);
                if(lastStake.lastWithdrawTime != 0){
                    stakeTimeSec = now.sub(lastStake.lastWithdrawTime);
                }
            }
            
            if (lastStake.amount <= sharesLeftToBurn) {
                // fully redeem a past stake
                rewardAmount = computeNewReward(rewardAmount, lastStake.amount, stakeTimeSec);
                sharesLeftToBurn = sharesLeftToBurn.sub(lastStake.amount);
                accountStakes.length--;
            } else {
                // partially redeem a past stake
                rewardAmount = computeNewReward(rewardAmount, sharesLeftToBurn, stakeTimeSec);
                lastStake.amount = lastStake.amount.sub(sharesLeftToBurn);
                lastStake.lastWithdrawTime = now;
                sharesLeftToBurn = 0;
            }
        }
        
        //substract value in staking
        userTotalStaking[msg.sender].totalStaking = userTotalStaking[msg.sender].totalStaking.sub(amount);
        
        //substract from total staked
        totalStaked = totalStaked.sub(amount);
        
        //update user rewards info
        userRewardInfo[msg.sender].totalWithdrawn = userRewardInfo[msg.sender].totalWithdrawn.add(rewardAmount);
        userRewardInfo[msg.sender].lastWithdrawTime = now;
        
        //update total rewards withdrawn
        rewardsWithdrawn = rewardsWithdrawn.add(rewardAmount);
        
        //transfer rewards and tokens
        rewardToken.transfer(msg.sender, rewardAmount);
        tswap.transfer(msg.sender, amount);
        
        emit RewardWithdrawal(msg.sender, rewardAmount);
        emit StakingWithdrawal(msg.sender, amount);
    }
    
    //Withdraw rewards
    function withdrawRewardsOnly() external {
        uint256 _rwdAmount = calculateReward(msg.sender);
        require(_rwdAmount > 0, "You do not have enough rewards");
        
        // 1. User Accounting
        Stake[] storage accountStakes = userStaking[msg.sender];
        
        // Redeem from most recent stake and go backwards in time.
        uint256 rewardAmount = 0;
        uint256 i = accountStakes.length;
        while (i > 0) {
            Stake storage userStake = accountStakes[i - 1];
            uint256 stakeTimeSec;
            
            //check if current time is more than pool ending time
            if (now > poolEndTime) {
                stakeTimeSec = poolEndTime.sub(userStake.stakingTime);
                if(userStake.lastWithdrawTime != 0){
                    stakeTimeSec = poolEndTime.sub(userStake.lastWithdrawTime);
                }
            } else {
                stakeTimeSec = now.sub(userStake.stakingTime);
                if(userStake.lastWithdrawTime != 0){
                    stakeTimeSec = now.sub(userStake.lastWithdrawTime);
                }
            }
            
            // fully redeem a past stake
            rewardAmount = computeNewReward(rewardAmount, userStake.amount, stakeTimeSec);
            userStake.lastWithdrawTime = now;
            i--;
        }
        
        //update user rewards info
        userRewardInfo[msg.sender].totalWithdrawn = userRewardInfo[msg.sender].totalWithdrawn.add(rewardAmount);
        userRewardInfo[msg.sender].lastWithdrawTime = now;
        
        //update total rewards withdrawn
        rewardsWithdrawn = rewardsWithdrawn.add(rewardAmount);
        
        //transfer rewards
        rewardToken.transfer(msg.sender, rewardAmount);
        emit RewardWithdrawal(msg.sender, rewardAmount);
    }
    
    //get staking details by user address
    function getStakingAmount(address _userAddress) external constant returns (uint256 _stakedAmount) {
        return userTotalStaking[_userAddress].totalStaking;
    }
    
    //get total rewards collected by user
    function getTotalRewardCollectedByUser(address userAddress) view external returns (uint256 _totalRewardCollected) 
    {
        return userRewardInfo[userAddress].totalWithdrawn;
    }
    
    //get total SWAP token staked in the contract
    function getTotalStaked() external constant returns ( uint256 _totalStaked) {
        return totalStaked;
    }
    
    //get total rewards in the contract
    function getTotalRewards() external constant returns ( uint256 _totalRewards) {
        return totalRewards;
    }
    
    //get pool details
    function getPoolDetails() external view returns (address _baseToken, address _pairedToken, uint256 _totalRewards, uint256 _rewardsWithdrawn, uint256 _poolStartTime, uint256 _poolEndTime) {
        return (address(tswap),address(rewardToken),totalRewards,rewardsWithdrawn,poolStartTime,poolEndTime);
    }
    
    //get duration of pools
    function getPoolDuration() external constant returns (uint256 _poolDuration) {
        return poolDuration;
    }

    //set duration of pools by owner in seconds
    function setPoolDuration(uint256 _poolDuration) external onlyOwner {
        poolDuration = _poolDuration;
        poolEndTime = poolStartTime + _poolDuration;
        emit PoolDurationChange(_poolDuration);
    }
    
    //get SWAP token address
    function getSwapAddress() external constant returns (address _swapAddress) {
        return address(tswap);
    }
    
    //set tswap address
    function setTswapAddress(address _address) external onlyOwner {
        tswap = Ierc20(_address);
    }
    
    //set reward token address
    function setRewardTokenAddress(address _address) external onlyOwner {
        rewardToken = Ierc20(_address);
    }
    
}