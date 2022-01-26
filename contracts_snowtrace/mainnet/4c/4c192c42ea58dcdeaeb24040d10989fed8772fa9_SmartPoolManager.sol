/**
 *Submitted for verification at snowtrace.io on 2022-01-26
*/

// File: contracts/libraries/KassandraConstants.sol


pragma solidity ^0.8.0;

/**
 * @author Kassandra (from Balancer Labs)
 *
 * @title Put all the constants in one place
 */
library KassandraConstants {
    // State variables (must be constant in a library)

    /// "ONE" - all math is in the "realm" of 10 ** 18; where numeric 1 = 10 ** 18
    uint public constant ONE               = 10**18;

    /// Minimum denormalized weight one token can have
    uint public constant MIN_WEIGHT        = ONE / 10;
    /// Maximum denormalized weight one token can have
    uint public constant MAX_WEIGHT        = ONE * 50;
    /// Maximum denormalized weight the entire pool can have
    uint public constant MAX_TOTAL_WEIGHT  = ONE * 50;

    /// Minimum token balance inside the pool
    uint public constant MIN_BALANCE       = ONE / 10**6;
    // Maximum token balance inside the pool
    // uint public constant MAX_BALANCE       = ONE * 10**12;

    /// Minimum supply of pool tokens
    uint public constant MIN_POOL_SUPPLY   = ONE * 100;
    /// Maximum supply of pool tokens
    uint public constant MAX_POOL_SUPPLY   = ONE * 10**9;

    /// Default fee for exiting a pool
    uint public constant EXIT_FEE          = ONE * 3 / 100;
    /// Minimum swap fee possible
    uint public constant MIN_FEE           = ONE / 10**6;
    /// Maximum swap fee possible
    uint public constant MAX_FEE           = ONE / 10;

    /// Maximum ratio of the token balance that can be sent to the pool for a swap
    uint public constant MAX_IN_RATIO      = ONE / 2;
    /// Maximum ratio of the token balance that can be taken out of the pool for a swap
    uint public constant MAX_OUT_RATIO     = (ONE / 3) + 1 wei;

    /// Minimum amount of tokens in a pool
    uint public constant MIN_ASSET_LIMIT   = 2;
    /// Maximum amount of tokens in a pool
    uint public constant MAX_ASSET_LIMIT   = 16;

    /// Maximum representable number in uint256
    uint public constant MAX_UINT          = type(uint).max;

    // Core Pools
    /// Minimum token balance inside the core pool
    uint public constant MIN_CORE_BALANCE  = ONE / 10**12;

    // Core Num
    /// Minimum base for doing a power of operation
    uint public constant MIN_BPOW_BASE     = 1 wei;
    /// Maximum base for doing a power of operation
    uint public constant MAX_BPOW_BASE     = (2 * ONE) - 1 wei;
    /// Precision of the approximate power function with fractional exponents
    uint public constant BPOW_PRECISION    = ONE / 10**10;
}

// File: contracts/libraries/KassandraSafeMath.sol


pragma solidity ^0.8.0;


/**
 * @author Kassandra (and Balancer Labs)
 *
 * @title SafeMath - Wrap Solidity operators to prevent underflow/overflow
 *
 * @dev mul/div have extra checks from OpenZeppelin SafeMath
 *      Most of this math is for dealing with 1 being 10^18
 */
library KassandraSafeMath {
    /**
     * @notice Safe signed subtraction
     *
     * @dev Do a signed subtraction
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        }
        return (b - a, true);
    }

    /**
     * @notice Safe multiplication
     *
     * @dev Multiply safely (and efficiently), rounding down
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Product of operands; throws if overflow or rounding error
     */
    function bmul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        uint c0 = a * b;
        // Round to 0 if x*y < ONE/2?
        uint c1 = c0 + (KassandraConstants.ONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        return c1 / KassandraConstants.ONE;
    }

    /**
     * @notice Safe division
     *
     * @dev Divide safely (and efficiently), rounding down
     *
     * @param dividend - First operand
     * @param divisor - Second operand
     *
     * @return Quotient; throws if overflow or rounding error
     */
    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0){
            return 0;
        }

        uint c0 = dividend * KassandraConstants.ONE;
        require(c0 / dividend == KassandraConstants.ONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        return c1 / divisor;
    }

    /**
     * @notice Safe unsigned integer modulo
     *
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - First operand
     * @param divisor - Second operand -- cannot be zero
     *
     * @return Quotient; throws if overflow or rounding error
     */
    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Maximum of a and b
     */
    function bmax(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Minimum of a and b
     */
    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     *
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - First operand
     * @param b - Second operand
     *
     * @return Average of the two values
     */
    function baverage(uint a, uint b) internal pure returns (uint) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     *
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     *
     * @param y - Operand
     *
     * @return z - Square root result
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        }
        else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @notice Remove the fractional part
     *
     * @dev Assumes the fractional part being everything below 10^18
     *
     * @param a - Operand
     *
     * @return Integer part of `a`
     */
    function btoi(uint a) internal pure returns (uint) {
        return a / KassandraConstants.ONE;
    }

    /**
     * @notice Floor function - Zeros the fractional part
     *
     * @dev Assumes the fractional part being everything below 10^18
     *
     * @param a - Operand
     *
     * @return Greatest integer less than or equal to x
     */
    function bfloor(uint a) internal pure returns (uint) {
        return btoi(a) * KassandraConstants.ONE;
    }

    /**
     * @notice Compute a^n where `n` does not have a fractional part
     *
     * @dev Based on code by _DSMath_, `n` must not have a fractional part
     *
     * @param a - Base that will be raised to the power of `n`
     * @param n - Integer exponent
     *
     * @return z - `a` raise to the power of `n`
     */
    function bpowi(uint a, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? a : KassandraConstants.ONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
    }

    /**
     * @notice Compute b^e where `e` has a fractional part
     *
     * @dev Compute b^e by splitting it into (b^i)*(b^f)
     *      Where `i` is the integer part and `f` the fractional part
     *      Uses `bpowi` for `b^e` and `bpowK` for k iterations of approximation of b^0.f
     *
     * @param base - Base that will be raised to the power of exp
     * @param exp - Exponent
     *
     * @return Approximation of b^e
     */
    function bpow(uint base, uint exp) internal pure returns (uint) {
        require(base >= KassandraConstants.MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= KassandraConstants.MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint integerPart  = btoi(exp);
        uint fractionPart = exp - (integerPart * KassandraConstants.ONE);

        uint integerPartPow = bpowi(base, integerPart);

        if (fractionPart == 0) {
            return integerPartPow;
        }

        uint fractionPartPow = bpowApprox(base, fractionPart, KassandraConstants.BPOW_PRECISION);
        return bmul(integerPartPow, fractionPartPow);
    }

    /**
     * @notice Compute an approximation of b^e where `e` is a fractional part
     *
     * @dev Computes b^e for k iterations of approximation of b^0.f
     *
     * @param base - Base that will be raised to the power of exp
     * @param exp - Fractional exponent
     * @param precision - When the adjustment term goes below this number the function stops
     *
     * @return sum - Approximation of b^e according to precision
     */
    function bpowApprox(uint base, uint exp, uint precision) internal pure returns (uint sum) {
        // term 0:
        (uint x, bool xneg) = bsubSign(base, KassandraConstants.ONE);
        uint term = KassandraConstants.ONE;
        bool negative = false;
        sum = term;

        // term(k) = numer / denom
        //         = (product(exp - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (exp-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * KassandraConstants.ONE;
            (uint c, bool cneg) = bsubSign(exp, (bigK - KassandraConstants.ONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);

            if (term == 0) break;

            if (xneg) negative = !negative;

            if (cneg) negative = !negative;

            if (negative) {
                sum -= term;
            } else {
                sum += term;
            }
        }
    }
}

// File: contracts/interfaces/IOwnable.sol


pragma solidity ^0.8.0;

/**
 * @title Ownable.sol interface
 *
 * @dev Other interfaces might inherit this one so it may be unnecessary to use it
 */
interface IOwnable {
    function getController() external view returns (address);
}

// File: contracts/interfaces/IMath.sol


pragma solidity ^0.8.0;

/**
 * @title Interface for the pure math functions
 *
 * @dev IPool inherits this, so it's only needed if you only want to interact with the Math functions
 */
interface IMath {
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee,
        uint exitFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee,
        uint exitFee
    )
        external pure
        returns (uint poolAmountIn);
}

// File: contracts/interfaces/IPool.sol


pragma solidity ^0.8.0;


/**
 * @title Core pool definition
 *
 * @dev Only contains the definitions of the Pool.sol contract and no parent classes
 */
interface IPoolDef {
    function setSwapFee(uint swapFee) external;
    function setExitFee(uint exitFee) external;
    function setPublicSwap(bool publicSwap) external;
    function setExitFeeCollector(address feeCollector) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function rebind(address token, uint balance, uint denorm) external;

    function getExitFeeCollector() external view returns (address);
    function isPublicSwap() external view returns (bool);
    function isBound(address token) external view returns(bool);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function getExitFee() external view returns (uint);
}

/**
 * @title Core pool interface for external contracts
 *
 * @dev Joins the Core pool definition and the Math abstract contract
 */
interface IPool is IPoolDef, IMath {}

// File: contracts/interfaces/IERC20.sol


pragma solidity ^0.8.0;

/* solhint-disable ordering */

/**
 * @title An ERC20 compatible token interface
 */
interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

// File: contracts/libraries/SafeApprove.sol


pragma solidity ^0.8.0;


/**
 * @author PieDAO (ported to Balancer Labs) (ported to Kassandra)
 *
 * @title SafeApprove - set approval for tokens that require 0 prior approval
 *
 * @dev Perhaps to address the known ERC20 race condition issue
 *      See https://github.com/crytic/not-so-smart-contracts/tree/master/race_condition
 *      Some tokens - notably KNC - only allow approvals to be increased from 0
 */
library SafeApprove {
    /**
     * @notice Handle approvals of tokens that require approving from a base of 0
     *
     * @param token - The token we're approving
     * @param spender - Entity the owner (sender) is approving to spend his tokens
     * @param amount - Number of tokens being approved
     *
     * @return Boolean to confirm execution worked
     */
    function safeApprove(IERC20 token, address spender, uint amount) internal returns (bool) {
        uint currentAllowance = token.allowance(address(this), spender);

        // Do nothing if allowance is already set to this value
        if (currentAllowance == amount) {
            return true;
        }

        // If approval is not zero reset it to zero first
        if (currentAllowance != 0) {
            return token.approve(spender, 0);
        }

        // do the actual approval
        return token.approve(spender, amount);
    }
}

// File: contracts/interfaces/IConfigurableRightsPool.sol


pragma solidity ^0.8.0;




/**
 * @title CRPool definition interface
 *
 * @dev Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
 *      Removing circularity allows flattener tools to work, which enables Etherscan verification
 *      Only contains the definitions of the ConfigurableRigthsPool.sol contract and no parent classes
 */
interface IConfigurableRightsPoolDef {
    function updateWeight(address token, uint newWeight) external;
    function updateWeightsGradually(uint[] calldata newWeights, uint startBlock, uint endBlock) external;
    function pokeWeights() external;
    function commitAddToken(address token, uint balance, uint denormalizedWeight) external;
    function applyAddToken() external;
    function removeToken(address token) external;
    function mintPoolShareFromLib(uint amount) external;
    function pushPoolShareFromLib(address to, uint amount) external;
    function pullPoolShareFromLib(address from, uint amount) external;
    function burnPoolShareFromLib(uint amount) external;

    function corePool() external view returns(IPool);
}

/**
 * @title CRPool interface for external contracts
 *
 * @dev Joins the CRPool definition and the token and ownable interfaces
 */
interface IConfigurableRightsPool is IConfigurableRightsPoolDef, IOwnable, IERC20 {}

// File: contracts/libraries/SmartPoolManager.sol


pragma solidity ^0.8.0;







/**
 * @author Kassandra (and Balancer Labs)
 *
 * @title Library for keeping CRP contract in a managable size
 * 
 * @notice Factor out weight updates, pool joining, pool exiting and token compliance
 */
library SmartPoolManager {
    // paramaters for adding a new token to the pool
    struct NewTokenParams {
        bool isCommitted;
        address addr;
        uint commitBlock;
        uint denorm;
        uint balance;
    }

    // For blockwise, automated weight updates
    // Move weights linearly from startWeights to endWeights,
    // between startBlock and endBlock
    struct GradualUpdateParams {
        uint startBlock;
        uint endBlock;
        uint[] startWeights;
        uint[] endWeights;
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */

    /**
     * @notice Update the weight of an existing token
     *
     * @dev Refactored to library to make CRPFactory deployable
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param token - Address of the token to be reweighted
     * @param newWeight - New weight of the token
     * @param minimumKacy - Minimum amount of $KACY to be enforced
     * @param kacyToken - $KACY address to be enforced
    */
    function updateWeight(
        IConfigurableRightsPool self,
        IPool corePool,
        address token,
        uint newWeight,
        uint minimumKacy,
        address kacyToken
    )
        external
    {
        require(newWeight >= KassandraConstants.MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(newWeight <= KassandraConstants.MAX_WEIGHT, "ERR_MAX_WEIGHT");

        uint currentWeight = corePool.getDenormalizedWeight(token);
        // Save gas; return immediately on NOOP
        if (currentWeight == newWeight) {
            return;
        }

        uint currentBalance = corePool.getBalance(token);
        uint totalSupply = self.totalSupply();
        uint totalWeight = corePool.getTotalDenormalizedWeight();
        uint poolShares;
        uint deltaBalance;
        uint deltaWeight;
        address controller = self.getController();

        if (newWeight < currentWeight) {
            // This means the controller will withdraw tokens to keep price
            // So they need to redeem SPTokens
            deltaWeight = currentWeight - newWeight;

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            poolShares = KassandraSafeMath.bmul(
                totalSupply,
                KassandraSafeMath.bdiv(deltaWeight, totalWeight)
            );

            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            deltaBalance = KassandraSafeMath.bmul(
                currentBalance,
                KassandraSafeMath.bdiv(deltaWeight, currentWeight)
            );

            // New balance cannot be lower than MIN_BALANCE
            uint newBalance = currentBalance - deltaBalance;

            require(newBalance >= KassandraConstants.MIN_BALANCE, "ERR_MIN_BALANCE");

            // First get the tokens from this contract (Pool Controller) to msg.sender
            corePool.rebind(token, newBalance, newWeight);
            require(minimumKacy <= corePool.getNormalizedWeight(kacyToken), "ERR_MIN_KACY");

            // Now with the tokens this contract can send them to controller
            bool xfer = IERC20(token).transfer(controller, deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            self.pullPoolShareFromLib(controller, poolShares);
            self.burnPoolShareFromLib(poolShares);
        }
        else {
            // This means the controller will deposit tokens to keep the price.
            // They will be minted and given SPTokens
            deltaWeight = newWeight - currentWeight;

            require((totalWeight + deltaWeight) <= KassandraConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            poolShares = KassandraSafeMath.bmul(
                totalSupply,
                KassandraSafeMath.bdiv(deltaWeight, totalWeight)
            );
            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            deltaBalance = KassandraSafeMath.bmul(
                currentBalance,
                KassandraSafeMath.bdiv(deltaWeight, currentWeight)
            );

            // First gets the tokens from controller to this contract (Pool Controller)
            bool xfer = IERC20(token).transferFrom(controller, address(this), deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            // Now with the tokens this contract can bind them to the pool it controls
            corePool.rebind(token, currentBalance + deltaBalance, newWeight);
            require(minimumKacy <= corePool.getNormalizedWeight(kacyToken), "ERR_MIN_KACY");

            self.mintPoolShareFromLib(poolShares);
            self.pushPoolShareFromLib(controller, poolShares);
        }
    }

    /**
     * @notice External function called to make the contract update weights according to plan
     *
     * @param corePool - Core Pool the CRP is wrapping
     * @param gradualUpdate - Gradual update parameters from the CRP
    */
    function pokeWeights(
        IPool corePool,
        GradualUpdateParams storage gradualUpdate
    )
        external
    {
        // Do nothing if we call this when there is no update plan
        if (gradualUpdate.startBlock == 0) {
            return;
        }

        // Error to call it before the start of the plan
        require(block.number >= gradualUpdate.startBlock, "ERR_CANT_POKE_YET");
        // Proposed error message improvement
        // require(block.number >= startBlock, "ERR_NO_HOKEY_POKEY");

        // This allows for pokes after endBlock that get weights to endWeights
        // Get the current block (or the endBlock, if we're already past the end)
        uint currentBlock;
        if (block.number > gradualUpdate.endBlock) {
            currentBlock = gradualUpdate.endBlock;
        }
        else {
            currentBlock = block.number;
        }

        uint blockPeriod = gradualUpdate.endBlock - gradualUpdate.startBlock;
        uint blocksElapsed = currentBlock - gradualUpdate.startBlock;
        uint weightDelta;
        uint deltaPerBlock;
        uint newWeight;

        address[] memory tokens = corePool.getCurrentTokens();

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            // Make sure it does nothing if the new and old weights are the same (saves gas)
            // It's a degenerate case if they're *all* the same, but you certainly could have
            // a plan where you only change some of the weights in the set
            if (gradualUpdate.startWeights[i] != gradualUpdate.endWeights[i]) {
                if (gradualUpdate.endWeights[i] < gradualUpdate.startWeights[i]) {
                    // We are decreasing the weight

                    // First get the total weight delta
                    weightDelta = gradualUpdate.startWeights[i] - gradualUpdate.endWeights[i];
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = KassandraSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                    // newWeight = startWeight - (blocksElapsed * deltaPerBlock)
                    newWeight = gradualUpdate.startWeights[i] - KassandraSafeMath.bmul(blocksElapsed, deltaPerBlock);
                }
                else {
                    // We are increasing the weight

                    // First get the total weight delta
                    weightDelta = gradualUpdate.endWeights[i] - gradualUpdate.startWeights[i];
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = KassandraSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                    // newWeight = startWeight + (blocksElapsed * deltaPerBlock)
                    newWeight = gradualUpdate.startWeights[i] + KassandraSafeMath.bmul(blocksElapsed, deltaPerBlock);
                }

                uint bal = corePool.getBalance(tokens[i]);

                corePool.rebind(tokens[i], bal, newWeight);
            }
        }

        // Reset to allow add/remove tokens, or manual weight updates
        if (block.number >= gradualUpdate.endBlock) {
            gradualUpdate.startBlock = 0;
        }
    }

    /* solhint-enable function-max-lines */

    /**
     * @notice Schedule (commit) a token to be added; must call applyAddToken after a fixed
     *         number of blocks to actually add the token
     *
     * @param corePool - Core Pool the CRP is wrapping
     * @param token - Address of the token to be added
     * @param balance - How much to be added
     * @param denormalizedWeight - The desired token denormalized weight
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function commitAddToken(
        IPool corePool,
        address token,
        uint balance,
        uint denormalizedWeight,
        NewTokenParams storage newToken
    )
        external
    {
        verifyTokenComplianceInternal(token);

        require(!corePool.isBound(token), "ERR_IS_BOUND");
        require(denormalizedWeight <= KassandraConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
        require(denormalizedWeight >= KassandraConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");
        require(
            (corePool.getTotalDenormalizedWeight() + denormalizedWeight) <= KassandraConstants.MAX_TOTAL_WEIGHT,
            "ERR_MAX_TOTAL_WEIGHT"
        );
        require(balance >= KassandraConstants.MIN_BALANCE, "ERR_BALANCE_BELOW_MIN");

        newToken.addr = token;
        newToken.balance = balance;
        newToken.denorm = denormalizedWeight;
        newToken.commitBlock = block.number;
        newToken.isCommitted = true;
    }

    /**
     * @notice Add the token previously committed (in commitAddToken) to the pool
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param addTokenTimeLockInBlocks - Wait time between committing and applying a new token
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function applyAddToken(
        IConfigurableRightsPool self,
        IPool corePool,
        uint addTokenTimeLockInBlocks,
        NewTokenParams storage newToken
    )
        external
    {
        require(newToken.isCommitted, "ERR_NO_TOKEN_COMMIT");
        require((block.number - newToken.commitBlock) >= addTokenTimeLockInBlocks, "ERR_TIMELOCK_STILL_COUNTING");

        uint totalSupply = self.totalSupply();
        address controller = self.getController();

        // poolShares = totalSupply * newTokenWeight / totalWeight
        uint poolShares = KassandraSafeMath.bdiv(
            KassandraSafeMath.bmul(totalSupply, newToken.denorm),
            corePool.getTotalDenormalizedWeight()
        );

        // Clear this to allow adding more tokens
        newToken.isCommitted = false;

        // First gets the tokens from msg.sender to this contract (Pool Controller)
        bool returnValue = IERC20(newToken.addr).transferFrom(controller, address(self), newToken.balance);
        require(returnValue, "ERR_ERC20_FALSE");

        // Now with the tokens this contract can bind them to the pool it controls
        // Approves corePool to pull from this controller
        // Approve unlimited, same as when creating the pool, so they can join pools later
        returnValue = SafeApprove.safeApprove(IERC20(newToken.addr), address(corePool), KassandraConstants.MAX_UINT);
        require(returnValue, "ERR_ERC20_FALSE");

        corePool.bind(newToken.addr, newToken.balance, newToken.denorm);

        self.mintPoolShareFromLib(poolShares);
        self.pushPoolShareFromLib(controller, poolShares);
    }

    /**
     * @notice Remove a token from the pool
     *
     * @dev Logic in the CRP controls when this can be called. There are two related permissions:
     *      AddRemoveTokens - which allows removing down to the underlying Pool limit of two
     *      RemoveAllTokens - which allows completely draining the pool by removing all tokens
     *                        This can result in a non-viable pool with 0 or 1 tokens (by design),
     *                        meaning all swapping or binding operations would fail in this state
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param token - Address of the token to remove
     */
    function removeToken(
        IConfigurableRightsPool self,
        IPool corePool,
        address token
    )
        external
    {
        uint totalSupply = self.totalSupply();
        address controller = self.getController();

        // poolShares = totalSupply * tokenWeight / totalWeight
        uint poolShares = KassandraSafeMath.bdiv(
            KassandraSafeMath.bmul(
                totalSupply, corePool.getDenormalizedWeight(token)
            ),
            corePool.getTotalDenormalizedWeight()
        );

        // this is what will be unbound from the pool
        // Have to get it before unbinding
        uint balance = corePool.getBalance(token);

        // Unbind and get the tokens out of the pool
        corePool.unbind(token);

        // Now with the tokens this contract can send them to msg.sender
        bool xfer = IERC20(token).transfer(controller, balance);
        require(xfer, "ERR_ERC20_FALSE");

        self.pullPoolShareFromLib(controller, poolShares);
        self.burnPoolShareFromLib(poolShares);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     *
     * @dev Will revert if invalid
     *
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     *
     * @dev Will revert if invalid - overloaded to save space in the main contract
     *
     * @param tokens - Array of addresses of prospective tokens to verify
     * @param tokenWeights - Array of denormalized weights of prospective tokens
     * @param minimumKacy - Minimum amount of $KACY to be enforced
     * @param kacyToken - $KACY address to be enforced
     */
    function verifyTokenCompliance(
        address[] calldata tokens,
        uint[] calldata tokenWeights,
        uint minimumKacy,
        address kacyToken
    )
        external
    {
        uint totalWeight;
        uint kacyWeight;

        for (uint i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
            totalWeight += tokenWeights[i];

            if (tokens[i] == kacyToken) {
                kacyWeight = tokenWeights[i];
            }
        }

        require(minimumKacy <= KassandraSafeMath.bdiv(kacyWeight, totalWeight), "ERR_MIN_KACY");
    }

    /**
     * @notice Update weights in a predetermined way, between startBlock and endBlock,
     *         through external cals to pokeWeights
     *
     * @param corePool - Core Pool the CRP is wrapping
     * @param newWeights - Final weights we want to get to
     * @param startBlock - When weights should start to change
     * @param endBlock - When weights will be at their final values
     * @param minimumWeightChangeBlockPeriod - Needed to validate the block period
     * @param minimumKacy - Minimum amount of $KACY to be enforced
     * @param kacyToken - $KACY address to be enforced
    */
    function updateWeightsGradually(
        IPool corePool,
        GradualUpdateParams storage gradualUpdate,
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock,
        uint minimumWeightChangeBlockPeriod,
        uint minimumKacy,
        address kacyToken
    )
        external
    {
        require(block.number < endBlock, "ERR_GRADUAL_UPDATE_TIME_TRAVEL");

        if (block.number > startBlock) {
            // This means the weight update should start ASAP
            // Moving the start block up prevents a big jump/discontinuity in the weights
            gradualUpdate.startBlock = block.number;
        }
        else{
            gradualUpdate.startBlock = startBlock;
        }

        // Enforce a minimum time over which to make the changes
        // The also prevents endBlock <= startBlock
        require(
            (endBlock - gradualUpdate.startBlock) >= minimumWeightChangeBlockPeriod,
            "ERR_WEIGHT_CHANGE_TIME_BELOW_MIN"
        );

        address[] memory tokens = corePool.getCurrentTokens();

        // Must specify weights for all tokens
        require(newWeights.length == tokens.length, "ERR_START_WEIGHTS_MISMATCH");

        uint weightsSum = 0;
        uint kacyDenorm = 0;
        gradualUpdate.startWeights = new uint[](tokens.length);

        // Check that endWeights are valid now to avoid reverting in a future pokeWeights call
        //
        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            require(newWeights[i] <= KassandraConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
            require(newWeights[i] >= KassandraConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");

            if (tokens[i] == kacyToken) {
                kacyDenorm = newWeights[i];
            }

            weightsSum += newWeights[i];
            gradualUpdate.startWeights[i] = corePool.getDenormalizedWeight(tokens[i]);
        }
        require(weightsSum <= KassandraConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        require(minimumKacy <= KassandraSafeMath.bdiv(kacyDenorm, weightsSum), "ERR_MIN_KACY");

        gradualUpdate.endBlock = endBlock;
        gradualUpdate.endWeights = newWeights;
    }

    /**
     * @notice Join a pool
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param poolAmountOut - Number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     *
     * @return actualAmountsIn - Calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IPool corePool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    )
        external
        view
        returns (uint[] memory actualAmountsIn)
    {
        address[] memory tokens = corePool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint ratio = KassandraSafeMath.bdiv(poolAmountOut, poolTotal - 1);

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = corePool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint tokenAmountIn = KassandraSafeMath.bmul(ratio, bal + 1);

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param poolAmountIn - Amount of pool tokens to redeem
     * @param minAmountsOut - Minimum amount of asset tokens to receive
     *
     * @return exitFee - Calculated exit fee
     * @return pAiAfterExitFee - Final amount in (after accounting for exit fee)
     * @return actualAmountsOut - Calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IPool corePool,
        uint poolAmountIn,
        uint[] calldata minAmountsOut
    )
        external
        view
        returns (
            uint exitFee,
            uint pAiAfterExitFee,
            uint[] memory actualAmountsOut
        )
    {
        address[] memory tokens = corePool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();

        // Calculate exit fee and the final amount in
        if (msg.sender != corePool.getExitFeeCollector()) {
            exitFee = KassandraSafeMath.bmul(poolAmountIn, corePool.getExitFee());
        }

        pAiAfterExitFee = poolAmountIn - exitFee;
        uint ratio = KassandraSafeMath.bdiv(pAiAfterExitFee, poolTotal + 1);

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = corePool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint tokenAmountOut = KassandraSafeMath.bmul(ratio, bal - 1);

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param tokenIn - Which token we're transferring in
     * @param tokenAmountIn - Amount of deposit
     * @param minPoolAmountOut - Minimum of pool tokens to receive
     *
     * @return poolAmountOut - Amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(
        IConfigurableRightsPool self,
        IPool corePool,
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
        external
        view
        returns (uint poolAmountOut)
    {
        require(corePool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(
            tokenAmountIn <= KassandraSafeMath.bmul(corePool.getBalance(tokenIn), KassandraConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        poolAmountOut = corePool.calcPoolOutGivenSingleIn(
            corePool.getBalance(tokenIn),
            corePool.getDenormalizedWeight(tokenIn),
            self.totalSupply(),
            corePool.getTotalDenormalizedWeight(),
            tokenAmountIn,
            corePool.getSwapFee()
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param tokenIn - Which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - Amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     *
     * @return tokenAmountIn - amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(
        IConfigurableRightsPool self,
        IPool corePool,
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    )
        external
        view
        returns (uint tokenAmountIn)
    {
        require(corePool.isBound(tokenIn), "ERR_NOT_BOUND");

        tokenAmountIn = corePool.calcSingleInGivenPoolOut(
            corePool.getBalance(tokenIn),
            corePool.getDenormalizedWeight(tokenIn),
            self.totalSupply(),
            corePool.getTotalDenormalizedWeight(),
            poolAmountOut,
            corePool.getSwapFee()
        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(
            tokenAmountIn <= KassandraSafeMath.bmul(corePool.getBalance(tokenIn), KassandraConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool, and will incur an _exitFee (if set to non-zero)
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param tokenOut - Which token the caller wants to receive
     * @param poolAmountIn - Amount of pool tokens to redeem
     * @param minAmountOut - Minimum asset tokens to receive
     *
     * @return exitFee - Calculated exit fee
     * @return pAiAfterExitFee - Pool amount in after exit fee
     * @return tokenAmountOut - Amount of asset tokens returned
     */
    function exitswapPoolAmountIn(
        IConfigurableRightsPool self,
        IPool corePool,
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
        external
        view
        returns (
            uint exitFee,
            uint pAiAfterExitFee,
            uint tokenAmountOut
        )
    {
        require(corePool.isBound(tokenOut), "ERR_NOT_BOUND");

        if (msg.sender != corePool.getExitFeeCollector()) {
            exitFee = corePool.getExitFee();
        }

        tokenAmountOut = corePool.calcSingleOutGivenPoolIn(
            corePool.getBalance(tokenOut),
            corePool.getDenormalizedWeight(tokenOut),
            self.totalSupply(),
            corePool.getTotalDenormalizedWeight(),
            poolAmountIn,
            corePool.getSwapFee(),
            exitFee
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(
            tokenAmountOut <= KassandraSafeMath.bmul(corePool.getBalance(tokenOut), KassandraConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        exitFee = KassandraSafeMath.bmul(poolAmountIn, exitFee);
        pAiAfterExitFee = poolAmountIn - exitFee;
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool
     *
     * @param self - ConfigurableRightsPool instance calling the library
     * @param corePool - Core Pool the CRP is wrapping
     * @param tokenOut - Which token the caller wants to receive
     * @param tokenAmountOut - Amount of underlying asset tokens to receive
     * @param maxPoolAmountIn - Maximum pool tokens to be redeemed
     *
     * @return exitFee - Calculated exit fee
     * @return pAiAfterExitFee - Pool amount in after exit fee
     * @return poolAmountIn - Amount of pool tokens redeemed
     */
    function exitswapExternAmountOut(
        IConfigurableRightsPool self,
        IPool corePool,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        view
        returns (
            uint exitFee,
            uint pAiAfterExitFee,
            uint poolAmountIn
        )
    {
        require(corePool.isBound(tokenOut), "ERR_NOT_BOUND");
        require(
            tokenAmountOut <= KassandraSafeMath.bmul(corePool.getBalance(tokenOut), KassandraConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        if (msg.sender != corePool.getExitFeeCollector()) {
            exitFee = corePool.getExitFee();
        }

        poolAmountIn = corePool.calcPoolInGivenSingleOut(
            corePool.getBalance(tokenOut),
            corePool.getDenormalizedWeight(tokenOut),
            self.totalSupply(),
            corePool.getTotalDenormalizedWeight(),
            tokenAmountOut,
            corePool.getSwapFee(),
            exitFee
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        exitFee = KassandraSafeMath.bmul(poolAmountIn, exitFee);
        pAiAfterExitFee = poolAmountIn - exitFee;
    }

    /**
     * @dev Check for zero transfer, and make sure it returns true to returnValue
     *
     * @param token - Address of the possible token
     */
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }
}