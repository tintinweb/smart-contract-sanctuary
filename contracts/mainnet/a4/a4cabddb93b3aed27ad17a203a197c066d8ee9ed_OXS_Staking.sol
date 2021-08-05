/**
 *Submitted for verification at Etherscan.io on 2020-12-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

// ----------------------------------------------------------------------------
// OXS Staking
// Symbol      : OXS
// Name        : OXSign
// Staking supply: 6,0000 (6 Thousand)
// Decimals    : 10
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

contract OXS_Staking is Owned{
    
    using SafeMath for uint256;

    uint256 public totalRewards;
    uint256 public stakingRate = 25; // .25%
    uint256 public totalStakes;
    
    address public OXS = 0xD48a38BAD734A7c491E98367321f7abE79BB19A2;
    
    struct DepositedToken{
        uint256 activeDeposit;
        uint256 totalDeposits;
        uint256 startTime;
        uint256 pendingGains;
        uint256 lastClaimedDate;
        uint256 totalGained;
    }
    
    mapping(address => DepositedToken) users;
    
    event StakeStarted(uint256 indexed _amount);
    event RewardsCollected(uint256 indexed _rewards);
    event AddedToExistingStake(uint256 indexed tokens);
    event StakingStopped(uint256 indexed _refunded);
    

    function Stake(uint256 _amount) external{
        
        // add to stake
        _newDeposit(_amount);
        
        // transfer tokens from user to the contract balance
        require(IERC20(OXS).transferFrom(msg.sender, address(this), _amount));
        
        emit StakeStarted(_amount);
    }
    

    function AddToStake(uint256 _amount) external{
        
        _addToExisting(_amount);
        
        // move the tokens from the caller to the contract address
        require(IERC20(OXS).transferFrom(msg.sender,address(this), _amount));
        
        emit AddedToExistingStake(_amount);
    }
    
 
    function ClaimReward() external {
        require(PendingReward(msg.sender) > 0, "No pending rewards");
    
        uint256 _pendingReward = PendingReward(msg.sender);
        
        // Global stats update
        totalRewards = totalRewards.add(_pendingReward);
        
        // update the record
        users[msg.sender].totalGained = users[msg.sender].totalGained.add(_pendingReward);
        users[msg.sender].lastClaimedDate = now;
        users[msg.sender].pendingGains = 0;
        
        // mint more tokens inside token contract equivalent to _pendingReward
        require(IERC20(OXS).transfer(msg.sender, _pendingReward));
        
        emit RewardsCollected(_pendingReward);
    }
    

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
        require(IERC20(OXS).transfer(msg.sender, _activeDeposit));
        
        emit StakingStopped(_activeDeposit);
    }

    function PendingReward(address _caller) public view returns(uint256 _pendingRewardWeis){
        uint256 _totalStakingTime = now.sub(users[_caller].lastClaimedDate);
        
        uint256 _reward_token_second = ((stakingRate).mul(10 ** 21)).div(365 days); // added extra 10^21
        
        uint256 reward = ((users[_caller].activeDeposit).mul(_totalStakingTime.mul(_reward_token_second))).div(10 ** 23); // remove extra 10^21 // 10^2 are for 100 (%)
        
        return reward.add(users[_caller].pendingGains);
    }
    

    function ActiveStakeDeposit(address _user) external view returns(uint256 _activeDeposit){
        return users[_user].activeDeposit;
    }

    function YourTotalStakingTillToday(address _user) external view returns(uint256 _totalStaking){
        return users[_user].totalDeposits;
    }
    

    function LastStakedOn(address _user) external view returns(uint256 _unixLastStakedTime){
        return users[_user].startTime;
    }
    

    function TotalStakingRewards(address _user) external view returns(uint256 _totalEarned){
        return users[_user].totalGained;
    }
 
    function _newDeposit(uint256 _amount) internal{
        require(users[msg.sender].activeDeposit ==  0, "Already running, use funtion add to stake");

        users[msg.sender].pendingGains = PendingReward(msg.sender);
            
        users[msg.sender].activeDeposit = _amount;
        users[msg.sender].totalDeposits = users[msg.sender].totalDeposits.add(_amount);
        users[msg.sender].startTime = now;
        users[msg.sender].lastClaimedDate = now;
        

        totalStakes = totalStakes.add(_amount);
    }

       
    function _addToExisting(uint256 _amount) internal{
        
        require(users[msg.sender].activeDeposit > 0, "no running farming/stake");

            users[msg.sender].pendingGains = PendingReward(msg.sender);

            users[msg.sender].activeDeposit = users[msg.sender].activeDeposit.add(_amount);

            users[msg.sender].totalDeposits = users[msg.sender].totalDeposits.add(_amount);

            users[msg.sender].startTime = now;

            users[msg.sender].lastClaimedDate = now;
            

        totalStakes = totalStakes.add(_amount);
    }
}