/**
 *Submitted for verification at Etherscan.io on 2020-11-21
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-08
*/



// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

// ----------------------------------------------------------------------------
// 'Hype' Staking smart contract. 2.5% deposit and withdrawal fees are rewarded to all staking members based on their staking amount.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// SafeMath library
// ----------------------------------------------------------------------------

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
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ERC20: sending to the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function transferFromStake(address from, address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract HypeStake is Owned {
    using SafeMath for uint256;
    
    address public Hype = 0x610c67be018A5C5bdC70ACd8DC19688A11421073;
    address rewardMaker = 0x181b3a5c476fEecC97Cf7f31Ea51093f324B726f;
    
    uint256 public totalStakes = 0;
    uint256 stakingFee = 50; // 5%
    uint256 unstakingFee = 100; // 10% 
    uint256 public totalDividends = 0;
    uint256 private scaledRemainder = 0;
    uint256 private scaling = uint256(10) ** 12;
    uint public round = 1;
    uint256 public maxAllowed = 1000000000000000000000; //1000 tokens total allowed to be staked
    uint public blockPerDay = 6539;
    uint public locktime = 1 * blockPerDay; //1days lock to test
    
    /* Fees breaker, to protect withdraws if anything ever goes wrong */
    bool public breaker = false; // withdraw can be lock,, default unlocked
    mapping(address => uint) public farmLock; // period that your sake it locked to keep it for farming
    //uint public lock = 0; // farm lock in blocks ~ 0 days for 15s/block
    //address public admin;
    
    struct USER{
        uint256 stakedTokens;
        uint256 lastDividends;
        uint256 fromTotalDividend;
        uint round;
        uint256 remainder;
    }
    
        address[] internal stakeholders;
    mapping(address => USER) stakers;
    mapping (uint => uint256) public payouts;                   // keeps record of each payout
    
    event STAKED(address staker, uint256 tokens, uint256 stakingFee);
    event EARNED(address staker, uint256 tokens);
    event UNSTAKED(address staker, uint256 tokens, uint256 unstakingFee);
    event PAYOUT(uint256 round, uint256 tokens, address sender);
    event CLAIMEDREWARD(address staker, uint256 reward);
    event WithdrawalLockDurationSet(uint256 value, address sender);
    
    function setBreaker(bool _breaker) external onlyOwner {
        //require(msg.sender == admin, "admin only");
        breaker = _breaker;
    }
    
    
   
    function calculateReward(address _stakeholder)
        public
        view
        returns(uint256)
    {
        uint256 bal = yourStakedHype(_stakeholder);
        return bal.div(totalStakes);
    }


    function distributeRewards(uint256 tokens)
        public
    {
        require(msg.sender == address(rewardMaker), "ERC20: You'r not allowed to use this function");
        require(IERC20(Hype).transferFromStake(msg.sender, address(this), tokens), "Tokens cannot be transferred from funder account");
        
        _addPayout(tokens);
        
        
    }
    
    function isStakeholder(address _address)
       public
       view
       returns(bool)
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true);
       }
       return (false);
   }
   
   function addStakeholder(address _stakeholder)
       public
   {
       (bool _isStakeholder) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }
   


    // ------------------------------------------------------------------------
    // Token holders can stake their tokens using this function
    // @param tokens number of tokens to stake
    // ------------------------------------------------------------------------
    function STAKE(uint256 tokens) external {
        require(totalStakes <= maxAllowed, "Total Stakes amount exceed");
        require(IERC20(Hype).transferFromStake(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        
        
            uint256 _stakingFee = 0;
            if(totalStakes > 0)
                _stakingFee= (onePercent(tokens).mul(stakingFee)).div(10); 
            
            if(totalStakes > 0)
                // distribute the staking fee accumulated before updating the user's stake
                _addPayout(_stakingFee);
                
            // add pending rewards to remainder to be claimed by user later, if there is any existing stake
            uint256 owing = pendingReward(msg.sender);
            stakers[msg.sender].remainder += owing;
            
            stakers[msg.sender].stakedTokens = (tokens.sub(_stakingFee)).add(stakers[msg.sender].stakedTokens);
            stakers[msg.sender].lastDividends = owing;
            stakers[msg.sender].fromTotalDividend= totalDividends;
            stakers[msg.sender].round =  round;
            
            (bool _isStakeholder) = isStakeholder(msg.sender);
             if(!_isStakeholder) farmLock[msg.sender] =  block.timestamp;
            
            
            totalStakes = totalStakes.add(tokens.sub(_stakingFee));
            
            addStakeholder(msg.sender);
            
            emit STAKED(msg.sender, tokens.sub(_stakingFee), _stakingFee);
        
    }
    
    
    function calculateExitBlock(address _staker) public view returns (uint256){
        require(_staker != address(0), "ERC20: sending to the zero address");
        
       // uint enterBlock = farmLock[msg.sender];
        //uint exitBlock = enterBlock.add(locktime)
        
        return farmLock[msg.sender];
    }
    
    // ------------------------------------------------------------------------
    // Owners can send the funds to be distributed to stakers using this function
    // @param tokens number of tokens to distribute
    // ------------------------------------------------------------------------
    function ADDFUNDS(uint256 tokens) external {
        
        require(IERC20(Hype).transferFromStake(msg.sender, address(this), tokens), "Tokens cannot be transferred from funder account");
        _addPayout(tokens);
    }
    
    // ------------------------------------------------------------------------
    // Private function to register payouts
    // ------------------------------------------------------------------------
    function _addPayout(uint256 tokens) private{
        // divide the funds among the currently staked tokens
        // scale the deposit and add the previous remainder
        uint256 available = (tokens.mul(scaling)).add(scaledRemainder); 
        uint256 dividendPerToken = available.div(totalStakes);
        scaledRemainder = available.mod(totalStakes);
        
        totalDividends = totalDividends.add(dividendPerToken);
        payouts[round] = payouts[round - 1].add(dividendPerToken);
        
        emit PAYOUT(round, tokens, msg.sender);
        round++;
    }
    
    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
    function CLAIMREWARD() public {
        
        if(totalDividends > stakers[msg.sender].fromTotalDividend){
            uint256 owing = pendingReward(msg.sender);
        
            owing = owing.add(stakers[msg.sender].remainder);
            stakers[msg.sender].remainder = 0;
        
            require(IERC20(Hype).transferFromStake(address(this), msg.sender,owing), "ERROR: error in sending reward from contract");
        
            emit CLAIMEDREWARD(msg.sender, owing);
        
            stakers[msg.sender].lastDividends = owing; // unscaled
            stakers[msg.sender].round = round; // update the round
            stakers[msg.sender].fromTotalDividend = totalDividends; // scaled
        }
    }
    
    // ------------------------------------------------------------------------
    // Get the pending rewards of the staker
    // @param _staker the address of the staker
    // ------------------------------------------------------------------------    
    function pendingReward(address staker) private returns (uint256) {
        require(staker != address(0), "ERC20: sending to the zero address");
        
        uint stakersRound = stakers[staker].round;
        uint256 amount =  ((totalDividends.sub(payouts[stakersRound - 1])).mul(stakers[staker].stakedTokens)).div(scaling);
        stakers[staker].remainder += ((totalDividends.sub(payouts[stakersRound - 1])).mul(stakers[staker].stakedTokens)) % scaling ;
        return amount;
    }
    
    function getPendingReward(address staker) public view returns(uint256 _pendingReward) {
        require(staker != address(0), "ERC20: sending to the zero address");
         uint stakersRound = stakers[staker].round;
         
        uint256 amount =  ((totalDividends.sub(payouts[stakersRound - 1])).mul(stakers[staker].stakedTokens)).div(scaling);
        amount += ((totalDividends.sub(payouts[stakersRound - 1])).mul(stakers[staker].stakedTokens)) % scaling ;
        return (amount.add(stakers[staker].remainder));
    }
    
    // ------------------------------------------------------------------------
    // Stakers can un stake the staked tokens using this function
    // @param tokens the number of tokens to withdraw
    // ------------------------------------------------------------------------
    function WITHDRAW(uint256 tokens) external {
        require(breaker == false, "Admin Restricted WITHDRAW");
        require(stakers[msg.sender].stakedTokens >= tokens && tokens > 0, "Invalid token amount to withdraw");
        
        //uint exitBlock = calculateExitBlock(msg.sender);
        require(farmLock[msg.sender]+30 days <= block.timestamp, "Withdraw can only be done after 30 days");
        
        
        uint256 _unstakingFee = (onePercent(tokens).mul(unstakingFee)).div(10);
        
        // add pending rewards to remainder to be claimed by user later, if there is any existing stake
        uint256 owing = pendingReward(msg.sender);
        stakers[msg.sender].remainder += owing;
                
        require(IERC20(Hype).transfer(msg.sender, tokens.sub(_unstakingFee)), "Error in un-staking tokens");
        
        stakers[msg.sender].stakedTokens = stakers[msg.sender].stakedTokens.sub(tokens);
        stakers[msg.sender].lastDividends = owing;
        stakers[msg.sender].fromTotalDividend= totalDividends;
        stakers[msg.sender].round =  round;
        
        totalStakes = totalStakes.sub(tokens);
        
        if(totalStakes > 0)
            // distribute the un staking fee accumulated after updating the user's stake
            _addPayout(_unstakingFee);
        
        emit UNSTAKED(msg.sender, tokens.sub(_unstakingFee), _unstakingFee);
    }
    
    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    // ------------------------------------------------------------------------
    // Get the number of tokens staked by a staker
    // @param _staker the address of the staker
    // ------------------------------------------------------------------------
    function yourStakedHype(address staker) public view returns(uint256 stakedHype){
        require(staker != address(0), "ERC20: sending to the zero address");
        
        return stakers[staker].stakedTokens;
    }
    
    // ------------------------------------------------------------------------
    // Get the Hype balance of the token holder
    // @param user the address of the token holder
    // ------------------------------------------------------------------------
    function yourHypeBalance(address user) external view returns(uint256 HypeBalance){
        require(user != address(0), "ERC20: sending to the zero address");
        return IERC20(Hype).balanceOf(user);
    }
    
    // -------------------- LOCK CODE  ------------------------------------------------------------------------
    
    


}