// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IExtendedAggregator.sol";
import "../misc/SafeMath.sol";
import "../misc/Math.sol";

/** @title UniswapV2PriceProvider
 * @notice Price provider for a Uniswap V2 pair token
 * It calculates the price using Chainlink as an external price source and the pair's tokens reserves using the weighted arithmetic mean formula.
 * If there is a price deviation, instead of the reserves, it uses a weighted geometric mean with the constant invariant K.
 */

contract UniswapV2PriceProvider is IExtendedAggregator {
    using SafeMath for uint256;

    IUniswapV2Pair public immutable pair;
    address[] public tokens;
    bool[] public isPeggedToEth;
    uint8[] public decimals;
    IPriceOracle immutable priceOracle;
    uint256 public immutable maxPriceDeviation;

    /**
     * UniswapV2PriceProvider constructor.
     * @param _pair Uniswap V2 pair address.
     * @param _isPeggedToEth For each token, true if it is pegged to ETH.
     * @param _decimals Number of decimals for each token.
     * @param _priceOracle Aave price oracle.
     * @param _maxPriceDeviation Threshold of spot prices deviation: 10ˆ16 represents a 1% deviation.
     */
    constructor(
        IUniswapV2Pair _pair,
        bool[] memory _isPeggedToEth,
        uint8[] memory _decimals,
        IPriceOracle _priceOracle,
        uint256 _maxPriceDeviation
    ) public {
        require(_isPeggedToEth.length == 2, "ERR_INVALID_PEGGED_LENGTH");
        require(_decimals.length == 2, "ERR_INVALID_DECIMALS_LENGTH");
        require(
            _decimals[0] <= 18 && _decimals[1] <= 18,
            "ERR_INVALID_DECIMALS"
        );
        require(
            address(_priceOracle) != address(0),
            "ERR_INVALID_PRICE_PROVIDER"
        );
        require(_maxPriceDeviation < Math.BONE, "ERR_INVALID_PRICE_DEVIATION");

        pair = _pair;
        //Get tokens
        tokens.push(_pair.token0());
        tokens.push(_pair.token1());
        isPeggedToEth = _isPeggedToEth;
        decimals = _decimals;
        priceOracle = _priceOracle;
        maxPriceDeviation = _maxPriceDeviation;
    }

    /**
     * Returns the token balance in ethers by multiplying its reserves with its price in ethers.
     * @param index Token index.
     * @param reserve Token reserves.
     */
    function getEthBalanceByToken(uint256 index, uint112 reserve)
        internal
        view
        returns (uint256)
    {
        uint256 pi =
            isPeggedToEth[index]
                ? Math.BONE
                : uint256(priceOracle.getAssetPrice(tokens[index]));
        require(pi > 0, "ERR_NO_ORACLE_PRICE");
        uint256 missingDecimals = uint256(18).sub(decimals[index]);
        uint256 bi = uint256(reserve).mul(10**(missingDecimals));
        return Math.bmul(bi, pi);
    }

    /**
     * Returns true if there is a price deviation.
     * @param ethTotal_0 Total eth for token 0.
     * @param ethTotal_1 Total eth for token 1.
     */
    function hasDeviation(uint256 ethTotal_0, uint256 ethTotal_1)
        internal
        view
        returns (bool)
    {
        //Check for a price deviation
        uint256 price_deviation = Math.bdiv(ethTotal_0, ethTotal_1);
        if (
            price_deviation > (Math.BONE.add(maxPriceDeviation)) ||
            price_deviation < (Math.BONE.sub(maxPriceDeviation))
        ) {
            return true;
        }
        price_deviation = Math.bdiv(ethTotal_1, ethTotal_0);
        if (
            price_deviation > (Math.BONE.add(maxPriceDeviation)) ||
            price_deviation < (Math.BONE.sub(maxPriceDeviation))
        ) {
            return true;
        }
        return false;
    }

    /**
     * Calculates the price of the pair token using the formula of arithmetic mean.
     * @param ethTotal_0 Total eth for token 0.
     * @param ethTotal_1 Total eth for token 1.
     */
    function getArithmeticMean(uint256 ethTotal_0, uint256 ethTotal_1)
        internal
        view
        returns (uint256)
    {
        uint256 totalEth = ethTotal_0 + ethTotal_1;
        return Math.bdiv(totalEth, getTotalSupplyAtWithdrawal());
    }

    /**
     * Calculates the price of the pair token using the formula of weighted geometric mean.
     * @param ethTotal_0 Total eth for token 0.
     * @param ethTotal_1 Total eth for token 1.
     */
    function getWeightedGeometricMean(uint256 ethTotal_0, uint256 ethTotal_1)
        internal
        view
        returns (uint256)
    {
        uint256 square = Math.bsqrt(Math.bmul(ethTotal_0, ethTotal_1), true);
        return
            Math.bdiv(
                Math.bmul(Math.TWO_BONES, square),
                getTotalSupplyAtWithdrawal()
            );
    }

    /**
     * Returns Uniswap V2 pair total supply at the time of withdrawal.
     */
    function getTotalSupplyAtWithdrawal()
        private
        view
        returns (uint256 totalSupply)
    {
        totalSupply = pair.totalSupply();
        address feeTo =
            IUniswapV2Factory(IUniswapV2Pair(pair).factory()).feeTo();
        bool feeOn = feeTo != address(0);
        if (feeOn) {
            uint256 kLast = IUniswapV2Pair(pair).kLast();
            if (kLast != 0) {
                (uint112 reserve_0, uint112 reserve_1, ) = pair.getReserves();
                uint256 rootK =
                    Math.bsqrt(uint256(reserve_0).mul(reserve_1), false);
                uint256 rootKLast = Math.bsqrt(kLast, false);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    totalSupply = totalSupply.add(liquidity);
                }
            }
        }
    }

    /**
     * Returns Uniswap V2 pair address.
     */
    function getPair() external view returns (IUniswapV2Pair) {
        return pair;
    }

    /**
     * Returns all tokens.
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @dev Returns the LP shares token
     * @return address of the LP shares token
     */
    function getToken() external view override returns (address) {
        return address(pair);
    }

    /**
     * @dev Returns token type for categorization
     * @return uint256 1 = Simple (Native or plain ERC20 tokens like DAI), 2 = Complex (LP Tokens, Staked tokens)
     */
    function getTokenType()
        external
        pure
        override
        returns (IExtendedAggregator.TokenType)
    {
        return IExtendedAggregator.TokenType.Complex;
    }

    /**
     * @dev Returns the number of tokens that composes the LP shares
     * @return address[] memory of token addresses
     */
    function getSubTokens() external view override returns (address[] memory) {
        return tokens;
    }

    /**
     * @dev Returns the platform id to categorize the price aggregator
     * @return uint256 1 = Uniswap, 2 = Balancer
     */
    function getPlatformId()
        external
        pure
        override
        returns (IExtendedAggregator.PlatformId)
    {
        return IExtendedAggregator.PlatformId.Uniswap;
    }

    /**
     * @dev Returns the pair's token price.
     *   It calculates the price using Chainlink as an external price source and the pair's tokens reserves using the arithmetic mean formula.
     *   If there is a price deviation, instead of the reserves, it uses a weighted geometric mean with constant invariant K.
     * @return int256 price
     */
    function latestAnswer() external view override returns (int256) {
        //Get token reserves in ethers
        (uint112 reserve_0, uint112 reserve_1, ) = pair.getReserves();
        uint256 ethTotal_0 = getEthBalanceByToken(0, reserve_0);
        uint256 ethTotal_1 = getEthBalanceByToken(1, reserve_1);

        if (hasDeviation(ethTotal_0, ethTotal_1)) {
            //Calculate the weighted geometric mean
            return int256(getWeightedGeometricMean(ethTotal_0, ethTotal_1));
        } else {
            //Calculate the arithmetic mean
            return int256(getArithmeticMean(ethTotal_0, ethTotal_1));
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IUniswapV2Pair {
  function totalSupply() external view returns (uint256);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function kLast() external view returns (uint256);

  function factory() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IUniswapV2Factory {
  function feeTo() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracle {
  /***********
    @dev returns the asset price in ETH
     */
  function getAssetPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.6.12;

interface IExtendedAggregator {
    enum TokenType {Invalid, Simple, Complex}

    enum PlatformId {Invalid, Simple, Uniswap, Balancer}

    /**
     * @dev Returns the LP shares token
     * @return address of the LP shares token
     */
    function getToken() external view returns (address);

    /**
     * @dev Returns token type for categorization
     * @return uint256 1 = Simple (Native or plain ERC20 tokens like DAI), 2 = Complex (LP Tokens, Staked tokens)
     */
    function getTokenType() external pure returns (TokenType);

    /**
     * @dev Returns the number of tokens that composes the LP shares
     * @return address[] memory of token addresses
     */
    function getSubTokens() external view returns (address[] memory);

    /**
     * @dev Returns the platform id to categorize the price aggregator
     * @return uint256 1 = Uniswap, 2 = Balancer
     */
    function getPlatformId() external pure returns (PlatformId);

    /**
     * @dev Returns the latest price
     * @return int256 price
     */
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, 'ds-math-add-overflow');
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, 'ds-math-sub-underflow');
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

// a library for performing various math operations

library Math {
  uint256 public constant BONE = 10**18;
  uint256 public constant TWO_BONES = 2 * 10**18;

  /**
   * @notice Returns the square root of an uint256 x using the Babylonian method
   * @param y The number to calculate the sqrt from
   * @param bone True when y has 18 decimals
   */
  function bsqrt(uint256 y, bool bone) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        if (bone) {
          x = (bdiv(y, x) + x) / 2;
        } else {
          x = (y / x + x) / 2;
        }
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  function bmul(
    uint256 a,
    uint256 b //Bone mul
  ) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, 'ERR_MUL_OVERFLOW');
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, 'ERR_MUL_OVERFLOW');
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(
    uint256 a,
    uint256 b //Bone div
  ) internal pure returns (uint256) {
    require(b != 0, 'ERR_DIV_ZERO');
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, 'ERR_DIV_INTERNAL'); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, 'ERR_DIV_INTERNAL'); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }
}