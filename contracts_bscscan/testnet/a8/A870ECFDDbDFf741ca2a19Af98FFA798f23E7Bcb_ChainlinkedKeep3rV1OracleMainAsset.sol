/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: bsl-1.1

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/

pragma solidity ^0.6.8;


/**
 * @title OracleSimple
 **/
abstract contract OracleSimple {
    // returns Q112-encoded value
    function assetToUsd(address asset, uint amount) public virtual view returns (uint) {}
}


/**
 * @title OracleSimplePoolToken
 **/
abstract contract OracleSimplePoolToken is OracleSimple {
    ChainlinkedOracleSimple public oracleMainAsset;
}


/**
 * @title ChainlinkedOracleSimple
 **/
abstract contract ChainlinkedOracleSimple is OracleSimple {
    address public WETH;
    // returns ordinary value
    function ethToUsd(uint ethAmount) public virtual view returns (uint) {}

    // returns Q112-encoded value
    function assetToEth(address asset, uint amount) public virtual view returns (uint) {}
}

// File: localhost/helpers/FixedPoint.sol

pragma solidity ^0.6.8;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// File: localhost/helpers/UniswapV2OracleLibrary.sol

pragma solidity ^0.6.8;




// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IPancakePair(pair).price0CumulativeLast();
        price1Cumulative = IPancakePair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/
pragma solidity ^0.6.8;



interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


pragma solidity ^0.6.8;




library PancakeV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash of Pancake
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: localhost/helpers/IUniswapV2Factory.sol

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/
pragma solidity ^0.6.8;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// File: localhost/helpers/Keep3rV1OracleAbstract.sol

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

abstract contract Keep3rV1OracleAbstract {
    struct Observation {
        uint timestamp;
        uint priceCumulative;
    }
    mapping(address => Observation[]) public observations;

    function current(address tokenIn, uint amountIn, address tokenOut) external virtual view returns (uint amountOut);
    function observationLength(address pair) external virtual view returns (uint);
    function lastObservation(address pair) public virtual view returns (Observation memory);
}

// File: localhost/helpers/AggregatorInterface.sol

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/
pragma solidity ^0.6.8;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256); // deprecated
    function latestTimestamp() external view returns (uint256); // deprecated
    function latestRound() external view returns (uint256);
    function decimals() external view returns (uint256);

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// File: localhost/helpers/SafeMath.sol

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/
pragma solidity ^0.6.8;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: localhost/impl/ChainlinkedKeep3rV1OracleMainAsset.sol

/*
    Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
    This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; Contact [email protected] 
*/
pragma solidity ^0.6.8;









/**
 * @title ChainlinkedKeep3rV1OracleMainAsset
 * @dev Calculates the USD price of desired tokens
 **/
contract ChainlinkedKeep3rV1OracleMainAsset is ChainlinkedOracleSimple {
    using SafeMath for uint;

    uint public immutable minObservationTimeBack = 1.5 hours;
    uint public immutable maxObservationTimeBack = 2.5 hours;

    uint public immutable Q112 = 2 ** 112;

    uint public immutable ETH_USD_DENOMINATOR = 1e8;

    AggregatorInterface public immutable ethUsdChainlinkAggregator;

    Keep3rV1OracleAbstract public immutable keep3rV1Oracle;

    IUniswapV2Factory public immutable uniswapFactory;

    constructor(
        IUniswapV2Factory _uniFactory,
        Keep3rV1OracleAbstract _keep3rV1Oracle,
        address weth,
        AggregatorInterface chainlinkAggregator
    )
    public
    {
        require(address(_uniFactory) != address(0), "CryptoPeso protocol : ZERO_ADDRESS");
        require(address(_keep3rV1Oracle) != address(0), "CryptoPeso protocol : ZERO_ADDRESS");
        require(weth != address(0), "CryptoPeso protocol : ZERO_ADDRESS");
        require(address(chainlinkAggregator) != address(0), "CryptoPeso protocol : ZERO_ADDRESS");

        uniswapFactory = _uniFactory;
        keep3rV1Oracle = _keep3rV1Oracle;
        WETH = weth;
        ethUsdChainlinkAggregator = chainlinkAggregator;
    }

    /**
     * @notice {Token}/WETH pair must be registered on Uniquote
     * @param asset The token address
     * @param amount Amount of tokens
     * @return Q112-encoded price of asset amount in USD
     **/
    function assetToUsd(address asset, uint amount) public override view returns (uint) {
        return ethToUsd(assetToEth(asset, amount));
    }

    /**
     * @notice {asset}/WETH pair must be registered at Keep3rV1Oracle
     * @param asset The token address
     * @param amount Amount of tokens
     * @return Q112-encoded price of asset amount in ETH
     **/
    function assetToEth(address asset, uint amount) public view override returns (uint) {
        if (amount == 0) {
            return 0;
        }
        if (asset == WETH) {
            return amount.mul(Q112);
        }
        return keep3rCurrent(asset, amount);
    }

    /**
     * @notice {asset}/WETH price feed from uniquote.finance, see for more info: https://docs.uniquote.finance/
     * @param tokenIn The token in address
     * @param amountIn Amount of tokens in
     * returns Q112-encoded current asset price in ETH
     **/
    function keep3rCurrent(address tokenIn, uint amountIn) public view returns (uint amountOut) {
        address pair = PancakeV2Library.pairFor(address(uniswapFactory), tokenIn, WETH);
        (address token0,) = PancakeV2Library.sortTokens(tokenIn, WETH);
        uint observationLength = keep3rV1Oracle.observationLength(pair);
        require(observationLength > 1, "CryptoPeso protocol : NOT_ENOUGH_OBSERVATIONS");
        uint observationIndex = observationLength - 1;
        uint timestampObs; uint priceCumulativeObs;
        (timestampObs, priceCumulativeObs) = keep3rV1Oracle.observations(pair, observationIndex);
        (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        while (block.timestamp - timestampObs < minObservationTimeBack) {
            observationIndex -= 1;
            (timestampObs, priceCumulativeObs) = keep3rV1Oracle.observations(pair, observationIndex);
            if (block.timestamp - timestampObs > maxObservationTimeBack) break;
        }
        require(block.timestamp - timestampObs <= maxObservationTimeBack, "CryptoPeso protocol : STALE_PRICES");
        uint timeElapsed = block.timestamp - timestampObs;
        if (token0 == tokenIn) {
            return computeAmountOut(priceCumulativeObs, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(priceCumulativeObs, price1Cumulative, timeElapsed, amountIn);
        }
    }

    // returns Q112-encoded value
    function computeAmountOut(
        uint priceCumulativeStart, uint priceCumulativeEnd,
        uint timeElapsed, uint amountIn
    ) private pure returns (uint) {
        // overflow is desired
        uint avgPrice = (priceCumulativeEnd - priceCumulativeStart) / timeElapsed;
        return avgPrice.mul(amountIn);
    }

    /**
     * @notice ETH/USD price feed from Chainlink, see for more info: https://feeds.chain.link/eth-usd
     * returns The price of given amount of Ether in USD (0 decimals)
     **/
    function ethToUsd(uint ethAmount) public override view returns (uint) {
        require(ethUsdChainlinkAggregator.latestTimestamp() > now - 6 hours, "CryptoPeso protocol : STALE_CHAINLINK_PRICE");
        uint ethUsdPrice = uint(ethUsdChainlinkAggregator.latestAnswer());
        return ethAmount.mul(ethUsdPrice).div(ETH_USD_DENOMINATOR);
    }
}