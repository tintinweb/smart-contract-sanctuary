// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./Owned.sol";
import "./BREE.sol";
import "./ERC20contract.sol";
import "./SafeMath.sol";

contract BREE_STAKE_FARM is Owned{
    
    using SafeMath for uint256;
    
    uint256 public yieldCollectionFee = 0.01 ether;
    uint256 public stakingPeriod = 30 days;
    uint256 public stakeClaimFee = 0.001 ether;
    uint256 public minStakeLimit = 500 * 10 **(18); //500 BREE
    uint256 public totalYield;
    uint256 public totalRewards;
    
    Token public bree;
    
    struct Tokens{
        bool exists;
        uint256 rate;
    }
    
    mapping(address => Tokens) public tokens;
    address[] TokensAddresses;
    address governance;
    
    struct DepositedToken{
        bool    whitelisted;
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
    
    event GovernanceSet(address indexed governanceAddress);
    
    modifier validStake(uint256 stakeAmount){
        require(stakeAmount >= minStakeLimit, "stake amount should be equal/greater than min stake limit");
        _;
    }
    
    modifier OwnerOrGovernance(address _caller){
        require(_caller == owner || _caller == governance);
        _;
    }
    
    constructor(address _tokenAddress) public {
        bree = Token(_tokenAddress);
        
        // add bree token to ecosystem
        _addToken(_tokenAddress, 40); // 40 apy initially
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
        require(_tokenAddress != address(bree), "Use staking instead"); 
        
        // add to farm
        _newDeposit(_tokenAddress, _amount);
        
        // transfer tokens from user to the contract balance
        require(ERC20Interface(_tokenAddress).transferFrom(msg.sender, address(this), _amount));
        
        emit FarmingStarted(_tokenAddress, _amount);
    }
    
    // ------------------------------------------------------------------------
    // Add more deposits to already running farm
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function AddToFarm(address _tokenAddress, uint256 _amount) external{
        require(_tokenAddress != address(bree), "use staking instead");
        _addToExisting(_tokenAddress, _amount);
        
        // move the tokens from the caller to the contract address
        require(ERC20Interface(_tokenAddress).transferFrom(msg.sender,address(this), _amount));
        
        emit AddedToExistingFarm(_tokenAddress, _amount);
    }
    
    // ------------------------------------------------------------------------
    // Withdraw accumulated yield
    // @param _tokenAddress address of the token asset
    // @required must pay yield claim fee
    // ------------------------------------------------------------------------
    function Yield(address _tokenAddress) external payable {
        require(msg.value >= yieldCollectionFee, "should pay exact claim fee");
        require(PendingYield(_tokenAddress, msg.sender) > 0, "No pending yield");
        require(tokens[_tokenAddress].exists, "Token doesn't exist");
        require(_tokenAddress != address(bree), "use staking instead");
    
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
        require(bree.MintTokens(_pendingYield, msg.sender));
        
        emit YieldCollected(_tokenAddress, _pendingYield);
    }
    
    // ------------------------------------------------------------------------
    // Withdraw any amount of tokens, the contract will update the farming 
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function WithdrawFarmedTokens(address _tokenAddress, uint256 _amount) external {
        require(users[msg.sender][_tokenAddress].activeDeposit >= _amount, "insufficient amount in farming");
        require(_tokenAddress != address(bree), "use withdraw of staking instead");
        
        // update farming stats
            // check if we have any pending yield, add it to previousYield var
            users[msg.sender][_tokenAddress].pendingGains = PendingYield(_tokenAddress, msg.sender);
            // update amount 
            users[msg.sender][_tokenAddress].activeDeposit = users[msg.sender][_tokenAddress].activeDeposit.sub(_amount);
            // update farming start time -- new farming will begin from this time onwards
            users[msg.sender][_tokenAddress].startTime = now;
            // reset last claimed figure as well -- new farming will begin from this time onwards
            users[msg.sender][_tokenAddress].lastClaimedDate = now;
        
        // withdraw the tokens and move from contract to the caller
        require(ERC20Interface(_tokenAddress).transfer(msg.sender, _amount));
        
        emit TokensClaimed(msg.sender, _amount);
    }
    
    //#########################################################################################################################################################//
    //####################################################STAKING EXTERNAL FUNCTIONS###########################################################################//
    //#########################################################################################################################################################//    
    
    // ------------------------------------------------------------------------
    // Start staking
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function Stake(uint256 _amount) external validStake(_amount) {
        // add new stake
        _newDeposit(address(bree), _amount);
        
        // transfer tokens from user to the contract balance
        require(bree.transferFrom(msg.sender, address(this), _amount));
        
        emit Staked(msg.sender, _amount);
        
    }
    
    // ------------------------------------------------------------------------
    // Add more deposits to already running farm
    // @param _tokenAddress address of the token asset
    // @param _amount amount of tokens to deposit
    // ------------------------------------------------------------------------
    function AddToStake(uint256 _amount) external {
        require(now - users[msg.sender][address(bree)].startTime < users[msg.sender][address(bree)].period, "current staking expired");
        _addToExisting(address(bree), _amount);

        // move the tokens from the caller to the contract address
        require(bree.transferFrom(msg.sender,address(this), _amount));
        
        emit AddedToExistingStake(msg.sender, _amount);
    }
    
    // ------------------------------------------------------------------------
    // Claim reward and staked tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimStakedTokens() external {
        //require(users[msg.sender][address(bree)].running, "no running stake");
        require(users[msg.sender][address(bree)].activeDeposit > 0, "no running stake");
        require(users[msg.sender][address(bree)].startTime.add(users[msg.sender][address(bree)].period) < now, "not claimable before staking period");
        
        uint256 _currentDeposit = users[msg.sender][address(bree)].activeDeposit;
        
        // check if we have any pending reward, add it to pendingGains var
        users[msg.sender][address(bree)].pendingGains = PendingReward(msg.sender);
        // update amount 
        users[msg.sender][address(bree)].activeDeposit = 0;
        
        // transfer staked tokens
        require(bree.transfer(msg.sender, _currentDeposit));
        
        emit TokensClaimed(msg.sender, _currentDeposit);
        
    }
    
    // ------------------------------------------------------------------------
    // Claim reward and staked tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimReward() external payable {
        require(msg.value >= stakeClaimFee, "should pay exact claim fee");
        require(PendingReward(msg.sender) > 0, "nothing pending to claim");
    
        uint256 _pendingReward = PendingReward(msg.sender);
        
        // add claimed reward to global stats
        totalRewards = totalRewards.add(_pendingReward);
        // add the reward to total claimed rewards
        users[msg.sender][address(bree)].totalGained = users[msg.sender][address(bree)].totalGained.add(_pendingReward);
        // update lastClaim amount
        users[msg.sender][address(bree)].lastClaimedDate = now;
        // reset previous rewards
        users[msg.sender][address(bree)].pendingGains = 0;
        
        // transfer the claim fee to the owner
        owner.transfer(msg.value);
        
        // mint more tokens inside token contract
        require(bree.MintTokens(_pendingReward, msg.sender));
         
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
    // Links governance contract to this contract
    // @param _govAddress address of the governance contract
    // @required only owner 
    // ------------------------------------------------------------------------    
    function setGovernanceContract(address _govAddress) external onlyOwner {
        governance = _govAddress;
        emit GovernanceSet(_govAddress);
    }
    
    // ------------------------------------------------------------------------
    // Add supported tokens
    // @param _tokenAddress address of the token asset
    // @param _farmingRate rate applied for farming yield to produce
    // @required only owner or governance contract
    // ------------------------------------------------------------------------    
    function AddToken(address _tokenAddress, uint256 _rate) public OwnerOrGovernance(msg.sender) {
        _addToken(_tokenAddress, _rate);
    }
    
    // ------------------------------------------------------------------------
    // Remove tokens if no longer supported
    // @param _tokenAddress address of the token asset
    // @required only owner or governance contract
    // ------------------------------------------------------------------------  
    function RemoveToken(address _tokenAddress) public OwnerOrGovernance(msg.sender) {
        
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
    function ChangeFarmingRate(address _tokenAddress, uint256 _newFarmingRate) public OwnerOrGovernance(msg.sender) {
        
        require(tokens[_tokenAddress].exists, "token doesn't exist");
        
        tokens[_tokenAddress].rate = _newFarmingRate;
        
        emit FarmingRateChanged(_tokenAddress, _newFarmingRate);
    }

    // ------------------------------------------------------------------------
    // Change Yield collection fee
    // @param _fee fee to claim the yield
    // @required only owner or governance contract
    // ------------------------------------------------------------------------     
    function SetYieldCollectionFee(uint256 _fee) public OwnerOrGovernance(msg.sender){
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
        uint256 expiryDate = (users[_caller][address(bree)].period).add(users[_caller][address(bree)].startTime);
        
        if(now < expiryDate)
            _totalStakedTime = now.sub(users[_caller][address(bree)].lastClaimedDate);
        else{
            if(users[_caller][address(bree)].lastClaimedDate >= expiryDate) // if claimed after expirydate already
                _totalStakedTime = 0;
            else
                _totalStakedTime = expiryDate.sub(users[_caller][address(bree)].lastClaimedDate);
        }
            
        uint256 _reward_token_second = ((users[_caller][address(bree)].rate).mul(10 ** 21)); // added extra 10^21
        uint256 reward =  ((users[_caller][address(bree)].activeDeposit).mul(_totalStakedTime.mul(_reward_token_second))).div(10 ** 27); // remove extra 10^21 // the two extra 10^2 is for 100 (%) // another two extra 10^4 is for decimals to be allowed
        reward = reward.div(365 days);
        return (reward.add(users[_caller][address(bree)].pendingGains));
    }
    
    // ------------------------------------------------------------------------
    // Query to get the active stake of the user
    // ------------------------------------------------------------------------
    function YourActiveStake(address _user) external view returns(uint256 _activeStake){
        return users[_user][address(bree)].activeDeposit;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the total stakes of the user
    // ------------------------------------------------------------------------
    function YourTotalStakesTillToday(address _user) external view returns(uint256 _totalStakes){
        return users[_user][address(bree)].totalDeposits;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the time of last stake of user
    // ------------------------------------------------------------------------
    function LastStakedOn(address _user) public view returns(uint256 _unixLastStakedTime){
        return users[_user][address(bree)].startTime;
    }
    
    // ------------------------------------------------------------------------
    // Query to get total earned rewards from stake
    // ------------------------------------------------------------------------
    function TotalStakeRewardsClaimedTillToday(address _user) external view returns(uint256 _totalEarned){
        return users[_user][address(bree)].totalGained;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking rate
    // ------------------------------------------------------------------------
    function LatestStakingRate() external view returns(uint256 APY){
        return tokens[address(bree)].rate;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking rate you staked at
    // ------------------------------------------------------------------------
    function YourStakingRate(address _user) external view returns(uint256 _stakingRate){
        return users[_user][address(bree)].rate;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking period you staked at
    // ------------------------------------------------------------------------
    function YourStakingPeriod(address _user) external view returns(uint256 _stakingPeriod){
        return users[_user][address(bree)].period;
    }
    
    // ------------------------------------------------------------------------
    // Query to get the staking time left
    // ------------------------------------------------------------------------
    function StakingTimeLeft(address _user) external view returns(uint256 _secsLeft){
        uint256 left = 0; 
        uint256 expiryDate = (users[_user][address(bree)].period).add(LastStakedOn(_user));
        
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
    function ChangeStakingRate(uint256 _newStakingRate) public OwnerOrGovernance(msg.sender){
        
        tokens[address(bree)].rate = _newStakingRate;
        
        emit StakingRateChanged(_newStakingRate);
    }
    
    // ------------------------------------------------------------------------
    // Change the min stake limit
    // @param _minStakeLimit minimum stake limit value
    // @required only callable by owner or governance contract
    // ------------------------------------------------------------------------
    function SetMinStakeLimit(uint256 _minStakeLimit) public OwnerOrGovernance(msg.sender){
       minStakeLimit = _minStakeLimit;
    }
    
    // ------------------------------------------------------------------------
    // Change the staking period
    // @param _seconds number of seconds to stake (n days = n*24*60*60)
    // @required only callable by owner or governance contract
    // ------------------------------------------------------------------------
    function SetStakingPeriod(uint256 _seconds) public OwnerOrGovernance(msg.sender){
       stakingPeriod = _seconds;
    }
    
    // ------------------------------------------------------------------------
    // Change the staking claim fee
    // @param _fee claim fee in weis
    // @required only callable by owner or governance contract
    // ------------------------------------------------------------------------
    function SetClaimFee(uint256 _fee) public OwnerOrGovernance(msg.sender){
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
        if(_tokenAddress == address(bree)){
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
            if(_tokenAddress == address(bree)){
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
            
            
    }

    // ------------------------------------------------------------------------
    // Internal function to add token
    // ------------------------------------------------------------------------     
    function _addToken(address _tokenAddress, uint256 _rate) internal{
        require(!tokens[_tokenAddress].exists, "token already exists");
        
        tokens[_tokenAddress] = Tokens({
            exists: true,
            rate: _rate
        });
        
        TokensAddresses.push(_tokenAddress);
        emit TokenAdded(_tokenAddress, _rate);
    }
    
    
}


