//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity ^0.6.0;

import "./Owned.sol";
import "./LittleLink.sol";
import "./ERC20Interface.sol";
import "./SafeMath.sol";

contract farming is Owned{
    
    using SafeMath for uint256;
    
    uint256 public yieldCollectionFee = 0.05 ether;
    uint256 public stakingPeriod = 30 days;
    uint256 public stakeClaimFee = 0.05 ether;
    uint256 public minStakeLimit = 300 * 10 **(18); // 300 LITTLE
    uint256 public totalYield;
    uint256 public totalRewards;
    
    LittleLink public little;
    
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
        little = LittleLink(_tokenAddress);
        
        // add little token to ecosystem
        _addToken(_tokenAddress, 40); // 40 apy initially
    }
    
    function Farm(address _tokenAddress, uint256 _amount) external{
        require(_tokenAddress != address(little), "Use staking instead"); 
        
        // add to farm
        _newDeposit(_tokenAddress, _amount);
        
        // transfer tokens from user to the contract balance
        require(ERC20Interface(_tokenAddress).transferFrom(msg.sender, address(this), _amount));
        
        emit FarmingStarted(_tokenAddress, _amount);
    }
    
    function AddToFarm(address _tokenAddress, uint256 _amount) external{
        require(_tokenAddress != address(little), "use staking instead");
        _addToExisting(_tokenAddress, _amount);
        
        // move the tokens from the caller to the contract address
        require(ERC20Interface(_tokenAddress).transferFrom(msg.sender,address(this), _amount));
        
        emit AddedToExistingFarm(_tokenAddress, _amount);
    }
    
    function Yield(address _tokenAddress) external payable {
        require(msg.value >= yieldCollectionFee, "should pay exact claim fee");
        require(PendingYield(_tokenAddress, msg.sender) > 0, "No pending yield");
        require(tokens[_tokenAddress].exists, "Token doesn't exist");
        require(_tokenAddress != address(little), "use staking instead");
    
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
        require(little.MintTokens(_pendingYield, msg.sender));
        
        emit YieldCollected(_tokenAddress, _pendingYield);
    }
    
    function WithdrawFarmedTokens(address _tokenAddress, uint256 _amount) external {
        require(users[msg.sender][_tokenAddress].activeDeposit >= _amount, "insufficient amount in farming");
        require(_tokenAddress != address(little), "use withdraw of staking instead");
        
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
    
    function Stake(uint256 _amount) external validStake(_amount) {
        // add new stake
        _newDeposit(address(little), _amount);
        
        // transfer tokens from user to the contract balance
        require(little.transferFrom(msg.sender, address(this), _amount));
        
        emit Staked(msg.sender, _amount);
        
    }
    
    function AddToStake(uint256 _amount) external {
        require(now - users[msg.sender][address(little)].startTime < users[msg.sender][address(little)].period, "current staking expired");
        _addToExisting(address(little), _amount);

        // move the tokens from the caller to the contract address
        require(little.transferFrom(msg.sender,address(this), _amount));
        
        emit AddedToExistingStake(msg.sender, _amount);
    }
    
    function ClaimStakedTokens() external {
        //require(users[msg.sender][address(little)].running, "no running stake");
        require(users[msg.sender][address(little)].activeDeposit > 0, "no running stake");
        require(users[msg.sender][address(little)].startTime.add(users[msg.sender][address(little)].period) < now, "not claimable before staking period");
        
        uint256 _currentDeposit = users[msg.sender][address(little)].activeDeposit;
        
        // check if we have any pending reward, add it to pendingGains var
        users[msg.sender][address(little)].pendingGains = PendingReward(msg.sender);
        // update amount 
        users[msg.sender][address(little)].activeDeposit = 0;
        
        // transfer staked tokens
        require(little.transfer(msg.sender, _currentDeposit));
        
        emit TokensClaimed(msg.sender, _currentDeposit);
        
    }
    
    function ClaimReward() external payable {
        require(msg.value >= stakeClaimFee, "should pay exact claim fee");
        require(PendingReward(msg.sender) > 0, "nothing pending to claim");
    
        uint256 _pendingReward = PendingReward(msg.sender);
        
        // add claimed reward to global stats
        totalRewards = totalRewards.add(_pendingReward);
        // add the reward to total claimed rewards
        users[msg.sender][address(little)].totalGained = users[msg.sender][address(little)].totalGained.add(_pendingReward);
        // update lastClaim amount
        users[msg.sender][address(little)].lastClaimedDate = now;
        // reset previous rewards
        users[msg.sender][address(little)].pendingGains = 0;
        
        // transfer the claim fee to the owner
        owner.transfer(msg.value);
        
        // mint more tokens inside token contract
        require(little.MintTokens(_pendingReward, msg.sender));
         
        emit RewardClaimed(msg.sender, _pendingReward);
    }
    
    function PendingYield(address _tokenAddress, address _caller) public view returns(uint256 _pendingRewardWeis){
        uint256 _totalFarmingTime = now.sub(users[_caller][_tokenAddress].lastClaimedDate);
        
        uint256 _reward_token_second = ((tokens[_tokenAddress].rate).mul(10 ** 21)).div(365 days); // added extra 10^21
        
        uint256 yield = ((users[_caller][_tokenAddress].activeDeposit).mul(_totalFarmingTime.mul(_reward_token_second))).div(10 ** 27); // remove extra 10^21 // 10^2 are for 100 (%)
        
        return yield.add(users[_caller][_tokenAddress].pendingGains);
    }
    
    function ActiveFarmDeposit(address _tokenAddress, address _user) external view returns(uint256 _activeDeposit){
        return users[_user][_tokenAddress].activeDeposit;
    }
    
    function YourTotalFarmingTillToday(address _tokenAddress, address _user) external view returns(uint256 _totalFarming){
        return users[_user][_tokenAddress].totalDeposits;
    }
    
    function LastFarmedOn(address _tokenAddress, address _user) external view returns(uint256 _unixLastFarmedTime){
        return users[_user][_tokenAddress].startTime;
    }
    
    function TotalFarmingRewards(address _tokenAddress, address _user) external view returns(uint256 _totalEarned){
        return users[_user][_tokenAddress].totalGained;
    }
    
    function setGovernanceContract(address _govAddress) external onlyOwner {
        governance = _govAddress;
        emit GovernanceSet(_govAddress);
    }
    
    function AddToken(address _tokenAddress, uint256 _rate) public OwnerOrGovernance(msg.sender) {
        _addToken(_tokenAddress, _rate);
    }
    
    function RemoveToken(address _tokenAddress) public OwnerOrGovernance(msg.sender) {
        
        require(tokens[_tokenAddress].exists, "token doesn't exist");
        
        tokens[_tokenAddress].exists = false;
        
        emit TokenRemoved(_tokenAddress, tokens[_tokenAddress].rate);
    }
    
    function ChangeFarmingRate(address _tokenAddress, uint256 _newFarmingRate) public OwnerOrGovernance(msg.sender) {
        
        require(tokens[_tokenAddress].exists, "token doesn't exist");
        
        tokens[_tokenAddress].rate = _newFarmingRate;
        
        emit FarmingRateChanged(_tokenAddress, _newFarmingRate);
    }

    function SetYieldCollectionFee(uint256 _fee) public OwnerOrGovernance(msg.sender){
        yieldCollectionFee = _fee;
        emit YieldCollectionFeeChanged(_fee);
    }
    
    function PendingReward(address _caller) public view returns(uint256 _pendingReward){
        uint256 _totalStakedTime = 0;
        uint256 expiryDate = (users[_caller][address(little)].period).add(users[_caller][address(little)].startTime);
        
        if(now < expiryDate)
            _totalStakedTime = now.sub(users[_caller][address(little)].lastClaimedDate);
        else{
            if(users[_caller][address(little)].lastClaimedDate >= expiryDate) // if claimed after expirydate already
                _totalStakedTime = 0;
            else
                _totalStakedTime = expiryDate.sub(users[_caller][address(little)].lastClaimedDate);
        }
            
        uint256 _reward_token_second = ((users[_caller][address(little)].rate).mul(10 ** 21)); // added extra 10^21
        uint256 reward =  ((users[_caller][address(little)].activeDeposit).mul(_totalStakedTime.mul(_reward_token_second))).div(10 ** 27); // remove extra 10^21 // the two extra 10^2 is for 100 (%) // another two extra 10^4 is for decimals to be allowed
        reward = reward.div(365 days);
        return (reward.add(users[_caller][address(little)].pendingGains));
    }
    
    function YourActiveStake(address _user) external view returns(uint256 _activeStake){
        return users[_user][address(little)].activeDeposit;
    }
    
    function YourTotalStakesTillToday(address _user) external view returns(uint256 _totalStakes){
        return users[_user][address(little)].totalDeposits;
    }
    
    function LastStakedOn(address _user) public view returns(uint256 _unixLastStakedTime){
        return users[_user][address(little)].startTime;
    }
    
    function TotalStakeRewardsClaimedTillToday(address _user) external view returns(uint256 _totalEarned){
        return users[_user][address(little)].totalGained;
    }
    
    function LatestStakingRate() external view returns(uint256 APY){
        return tokens[address(little)].rate;
    }
    
    function YourStakingRate(address _user) external view returns(uint256 _stakingRate){
        return users[_user][address(little)].rate;
    }
    
    function YourStakingPeriod(address _user) external view returns(uint256 _stakingPeriod){
        return users[_user][address(little)].period;
    }
    
    function StakingTimeLeft(address _user) external view returns(uint256 _secsLeft){
        uint256 left = 0; 
        uint256 expiryDate = (users[_user][address(little)].period).add(LastStakedOn(_user));
        
        if(now < expiryDate)
            left = expiryDate.sub(now);
            
        return left;
    }
    
    function ChangeStakingRate(uint256 _newStakingRate) public OwnerOrGovernance(msg.sender){
        
        tokens[address(little)].rate = _newStakingRate;
        
        emit StakingRateChanged(_newStakingRate);
    }
    
    function SetMinStakeLimit(uint256 _minStakeLimit) public OwnerOrGovernance(msg.sender){
       minStakeLimit = _minStakeLimit;
    }
    
    function SetStakingPeriod(uint256 _seconds) public OwnerOrGovernance(msg.sender){
       stakingPeriod = _seconds;
    }
    
    function SetClaimFee(uint256 _fee) public OwnerOrGovernance(msg.sender){
       stakeClaimFee = _fee;
    }
    
    function _newDeposit(address _tokenAddress, uint256 _amount) internal{
        require(users[msg.sender][_tokenAddress].activeDeposit ==  0, "Already running");
        require(tokens[_tokenAddress].exists, "Token doesn't exist");
        
        // add that token into the contract balance
        // check if we have any pending reward/yield, add it to pendingGains variable
        if(_tokenAddress == address(little)){
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

    function _addToExisting(address _tokenAddress, uint256 _amount) internal{
        require(tokens[_tokenAddress].exists, "Token doesn't exist");
        // require(users[msg.sender][_tokenAddress].running, "no running farming/stake");
        require(users[msg.sender][_tokenAddress].activeDeposit > 0, "no running farming/stake");
        // update farming stats
            // check if we have any pending reward/yield, add it to pendingGains variable
            if(_tokenAddress == address(little)){
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