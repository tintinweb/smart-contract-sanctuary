/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;


/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

/**
  * @title Careful Math
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// SPDX-License-Identifier: MIT
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
contract UsageRewardDistribution is CarefulMath {
        
    using SafeMath for uint256;

    /// @notice GIANT token address to distribute on burning Dollar
    address public giantToken;
    
    /// @notice Current GIANT token distribution per Dollar burn
    uint256 public currentGiantPerDollar = 20e18;
    
    /// @notice To calcuate next GIANT token distribution per Dollar burn (currentGiantPerDollar / nextGiantPerDollarScale)
    uint8 public nextGiantPerDollarScale = 2;

    /// @notice Current cycle
    uint8 public currentCycle = 0;
    
    /// @notice Total Dollar burn on the app
    uint256 public totalDollarBurned = 0;
    
    /// @notice Total Giant token distributed while burning the Dollar
    uint256 public totalGiantDistributed = 0;

    /// @notice Current Dollar burn cap
    uint256 public currentDollarBurnCap = 200_000e18;
    
    /// @notice Dollar burn current cycle
    uint256 public dollarBurnPerCycle = 200_000e18;

    /// @notice Reset or update the distribution value
    bool public isUpdateDistributionValue = true;
    
    /**
     * @notice Next cap scale value 
     * dollarBurnPerCycle will be changed as per this scale value (dollarBurnPerCycle * nextCapScale) once totalDollarBurned reached the currentDollarBurnCap
     */
    uint8 public nextCapScale = 2;
    
    /// @dev The current token decimal exponential value (i.e. 1000000000000000000)
    uint256 decimalExpScale = 1e18;

    address public admin;
    address public pendingAdmin;

    // ERROR object
    enum Error {
        NO_ERROR,
        TOKEN_NOT_LISTED,
        TOKEN_ALREADY_LISTED
    }

    event BurnDollar(address indexed spender, uint usedDollarValue);

    event DistributeGiant(address indexed spender, uint giantTokens);

    event AddedGiantTokenForDistribution(address indexed giantTokenAddress);

    event UpdatedDistributionCycleValue(uint8 currentCycle, uint256 currentGiantPerDollar, uint256 currentDollarBurnCap, uint256 dollarBurnPerCycle, uint256 totalDollarBurned, uint256 totalGiantDistributed);

    /**
     * @notice Construct a new UsageRewardDistribution contract
     */
    constructor() public {
        admin = msg.sender;
    }

    struct UsageTokenLocalVars {
        Error err;
        MathError mathErr;
        address spender;
        uint256 usedDollarValue;
        uint256 balanceNew;
        uint256 totalBurnedNew;
        uint256 totalSupplyNew;
        uint256 giantTokenValueNew;
        uint256 totalGiantDistributedNew;
        uint256 giantPerDollarNew;
        uint256 nextDollarBurnCapNew;
        uint256 dollarBurnPerCycleNew;
        uint8 currentCycleNew;
    }

     /**
     * @notice Admin record the user's spend dollar amount in the app and send the earnd the GIANT token (Burn Dollar and earn GIANT)
     * @param spender The spender address to get the GIANT token
     * @param usedDollarValue The amount of the dollar to be burned
     * @return (uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol)
     */
    function getUsageRewardForUser(address payable spender, uint usedDollarValue) public returns (uint) {
        // Check caller = admin
        require(msg.sender == admin);
        return usageRewardFresh(spender, usedDollarValue);
    }
    
    /**
     * @notice Admin record the user's spend dollar amount in the app and send the earnd the GIANT token (Burn Dollar and earn GIANT)
     * @param spender The spender address to get the GIANT token
     * @param usedDollarValue The amount of the dollar to be burned
     * @return (uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol)
     */
    function usageRewardFresh(address payable spender, uint usedDollarValue) internal returns (uint) {
        
        require(uint128(usedDollarValue) == usedDollarValue);
        require(usedDollarValue > 0, "UsageRewardDistribution::usageRewardFresh: cannot earn GIANT token for 0 usage");
        require(EIP20NonStandardInterface(giantToken) != EIP20NonStandardInterface(0x0));

        uint256 giantBalance = EIP20NonStandardInterface(giantToken).balanceOf(address(this));
        require(giantBalance > 0, "UsageRewardDistribution::usageRewardFresh: giant balance is 0");
        
        UsageTokenLocalVars memory vars;
        vars.spender = spender;
        vars.usedDollarValue = usedDollarValue;
        vars.dollarBurnPerCycleNew = dollarBurnPerCycle;
        vars.giantPerDollarNew = currentGiantPerDollar;
        vars.nextDollarBurnCapNew = currentDollarBurnCap;
        vars.currentCycleNew = currentCycle;
        
        /*
         * We calculate the new totalDollarBurned and checking for overflow:
         *  totalBurnedNew = totalDollarBurned + usedDollarValue
         */
        
        (vars.mathErr, vars.totalBurnedNew) = addUInt(totalDollarBurned, usedDollarValue);
        require(vars.mathErr == MathError.NO_ERROR, "UsageRewardDistribution::usageRewardFresh: adding used token with totalDollarBurned is failed");
        
        /*
         * Check totalBurned dollar value and reset the next cap value and make sure that is giant token available to distribute
         *  dollarBurnPerCycleNew = dollarBurnPerCycle * nextCapScale
         *  nextDollarBurnCapNew = currentDollarBurnCap + dollarBurnPerCycleNew
         *  giantPerDollarNew = currentGiantPerDollar / nextGiantPerDollarScale
         */
        if (vars.totalBurnedNew >= currentDollarBurnCap) {
            uint256 nextCapSpendToken = 0;
            uint256 currentCapSpendToken = 0;
            
            (vars.mathErr, vars.dollarBurnPerCycleNew) = mulUInt(dollarBurnPerCycle, nextCapScale);
            require(vars.mathErr == MathError.NO_ERROR, "UsageRewardDistribution::usageRewardFresh: calculating next dollarBurnPerCycle is failed");
            
            (vars.mathErr, vars.nextDollarBurnCapNew) = addUInt(currentDollarBurnCap, vars.dollarBurnPerCycleNew);
            require(vars.mathErr == MathError.NO_ERROR, "UsageRewardDistribution::usageRewardFresh: calculating next dollarBurnCap is failed");
            
            (vars.mathErr, vars.giantPerDollarNew) = divUInt(currentGiantPerDollar, nextGiantPerDollarScale);
            require(vars.mathErr == MathError.NO_ERROR, "UsageRewardDistribution::usageRewardFresh: calculating next giantPerDollar is failed");
            
            (vars.mathErr, nextCapSpendToken) = subUInt(vars.totalBurnedNew, currentDollarBurnCap);
            require(vars.mathErr == MathError.NO_ERROR, "UsageRewardDistribution::usageRewardFresh: calculating next cycle token usage (i.e. exceeds from the current cap) is failed");
            
            if(nextCapSpendToken > 0) {
                (vars.mathErr, currentCapSpendToken) = subUInt(usedDollarValue, nextCapSpendToken);
                require(vars.mathErr == MathError.NO_ERROR, "UsageRewardDistribution::usageRewardFresh: calculating current cycle token usage is failed");
                uint256 currentCapEarnToken = 0;
                uint256 nextCapEarnToken = 0;
                
                (currentCapEarnToken, vars.totalGiantDistributedNew) = calculateGiantToken(currentCapSpendToken, currentGiantPerDollar, totalGiantDistributed);
                (nextCapEarnToken, vars.totalGiantDistributedNew) = calculateGiantToken(nextCapSpendToken, vars.giantPerDollarNew, vars.totalGiantDistributedNew);
                
                (vars.mathErr, vars.giantTokenValueNew) = addUInt(currentCapEarnToken, nextCapEarnToken);
                require(vars.mathErr == MathError.NO_ERROR, "UsageRewardDistribution::usageRewardFresh: calculating earned giantTokenValue is failed");
            } else {
                (vars.giantTokenValueNew, vars.totalGiantDistributedNew) = calculateGiantToken(usedDollarValue, currentGiantPerDollar, totalGiantDistributed);
            }

            vars.currentCycleNew = currentCycle + 1;
        } else {
            (vars.giantTokenValueNew, vars.totalGiantDistributedNew) = calculateGiantToken(usedDollarValue, currentGiantPerDollar, totalGiantDistributed);
        }

        require(giantBalance >= vars.giantTokenValueNew, "UsageRewardDistribution::usageRewardFresh: giant balance is lesser then reward value");
        
        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferGiant for the spender and the giantTokenValueNew.
         *  On success, the spender will receive (giantTokenValueNew) number of GIANT token.
         *  doTransferGiant reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferGiant(spender, vars.giantTokenValueNew);
        
        /* We write previously calculated values into storage */
        totalDollarBurned = vars.totalBurnedNew;
        totalGiantDistributed = vars.totalGiantDistributedNew;
        
        currentDollarBurnCap = vars.nextDollarBurnCapNew;
        dollarBurnPerCycle = vars.dollarBurnPerCycleNew;
        currentGiantPerDollar = vars.giantPerDollarNew;
        currentCycle = vars.currentCycleNew;
        
         /* We emit a Burn event, and a Distribute event */
        emit BurnDollar(spender, usedDollarValue);
        emit DistributeGiant(spender, vars.giantTokenValueNew);

        return (uint(Error.NO_ERROR));
    }
    
    /**
     * @notice Internal function to calculate the giant token to be distributed to the user
     * @param usedDollarValue The number of dollar to be burned 
     * @param giantPerDollar The number giant to be distributed per dollar
     * @param giantDistributed The total amount of giant distributed
     * @return (uint, uint) The number of giant to be distributed and the total amount of giant distributed.
     */
    function calculateGiantToken(uint usedDollarValue, uint256 giantPerDollar, uint256 giantDistributed) internal view returns (uint, uint) {
        
        uint256 giantTokenValueNew;
        uint256 totalGiantDistributedNew;
        MathError mathErr;
        /*
         * Calucated the giantToken to be distributed to the spender as per the usedDollarValue with current rate
         *  giantTokenValueNew = currentGiantPerDollar * usedDollarValue / decimalExpScale
         */
        (mathErr, giantTokenValueNew) = mulUInt(giantPerDollar, usedDollarValue);
        require(mathErr == MathError.NO_ERROR, "UsageRewardDistribution::calculateGiantToken: calculating earned giantTokenValue with usedDollarValue is failed");
        
        (mathErr, giantTokenValueNew) = divUInt(giantTokenValueNew, decimalExpScale);
        require(mathErr == MathError.NO_ERROR, "UsageRewardDistribution::calculateGiantToken: calculating earned giantTokenValue with decimal value is failed");
        
        (mathErr, totalGiantDistributedNew) = addUInt(giantDistributed, giantTokenValueNew);
        require(mathErr == MathError.NO_ERROR, "UsageRewardDistribution::calculateGiantToken: calculating totalGiantDistributed value is failed");
        
        return (giantTokenValueNew, totalGiantDistributedNew);
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferGiant(address payable to, uint amount) internal returns (uint) {
        
        EIP20NonStandardInterface token = EIP20NonStandardInterface(address(giantToken));
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "UsageRewardDistribution::doTransferGiant: token transfer out failed");
        
        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Before GIANT token distribution, configure the giant token address 
      * @dev Admin function to add giant token address.
      * @param giantTokenAddress New Dollar token address.
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setGiantToken(address giantTokenAddress) external returns (uint) {
        // Check caller = admin
        require(msg.sender == admin);
        
        giantToken =  giantTokenAddress;
        
        emit AddedGiantTokenForDistribution(address(giantTokenAddress));
        
        return uint(Error.NO_ERROR);
    }


    function _updateDistributionCycleValue(uint8 currentCycleNew, uint256 currentGiantPerDollarNew, uint256 currentDollarBurnCapNew, uint256 dollarBurnPerCycleNew, uint256 totalDollarBurnedNew, uint256 totalGiantDistributedNew) external returns (uint) {
        // Check caller = admin
        require(msg.sender == admin);
        require(isUpdateDistributionValue == true, "UsageRewardDistribution::_updateDistributionCycleValue: cannot update the distribution cycle value");
        require(currentCycleNew >= currentCycle, "UsageRewardDistribution::_updateDistributionCycleValue: currentCycle is higher then new value");
        require(currentGiantPerDollarNew <= currentGiantPerDollar, "UsageRewardDistribution::_updateDistributionCycleValue: currentGiantPerDollar is lesser then new value");
        require(currentDollarBurnCapNew >= currentDollarBurnCap, "UsageRewardDistribution::_updateDistributionCycleValue: currentDollarBurnCap is higher then new value");
        require(dollarBurnPerCycleNew >= dollarBurnPerCycle, "UsageRewardDistribution::_updateDistributionCycleValue: dollarBurnPerCycle is higher then new value");
        require(totalDollarBurnedNew >= totalDollarBurned, "UsageRewardDistribution::_updateDistributionCycleValue: totalDollarBurned is higher then new value");
        require(totalGiantDistributedNew >= totalGiantDistributed, "UsageRewardDistribution::_updateDistributionCycleValue: totalGiantDistributed is higher then new value");

        isUpdateDistributionValue = false;
        currentCycle = currentCycleNew;
        currentGiantPerDollar = currentGiantPerDollarNew;
        currentDollarBurnCap = currentDollarBurnCapNew;
        dollarBurnPerCycle = dollarBurnPerCycleNew;
        totalDollarBurned = totalDollarBurnedNew;
        totalGiantDistributed = totalGiantDistributedNew;

        emit UpdatedDistributionCycleValue(currentCycleNew, currentGiantPerDollarNew, currentDollarBurnCapNew, dollarBurnPerCycleNew, totalDollarBurnedNew, totalGiantDistributedNew);

        return uint(Error.NO_ERROR);
    }
    
    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address payable newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin);

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin);
        require(msg.sender != address(0));

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);
    }

}