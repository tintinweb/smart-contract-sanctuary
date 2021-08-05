/**
 *Submitted for verification at Etherscan.io on 2020-12-24
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
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract ChocolatePool is Owned {
    using SafeMath for uint256;
    
    IERC20 vanilla;
    IRW rewardsWallet;
    uint256 public  stakingPeriod = 45 days;
    uint256 private rewardPercentage = 300; // APY
    uint256 private maxSlots = 30000 * 10 ** (18);
    uint256 private minTokensPerUser = 1000 * 10 ** (18);
    uint256 private maxTokensPerUser = 5000 * 10 ** (18);
    uint256 private subscriptionPeriod = 3 days;
    
    uint256 public  subscriptionEnds;
    uint256 public  rewardClaimDate;
    
    uint256 public  totalClaimedRewards;
    uint256 public  totalStaked;
    
    struct Account{
        uint256 stakedAmount;
        uint256 rewardsClaimed;
        uint256 pending;
    }
    
    mapping(address => Account) public stakers;
    
    event RewardClaimed(address claimer, uint256 reward);
    event UnStaked(address claimer, uint256 stakedTokens);
    event Staked(address staker, uint256 tokens);
    
    event MinTokensPerUserChanged(address by, uint256 oldValue, uint256 newValue);
    event MaxTokensPerUserChanged(address by, uint256 oldValue, uint256 newValue);
    event APYChanged(address by, uint256 oldValue, uint256 newValue);
    event MaxSlotsChanged(address by, uint256 oldValue, uint256 newValue);
    
    constructor(address _tokenAddress, address _rewardsWallet) public {
        vanilla = IERC20(_tokenAddress);
        rewardsWallet = IRW(_rewardsWallet);
        subscriptionEnds = block.timestamp.add(subscriptionPeriod);
        rewardClaimDate = subscriptionEnds.add(stakingPeriod);
    }
    
    // ------------------------------------------------------------------------
    // Start the staking or add to existing stake
    // user must approve the staking contract to transfer tokens before staking
    // @param _amount number of tokens to stake
    // staking is only possible within subscription period
    // ------------------------------------------------------------------------
    function STAKE(uint256 _amount) external {
        require(block.timestamp <= subscriptionEnds, "subscription time expires");
        
        require(stakers[msg.sender].stakedAmount.add(_amount) >= minTokensPerUser && stakers[msg.sender].stakedAmount.add(_amount) <= maxTokensPerUser, "exceeds allowed ranges");
        
        uint256 deduction = onePercent(_amount).mul(5); // 5% transaction cost

        totalStaked = totalStaked.add(_amount.sub(deduction));
        
        require(totalStaked <= maxSlots, "no free slots");
        
        // transfer the tokens from caller to staking contract
        vanilla.transferFrom(msg.sender, address(this), _amount);
        
        // record it in contract's storage
        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.add(_amount.sub(deduction)); // add to the stake or fresh stake
        
        emit Staked(msg.sender, _amount.sub(deduction));
    }
    
    function changeMinTokensPerUser(uint256 _newMinTokensPerUser) external onlyOwner{
        emit MinTokensPerUserChanged(msg.sender, minTokensPerUser, _newMinTokensPerUser);
        minTokensPerUser = _newMinTokensPerUser;
    }
    
    function changeMaxTokensPerUser(uint256 _newMaxTokensPerUser) external onlyOwner{
        emit MaxTokensPerUserChanged(msg.sender, maxTokensPerUser, _newMaxTokensPerUser);
        maxTokensPerUser = _newMaxTokensPerUser;
    }
    
    function changeAPY(uint256 _newAPY) external onlyOwner{
        emit APYChanged(msg.sender, rewardPercentage, _newAPY);
        rewardPercentage = _newAPY;
    }
    
    function changeMaxSlots(uint256 _newMaxSlots) external onlyOwner{
        emit MaxSlotsChanged(msg.sender, maxSlots, _newMaxSlots);
        maxSlots = _newMaxSlots;
    }
    
    function Claim() external{
        ClaimReward();
        UnStake();
    }
    
    // ------------------------------------------------------------------------
    // Claim reward
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function ClaimReward() public {
        require(pendingReward(msg.sender) > 0, "nothing pending to claim");
        require(block.timestamp > rewardClaimDate, "claim date has not reached");
        // transfer the reward tokens
        rewardsWallet.sendRewards(msg.sender, pendingReward(msg.sender));
         
        // add claimed reward to global stats
        totalClaimedRewards = totalClaimedRewards.add(pendingReward(msg.sender));
        
        emit RewardClaimed(msg.sender, pendingReward(msg.sender));
        
        // add the reward to total claimed rewards
        stakers[msg.sender].rewardsClaimed = stakers[msg.sender].rewardsClaimed.add(pendingReward(msg.sender));
    }
    
    // ------------------------------------------------------------------------
    // Unstake the tokens
    // @required user must be a staker
    // @required must be claimable
    // ------------------------------------------------------------------------
    function UnStake() public {
        uint256 stakedAmount = stakers[msg.sender].stakedAmount;
        require(stakedAmount > 0, "insufficient stake");
        
        if(block.timestamp < rewardClaimDate)
            totalStaked = totalStaked.sub(stakedAmount);
        else
            stakers[msg.sender].pending = pendingReward(msg.sender);
        
        stakers[msg.sender].stakedAmount = 0;
        
        // transfer staked tokens
        vanilla.transfer(msg.sender, stakedAmount);
        
        emit UnStaked(msg.sender, stakedAmount);
    }
    
    // ------------------------------------------------------------------------
    // Query to get the pending reward
    // ------------------------------------------------------------------------
    function pendingReward(address user) public view returns(uint256 _pendingReward){
        uint256 reward = (((stakers[user].stakedAmount).mul(rewardPercentage).mul(stakingPeriod)).div(365 days)).div(100);
        reward =  reward.sub(stakers[user].rewardsClaimed);
        return reward.add(stakers[user].pending);
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