/**
 *Submitted for verification at Etherscan.io on 2021-04-05
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
        require(m != 0, "SafeMath: to ceil number shall not be zero");
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

interface IRW{
    function sendRewards(address to, uint256 tokens) external;
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

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract Staking is Owned {
    using SafeMath for uint256;
    
    IERC20 token;
    
    uint256 private minStakeAmount = 1 * 10 ** (18);

    
    uint256 public  totalClaimedRewards;
    uint256 public  totalStaked;
    uint256 private totalDividentPoints;
    uint256 private unclaimedDividendPoints;
    uint256 pointMultiplier = 1000000000000000000;
    
    struct Account{
        uint256 stakedAmount;
        uint256 rewardsClaimed;
        uint256 pendingAPY;
        uint256 pendingDIV;
        uint256 plan;
        uint256 rewardClaimDate;
        uint256 lastDividentPoints;
        uint256 timeInvest;
        uint256 lastClaimed;
    }
    
    mapping(address => Account) public stakers;
    
    struct StakingPlan{
        uint256 totalDays;
        uint256 APY;
        uint256 EWF;
        mapping (address => bool) whiteList;
    }
    
    mapping(uint256 => StakingPlan) stakingPlans;
    
    event RewardClaimed(address claimer, uint256 reward);
    event UnStaked(address claimer, uint256 stakedTokens);
    event Staked(address staker, uint256 tokens);
    
    event MinTokensPerUserChanged(address by, uint256 oldValue, uint256 newValue);
    event MaxTokensPerUserChanged(address by, uint256 oldValue, uint256 newValue);
    event APYChanged(address by, uint256 oldValue, uint256 newValue);
    event MaxSlotsChanged(address by, uint256 oldValue, uint256 newValue);
    
    modifier validStakeAmount(uint256 tokens){
        require(tokens >= minStakeAmount, "Should stake atleast 1 token");
        _;
    }
    
    modifier validPlan(uint256 planNumber){
        require(planNumber >= 1 && planNumber <= 5, "Invalid plan number");
        _;
    }
    
    modifier onlyToken{
        require(msg.sender == address(token), "unauthorized");
        _;
    }
    
    constructor(address _tokenAddress) public {
        token = IERC20(_tokenAddress);
        
        stakingPlans[1].totalDays = 60 days;
        stakingPlans[1].APY = 40;
        stakingPlans[1].EWF = 6;
        
        stakingPlans[2].totalDays = 120 days;
        stakingPlans[2].APY = 69;
        stakingPlans[2].EWF = 12;
        
        stakingPlans[3].totalDays = 240 days;
        stakingPlans[3].APY = 81;
        stakingPlans[3].EWF = 24;
        
        stakingPlans[4].totalDays = 30 days;
        stakingPlans[4].APY = 75;
        stakingPlans[4].EWF = 0;
        
        stakingPlans[5].totalDays = 30 days;
        stakingPlans[5].APY = 40;
        stakingPlans[5].EWF = 0;
        
    }
    
    // ------------------------------------------------------------------------
    // Start the staking or add to existing stake
    // user must approve the staking contract to transfer tokens before staking
    // @param _amount number of tokens to stake
    // staking is only possible within subscription period
    // ------------------------------------------------------------------------
    function STAKE(uint256 _amount, uint256 planNumber) external validStakeAmount(_amount) 
    validPlan(planNumber)
    {
        uint256 owing = dividendsOwing(msg.sender); // dividends
        
        if(owing > 0) // existing stakes
            stakers[msg.sender].pendingDIV = owing;
        
        owing = pendingReward(msg.sender); // apy's
        
        if(owing > 0) // existing stakes
            stakers[msg.sender].pendingAPY = owing;
            
        uint256 deduction = onePercent(_amount).mul(2); // 2% transaction cost
        
        if(stakers[msg.sender].stakedAmount == 0 ) // first time staking
            stakers[msg.sender].timeInvest = block.timestamp;
            
        totalStaked = totalStaked.add(_amount.sub(deduction));
        
        // transfer the tokens from caller to staking contract
        token.transferFrom(msg.sender, address(this), _amount);
        
        // record it in contract's storage
        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.add(_amount.sub(deduction)); // add to the stake or fresh stake
        stakers[msg.sender].lastDividentPoints = totalDividentPoints;
        stakers[msg.sender].plan = planNumber;
        stakers[msg.sender].lastClaimed = block.timestamp;
        stakers[msg.sender].rewardClaimDate = block.timestamp.add(stakingPlans[planNumber].totalDays);
        
        if(planNumber == 4 || planNumber == 5){
            require(stakingPlans[planNumber].whiteList[msg.sender], "User not allowed for this plan");
        }
        
        emit Staked(msg.sender, _amount.sub(deduction));
    }
    
    function stakingStartedAt(address user) external view returns(uint256){
        return stakers[user].timeInvest;
    }
    
    function dividendsOwing(address investor) internal view returns (uint256){
        uint256 newDividendPoints = totalDividentPoints.sub(stakers[investor].lastDividentPoints);
        return (((stakers[investor].stakedAmount).mul(newDividendPoints)).div(pointMultiplier)).add(stakers[investor].pendingDIV);
    }
    
    function updateDividend(address investor) internal returns(uint256){
        uint256 owing = dividendsOwing(investor);
        if (owing > 0){
            unclaimedDividendPoints = unclaimedDividendPoints.sub(owing);
            stakers[investor].lastDividentPoints = totalDividentPoints;
            stakers[investor].pendingDIV = 0;
        }
        return owing;
    }
    
    function addToWhitelist(uint256 planNumber, address user) external onlyOwner{
        stakingPlans[planNumber].whiteList[user] = true;
    }
    
    function removeFromWhitelist(uint256 planNumber, address user) external onlyOwner{
        stakingPlans[planNumber].whiteList[user] = false;
    }
    
    // ------------------------------------------------------------------------
    // Claim reward
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimReward() public {
        require(pendingReward(msg.sender) > 0, "nothing pending to claim");
        require(block.timestamp > stakers[msg.sender].rewardClaimDate, "claim date has not reached");
        
        uint256 owing = updateDividend(msg.sender);
        owing = owing.add(pendingReward(msg.sender));
        
        require(owing > 0);
        
        // transfer the reward tokens
        token.transfer(msg.sender, owing);
         
        // add claimed reward to global stats
        totalClaimedRewards = totalClaimedRewards.add(owing);
        
        emit RewardClaimed(msg.sender, owing);
        
        // add the reward to total claimed rewards
        stakers[msg.sender].rewardsClaimed = stakers[msg.sender].rewardsClaimed.add(owing);
        stakers[msg.sender].pendingDIV = 0;
        stakers[msg.sender].pendingAPY = 0;
    }
    
    // ------------------------------------------------------------------------
    // Unstake the tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function UnStake() public {
        uint256 stakedAmount = stakers[msg.sender].stakedAmount;
        require(stakedAmount > 0, "Insufficient stake");
        
        uint256 deduction; // if Early withdraw fee is applicable
        
        if(block.timestamp < stakers[msg.sender].rewardClaimDate) // apply EWF
            deduction = onePercent(stakedAmount).mul(stakingPlans[stakers[msg.sender].plan].EWF); 
        else{
            stakers[msg.sender].pendingAPY = pendingReward(msg.sender);
            stakers[msg.sender].pendingDIV = dividendsOwing(msg.sender);
        }
        
        if(deduction > 0)
            _disburse_(deduction);
            
        stakers[msg.sender].stakedAmount = 0;
        
        // transfer staked tokens
        token.transfer(msg.sender, stakedAmount.sub(deduction));
        
        emit UnStaked(msg.sender, stakedAmount);
    }
    
    function disburse(uint256 amount) external onlyToken{
        _disburse_(amount);
    }
    
    function _disburse_(uint256 amount) private {
        uint256 unnormalized = amount.mul(pointMultiplier);
        totalDividentPoints = totalDividentPoints.add(unnormalized.div(totalStaked));
        unclaimedDividendPoints = unclaimedDividendPoints.add(amount);
    }
    
    // ------------------------------------------------------------------------
    // Query to get the pending reward
    // ------------------------------------------------------------------------
    function pendingReward(address user) public view returns(uint256 _pendingReward){
        uint256 reward = (((stakers[user].stakedAmount)
                        .mul(stakingPlans[stakers[user].plan].APY)
                        .mul(stakingPlans[stakers[user].plan].totalDays))
                        .div(365 days))
                        .div(100);
                        
        reward =  reward.sub(stakers[user].rewardsClaimed);
        
        return reward.add(stakers[user].pendingAPY);
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