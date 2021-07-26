// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

import "./PausableUpgradeable.sol";
import "./ERC165Checker.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./StringsUpgradeable.sol";
import "./ISeriesController.sol";
import "./IERC1155Controller.sol";
import "./ISeriesVault.sol";
import "./Proxiable.sol";
import "./IPriceOracle.sol";
import "./IERC20Lib.sol";
import "./IAddSeriesToAmm.sol";
import "./SeriesLibrary.sol";

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
    ISeriesController,
    PausableUpgradeable,
    AccessControlUpgradeable,
    Proxiable
{
    /** Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;

    /// @dev The price oracle consulted for any price data needed by the individual Series
    address internal priceOracle;

    /// @dev The address of the SeriesVault that stores all of this SeriesController's tokens
    address internal vault;

    /// @dev The fees charged for different methods on the SeriesController
    ISeriesController.Fees internal fees;

    /// @notice Monotonically incrementing index, used when creating Series.
    uint64 public latestIndex;

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

    ///////////////////// MODIFIER FUNCTIONS /////////////////////

    /// @notice Check if the msg.sender is the privileged DEFAULT_ADMIN_ROLE holder
    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "SeriesController: Caller is not the owner"
        );

        _;
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
        return allSeries[seriesId];
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

        Series memory series = allSeries[_seriesId];

        // calculate what amounts of the collateralToken locked in the Series the
        // buyer and the writer can redeem their bToken and wToken for
        if (series.isPutOption) {
            // Put
            if (settlementPrice >= series.strikePrice) {
                // OTM
                writerShare = getCollateralPerOptionToken(
                    _seriesId,
                    _optionTokenAmount
                );
                buyerShare = 0;
            } else {
                // ITM
                writerShare = getCollateralPerOptionTokenInternal(
                    _seriesId,
                    _optionTokenAmount,
                    settlementPrice
                );
                buyerShare = getCollateralPerOptionTokenInternal(
                    _seriesId,
                    _optionTokenAmount,
                    series.strikePrice - settlementPrice
                );
            }
        } else {
            // Call
            if (settlementPrice <= series.strikePrice) {
                // OTM
                writerShare = _optionTokenAmount;
                buyerShare = 0;
            } else {
                // ITM
                writerShare =
                    (_optionTokenAmount * series.strikePrice) /
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
        uint256 feeAmount =
            calculateFee(buyerShare, fees.exerciseFeeBasisPoints);
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
        (, uint256 writerShare) =
            getSettlementAmounts(_seriesId, _wTokenAmount);

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
        Series memory series = allSeries[_seriesId];
        return
            getSeriesName(
                series.tokens.underlyingToken,
                series.tokens.priceToken,
                series.tokens.collateralToken,
                series.strikePrice,
                series.expirationDate,
                series.isPutOption
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
            getCollateralPerOptionTokenInternal(
                _seriesId,
                _optionTokenAmount,
                allSeries[_seriesId].strikePrice
            );
    }

    /// @dev Given a Series and an amount of bToken/wToken, return the amount of collateral token received when exercising this amount of option token
    /// @dev In almost every callsite of this function the price is equal to the strike price, except in Series.getSettlementAmounts where we use the settlementPrice
    /// @param _seriesId The Series ID
    /// @param _optionTokenAmount The amount of bToken/wToken
    /// @param _price The price of the collateral token in units of price token
    /// @return The amount of collateral received when exercising this amount of option token
    function getCollateralPerOptionTokenInternal(
        uint64 _seriesId,
        uint256 _optionTokenAmount,
        uint256 _price
    ) internal view returns (uint256) {
        Series memory series = allSeries[_seriesId];

        // is it a call option?
        if (!series.isPutOption) {
            // for call options this conversion is simple, because 1 optionToken locks
            // 1 unit of collateral token
            return _optionTokenAmount;
        }

        // for put options we need to convert from the optionToken's underlying units
        // to the collateral token units. This way 1 put bToken/wToken is exercisable
        // for the value of 1 underlying token in units of collateral
        return
            (((_optionTokenAmount * _price) / (uint256(10)**priceDecimals)) *
                (uint256(10) **
                    (IERC20Lib(series.tokens.collateralToken).decimals()))) /
            (uint256(10) **
                (IERC20Lib(series.tokens.underlyingToken).decimals()));
    }

    /// @notice Returns the settlement price for this Series.
    /// @return true if the settlement price has been set (i.e. is nonzero), false otherwise
    function getSettlementPrice(uint64 _seriesId)
        public
        view
        returns (bool, uint256)
    {
        Series memory series = allSeries[_seriesId];

        return
            IPriceOracle(priceOracle).getSettlementPrice(
                address(series.tokens.underlyingToken),
                address(series.tokens.priceToken),
                series.expirationDate
            );
    }

    /// @dev Returns the current price for this Series' underlyingToken
    /// in units of priceToken
    function getCurrentPrice(uint64 _seriesId) internal view returns (uint256) {
        Series memory series = allSeries[_seriesId];

        return
            IPriceOracle(priceOracle).getCurrentPrice(
                address(series.tokens.underlyingToken),
                address(series.tokens.priceToken)
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
        (uint256 year, uint256 month, uint256 day) =
            _timestampToDate(_expirationDate);
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
        require(
            dateComponent < 100,
            "SeriesController: cannot format numbers greater than 99"
        );

        string memory componentStr = StringsUpgradeable.toString(dateComponent);
        if (dateComponent < 10) {
            return string(abi.encodePacked("0", componentStr));
        }

        return componentStr;
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

        require(
            _priceOracle != address(0x0),
            "MarketController: Invalid _priceOracle"
        );
        require(_vault != address(0x0), "MarketController: Invalid _vault");
        require(
            _erc1155Controller != address(0x0),
            "MarketController: Invalid _erc1155Controller"
        );

        // validate fee data
        require(
            _fees.exerciseFeeBasisPoints <= 10000 &&
                _fees.closeFeeBasisPoints <= 10000 &&
                _fees.claimFeeBasisPoints <= 10000,
            "SeriesController: _fees must not be greater than 10000"
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
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "SeriesController: must have pauser role to pause"
        );
        _pause();
    }

    /// @notice Unpauses all non-admin functions
    function unpause() external virtual {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "SeriesController: must have pauser role to unpause"
        );
        _pause();
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
    ) external onlyOwner {
        require(
            _strikePrices.length != 0,
            "SeriesController: _strikePrices length must be nonzero"
        );

        require(
            _strikePrices.length == _expirationDates.length,
            "SeriesController: must have the same number of strike prices and expiration dates"
        );

        // validate token data
        require(
            _tokens.underlyingToken != address(0x0),
            "SeriesController: Invalid underlyingToken"
        );
        require(_tokens.priceToken != address(0x0), "Invalid priceToken");
        require(
            _tokens.collateralToken != address(0x0),
            "SeriesController: Invalid collateralToken"
        );

        // validate that the token data makes sense given whether it's a Put or a Call
        if (_isPutOption) {
            require(
                _tokens.underlyingToken != _tokens.collateralToken,
                "SeriesController: Tokens must not match for Put"
            );
        } else {
            require(
                _tokens.underlyingToken == _tokens.collateralToken,
                "SeriesController: Tokens must match for Call"
            );
        }

        // restrictedMinters must be non-empty in order to protect against a subtle footgun: if a user were
        // to pass in an empty restrictedMinters array, then the expected behavior would be that anyone could
        // mint option tokens for that Series. However, this would not be the case because down in
        // SeriesController.mintOptions we check if the caller has the MINTER_ROLE, and so the original intent
        // of having anyone allowed to mint option tokens for that Series would not be honored.
        require(
            _restrictedMinters.length != 0,
            "SeriesController: Must specify Series' restricted minters"
        );

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
                        IAddSeriesToAmm.addSeries.selector
                    )
                ) {
                    IAddSeriesToAmm(_restrictedMinters[j]).addSeries(
                        _latestIndex
                    );
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
        ISeriesController.Tokens calldata _tokens,
        uint256 _strikePrice
    ) private view returns (Series memory) {
        // validate price and expiration
        require(
            _strikePrice != 0,
            "SeriesController: strikePrice cannot equal 0"
        );
        require(
            _expirationDate > block.timestamp,
            "SeriesController: _expirationDate must be in the future"
        );
        require(
            _expirationDate ==
                IPriceOracle(priceOracle).get8amAlignedDate(_expirationDate),
            "SeriesController: _expirationDate must be aligned to 8am UTC"
        );

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
    {
        // NOTE: this assumes that values in the allSeries array are never removed,
        // which is fine because there's currently no way to remove Series
        require(
            allSeries.length > _seriesId,
            "SeriesController: Series at this _seriesId does not exist"
        );

        require(
            state(_seriesId) == SeriesState.OPEN,
            "SeriesController: Option contract must be in Open State to mint"
        );

        // Is the caller one of the AMM pools, which are the only addresses with the MINTER_ROLE?
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "SeriesController: caller must have MINTER_ROLE"
        );

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

        uint256 collateralAmount =
            getCollateralPerOptionToken(_seriesId, _optionTokenAmount);

        // transfer this collateral to the vault for storage
        transferERC20In(msg.sender, _seriesId, collateralAmount);

        // Tell any offchain listeners that we minted some tokens
        emit OptionMinted(msg.sender, _seriesId, _optionTokenAmount);
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
    ) external override whenNotPaused {
        // We support only European style options so we exercise only after expiry, and only using
        // the settlement price set at expiration
        require(
            state(_seriesId) == SeriesState.EXPIRED,
            "SeriesController: Option contract must be in EXPIRED State to exercise"
        );

        // Save off the caller
        address redeemer = msg.sender;

        // Set settlement price in case it hasn't been set yet
        setSettlementPrice(_seriesId);

        // Buyer's share
        (uint256 collateralAmount, uint256 feeAmount) =
            getExerciseAmount(_seriesId, _bTokenAmount);

        // Only ITM exercise results in payoff
        require(
            !_revertOtm || collateralAmount > 0,
            "Only in-the-money options can be exercised"
        );

        Series memory series = allSeries[_seriesId];

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
                series.tokens.collateralToken,
                feeAmount
            );
        }

        // Send the collateral from the vault to the caller's address
        if (collateralAmount > 0) {
            transferERC20Out(_seriesId, redeemer, collateralAmount);
        }

        // Emit the Redeem Event
        emit OptionExercised(
            redeemer,
            _seriesId,
            _bTokenAmount,
            collateralAmount
        );
    }

    /// @notice Redeem the wToken for collateral token for the given Series
    /// @param _seriesId The ID of the Series
    /// @param _wTokenAmount The number of wToken to claim
    /// @dev Option tokens have the same decimals as the underlying token
    function claimCollateral(uint64 _seriesId, uint256 _wTokenAmount)
        external
        override
        whenNotPaused
    {
        require(
            state(_seriesId) == SeriesState.EXPIRED,
            "SeriesController: Option contract must be in EXPIRED State to claim collateral"
        );

        // Save off the caller
        address redeemer = msg.sender;

        // Set settlement price in case it hasn't been set yet
        setSettlementPrice(_seriesId);

        // Total collateral owed to wToken holder
        (uint256 collateralAmount, uint256 feeAmount) =
            getClaimAmount(_seriesId, _wTokenAmount);

        Series memory series = allSeries[_seriesId];

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
                address(series.tokens.collateralToken),
                feeAmount
            );
        }

        // Send the collateral from the vault to the caller's address
        transferERC20Out(_seriesId, redeemer, collateralAmount);

        // Emit event
        emit CollateralClaimed(
            redeemer,
            _seriesId,
            _wTokenAmount,
            collateralAmount
        );
    }

    /// @notice Close the position and take back collateral for the given Series
    /// @param _seriesId The ID of the Series
    /// @param _optionTokenAmount The number of bToken and wToken to close
    /// @dev Option tokens have the same decimals as the underlying token
    function closePosition(uint64 _seriesId, uint256 _optionTokenAmount)
        external
        override
        whenNotPaused
    {
        require(
            state(_seriesId) == SeriesState.OPEN,
            "SeriesController: Option contract must be in Open State to close a position"
        );

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

        uint256 collateralAmount =
            getCollateralPerOptionToken(_seriesId, _optionTokenAmount);

        // Calculate the claim Fee and move it if it is valid
        uint256 feeAmount =
            calculateFee(collateralAmount, fees.closeFeeBasisPoints);
        if (feeAmount > 0) {
            // First set the collateral amount that will be left over to send out
            collateralAmount -= feeAmount;

            // Send the fee Amount to the fee receiver
            transferERC20Out(_seriesId, fees.feeReceiver, feeAmount);

            Series memory series = allSeries[_seriesId];

            // Emit the fee event
            emit FeePaid(
                FeeType.CLOSE_FEE,
                address(series.tokens.collateralToken),
                feeAmount
            );
        }

        // Send the collateral to the caller's address
        transferERC20Out(_seriesId, redeemer, collateralAmount);

        // Emit the Closed Event
        emit OptionClosed(
            redeemer,
            _seriesId,
            _optionTokenAmount,
            collateralAmount
        );
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

    /// @notice transfer the DEFAULT_ADMIN_ROLE from the msg.sender to a new address
    /// @param _newAdmin the address of the new DEFAULT_ADMIN_ROLE holder
    /// @dev only the admin address may call this function
    function transferOwnership(address _newAdmin) external onlyOwner {
        require(
            _newAdmin != msg.sender,
            "SeriesController: cannot transfer ownership to existing owner"
        );

        // first add _newAdmin to the role, while the msg.sender still
        // has the DEFAULT_ADMIN_ROLE role
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);

        // now remove the current admin from the admin role, leaving only
        // _newAdmin as the sole admin
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Update the priceOracle used when creating new Series
    /// @dev This means the new price oracle must have settlement prices set such that all
    /// existing Series can get their settlement price
    function setPriceOracle(address _priceOracle) external onlyOwner {
        require(
            _priceOracle != address(0x0),
            "SeriesController: _priceOracle cannot be 0x0 address"
        );

        priceOracle = _priceOracle;
    }

    /// @notice Sets the settlement price for all settlement dates prior to the current block timestamp
    /// for the given <underlyingToken>-<priceToken> pair
    /// @param _seriesId The specific series, accessed by its index
    function setSettlementPrice(uint64 _seriesId) internal {
        Series memory series = allSeries[_seriesId];

        return
            IPriceOracle(priceOracle).setSettlementPrice(
                address(series.tokens.underlyingToken),
                address(series.tokens.priceToken)
            );
    }
}