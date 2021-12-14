/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

// File: gist-71572af562f01852a1e328dba89471fe/skippy/IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: gist-71572af562f01852a1e328dba89471fe/skippy/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: gist-71572af562f01852a1e328dba89471fe/skippy/SkippyICO.sol




pragma solidity ^0.8.0;

contract Crowdsale {
    using SafeMath for uint256;

    uint256 public tokenRate;
    IERC20 public token;   
    uint public startDate;
    uint public endDate;
    uint public contractBalance = 300 * (10 ** 6) * (10 ** 18);

    address public owner;

    /* Structure to store Investor Details*/
    struct InvestorDetails{
        uint totalBalance;
        uint lastVestedTime;
        uint reminingUnitsToVest;
        uint tokensPerUnit;
        uint vestingBalance;
        uint totalPaid;
        bool purchased;
    }
    
    event Buy(address indexed buyer, uint indexed bnbPaid, uint indexed skippyBought);
    event TokenWithdraw(address indexed buyer, uint value);

    mapping(address => InvestorDetails) public Investors;

    modifier onlyOwner {
        require(msg.sender == owner, 'Owner only function');
        _;
    }
    
    modifier icoShouldBeStarted {
        require(block.timestamp >= startDate, 'ICO is not started yet!');
        _;
    }

    modifier icoShouldnotBeEnded {
        require(block.timestamp <= endDate, 'ICO is ended');
        _;
    }
   
    receive() external payable {
      buy();
    }
   
    constructor(uint256 _tokenRate, address _tokenAddress, uint _startDate, uint _endDate) {
        require(
        _tokenRate != 0 &&
        _tokenAddress != address(0) &&
        _startDate != 0 &&
        _endDate != 0);

        tokenRate = _tokenRate;
        token = IERC20(_tokenAddress);
        startDate = _startDate;
        endDate = _endDate;
        owner = msg.sender;
    }
    
    uint public vestingTime = 1* 60; //14 Days
    uint public fiveMinutes = 5 * 60;
    uint minimumBNB = 100000000000000000;
    uint maximumBNB = 10000000000000000000;

    function buy() public payable icoShouldBeStarted icoShouldnotBeEnded {
        /* Each wallet is limited to do only one purchase */
        //require(Investors[msg.sender].purchased == false, 'Restricted to 1 purchase per wallet');
        /* Buy value should be within the range */
        require(msg.value >= minimumBNB, 'Value is less than the minium BNB');
        require(msg.value <= maximumBNB, 'Value is greater than maximum BNB');
        
        if(!Investors[msg.sender].purchased) {
            uint tokensToBuy = msg.value.div(tokenRate).mul(10 ** 18);
            /* The number of tokens should be less than the balance of ICO contract*/
            require(tokensToBuy <= contractBalance, 'Tokens sold out! Try giving minium BNB value');
            
            /* Set all the initial investor details */
            InvestorDetails memory investor;
    
            investor.totalPaid = msg.value;
            investor.totalBalance = tokensToBuy; //Number of tokens investor bought
            investor.tokensPerUnit = investor.totalBalance.div(10); // Number of Token to release for each vesting period
            investor.reminingUnitsToVest =  10; // Remining number of units to vest
            investor.lastVestedTime = block.timestamp; // Last vested time
            investor.vestingBalance = tokensToBuy;
            contractBalance -= tokensToBuy;
            investor.purchased = true;
            Investors[msg.sender] = investor; // Map the investor address to it's corresponding details
            emit Buy(msg.sender, msg.value, tokensToBuy);
        } else {
            
            require(Investors[msg.sender].totalPaid.add(msg.value) <= maximumBNB, 'Already bought for maximum BNB');
            
            uint tokensToBuy = msg.value.div(tokenRate).mul(10 ** 18);
            require(tokensToBuy <= contractBalance, 'Tokens sold out! Try giving minium BNB value');
            Investors[msg.sender].totalPaid += msg.value;
            uint reminingUnitsToVest = Investors[msg.sender].reminingUnitsToVest;
            uint tokensPerUnit = tokensToBuy.div(reminingUnitsToVest);
            Investors[msg.sender].tokensPerUnit += tokensPerUnit;   
            Investors[msg.sender].totalBalance += tokensToBuy;
            contractBalance -= tokensToBuy;
            Investors[msg.sender].vestingBalance += tokensToBuy;
            emit Buy(msg.sender, msg.value, tokensToBuy);
        }
        
    }
    
    function withdrawTokens() public {
        /* Time difference to calculate the interval between now and last vested time. */
        uint timeDifference = block.timestamp.sub(Investors[msg.sender].lastVestedTime);
        
        /* Number of units that can be vested between the time interval */
        uint numberOfUnitsCanBeVested = timeDifference.div(vestingTime);
        
        /* Remining units to vest should be greater than 0 */
        require(Investors[msg.sender].reminingUnitsToVest > 0, 'All units vested!');
        
        /* Number of units can be vested should be more than 0 */
        require(numberOfUnitsCanBeVested > 0, 'Please wait till next vesting period!');

        if(numberOfUnitsCanBeVested >= Investors[msg.sender].reminingUnitsToVest) {
            numberOfUnitsCanBeVested = Investors[msg.sender].reminingUnitsToVest;
        }
        
        /*
            1. Calculate number of tokens to transfer
            2. Update the investor details
            3. Transfer the tokens to the wallet
        */
        
        uint tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
        uint reminingUnits = Investors[msg.sender].reminingUnitsToVest;
        uint balance = Investors[msg.sender].vestingBalance;
        Investors[msg.sender].reminingUnitsToVest -= numberOfUnitsCanBeVested;
        Investors[msg.sender].vestingBalance -= numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
        Investors[msg.sender].lastVestedTime = block.timestamp;
        if(numberOfUnitsCanBeVested == reminingUnits) { 
            token.transfer(msg.sender, balance);
            emit TokenWithdraw(msg.sender, balance);
        } else {
            token.transfer(msg.sender, tokenToTransfer);
            emit TokenWithdraw(msg.sender, tokenToTransfer);
        }
        
    }
    
    /* Withdraw the contract's BNB balance to owner wallet*/
    function extractBNB() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getInvestorDetails(address _addr) public view returns(InvestorDetails memory){
        return Investors[_addr];
    }
    
    function getContractBNBBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getContractSkippyBalance() public view returns(uint) {
        return contractBalance;
    }
    
    /* Set the price of each token */
    function setTokneRate(uint rate) public onlyOwner {
        tokenRate = rate;
    }
    
    /* Set the maximum BNB to buy tokens*/
    function setMaximumBNB(uint value) public  onlyOwner {
        maximumBNB = value;
    }
    
    /* 
        Transfer the remining token to different wallet. 
        Once the ICO is completed and if there is any remining tokens it can be transfered other wallets.
    */
    function transferSkippy(address _addr, uint value) public onlyOwner {
        require(value <= contractBalance, 'Insufficient balance to withdraw');
        contractBalance -= value;
        token.transfer(_addr, value);
    }
    
    /* Set the ICO start date */
    function setICOStartDate(uint value) public onlyOwner {
        startDate = value;
    }

    function vestingTimeDifference(uint _time) public onlyOwner {
        vestingTime = _time;
    }

    /* Utility function for testing. The token address used in this ICO contract can be changed. */
    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20(_addr);
    }

    function changeEndDate(uint _value) public onlyOwner {
        endDate = _value;
    }

    function addContractBalance(uint _value) public onlyOwner {
        contractBalance += _value;
    }

}