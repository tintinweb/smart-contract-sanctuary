// SPDX-License-Identifier: Unlicense

/** This library exists mostly as a space saving measure for now.
  * The logic probably needs more separating than just this*/

//TODO: Check if it would be better to just use storage rather than memory when retrieving data from the coindeed
//TODO: MAKE SURE TO REVIEW THE CODE FOR CHECK EFFECT INTERACTIONS ORDERING
//TODO: Move all functions the require _repay here

pragma solidity >=0.8.0;

import "../interface/FeedRegistryInterface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interface/IToken.sol";
import "../interface/ICoinDeed.sol";
import "../interface/ICoinDeedFactory.sol";
import "../interface/ICoinDeedAddressesProvider.sol";
import "../interface/ICoinDeedDao.sol";
import "../interface/ILendingPool.sol";
import "../interface/IWholesaleFactory.sol";

library CoinDeedAddressesProviderUtils {
    using SafeERC20 for IERC20;

    uint256 public constant BASE_DENOMINATOR = 10_000;
    // TODO
    address internal constant USDT_ADDRESS = 0xd35d2e839d888d1cDBAdef7dE118b87DfefeD20e;

    function tokenRatio(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address tokenA,
        uint256 tokenAAmount,
        address tokenB
    ) internal view returns (uint256 tokenBAmount){
        FeedRegistryInterface feedRegistry = FeedRegistryInterface(coinDeedAddressesProvider.feedRegistry());
        uint256 answerA = uint256(feedRegistry.latestAnswer(tokenA, Denominations.USD));
        uint256 answerB = uint256(feedRegistry.latestAnswer(tokenB, Denominations.USD));
        uint8 decimalsA = feedRegistry.decimals(tokenA, Denominations.USD);
        uint8 decimalsB = feedRegistry.decimals(tokenB, Denominations.USD);
        require(answerA > 0 && answerB > 0, "Invalid oracle answer");
        return tokenAAmount * (answerA / (10 ** decimalsA)) * ((10 ** decimalsB) / answerB);
    }

    function readyCheck(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address tokenA,
        uint256 totalStake,
        uint256 stakingMultiplier,
        uint256 deedSize
    ) external view returns (bool){
        FeedRegistryInterface feedRegistry = FeedRegistryInterface(coinDeedAddressesProvider.feedRegistry());
        uint256 tokenAPrice = uint256(feedRegistry.latestAnswer(tokenA, Denominations.USD));
        uint8 tokenADecimals = feedRegistry.decimals(tokenA, Denominations.USD);
        uint256 dTokenPrice = uint256(feedRegistry.latestAnswer(tokenA, Denominations.USD));
        uint8 dTokenDecimals = feedRegistry.decimals(tokenA, Denominations.USD);
        require(tokenAPrice > 0 && dTokenPrice > 0, "Invalid oracle answer");
        if (
            totalStake *
            dTokenPrice /
            (10 ** dTokenDecimals) >=
            deedSize *
            tokenAPrice /
            (10 ** tokenADecimals) * // Oracle Price in USD
            stakingMultiplier /
            BASE_DENOMINATOR // Staking multiplier
        )
        {
            return true;
        }
        return false;
    }

    // Token B is the collateral token
    // Token A is the debt token
    function checkRiskMitigationAndGetSellAmount(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair,
        ICoinDeed.RiskMitigation memory riskMitigation,
        bool riskMitigationTriggered
    ) external view returns (uint256 sellAmount, uint256 buyAmount) {
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        uint256 totalDeposit = lendingPool.totalDepositBalance(pair.tokenB, address(this));
        uint256 totalBorrow = lendingPool.totalBorrowBalance(pair.tokenA, address(this));
        // Debt value expressed in collateral token units
        uint256 totalBorrowInDepositToken = tokenRatio(
            coinDeedAddressesProvider,
            pair.tokenA,
            totalBorrow,
            pair.tokenB);

        require(checkRiskMitigation(
            riskMitigation,
            totalDeposit,
            totalBorrowInDepositToken,
            riskMitigationTriggered
        ), "Risk Mitigation isnt required.");

        /** To figure out how much to sell, we use the following formula:
          * a = collateral tokens
          * d = debt token value expressed in collateral token units
          * (e.g. for ETH collateral and BTC debt, how much ETH the BTC debt is worth)
          * s = amount of collateral tokens to sell
          * l_1 = current leverage = a/(a - d)
          * l_2 = risk mitigation target leverage = (a - s)/(a - d)
          * e = equity value expressed in collateral token units = a - d
          * From here we derive s = [a/e - l_2] * e
          *
          * If risk mitigation has already been triggered, sell the entire deed
         **/
        uint256 equityInDepositToken = totalDeposit - totalBorrowInDepositToken;
        if (!riskMitigationTriggered) {
            sellAmount = ((BASE_DENOMINATOR * totalDeposit / equityInDepositToken) -
                (BASE_DENOMINATOR * riskMitigation.leverage)) *
                equityInDepositToken / BASE_DENOMINATOR;
        }
        else {
            sellAmount = totalDeposit;
        }
        buyAmount = tokenRatio(
            coinDeedAddressesProvider,
            pair.tokenB,
            sellAmount,
            pair.tokenA);

        return (sellAmount, buyAmount);
    }

    /** With leverage L, the ratio of total value of assets / debt is L/L-1.
      * To track an X% price drop, we set the mitigation threshold to (1-X) * L/L-1.
      * For example, if the initial leverage is 3 and we track a price drop of 5%,
      * risk mitigation can be triggered when the ratio of assets to debt falls
      * below 0.95 * 3/2 = 0.1485. */
    function checkRiskMitigation(
        ICoinDeed.RiskMitigation memory riskMitigation,
        uint256 totalDeposit,
        uint256 totalBorrowInDepositToken,
        bool riskMitigationTriggered
    ) internal pure returns (bool) {
        uint256 trigger = riskMitigationTriggered ?
            riskMitigation.secondTrigger :
            riskMitigation.trigger;
        uint256 mitigationThreshold =
            (BASE_DENOMINATOR - trigger) *
            riskMitigation.leverage /
            (riskMitigation.leverage - 1);
        uint256 priceRatio =
            totalDeposit *
            BASE_DENOMINATOR /
            totalBorrowInDepositToken;
        return priceRatio < mitigationThreshold;
    }

    // Validates that the tokens have oracles
    function validateTokens(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair
    ) external view returns (bool) {
        FeedRegistryInterface feedRegistry = FeedRegistryInterface(coinDeedAddressesProvider.feedRegistry());
        return(
            feedRegistry.latestAnswer(pair.tokenA, Denominations.USD) > 0 &&
            feedRegistry.latestAnswer(pair.tokenB, Denominations.USD) > 0
        );
    }

    // Validates risk parameters. This is for setting parameters, NOT for actual risk mitigation
    function validateRiskMitigation(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.RiskMitigation memory riskMitigation_,
        uint8 leverage
    ) external view {
        ICoinDeedFactory coinDeedFactory = ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory());
        require(riskMitigation_.trigger <= coinDeedFactory.maxPriceDrop() / leverage, "BAD_TRIG");
        require(riskMitigation_.leverage <= coinDeedFactory.maxLeverage(), "BAD_LEVERAGE");
        require(
            (riskMitigation_.secondTrigger <= coinDeedFactory.maxPriceDrop() / leverage) &&
            (riskMitigation_.secondTrigger >= riskMitigation_.trigger),
            "BAD_TRIG"
        );
    }

    // Validates execution times
    function validateExecutionTime(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.ExecutionTime memory executionTime_,
        uint256 wholesaleId
    ) external {
        require(executionTime_.recruitingEndTimestamp > block.timestamp, "BAD_END");
        require(executionTime_.recruitingEndTimestamp < executionTime_.buyTimestamp, "BAD_BUY");
        require(executionTime_.buyTimestamp < executionTime_.sellTimestamp, "BAD_SELL");

        if (wholesaleId != 0) {
            IWholesaleFactory wholesaleFactory = IWholesaleFactory(coinDeedAddressesProvider.wholesaleFactory());
            IWholesaleFactory.Wholesale memory wholesale = wholesaleFactory.getWholesale(wholesaleId);
            require(wholesale.deadline > executionTime_.buyTimestamp, "BAD_BUY_TIME");
        }
    }

    /** Helps the coindeed buy function. Mostly a contract space saving measure
      * Returns values that are needed to modify the coindeed contract's state
      * Interactions with other contracts are done here instead of in the coindeed */
    function buy(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair,
        ICoinDeed.ExecutionTime memory executionTime,
        ICoinDeed.DeedParameters memory deedParameters,
        uint256 totalSupply,
        uint256 wholesaleId,
        uint256 minAmountOut
    ) external returns (uint256 totalManagementFee) {
        totalManagementFee = _validateBuyAndReturnManagementFee(
            pair,
            executionTime,
            deedParameters,
            totalSupply
        );
        _buyWithLeverageAndDeposit(
            coinDeedAddressesProvider,
            pair,
            deedParameters,
            totalSupply - totalManagementFee,
            wholesaleId,
            minAmountOut
        );
        return totalManagementFee;
    }

    /** Helps the buy function. Exists mostly to avoid stack too deep errors
      * Returns the total management fee. */
    function _validateBuyAndReturnManagementFee(
        ICoinDeed.Pair memory pair,
        ICoinDeed.ExecutionTime memory executionTime,
        ICoinDeed.DeedParameters memory deedParameters,
        uint256 totalSupply
    ) internal view returns (uint256 totalManagementFee) {
        // Can trigger buy early if deed is full
        require(
            block.timestamp >= executionTime.buyTimestamp ||
            totalSupply >= deedParameters.deedSize * deedParameters.minimumBuy / BASE_DENOMINATOR / deedParameters.leverage, 
            "CANT_BUY");

        totalManagementFee = totalSupply * deedParameters.managementFee / BASE_DENOMINATOR;
        uint256 remainder = totalSupply - totalManagementFee;

        if (pair.tokenA == address(0x00)) {
            require(remainder <= address(this).balance, "LOW_ETHER");
        } else {
            require(remainder <= IERC20(pair.tokenA).balanceOf(address(this)), "LOW_TOKENS");
        }
        return totalManagementFee;
    }

    /** Helps the buy function after management fees are deducted.
      * Borrows (leverage - 1) * buyIn from the lending pool
      * Sells leverage * buyIn of tokenA with the specified wholesale first,
      * and swaps the rest on uniswap. Deposits the tokens received into the lending pool.
      * @dev Relies on the lending pool to bubble an error if there's no liquidity. */
    function _buyWithLeverageAndDeposit(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair,
        ICoinDeed.DeedParameters memory deedParameters,
        uint256 buyIn,
        uint256 wholesaleId,
        uint256 minAmountOut
    ) internal returns (uint256 amountReceived) {
        uint256 totalLoan = buyIn * (deedParameters.leverage - 1);
        // Borrow the token A if leverage > 1
        if (totalLoan > 0) {
            ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
            lendingPool.borrow(pair.tokenA, totalLoan);
        }
        // Try to sell through a wholesale first
        uint256 amountSent = _wholesaleSwap(
            coinDeedAddressesProvider,
            pair,
            wholesaleId,
            buyIn * deedParameters.leverage);
        amountReceived = pair.tokenB == address(0) ? address(this).balance : IERC20(pair.tokenB).balanceOf(address(this));
        // Sell the rest through a dex
        if (amountSent < buyIn * deedParameters.leverage) {
            amountReceived += _dexSwap(
                coinDeedAddressesProvider, 
                pair.tokenA, 
                pair.tokenB, 
                buyIn * deedParameters.leverage - amountSent,
                minAmountOut);
        }
        // Deposit the tokens received
        _deposit(coinDeedAddressesProvider, pair.tokenB, amountReceived);
        return amountReceived;
    }

    /** Withdraw and sell the entire deposit balance.
      * Repay the smaller between the total debt or the total received from selling.
      * Specify 0 in minAmountOut to default to 2.5% slippage using chainlink oracles */
    function sell(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair,
        ICoinDeed.ExecutionTime memory executionTime,
        uint256 minAmountOut
    ) external {
        require(block.timestamp >= executionTime.sellTimestamp, "NOT_TIME");
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());

        (uint256 amountToSwap, uint256 amountToWithdraw) = _getTotalTokenB(address(coinDeedAddressesProvider), pair.tokenB);
        uint256 totalBorrow = lendingPool.totalBorrowBalance(pair.tokenA, address(this));

        lendingPool.withdraw(pair.tokenB, amountToWithdraw);

        uint256 amountReceived = _dexSwap(
            coinDeedAddressesProvider,
            pair.tokenB,
            pair.tokenA,
            amountToSwap,
            minAmountOut);

        _repay(
            coinDeedAddressesProvider,
            pair.tokenA,
            totalBorrow < amountReceived ? totalBorrow : amountReceived
        );
    }

    /** Validation should already be done.
      * @dev UPDATE THE STAKES IN THE DEED CONTRACT BEFORE THIS.
      * Google 'check effect interactions' for more info */
    function withdrawStake(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair,
        ICoinDeed.DeedState state,
        uint256 stake,
        uint256 totalStake,
        uint256 totalFee
    ) external
    {
        IToken deedToken = IToken(coinDeedAddressesProvider.deedToken());
        ICoinDeedDao coinDeedDao = ICoinDeedDao(coinDeedAddressesProvider.coinDeedDao());
        // There's only a management fee if the deed passes through all the phases
        uint256 managementFeeConverted;
        if (state == ICoinDeed.DeedState.CLOSED) {
            // The math looks a little weird because I want to avoid overflow and rounding to zero.
            // The intended math is totalManagementFee = totalFee * (stake/totalStake)
            uint256 totalManagementFee = totalFee * (BASE_DENOMINATOR * stake / totalStake) / BASE_DENOMINATOR ;
            uint256 amount;
            if (pair.tokenA == address(0x00)) {
                amount = coinDeedDao.claimCoinDeedManagementFee{value: totalManagementFee}(pair.tokenA, totalManagementFee);
            } else {
                if (pair.tokenA == USDT_ADDRESS) {
                    IERC20(pair.tokenA).safeApprove(address(coinDeedDao), 0);
                }
                IERC20(pair.tokenA).safeApprove(address(coinDeedDao), totalManagementFee);
                amount = coinDeedDao.claimCoinDeedManagementFee(pair.tokenA, totalManagementFee);
            }
            // Take the platform cut
            uint256 platformFee = amount * ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).platformFee() / BASE_DENOMINATOR;
            managementFeeConverted = amount - platformFee;
            deedToken.transfer(coinDeedAddressesProvider.treasury(), platformFee);
        }
        // Give their stakes
        deedToken.transfer(msg.sender, stake + managementFeeConverted);
    }

    /** User exits the deed.
      * Withdraw the user's share of the total deposit of the deed
      * Swap the user's collateral for the debt token
      * Repay the user's share of the total borrow of the deed
      * Transfer the rest to sender*/
    function exitDeed(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair,
        uint256 buyIn,
        uint256 totalSupply,
        bool payOff
    ) external {
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        (uint256 totalTokenB, uint256 depositAmount) = _getTotalTokenB(address(coinDeedAddressesProvider), pair.tokenB);
        uint256 exitAmount = totalTokenB * buyIn / totalSupply;
        uint256 actualWithdraw = depositAmount * buyIn / totalSupply;
        if (actualWithdraw > 0) {
            lendingPool.withdraw(pair.tokenB, actualWithdraw);
        }

        uint256 userBorrow = lendingPool.totalBorrowBalance(
            pair.tokenA, address(this)
        ) * buyIn / totalSupply;

        if (payOff) {
            if (userBorrow > 0) {
                if(pair.tokenA == address(0x00)) {
                    require(msg.value == userBorrow, "BAD_REPAY");
                } else {
                    IERC20(pair.tokenA).safeTransferFrom(msg.sender, address(this), userBorrow);
                }
                _repay(
                    coinDeedAddressesProvider,
                    pair.tokenA,
                    userBorrow
                );
            }

            IERC20 token = IERC20(pair.tokenB);
            token.safeTransfer(msg.sender, exitAmount);
            ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitPayOff(msg.sender, exitAmount);
        } else {
            uint256 amountReceived = _dexSwap(
                coinDeedAddressesProvider,
                pair.tokenB,
                pair.tokenA,
                exitAmount,
                0
            );

            // Logic to take if solvent
            if (amountReceived > userBorrow) {
                _repay(
                    coinDeedAddressesProvider,
                    pair.tokenA,
                    userBorrow
                );
                if (pair.tokenA == address(0x00)) {
                    payable(msg.sender).transfer(amountReceived - userBorrow);
                } else {
                    IERC20 token = IERC20(pair.tokenA);
                    token.safeTransfer(msg.sender, amountReceived - userBorrow);
                }
            }
            /** Logic to take if insolvent
            * There is no incentive to call this function
            * if the position is insolvent. Don't let it get to this point.*/
            else {
                _repay(
                    coinDeedAddressesProvider,
                    pair.tokenA,
                    amountReceived
                );
            }
            ICoinDeedFactory(coinDeedAddressesProvider.coinDeedFactory()).emitExitDeed(msg.sender, exitAmount);
        }
    }

    /** Uses the *wholesaleId* to sell the *amount* of tokens requested by the wholesale
      * Operates under the assumption that the wholesale has the right tokens for the deed*/
    function _wholesaleSwap(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        ICoinDeed.Pair memory pair,
        uint256 wholesaleId,
        uint256 amount
    ) internal returns (uint256 amountIn) {
        IWholesaleFactory.Wholesale memory wholesale;
        if (wholesaleId != 0) {
            IWholesaleFactory wholesaleFactory = IWholesaleFactory(coinDeedAddressesProvider.wholesaleFactory());
            wholesale = wholesaleFactory.getWholesale(wholesaleId);

            if (amount <= wholesale.requestedAmount) {
                amountIn = amount;
            } else {
                amountIn = wholesale.requestedAmount;
            }

            if (pair.tokenA == address(0x00)) {
                wholesaleFactory.executeWholesale{value : amountIn}(wholesaleId, amountIn);
            } else {
                IERC20(pair.tokenA).safeApprove(address(wholesaleFactory), amountIn);
                wholesaleFactory.executeWholesale(wholesaleId, amountIn);
            }
        }
    }

    /** Swaps on uniswap.
      * Use minAmountOut to control for frontrunning. If provided 0,
      * will revert if amount received is less than 97.5% less than oracle price*/
    function _dexSwap(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        uint256 tokenOutTarget = tokenRatio(
            coinDeedAddressesProvider,
            tokenIn,
            amountIn,
            tokenOut);
        if(minAmountOut == 0) {
            minAmountOut = tokenOutTarget * 9750 / BASE_DENOMINATOR;
        }
        /* TODO RE-ENABLE THIS BLOCK WHEN TESTING IS MORE MATURE.
         * It's too cumbersome in a testing environment to maintain prices for test tokens
        else {
            require(minAmountOut > tokenOutTarget * 9500 / BASE_DENOMINATOR, "UNSAFE_MIN_AMOUNT_OUT");
        }*/
        if (amountIn > 0) {
            if (tokenIn == address(0x00)) {
                return _swapEthToToken(coinDeedAddressesProvider, amountIn, tokenOut, minAmountOut);
            } else if (tokenOut == address(0x00)){
                return _swapTokenToEth(coinDeedAddressesProvider, amountIn, tokenIn, minAmountOut);
            } else {
                return _swapTokenToToken(coinDeedAddressesProvider, tokenIn, amountIn, tokenOut, minAmountOut);
            }
        }
        return 0;
    }

    function _swapTokenToToken(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address token1Address,
        uint256 amount,
        address token2Address,
        uint256 minAmountOut
    ) internal returns (uint256 amountReceived){
        IUniswapV2Router01 uniswapRouter1 = IUniswapV2Router01(coinDeedAddressesProvider.swapRouter());
        IERC20 token1 = IERC20(token1Address);
        if (address(token1) == USDT_ADDRESS) {
            token1.safeApprove(address(uniswapRouter1), 0);
        }
        token1.safeApprove(address(uniswapRouter1), amount);
        address[] memory path = new address[](2);
        path[0] = token1Address;
        path[1] = token2Address;

        uint[] memory amounts = uniswapRouter1.swapExactTokensForTokens(amount, minAmountOut, path, address(this), block.timestamp + 15);
        return amounts[1];
    }

    function _swapEthToToken(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        uint256 amount,
        address token,
        uint256 minAmountOut
    ) internal returns (uint256 amountReceived){
        IUniswapV2Router01 uniswapRouter1 = IUniswapV2Router01(coinDeedAddressesProvider.swapRouter());
        address[] memory path = new address[](2);
        path[0] = uniswapRouter1.WETH();
        path[1] = address(token);

        uint[] memory amounts = uniswapRouter1.swapExactETHForTokens{value : amount}(minAmountOut, path, address(this), block.timestamp + 15);
        return amounts[1];
    }

    function _swapTokenToEth(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        uint256 amount,
        address tokenAddress,
        uint256 minAmountOut
    ) internal returns (uint256 amountReceived){
        IUniswapV2Router01 uniswapRouter1 = IUniswapV2Router01(coinDeedAddressesProvider.swapRouter());
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = uniswapRouter1.WETH();

        IERC20 token = IERC20(tokenAddress);
        if (address(token) == USDT_ADDRESS) {
            token.safeApprove(address(uniswapRouter1), 0);
        }
        token.safeApprove(address(uniswapRouter1), amount);

        uint[] memory amounts = uniswapRouter1.swapExactTokensForETH(amount, minAmountOut, path, address(this), block.timestamp + 15);
        return amounts[1];
    }

    function _repay(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address tokenAddress,
        uint amount
    ) internal {
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        if (amount > 0) {
            if (tokenAddress == address(0x00)) {
                lendingPool.repay{value : amount}(tokenAddress, amount);
            } else {
                if (tokenAddress == USDT_ADDRESS) {
                    IERC20(tokenAddress).safeApprove(address(lendingPool), 0);
                }
                IERC20(tokenAddress).safeApprove(address(lendingPool), amount);
                lendingPool.repay(tokenAddress, amount);
            }
        }
    }

    function _deposit(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address tokenAddress,
        uint256 amount
    ) internal {
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        if (lendingPool.poolActive(tokenAddress)) {
            if (tokenAddress == address(0x00)) {
                lendingPool.deposit{value : amount}(tokenAddress, amount);
            } else {
                IERC20(tokenAddress).safeApprove(address(lendingPool), amount);
                lendingPool.deposit(tokenAddress, amount);
            }
        }
    }

    function _getTotalTokenB(address addressProvider, address tokenB) internal view returns (uint256 returnAmount, uint256 depositAmount) {
        ICoinDeedAddressesProvider coinDeedAddressesProvider = ICoinDeedAddressesProvider(addressProvider);
        ILendingPool lendingPool = ILendingPool(coinDeedAddressesProvider.lendingPool());
        if (lendingPool.poolActive(tokenB)) {
            returnAmount = lendingPool.totalDepositBalance(tokenB, address(this));
            depositAmount = lendingPool.depositAmount(tokenB, address(this));
        } else {
            returnAmount = IERC20(tokenB).balanceOf(address(this));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FeedRegistryInterface {
    function decimals(address base, address quote)
        external
        view
        returns (uint8);

    function latestRoundData(address base, address quote)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    // V2 AggregatorInterface

    function latestAnswer(address base, address quote)
        external
        view
        returns (int256 answer);

    function latestTimestamp(address base, address quote)
        external
        view
        returns (uint256 timestamp);

    function latestRound(address base, address quote)
        external
        view
        returns (uint256 roundId);

    function isFeedEnabled(address aggregator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IToken is IERC20, IAccessControl, IERC165 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: Unlicense
/** @title Interface for CoinDeed
  * @author Bitus Labs
 **/
pragma solidity ^0.8.0;

interface ICoinDeed {


    enum DeedState {SETUP, READY, OPEN, CLOSED, CANCELED}

    /// @notice Class of all initial deed creation parameters.
    struct DeedParameters {
        uint256 deedSize;
        uint8 leverage;
        uint256 managementFee;
        uint256 minimumBuy;
    }

    struct Pair {address tokenA; address tokenB;}

    /// @notice Stores all the timestamps that must be checked prior to moving through deed phases.
    struct ExecutionTime {
        uint256 recruitingEndTimestamp;
        uint256 buyTimestamp;
        uint256 sellTimestamp;
    }

    /** @notice Risk mitigation can be triggered twice. *trigger* and *secondTrigger* are the percent drops that the collateral asset
      * can drop compared to the debt asset before the position is eligible for liquidation. The first mitigation is a partial
      * liquidation, liquidating just enough assets to return the position to the *leverage*. */
    struct RiskMitigation {
        uint256 trigger;
        uint256 secondTrigger;
        uint8 leverage;
    }

    /// @notice Stores all the parameters related to brokers
    struct BrokerConfig {
        bool allowed;
        uint256 minimumStaking;
    }


    /// @notice Reserve a wholesale to swap on execution time
    function reserveWholesale(uint256 wholesaleId_) external;

    /// @notice Add stake by deed manager or brokers. If brokersEnabled for the deed anyone can call this function to be a broker
    function stake(uint256 amount) external;

    /// @notice Brokers can withdraw their stake
    function withdrawStake() external;

    /// @notice Edit Broker Config
    function editBrokerConfig(BrokerConfig memory brokerConfig_) external;

    /// @notice Edit RiskMitigation
    function editRiskMitigation(RiskMitigation memory riskMitigation_) external;

    /// @notice Edit ExecutionTime
    function editExecutionTime(ExecutionTime memory executionTime_) external;

    /// @notice Edit DeedInfo
    function editBasicInfo(uint256 deedSize, uint8 leverage, uint256 managementFee, uint256 minimumBuy) external;

    /// @notice Edit SwapType
    function editSwapType(uint256 saleId_) external;

    /// @notice Returns the deed manager
    function manager() external view returns (address);

    /// @notice Returns the total fee
    function totalFee() external view returns (uint256);

    /// @notice Returns the total supply
    function totalSupply() external view returns (uint256);

    /// @notice Returns the total stake
    function totalStake() external view returns (uint256);

    /// @notice Returns the wholesale ID assigned to this deed
    function wholesaleId() external view returns (uint256);

    /// @notice Returns whether risk mitigation has been triggered
    function riskMitigationTriggered() external view returns (bool);

    function deedParameters() external view returns (
      uint256 deedSize,
      uint8 leverage,
      uint256 managementFee,
      uint256 minimumBuy
    );

    function executionTime() external view returns (
      uint256 recruitingEndTimestamp,
      uint256 buyTimestamp,
      uint256 sellTimestamp
    );

    function riskMitigation() external view returns (
      uint256 trigger,
      uint256 secondTrigger,
      uint8 leverage
    );

    function brokerConfig() external view returns (bool allowed, uint256 minimumStaking);

    function state() external view returns (DeedState);

    /// @notice Edit all deed parameters. Use previous parameters if unchanged.
    function edit(DeedParameters memory deedParameters_,
        ExecutionTime memory executionTime_,
        RiskMitigation memory riskMitigation_,
        BrokerConfig memory brokerConfig_,
        uint256 saleId_) external;

    /** @notice Initial swap for the deed to buy the tokens
      * After validating the deed's eligibility to move to the OPEN phase,
      * the management fee is subtracted, and then the deed contract is loaned
      * enough of the buyin token to bring it to the specified leverage.
      * The deed then swaps the tokens into the collateral token and deposits
      * it into the lending pool to earn additional yield. The deed is now
      * in the open state.
      * @dev There is no economic incentive built in to call this function.
      * No safety check for swapping assets */
    function buy(uint256 minAmountOut) external;

    /** @notice Sells the entire deed's collateral
      * After validating that the sell execution time has passed,
      * withdraws all collateral from the lending pool, sells it for the debt token,
      * and repays the loan in full. This closes the deed.
      * @dev There is no economic incentive built in to call this function.
      * No safety check for swapping assets */
    function sell(uint256 minAmountOut) external;

    /// @notice Cancels deed if it is in the setup or ready phase
    function cancel() external;

    /// @notice Buyers buys into the deed. Amount is ignored for ETH.
    function buyIn(uint256 amount) external payable;

    /// @notice Buyers claims their balance if the deed is completed.
    function claimBalance() external;

    /** @notice Executes risk mitigation
      * Validates that the position is eligible for liquidation,
      * and then liquidates the appropriate amount of collateral depending on
      * whether risk mitigation has already been triggered.
      * If this is the second risk mitigation, closes the deed.
      * Allocates a liquidation bonus from the collateral to the caller. */
    function executeRiskMitigation() external payable;

    /** @notice Message sender exits the deed
      * When the deed is open, this withdraws the buyer's share of collateral
      * and sells the entire amount. From this amount, repay the buyer's share of the debt
      * and return the rest to sender */
    function exitDeed(bool _payoff) payable external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICoinDeed.sol";

interface ICoinDeedFactory {


    event DeedCreated(
        uint256 indexed id,
        address indexed deedAddress,
        address indexed manager,
        uint8 leverage,
        uint256 wholesaleId
    );

    event StakeAdded(
        address indexed coinDeed,
        address indexed broker,
        uint256 indexed amount
    );

    event StateChanged(
        address indexed coinDeed,
        ICoinDeed.DeedState state
    );

    event DeedCanceled(
        address indexed coinDeed,
        address indexed deedAddress
    );

    event SwapExecuted(
        address indexed coinDeed,
        uint256 indexed tokenBought
    );

    event BuyIn(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event ExitDeed(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event PayOff(
        address indexed coinDeed,
        address indexed buyer,
        uint256 indexed amount
    );

    event LeverageChanged(
        address indexed coinDeed,
        address indexed salePercentage
    );

    event BrokersEnabled(
        address indexed coinDeed
    );

    /**
    * DeedManager calls to create deed contract
    */
    function createDeed(ICoinDeed.Pair calldata pair,
        uint256 stakingAmount,
        uint256 wholesaleId,
        ICoinDeed.DeedParameters calldata deedParameters,
        ICoinDeed.ExecutionTime calldata executionTime,
        ICoinDeed.RiskMitigation calldata riskMitigation,
        ICoinDeed.BrokerConfig calldata brokerConfig) external returns (address);

    function setMaxLeverage(uint8 _maxLeverage) external;

    function setStakingMultiplier(uint256 _stakingMultiplier) external;

    function permitToken(address token) external;

    function unpermitToken(address token) external;

    // All the important addresses
    function getCoinDeedAddressesProvider() external view returns (address);

    // The maximum leverage that any deed can have
    function maxLeverage() external view returns (uint8);

    // The fee the platform takes from all buyins before the swap
    function platformFee() external view returns (uint256);

    // The amount of stake needed per dollar value of the buyins
    function stakingMultiplier() external view returns (uint256);

    // The maximum proportion relative price can drop before a position becomes insolvent is 1/leverage.
    // The maximum price drop a deed can list risk mitigation with is maxPriceDrop/leverage
    function maxPriceDrop() external view returns (uint256);

    function deedCount() external view returns (uint256);

    function coinDeedAddresses(uint256 _id) external view returns (address);

    function liquidationBonus() external view returns (uint256);

    function setPlatformFee(uint256 _platformFee) external;

    function setMaxPriceDrop(uint256 _maxPriceDrop) external;

    function setLiquidationBonus(uint256 _liquidationBonus) external;

    function isDeed(address deedAddress) external view returns (bool);

    function emitStakeAdded(
        address broker,
        uint256 amount
    ) external;

    function emitStateChanged(
        ICoinDeed.DeedState state
    ) external;

    function emitDeedCanceled(
        address deedAddress
    ) external;

    function emitSwapExecuted(
        uint256 tokenBought
    ) external;

    function emitBuyIn(
        address buyer,
        uint256 amount
    ) external;

    function emitExitDeed(
        address buyer,
        uint256 amount
    ) external;

    function emitPayOff(
        address buyer,
        uint256 amount
    ) external;

    function emitLeverageChanged(
        address salePercentage
    ) external;

    function emitBrokersEnabled() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinDeedAddressesProvider {
    event FeedRegistryChanged(address feedRegistry);
    event SwapRouterChanged(address router);
    event LendingPoolChanged(address lendingPool);
    event CoinDeedFactoryChanged(address coinDeedFactory);
    event WholesaleFactoryChanged(address wholesaleFactory);
    event DeedTokenChanged(address deedToken);
    event CoinDeedDeployerChanged(address coinDeedDeployer);
    event TreasuryChanged(address treasury);
    event CoinDeedDaoChanged(address coinDeedDao);

    function feedRegistry() external view returns (address);
    function swapRouter() external view returns (address);
    function lendingPool() external view returns (address);
    function coinDeedFactory() external view returns (address);
    function wholesaleFactory() external view returns (address);
    function deedToken() external view returns (address);
    function coinDeedDeployer() external view returns (address);
    function treasury() external view returns (address);
    function coinDeedDao() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IOracle.sol";

/**
 * @dev Interface of the Dao.
 */
interface ICoinDeedDao {
    event Mint(address indexed user, uint256 amount);
    event AddOracleForToken(
        address indexed token,
        address indexed tokenOracle,
        uint256 oracleDecimals
    );

    function setCoinDeedAddressesProvider(address _coinDeedAddressesProvider)
        external;

    /**
     * @notice This function will receive the amount of token that lending pool transfer to
     * @dev It will convert the token to USDT and add it to user account to claim
     * This function take 3 parameters {_tokenAddress}, {_to} and {_amount}
     * The default value of amount should be in wei (1e18)
     */
    function claimDToken(
        address _tokenAddress,
        address _to,
        uint256 _amount
    ) external;

    /**
     * @notice This function will return amount reward exchange from Oracle
     * @dev It will return reward exchange from Oracle
     * This function take 2 parameters {_tokenAddress} and {_amount}
     */
    function exchangRewardToken(address _tokenAddress, uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @notice This function will receive the amount of token that lending pool transfer to Deed
     * @dev It will return reward exchange from Oracle
     * This function take 2 parameters {_tokenAddress} and {_amount}
     */
    function claimCoinDeedManagementFee(address _tokenAddress, uint256 _amount)
        external
        payable
        returns (uint256);

    /**
     * @notice This function will return fee exchange from Oracle
     * @dev It will return fee exchange to Dtoken from Oracle
     * This function take 2 parameters {_tokenAddress} and {_amount}
     */
    function getCoinDeedManagementFee(address _tokenAddress, uint256 _amount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../Exponential.sol";
import "../ErrorReporter.sol";

/**
 * @dev Interface of the Lending pool.
 */
interface ILendingPool {
    /// @notice Info of each user.
    struct UserAssetInfo {
        uint256 amount; // How many tokens the lender has provided
        uint256 supplyIndex; // Reward debt. See explanation below.
    }

    /// @notice Info of each deed.
    struct DeedInfo {
        uint256 borrow;
        uint256 totalBorrow;
        uint256 borrowIndex;
        bool isValid;
    }

    /// @notice Info of each pool.
    struct PoolInfo {
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 borrowIndex;
        uint256 supplyIndex;
        uint256 accrualBlockNumber;
        bool isCreated;
        uint256 decimals;
        uint256 supplyIndexDebt;
        uint256 accSupplyTokenPerShare;
    }

    event PoolAdded(address indexed token, uint256 decimals);
    event PoolUpdated(
        address indexed token,
        uint256 decimals,
        address oracle,
        uint256 oracleDecimals
    );
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves,
        uint256 supplyIndex
    );

    function initialize(
        address _dao,
        uint256 multiplierPerYear,
        uint256 baseRatePerYear
    ) external;

    function setCoinDeedAddressesProvider(address _coinDeedAddressesProvider)
        external;

    /**
     * @notice This function will add a pool into market
     * @dev It will initialize the components of a pool
     * This function take a parameter {_tokenAddress}
     */
    function createPool(address _tokenAddress) external;

    /**
     * @dev Testing service for testers
     * This function take a parameter {_address}
     */
    function addNewDeed(address _address) external;

    /**
     * @notice This function will supplying assets to the pool
     * @dev It will Stake tokens to Pool
     * Reverts upon any failure
     * Accrues interest whether or not the operation succeeds, unless reverted
     * This function take 2 parameters {_tokenAddress} and {_amount}
     */
    function deposit(address _tokenAddress, uint256 _amount) external payable;

    /**
     * @notice This function will borrowing assets to the pool
     * @dev Deed will Borrow tokens from Pool
     * Reverts upon any failure
     * Accrues interest whether or not the operation succeeds, unless reverted
     * This function take 2 parameters {_tokenAddress} and {_amount}
     */
    function borrow(address _tokenAddress, uint256 _amount) external;

    /**
     * @notice Deed repays a borrow
     * @dev repay
     * Reverts upon any failure
     * Accrues interest whether or not the operation succeeds, unless reverted
     * This function take 2 parameters {_tokenAddress} and {_amount}
     */
    function repay(address _tokenAddress, uint256 _amount) external payable;

    /**
     * @notice This function will withdrawing assets to the pool
     * @dev It will Withdraw tokens to Pool
     * Reverts upon any failure
     * Accrues interest whether or not the operation succeeds, unless reverted
     * This function take 2 parameters {_tokenAddress} and {_amount}
     */
    function withdraw(address _tokenAddress, uint256 _amount) external;

    /**
     * @notice Transfer all the claimable amount of deed token to the lender wallet address.
     * @dev It will call to DAO contract
     * Reverts upon any failure
     * Accrues interest whether or not the operation succeeds, unless reverted
     * This function take a parameter {_tokenAddress}
     */
    function claimDToken(address _tokenAddress) external;

    /// @notice Returns total interest and amount supplied
    function totalBorrowBalance(address _token, address _deed)
        external
        view
        returns (uint256);

    /// @notice Returns total interest and amount borrowed
    function totalDepositBalance(address _token, address _lender)
        external
        view
        returns (uint256);

    /// @notice Returns amount of tokens to borrow
    function borrowAmount(address _lender) external view returns (uint256);

    /// @notice Returns amount of tokens to deposit
    function depositAmount(address _token, address _lender) external view returns (uint256);

    /// @notice Returns rewarded token that  lender earned.
    function pendingToken(address _token, address _lender)
        external
        view
        returns (uint256);
    
    /// @notice Returns rewarded deed token that  lender earned.
    function pendingDToken(address _token, address _lender)
        external
        view
        returns (uint256);

    /// @notice Returns the existence of pool
    function poolActive(address _token) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWholesaleFactory {

    enum WholesaleState {OPEN, RESERVED, CANCELLED, COMPLETED, WITHDRAWN}

    struct Wholesale {
        address offeredBy;
        address tokenOffered;
        address tokenRequested;
        uint256 offeredAmount;
        uint256 requestedAmount;
        uint256 soldAmount;
        uint256 receivedAmount;
        uint256 minSaleAmount;
        uint256 deadline;
        address reservedTo;
        bool isPrivate;
        WholesaleState state;
    }


    event WholesaleCreated(
        uint256 indexed saleId,
        address indexed offeredBy,
        address tokenOffered,
        address tokenRequested,
        uint256 offeredAmount,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo,
        address permitDeedManager,
        bool isPrivate
    );

    event WholesaleCanceled(
        uint256 indexed saleId
    );

    event WholesaleReserved(
        uint256 indexed saleId,
        address indexed reservedBy
    );

    event WholesaleUnreserved(
        uint256 indexed saleId
    );

    event WholesaleExecuted(
        uint256 indexed saleId,
        uint256 indexed tokenOfferedAmount
    );

    event WholesaleWithdrawn(
        uint256 indexed saleId,
        address indexed tokenRequested,
        address indexed tokenOffered,
        uint256 receivedAmount,
        uint256 unsoldAmount
    );

    event WholesaleEdited(
        uint256 indexed saleId,
        bool isPrivate,
        uint256 deadline,
        uint256 minSaleAmount
    );

    /**
    * Seller creates a wholesale
    */
    function createWholesale(address tokenOffered,
        address tokenRequested,
        uint256 offeredAmount,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo,
        address permitDeedManager,
        bool isPrivate) external;

    /**
    * Seller creates a wholesale with native coin
    */
    function createWholesaleEth(
        address tokenRequested,
        uint256 requestedAmount,
        uint256 minSaleAmount,
        uint256 deadline,
        address reservedTo,
        address permitDeedManager,
        bool isPrivate) external payable;

    /**
    * Seller cancels a wholesale before it is reserved
    */
    function cancelWholesale(uint256 saleId) external;

    /**
     * Deed reserves a wholesale
     */
    function reserveWholesale(uint256 saleId) external;

    /**
     * Deed triggers a wholesale
     */
    function executeWholesale(uint256 saleId, uint256 amount) external payable;

    /**
     * Returns a wholesale with Id
     */
    function getWholesale(uint256 saleId) external returns (Wholesale memory);

    /**
     * Cancels reservation n a wholesale by a deed by seller
     */
    function cancelReservation(uint256 saleId) external;

    function permittedDeedManager(uint256 saleId, address manager) external returns (bool);

    /**
     * Withdraw funds from a wholesale
     */
    function withdraw(uint256 saleId) external;

    function permitManagers(uint256 saleId, address[] calldata managers) external;
    function permitManager(uint256 saleId, address manager) external;
    function setPrivate(uint256 saleId, bool isPrivate) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IOracle {
    function decimals() external view returns (uint256);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./maths/CarefulMath.sol";
import "./maths/ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
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
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
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
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
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
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
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
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_SUPPLY_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_SUPPLY_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
  * @title Careful Math
  * @author Compound
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
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
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
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
}