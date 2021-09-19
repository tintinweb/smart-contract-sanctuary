/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
        );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
            );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount)
    external
    returns (bool);


    function allowance(address owner, address spender)
    external
    view
    returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
        );
}

contract SSTXStaking is Ownable {
    
    struct Stake {
        uint256 staked;
        uint256 lastStakedTime;
        uint256 lastUnstakedTime;
        uint256 lastClaimedTime;
        uint256 lastClaimedAmount;
        uint256 cooldown;
        uint256 currentReward;
        uint256 previousReward;
        uint256 totalEarned;
        uint256 TotalClaimedAmount;
    }

    struct MembershipLevel {
        uint256 threshold;
        uint256 APY;
    }

    uint256 constant _divider = 1000;
    uint256 constant _decimals = 7;
    uint256 constant apyBase = 31449600; // in seconds = 364 days
    
    uint256 public rewardPeriod = 60;
    uint256 public rewardMembers;

    mapping(address => Stake) public Stakes;
    
    MembershipLevel[] public MembershipLevels;
    uint256 public levelsCount = 0;

    IERC20 _token;
    address locker;

    event MembershipAdded(uint256 threshold, uint256 apy, uint256 newLevelsCount);
    event MembershipRemoved(uint256 index, uint256 newLevelsCount);
    event Staked(address fromUser, uint256 amount);
    event Claimed(address byUser, uint256 reward);
    event Unstaked(address byUser, uint256 amount);

    constructor(address token) {
        addMembership(750000000  * 10**_decimals, 50);
        addMembership(1500000000 * 10**_decimals, 60);
        addMembership(3000000000 * 10**_decimals, 80);
        addMembership(5000000000 * 10**_decimals, 100);
        addMembership(8500000000 * 10**_decimals, 120);
        setToken(token);
    }
    
    function setLocker(address _locker) external onlyOwner {
        locker = _locker;
    }

    /* changeRewardPeriod()
       Description: Takes in a new period in seconds
       
       Business Rule:
       (1) Require that the period specified is greater than 0 seconds
       (2) Set the reward period to the new time provided (in seconds)
    */
    function changeRewardPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Cannot be 0");
        rewardPeriod = newPeriod;
    }

    function changeMembershipAPY(uint256 index, uint256 newAPY) external onlyOwner {
        require(index <= levelsCount - 1, "Wrong membership id");
        if (index > 0) require(MembershipLevels[index - 1].APY < newAPY, "Cannot be lower than previous lvl");
        if (index < levelsCount - 1) require(MembershipLevels[index + 1].APY > newAPY, "Cannot be higher than next lvl");
        MembershipLevels[index].APY = newAPY;
    }

    function changeMembershipThreshold(uint256 index, uint256 newThreshold) external onlyOwner {
        require(index <= levelsCount - 1, "Wrong membership id");
        if (index > 0) require(MembershipLevels[index - 1].threshold < newThreshold, "Cannot be lower than previous lvl");
        if (index < levelsCount - 1) require(MembershipLevels[index + 1].threshold > newThreshold, "Cannot be higher than next lvl");
        MembershipLevels[index].threshold = newThreshold;
    }

    function addMembership(uint256 threshold, uint256 APY) public onlyOwner {
        require(threshold > 0 && APY > 0, "Threshold and APY should be larger than zero");
        if (levelsCount == 0) {
            MembershipLevels.push(MembershipLevel(threshold, APY));
        } else {
            require(MembershipLevels[levelsCount - 1].threshold < threshold, "New threshold must be larger than the last");
            require(MembershipLevels[levelsCount - 1].APY < APY, "New APY must be larger than the last");
            MembershipLevels.push(MembershipLevel(threshold, APY));
        }
        levelsCount++;
        emit MembershipAdded(threshold, APY, levelsCount);
    }

    function removeMembership(uint256 index) external onlyOwner {
        require(levelsCount > 0, "Nothing to remove");
        require(index <= levelsCount - 1, "Wrong index");

        for (uint256 i = index; i < levelsCount - 1; i++) {
            MembershipLevels[i] = MembershipLevels[i + 1];
        }
        delete MembershipLevels[levelsCount - 1];
        levelsCount--;
        emit MembershipRemoved(index, levelsCount);
    }

    function setToken(address token) public onlyOwner {
        _token = IERC20(token);
    }

    /* getStakeInfo()
       Description: Takes in a wallet address and uses the Stakes hashtable (mapping) to return stake information for that address as follows:
                    staked       Amount of tokens last staked
                    apy          APY 
                    lastClaimed  Last amount of tokens Claimed
                    cooldown     The cooldown period
       
       Business Rule:
       (1) Call getTotalRewards() to calculate the user's reward. Return true if it is greater than 0
    */
    function getStakeInfo(address user)
        external
        view
        returns (
            uint256 staked,
            uint256 apy,
            uint256 lastClaimed,
            uint256 cooldown
        )
    {
        return (Stakes[user].staked, getAPY(Stakes[user].staked), Stakes[user].lastClaimedTime, Stakes[user].cooldown);
    }

    /* canClaim()
       Description: Takes in a wallet address and returns true if that user can claim a reward
       
       Business Rule:
       (1) Calculate the time elapsed since the last time the user staked
       (2) Calculate the time elapsed since the last time the user claimed
       (3) If the user has not yet claimed (first time) and the time since the user last staked is less than the cooldown time, return false
           ..OR
       (4) If the user has already claimed and the time since the user last claimed is less than the cooldown time, return false
       (5) .. ELSE return true;
    */
    function canClaim(address user) public view returns (bool) {
        uint256 lastStaked = Stakes[user].lastStakedTime;
        uint256 lastClaimed = Stakes[user].lastClaimedTime;
        uint256 cooldown = Stakes[user].cooldown;
        uint256 currentTime = block.timestamp;
        uint256 timeElapsedSinceLastStaked = currentTime - lastStaked;
        uint256 timeElapsedSinceLastClaimed = currentTime - lastClaimed;

        if ( (lastClaimed == 0 && timeElapsedSinceLastStaked < cooldown) || timeElapsedSinceLastClaimed < cooldown) return false;
        return true;        
    }
    
    /* getAPY()
       Description: Takes in a number of tokens and returns the Annual Percentage Yield (APY)
       
       Business Rules:
       (1) Require a membership level greater than 0
       (2) Loop through the current membership level, from the highest threshold to the lowest to determine the right APY
    */
    function getAPY(uint256 tokens) public view returns (uint256) {
        require(levelsCount > 0, "No membership levels exist");

        for (uint256 i=levelsCount; i>0; i--) {
            if (tokens >= MembershipLevels[i-1].threshold) return MembershipLevels[i-1].APY;
        }
        return 0;
    }

    /* calculateReward()
       Description: Takes in an APY amount, last staked time, and number of tokens staked, and returns a calculated reward
       
       Business Rules:
       (1) If the last staked time is 0, return 0
       (2) Return (the time elapsed * tokens * APY) divided by _divider (e.g. 1000) then again divided by apyBase (e.g. 364 days)
           NOTE: time elapsed = current time minus the last staked time
    */
    function calculateReward(
        uint256 APY,
        uint256 lastStakedTime,
        uint256 tokens
    ) public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - lastStakedTime; 
        if (lastStakedTime == 0) return 0;
        return (timeElapsed * tokens * APY) / _divider / apyBase;
    }
    
    /* getTotalRewards()
       Description: Takes in the user's wallet address and calls calculateReward to return the user's total reward amount
       
       Business Rules:
       (1) Require a membership level greater than 0
       (2) Get the last staked time and the total staked amount
       (3) Get the APY by calling getAPY() and sending it the total staked amount.
       (4) Calculate the reward by calling calculateReward() and sending it APY, lastStaked time, and the total number of tokens staked
    */
    function getTotalRewards(address user) public view returns (uint256) {
        require(levelsCount > 0, "No membership levels exist");
        uint256 lastStakedTime = Stakes[user].lastStakedTime;
        uint256 totalStaked = Stakes[user].staked;
        uint256 APY = getAPY(totalStaked);

        return calculateReward(APY, lastStakedTime, totalStaked);
    }
    
    
    function getLastClaimedAmount(address user) public view returns (uint256) {
        return Stakes[user].lastClaimedAmount;
    }

    function getTotalEarned(address user) public view returns (uint256) {
        return Stakes[user].totalEarned;
    }

    /* stake()
       Description: Takes in an amount of tokens to stake and returns true if the staking was successful
       
       Business Rules:
       (1)  Require token amount to be greater than 0
       (2)  If you're staking again, require that the tokens staked is at a minimum equal to "membership level threshold 0" + the staked amount
            This, for example, would allow you to stake 750000000 and then stake another 100 later.
       (3)  Transfer the tokens you want to stake from the sender's wallet address to the locker
       (4)  Set the last staked time to the current time (block.timestamp).
       (5)  Set the last claimed amount to 0
       (6)  If it is the first time the user stakes, increse the number of reward members, and initialize some variables.
       (7)  Set the last staked time to the current time
       (8)  Set the user's cooldown time to the set reward period
       (9)  Add the number of tokens staked to the total staked amount
       (10) emit the amount of tokens staked
    */
    function stake(uint256 tokens) external returns (bool) {
        require(tokens > 0, "You need to stake the minimum threshold. Check membership levels");
        require(MembershipLevels[0].threshold <= tokens + Stakes[msg.sender].staked, "Insufficient tokens for staking.");
        _token.transferFrom(msg.sender, locker, tokens);
        Stakes[msg.sender].lastStakedTime = block.timestamp;
        Stakes[msg.sender].lastClaimedAmount = 0;
        //if it is the first time then increase number of reward members and initialize some values
        if (Stakes[msg.sender].staked == 0) {
            // increase number of total active rewardMembers
            rewardMembers++;
            // initialize the total earned and current reward variables
            Stakes[msg.sender].totalEarned = 0;
            Stakes[msg.sender].currentReward = 0;
        } 
        Stakes[msg.sender].lastStakedTime = block.timestamp;
        Stakes[msg.sender].cooldown = rewardPeriod;
        Stakes[msg.sender].staked += tokens;
       
        emit Staked(msg.sender, tokens);
        return true;
    }

    /* claim()
       Description: Allows a user to claim tokens and returns true if the claim is successful
       
       Business Rules:
       (1) Require that the user is able to claim by calling canClaim
       (2) Get the reward amount that can be claimed
       (3) Transfer the reward amount from the locker to the user's wallet address
       (4) Set the last claimed amount to the current reward amount
       (5) Set the last claimed time to the current time
       (6) Add the reward amount to the user's total earned amount
       (7) Set the previous reward to the current reward
       (8) Set the current reward to 0
       (9) Emit the current reward amount
    */
    function claim() public returns (bool) {
        require(canClaim(msg.sender), "Please wait for the next reward period to claim");

        uint256 totalClaimed = Stakes[msg.sender].totalEarned;
        uint256 currentReward = getTotalRewards(msg.sender) - totalClaimed; 
        Stakes[msg.sender].currentReward = currentReward;
        _token.transferFrom(locker, msg.sender, currentReward);
        Stakes[msg.sender].lastClaimedAmount = currentReward;
        Stakes[msg.sender].lastClaimedTime = block.timestamp;
        Stakes[msg.sender].totalEarned += currentReward;
        
        Stakes[msg.sender].previousReward = Stakes[msg.sender].currentReward;
        Stakes[msg.sender].currentReward = 0;
        
        emit Claimed(msg.sender, currentReward);
        return true;
    }

    function emergency_withdraw() external onlyOwner() returns (bool) {
        require(Stakes[msg.sender].staked > 0, "Nothing to unstake");
        // uint256 reward = getReward(msg.sender);
        uint256 reward = 10;
        uint256 unstakeAmount = Stakes[msg.sender].staked;

        _token.transferFrom(locker, msg.sender, reward + unstakeAmount);

        // totalTokenLocked = totalTokenLocked - reward - unstakeAmount;
        delete Stakes[msg.sender];
        // Decreases number of total active rewardMembers
        rewardMembers--;
        emit Claimed(msg.sender, reward);
        emit Unstaked(msg.sender, unstakeAmount);
        return true;
    }
    
    /* unstake()
       Description: Takes in an amount of tokens to unstake and returns true if the unstaking was successful
       
       Business Rules:
       (1) Require the total staked amount to be greater than 0
       (2) Require that the unstake amount is either zero (unstaking all staked tokens) or greater than the minimum threshold amount (Level 0)
       (3) Check if there is anything to claim and, if so, require that the total staked minus the stake amount is still greater than the minimum threshold
       (4) Require that the unstake amount is not greater than your total staked amount
       (5) Transfer the unstake amount from the locker to the user's wallet address
       (6) If the unstake amount is equal to the total number of staked tokens, then delete the Stakes structure for that user, and reduce rewardMembers
       (7) else update the Stakes structure for that user
       (8) emit the Unstaked amount
    */
    function unstake(uint256 unstakeAmount) external returns (bool) {

        require(Stakes[msg.sender].staked > 0, "Nothing to unstake");
        uint256 resultingUnstakeAmt = Stakes[msg.sender].staked - unstakeAmount;
        
        require(0 < unstakeAmount  && unstakeAmount <= Stakes[msg.sender].staked, "Unstake amount exceeds total staked amount");
        require(resultingUnstakeAmt == 0 || resultingUnstakeAmt >= MembershipLevels[0].threshold, "By unstaking this amount of tokens you are falling under the minimum threshold level to stake tokens. Either unstake all or unstake less tokens.");

        _token.transferFrom(locker, msg.sender, unstakeAmount);

        if (unstakeAmount == Stakes[msg.sender].staked){
            delete Stakes[msg.sender];
            rewardMembers--;
            // emit Claimed(msg.sender, reward);
            emit Unstaked(msg.sender, unstakeAmount);
            return true;
        } else {
            Stakes[msg.sender].staked -= unstakeAmount;
            Stakes[msg.sender].lastUnstakedTime = block.timestamp;
            Stakes[msg.sender].cooldown = rewardPeriod;
            emit Unstaked(msg.sender, unstakeAmount);
            return true;
        }
    }

    function getUserDetails(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        Stake storage user = Stakes[userAddress];
        uint256 nextRewardDate = user.lastClaimedTime + user.cooldown;
        return (user.staked, user.lastStakedTime, user.lastUnstakedTime, user.lastClaimedTime, user.cooldown, user.previousReward, user.currentReward, user.totalEarned, nextRewardDate);
    }

}