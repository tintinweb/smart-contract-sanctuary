/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Token {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint8);
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

contract owned{
    address public owner;

    constructor() {
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
/**
@title BitcashPayStakingV2
@author BitcashPay Dev Team
 */
contract BitcashPayStakingV2 is owned
{
    using SafeMath for uint256;
    
    uint256 private StakingPairsCounter;
    uint256[] public AllStakingPairIds;

    struct StakingPairItems {
        address StakeToken;
        address RewardToken;
        uint256 LockDuration;
        uint256 StakingPY;
        uint256 MaxStakingPeriod; //in days
        uint256 TotalStakedToken;
        uint256 CurrentRewardTokenAmount;
        bool isActive;
    }

    mapping (uint256 => StakingPairItems) public StakingPairs;

    event StakingPairCreated(
        address StakeToken,
        address RewardToken,
        uint256 RewardTokenAmount,
        uint256 LockDuration,
        uint256 StakingPY
    );

    /**
    @notice This function creates new staking Pair
    @param _tokenA the token to be stake
    @param _tokenB the token to be rewarded
    @param _rewardTokenAmount pool of _tokenB to be rewarded for the stakers
    @param _lockDuration duration of staked token to be locked to the staking contract
    @param _stakingPY the percentage yield depends on the _maxStakingPeriod
    e.g. _maxStakingPeriod = 365days or 1 year; _stakingPY = 1000; the _stakingPY will be devided to days of _maxStakingPeriod
    @param _maxStakingPeriod the duration of staked token yields
    */

    function createStakingPair(address _tokenA, address _tokenB, uint256 _rewardTokenAmount, uint256 _lockDuration, uint256 _stakingPY, uint256 _maxStakingPeriod) public onlyOwner
    returns (uint256 _id)
    {
        require(Token(_tokenB).balanceOf(msg.sender) >= _rewardTokenAmount, "Account fund is Insufficient");

        _id = ++StakingPairsCounter;
        StakingPairs[_id].StakeToken = _tokenA;
        StakingPairs[_id].RewardToken = _tokenB;
        StakingPairs[_id].LockDuration = _lockDuration;
        StakingPairs[_id].StakingPY = _stakingPY;
        StakingPairs[_id].MaxStakingPeriod = _maxStakingPeriod;
        StakingPairs[_id].TotalStakedToken = 0;
        StakingPairs[_id].CurrentRewardTokenAmount = _rewardTokenAmount;
        StakingPairs[_id].isActive = true;

        AllStakingPairIds.push(_id);

        Token(_tokenB).transferFrom(msg.sender, address(this), _rewardTokenAmount);

        emit StakingPairCreated(_tokenA, _tokenB, _rewardTokenAmount, _lockDuration, _stakingPY);

        return _id;

    }

    event StakingPairUpdated (
        uint256 StakingPairID,
        address StakeToken,
        address RewardToken,
        uint256 RewardTokenAmountAdded,
        uint256 LockDuration,
        uint256 StakingPY,
        uint256 MaxStakingPeriod,
        bool IsActive
    );

    /**
    @notice this function will update the staking pair
    @param _stakingPairID used to find the staking pair on the mapping
    @param _tokenA the token to be stake
    @param _tokenB the token to be rewarded
    @param _rewardTokenAmount pool of _tokenB to be rewarded for the stakers
    @param _lockDuration duration of staked token to be locked to the staking contract
    @param _stakingPY the percentage yield depends on the _maxStakingPeriod
    e.g. _maxStakingPeriod = 365days or 1 year; _stakingPY = 1000; the _stakingPY will be devided to days of _maxStakingPeriod
    @param _maxStakingPeriod the duration of staked token yields
    @param _isActive sets the status of staking pair
    @return stakingPairUpdated_ 
    */

    function updateStakingPair(uint256 _stakingPairID, address _tokenA, address _tokenB, uint256 _rewardTokenAmount, uint256 _lockDuration, uint256 _stakingPY, uint256 _maxStakingPeriod, bool _isActive) public onlyOwner
    returns (bool stakingPairUpdated_)
    {
        require(Token(_tokenB).balanceOf(msg.sender) >= _rewardTokenAmount, "Account fund is Insufficient");

        StakingPairs[_stakingPairID].StakeToken = _tokenA;
        StakingPairs[_stakingPairID].RewardToken = _tokenB;
        StakingPairs[_stakingPairID].LockDuration = _lockDuration;
        StakingPairs[_stakingPairID].StakingPY = _stakingPY;
        StakingPairs[_stakingPairID].MaxStakingPeriod = _maxStakingPeriod;
        StakingPairs[_stakingPairID].isActive = _isActive;

        if (_rewardTokenAmount != 0) {
            StakingPairs[_stakingPairID].CurrentRewardTokenAmount += _rewardTokenAmount;
            Token(_tokenB).transferFrom(msg.sender, address(this), _rewardTokenAmount);
        }
        emit StakingPairUpdated(_stakingPairID, _tokenA, _tokenB, _rewardTokenAmount, _lockDuration, _stakingPY, _maxStakingPeriod, _isActive);
        stakingPairUpdated_ = true;
        return stakingPairUpdated_;

    }

    /**
    @notice gets the staking pair count
    @return uint256
    */

    function getStakingPairsCount() public view onlyOwner returns (uint256)
    {
        return StakingPairsCounter;
    }

    /**
    @notice gets all staking pair IDs
    @return uint256[] array
    */
    function getAllStakingPairIds() public view returns (uint256[] memory)
    {
        return AllStakingPairIds;
    }

    /** @notice gets the staking pair details by ID */

    function getStakingPairByID(uint256 _stakingPairID) public view 
    returns (address,address,uint256,uint256,uint256,uint256,uint256,bool)
    {
        StakingPairItems memory stakingPairs_ = StakingPairs[_stakingPairID];
        return (
            stakingPairs_.StakeToken,
            stakingPairs_.RewardToken,
            stakingPairs_.LockDuration,
            currentStakingPairPYRate(_stakingPairID, 0),
            stakingPairs_.MaxStakingPeriod,
            stakingPairs_.TotalStakedToken,
            stakingPairs_.CurrentRewardTokenAmount,
            stakingPairs_.isActive
        );
    }

    uint256 private stakingCounter;
    uint256[] private allStakingIDs;
    
    mapping(address => uint[]) public stakeIDsOfAddress;

    struct StakeItems {
        uint256 StakingPairID;
        address StakeHolder;
        uint256 StakedPY;
        uint256 MaxStakingPeriod;
        uint256 StakedAmount;
        uint256 LockDuration;
        uint256 TimestampStaked;
        bool IsUnstaked;
    }

    mapping(address => mapping(uint256 => StakeItems)) public Stakes;

    event CreateStake(uint256, address, uint256, uint256, uint256, uint256, uint256);

    /**
    @notice this function is where the users can stake their tokens based on the stakingPair ID they choose
    @param _stakingPairId the staking pair id of the staking pair created from createStakingPair function
    @param _stakeAmount the amount of tokens to be staked.
    @return _id uint256 the id for the created stake
    */
    function createStake(uint8 _stakingPairId, uint256 _stakeAmount) public returns (uint256 _id)
    {
        require(Token(StakingPairs[_stakingPairId].StakeToken).balanceOf(msg.sender) >= _stakeAmount, "Insufficient Balance");
        require(StakingPairs[_stakingPairId].isActive == true, "Staking Pair is Currently Disabled");
        require(Token(StakingPairs[_stakingPairId].StakeToken).transferFrom(msg.sender, address(this), _stakeAmount), "Failed to transfer tokens");
        
        _id = ++stakingCounter;
        Stakes[msg.sender][_id].StakingPairID = _stakingPairId;
        Stakes[msg.sender][_id].StakeHolder = msg.sender;
        Stakes[msg.sender][_id].StakedPY = currentStakingPairPYRate(_stakingPairId, _stakeAmount);
        Stakes[msg.sender][_id].MaxStakingPeriod = StakingPairs[_stakingPairId].MaxStakingPeriod;
        Stakes[msg.sender][_id].StakedAmount = _stakeAmount;
        Stakes[msg.sender][_id].LockDuration = StakingPairs[_stakingPairId].LockDuration;
        Stakes[msg.sender][_id].TimestampStaked = block.timestamp;
        Stakes[msg.sender][_id].IsUnstaked = false;

        allStakingIDs.push(_id);
        stakeIDsOfAddress[msg.sender].push(_id);

        StakingPairs[_stakingPairId].TotalStakedToken += _stakeAmount;

        emit CreateStake(
            _id,
            msg.sender,
            StakingPairs[_stakingPairId].StakingPY,
            StakingPairs[_stakingPairId].MaxStakingPeriod,
            _stakeAmount,
            StakingPairs[_stakingPairId].LockDuration,
            block.timestamp
        );

        return _id;
    }

    /**
    @notice returns all staked IDs
    @return uint256 array
    */
    function getAllStakedIDs() onlyOwner public view returns (uint256[] memory) 
    {
        return allStakingIDs;
    }

    /** @notice gets all the stakedIDs of a certain address 
    @return uint256 array
    */
    function getAllStakeIDsOfAddress() public view returns (uint256[] memory) {
        return stakeIDsOfAddress[msg.sender];
    }

    /**
    @notice returns the stake details by ID
    @param _stakeID the ID of staked token
    */

    function getStakeDetails(uint256 _stakeID) public view returns
    (uint256, address, uint256, uint256, uint256, uint256, uint256, bool)
    {
        StakeItems memory stakingItemDetails_ = Stakes[msg.sender][_stakeID];

        return (
            stakingItemDetails_.StakingPairID,
            stakingItemDetails_.StakeHolder,
            stakingItemDetails_.StakedPY,
            stakingItemDetails_.MaxStakingPeriod,
            stakingItemDetails_.StakedAmount,
            stakingItemDetails_.LockDuration,
            stakingItemDetails_.TimestampStaked,
            stakingItemDetails_.IsUnstaked
        );
    }

    /** @notice this function will return the unlock time of certain stakeID */
    function getStakeUnlockTime(uint256 _stakeID) public view returns (uint256) {
        uint256 UnlockTimeStamp = Stakes[msg.sender][_stakeID].TimestampStaked.add(Stakes[msg.sender][_stakeID].LockDuration * 1 days);
        return UnlockTimeStamp;
    }


    uint256[] public allLockWithdrawalIDs;
    uint256 public lockedWithdrawalsCounter;

    mapping(address => uint256[]) public LockedWithdrawalIDsOfAddress;

    struct LockedWithdrawal {
        uint256 Id;
        address WithdrawalRecipient;
        address TokenAddress;
        uint256 Amount;
        uint256 LockDuration;
        uint256 UnlockTimestamp;
        uint256 LockedTimestap;
        bool isWithdrawn;
    }

    mapping(address => mapping(uint => LockedWithdrawal)) public LockedWithdrawals;


    function getLockedWithdrawalIdsOfAddress() public view returns(uint256[] memory) {
        return LockedWithdrawalIDsOfAddress[msg.sender];
    }

    function getLockedWithdrawalsByID(uint256 _withdrawalID) public view 
    returns (uint256,address,address,uint256,uint256,uint256,uint256,bool) {
        LockedWithdrawal memory lockedWithdrawalDetails_ = LockedWithdrawals[msg.sender][_withdrawalID];

        return (
            lockedWithdrawalDetails_.Id,
            lockedWithdrawalDetails_.WithdrawalRecipient,
            lockedWithdrawalDetails_.TokenAddress,
            lockedWithdrawalDetails_.Amount,
            lockedWithdrawalDetails_.LockDuration,
            lockedWithdrawalDetails_.UnlockTimestamp,
            lockedWithdrawalDetails_.LockedTimestap,
            lockedWithdrawalDetails_.isWithdrawn
        );
    }

    function withdrawLockedTokens(uint256 _withdrawalID) public returns (bool) {
        LockedWithdrawal memory lockedWithdrawalDetails_ = LockedWithdrawals[msg.sender][_withdrawalID];

        require(lockedWithdrawalDetails_.UnlockTimestamp <= block.timestamp, "This withdrawal is currently locked.");
        require(Token(lockedWithdrawalDetails_.TokenAddress).transfer(msg.sender, lockedWithdrawalDetails_.Amount), "Failed to transfer withdraw amount");
        LockedWithdrawals[msg.sender][_withdrawalID].isWithdrawn = true;

        return true;
    }

    function lockTokensForWithdrawal(uint256 _stakeID) internal returns (bool result_) {
        StakeItems memory stakingItemDetails_ = Stakes[msg.sender][_stakeID];
        StakingPairItems memory stakingPairs_ = StakingPairs[stakingItemDetails_.StakingPairID];

        uint id_ = ++lockedWithdrawalsCounter;
        
        LockedWithdrawals[msg.sender][id_].Id = id_;
        LockedWithdrawals[msg.sender][id_].WithdrawalRecipient = stakingItemDetails_.StakeHolder;
        LockedWithdrawals[msg.sender][id_].TokenAddress = stakingPairs_.StakeToken;
        LockedWithdrawals[msg.sender][id_].Amount = stakingItemDetails_.StakedAmount;
        LockedWithdrawals[msg.sender][id_].LockDuration = stakingItemDetails_.LockDuration;
        LockedWithdrawals[msg.sender][id_].UnlockTimestamp = block.timestamp.add((stakingItemDetails_.LockDuration).mul(1 days));
        LockedWithdrawals[msg.sender][id_].LockedTimestap = block.timestamp;
        LockedWithdrawals[msg.sender][id_].isWithdrawn = false;
    
        result_ = true;
        return result_;

    }

    event OnUnstake (
        uint256 StakeID,
        address StakeHolder,
        uint256 UnStakedAmount,
        uint256 RewardAmount,
        bool IsUnstaked
    );


    /**
    @notice this is the function where users can unstake their tokens
    @param _stakeID to find the id of a the staked token
    */

    function unStakeToken(uint256 _stakeID) public returns (bool) {
        StakeItems memory stakingItemDetails_ = Stakes[msg.sender][_stakeID];
        StakingPairItems memory stakingPairs_ = StakingPairs[stakingItemDetails_.StakingPairID];

        require(lockTokensForWithdrawal(_stakeID), "Failed to lock tokens for withdrawal");
        
        
        Token(stakingPairs_.RewardToken).transfer(msg.sender, calculateRewards(_stakeID));


        Stakes[msg.sender][_stakeID].IsUnstaked = true;
        StakingPairs[stakingItemDetails_.StakingPairID].TotalStakedToken -= stakingItemDetails_.StakedAmount;
        StakingPairs[stakingItemDetails_.StakingPairID].CurrentRewardTokenAmount -= calculateRewards(_stakeID);

        emit OnUnstake(_stakeID, msg.sender, stakingItemDetails_.StakedAmount, calculateRewards(_stakeID), true);
        
        return true;
    }

    mapping(address => mapping(uint256 => uint256)) public ClaimedRewards;

    event ClaimedReward(
        uint256 StakeID,
        uint256 ClaimedReward
    );

    /**
    @notice this is the function where the staked holder can claim their rewards
    @param _stakeID used to find the staked token details
    @return claimedReward_
    */

    function claimReward(uint256 _stakeID) public returns(uint256 claimedReward_)
    {
        StakeItems memory stakedItemDetails_ = Stakes[msg.sender][_stakeID];
        StakingPairItems memory stakingPair_ = StakingPairs[stakedItemDetails_.StakingPairID];
        claimedReward_ = calculateRewards(_stakeID);
        
        require(Token(stakingPair_.RewardToken).transfer(msg.sender, claimedReward_), "Failed to transfer reward claims");
        StakingPairs[stakedItemDetails_.StakingPairID].CurrentRewardTokenAmount -= claimedReward_;

        ClaimedRewards[msg.sender][_stakeID] = ClaimedRewards[msg.sender][_stakeID].add(claimedReward_);

        emit ClaimedReward(_stakeID, claimedReward_);
        return claimedReward_;
    }

    function getClaimedRewards(uint256 _stakeID)
    public view
    returns (uint256 claimedReward_)
    {
        claimedReward_ = ClaimedRewards[msg.sender][_stakeID];
        return claimedReward_;
    }

    /**
    @notice calculates the StakingPair PY rate
    @param _stakingPairID will use to find the staking Pair
    @param _stakeAmount used to calculate the Percentage yield to be given to the new stake
    @return stakingPairPY_ the percentage of yield to be given
    */
    function currentStakingPairPYRate(uint256 _stakingPairID, uint256 _stakeAmount) public view
    returns (uint256 stakingPairPY_) {
        StakingPairItems memory stakingPair_ = StakingPairs[_stakingPairID];
        uint256 stakingPairPY = stakingPair_.StakingPY;
        uint256 stakingPairTotalStaked = stakingPair_.TotalStakedToken;

        uint256 stakedTokenPlusStakeAmount = stakingPairTotalStaked + _stakeAmount;
    

        uint256 currentRemainingTokenReward = stakingPair_.CurrentRewardTokenAmount;

        
        uint256 totalStakedPlusStakeAmount = stakedTokenPlusStakeAmount.div(10 ** Token(stakingPair_.StakeToken).decimals());
        
        totalStakedPlusStakeAmount = totalStakedPlusStakeAmount.mul(10 ** Token(stakingPair_.RewardToken).decimals());

        

        uint256 estimatedStakingPairRewardAfterAddingStakeAmount = (totalStakedPlusStakeAmount.mul(stakingPairPY.mul(100))).div(10000);
        uint rewardDescrepancy;

        if (currentRemainingTokenReward < estimatedStakingPairRewardAfterAddingStakeAmount) {
            rewardDescrepancy = ((estimatedStakingPairRewardAfterAddingStakeAmount.sub(currentRemainingTokenReward)).mul(100)).div(currentRemainingTokenReward);
        }


        stakingPairTotalStaked = stakingPairTotalStaked.div(10 ** Token(stakingPair_.StakeToken).decimals());
        stakingPairTotalStaked = stakingPairTotalStaked.mul(10 ** Token(stakingPair_.RewardToken).decimals());

        uint256 estimatedStakingPairReward = (stakingPairTotalStaked.mul(stakingPairPY.mul(100))).div(10000);

        uint256 stakingPairRewardPoolPercentage = ((currentRemainingTokenReward.sub(estimatedStakingPairReward)).mul(100)).div(currentRemainingTokenReward);        

        stakingPairPY_ = (stakingPairPY.mul(stakingPairRewardPoolPercentage.mul(100))).div(10000);

        if (rewardDescrepancy != 0) {
            if (rewardDescrepancy >= 100) {
                return 0;
            }
            stakingPairPY_ = stakingPairPY_.sub((stakingPairPY_.mul(rewardDescrepancy.mul(100))).div(10000));
        }
     
        return stakingPairPY_;

    }


    /**
    @notice calculates the reward of a certain stake
    @param _stakeID use to find the staked token
    @return calculatedReward_
    */
    function calculateRewards(uint256 _stakeID) public view
    returns (uint256 calculatedReward_)
    {
        StakeItems memory stakedItemDetails_ = Stakes[msg.sender][_stakeID];
        StakingPairItems memory stakingPair_ = StakingPairs[stakedItemDetails_.StakingPairID];
        uint256 startOfStake_ = stakedItemDetails_.TimestampStaked;
        uint256 secondsPassed_ = ((block.timestamp).add(1 days)).sub(startOfStake_);
        uint256 stakedAmount_ = stakedItemDetails_.StakedAmount;
        uint256 rewardAmount_ = 0;
        uint256 claimedRewards_ = 0;
        if (stakedAmount_ > 0 && !stakedItemDetails_.IsUnstaked) {
            stakedAmount_ = stakedAmount_.div(10 ** Token(stakingPair_.StakeToken).decimals());
            rewardAmount_ = stakedAmount_.mul(10 ** Token(stakingPair_.RewardToken).decimals());
            calculatedReward_ = (rewardAmount_.mul(stakedItemDetails_.StakedPY.mul(100))).div(10000);
            calculatedReward_ = calculatedReward_.div(stakedItemDetails_.MaxStakingPeriod.mul(1 days));
            claimedRewards_ = getClaimedRewards(_stakeID);
            
            if(startOfStake_.add(secondsPassed_) >= startOfStake_.add(stakedItemDetails_.MaxStakingPeriod.mul(1 days))) {
                return (calculatedReward_.mul(stakedItemDetails_.MaxStakingPeriod.mul(1 days))).sub(claimedRewards_);
            }
            return (calculatedReward_.mul(secondsPassed_)).sub(claimedRewards_);  
        }
        return 0;
    }


}