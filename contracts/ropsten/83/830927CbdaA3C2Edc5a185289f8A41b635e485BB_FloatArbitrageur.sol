// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IAuctionHouse.sol";
import "./IAuction.sol";
import "./IUniswapV2Router01.sol";
import "./Arbitrageur.sol";
import "./IERC20.sol";

contract FloatArbitrageur is Arbitrageur, IAuction {

    address private sushi;
    address private auction;
    address private weth;
    address private float;
    address private bank;
    
    uint8 public slippageDecimals = 4;
    uint8 public auctionDuration = 149;

    Cases private stabilizationCase;

    event Arbitrage(
        uint256 round,
        uint256 step,
        uint256 tradeSizeEth,
        uint256 tradeSizeFloat,
        uint256 profit
    );

    event ModifyParameter(
        bytes32 name,
        uint256 value
    );

    modifier onlyDuringAuction() {
        require(
            IAuctionHouse(auction).step() < auctionDuration,
            "FloatArbitrageur/AuctionInactive"
        );
        _;
    }

    constructor(
        address _sushi,
        address _auction,
        address _weth,
        address _float,
        address _bank
    ) {
        require(
            _sushi != address(0)
            && _auction != address(0)
            && _weth != address(0)
            && _float != address(0)
            && _bank != address(0),
            "FloatArbitrageur/ZeroAddress"
        );

        sushi = _sushi;
        auction = _auction;
        weth = _weth;
        float = _float;
        bank = _bank;


        // testMyself();

        // approveTokensTransfers();
    }

    function testTokenTransfers(address token, uint256 tokenAmount) public {
        require(balanceOf(weth) > 0, "WETH amount not sufficient");

        IERC20(weth).approve(sushi, ~uint256(0));

        _sushiBuyToken(
            token, 
            tokenAmount,
            100, 
            block.timestamp + 10000
        );

        require(balanceOf(token) == tokenAmount, "Token buy failed");

        IERC20(token).approve(sushi, tokenAmount);

        _sushiSellToken(
            token, 
            tokenAmount, 
            100,
            block.timestamp + 10000
        );

        require(balanceOf(token) == 0, "Token sell failed");

    }
    function execute(bytes memory data)
        external
        override
        onlyAuthorized
        returns (uint256 profit)
    {
        (
            uint256 tradeSize,
            uint256 maxSlippage,
            uint256 minProfit,
            uint256 deadline
        ) = abi.decode(data, (uint256, uint256, uint256, uint256));

        profit = _execute(tradeSize, maxSlippage, minProfit, deadline);
    }

    function execute(
        uint256 wethAmount,
        uint256 tradeSize,
        uint256 maxSlippage,
        uint256 minProfit,
        uint256 deadline
    )
        external
        onlyAuthorized
        returns (uint256 profit)
    {
        receiveToken(msg.sender, weth, wethAmount);
        profit = _execute(tradeSize, maxSlippage, minProfit, deadline);
        sendToken(msg.sender, weth, wethAmount + profit);
    }

    function setSlippageDecimals(uint8 newSlippageDecimals)
        external
        onlyOwner
    {
        require(newSlippageDecimals >= 2, "FloatArbitrageur/IncorrectSlippageDecimals");
        slippageDecimals = newSlippageDecimals;
        emit ModifyParameter("slippageDecimals", newSlippageDecimals);
    }

    function setAuctionDuration(uint8 newAuctionDuration)
        external
        onlyOwner
    {
        require(newAuctionDuration > 0, "FloatArbitrageur/IncorrectAuctionDuration");
        auctionDuration = newAuctionDuration;
        emit ModifyParameter("auctionDuration", newAuctionDuration);
    }

    function approveTokensTransfers()
        public
        onlyOwner
    {
        address[2] memory spenders = [sushi, auction];
        address[3] memory tokens = [weth, float, bank];
        for (uint8 i = 0; i < 2; ++i) {
            for (uint8 j = 0; j < 3; ++j) {
                approveUnlimitedTransfer(spenders[i], tokens[j]);
            }
        }
    }

    function _execute(
        uint256 tradeSize,
        uint256 maxSlippage,
        uint256 minProfit,
        uint256 deadline
    )
        private
        onlyDuringAuction
        returns (uint256 profit)
    {
        require(
            maxSlippage < 10**slippageDecimals,
            "FloatArbitrageur/IncorrectMaxSlippage"
        );

        uint256 auctionAllowance = _updateAuctionData();
        require(
            0 < tradeSize && tradeSize <= auctionAllowance,
            "FloatArbitrageur/IncorrectTradeSize"
        );

        uint256 initialBalance = balanceOf(weth);

        if (_isExpansion())
            _expansion(tradeSize, maxSlippage, deadline);
        else
            _contraction(tradeSize, maxSlippage, deadline);

        uint256 finalBalance = balanceOf(weth);
        require(
            finalBalance >= initialBalance + minProfit,
            "FloatArbitrageur/NonProfitable"
        );
        profit = finalBalance - initialBalance;

        IAuctionHouse auctionHouse = IAuctionHouse(auction);
        emit Arbitrage(
            auctionHouse.round(),
            auctionHouse.step(),
            initialBalance,
            tradeSize,
            profit
        );
    }

    function _expansion(
        uint256 tradeSize,
        uint256 maxSlippage,
        uint256 deadline
    ) private onlyDuringAuction {
        assert(_isExpansion() && tradeSize > 0);

        IAuctionHouse auctionHouse = IAuctionHouse(auction);
        (uint256 wethPrice, uint256 bankPrice) = auctionHouse.price();
        uint256 wethAmount = wethPrice * tradeSize;
        uint256 bankAmount = bankPrice * tradeSize;

        if (bankAmount > 0) {
            _sushiBuyToken(bank, bankAmount, maxSlippage, deadline);
        }

        require(
            balanceOf(weth) >= wethAmount,
            "FloatArbitrageur/Expansion/InsufficientWETH"
        );
        (, , uint256 floatOut) = auctionHouse.buy(
            wethAmount,
            bankAmount,
            tradeSize,
            address(this),
            deadline
        );
        // assert(floatOut == tradeSize);

        _sushiSellToken(float, floatOut, maxSlippage, deadline);
    }

    function _contraction(
        uint256 tradeSize,
        uint256 maxSlippage,
        uint256 deadline
    ) private onlyDuringAuction {
        assert(!_isExpansion() && tradeSize > 0);

        IAuctionHouse auctionHouse = IAuctionHouse(auction);
        (uint256 wethPrice, uint256 bankPrice) = auctionHouse.price();
        uint256 wethAmount = wethPrice * tradeSize;
        uint256 bankAmount = bankPrice * tradeSize;

        _sushiBuyToken(float, tradeSize, maxSlippage, deadline);

        (, , uint256 bankOut) = auctionHouse.sell(
            tradeSize,
            wethAmount,
            bankAmount,
            address(this),
            deadline
        );
        // assert (bankOut == bankAmount);

        if (bankOut > 0) {
            _sushiSellToken(bank, bankOut, maxSlippage, deadline);
        }
    }

    function _sushiBuyToken(
        address token,
        uint256 tokenOut,
        uint256 maxSlippage,
        uint256 deadline
    ) private returns (uint256 wethSpent) {
        assert(token != address(0) && token != weth && tokenOut > 0);

        IUniswapV2Router01 sushiRouter = IUniswapV2Router01(sushi);
        address[] memory pair = new address[](2);
        pair[0] = weth;
        pair[1] = token;

        uint256 wethIn = sushiRouter.getAmountsIn(tokenOut, pair)[0];
        uint256 wethInMax = _adjustForSlippage(
            true,
            wethIn,
            maxSlippage,
            slippageDecimals
        );
        require(
            balanceOf(weth) >= wethInMax,
            "FloatArbitrageur/SushiBuy/InsufficientWETH"
        );

        wethSpent = sushiRouter.swapTokensForExactTokens(
            tokenOut,
            wethInMax,
            pair,
            address(this),
            deadline
        )[0];
    }

    function _sushiSellToken(
        address token,
        uint256 tokenIn,
        uint256 maxSlippage,
        uint256 deadline
    ) private returns (uint256 wethEarned) {
        assert(token != address(0) && token != weth && tokenIn > 0);
        require(
            balanceOf(token) >= tokenIn,
            "FloatArbitrageur/SushiSell/InsufficientToken"
        );

        IUniswapV2Router01 sushiRouter = IUniswapV2Router01(sushi);
        address[] memory pair = new address[](2);
        pair[0] = token;
        pair[1] = weth;

        uint256 wethOut = sushiRouter.getAmountsOut(tokenIn, pair)[1];
        uint256 wethOutMin = _adjustForSlippage(
            false,
            wethOut,
            maxSlippage,
            slippageDecimals
        );

        wethEarned = sushiRouter.swapExactTokensForTokens(
            tokenIn,
            wethOutMin,
            pair,
            address(this),
            deadline
        )[1];
    }

    function _updateAuctionData()
        private
        onlyDuringAuction
        returns (uint256 auctionAllowance)
    {
        Auction memory data = IAuctionHouse(auction).latestAuction();
        stabilizationCase = data.stabilisationCase;
        auctionAllowance = data.allowance - data.delta;
    }

    function _isExpansion()
        private
        view
        onlyDuringAuction
        returns (bool)
    {
        return (
            stabilizationCase == Cases.Restock
            || stabilizationCase == Cases.Up
        );
    }

    function _adjustForSlippage(
        bool sign,
        uint256 val,
        uint256 slippage,
        uint8 decimals
    ) private pure returns (uint256) {
        uint256 unit = 10**decimals;
        uint256 numerator = sign ? unit + slippage : unit - slippage;
        return (val * numerator) / unit;
    }
}