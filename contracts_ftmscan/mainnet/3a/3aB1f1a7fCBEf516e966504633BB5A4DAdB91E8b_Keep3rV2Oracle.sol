/**
 *Submitted for verification at FtmScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IXToken {
    function decimals() external view returns (uint8);

    function getShareValue() external view returns (uint256);
}

// sliding oracle that uses observations collected to provide moving price averages in the past
contract Keep3rV2Oracle {
    address public constant WFTM_ADDRESS =
        0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    constructor(address _pair, address _xToken) {
        _factory = msg.sender;
        xToken = IXToken(_xToken);
        pair = _pair;
        xTokenUnderlying = IUniswapV2Pair(_pair).token0();
        if (IUniswapV2Pair(_pair).token0() == WFTM_ADDRESS) {
            xTokenUnderlying = IUniswapV2Pair(_pair).token1();
        }
        uint256 _shareValue = 1 ether;
        if (address(_xToken) != address(0)) {
            _shareValue = xToken.getShareValue();
        }
        (, , uint32 timestamp) = IUniswapV2Pair(_pair).getReserves();
        uint112 _price0CumulativeLast = uint112(
            (IUniswapV2Pair(_pair).price0CumulativeLast() * e10) / Q112
        );
        uint112 _price1CumulativeLast = uint112(
            (IUniswapV2Pair(_pair).price1CumulativeLast() * e10) / Q112
        );
        observations[length++] = Observation(
            timestamp,
            _price0CumulativeLast,
            _price1CumulativeLast,
            _shareValue
        );
    }

    struct Observation {
        uint32 timestamp;
        uint112 price0Cumulative;
        uint112 price1Cumulative;
        uint256 xTokenShareValue;
    }

    modifier factory() {
        require(msg.sender == _factory, "!F");
        _;
    }

    Observation[65535] public observations;
    uint16 public length;

    address public xTokenUnderlying;
    address immutable _factory;
    address public immutable pair;
    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint256 constant periodSize = 1200;
    uint256 Q112 = 2**112;
    uint256 e10 = 10**18;

    IXToken xToken;

    // Pre-cache slots for cheaper oracle writes
    function cache(uint256 size) external {
        uint256 _length = length + size;
        for (uint256 i = length; i < _length; i++)
            observations[i].timestamp = 1;
    }

    // update the current feed for free
    function update() external factory returns (bool) {
        return _update();
    }

    function updateable() external view returns (bool) {
        Observation memory _point = observations[length - 1];
        (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();
        uint256 timeElapsed = timestamp - _point.timestamp;
        return timeElapsed > periodSize;
    }

    function _update() internal returns (bool) {
        uint256 _shareValue = 1 ether;
        Observation memory _point = observations[length - 1];
        (, , uint32 timestamp) = IUniswapV2Pair(pair).getReserves();
        uint32 timeElapsed = timestamp - _point.timestamp;
        if (timeElapsed > periodSize) {
            uint112 _price0CumulativeLast = uint112(
                (IUniswapV2Pair(pair).price0CumulativeLast() * e10) / Q112
            );
            uint112 _price1CumulativeLast = uint112(
                (IUniswapV2Pair(pair).price1CumulativeLast() * e10) / Q112
            );
            if (address(xToken) != address(0)) {
                _shareValue = xToken.getShareValue();
                observations[length++] = Observation(
                    timestamp,
                    _price0CumulativeLast,
                    _price1CumulativeLast,
                    _shareValue
                );
            } else {
                observations[length++] = Observation(
                    timestamp,
                    _price0CumulativeLast,
                    _price1CumulativeLast,
                    _shareValue
                );
            }

            return true;
        }
        return false;
    }

    function _computeAmountOut(
        uint256 start,
        uint256 end,
        uint256 elapsed,
        uint256 amountIn,
        uint256 shareValue
    ) internal view returns (uint256 amountOut) {
        uint256 xTokenDecimals = 18;
        if (address(xToken) != address(0)) {
            xTokenDecimals = xToken.decimals();
        }
        amountOut =
            ((amountIn * (end - start) * shareValue) / e10 / uint256(10**(xTokenDecimals)) / elapsed);
    }

    function current(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo) {
        (address token0, ) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);

        Observation memory _observation = observations[length - 1];
        uint256 price0Cumulative = (IUniswapV2Pair(pair)
            .price0CumulativeLast() * e10) / Q112;
        uint256 price1Cumulative = (IUniswapV2Pair(pair)
            .price1CumulativeLast() * e10) / Q112;
        (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();

        // Handle edge cases where we have no updates, will revert on first reading set
        if (timestamp == _observation.timestamp) {
            _observation = observations[length - 2];
        }

        uint256 timeElapsed = timestamp - _observation.timestamp;
        timeElapsed = timeElapsed == 0 ? 1 : timeElapsed;
        uint256 shareValue = 1 ether;
        if (tokenOut != WFTM_ADDRESS) {
            shareValue = _observation.xTokenShareValue;
        }
        if (token0 == tokenIn) {
            amountOut = _computeAmountOut(
                _observation.price0Cumulative,
                price0Cumulative,
                timeElapsed,
                amountIn,
                shareValue
            );
        } else {
            amountOut = _computeAmountOut(
                _observation.price1Cumulative,
                price1Cumulative,
                timeElapsed,
                amountIn,
                shareValue
            );
        }
        lastUpdatedAgo = timeElapsed;
    }

    function quote(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 points
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAgo) {
        (address token0, ) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);

        uint256 priceAverageCumulative = 0;
        uint256 i = length - 1 - points;
        Observation memory currentObservation;
        Observation memory nextObservation;
        uint256 nextIndex = 0;
        for (; i < length - 1; i++) {
            nextIndex = i + 1;
            currentObservation = observations[i];
            uint256 shareValue = 1 ether;
            if (tokenOut != WFTM_ADDRESS) {
                shareValue = currentObservation.xTokenShareValue;
            }
            nextObservation = observations[nextIndex];
            if (token0 == tokenIn) {
                priceAverageCumulative += _computeAmountOut(
                    currentObservation.price0Cumulative,
                    nextObservation.price0Cumulative,
                    nextObservation.timestamp - currentObservation.timestamp,
                    amountIn,
                    shareValue
                );
            } else {
                priceAverageCumulative += _computeAmountOut(
                    currentObservation.price1Cumulative,
                    nextObservation.price1Cumulative,
                    nextObservation.timestamp - currentObservation.timestamp,
                    amountIn,
                    shareValue
                );}
        }
        amountOut = priceAverageCumulative / points;

        (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();
        lastUpdatedAgo = timestamp - nextObservation.timestamp;
    }

    function sample(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 points,
        uint256 window
    ) external view returns (uint256[] memory prices, uint256 lastUpdatedAgo) {
        prices = new uint256[](points);
        uint256 i = length - 1 - (points * window);
        uint256 _index = 0;

        Observation memory nextObservation;
        for (; i < length - 1; i += window) {
            Observation memory currentObservation;
            currentObservation = observations[i];
            uint256 shareValue = 1 ether;
            if (tokenOut != WFTM_ADDRESS) {
                shareValue = currentObservation.xTokenShareValue;
            }
            nextObservation = observations[i + window];
            (address token0, ) = tokenIn < tokenOut
                ? (tokenIn, tokenOut)
                : (tokenOut, tokenIn);
            if (token0 == tokenIn) {
                prices[_index] = _computeAmountOut(
                    currentObservation.price0Cumulative,
                    nextObservation.price0Cumulative,
                    nextObservation.timestamp - currentObservation.timestamp,
                    amountIn,
                    shareValue
                );
            } else {
                prices[_index] = _computeAmountOut(
                    currentObservation.price1Cumulative,
                    nextObservation.price1Cumulative,
                    nextObservation.timestamp - currentObservation.timestamp,
                    amountIn,
                    shareValue
                );
            }
            _index = _index + 1;
        }

        (, , uint256 timestamp) = IUniswapV2Pair(pair).getReserves();
        lastUpdatedAgo = timestamp - nextObservation.timestamp;
    }
}