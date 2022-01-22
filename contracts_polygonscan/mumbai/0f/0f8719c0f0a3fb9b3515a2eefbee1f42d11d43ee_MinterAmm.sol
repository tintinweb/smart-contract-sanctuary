// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "../libraries/Math.sol";
import "../proxy/Proxiable.sol";
import "../proxy/Proxy.sol";
import "./IAmmDataProvider.sol";
import "../series/IPriceOracle.sol";
import "../swap/ILight.sol";
import "../token/IERC20Lib.sol";
import "../oz/EnumerableSet.sol";
import "../series/SeriesLibrary.sol";
import "./MinterAmmStorage.sol";
import "../series/IVolatilityOracle.sol";
import "./IBlackScholes.sol";
import "./IWTokenVault.sol";

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
/// If fees are enabled (3 params are configured: trade fee, max fee, and fee destination) a trade fee will be collected and
/// sent to an external acct.  Fee calculations mimic the Deribit fee schedule (see https://www.deribit.com/pages/information/fees for
/// their explanation with examples of BTC/ETH options). Each buy/sell has a trade fee percentage
/// based on the number of underlying option contracts (bToken amt) priced in the collateral token.
/// Additionally, there is a max fee percentage based on the option value being bought or sold (collateral paid or received).
/// The lower of the 2 fees calculated will be used.  Fees are paid out on each buy or sell of bTokens to a configured address.
///
/// Fee Example: If trade fee is 3 basis points and max fee is 1250 basis points and a buy of bTokens is priced at 0.0001 collateral
/// tokens, the fee will be 0.0000125 collateral tokens (using the max fee). If the option prices are much higher then 0.0003
/// of collateral would be the fee for each bToken.
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
    Proxiable,
    ERC1155HolderUpgradeable,
    OwnableUpgradeable,
    MinterAmmStorageV3
{
    /// @dev NOTE: No local variables should be added here.  Instead see MinterAmmStorageV*.sol

    /// Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;
    using SafeERC20 for ISimpleToken;

    using EnumerableSet for EnumerableSet.UintSet;

    /// Emitted when the amm is created
    event AMMInitialized(ISimpleToken lpToken, address controller);

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

    /// @notice Emitted when an expired series has been removed
    event SeriesEvicted(uint64 seriesId);

    /// Emitted when the owner updates fee params
    event TradeFeesUpdated(
        uint16 newTradeFeeBasisPoints,
        uint16 newMaxOptionFeeBasisPoints,
        address newFeeDestinationAddress
    );

    event ConfigUpdated(
        int256 ivShift,
        bool dynamicIvEnabled,
        uint16 ivDriftRate
    );

    // Emitted when fees are paid
    event TradeFeesPaid(address indexed feePaidTo, uint256 feeAmount);

    //Emitted when AddressesProvider is updated
    event AddressesProviderUpdated(address addressesProvider);

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
    // E13: Series does not exist on this AMM
    // E14: Invalid _newAmmDataProvider
    // E15: Invalid _ammDataProvider
    // E16: Invalid lightAirswapAddress
    // E17: Option price is 0
    // E18: Invalid expirationId
    // E19: Negative IV
    // E20: Slippage exceeded
    // E21: Last LP can't sell wTokens to the pool
    // E22: Series has expired
    // E23: Trade amount is too low
    // E24: Too many open series

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
        IAddressesProvider _addressesProvider,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        ISimpleToken _lpToken,
        uint16 _tradeFeeBasisPoints
    ) public override {
        // AMMs are created only by the AmmFactory contract which already checks these
        // So we can remove them to reduce contract size
        // require(address(_underlyingToken) != address(0x0), "E03");
        // require(address(_priceToken) != address(0x0), "E04");
        // require(address(_collateralToken) != address(0x0), "E05");
        // require(address(_underlyingToken) != address(_priceToken), "E06");
        // require(_tokenImplementation != address(0x0), "E07");

        // Enforce initialization can only happen once
        require(!initialized, "E08");
        initialized = true;

        // Save off state variables
        seriesController = _seriesController;
        addressesProvider = _addressesProvider;
        erc1155Controller = IERC1155(_seriesController.erc1155Controller());

        // Approve seriesController to move tokens
        erc1155Controller.setApprovalForAll(address(seriesController), true);

        tradeFeeBasisPoints = _tradeFeeBasisPoints;

        // Save off series tokens
        underlyingToken = _underlyingToken;
        priceToken = _priceToken;
        collateralToken = _collateralToken;
        lpToken = _lpToken;

        __Ownable_init();

        emit AMMInitialized(lpToken, address(_seriesController));
    }

    function updateAddressesProvider(address _addressesProvider)
        external
        override
        onlyOwner
    {
        //How do we want to handle when we update the addressProvider that it has the proper contracts set
        addressesProvider = IAddressesProvider(_addressesProvider);
        emit AddressesProviderUpdated(_addressesProvider);
    }

    /// Get volatility of a series
    function getVolatility(uint64 _seriesId)
        public
        view
        override
        returns (uint256)
    {
        SeriesVolatility memory seriesVolatility = seriesVolatilities[
            _seriesId
        ];

        uint256 targetVolatility = getBaselineVolatility();
        int256 iv;

        if (
            seriesVolatility.updatedAt == 0 ||
            seriesVolatility.volatility == targetVolatility
        ) {
            // Volatility hasn't been initialized for this series
            iv = int256(targetVolatility);
        } else {
            if (ivDriftRate == 0) return seriesVolatility.volatility;

            int256 ivDrift = ((int256(targetVolatility) -
                int256(seriesVolatility.volatility)) *
                int256(block.timestamp - seriesVolatility.updatedAt)) /
                int256(ivDriftRate);
            iv = int256(seriesVolatility.volatility) + ivDrift;

            if (
                (ivDrift > 0 && iv > int256(targetVolatility)) ||
                (ivDrift < 0 && iv < int256(targetVolatility))
            ) {
                iv = int256(targetVolatility);
            }
        }

        return uint256(iv);
    }

    /// Each time a trade happens we update the volatility
    function updateVolatility(
        uint64 _seriesId,
        int256 priceImpact,
        uint256 currentIV,
        uint256 vega
    ) internal returns (uint256) {
        int256 newIV = int256(currentIV) + (priceImpact * 1e18) / int256(vega);

        // TODO: ability to set IV range
        int256 MAX_IV = 4e18; // 400%
        int256 MIN_IV = 5e17; // 50%
        if (newIV > MAX_IV) {
            newIV = MAX_IV;
        } else if (newIV < MIN_IV) {
            newIV = MIN_IV;
        }
        SeriesVolatility storage seriesVolatility = seriesVolatilities[
            _seriesId
        ];
        seriesVolatility.volatility = uint256(newIV);
        seriesVolatility.updatedAt = block.timestamp;
    }

    function getBaselineVolatility() public view override returns (uint256) {
        int256 iv = int256(
            IVolatilityOracle(addressesProvider.getVolatilityOracle())
                .annualizedVol(address(underlyingToken), address(priceToken))
        ) *
            1e10 + // oracle stores volatility in 8 decimals precision, here we operate at 18 decimals
            ivShift;

        require(iv > 3e17, "E19"); // 30% minimum

        return uint256(iv);
    }

    /// The owner can set the trade fee params - if any are set to 0/0x0 then trade fees are disabled
    function setTradingFeeParams(
        uint16 _tradeFeeBasisPoints,
        uint16 _maxOptionFeeBasisPoints,
        address _feeDestinationAddress
    ) public onlyOwner {
        tradeFeeBasisPoints = _tradeFeeBasisPoints;
        maxOptionFeeBasisPoints = _maxOptionFeeBasisPoints;
        feeDestinationAddress = _feeDestinationAddress;
        emit TradeFeesUpdated(
            tradeFeeBasisPoints,
            maxOptionFeeBasisPoints,
            feeDestinationAddress
        );
    }

    /// Owner can set volatility config
    function setAmmConfig(
        int256 _ivShift,
        bool _dynamicIvEnabled,
        uint16 _ivDriftRate
    ) external override onlyOwner {
        ivShift = _ivShift;
        dynamicIvEnabled = _dynamicIvEnabled;
        ivDriftRate = _ivDriftRate;

        emit ConfigUpdated(ivShift, dynamicIvEnabled, ivDriftRate);
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

    function getAmmDataProvider() public view returns (IAmmDataProvider) {
        return IAmmDataProvider(addressesProvider.getAmmDataProvider());
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

        uint256 poolValue = getAmmDataProvider().getTotalPoolValue(
            false,
            getAllSeries(),
            collateralBalance(),
            address(this),
            getBaselineVolatility()
        );

        // Mint LP tokens - the percentage added to bTokens should be same as lp tokens added
        uint256 lpTokenExistingSupply = IERC20Lib(address(lpToken))
            .totalSupply();

        uint256 lpTokensNewSupply = (poolValue * lpTokenExistingSupply) /
            (poolValue - collateralAmount);
        uint256 lpTokensToMint = lpTokensNewSupply - lpTokenExistingSupply;
        require(lpTokensToMint >= lpTokenMinimum, "E20");
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

        uint256 collateralTokenBalance = collateralBalance();

        // Withdraw pro-rata collateral token
        // We withdraw this collateral here instead of at the end,
        // because when we sell the residual tokens to the pool we want
        // to exclude the withdrawn collateral
        uint256 ammCollateralBalance = collateralTokenBalance -
            ((collateralTokenBalance * lpTokenAmount) / lpTokenSupply);

        if (sellTokens) {
            // Sell pro-rata active tokens
            require(lpTokenAmount < lpTokenSupply, "E21");
            ammCollateralBalance = _sellActiveTokens(
                lpTokenAmount,
                lpTokenSupply,
                ammCollateralBalance
            );
        } else {
            // Lock tokens
            IWTokenVault(addressesProvider.getWTokenVault()).lockActiveWTokens(
                lpTokenAmount,
                lpTokenSupply,
                msg.sender,
                getBaselineVolatility()
            );
        }

        // Send all accumulated collateralTokens
        collateralToken.safeTransfer(
            msg.sender,
            collateralTokenBalance - ammCollateralBalance
        );

        uint256 collateralTokenSent = collateralToken.balanceOf(msg.sender) -
            redeemerCollateralBalance;
        require(!sellTokens || collateralTokenSent >= collateralMinimum, "E20");

        // Emit the event
        emit LpTokensBurned(msg.sender, collateralTokenSent, lpTokenAmount);
    }

    /// Withdraws locked collateral
    function withdrawLockedCollateral(uint64[] memory expirationIds)
        external
        nonReentrant
    {
        // Claim all expired tokens
        claimAllExpiredTokens();

        uint256 claimableCollateral;

        for (uint256 i = 0; i < expirationIds.length; i++) {
            uint64 expirationId = expirationIds[i];
            uint256 expiration = seriesController.allowedExpirationsList(
                expirationId
            );
            require(expiration > 0, "E18");

            claimableCollateral += IWTokenVault(
                addressesProvider.getWTokenVault()
            ).redeemCollateral(expirationId, msg.sender);
        }

        lockedCollateral -= claimableCollateral;

        collateralToken.safeTransfer(msg.sender, claimableCollateral);
    }

    function lockCollateral(
        uint64 seriesId,
        uint256 collateralAmountMax,
        uint256 wTokenAmountMax
    ) internal {
        IWTokenVault wTokenVault = IWTokenVault(
            addressesProvider.getWTokenVault()
        );

        uint256 lockedWTokenBalance = wTokenVault.getWTokenBalance(
            address(this),
            seriesId
        );

        if (lockedWTokenBalance == 0) return;

        uint256 closedWTokens = Math.min(lockedWTokenBalance, wTokenAmountMax);
        uint256 collateralToLock = (collateralAmountMax * closedWTokens) /
            wTokenAmountMax;

        wTokenVault.lockCollateral(seriesId, collateralToLock, closedWTokens);

        lockedCollateral += collateralToLock;
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
            uint256 collateralClaimed = seriesController.claimCollateral(
                seriesId,
                wTokenBalance
            );

            lockCollateral(seriesId, collateralClaimed, wTokenBalance);
        }
        // Remove the expired series to free storage and reduce gas fee
        // NOTE: openSeries.remove will remove the series from the i’th position in the EnumerableSet by
        // swapping it with the last element in EnumerableSet and then calling .pop on the internal array.
        // We are relying on this undocumented behavior of EnumerableSet, which is acceptable because once
        // deployed we will never change the EnumerableSet logic.
        openSeries.remove(seriesId);

        emit SeriesEvicted(seriesId);
    }

    /// During liquidity withdrawal pro-rata active tokens back to the pool
    function _sellActiveTokens(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 collateralLeft
    ) internal view returns (uint256) {
        IWTokenVault wTokenVault = IWTokenVault(
            addressesProvider.getWTokenVault()
        );

        for (uint256 i = 0; i < openSeries.length(); i++) {
            uint64 seriesId = uint64(openSeries.at(i));
            if (
                seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN
            ) {
                uint256 wTokenIndex = SeriesLibrary.wTokenIndex(seriesId);

                // Get wToken balance excluding locked tokens
                uint256 wTokenAmount = ((erc1155Controller.balanceOf(
                    address(this),
                    wTokenIndex
                ) - wTokenVault.getWTokenBalance(address(this), seriesId)) *
                    lpTokenAmount) / lpTokenSupply;

                if (wTokenAmount > 0) {
                    // The LP sells their bToken and wToken to the AMM. The AMM
                    // pays the LP by reducing collateralLeft, which is what the
                    // AMM's collateral balance will be after executing this
                    // transaction (see MinterAmm.withdrawCapital to see where
                    // _sellActiveTokens gets called)
                    uint256 bTokenPrice = getPriceForSeries(seriesId);

                    // Note! It's possible that either of the two subraction operations
                    // below will underflow and return an error. This will only
                    // happen if the AMM does not have sufficient collateral
                    // balance to buy the bToken and wToken from the LP. If this
                    // happens, this transaction will revert with a
                    // "revert" error message
                    uint256 collateralAmountW = optionTokenGetCollateralOutInternal(
                            seriesId,
                            wTokenAmount,
                            collateralLeft,
                            bTokenPrice,
                            false
                        );
                    collateralLeft -= collateralAmountW;
                }
            }
        }

        return collateralLeft;
    }

    /// @notice List the Series ids this AMM trades
    /// @notice Warning: there is no guarantee that the indexes
    /// of any individual Series will remain constant between blocks. At any
    /// point the indexes of a particular Series may change, so do not rely on
    /// the indexes obtained from this function
    /// @return an array of all the series IDs
    function getAllSeries() public view override returns (uint64[] memory) {
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

    /// @dev Get the current series price of the underlying token with units of priceToken,
    /// always with 8 decimals
    /// @dev For example, if underlying == WBTC and price == USDC, then this function will return
    /// 4500000000000 ($45_000 in human readable units)
    function getCurrentUnderlyingPrice()
        public
        view
        override
        returns (uint256)
    {
        return
            IPriceOracle(addressesProvider.getPriceOracle()).getCurrentPrice(
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
    function getPriceForSeries(uint64 seriesId) public view returns (uint256) {
        require(openSeries.contains(seriesId), "E13");

        return
            getAmmDataProvider().getPriceForSeries(
                seriesId,
                getVolatility(seriesId)
            );
    }

    /// @dev Calculate the fee amount for a buy/sell
    /// If params are not set, the fee amount will be 0
    /// See contract comments above for logic explanation of fee calculations.
    function calculateFees(uint256 bTokenAmount, uint256 collateralAmount)
        public
        view
        override
        returns (uint256)
    {
        // Check if fees are enabled
        if (
            tradeFeeBasisPoints > 0 &&
            maxOptionFeeBasisPoints > 0 &&
            feeDestinationAddress != address(0x0)
        ) {
            uint256 tradeFee = 0;

            // The default fee is the basis points of the number of options being bought (e.g. bToken amount)
            uint256 defaultFee = (bTokenAmount * tradeFeeBasisPoints) / 10_000;

            // The max fee is based on the maximum percentage of the collateral being paid to buy the options
            uint256 maxFee = (collateralAmount * maxOptionFeeBasisPoints) /
                10_000;

            // Use the smaller of the 2
            if (defaultFee < maxFee) {
                tradeFee = defaultFee;
            } else {
                tradeFee = maxFee;
            }

            return tradeFee;
        }

        // Fees are not enabled
        return 0;
    }

    /// @dev Allows an owner to invoke a Direct Buy against the AMM
    /// A direct buy allows a signer wallet to predetermine a number of option
    ///     tokens to buy (senderAmount) with the specified number of collateral payment tokens (signerTokens).
    /// The direct buy will first use the collateral in the AMM to mint the options and
    ///     then execute a swap with the signer using Airswap protocol.
    /// Only the owner should be allowed to execute a direct buy as this is a "guarded" call.
    /// Sender address in the Airswap protocol will be this contract address.
    function bTokenDirectBuy(
        uint64 seriesId,
        uint256 nonce, // Nonce on the airswap sig for the signer
        uint256 expiry, // Date until swap is valid
        address signerWallet, // Address of the buyer (signer)
        uint256 signerAmount, // Amount of collateral that will be paid for options by the signer
        uint256 senderAmount, // Amount of options to buy from the AMM
        uint8 v, // Sig of signer wallet for Airswap
        bytes32 r, // Sig of signer wallet for Airswap
        bytes32 s // Sig of signer wallet for Airswap
    ) external nonReentrant {
        require(
            msg.sender == addressesProvider.getDirectBuyManager(),
            "!manager"
        );
        require(openSeries.contains(seriesId), "E13");

        address airswapLight = addressesProvider.getAirswapLight();
        require(airswapLight != address(0x0), "E16");

        // Get the bToken balance of the AMM
        uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);
        uint256 bTokenBalance = erc1155Controller.balanceOf(
            address(this),
            bTokenIndex
        );

        // Mint required number of bTokens for the direct buy (if required)
        if (bTokenBalance < senderAmount) {
            // Approve the collateral to mint bTokenAmount of new options
            uint256 bTokenCollateralAmount = seriesController
                .getCollateralPerOptionToken(
                    seriesId,
                    senderAmount - bTokenBalance
                );

            collateralToken.approve(
                address(seriesController),
                bTokenCollateralAmount
            );

            // If the AMM does not have enough collateral to mint tokens, expect revert.
            seriesController.mintOptions(
                seriesId,
                senderAmount - bTokenBalance
            );
        }

        // Approve the bTokens to be swapped
        erc1155Controller.setApprovalForAll(airswapLight, true);

        // Now that the contract has enough bTokens, swap with the buyer
        ILight(airswapLight).swap(
            nonce, // Signer's nonce
            expiry, // Expiration date of swap
            signerWallet, // Buyer of the options
            address(collateralToken), // Payment made by buyer
            signerAmount, // Amount of collateral paid for options
            address(erc1155Controller), // Address of erc1155 contract
            bTokenIndex, // Token ID for options
            senderAmount, // Num options to sell
            v,
            r,
            s
        ); // Sig of signer for swap

        // Remove approval
        erc1155Controller.setApprovalForAll(airswapLight, false);

        // Calculate trade fees if they are enabled with all params set
        uint256 tradeFee = calculateFees(senderAmount, signerAmount);

        // If fees were taken, move them to the destination
        if (tradeFee > 0) {
            collateralToken.safeTransfer(feeDestinationAddress, tradeFee);
            emit TradeFeesPaid(feeDestinationAddress, tradeFee);
        }

        // Emit the event
        emit BTokensBought(signerWallet, seriesId, senderAmount, signerAmount);
    }

    /// @dev Buy bToken of a given series.
    /// We supply series index instead of series address to ensure that only supported series can be traded using this AMM
    /// collateralMaximum is used for slippage protection.
    /// @notice Trade fees are added to the collateral amount moved from the buyer's account to pay for the bToken
    function bTokenBuy(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMaximum
    ) external override nonReentrant returns (uint256) {
        require(openSeries.contains(seriesId), "E13");

        require(
            seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN,
            "E22" // Series has expired
        );
        uint256 collateralAmount;
        {
            uint256 underlyingPrice = getCurrentUnderlyingPrice();
            (uint256 price, uint256 vega) = calculatePriceAndVega(
                seriesId,
                underlyingPrice
            );
            require(price > 0, "E17");

            collateralAmount = getAmmDataProvider().bTokenGetCollateralIn(
                seriesId,
                address(this),
                bTokenAmount,
                collateralBalance(),
                price
            );
            require(
                collateralAmount * 1e18 >=
                    seriesController.getCollateralPerUnderlying(
                        seriesId,
                        price * bTokenAmount,
                        underlyingPrice
                    ),
                "E23" // Buy amount is too low
            );

            if (dynamicIvEnabled) {
                uint256 priceImpact;
                if (seriesController.isPutOption(seriesId)) {
                    priceImpact =
                        (collateralAmount * 1e26) /
                        seriesController.getCollateralPerUnderlying(
                            seriesId,
                            bTokenAmount,
                            1e8
                        ) /
                        underlyingPrice -
                        price;
                } else {
                    priceImpact =
                        (collateralAmount * 1e18) /
                        bTokenAmount -
                        price;
                }

                updateVolatility(
                    seriesId,
                    int256(priceImpact),
                    getVolatility(seriesId),
                    vega
                );
            }
        }

        // Calculate trade fees if they are enabled with all params set
        uint256 tradeFee = calculateFees(bTokenAmount, collateralAmount);
        require(
            collateralAmount + tradeFee <= collateralMaximum,
            "E20" // Slippage exceeded
        );

        // Move collateral into this contract
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount + tradeFee
        );

        // If fees were taken, move them to the destination
        if (tradeFee > 0) {
            collateralToken.safeTransfer(feeDestinationAddress, tradeFee);
            emit TradeFeesPaid(feeDestinationAddress, tradeFee);
        }

        // Approve the collateral to mint bTokenAmount of new options
        uint256 bTokenCollateralAmount = seriesController
            .getCollateralPerOptionToken(seriesId, bTokenAmount);

        collateralToken.approve(
            address(seriesController),
            bTokenCollateralAmount
        );
        seriesController.mintOptions(seriesId, bTokenAmount);

        // Send all bTokens back
        bytes memory data;
        erc1155Controller.safeTransferFrom(
            address(this),
            msg.sender,
            SeriesLibrary.bTokenIndex(seriesId),
            bTokenAmount,
            data
        );

        // Emit the event
        emit BTokensBought(
            msg.sender,
            seriesId,
            bTokenAmount,
            collateralAmount + tradeFee
        );

        // Return the amount of collateral required to buy
        return collateralAmount + tradeFee;
    }

    /// @notice Sell the bToken of a given series to the AMM in exchange for collateral token
    /// @notice This call will fail if the caller tries to sell a bToken amount larger than the amount of
    /// wToken held by the AMM
    /// @notice Trade fees are subracted from the collateral amount moved to the seller's account in exchange for bTokens
    /// @param seriesId The ID of the Series to buy bToken on
    /// @param bTokenAmount The amount of bToken to sell (bToken has the same decimals as the underlying)
    /// @param collateralMinimum The lowest amount of collateral the caller is willing to receive as payment
    /// for their bToken. The actual amount of bToken received may be lower than this due to slippage
    function bTokenSell(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMinimum
    ) external override nonReentrant returns (uint256) {
        require(openSeries.contains(seriesId), "E13");

        require(
            seriesController.state(seriesId) ==
                ISeriesController.SeriesState.OPEN,
            "E22" // Series has expired
        );
        uint256 collateralAmount;
        {
            uint256 underlyingPrice = getCurrentUnderlyingPrice();
            (uint256 price, uint256 vega) = calculatePriceAndVega(
                seriesId,
                underlyingPrice
            );
            require(price > 0, "E17");

            collateralAmount = optionTokenGetCollateralOutInternal(
                seriesId,
                bTokenAmount,
                collateralBalance(),
                price,
                true
            );
            require(
                collateralAmount * 1e18 <=
                    seriesController.getCollateralPerUnderlying(
                        seriesId,
                        price * bTokenAmount,
                        underlyingPrice
                    ),
                "E23" // Sell amount is too low
            );

            if (dynamicIvEnabled) {
                uint256 priceImpact;
                if (seriesController.isPutOption(seriesId)) {
                    priceImpact =
                        price -
                        (collateralAmount * 1e26) /
                        seriesController.getCollateralPerUnderlying(
                            seriesId,
                            bTokenAmount,
                            1e8
                        ) /
                        underlyingPrice;
                } else {
                    priceImpact =
                        price -
                        (collateralAmount * 1e18) /
                        bTokenAmount;
                }

                updateVolatility(
                    seriesId,
                    -int256(priceImpact),
                    getVolatility(seriesId),
                    vega
                );
            }
        }

        // Calculate trade fees if they are enabled with all params set
        uint256 tradeFee = calculateFees(bTokenAmount, collateralAmount);

        require(
            collateralAmount - tradeFee >= collateralMinimum,
            "E20" // Slippage exceeded
        );

        uint256 bTokenIndex = SeriesLibrary.bTokenIndex(seriesId);

        // Move bToken into this contract
        bytes memory data;
        erc1155Controller.safeTransferFrom(
            msg.sender,
            address(this),
            bTokenIndex,
            bTokenAmount,
            data
        );

        // at this point we know it's worth calling closePosition because
        // the close amount is greater than 0, so let's call it and burn
        // excess option tokens in order to receive collateral tokens
        // and lock collateral in the WTokenVault
        lockCollateral(
            seriesId,
            seriesController.closePosition(seriesId, bTokenAmount) -
                collateralAmount,
            bTokenAmount
        );

        // Send the tokens to the seller
        collateralToken.safeTransfer(msg.sender, collateralAmount - tradeFee);

        // If fees were taken, move them to the destination
        if (tradeFee > 0) {
            collateralToken.safeTransfer(feeDestinationAddress, tradeFee);
            emit TradeFeesPaid(feeDestinationAddress, tradeFee);
        }

        // Emit the event
        emit BTokensSold(
            msg.sender,
            seriesId,
            bTokenAmount,
            collateralAmount - tradeFee
        );

        // Return the amount of collateral received during sale
        return collateralAmount - tradeFee;
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
        uint256 bTokenPrice,
        bool isBToken
    ) private view returns (uint256) {
        return
            getAmmDataProvider().optionTokenGetCollateralOut(
                seriesId,
                address(this),
                optionTokenAmount,
                _collateralTokenBalance,
                bTokenPrice,
                isBToken
            );
    }

    /// @notice Adds the address of series to the amm
    /// @dev Only the associated SeriesController may call this function
    /// @dev The SeriesController calls this function when it is creating a Series
    /// and adds the Series to this AMM
    function addSeries(uint64 _seriesId) external override {
        require(msg.sender == address(seriesController), "E11");
        // Prevents out of gas error, occuring at 250 series, from locking
        // in LPs when we cycle over openSeries in _sellActiveTokens.
        // We further lower the limit to 60 series for extra safety.
        require(openSeries.length() <= 60, "E24"); // Too many open series
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

    function calculatePriceAndVega(uint64 seriesId, uint256 underlyingPrice)
        internal
        view
        returns (uint256 price, uint256 vega)
    {
        ISeriesController.Series memory series = seriesController.series(
            seriesId
        );
        IBlackScholes blackScholes = IBlackScholes(
            addressesProvider.getBlackScholes()
        );

        IBlackScholes.PricesStdVega memory pricesStdVega = blackScholes
            .pricesStdVegaInUnderlying(
                series.expirationDate - block.timestamp,
                getVolatility(seriesId),
                underlyingPrice,
                series.strikePrice,
                0,
                series.isPutOption
            );
        return (pricesStdVega.price, pricesStdVega.stdVega);
    }

    function collateralBalance() public view override returns (uint256) {
        return collateralToken.balanceOf(address(this)) - lockedCollateral;
    }
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

// a library for performing various math operations

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        return b;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    event CodeAddressUpdated(address newAddress);

    function _updateCodeAddress(address newAddress) internal {
        require(
            bytes32(PROXY_MEM_SLOT) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, newAddress)
        }

        emit CodeAddressUpdated(newAddress);
    }

    function getLogicAddress() public view returns (address logicAddress) {
        assembly {
            // solium-disable-line
            logicAddress := sload(PROXY_MEM_SLOT)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return bytes32(PROXY_MEM_SLOT);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

contract Proxy {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXY_MEM_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    constructor(address contractLogic) public {
        // Verify a valid address was passed in
        require(contractLogic != address(0), "Contract Logic cannot be 0x0");

        // save the code address
        assembly {
            // solium-disable-line
            sstore(PROXY_MEM_SLOT, contractLogic)
        }
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(PROXY_MEM_SLOT)
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let success := delegatecall(
                gas(),
                contractLogic,
                ptr,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(ptr, 0, retSz)
            switch success
            case 0 {
                revert(ptr, retSz)
            }
            default {
                return(ptr, retSz)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

interface IAmmDataProvider {
    function getVirtualReserves(
        uint64 seriesId,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) external view returns (uint256, uint256);

    function bTokenGetCollateralIn(
        uint64 seriesId,
        address ammAddress,
        uint256 bTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice
    ) external view returns (uint256);

    function optionTokenGetCollateralOut(
        uint64 seriesId,
        address ammAddress,
        uint256 optionTokenAmount,
        uint256 collateralTokenBalance,
        uint256 bTokenPrice,
        bool isBToken
    ) external view returns (uint256);

    function getCollateralValueOfAllExpiredOptionTokens(
        uint64[] memory openSeries,
        address ammAddress
    ) external view returns (uint256);

    function getOptionTokensSaleValue(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint64[] memory openSeries,
        address ammAddress,
        uint256 collateralTokenBalance,
        uint256 impliedVolatility
    ) external view returns (uint256);

    function getPriceForSeries(uint64 seriesId, uint256 annualVolatility)
        external
        view
        returns (uint256);

    function getTotalPoolValue(
        bool includeUnclaimed,
        uint64[] memory openSeries,
        uint256 collateralBalance,
        address ammAddress,
        uint256 impliedVolatility
    ) external view returns (uint256);

    function getRedeemableCollateral(uint64 seriesId, uint256 wTokenBalance)
        external
        view
        returns (uint256);

    function getTotalPoolValueView(address ammAddress, bool includeUnclaimed)
        external
        view
        returns (uint256);

    function bTokenGetCollateralInView(
        address ammAddress,
        uint64 seriesId,
        uint256 bTokenAmount
    ) external view returns (uint256);

    function bTokenGetCollateralOutView(
        address ammAddress,
        uint64 seriesId,
        uint256 bTokenAmount
    ) external view returns (uint256);

    function wTokenGetCollateralOutView(
        address ammAddress,
        uint64 seriesId,
        uint256 wTokenAmount
    ) external view returns (uint256);

    function getCollateralValueOfAllExpiredOptionTokensView(address ammAddress)
        external
        view
        returns (uint256);

    function getOptionTokensSaleValueView(
        address ammAddress,
        uint256 lpTokenAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

interface IPriceOracle {
    function getSettlementPrice(
        address underlyingToken,
        address priceToken,
        uint256 settlementDate
    ) external view returns (bool, uint256);

    function getCurrentPrice(address underlyingToken, address priceToken)
        external
        view
        returns (uint256);

    function setSettlementPrice(address underlyingToken, address priceToken)
        external;

    function setSettlementPriceForDate(
        address underlyingToken,
        address priceToken,
        uint256 date
    ) external;

    function get8amWeeklyOrDailyAligned(uint256 _timestamp)
        external
        view
        returns (uint256);

    function addTokenPair(
        address underlyingToken,
        address priceToken,
        address oracle
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ILight {
    event Swap(
        uint256 indexed nonce,
        uint256 timestamp,
        address indexed signerWallet,
        address signerToken,
        uint256 signerAmount,
        address indexed senderWallet,
        address senderToken,
        uint256 senderTokenId,
        uint256 senderAmount
    );

    event Cancel(uint256 indexed nonce, address indexed signerWallet);

    event Authorize(address indexed signer, address indexed signerWallet);

    event Revoke(address indexed signer, address indexed signerWallet);

    function swap(
        uint256 nonce,
        uint256 expiry,
        address signerWallet,
        address signerToken,
        uint256 signerAmount,
        address senderToken,
        uint256 senderTokenId,
        uint256 senderAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swapWithRecipient(
        address recipient,
        uint256 nonce,
        uint256 expiry,
        address signerWallet,
        address signerToken,
        uint256 signerAmount,
        address senderToken,
        uint256 senderTokenId,
        uint256 senderAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function authorize(address sender) external;

    function revoke() external;

    function cancel(uint256[] calldata nonces) external;

    function nonceUsed(address, uint256) external view returns (bool);

    function authorized(address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/** Dead simple interface for the ERC20 methods that aren't in the standard interface
 */
interface IERC20Lib {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

library SeriesLibrary {
    function wTokenIndex(uint64 _seriesId) internal pure returns (uint256) {
        return _seriesId * 2;
    }

    function bTokenIndex(uint64 _seriesId) internal pure returns (uint256) {
        return (_seriesId * 2) + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMinterAmm.sol";
import "../oz/EnumerableSet.sol";
import "../series/ISeriesController.sol";
import "../series/SeriesLibrary.sol";
import "../token/ISimpleToken.sol";
import "../configuration/IAddressesProvider.sol";

/// This contract stores all new local variables for the MinterAmm.sol contract.
/// This allows us to upgrade the contract and add new variables without worrying about
///   memory layout when we add new variables.
/// Each time a new version is created with new variables, the version "V1, V2, etc" should
//    be bumped and inherit from the previous version, and the MinterAmm should inherit from
///   the newest version.
abstract contract MinterAmmStorageV1 is IMinterAmm {
    /// @dev The token contract that will track lp ownership of the AMM
    ISimpleToken public override lpToken;

    /// @dev The ERC20 tokens used by all the Series associated with this AMM
    IERC20 public override underlyingToken;
    IERC20 public override priceToken;
    IERC20 public override collateralToken;

    /// @dev The registry which the AMM will use to lookup individual Series
    ISeriesController public seriesController;

    /// @notice The contract used to mint the option tokens
    IERC1155 public erc1155Controller;

    /// @dev Fees on trading
    uint16 public tradeFeeBasisPoints;

    // volatilityFactor is depricated and replaced with seriesVolatilities
    uint256 public volatilityFactor;

    /// @dev Flag to ensure initialization can only happen once
    bool initialized = false;

    uint256 public constant MINIMUM_TRADE_SIZE = 1000;

    /// @dev A price oracle contract used to get onchain price data
    address internal sirenPriceOracle;

    /// @dev Collection of ids of open series
    /// @dev If we ever re-deploy MinterAmm we need to check that the EnumerableSet implementation hasn’t changed,
    /// because we rely on undocumented implementation details (see Note in MinterAmm.claimAllExpiredTokens on
    /// removing series)
    EnumerableSet.UintSet internal openSeries;

    /// @dev These contract variables, as well as the `nonReentrant` modifier further down below,
    /// are copied from OpenZeppelin's ReentrancyGuard contract. We chose to copy ReentrancyGuard instead of
    /// having MinterAmm inherit it because we intend use this MinterAmm contract to upgrade already-deployed
    /// MinterAmm contracts. If The MinterAmm were to inherit from ReentrancyGuard, the ReentrancyGuard's
    /// contract storage variables would overwrite existing storage variables on the contract and it would
    /// break the contract. So by manually implementing ReentrancyGuard's logic we have full control over
    /// the position of the variable in the contract's storage, and we can ensure the MinterAmm's contract
    /// storage variables are only ever appended to. See this OpenZeppelin article about contract upgradeability
    /// for more info on the contract storage variable requirement:
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status;

    /// @dev Max fee basis points on the value of the option
    uint16 public maxOptionFeeBasisPoints;

    /// @dev Address where fees are sent on each trade
    address public feeDestinationAddress;

    /// @dev The contract used to make pricing calculations for the MinterAmm
    address public ammDataProvider;

    /// @dev The address for the airswap Light contract on-chain.
    address public lightAirswapAddress;
}

abstract contract MinterAmmStorageV2 is MinterAmmStorageV1 {
    /// @dev Stores volatility mapped to each series
    struct SeriesVolatility {
        uint256 volatility;
        uint256 updatedAt;
    }

    ///Replaces volatilityFactor
    mapping(uint64 => SeriesVolatility) public seriesVolatilities;

    /// @dev The address for the AddressesProvider
    IAddressesProvider addressesProvider;

    /// @dev Shift of baseline IV vs historical oracle feed (1e18)
    int256 public ivShift;

    /// @dev Turn dynamic IV on/off
    bool public dynamicIvEnabled;

    /// @dev IV drift rate towards baseline IV (smaller means faster convergence)
    uint16 public ivDriftRate;
}

abstract contract MinterAmmStorageV3 is MinterAmmStorageV2 {
    uint256 public lockedCollateral;
}

// Next version example:
/// contract MinterAmmStorageV3 is MinterAmmStorageV2 {
///   address public myAddress;
/// }
/// Then... MinterAmm should inherit from MinterAmmStorageV3

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

interface IVolatilityOracle {
    function vol(address underlyingToken, address priceToken)
        external
        view
        returns (uint256 standardDeviation);

    function annualizedVol(address underlyingToken, address priceToken)
        external
        view
        returns (uint256 annualStdev);

    function commit(address underlyingToken, address priceToken) external;

    function addTokenPair(address underlyingToken, address priceToken) external;

    function setAccumulator(
        address underlyingToken,
        address priceToken,
        uint8 currentObservationIndex,
        uint32 lastTimestamp,
        int96 mean,
        uint256 dsq
    ) external;

    function setLastPrice(
        address underlyingToken,
        address priceToken,
        uint256 price
    ) external;
}

//SPDX-License-Identifier: ISC
pragma solidity >=0.5.0 <=0.8.0;
pragma experimental ABIEncoderV2;

interface IBlackScholes {
    struct PricesDeltaStdVega {
        uint256 callPrice;
        uint256 putPrice;
        int256 callDelta;
        int256 putDelta;
        uint256 stdVega;
    }

    struct PricesStdVega {
        uint256 price;
        uint256 stdVega;
    }

    function abs(int256 x) external pure returns (uint256);

    function exp(uint256 x) external pure returns (uint256);

    function exp(int256 x) external pure returns (uint256);

    function sqrt(uint256 x) external pure returns (uint256 y);

    function optionPrices(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external view returns (uint256 call, uint256 put);

    function pricesDeltaStdVega(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external pure returns (PricesDeltaStdVega memory);

    function pricesStdVegaInUnderlying(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal,
        bool isPut
    ) external pure returns (PricesStdVega memory);
}

pragma solidity 0.8.0;

interface IWTokenVault {
    event WTokensLocked(
        address ammAddress,
        address redeemer,
        uint256 expirationId,
        uint256 lpSharesMinted
    );
    event LpSharesRedeemed(
        address ammAddress,
        address redeemer,
        uint256 expirationId,
        uint256 numShares,
        uint256 collateralAmount
    );
    event CollateralLocked(
        address ammAddress,
        uint64 seriesId,
        uint256 collateralAmount,
        uint256 wTokenAmount
    );

    function getWTokenBalance(address poolAddress, uint64 seriesId)
        external
        view
        returns (uint256);

    function lockActiveWTokens(
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        address redeemer,
        uint256 volatility
    ) external;

    function redeemCollateral(uint256 expirationId, address redeemer)
        external
        returns (uint256);

    function lockCollateral(
        uint64 seriesId,
        uint256 collateralAmount,
        uint256 wTokenAmount
    ) external;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/ISimpleToken.sol";
import "../series/ISeriesController.sol";
import "../configuration/IAddressesProvider.sol";

interface IMinterAmm {
    function lpToken() external view returns (ISimpleToken);

    function underlyingToken() external view returns (IERC20);

    function priceToken() external view returns (IERC20);

    function collateralToken() external view returns (IERC20);

    function initialize(
        ISeriesController _seriesController,
        IAddressesProvider _addressesProvider,
        IERC20 _underlyingToken,
        IERC20 _priceToken,
        IERC20 _collateralToken,
        ISimpleToken _lpToken,
        uint16 _tradeFeeBasisPoints
    ) external;

    function bTokenBuy(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMaximum
    ) external returns (uint256);

    function bTokenSell(
        uint64 seriesId,
        uint256 bTokenAmount,
        uint256 collateralMinimum
    ) external returns (uint256);

    function addSeries(uint64 _seriesId) external;

    function getAllSeries() external view returns (uint64[] memory);

    function getVolatility(uint64 _seriesId) external view returns (uint256);

    function getBaselineVolatility() external view returns (uint256);

    function calculateFees(uint256 bTokenAmount, uint256 collateralAmount)
        external
        view
        returns (uint256);

    function updateAddressesProvider(address _addressesProvider) external;

    function getCurrentUnderlyingPrice() external view returns (uint256);
    
    function collateralBalance() external view returns (uint256);

    function setAmmConfig(
        int256 _ivShift,
        bool _dynamicIvEnabled,
        uint16 _ivDriftRate
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/**
 @title ISeriesController
 @author The Siren Devs
 @notice Onchain options protocol for minting, exercising, and claiming calls and puts
 @notice Manages the lifecycle of individual Series
 @dev The id's for bTokens and wTokens on the same Series are consecutive uints
 */
interface ISeriesController {
    /// @notice The basis points to use for fees on the various SeriesController functions,
    /// in units of basis points (1 basis point = 0.01%)
    struct Fees {
        address feeReceiver;
        uint16 exerciseFeeBasisPoints;
        uint16 closeFeeBasisPoints;
        uint16 claimFeeBasisPoints;
    }

    struct Tokens {
        address underlyingToken;
        address priceToken;
        address collateralToken;
    }

    /// @notice All data pertaining to an individual series
    struct Series {
        uint40 expirationDate;
        bool isPutOption;
        ISeriesController.Tokens tokens;
        uint256 strikePrice;
    }

    /// @notice All possible states a Series can be in with regard to its expiration date
    enum SeriesState {
        /**
         * New option token cans be created.
         * Existing positions can be closed.
         * bTokens cannot be exercised
         * wTokens cannot be claimed
         */
        OPEN,
        /**
         * No new options can be created
         * Positions cannot be closed
         * bTokens can be exercised
         * wTokens can be claimed
         */
        EXPIRED
    }

    /** Enum to track Fee Events */
    enum FeeType {
        EXERCISE_FEE,
        CLOSE_FEE,
        CLAIM_FEE
    }

    ///////////////////// EVENTS /////////////////////

    /// @notice Emitted when the owner creates a new series
    event SeriesCreated(
        uint64 seriesId,
        Tokens tokens,
        address[] restrictedMinters,
        uint256 strikePrice,
        uint40 expirationDate,
        bool isPutOption
    );

    /// @notice Emitted when the SeriesController gets initialized
    event SeriesControllerInitialized(
        address priceOracle,
        address vault,
        address erc1155Controller,
        Fees fees
    );

    /// @notice Emitted when SeriesController.mintOptions is called, and wToken + bToken are minted
    event OptionMinted(
        address minter,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply
    );

    /// @notice Emitted when either the SeriesController transfers ERC20 funds to the SeriesVault,
    /// or the SeriesController transfers funds from the SeriesVault to a recipient
    event ERC20VaultTransferIn(address sender, uint64 seriesId, uint256 amount);
    event ERC20VaultTransferOut(
        address recipient,
        uint64 seriesId,
        uint256 amount
    );

    event FeePaid(
        FeeType indexed feeType,
        address indexed token,
        uint256 value
    );

    /** Emitted when a bToken is exercised for collateral */
    event OptionExercised(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when a wToken is redeemed after expiration */
    event CollateralClaimed(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when an equal amount of wToken and bToken is redeemed for original collateral */
    event OptionClosed(
        address indexed redeemer,
        uint64 seriesId,
        uint256 optionTokenAmount,
        uint256 wTokenTotalSupply,
        uint256 bTokenTotalSupply,
        uint256 collateralAmount
    );

    /** Emitted when the owner adds new allowed expirations */
    event AllowedExpirationUpdated(uint256 newAllowedExpiration);

    ///////////////////// VIEW/PURE FUNCTIONS /////////////////////

    function priceDecimals() external view returns (uint8);

    function erc1155Controller() external view returns (address);

    function allowedExpirationsList(uint256 expirationId)
        external
        view
        returns (uint256);

    function allowedExpirationsMap(uint256 expirationTimestamp)
        external
        view
        returns (uint256);

    function getExpirationIdRange() external view returns (uint256, uint256);

    function series(uint256 seriesId)
        external
        view
        returns (ISeriesController.Series memory);

    function state(uint64 _seriesId) external view returns (SeriesState);

    function calculateFee(uint256 _amount, uint16 _basisPoints)
        external
        pure
        returns (uint256);

    function getExerciseAmount(uint64 _seriesId, uint256 _bTokenAmount)
        external
        view
        returns (uint256, uint256);

    function getClaimAmount(uint64 _seriesId, uint256 _wTokenAmount)
        external
        view
        returns (uint256, uint256);

    function seriesName(uint64 _seriesId) external view returns (string memory);

    function strikePrice(uint64 _seriesId) external view returns (uint256);

    function expirationDate(uint64 _seriesId) external view returns (uint40);

    function underlyingToken(uint64 _seriesId) external view returns (address);

    function priceToken(uint64 _seriesId) external view returns (address);

    function collateralToken(uint64 _seriesId) external view returns (address);

    function exerciseFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function closeFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function claimFeeBasisPoints(uint64 _seriesId)
        external
        view
        returns (uint16);

    function wTokenIndex(uint64 _seriesId) external pure returns (uint256);

    function bTokenIndex(uint64 _seriesId) external pure returns (uint256);

    function isPutOption(uint64 _seriesId) external view returns (bool);

    function getCollateralPerOptionToken(
        uint64 _seriesId,
        uint256 _optionTokenAmount
    ) external view returns (uint256);

    function getCollateralPerUnderlying(
        uint64 _seriesId,
        uint256 _underlyingAmount,
        uint256 _price
    ) external view returns (uint256);

    /// @notice Returns the amount of collateralToken held in the vault on behalf of the Series at _seriesId
    /// @param _seriesId The index of the Series in the SeriesController
    function getSeriesERC20Balance(uint64 _seriesId)
        external
        view
        returns (uint256);

    function latestIndex() external returns (uint64);

    ///////////////////// MUTATING FUNCTIONS /////////////////////

    function mintOptions(uint64 _seriesId, uint256 _optionTokenAmount) external;

    function exerciseOption(
        uint64 _seriesId,
        uint256 _bTokenAmount,
        bool _revertOtm
    ) external returns (uint256);

    function claimCollateral(uint64 _seriesId, uint256 _wTokenAmount)
        external
        returns (uint256);

    function closePosition(uint64 _seriesId, uint256 _optionTokenAmount)
        external
        returns (uint256);

    function createSeries(
        ISeriesController.Tokens calldata _tokens,
        uint256[] calldata _strikePrices,
        uint40[] calldata _expirationDates,
        address[] calldata _restrictedMinters,
        bool _isPutOption
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/** Interface for any Siren SimpleToken
 */
interface ISimpleToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

/**
 * @title IAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * @author Dakra-Mystic
 **/
interface IAddressesProvider {
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event AmmDataProviderUpdated(address indexed newAddress);
    event SeriesControllerUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event DirectBuyManagerUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    event VolatilityOracleUpdated(address indexed newAddress);
    event BlackScholesUpdated(address indexed newAddress);
    event AirswapLightUpdated(address indexed newAddress);
    event AmmFactoryUpdated(address indexed newAddress);    
    event WTokenVaultUpdated(address indexed newAddress);
    event AmmConfigUpdated(address indexed newAddress);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getAmmDataProvider() external view returns (address);

    function setAmmDataProvider(address ammDataProvider) external;

    function getSeriesController() external view returns (address);

    function setSeriesController(address seriesController) external;

    function getVolatilityOracle() external view returns (address);

    function setVolatilityOracle(address volatilityOracle) external;

    function getBlackScholes() external view returns (address);

    function setBlackScholes(address blackScholes) external;

    function getAirswapLight() external view returns (address);

    function setAirswapLight(address airswapLight) external;

    function getAmmFactory() external view returns (address);

    function setAmmFactory(address ammFactory) external;

    function getDirectBuyManager() external view returns (address);

    function setDirectBuyManager(address directBuyManager) external;

    function getWTokenVault() external view returns (address);

    function setWTokenVault(address wTokenVault) external;

    function getAmmConfig() external view returns (address);

    function setAmmConfig(address ammConfig) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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