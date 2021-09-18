// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./IAmmDataProvider.sol";
import "./ISimpleToken.sol";
import "./ISeriesController.sol";
import "./IPriceOracle.sol";
import "./SeriesLibrary.sol";
import "./Math.sol";

contract AmmDataProvider is IAmmDataProvider {
    ISeriesController public seriesController;
    IERC1155 public erc1155Controller;
    IPriceOracle public priceOracle;

    event AmmDataProviderCreated(
        ISeriesController seriesController,
        IERC1155 erc1155Controller,
        IPriceOracle priceOracle
    );

    constructor(
        ISeriesController _seriesController,
        IERC1155 _erc1155Controller,
        IPriceOracle _priceOracle
    ) {
        require(
            address(_seriesController) != address(0x0),
            "AmmDataProvider: _seriesController cannot be the 0x0 address"
        );
        require(
            address(_erc1155Controller) != address(0x0),
            "AmmDataProvider: _erc1155Controller cannot be the 0x0 address"
        );
        require(
            address(_priceOracle) != address(0x0),
            "AmmDataProvider: _priceOracle cannot be the 0x0 address"
        );

        seriesController = _seriesController;
        erc1155Controller = _erc1155Controller;
        priceOracle = _priceOracle;

        emit AmmDataProviderCreated(
            _seriesController,
            _erc1155Controller,
            _priceOracle
        );
    }

    /// This function determines reserves of a bonding curve for a specific series.
    /// Given price of bToken we determine what is the largest pool we can create such that
    /// the ratio of its reserves satisfy the given bToken price: Rb / Rw = (1 - Pb) / Pb
    function getVirtualReserves(
        uint64 seriesId,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) public view override returns (uint256, uint256) {
        uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
        uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

        // Get residual balances
        uint256 bTokenBalance = erc1155Controller.balanceOf(
            ammAddress,
            bTokenIndex
        );
        uint256 wTokenBalance = erc1155Controller.balanceOf(
            ammAddress,
            wTokenIndex
        );

        ISeriesController.Series memory series = seriesController.series(
            seriesId
        );

        // For put convert token balances into collateral locked in them
        if (series.isPutOption) {
            bTokenBalance = seriesController.getCollateralPerOptionToken(
                seriesId,
                bTokenBalance
            );
            wTokenBalance = seriesController.getCollateralPerOptionToken(
                seriesId,
                wTokenBalance
            );
        }

        // Max amount of tokens we can get by adding current balance plus what can be minted from collateral
        uint256 bTokenBalanceMax = bTokenBalance + collateralTokenBalance;
        uint256 wTokenBalanceMax = wTokenBalance + collateralTokenBalance;

        uint256 wTokenPrice = uint256(1e18) - bTokenPrice;

        // Balance on higher reserve side is the sum of what can be minted (collateralTokenBalance)
        // plus existing balance of the token
        uint256 bTokenVirtualBalance;
        uint256 wTokenVirtualBalance;

        if (bTokenPrice <= wTokenPrice) {
            // Rb >= Rw, Pb <= Pw
            bTokenVirtualBalance = bTokenBalanceMax;
            wTokenVirtualBalance =
                (bTokenVirtualBalance * bTokenPrice) /
                wTokenPrice;

            // Sanity check that we don't exceed actual physical balances
            // In case this happens, adjust virtual balances to not exceed maximum
            // available reserves while still preserving correct price
            if (wTokenVirtualBalance > wTokenBalanceMax) {
                wTokenVirtualBalance = wTokenBalanceMax;
                bTokenVirtualBalance =
                    (wTokenVirtualBalance * wTokenPrice) /
                    bTokenPrice;
            }
        } else {
            // if Rb < Rw, Pb > Pw
            wTokenVirtualBalance = wTokenBalanceMax;
            bTokenVirtualBalance =
                (wTokenVirtualBalance * wTokenPrice) /
                bTokenPrice;

            // Sanity check
            if (bTokenVirtualBalance > bTokenBalanceMax) {
                bTokenVirtualBalance = bTokenBalanceMax;
                wTokenVirtualBalance =
                    (bTokenVirtualBalance * bTokenPrice) /
                    wTokenPrice;
            }
        }

        return (bTokenVirtualBalance, wTokenVirtualBalance);
    }

    /// @dev Calculate price of bToken based on Black-Scholes approximation by Brennan-Subrahmanyam from their paper
    /// "A Simple Formula to Compute the Implied Standard Deviation" (1988).
    /// Formula: 0.4 * ImplVol * sqrt(timeUntilExpiry) * priceRatio
    ///
    /// Please note that the 0.4 is assumed to already be factored into the `volatility` argument. We do this to save
    /// gas.
    ///
    /// Returns premium in units of percentage of collateral locked in a contract for both calls and puts
    function calcPrice(
        uint256 timeUntilExpiry,
        uint256 strike,
        uint256 currentPrice,
        uint256 volatility,
        bool isPutOption
    ) public pure override returns (uint256) {
        uint256 intrinsic = 0;
        uint256 timeValue = 0;

        if (isPutOption) {
            if (currentPrice < strike) {
                // ITM
                intrinsic = ((strike - currentPrice) * 1e18) / strike;
            }

            timeValue =
                (Math.sqrt(timeUntilExpiry) * volatility * strike) /
                currentPrice;
        } else {
            if (currentPrice > strike) {
                // ITM
                intrinsic = ((currentPrice - strike) * 1e18) / currentPrice;
            }

            // use a Black-Scholes approximation to calculate the option price given the
            // volatility, strike price, and the current series price
            timeValue =
                (Math.sqrt(timeUntilExpiry) * volatility * currentPrice) /
                strike;
        }

        // Verify that 100% is the max that can be returned.
        // A super deep In The Money option could return a higher value than 100% using the approximation formula
        if (intrinsic + timeValue > 1e18) {
            return 1e18;
        }

        return intrinsic + timeValue;
    }

    /// @notice Calculate premium (i.e. the option price) to buy bTokenAmount bTokens for the
    /// given Series
    /// @notice The premium depends on the amount of collateral token in the pool, the reserves
    /// of bToken and wToken in the pool, and the current series price of the underlying
    /// @param seriesId The ID of the Series to buy bToken on
    /// @param ammAddress The AMM whose reserves we'll use
    /// @param bTokenAmount The amount of bToken to buy, which uses the same decimals as
    /// the underlying ERC20 token
    /// @return The amount of collateral token necessary to buy bTokenAmount worth of bTokens
    function bTokenGetCollateralIn(
        uint64 seriesId,
        address ammAddress,
        uint256 bTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) external view override returns (uint256) {
        // Shortcut for 0 amount
        if (bTokenAmount == 0) return 0;

        bTokenAmount = seriesController.getCollateralPerOptionToken(
            seriesId,
            bTokenAmount
        );

        // For both puts and calls balances are expressed in collateral token
        (uint256 bTokenBalance, uint256 wTokenBalance) = getVirtualReserves(
            seriesId,
            ammAddress,
            collateralTokenBalance,
            bTokenPrice
        );

        uint256 sumBalance = bTokenBalance + wTokenBalance;
        uint256 toSquare;
        if (sumBalance > bTokenAmount) {
            toSquare = sumBalance - bTokenAmount;
        } else {
            toSquare = bTokenAmount - sumBalance;
        }

        // return the collateral amount
        return
            (((Math.sqrt((toSquare**2) + (4 * bTokenAmount * wTokenBalance)) +
                bTokenAmount) - bTokenBalance) - wTokenBalance) / 2;
    }

    /// @dev Calculates the amount of collateral token a seller will receive for selling their option tokens,
    /// taking into account the AMM's level of reserves
    /// @param seriesId The ID of the Series
    /// @param ammAddress The AMM whose reserves we'll use
    /// @param optionTokenAmount The amount of option tokens (either bToken or wToken) to be sold
    /// @param collateralTokenBalance The amount of collateral token held by this AMM
    /// @param bTokenPrice The price of 1 (human readable unit) bToken for this series, in units of collateral token
    /// @param isBToken true if the option token is bToken, and false if it's wToken. Depending on which
    /// of the two it is, the equation for calculating the final collateral token is a little different
    /// @return The amount of collateral token the seller will receive in exchange for their option token
    function optionTokenGetCollateralOut(
        uint64 seriesId,
        address ammAddress,
        uint256 optionTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice,
        bool isBToken
    ) public view override returns (uint256) {
        // Shortcut for 0 amount
        if (optionTokenAmount == 0) return 0;

        optionTokenAmount = seriesController.getCollateralPerOptionToken(
            seriesId,
            optionTokenAmount
        );

        (uint256 bTokenBalance, uint256 wTokenBalance) = getVirtualReserves(
            seriesId,
            ammAddress,
            collateralTokenBalance,
            bTokenPrice
        );

        uint256 balanceFactor;
        if (isBToken) {
            balanceFactor = wTokenBalance;
        } else {
            balanceFactor = bTokenBalance;
        }
        uint256 toSquare = optionTokenAmount + wTokenBalance + bTokenBalance;
        uint256 collateralAmount = (toSquare -
            Math.sqrt(
                (toSquare**2) - (4 * optionTokenAmount * balanceFactor)
            )) / 2;

        return collateralAmount;
    }

    /// @dev Calculate the collateral amount receivable by redeeming the given
    /// Series' bTokens and wToken
    /// @param seriesId The index of the Series
    /// @param wTokenBalance The wToken balance for this Series owned by this AMM
    /// @param bTokenBalance The bToken balance for this Series owned by this AMM
    /// @return The total amount of collateral receivable by redeeming the Series' option tokens
    function getRedeemableCollateral(
        uint64 seriesId,
        uint256 wTokenBalance,
        uint256 bTokenBalance
    ) public view override returns (uint256) {
        uint256 unredeemedCollateral = 0;
        if (wTokenBalance > 0) {
            (uint256 unclaimedCollateral, ) = seriesController.getClaimAmount(
                seriesId,
                wTokenBalance
            );
            unredeemedCollateral += unclaimedCollateral;
        }
        if (bTokenBalance > 0) {
            (uint256 unexercisedCollateral, ) = seriesController
                .getExerciseAmount(seriesId, bTokenBalance);
            unredeemedCollateral += unexercisedCollateral;
        }

        return unredeemedCollateral;
    }

    /// @notice Calculate the amount of collateral the AMM would received if all of the
    /// expired Series' wTokens and bTokens were to be redeemed for their underlying collateral
    /// value
    /// @return The amount of collateral token the AMM would receive if it were to exercise/claim
    /// all expired bTokens/wTokens
    function getCollateralValueOfAllExpiredOptionTokens(
        uint64[] memory openSeries,
        address ammAddress
    ) public view override returns (uint256) {
        uint256 unredeemedCollateral = 0;

        for (uint256 i = 0; i < openSeries.length; i++) {
            uint64 seriesId = openSeries[i];

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.EXPIRED
            ) {
                uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
                uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

                // Get the pool's option token balances
                uint256 bTokenBalance = erc1155Controller.balanceOf(
                    ammAddress,
                    bTokenIndex
                );
                uint256 wTokenBalance = erc1155Controller.balanceOf(
                    ammAddress,
                    wTokenIndex
                );

                // calculate the amount of collateral The AMM would receive by
                // redeeming this Series' bTokens and wTokens
                unredeemedCollateral += getRedeemableCollateral(
                    seriesId,
                    wTokenBalance,
                    bTokenBalance
                );
            }
        }

        return unredeemedCollateral;
    }

    /// @notice Calculate sale value of pro-rata LP b/wTokens in units of collateral token
    function getOptionTokensSaleValue(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint64[] memory openSeries,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 impliedVolatility
    ) external view override returns (uint256) {
        if (lpTokenAmount == 0) return 0;
        if (lpTokenSupply == 0) return 0;

        // Calculate the amount of collateral receivable by redeeming all the expired option tokens
        uint256 expiredOptionTokenCollateral = getCollateralValueOfAllExpiredOptionTokens(
                openSeries,
                ammAddress
            );

        // Calculate amount of collateral left in the pool to sell tokens to
        uint256 totalCollateral = expiredOptionTokenCollateral +
            collateralTokenBalance;

        // Subtract pro-rata collateral amount to be withdrawn
        totalCollateral =
            (totalCollateral * (lpTokenSupply - lpTokenAmount)) /
            lpTokenSupply;

        // Given remaining collateral calculate how much all tokens can be sold for
        uint256 collateralLeft = totalCollateral;
        for (uint256 i = 0; i < openSeries.length; i++) {
            uint64 seriesId = openSeries[i];

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN
            ) {
                uint256 bTokenToSell = (erc1155Controller.balanceOf(
                    ammAddress,
                    SeriesLibrary.bTokenIndex(seriesId)
                ) * lpTokenAmount) / lpTokenSupply;
                uint256 wTokenToSell = (erc1155Controller.balanceOf(
                    ammAddress,
                    SeriesLibrary.wTokenIndex(seriesId)
                ) * lpTokenAmount) / lpTokenSupply;

                uint256 bTokenPrice = getPriceForExpiredSeries(
                    seriesId,
                    impliedVolatility
                );

                uint256 collateralAmountB = optionTokenGetCollateralOut(
                    seriesId,
                    ammAddress,
                    bTokenToSell,
                    collateralLeft,
                    bTokenPrice,
                    true
                );
                collateralLeft -= collateralAmountB;

                uint256 collateralAmountW = optionTokenGetCollateralOut(
                    seriesId,
                    ammAddress,
                    wTokenToSell,
                    collateralLeft,
                    bTokenPrice,
                    false
                );
                collateralLeft -= collateralAmountW;
            }
        }

        return totalCollateral - collateralLeft;
    }

    /// @notice Get the bToken price for given Series, in units of the collateral token
    /// and normalized to 1e18. We use a normalization factor of 1e18 because we need
    /// to represent fractional values, yet Solidity does not support floating point numerics.
    /// @notice For example, if this is a WBTC Call option pool and so
    /// the collateral token is WBTC, then a return value of 0.5e18 means X units of bToken
    /// have a price of 0.5 * X units of WBTC. Another example; if this were a WBTC Put
    /// option pool, and so the collateral token is USDC, then a return value of 0.1e18 means
    /// X units of bToken have a price of 0.1 * X * strikePrice units of USDC.
    /// @notice This value will always be between 0 and 1e18, so you can think of it as
    /// representing the price as a fraction of 1 collateral token unit
    /// @dev This function assumes that it will only be called on an OPEN Series; if the
    /// Series is EXPIRED, then the expirationDate - block.timestamp will throw an underflow error
    function getPriceForExpiredSeries(uint64 seriesId, uint256 volatilityFactor)
        public
        view
        override
        returns (uint256)
    {
        ISeriesController.Series memory series = seriesController.series(
            seriesId
        );
        uint256 underlyingPrice = IPriceOracle(priceOracle).getCurrentPrice(
            seriesController.underlyingToken(seriesId),
            seriesController.priceToken(seriesId)
        );

        return
            getPriceForExpiredSeriesInternal(
                series,
                underlyingPrice,
                volatilityFactor
            );
    }

    function getPriceForExpiredSeriesInternal(
        ISeriesController.Series memory series,
        uint256 underlyingPrice,
        uint256 volatilityFactor
    ) private view returns (uint256) {
        return
            // Note! This function assumes the underlyingPrice is a valid series
            // price in units of underlyingToken/priceToken. If the onchain price
            // oracle's value were to drift from the true series price, then the bToken price
            // we calculate here would also drift, and will result in undefined
            // behavior for any functions which call getPriceForExpiredSeriesInternal
            calcPrice(
                series.expirationDate - block.timestamp,
                series.strikePrice,
                underlyingPrice,
                volatilityFactor,
                series.isPutOption
            );
    }

    /// Get value of all assets in the pool in units of this AMM's collateralToken.
    /// Can specify whether to include the value of expired unclaimed tokens
    function getTotalPoolValue(
        bool includeUnclaimed,
        uint64[] memory openSeries,
        uint256 collateralBalance,
        address ammAddress,
        uint256 impliedVolatility
    ) external view override returns (uint256) {
        // Note! This function assumes the underlyingPrice is a valid series
        // price in units of underlyingToken/priceToken. If the onchain price
        // oracle's value were to drift from the true series price, then the bToken price
        // we calculate here would also drift, and will result in undefined
        // behavior for any functions which call getTotalPoolValue
        uint256 underlyingPrice;
        if (openSeries.length > 0) {
            // we assume the openSeries are all from the same AMM, and thus all its Series
            // use the same underlying and price tokens, so we can arbitrarily choose the first
            // when fetching the necessary token addresses
            underlyingPrice = IPriceOracle(priceOracle).getCurrentPrice(
                seriesController.underlyingToken(openSeries[0]),
                seriesController.priceToken(openSeries[0])
            );
        }

        // First, determine the value of all residual b/wTokens
        uint256 activeTokensValue = 0;
        uint256 expiredTokensValue = 0;
        for (uint256 i = 0; i < openSeries.length; i++) {
            uint64 seriesId = openSeries[i];
            ISeriesController.Series memory series = seriesController.series(
                seriesId
            );

            uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
            uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

            uint256 bTokenBalance = erc1155Controller.balanceOf(
                ammAddress,
                bTokenIndex
            );
            uint256 wTokenBalance = erc1155Controller.balanceOf(
                ammAddress,
                wTokenIndex
            );

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN
            ) {
                // value all active bTokens and wTokens at current prices
                uint256 bPrice = getPriceForExpiredSeriesInternal(
                    series,
                    underlyingPrice,
                    impliedVolatility
                );
                // wPrice = 1 - bPrice
                uint256 wPrice = uint256(1e18) - bPrice;

                uint256 tokensValueCollateral = seriesController
                    .getCollateralPerOptionToken(
                        seriesId,
                        (bTokenBalance * bPrice + wTokenBalance * wPrice) / 1e18
                    );

                activeTokensValue += tokensValueCollateral;
            } else if (
                includeUnclaimed &&
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.EXPIRED
            ) {
                // Get collateral token locked in the series
                expiredTokensValue += getRedeemableCollateral(
                    seriesId,
                    wTokenBalance,
                    bTokenBalance
                );
            }
        }

        // Add value of OPEN Series, EXPIRED Series, and collateral token
        return activeTokensValue + expiredTokensValue + collateralBalance;
    }
}