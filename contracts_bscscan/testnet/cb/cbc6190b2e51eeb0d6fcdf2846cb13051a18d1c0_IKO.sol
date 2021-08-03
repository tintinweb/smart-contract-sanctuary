/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

 
// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.6.0 <0.8.0;

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
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
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
pragma solidity  ^0.6.12;
 

contract IKO 

   {

    using SafeMath for uint256;
    
    //define the admin of IKO 
    address public owner;
    
    address public inputtoken;
    
    bool public inputToken6Decimal=false; //USDC 
    
    address public outputtoken;
    
    bool noOutputToken;
    
    // total Supply for IKO
    uint256 public totalsupply;

    mapping (address => uint256)public userInvested;
    
    mapping (address => uint256)public userInvestedMemory;
    
    address[] public investors;
    
    mapping (address => bool) public existinguser;
    
    uint256 public maxInvestment = 0; // pay attention to the decimals number of inputtoken
    
    uint256 public minInvestment = 0; // pay attention to the decimals number of inputtoken
    
    //set number of out tokens per in tokens  
    uint256 public outTokenPriceInDollar;                   

    //hardcap 
    uint public IKOTarget;

    //define a state variable to track the funded amount
    uint public receivedFund=0;
    
    //define a state variable to track the input token fee amount (used to buyback and burn Lyptus after IKO)
    uint public receivedInTokenFee=0;
    
    //set the IKO status
    
    enum Status {inactive, active, stopped, completed}      // 0, 1, 2, 3
    
    Status private IKOStatus;
    
    uint public IKOStartTime=0;
    
    uint public IKOInTokenClaimTime=0;
    
    uint public IKOEndTime=0;
    
    // Token burn rate in basis point
    uint16 public inTokenBurnFeeBP=0;  

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;      

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }   

    function transferOwnership(address _newowner) public onlyOwner {
        owner = _newowner;
    } 
 
    constructor () public  {
    
        owner = msg.sender;
    
    }
 
    function setStopStatus() public onlyOwner  {
     
        IKOStatus = getIKOStatus();
        
        require(IKOStatus == Status.active, "Cannot Stop inactive or completed IKO ");   
        
        IKOStatus = Status.stopped;
    }

    function setActiveStatus() public onlyOwner {
    
        IKOStatus = getIKOStatus();
        
        require(IKOStatus == Status.stopped, "IKO not stopped");   
        
        IKOStatus = Status.active;
    }

    function getIKOStatus() public view returns(Status)  {
    
        
        if (IKOStatus == Status.stopped)
        {
            return Status.stopped;
        }
        
        else if (block.timestamp >=IKOStartTime && block.timestamp <=IKOEndTime)
        {
            return Status.active;
        }
        
        else if (block.timestamp <= IKOStartTime || IKOStartTime == 0)
        {
            return Status.inactive;
        }
        
        else
        {
            return Status.completed;
        }
    
    }

    function invest(uint256 _amount) public {
    
        // check IKO Status
        IKOStatus = getIKOStatus();
        
        require(IKOStatus == Status.active, "IKO in not active");
        
        //check for hard cap
        require(IKOTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
        
        require(_amount >= minInvestment , "min Investment not accepted");
        
        uint256 checkamount = userInvested[msg.sender] + _amount;

        //check maximum investment        
        require(checkamount <= maxInvestment, "Investment not in allowed range"); 
        
        uint256 inTokenFeeAmount = 0;
        
            // Fee is payed in input token
            
            inTokenFeeAmount = _amount.mul(inTokenBurnFeeBP).div(10000);

        // check for existinguser
        if (existinguser[msg.sender]==false) {
        
            existinguser[msg.sender] = true;
            investors.push(msg.sender);
        }
        
        userInvested[msg.sender] += _amount.sub(inTokenFeeAmount); 
        //Duplicate to keep in memory after the IKO
        userInvestedMemory[msg.sender] += _amount.sub(inTokenFeeAmount);         
        
        receivedFund = receivedFund + _amount; 
        receivedInTokenFee = receivedInTokenFee + inTokenFeeAmount;
        IERC20(inputtoken).transferFrom(msg.sender,address(this), _amount); 

    }
     
     
    function claimTokens() public {

        require(existinguser[msg.sender] == true, "Already claim"); 

        require(outputtoken!=BURN_ADDRESS, "Outputtoken not yet available"); 
                
        // check IKO Status 
        IKOStatus = getIKOStatus();
        
        require(IKOStatus == Status.completed, "IKO in not complete yet");

        uint256 redeemtokens = remainingClaim(msg.sender);
        
        require(redeemtokens>0, "No tokens to redeem");
        
        IERC20(outputtoken).transfer(msg.sender, redeemtokens);
        
        existinguser[msg.sender] = false; 
        userInvested[msg.sender] = 0;
    }

    // Display user token claim balance
    function remainingClaim(address _address) public view returns (uint256) {

        uint256 redeemtokens = 0;

        if (inputToken6Decimal) {
            redeemtokens = (userInvested[_address] * 1000000000000 * 1000000000000000000) / outTokenPriceInDollar;
        }
        else {
            redeemtokens = (userInvested[_address] * 1000000000000000000) / outTokenPriceInDollar;
        }
        
        return redeemtokens;
        
    }

    // Display user max available investment
    function remainingContribution(address _address) public view returns (uint256) {

        uint256 remaining = maxInvestment - userInvested[_address];
        
        return remaining;
        
    }
    
    //  _token = 1 (outputtoken)        and         _token = 2 (inputtoken) 
    function checkIKObalance(uint8 _token) public view returns(uint256 _balance) {
    
        if (_token == 1) {
            return getOutputTokenBalance();
        }
        else if (_token == 2) {
            return IERC20(inputtoken).balanceOf(address(this));  
        }
        else {
            return 0;
        }
    }

    function withdrawInputToken(address _admin) public onlyOwner{
        
        require(block.timestamp >= IKOInTokenClaimTime, "IKO in token claim time is not over yet");
        
        uint256 raisedamount = IERC20(inputtoken).balanceOf(address(this));
        
        IERC20(inputtoken).transfer(_admin, raisedamount);
    
    }
  
    function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{

        IKOStatus = getIKOStatus();
        require(IKOStatus == Status.completed, "IKO in not complete yet");
        
        uint256 remainingamount = IERC20(outputtoken).balanceOf(address(this));
        
        require(remainingamount >= _amount, "Not enough token to withdraw");
        
        IERC20(outputtoken).transfer(_admin, _amount);
    }
    
    
    function resetIKO() public onlyOwner {
    
        for (uint256 i = 0; i < investors.length; i++) {
         
            if (existinguser[investors[i]]==true)
            {
                existinguser[investors[i]]=false;
                userInvested[investors[i]] = 0;
                userInvestedMemory[investors[i]] = 0;
            }
        }
        
        require(IERC20(outputtoken).balanceOf(address(this)) <= 0, "IKO is not empty");
        require(IERC20(inputtoken).balanceOf(address(this)) <= 0, "IKO is not empty");
        
        totalsupply = 0;
        IKOTarget = 0;
        IKOStatus = Status.inactive;
        IKOStartTime = 0;
        IKOInTokenClaimTime = 0;
        IKOEndTime = 0;
        inTokenBurnFeeBP = 0;
        receivedFund = 0;
        receivedInTokenFee = 0;
        maxInvestment = 0;
        minInvestment = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        outTokenPriceInDollar = 0;
        
        delete investors;
    
    }
        
    function initializeIKO(address _inputtoken, address _outputtoken, uint256 _startTime, uint256 _inTokenClaimTime, uint256 _endtime, uint16 _inTokenBurnFeeBP, uint256 _outTokenPriceInDollar, uint256 _maxinvestment, uint256 _minInvestment, bool _inputToken6Decimal, uint256 _forceTotalSupply) public onlyOwner {
        
        require(_endtime > _startTime, "Enter correct Time");
        
        inputtoken = _inputtoken;
        inputToken6Decimal = _inputToken6Decimal;
        outputtoken = _outputtoken;
        outTokenPriceInDollar = _outTokenPriceInDollar;
        require(outTokenPriceInDollar > 0, "token price not set");
        
        if (_outputtoken==BURN_ADDRESS) {
            require(_forceTotalSupply > 0, "Enter correct _forceTotalSupply");
            totalsupply = _forceTotalSupply;
            noOutputToken = true;
        }
        else
        {
            require(IERC20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to IPO");
            totalsupply = IERC20(outputtoken).balanceOf(address(this));
            noOutputToken = false;
        }
        
         if (inputToken6Decimal) {
            IKOTarget = (totalsupply *  outTokenPriceInDollar) / 1000000000000 / 1000000000000000000;
        }
        else {
            IKOTarget = (totalsupply * outTokenPriceInDollar) / 1000000000000000000;
        }        
                
        IKOStatus = Status.active;
        IKOStartTime = _startTime;
        IKOInTokenClaimTime = _inTokenClaimTime;
        IKOEndTime = _endtime;
        inTokenBurnFeeBP = _inTokenBurnFeeBP;
        
        require (IKOTarget > maxInvestment, "Incorrect maxinvestment value");
        
        maxInvestment = _maxinvestment;
        minInvestment = _minInvestment;
    }
    
    function getParticipantNumber() public view returns(uint256 _participantNumber) {
        return investors.length;
    }
    function getOutputTokenBalance() internal view returns(uint256 _outputTokenBalance) {
        if (noOutputToken) {
            return totalsupply;
        }
        else {
            return IERC20(outputtoken).balanceOf(address(this));
        }          
    } 
    

}