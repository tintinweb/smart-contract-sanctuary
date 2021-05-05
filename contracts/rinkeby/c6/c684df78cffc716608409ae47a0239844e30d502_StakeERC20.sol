/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract StakeERC20 {
    
    using SafeMath for uint256;
    address public governance;
    
    uint256 private BIGNUMBER = 10**18;

    struct StakeHolder {
        bool isClaimed;                 // Current Staking status
        uint256 amount;                 // Current active stake
        uint256 stakedBlock;            // Last staked block (if any)
        uint256 releaseBlock;           // Last claimed block (if any)
        uint256 lastClaimedOn;          // Last time claimed
        uint256 totalStakeLocked;       // Total Staked Locked during the whole contract period
        uint256 totalStakeWithdrawn;    // Total Staked Withdraw during the whole contract period
        uint256 totalRewardsClaimed;    // Total rewards claimed during the whole contract period
    }
    
    /**
     * @dev Mapping of All StakeHolders.
     */
    mapping (address => StakeHolder) public StakeHolders;
    address[] private allStakeHolders;
    
    /**
     * @dev Reward Token Address.
     */
    address private rewardToken;
    
    /**
     * @dev Allowed Stake Token Address.
     */
    address private stakeToken;
    
    /**
     * @dev Rewards to Pay to user per block, per token in wei
     */
    uint256 private weight;
    
    /**
     * @dev Total No.of Tokens Staked in Contract
     */
    uint256 private totalTokensStaked;

    bool public isStakingActive;
    bool public isStakingPaused;
    bool public isStakingClosed;
    
    /**
     * @dev Currenly active staked tokens in Contract
     */
    uint256 private currentStakedTokens;
    
    /**
     * @dev Total Staked Rewards in Contract -> Sum of all the Reward Tokens Paid to users
     */
    uint256 private totalTokensRewarded;
    
    /**
     * @dev Total no.of tokens to reward used, will be updated everytime there is a stake & claim
     */
    uint256 private tokensToPayForReward;

    /**
     * @param _rewardToken address of the Token which user get rewarded
     * @param _stakingToken address of the Token whcih user stakes
     * @param _weight rewards awarded to user per block, per token user stakes in wei
     */
    constructor(address _rewardToken, address _stakingToken, uint256 _weight) {
        rewardToken = _rewardToken;
        stakeToken= _stakingToken;
        weight = _weight;
        governance = msg.sender;
    }

    /**
     * @dev Allow users to stake the Tokens.
     * @notice Only after this function execution only, user can stake tokens
     */
    function allowStaking() public {
        require(_msgSender() == governance, "!governance");
        isStakingActive = true;
        isStakingPaused = false;
        isStakingClosed = false;
    }

    /**
     * @dev Close staking of the Tokens.
     * @notice Once closeStaking, Can't revert back to active Stake
     */
    function closeStaking() public {
        require(_msgSender() == governance, "!governance");
        isStakingActive = false;
        isStakingPaused = false;
        isStakingClosed = true;
    }

    /**
     * @dev Pause Staking of the Tokens, this restrict user to stake and claim.
     */
    function pauseStaking() public {
        require(_msgSender() == governance, "!governance");
        isStakingPaused = true;
    }

    /**
     * @dev Unpause Staking of the Tokens, this allow user to stake and claim.
     */
    function unPauseStaking() public {
        require(_msgSender() == governance, "!governance");
        isStakingPaused = false;
    }

    /**
     * @dev Returns the address of the Staked Tokens of this Contract
     */
    function stakedToken() public view returns (address) {
        return stakeToken;
    }

    /**
     * @dev Returns the address of the Reward Tokens (FXF)
     */
    function rewardedToken() public view returns (address) {
        return rewardToken;
    }
    
    /**
     * @dev Returns No.of tokens staked till now
     */
    function totalTokensStakedTillNow() public view returns (uint256) {
        return totalTokensStaked;
    }

    /**
     * @dev Returns No.of tokens rewarded till now
     */
    function totalTokensRewardedTillNow() public view returns (uint256) {
        return totalTokensRewarded;
    }

    /**
     * @dev Returns active staked tokens
     */
    function activeStakedTokens() public view returns (uint256) {
        return currentStakedTokens;
    }

    /**
     * @dev Returns the caller of the contract
     */
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    
    /**
     * @dev Update the token rewards of Contract
     */
    function updateWeight(uint256 _weight) external {
        require(_msgSender() == governance, "!governance");
        weight = _weight;
    }

    /**
     * @dev Returns current Block Timestamp
     */
    function currentBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns current Block Timestamp
     */
    function currentBlockNumber() public view returns (uint256) {
        return block.number;
    }
    
    /**
     * @dev Event to trigger post successful staking
     */
    event staked(address _address, uint256 stakedTokens, uint256 claimAfter);

    /**
     * @dev Stake the tokens to contract
     * @param _noOfTokens no.of tokens adding into contract
     * @param _noOfBlocks duration of the staking period (in no.of Blocks)
     */
    function stake(uint256 _noOfTokens, uint256 _noOfBlocks) public {

        // Won't allow user to stake unless taking started
        require(isStakingActive == true, "Staking is not started");

        // Won't allow user to stake when contract is paused 
        require(isStakingPaused == false, "Staking is paused");

        // Won't allow user to stake when contract is closed
        require(isStakingClosed == false, "Staking is closed");

        // _noOfTokens can't zero
        require(_noOfTokens > 0, "Tokens can not be zero");

        // User can have only one active staking at a time, if user want to stake again, user has to claim first then stake again
        require(StakeHolders[msg.sender].amount == 0, "Already staked, Can not change the staking");

        // Update StakeHolders info
        StakeHolders[msg.sender].amount = _noOfTokens;
        StakeHolders[msg.sender].isClaimed = false;
        StakeHolders[msg.sender].stakedBlock = block.number;
        StakeHolders[msg.sender].releaseBlock = (block.number).add(_noOfBlocks);
        StakeHolders[msg.sender].totalStakeLocked = StakeHolders[msg.sender].totalStakeLocked.add(_noOfTokens);

        // Calculate the No.of Blocks that user is staking
        uint256 durationStaked = ((block.number).add(_noOfBlocks)).sub(block.number);

        // Calculate the no.of rewards user is entitled
        uint256 rewardTokens = _noOfTokens.mul(durationStaked.mul(weight));
        rewardTokens = rewardTokens.div(BIGNUMBER);
        tokensToPayForReward = tokensToPayForReward.add(rewardTokens);

        // Check if the contract has enough rewards to pay for this user or contract reward limit exceeded
        uint256 tokensAvailableForReward = IERC20(rewardToken).balanceOf(address(this));

        // Revert if there are not enough rewards to reward user
        require(tokensAvailableForReward >= tokensToPayForReward, "Insufficiant rewards");

        // Check if the transfer of the token to contract is success
        require(IERC20(stakeToken).transferFrom(msg.sender, address(this), _noOfTokens));

        // Update the total tokens staked 
        totalTokensStaked = totalTokensStaked.add(_noOfTokens);

        // Update the current tokens staked
        currentStakedTokens = currentStakedTokens.add(_noOfTokens);

        // Add the user to stakeholder list
        allStakeHolders.push(msg.sender);

        // Trigger event of staking
        emit staked(msg.sender, _noOfTokens, _noOfBlocks);
    }
    
    
    /**
     * @dev Stake the tokens to contract
     * @param _noOfTokens no.of tokens adding into contract
     * @param _noOfBlocks duration of the staking period (in no.of Blocks)
     */
    function calculateRewardsInAdvance(uint256 _noOfTokens, uint256 _noOfBlocks) public view returns (uint256) {

        // Calculate the no.of rewards user is entitled
        uint256 rewardTokens = _noOfTokens.mul(_noOfBlocks.mul(weight));
        rewardTokens = rewardTokens.div(BIGNUMBER);
        
        return rewardTokens;
    }
    
    /**
     * @dev Event to trigger post successful claiming of tokens
     */
    event claimed(address _address, uint256 stakedTokens, uint256 claimedTokens);

    function claim() public {
        // User can't claim when the staking is paused
        require(isStakingPaused == false, "Claiming is Paused");

        // User can't claim if the user token balance is Zero
        require(StakeHolders[msg.sender].amount > 0, "Can not claim Zero tokens");

        // User can't claim before release block / date / duration
        require(block.number > StakeHolders[msg.sender].releaseBlock, "You can not claim before staked duration");

        // Tokens staked by user
        uint256 stakedTokens = StakeHolders[msg.sender].amount;

        // Rewards entitled by user
        uint256 rewardTokens = calculateRewards(msg.sender);

        // Transfer staked tokens to msg.sender
        require(IERC20(stakeToken).transfer(msg.sender, stakedTokens));

        // Transfer reward tokens to msg.sender
        require(IERC20(rewardToken).transfer(msg.sender, rewardTokens));

        // Update StakeHolders info
        StakeHolders[msg.sender].amount = 0;
        StakeHolders[msg.sender].isClaimed = true;
        StakeHolders[msg.sender].lastClaimedOn = block.timestamp;
        StakeHolders[msg.sender].totalStakeLocked = StakeHolders[msg.sender].totalStakeLocked.sub(stakedTokens);
        StakeHolders[msg.sender].totalStakeWithdrawn = StakeHolders[msg.sender].totalStakeWithdrawn.add(stakedTokens);
        StakeHolders[msg.sender].totalRewardsClaimed = StakeHolders[msg.sender].totalRewardsClaimed.add(rewardTokens);

        // Update tokensToPayForReward 
        tokensToPayForReward = tokensToPayForReward.sub(rewardTokens);

        // Update currentStakedTokens 
        currentStakedTokens = currentStakedTokens.sub(stakedTokens);

        // Update totalTokensRewarded 
        totalTokensRewarded = totalTokensRewarded.add(rewardTokens);

        // Trigger claimed event
        emit claimed(msg.sender, stakedTokens, rewardTokens);
    }
    
    /**
     * @dev User can calculate the rewards of the active stake
     * @param _address of the user to whom you want to know the stake 
     */
    function calculateRewards(address _address) public view returns (uint256) {
        uint256 stakedTokens = StakeHolders[_address].amount;
        uint256 durationStaked = stakedTerm(_address);
        uint256 rewardTokens = stakedTokens.mul(durationStaked.mul(weight));
        rewardTokens = rewardTokens.div(BIGNUMBER);
        return rewardTokens;
    }
    
    /**
     * @dev Returns the rewards per token and per block in Wei
     */
    function rewardPerToken() public view returns (uint256) {
        return weight;
    }

    /**
     * @dev Returns the staked term of the current active stake
     * @param _address of the user to whom you want to know the staking duration in Blocks
     */
    function stakedTerm(address _address) internal view returns (uint256) {
        return(StakeHolders[_address].releaseBlock).sub(StakeHolders[_address].stakedBlock);
    }

    /**
     * @dev Returns the total no.of tokens rewarded to an address
     * @param _address of the user to whom you want to know the staking rewards
     */
    function tokensRewarded(address _address) public view returns (uint256) {
        return StakeHolders[_address].totalRewardsClaimed;
    }

    /**
     * @dev Returns the claim status of the current active stake
     * @notice there will be only one active stake at all the time
     * @param _address of the user to whom you want to know the claim status
     */    
    function claimStatus(address _address) public view returns (bool) {
        return StakeHolders[_address].isClaimed;
    }

    /**
     * @dev Governance can withdraw the reward tokens locked in Contract
     * @notice  This can execute only after closing stake,
     * Only governance can execute this,
     * Unclaimed rewards of the user are stored in the contract and balance rewards will be transferred to governance
     */
    function withdrawBalanceRewardTokens() public {
        // Only Governance can call
        require(_msgSender() == governance, "!governance");

        // Can execute only after staking closed of the contract
        require(isStakingClosed == true, "Staking is not Closed");
        
        uint256 totalStakedTokens;
        uint256 totalBlocks;
        uint256 balance;
        for(uint256 i=0; i<allStakeHolders.length; i++) {
            if(StakeHolders[allStakeHolders[i]].isClaimed == false) {
                totalStakedTokens = totalStakedTokens.add(StakeHolders[allStakeHolders[i]].amount);
                totalBlocks = totalBlocks.add((StakeHolders[allStakeHolders[i]].releaseBlock).sub(StakeHolders[allStakeHolders[i]].stakedBlock)); 
            }
        }

        // Calculate the reward token balance of the contract
        uint256 balanceInContract = IERC20(rewardToken).balanceOf(address(this));

        // Calculate the rewards to maintain in the contract (there might be unclaimed rewards which governance can't withdraw)
        uint256 rewardsToMaintainInContract = totalStakedTokens.mul(totalBlocks).mul(weight).div(BIGNUMBER);

        // Can't withdraw if the balance of reward tokens and rewards to maintain in contract is same
        if(balanceInContract == rewardsToMaintainInContract) {
            revert("Tokens to maintain and Tokens in Contract are equal");
        }

        // If the contract has more rewards after calculating the rewards to maintain, then the extra rewards tokens will be transfered to governance        
        if(balanceInContract > rewardsToMaintainInContract) {
            balance = balanceInContract - rewardsToMaintainInContract;
            IERC20(rewardToken).transfer(governance, balance);
        }
    }

    /**
     * @dev Governance function to calculate the rewards to maintain in Contract
     * @notice this scenario never occur, but just to calculate the rewards
     */
    function rewardsToMaintain() public view returns (uint256, uint256) {       
        uint256 totalStakedTokens;
        uint256 totalBlocks;
        uint256 totalTokensToMaintain;

        // Calculate the tokens staked in Contract
        uint256 alreadyInContract = IERC20(rewardToken).balanceOf(address(this));
        
        for(uint256 i=0; i<allStakeHolders.length; i++) {
            if(StakeHolders[allStakeHolders[i]].isClaimed == false) {
                totalStakedTokens = totalStakedTokens.add(StakeHolders[allStakeHolders[i]].amount);
                totalBlocks = totalBlocks.add((StakeHolders[allStakeHolders[i]].releaseBlock).sub(StakeHolders[allStakeHolders[i]].stakedBlock));   
            }
        }
        
        // Calculate the rewards to maintain
        totalTokensToMaintain =  totalStakedTokens.mul(totalBlocks).mul(weight).div(BIGNUMBER);

        // Return the tokens to Maintain in contract and the tokens already in contract
        return (totalTokensToMaintain, alreadyInContract);
    }
    
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}