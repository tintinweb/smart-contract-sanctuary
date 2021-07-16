// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;

import "./OpenOracleData.sol";

/**
 * @title The Open Oracle Price Data Contract
 * @notice Values stored in this contract should represent a USD price with 6 decimals precision
 * @author Compound Labs, Inc.
 */
contract OpenOraclePriceData is OpenOracleData {
    ///@notice The event emitted when a source writes to its storage
    event Write(address indexed source, string key, uint64 timestamp, uint64 value);
    ///@notice The event emitted when the timestamp on a price is invalid and it is not written to storage
    event NotWritten(uint64 priorTimestamp, uint256 messageTimestamp, uint256 blockTimestamp);

    ///@notice The fundamental unit of storage for a reporter source
    struct Datum {
        uint64 timestamp;
        uint64 value;
    }

    /**
     * @dev The most recent authenticated data from all sources.
     *  This is private because dynamic mapping keys preclude auto-generated getters.
     */
    mapping(address => mapping(string => Datum)) private data;

    /**
     * @notice Write a bunch of signed datum to the authenticated storage mapping
     * @param message The payload containing the timestamp, and (key, value) pairs
     * @param signature The cryptographic signature of the message payload, authorizing the source to write
     * @return The keys that were written
     */
    function put(bytes calldata message, bytes calldata signature) external returns (string memory) {
        (address source, uint64 timestamp, string memory key, uint64 value) = decodeMessage(message, signature);
        return putInternal(source, timestamp, key, value);
    }

    function putInternal(address source, uint64 timestamp, string memory key, uint64 value) internal returns (string memory) {
        // Only update if newer than stored, according to source
        Datum storage prior = data[source][key];
        if (timestamp > prior.timestamp && timestamp < block.timestamp + 60 minutes && source != address(0)) {
            data[source][key] = Datum(timestamp, value);
            emit Write(source, key, timestamp, value);
        } else {
            emit NotWritten(prior.timestamp, timestamp, block.timestamp);
        }
        return key;
    }

    function decodeMessage(bytes calldata message, bytes calldata signature) internal returns (address, uint64, string memory, uint64) {
        // Recover the source address
        address source = source(message, signature);

        // Decode the message and check the kind
        (string memory kind, uint64 timestamp, string memory key, uint64 value) = abi.decode(message, (string, uint64, string, uint64));
        require(keccak256(abi.encodePacked(kind)) == keccak256(abi.encodePacked("prices")), "Kind of data must be 'prices'");
        return (source, timestamp, key, value);
    }

    /**
     * @notice Read a single key from an authenticated source
     * @param source The verifiable author of the data
     * @param key The selector for the value to return
     * @return The claimed Unix timestamp for the data and the price value (defaults to (0, 0))
     */
    function get(address source, string calldata key) external view returns (uint64, uint64) {
        Datum storage datum = data[source][key];
        return (datum.timestamp, datum.value);
    }

    /**
     * @notice Read only the value for a single key from an authenticated source
     * @param source The verifiable author of the data
     * @param key The selector for the value to return
     * @return The price value (defaults to 0)
     */
    function getPrice(address source, string calldata key) external view returns (uint64) {
        return data[source][key].value;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title The Open Oracle Data Base Contract
 * @author Compound Labs, Inc.
 */
contract OpenOracleData {
    /**
     * @notice The event emitted when a source writes to its storage
     */
    //event Write(address indexed source, <Key> indexed key, string kind, uint64 timestamp, <Value> value);

    /**
     * @notice Write a bunch of signed datum to the authenticated storage mapping
     * @param message The payload containing the timestamp, and (key, value) pairs
     * @param signature The cryptographic signature of the message payload, authorizing the source to write
     * @return The keys that were written
     */
    //function put(bytes calldata message, bytes calldata signature) external returns (<Key> memory);

    /**
     * @notice Read a single key with a pre-defined type signature from an authenticated source
     * @param source The verifiable author of the data
     * @param key The selector for the value to return
     * @return The claimed Unix timestamp for the data and the encoded value (defaults to (0, 0x))
     */
    //function get(address source, <Key> key) external view returns (uint, <Value>);

    /**
     * @notice Recovers the source address which signed a message
     * @dev Comparing to a claimed address would add nothing,
     *  as the caller could simply perform the recover and claim that address.
     * @param message The data that was presumably signed
     * @param signature The fingerprint of the data + private key
     * @return The source address which signed the message, presumably
     */
    function source(bytes memory message, bytes memory signature) public view returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ecrecover(hash, v, r, s);
    }
}