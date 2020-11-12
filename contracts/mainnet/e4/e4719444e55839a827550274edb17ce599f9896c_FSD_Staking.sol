// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

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


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract FSD_Staking is Owned{
    
    using SafeMath for uint256;

    uint256 public totalRewards;
    uint256 public stakingRate = 100; // 100% APY
    uint256 public totalStakes;
    
    address public FSD = 0x94989cB638Eb46e04bb4bD12751d1E56bB9B57C1;
    
    struct DepositedToken{
        uint256 activeDeposit;
        uint256 totalDeposits;
        uint256 startTime;
        uint256 pendingGains;
        uint256 lastClaimedDate;
        uint256 totalGained;
    }
    
    mapping(address => DepositedToken) users;
    
    event StakeStarted(address indexed _staker, uint256 indexed _amount);
    event RewardsCollected(address indexed _staker, uint256 indexed _rewards);
    event StakingStopped(address indexed _staker, uint256 indexed _refunded);
    
    // ------------------------------------------------------------------------
    // Add tokens to stake
    // @param _amount amount of tokens to stake
    // ------------------------------------------------------------------------
    function Stake(uint256 _amount) external{
        require(_amount > 0, "amount of stake cannot be zero");
        
        // transfer tokens from user to the contract balance
        require(IERC20(FSD).transferFrom(msg.sender, address(this), _amount));
        
        uint256 fsdBurned = onePercent(_amount).mul(3); //3% of the staked amount is burned in transaction
        
        _amount = _amount.sub(fsdBurned);
        
        // add to stake
        _addToStake(_amount);
        
        emit StakeStarted(msg.sender, _amount);
    }
    
    // ------------------------------------------------------------------------
    // Withdraw accumulated rewards
    // ------------------------------------------------------------------------
    function ClaimReward() external {
        require(PendingReward(msg.sender) > 0, "No pending rewards");
        require(IERC20(FSD).balanceOf(address(this)) > totalStakes);
        uint256 _pendingReward = PendingReward(msg.sender);
        
        // Global stats update
        totalRewards = totalRewards.add(_pendingReward);
        
        // update the record
        users[msg.sender].totalGained = users[msg.sender].totalGained.add(_pendingReward);
        users[msg.sender].lastClaimedDate = now;
        users[msg.sender].pendingGains = 0;
        
        // mint more tokens inside token contract equivalent to _pendingReward
        require(IERC20(FSD).transfer(msg.sender, _pendingReward));
        
        uint256 fsdBurned = onePercent(_pendingReward).mul(3); //3% of the claimed amount is burned in transaction
        
        emit RewardsCollected(msg.sender, _pendingReward.sub(fsdBurned));
    }
    
    // ------------------------------------------------------------------------
    // This will stop the existing staking
    // ------------------------------------------------------------------------
    function StopStaking() external {
        require(users[msg.sender].activeDeposit >= 0, "No active stake");
        uint256 _activeDeposit = users[msg.sender].activeDeposit;
        
        // update staking stats
            // check if we have any pending rewards, add it to previousGains var
            users[msg.sender].pendingGains = PendingReward(msg.sender);
            // update amount 
            users[msg.sender].activeDeposit = 0;
            // reset last claimed figure as well
            users[msg.sender].lastClaimedDate = now;
        
        // withdraw the tokens and move from contract to the caller
        require(IERC20(FSD).transfer(msg.sender, _activeDeposit));
        
        emit StakingStopped(msg.sender, _activeDeposit);
    }
    
    
    
    //#########################################################################################################################################################//
    //##########################################################QUERIES################################################################################//
    //#########################################################################################################################################################//
    
    // ------------------------------------------------------------------------
    // Query to get the pending reward
    // @param _caller address of the staker
    // ------------------------------------------------------------------------
    function PendingReward(address _caller) public view returns(uint256 _pendingRewardWeis){
        uint256 _totalStakingTime = now.sub(users[_caller].lastClaimedDate);
        
        uint256 _reward_token_second = ((stakingRate).mul(10 ** 21)).div(365 days); // added extra 10^21
        
        uint256 reward = ((users[_caller].activeDeposit).mul(_totalStakingTime.mul(_reward_token_second))).div(10 ** 23); // remove extra 10^21 // 10^2 are for 100 (%)
        
        return reward.add(users[_caller].pendingGains);
    }
    
    // ------------------------------------------------------------------------
    // Query to get the active stake of the user
    // @param _user wallet address of the staker
    // ------------------------------------------------------------------------
    function ActiveStakeDeposit(address _user) external view returns(uint256 _activeDeposit){
        return users[_user].activeDeposit;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the total staking of the user
    // @param _user wallet address of the staker
    // ------------------------------------------------------------------------
    function YourTotalStakingTillToday(address _user) external view returns(uint256 _totalStaking){
        return users[_user].totalDeposits;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the time of last staking of user
    // ------------------------------------------------------------------------
    function LastStakedOn(address _user) external view returns(uint256 _unixLastStakedTime){
        return users[_user].startTime;
    }
    
    // ------------------------------------------------------------------------
    // Query to get total earned rewards
    // @param _user wallet address of the staker
    // ------------------------------------------------------------------------
    function TotalStakingRewards(address _user) external view returns(uint256 _totalEarned){
        return users[_user].totalGained;
    }
    
    // ------------------------------------------------------------------------
    // Internal function to add new deposit
    // ------------------------------------------------------------------------        
    function _addToStake(uint256 _amount) internal{
        
        // add that token into the contract balance
        // check if we have any pending reward, add it to pendingGains variable
        users[msg.sender].pendingGains = PendingReward(msg.sender);
            
        // update current deposited amount 
        users[msg.sender].activeDeposit = users[msg.sender].activeDeposit.add(_amount);
        users[msg.sender].totalDeposits = users[msg.sender].totalDeposits.add(_amount);
        users[msg.sender].startTime = now;
        users[msg.sender].lastClaimedDate = now;
        
        // update global stats
        totalStakes = totalStakes.add(_amount);
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
}