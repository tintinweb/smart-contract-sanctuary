pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../../common/implementation/Testable.sol";
import "../interfaces/OracleInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "../interfaces/FinderInterface.sol";
import "../implementation/Constants.sol";


// A mock oracle used for testing.
contract MockOracle is OracleInterface, Testable {
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
    }

    // Reference to the Finder.
    FinderInterface private finder;

    // Conceptually we want a (time, identifier) -> price map.
    mapping(bytes32 => mapping(uint256 => Price)) private verifiedPrices;

    // The mapping and array allow retrieving all the elements in a mapping and finding/deleting elements.
    // Can we generalize this data structure?
    mapping(bytes32 => mapping(uint256 => QueryIndex)) private queryIndices;
    QueryPoint[] private requestedPrices;

    constructor(address _finderAddress, address _timerAddress) public Testable(_timerAddress) {
        finder = FinderInterface(_finderAddress);
    }

    // Enqueues a request (if a request isn't already present) for the given (identifier, time) pair.

    function requestPrice(bytes32 identifier, uint256 time) external override {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time];
        if (!lookup.isAvailable && !queryIndices[identifier][time].isValid) {
            // New query, enqueue it for review.
            queryIndices[identifier][time] = QueryIndex(true, requestedPrices.length);
            requestedPrices.push(QueryPoint(identifier, time));
        }
    }

    // Pushes the verified price for a requested query.
    function pushPrice(
        bytes32 identifier,
        uint256 time,
        int256 price
    ) external {
        verifiedPrices[identifier][time] = Price(true, price, getCurrentTime());

        QueryIndex storage queryIndex = queryIndices[identifier][time];
        require(queryIndex.isValid, "Can't push prices that haven't been requested");
        // Delete from the array. Instead of shifting the queries over, replace the contents of `indexToReplace` with
        // the contents of the last index (unless it is the last index).
        uint256 indexToReplace = queryIndex.index;
        delete queryIndices[identifier][time];
        uint256 lastIndex = requestedPrices.length - 1;
        if (lastIndex != indexToReplace) {
            QueryPoint storage queryToCopy = requestedPrices[lastIndex];
            queryIndices[queryToCopy.identifier][queryToCopy.time].index = indexToReplace;
            requestedPrices[indexToReplace] = queryToCopy;
        }
    }

    // Checks whether a price has been resolved.
    function hasPrice(bytes32 identifier, uint256 time) external override view returns (bool) {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time];
        return lookup.isAvailable;
    }

    // Gets a price that has already been resolved.
    function getPrice(bytes32 identifier, uint256 time) external override view returns (int256) {
        require(_getIdentifierWhitelist().isIdentifierSupported(identifier));
        Price storage lookup = verifiedPrices[identifier][time];
        require(lookup.isAvailable);
        return lookup.price;
    }

    // Gets the queries that still need verified prices.
    function getPendingQueries() external view returns (QueryPoint[] memory) {
        return requestedPrices;
    }

    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface supportedIdentifiers) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }
}
