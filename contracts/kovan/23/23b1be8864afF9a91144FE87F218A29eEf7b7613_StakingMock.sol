/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract StakingMock {

   struct Stake {
        uint72 tokenAmount;                   // Amount of tokens locked in a stake                                                             
        uint24 lockingPeriodInBlocks;         // Arbitrary lock period that will give you a reward                                    
        uint32 startBlock;                    // Start of the locking                                                                            
        uint128 expectedStakingRewardPoints;  // The amount of RewardPoints the stake will earn if not unlocked prematurely    
    }
    
    /// @notice Active stakes for each user
    mapping (address => Stake) public stakes;

    /// @notice "Reward points" each user earned (would be relative to totalRewardPoints to get the percentage)
    mapping (address => uint256) public rewardPointsEarned;
    
    /// @notice Total "reward points" all users earned
    uint256 public totalRewardPoints;
    /// @notice Block when Staking Program ends          
    uint256 public stakingProgramEndsBlock;
    /// @notice Amount of Staking Bonus Fund (500 000 OIL), Oiler funds must be here, approved and ready to be transferredFrom
    uint256 public stakingFundAmount;
    
    /// @notice The amount of OIL tokens earned, granted to be released during vesting period 
    mapping (address => uint256) public grantedTokens;
    /// @notice The amount of OIL tokens that were already released during vesting period
    mapping (address => uint256) public releasedTokens;
    
    /// @dev In blocks - should be around 100 days
    uint256 public vestingDuration;

    function prolongStakingProgramEnd(uint256 blocks) public {
        stakingProgramEndsBlock = block.number + blocks;
    }

    function prolongVestingDuration(uint256 blocks) public {
        vestingDuration = block.number + blocks;
    }

    function endStakingProgram() public {
        stakingProgramEndsBlock = block.number;
    }

    function endVesting() public {
        vestingDuration = block.number;
    }

    /// @dev Owner is used only in setPoolToken()
    // address public owner;

    constructor() {
        // require(owner_ != address(0x0), "Owner address cannot be zero");
        // owner = owner_;

        // require(oilerToken_ != address(0x0), "oilerToken address cannot be zero");
        // oilerToken = IERC20(oilerToken_);
        
        stakingProgramEndsBlock = block.number + 150;
        vestingDuration = 150;

        
        stakingFundAmount = 500000 * 1e18;
    }

        /**
     * @notice Calculates the RewardPoints user will earn for a given tokenAmount locked for a given period
     * @dev If any parameter is zero - it will fail, thus we save gas on "requires" by not checking in other places
     * @param tokenAmount_ - Amount of tokens to be stake.
     * @param lockingPeriodInBlocks_ - Lock duration defined in blocks.
     */
    function calculateStakingRewardPoints(uint72 tokenAmount_, uint24 lockingPeriodInBlocks_) public pure returns (uint128) {
        //
        //                         /                                   \
        //  stakingRewardPoints = ( tokenAmount * lockingPeriodInBlocks )  *  lockingPeriodInBlocks
        //                         \                                   /
        //

        uint256 stakingRewardPoints = uint256(tokenAmount_) * uint256(lockingPeriodInBlocks_) * uint256(lockingPeriodInBlocks_);
        require(stakingRewardPoints > 0, "Neither tokenAmount nor lockingPeriod couldn't be 0");
        return uint128(stakingRewardPoints);
    }

    /**
     * @notice Lock the LP tokens for a specified period of Blocks.
     * @notice Can only be called before Staking Program ends.
     * @notice And the locking period can't last longer than the end of Staking Program block.
     * @param tokenAmount_ - Amount of LP tokens to be locked.
     * @param lockingPeriodInBlocks_ - locking period duration defined in blocks.
     */
    function lockTokens(uint72 tokenAmount_, uint24 lockingPeriodInBlocks_) public {
        // Here we don't check lockingPeriodInBlocks_ for being non-zero, cause its happening in calculateStakingRewardPoints() calculation
        require(block.number <= stakingProgramEndsBlock - lockingPeriodInBlocks_, "Your lock period exceeds Staking Program duration");
        require(stakes[msg.sender].tokenAmount == 0, "Already staking");

        // This is a locking reward - will be earned only after the full lock period is over - otherwise not applicable
        uint128 expectedStakingRewardPoints = calculateStakingRewardPoints(tokenAmount_, lockingPeriodInBlocks_);

        Stake memory stake = Stake(tokenAmount_, lockingPeriodInBlocks_, uint32(block.number), expectedStakingRewardPoints);
        stakes[msg.sender] = stake;
        
        // We add the rewards initially during locking of tokens, and subtract them later if unlocking is made prematurely
        // That prevents us from waiting for all users to unlock to distribute the rewards after Staking Program Ends
        totalRewardPoints += expectedStakingRewardPoints;
        rewardPointsEarned[msg.sender] += expectedStakingRewardPoints;
        
        // We transfer LP tokens from user to this contract, "locking" them
        // We don't check for allowances or balance cause it's done within the transferFrom() and would only raise gas costs
        // require(poolToken.transferFrom(msg.sender, address(this), tokenAmount_), "TransferFrom of poolTokens failed");

        emit StakeLocked(msg.sender, tokenAmount_, lockingPeriodInBlocks_, expectedStakingRewardPoints);
    }

    /**
     * @notice Unlock the tokens and get the reward
     * @notice This can be called at any time, even after Staking Program end block
     */
    function unlockTokens() public {
        Stake memory stake = stakes[msg.sender];

        uint256 stakeAmount = stake.tokenAmount;

        require(stakeAmount != 0, "You don't have a stake to unlock");

        require(block.number > stake.startBlock, "You can't withdraw the stake in the same block it was locked");

        // Check if the unlock is called prematurely - and subtract the reward if it is the case
        _punishEarlyWithdrawal(stake);

        // Zero the Stake - to protect from double-unlocking and to be able to stake again
        delete stakes[msg.sender];

        // require(poolToken.transfer(msg.sender, stakeAmount), "Pool token transfer failed");
    }

    /**
     * @notice If the unlock is called prematurely - we subtract the bonus
     */
    function _punishEarlyWithdrawal(Stake memory stake_) internal {
        // As any of the locking periods can't be longer than Staking Program end block - this will automatically mean that if called after Staking Program end - all stakes locking periods are over
        // So no rewards can be manipulated after Staking Program ends
        if (block.number < (stake_.startBlock + stake_.lockingPeriodInBlocks)) { // lt - cause you can only withdraw at or after startBlock + lockPeriod
            rewardPointsEarned[msg.sender] -= stake_.expectedStakingRewardPoints;
            totalRewardPoints -= stake_.expectedStakingRewardPoints;
            emit StakeUnlockedPrematurely(msg.sender, stake_.tokenAmount, stake_.lockingPeriodInBlocks, block.number - stake_.startBlock);
        } else {
            emit StakeUnlocked(msg.sender, stake_.tokenAmount, stake_.lockingPeriodInBlocks, stake_.expectedStakingRewardPoints);
        }
    }

    /** 
     * @notice This can only be called after the Staking Program ended
     * @dev Which means that all stakes lock periods are already over, and totalRewardPoints value isn't changing anymore - so we can now calculate the percentages of rewards
     */
    function getRewards() public {
        require(block.number > stakingProgramEndsBlock, "You can only get Rewards after Staking Program ends");
        require(stakes[msg.sender].tokenAmount == 0, "You still have a stake locked - please unlock first, don't leave free money here");
        require(rewardPointsEarned[msg.sender] > 0, "You don't have any rewardPoints");
        
        // The amount earned is calculated as:
        //
        //                                  user RewardPoints earned during Staking Program
        // amountEarned = stakingFund * -------------------------------------------------------
        //                                 total RewardPoints earned by everyone participated
        //
        // Division always rounds towards zero in solidity.
        // And because of this rounding somebody always misses the fractional part of their earnings and gets only integer amount.
        // Thus the worst thing that can happen is amountEarned becomes 0, and we check for that in _grantTokens()
        uint256 amountEarned = stakingFundAmount * rewardPointsEarned[msg.sender] / totalRewardPoints;
        rewardPointsEarned[msg.sender] = 0; // Zero rewardPoints of a user - so this function can be called only once per user

        _grantTokens(msg.sender, amountEarned); // Grant OIL reward earned by user for future vesting during the Vesting period
    }

    //////////////////////////////////////////////////////
    //
    //     VESTING PART
    //
    //////////////////////////////////////////////////////
    

    /**
     * @param recipient_ - Recipient of granted tokens
     * @param amountEarned_ - Amount of tokens earned to be granted
     */
    function _grantTokens(address recipient_, uint256 amountEarned_) internal {
        require(amountEarned_ > 0, "You didn't earn any integer amount of wei");
        require(recipient_ != address(0), "TokenVesting: beneficiary is the zero address");
        grantedTokens[recipient_] = amountEarned_;
        emit RewardGranted(recipient_, amountEarned_);
    }
    
    /// @notice Releases granted tokens
    function release() public {
        uint256 releasable = _releasableAmount(msg.sender);
        require(releasable > 0, "Vesting release: no tokens are due");

        releasedTokens[msg.sender] += releasable;
        // require(oilerToken.transfer(msg.sender, releasable), "Reward oilers transfer failed");

        emit grantedTokensReleased(msg.sender, releasable);
    }
    
    /// @notice Releasable amount is what is available at a given time minus what was already withdrawn
    function _releasableAmount(address recipient_) internal view returns (uint256) {
        return _vestedAmount(recipient_) - releasedTokens[recipient_];
    }
    
    /**
     * @notice The output of this function gradually changes from [0.. to ..grantedAmount] while the vesting is going
     * @param recipient_ - vested tokens recipient
     * @return vested amount
     */
    function _vestedAmount(address recipient_) internal view returns (uint256) {
        if (block.number >= stakingProgramEndsBlock + vestingDuration) {
            // Return the full granted amount if Vesting Period is over
            return grantedTokens[recipient_];
        } else {
            // Return the proportional amount if Vesting Period is still going
            return grantedTokens[recipient_] * (block.number - stakingProgramEndsBlock) / vestingDuration;
        }
    }
    
    event StakeLocked(address recipient, uint256 tokenAmount, uint256 lockingPeriodInBlocks, uint256 expectedStakingRewardPoints);
    event StakeUnlockedPrematurely(address recipient, uint256 tokenAmount, uint256 lockingPeriodInBlocks, uint256 actualLockingPeriodInBlocks);
    event StakeUnlocked(address recipient, uint256 tokenAmount, uint256 lockingPeriodInBlocks, uint256 rewardPoints);
    event RewardGranted(address recipient, uint256 amountEarned);
    event grantedTokensReleased(address recipient, uint256 amount);
}