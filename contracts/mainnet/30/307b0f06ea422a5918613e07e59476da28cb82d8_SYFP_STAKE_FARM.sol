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

interface ISYFP{
   function transferFrom(address from, address to, uint256 tokens) external returns (bool success); 
   function transfer(address to, uint256 tokens) external returns (bool success);
   function mint(address to, uint256 _mint_amount) external;
}

contract SYFP_STAKE_FARM is Owned{
    
    using SafeMath for uint256;
    
    uint256 public yieldCollectionFee = 0.05 ether;
    uint256 public stakingPeriod = 2 weeks;
    uint256 public stakeClaimFee = 0.01 ether;
    uint256 public totalYield;
    uint256 public totalRewards;
    
    address public SYFP = 0xC11396e14990ebE98a09F8639a082C03Eb9dB55a;
    
    struct Tokens{
        bool exists;
        uint256 rate;
        uint256 stakedTokens;
    }
    
    mapping(address => Tokens) public tokens;
    address[] TokensAddresses;
    
    struct DepositedToken{
        uint256 activeDeposit;
        uint256 totalDeposits;
        uint256 startTime;
        uint256 pendingGains;
        uint256 lastClaimedDate;
        uint256 totalGained;
        uint    rate;
        uint    period;
    }
    
    mapping(address => mapping(address => DepositedToken)) users;
    
    event TokenAdded(address indexed tokenAddress, uint256 indexed APY);
    event TokenRemoved(address indexed tokenAddress, uint256 indexed APY);
    event FarmingRateChanged(address indexed tokenAddress, uint256 indexed newAPY);
    event YieldCollectionFeeChanged(uint256 indexed yieldCollectionFee);
    event FarmingStarted(address indexed _tokenAddress, uint256 indexed _amount);
    event YieldCollected(address indexed _tokenAddress, uint256 indexed _yield);
    event AddedToExistingFarm(address indexed _tokenAddress, uint256 indexed tokens);
    
    event Staked(address indexed staker, uint256 indexed tokens);
    event AddedToExistingStake(address indexed staker, uint256 indexed tokens);
    event StakingRateChanged(uint256 indexed newAPY);
    event TokensClaimed(address indexed claimer, uint256 indexed stakedTokens);
    event RewardClaimed(address indexed claimer, uint256 indexed reward);
    
    constructor() public {
        owner = 0xf64df26Fb32Ce9142393C31f01BB1689Ff7b29f5;
        // add syfp token to ecosystem
        _addToken(0xC11396e14990ebE98a09F8639a082C03Eb9dB55a, 4000000); //SYFP
        _addToken(0xdAC17F958D2ee523a2206206994597C13D831ec7, 14200); // USDT
        _addToken(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 14200); // USDC
        _addToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 5200000); // WETH
        _addToken(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e, 297300000); // YFI
        _addToken(0x45f24BaEef268BB6d63AEe5129015d69702BCDfa, 230000); // YFV
        _addToken(0x96d62cdCD1cc49cb6eE99c867CB8812bea86B9FA, 300000); // yfp
        
    }
    
    //#########################################################################################################################################################//
    //####################################################FARMING EXTERNAL FUNCTIONS###########################################################################//
    //#########################################################################################################################################################// 
    
    // ------------------------------------------------------------------------
    // Add assets to farm
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function Farm(address _tokenAddress, uint256 _amount) external{
        require(_tokenAddress != SYFP, "Use staking instead"); 
        
        // add to farm
        _newDeposit(_tokenAddress, _amount);
        
        // transfer tokens from user to the contract balance
        require(ISYFP(_tokenAddress).transferFrom(msg.sender, address(this), _amount));
        
        emit FarmingStarted(_tokenAddress, _amount);
    }
    
    // ------------------------------------------------------------------------
    // Add more deposits to already running farm
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function AddToFarm(address _tokenAddress, uint256 _amount) external{
        require(_tokenAddress != SYFP, "use staking instead");
        _addToExisting(_tokenAddress, _amount);
        
        // move the tokens from the caller to the contract address
        require(ISYFP(_tokenAddress).transferFrom(msg.sender,address(this), _amount));
        
        emit AddedToExistingFarm(_tokenAddress, _amount);
    }
    
    // ------------------------------------------------------------------------
    // Withdraw accumulated yield
    // @param _tokenAddress address of the token asset
    // @required must pay yield claim fee
    // ------------------------------------------------------------------------
    function Yield(address _tokenAddress) public payable {
        require(msg.value >= yieldCollectionFee, "should pay exact claim fee");
        require(PendingYield(_tokenAddress, msg.sender) > 0, "No pending yield");
        require(tokens[_tokenAddress].exists, "Token doesn't exist");
        require(_tokenAddress != SYFP, "use staking instead");
    
        uint256 _pendingYield = PendingYield(_tokenAddress, msg.sender);
        
        // Global stats update
        totalYield = totalYield.add(_pendingYield);
        
        // update the record
        users[msg.sender][_tokenAddress].totalGained = users[msg.sender][_tokenAddress].totalGained.add(_pendingYield);
        users[msg.sender][_tokenAddress].lastClaimedDate = now;
        users[msg.sender][_tokenAddress].pendingGains = 0;
        
        // transfer fee to the owner
        owner.transfer(msg.value);
        
        // mint more tokens inside token contract equivalent to _pendingYield
        ISYFP(SYFP).mint(msg.sender, _pendingYield);
        
        emit YieldCollected(_tokenAddress, _pendingYield);
    }
    
    // ------------------------------------------------------------------------
    // Withdraw any amount of tokens, the contract will update the farming 
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function WithdrawFarmedTokens(address _tokenAddress, uint256 _amount) public {
        require(users[msg.sender][_tokenAddress].activeDeposit >= _amount, "insufficient amount in farming");
        require(_tokenAddress != SYFP, "use withdraw of staking instead");
        
        // update farming stats
            // check if we have any pending yield, add it to previousYield var
            users[msg.sender][_tokenAddress].pendingGains = PendingYield(_tokenAddress, msg.sender);
            
            tokens[_tokenAddress].stakedTokens = tokens[_tokenAddress].stakedTokens.sub(_amount);
            
            // update amount 
            users[msg.sender][_tokenAddress].activeDeposit = users[msg.sender][_tokenAddress].activeDeposit.sub(_amount);
            // update farming start time -- new farming will begin from this time onwards
            users[msg.sender][_tokenAddress].startTime = now;
            // reset last claimed figure as well -- new farming will begin from this time onwards
            users[msg.sender][_tokenAddress].lastClaimedDate = now;
        
        // withdraw the tokens and move from contract to the caller
        require(ISYFP(_tokenAddress).transfer(msg.sender, _amount));
        
        emit TokensClaimed(msg.sender, _amount);
    }
    
    function yieldWithdraw(address _tokenAddress) external {
        Yield(_tokenAddress);
        WithdrawFarmedTokens(_tokenAddress, users[msg.sender][_tokenAddress].activeDeposit);
        
    }
    
    //#########################################################################################################################################################//
    //####################################################STAKING EXTERNAL FUNCTIONS###########################################################################//
    //#########################################################################################################################################################//    
    
    // ------------------------------------------------------------------------
    // Start staking
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function Stake(uint256 _amount) external {
        // add new stake
        _newDeposit(SYFP, _amount);
        
        // transfer tokens from user to the contract balance
        require(ISYFP(SYFP).transferFrom(msg.sender, address(this), _amount));
        
        emit Staked(msg.sender, _amount);
    }
    
    // ------------------------------------------------------------------------
    // Add more deposits to already running farm
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function AddToStake(uint256 _amount) external {
        require(now - users[msg.sender][SYFP].startTime < users[msg.sender][SYFP].period, "current staking expired");
        _addToExisting(SYFP, _amount);

        // move the tokens from the caller to the contract address
        require(ISYFP(SYFP).transferFrom(msg.sender,address(this), _amount));
        
        emit AddedToExistingStake(msg.sender, _amount);
    }
    
    // ------------------------------------------------------------------------
    // Claim reward and staked tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimStakedTokens() public {
        require(users[msg.sender][SYFP].activeDeposit > 0, "no running stake");
        require(users[msg.sender][SYFP].startTime.add(users[msg.sender][SYFP].period) < now, "not claimable before staking period");
        
        uint256 _currentDeposit = users[msg.sender][SYFP].activeDeposit;
        
        // check if we have any pending reward, add it to pendingGains var
        users[msg.sender][SYFP].pendingGains = PendingReward(msg.sender);
        
        tokens[SYFP].stakedTokens = tokens[SYFP].stakedTokens.sub(users[msg.sender][SYFP].activeDeposit);
        
        // update amount 
        users[msg.sender][SYFP].activeDeposit = 0;
        
        // transfer staked tokens
        require(ISYFP(SYFP).transfer(msg.sender, _currentDeposit));
        emit TokensClaimed(msg.sender, _currentDeposit);
        
        
    }
    
    function ClaimUnStake() external {
        ClaimReward();
        ClaimStakedTokens();
    }
    
    // ------------------------------------------------------------------------
    // Claim reward and staked tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimReward() public payable {
        require(msg.value >= stakeClaimFee, "should pay exact claim fee");
        require(PendingReward(msg.sender) > 0, "nothing pending to claim");
    
        uint256 _pendingReward = PendingReward(msg.sender);
        
        // add claimed reward to global stats
        totalRewards = totalRewards.add(_pendingReward);
        // add the reward to total claimed rewards
        users[msg.sender][SYFP].totalGained = users[msg.sender][SYFP].totalGained.add(_pendingReward);
        // update lastClaim amount
        users[msg.sender][SYFP].lastClaimedDate = now;
        // reset previous rewards
        users[msg.sender][SYFP].pendingGains = 0;
        
        // transfer the claim fee to the owner
        owner.transfer(msg.value);
        
        // mint more tokens inside token contract
        ISYFP(SYFP).mint(msg.sender, _pendingReward);
         
        emit RewardClaimed(msg.sender, _pendingReward);
    }
    
    //#########################################################################################################################################################//
    //##########################################################FARMING QUERIES################################################################################//
    //#########################################################################################################################################################//
    
    // ------------------------------------------------------------------------
    // Query to get the pending yield
    // @param _tokenAddress address of the token asset
    // ------------------------------------------------------------------------
    function PendingYield(address _tokenAddress, address _caller) public view returns(uint256 _pendingRewardWeis){
        uint256 _totalFarmingTime = now.sub(users[_caller][_tokenAddress].lastClaimedDate);
        
        uint256 _reward_token_second = ((tokens[_tokenAddress].rate).mul(10 ** 21)).div(365 days); // added extra 10^21
        
        uint256 yield = ((users[_caller][_tokenAddress].activeDeposit).mul(_totalFarmingTime.mul(_reward_token_second))).div(10 ** 27); // remove extra 10^21 // 10^2 are for 100 (%)
        
        return yield.add(users[_caller][_tokenAddress].pendingGains);
    }
    
    // ------------------------------------------------------------------------
    // Query to get the active farm of the user
    // @param farming asset/ token address
    // ------------------------------------------------------------------------
    function ActiveFarmDeposit(address _tokenAddress, address _user) external view returns(uint256 _activeDeposit){
        return users[_user][_tokenAddress].activeDeposit;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the total farming of the user
    // @param farming asset/ token address
    // ------------------------------------------------------------------------
    function YourTotalFarmingTillToday(address _tokenAddress, address _user) external view returns(uint256 _totalFarming){
        return users[_user][_tokenAddress].totalDeposits;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the time of last farming of user
    // ------------------------------------------------------------------------
    function LastFarmedOn(address _tokenAddress, address _user) external view returns(uint256 _unixLastFarmedTime){
        return users[_user][_tokenAddress].startTime;
    }
    
    // ------------------------------------------------------------------------
    // Query to get total earned rewards from particular farming
    // @param farming asset/ token address
    // ------------------------------------------------------------------------
    function TotalFarmingRewards(address _tokenAddress, address _user) external view returns(uint256 _totalEarned){
        return users[_user][_tokenAddress].totalGained;
    }
    
    //#########################################################################################################################################################//
    //####################################################FARMING ONLY OWNER FUNCTIONS#########################################################################//
    //#########################################################################################################################################################//
    
    // ------------------------------------------------------------------------
    // Add supported tokens
    // @param _tokenAddress address of the token asset
    // @param _farmingRate rate applied for farming yield to produce
    // @required only owner or governance contract
    // ------------------------------------------------------------------------    
    function AddToken(address _tokenAddress, uint256 _rate) public onlyOwner {
        _addToken(_tokenAddress, _rate);
    }
    
    // ------------------------------------------------------------------------
    // Remove tokens if no longer supported
    // @param _tokenAddress address of the token asset
    // @required only owner or governance contract
    // ------------------------------------------------------------------------  
    function RemoveToken(address _tokenAddress) public onlyOwner {
        
        require(tokens[_tokenAddress].exists, "token doesn't exist");
        
        tokens[_tokenAddress].exists = false;
        
        emit TokenRemoved(_tokenAddress, tokens[_tokenAddress].rate);
    }
    
    // ------------------------------------------------------------------------
    // Change farming rate of the supported token
    // @param _tokenAddress address of the token asset
    // @param _newFarmingRate new rate applied for farming yield to produce
    // @required only owner or governance contract
    // ------------------------------------------------------------------------  
    function ChangeFarmingRate(address _tokenAddress, uint256 _newFarmingRate) public onlyOwner{
        
        require(tokens[_tokenAddress].exists, "token doesn't exist");
        
        tokens[_tokenAddress].rate = _newFarmingRate;
        
        emit FarmingRateChanged(_tokenAddress, _newFarmingRate);
    }

    // ------------------------------------------------------------------------
    // Change Yield collection fee
    // @param _fee fee to claim the yield
    // @required only owner or governance contract
    // ------------------------------------------------------------------------     
    function SetYieldCollectionFee(uint256 _fee) public onlyOwner{
        yieldCollectionFee = _fee;
        emit YieldCollectionFeeChanged(_fee);
    }
    
    //#########################################################################################################################################################//
    //####################################################STAKING QUERIES######################################################################################//
    //#########################################################################################################################################################//
    
    // ------------------------------------------------------------------------
    // Query to get the pending reward
    // ------------------------------------------------------------------------
    function PendingReward(address _caller) public view returns(uint256 _pendingReward){
        uint256 _totalStakedTime = 0;
        uint256 expiryDate = (users[_caller][SYFP].period).add(users[_caller][SYFP].startTime);
        
        if(now < expiryDate)
            _totalStakedTime = now.sub(users[_caller][SYFP].lastClaimedDate);
        else{
            if(users[_caller][SYFP].lastClaimedDate >= expiryDate) // if claimed after expirydate already
                _totalStakedTime = 0;
            else
                _totalStakedTime = expiryDate.sub(users[_caller][SYFP].lastClaimedDate);
        }
            
        uint256 _reward_token_second = ((users[_caller][SYFP].rate).mul(10 ** 21)); // added extra 10^21
        uint256 reward =  ((users[_caller][SYFP].activeDeposit).mul(_totalStakedTime.mul(_reward_token_second))).div(10 ** 27); // remove extra 10^21 // the two extra 10^2 is for 100 (%) // another two extra 10^4 is for decimals to be allowed
        reward = reward.div(365 days);
        return (reward.add(users[_caller][SYFP].pendingGains));
    }
    
    // ------------------------------------------------------------------------
    // Query to get the active stake of the user
    // ------------------------------------------------------------------------
    function YourActiveStake(address _user) external view returns(uint256 _activeStake){
        return users[_user][SYFP].activeDeposit;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the total stakes of the user
    // ------------------------------------------------------------------------
    function YourTotalStakesTillToday(address _user) external view returns(uint256 _totalStakes){
        return users[_user][SYFP].totalDeposits;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the time of last stake of user
    // ------------------------------------------------------------------------
    function LastStakedOn(address _user) public view returns(uint256 _unixLastStakedTime){
        return users[_user][SYFP].startTime;
    }
    
    // ------------------------------------------------------------------------
    // Query to get total earned rewards from stake
    // ------------------------------------------------------------------------
    function TotalStakeRewardsClaimedTillToday(address _user) external view returns(uint256 _totalEarned){
        return users[_user][SYFP].totalGained;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking rate
    // ------------------------------------------------------------------------
    function LatestStakingRate() external view returns(uint256 APY){
        return tokens[SYFP].rate;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking rate you staked at
    // ------------------------------------------------------------------------
    function YourStakingRate(address _user) external view returns(uint256 _stakingRate){
        return users[_user][SYFP].rate;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking period you staked at
    // ------------------------------------------------------------------------
    function YourStakingPeriod(address _user) external view returns(uint256 _stakingPeriod){
        return users[_user][SYFP].period;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking time left
    // ------------------------------------------------------------------------
    function StakingTimeLeft(address _user) external view returns(uint256 _secsLeft){
        uint256 left = 0; 
        uint256 expiryDate = (users[_user][SYFP].period).add(LastStakedOn(_user));
        
        if(now < expiryDate)
            left = expiryDate.sub(now);
            
        return left;
    }
    
    //#########################################################################################################################################################//
    //####################################################STAKING ONLY OWNER FUNCTION##########################################################################//
    //#########################################################################################################################################################//
    
    // ------------------------------------------------------------------------
    // Change staking rate
    // @param _newStakingRate new rate applied for staking
    // @required only owner or governance contract
    // ------------------------------------------------------------------------  
    function ChangeStakingRate(uint256 _newStakingRate) public onlyOwner{
        
        tokens[SYFP].rate = _newStakingRate;
        
        emit StakingRateChanged(_newStakingRate);
    }
    
    // ------------------------------------------------------------------------
    // Change the staking period
    // @param _seconds number of seconds to stake (n days = n*24*60*60)
    // @required only callable by owner or governance contract
    // ------------------------------------------------------------------------
    function SetStakingPeriod(uint256 _seconds) public onlyOwner{
       stakingPeriod = _seconds;
    }
    
    // ------------------------------------------------------------------------
    // Change the staking claim fee
    // @param _fee claim fee in weis
    // @required only callable by owner or governance contract
    // ------------------------------------------------------------------------
    function SetClaimFee(uint256 _fee) public onlyOwner{
       stakeClaimFee = _fee;
    }
    
    //#########################################################################################################################################################//
    //################################################################COMMON UTILITIES#########################################################################//
    //#########################################################################################################################################################//    
    
    // ------------------------------------------------------------------------
    // Internal function to add new deposit
    // ------------------------------------------------------------------------        
    function _newDeposit(address _tokenAddress, uint256 _amount) internal{
        require(users[msg.sender][_tokenAddress].activeDeposit ==  0, "Already running");
        require(tokens[_tokenAddress].exists, "Token doesn't exist");
        
        // add that token into the contract balance
        // check if we have any pending reward/yield, add it to pendingGains variable
        if(_tokenAddress == SYFP){
            users[msg.sender][_tokenAddress].pendingGains = PendingReward(msg.sender);
            users[msg.sender][_tokenAddress].period = stakingPeriod;
            users[msg.sender][_tokenAddress].rate = tokens[_tokenAddress].rate; // rate for stakers will be fixed at time of staking
        }
        else
            users[msg.sender][_tokenAddress].pendingGains = PendingYield(_tokenAddress, msg.sender);
            
        users[msg.sender][_tokenAddress].activeDeposit = _amount;
        users[msg.sender][_tokenAddress].totalDeposits = users[msg.sender][_tokenAddress].totalDeposits.add(_amount);
        users[msg.sender][_tokenAddress].startTime = now;
        users[msg.sender][_tokenAddress].lastClaimedDate = now;
        tokens[_tokenAddress].stakedTokens = tokens[_tokenAddress].stakedTokens.add(_amount);
    }

    // ------------------------------------------------------------------------
    // Internal function to add to existing deposit
    // ------------------------------------------------------------------------        
    function _addToExisting(address _tokenAddress, uint256 _amount) internal{
        require(tokens[_tokenAddress].exists, "Token doesn't exist");
        // require(users[msg.sender][_tokenAddress].running, "no running farming/stake");
        require(users[msg.sender][_tokenAddress].activeDeposit > 0, "no running farming/stake");
        // update farming stats
            // check if we have any pending reward/yield, add it to pendingGains variable
            if(_tokenAddress == SYFP){
                users[msg.sender][_tokenAddress].pendingGains = PendingReward(msg.sender);
                users[msg.sender][_tokenAddress].period = stakingPeriod;
                users[msg.sender][_tokenAddress].rate = tokens[_tokenAddress].rate; // rate of only staking will be updated when more is added to stake
            }
            else
                users[msg.sender][_tokenAddress].pendingGains = PendingYield(_tokenAddress, msg.sender);
            // update current deposited amount 
            users[msg.sender][_tokenAddress].activeDeposit = users[msg.sender][_tokenAddress].activeDeposit.add(_amount);
            // update total deposits till today
            users[msg.sender][_tokenAddress].totalDeposits = users[msg.sender][_tokenAddress].totalDeposits.add(_amount);
            // update new deposit start time -- new stake/farming will begin from this time onwards
            users[msg.sender][_tokenAddress].startTime = now;
            // reset last claimed figure as well -- new stake/farming will begin from this time onwards
            users[msg.sender][_tokenAddress].lastClaimedDate = now;
            tokens[_tokenAddress].stakedTokens = tokens[_tokenAddress].stakedTokens.add(_amount);
            
            
    }

    // ------------------------------------------------------------------------
    // Internal function to add token
    // ------------------------------------------------------------------------     
    function _addToken(address _tokenAddress, uint256 _rate) internal{
        require(!tokens[_tokenAddress].exists, "token already exists");
        
        tokens[_tokenAddress] = Tokens({
            exists: true,
            rate: _rate,
            stakedTokens: 0
        });
        
        TokensAddresses.push(_tokenAddress);
        emit TokenAdded(_tokenAddress, _rate);
    }
}