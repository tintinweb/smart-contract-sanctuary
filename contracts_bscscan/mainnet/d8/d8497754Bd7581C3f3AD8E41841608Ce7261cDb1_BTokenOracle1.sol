// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import './IERC20.sol';
import './IUniswapV2Pair.sol';

// Price oracle using only one swap pair
contract BTokenOracle1 is IOracle {

    uint256 constant Q112 = 2**112;

    address public immutable pair;
    address public immutable quote;
    address public immutable base;
    uint256 public immutable qDecimals;
    uint256 public immutable bDecimals;
    bool    public immutable isQuoteToken0;

    uint256 public priceCumulativeLast1;
    uint256 public priceCumulativeLast2;
    uint256 public timestampLast1;
    uint256 public timestampLast2;

    constructor (address pair_, address quote_, address base_, bool isQuoteToken0_) {
        pair = pair_;
        quote = quote_;
        base = base_;
        qDecimals = IERC20(quote_).decimals();
        bDecimals = IERC20(base_).decimals();
        isQuoteToken0 = isQuoteToken0_;

        IUniswapV2Pair p = IUniswapV2Pair(pair_);
        priceCumulativeLast2 = isQuoteToken0_ ? p.price0CumulativeLast() : p.price1CumulativeLast();
        (, , timestampLast2) = p.getReserves();
    }

    function getPrice() external override returns (uint256) {
        IUniswapV2Pair p = IUniswapV2Pair(pair);
        uint256 reserveQ;
        uint256 reserveB;
        uint256 timestamp;

        if (isQuoteToken0) {
            (reserveQ, reserveB, timestamp) = p.getReserves();
        } else {
            (reserveB, reserveQ, timestamp) = p.getReserves();
        }

        if (timestamp != timestampLast2) {
            priceCumulativeLast1 = priceCumulativeLast2;
            timestampLast1 = timestampLast2;
            priceCumulativeLast2 = isQuoteToken0 ? p.price0CumulativeLast() : p.price1CumulativeLast();
            timestampLast2 = timestamp;
        }

        uint256 price;
        if (timestampLast1 != 0) {
            // TWAP
            price = (priceCumulativeLast2 - priceCumulativeLast1) / (timestampLast2 - timestampLast1) * 10**(18 + qDecimals - bDecimals) / Q112;
        } else {
            // Spot
            // this price will only be used when BToken is newly added to pool
            // since the liquidity for newly added BToken is always zero,
            // there will be no manipulation consequences for this price
            price = reserveB * 10**(18 + qDecimals - bDecimals) / reserveQ;
        }

        return price;
    }

}