//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Staking contract for FTMO-USDC
 */

import "./FTMOToken.sol";
import "./IERC20.sol";

contract FTMOStakingUSDCnew {
    struct _rewardInfo {
        uint256 totalRewards;
        uint256 runningSumPrevious;
        uint256 tokensStaked;
        uint256 rewardsClaimed;
    }

    uint256 public RATE;

    uint256 public totalTokensStaked;

    uint256 public runningSum;

    mapping(address => _rewardInfo) private _stakerInfo;

    address private _admin; // contract admin

    bool public poolActive; // is this pool active

    FTMOToken public FTMO; // main FTMO contract

    IERC20 public USDC; // USDC token contract

    uint256 public claimedTokens; // FTMO tokens claimed in total

    uint256 public lastTime; // last time since change

    uint256 public startTime;

    uint256 public totalFTMOToReward;

    bool public poolStarted;

    address[] public stakers; // array of all stakers

    mapping(address => bool) isStaker;

    /**------------------------------------------------------------------------
     * Constructor to initialize pool parameters
     * ------------------------------------------------------------------------
     */

    constructor(address admin)
    {
        _admin = admin;
        FTMO = FTMOToken(0x9bD0611610A0f5133e4dd1bFdd71C5479Ee77f37);
        USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); // USDC
        lastTime = 0;
        startTime = 0;
        RATE = 0;
        totalTokensStaked = 0;
        claimedTokens = 0;
        runningSum = 0;
        poolActive = false;
        poolStarted = false;
    }

    function startPool()
        external
        onlyAdmin
        poolNotStarted
    {
        startTime = block.timestamp;
        totalFTMOToReward = FTMO.balanceOf(address(this));
        RATE = totalFTMOToReward / (30 * 24 * 3600); // 30 days of staking
        poolStarted = true;
        poolActive = true;
    }

    function depositStake(uint256 amount)
        external
    {
        require(poolActive, "FTMOStakingUSDC: pool not active");
        require(amount > 0, "FTMOStakingUSDC: invalid deposit amount");
        require(
            USDC.allowance(msg.sender, address(this)) >= amount,
            "FTMOStakingUSDC: insufficient allowance"
        );
        require(
            USDC.balanceOf(msg.sender) >= amount,
            "FTMOStakingUSDC: not enough tokens"
        );

        USDC.transferFrom(msg.sender, address(this), amount);

        if (totalTokensStaked == 0) {
            lastTime = block.timestamp;
        } else {
            updateRunningSum();
        }
        totalTokensStaked += amount;

        uint256 sumPrevious = _stakerInfo[msg.sender].runningSumPrevious;
        uint256 staked = _stakerInfo[msg.sender].tokensStaked;

        _stakerInfo[msg.sender].totalRewards +=
            (staked *
            (runningSum - sumPrevious)) / 10**18;
        _stakerInfo[msg.sender].tokensStaked += amount;
        _stakerInfo[msg.sender].runningSumPrevious = runningSum;

        if (!isStaker[msg.sender]) {
            stakers.push(msg.sender);
            isStaker[msg.sender] = true;
        }
    }

    function withdrawStake(uint256 amount)
        external
        onlyStakers
    {
        require(totalTokensStaked > 0, "FTMOStakingUSDC: no tokens staked in pool");
        require(amount > 0, "FTMOStakingUSDC: invalid withdraw amount");
        uint256 balance = _stakerInfo[msg.sender].tokensStaked;
        require(amount <= balance, "FTMOStakingUSDC: over withdraw limit");

        updateRunningSum();

        // update stake
        uint256 newStake = balance - amount;
        uint256 sumPrevious = _stakerInfo[msg.sender].runningSumPrevious;
        totalTokensStaked -= amount;
        _stakerInfo[msg.sender].totalRewards +=
            (balance *
            (runningSum - sumPrevious)) / 10**18;
        _stakerInfo[msg.sender].tokensStaked = newStake;
        _stakerInfo[msg.sender].runningSumPrevious = runningSum;
        USDC.transfer(msg.sender, amount);
    }

    function rewardsWithdrawable(address staker)
        public
        onlyStakers
        returns (uint256)
    {
        updateRunningSum();

        uint256 maxWithdraw = 0;
        uint256 sumPrevious = _stakerInfo[staker].runningSumPrevious;
        uint256 staked = _stakerInfo[staker].tokensStaked;
        _stakerInfo[staker].totalRewards += (staked * (runningSum - sumPrevious)) / 10**18;
        _stakerInfo[staker].runningSumPrevious = runningSum;
        maxWithdraw = _stakerInfo[staker].totalRewards - _stakerInfo[staker].rewardsClaimed;
        return maxWithdraw;
    }

    function withdrawReward(uint256 amount)
        external
        onlyStakers
    {
        uint256 max = rewardsWithdrawable(msg.sender);
        require(
            amount <= max,
            "FTMOStakingUSDC: amount exceeds withdrawable FTMO"
        );

        _stakerInfo[msg.sender].rewardsClaimed += amount;
        claimedTokens += amount;
        FTMO.transfer(msg.sender, amount);
    }

    function addToTotalReward(uint256 amount)
        external
        onlyAdmin
    {
        totalFTMOToReward += amount;
        uint256 endTime = startTime + 30 * 24 * 3600;
        updateRunningSum();
        RATE += amount / (endTime - block.timestamp); // 30 days of staking
    }

    function subFromTotalReward(uint256 amount)
        external
        onlyAdmin
    {
        totalFTMOToReward -= amount;
        uint256 endTime = startTime + 30 * 24 * 3600;
        updateRunningSum();
        if ((amount / (endTime - block.timestamp)) < RATE) {
            RATE -= amount / (endTime - block.timestamp); // 30 days of staking
        } else {
            RATE = 0;
        }
    }

    function updateRunningSum()
        internal
    {
        if (totalTokensStaked > 0 && poolActive) {
            if ((startTime + 30 * 24 * 3600) > block.timestamp) {
                runningSum += ((10**18 * RATE * (block.timestamp - lastTime)) /
                    totalTokensStaked);
                lastTime = block.timestamp;
            }
        }
    }

    function getInfo(address staker)
        external
        view
        returns (_rewardInfo memory)
    {
        return _stakerInfo[staker];
    }

    function pausePool()
        external
        onlyAdmin
    {
        require(poolActive, "FTMOStakingUSDC: pool is paused");
        updateRunningSum();
        poolActive = false;
    }

    function resumePool()
        external
        onlyAdmin
    {
        require(!poolActive, "FTMOStakingUSDC: pool is active");
        lastTime = block.timestamp;
        poolActive = true;
    }

    function amIAdmin()
        external
        view
        returns (bool)
    {
        return (msg.sender == _admin);
    }

    function replaceAdmin(address newAdmin)
        external
        onlyAdmin
    {
        _admin = newAdmin;
    }

    // Only contract creator has certain privileges
    modifier onlyAdmin() {
        require(
            msg.sender == _admin,
            "FTMOStakingUSDC: only admin can do this"
        );
        _;
    }

    // Only stakers can withdraw
    modifier onlyStakers() {
        require(
            isStaker[msg.sender],
            "FTMOStakingUSDC: only stakers allowed"
        );
        _;
    }

    // Pool for the token cannot have already begun
    modifier poolNotStarted() {
        require(!poolStarted, "FTMOStakingUSDC: pool already started");
        _;
    }
}