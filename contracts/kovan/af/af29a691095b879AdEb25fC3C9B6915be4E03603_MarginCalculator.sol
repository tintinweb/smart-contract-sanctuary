/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../packages/oz/SafeMath.sol";
import {Ownable} from "../packages/oz/Ownable.sol";
import {OtokenInterface} from "../interfaces/OtokenInterface.sol";
import {OracleInterface} from "../interfaces/OracleInterface.sol";
import {ERC20Interface} from "../interfaces/ERC20Interface.sol";
import {FixedPointInt256 as FPI} from "../libs/FixedPointInt256.sol";
import {MarginVault} from "../libs/MarginVault.sol";

/**
 * @title MarginCalculator
 * @author Opyn
 * @notice Calculator module that checks if a given vault is valid, calculates margin requirements, and settlement proceeds
 */
contract MarginCalculator is Ownable {
    using SafeMath for uint256;
    using FPI for FPI.FixedPointInt;

    /// @dev decimals option upper bound value, spot shock and oracle deviation
    uint256 internal constant SCALING_FACTOR = 27;

    /// @dev decimals used by strike price and oracle price
    uint256 internal constant BASE = 8;

    /// @notice auction length
    uint256 public constant AUCTION_TIME = 3600;

    /// @dev struct to store all needed vault details
    struct VaultDetails {
        address shortUnderlyingAsset;
        address shortStrikeAsset;
        address shortCollateralAsset;
        address longUnderlyingAsset;
        address longStrikeAsset;
        address longCollateralAsset;
        uint256 shortStrikePrice;
        uint256 shortExpiryTimestamp;
        uint256 shortCollateralDecimals;
        uint256 longStrikePrice;
        uint256 longExpiryTimestamp;
        uint256 longCollateralDecimals;
        uint256 collateralDecimals;
        uint256 vaultType;
        bool isShortPut;
        bool isLongPut;
        bool hasLong;
        bool hasShort;
        bool hasCollateral;
    }

    /// @dev oracle deviation value (1e27)
    uint256 internal oracleDeviation;

    /// @dev FixedPoint 0
    FPI.FixedPointInt internal ZERO = FPI.fromScaledUint(0, BASE);

    /// @dev mapping to store dust amount per option collateral asset (scaled by collateral asset decimals)
    mapping(address => uint256) internal dust;

    /// @dev mapping to store array of time to expiry for a given product
    mapping(bytes32 => uint256[]) internal timesToExpiryForProduct;

    /// @dev mapping to store option upper bound value at specific time to expiry for a given product (1e27)
    mapping(bytes32 => mapping(uint256 => uint256)) internal maxPriceAtTimeToExpiry;

    /// @dev mapping to store shock value for spot price of a given product (1e27)
    mapping(bytes32 => uint256) internal spotShock;

    /// @dev oracle module
    OracleInterface public oracle;

    /// @notice emits an event when collateral dust is updated
    event CollateralDustUpdated(address indexed collateral, uint256 dust);
    /// @notice emits an event when new time to expiry is added for a specific product
    event TimeToExpiryAdded(bytes32 indexed productHash, uint256 timeToExpiry);
    /// @notice emits an event when new upper bound value is added for a specific time to expiry timestamp
    event MaxPriceAdded(bytes32 indexed productHash, uint256 timeToExpiry, uint256 value);
    /// @notice emits an event when updating upper bound value at specific expiry timestamp
    event MaxPriceUpdated(bytes32 indexed productHash, uint256 timeToExpiry, uint256 oldValue, uint256 newValue);
    /// @notice emits an event when spot shock value is updated for a specific product
    event SpotShockUpdated(bytes32 indexed product, uint256 spotShock);
    /// @notice emits an event when oracle deviation value is updated
    event OracleDeviationUpdated(uint256 oracleDeviation);

    /**
     * @notice constructor
     * @param _oracle oracle module address
     */
    constructor(address _oracle) public {
        require(_oracle != address(0), "MarginCalculator: invalid oracle address");

        oracle = OracleInterface(_oracle);
    }

    /**
     * @notice set dust amount for collateral asset
     * @dev can only be called by owner
     * @param _collateral collateral asset address
     * @param _dust dust amount, should be scaled by collateral asset decimals
     */
    function setCollateralDust(address _collateral, uint256 _dust) external onlyOwner {
        require(_dust > 0, "MarginCalculator: dust amount should be greater than zero");

        dust[_collateral] = _dust;

        emit CollateralDustUpdated(_collateral, _dust);
    }

    /**
     * @notice set product upper bound values
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timesToExpiry array of times to expiry timestamp
     * @param _values upper bound values array
     */
    function setUpperBoundValues(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256[] calldata _timesToExpiry,
        uint256[] calldata _values
    ) external onlyOwner {
        require(_timesToExpiry.length > 0, "MarginCalculator: invalid times to expiry array");
        require(_timesToExpiry.length == _values.length, "MarginCalculator: invalid values array");

        // get product hash
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        uint256[] storage expiryArray = timesToExpiryForProduct[productHash];

        // check that this is the first expiry to set
        // if not, the last expiry should be less than the new one to insert (to make sure the array stay in order)
        require(
            (expiryArray.length == 0) || (_timesToExpiry[0] > expiryArray[expiryArray.length.sub(1)]),
            "MarginCalculator: expiry array is not in order"
        );

        for (uint256 i = 0; i < _timesToExpiry.length; i++) {
            // check that new times array is in order
            if (i.add(1) < _timesToExpiry.length) {
                require(_timesToExpiry[i] < _timesToExpiry[i.add(1)], "MarginCalculator: time should be in order");
            }

            require(_values[i] > 0, "MarginCalculator: no expiry upper bound value found");

            // add new upper bound value for this product at specific time to expiry
            maxPriceAtTimeToExpiry[productHash][_timesToExpiry[i]] = _values[i];

            // add new time to expiry to array
            expiryArray.push(_timesToExpiry[i]);

            emit TimeToExpiryAdded(productHash, _timesToExpiry[i]);
            emit MaxPriceAdded(productHash, _timesToExpiry[i], _values[i]);
        }
    }

    /**
     * @notice set option upper bound value for specific time to expiry (1e27)
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timeToExpiry option time to expiry timestamp
     * @param _value upper bound value
     */
    function updateUpperBoundValue(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _timeToExpiry,
        uint256 _value
    ) external onlyOwner {
        require(_value > 0, "MarginCalculator: invalid option upper bound value");

        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);
        uint256 oldMaxPrice = maxPriceAtTimeToExpiry[productHash][_timeToExpiry];

        require(oldMaxPrice != 0, "MarginCalculator: upper bound value not found");

        // update upper bound value for the time to expiry
        maxPriceAtTimeToExpiry[productHash][_timeToExpiry] = _value;

        emit MaxPriceUpdated(productHash, _timeToExpiry, oldMaxPrice, _value);
    }

    /**
     * @notice set spot shock value, scaled to 1e27
     * @dev can only be called by owner
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _shockValue spot shock value
     */
    function setSpotShock(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _shockValue
    ) external onlyOwner {
        require(_shockValue > 0, "MarginCalculator: invalid spot shock value");

        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        spotShock[productHash] = _shockValue;

        emit SpotShockUpdated(productHash, _shockValue);
    }

    /**
     * @notice set oracle deviation (1e27)
     * @dev can only be called by owner
     * @param _deviation deviation value
     */
    function setOracleDeviation(uint256 _deviation) external onlyOwner {
        oracleDeviation = _deviation;

        emit OracleDeviationUpdated(_deviation);
    }

    /**
     * @notice get dust amount for collateral asset
     * @param _collateral collateral asset address
     * @return dust amount
     */
    function getCollateralDust(address _collateral) external view returns (uint256) {
        return dust[_collateral];
    }

    /**
     * @notice get times to expiry for a specific product
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @return array of times to expiry
     */
    function getTimesToExpiry(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (uint256[] memory) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);
        return timesToExpiryForProduct[productHash];
    }

    /**
     * @notice get option upper bound value for specific time to expiry
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @param _timeToExpiry option time to expiry timestamp
     * @return option upper bound value (1e27)
     */
    function getMaxPrice(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut,
        uint256 _timeToExpiry
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        return maxPriceAtTimeToExpiry[productHash][_timeToExpiry];
    }

    /**
     * @notice get spot shock value
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _collateral otoken collateral asset
     * @param _isPut otoken type
     * @return _shockValue spot shock value (1e27)
     */
    function getSpotShock(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        return spotShock[productHash];
    }

    /**
     * @notice get oracle deviation
     * @return oracle deviation value (1e27)
     */
    function getOracleDeviation() external view returns (uint256) {
        return oracleDeviation;
    }

    /**
     * @notice return the collateral required for naked margin vault, in collateral asset decimals
     * @dev _shortAmount, _strikePrice and _underlyingPrice should be scaled by 1e8
     * @param _underlying underlying asset address
     * @param _strike strike asset address
     * @param _collateral collateral asset address
     * @param _shortAmount amount of short otoken
     * @param  _strikePrice otoken strike price
     * @param _underlyingPrice otoken underlying price
     * @param _shortExpiryTimestamp otoken expiry timestamp
     * @param _collateralDecimals otoken collateral asset decimals
     * @param _isPut otoken type
     * @return collateral required for a naked margin vault, in collateral asset decimals
     */
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256) {
        bytes32 productHash = _getProductHash(_underlying, _strike, _collateral, _isPut);

        // scale short amount from 1e8 to 1e27 (oToken is always in 1e8)
        FPI.FixedPointInt memory shortAmount = FPI.fromScaledUint(_shortAmount, BASE);
        // scale short strike from 1e8 to 1e27
        FPI.FixedPointInt memory shortStrike = FPI.fromScaledUint(_strikePrice, BASE);
        // scale short underlying price from 1e8 to 1e27
        FPI.FixedPointInt memory shortUnderlyingPrice = FPI.fromScaledUint(_underlyingPrice, BASE);

        // return required margin, scaled by collateral asset decimals, explicitly rounded up
        return
            FPI.toScaledUint(
                _getNakedMarginRequired(
                    productHash,
                    shortAmount,
                    shortUnderlyingPrice,
                    shortStrike,
                    _shortExpiryTimestamp,
                    _isPut
                ),
                _collateralDecimals,
                false
            );
    }

    /**
     * @notice return the cash value of an expired oToken, denominated in collateral
     * @param _otoken oToken address
     * @return how much collateral can be taken out by 1 otoken unit, scaled by 1e8,
     * or how much collateral can be taken out for 1 (1e8) oToken
     */
    function getExpiredPayoutRate(address _otoken) external view returns (uint256) {
        require(_otoken != address(0), "MarginCalculator: Invalid token address");

        (
            address collateral,
            address underlying,
            address strikeAsset,
            uint256 strikePrice,
            uint256 expiry,
            bool isPut
        ) = _getOtokenDetails(_otoken);

        require(now >= expiry, "MarginCalculator: Otoken not expired yet");

        FPI.FixedPointInt memory cashValueInStrike = _getExpiredCashValue(
            underlying,
            strikeAsset,
            expiry,
            strikePrice,
            isPut
        );

        FPI.FixedPointInt memory cashValueInCollateral = _convertAmountOnExpiryPrice(
            cashValueInStrike,
            strikeAsset,
            collateral,
            expiry
        );

        // the exchangeRate was scaled by 1e8, if 1e8 otoken can take out 1 USDC, the exchangeRate is currently 1e8
        // we want to return: how much USDC units can be taken out by 1 (1e8 units) oToken
        uint256 collateralDecimals = uint256(ERC20Interface(collateral).decimals());
        return cashValueInCollateral.toScaledUint(collateralDecimals, true);
    }

    // structs to avoid stack too deep error
    // struct to store shortAmount, shortStrike and shortUnderlyingPrice scaled to 1e27
    struct ShortScaledDetails {
        FPI.FixedPointInt shortAmount;
        FPI.FixedPointInt shortStrike;
        FPI.FixedPointInt shortUnderlyingPrice;
    }

    /**
     * @notice check if a specific vault is undercollateralized at a specific chainlink round
     * @dev if the vault is of type 0, the function will revert
     * @param _vault vault struct
     * @param _vaultType vault type (0 for max loss/spread and 1 for naked margin vault)
     * @param _vaultLatestUpdate vault latest update (timestamp when latest vault state change happened)
     * @param _roundId chainlink round id
     * @return isLiquidatable, true if vault is undercollateralized, liquidation price and collateral dust amount
     */
    function isLiquidatable(
        MarginVault.Vault memory _vault,
        uint256 _vaultType,
        uint256 _vaultLatestUpdate,
        uint256 _roundId
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        // liquidation is only supported for naked margin vault
        require(_vaultType == 1, "MarginCalculator: invalid vault type to liquidate");

        VaultDetails memory vaultDetails = _getVaultDetails(_vault, _vaultType);

        // can not liquidate vault that have no short position
        if (!vaultDetails.hasShort) return (false, 0, 0);

        require(now < vaultDetails.shortExpiryTimestamp, "MarginCalculator: can not liquidate expired position");

        (uint256 price, uint256 timestamp) = oracle.getChainlinkRoundData(
            vaultDetails.shortUnderlyingAsset,
            uint80(_roundId)
        );

        // check that price timestamp is after latest timestamp the vault was updated at
        require(
            timestamp > _vaultLatestUpdate,
            "MarginCalculator: auction timestamp should be post vault latest update"
        );

        // another struct to store some useful short otoken details, to avoid stack to deep error
        ShortScaledDetails memory shortDetails = ShortScaledDetails({
            shortAmount: FPI.fromScaledUint(_vault.shortAmounts[0], BASE),
            shortStrike: FPI.fromScaledUint(vaultDetails.shortStrikePrice, BASE),
            shortUnderlyingPrice: FPI.fromScaledUint(price, BASE)
        });

        bytes32 productHash = _getProductHash(
            vaultDetails.shortUnderlyingAsset,
            vaultDetails.shortStrikeAsset,
            vaultDetails.shortCollateralAsset,
            vaultDetails.isShortPut
        );

        // convert vault collateral to a fixed point (1e27) from collateral decimals
        FPI.FixedPointInt memory depositedCollateral = FPI.fromScaledUint(
            _vault.collateralAmounts[0],
            vaultDetails.collateralDecimals
        );

        FPI.FixedPointInt memory collateralRequired = _getNakedMarginRequired(
            productHash,
            shortDetails.shortAmount,
            shortDetails.shortUnderlyingPrice,
            shortDetails.shortStrike,
            vaultDetails.shortExpiryTimestamp,
            vaultDetails.isShortPut
        );

        // if collateral required <= collateral in the vault, the vault is not liquidatable
        if (collateralRequired.isLessThanOrEqual(depositedCollateral)) {
            return (false, 0, 0);
        }

        FPI.FixedPointInt memory cashValue = _getCashValue(
            shortDetails.shortStrike,
            shortDetails.shortUnderlyingPrice,
            vaultDetails.isShortPut
        );

        // get the amount of collateral per 1 repaid otoken
        uint256 debtPrice = _getDebtPrice(
            depositedCollateral,
            shortDetails.shortAmount,
            cashValue,
            shortDetails.shortUnderlyingPrice,
            timestamp,
            vaultDetails.collateralDecimals,
            vaultDetails.isShortPut
        );

        return (true, debtPrice, dust[vaultDetails.shortCollateralAsset]);
    }

    /**
     * @notice calculate required collateral margin for a vault
     * @param _vault theoretical vault that needs to be checked
     * @param _vaultType vault type
     * @return the vault collateral amount, and marginRequired the minimal amount of collateral needed in a vault, scaled to 1e27
     */
    function getMarginRequired(MarginVault.Vault memory _vault, uint256 _vaultType)
        external
        view
        returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory)
    {
        VaultDetails memory vaultDetail = _getVaultDetails(_vault, _vaultType);
        return _getMarginRequired(_vault, vaultDetail);
    }

    /**
     * @notice returns the amount of collateral that can be removed from an actual or a theoretical vault
     * @dev return amount is denominated in the collateral asset for the oToken in the vault, or the collateral asset in the vault
     * @param _vault theoretical vault that needs to be checked
     * @param _vaultType vault type (0 for spread/max loss, 1 for naked margin)
     * @return excessCollateral the amount by which the margin is above or below the required amount
     * @return isExcess True if there is excess margin in the vault, False if there is a deficit of margin in the vault
     * if True, collateral can be taken out from the vault, if False, additional collateral needs to be added to vault
     */
    function getExcessCollateral(MarginVault.Vault memory _vault, uint256 _vaultType)
        public
        view
        returns (uint256, bool)
    {
        VaultDetails memory vaultDetails = _getVaultDetails(_vault, _vaultType);

        // include all the checks for to ensure the vault is valid
        _checkIsValidVault(_vault, vaultDetails);

        // if the vault contains no oTokens, return the amount of collateral
        if (!vaultDetails.hasShort && !vaultDetails.hasLong) {
            uint256 amount = vaultDetails.hasCollateral ? _vault.collateralAmounts[0] : 0;
            return (amount, true);
        }

        // get required margin, denominated in collateral, scaled in 1e27
        (FPI.FixedPointInt memory collateralAmount, FPI.FixedPointInt memory collateralRequired) = _getMarginRequired(
            _vault,
            vaultDetails
        );
        FPI.FixedPointInt memory excessCollateral = collateralAmount.sub(collateralRequired);

        bool isExcess = excessCollateral.isGreaterThanOrEqual(ZERO);
        uint256 collateralDecimals = vaultDetails.hasLong
            ? vaultDetails.longCollateralDecimals
            : vaultDetails.shortCollateralDecimals;
        // if is excess, truncate the tailing digits in excessCollateralExternal calculation
        uint256 excessCollateralExternal = excessCollateral.toScaledUint(collateralDecimals, isExcess);
        return (excessCollateralExternal, isExcess);
    }

    /**
     * @notice return the cash value of an expired oToken, denominated in strike asset
     * @dev for a call, return Max (0, underlyingPriceInStrike - otoken.strikePrice)
     * @dev for a put, return Max(0, otoken.strikePrice - underlyingPriceInStrike)
     * @param _underlying otoken underlying asset
     * @param _strike otoken strike asset
     * @param _expiryTimestamp otoken expiry timestamp
     * @param _strikePrice otoken strike price
     * @param _strikePrice true if otoken is put otherwise false
     * @return cash value of an expired otoken, denominated in the strike asset
     */
    function _getExpiredCashValue(
        address _underlying,
        address _strike,
        uint256 _expiryTimestamp,
        uint256 _strikePrice,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        // strike price is denominated in strike asset
        FPI.FixedPointInt memory strikePrice = FPI.fromScaledUint(_strikePrice, BASE);
        FPI.FixedPointInt memory one = FPI.fromScaledUint(1, 0);

        // calculate the value of the underlying asset in terms of the strike asset
        FPI.FixedPointInt memory underlyingPriceInStrike = _convertAmountOnExpiryPrice(
            one, // underlying price is 1 (1e27) in term of underlying
            _underlying,
            _strike,
            _expiryTimestamp
        );

        return _getCashValue(strikePrice, underlyingPriceInStrike, _isPut);
    }

    /// @dev added this struct to avoid stack-too-deep error
    struct OtokenDetails {
        address otokenUnderlyingAsset;
        address otokenCollateralAsset;
        address otokenStrikeAsset;
        uint256 otokenExpiry;
        bool isPut;
    }

    /**
     * @notice calculate the amount of collateral needed for a vault
     * @dev vault passed in has already passed the checkIsValidVault function
     * @param _vault theoretical vault that needs to be checked
     * @return the vault collateral amount, and marginRequired the minimal amount of collateral needed in a vault,
     * scaled to 1e27
     */
    function _getMarginRequired(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        view
        returns (FPI.FixedPointInt memory, FPI.FixedPointInt memory)
    {
        FPI.FixedPointInt memory shortAmount = _vaultDetails.hasShort
            ? FPI.fromScaledUint(_vault.shortAmounts[0], BASE)
            : ZERO;
        FPI.FixedPointInt memory longAmount = _vaultDetails.hasLong
            ? FPI.fromScaledUint(_vault.longAmounts[0], BASE)
            : ZERO;
        FPI.FixedPointInt memory collateralAmount = _vaultDetails.hasCollateral
            ? FPI.fromScaledUint(_vault.collateralAmounts[0], _vaultDetails.collateralDecimals)
            : ZERO;
        FPI.FixedPointInt memory shortStrike = _vaultDetails.hasShort
            ? FPI.fromScaledUint(_vaultDetails.shortStrikePrice, BASE)
            : ZERO;

        // struct to avoid stack too deep error
        OtokenDetails memory otokenDetails = OtokenDetails(
            _vaultDetails.hasShort ? _vaultDetails.shortUnderlyingAsset : _vaultDetails.longUnderlyingAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortCollateralAsset : _vaultDetails.longCollateralAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortStrikeAsset : _vaultDetails.longStrikeAsset,
            _vaultDetails.hasShort ? _vaultDetails.shortExpiryTimestamp : _vaultDetails.longExpiryTimestamp,
            _vaultDetails.hasShort ? _vaultDetails.isShortPut : _vaultDetails.isLongPut
        );

        if (now < otokenDetails.otokenExpiry) {
            // it's not expired, return amount of margin required based on vault type
            if (_vaultDetails.vaultType == 1) {
                // this is a naked margin vault
                // fetch dust amount for otoken collateral asset as FixedPointInt, assuming dust is already scaled by collateral decimals
                FPI.FixedPointInt memory dustAmount = FPI.fromScaledUint(
                    dust[_vaultDetails.shortCollateralAsset],
                    _vaultDetails.collateralDecimals
                );

                // check that collateral deposited in naked margin vault is greater than dust amount for that particular collateral asset
                if (collateralAmount.isGreaterThan(ZERO)) {
                    require(
                        collateralAmount.isGreaterThan(dustAmount),
                        "MarginCalculator: naked margin vault should have collateral amount greater than dust amount"
                    );
                }

                // get underlying asset price for short option
                FPI.FixedPointInt memory shortUnderlyingPrice = FPI.fromScaledUint(
                    oracle.getPrice(_vaultDetails.shortUnderlyingAsset),
                    BASE
                );

                // encode product hash
                bytes32 productHash = _getProductHash(
                    _vaultDetails.shortUnderlyingAsset,
                    _vaultDetails.shortStrikeAsset,
                    _vaultDetails.shortCollateralAsset,
                    _vaultDetails.isShortPut
                );

                // return amount of collateral in vault and needed collateral amount for margin
                return (
                    collateralAmount,
                    _getNakedMarginRequired(
                        productHash,
                        shortAmount,
                        shortUnderlyingPrice,
                        shortStrike,
                        otokenDetails.otokenExpiry,
                        otokenDetails.isPut
                    )
                );
            } else {
                // this is a fully collateralized vault
                FPI.FixedPointInt memory longStrike = _vaultDetails.hasLong
                    ? FPI.fromScaledUint(_vaultDetails.longStrikePrice, BASE)
                    : ZERO;

                if (otokenDetails.isPut) {
                    FPI.FixedPointInt memory strikeNeeded = _getPutSpreadMarginRequired(
                        shortAmount,
                        longAmount,
                        shortStrike,
                        longStrike
                    );
                    // convert amount to be denominated in collateral
                    return (
                        collateralAmount,
                        _convertAmountOnLivePrice(
                            strikeNeeded,
                            otokenDetails.otokenStrikeAsset,
                            otokenDetails.otokenCollateralAsset
                        )
                    );
                } else {
                    FPI.FixedPointInt memory underlyingNeeded = _getCallSpreadMarginRequired(
                        shortAmount,
                        longAmount,
                        shortStrike,
                        longStrike
                    );
                    // convert amount to be denominated in collateral
                    return (
                        collateralAmount,
                        _convertAmountOnLivePrice(
                            underlyingNeeded,
                            otokenDetails.otokenUnderlyingAsset,
                            otokenDetails.otokenCollateralAsset
                        )
                    );
                }
            }
        } else {
            // the vault has expired. calculate the cash value of all the minted short options
            FPI.FixedPointInt memory shortCashValue = _vaultDetails.hasShort
                ? _getExpiredCashValue(
                    _vaultDetails.shortUnderlyingAsset,
                    _vaultDetails.shortStrikeAsset,
                    _vaultDetails.shortExpiryTimestamp,
                    _vaultDetails.shortStrikePrice,
                    otokenDetails.isPut
                )
                : ZERO;
            FPI.FixedPointInt memory longCashValue = _vaultDetails.hasLong
                ? _getExpiredCashValue(
                    _vaultDetails.longUnderlyingAsset,
                    _vaultDetails.longStrikeAsset,
                    _vaultDetails.longExpiryTimestamp,
                    _vaultDetails.longStrikePrice,
                    otokenDetails.isPut
                )
                : ZERO;

            FPI.FixedPointInt memory valueInStrike = _getExpiredSpreadCashValue(
                shortAmount,
                longAmount,
                shortCashValue,
                longCashValue
            );

            // convert amount to be denominated in collateral
            return (
                collateralAmount,
                _convertAmountOnExpiryPrice(
                    valueInStrike,
                    otokenDetails.otokenStrikeAsset,
                    otokenDetails.otokenCollateralAsset,
                    otokenDetails.otokenExpiry
                )
            );
        }
    }

    /**
     * @notice get required collateral for naked margin position
     * if put:
     * a = min(strike price, spot shock * underlying price)
     * b = max(strike price - spot shock * underlying price, 0)
     * marginRequired = ( option upper bound value * a + b) * short amount
     * if call:
     * a = min(1, strike price / (underlying price / spot shock value))
     * b = max(1- (strike price / (underlying price / spot shock value)), 0)
     * marginRequired = (option upper bound value * a + b) * short amount
     * @param _productHash product hash
     * @param _shortAmount short amount in vault, in FixedPointInt type
     * @param _strikePrice strike price of short otoken, in FixedPointInt type
     * @param _underlyingPrice underlying price of short otoken underlying asset, in FixedPointInt type
     * @param _shortExpiryTimestamp short otoken expiry timestamp
     * @param _isPut otoken type, true if put option, false for call option
     * @return required margin for this naked vault, in FixedPointInt type (scaled by 1e27)
     */
    function _getNakedMarginRequired(
        bytes32 _productHash,
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _underlyingPrice,
        FPI.FixedPointInt memory _strikePrice,
        uint256 _shortExpiryTimestamp,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        // find option upper bound value
        FPI.FixedPointInt memory optionUpperBoundValue = _findUpperBoundValue(_productHash, _shortExpiryTimestamp);
        // convert spot shock value of this product to FixedPointInt (already scaled by 1e27)
        FPI.FixedPointInt memory spotShockValue = FPI.FixedPointInt(int256(spotShock[_productHash]));

        FPI.FixedPointInt memory a;
        FPI.FixedPointInt memory b;
        FPI.FixedPointInt memory marginRequired;

        if (_isPut) {
            a = FPI.min(_strikePrice, spotShockValue.mul(_underlyingPrice));
            b = FPI.max(_strikePrice.sub(spotShockValue.mul(_underlyingPrice)), ZERO);
            marginRequired = optionUpperBoundValue.mul(a).add(b).mul(_shortAmount);
        } else {
            FPI.FixedPointInt memory one = FPI.fromScaledUint(1e27, SCALING_FACTOR);
            a = FPI.min(one, _strikePrice.mul(spotShockValue).div(_underlyingPrice));
            b = FPI.max(one.sub(_strikePrice.mul(spotShockValue).div(_underlyingPrice)), ZERO);
            marginRequired = optionUpperBoundValue.mul(a).add(b).mul(_shortAmount);
        }

        return marginRequired;
    }

    /**
     * @notice find upper bound value for product by specific expiry timestamp
     * @dev should return the upper bound value that correspond to option time to expiry, of if not found should return the next greater one, revert if no value found
     * @param _productHash product hash
     * @param _expiryTimestamp expiry timestamp
     * @return option upper bound value
     */
    function _findUpperBoundValue(bytes32 _productHash, uint256 _expiryTimestamp)
        internal
        view
        returns (FPI.FixedPointInt memory)
    {
        // get time to expiry array of this product hash
        uint256[] memory timesToExpiry = timesToExpiryForProduct[_productHash];

        // check that this product have upper bound values stored
        require(timesToExpiry.length != 0, "MarginCalculator: product have no expiry values");

        uint256 optionTimeToExpiry = _expiryTimestamp.sub(now);

        // check that the option time to expiry is in the expiry array
        require(
            timesToExpiry[timesToExpiry.length.sub(1)] >= optionTimeToExpiry,
            "MarginCalculator: product have no upper bound value"
        );

        // loop through the array and return the upper bound value in FixedPointInt type (already scaled by 1e27)
        for (uint8 i = 0; i < timesToExpiry.length; i++) {
            if (timesToExpiry[i] >= optionTimeToExpiry)
                return FPI.fromScaledUint(maxPriceAtTimeToExpiry[_productHash][timesToExpiry[i]], SCALING_FACTOR);
        }
    }

    /**
     * @dev returns the strike asset amount of margin required for a put or put spread with the given short oTokens, long oTokens and amounts
     *
     * marginRequired = max( (short amount * short strike) - (long strike * min (short amount, long amount)) , 0 )
     *
     * @return margin requirement denominated in the strike asset
     */
    function _getPutSpreadMarginRequired(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortStrike,
        FPI.FixedPointInt memory _longStrike
    ) internal view returns (FPI.FixedPointInt memory) {
        return FPI.max(_shortAmount.mul(_shortStrike).sub(_longStrike.mul(FPI.min(_shortAmount, _longAmount))), ZERO);
    }

    /**
     * @dev returns the underlying asset amount required for a call or call spread with the given short oTokens, long oTokens, and amounts
     *
     *                           (long strike - short strike) * short amount
     * marginRequired =  max( ------------------------------------------------- , max (short amount - long amount, 0) )
     *                                           long strike
     *
     * @dev if long strike = 0, return max( short amount - long amount, 0)
     * @return margin requirement denominated in the underlying asset
     */
    function _getCallSpreadMarginRequired(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortStrike,
        FPI.FixedPointInt memory _longStrike
    ) internal view returns (FPI.FixedPointInt memory) {
        // max (short amount - long amount , 0)
        if (_longStrike.isEqual(ZERO)) {
            return FPI.max(_shortAmount.sub(_longAmount), ZERO);
        }

        /**
         *             (long strike - short strike) * short amount
         * calculate  ----------------------------------------------
         *                             long strike
         */
        FPI.FixedPointInt memory firstPart = _longStrike.sub(_shortStrike).mul(_shortAmount).div(_longStrike);

        /**
         * calculate max ( short amount - long amount , 0)
         */
        FPI.FixedPointInt memory secondPart = FPI.max(_shortAmount.sub(_longAmount), ZERO);

        return FPI.max(firstPart, secondPart);
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on a live price
     * @dev function includes the amount and applies .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnLivePrice(
        FPI.FixedPointInt memory _amount,
        address _assetA,
        address _assetB
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        uint256 priceA = oracle.getPrice(_assetA);
        uint256 priceB = oracle.getPrice(_assetB);
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice convert an amount in asset A to equivalent amount of asset B, based on an expiry price
     * @dev function includes the amount and apply .mul() first to increase the accuracy
     * @param _amount amount in asset A
     * @param _assetA asset A
     * @param _assetB asset B
     * @return _amount in asset B
     */
    function _convertAmountOnExpiryPrice(
        FPI.FixedPointInt memory _amount,
        address _assetA,
        address _assetB,
        uint256 _expiry
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_assetA == _assetB) {
            return _amount;
        }
        (uint256 priceA, bool priceAFinalized) = oracle.getExpiryPrice(_assetA, _expiry);
        (uint256 priceB, bool priceBFinalized) = oracle.getExpiryPrice(_assetB, _expiry);
        require(priceAFinalized && priceBFinalized, "MarginCalculator: price at expiry not finalized yet");
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        return _amount.mul(FPI.fromScaledUint(priceA, BASE)).div(FPI.fromScaledUint(priceB, BASE));
    }

    /**
     * @notice return debt price, how much collateral asset per 1 otoken repaid in collateral decimal
     * ending price = vault collateral / vault debt
     * if auction ended, return ending price
     * else calculate starting price
     * for put option:
     * starting price = max(cash value - underlying price * oracle deviation, 0)
     * for call option:
     *                      max(cash value - underlying price * oracle deviation, 0)
     * starting price =  ---------------------------------------------------------------
     *                                          underlying price
     *
     *
     *                  starting price + (ending price - starting price) * auction elapsed time
     * then price = --------------------------------------------------------------------------
     *                                      auction time
     *
     *
     * @param _vaultCollateral vault collateral amount
     * @param _vaultDebt vault short amount
     * @param _cashValue option cash value
     * @param _spotPrice option underlying asset price (in USDC)
     * @param _auctionStartingTime auction starting timestamp (_spotPrice timestamp from chainlink)
     * @param _collateralDecimals collateral asset decimals
     * @param _isPut otoken type, true for put, false for call option
     * @return price of 1 debt otoken in collateral asset scaled by collateral decimals
     */
    function _getDebtPrice(
        FPI.FixedPointInt memory _vaultCollateral,
        FPI.FixedPointInt memory _vaultDebt,
        FPI.FixedPointInt memory _cashValue,
        FPI.FixedPointInt memory _spotPrice,
        uint256 _auctionStartingTime,
        uint256 _collateralDecimals,
        bool _isPut
    ) internal view returns (uint256) {
        // price of 1 repaid otoken in collateral asset, scaled to 1e27
        FPI.FixedPointInt memory price;
        // auction ending price
        FPI.FixedPointInt memory endingPrice = _vaultCollateral.div(_vaultDebt);

        // auction elapsed time
        uint256 auctionElapsedTime = now.sub(_auctionStartingTime);

        // if auction ended, return ending price
        if (auctionElapsedTime >= AUCTION_TIME) {
            price = endingPrice;
        } else {
            // starting price
            FPI.FixedPointInt memory startingPrice;

            {
                // store oracle deviation in a FixedPointInt (already scaled by 1e27)
                FPI.FixedPointInt memory fixedOracleDeviation = FPI.fromScaledUint(oracleDeviation, SCALING_FACTOR);

                if (_isPut) {
                    startingPrice = FPI.max(_cashValue.sub(fixedOracleDeviation.mul(_spotPrice)), ZERO);
                } else {
                    startingPrice = FPI.max(_cashValue.sub(fixedOracleDeviation.mul(_spotPrice)), ZERO).div(_spotPrice);
                }
            }

            // store auctionElapsedTime in a FixedPointInt scaled by 1e27
            FPI.FixedPointInt memory auctionElapsedTimeFixedPoint = FPI.fromScaledUint(auctionElapsedTime, 18);
            // store AUCTION_TIME in a FixedPointInt (already scaled by 1e27)
            FPI.FixedPointInt memory auctionTime = FPI.fromScaledUint(AUCTION_TIME, 18);

            // calculate price of 1 repaid otoken, scaled by the collateral decimals, expilictly rounded down
            price = startingPrice.add(
                (endingPrice.sub(startingPrice)).mul(auctionElapsedTimeFixedPoint).div(auctionTime)
            );

            // cap liquidation price to ending price
            if (price.isGreaterThan(endingPrice)) price = endingPrice;
        }

        return price.toScaledUint(_collateralDecimals, true);
    }

    /**
     * @notice get vault details to save us from making multiple external calls
     * @param _vault vault struct
     * @param _vaultType vault type, 0 for max loss/spreads and 1 for naked margin vault
     * @return vault details in VaultDetails struct
     */
    function _getVaultDetails(MarginVault.Vault memory _vault, uint256 _vaultType)
        internal
        view
        returns (VaultDetails memory)
    {
        VaultDetails memory vaultDetails = VaultDetails(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            false,
            false,
            false,
            false,
            false
        );

        // check if vault has long, short otoken and collateral asset
        vaultDetails.hasLong = _isNotEmpty(_vault.longOtokens);
        vaultDetails.hasShort = _isNotEmpty(_vault.shortOtokens);
        vaultDetails.hasCollateral = _isNotEmpty(_vault.collateralAssets);

        vaultDetails.vaultType = _vaultType;

        // get vault long otoken if available
        if (vaultDetails.hasLong) {
            OtokenInterface long = OtokenInterface(_vault.longOtokens[0]);
            (
                vaultDetails.longCollateralAsset,
                vaultDetails.longUnderlyingAsset,
                vaultDetails.longStrikeAsset,
                vaultDetails.longStrikePrice,
                vaultDetails.longExpiryTimestamp,
                vaultDetails.isLongPut
            ) = _getOtokenDetails(address(long));
            vaultDetails.longCollateralDecimals = uint256(ERC20Interface(vaultDetails.longCollateralAsset).decimals());
        }

        // get vault short otoken if available
        if (vaultDetails.hasShort) {
            OtokenInterface short = OtokenInterface(_vault.shortOtokens[0]);
            (
                vaultDetails.shortCollateralAsset,
                vaultDetails.shortUnderlyingAsset,
                vaultDetails.shortStrikeAsset,
                vaultDetails.shortStrikePrice,
                vaultDetails.shortExpiryTimestamp,
                vaultDetails.isShortPut
            ) = _getOtokenDetails(address(short));
            vaultDetails.shortCollateralDecimals = uint256(
                ERC20Interface(vaultDetails.shortCollateralAsset).decimals()
            );
        }

        if (vaultDetails.hasCollateral) {
            vaultDetails.collateralDecimals = uint256(ERC20Interface(_vault.collateralAssets[0]).decimals());
        }

        return vaultDetails;
    }

    /**
     * @dev calculate the cash value obligation for an expired vault, where a positive number is an obligation
     *
     * Formula: net = (short cash value * short amount) - ( long cash value * long Amount )
     *
     * @return cash value obligation denominated in the strike asset
     */
    function _getExpiredSpreadCashValue(
        FPI.FixedPointInt memory _shortAmount,
        FPI.FixedPointInt memory _longAmount,
        FPI.FixedPointInt memory _shortCashValue,
        FPI.FixedPointInt memory _longCashValue
    ) internal pure returns (FPI.FixedPointInt memory) {
        return _shortCashValue.mul(_shortAmount).sub(_longCashValue.mul(_longAmount));
    }

    /**
     * @dev check if asset array contain a token address
     * @return True if the array is not empty
     */
    function _isNotEmpty(address[] memory _assets) internal pure returns (bool) {
        return _assets.length > 0 && _assets[0] != address(0);
    }

    /**
     * @dev ensure that:
     * a) at most 1 asset type used as collateral
     * b) at most 1 series of option used as the long option
     * c) at most 1 series of option used as the short option
     * d) asset array lengths match for long, short and collateral
     * e) long option and collateral asset is acceptable for margin with short asset
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     */
    function _checkIsValidVault(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails) internal pure {
        // ensure all the arrays in the vault are valid
        require(_vault.shortOtokens.length <= 1, "MarginCalculator: Too many short otokens in the vault");
        require(_vault.longOtokens.length <= 1, "MarginCalculator: Too many long otokens in the vault");
        require(_vault.collateralAssets.length <= 1, "MarginCalculator: Too many collateral assets in the vault");

        require(
            _vault.shortOtokens.length == _vault.shortAmounts.length,
            "MarginCalculator: Short asset and amount mismatch"
        );
        require(
            _vault.longOtokens.length == _vault.longAmounts.length,
            "MarginCalculator: Long asset and amount mismatch"
        );
        require(
            _vault.collateralAssets.length == _vault.collateralAmounts.length,
            "MarginCalculator: Collateral asset and amount mismatch"
        );

        // ensure the long asset is valid for the short asset
        require(
            _isMarginableLong(_vault, _vaultDetails),
            "MarginCalculator: long asset not marginable for short asset"
        );

        // ensure that the collateral asset is valid for the short asset
        require(
            _isMarginableCollateral(_vault, _vaultDetails),
            "MarginCalculator: collateral asset not marginable for short asset"
        );
    }

    /**
     * @dev if there is a short option and a long option in the vault, ensure that the long option is able to be used as collateral for the short option
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     * @return true if long is marginable or false if not
     */
    function _isMarginableLong(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        pure
        returns (bool)
    {
        if (_vaultDetails.vaultType == 1)
            require(!_vaultDetails.hasLong, "MarginCalculator: naked margin vault cannot have long otoken");

        // if vault is missing a long or a short, return True
        if (!_vaultDetails.hasLong || !_vaultDetails.hasShort) return true;

        return
            _vault.longOtokens[0] != _vault.shortOtokens[0] &&
            _vaultDetails.longUnderlyingAsset == _vaultDetails.shortUnderlyingAsset &&
            _vaultDetails.longStrikeAsset == _vaultDetails.shortStrikeAsset &&
            _vaultDetails.longCollateralAsset == _vaultDetails.shortCollateralAsset &&
            _vaultDetails.longExpiryTimestamp == _vaultDetails.shortExpiryTimestamp &&
            _vaultDetails.isLongPut == _vaultDetails.isShortPut;
    }

    /**
     * @dev if there is short option and collateral asset in the vault, ensure that the collateral asset is valid for the short option
     * @param _vault the vault to check
     * @param _vaultDetails vault details struct
     * @return true if marginable or false
     */
    function _isMarginableCollateral(MarginVault.Vault memory _vault, VaultDetails memory _vaultDetails)
        internal
        pure
        returns (bool)
    {
        bool isMarginable = true;

        if (!_vaultDetails.hasCollateral) return isMarginable;

        if (_vaultDetails.hasShort) {
            isMarginable = _vaultDetails.shortCollateralAsset == _vault.collateralAssets[0];
        } else if (_vaultDetails.hasLong) {
            isMarginable = _vaultDetails.longCollateralAsset == _vault.collateralAssets[0];
        }

        return isMarginable;
    }

    /**
     * @notice get a product hash
     * @param _underlying option underlying asset
     * @param _strike option strike asset
     * @param _collateral option collateral asset
     * @param _isPut option type
     * @return product hash
     */
    function _getProductHash(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));
    }

    /**
     * @notice get option cash value
     * @dev this assume that the underlying price is denominated in strike asset
     * cash value = max(underlying price - strike price, 0)
     * @param _strikePrice option strike price
     * @param _underlyingPrice option underlying price
     * @param _isPut option type, true for put and false for call option
     */
    function _getCashValue(
        FPI.FixedPointInt memory _strikePrice,
        FPI.FixedPointInt memory _underlyingPrice,
        bool _isPut
    ) internal view returns (FPI.FixedPointInt memory) {
        if (_isPut) return _strikePrice.isGreaterThan(_underlyingPrice) ? _strikePrice.sub(_underlyingPrice) : ZERO;

        return _underlyingPrice.isGreaterThan(_strikePrice) ? _underlyingPrice.sub(_strikePrice) : ZERO;
    }

    /**
     * @dev get otoken detail, from both otoken versions
     */
    function _getOtokenDetails(address _otoken)
        internal
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        )
    {
        OtokenInterface otoken = OtokenInterface(_otoken);
        try otoken.getOtokenDetails() returns (
            address collateral,
            address underlying,
            address strike,
            uint256 strikePrice,
            uint256 expiry,
            bool isPut
        ) {
            return (collateral, underlying, strike, strikePrice, expiry, isPut);
        } catch {
            // v1 otoken
            return (
                otoken.collateralAsset(),
                otoken.underlyingAsset(),
                otoken.strikeAsset(),
                otoken.strikePrice(),
                otoken.expiryTimestamp(),
                otoken.isPut()
            );
        }
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20Interface {
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

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OtokenInterface {
    function addressBook() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

import "../packages/oz/SignedSafeMath.sol";
import "../libs/SignedConverter.sol";
import "../packages/oz/SafeMath.sol";

/**
 * @title FixedPointInt256
 * @author Opyn Team
 * @notice FixedPoint library
 */
library FixedPointInt256 {
    using SignedSafeMath for int256;
    using SignedConverter for int256;
    using SafeMath for uint256;
    using SignedConverter for uint256;

    int256 private constant SCALING_FACTOR = 1e27;
    uint256 private constant BASE_DECIMALS = 27;

    struct FixedPointInt {
        int256 value;
    }

    /**
     * @notice constructs an `FixedPointInt` from an unscaled int, e.g., `b=5` gets stored internally as `5**27`.
     * @param a int to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledInt(int256 a) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.mul(SCALING_FACTOR));
    }

    /**
     * @notice constructs an FixedPointInt from an scaled uint with {_decimals} decimals
     * Examples:
     * (1)  USDC    decimals = 6
     *      Input:  5 * 1e6 USDC  =>    Output: 5 * 1e27 (FixedPoint 5.0 USDC)
     * (2)  cUSDC   decimals = 8
     *      Input:  5 * 1e6 cUSDC =>    Output: 5 * 1e25 (FixedPoint 0.05 cUSDC)
     * @param _a uint256 to convert into a FixedPoint.
     * @param _decimals  original decimals _a has
     * @return the converted FixedPoint, with 27 decimals.
     */
    function fromScaledUint(uint256 _a, uint256 _decimals) internal pure returns (FixedPointInt memory) {
        FixedPointInt memory fixedPoint;

        if (_decimals == BASE_DECIMALS) {
            fixedPoint = FixedPointInt(_a.uintToInt());
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals.sub(BASE_DECIMALS);
            fixedPoint = FixedPointInt((_a.div(10**exp)).uintToInt());
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            fixedPoint = FixedPointInt((_a.mul(10**exp)).uintToInt());
        }

        return fixedPoint;
    }

    /**
     * @notice convert a FixedPointInt number to an uint256 with a specific number of decimals
     * @param _a FixedPointInt to convert
     * @param _decimals number of decimals that the uint256 should be scaled to
     * @param _roundDown True to round down the result, False to round up
     * @return the converted uint256
     */
    function toScaledUint(
        FixedPointInt memory _a,
        uint256 _decimals,
        bool _roundDown
    ) internal pure returns (uint256) {
        uint256 scaledUint;

        if (_decimals == BASE_DECIMALS) {
            scaledUint = _a.value.intToUint();
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals - BASE_DECIMALS;
            scaledUint = (_a.value).intToUint().mul(10**exp);
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            uint256 tailing;
            if (!_roundDown) {
                uint256 remainer = (_a.value).intToUint().mod(10**exp);
                if (remainer > 0) tailing = 1;
            }
            scaledUint = (_a.value).intToUint().div(10**exp).add(tailing);
        }

        return scaledUint;
    }

    /**
     * @notice add two signed integers, a + b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return sum of the two signed integers
     */
    function add(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.add(b.value));
    }

    /**
     * @notice subtract two signed integers, a-b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return difference of two signed integers
     */
    function sub(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.sub(b.value));
    }

    /**
     * @notice multiply two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return mul of two signed integers
     */
    function mul(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(b.value)) / SCALING_FACTOR);
    }

    /**
     * @notice divide two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return div of two signed integers
     */
    function div(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(SCALING_FACTOR)) / b.value);
    }

    /**
     * @notice minimum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return min of two signed integers
     */
    function min(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value < b.value ? a : b;
    }

    /**
     * @notice maximum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return max of two signed integers
     */
    function max(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value > b.value ? a : b;
    }

    /**
     * @notice is a is equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if equal, False if not
     */
    function isEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value == b.value;
    }

    /**
     * @notice is a greater than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a > b, False if not
     */
    function isGreaterThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value > b.value;
    }

    /**
     * @notice is a greater than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a >= b, False if not
     */
    function isGreaterThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value >= b.value;
    }

    /**
     * @notice is a is less than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a < b, False if not
     */
    function isLessThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value < b.value;
    }

    /**
     * @notice is a less than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a <= b, False if not
     */
    function isLessThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value <= b.value;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * MarginVault Error Codes
 * V1: invalid short otoken amount
 * V2: invalid short otoken index
 * V3: short otoken address mismatch
 * V4: invalid long otoken amount
 * V5: invalid long otoken index
 * V6: long otoken address mismatch
 * V7: invalid collateral amount
 * V8: invalid collateral token index
 * V9: collateral token address mismatch
 */

/**
 * @title MarginVault
 * @author Opyn Team
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    using SafeMath for uint256;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }

    /**
     * @dev increase the short oToken balance in a vault when a new oToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _shortOtoken address of the _shortOtoken being minted from the user's vault
     * @param _amount number of _shortOtoken being minted from the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function addShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V1");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.shortOtokens.length) && (_index == _vault.shortAmounts.length)) {
            _vault.shortOtokens.push(_shortOtoken);
            _vault.shortAmounts.push(_amount);
        } else {
            require((_index < _vault.shortOtokens.length) && (_index < _vault.shortAmounts.length), "V2");
            address existingShort = _vault.shortOtokens[_index];
            require((existingShort == _shortOtoken) || (existingShort == address(0)), "V3");

            _vault.shortAmounts[_index] = _vault.shortAmounts[_index].add(_amount);
            _vault.shortOtokens[_index] = _shortOtoken;
        }
    }

    /**
     * @dev decrease the short oToken balance in a vault when an oToken is burned
     * @param _vault vault to decrease short position in
     * @param _shortOtoken address of the _shortOtoken being reduced in the user's vault
     * @param _amount number of _shortOtoken being reduced in the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function removeShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed short oToken exists in the vault at the specified index
        require(_index < _vault.shortOtokens.length, "V2");
        require(_vault.shortOtokens[_index] == _shortOtoken, "V3");

        uint256 newShortAmount = _vault.shortAmounts[_index].sub(_amount);

        if (newShortAmount == 0) {
            delete _vault.shortOtokens[_index];
        }
        _vault.shortAmounts[_index] = newShortAmount;
    }

    /**
     * @dev increase the long oToken balance in a vault when an oToken is deposited
     * @param _vault vault to add a long position to
     * @param _longOtoken address of the _longOtoken being added to the user's vault
     * @param _amount number of _longOtoken the protocol is adding to the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function addLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V4");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.longOtokens.length) && (_index == _vault.longAmounts.length)) {
            _vault.longOtokens.push(_longOtoken);
            _vault.longAmounts.push(_amount);
        } else {
            require((_index < _vault.longOtokens.length) && (_index < _vault.longAmounts.length), "V5");
            address existingLong = _vault.longOtokens[_index];
            require((existingLong == _longOtoken) || (existingLong == address(0)), "V6");

            _vault.longAmounts[_index] = _vault.longAmounts[_index].add(_amount);
            _vault.longOtokens[_index] = _longOtoken;
        }
    }

    /**
     * @dev decrease the long oToken balance in a vault when an oToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longOtoken address of the _longOtoken being removed from the user's vault
     * @param _amount number of _longOtoken the protocol is removing from the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function removeLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed long oToken exists in the vault at the specified index
        require(_index < _vault.longOtokens.length, "V5");
        require(_vault.longOtokens[_index] == _longOtoken, "V6");

        uint256 newLongAmount = _vault.longAmounts[_index].sub(_amount);

        if (newLongAmount == 0) {
            delete _vault.longOtokens[_index];
        }
        _vault.longAmounts[_index] = newLongAmount;
    }

    /**
     * @dev increase the collateral balance in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAsset address of the _collateralAsset being added to the user's vault
     * @param _amount number of _collateralAsset being added to the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function addCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V7");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.collateralAssets.length) && (_index == _vault.collateralAmounts.length)) {
            _vault.collateralAssets.push(_collateralAsset);
            _vault.collateralAmounts.push(_amount);
        } else {
            require((_index < _vault.collateralAssets.length) && (_index < _vault.collateralAmounts.length), "V8");
            address existingCollateral = _vault.collateralAssets[_index];
            require((existingCollateral == _collateralAsset) || (existingCollateral == address(0)), "V9");

            _vault.collateralAmounts[_index] = _vault.collateralAmounts[_index].add(_amount);
            _vault.collateralAssets[_index] = _collateralAsset;
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _collateralAsset address of the _collateralAsset being removed from the user's vault
     * @param _amount number of _collateralAsset being removed from the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function removeCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed collateral exists in the vault at the specified index
        require(_index < _vault.collateralAssets.length, "V8");
        require(_vault.collateralAssets[_index] == _collateralAsset, "V9");

        uint256 newCollateralAmount = _vault.collateralAmounts[_index].sub(_amount);

        if (newCollateralAmount == 0) {
            delete _vault.collateralAssets[_index];
        }
        _vault.collateralAmounts[_index] = newCollateralAmount;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.6.10;

/**
 * @title SignedConverter
 * @author Opyn Team
 * @notice A library to convert an unsigned integer to signed integer or signed integer to unsigned integer.
 */
library SignedConverter {
    /**
     * @notice convert an unsigned integer to a signed integer
     * @param a uint to convert into a signed integer
     * @return converted signed integer
     */
    function uintToInt(uint256 a) internal pure returns (int256) {
        require(a < 2**255, "FixedPointInt256: out of int range");

        return int256(a);
    }

    /**
     * @notice convert a signed integer to an unsigned integer
     * @param a int to convert into an unsigned integer
     * @return converted unsigned integer
     */
    function intToUint(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(-a);
        } else {
            return uint256(a);
        }
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

pragma solidity 0.6.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

pragma solidity 0.6.10;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 private constant _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}