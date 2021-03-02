/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity 0.4.25;

/**
 * token contract functions
*/
contract IERC20 {
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

contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
}

contract lockToken is owned{
    using SafeMath for uint256;
    
    IERC20 public tswap = IERC20(0x8CfDaeb56Ebb87229d311109Cf02Be3aAE57eb3C);
    uint256 public poolId;
    uint256[] allPoolIds;
    uint256 totalStaked;
    
    //pool Item
    struct poolItem {
        address baseAddress;
        address tokenAddress;
        uint256 rewardAmount;
        uint256 rewardsWithdrawn;
        uint256 poolStartTime;
        uint256 poolEndTime;
    }
    mapping(uint256 => poolItem) public stakingPool;
    mapping (uint256 => mapping (address => uint256)) public usersStaking;
    struct ris3Rewards {
        uint256 totalWithdrawn;
        uint256 lastWithdrawTime;
    }
    mapping(uint256 => mapping (address => ris3Rewards)) public userRewardInfo;
    mapping (uint256 => uint256) public totalStakedByPoolId;
    
    event Staked(uint256 poolId, address userAddress, uint256 amount);
    event stakingWithdrawal(uint256 poolId, address userAddress, uint256 amount);
    event rewardWithdrawal(uint256 poolId, address userAddress, uint256 amount);
    
    /**
     * Constrctor function
    */
    constructor() public {
        
    }
    
    //Stake function for users to stake SWAP token
    function stake(uint256 _poolId, uint256 amount) public {
        require(amount > 0, "Cannot stake 0");
        require(now < stakingPool[_poolId].poolEndTime, "Staking pool is closed"); //staking pool is closed for staking
        
        //add value in staking
        usersStaking[_poolId][msg.sender] = usersStaking[_poolId][msg.sender].add(amount);
        
        //add to total staked
        totalStaked = totalStaked.add(amount);
        totalStakedByPoolId[_poolId] = totalStakedByPoolId[_poolId].add(amount);
        
        IERC20(tswap).transferFrom(msg.sender, this, amount);
        emit Staked(_poolId, msg.sender, amount);
    }
    
    //Withdraw staking
    function WithdrawStaking(uint256 _poolId, uint256 amount) public {
        require(amount > 0, "Amount can not be zero");
        require(usersStaking[_poolId][msg.sender] > 0, "No stake left on this pool for this address");
        require(now < stakingPool[_poolId].poolEndTime, "Staking pool is closed"); //staking pool is closed for staking
        
        //substract value in staking
        usersStaking[_poolId][msg.sender] = usersStaking[_poolId][msg.sender].sub(amount);
        
        //add to total staked
        totalStaked = totalStaked.sub(amount);
        totalStakedByPoolId[_poolId] = totalStakedByPoolId[_poolId].sub(amount);
        
        IERC20(tswap).transfer(msg.sender, amount);
        emit stakingWithdrawal(_poolId, msg.sender, amount);
    }
    
    //calculate reward testing function
    function calculateRewardTesting(uint256 _poolId, address _userAddress) public view returns (uint256 _percnt, uint256 _diff, uint256 _userRewardPerSecond) {
        
        uint256 tswapAmount = usersStaking[_poolId][_userAddress];
        uint256 percnt = tswapAmount.mul(100000000);
        if (percnt != 0 ) {
            percnt = percnt.div(totalStakedByPoolId[_poolId]);
        }
        
        uint256 diff = 0;
        uint256 totalRewards = getTotalRewardsByPoolId(_poolId);
        
        //Check if withdrawn before
        if (userRewardInfo[_poolId][_userAddress].lastWithdrawTime == 0) {
            //check for current time
            if (now < stakingPool[_poolId].poolEndTime) {
              diff = now - stakingPool[_poolId].poolStartTime;
            } else {
              diff = stakingPool[_poolId].poolEndTime - stakingPool[_poolId].poolStartTime;
            }
        } else {
            //check for current time
            if (now < stakingPool[_poolId].poolEndTime) {
              diff = now - userRewardInfo[_poolId][_userAddress].lastWithdrawTime;
            } else {
              diff = stakingPool[_poolId].poolEndTime - userRewardInfo[_poolId][_userAddress].lastWithdrawTime;
            }
        }
        
        uint256 userRewardPerSecond = totalRewards.div(30 days).mul(percnt).div(100000000);   
        return ( percnt, diff, userRewardPerSecond);
    }
    
    //calculate your rewards
    function calculateReward(uint256 _poolId, address _userAddress) public view returns (uint256 _reward) {
        uint256 tswapAmount = usersStaking[_poolId][_userAddress];
        uint256 percnt = tswapAmount.mul(100000000);
        if (percnt != 0 ) {
            percnt = percnt.div(totalStakedByPoolId[_poolId]);
        }
        
        uint256 diff = 0;
        uint256 totalRewards = getTotalRewardsByPoolId(_poolId);
        
        //rewards can be calculated after staking done only
        if (totalRewards == 0 || percnt == 0){
            return 0;
        } else {
            //Check if withdrawn before
            if (userRewardInfo[_poolId][_userAddress].lastWithdrawTime == 0) {
                //check for current time
                if (now < stakingPool[_poolId].poolEndTime) {
                  diff = now - stakingPool[_poolId].poolStartTime;
                } else {
                  diff = stakingPool[_poolId].poolEndTime - stakingPool[_poolId].poolStartTime;
                }
            } else {
                //check for current time
                if (now < stakingPool[_poolId].poolEndTime) {
                  diff = now - userRewardInfo[_poolId][_userAddress].lastWithdrawTime;
                } else {
                  diff = stakingPool[_poolId].poolEndTime - userRewardInfo[_poolId][_userAddress].lastWithdrawTime;
                }
            }
            
            uint256 userRewardPerSecond = totalRewards.div(30 days).mul(percnt).div(100000000);
            return userRewardPerSecond.mul(diff);
        }
    }
    
    //withdraw your reward by pool id 
    function withdrawRewards(uint256 _poolId) public {
        uint256 amount = calculateReward(_poolId, msg.sender);
        require(amount > 0, "No rewards for this address");
        
        userRewardInfo[_poolId][msg.sender].totalWithdrawn = userRewardInfo[_poolId][msg.sender].totalWithdrawn.add(amount);
        userRewardInfo[_poolId][msg.sender].lastWithdrawTime = now;
        
        //set total rewards withdrawn in pool
        stakingPool[_poolId].rewardsWithdrawn = stakingPool[_poolId].rewardsWithdrawn.add(amount);
        
        
        IERC20(tswap).transfer(msg.sender, amount);
        emit rewardWithdrawal(_poolId, msg.sender, amount);
    }
    
    //Create a pool
    function createPool(address _tokenAddress, uint256 _tokenAmount) public onlyOwner {
        require(_tokenAmount > 0, "Cannot create pool with zero amount");
        
        uint256 _id = ++poolId;
        stakingPool[_id].baseAddress = tswap;
        stakingPool[_id].tokenAddress = _tokenAddress;
        stakingPool[_id].rewardAmount = _tokenAmount;
        stakingPool[_id].poolEndTime = now + 30 days;
        
        //store pool id
        allPoolIds.push(_id);
        
        //transfer tokens to contract
        IERC20(_tokenAddress).transferFrom(msg.sender, this, _tokenAmount);
    }
    
    //get staking details by pool id and user address
    function getStakingAmountByPoolId(uint256 _id, address _userAddress) public view returns ( uint256 _stakedAmount) {
        return usersStaking[_id][_userAddress];
    }
    
    //get total rewards collected by user
    function getTotalRewardCollectedByUser(uint256 _poolId, address userAddress) view public returns (uint256 _totalRewardCollected) 
    {
        return userRewardInfo[_poolId][userAddress].totalWithdrawn;
    }
    
    //get total rewards by poolId
    function getTotalRewardsByPoolId(uint256 _poolId) public view returns ( uint256 _totalRewards) {
        return stakingPool[_poolId].rewardAmount;
    }
    
    //get total rewards withdrawn by poolId
    function getTotalRewardsWithdrawnInPool(uint256 _poolId) public view returns ( uint256 _totalWithdrawn) {
        return stakingPool[_poolId].rewardsWithdrawn;
    }
    
    //get total SWAP token staked in the contract
    function getTotalStaked() public view returns ( uint256 _totalStaked) {
        return totalStaked;
    }
    
    //get total SWAP token staked by pool id
    function getTotalStakedByPoolId(uint256 _poolId) public view returns ( uint256 _totalStaked) {
        return totalStakedByPoolId[_poolId];
    }
    
    //get pool details by id
    function getPoolDetailsById(uint256 _poolId) public view returns (address _baseAddress, address _tokenAddress, uint256 _tokenAmount, uint256 _rewardsWithdrawn, uint256 _poolStartTime, uint256 _poolEndTime) {
        return (stakingPool[_poolId].baseAddress,stakingPool[_poolId].tokenAddress,stakingPool[_poolId].rewardAmount,stakingPool[_poolId].rewardsWithdrawn,stakingPool[_poolId].poolStartTime,stakingPool[_poolId].poolEndTime);
    }
    
    //set tswap address
    function setTswapAddress(address _address) public onlyOwner {
        tswap = IERC20(_address);
    }
    
}