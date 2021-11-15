// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { AggregatorInterface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

import { IOptionFactory } from "../interfaces/OptionFactory.sol";
import { IBlackScholes } from "../interfaces/BlackScholes.sol";
import { ILiquidityManager } from "../interfaces/LiquidityManager.sol";
import { ILiquidityVault } from "../interfaces/LiquidityVault.sol";
import { ILongShortPair } from "../interfaces/LongShortPair.sol";
import { IUniswapV3Pool } from "../interfaces/UniswapV3Pool.sol";
import { ICoveredCallFinancialLibrary } from "../interfaces/CoveredCallFinancialLibrary.sol";

import { FullMath } from "../libraries/FullMath.sol";
import { PriceMath } from "../libraries/PriceMath.sol";
import { PercentageMath } from "../libraries/PercentageMath.sol";

contract BlackScholesStrategy is Ownable {
    using PercentageMath for uint256;

    /* ============ Immutables ============ */
    IOptionFactory public immutable optionFactory;
    IBlackScholes public immutable blackScholes;
    ILiquidityManager public immutable liqManager;
    ICoveredCallFinancialLibrary public immutable coveredCall;

    mapping(address => uint256) public volatility;
    mapping(address => AggregatorInterface) public oracles;
    mapping(address => uint256) public lastRebalanced; 

    constructor(
        IOptionFactory options,
        IBlackScholes bs,
        ILiquidityManager liquidityManager,
        ICoveredCallFinancialLibrary fpl
    ) {
        optionFactory = options;
        blackScholes = bs;
        liqManager = liquidityManager;
        coveredCall = fpl;
    }

    function rebalance(address lsp) external {
        require(optionFactory.lsps(lsp));
        require(lastRebalanced[lsp] + 1 days >= block.timestamp, "BlackScholesStrategy::too-early-to-rebalance");

        ILongShortPair longShort = ILongShortPair(lsp);

        (uint256 collateralPrice, uint256 idealPrice) = getIdealPrice(lsp);
        uint256 price = FullMath.mulDiv(idealPrice, 10 ** 18, collateralPrice);
        uint256 sqrtPriceX96 = PriceMath.getSqrtRatioAtPrice(
            longShort.longToken(),
            longShort.collateralToken(),
            price
        );

        // uint256 percent = price.percentMul(1000);

        uint256 upperPrice = price + price.percentMul(1000);
        uint256 lowerPrice = price - price.percentMul(1000);

        uint160 sqrtPriceAX96 = PriceMath.getSqrtRatioAtPrice(
            longShort.longToken(),
            longShort.collateralToken(),
            lowerPrice
        );

        uint160 sqrtPriceBX96 = PriceMath.getSqrtRatioAtPrice(
            longShort.longToken(),
            longShort.collateralToken(),
            upperPrice
        );

        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }

        ILiquidityVault vault = ILiquidityVault(liqManager.vaults(lsp));
        IUniswapV3Pool pool = vault.pool();

        (uint160 currentPriceX96, , , , , , ) = pool.slot0();

        {
            bool zeroForOne;

            if (longShort.collateralToken() > longShort.longToken()) {
                zeroForOne = currentPriceX96 > sqrtPriceX96 ? false : true;
            } else {
                price = FullMath.mulDiv(collateralPrice, 10 ** 18, idealPrice);
                sqrtPriceX96 = PriceMath.getSqrtRatioAtPrice(
                    longShort.collateralToken(),
                    longShort.longToken(),
                    price
                );
                zeroForOne = currentPriceX96 > sqrtPriceX96 ? true : false;
            }

            vault.rebalance(
                PriceMath.getTickAtSqrtRatioWithFee(sqrtPriceAX96, 200),
                PriceMath.getTickAtSqrtRatioWithFee(sqrtPriceBX96, 200),
                0,
                10000,
                zeroForOne
            );
        }

        lastRebalanced[lsp] = block.timestamp;
    }

    function getIdealPrice(address lsp) public view returns (uint256 collateralPrice, uint256 idealPrice) {
        address asset = ILongShortPair(lsp).collateralToken();
        uint256 expiryTimestamp = uint256(ILongShortPair(lsp).expirationTimestamp());
        collateralPrice = uint256(oracles[asset].latestAnswer());

        if (block.timestamp > expiryTimestamp) {
            return (collateralPrice, 0);
        }
        uint256 secondsToExpiry = expiryTimestamp - block.timestamp;
        uint256 annualTime = FullMath.mulDiv(secondsToExpiry, 10 ** 18, 31556952);

        idealPrice = blackScholes.getCallPrice(
            collateralPrice,
            coveredCall.longShortPairStrikePrices(lsp),
            volatility[asset],
            annualTime,
            0
        );
    }

    function getIdealPriceWithAll(address lsp) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        address asset = ILongShortPair(lsp).collateralToken();
        uint256 expiryTimestamp = uint256(ILongShortPair(lsp).expirationTimestamp());
        uint256 collateralPrice = uint256(oracles[asset].latestAnswer());
        collateralPrice = FullMath.mulDiv(collateralPrice, 10 ** 18, 10 ** 8);

        if (block.timestamp > expiryTimestamp) {
            return (collateralPrice, 0, 0, 0, 0, 0);
        }
        uint256 secondsToExpiry = expiryTimestamp - block.timestamp;
        uint256 annualTime = FullMath.mulDiv(secondsToExpiry, 10 ** 18, 31556952);

        uint256 strike = coveredCall.longShortPairStrikePrices(lsp);
        strike = FullMath.mulDiv(strike, 10 ** 18, 10 ** 8);

        uint256 idealPrice = blackScholes.getCallPrice(
            collateralPrice,
            strike,
            volatility[asset],
            annualTime,
            0
        );

        return (collateralPrice, idealPrice, secondsToExpiry, annualTime, volatility[asset], strike);
    }

    function getSqrtPricesX96(address lsp, uint256 percent) public view returns (
        uint160 sqrtPriceX96,
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96
    ) {
        ILongShortPair longShort = ILongShortPair(lsp);

        (uint256 collateralPrice, uint256 idealPrice) = getIdealPrice(lsp);
        uint256 price = FullMath.mulDiv(idealPrice, 10 ** 18, collateralPrice);
        sqrtPriceX96 = PriceMath.getSqrtRatioAtPrice(
            longShort.longToken(),
            longShort.collateralToken(),
            price
        );

        uint256 upperPrice = price + price.percentMul(percent);
        uint256 lowerPrice = price - price.percentMul(percent);

        sqrtPriceAX96 = PriceMath.getSqrtRatioAtPrice(
            longShort.longToken(),
            longShort.collateralToken(),
            lowerPrice
        );

        sqrtPriceBX96 = PriceMath.getSqrtRatioAtPrice(
            longShort.longToken(),
            longShort.collateralToken(),
            upperPrice
        );

        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }
    }

    function setVolatility(address asset, uint256 vol) external onlyOwner {
        volatility[asset] = vol;
    }

    function setOracle(address asset, AggregatorInterface chainlink) external onlyOwner {
        oracles[asset] = chainlink;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IOptionFactory {
    function collaterals(address) external view returns (DataTypes.Collateral memory);
    function lsps(address) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.12;

interface IBlackScholes {
    function getCallPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);

    function getPutPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILiquidityManager {
    function vaults(address) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ILongShortPair } from "./LongShortPair.sol";
import { IUniswapV3Factory } from "./UniswapV3Factory.sol";
import { IUniswapV3Pool } from "./UniswapV3Pool.sol";

interface ILiquidityVault {
    function initialize(
        ILongShortPair pair,
        IUniswapV3Factory uniV3Factory,
        uint160 sqrtPriceX96,
        uint160 sqrtPriceA,
        uint160 sqrtPriceB,
        address newOwner,
        address newRebalancer
    ) external;

    function rebalance(
        int24 newLowerTick,
        int24 newUpperTick,
        uint160 swapThresholdPrice,
        uint256 swapAmountBPS,
        bool zeroForOne
    ) external;

    function pool() external view returns (IUniswapV3Pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILongShortPair {
    function longToken() external view returns (address);
    
    function shortToken() external view returns (address);

    function collateralToken() external view returns (address);

    function expirationTimestamp() external view returns (uint64);

    function create(uint256 tokensToCreate) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV3Pool {
    function initialize(uint160 sqrtPriceX96) external;

    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );

    function positions(bytes32 key) external view returns (
        uint128 _liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    function ticks(int24 tick) external view returns (
        uint128 liquidityGross,
        int128 liquidityNet,
        uint256 feeGrowthOutside0X128,
        uint256 feeGrowthOutside1X128,
        int56 tickCumulativeOutside,
        uint160 secondsPerLiquidityOutsideX128,
        uint32 secondsOutside,
        bool initialized
    );

    function feeGrowthGlobal0X128() external view returns (uint256);

    function feeGrowthGlobal1X128() external view returns (uint256);

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes memory data
    ) external returns (uint256 amount0, uint256 amount1);

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoveredCallFinancialLibrary {
    /**
     * @notice Enables any address to set the strike price for an associated LSP.
     * @param LongShortPair address of the LSP.
     * @param strikePrice the strike price for the covered call for the associated LSP.
     * @dev Note: a) Any address can set the initial strike price b) A strike price cannot be 0.
     * c) A strike price can only be set once to prevent the deployer from changing the strike after the fact.
     * d) For safety, a strike price should be set before depositing any synthetic tokens in a liquidity pool.
     * e) financialProduct must expose an expirationTimestamp method to validate it is correctly deployed.
     */
    function setLongShortPairParameters(address LongShortPair, uint256 strikePrice) external;

    function longShortPairStrikePrices(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos;
        unchecked {
            twos = (0 - denominator) & denominator;
        }

        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import { TickMath } from "./TickMath.sol";
import { UnsafeMath } from "./UnsafeMath.sol";

/// @title Math library for computing sqrt prices from price and vice versa.
/// @notice Computes sqrt price for price.
library PriceMath {
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Calculates the sqrt ratio for given price
    /// @param token0 The address of token0
    /// @param token1 The address of token1
    /// @param price The amount with decimals of token1 for 1 token0
    /// @return sqrtPriceX96 The greatest tick for which the ratio is less than or equal to the input ratio
    function getSqrtRatioAtPrice(
        address token0,
        address token1,
        uint256 price
    ) internal pure returns (uint160 sqrtPriceX96) {
        uint256 base = 1e18;
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
            (base, price) = (price, base);
        }
        uint256 priceX96 = (price << 192) / base;
        sqrtPriceX96 = uint160(sqrt(priceX96));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param token0 The address of token0
    /// @param token1 The address of token1
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the price as a Q64.96
    /// @return price The amount with decimals of token1 for 1 token0
    function getPriceAtSqrtRatio(
        address token0,
        address token1,
        uint160 sqrtPriceX96
    ) internal pure returns (uint256 price) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96 >= TickMath.MIN_SQRT_RATIO &&
            sqrtPriceX96 < TickMath.MAX_SQRT_RATIO,
            'R'
        );

        uint256 base = 1e18;
        uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        if (token0 > token1) {
            price = UnsafeMath.divRoundingUp(base << 192, priceX96);
        } else {
            price = (priceX96 * base) >> 192;
        }
    }

    function getTickAtSqrtRatioWithFee(
        uint160 sqrtPriceX96,
        int24 _tickSpacing
    ) internal pure returns (int24) {
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        int24 tickCorrection = tick % _tickSpacing;
        return tick - tickCorrection;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/
library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    /**
    * @dev Executes a percentage multiplication
    * @param value The value of which the percentage needs to be calculated
    * @param percentage The percentage of the value to be calculated
    * @return The percentage of value
    **/
   function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
       if (value == 0 || percentage == 0) {
           return 0;
        }

        require(value <= (type(uint256).max - HALF_PERCENT) / percentage, "PercentageMath::mul-overflow");

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
   }

   /**
    * @dev Executes a percentage division
    * @param value The value of which the percentage needs to be calculated
    * @param percentage The percentage of the value to be calculated
    * @return The value divided the percentage
    **/
    function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
        require(percentage != 0, "PercentageMath::div-by-zero");

        uint256 halfPercentage = percentage / 2;

        require(value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR, "PercentageMath::div-overflow");

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DataTypes {
    struct Collateral {
        bool isActive;
        bytes32 priceIdentifier;
        string name;
        string symbol;
    }

    struct Option {
        uint64 expiry;
        uint256 strikePrice;
        address collateral;
        address lsp;
        address longToken;
        address shortToken;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= 887272, 'T'); // MAX_TICK

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

