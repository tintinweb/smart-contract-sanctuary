// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./UniswapV2Library.sol";
import "./UniswapV2OracleLibrary.sol";

contract PriceOracle {
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    address internal immutable _uniswapFactory;
    address internal immutable _weth;

    struct PriceObservation {
        uint32 timestamp;
        uint224 priceCumulativeLast;
        uint224 ethPriceCumulativeLast;
    }

    mapping(address => PriceObservation) public lastUpdatedObservation;
    mapping(address => address) public feeds;

    constructor(address uniswapFactory, address weth) public {
        _uniswapFactory = uniswapFactory;
        _weth = weth;
    }

    modifier valueNotNullCoin(address tokenAddress) {
        require(feeds[tokenAddress] != address(0), "key not present");
        _;
    }

    function addInstancesOfCoin(address tokenAddress, address aggregatorAddress)
        public
    {
        require(
            aggregatorAddress != address(0),
            "Aggregator address shoudn't not be equal to null"
        );
        require(
            tokenAddress != address(0),
            "Token address shoudn't not be equal to null"
        );
        feeds[tokenAddress] = aggregatorAddress;
    }

    function removeInstanceOfCoin(address tokenAddress)
        public
        valueNotNullCoin(tokenAddress)
    {
        delete feeds[tokenAddress];
    }

    /**
     * @dev Attempts to update the price of `token` and returns a boolean
     * indicating whether it was updated.
     *
     * Note: The price can be updated if there is no observation for the current hour
     * and at least 30 minutes have passed since the last observation.
     */
    function updatePrice(address token)
        public
    {
        PriceObservation memory observation = observeTwoWayPrice(token);
        lastUpdatedObservation[token] = observation;
    }

    function getLatestPriceOfCoin(address token)
        public
        view
        returns (uint256)
    {
        FixedPoint.uq112x112 memory tokenPrice = _getTokenPrice(token);
        return tokenPrice.mul(1000000000000000000).decode144(); //1
    }

    function computeAverageEthForTokens(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint144 /* averageValueInWETH */
        )
    {
        FixedPoint.uq112x112 memory tokenPrice = _getTokenPrice(token);
        return tokenPrice.mul(tokenAmount).decode144();
    }

    function _getTokenPrice(address token)
        internal
        view
        returns (FixedPoint.uq112x112 memory)
    {
        if (token == _weth) {
            return FixedPoint.fraction(1, 1);
        }
        (uint32 timestamp, uint224 priceCumulativeEnd) = observePrice(
            token,
            _weth
        );
        PriceObservation storage previous = lastUpdatedObservation[token];
        return
            UniswapV2OracleLibrary.computeAveragePrice(
                previous.priceCumulativeLast,
                priceCumulativeEnd,
                uint32(timestamp - previous.timestamp)
            );
    }

    function observePrice(address tokenIn, address quoteToken)
        internal
        view
        returns (
            uint32, /* timestamp */
            uint224 /* priceCumulativeLast */
        )
    {
        (address token0, address token1) = UniswapV2Library.sortTokens(
            tokenIn,
            quoteToken
        );
        address pair = UniswapV2Library.calculatePair(
            _uniswapFactory,
            token0,
            token1
        );
        if (token0 == tokenIn) {
            (
                uint256 price0Cumulative,
                uint32 blockTimestamp
            ) = UniswapV2OracleLibrary.currentCumulativePrice0(pair);
            return (blockTimestamp, uint224(price0Cumulative));
        } else {
            (
                uint256 price1Cumulative,
                uint32 blockTimestamp
            ) = UniswapV2OracleLibrary.currentCumulativePrice1(pair);
            return (blockTimestamp, uint224(price1Cumulative));
        }
    }

    function observeTwoWayPrice(address token)
        internal
        view
        returns (PriceObservation memory)
    {
        (address token0, address token1) = UniswapV2Library.sortTokens(
            token,
            _weth
        );
        address pair = UniswapV2Library.calculatePair(
            _uniswapFactory,
            token0,
            token1
        );
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        if (token0 == token) {
            return
                PriceObservation({
                    timestamp: blockTimestamp,
                    priceCumulativeLast: uint224(price0Cumulative),
                    ethPriceCumulativeLast: uint224(price1Cumulative)
                });
        } else {
            return
                PriceObservation({
                    timestamp: blockTimestamp,
                    priceCumulativeLast: uint224(price1Cumulative),
                    ethPriceCumulativeLast: uint224(price0Cumulative)
                });
        }
    }
}