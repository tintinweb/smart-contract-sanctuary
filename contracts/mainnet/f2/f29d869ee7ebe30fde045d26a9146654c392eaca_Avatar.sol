/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

// File: contracts/bprotocol/interfaces/IComptroller.sol

pragma solidity 0.5.16;

interface IComptroller {

    // ComptrollerLensInterface.sol
    // =============================
    function markets(address) external view returns (bool, uint);
    function oracle() external view returns (address);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function getAssetsIn(address) external view returns (address[] memory);
    function compAccrued(address) external view returns (uint);
    // Claim all the COMP accrued by holder in all markets
    function claimComp(address holder) external;
    // Claim all the COMP accrued by holder in specific markets
    function claimComp(address holder, address[] calldata cTokens) external;
    function claimComp(address[] calldata holders, address[] calldata cTokens, bool borrowers, bool suppliers) external;

    // Public storage defined in Comptroller contract
    // ===============================================
    function checkMembership(address account, address cToken) external view returns (bool);
    function closeFactorMantissa() external returns (uint256);
    function liquidationIncentiveMantissa() external returns (uint256);



    // Public/external functions defined in Comptroller contract
    // ==========================================================
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);

    function getAllMarkets() external view returns (address[] memory);

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint actualRepayAmount) external view returns (uint, uint);

    function compBorrowState(address cToken) external returns (uint224, uint32);
    function compSupplyState(address cToken) external returns (uint224, uint32);
}

// File: contracts/bprotocol/interfaces/IRegistry.sol

pragma solidity 0.5.16;


interface IRegistry {

    // Ownable
    function transferOwnership(address newOwner) external;

    // Compound contracts
    function comp() external view returns (address);
    function comptroller() external view returns (address);
    function cEther() external view returns (address);

    // B.Protocol contracts
    function bComptroller() external view returns (address);
    function score() external view returns (address);
    function pool() external view returns (address);

    // Avatar functions
    function delegate(address avatar, address delegatee) external view returns (bool);
    function doesAvatarExist(address avatar) external view returns (bool);
    function doesAvatarExistFor(address owner) external view returns (bool);
    function ownerOf(address avatar) external view returns (address);
    function avatarOf(address owner) external view returns (address);
    function newAvatar() external returns (address);
    function getAvatar(address owner) external returns (address);
    // avatar whitelisted calls
    function whitelistedAvatarCalls(address target, bytes4 functionSig) external view returns(bool);

    function setPool(address newPool) external;
    function setWhitelistAvatarCall(address target, bytes4 functionSig, bool list) external;
}

// File: contracts/bprotocol/interfaces/IScore.sol

pragma solidity 0.5.16;

interface IScore {
    function updateDebtScore(address _user, address cToken, int256 amount) external;
    function updateCollScore(address _user, address cToken, int256 amount) external;
    function slashedScore(address _user, address cToken, int256 amount) external;
}

// File: contracts/bprotocol/lib/CarefulMath.sol

pragma solidity 0.5.16;

/**
  * @title Careful Math
  * @author Compound
  * @notice COPY TAKEN FROM COMPOUND FINANCE
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

// File: contracts/bprotocol/lib/Exponential.sol

pragma solidity 0.5.16;


/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }


    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }


    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }

    // New functions added by BProtocol
    // =================================

    function mulTrucate(uint a, uint b) internal pure returns (uint) {
        return mul_(a, b) / expScale;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/bprotocol/interfaces/CTokenInterfaces.sol

pragma solidity 0.5.16;


contract CTokenInterface {
    /* ERC20 */
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /* User Interface */
    function isCToken() external view returns (bool);
    function underlying() external view returns (IERC20);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) public view returns (uint);
    function exchangeRateCurrent() public returns (uint);
    function exchangeRateStored() public view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() public returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

}

contract ICToken is CTokenInterface {

    /* User Interface */
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
}

// Workaround for issue https://github.com/ethereum/solidity/issues/526
// Defined separate contract as `mint()` override with `.value()` has issues
contract ICErc20 is ICToken {
    function mint(uint mintAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
}

contract ICEther is ICToken {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

contract IPriceOracle {
    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CTokenInterface cToken) external view returns (uint);
}

// File: contracts/bprotocol/avatar/AbsAvatarBase.sol

pragma solidity 0.5.16;








contract AbsAvatarBase is Exponential {
    using SafeERC20 for IERC20;

    IRegistry public registry;
    bool public quit;

    /* Storage for topup details */
    // Topped up cToken
    ICToken public toppedUpCToken;
    // Topped up amount of tokens
    uint256 public toppedUpAmount;
    // Remaining max amount available for liquidation
    uint256 public remainingLiquidationAmount;
    // Liquidation cToken
    ICToken public liquidationCToken;

    modifier onlyAvatarOwner() {
        _allowOnlyAvatarOwner();
        _;
    }
    function _allowOnlyAvatarOwner() internal view {
        require(msg.sender == registry.ownerOf(address(this)), "sender-not-owner");
    }

    modifier onlyPool() {
        _allowOnlyPool();
        _;
    }
    function _allowOnlyPool() internal view {
        require(msg.sender == pool(), "only-pool-authorized");
    }

    modifier onlyBComptroller() {
        _allowOnlyBComptroller();
        _;
    }
    function _allowOnlyBComptroller() internal view {
        require(msg.sender == registry.bComptroller(), "only-BComptroller-authorized");
    }

    modifier postPoolOp(bool debtIncrease) {
        _;
        _reevaluate(debtIncrease);
    }

    function _initAvatarBase(address _registry) internal {
        require(registry == IRegistry(0x0), "avatar-already-init");
        registry = IRegistry(_registry);
    }

    /**
     * @dev Hard check to ensure untop is allowed and then reset remaining liquidation amount
     */
    function _hardReevaluate() internal {
        // Check: must allowed untop
        require(canUntop(), "cannot-untop");
        // Reset it to force re-calculation
        remainingLiquidationAmount = 0;
    }

    /**
     * @dev Soft check and reset remaining liquidation amount
     */
    function _softReevaluate() private {
        if(isPartiallyLiquidated()) {
            _hardReevaluate();
        }
    }

    function _reevaluate(bool debtIncrease) private {
        if(debtIncrease) {
            _hardReevaluate();
        } else {
            _softReevaluate();
        }
    }

    function _isCEther(ICToken cToken) internal view returns (bool) {
        return address(cToken) == registry.cEther();
    }

    function _score() internal view returns (IScore) {
        return IScore(registry.score());
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        int256 result = int256(value);
        require(result >= 0, "conversion-fail");
        return result;
    }

    function isPartiallyLiquidated() public view returns (bool) {
        return remainingLiquidationAmount > 0;
    }

    function isToppedUp() public view returns (bool) {
        return toppedUpAmount > 0;
    }

    /**
     * @dev Checks if this Avatar can untop the amount.
     * @return `true` if allowed to borrow, `false` otherwise.
     */
    function canUntop() public returns (bool) {
        // When not topped up, just return true
        if(!isToppedUp()) return true;
        IComptroller comptroller = IComptroller(registry.comptroller());
        bool result = comptroller.borrowAllowed(address(toppedUpCToken), address(this), toppedUpAmount) == 0;
        return result;
    }

    function pool() public view returns (address payable) {
        return address(uint160(registry.pool()));
    }

    /**
     * @dev Returns the status if this Avatar's debt can be liquidated
     * @return `true` when this Avatar can be liquidated, `false` otherwise
     */
    function canLiquidate() public returns (bool) {
        bool result = isToppedUp() && (remainingLiquidationAmount > 0) || (!canUntop());

        return result;
    }

    // function reduce contract size
    function _ensureUserNotQuitB() internal view {
        require(! quit, "user-quit-B");
    }
    /**
     * @dev Topup this avatar by repaying borrowings with ETH
     */
    function topup() external payable onlyPool {
        _ensureUserNotQuitB();

        address cEtherAddr = registry.cEther();
        // when already topped
        bool _isToppedUp = isToppedUp();
        if(_isToppedUp) {
            require(address(toppedUpCToken) == cEtherAddr, "already-topped-other-cToken");
        }

        // 2. Repay borrows from Pool to topup
        ICEther cEther = ICEther(cEtherAddr);
        cEther.repayBorrow.value(msg.value)();

        // 3. Store Topped-up details
        if(! _isToppedUp) toppedUpCToken = cEther;
        toppedUpAmount = add_(toppedUpAmount, msg.value);
    }

    /**
     * @dev Topup the borrowed position of this Avatar by repaying borrows from the pool
     * @notice Only Pool contract allowed to call the topup.
     * @param cToken CToken address to use to RepayBorrows
     * @param topupAmount Amount of tokens to Topup
     */
    function topup(ICErc20 cToken, uint256 topupAmount) external onlyPool {
        _ensureUserNotQuitB();

        // when already topped
        bool _isToppedUp = isToppedUp();
        if(_isToppedUp) {
            require(toppedUpCToken == cToken, "already-topped-other-cToken");
        }

        // 1. Transfer funds from the Pool contract
        IERC20 underlying = cToken.underlying();
        underlying.safeTransferFrom(pool(), address(this), topupAmount);
        underlying.safeApprove(address(cToken), topupAmount);

        // 2. Repay borrows from Pool to topup
        require(cToken.repayBorrow(topupAmount) == 0, "RepayBorrow-fail");

        // 3. Store Topped-up details
        if(! _isToppedUp) toppedUpCToken = cToken;
        toppedUpAmount = add_(toppedUpAmount, topupAmount);
    }

    function untop(uint amount) external onlyPool {
        _untop(amount, amount);
    }

    /**
     * @dev Untop the borrowed position of this Avatar by borrowing from Compound and transferring
     *      it to the pool.
     * @notice Only Pool contract allowed to call the untop.
     */
    function _untop(uint amount, uint amountToBorrow) internal {
        // when already untopped
        if(!isToppedUp()) return;

        // 1. Udpdate storage for toppedUp details
        require(toppedUpAmount >= amount, "amount>=toppedUpAmount");
        toppedUpAmount = sub_(toppedUpAmount, amount);
        if((toppedUpAmount == 0) && (remainingLiquidationAmount > 0)) remainingLiquidationAmount = 0;

        // 2. Borrow from Compound and send tokens to Pool
        if(amountToBorrow > 0 )
            require(toppedUpCToken.borrow(amountToBorrow) == 0, "borrow-fail");

        if(address(toppedUpCToken) == registry.cEther()) {
            // 3. Send borrowed ETH to Pool contract
            // Sending ETH to Pool using `.send()` to avoid DoS attack
            bool success = pool().send(amount);
            success; // shh: Not checking return value to avoid DoS attack
        } else {
            // 3. Transfer borrowed amount to Pool contract
            IERC20 underlying = toppedUpCToken.underlying();
            underlying.safeTransfer(pool(), amount);
        }
    }

    function _untop() internal {
        // when already untopped
        if(!isToppedUp()) return;
        _untop(toppedUpAmount, toppedUpAmount);
    }

    function _untopBeforeRepay(ICToken cToken, uint256 repayAmount) internal returns (uint256 amtToRepayOnCompound) {
        if(toppedUpAmount > 0 && cToken == toppedUpCToken) {
            // consume debt from cushion first
            uint256 amtToUntopFromB = repayAmount >= toppedUpAmount ? toppedUpAmount : repayAmount;
            _untop(toppedUpAmount, sub_(toppedUpAmount, amtToUntopFromB));
            amtToRepayOnCompound = sub_(repayAmount, amtToUntopFromB);
        } else {
            amtToRepayOnCompound = repayAmount;
        }
    }

    function _doLiquidateBorrow(
        ICToken debtCToken,
        uint256 underlyingAmtToLiquidate,
        uint256 amtToDeductFromTopup,
        ICToken collCToken
    )
        internal
        onlyPool
        returns (uint256)
    {
        address payable poolContract = pool();

        // 1. Is toppedUp OR partially liquidated
        bool partiallyLiquidated = isPartiallyLiquidated();
        require(isToppedUp() || partiallyLiquidated, "cant-perform-liquidateBorrow");

        if(partiallyLiquidated) {
            require(debtCToken == liquidationCToken, "debtCToken!=liquidationCToken");
        } else {
            require(debtCToken == toppedUpCToken, "debtCToken!=toppedUpCToken");
            liquidationCToken = debtCToken;
        }

        if(!partiallyLiquidated) {
            remainingLiquidationAmount = getMaxLiquidationAmount(debtCToken);
        }

        // 2. `underlayingAmtToLiquidate` is under limit
        require(underlyingAmtToLiquidate <= remainingLiquidationAmount, "amountToLiquidate-too-big");

        // 3. Liquidator perform repayBorrow
        require(underlyingAmtToLiquidate >= amtToDeductFromTopup, "amtToDeductFromTopup>underlyingAmtToLiquidate");
        uint256 amtToRepayOnCompound = sub_(underlyingAmtToLiquidate, amtToDeductFromTopup);
        
        if(amtToRepayOnCompound > 0) {
            bool isCEtherDebt = _isCEther(debtCToken);
            if(isCEtherDebt) {
                // CEther
                require(msg.value == amtToRepayOnCompound, "insuffecient-ETH-sent");
                ICEther cEther = ICEther(registry.cEther());
                cEther.repayBorrow.value(amtToRepayOnCompound)();
            } else {
                // CErc20
                // take tokens from pool contract
                IERC20 underlying = toppedUpCToken.underlying();
                underlying.safeTransferFrom(poolContract, address(this), amtToRepayOnCompound);
                underlying.safeApprove(address(debtCToken), amtToRepayOnCompound);
                require(ICErc20(address(debtCToken)).repayBorrow(amtToRepayOnCompound) == 0, "repayBorrow-fail");
            }
        }

        require(toppedUpAmount >= amtToDeductFromTopup, "amtToDeductFromTopup>toppedUpAmount");
        toppedUpAmount = sub_(toppedUpAmount, amtToDeductFromTopup);

        // 4.1 Update remaining liquidation amount
        remainingLiquidationAmount = sub_(remainingLiquidationAmount, underlyingAmtToLiquidate);

        // 5. Calculate premium and transfer to Liquidator
        IComptroller comptroller = IComptroller(registry.comptroller());
        (uint err, uint seizeTokens) = comptroller.liquidateCalculateSeizeTokens(
            address(debtCToken),
            address(collCToken),
            underlyingAmtToLiquidate
        );
        require(err == 0, "err-liquidateCalculateSeizeTokens");

        // 6. Transfer permiumAmount to liquidator
        require(collCToken.transfer(poolContract, seizeTokens), "collCToken-xfr-fail");

        return seizeTokens;
    }

    function getMaxLiquidationAmount(ICToken debtCToken) public returns (uint256) {
        if(isPartiallyLiquidated()) return remainingLiquidationAmount;

        uint256 avatarDebt = debtCToken.borrowBalanceCurrent(address(this));
        // `toppedUpAmount` is also called poolDebt;
        uint256 totalDebt = add_(avatarDebt, toppedUpAmount);
        // When First time liquidation is performed after topup
        // maxLiquidationAmount = closeFactorMantissa * totalDedt / 1e18;
        IComptroller comptroller = IComptroller(registry.comptroller());
        return mulTrucate(comptroller.closeFactorMantissa(), totalDebt);
    }

    function splitAmountToLiquidate(
        uint256 underlyingAmtToLiquidate,
        uint256 maxLiquidationAmount
    )
        public view returns (uint256 amtToDeductFromTopup, uint256 amtToRepayOnCompound)
    {
        // underlyingAmtToLiqScalar = underlyingAmtToLiquidate * 1e18
        (MathError mErr, Exp memory result) = mulScalar(Exp({mantissa: underlyingAmtToLiquidate}), expScale);
        require(mErr == MathError.NO_ERROR, "underlyingAmtToLiqScalar-fail");
        uint underlyingAmtToLiqScalar = result.mantissa;

        // percent = underlyingAmtToLiqScalar / maxLiquidationAmount
        uint256 percentInScale = div_(underlyingAmtToLiqScalar, maxLiquidationAmount);

        // amtToDeductFromTopup = toppedUpAmount * percentInScale / 1e18
        amtToDeductFromTopup = mulTrucate(toppedUpAmount, percentInScale);

        // amtToRepayOnCompound = underlyingAmtToLiquidate - amtToDeductFromTopup
        amtToRepayOnCompound = sub_(underlyingAmtToLiquidate, amtToDeductFromTopup);
    }

    /**
     * @dev Off-chain function to calculate `amtToDeductFromTopup` and `amtToRepayOnCompound`
     * @notice function is non-view but no-harm as CToken.borrowBalanceCurrent() only updates accured interest
     */
    function calcAmountToLiquidate(
        ICToken debtCToken,
        uint256 underlyingAmtToLiquidate
    )
        external returns (uint256 amtToDeductFromTopup, uint256 amtToRepayOnCompound)
    {
        uint256 amountToLiquidate = remainingLiquidationAmount;
        if(! isPartiallyLiquidated()) {
            amountToLiquidate = getMaxLiquidationAmount(debtCToken);
        }
        (amtToDeductFromTopup, amtToRepayOnCompound) = splitAmountToLiquidate(underlyingAmtToLiquidate, amountToLiquidate);
    }

    function quitB() external onlyAvatarOwner() {
        quit = true;
        _hardReevaluate();
    }
}

// File: contracts/bprotocol/interfaces/IBToken.sol

pragma solidity 0.5.16;

interface IBToken {
    function cToken() external view returns (address);
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
}

// File: contracts/bprotocol/avatar/AbsComptroller.sol

pragma solidity 0.5.16;






/**
 * @title Abstract Comptroller contract for Avatar
 */
contract AbsComptroller is AbsAvatarBase {

    function enterMarket(address bToken) external onlyBComptroller returns (uint256) {
        address cToken = IBToken(bToken).cToken();
        return _enterMarket(cToken);
    }

    function _enterMarket(address cToken) internal postPoolOp(false) returns (uint256) {
        address[] memory cTokens = new address[](1);
        cTokens[0] = cToken;
        return _enterMarkets(cTokens)[0];
    }

    function enterMarkets(address[] calldata bTokens) external onlyBComptroller returns (uint256[] memory) {
        address[] memory cTokens = new address[](bTokens.length);
        for(uint256 i = 0; i < bTokens.length; i++) {
            cTokens[i] = IBToken(bTokens[i]).cToken();
        }
        return _enterMarkets(cTokens);
    }

    function _enterMarkets(address[] memory cTokens) internal postPoolOp(false) returns (uint256[] memory) {
        IComptroller comptroller = IComptroller(registry.comptroller());
        uint256[] memory result = comptroller.enterMarkets(cTokens);
        for(uint256 i = 0; i < result.length; i++) {
            require(result[i] == 0, "enter-markets-fail");
        }
        return result;
    }

    function exitMarket(IBToken bToken) external onlyBComptroller postPoolOp(true) returns (uint256) {
        address cToken = bToken.cToken();
        IComptroller comptroller = IComptroller(registry.comptroller());
        uint result = comptroller.exitMarket(cToken);
        _disableCToken(cToken);
        return result;
    }

    function _disableCToken(address cToken) internal {
        ICToken(cToken).underlying().safeApprove(cToken, 0);
    }

    function claimComp() external onlyBComptroller {
        IComptroller comptroller = IComptroller(registry.comptroller());
        comptroller.claimComp(address(this));
        transferCOMP();
    }

    function claimComp(address[] calldata bTokens) external onlyBComptroller {
        address[] memory cTokens = new address[](bTokens.length);
        for(uint256 i = 0; i < bTokens.length; i++) {
            cTokens[i] = IBToken(bTokens[i]).cToken();
        }
        IComptroller comptroller = IComptroller(registry.comptroller());
        comptroller.claimComp(address(this), cTokens);
        transferCOMP();
    }

    function claimComp(
        address[] calldata bTokens,
        bool borrowers,
        bool suppliers
    )
        external
        onlyBComptroller
    {
        address[] memory cTokens = new address[](bTokens.length);
        for(uint256 i = 0; i < bTokens.length; i++) {
            cTokens[i] = IBToken(bTokens[i]).cToken();
        }

        address[] memory holders = new address[](1);
        holders[0] = address(this);
        IComptroller comptroller = IComptroller(registry.comptroller());
        comptroller.claimComp(holders, cTokens, borrowers, suppliers);

        transferCOMP();
    }

    function transferCOMP() public {
        address owner = registry.ownerOf(address(this));
        IERC20 comp = IERC20(registry.comp());
        comp.safeTransfer(owner, comp.balanceOf(address(this)));
    }

    function getAccountLiquidity(address oracle) external view returns (uint err, uint liquidity, uint shortFall) {
        return _getAccountLiquidity(oracle);
    }

    function getAccountLiquidity() external view returns (uint err, uint liquidity, uint shortFall) {
        IComptroller comptroller = IComptroller(registry.comptroller());
        return _getAccountLiquidity(comptroller.oracle());
    }

    function _getAccountLiquidity(address oracle) internal view returns (uint err, uint liquidity, uint shortFall) {
        IComptroller comptroller = IComptroller(registry.comptroller());
        // If not topped up, get the account liquidity from Comptroller
        (err, liquidity, shortFall) = comptroller.getAccountLiquidity(address(this));
        if(!isToppedUp()) {
            return (err, liquidity, shortFall);
        }
        require(err == 0, "Err-in-account-liquidity");

        uint256 price = IPriceOracle(oracle).getUnderlyingPrice(toppedUpCToken);
        uint256 toppedUpAmtInUSD = mulTrucate(toppedUpAmount, price);

        // liquidity = 0 and shortFall = 0
        if(liquidity == toppedUpAmtInUSD) return(0, 0, 0);

        // when shortFall = 0
        if(shortFall == 0 && liquidity > 0) {
            if(liquidity > toppedUpAmtInUSD) {
                liquidity = sub_(liquidity, toppedUpAmtInUSD);
            } else {
                shortFall = sub_(toppedUpAmtInUSD, liquidity);
                liquidity = 0;
            }
        } else {
            // Handling case when compound returned liquidity = 0 and shortFall >= 0
            shortFall = add_(shortFall, toppedUpAmtInUSD);
        }
    }
}

// File: contracts/bprotocol/interfaces/IAvatar.sol

pragma solidity 0.5.16;

contract IAvatarERC20 {
    function transfer(address cToken, address dst, uint256 amount) external returns (bool);
    function transferFrom(address cToken, address src, address dst, uint256 amount) external returns (bool);
    function approve(address cToken, address spender, uint256 amount) public returns (bool);
}

contract IAvatar is IAvatarERC20 {
    function initialize(address _registry, address comp, address compVoter) external;
    function quit() external returns (bool);
    function canUntop() public returns (bool);
    function toppedUpCToken() external returns (address);
    function toppedUpAmount() external returns (uint256);
    function redeem(address cToken, uint256 redeemTokens, address payable userOrDelegatee) external returns (uint256);
    function redeemUnderlying(address cToken, uint256 redeemAmount, address payable userOrDelegatee) external returns (uint256);
    function borrow(address cToken, uint256 borrowAmount, address payable userOrDelegatee) external returns (uint256);
    function borrowBalanceCurrent(address cToken) external returns (uint256);
    function collectCToken(address cToken, address from, uint256 cTokenAmt) public;
    function liquidateBorrow(uint repayAmount, address cTokenCollateral) external payable returns (uint256);

    // Comptroller functions
    function enterMarket(address cToken) external returns (uint256);
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    function exitMarket(address cToken) external returns (uint256);
    function claimComp() external;
    function claimComp(address[] calldata bTokens) external;
    function claimComp(address[] calldata bTokens, bool borrowers, bool suppliers) external;
    function getAccountLiquidity() external view returns (uint err, uint liquidity, uint shortFall);
}

// Workaround for issue https://github.com/ethereum/solidity/issues/526
// CEther
contract IAvatarCEther is IAvatar {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
}

// CErc20
contract IAvatarCErc20 is IAvatar {
    function mint(address cToken, uint256 mintAmount) external returns (uint256);
    function repayBorrow(address cToken, uint256 repayAmount) external returns (uint256);
    function repayBorrowBehalf(address cToken, address borrower, uint256 repayAmount) external returns (uint256);
}

contract ICushion {
    function liquidateBorrow(uint256 underlyingAmtToLiquidate, uint256 amtToDeductFromTopup, address cTokenCollateral) external payable returns (uint256);    
    function canLiquidate() external returns (bool);
    function untop(uint amount) external;
    function toppedUpAmount() external returns (uint);
    function remainingLiquidationAmount() external returns(uint);
    function getMaxLiquidationAmount(address debtCToken) public returns (uint256);
}

contract ICushionCErc20 is ICushion {
    function topup(address cToken, uint256 topupAmount) external;
}

contract ICushionCEther is ICushion {
    function topup() external payable;
}

// File: contracts/bprotocol/interfaces/IBComptroller.sol

pragma solidity 0.5.16;

interface IBComptroller {
    function isCToken(address cToken) external view returns (bool);
    function isBToken(address bToken) external view returns (bool);
    function c2b(address cToken) external view returns (address);
    function b2c(address bToken) external view returns (address);
}

// File: contracts/bprotocol/avatar/AbsCToken.sol

pragma solidity 0.5.16;







contract AbsCToken is AbsAvatarBase {

    modifier onlyBToken() {
        _allowOnlyBToken();
        _;
    }

    function _allowOnlyBToken() internal view {
        require(isValidBToken(msg.sender), "only-BToken-authorized");
    }

    function isValidBToken(address bToken) internal view returns (bool) {
        IBComptroller bComptroller = IBComptroller(registry.bComptroller());
        return bComptroller.isBToken(bToken);
    }

    function borrowBalanceCurrent(ICToken cToken) public onlyBToken returns (uint256) {
        uint256 borrowBalanceCurr = cToken.borrowBalanceCurrent(address(this));
        if(toppedUpCToken == cToken) return add_(borrowBalanceCurr, toppedUpAmount);
        return borrowBalanceCurr;
    }

    function _toUnderlying(ICToken cToken, uint256 redeemTokens) internal returns (uint256) {
        uint256 exchangeRate = cToken.exchangeRateCurrent();
        return mulTrucate(redeemTokens, exchangeRate);
    }

    // CEther
    // ======
    function mint() public payable onlyBToken postPoolOp(false) {
        ICEther cEther = ICEther(registry.cEther());
        cEther.mint.value(msg.value)(); // fails on compound in case of err
        if(! quit) _score().updateCollScore(address(this), address(cEther), toInt256(msg.value));
    }

    function repayBorrow()
        external
        payable
        onlyBToken
        postPoolOp(false)
    {
        ICEther cEther = ICEther(registry.cEther());
        uint256 amtToRepayOnCompound = _untopBeforeRepay(cEther, msg.value);
        if(amtToRepayOnCompound > 0) cEther.repayBorrow.value(amtToRepayOnCompound)(); // fails on compound in case of err
        if(! quit) _score().updateDebtScore(address(this), address(cEther), -toInt256(msg.value));
    }

    // CErc20
    // ======
    function mint(ICErc20 cToken, uint256 mintAmount) public onlyBToken postPoolOp(false) returns (uint256) {
        IERC20 underlying = cToken.underlying();
        underlying.safeApprove(address(cToken), mintAmount);
        uint result = cToken.mint(mintAmount);
        require(result == 0, "mint-fail");
        if(! quit) _score().updateCollScore(address(this), address(cToken), toInt256(mintAmount));
        return result;
    }

    function repayBorrow(ICErc20 cToken, uint256 repayAmount)
        external
        onlyBToken
        postPoolOp(false)
        returns (uint256)
    {
        uint256 amtToRepayOnCompound = _untopBeforeRepay(cToken, repayAmount);
        uint256 result = 0;
        if(amtToRepayOnCompound > 0) {
            IERC20 underlying = cToken.underlying();
            // use resetApprove() in case ERC20.approve() has front-running attack protection
            underlying.safeApprove(address(cToken), amtToRepayOnCompound);
            result = cToken.repayBorrow(amtToRepayOnCompound);
            require(result == 0, "repayBorrow-fail");
            if(! quit) _score().updateDebtScore(address(this), address(cToken), -toInt256(repayAmount));
        }
        return result; // in case of err, tx fails at BToken
    }

    // CEther / CErc20
    // ===============
    function liquidateBorrow(
        uint256 underlyingAmtToLiquidateDebt,
        uint256 amtToDeductFromTopup,
        ICToken cTokenColl
    ) external payable returns (uint256) {
        // 1. Can liquidate?
        require(canLiquidate(), "cant-liquidate");

        ICToken cTokenDebt = toppedUpCToken;
        uint256 seizedCTokensColl = _doLiquidateBorrow(cTokenDebt, underlyingAmtToLiquidateDebt, amtToDeductFromTopup, cTokenColl);
        // Convert seizedCToken to underlyingTokens
        uint256 underlyingSeizedTokensColl = _toUnderlying(cTokenColl, seizedCTokensColl);
        if(! quit) {
            IScore score = _score();
            score.updateCollScore(address(this), address(cTokenColl), -toInt256(underlyingSeizedTokensColl));
            score.updateDebtScore(address(this), address(cTokenDebt), -toInt256(underlyingAmtToLiquidateDebt));
        }
        return 0;
    }

    function redeem(
        ICToken cToken,
        uint256 redeemTokens,
        address payable userOrDelegatee
    ) external onlyBToken postPoolOp(true) returns (uint256) {
        uint256 result = cToken.redeem(redeemTokens);
        require(result == 0, "redeem-fail");

        uint256 underlyingRedeemAmount = _toUnderlying(cToken, redeemTokens);
        if(! quit) _score().updateCollScore(address(this), address(cToken), -toInt256(underlyingRedeemAmount));

        // Do the fund transfer at last
        if(_isCEther(cToken)) {
            userOrDelegatee.transfer(address(this).balance);
        } else {
            IERC20 underlying = cToken.underlying();
            uint256 redeemedAmount = underlying.balanceOf(address(this));
            underlying.safeTransfer(userOrDelegatee, redeemedAmount);
        }
        return result;
    }

    function redeemUnderlying(
        ICToken cToken,
        uint256 redeemAmount,
        address payable userOrDelegatee
    ) external onlyBToken postPoolOp(true) returns (uint256) {
        uint256 result = cToken.redeemUnderlying(redeemAmount);
        require(result == 0, "redeemUnderlying-fail");

        if(! quit) _score().updateCollScore(address(this), address(cToken), -toInt256(redeemAmount));

        // Do the fund transfer at last
        if(_isCEther(cToken)) {
            userOrDelegatee.transfer(redeemAmount);
        } else {
            IERC20 underlying = cToken.underlying();
            underlying.safeTransfer(userOrDelegatee, redeemAmount);
        }
        return result;
    }

    function borrow(
        ICToken cToken,
        uint256 borrowAmount,
        address payable userOrDelegatee
    ) external onlyBToken postPoolOp(true) returns (uint256) {
        uint256 result = cToken.borrow(borrowAmount);
        require(result == 0, "borrow-fail");

        if(! quit) _score().updateDebtScore(address(this), address(cToken), toInt256(borrowAmount));

        // send funds at last
        if(_isCEther(cToken)) {
            userOrDelegatee.transfer(borrowAmount);
        } else {
            IERC20 underlying = cToken.underlying();
            underlying.safeTransfer(userOrDelegatee, borrowAmount);
        }
        return result;
    }

    // ERC20
    // ======
    function transfer(ICToken cToken, address dst, uint256 amount) public onlyBToken postPoolOp(true) returns (bool) {
        address dstAvatar = registry.getAvatar(dst);
        bool result = cToken.transfer(dstAvatar, amount);
        require(result, "transfer-fail");

        uint256 underlyingRedeemAmount = _toUnderlying(cToken, amount);

        IScore score = _score();
        if(! quit) score.updateCollScore(address(this), address(cToken), -toInt256(underlyingRedeemAmount));
        if(! IAvatar(dstAvatar).quit()) score.updateCollScore(dstAvatar, address(cToken), toInt256(underlyingRedeemAmount));

        return result;
    }

    function transferFrom(ICToken cToken, address src, address dst, uint256 amount) public onlyBToken postPoolOp(true) returns (bool) {
        address srcAvatar = registry.getAvatar(src);
        address dstAvatar = registry.getAvatar(dst);

        bool result = cToken.transferFrom(srcAvatar, dstAvatar, amount);
        require(result, "transferFrom-fail");

        require(IAvatar(srcAvatar).canUntop(), "insuffecient-fund-at-src");
        uint256 underlyingRedeemAmount = _toUnderlying(cToken, amount);

        IScore score = _score();
        if(! IAvatar(srcAvatar).quit()) score.updateCollScore(srcAvatar, address(cToken), -toInt256(underlyingRedeemAmount));
        if(! IAvatar(dstAvatar).quit()) score.updateCollScore(dstAvatar, address(cToken), toInt256(underlyingRedeemAmount));

        return result;
    }

    function approve(ICToken cToken, address spender, uint256 amount) public onlyBToken returns (bool) {
        address spenderAvatar = registry.getAvatar(spender);
        return cToken.approve(spenderAvatar, amount);
    }

    function collectCToken(ICToken cToken, address from, uint256 cTokenAmt) public postPoolOp(false) {
        // `from` should not be an avatar
        require(registry.ownerOf(from) == address(0), "from-is-an-avatar");
        require(cToken.transferFrom(from, address(this), cTokenAmt), "transferFrom-fail");
        uint256 underlyingAmt = _toUnderlying(cToken, cTokenAmt);
        if(! quit) _score().updateCollScore(address(this), address(cToken), toInt256(underlyingAmt));
    }

    /**
     * @dev Fallback to receieve ETH from CEther contract on `borrow()`, `redeem()`, `redeemUnderlying`
     */

    function () external payable {
        // Receive ETH
    }
}

// File: contracts/bprotocol/interfaces/IComp.sol

pragma solidity 0.5.16;

interface IComp {
    function delegate(address delegatee) external;
}

// File: contracts/bprotocol/avatar/Avatar.sol

pragma solidity 0.5.16;





contract ProxyStorage {
    address internal masterCopy;
}

/**
 * @title An Avatar contract deployed per account. The contract holds cTokens and directly interacts
 *        with Compound finance.
 * @author Smart Future Labs Ltd.
 */
contract Avatar is ProxyStorage, AbsComptroller, AbsCToken {

    // @NOTICE: NO CONSTRUCTOR AS ITS USED AS AN IMPLEMENTATION CONTRACT FOR PROXY

    /**
     * @dev Initialize the contract variables
     * @param _registry Registry contract address
     */
    function initialize(address _registry, address /*comp*/, address /*compVoter*/) external {
        _initAvatarBase(_registry);
    }

    //override
    /**
     * @dev Mint cETH using ETH and enter market on Compound
     * @notice onlyBToken can call this function, as `super.mint()` is protected with `onlyBToken` modifier
     */
    function mint() public payable {
        ICEther cEther = ICEther(registry.cEther());
        require(_enterMarket(address(cEther)) == 0, "enterMarket-fail");
        super.mint();
    }

    //override
    /**
     * @dev Mint cToken for ERC20 and enter market on Compound
     * @notice onlyBToken can call this function, as `super.mint()` is protected with `onlyBToken` modifier
     */
    function mint(ICErc20 cToken, uint256 mintAmount) public returns (uint256) {
        require(_enterMarket(address(cToken)) == 0, "enterMarket-fail");
        uint256 result = super.mint(cToken, mintAmount);
        return result;
    }

    // EMERGENCY FUNCTIONS
    function emergencyCall(address payable target, bytes calldata data) external payable onlyAvatarOwner {
        uint first4Bytes = uint(uint8(data[0])) << 24 | uint(uint8(data[1])) << 16 | uint(uint8(data[2])) << 8 | uint(uint8(data[3])) << 0;
        bytes4 functionSig = bytes4(uint32(first4Bytes));

        require(quit || registry.whitelistedAvatarCalls(target, functionSig), "not-listed");
        (bool succ, bytes memory err) = target.call.value(msg.value)(data);

        require(succ, string(err));
    }
}