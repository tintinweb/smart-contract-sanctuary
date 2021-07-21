// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

import "./OwnableUpgradeable.sol";
import "./AggregatorV3Interface.sol";
import "./IPriceOracle.sol";
import "./Proxiable.sol";

/// @title PriceOracle
/// @notice Uses a collection of sub price oracles to fetch settlement price and current price data for the SeriesController
/// @notice The price data is for a given underlying-price token pair and Series expiration date
/// @dev An important assumption of the PriceOracle is that settlement dates are aligned to Friday 8am UTC.
/// We assume this because we do not want to fragment liquidity and complicate the UX by allowing for arbitrary settlement dates
/// so we enforce this when adding new oracle token pairs by aligning the initial earliest settlement date to Friday 8am UTC, and
/// then aligning all subsequent settlement prices for that oracle token pair to an exact 7 day offset
/// Series whose expirations are Friday 8am UTC as well
/// @dev All prices are normalized to 8 decimal places
contract PriceOracle is IPriceOracle, OwnableUpgradeable, Proxiable {
    /// @dev Stores the price for a given <underlyingToken>-<priceToken>-<settlementDate> triplet
    /// @dev All prices are normalized to 8 decimals
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        internal settlementPrices;

    /// @dev Stores the oracle address to use when looking for the price of a given token
    /// @dev oracles are keyed by the pair of underlyingToken-priceToken, so for a BTCUSD oracle
    /// returning a price of $14_000, the pair would be the addresses corresponding to WBTC and USDC
    mapping(address => mapping(address => address)) internal oracles;

    event SettlementPriceSet(
        address underlyingToken,
        address priceToken,
        uint256 settlementDate,
        uint256 price
    );

    event OracleSet(
        address underlyingToken,
        address priceToken,
        address oracle,
        uint256 earliestSettlementDate
    );

    /// @notice Setup the owner and date time and range for this PriceOracle
    function initialize() external {
        __Ownable_init();
    }

    /// @notice Stores the current price from the oracle specified by the pair underlyingToken-priceToken
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    /// @dev More than a single settlement price may be set, because this function will set all prices for each
    /// prior Friday 8am UTC date until it reaches a settlement date that previously had a price set, or it runs
    /// out of gas
    /// @dev WARNING: setSettlementDate must be called frequently enough that the gap in settlement date
    /// prices does not grow so great that it takes more than the gasLimit's amount of gas to set them all
    /// that haven't had a price set on them prior to the current block timestamp
    function setSettlementPrice(address underlyingToken, address priceToken)
        external
        override
    {
        require(
            oracles[underlyingToken][priceToken] != address(0x0),
            "no oracle address for this token pair"
        );

        // fetch the current spot price for this pair's oracle, and set all previous Friday 8am UTC
        // settlement dates that have not yet had their price set to that spot price
        uint256 spotPrice = getCurrentPrice(underlyingToken, priceToken);
        uint256 priorFriday8am = getFriday8amAlignedDate(block.timestamp);
        uint256 currentSettlementPrice =
            settlementPrices[underlyingToken][priceToken][priorFriday8am];

        // keep going back 1 week until we reach a settlement date that has already been set by a previous
        // call to PriceOracle.setSettlementPrice
        while (currentSettlementPrice == 0) {
            settlementPrices[underlyingToken][priceToken][
                priorFriday8am
            ] = spotPrice;

            emit SettlementPriceSet(
                underlyingToken,
                priceToken,
                priorFriday8am,
                spotPrice
            );

            // go back exactly 1 week's worth of time to the previous Friday 8am UTC date
            priorFriday8am -= 1 weeks;

            // update the currentSettlementPrice so the while loop will eventually break
            currentSettlementPrice = settlementPrices[underlyingToken][
                priceToken
            ][priorFriday8am];
        }
    }

    /// @notice get the settlement price with the given underlyingToken and priceToken,
    /// at the given expirationDate, and whether the price exists
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    /// @param settlementDate Should be equal to the expirationDate of the series calling this function
    /// @return true if the settlement price has been set (i.e. is nonzero), false otherwise
    /// @return the settlement price
    function getSettlementPrice(
        address underlyingToken,
        address priceToken,
        uint256 settlementDate
    ) external view override returns (bool, uint256) {
        require(
            oracles[underlyingToken][priceToken] != address(0x0),
            "no oracle address for this token pair"
        );

        uint256 settlementPrice =
            settlementPrices[underlyingToken][priceToken][settlementDate];

        return (settlementPrice != 0, settlementPrice);
    }

    /// @notice Use an oracle keyed by the underlyingToken-priceToken pair to fetch the current price
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    function getCurrentPrice(address underlyingToken, address priceToken)
        public
        view
        override
        returns (uint256)
    {
        (, int256 latestAnswer, , , ) =
            AggregatorV3Interface(oracles[underlyingToken][priceToken])
                .latestRoundData();
        require(latestAnswer >= 0, "invalid value received from price oracle");

        return uint256(latestAnswer);
    }

    /// @notice Sets the price oracle to use for the given underlyingToken and priceToken pair
    /// @dev earliestSettlementDate should be the next Series settlementDate the PriceOracle
    /// sets in PriceOracle.setSettlementSet. To ensure that, the previous Friday 8am UTC
    /// to earliestSettlementDate will be set with a nonzero value, so that PriceOracle.setSettlementPrice
    /// will set all subsequent dates (including earliestSettlementDate) when it is called
    /// @param underlyingToken Should be equal to the Series' underlyingToken field
    /// @param priceToken Should be equal to the Series' priceToken field
    /// @param oracle The address of the price oracle contract
    function addTokenPair(
        address underlyingToken,
        address priceToken,
        address oracle
    ) external onlyOwner {
        require(
            oracles[underlyingToken][priceToken] == address(0x0),
            "PriceOracle: cannot set address for an existing oracle"
        );

        // set the pair's oracle on the PriceOracle
        oracles[underlyingToken][priceToken] = oracle;

        uint256 currentPrice = getCurrentPrice(underlyingToken, priceToken);
        // We need to initially set the price on some offset-aligned date prior to the current date, so that
        // in the loop in PriceOracle.setSettlementDate it will eventually stop looping when it finds a
        // non-zero price. If we do not add set this price, then the first call to PriceOracle.setSettlementDate the first
        // is guaranteed to run out of gas because there will never be a non-zero price value. We choose the most recent
        // aligned date because it will result in the least gas used by PriceOracle.setSettlementDate
        uint256 earliestSettlementDate =
            getFriday8amAlignedDate(block.timestamp);
        settlementPrices[underlyingToken][priceToken][
            earliestSettlementDate
        ] = currentPrice;

        emit OracleSet(
            underlyingToken,
            priceToken,
            oracle,
            earliestSettlementDate
        );
    }

    /// @notice update the PriceOracle's logic contract
    /// @param newPriceOracleImpl the address of the new price oracle implementation contract
    function updateImplementation(address newPriceOracleImpl)
        external
        onlyOwner
    {
        require(
            newPriceOracleImpl != address(0x0),
            "PriceOracle: Invalid newPriceOracleImpl"
        );

        // Call the proxiable update
        _updateCodeAddress(newPriceOracleImpl);
    }

    /// @notice Returns the given timestamp date, but aligned to the prior (Friday) 8am UTC date
    /// unless the timestamp is exactly (Friday) 8am UTC, in which case it will return the same
    /// value as the timestamp
    /// @param _timestamp a block time (seconds past epoch)
    /// @return the block time of the prior (or current) (Friday) 8am UTC date
    function getFriday8amAlignedDate(uint256 _timestamp)
        public
        pure
        override
        returns (uint256)
    {
        uint256 numOffsetsSinceEpochStart = _timestamp / 1 weeks;

        // this will get us the timestamp of the Thursday midnight date prior to _timestamp
        // (we rely on Solidity rounding in the line above)
        uint256 timestampRoundedDown = numOffsetsSinceEpochStart * 1 weeks;

        uint256 fridayEightHoursAligned =
            timestampRoundedDown + (1 days + 8 hours);
        if (fridayEightHoursAligned > _timestamp) {
            return fridayEightHoursAligned - 1 weeks;
        } else {
            return fridayEightHoursAligned;
        }
    }
}