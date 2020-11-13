// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IUnifiedStableFarming.sol";

contract UnifiedStableFarming is IUnifiedStableFarming {
    address
        private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256[] private _percentage;

    constructor(uint256[] memory percentage) {
        assert(percentage.length == 2);
        _percentage = percentage;
    }

    function percentage() public override view returns(uint256[] memory) {
        return _percentage;
    }

    //Earn pumping uSD - Means swap a chosen stableCoin for uSD, then burn the difference of uSD to obtain a greater uSD value in Uniswap Pool tokens
    function earnByPump(
        address stableCoinAddress,
        uint256 pairIndex,
        uint256 pairAmount,
        uint256 amount0,
        uint256 amount1,
        address tokenAddress,
        uint256 tokenValue
    ) public override {
        require(
            _isValidPairToken(stableCoinAddress, tokenAddress),
            "Choosen token address is not in a valid pair"
        );
        _transferToMeAndCheckAllowance(
            tokenAddress,
            tokenValue,
            UNISWAP_V2_ROUTER
        );
        uint256 stableCoinAmount = _swap(
            tokenAddress,
            stableCoinAddress,
            tokenValue,
            address(this)
        );
        (uint256 return0, uint256 return1) = IStableCoin(stableCoinAddress)
            .burn(pairIndex, pairAmount, amount0, amount1);
        (address token0, address token1, ) = _getPairData(
            stableCoinAddress,
            pairIndex
        );
        require(
            _isPumpOK(
                stableCoinAddress,
                tokenAddress,
                tokenValue,
                token0,
                return0,
                token1,
                return1,
                stableCoinAmount
            ),
            "Values are not coherent"
        );
        _flushToSender(token0, token1, stableCoinAddress);
    }

    function _isPumpOK(
        address stableCoinAddress,
        address tokenAddress,
        uint256 tokenValue,
        address token0,
        uint256 return0,
        address token1,
        uint256 return1,
        uint256 stableCoinAmount
    ) private view returns (bool) {
        IStableCoin stableCoin = IStableCoin(stableCoinAddress);
        uint256 cumulative = stableCoin.fromTokenToStable(
            tokenAddress,
            tokenValue
        );
        cumulative += stableCoin.fromTokenToStable(token0, return0);
        cumulative += stableCoin.fromTokenToStable(token1, return1);
        uint256 percentage = (cumulative * _percentage[0]) / _percentage[1];
        uint256 cumulativePlus = cumulative + percentage;
        uint256 cumulativeMinus = cumulative - percentage;
        return
            stableCoinAmount >= cumulativeMinus &&
            stableCoinAmount <= cumulativePlus;
    }

    //Earn dumping uSD - Means mint uSD then swap uSD for the chosen Uniswap Pool tokens
    function earnByDump(
        address stableCoinAddress,
        uint256 pairIndex,
        uint256 amount0,
        uint256 amount1,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256[] memory tokenIndices,
        uint256[] memory stableCoinAmounts
    ) public override {
        require(
            tokenIndices.length > 0 && tokenIndices.length <= 2,
            "You must choose at least one of the two Tokens"
        );
        require(
            tokenIndices.length == stableCoinAmounts.length,
            "Token Indices and StableCoin Amounts must have the same length"
        );
        (address token0, address token1) = _prepareForDump(
            stableCoinAddress,
            pairIndex,
            amount0,
            amount1
        );
        IStableCoin(stableCoinAddress).mint(
            pairIndex,
            amount0,
            amount1,
            amount0Min,
            amount1Min
        );
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            _swap(
                stableCoinAddress,
                tokenIndices[i] == 0 ? token0 : token1,
                stableCoinAmounts[i],
                msg.sender
            );
        }
        _flushToSender(token0, token1, stableCoinAddress);
    }

    function _transferTokens(
        address stableCoinAddress,
        uint256 pairIndex,
        uint256 amount0,
        uint256 amount1
    ) private {
        (address token0, address token1, ) = _getPairData(
            stableCoinAddress,
            pairIndex
        );
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
    }

    function _getPairData(address stableCoinAddress, uint256 pairIndex)
        private
        view
        returns (
            address token0,
            address token1,
            address pairAddress
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(
            pairAddress = IStableCoin(stableCoinAddress)
                .allowedPairs()[pairIndex]
        );
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function _checkAllowance(
        address tokenAddress,
        uint256 value,
        address spender
    ) private {
        IERC20 token = IERC20(tokenAddress);
        if (token.allowance(address(this), spender) <= value) {
            token.approve(spender, value);
        }
    }

    function _transferToMeAndCheckAllowance(
        address tokenAddress,
        uint256 value,
        address spender
    ) private {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), value);
        _checkAllowance(tokenAddress, value, spender);
    }

    function _prepareForDump(
        address stableCoinAddress,
        uint256 pairIndex,
        uint256 amount0,
        uint256 amount1
    ) private returns (address token0, address token1) {
        (token0, token1, ) = _getPairData(stableCoinAddress, pairIndex);
        _transferToMeAndCheckAllowance(token0, amount0, stableCoinAddress);
        _transferToMeAndCheckAllowance(token1, amount1, stableCoinAddress);
    }

    function _flushToSender(
        address token0,
        address token1,
        address token2
    ) private {
        _flushToSender(token0);
        _flushToSender(token1);
        _flushToSender(token2);
    }

    function _flushToSender(address tokenAddress) private {
        if (tokenAddress == address(0)) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceOf = token.balanceOf(address(this));
        if (balanceOf > 0) {
            token.transfer(msg.sender, balanceOf);
        }
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address receiver
    ) private returns (uint256) {
        _checkAllowance(tokenIn, amountIn, UNISWAP_V2_ROUTER);

        IUniswapV2Router uniswapV2Router = IUniswapV2Router(UNISWAP_V2_ROUTER);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return
            uniswapV2Router.swapExactTokensForTokens(
                amountIn,
                uniswapV2Router.getAmountsOut(amountIn, path)[1],
                path,
                receiver,
                block.timestamp + 1000
            )[1];
    }

    function _isValidPairToken(address stableCoinAddress, address tokenAddress)
        private
        view
        returns (bool)
    {
        address[] memory allowedPairs = IStableCoin(stableCoinAddress)
            .allowedPairs();
        for (uint256 i = 0; i < allowedPairs.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(allowedPairs[i]);
            if (pair.token0() == tokenAddress) {
                return true;
            }
            if (pair.token1() == tokenAddress) {
                return true;
            }
        }
        return false;
    }
}
