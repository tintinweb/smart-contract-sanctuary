///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////################################################################/////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////THIS IS THE RPEPEBLU POOL OF KEK STAKING - rPepe Token Staking//////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////################################################################/////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: UNLICENSED

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

interface IKEK{
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function claimRewards(uint256 rewards, address rewardedTo) external returns(bool);
    function stakingRewardsAvailable() external view returns(uint256 _rewardsAvailable);
}

pragma solidity ^0.6.0;
contract rPepeToKEK {
    using SafeMath for uint256;
    
    uint256 public currentStakingRate;
    address public KEK = 0x31AEe7Db3b390bAaD34213C173A9df0dd11D84bd;
    address public RPepe = 0x0e9b56D2233ea2b5883861754435f9C51Dbca141;
    
    uint256 public totalRewards;
    uint256 private basePercent = 100;
    
    struct DepositedToken{
        uint256 activeDeposit;
        uint256 totalDeposits;
        uint256 startTime;
        uint256 pendingGains;
        uint256 lastClaimedDate;
        uint256 totalGained;
        uint    rate;
    }
    
    mapping(address => DepositedToken) users;
    
    event Staked(address indexed staker, uint256 indexed tokens);
    event StakingRateChanged(uint256 indexed stakingRatePerHour);
    event TokensClaimed(address indexed claimer, uint256 indexed stakedTokens);
    event RewardClaimed(address indexed claimer, uint256 indexed reward);
    
    constructor() public{
        currentStakingRate = 1e16; // 0.01 per hour
    }
    
    // ------------------------------------------------------------------------
    // Start staking
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function Stake(uint256 _amount) external {
        
        // transfer tokens from user to the contract balance
        require(IKEK(RPepe).transferFrom(msg.sender, address(this), _amount));
        
        uint256 tokensBurned = findTwoPointFivePercent(_amount);
        uint256 tokensTransferred = _amount.sub(tokensBurned);
    
        // add new stake
        _addToStake(tokensTransferred);
        
        emit Staked(msg.sender, _amount);
        
    }
    
    // ------------------------------------------------------------------------
    // Claim reward and staked tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimStakedTokens() public {
        require(users[msg.sender].activeDeposit > 0, "no running stake");
        
        uint256 _currentDeposit = users[msg.sender].activeDeposit;
        
        // check if we have any pending reward, add it to pendingGains var
        users[msg.sender].pendingGains = PendingReward(msg.sender);
        // update amount 
        users[msg.sender].activeDeposit = 0;
        
        // transfer staked tokens
        require(IKEK(RPepe).transfer(msg.sender, _currentDeposit));
        
        emit TokensClaimed(msg.sender, _currentDeposit);
        
    }
    
    // ------------------------------------------------------------------------
    // Claim reward and staked tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimReward() public {
        require(PendingReward(msg.sender) > 0, "nothing pending to claim");
    
        uint256 _pendingReward = PendingReward(msg.sender);
        
        // add claimed reward to global stats
        totalRewards = totalRewards.add(_pendingReward);
        // add the reward to total claimed rewards
        users[msg.sender].totalGained = users[msg.sender].totalGained.add(_pendingReward);
        // update lastClaim amount
        users[msg.sender].lastClaimedDate = now;
        // reset previous rewards
        users[msg.sender].pendingGains = 0;
        
        // send tokens from KEK to the user
        require(IKEK(KEK).claimRewards(_pendingReward, msg.sender));
        
        _updateStakingRate();
        // update staking rate
        users[msg.sender].rate = currentStakingRate;
        
        emit RewardClaimed(msg.sender, _pendingReward);
    }
    
    function Exit() external{
        if(PendingReward(msg.sender) > 0)
            ClaimReward();
        if(users[msg.sender].activeDeposit > 0)
            ClaimStakedTokens();
    }
    
    // ------------------------------------------------------------------------
    // Private function to update the staking rate
    // ------------------------------------------------------------------------
    function _updateStakingRate() private{
        uint256 originalRewards = 49000000 * 10 ** 18;
        
        // check the current volume of the rewards
        uint256 rewardsAvailable = IKEK(KEK).stakingRewardsAvailable();
        uint256 rewardsRemoved = originalRewards.sub(rewardsAvailable);
        
        if(rewardsRemoved >= 12250000 * 10 ** 18 && rewardsRemoved < 24500000 * 10 ** 18) { // less than 25% but greater than 50%
            currentStakingRate =  5e15; // 0.005 per hour
        }
        else if(rewardsRemoved >= 24500000 * 10 ** 18 && rewardsRemoved < 34300000 * 10 ** 18){ // less than equal to 50% but greater than 70%
            currentStakingRate = 2e15; // 0.002 per hour
        }
        else if(rewardsRemoved >= 34300000 * 10 ** 18 && rewardsRemoved < 44100000 * 10 ** 18){ // less than equal to 70% but greater than 90%
            currentStakingRate = 1e15; // 0.001 per hour
        }
        else if(rewardsRemoved >= 44100000 * 10 ** 18) {
            currentStakingRate = 5e14; // 0.0005 per hour
        }
    }
    
    // ------------------------------------------------------------------------
    // Query to get the pending reward
    // ------------------------------------------------------------------------
    function PendingReward(address _caller) public view returns(uint256 _pendingReward){
        uint256 _totalStakedTime = (now.sub(users[_caller].lastClaimedDate)).div(1 hours); // in hours
        
        uint256 reward = ((users[_caller].activeDeposit).mul(_totalStakedTime.mul(users[_caller].rate)));
        reward = reward.div(10 ** 18);
        return reward.add(users[_caller].pendingGains);
    }
    
    // ------------------------------------------------------------------------
    // Query to get the active stake of the user
    // ------------------------------------------------------------------------
    function YourActiveStake(address _user) external view returns(uint256 _activeStake){
        return users[_user].activeDeposit;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the total stakes of the user
    // ------------------------------------------------------------------------
    function YourTotalStakes(address _user) external view returns(uint256 _totalStakes){
        return users[_user].totalDeposits;
    }
    
    // ------------------------------------------------------------------------
    // Query to get total earned rewards from stake
    // ------------------------------------------------------------------------
    function TotalStakeRewardsClaimed(address _user) external view returns(uint256 _totalEarned){
        return users[_user].totalGained;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking rate you staked at
    // ------------------------------------------------------------------------
    function YourStakingRate(address _user) external view returns(uint256 _stakingRate){
        return users[_user].rate;
    }
    
    // ------------------------------------------------------------------------
    // Internal function to add new deposit
    // ------------------------------------------------------------------------        
    function _addToStake(uint256 _amount) internal{
        _updateStakingRate();
        
        // check if we have any pending reward, add it to pendingGains variable
        users[msg.sender].pendingGains = PendingReward(msg.sender);
        users[msg.sender].rate = currentStakingRate; // rate for stakers will be fixed at time of staking
            
        users[msg.sender].activeDeposit = _amount;
        users[msg.sender].totalDeposits = users[msg.sender].totalDeposits.add(_amount);
        users[msg.sender].startTime = now;
        users[msg.sender].lastClaimedDate = now;
        
    }
    
    //// utility function from RPepe
    function findTwoPointFivePercent(uint256 value) public view returns (uint256)  {
        uint256 roundValue = value.ceil(basePercent);
        uint256 twoPointFivePercent = roundValue.mul(basePercent).div(4000);
        return twoPointFivePercent;
    }
}