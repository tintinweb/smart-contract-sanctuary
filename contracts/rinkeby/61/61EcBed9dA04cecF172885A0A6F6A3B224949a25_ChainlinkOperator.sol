// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./IErc20.sol";

import "./IChainlinkOperator.sol";

/// @title ChainlinkOperator
/// @author Hifi
contract ChainlinkOperator is
    IChainlinkOperator, // no dependency
    Ownable // one dependency
{
    /// PUBLIC STORAGE ///

    /// @dev Mapping between Erc20 symbols and Feed structs.
    mapping(string => Feed) internal feeds;

    /// @inheritdoc IChainlinkOperator
    uint256 public constant override pricePrecision = 8;

    /// @inheritdoc IChainlinkOperator
    uint256 public constant override pricePrecisionScalar = 1.0e10;

    constructor() Ownable() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc IChainlinkOperator
    function getFeed(string memory symbol)
        external
        view
        override
        returns (
            IErc20,
            IAggregatorV3,
            bool
        )
    {
        return (feeds[symbol].asset, feeds[symbol].id, feeds[symbol].isSet);
    }

    /// @inheritdoc IChainlinkOperator
    function getNormalizedPrice(string memory symbol) external view override returns (uint256) {
        uint256 price = getPrice(symbol);
        uint256 normalizedPrice = price * pricePrecisionScalar;
        return normalizedPrice;
    }

    /// @inheritdoc IChainlinkOperator
    function getPrice(string memory symbol) public view override returns (uint256) {
        require(feeds[symbol].isSet, "FEED_NOT_SET");
        (, int256 intPrice, , , ) = IAggregatorV3(feeds[symbol].id).latestRoundData();
        uint256 price = uint256(intPrice);
        require(price > 0, "PRICE_ZERO");
        return price;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IChainlinkOperator
    function deleteFeed(string memory symbol) external override onlyOwner {
        // Checks
        require(feeds[symbol].isSet, "FEED_NOT_SET");

        // Effects: delete the feed from storage.
        IAggregatorV3 feed = feeds[symbol].id;
        IErc20 asset = feeds[symbol].asset;
        delete feeds[symbol];

        emit DeleteFeed(asset, feed);
    }

    /// @inheritdoc IChainlinkOperator
    function setFeed(IErc20 asset, IAggregatorV3 feed) external override onlyOwner {
        string memory symbol = asset.symbol();

        // Checks: price precision.
        uint8 decimals = feed.decimals();
        require(decimals == pricePrecision, "FEED_DECIMALS_MISMATCH");

        // Effects: put the feed into storage.
        feeds[symbol] = Feed({ asset: asset, id: feed, isSet: true });

        emit SetFeed(asset, feed);
    }
}