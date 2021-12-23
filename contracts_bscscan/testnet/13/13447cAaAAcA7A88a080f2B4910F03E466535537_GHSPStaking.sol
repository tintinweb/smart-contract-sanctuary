// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SafeMath } from "./SafeMath.sol";
import { Ownable } from "./Ownable.sol";
import { IBEP20 } from "./IBEP20.sol";

/**
 * @title GHSP Staking
 * Distribute GHSP rewards over discrete-time schedules for the staking of GHSP on BSC network.
 * This contract is designed on a self-service model, where users will stake GHSP, unstake GHSP and claim rewards through their own transactions only.
 */
contract GHSPStaking is Ownable {

    /* ------------------------------ States --------------------------------- */

    using SafeMath for uint256;

    IBEP20 public immutable tokenAddress;               // contract address of bep20 token

    uint256 public allStakes;                           // total amount of staked token

    mapping(address => uint256) stakes;                 // amount of staked token per user: staker => amount

    address[] stakers;                                  // all stakers

    mapping(address => uint256) rewards;                // rewards: staker => reward 

    mapping(address => uint256) lastUpdatedTimes;       // last updated: staker => time

    struct SnapStaking {                                // SnapShot of Staking
        address user;                                   // staker
        uint256 time;                                   // time
        bool status;                                    // stake or unstake
        uint256 amount;                                 // amount
    }

    SnapStaking[] public stakingHistories;              // history of all staking

    struct SnapHarvest {                                // SnapShot of Harvesting
        address user;                                   // staker
        uint256 time;                                   // time
        bool status;                                    // not used
        uint256 amount;                                 // amount
    }

    SnapHarvest[] public harvestingHistories;           // history of harvest

    bool public isRunning;                              // is running or not

    uint256 public decimal;                             // decimal of reward token

    uint256 public totalSupply;                         // total Supply of rewarding - min: 10K

    uint256 public totalStakingPeriodDays;                  // total staking period by month - min: 1 Month

    uint256 private _totalRewards;                      // total Rewardings

    uint256 private _totalHarvest;                      // total amount of harvested                    

    uint256 private _rewardCapacity;                    // total amount of token in contract for rewarding

    uint256 private _rewardAmountPerSecond;             // total rewarding per second
    
    /* ------------------------------ Events --------------------------------- */
    event Staked(address staker, uint256 tokenId);
    
    event UnStaked(address staker, uint256 tokenId);

    event Harvest(address staker, uint256 amount);

    event AdminDeposit(address admin, uint256 amount);

    event AdminWithdraw(address admin, uint256 amount);

    event AdminHarvest(address user, uint256 amount);

    event AdminUpdatedAPY(uint256 totalSupply, uint256 totalPeriods);

    /* ------------------------------ Modifiers --------------------------------- */


    /* ------------------------------ User Functions --------------------------------- */

    /* 
        Contructor of contract
    params:
        - tokenAddress: Contract Address of BEP20 token
        - totalSupply: total amount of rewarding tokens
        - totalStakingPeriodDays: total time of staking for nft tokens
    */
    constructor(
        IBEP20 tokenAddress_,
        uint256 totalSupply_,
        uint256 totalStakingPeriodDays_
    ) {
        require(totalSupply_ > 1e4, "Contract Constructor: Not Enough Supply Amount, bigger than 10K");
        require(totalStakingPeriodDays_ > 0, "Contract Constructor: Not Enough Staking Period, bigger than 1 days");
        
        tokenAddress = tokenAddress_;
        
        decimal = tokenAddress_.decimals();
        totalSupply = totalSupply_;
        totalStakingPeriodDays = totalStakingPeriodDays_;

        isRunning = true;
        
        _updateRewardAmountPerSecond();
    }

    /*
        Cal rewards per seconds from APY
    */
    function _updateRewardAmountPerSecond() private{
        _rewardAmountPerSecond = totalSupply / (totalStakingPeriodDays * 24 * 3600);
    }

    /*
        Update Rewardings(amount and time)
        notice: rewarding amount increases only isRunning
    */
    function _updateRewards(address staker) private {
        uint256 total = allStakes;
        uint256 count = stakes[staker];
        
        if(lastUpdatedTimes[staker] == 0 || total == 0 || count == 0) return;

        uint256 current = block.timestamp;

        if(isRunning){
            uint256 rewarding = _calculateAddingRewards(staker);
            rewards[staker] = rewards[staker] + rewarding;
            _totalRewards = _totalRewards + rewarding;
        }

        lastUpdatedTimes[staker] = current;
    }

    /*
        Get Adding rewardings not stored in storage
    */
    function _calculateAddingRewards(address staker) private view returns(uint256){
        uint256 total = allStakes;
        uint256 count = stakes[staker];
        
        if(!isRunning || lastUpdatedTimes[staker] == 0 || total == 0 || count == 0)
            return 0;
        
        uint256 current = block.timestamp;
        uint256 rewarding = (current - lastUpdatedTimes[staker]) * _rewardAmountPerSecond * count / total;

        return rewarding;
    }

    /*
        Get total Adding rewardings not stored in storage
    */
    function _calculateTotalAddingRewards() private view returns(uint256){
        uint256 totalAdding;
        for(uint256 i = 0; i < stakers.length; i++){
            totalAdding = totalAdding + _calculateAddingRewards(stakers[i]);
        }
        return totalAdding;
    }

    /*
        Update Rewardings for all stakers
    */
    function _updateAllRewards() private {
        for(uint256 i = 0; i < stakers.length; i++){
            _updateRewards(stakers[i]);
        }
    }

    /*
        Get Rewards amount per second by user
    */
    function rewardsPerSecond() external view returns(uint256){
        uint256 total = allStakes;
        uint256 count = stakes[msg.sender];
        if(total == 0 || count == 0) return 0;
        uint256 rewarding = _rewardAmountPerSecond * count / total;
        return rewarding;
    }

    /*
        Stake token
        note - user should call the token address and approve for the amount for this contract
    */
    function stake(uint256 amount) external {
        _updateRewards(msg.sender);

        allStakes = allStakes + amount;
        stakes[msg.sender] = stakes[msg.sender] + amount;
        stakingHistories.push(SnapStaking(msg.sender, block.timestamp, true, amount));
        _addStakerToArray(msg.sender);
        
        lastUpdatedTimes[msg.sender] = block.timestamp;

        tokenAddress.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /*
        Add staker to array, if not exists
    */
    function _addStakerToArray(address staker) private {
        for(uint256 i = 0; i < stakers.length; i ++){
            if(stakers[i] == staker){
                return;
            }
        }
        stakers.push(staker);
    }

    /*
        Unstake token
    */
    function unstake(uint256 amount) external {

        require(stakes[msg.sender] >= amount, "GHSP UnStaking: not enough staked token amount.");
        _updateRewards(msg.sender);

        allStakes = allStakes - amount;
        stakes[msg.sender] = stakes[msg.sender] - amount;
        stakingHistories.push(SnapStaking(msg.sender, block.timestamp, false, amount));

        tokenAddress.transfer(msg.sender, amount);
        emit UnStaked(msg.sender, amount);
    }

    /*
        Harvest rewardings
    */
    function harvest(uint256 amount) external {
        _updateRewards(msg.sender);
        require(_rewardCapacity >= amount, "Harvest Rewarding: not enough reward capacity.");
        require(amount > 0 && rewards[msg.sender] >= amount, "Harvest Rewarding: not enough rewards");

        rewards[msg.sender] = rewards[msg.sender] - amount;
        harvestingHistories.push(SnapHarvest(msg.sender, block.timestamp, true, amount));
        
        _totalHarvest = _totalHarvest + amount;
        _rewardCapacity = _rewardCapacity - amount;

        tokenAddress.transfer(msg.sender, amount);
        emit Harvest(msg.sender, amount);
    }

    /*
        Get amount of staked token per user
    */
    function balanceOfStakes() external view returns (uint256){
        return stakes[msg.sender];
    }

    /*
        Get reward amounts
    */
    function balanceOfRewards() external view returns(uint256){
        return _balanceOfRewards(msg.sender);
    }

    function _balanceOfRewards(address staker) private view returns(uint256){
        return rewards[staker] + _calculateAddingRewards(staker);
    }

    /*
        Get logs of stake and unstake per user
    */
    function historyOfStakes() external view returns(uint256[] memory, uint256[] memory, bool[] memory){
        uint256 len = 0;
        for(uint256 i = 0; i < stakingHistories.length; i ++){
            if(stakingHistories[i].user == msg.sender){
                len ++;
            }
        }

        uint256[] memory times = new uint256[](len);
        uint256[] memory tokens = new uint256[](len);
        bool[] memory status = new bool[](len);
        uint256 index = 0;

        for(uint256 i = 0; i < stakingHistories.length; i ++){
            if(stakingHistories[i].user == msg.sender){
                times[index] = stakingHistories[i].time;
                tokens[index] = stakingHistories[i].amount;
                status[index] = stakingHistories[i].status;
                index ++;
            }
        }
        return (times, tokens, status);
    }


    /*
        Get logs of harvest per user
    */
    function historyOfHarvest() external view returns(uint256[] memory, uint256[] memory, bool[] memory){
        uint256 len = 0;
        for(uint256 i = 0; i < harvestingHistories.length; i ++){
            if(harvestingHistories[i].user == msg.sender){
                len ++;
            }
        }

        uint256[] memory times = new uint256[](len);
        uint256[] memory amounts = new uint256[](len);
        bool[] memory status = new bool[](len);
        uint256 index = 0;

        for(uint256 i = 0; i < harvestingHistories.length; i ++){
            if(harvestingHistories[i].user == msg.sender){
                times[index] = harvestingHistories[i].time;
                amounts[index] = harvestingHistories[i].amount;
                status[index] = harvestingHistories[i].status;
                index ++;
            }
        }
        return (times, amounts, status);
    }

    /* ------------------------------ Admin Functions --------------------------------- */
    /*
        Deposit token for rewarding by admin
        note - user should call the token address and approve for the amount for this contract
    */
    function adminDepositReward(uint256 amount) external onlyOwner {
        _rewardCapacity = _rewardCapacity + amount;
        
        tokenAddress.transferFrom(msg.sender, address(this), amount);
        emit AdminDeposit(msg.sender, amount);
    }

    /*
        Withdraw rewarding token by admin
    */
    function adminWithdrawReward(uint256 amount) external onlyOwner {
        uint256 pendingRewards = _totalRewards + _calculateTotalAddingRewards() - _totalHarvest;
        require(_rewardCapacity - pendingRewards >= amount, "Admin Witdraw Rewards: not enough rewards capacity to withdraw");
        _rewardCapacity = _rewardCapacity - amount;

        tokenAddress.transfer(msg.sender, amount);
        emit AdminWithdraw(msg.sender, amount);
    }

    /*
        Get all logs of stake and unstake
    */
    function adminAllHistoriesOfStakes() external view onlyOwner returns(uint256[] memory, uint256[] memory, bool[] memory){
        uint256 len = stakingHistories.length;
        uint256[] memory times = new uint256[](len);
        uint256[] memory amounts = new uint256[](len);
        bool[] memory status = new bool[](len);

        for(uint256 i = 0; i < stakingHistories.length; i ++){
            if(stakingHistories[i].user == msg.sender){
                times[i] = stakingHistories[i].time;
                amounts[i] = stakingHistories[i].amount;
                status[i] = stakingHistories[i].status;
            }
        }
        return (times, amounts, status);
    }

    /*
        Get all logs of harvest
    */
    function adminAllHistoriesOfHarvest() public view onlyOwner returns(uint256[] memory, uint256[] memory, bool[] memory){
        uint256 len = harvestingHistories.length;
        uint256[] memory times = new uint256[](len);
        uint256[] memory amounts = new uint256[](len);
        bool[] memory status = new bool[](len);

        for(uint256 i = 0; i < harvestingHistories.length; i ++){
            times[i] = harvestingHistories[i].time;
            amounts[i] = harvestingHistories[i].amount;
            status[i] = harvestingHistories[i].status;
        }
        return (times, amounts, status);
    }

    /*
        Get rewards of staker
    */
    function adminRewards(address staker) public view onlyOwner returns(uint256){
        return _balanceOfRewards(staker);
    }

    /*
        Start or stop staking logic by admin
    */
    function adminSetRunning(bool running_) public onlyOwner{
        if(running_ == isRunning) return;
        _updateAllRewards();
        isRunning = running_;
    }


    /*
        Get Total Rewards, Harvest, Completed Harvest
    */
    function adminTotalRewardAndHarvest() public view onlyOwner returns(uint256, uint256, uint256){
        uint256 totalAdding = _calculateTotalAddingRewards();
        return (_rewardCapacity, _totalRewards + totalAdding, _totalHarvest);
    }

    /* 
        Update APY
    params:
        - nftTokenAddress: Contract Address of NFT
        - totalSupply: total amount of rewarding tokens
        - totalStakingPeriodDays: total time of staking for nft tokens by months
        - deciaml: decimal of rewarding token
    */
    function adminUpdateAPY(uint256 totalSupply_, uint256 totalPeriods_) public onlyOwner{
        require(totalSupply_ > 1e4, "Contract Constructor: Not Enough Supply Amount, bigger than 10K");
        require(totalPeriods_ > 0, "Contract Constructor: Not Enough Staking Period, bigger than 1 (months)");

        _updateAllRewards();
        totalSupply = totalSupply_;
        totalStakingPeriodDays = totalPeriods_;
        _updateRewardAmountPerSecond();

        emit AdminUpdatedAPY(totalSupply, totalStakingPeriodDays);
    }
}