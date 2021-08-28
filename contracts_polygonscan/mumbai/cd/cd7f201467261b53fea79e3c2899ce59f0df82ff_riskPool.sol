/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT

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


interface IinvestedPool {
    function getLiquidity() external view returns(uint256);
    
    function getBondDueDate() external view returns(uint256);
    
    function registerNewApplication(uint256 _decresedLiquidity) external;
    
    function decreaseInvestedPoolBalance(uint256 _compensatedAmount) external;
    
    function increaseInvestedPoolBalance(uint256 _amount) external;
} 



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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor() {
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



/** @dev Set event and override the interface
 * 
 */ 
contract riskPool is Ownable {
    using SafeMath for uint256;
    
     // Initialized insuredId.
    uint256 public nextInsuredId = 0;
    uint256 public constant Tday = 86400;
    uint256 public constant T365days = 31536000;
    
    uint256 public investmentMultiple;
    
    uint256 public baseInsuredPeriod;
    
    uint256 public insuredDeadline;
    
    uint256 public insuranceDueDate;
    
    uint256 public extendedInsuredDays;
    
    uint256[] public earthquakeOccuranceTime;
    
    uint256 public totalMaxPayoutAmount;
    
    uint256 public totalPayoutAmount;
    
    uint256 public riskPoolBalanceForPayout;

    uint256 public investedPoolMaxBalanceForPayout;
    
    uint256 public investedPoolRemainingBalanceForPayout;
    
    address public investedPoolAddress;
    
    
    
    
    
    
    // insuredId => insuredAddress
    mapping(uint256 => address) insuredAddress;
    
    // insuredId => Content
    mapping(uint256 => Content) Contents;
    
    // earthquakeIntensity => insuranceCoef
    mapping(uint256 => uint256) insuranceCoef;
    
    // insuredId => excessPremium received or not
    mapping(uint256 => bool) excessPremiumReceived;
    
    IinvestedPool investedPool;
    IERC20 JPYC = IERC20(0xf4e5335a8Db75157b6288d447f3a67ddECc01ED8); // JPYC on Mumbai testnet
    
    /** earthquakeIntensity is 8 or 9 or 10.
     * 
     */ 
    struct Content {
        uint256 premium;
        uint256 realAddress;
        uint256 applyingtime;
        uint256 earthquakeIntensity;
        bool damaged;
        address bondPurchaser;
        
    }
    
    /** @dev 
     * 
     */
    function getContent(uint256 insuredId) external view returns(
        uint256 premium,
        uint256 realAddress,
        uint256 applyingtime,
        uint256 earthquakeIntensity,
        bool damaged,
        address bondPurchaser
        ) {
        return (
        Contents[insuredId].premium,
        Contents[insuredId].realAddress,
        Contents[insuredId].applyingtime,
        Contents[insuredId].earthquakeIntensity,
        Contents[insuredId].damaged,
        Contents[insuredId].bondPurchaser
        );
    }
    
    function getInvestmentMultiple() external view returns(uint256) {
        return investmentMultiple;
    }
    
    function getBaseInsuredPeriod() external view returns(uint256) {
        return baseInsuredPeriod;
    }
    
    function getEarthquakeOccuranceTime0() external view returns(uint256) {
        return earthquakeOccuranceTime[0];
    }
    
    function getInvestedPoolMaxBalanceForPayout() external view returns(uint256) {
        return investedPoolMaxBalanceForPayout;
    }
    
    function getInvestedPoolRemainingBalanceForPayout() external view returns(uint256) {
        return investedPoolRemainingBalanceForPayout;
    }
    
    /**
     * @param _investmentMultiple is e.g. 5
     */ 
    function setInvestmentMultiple(uint256 _investmentMultiple) public onlyOwner {
        investmentMultiple = _investmentMultiple;
    }
    
    /** Set T365days
     * @param _baseInsuredPeriod is period, not point
     */ 
    function setBaseInsuredPeriod(uint256 _baseInsuredPeriod) public onlyOwner {
        baseInsuredPeriod = _baseInsuredPeriod;
    }
    
    // 6 lower : 8, 6upper : 9, seven : 10
    function setInsuranceCoefs(uint256 _sixLowerCoef, uint256 _sixUpperCoef, uint256 _sevenCoef) public onlyOwner {
        insuranceCoef[8] = _sixLowerCoef; // 2 multiple
        insuranceCoef[9] = _sixUpperCoef; // 10 multiple
        insuranceCoef[10] = _sevenCoef;  // 50 multiple
    }
    
    // 15-45 days are appropriate
    function setExtendedInsuredDays(uint256 _extendedInsuredDays) public onlyOwner {
        extendedInsuredDays = _extendedInsuredDays;
    }
    
    function setInvestedPool(address _investedPoolAddress) public onlyOwner {
        investedPool = IinvestedPool(_investedPoolAddress);
        investedPoolAddress = _investedPoolAddress;
    }
    
    function approveInvestedPool() public onlyOwner {
        JPYC.approve(investedPoolAddress, 2**256 - 1);
    }
    
    /**  Call Approve of JPYC contract before newAppliction
     * @dev 20 % of bondInterestRate is basis of _premium * 5 in require
     * you have to require underwritten before newApplication when you make your product.
     * 
     * @param _premium is JPYC amount with 18 decimals
     * @param _realAddress is latitude and longtitude
     * @param _insuredPoint is block.timestamp when applying.
     * 
     */
    function newApplication(
        uint256 _premium,
        uint256 _realAddress,
        uint256 _insuredPoint
        ) public 
        returns(bool) {
        require(investedPool.getLiquidity() >= _premium * investmentMultiple, "No sufficient liquidity.");
        
        uint256 insuredId = nextInsuredId;
        insuredAddress[insuredId] = msg.sender;
        JPYC.transferFrom(insuredAddress[insuredId], address(this), _premium);
            
        
        Contents[insuredId] = Content(
            _premium,
            _realAddress,
            _insuredPoint,
            0,
            false,
            investedPoolAddress
            );
            
        investedPool.registerNewApplication(_premium * investmentMultiple);
            
        nextInsuredId.add(1);
        
        return true;
    }
    
    function changeBondPurchaser(uint256 insuredId, address _newPurchaser) external {
        require(msg.sender == investedPoolAddress, "You are not the purchaser.");
        
        Contents[insuredId].bondPurchaser = _newPurchaser;
    }
    
    // this function is just test ver. Use Oracle and change the structure of this function when you release your product.
    function requestEarthquakeOccuranceTime() public onlyOwner {
        earthquakeOccuranceTime.push(block.timestamp);
        insuredDeadline = block.timestamp.add(extendedInsuredDays);
        
        insuranceDueDate = insuredDeadline + Tday;
    }
    
    /** 
     * Use "require" to call this function after insuredDeadline when you make your product.
     * You have to return premium equivalent to the rest of their insurance period, so calculate amount for payout in the riskPool.
     * 
     */ 
    function calculateRiskPoolBalanceForPayout() public returns(uint256) {
        
        for (uint256 i = 0; i < nextInsuredId; i++) {
            uint256 _ratio;
            
            if (earthquakeOccuranceTime[0] <= Contents[i].applyingtime + baseInsuredPeriod
                && earthquakeOccuranceTime[0] > Contents[i].applyingtime) {
                _ratio = insuredDeadline.sub(Contents[i].applyingtime) / T365days;
            
            } else {
                _ratio = 0;
            }
            
            
            riskPoolBalanceForPayout += (Contents[i].premium * _ratio);
        }
        return riskPoolBalanceForPayout;
    }
    
    /** 
     * Use "require" to call this function after insuredDeadline when you make your product.
     * You have to return premium equivalent to the rest of their insurance period, so calculate amount for payout in the riskPool.
     * 
     */ 
    function calculateInvestedPoolBalanceForPayout() public returns(uint256) {
        for (uint256 i = 0; i < nextInsuredId; i++) {
            uint256 _investedPoolMaxBalanceForPayout;
            
            if (earthquakeOccuranceTime[0] <= Contents[i].applyingtime + baseInsuredPeriod
                && earthquakeOccuranceTime[0] > Contents[i].applyingtime) {
                _investedPoolMaxBalanceForPayout = Contents[i].premium * investmentMultiple;
            } else {
                
            }
            
            investedPoolMaxBalanceForPayout += _investedPoolMaxBalanceForPayout;
        }
        return investedPoolMaxBalanceForPayout;
    }
    
    /** @dev  this function is just test ver. Use Oracle and change the structure of this function when you release your product.
     * Be careful not to decrease earthquakeIntensity when the second earthquake is weaker.
     * Be careful not to set the information about expired insuredId
     */
    
    function requestDamageInformation(uint256 insuredId, uint256 _earthquakeIntensity) public onlyOwner {
        
        if (Contents[insuredId].damaged) {
            uint256 _alreadySetMaxPayoutAmount = Contents[insuredId].premium * insuranceCoef[Contents[insuredId].earthquakeIntensity];
            totalMaxPayoutAmount = totalMaxPayoutAmount.sub(_alreadySetMaxPayoutAmount);
            
            uint256 _maxPayoutAmount = Contents[insuredId].premium * insuranceCoef[_earthquakeIntensity];
            totalMaxPayoutAmount = totalMaxPayoutAmount.add(_maxPayoutAmount);
            
        } else {
            uint256 _maxPayoutAmount = Contents[insuredId].premium * insuranceCoef[_earthquakeIntensity];
            totalMaxPayoutAmount = totalMaxPayoutAmount.add(_maxPayoutAmount);
            
        }
        
        Contents[insuredId].earthquakeIntensity = _earthquakeIntensity;
        Contents[insuredId].damaged = true;
    }
    
     
     
    
    /** Call Approve of JPYC contract before claim
     * Do all requestDamageInformation() before claim
     * Use "require" to call this function after insuredDeadline when you make your product.
     * 
     */ 
    function determineTotalPayoutAmount() public onlyOwner {
        require(block.timestamp > insuredDeadline, "The insuredDeadline has not come.");
        uint256 _compensatedAmount;
        
        if (totalMaxPayoutAmount <= riskPoolBalanceForPayout) {
            
            uint256 _remainingAmount = riskPoolBalanceForPayout - totalMaxPayoutAmount;
            
            JPYC.transfer(investedPoolAddress, _remainingAmount);
            
            riskPoolBalanceForPayout -= _remainingAmount;
            
            investedPoolRemainingBalanceForPayout = investedPoolMaxBalanceForPayout + _remainingAmount;
            
        } else if (
            riskPoolBalanceForPayout < totalMaxPayoutAmount 
            && totalMaxPayoutAmount <= riskPoolBalanceForPayout.add(investedPoolMaxBalanceForPayout)
            ) {
            
            _compensatedAmount = totalMaxPayoutAmount.sub(riskPoolBalanceForPayout);    
                
            JPYC.transferFrom(investedPoolAddress, address(this), _compensatedAmount);
            
            riskPoolBalanceForPayout += _compensatedAmount;
            
            investedPoolRemainingBalanceForPayout = investedPoolMaxBalanceForPayout - _compensatedAmount;
            
        } else {
            
            _compensatedAmount = investedPoolMaxBalanceForPayout;
            
            JPYC.transferFrom(investedPoolAddress, address(this), _compensatedAmount);
            
            riskPoolBalanceForPayout += _compensatedAmount;
            
            investedPoolRemainingBalanceForPayout = 0;
        }
        totalPayoutAmount = riskPoolBalanceForPayout;
    }
    
    
    /** Call Approve of JPYC contract before claim
     * Compensate from investedPool before claim
     * 
     */
    function ClaimInsurance(uint256 insuredId, address _receiver) public {
        require(msg.sender == insuredAddress[insuredId], "You are not insured.");
        require(Contents[insuredId].damaged, "You are not damaged.");
        require(block.timestamp > insuranceDueDate, "The insuranceDueDate has not come.");
        
        uint256 _maxPayoutAmount = Contents[insuredId].premium * insuranceCoef[Contents[insuredId].earthquakeIntensity];
        uint256 _payoutAmount = _maxPayoutAmount * (totalPayoutAmount / totalMaxPayoutAmount);
        
        JPYC.transfer(_receiver, _payoutAmount);
        
        Contents[insuredId].damaged = false;
    }
    
    function returnExcessPremium(uint256 insuredId, address _receiver) public {
        require(msg.sender == insuredAddress[insuredId], "You are not insured.");
        require(earthquakeOccuranceTime[0] > Contents[insuredId].applyingtime
                && earthquakeOccuranceTime[0] < Contents[insuredId].applyingtime + baseInsuredPeriod,
                "Your insured period was over.");
        require(Contents[insuredId].earthquakeIntensity == 0, "you have to receive insurance, not excesspremium");
        require(block.timestamp > insuranceDueDate, "The insuranceDueDate has not come.");
        require(excessPremiumReceived[insuredId] == false, "You already have received an excess premium.");
        
        uint256 _insuredPeriod = insuredDeadline.sub(Contents[insuredId].applyingtime);
        uint256 _excessPremium = Contents[insuredId].premium * (baseInsuredPeriod - _insuredPeriod) / baseInsuredPeriod;
        
        JPYC.transfer(_receiver, _excessPremium);
        
        excessPremiumReceived[insuredId] = true;
    }
    
    
    
    
    // Set withdraw function for prescription
    

        

    
    
}