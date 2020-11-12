// SPDX-License-Identifier: MIKIStaking
pragma solidity ^0.6.12;

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
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract MIKI_Staking is Owned{
    
    using SafeMath for uint256;
    
    uint256 public penaltyFee = 95; //95% penlaty fee applicable before lock up time 
    uint256 public totalRewards;
    uint256 public totalStakes;
    
    uint256 public firstYearRate = 30;
    uint256 public secondYearRate = 20;
    uint256 public afterSecondYearRate = 10;
    
    uint256 public firstYearStakingPeriod = 4 hours;
    uint256 public secondYearStakingPeriod = 2 hours;
    uint256 public afterSecondYearStakingPeriod = 1 hours;
    
    uint256 private contractStartDate;
    
    address constant MIKI = 0x0488a7b65e8A07Db4642A1cBe75434b4C4524026;
    
    struct DepositedToken{
        bool Exist;
        uint256 activeDeposit;
        uint256 totalDeposits;
        uint256 startTime;
        uint256 pendingGains;
        uint256 lastClaimedDate;
        uint256 totalGained;
        address referrer;
    }
    
    mapping(address => DepositedToken) users;
    
    event Staked(address staker, uint256 tokens);
    event AddedToExistingStake(uint256 tokens);
    event TokensClaimed(address claimer, uint256 stakedTokens);
    event RewardClaimed(address claimer, uint256 reward);

    
    //#########################################################################################################################################################//
    //####################################################STAKING EXTERNAL FUNCTIONS###########################################################################//
    //#########################################################################################################################################################//    
    
    constructor() public{
        contractStartDate = block.timestamp;
    }
    
    // ------------------------------------------------------------------------
    // Start staking
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function STAKE(uint256 _amount, address _referrerID) public {
        require(_referrerID == address(0) || users[_referrerID].Exist, "Invalid Referrer Id");
        require(_amount > 0, "Invalid amount");
        
        // add new stake
        _newDeposit(MIKI, _amount, _referrerID);
        
        // update referral reward
        _updateReferralReward(_amount, _referrerID);
        
        // transfer tokens from user to the contract balance
        require(ERC20Interface(MIKI).transferFrom(msg.sender, address(this), _amount));
        
        emit Staked(msg.sender, _amount);
        
    }
    
    // ------------------------------------------------------------------------
    // Claim reward and staked tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimStakedTokens() external {
        require(users[msg.sender].activeDeposit > 0, "no running stake");
        
        uint256 _penaltyFee = 0;
        
        if(users[msg.sender].startTime + latestStakingPeriod() > now){ // claiming before lock up time
            _penaltyFee = penaltyFee; 
        }
        
        uint256 toTransfer = users[msg.sender].activeDeposit.sub(_onePercent(users[msg.sender].activeDeposit).mul(_penaltyFee));
        
        // transfer staked tokens - apply 95% penalty and send back staked tokens
        require(ERC20Interface(MIKI).transfer(msg.sender, toTransfer));
        
        // check if we have any pending reward, add it to pendingGains var
        users[msg.sender].pendingGains = pendingReward(msg.sender);
        
        emit TokensClaimed(msg.sender, toTransfer);
        
        // update amount 
        users[msg.sender].activeDeposit = 0;
    }
    
    // ------------------------------------------------------------------------
    // Claim reward and staked tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimReward() public {
        require(pendingReward(msg.sender) > 0, "nothing pending to claim");
    
        // transfer the reward to the claimer
        require(ERC20Interface(MIKI).transfer(msg.sender, pendingReward(msg.sender))); 
        
        emit RewardClaimed(msg.sender, pendingReward(msg.sender));
        
        // add claimed reward to global stats
        totalRewards = totalRewards.add(pendingReward(msg.sender));
        
        // add the reward to total claimed rewards
        users[msg.sender].totalGained = users[msg.sender].totalGained.add(pendingReward(msg.sender));
        // update lastClaim amount
        users[msg.sender].lastClaimedDate = now;
        // reset previous rewards
        users[msg.sender].pendingGains = 0;
    }
    
    //#########################################################################################################################################################//
    //####################################################STAKING QUERIES######################################################################################//
    //#########################################################################################################################################################//
    
    // ------------------------------------------------------------------------
    // Query to get the pending reward
    // ------------------------------------------------------------------------
    function pendingReward(address _caller) public view returns(uint256 _pendingReward){
        uint256 _totalStakedTime = 0;
        uint256 expiryDate = (latestStakingPeriod()).add(users[_caller].startTime);
        
        if(now < expiryDate)
            _totalStakedTime = now.sub(users[_caller].lastClaimedDate);
        else{
            if(users[_caller].lastClaimedDate >= expiryDate) // if claimed after expirydate already
                _totalStakedTime = 0;
            else
                _totalStakedTime = expiryDate.sub(users[_caller].lastClaimedDate);
        }
            
        uint256 _reward_token_second = ((latestStakingRate()).mul(10 ** 21)).div(365 days); // added extra 10^21
        
        uint256 reward =  ((users[_caller].activeDeposit).mul(_totalStakedTime.mul(_reward_token_second))).div(10 ** 23); // remove extra 10^21 // the two extra 10^2 is for 100 (%)
        
        return (reward.add(users[_caller].pendingGains));
    }
    
    // ------------------------------------------------------------------------
    // Query to get the active stake of the user
    // ------------------------------------------------------------------------
    function yourActiveStake(address _user) public view returns(uint256 _activeStake){
        return users[_user].activeDeposit;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the total stakes of the user
    // ------------------------------------------------------------------------
    function yourTotalStakesTillToday(address _user) public view returns(uint256 _totalStakes){
        return users[_user].totalDeposits;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the time of last stake of user
    // ------------------------------------------------------------------------
    function StakedOn(address _user) public view returns(uint256 _unixLastStakedTime){
        return users[_user].startTime;
    }
    
    // ------------------------------------------------------------------------
    // Query to get total earned rewards from stake
    // ------------------------------------------------------------------------
    function totalStakeRewardsClaimedTillToday(address _user) public view returns(uint256 _totalEarned){
        return users[_user].totalGained;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking rate
    // ------------------------------------------------------------------------
    function latestStakingRate() public view returns(uint256 APY){
        uint256 yearOfContract = (((block.timestamp).sub(contractStartDate)).div(365 days)).add(1);
        uint256 rate;
        
        if(yearOfContract == 1)
            rate = firstYearRate;
            
        else if(yearOfContract == 2)
            rate = secondYearRate;
        else
            rate = afterSecondYearRate;
            
        return rate;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking period 
    // ------------------------------------------------------------------------
    function latestStakingPeriod() public view returns(uint256 Period){
        uint256 yearOfContract = (((block.timestamp).sub(contractStartDate)).div(365 days)).add(1);
        uint256 period;
        
        if(yearOfContract == 1)
            period = firstYearStakingPeriod;
            
        else if(yearOfContract == 2)
            period = secondYearStakingPeriod;
        else
            period = afterSecondYearStakingPeriod;
            
        return period;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking time left
    // ------------------------------------------------------------------------
    function stakingTimeLeft(address _user) public view returns(uint256 _secsLeft){
        if(users[_user].activeDeposit > 0){
            uint256 left = 0; 
            uint256 expiryDate = (latestStakingPeriod()).add(StakedOn(_user));
        
            if(now < expiryDate)
                left = expiryDate.sub(now);
            
            return left;
        } 
        else
            return 0;
    }
    
    //#########################################################################################################################################################//
    //################################################################COMMON UTILITIES#########################################################################//
    //#########################################################################################################################################################//    
    
    // ------------------------------------------------------------------------
    // Internal function to add new deposit
    // ------------------------------------------------------------------------        
    function _newDeposit(address _tokenAddress, uint256 _amount, address _referrerID) internal{
        require(users[msg.sender].activeDeposit ==  0, "Already running");
        require(_tokenAddress == MIKI, "Only MIKI tokens supported");
        
        // add that token into the contract balance
        // check if we have any pending reward, add it to pendingGains variable
        
        users[msg.sender].pendingGains = pendingReward(msg.sender);

        users[msg.sender].activeDeposit = _amount;
        users[msg.sender].totalDeposits = users[msg.sender].totalDeposits.add(_amount);
        users[msg.sender].startTime = now;
        users[msg.sender].lastClaimedDate = now;
        users[msg.sender].referrer = _referrerID;
        users[msg.sender].Exist = true;
        
        totalStakes = totalStakes.add(_amount);
        
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function _onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    // ------------------------------------------------------------------------
    // Updates the reward for referrer
    // ------------------------------------------------------------------------
    function _updateReferralReward(uint256 _amount, address _referrerID) private{
        users[_referrerID].pendingGains +=  _onePercent(_amount);
    }
}