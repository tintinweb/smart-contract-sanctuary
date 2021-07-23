// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract StakingRewards {
    
    using SafeMath for uint256;
    address public governance;
    
    uint256 private BIGNUMBER = 10**18;

    struct StakeHolder {
        bool isClaimed;                 // Current Staking status
        uint256 amount;                 // Current active stake
        uint256 stakedBlock;            // Last staked block (if any)
        uint256 releaseBlock;           // Last claimed block (if any)
        uint256 claimedOn;              // Last time claimed
        uint256 rewards;                // Rewards
    }
    mapping (address => StakeHolder) public StakeHolders;
    address[] private allStakeHolders;
    
    address public rewardToken;
    address public stakeToken;

    bool public isStakingActive;
    bool public isStakingPaused;
    bool public isStakingClosed;
    
    uint256 public stakingPool;
    uint256 public stakingPoolRewards;
    uint256 public stakingStartTime;
    uint256 public stakingDuration;
    uint256 public noOfStakingBlocks;
    uint256 public poolOpenTime;
    
    // 6440 is the avg no.of Ethereum Blocks per day, Applicable only for Ethereum network 
    uint256 public avgETHBlocksPerDay = 6440;
    uint256 public currentPool;

    event Staked(address _address, uint256 stakedTokens);
    event StakeClaimed(address _address, uint256 stakedTokens, uint256 claimedTokens);

    /**
     * @param _rewardToken address of the Token which user get rewarded
     * @param _stakingToken address of the Token which user stakes
     * @param _stakingPool is the total no.of tokens to meet the requirement to start the staking
     * @param _stakingPoolRewards is the total no.of rewards for the _rewardCapital
     * @param _stakingStartTime is the starting block of staking in epoch
     * @param _stakingDuration is the statking duration of staking ex: 30 days, 60 days, 90 days... in days
     */
    constructor(address _stakingToken, address _rewardToken, uint256 _stakingPool, uint256 _stakingPoolRewards, uint256 _poolOpenTime, uint256 _stakingStartTime, uint256 _stakingDuration) {
        stakeToken= _stakingToken;
        rewardToken = _rewardToken;
        stakingPool = _stakingPool;
        stakingPoolRewards = _stakingPoolRewards;
        stakingStartTime = _stakingStartTime;
        stakingDuration = _stakingDuration;
        poolOpenTime = _poolOpenTime;
        calculateBlocks(_stakingDuration);
        governance = msg.sender;
        isStakingActive = true;
        isStakingPaused = false;
        isStakingClosed = false;
    }
    
    function calculateBlocks(uint256 _days) internal {
        // Comment in Testing
        // noOfStakingBlocks = 1;
        // noOfStakingBlocks = noOfStakingBlocks.mul(_days).mul(avgETHBlocksPerDay);

        // Comment in Production
        noOfStakingBlocks = 10;
    }
    
    modifier onlyGovernance {
        require(msg.sender == governance, "Unauthorized Access");
        _;
    }
    
    /**
     * @dev Stake Tokens
     */
    function stake(uint256 _noOfTokens) external {
        require(isStakingActive == true, "Staking is not started");
        require(isStakingPaused == false, "Staking is paused");
        require(isStakingClosed == false, "Staking is closed");
        require(_noOfTokens > 0, "Can not stake Zero Tokens");
        require(currentBlockTimestamp() > poolOpenTime, "Staking have not started for this pool");
        require(currentBlockTimestamp() < stakingStartTime, "Staking Closed");
        require(stakingPool >= currentPool, "Staking Pool is Full");
        require(stakingPool >= currentPool.add(StakeHolders[msg.sender].amount.add(_noOfTokens)), "Pool is open, your staking exceeded Staking Pool!");
        IERC20(stakeToken).transferFrom(msg.sender, address(this), _noOfTokens);
        updateStakingInfo(_noOfTokens);
        currentPool = currentPool.add(StakeHolders[msg.sender].amount.add(_noOfTokens));
        allStakeHolders.push(msg.sender);
        emit Staked(msg.sender, _noOfTokens);
    }
    
    /**
     * @dev Update Stake Info in StakeHolder
     */
    function updateStakingInfo(uint256 _noOfTokens) internal {
        StakeHolders[msg.sender].amount = StakeHolders[msg.sender].amount.add(_noOfTokens);
        StakeHolders[msg.sender].isClaimed = false;
        StakeHolders[msg.sender].releaseBlock = (currentBlockNumber()).add(noOfStakingBlocks);
        StakeHolders[msg.sender].rewards = calculateStakingReward(_noOfTokens);
    }
    
    // Change this function visibility from public to internal
    /**
     * @dev Calculate Staking Reward based on the stake
     */
    function calculateStakingReward(uint256 _noOfTokens) public view returns (uint256) {
        uint256 userShareInPool = (_noOfTokens.mul(100)).div(stakingPool);
        return StakeHolders[msg.sender].rewards.add((userShareInPool.mul(stakingPoolRewards)).div(100));
    }
    
    /**
     * @dev claimStake to claim staking & also rewards
     */
    function claimStake() external {
        require(isStakingPaused == false, "Claiming is Paused");
        require(StakeHolders[msg.sender].isClaimed == false, "Already Claimed");
        require(StakeHolders[msg.sender].amount > 0, "Seems like haven't staked to claim");
        require(currentBlockNumber() > StakeHolders[msg.sender].releaseBlock, "You can not claim before staked duration");
        require(IERC20(stakeToken).balanceOf(address(this)) >= StakeHolders[msg.sender].amount, "Invalid Balance");
        require(IERC20(rewardToken).balanceOf(address(this)) >= StakeHolders[msg.sender].rewards, "Invalid Balance");
        IERC20(stakeToken).transfer(msg.sender, StakeHolders[msg.sender].amount);
        IERC20(rewardToken).transfer(msg.sender, StakeHolders[msg.sender].rewards);
        updateClaimInfo();
        emit StakeClaimed(msg.sender, StakeHolders[msg.sender].amount, StakeHolders[msg.sender].rewards);
    }
    
    /**
     * @dev Update Claim Info in StakeHolder
     */
    function updateClaimInfo() internal {
        StakeHolders[msg.sender].isClaimed = true;
        StakeHolders[msg.sender].amount = 0;
        StakeHolders[msg.sender].rewards = 0;
        StakeHolders[msg.sender].releaseBlock = 0;
        StakeHolders[msg.sender].claimedOn = currentBlockTimestamp();
    }

    /**
     * @dev Close staking of the Tokens.
     * @notice Once closeStaking, Can't revert back to active Stake
     */
    function closeStaking() external onlyGovernance {
        isStakingActive = false;
        isStakingPaused = false;
        isStakingClosed = true;
    }

    /**
     * @dev Pause Staking of the Tokens, this restrict user to stake and claim.
     */
    function pauseStaking() external onlyGovernance {
        isStakingPaused = true;
    }

    /**
     * @dev Unpause Staking of the Tokens, this allow user to stake and claim.
     */
    function unPauseStaking() external onlyGovernance {
        isStakingPaused = false;
    }

    /**
     * @dev Returns current Block Timestamp
     */
    function currentBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns current Block Timestamp
     */
    function currentBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @dev Returns the claim status of the current active stake
     * @notice there will be only one active stake at all the time
     * @param _address of the user to whom you want to know the claim status
     */    
    function claimStatus(address _address) external view returns (bool) {
        return StakeHolders[_address].isClaimed;
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
        // totalTokensToMaintain =  totalStakedTokens.mul(totalBlocks).mul(weight).div(BIGNUMBER);

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}