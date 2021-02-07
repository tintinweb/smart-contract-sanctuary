/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        return (a + m - 1) / m * m;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
}

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
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0),"Invalid address passed");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract IFY_Stake is Owned {
    using SafeMath for uint256;
    
    IERC20 public IFY;
    
    uint256 public  totalClaimedRewards;
    uint256 public  totalStaked;
    
    struct Account{
        uint256 stakedAmount;
        uint256 rewardsClaimed;
        uint256 pending;
        uint256 stakingOpt;
        uint256 stakingEndDate;
        uint256 rewardPercentage;
    }
    
    mapping(address => Account) public stakers;
    
    struct StakingOpts{
        uint256 stakingPeriod;
        uint256 stakingPercentage;
    }
    
    StakingOpts[4] public stakingOptions;
    
    event RewardClaimed(address claimer, uint256 reward);
    event UnStaked(address claimer, uint256 stakedTokens);
    event Staked(address staker, uint256 tokens, uint256 stakingOption);
    
    constructor() public {
        /*
        1 week: 5% ROI
        1 month: 25% ROI
        3 months: 100% ROI
        6 months: 245% ROI
        */
        stakingOptions[0].stakingPeriod = 1 weeks;
        stakingOptions[0].stakingPercentage = 5;
        
        stakingOptions[1].stakingPeriod = 30 days; // 1 month
        stakingOptions[1].stakingPercentage = 25;
        
        stakingOptions[2].stakingPeriod = 90 days;
        stakingOptions[2].stakingPercentage = 100;
        
        stakingOptions[3].stakingPeriod = 180 days;
        stakingOptions[3].stakingPercentage = 245;
        
        owner = 0xa97F07bc8155f729bfF5B5312cf42b6bA7c4fCB9;
    }
    
    // ------------------------------------------------------------------------
    // Set Token Address
    // only Owner can use it
    // @param _tokenAddress the address of token
    // -----------------------------------------------------------------------
    function setTokenAddress(address _tokenAddress) external onlyOwner{
        IFY = IERC20(_tokenAddress);
    }
    
    // ------------------------------------------------------------------------
    // Start the staking or add to existing stake
    // user must approve the staking contract to transfer tokens before staking
    // @param _amount number of tokens to stake
    // ------------------------------------------------------------------------
    function STAKE(uint256 _amount, uint256 optionNumber) external {
        require(optionNumber >= 1 && optionNumber <= 4, "Invalid option choice");
        require(stakers[msg.sender].stakedAmount == 0, "Your stake is already running");
        
        // no tax will be applied upon staking IFY
        totalStaked = totalStaked.add(_amount);
        
        // record it in contract's storage
        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.add(_amount); // add to the stake or fresh stake
        stakers[msg.sender].stakingOpt = optionNumber;
        stakers[msg.sender].stakingEndDate = block.timestamp.add(stakingOptions[optionNumber.sub(1)].stakingPeriod);
        stakers[msg.sender].rewardPercentage = stakingOptions[optionNumber.sub(1)].stakingPercentage;
        
        emit Staked(msg.sender, _amount, optionNumber);
        
        // transfer the tokens from caller to staking contract
        require(IFY.transferFrom(msg.sender, address(this), _amount));
    }
    
    function Exit() external{
        if(pendingReward(msg.sender) > 0)
            ClaimReward();
        if(stakers[msg.sender].stakedAmount > 0)
            UnStake();
    }
    
    // ------------------------------------------------------------------------
    // Claim reward
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimReward() public {
        require(pendingReward(msg.sender) > 0, "nothing pending to claim");
        require(block.timestamp > stakers[msg.sender].stakingEndDate, "claim date has not reached");
        
        uint256 reward = pendingReward(msg.sender);
        
        // add claimed reward to global stats
        totalClaimedRewards = totalClaimedRewards.add(reward);
        
        // add the reward to total claimed rewards
        stakers[msg.sender].rewardsClaimed = stakers[msg.sender].rewardsClaimed.add(reward);
        
        emit RewardClaimed(msg.sender, reward);
        
        // transfer the reward tokens
        require(IFY.transfer(msg.sender, reward), "reward transfer failed");
    }
    
    // ------------------------------------------------------------------------
    // Unstake the tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function UnStake() public {
        uint256 stakedAmount = stakers[msg.sender].stakedAmount;
        require(stakedAmount > 0, "insufficient stake");
        require(block.timestamp > stakers[msg.sender].stakingEndDate, "staking period has not ended");
        
        totalStaked = totalStaked.sub(stakedAmount);
        
        if(pendingReward(msg.sender) > 0)
            stakers[msg.sender].pending = pendingReward(msg.sender);
        
        stakers[msg.sender].stakedAmount = 0;
        
        emit UnStaked(msg.sender, stakedAmount);
        
        // transfer staked tokens
        require(IFY.transfer(msg.sender, stakedAmount));
    }
    
    // ------------------------------------------------------------------------
    // Query to get the pending reward
    // ------------------------------------------------------------------------
    function pendingReward(address user) public view returns(uint256 _pendingReward){
        uint256 reward = (onePercent(stakers[user].stakedAmount)).mul(stakers[user].rewardPercentage);
        reward =  reward.sub(stakers[user].rewardsClaimed);
        return reward.add(stakers[msg.sender].pending);
    }
    
    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
}