/**
 *Submitted for verification at snowtrace.io on 2022-01-26
*/

// File: contracts/interfaces/IcrpFactory.sol


pragma solidity ^0.8.0;

/**
 * @title CRP Factory interface for checking pools
 */
interface IcrpFactory {
    function isCrp(address addr) external view returns (bool);
}

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

// File: contracts/libraries/RightsManager.sol


pragma solidity ^0.8.0;

/**
 * @author Kassandra (and Balancer Labs)
 *
 * @title Manage Configurable Rights for the smart pool
 *
 *      canPauseSwapping - can setPublicSwap back to false after turning it on
 *                         by default, it is off on initialization and can only be turned on
 *      canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      canWhitelistLPs - can limit liquidity providers to a given set of addresses
 *      canChangeCap - can change the KSP cap (max # of pool tokens)
 */
library RightsManager {
    // possible permissions
    enum Permissions {
        PAUSE_SWAPPING,
        CHANGE_SWAP_FEE,
        CHANGE_WEIGHTS,
        ADD_REMOVE_TOKENS,
        WHITELIST_LPS,
        CHANGE_CAP
    }

    // for holding all possible permissions in a compact way
    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
    }

    // Default state variables (can only be constants in a library)
    bool public constant DEFAULT_CAN_PAUSE_SWAPPING = false;
    bool public constant DEFAULT_CAN_CHANGE_SWAP_FEE = true;
    bool public constant DEFAULT_CAN_CHANGE_WEIGHTS = true;
    bool public constant DEFAULT_CAN_ADD_REMOVE_TOKENS = false;
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_CHANGE_CAP = false;

    /**
     * @notice create a struct from an array (or return defaults)
     *
     * @dev If you pass an empty array, it will construct it using the defaults
     *
     * @param a - Boolean array input
     *
     * @return Rights struct
     */
    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length == 0) {
            return Rights(
                DEFAULT_CAN_PAUSE_SWAPPING,
                DEFAULT_CAN_CHANGE_SWAP_FEE,
                DEFAULT_CAN_CHANGE_WEIGHTS,
                DEFAULT_CAN_ADD_REMOVE_TOKENS,
                DEFAULT_CAN_WHITELIST_LPS,
                DEFAULT_CAN_CHANGE_CAP
            );
        }
        return Rights(a[0], a[1], a[2], a[3], a[4], a[5]);
    }

    /**
     * @notice Convert rights struct to an array (e.g., for events, GUI)
     *
     * @dev Avoids multiple calls to hasPermission
     *
     * @param rights - The Rights struct to convert
     *
     * @return Boolean array containing the Rights settings
     */
    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](6);

        result[0] = rights.canPauseSwapping;
        result[1] = rights.canChangeSwapFee;
        result[2] = rights.canChangeWeights;
        result[3] = rights.canAddRemoveTokens;
        result[4] = rights.canWhitelistLPs;
        result[5] = rights.canChangeCap;

        return result;
    }

    /**
     * @notice Externally check permissions using the Enum
     *
     * @param self - Rights struct containing the permissions
     *
     * @param permission - The permission to check
     *
     * @return Boolean true if it has the permission
     */
    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        // assembly allows us to heavily optmise this by reading padding the location instead of using expensive ifs
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, add(self, mul(permission, 32)), 32)
            return(0, 32)
        }
    }
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

// File: contracts/utils/ReentrancyGuard.sol


pragma solidity ^0.8.0;

/**
 * @author Kassandra (and Balancer Labs and OpenZeppelin)
 *
 * @title Protect against reentrant calls (and also selectively protect view functions)
 *
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {_lock_} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `_lock_` guard, functions marked as
 * `_lock_` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `_lock_` entry
 * points to them.
 *
 * Also adds a _lockview_ modifier, which doesn't create a lock, but fails
 *   if another _lock_ call is in progress
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
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    // current status of entrancy
    uint private _status;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `_lock_` function from another `_lock_`
     * function is not supported. It is possible to prevent this from happening
     * by making the `_lock_` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier lock() {
        // On the first call to _lock_, _notEntered will be true
        require(_status != _ENTERED, "ERR_REENTRY");

        // Any calls to _lock_ after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Also add a modifier that doesn't create a lock, but protects functions that
     *      should not be called while a _lock_ function is running
     */
    modifier viewlock() {
        require(_status != _ENTERED, "ERR_REENTRY_VIEW");
        _;
    }

    /**
     * @dev Initializes the contract with not entered state
     */
    constructor () {
        _status = _NOT_ENTERED;
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

// File: contracts/interfaces/IFactory.sol


pragma solidity ^0.8.0;



/**
 * @title Core factory definition interface
 */
interface IFactoryDef {
    function kacyToken() external view returns (address);
    function minimumKacy() external view returns (uint);
}

/**
 * @title Core factory interface with `newPool` as `IPool`
 *
 * @dev If `newPool` must be called and an interface must be returned this interface does that
 */
interface IFactory is IFactoryDef, IOwnable {
    function newPool() external returns (IPool pool);
}

// File: contracts/utils/Ownable.sol


pragma solidity ^0.8.0;


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
abstract contract Ownable is IOwnable {
    // owner of the contract
    address private _owner;

    /**
     * @notice Emitted when the owner is changed
     *
     * @param previousOwner - The previous owner of the contract
     * @param newOwner - The new owner of the contract
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     *
     * @dev external for gas optimization
     *
     * @param newOwner - Address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    /**
     * @notice Returns the address of the current owner
     *
     * @dev external for gas optimization
     *
     * @return address - of the owner (AKA controller)
     */
    function getController() external view override returns (address) {
        return _owner;
    }
}

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

// File: contracts/Token.sol


pragma solidity ^0.8.0;


/**
 * @author Kassandra (and Balancer Labs)
 * @title Highly opinionated token implementation
*/
abstract contract TokenBase is IERC20 {
    // State variables
    uint8 private constant _DECIMALS = 18;

    uint internal _totalSupply;
    string private _symbol;
    string private _name;

    mapping(address => uint) private _balance;
    mapping(address => mapping(address => uint)) private _allowance;

    // Function declarations

    /**
     * @notice Base token constructor
     * @param tokenSymbol - the token symbol
     * @param tokenName - the token name
     */
    constructor (string memory tokenSymbol, string memory tokenName) {
        _symbol = tokenSymbol;
        _name = tokenName;
    }

    /* solhint-disable ordering */
    // External functions

    /**
     * @notice Getter for allowance: amount spender will be allowed to spend on behalf of owner
     * @param owner - owner of the tokens
     * @param spender - entity allowed to spend the tokens
     * @return uint - remaining amount spender is allowed to transfer
     */
    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowance[owner][spender];
    }

    /**
     * @notice Getter for current account balance
     * @param account - address we're checking the balance of
     * @return uint - token balance in the account
     */
    function balanceOf(address account) external view override returns (uint) {
        return _balance[account];
    }

    /**
     * @notice Approve owner (sender) to spend a certain amount
     * @dev emits an Approval event
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function approve(address spender, uint amount) external override returns (bool) {
        /* In addition to the increase/decreaseApproval functions, could
           avoid the "approval race condition" by only allowing calls to approve
           when the current approval amount is 0

           require(_allowance[msg.sender][spender] == 0, "ERR_RACE_CONDITION");

           Some token contracts (e.g., KNC), already revert if you call approve
           on a non-zero allocation. To deal with these, we use the SafeApprove library
           and safeApprove function when adding tokens to the pool.
        */

        _allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
     * @notice Increase the amount the spender is allowed to spend on behalf of the owner (sender)
     * @dev emits an Approval event
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function increaseApproval(address spender, uint amount) external returns (bool) {
        _allowance[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @notice Decrease the amount the spender is allowed to spend on behalf of the owner (sender)
     * @dev emits an Approval event
     * @dev If you try to decrease it below the current limit, it's just set to zero (not an error)
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function decreaseApproval(address spender, uint amount) external returns (bool) {
        uint oldValue = _allowance[msg.sender][spender];
        // Gas optimization - if amount == oldValue (or is larger), set to zero immediately
        if (amount >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue - amount;
        }

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @notice Transfer the given amount from sender (caller) to recipient
     * @dev _move emits a Transfer event if successful
     * @param recipient - entity receiving the tokens
     * @param amount - number of tokens being transferred
     * @return bool - result of the transfer (will always be true if it doesn't revert)
     */
    function transfer(address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");

        _move(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @notice Transfer the given amount from sender to recipient
     * @dev _move emits a Transfer event if successful; may also emit an Approval event
     * @param sender - entity sending the tokens (must be caller or allowed to spend on behalf of caller)
     * @param recipient - recipient of the tokens
     * @param amount - number of tokens being transferred
     * @return bool - result of the transfer (will always be true if it doesn't revert)
     */
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");
        // memoize for gas optimization
        uint oldAllowance = _allowance[sender][msg.sender];
        require(msg.sender == sender || amount <= oldAllowance, "ERR_TOKEN_BAD_CALLER");

        _move(sender, recipient, amount);

        // If the sender is not the caller, adjust the allowance by the amount transferred
        if (msg.sender != sender && oldAllowance != type(uint).max) {
            _allowance[sender][msg.sender] = oldAllowance - amount;

            emit Approval(msg.sender, recipient, _allowance[sender][msg.sender]);
        }

        return true;
    }

    // public functions

    /**
     * @notice Getter for the total supply
     * @dev declared external for gas optimization
     * @return uint - total number of tokens in existence
     */
    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    // Public functions

    /**
     * @dev Returns the name of the token.
     *      We allow the user to set this name (as well as the symbol).
     *      Alternatives are 1) A fixed string (original design)
     *                       2) A fixed string plus the user-defined symbol
     *                          return string(abi.encodePacked(NAME, "-", _symbol));
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external pure returns (uint8) {
        return _DECIMALS;
    }

    // internal functions

    // Mint an amount of new tokens, and add them to the balance (and total supply)
    // Emit a transfer amount from the null address to this contract
    function _mint(uint amount) internal virtual {
        _balance[address(this)] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), address(this), amount);
    }

    // Burn an amount of new tokens, and subtract them from the balance (and total supply)
    // Emit a transfer amount from this contract to the null address
    function _burn(uint amount) internal virtual {
        // Can't burn more than we have
        // Remove require for gas optimization - will revert on underflow
        // require(_balance[address(this)] >= amount, "ERR_INSUFFICIENT_BAL");

        _balance[address(this)] -= amount;
        _totalSupply -= amount;

        emit Transfer(address(this), address(0), amount);
    }

    // Transfer tokens from sender to recipient
    // Adjust balances, and emit a Transfer event
    function _move(address sender, address recipient, uint amount) internal virtual {
        // Can't send more than sender has
        // Remove require for gas optimization - will revert on underflow
        // require(_balance[sender] >= amount, "ERR_INSUFFICIENT_BAL");

        _balance[sender] -= amount;
        _balance[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    // Transfer from this contract to recipient
    // Emits a transfer event if successful
    function _push(address recipient, uint amount) internal {
        _move(address(this), recipient, amount);
    }

    // Transfer from recipient to this contract
    // Emits a transfer event if successful
    function _pull(address sender, uint amount) internal {
        _move(sender, address(this), amount);
    }
}

/**
 * @title Smart Pool Token
*/
abstract contract SPToken is TokenBase {
    string public constant NAME = "Kassandra Smart Pool";

    constructor (string memory tokenSymbol, string memory tokenName)
        TokenBase(tokenSymbol, tokenName) {}
}

/**
 * @title Core Pool Token
*/
abstract contract CPToken is TokenBase {
    string public constant NAME = "Kassandra Core Pool";

    constructor (string memory tokenSymbol, string memory tokenName)
        TokenBase(tokenSymbol, tokenName) {}
}

// File: contracts/ConfigurableRightsPool.sol


pragma solidity ^0.8.0;












/**
 * @author Kassandra (and Balancer Labs)
 *
 * @title Smart Pool with customizable features
 *
 * @notice SPToken is the "Kassandra Smart Pool" token (transferred upon finalization)
 *
 * @dev Rights are defined as follows (index values into the array)
 *      0: canPauseSwapping - can setPublicSwap back to false after turning it on
 *                            by default, it is off on initialization and can only be turned on
 *      1: canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      2: canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      3: canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      4: canWhitelistLPs - can restrict LPs to a whitelist
 *      5: canChangeCap - can change the KSP cap (max # of pool tokens)
 *
 * Note that functions called on corePool and coreFactory may look like internal calls,
 *   but since they are contracts accessed through an interface, they are really external.
 * To make this explicit, we could write "IPool(address(corePool)).function()" everywhere,
 *   instead of "corePool.function()".
 */
contract ConfigurableRightsPool is IConfigurableRightsPoolDef, SPToken, Ownable, ReentrancyGuard {
    using SafeApprove for IERC20;

    // struct used on pool creation
    struct PoolParams {
        // Kassandra Pool Token (representing shares of the pool)
        string poolTokenSymbol; // symbol of the pool token
        string poolTokenName;   // name of the pool token
        // Tokens inside the Pool
        address[] constituentTokens; // addresses
        uint[] tokenBalances;        // balances
        uint[] tokenWeights;         // denormalized weights
        uint swapFee; // pool swap fee
    }

    /// Address of the contract that handles the strategy
    address public strategyUpdater;

    /// Address of the core factory contract; for creating the core pool and enforcing $KACY
    IFactory public coreFactory;
    /// Address of the core pool for this CRP; holds the tokens
    IPool public override corePool;

    /// Struct holding the rights configuration
    RightsManager.Rights public rights;

    /**
     * @notice This is for adding a new (currently unbound) token to the pool
     *         It's a two-step process: commitAddToken(), then applyAddToken()
     */
    SmartPoolManager.NewTokenParams public newToken;

    /// Hold the parameters used in updateWeightsGradually
    SmartPoolManager.GradualUpdateParams public gradualUpdate;

    // Fee is initialized on creation, and can be changed if permission is set
    // Only needed for temporary storage between construction and createPool
    // Thereafter, the swap fee should always be read from the underlying pool
    uint private _initialSwapFee;

    // Store the list of tokens in the pool, and balances
    // NOTE that the token list is *only* used to store the pool tokens between
    //   construction and createPool - thereafter, use the underlying core Pool's list
    //   (avoids synchronization issues)
    address[] private _initialTokens;
    uint[] private _initialBalances;

    /// Enforce a minimum time between the start and end blocks on updateWeightsGradually
    uint public minimumWeightChangeBlockPeriod;
    /// Enforce a wait time between committing and applying a new token
    uint public addTokenTimeLockInBlocks;

    // Default values for the above variables, set in the constructor
    // Pools without permission to update weights or add tokens cannot use them anyway,
    //   and should call the default createPool() function.
    // To override these defaults, pass them into the overloaded createPool()
    // Period is in blocks; 500 blocks ~ 2 hours; 5,700 blocks ~< 1 day
    uint private constant _DEFAULT_MIN_WEIGHT_CHANGE_BLOCK_PERIOD = 5700;
    uint private constant _DEFAULT_ADD_TOKEN_TIME_LOCK_IN_BLOCKS = 500;

    /**
     * @notice Cap on the pool size (i.e., # of tokens minted when joining)
     *         Limits the risk of experimental pools; failsafe/backup for fixed-size pools
     */
    uint public tokenCap;

    // Whitelist of LPs (if configured)
    mapping(address => bool) private _liquidityProviderWhitelist;

    /**
     * @notice Emitted when the maximum cap (`tokenCap`) has changed
     *
     * @param caller - Address of who changed the cap
     * @param oldCap - Previous maximum cap
     * @param newCap - New maximum cap
     */
    event CapChanged(
        address indexed caller,
        uint            oldCap,
        uint            newCap
    );

    /**
     * @notice Emitted when a new token has been committed to be added to the pool
     *         The token has not been added yet, but eventually will be once pass `addTokenTimeLockInBlocks`
     *
     * @param caller - Address of who committed this new token
     * @param pool - Address of the CRP pool that will have the new token
     * @param token - Address of the token being added
     */ 
    event NewTokenCommitted(
        address indexed caller,
        address indexed pool,
        address indexed token
    );

    /**
     * @notice Emitted when the strategy contract has been changed
     *
     * @param caller - Address of who changed the strategy contract
     * @param pool - Address of the CRP pool that changed the strategy contract
     * @param newAddr - Address of the new strategy contract
     */
    event NewStrategy(
        address indexed caller,
        address indexed pool,
        address indexed newAddr
    );

    /**
     * @notice Emitted on virtually every externally callable function
     *
     * @dev Anonymous logger event - can only be filtered by contract address
     *
     * @param sig - Function identifier
     * @param caller - Caller of the function
     * @param data - The full data of the call
     */
    event LogCall(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    /**
     * @notice Emitted when someone joins the pool
     *         Also known as "Minted the pool token"
     *
     * @param caller - Adddress of who joined the pool
     * @param tokenIn - Address of the token that was sent to the pool
     * @param tokenAmountIn - Amount of the token added to the pool
     */
    event LogJoin(
        address indexed caller,
        address indexed tokenIn,
        uint            tokenAmountIn
    );

    /**
     * @notice Emitted when someone exits the pool
     *         Also known as "Burned the pool token"
     *
     * @param caller - Adddress of who exited the pool
     * @param tokenOut - Address of the token that was sent to the caller
     * @param tokenAmountOut - Amount of the token sent to the caller
     */
    event LogExit(
        address indexed caller,
        address indexed tokenOut,
        uint            tokenAmountOut
    );

    /**
     * @dev Logs a call to a function, only needed for external and public function
     */
    modifier logs() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    /**
     * @dev Mark functions that require delegation to the underlying Pool
     */
    modifier needsCorePool() {
        require(address(corePool) != address(0), "ERR_NOT_CREATED");
        _;
    }

    /**
     * @dev Turn off swapping on the underlying pool during joins
     *      Otherwise tokens with callbacks would enable attacks involving simultaneous swaps and joins
     */
    modifier lockUnderlyingPool() {
        bool origSwapState = corePool.isPublicSwap();
        corePool.setPublicSwap(false);
        _;
        corePool.setPublicSwap(origSwapState);
    }

    /**
     * @dev Mark functions that only the strategy contract can control
     */
    modifier onlyStrategy() {
        require(msg.sender == strategyUpdater, "ERR_NOT_STRATEGY");
        _;
    }

    /**
     * @notice Construct a new Configurable Rights Pool (wrapper around core Pool)
     *
     * @dev _initialTokens and _swapFee are only used for temporary storage between construction
     *      and create pool, and should not be used thereafter! _initialTokens is destroyed in
     *      createPool to prevent this, and _swapFee is kept in sync (defensively), but
     *      should never be used except in this constructor and createPool()
     *
     * @param factoryAddress - Core Pool Factory used to create the underlying pool
     * @param poolParams - Struct containing pool parameters
     * @param rightsStruct - Set of permissions we are assigning to this smart pool
     */
    constructor(
        address factoryAddress,
        PoolParams memory poolParams,
        RightsManager.Rights memory rightsStruct
    )
        SPToken(poolParams.poolTokenSymbol, poolParams.poolTokenName)
    {
        // We don't have a pool yet; check now or it will fail later (in order of likelihood to fail)
        // (and be unrecoverable if they don't have permission set to change it)
        // Most likely to fail, so check first
        require(
            poolParams.swapFee >= KassandraConstants.MIN_FEE && poolParams.swapFee <= KassandraConstants.MAX_FEE,
            "ERR_INVALID_SWAP_FEE"
        );

        // Arrays must be parallel
        require(poolParams.tokenBalances.length == poolParams.constituentTokens.length, "ERR_START_BALANCES_MISMATCH");
        require(poolParams.tokenWeights.length == poolParams.constituentTokens.length, "ERR_START_WEIGHTS_MISMATCH");
        // Cannot have too many or too few - technically redundant, since Pool.bind() would fail later
        // But if we don't check now, we could have a useless contract with no way to create a pool

        require(poolParams.constituentTokens.length >= KassandraConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");
        require(poolParams.constituentTokens.length <= KassandraConstants.MAX_ASSET_LIMIT, "ERR_TOO_MANY_TOKENS");
        // There are further possible checks (e.g., if they use the same token twice), but
        // we can let bind() catch things like that (i.e., not things that might reasonably work)

        coreFactory = IFactory(factoryAddress);

        SmartPoolManager.verifyTokenCompliance(
            poolParams.constituentTokens,
            poolParams.tokenWeights,
            coreFactory.minimumKacy(),
            coreFactory.kacyToken()
        );

        rights = rightsStruct;
        _initialTokens = poolParams.constituentTokens;
        _initialBalances = poolParams.tokenBalances;
        _initialSwapFee = poolParams.swapFee;

        // These default block time parameters can be overridden in createPool
        minimumWeightChangeBlockPeriod = _DEFAULT_MIN_WEIGHT_CHANGE_BLOCK_PERIOD;
        addTokenTimeLockInBlocks = _DEFAULT_ADD_TOKEN_TIME_LOCK_IN_BLOCKS;

        gradualUpdate.startWeights = poolParams.tokenWeights;
        // Initializing (unnecessarily) for documentation - 0 means no gradual weight change has been initiated
        // gradualUpdate.startBlock = 0;
        // By default, there is no cap (unlimited pool token minting)
        tokenCap = KassandraConstants.MAX_UINT;
    }

    /**
     * @notice Set the swap fee on the underlying pool
     *
     * @dev Keep the local version and core in sync (see below)
     *      corePool is a contract interface; function calls on it are external
     *
     * @param swapFee - in Wei, where 1 ether is 100%
     */
    function setSwapFee(uint swapFee)
        external
        needsCorePool
        onlyOwner
        lock
        logs
        virtual
    {
        require(rights.canChangeSwapFee, "ERR_NOT_CONFIGURABLE_SWAP_FEE");

        // Underlying pool will check against min/max fee
        corePool.setSwapFee(swapFee);
    }

    /**
     * @notice Set the exit fee on the underlying pool
     *
     * @dev Keep the local version and core in sync (see below)
     *      corePool is a contract interface; function calls on it are external
     *
     * @param exitFee - in Wei, where 1 ether is 100%
     */
    function setExitFee(uint exitFee)
        external
        needsCorePool
        onlyOwner
        lock
        logs
        virtual
    {
        require(rights.canChangeSwapFee, "ERR_NOT_CONFIGURABLE_SWAP_FEE");

        // Underlying pool will check against min/max fee
        corePool.setExitFee(exitFee);
    }

    /**
     * @notice Set the cap (max # of pool tokens)
     *
     * @dev tokenCap defaults in the constructor to unlimited
     *      Can set to 0 (or anywhere below the current supply), to halt new investment
     *      Prevent setting it before creating a pool, since createPool sets to intialSupply
     *      (it does this to avoid an unlimited cap window between construction and createPool)
     *      Therefore setting it before then has no effect, so should not be allowed
     *
     * @param newCap - New value of the cap
     */
    function setCap(uint newCap)
        external
        needsCorePool
        onlyOwner
        lock
        logs
    {
        require(rights.canChangeCap, "ERR_CANNOT_CHANGE_CAP");

        emit CapChanged(msg.sender, tokenCap, newCap);

        tokenCap = newCap;
    }

    /**
     * @notice Set the public swap flag on the underlying pool to allow or prevent swapping in the pool
     *
     * @dev If this smart pool has canPauseSwapping enabled, we can turn publicSwap off if it's already on
     *      Note that if they turn swapping off - but then finalize the pool - finalizing will turn the
     *      swapping back on. They're not supposed to finalize the underlying pool... would defeat the
     *      smart pool functions. (Only the owner can finalize the pool - which is this contract -
     *      so there is no risk from outside.)
     *
     *      corePool is a contract interface; function calls on it are external
     *
     * @param publicSwap - New value of the swap status
     */
    function setPublicSwap(bool publicSwap)
        external
        needsCorePool
        onlyOwner
        lock
        logs
        virtual
    {
        require(rights.canPauseSwapping, "ERR_NOT_PAUSABLE_SWAP");

        corePool.setPublicSwap(publicSwap);
    }

    /**
     * @notice Set an address that will receive the exit fees in the underlying pool
     *
     * @param feeCollector - Address that will receive exit fees
     */
    function setExitFeeCollector(address feeCollector)
        external
        onlyOwner
        logs
    {
        corePool.setExitFeeCollector(feeCollector);
    }

    /**
     * @notice Set a contract/address that will be allowed to update weights and add/remove tokens
     *
     * @dev If this smart pool has canUpdateWeigths enabled, another smart contract with defined
     *      rules and formulas could update them
     *
     * @param updaterAddr - Contract address that will be able to update weights
     */
    function setStrategy(address updaterAddr)
        external
        onlyOwner
        logs
    {
        require(updaterAddr != address(0), "ERR_ZERO_ADDRESS");
        emit NewStrategy(msg.sender, address(this), updaterAddr);
        strategyUpdater = updaterAddr;
    }

    /**
     * @notice Create a new Smart Pool - and set the block period time parameters
     *
     * @dev Initialize the swap fee to the value provided in the CRP constructor
     *      Can be changed if the canChangeSwapFee permission is enabled
     *      Time parameters will be fixed at these values
     *      Delegates to internal function
     *
     *      If this contract doesn't have canChangeWeights permission - or you want to use the default
     *      values, the block time arguments are not needed, and you can just call the single-argument
     *      createPool()
     *
     * @param initialSupply - Starting token balance
     * @param minimumWeightChangeBlockPeriodParam - Enforce a minimum time between the start and end blocks
     * @param addTokenTimeLockInBlocksParam - Enforce a mandatory wait time between committing and applying a new token
     */
    function createPool(
        uint initialSupply,
        uint minimumWeightChangeBlockPeriodParam,
        uint addTokenTimeLockInBlocksParam
    )
        external
        onlyOwner
        lock
        logs
        virtual
    {
        require(
            minimumWeightChangeBlockPeriodParam >= addTokenTimeLockInBlocksParam,
            "ERR_INCONSISTENT_TOKEN_TIME_LOCK"
        );

        minimumWeightChangeBlockPeriod = minimumWeightChangeBlockPeriodParam;
        addTokenTimeLockInBlocks = addTokenTimeLockInBlocksParam;

        createPoolInternal(initialSupply);
    }

    /**
     * @notice Create a new Smart Pool
     *
     * @dev Initialize the swap fee to the value provided in the CRP constructor
     *      Can be changed if the canChangeSwapFee permission is enabled
     *      Delegates to internal function
     *
     * @param initialSupply - Starting token balance
     */
    function createPool(uint initialSupply)
        external
        onlyOwner
        lock
        logs
        virtual
    {
        createPoolInternal(initialSupply);
    }

    /**
     * @notice Update the weight of an existing token
     *
     * @dev Notice Balance is not an input (like with rebind on core Pool) since we will require prices not to change
     *      This is achieved by forcing balances to change proportionally to weights, so that prices don't change
     *      If prices could be changed, this would allow the controller to drain the pool by arbing price changes
     *
     * @param token - Address of the token to be reweighted
     * @param newWeight - New weight of the token
     */
    function updateWeight(address token, uint newWeight)
        external
        override
        needsCorePool
        onlyStrategy
        lock
        logs
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");

        // We don't want people to set weights manually if there's a block-based update in progress
        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");

        // Delegate to library to save space
        SmartPoolManager.updateWeight(
            IConfigurableRightsPool(address(this)),
            corePool,
            token,
            newWeight,
            coreFactory.minimumKacy(),
            coreFactory.kacyToken()
        );
    }

    /**
     * @notice Update weights in a predetermined way, between startBlock and endBlock,
     *         through external calls to pokeWeights
     *
     * @dev Must call pokeWeights at least once past the end for it to do the final update
     *      and enable calling this again.
     *      It is possible to call updateWeightsGradually during an update in some use cases
     *      For instance, setting newWeights to currentWeights to stop the update where it is
     *
     * @param newWeights - Final weights we want to get to. Note that the ORDER (and number) of
     *                     tokens can change if you have added or removed tokens from the pool
     *                     It ensures the counts are correct, but can't help you with the order!
     *                     You can get the underlying core Pool (it's public), and call
     *                     getCurrentTokens() to see the current ordering, if you're not sure
     * @param startBlock - When weights should start to change
     * @param endBlock - When weights will be at their final values
     */
    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    )
        external
        override
        needsCorePool
        onlyStrategy
        lock
        logs
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");
        // Don't start this when we're in the middle of adding a new token
        require(!newToken.isCommitted, "ERR_PENDING_TOKEN_ADD");

        // Library computes the startBlock, computes startWeights as the current
        // denormalized weights of the core pool tokens.
        SmartPoolManager.updateWeightsGradually(
            corePool,
            gradualUpdate,
            newWeights,
            startBlock,
            endBlock,
            minimumWeightChangeBlockPeriod,
            coreFactory.minimumKacy(),
            coreFactory.kacyToken()
        );
    }

    /**
     * @notice External function called to make the contract update weights according to plan
     *
     * @dev Still works if we poke after the end of the period; also works if the weights don't change
     *      Resets if we are poking beyond the end, so that we can do it again
     */
    function pokeWeights()
        external
        override
        needsCorePool
        lock
        logs
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");

        // Delegate to library to save space
        SmartPoolManager.pokeWeights(corePool, gradualUpdate);
    }

    /**
     * @notice Schedule (commit) a token to be added; must call applyAddToken after a fixed
     *         number of blocks to actually add the token
     *
     * @dev The purpose of this two-stage commit is to give warning of a potentially dangerous
     *      operation. A malicious pool operator could add a large amount of a low-value token,
     *      then drain the pool through price manipulation. Of course, there are many
     *      legitimate purposes, such as adding additional collateral tokens.
     *
     * @param token - Address of the token to be added
     * @param balance - How much to be added
     * @param denormalizedWeight - Desired token weight
     */
    function commitAddToken(
        address token,
        uint balance,
        uint denormalizedWeight
    )
        external
        override
        needsCorePool
        onlyStrategy
        lock
        logs
        virtual
    {
        require(rights.canAddRemoveTokens, "ERR_CANNOT_ADD_REMOVE_TOKENS");

        // Can't do this while a progressive update is happening
        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");

        emit NewTokenCommitted(msg.sender, address(this), token);

        // Delegate to library to save space
        SmartPoolManager.commitAddToken(
            corePool,
            token,
            balance,
            denormalizedWeight,
            newToken
        );
    }

    /**
     * @notice Add the token previously committed (in commitAddToken) to the pool
     *
     * @dev Caller must have the token available to include it in the pool
     */
    function applyAddToken()
        external
        override
        needsCorePool
        onlyStrategy
        lock
        logs
        virtual
    {
        require(rights.canAddRemoveTokens, "ERR_CANNOT_ADD_REMOVE_TOKENS");

        // Delegate to library to save space
        SmartPoolManager.applyAddToken(
            IConfigurableRightsPool(address(this)),
            corePool,
            addTokenTimeLockInBlocks,
            newToken
        );
    }

    /**
     * @notice Remove a token from the pool
     *
     * @dev corePool is a contract interface; function calls on it are external
     *
     * @param token - Address of the token to remove
     */
    function removeToken(address token)
        external
        override
        needsCorePool
        onlyStrategy
        lock
        logs
    {
        // It's possible to have remove rights without having add rights
        require(rights.canAddRemoveTokens,"ERR_CANNOT_ADD_REMOVE_TOKENS");
        // After createPool, token list is maintained in the underlying core Pool
        require(!newToken.isCommitted, "ERR_REMOVE_WITH_ADD_PENDING");
        // Prevent removing during an update (or token lists can get out of sync)
        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");
        // can't remove $KACY (core pool also checks but we can fail earlier)
        require(token != coreFactory.kacyToken(), "ERR_MIN_KACY");

        // Delegate to library to save space
        SmartPoolManager.removeToken(IConfigurableRightsPool(address(this)), corePool, token);
    }

    /**
     * @notice Join a pool - mint pool tokens with underlying assets
     *
     * @dev Emits a LogJoin event for each token
     *      corePool is a contract interface; function calls on it are external
     *
     * @param poolAmountOut - Number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend; will follow the pool order
     */
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external
        needsCorePool
        lock
        lockUnderlyingPool
        logs
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender], "ERR_NOT_ON_WHITELIST");

        // Delegate to library to save space

        // Library computes actualAmountsIn, and does many validations
        // Cannot call the push/pull/min from an external library for
        // any of these pool functions. Since msg.sender can be anybody,
        // they must be internal
        uint[] memory actualAmountsIn = SmartPoolManager.joinPool(
            IConfigurableRightsPool(address(this)),
            corePool,
            poolAmountOut,
            maxAmountsIn
        );

        // After createPool, token list is maintained in the underlying core Pool
        address[] memory poolTokens = corePool.getCurrentTokens();

        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenAmountIn = actualAmountsIn[i];

            emit LogJoin(msg.sender, t, tokenAmountIn);

            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    /**
     * @notice Exit a pool - redeem/burn pool tokens for underlying assets
     *
     * @dev Emits a LogExit event for each token
     *      corePool is a contract interface; function calls on it are external
     *
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     */
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external
        needsCorePool
        lock
        lockUnderlyingPool
        logs
    {
        // Delegate to library to save space

        // Library computes actualAmountsOut, and does many validations
        // Also computes the exitFee and pAiAfterExitFee
        (
            uint exitFee,
            uint pAiAfterExitFee,
            uint[] memory actualAmountsOut
        ) = SmartPoolManager.exitPool(
            IConfigurableRightsPool(address(this)),
            corePool,
            poolAmountIn,
            minAmountsOut
        );

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(corePool.getExitFeeCollector(), exitFee);
        _burnPoolShare(pAiAfterExitFee);

        // After createPool, token list is maintained in the underlying core Pool
        address[] memory poolTokens = corePool.getCurrentTokens();

        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenAmountOut = actualAmountsOut[i];

            emit LogExit(msg.sender, t, tokenAmountOut);

            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     *
     * @dev emits a LogJoin event
     *
     * @param tokenIn - Which token we're transferring in
     * @param tokenAmountIn - Amount of the deposit
     * @param minPoolAmountOut - Minimum of pool tokens to receive
     *
     * @return poolAmountOut - Amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
        external
        logs
        needsCorePool
        lock
        returns (uint poolAmountOut)
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender], "ERR_NOT_ON_WHITELIST");

        // Delegate to library to save space
        poolAmountOut = SmartPoolManager.joinswapExternAmountIn(
            IConfigurableRightsPool(address(this)),
            corePool,
            tokenIn,
            tokenAmountIn,
            minPoolAmountOut
        );

        emit LogJoin(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     *
     * @dev emits a LogJoin event
     *
     * @param tokenIn - Which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - Amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     *
     * @return tokenAmountIn - Amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    )
        external
        logs
        needsCorePool
        lock
        returns (uint tokenAmountIn)
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender], "ERR_NOT_ON_WHITELIST");

        // Delegate to library to save space
        tokenAmountIn = SmartPoolManager.joinswapPoolAmountOut(
            IConfigurableRightsPool(address(this)),
            corePool,
            tokenIn,
            poolAmountOut,
            maxAmountIn
        );

        emit LogJoin(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool, and will incur an _exitFee (if set to non-zero)
     *
     * @dev Emits a LogExit event for the token
     *
     * @param tokenOut - Which token the caller wants to receive
     * @param poolAmountIn - Amount of pool tokens to redeem
     * @param minAmountOut - Minimum asset tokens to receive
     *
     * @return tokenAmountOut - Amount of asset tokens returned
     */
    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
        external
        logs
        needsCorePool
        lock
        returns (uint tokenAmountOut)
    {
        // Delegate to library to save space
        uint exitFee;
        uint pAiAfterExitFee;

        // Calculates final amountOut, and the fee and final amount in
        (
            exitFee,
            pAiAfterExitFee,
            tokenAmountOut
        ) = SmartPoolManager.exitswapPoolAmountIn(
            IConfigurableRightsPool(address(this)),
            corePool,
            tokenOut,
            poolAmountIn,
            minAmountOut
        );

        emit LogExit(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(pAiAfterExitFee);
        _pushPoolShare(corePool.getExitFeeCollector(), exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool
     *
     * @dev Emits a LogExit event for the token
     *
     * @param tokenOut - Which token the caller wants to receive
     * @param tokenAmountOut - Amount of underlying asset tokens to receive
     * @param maxPoolAmountIn - Maximum pool tokens to be redeemed
     *
     * @return poolAmountIn - Amount of pool tokens redeemed
     */
    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        logs
        needsCorePool
        lock
        returns (uint poolAmountIn)
    {
        // Delegate to library to save space
        uint exitFee;
        uint pAiAfterExitFee;

        // Calculates final amounts in, accounting for the exit fee
        (
            exitFee,
            pAiAfterExitFee,
            poolAmountIn
        ) = SmartPoolManager.exitswapExternAmountOut(
            IConfigurableRightsPool(address(this)),
            corePool,
            tokenOut,
            tokenAmountOut,
            maxPoolAmountIn
        );

        emit LogExit(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(pAiAfterExitFee);
        _pushPoolShare(corePool.getExitFeeCollector(), exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    }

    /**
     * @notice Add to the whitelist of liquidity providers (if enabled)
     *
     * @param provider - address of the liquidity provider
     */
    function whitelistLiquidityProvider(address provider)
        external
        onlyOwner
        lock
        logs
    {
        require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        require(provider != address(0), "ERR_INVALID_ADDRESS");

        _liquidityProviderWhitelist[provider] = true;
    }

    /**
     * @notice Remove from the whitelist of liquidity providers (if enabled)
     *
     * @param provider - address of the liquidity provider
     */
    function removeWhitelistedLiquidityProvider(address provider)
        external
        onlyOwner
        lock
        logs
    {
        require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        require(_liquidityProviderWhitelist[provider], "ERR_LP_NOT_WHITELISTED");

        _liquidityProviderWhitelist[provider] = false;
    }

    /**
     * @notice Check if an address is a liquidity provider
     *
     * @dev If the whitelist feature is not enabled, anyone can provide liquidity (assuming finalized)
     *
     * @param provider - Address to check if it can become a liquidity provider
     *
     * @return Boolean value indicating whether the address can join a pool
     */
    function canProvideLiquidity(address provider)
        external
        view
        returns (bool)
    {
        // Technically the null address can't provide funds, but it's irrelevant when there's no whitelist
        return !rights.canWhitelistLPs || _liquidityProviderWhitelist[provider];
    }

    /**
     * @notice Getter for specific permissions
     *
     * @dev value of the enum is just the 0-based index in the enumeration
     *      For instance canPauseSwapping is 0; canChangeWeights is 2
     *
     * @param permission - What permission to check
     *
     * @return Boolean true if we have the given permission
    */
    function hasPermission(RightsManager.Permissions permission)
        external
        view
        virtual
        returns (bool)
    {
        return RightsManager.hasPermission(rights, permission);
    }

    /**
     * @notice Getter for the RightsManager contract
     *
     * @dev Convenience function to get the address of the RightsManager library (so clients can check version)
     *
     * @return Address of the RightsManager library
    */
    function getRightsManagerVersion() external pure returns (address) {
        return address(RightsManager);
    }

    /**
     * @notice Getter for the SmartPoolManager contract
     *
     * @dev Convenience function to get the address of the SmartPoolManager library (so clients can check version)
     *
     * @return Address of the SmartPoolManager library
    */
    function getSmartPoolManagerVersion() external pure returns (address) {
        return address(SmartPoolManager);
    }

    // Public functions
    // "Public" versions that can safely be called from SmartPoolManager
    // Allows only the contract itself to call them (not the controller or any external account)

    /// Can only be called by the SmartPoolManager library, will fail otherwise
    function mintPoolShareFromLib(uint amount) public override {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _mint(amount);
    }

    /// Can only be called by the SmartPoolManager library, will fail otherwise
    function pushPoolShareFromLib(address to, uint amount) public override {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _push(to, amount);
    }

    /// Can only be called by the SmartPoolManager library, will fail otherwise
    function pullPoolShareFromLib(address from, uint amount) public override {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _pull(from, amount);
    }

    /// Can only be called by the SmartPoolManager library, will fail otherwise
    function burnPoolShareFromLib(uint amount) public override {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _burn(amount);
    }

    // Internal functions
    // Lint wants the function to have a leading underscore too
    /* solhint-disable private-vars-leading-underscore */

    /**
     * @notice Create a new Smart Pool
     *
     * @dev Initialize the swap fee to the value provided in the CRP constructor
     *      Can be changed if the canChangeSwapFee permission is enabled
     *
     * @param initialSupply - Starting pool token balance
     */
    function createPoolInternal(uint initialSupply) internal {
        require(address(corePool) == address(0), "ERR_IS_CREATED");
        require(initialSupply >= KassandraConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        require(initialSupply <= KassandraConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");

        // If the controller can change the cap, initialize it to the initial supply
        // Defensive programming, so that there is no gap between creating the pool
        // (initialized to unlimited in the constructor), and setting the cap,
        // which they will presumably do if they have this right.
        if (rights.canChangeCap) {
            tokenCap = initialSupply;
        }

        // There is technically reentrancy here, since we're making external calls and
        // then transferring tokens. However, the external calls are all to the underlying core Pool

        // To the extent possible, modify state variables before calling functions
        _mintPoolShare(initialSupply);
        _pushPoolShare(msg.sender, initialSupply);

        // Deploy new core Pool (coreFactory and corePool are interfaces; all calls are external)
        corePool = coreFactory.newPool();

        for (uint i = 0; i < _initialTokens.length; i++) {
            address t = _initialTokens[i];
            uint bal = _initialBalances[i];
            uint denorm = gradualUpdate.startWeights[i];

            bool returnValue = IERC20(t).transferFrom(msg.sender, address(this), bal);
            require(returnValue, "ERR_ERC20_FALSE");

            returnValue = IERC20(t).safeApprove(address(corePool), KassandraConstants.MAX_UINT);
            require(returnValue, "ERR_ERC20_FALSE");

            corePool.bind(t, bal, denorm);
        }

        // Modifying state variable after external calls here,
        // but not essential, so not dangerous
        delete _initialTokens;

        // set the exit fee collector to the creator of this pool
        corePool.setExitFeeCollector(msg.sender);
        // Set fee to the initial value set in the constructor
        // Hereafter, read the swapFee from the underlying pool, not the local state variable
        corePool.setSwapFee(_initialSwapFee);
        corePool.setPublicSwap(true);

        // "destroy" the temporary swap fee (like _initialTokens above) in case a subclass tries to use it
        delete _initialSwapFee;
    }

    /* solhint-enable private-vars-leading-underscore */

    /**
     * @dev Rebind core Pool and pull tokens from address
     *      Will get tokens from somewhere to send to the underlying core pool
     *
     *      corePool is a contract interface; function calls on it are external
     *
     * @param erc20 - Address of the token being pulled
     * @param from - Address of the owner of the tokens being pulled
     * @param amount - How much tokens are being transferred
     */
    function _pullUnderlying(address erc20, address from, uint amount) internal needsCorePool {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from core Pool.
        uint tokenBalance = corePool.getBalance(erc20);
        uint tokenWeight = corePool.getDenormalizedWeight(erc20);

        // transfer tokens to this contract
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        // and then send it to the core pool
        corePool.rebind(erc20, tokenBalance + amount, tokenWeight);
    }

    /**
     * @dev Rebind core Pool and push tokens to address
     *      Will get tokens from the core pool and send to some address
     *
     *      corePool is a contract interface; function calls on it are external
     *
     * @param erc20 - Address of the token being sent
     * @param to - Address where the tokens are being pushed to
     * @param amount - How much tokens are being transferred
     */
    function _pushUnderlying(address erc20, address to, uint amount) internal needsCorePool {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from core Pool.
        uint tokenBalance = corePool.getBalance(erc20);
        uint tokenWeight = corePool.getDenormalizedWeight(erc20);
        // get the amount of tokens from the underlying pool to this contract
        corePool.rebind(erc20, tokenBalance - amount, tokenWeight);

        // and transfer them to the address
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    // Wrappers around corresponding core functions

    /**
     * @dev Wrapper to mint and enforce maximum cap
     *
     * @param amount - Amount to mint
     */
    function _mint(uint amount) internal override {
        super._mint(amount);
        require(_totalSupply <= tokenCap, "ERR_CAP_LIMIT_REACHED");
    }

    /**
     * @dev Mint pool tokens
     *
     * @param amount - How much to mint
     */
    function _mintPoolShare(uint amount) internal {
        _mint(amount);
    }

    /**
     * @dev Send pool tokens to someone
     *
     * @param to - Who should receive the tokens
     * @param amount - How much to send to the address
     */
    function _pushPoolShare(address to, uint amount) internal {
        _push(to, amount);
    }

    /**
     * @dev Get/Receive pool tokens from someone
     *
     * @param from - From whom should tokens be received
     * @param amount - How much to get from address
     */
    function _pullPoolShare(address from, uint amount) internal  {
        _pull(from, amount);
    }

    /**
     * @dev Burn pool tokens
     *
     * @param amount - How much to burn
     */
    function _burnPoolShare(uint amount) internal  {
        _burn(amount);
    }
}

// File: contracts/CRPFactory.sol


pragma solidity ^0.8.0;






/**
 * @author Kassandra (and Balancer Labs)
 *
 * @title Configurable Rights Pool Factory - create parameterized smart pools
 *
 * @dev Rights are held in a corresponding struct in ConfigurableRightsPool
 *      Index values are as follows:
 *      0: canPauseSwapping - can setPublicSwap back to false after turning it on
 *                            by default, it is off on initialization and can only be turned on
 *      1: canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      2: canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      3: canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      4: canWhitelistLPs - if set, only whitelisted addresses can join pools
 *                           (enables private pools with more than one LP)
 *      5: canChangeCap - can change the KSP cap (max # of pool tokens)
 */
contract CRPFactory is IcrpFactory, Ownable {
    // Keep a list of all Configurable Rights Pools
    mapping(address=>bool) private _isCrp;

    /**
     * @notice Log the address of each new smart pool, and its creator
     *
     * @param caller - Address that created the pool
     * @param pool - Address of the created pool
     */
    event LogNewCrp(
        address indexed caller,
        address indexed pool
    );

    /**
     * @notice Create a new CRP
     *
     * @dev emits a LogNewCRP event
     *
     * @param factoryAddress - the Factory instance used to create the underlying pool
     * @param poolParams - struct containing the names, tokens, weights, balances, and swap fee
     * @param rights - struct of permissions, configuring this CRP instance (see above for definitions)
     *
     * @return crp - ConfigurableRightPool instance of the created CRP
     */
    function newCrp(
        address factoryAddress,
        ConfigurableRightsPool.PoolParams calldata poolParams,
        RightsManager.Rights calldata rights
    )
        external onlyOwner
        returns (ConfigurableRightsPool crp)
    {
        require(poolParams.constituentTokens.length >= KassandraConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");

        // Arrays must be parallel
        require(poolParams.tokenBalances.length == poolParams.constituentTokens.length, "ERR_START_BALANCES_MISMATCH");
        require(poolParams.tokenWeights.length == poolParams.constituentTokens.length, "ERR_START_WEIGHTS_MISMATCH");

        crp = new ConfigurableRightsPool(
            factoryAddress,
            poolParams,
            rights
        );

        emit LogNewCrp(msg.sender, address(crp));

        _isCrp[address(crp)] = true;
        // The caller is the controller of the CRP
        // The CRP will be the controller of the underlying Core Pool
        crp.setController(msg.sender);
    }

    /**
     * @notice Check to see if a given address is a CRP
     *
     * @param addr - Address to check
     *
     * @return boolean indicating whether it is a CRP
     */
    function isCrp(address addr)
        external view override
        returns (bool)
    {
        return _isCrp[addr];
    }
}