//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBPool.sol";
import "../interfaces/IProtocolFee.sol";

/**
 * @title ProtocolFee
 * @author Protofire
 * @dev Module for protocol swap fee calculations.
 *
 */
contract ProtocolFee is Ownable, IProtocolFee {
    using SafeMath for uint256;

    uint256 public constant ONE = 10**18;
    uint256 public constant MIN_FEE = ONE / 10**6; // 0.0001%
    uint256 public constant MAX_FEE = ONE / 2; // 50%

    /// @dev Protocol fee % - 10^18 = 100%
    uint256 public protocolFee;
    /// @dev Minimum Protocol fee % - 10^18 = 100%
    uint256 public minProtocolFee;

    /**
     * @dev Emitted when `protocolFee` is set.
     */
    event ProtocolFeeSet(uint256 protocolFee);

    /**
     * @dev Emitted when `minProtocolFee` is set.
     */
    event MinProtocolFeeSet(uint256 minProtocolFee);

    /**
     * @dev Sets the values for {protocolFee} and {minProtocolFee}.
     *
     * Sets ownership to the account that deploys the contract.
     *
     */
    constructor(uint256 _protocolFee, uint256 _minProtocolFee) {
        _setProtocolFee(_protocolFee);
        _setMinProtocolFee(_minProtocolFee);
    }

    /**
     * @dev Sets `_protocolFee` as the new protocolFee.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_protocolFee` should not be the greater than or equal to MIN_FEE and lower than or equal to MAX_FEE.
     *
     * @param _protocolFee The address of the registry.
     */
    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        _setProtocolFee(_protocolFee);
    }

    /**
     * @dev Sets `_minProtocolFee` as the new minProtocolFee.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_minProtocolFee` should not be the greater than or equal to MIN_FEE and lower than or equal to MAX_FEE.
     *
     * @param _minProtocolFee The address of the registry.
     */
    function setMinProtocolFee(uint256 _minProtocolFee) external onlyOwner {
        _setMinProtocolFee(_minProtocolFee);
    }

    /**
     * @dev Sets `_protocolFee` as the new protocolFee.
     *
     * Requirements:
     *
     * - `_protocolFee` should not be the greater than or equal to MIN_FEE and lower than or equal to MAX_FEE.
     *
     * @param _protocolFee The address of the registry.
     */
    function _setProtocolFee(uint256 _protocolFee) internal {
        require(_protocolFee >= MIN_FEE, "ERR_MIN_FEE");
        require(_protocolFee <= MAX_FEE, "ERR_MAX_FEE");
        emit ProtocolFeeSet(_protocolFee);
        protocolFee = _protocolFee;
    }

    /**
     * @dev Sets `_minProtocolFee` as the new minProtocolFee.
     *
     * Requirements:
     *
     * - `_minProtocolFee` should not be the greater than or equal to MIN_FEE and lower than or equal to MAX_FEE.
     *
     * @param _minProtocolFee The address of the registry.
     */
    function _setMinProtocolFee(uint256 _minProtocolFee) internal {
        require(_minProtocolFee >= MIN_FEE, "ERR_MIN_MIN_FEE");
        require(_minProtocolFee <= MAX_FEE, "ERR_MAX_MIN_FEE");
        emit MinProtocolFeeSet(_minProtocolFee);
        minProtocolFee = _minProtocolFee;
    }

    /**
     * @dev Calculates protocol swap fee for single-hop swaps.
     *
     * @param swaps Array of single-hop swaps.
     * @param totalAmountIn Total amount in.
     */
    function batchFee(Swap[] memory swaps, uint256 totalAmountIn) external view override returns (uint256) {
        uint256 totalSwapsFee = 0;

        for (uint256 i = 0; i < swaps.length; i++) {
            totalSwapsFee = totalSwapsFee.add(getPoolFeeAmount(swaps[i].pool, swaps[i].swapAmount));
        }

        uint256 feeAmount = getProtocolFeeAmount(totalSwapsFee);

        return Math.max(feeAmount, minProtocolFee.mul(totalAmountIn).div(ONE));
    }

    /**
     * @dev Calculates protocol swap fee for multi-hop swaps.
     *
     * @param swapSequences multi-hop swaps sequence.
     * @param totalAmountIn Total amount in.
     */
    function multihopBatch(Swap[][] memory swapSequences, uint256 totalAmountIn)
        external
        view
        override
        returns (uint256)
    {
        uint256 totalSwapFeeAmount = 0;

        for (uint256 i = 0; i < swapSequences.length; i++) {
            // Considering that the outgoing value is equivalent to the incoming less the pool fee,
            // all the amounts are expressed in A to be able to calculate the equivalent total fee.
            // So the swapAmount[i][k] = swapAmount[i][k-1] - swapFee[i][k-1]
            uint256 totalSequenceIn = swapSequences[i][0].swapAmount;

            for (uint256 k = 0; k < swapSequences[i].length; k++) {
                uint256 poolFeeAmount = getPoolFeeAmount(swapSequences[i][k].pool, totalSequenceIn);
                totalSwapFeeAmount = totalSwapFeeAmount.add(poolFeeAmount);
                totalSequenceIn = totalSequenceIn.sub(poolFeeAmount);
            }
        }

        return Math.max(getProtocolFeeAmount(totalSwapFeeAmount), minProtocolFee.mul(totalAmountIn).div(ONE));
    }

    /**
     * @dev Retives protocol fee amount out of the pool fee amount.
     *
     * @param poolFeeAmount Pool fee ammount.
     */
    function getProtocolFeeAmount(uint256 poolFeeAmount) internal view returns (uint256) {
        return protocolFee.mul(poolFeeAmount).div(ONE);
    }

    /**
     * @dev Retives pool swap fee amount.
     *
     * @param pool Pool address.
     * @param swapAmount Total amount in.
     */
    function getPoolFeeAmount(address pool, uint256 swapAmount) internal view returns (uint256) {
        IBPool bPool = IBPool(pool);
        uint256 swapFee = bPool.getSwapFee();
        return swapFee.mul(swapAmount).div(ONE);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../GSN/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBPool
 * @author Protofire
 * @dev Balancer BPool contract interface.
 *
 */
interface IBPool {
    function isPublicSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getNormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getController() external view returns (address);

    function setSwapFee(uint256 swapFee) external;

    function setController(address manager) external;

    function setPublicSwap(bool public_) external;

    function finalize() external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);

    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) external pure returns (uint256 spotPrice);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../balancer/ISwap.sol";

/**
 * @title IProtocolFee
 * @author Protofire
 * @dev ProtocolFee interface.
 *
 */
interface IProtocolFee is ISwap {
    function batchFee(Swap[] memory swaps, uint256 amountIn) external view returns (uint256);

    function multihopBatch(Swap[][] memory swapSequences, uint256 amountIn) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

interface ISwap {
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
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