/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

// A mock oracle used for testing.
contract MockOracle {
    // Represents an available price. Have to keep a separate bool to allow for price=0.
    struct Price {
        bool isAvailable;
        int256 price;
        // Time the verified price became available.
        uint256 verifiedTime;
    }

    // The two structs below are used in an array and mapping to keep track of prices that have been requested but are
    // not yet available.
    struct QueryIndex {
        bool isValid;
        uint256 index;
    }

    // Represents a (identifier, time) point that has been queried.
    struct QueryPoint {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
    }

    // Conceptually we want a (time, identifier) -> price map.
    mapping(bytes32 => mapping(uint256 => mapping(bytes => Price))) private verifiedPrices;

    // The mapping and array allow retrieving all the elements in a mapping and finding/deleting elements.
    // Can we generalize this data structure?
    mapping(bytes32 => mapping(uint256 => mapping(bytes => QueryIndex))) private queryIndices;
    QueryPoint[] private requestedPrices;

    event PriceRequestAdded(address indexed requester, bytes32 indexed identifier, uint256 time, bytes ancillaryData);
    event PushedPrice(
        address indexed pusher,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        int256 price
    );

    // Enqueues a request (if a request isn't already present) for the given (identifier, time) pair.
    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public {
        Price storage lookup = verifiedPrices[identifier][time][ancillaryData];
        if (!lookup.isAvailable && !queryIndices[identifier][time][ancillaryData].isValid) {
            // New query, enqueue it for review.
            queryIndices[identifier][time][ancillaryData] = QueryIndex(true, requestedPrices.length);
            requestedPrices.push(QueryPoint(identifier, time, ancillaryData));
            emit PriceRequestAdded(msg.sender, identifier, time, ancillaryData);
        }
    }

    // Pushes the verified price for a requested query.
    function pushPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        int256 price
    ) public {
        verifiedPrices[identifier][time][ancillaryData] = Price(true, price, now);

        QueryIndex storage queryIndex = queryIndices[identifier][time][ancillaryData];
        require(queryIndex.isValid, "Can't push prices that haven't been requested");
        // Delete from the array. Instead of shifting the queries over, replace the contents of `indexToReplace` with
        // the contents of the last index (unless it is the last index).
        uint256 indexToReplace = queryIndex.index;
        delete queryIndices[identifier][time][ancillaryData];
        uint256 lastIndex = requestedPrices.length - 1;
        if (lastIndex != indexToReplace) {
            QueryPoint storage queryToCopy = requestedPrices[lastIndex];
            queryIndices[queryToCopy.identifier][queryToCopy.time][queryToCopy.ancillaryData].index = indexToReplace;
            requestedPrices[indexToReplace] = queryToCopy;
        }

        emit PushedPrice(msg.sender, identifier, time, ancillaryData, price);
    }

    // Checks whether a price has been resolved.
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view returns (bool) {
        Price storage lookup = verifiedPrices[identifier][time][ancillaryData];
        return lookup.isAvailable;
    }

    // Gets a price that has already been resolved.
    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view returns (int256) {
        Price storage lookup = verifiedPrices[identifier][time][ancillaryData];
        require(lookup.isAvailable);
        return lookup.price;
    }

    // Gets the queries that still need verified prices.
    function getPendingQueries() external view returns (QueryPoint[] memory) {
        return requestedPrices;
    }
}