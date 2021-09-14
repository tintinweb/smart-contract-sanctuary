// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Crowdsale.sol";

contract LaunchpadFactory {

    using SafeMath for uint256;
    
    /// @notice all the information for this crowdsale in one struct
    struct CrowdsaleInfo {
        address crowdsaleAddress;
        IERC20 tokenAddress;
        address owner;
    }
    
    CrowdsaleInfo[] public crowdsales;  //creating a variable requests of type array which will hold value in format that of Request 
    
    uint256 public crowdsaleIndex;

    event CrowdsaleLaunched(uint256 indexed crowdsaleIndex, address indexed crowdsaleAddress, IERC20 token, uint256 indexed crowdsaleStartTime);
    
    function _preValidateAddress(IERC20 _addr)
        internal pure
      {
        require(address(_addr) != address(0),"Cant be Zero address");
      }
      
    /**
     * @notice Creates a new Crowdsale contract and registers it in the LaunchpadFactory
     * All invested amount would be accumulated in the Crowdsale Contract
     */
    function launchCrowdsale (
     IERC20 _tokenAddress,
     uint8 _tokenDecimal,
     uint256 _amountAllocation,
     uint256 _rate,
     uint256 _crowdsaleStartTime,
     uint256 _crowdsaleEndTime,
     uint256 _vestingStartTime,
     uint256 _vestingEndTime,
     uint256 _cliffDurationInSecs) 
    public 
    returns (address)
    {
        _preValidateAddress(_tokenAddress);
        require(_crowdsaleStartTime >= block.timestamp, "Start time should be greater than current"); // ideally at least 24 hours more to give investors time
        require(_crowdsaleEndTime > _crowdsaleStartTime || _crowdsaleEndTime == 0, "End Time could be 0 or > crowdsale StartTime");  //_crowdsaleEndTime = 0 means crowdsale would be concluded manually by owner
        require(_amountAllocation > 0, "Allocate some amount to start Crowdsale");
        require(address(_tokenAddress) != address(0), "Invalid Token address");
        require(_rate > 0, "Rate cannot be Zero"); 
        
                
        if(_crowdsaleEndTime == 0){ // vesting Data would be 0 & can be set when crowdsale is ended manually by owner to avoid confusion
            _vestingStartTime = 0;
            _vestingEndTime = 0;
            _cliffDurationInSecs = 0;
        }
        else if(_crowdsaleEndTime >_crowdsaleStartTime){
            require(_vestingStartTime >= _crowdsaleEndTime, "Vesting Start time should >= Crowdsale EndTime");
            require(_vestingEndTime > _vestingStartTime.add(_cliffDurationInSecs), "Vesting End Time should be after the cliffPeriod");
        }
        
        TransferHelper.safeTransferFrom(address(_tokenAddress), msg.sender, address(this), _amountAllocation);
        Crowdsale newCrowdsale = new Crowdsale(msg.sender,address(this));
        TransferHelper.safeApprove(address(_tokenAddress), address(newCrowdsale), _amountAllocation);
        newCrowdsale.init(_tokenAddress, _tokenDecimal, _amountAllocation,_rate,_crowdsaleStartTime,_crowdsaleEndTime, _vestingStartTime,_vestingEndTime, _cliffDurationInSecs);
                        
       CrowdsaleInfo memory newCrowdsaleInfo=CrowdsaleInfo({     //creating a variable newCrowdsaleInfo which will hold value in format that of CrowdsaleInfo 
            crowdsaleAddress : address(newCrowdsale),   //setting the value of keys as being passed by crowdsale deployer during the function call
            tokenAddress:_tokenAddress,
            owner:msg.sender
        });
        crowdsales.push(newCrowdsaleInfo);  //stacking up every crowdsale info ever made to crowdsales variable
       
        emit CrowdsaleLaunched(crowdsaleIndex,address(newCrowdsale),_tokenAddress,_crowdsaleStartTime);
        crowdsaleIndex++;
    }
    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./library/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract Crowdsale is ReentrancyGuard  {
    using SafeMath for uint256;
    
    //@notice the amount of token investor will recieve against 1 stableCoin
    uint256 public rate;    
    
    ///@notice TokenAddress available for purchase in this Crowdsale
    IERC20 public token;    
    
    uint256 public tokenRemainingForSale;

    address public owner;
    
    /// @notice of launchpadFactory Contract
    address public launchpadFactory;    
    
    IERC20 private usdc = IERC20(0x0722F34264432D74A5DFc70379e574a15dA65F48);  
    IERC20 private dai = IERC20(0x87a777e458178F5B0624e62b80E4bAc9FF5a110F); 

    /// @notice start of vesting period as a timestamp
    uint256 public vestingStart;
    
     /// @notice start of crowdsale as a timestamp
    uint256 public crowdsaleStartTime;
    
     /// @notice end of crowdsale as a timestamp
    uint256 public crowdsaleEndTime;

    /// @notice end of vesting period as a timestamp
    uint256 public vestingEnd;
    
    /// @notice Number of Tokens Allocated for crowdsale
    uint256 public crowdsaleTokenAllocated;

    /// @notice cliff duration in seconds
    uint256 public cliffDuration;

    uint256 public tokenDecimal;

    /// @notice amount vested for a investor. 
    mapping(address => uint256) public vestedAmount;

    /// @notice cumulative total of tokens drawn down (and transferred from the deposit account) per investor
    mapping(address => uint256) public totalDrawn;

    /// @notice last drawn down time (seconds) per investor
    mapping(address => uint256) public lastDrawnAt;

    /// @notice whitelisted address those can participate in crowdsale
    mapping(address => bool) public whitelistedAddress;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }
    
    /**
       * Event for Tokens purchase logging
       * @param investor who invested & got the tokens
       * @param investedAmount of stableCoin paid for purchase
       * @param tokenPurchased amount
       * @param stableCoin address used to invest
       * @param tokenRemaining amount of token still remaining for sale in crowdsale
    */
    event TokenPurchase(
        address indexed investor,
        uint256 investedAmount,
        uint256 indexed tokenPurchased,
        IERC20 indexed stableCoin,
        uint256 tokenRemaining
    );

    /// @notice event emitted when a successful drawn down of vesting tokens is made
    event DrawDown(address indexed _investor, uint256 _amount,uint256 indexed drawnTime);
    
    /// @notice event emitted when crowdsale is ended manually
    event CrowdsaleEndedManually(uint256 indexed crowdsaleEndedManuallyAt);
    
     /// @notice event emitted when the crowdsale raised funds are withdrawn by the owner 
    event FundsWithdrawn(address indexed beneficiary,IERC20 indexed _token,uint256 amount);
    
    constructor(address _owner,address _launchpad) public {
        launchpadFactory = _launchpad;
        owner = _owner;
    }
    
    /**
     * @notice initialize the Crowdsale contract. This is called only once upon Crowdsale creation and the launchpadFactory ensures the Crowdsale has the correct paramaters
     */
    function init (IERC20 _tokenAddress, uint8 _tokenDecimal, uint256 _amount, uint256 _rate,uint256 _crowdsaleStartTime,uint256 _crowdsaleEndTime, uint256 _vestingStartTime, uint256 _vestingEndTime,uint256 _cliffDurationInSecs) public {
        require(msg.sender == address(launchpadFactory), "FORBIDDEN");
        TransferHelper.safeTransferFrom(address(_tokenAddress), msg.sender, address(this), _amount);
        token = _tokenAddress;
        tokenDecimal = _tokenDecimal;
        rate = _rate;
        crowdsaleStartTime = _crowdsaleStartTime;
        crowdsaleEndTime = _crowdsaleEndTime;
        vestingStart = _vestingStartTime;
        vestingEnd = _vestingEndTime;
        crowdsaleTokenAllocated = _amount;
        tokenRemainingForSale = _amount;
        cliffDuration = _cliffDurationInSecs;
    }
    
    modifier isCrowdsaleOver(){
        require(_getNow() >= crowdsaleEndTime && crowdsaleEndTime != 0,"Crowdsale Not Ended Yet");
        _;
    }
    
    function buyTokenWithStableCoin(IERC20 _stableCoin, uint256 _stableCoinAmount) external {   
        require(_getNow() >= crowdsaleStartTime,"Crowdsale isnt started yet");
        require(_stableCoin == usdc || _stableCoin == dai,"Unsupported StableCoin");
        if(crowdsaleEndTime != 0){
            require(_getNow() < crowdsaleEndTime, "Crowdsale Ended");
        }
        
        uint256 tokenPurchased = _stableCoin == dai ? _stableCoinAmount.mul(rate) : _stableCoinAmount.mul(rate).mul(1e12);
        
        tokenPurchased = tokenDecimal >= 36 ? tokenPurchased.mul(10**(tokenDecimal-36)) : tokenPurchased.div(10**(36-tokenDecimal)) ;

        require(tokenPurchased <= tokenRemainingForSale,"Exceeding purchase amount");

        _stableCoin.transferFrom(msg.sender, address(this), _stableCoinAmount);

        tokenRemainingForSale = tokenRemainingForSale.sub(tokenPurchased);
        _updateVestingSchedule(msg.sender, tokenPurchased);
        
        emit TokenPurchase(msg.sender,_stableCoinAmount,tokenPurchased,_stableCoin,tokenRemainingForSale);
    }
    
    function _updateVestingSchedule(address _investor, uint256 _amount) internal {
        require(_investor != address(0), "Beneficiary cannot be empty");
        require(_amount > 0, "Amount cannot be empty");

        vestedAmount[_investor] =  vestedAmount[_investor].add(_amount);
    }
    
    /**
     * @notice Vesting schedule and associated data for an investor
     * @return _amount
     * @return _totalDrawn
     * @return _lastDrawnAt
     * @return _remainingBalance
     * @return _availableForDrawDown
     */
    function vestingScheduleForBeneficiary(address _investor)
    external view
    returns (uint256 _amount, uint256 _totalDrawn, uint256 _lastDrawnAt, uint256 _remainingBalance, uint256 _availableForDrawDown) {
        return (
        vestedAmount[_investor],
        totalDrawn[_investor],
        lastDrawnAt[_investor],
        vestedAmount[_investor].sub(totalDrawn[_investor]),
        _availableDrawDownAmount(_investor)
        );
    }

     /**
     * @notice Draw down amount currently available (based on the block timestamp)
     * @param _investor beneficiary of the vested tokens
     * @return _amount tokens due from vesting schedule
     */
    function availableDrawDownAmount(address _investor) external view returns (uint256 _amount) {
        return _availableDrawDownAmount(_investor);
    }
    
    function _availableDrawDownAmount(address _investor) internal view returns (uint256 _amount) {
        
        // Cliff Period
        if (_getNow() <= vestingStart.add(cliffDuration) || vestingStart == 0) {
            // the cliff period has not ended, no tokens to draw down
            return 0;
        }

        // Schedule complete
        if (_getNow() > vestingEnd) {
            return vestedAmount[_investor].sub(totalDrawn[_investor]);
        }

        // Schedule is active

        // Work out when the last invocation was
        uint256 timeLastDrawnOrStart = lastDrawnAt[_investor] == 0 ? vestingStart : lastDrawnAt[_investor];

        // Find out how much time has past since last invocation
        uint256 timePassedSinceLastInvocation = _getNow().sub(timeLastDrawnOrStart);

        // Work out how many due tokens - time passed * rate per second
        uint256 drawDownRate = vestedAmount[_investor].div(vestingEnd.sub(vestingStart));
        uint256 amount = timePassedSinceLastInvocation.mul(drawDownRate);

        return amount;
    }

    /**
     * @notice Draws down any vested tokens due
     * @dev Must be called directly by the investor assigned the tokens in the schedule
     */
    function drawDown() external isCrowdsaleOver nonReentrant {
        _drawDown(msg.sender);
    }
    
    function _drawDown(address _investor) internal {
        require(vestedAmount[_investor] > 0, "There is no schedule currently in flight");

        uint256 amount = _availableDrawDownAmount(_investor);
        require(amount > 0, "No allowance left to withdraw");

        // Update last drawn to now
        lastDrawnAt[_investor] = _getNow();

        // Increase total drawn amount
        totalDrawn[_investor] = totalDrawn[_investor].add(amount);

        // Safety measure - this should never trigger
        require(
            totalDrawn[_investor] <= vestedAmount[_investor],
            "Safety Mechanism - Drawn exceeded Amount Vested"
        );

        // Issue tokens to investor
        require(token.transfer(_investor, amount), "Unable to transfer tokens");

        emit DrawDown(_investor, amount,_getNow());
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function getContractTokenBalance(IERC20 _token) public view returns (uint256) {
        return _token.balanceOf(address(this));
    }
    
    /**
     * @notice Balance remaining in vesting schedule
     * @param _investor beneficiary of the vested tokens
     * @return _remainingBalance tokens still due (and currently locked) from vesting schedule
    */
    function remainingBalance(address _investor) public view returns (uint256) {
        return vestedAmount[_investor].sub(totalDrawn[_investor]);
    }
    
    function endCrowdsale(uint256 _vestingStartTime,uint256 _vestingEndTime,uint256 _cliffDurationInSecs) external onlyOwner {
        require(crowdsaleEndTime == 0,"Crowdsale would end automatically after endTime");
        crowdsaleEndTime = _getNow();
        require(_vestingStartTime >= crowdsaleEndTime, "Start time should >= Crowdsale EndTime");
        require(_vestingEndTime > _vestingStartTime.add(_cliffDurationInSecs), "End Time should after the cliffPeriod");

        vestingStart = _vestingStartTime;
        vestingEnd = _vestingEndTime;
        cliffDuration = _cliffDurationInSecs;
        if(tokenRemainingForSale!=0){
            withdrawFunds(token,tokenRemainingForSale);  //when crowdsaleEnds withdraw unsold tokens to the owner
        }
        emit CrowdsaleEndedManually(crowdsaleEndTime);
    }
    
    function withdrawFunds(IERC20 _token, uint256 amount) public isCrowdsaleOver onlyOwner {
        require(getContractTokenBalance(_token) >= amount,"the contract doesnt have tokens");

        _token.transfer(msg.sender, amount);
        
        emit FundsWithdrawn(msg.sender,_token,amount);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;
    }

    /**
     * @dev Whitelist new user address , such that user can participate in crowdsale
     * Can only be called by the current owner.
     */
    function whitelist(address user) public virtual onlyOwner {
        whitelistedAddress[user] = true;
    }
}

pragma solidity ^0.7.0;

// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}