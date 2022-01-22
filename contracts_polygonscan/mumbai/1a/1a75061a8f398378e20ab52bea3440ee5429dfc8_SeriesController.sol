// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./ISeriesController.sol";
import "./IERC1155Controller.sol";
import "./ISeriesVault.sol";
import "../proxy/Proxiable.sol";
import "./IPriceOracle.sol";
import "../token/IERC20Lib.sol";
import "../amm/IMinterAmm.sol";
import "./SeriesLibrary.sol";
import "./SeriesControllerStorage.sol";
import "../amm/IAmmFactory.sol";

/// @title SeriesController
/// @notice The SeriesController implements all of the logic for minting and interacting with option tokens
/// (bTokens and wTokens). Siren options are European style, cash-settled, and fully collateralized.
/// @notice Siren European options are slightly different than European options users might be
/// used to in Traditional Finance. European options differ from American options in that they can only
/// be executed on the day the option expires. Siren options can be exercised any time after expiration,
/// but the settlement price used to calculate the payoffs will be the spot price at the time of expiration.
/// So Siren options are effectively European options TradFi users are used to, except they have an additional
/// feature where there is an unbounded amount of time after expiration where the user can exercise their option
/// and receive their payoff, using the expiration date's settlement price
/// @notice The primary data structure of the SeriesController is the Series struct, which represents
/// an option series by storing the series' tokens, expiration date, and strike price
/// @notice The SeriesController stores Series using a monotonically incrementing "seriesId"
/// @dev In v1 of the Siren Options Protocol we deployed separate Series contracts every time we wanted
/// to create a new option series. But here in v2 of the Protocol we use the ERC1155 standard to save
/// on gas deployment costs by storing individual Series structs in an array
contract SeriesController is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    Proxiable,
    SeriesControllerStorageV2
{
    /** Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;

    ///////////////////// MODIFIER FUNCTIONS /////////////////////

    /// @notice Check if the msg.sender is the privileged DEFAULT_ADMIN_ROLE holder
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "!admin");

        _;
    }

    /// @notice Check if the msg.sender is the privileged SERIES_DEPLOYER_ROLE holder
    modifier onlySeriesDeployer() {
        require(
            hasRole(SERIES_DEPLOYER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "!deployer"
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
        require(_status != _ENTERED, "!reentrant");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    ///////////////////// VIEW/PURE FUNCTIONS /////////////////////

    /// @notice Returns the state of a Series, which can be OPEN or EXPIRED. The OPEN state
    /// means the block timestamp is still prior to the Series' expiration date, and so option
    /// tokens can be minted or closed. The EXPIRED state means the block timestamp is after
    /// the expiration date, and now the bTokens can be exercised and the wTokens claimed
    /// @param _seriesId The index of this Series
    /// @return The state of the Series
    function state(uint64 _seriesId)
        public
        view
        override
        returns (SeriesState)
    {
        // before the expiration
        if (block.timestamp < allSeries[_seriesId].expirationDate) {
            return SeriesState.OPEN;
        }

        // at or after expiration
        return SeriesState.EXPIRED;
    }

    function series(uint256 seriesId)
        external
        view
        override
        returns (ISeriesController.Series memory)
    {
        ISeriesController.Series memory series = allSeries[seriesId];

        // check series exists
        require(series.expirationDate > 0, "!series");
        return series;
    }

    /// @notice Calculate the fee to charge given some amount
    /// @dev A Basis Point is 1 / 100 of a percent. e.g. 10 basis points (e.g. 0.1%) on 5000 is 5000 * 0.001 => 5
    function calculateFee(uint256 amount, uint16 basisPoints)
        public
        pure
        override
        returns (uint256)
    {
        return (amount * basisPoints) / (10000);
    }

    /// @dev Calculate settlement payoffs (in units of collateralToken) for the
    /// option buyers and writers. The relationship between the settlement price and
    /// the strike price determines the payoff amounts
    /// @dev If `getSettlementAmounts` is executed when the Series is in the EXPIRED state and the
    /// settlement price has been set on the PriceOracle, then the payoffs calculated
    /// here will remain the same forever. If `getSettlementAmounts` is executed prior to the PriceOracle setting the settlement
    /// price, then this function will use the current onchain price. This means the return
    /// value might change between successive calls, because the onchain price may change
    /// @dev As the Series becomes more in the money, the bToken holder gains a large share
    /// of the locked collateral (i.e. their payoff increases) and the wToken holder receives less
    /// @param _seriesId The index of this Series
    /// @param _optionTokenAmount The amount of bToken/wToken
    /// @return A tuple of uint256's, where the first is the bToken holder's share of the locked collateral
    /// and the second is the wToken holder's share of the locked collateral
    function getSettlementAmounts(uint64 _seriesId, uint256 _optionTokenAmount)
        internal
        view
        returns (uint256, uint256)
    {
        (bool isSet, uint256 settlementPrice) = getSettlementPrice(_seriesId);
        if (!isSet) {
            // the settlement price hasn't been set yet, so we use the current oracle
            // price instead. This means the amounts returned by getSettlementAmounts
            // might be different at a later date, when the settlement price gets set
            // and remains, but assuming small price swings it should not differ by
            // a large amount
            settlementPrice = getCurrentPrice(_seriesId);
        }

        uint256 buyerShare;
        uint256 writerShare;

        Series memory currentSeries = allSeries[_seriesId];

        // calculate what amounts of the collateralToken locked in the Series the
        // buyer and the writer can redeem their bToken and wToken for
        if (currentSeries.isPutOption) {
            // Put
            if (settlementPrice >= currentSeries.strikePrice) {
                // OTM
                writerShare = getCollateralPerOptionToken(
                    _seriesId,
                    _optionTokenAmount
                );
                buyerShare = 0;
            } else {
                // ITM
                writerShare = getCollateralPerUnderlying(
                    _seriesId,
                    _optionTokenAmount,
                    settlementPrice
                );
                buyerShare = getCollateralPerUnderlying(
                    _seriesId,
                    _optionTokenAmount,
                    currentSeries.strikePrice - settlementPrice
                );
            }
        } else {
            // Call
            if (settlementPrice <= currentSeries.strikePrice) {
                // OTM
                writerShare = _optionTokenAmount;
                buyerShare = 0;
            } else {
                // ITM
                writerShare =
                    (_optionTokenAmount * currentSeries.strikePrice) /
                    settlementPrice;
                buyerShare = _optionTokenAmount - writerShare;
            }
        }

        return (buyerShare, writerShare);
    }

    /// @notice Calculate the option payoff for exercising bToken
    /// @dev For the details on bToken holder payoff, see `SeriesController.getSettlementAmounts`
    /// @param _seriesId The index of this Series
    /// @param _bTokenAmount The amount of bToken
    /// @return A tuple of uint256's, where the first is the bToken holder's share of the locked collateral
    /// and the second is the fee paid paid to the protocol for exercising
    function getExerciseAmount(uint64 _seriesId, uint256 _bTokenAmount)
        public
        view
        override
        returns (uint256, uint256)
    {
        (uint256 buyerShare, ) = getSettlementAmounts(_seriesId, _bTokenAmount);

        // Calculate the redeem Fee and move it if it is valid
        uint256 feeAmount = calculateFee(
            buyerShare,
            fees.exerciseFeeBasisPoints
        );
        if (feeAmount > 0) {
            buyerShare -= feeAmount;
        }

        // Verify the amount to send is not less than the balance due to rounding for the last user claiming funds.
        // If so, just send the remaining amount in the contract.
        uint256 collateralMinusFee = seriesBalances[_seriesId] - feeAmount;
        if (collateralMinusFee < buyerShare) {
            buyerShare = collateralMinusFee;
        }

        return (buyerShare, feeAmount);
    }

    /// @notice Calculate the option payoff for claim wToken
    /// @dev For the details on wToken holder payoff, see `SeriesController.getSettlementAmounts`
    /// @param _seriesId The index of this Series
    /// @param _wTokenAmount The amount of wToken
    /// @return A tuple of uint256's, where the first is the wToken holder's share of the locked collateral
    /// and the second is the fee paid paid to the protocol for claiming
    function getClaimAmount(uint64 _seriesId, uint256 _wTokenAmount)
        public
        view
        override
        returns (uint256, uint256)
    {
        (, uint256 writerShare) = getSettlementAmounts(
            _seriesId,
            _wTokenAmount
        );

        // Calculate the claim Fee and move it if it is valid
        uint256 feeAmount = calculateFee(writerShare, fees.claimFeeBasisPoints);
        if (feeAmount > 0) {
            // First set the collateral amount that will be left over to send out
            writerShare -= feeAmount;
        }

        // Verify the amount to send is not less than the balance due to rounding for the last user claiming funds.
        // If so, just send the remaining amount in the contract.
        uint256 collateralMinusFee = seriesBalances[_seriesId] - feeAmount;
        if (collateralMinusFee < writerShare) {
            writerShare = collateralMinusFee;
        }

        return (writerShare, feeAmount);
    }

    /// @notice Returns the name of the Series at the given index, which contains information about this Series
    /// @param _seriesId The index of this Series
    /// @return The series name (e.g. "WBTC.USDC.20201215.C.16000.WBTC")
    function seriesName(uint64 _seriesId)
        external
        view
        override
        returns (string memory)
    {
        Series memory currentSeries = allSeries[_seriesId];
        return
            getSeriesName(
                currentSeries.tokens.underlyingToken,
                currentSeries.tokens.priceToken,
                currentSeries.tokens.collateralToken,
                currentSeries.strikePrice,
                currentSeries.expirationDate,
                currentSeries.isPutOption
            );
    }

    function strikePrice(uint64 _seriesId)
        external
        view
        override
        returns (uint256)
    {
        return allSeries[_seriesId].strikePrice;
    }

    function expirationDate(uint64 _seriesId)
        external
        view
        override
        returns (uint40)
    {
        return allSeries[_seriesId].expirationDate;
    }

    function underlyingToken(uint64 _seriesId)
        external
        view
        override
        returns (address)
    {
        return allSeries[_seriesId].tokens.underlyingToken;
    }

    function priceToken(uint64 _seriesId)
        external
        view
        override
        returns (address)
    {
        return allSeries[_seriesId].tokens.priceToken;
    }

    function collateralToken(uint64 _seriesId)
        external
        view
        override
        returns (address)
    {
        return allSeries[_seriesId].tokens.collateralToken;
    }

    function exerciseFeeBasisPoints(uint64 _seriesId)
        external
        view
        override
        returns (uint16)
    {
        return fees.exerciseFeeBasisPoints;
    }

    function closeFeeBasisPoints(uint64 _seriesId)
        external
        view
        override
        returns (uint16)
    {
        return fees.closeFeeBasisPoints;
    }

    function claimFeeBasisPoints(uint64 _seriesId)
        external
        view
        override
        returns (uint16)
    {
        return fees.claimFeeBasisPoints;
    }

    function wTokenIndex(uint64 _seriesId)
        external
        pure
        override
        returns (uint256)
    {
        return SeriesLibrary.wTokenIndex(_seriesId);
    }

    function bTokenIndex(uint64 _seriesId)
        external
        pure
        override
        returns (uint256)
    {
        return SeriesLibrary.bTokenIndex(_seriesId);
    }

    function isPutOption(uint64 _seriesId)
        external
        view
        override
        returns (bool)
    {
        return allSeries[_seriesId].isPutOption;
    }

    /// @notice Returns the amount of collateralToken held in the vault on behalf of the Series at _seriesId
    /// @param _seriesId The index of the Series in the SeriesController
    function getSeriesERC20Balance(uint64 _seriesId)
        external
        view
        override
        returns (uint256)
    {
        return seriesBalances[_seriesId];
    }

    /// @notice Given a series ID and an amount of bToken/wToken, return the amount of collateral token received when it's exercised
    /// @param _seriesId The Series ID
    /// @param _optionTokenAmount The amount of bToken/wToken
    /// @return The amount of collateral token received when exercising this amount of option token
    function getCollateralPerOptionToken(
        uint64 _seriesId,
        uint256 _optionTokenAmount
    ) public view override returns (uint256) {
        return
            getCollateralPerUnderlying(
                _seriesId,
                _optionTokenAmount,
                allSeries[_seriesId].strikePrice
            );
    }

    /// @dev Given a Series and an amount of underlying, return the amount of collateral adjusted for decimals
    /// @dev In almost every callsite of this function the price is equal to the strike price, except in Series.getSettlementAmounts where we use the settlementPrice
    /// @param _seriesId The Series ID
    /// @param _underlyingAmount The amount of underlying
    /// @param _price The price of the collateral token in units of price token
    /// @return The amount of collateral
    function getCollateralPerUnderlying(
        uint64 _seriesId,
        uint256 _underlyingAmount,
        uint256 _price
    ) public view override returns (uint256) {
        Series memory currentSeries = allSeries[_seriesId];

        // is it a call option?
        if (!currentSeries.isPutOption) {
            // for call options this conversion is simple, because 1 optionToken locks
            // 1 unit of collateral token
            return _underlyingAmount;
        }

        // for put options we need to convert from the optionToken's underlying units
        // to the collateral token units. This way 1 put bToken/wToken is exercisable
        // for the value of 1 underlying token in units of collateral
        return
            (((_underlyingAmount * _price) / (uint256(10)**priceDecimals)) *
                (uint256(10) **
                    (
                        IERC20Lib(currentSeries.tokens.collateralToken)
                            .decimals()
                    ))) /
            (uint256(10) **
                (IERC20Lib(currentSeries.tokens.underlyingToken).decimals()));
    }

    /// @notice Returns the settlement price for this Series.
    /// @return true if the settlement price has been set (i.e. is nonzero), false otherwise
    function getSettlementPrice(uint64 _seriesId)
        public
        view
        returns (bool, uint256)
    {
        Series memory currentSeries = allSeries[_seriesId];

        return
            IPriceOracle(priceOracle).getSettlementPrice(
                address(currentSeries.tokens.underlyingToken),
                address(currentSeries.tokens.priceToken),
                currentSeries.expirationDate
            );
    }

    /// @dev Returns the current price for this Series' underlyingToken
    /// in units of priceToken
    function getCurrentPrice(uint64 _seriesId) internal view returns (uint256) {
        Series memory currentSeries = allSeries[_seriesId];

        return
            IPriceOracle(priceOracle).getCurrentPrice(
                address(currentSeries.tokens.underlyingToken),
                address(currentSeries.tokens.priceToken)
            );
    }

    /// @dev Get the canonical name for the Series with the given fields (e.g. "WBTC.USDC.20201215.C.16000.WBTC")
    /// @return A string of the form "underlying.price.expiration.type.strike.collateral"
    /// @param _underlyingToken The token whose price determines the value of the option
    /// @param _priceToken The token whose units will denominate this Series' strike price
    /// @param _collateralToken The token that will be received when option tokens are exercised/claimed
    /// @param _strikePrice The price (in units of _priceToken) this option will value the underlying at when exercised/claimed
    /// @param _expirationDate The date (in blocktime) when this Series expires
    /// @param _isPutOption True if this Series is a put option, false otherwise
    function getSeriesName(
        address _underlyingToken,
        address _priceToken,
        address _collateralToken,
        uint256 _strikePrice,
        uint40 _expirationDate,
        bool _isPutOption
    ) private view returns (string memory) {
        // convert the expirationDate from a uint256 to a string of the form 20210108 (<year><month><day>)
        // This logic is taken from bokkypoobah's BokkyPooBahsDateTimeLibrary, the timestampToDate function
        (uint256 year, uint256 month, uint256 day) = _timestampToDate(
            _expirationDate
        );
        return
            string(
                abi.encodePacked(
                    IERC20Lib(_underlyingToken).symbol(),
                    ".",
                    IERC20Lib(_priceToken).symbol(),
                    ".",
                    StringsUpgradeable.toString(year),
                    _dateComponentToString(month),
                    _dateComponentToString(day),
                    ".",
                    _isPutOption ? "P" : "C",
                    ".",
                    StringsUpgradeable.toString(_strikePrice / 1e8),
                    ".",
                    IERC20Lib(_collateralToken).symbol()
                )
            );
    }

    /// @dev convert a blocktime number to the {year} {month} {day} strings
    /// ------------------------------------------------------------------------
    /// Calculate year/month/day from the number of days since 1970/01/01 using
    /// the date conversion algorithm from
    ///   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    /// and adding the offset 2440588 so that 1970/01/01 is day 0
    ///
    /// int256 L = days + 68569 + offset
    /// int256 N = 4 * L / 146097
    /// L = L - (146097 * N + 3) / 4
    /// year = 4000 * (L + 1) / 1461001
    /// L = L - 1461 * year / 4 + 31
    /// month = 80 * L / 2447
    /// dd = L - 2447 * month / 80
    /// L = month / 11
    /// month = month + 2 - 12 * L
    /// year = 100 * (N - 49) + year + L
    /// ------------------------------------------------------------------------
    function _timestampToDate(uint40 _timestamp)
        private
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        uint256 _days = _timestamp / (24 * 60 * 60); // number of days in the _timestamp (rounded down)
        int256 __days = int256(_days);

        int256 L = __days + 68569 + 2440588; // 2440588 is an offset to align dates to unix time
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    /// @dev Format the number representing a month or day as a 2-digit string. Single-digit numbers
    /// are padded with a leading zero
    /// @dev This function only expects
    function _dateComponentToString(uint256 dateComponent)
        private
        pure
        returns (string memory)
    {
        require(dateComponent < 100, "Invalid dateComponent");

        string memory componentStr = StringsUpgradeable.toString(dateComponent);
        if (dateComponent < 10) {
            return string(abi.encodePacked("0", componentStr));
        }

        return componentStr;
    }

    function getExpirationIdRange()
        external
        view
        override
        returns (uint256, uint256)
    {
        return (1, allowedExpirationsList.length - 1);
    }

    ///////////////////// MUTATING FUNCTIONS /////////////////////

    /// @notice Initialize the SeriesController, setting its URI and priceOracle
    /// @param _priceOracle The PriceOracle used for fetching prices for Series
    /// @param _vault The SeriesVault contract that will be used to store all of this SeriesController's tokens
    /// @param _fees The various fees to charge on executing certain SeriesController functions
    function __SeriesController_init(
        address _priceOracle,
        address _vault,
        address _erc1155Controller,
        ISeriesController.Fees calldata _fees
    ) external initializer {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(SERIES_DEPLOYER_ROLE, msg.sender);

        require(_priceOracle != address(0x0), "Invalid _priceOracle");
        require(_vault != address(0x0), "Invalid _vault");
        require(
            _erc1155Controller != address(0x0),
            "Invalid _erc1155Controller"
        );

        // validate fee data
        require(
            _fees.exerciseFeeBasisPoints <= 10000 &&
                _fees.closeFeeBasisPoints <= 10000 &&
                _fees.claimFeeBasisPoints <= 10000,
            "Invalid _fees"
        );

        // set the state variables
        priceOracle = _priceOracle;
        vault = _vault;
        erc1155Controller = _erc1155Controller;
        fees = _fees;

        ISeriesVault(_vault).setERC1155ApprovalForController(
            _erc1155Controller
        );

        emit SeriesControllerInitialized(
            _priceOracle,
            _vault,
            _erc1155Controller,
            _fees
        );
    }

    /// @notice Pauses all non-admin functions
    function pause() external virtual {
        require(hasRole(PAUSER_ROLE, msg.sender), "!PAUSER");
        _pause();
    }

    /// @notice Unpauses all non-admin functions
    function unpause() external virtual {
        require(hasRole(PAUSER_ROLE, msg.sender), "!PAUSER");
        _unpause();
    }

    /// @dev Transfer _amount of given Series' collateral token to the SeriesVault from the _sender address
    /// @dev Prior to calling this the _sender must have approved the SeriesController for _amount
    /// @param _sender The address to transfer the token from
    /// @param _seriesId The index of the Series
    /// @param _amount The amount of _token to transfer from the SeriesController
    function transferERC20In(
        address _sender,
        uint64 _seriesId,
        uint256 _amount
    ) private {
        // update the balances state
        seriesBalances[_seriesId] += _amount;

        // pull the ERC20 token from the SeriesController
        IERC20(allSeries[_seriesId].tokens.collateralToken).safeTransferFrom(
            _sender,
            vault,
            _amount
        );

        emit ERC20VaultTransferIn(_sender, _seriesId, _amount);
    }

    /// @notice Transfer _amount of the collateral token Series at _seriesId
    /// @param _seriesId The index of the Series
    /// @param _recipient The address to send the _amount of _token to
    /// @param _amount The amount of _token to transfer to the recipient
    function transferERC20Out(
        uint64 _seriesId,
        address _recipient,
        uint256 _amount
    ) private {
        // update the balances state.
        // If not enough balance this will revert due to SafeMath, no need for additional 'require'
        seriesBalances[_seriesId] -= _amount;

        // pull the ERC20 token from the SeriesController
        IERC20(allSeries[_seriesId].tokens.collateralToken).safeTransferFrom(
            vault,
            _recipient,
            _amount
        );

        emit ERC20VaultTransferOut(_recipient, _seriesId, _amount);
    }

    /// @notice Create one or more Series
    /// @notice The Series will differ in their strike prices (according to the _strikePrices and _expirationDates arguments)
    /// but will share the same tokens, restricted minters, and option type
    /// @dev Each new Series is represented by a monotonically incrementing seriesId
    /// @dev An important assumption of the Series is that settlement dates are aligned to Friday 8am UTC.
    /// We assume this because we do not want to fragment liquidity and complicate the UX by allowing for arbitrary settlement dates
    /// so we enforce this when adding Series by aligning the settlement date to Friday 8am UTC
    /// @param _tokens The token whose price determines the value of the options
    /// @param _strikePrices The prices (in units of _priceToken) these options will value the underlying at when exercised/claimed
    /// @param _expirationDates The dates (in blocktime) when these Series expire
    /// @param _restrictedMinters The addresses allowed to mint options on these Series
    /// @param _isPutOption True if these Series are a put option, false otherwise
    function createSeries(
        ISeriesController.Tokens calldata _tokens,
        uint256[] calldata _strikePrices,
        uint40[] calldata _expirationDates,
        address[] calldata _restrictedMinters,
        bool _isPutOption
    ) external override onlySeriesDeployer {
        require(_strikePrices.length != 0, "!strikePrices");

        require(_strikePrices.length == _expirationDates.length, "!Array");

        // validate token data
        require(_tokens.underlyingToken != address(0x0), "!Underlying");
        require(_tokens.priceToken != address(0x0), "!Price");
        require(_tokens.collateralToken != address(0x0), "!Collateral");

        // validate that the token data makes sense given whether it's a Put or a Call
        if (_isPutOption) {
            require(_tokens.underlyingToken != _tokens.collateralToken, "!Put");
        } else {
            require(
                _tokens.underlyingToken == _tokens.collateralToken,
                "!Call"
            );
        }

        // restrictedMinters must be non-empty in order to protect against a subtle footgun: if a user were
        // to pass in an empty restrictedMinters array, then the expected behavior would be that anyone could
        // mint option tokens for that Series. However, this would not be the case because down in
        // SeriesController.mintOptions we check if the caller has the MINTER_ROLE, and so the original intent
        // of having anyone allowed to mint option tokens for that Series would not be honored.
        require(_restrictedMinters.length != 0, "!restrictedMinters");

        // add the privileged minters if they haven't already been added
        for (uint256 i = 0; i < _restrictedMinters.length; i++) {
            _setupRole(MINTER_ROLE, _restrictedMinters[i]);
        }

        // allow the SeriesController to transfer near-infinite amounts
        // of this ERC20 token from the SeriesVault
        ISeriesVault(vault).setERC20ApprovalForController(
            _tokens.collateralToken
        );

        // store variable in memory for reduced gas costs when reading
        uint64 _latestIndex = latestIndex;

        for (uint256 i = 0; i < _strikePrices.length; i++) {
            // add to the array so the Series data can be accessed in the future
            allSeries.push(
                createSeriesInternal(
                    _expirationDates[i],
                    _isPutOption,
                    _tokens,
                    _strikePrices[i]
                )
            );

            // Emit the event
            emit SeriesCreated(
                _latestIndex,
                _tokens,
                _restrictedMinters,
                _strikePrices[i],
                _expirationDates[i],
                _isPutOption
            );

            for (uint256 j = 0; j < _restrictedMinters.length; j++) {
                // if the restricted minter is a Amm contract, then make sure we make the Amm aware of
                // this Series. The only case where a restricted minter would not be an AMM is in our
                // automated tests, where it's much easier to test the SeriesController when we can use an
                // EOA (externally owned account) to mint options
                if (
                    ERC165Checker.supportsInterface(
                        _restrictedMinters[j],
                        IMinterAmm.addSeries.selector
                    )
                ) {
                    IMinterAmm(_restrictedMinters[j]).addSeries(_latestIndex);
                }
            }

            // don't forget to increment our series index
            _latestIndex = _latestIndex + 1;
        }

        // now that we're done incrementing our memory _latestIndex, update the storage variable latestIndex
        latestIndex = _latestIndex;
    }

    /// @dev Sanitize and set the parameters for a new Series
    function createSeriesInternal(
        uint40 _expirationDate,
        bool _isPutOption,
        ISeriesController.Tokens memory _tokens,
        uint256 _strikePrice
    ) private returns (Series memory) {
        // validate price and expiration
        require(_strikePrice != 0, "!strikePrice");
        require(_expirationDate > block.timestamp, "!expirationDate");

        // Validate the expiration has been added to the list by the owner
        require(allowedExpirationsMap[_expirationDate] > 0, "!expiration");

        // Add to created series mapping so we can track if it has been added before
        bytes32 seriesHash = keccak256(
            abi.encode(
                _expirationDate,
                _isPutOption,
                _tokens.underlyingToken,
                _tokens.priceToken,
                _tokens.collateralToken,
                _strikePrice
            )
        );
        require(!addedSeries[seriesHash], "!series");
        addedSeries[seriesHash] = true;

        return
            ISeriesController.Series(
                _expirationDate,
                _isPutOption,
                _tokens,
                _strikePrice
            );
    }

    /// @notice Create _optionTokenAmount of bToken and wToken for the given Series at _seriesId
    /// @param _seriesId The ID of the Series
    /// @param _optionTokenAmount The number of bToken and wTokens to mint
    /// @dev Option tokens have the same decimals as the underlying token
    function mintOptions(uint64 _seriesId, uint256 _optionTokenAmount)
        external
        override
        whenNotPaused
        nonReentrant
    {
        // NOTE: this assumes that values in the allSeries array are never removed,
        // which is fine because there's currently no way to remove Series
        require(allSeries.length > _seriesId, "!_seriesId");

        require(state(_seriesId) == SeriesState.OPEN, "!Open");

        // Is the caller one of the AMM pools, which are the only addresses with the MINTER_ROLE?
        require(hasRole(MINTER_ROLE, msg.sender), "!Minter");

        uint256 wIndex = SeriesLibrary.wTokenIndex(_seriesId);
        uint256 bIndex = SeriesLibrary.bTokenIndex(_seriesId);

        // mint equal amounts of wToken and bToken to the minter caller
        bytes memory data;

        uint256[] memory optionTokenIds = new uint256[](2);
        optionTokenIds[0] = wIndex;
        optionTokenIds[1] = bIndex;

        uint256[] memory optionTokenAmounts = new uint256[](2);
        optionTokenAmounts[0] = _optionTokenAmount;
        optionTokenAmounts[1] = _optionTokenAmount;

        IERC1155Controller(erc1155Controller).mintBatch(
            msg.sender,
            optionTokenIds,
            optionTokenAmounts,
            data
        );

        uint256 collateralAmount = getCollateralPerOptionToken(
            _seriesId,
            _optionTokenAmount
        );

        // transfer this collateral to the vault for storage
        transferERC20In(msg.sender, _seriesId, collateralAmount);

        uint256[] memory totalSupplies = IERC1155Controller(erc1155Controller)
            .optionTokenTotalSupplyBatch(optionTokenIds);

        // Tell any offchain listeners that we minted some tokens
        emit OptionMinted(
            msg.sender,
            _seriesId,
            _optionTokenAmount,
            totalSupplies[0],
            totalSupplies[1]
        );
    }

    /// @notice Exercise bToken for the given Series at _seriesId
    /// @param _seriesId The ID of the Series
    /// @param _bTokenAmount The number of bToken to exercise
    /// @param _revertOtm Whether to revert on OTM exercise attempt
    /// @dev Option tokens have the same decimals as the underlying token
    function exerciseOption(
        uint64 _seriesId,
        uint256 _bTokenAmount,
        bool _revertOtm
    ) external override whenNotPaused nonReentrant returns (uint256) {
        // We support only European style options so we exercise only after expiry, and only using
        // the settlement price set at expiration
        require(state(_seriesId) == SeriesState.EXPIRED, "!Expired");

        // Save off the caller
        address redeemer = msg.sender;

        // Set settlement price in case it hasn't been set yet
        setSettlementPrice(_seriesId);

        // Buyer's share
        (uint256 collateralAmount, uint256 feeAmount) = getExerciseAmount(
            _seriesId,
            _bTokenAmount
        );

        // Only ITM exercise results in payoff
        require(!_revertOtm || collateralAmount > 0, "!ITM");

        Series memory currentSeries = allSeries[_seriesId];

        // Burn the bToken amount from the callers account - this will be the same amount as the collateral that is requested
        IERC1155Controller(erc1155Controller).burn(
            redeemer,
            SeriesLibrary.bTokenIndex(_seriesId),
            _bTokenAmount
        );

        // Calculate the redeem Fee and move it if it is valid
        if (feeAmount > 0) {
            // Send the fee Amount to the fee receiver
            transferERC20Out(_seriesId, fees.feeReceiver, feeAmount);

            // Emit the fee event
            emit FeePaid(
                FeeType.EXERCISE_FEE,
                currentSeries.tokens.collateralToken,
                feeAmount
            );
        }

        // Send the collateral from the vault to the caller's address
        if (collateralAmount > 0) {
            transferERC20Out(_seriesId, redeemer, collateralAmount);
        }

        // get the option token total supplies
        uint256[] memory optionTokenIds = new uint256[](2);
        optionTokenIds[0] = SeriesLibrary.wTokenIndex(_seriesId);
        optionTokenIds[1] = SeriesLibrary.bTokenIndex(_seriesId);
        uint256[] memory totalSupplies = IERC1155Controller(erc1155Controller)
            .optionTokenTotalSupplyBatch(optionTokenIds);

        // Emit the Redeem Event
        emit OptionExercised(
            redeemer,
            _seriesId,
            _bTokenAmount,
            totalSupplies[0],
            totalSupplies[1],
            collateralAmount
        );

        return collateralAmount;
    }

    /// @notice Redeem the wToken for collateral token for the given Series
    /// @param _seriesId The ID of the Series
    /// @param _wTokenAmount The number of wToken to claim
    /// @dev Option tokens have the same decimals as the underlying token
    function claimCollateral(uint64 _seriesId, uint256 _wTokenAmount)
        external
        override
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(state(_seriesId) == SeriesState.EXPIRED, "!Expired");

        // Save off the caller
        address redeemer = msg.sender;

        // Set settlement price in case it hasn't been set yet
        setSettlementPrice(_seriesId);

        // Total collateral owed to wToken holder
        (uint256 collateralAmount, uint256 feeAmount) = getClaimAmount(
            _seriesId,
            _wTokenAmount
        );

        Series memory currentSeries = allSeries[_seriesId];

        // Burn the collateral token for the amount they are claiming
        IERC1155Controller(erc1155Controller).burn(
            redeemer,
            SeriesLibrary.wTokenIndex(_seriesId),
            _wTokenAmount
        );
        if (feeAmount > 0) {
            // Send the fee Amount to the fee receiver
            transferERC20Out(_seriesId, fees.feeReceiver, feeAmount);

            // Emit the fee event
            emit FeePaid(
                FeeType.CLAIM_FEE,
                address(currentSeries.tokens.collateralToken),
                feeAmount
            );
        }

        // Send the collateral from the vault to the caller's address
        transferERC20Out(_seriesId, redeemer, collateralAmount);

        // get the option token total supplies
        uint256[] memory optionTokenIds = new uint256[](2);
        optionTokenIds[0] = SeriesLibrary.wTokenIndex(_seriesId);
        optionTokenIds[1] = SeriesLibrary.bTokenIndex(_seriesId);
        uint256[] memory totalSupplies = IERC1155Controller(erc1155Controller)
            .optionTokenTotalSupplyBatch(optionTokenIds);

        // Emit event
        emit CollateralClaimed(
            redeemer,
            _seriesId,
            _wTokenAmount,
            totalSupplies[0],
            totalSupplies[1],
            collateralAmount
        );

        return collateralAmount;
    }

    /// @notice Close the position and take back collateral for the given Series
    /// @param _seriesId The ID of the Series
    /// @param _optionTokenAmount The number of bToken and wToken to close
    /// @dev Option tokens have the same decimals as the underlying token
    function closePosition(uint64 _seriesId, uint256 _optionTokenAmount)
        external
        override
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(state(_seriesId) == SeriesState.OPEN, "!Open");

        // Save off the caller
        address redeemer = msg.sender;

        // burn equal amounts of wToken and bToken
        uint256[] memory optionTokenIds = new uint256[](2);
        optionTokenIds[0] = SeriesLibrary.wTokenIndex(_seriesId);
        optionTokenIds[1] = SeriesLibrary.bTokenIndex(_seriesId);

        uint256[] memory optionTokenAmounts = new uint256[](2);
        optionTokenAmounts[0] = _optionTokenAmount;
        optionTokenAmounts[1] = _optionTokenAmount;

        IERC1155Controller(erc1155Controller).burnBatch(
            redeemer,
            optionTokenIds,
            optionTokenAmounts
        );

        uint256 collateralAmount = getCollateralPerOptionToken(
            _seriesId,
            _optionTokenAmount
        );

        // Calculate the claim Fee and move it if it is valid
        uint256 feeAmount = calculateFee(
            collateralAmount,
            fees.closeFeeBasisPoints
        );
        if (feeAmount > 0) {
            // First set the collateral amount that will be left over to send out
            collateralAmount -= feeAmount;

            // Send the fee Amount to the fee receiver
            transferERC20Out(_seriesId, fees.feeReceiver, feeAmount);

            Series memory currentSeries = allSeries[_seriesId];

            // Emit the fee event
            emit FeePaid(
                FeeType.CLOSE_FEE,
                address(currentSeries.tokens.collateralToken),
                feeAmount
            );
        }

        // Send the collateral to the caller's address
        transferERC20Out(_seriesId, redeemer, collateralAmount);

        // get the option token total supplies for the event
        uint256[] memory totalSupplies = IERC1155Controller(erc1155Controller)
            .optionTokenTotalSupplyBatch(optionTokenIds);

        // Emit the Closed Event
        emit OptionClosed(
            redeemer,
            _seriesId,
            _optionTokenAmount,
            totalSupplies[0],
            totalSupplies[1],
            collateralAmount
        );

        return collateralAmount;
    }

    /// @notice update the logic contract for this proxy contract
    /// @param _newImplementation the address of the new SeriesController implementation
    /// @dev only the admin address may call this function
    function updateImplementation(address _newImplementation)
        external
        onlyOwner
    {
        _updateCodeAddress(_newImplementation);
    }

    /// @notice transfer the DEFAULT_ADMIN_ROLE and PAUSER_ROLE from the msg.sender to a new address
    /// @param _newAdmin the address of the new DEFAULT_ADMIN_ROLE and PAUSER_ROLE holder
    /// @dev only the admin address may call this function
    function transferOwnership(address _newAdmin) external onlyOwner {
        require(_newAdmin != msg.sender, "!Owner");

        // first make _newAdmin the a pauser
        grantRole(PAUSER_ROLE, _newAdmin);

        // now remove the pause role from the current pauser
        renounceRole(PAUSER_ROLE, msg.sender);

        // then add _newAdmin to the admin role, while the msg.sender still
        // has the DEFAULT_ADMIN_ROLE role
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);

        // now remove the current admin from the admin role, leaving only
        // _newAdmin as the sole admin
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Update the addressProvider used for other contract lookups
    function setAddressesProvider(address _addressesProvider)
        external
        onlyOwner
    {
        require(_addressesProvider != address(0x0), "!addr");
        addressesProvider = IAddressesProvider(_addressesProvider);
    }

    /// @notice Sets the settlement price for all settlement dates prior to the current block timestamp
    /// for the given <underlyingToken>-<priceToken> pair
    /// @param _seriesId The specific series, accessed by its index
    function setSettlementPrice(uint64 _seriesId) internal {
        Series memory currentSeries = allSeries[_seriesId];

        return
            IPriceOracle(priceOracle).setSettlementPrice(
                address(currentSeries.tokens.underlyingToken),
                address(currentSeries.tokens.priceToken)
            );
    }

    /// @notice This function allows the owner address to update allowed expirations for the auto series creation feature
    /// @param timestamps timestamps to update
    /// @dev Only the owner address should be allowed to call this
    /// Expirations must be added in ascending order
    /// Expirations must be aligned 8 AM weekly or daily
    function updateAllowedExpirations(uint256[] calldata timestamps)
        public
        onlyOwner
    {
        // Save off the expiration list length as the next expiration ID to be added
        uint256 nextExpirationID = allowedExpirationsList.length;

        // First time through, increment counter since we don't want to allow an ID of 0
        if (nextExpirationID == 0) {
            allowedExpirationsList.push(0);
            nextExpirationID++;
        }

        for (uint256 i = 0; i < timestamps.length; i++) {
            // Verify the next timestamp added is newer than the last one (empty should return 0)
            require(
                (allowedExpirationsList[nextExpirationID - 1] < timestamps[i]),
                "!Order"
            );

            // Ensure the date is aligned
            require(
                timestamps[i] ==
                    IPriceOracle(priceOracle).get8amWeeklyOrDailyAligned(
                        timestamps[i]
                    ),
                "Nonaligned"
            );

            // Update the mapping of ExpirationDate => ExpirationID
            allowedExpirationsMap[timestamps[i]] = nextExpirationID;

            // Add the expiration to the array, index is ExpirationID and value is ExpirationDate
            allowedExpirationsList.push(timestamps[i]);

            // Increment the counter
            nextExpirationID++;

            // Emit the event for the new expiration
            emit AllowedExpirationUpdated(timestamps[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
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

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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

/// @title IERC1155Controller
/// @notice A contract used by the SeriesController to perform ERC1155 functions (inherited
/// from the OpenZeppelin ERC1155PresetMinterPauserUpgradeable contract)
/// @dev All ERC1155 tokens minted by this contract are stored on SeriesVault
/// @dev This contract exists solely to decrease the size of the deployed SeriesController
/// bytecode so it can be lower than the Spurious Dragon bytecode size limit
interface IERC1155Controller {
    function optionTokenTotalSupply(uint256 id) external view returns (uint256);

    function optionTokenTotalSupplyBatch(uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ISeriesVault
/// @author The Siren Devs
/// @notice Interface to interact with a SeriesVault
/// @dev The SeriesVault can store multiple SeriesController's tokens
/// @dev Never send ERC20 tokens directly to this contract with ERC20.safeTransfer*.
/// Always use the SeriesController.transfer*In/transfer*Out functions
/// @dev EIP-1155 functions are OK to use as is, because no 2 Series trade the same wToken,
/// whereas multiple Series trade the same ERC20 (see the warning above)
/// @dev The SeriesController should be the only contract interacting with the SeriesVault
interface ISeriesVault {
    ///////////////////// MUTATING FUNCTIONS /////////////////////

    /// @notice Allow the SeriesController to transfer MAX_UINT of the given ERC20 token from the SeriesVault
    /// @dev Can only be called by the seriesController
    /// @param erc20Token An ERC20-compatible token
    function setERC20ApprovalForController(address erc20Token) external;

    /// @notice Allow the SeriesController to transfer any number of ERC1155 tokens from the SeriesVault
    /// @dev Can only be called by the seriesController
    /// @dev The ERC1155 tokens will be minted and burned by the ERC1155Controller contract
    function setERC1155ApprovalForController(address erc1155Contract) external;
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

/** Dead simple interface for the ERC20 methods that aren't in the standard interface
 */
interface IERC20Lib {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
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

import "./ISeriesController.sol";
import "../configuration/IAddressesProvider.sol";

/// This contract stores all new local variables for the SeriesController.sol contract.
/// This allows us to upgrade the contract and add new variables without worrying about
///   memory layout when we add new variables.
/// Each time a new version is created with new variables, the version "V1, V2, etc" should
//    be bumped and inherit from the previous version, and the MinterAmm should inherit from
///   the newest version.
abstract contract SeriesControllerStorageV1 is ISeriesController {
    /// @dev The price oracle consulted for any price data needed by the individual Series
    address internal priceOracle;

    /// @dev The address of the SeriesVault that stores all of this SeriesController's tokens
    address internal vault;

    /// @dev The fees charged for different methods on the SeriesController
    ISeriesController.Fees internal fees;

    /// @notice Monotonically incrementing index, used when creating Series.
    uint64 public override latestIndex;

    /// @dev The address of the ERC1155Controler that performs minting and burning of option tokens
    address public override erc1155Controller;

    /// @dev An array of all the Series structs ever created by the SeriesController
    ISeriesController.Series[] internal allSeries;

    /// @dev Stores the balance of a Series' ERC20 collateralToken
    /// e.g. seriesBalances[_seriesId] = 1,337,000,000
    mapping(uint64 => uint256) internal seriesBalances;

    /// @dev Price decimals
    uint8 public constant override priceDecimals = 8;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev These contract variables, as well as the `nonReentrant` modifier further down below,
    /// are copied from OpenZeppelin's ReentrancyGuard contract. We chose to copy ReentrancyGuard instead of
    /// having SeriesController inherit it because we intend use this SeriesController contract to upgrade already-deployed
    /// SeriesController contracts. If the SeriesController were to inherit from ReentrancyGuard, the ReentrancyGuard's
    /// contract storage variables would overwrite existing storage variables on the contract and it would
    /// break the contract. So by manually implementing ReentrancyGuard's logic we have full control over
    /// the position of the variable in the contract's storage, and we can ensure the SeriesController's contract
    /// storage variables are only ever appended to. See this OpenZeppelin article about contract upgradeability
    /// for more info on the contract storage variable requirement:
    /// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status;

    /// @dev Stores the allowed expiration dates for series created by the auto series creation feature
    // Mapping is (ExpirationDate => ExpirationID); If the expiration ID is not 0 then it is a valid expiration date.
    // This is a convenience lookup mapping -> corresponds with allowedExpirationsList
    // ExpirationID lookup of value 0 means it is not set
    mapping(uint256 => uint256) public override allowedExpirationsMap;

    /// @dev Stores an array of allowed expirations.
    // The index in the array is the ExpirationID, the value is the ExpirationDate
    // This is a convenience lookup array -> corresponds with allowedExpirations
    // @note The 0th element in the list (first one) is a place holder, since we do not want any
    // expirations with ID 0 (we need to verify in the mapping that 0 means it is not set)
    uint256[] public override allowedExpirationsList;
}

abstract contract SeriesControllerStorageV2 is SeriesControllerStorageV1 {
    IAddressesProvider public addressesProvider;

    mapping(bytes32 => bool) public addedSeries;

    bytes32 public constant SERIES_DEPLOYER_ROLE =
        keccak256("SERIES_DEPLOYER_ROLE");
}

// Next version example:
/// contract SeriesControllerStorageV2 is SeriesControllerStorageV1 {
///   address public myAddress;
/// }
/// Then... SeriesController should inherit from SeriesControllerStorageV2

pragma solidity 0.8.0;

interface IAmmFactory {
    function amms(bytes32 assetPair) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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