// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./ISeriesController.sol";
import "./Proxiable.sol";
import "./Proxy.sol";
import "./Math.sol";
import "./InitializeableAmm.sol";
import "./IAddSeriesToAmm.sol";
import "./IPriceOracle.sol";
import "./ISimpleToken.sol";
import "./IERC20Lib.sol";
import "./EnumerableSet.sol";
import "./SeriesLibrary.sol";

/// This is an implementation of a minting/redeeming AMM (Automated Market Maker) that trades a list of series with the same
/// collateral token. For example, a single WBTC Call AMM contract can trade all strikes of WBTC calls using
/// WBTC as the collateral, and a single WBTC Put AMM contract can trade all strikes of WBTC puts, using
/// USDC as the collateral.
///
/// Each AMM uses a triplet of ERC20 tokens to define the option asset whose price determines the option's value
/// (the underlyingToken), the token used to denominate the strike price (the priceToken) and the token used
/// as collateral writing the option (the collateralToken). The collateralToken also determines the units used
/// in pricing the option's premiums.
///
/// It uses an on-chain Black-Scholes approximation to calculate the price of a single option (which we represent by an
/// ERC1155 token we call "bToken"). The Black-Scholes approximation uses an on-chain oracle price feed to get the
/// current series price of the underlying asset. By using an on-chain oracle the AMM's bonding curve is aware of the
/// time-dependent nature of options pricing (a.k.a. theta-decay), and can price options better than a naive constant
/// product bonding curve such as Uniswap.
///
/// In addition, it uses a novel "mint aware bonding curve" to allow for infinite depth when buying options. A user
/// pays for options in units of the AMM's collateral token, and the AMM uses this collateral to mint additional bTokens
/// to satisfy the user's trade size
///
/// External users can buy bTokens with collateral (wToken trading is disabled in this version).
/// When they do this, the AMM will mint new bTokens and wTokens, sell the wToken to the AMM for more bToken,
/// and transfer the bToken to the user.
///
/// External users can sell bTokens for collateral. When they do this, the AMM will sell a partial amount of assets
/// to get a 50/50 split between bTokens and wTokens, then redeem them for collateral and transfer the collateral back to
/// the user.
///
/// LPs can provide collateral for liquidity. All collateral will be used to mint bTokens/wTokens for each trade.
/// They will be given a corresponding amount of lpTokens to track ownership. The amount of lpTokens is calculated based on
/// total pool value which includes collateral token, active b/wTokens and expired/unclaimed b/wTokens
///
/// LPs can withdraw collateral from liquidity. When withdrawing user can specify if they want their pro-rata b/wTokens
/// to be automatically sold to the pool for collateral. If the chose not to sell then they get pro-rata of all tokens
/// in the pool (collateral, bToken, wToken). If they chose to sell then their bTokens and wTokens will be sold
/// to the pool for collateral incurring slippage.
///
/// All expired unclaimed wTokens are automatically claimed on each deposit or withdrawal
///
/// All conversions between bToken and wToken in the AMM will generate fees that will be send to the protocol fees pool
/// (disabled in this version)
contract MinterAmm is
    InitializeableAmm,
    ERC1155HolderUpgradeable,
    IAddSeriesToAmm,
    OwnableUpgradeable,
    Proxiable
{
    /// Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;
    using SafeERC20 for ISimpleToken;

    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev The token contract that will track lp ownership of the AMM
    ISimpleToken public lpToken;

    /// @dev The ERC20 tokens used by all the Series associated with this AMM
    IERC20 public underlyingToken;
    IERC20 public priceToken;
    IERC20 public collateralToken;

    /// @dev The registry which the AMM will use to lookup individual Series
    ISeriesController public seriesController;

    /// @notice The contract used to mint the option tokens
    IERC1155 public erc1155Controller;

    /// @dev Fees on trading
    uint16 public tradeFeeBasisPoints;

    /// Volatility factor used in the black scholes approximation - can be updated by the owner */
    uint256 public volatilityFactor;

    /// @dev Flag to ensure initialization can only happen once
    bool initialized = false;

    uint256 public constant MINIMUM_TRADE_SIZE = 1000;

    /// @dev A price oracle contract used to get onchain price data
    address private sirenPriceOracle;

    /// @dev Collection of ids of open series
    /// @dev If we ever re-deploy MinterAmm we need to check that the EnumerableSet implementation hasn’t changed,
    /// because we rely on undocumented implementation details (see Note in MinterAmm.claimAllExpiredTokens on
    /// removing series)
    EnumerableSet.UintSet private openSeries;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /// Emitted when the amm is created
    event AMMInitialized(
        ISimpleToken lpToken,
        address sirenPriceOracle,
        address controller
    );

    /// Emitted when an LP deposits collateral
    event LpTokensMinted(
        address minter,
        uint256 collateralAdded,
        uint256 lpTokensMinted
    );

    /// Emitted when an LP withdraws collateral
    event LpTokensBurned(
        address redeemer,
        uint256 collateralRemoved,
        uint256 lpTokensBurned
    );

    /// Emitted when a user buys bTokens from the AMM
    event BTokensBought(
        address buyer,
        uint64 seriesId,
        uint256 bTokensBought,
        uint256 collateralPaid
    );

    /// Emitted when a user sells bTokens to the AMM
    event BTokensSold(
        address seller,
        uint64 seriesId,
        uint256 bTokensSold,
        uint256 collateralPaid
    );

    /// Emitted when a user sells wTokens to the AMM
    event WTokensSold(
        address seller,
        uint64 seriesId,
        uint256 wTokensSold,
        uint256 collateralPaid
    );

    /// Emitted when the owner updates volatilityFactor
    event VolatilityFactorUpdated(uint256 newVolatilityFactor);

    /// Emitted when a new sirenPriceOracle gets set on an upgraded AMM
    event NewSirenPriceOracle(address newSirenPriceOracle);

    /// @notice Emitted when an expired series has been removed
    event SeriesEvicted(uint64 seriesId);

    // Error codes. We only use error code because we need to reduce the size of this contract's deployed
    // bytecode in order for it to be deployable

    // E02: Invalid _sirenPriceOracle
    // E03: Invalid _underlyingToken
    // E04: Invalid _priceToken
    // E05: Invalid _collateralToken
    // E06: _underlyingToken cannot equal _priceToken
    // E07: Invalid _tokenImplementation
    // E08: Contract can only be initialized once
    // E09: VolatilityFactor is too low
    // E10: Invalid _newImplementation
    // E11: Can only be called by SeriesController
    // E12: withdrawCapital: collateralMinimum must be set

    /// @dev Require minimum trade size to prevent precision errors at low values
    modifier minTradeSize(uint256 tradeSize) {
        require(
            tradeSize >= MINIMUM_TRADE_SIZE,
            "Buy/Sell amount below min size"
        );
        _;
    }

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and make it call a
    /// `private` function that does the actual work.
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

    /// Initialize the contract, and create an lpToken to track ownership
    function initialize(
        ISeriesController _seriesController,
        address _sirenPriceOracle,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        address _tokenImplementation,
        uint16 _tradeFeeBasisPoints
    ) public override {
        require(address(_sirenPriceOracle) != address(0x0), "E02");
        require(address(_underlyingToken) != address(0x0), "E03");
        require(address(_priceToken) != address(0x0), "E04");
        require(address(_collateralToken) != address(0x0), "E05");
        require(address(_underlyingToken) != address(_priceToken), "E06");
        require(_tokenImplementation != address(0x0), "E07");

        // Enforce initialization can only happen once
        require(!initialized, "E08");
        initialized = true;

        // Save off state variables
        seriesController = _seriesController;
        erc1155Controller = IERC1155(_seriesController.erc1155Controller());

        // Approve seriesController to move tokens
        erc1155Controller.setApprovalForAll(address(seriesController), true);

        sirenPriceOracle = _sirenPriceOracle;
        tradeFeeBasisPoints = _tradeFeeBasisPoints;

        // Save off series tokens
        underlyingToken = _underlyingToken;
        priceToken = _priceToken;
        collateralToken = _collateralToken;

        // Create the lpToken and initialize it
        Proxy lpTokenProxy = new Proxy(_tokenImplementation);
        lpToken = ISimpleToken(address(lpTokenProxy));

        // AMM name will be <underlying>-<price>-<collateral>, e.g. WBTC-USDC-WBTC for a WBTC Call AMM
        string memory ammName = string(
            abi.encodePacked(
                IERC20Lib(address(underlyingToken)).symbol(),
                "-",
                IERC20Lib(address(priceToken)).symbol(),
                "-",
                IERC20Lib(address(collateralToken)).symbol()
            )
        );
        string memory lpTokenName = string(abi.encodePacked("LP-", ammName));
        lpToken.initialize(
            lpTokenName,
            lpTokenName,
            IERC20Lib(address(collateralToken)).decimals()
        );

        // Set default volatility
        // 0.4 * volInSeconds * 1e18
        volatilityFactor = 4000e10;

        __Ownable_init();

        emit AMMInitialized(
            lpToken,
            _sirenPriceOracle,
            address(_seriesController)
        );
    }

    /// The owner can set the volatility factor used to price the options
    function setVolatilityFactor(uint256 _volatilityFactor) public onlyOwner {
        // Check lower bounds: 500e10 corresponds to ~7% annualized volatility
        require(_volatilityFactor > 500e10, "E09");

        volatilityFactor = _volatilityFactor;
        emit VolatilityFactorUpdated(_volatilityFactor);
    }

    /// @notice update the logic contract for this proxy contract
    /// @param _newImplementation the address of the new MinterAmm implementation
    /// @dev only the admin address may call this function
    function updateImplementation(address _newImplementation)
        external
        onlyOwner
    {
        require(_newImplementation != address(0x0), "E10");

        _updateCodeAddress(_newImplementation);
    }

    /// LP allows collateral to be used to mint new options
    /// bTokens and wTokens will be held in this contract and can be traded back and forth.
    /// The amount of lpTokens is calculated based on total pool value
    function provideCapital(uint256 collateralAmount, uint256 lpTokenMinimum)
        external
        nonReentrant
    {
        // Move collateral into this contract
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );

        // If first LP, mint options, mint LP tokens, and send back any redemption amount
        if (IERC20Lib(address(lpToken)).totalSupply() == 0) {
            // Mint lp tokens to the user
            lpToken.mint(msg.sender, collateralAmount);

            // Emit event
            LpTokensMinted(msg.sender, collateralAmount, collateralAmount);

            // Bail out after initial tokens are minted - nothing else to do
            return;
        }

        // At any given moment the AMM can have the following reserves:
        // * collateral token
        // * active bTokens and wTokens for any series
        // * expired bTokens and wTokens for any series
        // In order to calculate correct LP amount we do the following:
        // 1. Claim expired wTokens and bTokens
        // 2. Add value of all active bTokens and wTokens at current prices
        // 3. Add value of collateral

        claimAllExpiredTokens();

        uint256 poolValue = getTotalPoolValue(false);

        // Mint LP tokens - the percentage added to bTokens should be same as lp tokens added
        uint256 lpTokenExistingSupply = IERC20Lib(address(lpToken))
            .totalSupply();

        uint256 lpTokensNewSupply = (poolValue * lpTokenExistingSupply) /
            (poolValue - collateralAmount);
        uint256 lpTokensToMint = lpTokensNewSupply - lpTokenExistingSupply;
        require(lpTokensToMint >= lpTokenMinimum, "Slippage exceeded");
        lpToken.mint(msg.sender, lpTokensToMint);

        // Emit event
        emit LpTokensMinted(msg.sender, collateralAmount, lpTokensToMint);
    }

    /// LP can redeem their LP tokens in exchange for collateral
    /// If `sellTokens` is true pro-rata active b/wTokens will be sold to the pool in exchange for collateral
    /// All expired wTokens will be claimed
    /// LP will get pro-rata collateral asset
    function withdrawCapital(
        uint256 lpTokenAmount,
        bool sellTokens,
        uint256 collateralMinimum
    ) public nonReentrant {
        require(!sellTokens || collateralMinimum > 0, "E12");
        // First get starting numbers
        uint256 redeemerCollateralBalance = collateralToken.balanceOf(
            msg.sender
        );

        // Get the lpToken supply
        uint256 lpTokenSupply = IERC20Lib(address(lpToken)).totalSupply();

        // Burn the lp tokens
        lpToken.burn(msg.sender, lpTokenAmount);

        // Claim all expired wTokens
        claimAllExpiredTokens();

        uint256 collateralTokenBalance = collateralToken.balanceOf(
            address(this)
        );

        // Withdraw pro-rata collateral token
        // We withdraw this collateral here instead of at the end,
        // because when we sell the residual tokens to the pool we want
        // to exclude the withdrawn collateral
        uint256 ammCollateralBalance = collateralTokenBalance -
            ((collateralTokenBalance * lpTokenAmount) / lpTokenSupply);

        // Sell pro-rata active tokens or withdraw if no collateral left
        ammCollateralBalance = _sellOrWithdrawActiveTokens(
            lpTokenAmount,
            lpTokenSupply,
            msg.sender,
            sellTokens,
            ammCollateralBalance
        );

        // Send all accumulated collateralTokens
        collateralToken.safeTransfer(
            msg.sender,
            collateralTokenBalance - ammCollateralBalance
        );

        uint256 collateralTokenSent = collateralToken.balanceOf(msg.sender) -
            redeemerCollateralBalance;

        require(
            !sellTokens || collateralTokenSent >= collateralMinimum,
            "Slippage exceeded"
        );

        // Emit the event
        emit LpTokensBurned(msg.sender, collateralTokenSent, lpTokenAmount);
    }

    /// @notice Claims any remaining collateral from all expired series whose wToken is held by the AMM, and removes
    /// the expired series from the AMM's collection of series
    function claimAllExpiredTokens() public {
        for (uint256 i = 0; i < openSeries.length(); i++) {
            uint64 seriesId = uint64(openSeries.at(i));
            while (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.EXPIRED
            ) {
                claimExpiredTokens(seriesId);

                // Handle edge case: If, prior to removing the Series, i was the index of the last Series
                // in openSeries, then after the removal `i` will point to one beyond the end of the array.
                // This means we've iterated through all of the Series in `openSeries`, and we should break
                // out of the while loop. At this point i == openSeries.length(), so the outer for loop
                // will end as well
                if (i == openSeries.length()) {
                    break;
                } else {
                    seriesId = uint64(openSeries.at(i));
                }
            }
        }
    }

    /// @notice Claims any remaining collateral from expired series whose wToken is held by the AMM, and removes
    /// the expired series from the AMM's collection of series
    function claimExpiredTokens(uint64 seriesId) public {
        // claim the expired series' wTokens, which means it can now be safely removed
        uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
        uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

        uint256 bTokenBalance = erc1155Controller.balanceOf(
            address(this),
            bTokenIndex
        );
        if (bTokenBalance > 0) {
            seriesController.exerciseOption(seriesId, bTokenBalance, false);
        }

        uint256 wTokenBalance = erc1155Controller.balanceOf(
            address(this),
            wTokenIndex
        );
        if (wTokenBalance > 0) {
            seriesController.claimCollateral(seriesId, wTokenBalance);
        }
        // Remove the expired series to free storage and reduce gas fee
        // NOTE: openSeries.remove will remove the series from the i’th position in the EnumerableSet by
        // swapping it with the last element in EnumerableSet and then calling .pop on the internal array.
        // We are relying on this undocumented behavior of EnumerableSet, which is acceptable because once
        // deployed we will never change the EnumerableSet logic.
        openSeries.remove(seriesId);

        emit SeriesEvicted(seriesId);
    }

    /// During liquidity withdrawal we either sell pro-rata active tokens back to the pool
    /// or withdraw them to the LP
    function _sellOrWithdrawActiveTokens(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        address redeemer,
        bool sellTokens,
        uint256 collateralLeft
    ) internal returns (uint256) {
        for (uint256 i = 0; i < openSeries.length(); i++) {
            uint64 seriesId = uint64(openSeries.at(i));
            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN
            ) {
                uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
                uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

                uint256 bTokenToSell = (erc1155Controller.balanceOf(
                    address(this),
                    bTokenIndex
                ) * lpTokenAmount) / lpTokenSupply;
                uint256 wTokenToSell = (erc1155Controller.balanceOf(
                    address(this),
                    wTokenIndex
                ) * lpTokenAmount) / lpTokenSupply;
                if (!sellTokens || lpTokenAmount == lpTokenSupply) {
                    // Full LP token withdrawal for the last LP in the pool
                    // or if auto-sale is disabled
                    if (bTokenToSell > 0) {
                        bytes memory data;
                        erc1155Controller.safeTransferFrom(
                            address(this),
                            redeemer,
                            bTokenIndex,
                            bTokenToSell,
                            data
                        );
                    }
                    if (wTokenToSell > 0) {
                        bytes memory data;
                        erc1155Controller.safeTransferFrom(
                            address(this),
                            redeemer,
                            wTokenIndex,
                            wTokenToSell,
                            data
                        );
                    }
                } else {
                    // The LP sells their bToken and wToken to the AMM. The AMM
                    // pays the LP by reducing collateralLeft, which is what the
                    // AMM's collateral balance will be after executing this
                    // transaction (see MinterAmm.withdrawCapital to see where
                    // _sellOrWithdrawActiveTokens gets called)
                    uint256 collateralAmountB = optionTokenGetCollateralOutInternal(
                            seriesId,
                            bTokenToSell,
                            collateralLeft,
                            true
                        );

                    // Note! It's possible that either of the two subraction operations
                    // below will underflow and return an error. This will only
                    // happen if the AMM does not have sufficient collateral
                    // balance to buy the bToken and wToken from the LP. If this
                    // happens, this transaction will revert with a
                    // "revert" error message
                    collateralLeft -= collateralAmountB;
                    uint256 collateralAmountW = optionTokenGetCollateralOutInternal(
                            seriesId,
                            wTokenToSell,
                            collateralLeft,
                            false
                        );
                    collateralLeft -= collateralAmountW;
                }
            }
        }

        return collateralLeft;
    }

    /// Get value of all assets in the pool in units of this AMM's collateralToken.
    /// Can specify whether to include the value of expired unclaimed tokens
    function getTotalPoolValue(bool includeUnclaimed)
        public
        view
        returns (uint256)
    {
        // Note! This function assumes the price obtained from the onchain oracle
        // in getCurrentUnderlyingPrice is a valid series price in units of
        // collateralToken/paymentToken. If the onchain price oracle's value
        // were to drift from the true series price, then the bToken price
        // we calculate here would also drift, and will result in undefined
        // behavior for any functions which call getTotalPoolValue
        uint256 underlyingPrice = getCurrentUnderlyingPrice();
        // First, determine the value of all residual b/wTokens
        uint256 activeTokensValue = 0;
        uint256 expiredTokensValue = 0;
        for (uint256 i = 0; i < openSeries.length(); i++) {
            uint64 seriesId = uint64(openSeries.at(i));
            ISeriesController.Series memory series = seriesController.series(
                seriesId
            );

            uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
            uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

            uint256 bTokenBalance = erc1155Controller.balanceOf(
                address(this),
                bTokenIndex
            );
            uint256 wTokenBalance = erc1155Controller.balanceOf(
                address(this),
                wTokenIndex
            );

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN
            ) {
                // value all active bTokens and wTokens at current prices
                uint256 bPrice = getPriceForSeriesInternal(
                    series,
                    underlyingPrice
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

        // Add collateral value
        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        return activeTokensValue + expiredTokensValue + collateralBalance;
    }

    /// @notice List the Series ids this AMM trades
    /// @notice Warning: there is no guarantee that the indexes
    /// of any individual Series will remain constant between blocks. At any
    /// point the indexes of a particular Series may change, so do not rely on
    /// the indexes obtained from this function
    /// @return an array of all the series IDs
    function getAllSeries() external view returns (uint64[] memory) {
        uint64[] memory series = new uint64[](openSeries.length());
        for (uint256 i = 0; i < openSeries.length(); i++) {
            series[i] = uint64(openSeries.at(i));
        }
        return series;
    }

    /// @notice Get a specific Series that this AMM trades
    /// @notice Warning: there is no guarantee that the indexes
    /// of any individual Series will remain constant between blocks. At any
    /// point the indexes of a particular Series may change, so do not rely on
    /// the indexes obtained from this function
    /// @param seriesId the ID of the Series
    /// @return an ISeries, if it exists
    function getSeries(uint64 seriesId)
        external
        view
        returns (ISeriesController.Series memory)
    {
        require(openSeries.contains(seriesId), "E13");
        return seriesController.series(seriesId);
    }

    /// This function determines reserves of a bonding curve for a specific series.
    /// Given price of bToken we determine what is the largest pool we can create such that
    /// the ratio of its reserves satisfy the given bToken price: Rb / Rw = (1 - Pb) / Pb
    function getVirtualReserves(uint64 seriesId)
        public
        view
        returns (uint256, uint256)
    {
        require(openSeries.contains(seriesId), "E13");

        return
            getVirtualReservesInternal(
                seriesId,
                collateralToken.balanceOf(address(this))
            );
    }

    function getVirtualReservesInternal(
        uint64 seriesId,
        uint256 collateralTokenBalance
    ) internal view returns (uint256, uint256) {
        uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
        uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

        // Get residual balances
        uint256 bTokenBalance = erc1155Controller.balanceOf(
            address(this),
            bTokenIndex
        );
        uint256 wTokenBalance = erc1155Controller.balanceOf(
            address(this),
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

        uint256 bTokenPrice = getPriceForSeriesInternal(
            series,
            getCurrentUnderlyingPrice()
        );
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

    /// @dev Get the current series price of the underlying token with units of priceToken,
    /// always with 8 decimals
    /// @dev For example, if underlying == WBTC and price == USDC, then this function will return
    /// 4500000000000 ($45_000 in human readable units)
    function getCurrentUnderlyingPrice() private view returns (uint256) {
        return
            IPriceOracle(sirenPriceOracle).getCurrentPrice(
                address(underlyingToken),
                address(priceToken)
            );
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
    function getPriceForSeries(uint64 seriesId)
        external
        view
        returns (uint256)
    {
        require(openSeries.contains(seriesId), "E13");

        return
            getPriceForSeriesInternal(
                seriesController.series(seriesId),
                getCurrentUnderlyingPrice()
            );
    }

    function getPriceForSeriesInternal(
        ISeriesController.Series memory series,
        uint256 underlyingPrice
    ) private view returns (uint256) {
        return
            // Note! This function assumes the price obtained from the onchain oracle
            // in getCurrentUnderlyingPrice is a valid series price in units of
            // underlyingToken/priceToken. If the onchain price oracle's value
            // were to drift from the true series price, then the bToken price
            // we calculate here would also drift, and will result in undefined
            // behavior for any functions which call getPriceForSeries
            calcPrice(
                series.expirationDate - block.timestamp,
                series.strikePrice,
                underlyingPrice,
                volatilityFactor,
                series.isPutOption
            );
    }

    /// @dev Calculate price of bToken based on Black-Scholes approximation by Brennan-Subrahmanyam from their paper
    /// "A Simple Formula to Compute the Implied Standard Deviation" (1988).
    /// Formula: 0.4 * ImplVol * sqrt(timeUntilExpiry) * priceRatio
    ///
    /// Returns premium in units of percentage of collateral locked in a contract for both calls and puts
    function calcPrice(
        uint256 timeUntilExpiry,
        uint256 strike,
        uint256 currentPrice,
        uint256 volatility,
        bool isPutOption
    ) public pure returns (uint256) {
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

        return intrinsic + timeValue;
    }

    /// @dev Buy bToken of a given series.
    /// We supply series index instead of series address to ensure that only supported series can be traded using this AMM
    /// collateralMaximum is used for slippage protection
    function bTokenBuy(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMaximum
    ) external minTradeSize(bTokenAmount) nonReentrant returns (uint256) {
        require(openSeries.contains(seriesId), "E13");

        require(
            seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN,
            "Series has expired"
        );

        uint256 collateralAmount = bTokenGetCollateralIn(
            seriesId,
            bTokenAmount
        );
        require(collateralAmount <= collateralMaximum, "Slippage exceeded");

        // Move collateral into this contract
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );

        // Mint new options only as needed
        uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
        uint256 bTokenBalance = erc1155Controller.balanceOf(
            address(this),
            bTokenIndex
        );
        if (bTokenBalance < bTokenAmount) {
            // Approve the collateral to mint bTokenAmount of new options
            uint256 bTokenCollateralAmount = seriesController
                .getCollateralPerOptionToken(seriesId, bTokenAmount);

            collateralToken.approve(
                address(seriesController),
                bTokenCollateralAmount
            );
            seriesController.mintOptions(
                seriesId,
                bTokenAmount - bTokenBalance
            );
        }

        // Send all bTokens back
        bytes memory data;
        erc1155Controller.safeTransferFrom(
            address(this),
            msg.sender,
            bTokenIndex,
            bTokenAmount,
            data
        );

        // Emit the event
        emit BTokensBought(
            msg.sender,
            seriesId,
            bTokenAmount,
            collateralAmount
        );

        // Return the amount of collateral required to buy
        return collateralAmount;
    }

    /// @notice Sell the bToken of a given series to the AMM in exchange for collateral token
    /// @notice This call will fail if the caller tries to sell a bToken amount larger than the amount of
    /// wToken held by the AMM
    /// @param seriesId The ID of the Series to buy bToken on
    /// @param bTokenAmount The amount of bToken to sell (bToken has the same decimals as the underlying)
    /// @param collateralMinimum The lowest amount of collateral the caller is willing to receive as payment
    /// for their bToken. The actual amount of bToken received may be lower than this due to slippage
    function bTokenSell(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMinimum
    ) external minTradeSize(bTokenAmount) nonReentrant returns (uint256) {
        require(openSeries.contains(seriesId), "E13");

        require(
            seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN,
            "Series has expired"
        );

        uint256 collateralAmount = bTokenGetCollateralOut(
            seriesId,
            bTokenAmount
        );
        require(collateralAmount >= collateralMinimum, "Slippage exceeded");

        uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
        uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

        // Move bToken into this contract
        bytes memory data;
        erc1155Controller.safeTransferFrom(
            msg.sender,
            address(this),
            bTokenIndex,
            bTokenAmount,
            data
        );

        // Always be closing!
        uint256 bTokenBalance = erc1155Controller.balanceOf(
            address(this),
            bTokenIndex
        );
        uint256 wTokenBalance = erc1155Controller.balanceOf(
            address(this),
            wTokenIndex
        );
        uint256 closeAmount = Math.min(bTokenBalance, wTokenBalance);

        // at this point we know it's worth calling closePosition because
        // the close amount is greater than 0, so let's call it and burn
        // excess option tokens in order to receive collateral tokens
        seriesController.closePosition(seriesId, closeAmount);

        // Send the tokens to the seller
        collateralToken.safeTransfer(msg.sender, collateralAmount);

        // Emit the event
        emit BTokensSold(msg.sender, seriesId, bTokenAmount, collateralAmount);

        // Return the amount of collateral received during sale
        return collateralAmount;
    }

    /// @notice Calculate premium (i.e. the option price) to buy bTokenAmount bTokens for the
    /// given Series
    /// @notice The premium depends on the amount of collateral token in the pool, the reserves
    /// of bToken and wToken in the pool, and the current series price of the underlying
    /// @param seriesId The ID of the Series to buy bToken on
    /// @param bTokenAmount The amount of bToken to buy, which uses the same decimals as
    /// the underlying ERC20 token
    /// @return The amount of collateral token necessary to buy bTokenAmount worth of bTokens
    function bTokenGetCollateralIn(uint64 seriesId, uint256 bTokenAmount)
        public
        view
        returns (uint256)
    {
        // Shortcut for 0 amount
        if (bTokenAmount == 0) return 0;

        bTokenAmount = seriesController.getCollateralPerOptionToken(
            seriesId,
            bTokenAmount
        );

        // For both puts and calls balances are expressed in collateral token
        (uint256 bTokenBalance, uint256 wTokenBalance) = getVirtualReserves(
            seriesId
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

    /// @notice Calculate the amount of collateral token the user will receive for selling
    /// bTokenAmount worth of bToken to the pool. This is the option's sell price
    /// @notice The sell price depends on the amount of collateral token in the pool, the reserves
    /// of bToken and wToken in the pool, and the current series price of the underlying
    /// @param seriesId The ID of the Series to sell bToken on
    /// @param bTokenAmount The amount of bToken to sell, which uses the same decimals as
    /// the underlying ERC20 token
    /// @return The amount of collateral token the user will receive upon selling bTokenAmount of
    /// bTokens to the pool
    function bTokenGetCollateralOut(uint64 seriesId, uint256 bTokenAmount)
        public
        view
        returns (uint256)
    {
        return
            optionTokenGetCollateralOutInternal(
                seriesId,
                bTokenAmount,
                collateralToken.balanceOf(address(this)),
                true
            );
    }

    /// @notice Sell the wToken of a given series to the AMM in exchange for collateral token
    /// @param seriesId The ID of the Series to buy wToken on
    /// @param wTokenAmount The amount of wToken to sell (wToken has the same decimals as the underlying)
    /// @param collateralMinimum The lowest amount of collateral the caller is willing to receive as payment
    /// for their wToken. The actual amount of wToken received may be lower than this due to slippage
    function wTokenSell(
        uint64 seriesId,
        uint256 wTokenAmount,
        uint256 collateralMinimum
    ) external minTradeSize(wTokenAmount) nonReentrant returns (uint256) {
        require(openSeries.contains(seriesId), "E13");

        require(
            seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN,
            "Series has expired"
        );

        // Get initial stats
        uint256 collateralAmount = wTokenGetCollateralOut(
            seriesId,
            wTokenAmount
        );
        require(collateralAmount >= collateralMinimum, "Slippage exceeded");

        uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
        uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

        // Move wToken into this contract
        bytes memory data;
        erc1155Controller.safeTransferFrom(
            msg.sender,
            address(this),
            wTokenIndex,
            wTokenAmount,
            data
        );

        // Always be closing!
        uint256 bTokenBalance = erc1155Controller.balanceOf(
            address(this),
            bTokenIndex
        );
        uint256 wTokenBalance = erc1155Controller.balanceOf(
            address(this),
            wTokenIndex
        );
        uint256 closeAmount = Math.min(bTokenBalance, wTokenBalance);
        if (closeAmount > 0) {
            seriesController.closePosition(seriesId, closeAmount);
        }

        // Send the tokens to the seller
        collateralToken.safeTransfer(msg.sender, collateralAmount);

        // Emit the event
        emit WTokensSold(msg.sender, seriesId, wTokenAmount, collateralAmount);

        // Return the amount of collateral received during sale
        return collateralAmount;
    }

    /// @notice Calculate amount of collateral in exchange for selling wTokens
    function wTokenGetCollateralOut(uint64 seriesId, uint256 wTokenAmount)
        public
        view
        returns (uint256)
    {
        return
            optionTokenGetCollateralOutInternal(
                seriesId,
                wTokenAmount,
                collateralToken.balanceOf(address(this)),
                false
            );
    }

    /// @dev Calculates the amount of collateral token a seller will receive for selling their option tokens,
    /// taking into account the AMM's level of reserves
    /// @param seriesId The ID of the Series
    /// @param optionTokenAmount The amount of option tokens (either bToken or wToken) to be sold
    /// @param _collateralTokenBalance The amount of collateral token held by this AMM
    /// @param isBToken true if the option token is bToken, and false if it's wToken. Depending on which
    /// of the two it is, the equation for calculating the final collateral token is a little different
    /// @return The amount of collateral token the seller will receive in exchange for their option token
    function optionTokenGetCollateralOutInternal(
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 _collateralTokenBalance,
        bool isBToken
    ) private view returns (uint256) {
        // Shortcut for 0 amount
        if (optionTokenAmount == 0) return 0;

        optionTokenAmount = seriesController.getCollateralPerOptionToken(
            seriesId,
            optionTokenAmount
        );

        (
            uint256 bTokenBalance,
            uint256 wTokenBalance
        ) = getVirtualReservesInternal(seriesId, _collateralTokenBalance);

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

    /// @notice Calculate the amount of collateral the AMM would received if all of the
    /// expired Series' wTokens and bTokens were to be redeemed for their underlying collateral
    /// value
    /// @return The amount of collateral token the AMM would receive if it were to exercise/claim
    /// all expired bTokens/wTokens
    function getCollateralValueOfAllExpiredOptionTokens()
        public
        view
        returns (uint256)
    {
        uint256 unredeemedCollateral = 0;

        for (uint256 i = 0; i < openSeries.length(); i++) {
            uint64 seriesId = uint64(openSeries.at(i));

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.EXPIRED
            ) {
                uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
                uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

                // Get the pool's option token balances
                uint256 bTokenBalance = erc1155Controller.balanceOf(
                    address(this),
                    bTokenIndex
                );
                uint256 wTokenBalance = erc1155Controller.balanceOf(
                    address(this),
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
    function getOptionTokensSaleValue(uint256 lpTokenAmount)
        external
        view
        returns (uint256)
    {
        if (lpTokenAmount == 0) return 0;

        uint256 lpTokenSupply = IERC20Lib(address(lpToken)).totalSupply();
        if (lpTokenSupply == 0) return 0;

        // Calculate the amount of collateral receivable by redeeming all the expired option tokens
        uint256 expiredOptionTokenCollateral = getCollateralValueOfAllExpiredOptionTokens();

        // Calculate amount of collateral left in the pool to sell tokens to
        uint256 totalCollateral = expiredOptionTokenCollateral +
            collateralToken.balanceOf(address(this));

        // Subtract pro-rata collateral amount to be withdrawn
        totalCollateral =
            (totalCollateral * (lpTokenSupply - lpTokenAmount)) /
            lpTokenSupply;

        // Given remaining collateral calculate how much all tokens can be sold for
        uint256 collateralLeft = totalCollateral;
        for (uint256 i = 0; i < openSeries.length(); i++) {
            uint64 seriesId = uint64(openSeries.at(i));

            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN
            ) {
                uint256 bTokenToSell = (erc1155Controller.balanceOf(
                    address(this),
                    SeriesLibrary.bTokenIndex(seriesId)
                ) * lpTokenAmount) / lpTokenSupply;
                uint256 wTokenToSell = (erc1155Controller.balanceOf(
                    address(this),
                    SeriesLibrary.wTokenIndex(seriesId)
                ) * lpTokenAmount) / lpTokenSupply;

                uint256 collateralAmountB = optionTokenGetCollateralOutInternal(
                    seriesId,
                    bTokenToSell,
                    collateralLeft,
                    true
                );
                collateralLeft -= collateralAmountB;

                uint256 collateralAmountW = optionTokenGetCollateralOutInternal(
                    seriesId,
                    wTokenToSell,
                    collateralLeft,
                    false
                );
                collateralLeft -= collateralAmountW;
            }
        }

        return totalCollateral - collateralLeft;
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
    ) private view returns (uint256) {
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

    /// @notice Adds the address of series to the amm
    /// @dev Only the associated SeriesController may call this function
    /// @dev The SeriesController calls this function when it is creating a Series
    /// and adds the Series to this AMM
    function addSeries(uint64 _seriesId) external override {
        require(msg.sender == address(seriesController), "E11");
        // Prevents out of gas error, occuring at 250 series, from locking
        // in LPs when we cycle over openSeries in _sellOrWithdrawActiveTokens.
        // We further lower the limit to 100 series for extra safety.
        require(openSeries.length() <= 100, "Too many open series");
        openSeries.add(_seriesId);
    }

    /// @notice Returns true when interfaceId is the ID of the addSeries function or the ERC165
    /// standard, and false otherwise
    /// @dev This function exists only so the SeriesController can tell when to try to add
    /// Series it has created to the MinterAmm
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == this.addSeries.selector ||
            super.supportsInterface(interfaceId);
    }
}