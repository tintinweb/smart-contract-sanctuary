/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Admin.sol";
import "./CarefulMath.sol";
import "./Erc20Interface.sol";

import "./ChainlinkOperatorInterface.sol";
import "./AggregatorV3Interface.sol";

/**
 * @title ChainlinkOperator
 * @author Hifi
 * @notice Manages USD-quoted Chainlink price feeds.
 */
contract ChainlinkOperator is
    CarefulMath, /* no dependency */
    ChainlinkOperatorInterface, /* no dependency */
    Admin /* two dependencies */
{
    /* solhint-disable-next-line no-empty-blocks */
    constructor() Admin() {}

    /**
     * CONSTANT FUNCTIONS
     */

    /**
     * @notice Gets the official price for a symbol and adjusts it have 18 decimals instead of the
     * format used by Chainlink, which has 8 decimals.
     *
     * @dev Requirements:
     *
     * - The upscaled price cannot overflow.
     *
     * @param symbol The Erc20 symbol of the token for which to query the price.
     * @return The upscaled price as a mantissa.
     */
    function getAdjustedPrice(string memory symbol) external view override returns (uint256) {
        uint256 price = getPrice(symbol);
        (MathError mathErr, uint256 adjustedPrice) = mulUInt(price, pricePrecisionScalar);
        require(mathErr == MathError.NO_ERROR, "ERR_GET_ADJUSTED_PRICE_MATH_ERROR");
        return adjustedPrice;
    }

    /**
     * @notice Gets the official feed for a symbol.
     * @param symbol The symbol to return the feed for.
     * @return (address asset, address id, bool isSet).
     */
    function getFeed(string memory symbol)
        external
        view
        override
        returns (
            Erc20Interface,
            AggregatorV3Interface,
            bool
        )
    {
        return (feeds[symbol].asset, feeds[symbol].id, feeds[symbol].isSet);
    }

    /**
     * @notice Gets the official price for a symbol in the default format used by Chainlink, which
     * has 8 decimals.
     *
     * @dev Requirements:
     *
     * - The feed must have been previously set.
     * - The price returned by the oracle cannot be zero.
     *
     * @param symbol The symbol to fetch the price for.
     * @return Price denominated in USD, with 8 decimals.
     */
    function getPrice(string memory symbol) public view override returns (uint256) {
        require(feeds[symbol].isSet, "ERR_FEED_NOT_SET");
        (, int256 intPrice, , , ) = AggregatorV3Interface(feeds[symbol].id).latestRoundData();
        uint256 price = uint256(intPrice);
        require(price > 0, "ERR_PRICE_ZERO");
        return price;
    }

    /**
     * NON-CONSTANT FUNCTIONS
     */

    /**
     * @notice Deletes a previously set Chainlink price feed.
     *
     * @dev Emits a {DeleteFeed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The feed must have been previously set.
     *
     * @param symbol The Erc20 symbol of the asset to delete the feed for.
     * @return bool true = success, otherwise it reverts.
     */
    function deleteFeed(string memory symbol) external override onlyAdmin returns (bool) {
        /* Checks */
        require(feeds[symbol].isSet, "ERR_FEED_NOT_SET");

        /* Effects: delete the feed from storage. */
        AggregatorV3Interface feed = feeds[symbol].id;
        Erc20Interface asset = feeds[symbol].asset;
        delete feeds[symbol];

        emit DeleteFeed(asset, feed);
        return true;
    }

    /**
     * @notice Sets a Chainlink price feed. It is not an error to set a feed twice.
     *
     * @dev Emits a {SetFeed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The number of decimals of the feed must be 8.
     *
     * @param asset The address of the Erc20 contract for which to get the price.
     * @param feed The address of the Chainlink price feed contract.
     * @return bool true = success, otherwise it reverts.
     */
    function setFeed(Erc20Interface asset, AggregatorV3Interface feed) external override onlyAdmin returns (bool) {
        string memory symbol = asset.symbol();

        /* Checks: price precision. */
        uint8 decimals = feed.decimals();
        require(decimals == pricePrecision, "ERR_FEED_INCORRECT_DECIMALS");

        /* Effects: put the feed into storage. */
        feeds[symbol] = Feed({ asset: asset, id: feed, isSet: true });

        emit SetFeed(asset, feed);
        return true;
    }
}