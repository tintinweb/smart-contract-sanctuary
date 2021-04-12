/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
// ----------------------------------------------------------------------------
// 'SNTM' Staking smart contract
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
     * @dev Returns the  of dividing two unsigned integers. (unsigned integer modulo),
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
     * @dev Returns the  of dividing two unsigned integers. (unsigned integer modulo),
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

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------



interface BitSantim {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external  returns (bool success);
    function approve(address _to, uint256 _amount) external  returns (bool success);
}
interface Birr {
    function balanceOf(address _owner) view external  returns (uint256 balance);
    // function transfer(address _to, uint256 _value) public  returns (bool success);
    // function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    // function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transfer(address _to, uint256 _amount) external  returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external  returns (bool success);
    function approve(address _to, uint256 _amount) external  returns (bool success);
    // function balanceOf(address _owner) external view returns (uint256 balance);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Stake is Owned {
    using SafeMath for uint256;
    
    address public SNTM= 0xB12038f02cDF4F91023a43eF1d99fF761a58B5ff;
    address public BIRR= 0x0f83E7bD1b50A5437956b16b0D594F848110F07c;
    
    
    uint256 public Earned = 0; //totalEarning
    uint256 public custLockPercent = 300; //
    uint256 public custPercent = 100;
    uint256 public lockdays = 50;
    uint256 public totalStakes = 0;

    struct USER{
        uint256 stakedTokens;
        uint256 reward;
        uint256 freezeReward;
        uint256 creationTime; 
        uint256 totalEarned;
        uint256 lockTokens;
        uint256 lockCreation;
        uint256 lockdays;
    }
    
    mapping(address => USER) public stakers;                 // keeps record of each payout
    mapping(address=>uint256) public amounts;
    mapping(address=>uint256) public lockamounts;
    
    
    event STAKED(address staker, uint256 tokens, uint256 creationTime);
    event UNSTAKED(address staker, uint256 tokens, uint256 creationTime);
    event CLAIMEDREWARD(address staker, uint256 reward);
    event PERCENTCHANGED(address operator, uint256 percent);
    event LOCKDAYSCHANGED(address operator, uint256 day);
    // ------------------------------------------------------------------------
    // Token holders can stake their tokens using this function
    // @param tokens number of tokens to stake
    // ------------------------------------------------------------------------
    function STAKE(uint256 tokens) external {
        require(tokens > 0,"tokens cant be zero");
        require(BitSantim(SNTM).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        
        if(stakers[msg.sender].creationTime > 0)
        {
        uint256 owing = 0;
        owing = CalculateAmount();
            if(owing > 0)
                {
         
                    stakers[msg.sender].reward = (stakers[msg.sender].reward).add(owing);   
                }
        }
        stakers[msg.sender].stakedTokens = tokens.add(stakers[msg.sender].stakedTokens);
        stakers[msg.sender].creationTime = now;    
        totalStakes = totalStakes.add(tokens);
        uint256 percal = calPercent(tokens,custPercent);
        amounts[msg.sender] = percal;
   
        emit STAKED(msg.sender, tokens, stakers[msg.sender].creationTime);
    
    }
    
    
    
    
    function LOCKSTAKE(uint256 tokens) external {
        
        require(tokens > 0,"tokens cant be zero");
        {
            
        require(BitSantim(SNTM).transferFrom(msg.sender, address(this), tokens), "Tokens cannot be transferred from user account");
        
         if(stakers[msg.sender].lockCreation > 0)
        {
        uint256 owing = 0;
        owing = CalculateAmountFreeze();
        
            if(owing > 0)
                {
                    stakers[msg.sender].freezeReward = (stakers[msg.sender].freezeReward).add(owing);   
                }
        
        }
        
        stakers[msg.sender].lockTokens = tokens.add(stakers[msg.sender].lockTokens);
        stakers[msg.sender].lockCreation = now;
        totalStakes = totalStakes.add(tokens);
        uint256 percal = calPercent(tokens,custLockPercent);
        lockamounts[msg.sender] = percal;
        emit STAKED(msg.sender, tokens, stakers[msg.sender].lockCreation);
    }
        }
    // ------------------------------------------------------------------------
    // Stakers can claim their pending rewards using this function
    // ------------------------------------------------------------------------
    function CLAIMREWARD() public {
            uint256 owing = CalculateAmount();    
            owing = owing.add(CalculateAmountFreeze());
            owing = owing.add((stakers[msg.sender].reward).add(stakers[msg.sender].freezeReward));
            require(Birr(BIRR).transfer(msg.sender,owing), "ERROR: error in sending reward from contract");
            emit CLAIMEDREWARD(msg.sender, owing);
            stakers[msg.sender].reward = 0;
            stakers[msg.sender].freezeReward = 0;
            Earned = Earned.add(owing);
            stakers[msg.sender].totalEarned = (stakers[msg.sender].totalEarned).add(owing);
            if(stakers[msg.sender].stakedTokens == 0)
            {
                stakers[msg.sender].creationTime = 0;
            }
            else
            {
               stakers[msg.sender].creationTime = now;
            }
               if(stakers[msg.sender].lockTokens == 0)
            {
                stakers[msg.sender].lockCreation = 0;
            }
        else
            {
               stakers[msg.sender].lockCreation = now;
            }
            stakers[msg.sender].lockCreation = now;
    }
    
    function CalculateAmount() private view returns (uint256)
    {
         uint256 time = now - stakers[msg.sender].creationTime; 
         uint256 daysCount = time.div(30);
           time = now - stakers[msg.sender].lockCreation; 
           require(daysCount > 0 , "Minimum Time of withdrawal is 1 day");
           uint256  owing =0;
            if(daysCount>0)
            {
            owing =  ((amounts[msg.sender]).mul(daysCount));
            }            
        return owing;   
    }
    function CalculateAmountFreeze() private view returns (uint256)
    {
            uint256  time = now - stakers[msg.sender].lockCreation; 
            uint256 daysLockCount = time.div(30);
            require(daysLockCount > 0 , "Minimum Time of withdrawal is 1 day");
            uint256  owing =0;
            if(daysLockCount>0)
            {
                    owing =  ((lockamounts[msg.sender]).mul(daysLockCount)).add(owing);
            }
            return owing;
            
    }
    // ------------------------------------------------------------------------
    // Stakers can un stake the staked tokens using this function
    // @param tokens the number of tokens to withdraw
    // ------------------------------------------------------------------------
    function WITHDRAW(uint256 tokens) external {
        
        require(stakers[msg.sender].stakedTokens >= tokens && tokens > 0, "Invalid token amount to withdraw");
       
        // add pending rewards to remainder to be claimed by user later, if there is any existing stake
        uint256 owing = 0;

        
        require(BitSantim(SNTM).transfer(msg.sender, tokens), "Error in un-staking tokens");
        
        owing = 0;
        owing = CalculateAmount();
        
        if(owing > 0)
        {
         
          stakers[msg.sender].reward = (stakers[msg.sender].reward).add(owing);   
        }
        
        
        
        stakers[msg.sender].stakedTokens = stakers[msg.sender].stakedTokens.sub(tokens);
        if(stakers[msg.sender].stakedTokens == 0)
            {
                stakers[msg.sender].creationTime = 0;
            }
        
        else
            {
                stakers[msg.sender].creationTime = now;
            }
        totalStakes = totalStakes.sub(tokens);
        uint256 percal = calPercent(stakers[msg.sender].stakedTokens,custPercent);
        amounts[msg.sender] = percal;
        
        emit UNSTAKED(msg.sender, tokens,stakers[msg.sender].creationTime );
    }
     
    // ------------------------------------------------------------------------
    // Withdraw for freezed tokens
    // ------------------------------------------------------------------------
    
        function LOCKWITHDRAW(uint256 tokens) external {
        
        require(stakers[msg.sender].lockTokens >= tokens && tokens > 0, "Invalid token amount to withdraw");
        
        
        uint256 time = now - stakers[msg.sender].lockCreation; 
        uint256 daysLockCount = time.div(30);
        
        
        require(daysLockCount > lockdays , "Lock Period not finished");
        {
       
        // add pending rewards to remainder to be claimed by user later, if there is any existing stake
        uint256 owing = 0;

        require(BitSantim(SNTM).transfer(msg.sender, tokens), "Error in un-staking tokens");
        
           
        owing = 0;
        owing = CalculateAmountFreeze();
        
        if(owing > 0)
        {
         
          stakers[msg.sender].freezeReward = (stakers[msg.sender].freezeReward).add(owing);   
        }
        
 
        stakers[msg.sender].lockTokens = stakers[msg.sender].lockTokens.sub(tokens);
        
               if(stakers[msg.sender].lockTokens == 0)
            {
                stakers[msg.sender].lockCreation = 0;
            }
        
        else
            {
                 stakers[msg.sender].lockCreation = now;
            }
        
        totalStakes = totalStakes.sub(tokens);
        uint256 percal = calPercent(stakers[msg.sender].lockTokens,custLockPercent);
        amounts[msg.sender] = percal;
        
        
        if(totalStakes > 0)
        emit UNSTAKED(msg.sender, tokens, stakers[msg.sender].lockCreation);
        }
        
        
        
    
    }
    
    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // -
    
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
       
    function calPercent(uint256 _tokens, uint256 cust) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint256 custPercentofTokens = roundValue.mul(cust).div(100 * 10**uint(2));
        custPercentofTokens = custPercentofTokens.div(7);
        return custPercentofTokens;
    }
    
    
    // ------------------------------------------------------------------------
    // Get the number of tokens staked by a staker
    // @param _staker the address of the staker
    // ------------------------------------------------------------------------
    function yourStakedSNTM(address staker) external view returns(uint256 stakedSNTM){
        return stakers[staker].stakedTokens;
    }
    
    // ------------------------------------------------------------------------
    // Get the SNTM balance of the token holder
    // @param user the address of the token holder
    // ------------------------------------------------------------------------
    function yourSNTMBalance(address user) external view returns(uint256 SNTMBalance){
        return BitSantim(SNTM).balanceOf(user);
    }
    
        function setPercent(uint256 percent) public onlyOwner {
        
        if(percent >= 1)
        {
         custPercent = percent;    
         emit PERCENTCHANGED(msg.sender, percent);
        }
         
    }
    
    
    
         function setLockPercent(uint256 percent) public onlyOwner {
        
        if(percent >= 1)
        {
         custLockPercent = percent;    
         emit PERCENTCHANGED(msg.sender, percent);
        }
         
    }
    
        
        function setLockDays(uint256 day) public onlyOwner {
        
        require(day != 0,"lock days cant be 0");
        {
         lockdays  =day;    
         emit LOCKDAYSCHANGED(msg.sender, day);
        }
         
    }
    
    
}