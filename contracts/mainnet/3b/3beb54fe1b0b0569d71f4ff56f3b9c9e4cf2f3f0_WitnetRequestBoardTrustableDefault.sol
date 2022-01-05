/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

// File: contracts\interfaces\IWitnetRequestBoardEvents.sol
/// @title Witnet Request Board emitting events interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardEvents {
    /// Emitted when a Witnet Data Request is posted to the WRB.
    event PostedRequest(uint256 queryId, address from);

    /// Emitted when a Witnet-solved result is reported to the WRB.
    event PostedResult(uint256 queryId, address from);

    /// Emitted when all data related to given query is deleted from the WRB.
    event DeletedQuery(uint256 queryId, address from);
}
// File: contracts\interfaces\IWitnetRequestBoardReporter.sol
/// @title The Witnet Request Board Reporter interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardReporter {
    /// Reports the Witnet-provided result to a previously posted request. 
    /// @dev Will assume `block.timestamp` as the timestamp at which the request was solved.
    /// @dev Fails if:
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique identifier of the data request.
    /// @param _drTxHash The hash of the solving tally transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(uint256 _queryId, bytes32 _drTxHash, bytes calldata _result) external;

    /// Reports the Witnet-provided result to a previously posted request.
    /// @dev Fails if:
    /// @dev - called from unauthorized address;
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique query identifier
    /// @param _timestamp The timestamp of the solving tally transaction in Witnet.
    /// @param _drTxHash The hash of the solving tally transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(uint256 _queryId, uint256 _timestamp, bytes32 _drTxHash, bytes calldata _result) external;
}
// File: contracts\interfaces\IWitnetRequest.sol
/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    /// A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}
// File: contracts\libs\Witnet.sol
library Witnet {

    /// @notice Witnet function that computes the hash of a CBOR-encoded Data Request.
    /// @param _bytecode CBOR-encoded RADON.
    function hash(bytes memory _bytecode) internal pure returns (bytes32) {
        return sha256(_bytecode);
    }

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
        address from;      // Address from which the request was posted.
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        IWitnetRequest addr;    // The contract containing the Data Request which execution has been requested.
        address requester;      // Address from which the request was posted.
        bytes32 hash;           // Hash of the Data Request whose execution has been requested.
        uint256 gasprice;       // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;         // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // Timestamp of the Witnet-provided result.
        bytes32 drTxHash;       // Hash of the Witnet transaction that solved the queried Data Request.
        bytes   cborBytes;      // Witnet-provided result CBOR-bytes to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        CBOR value;             // Resulting value, in CBOR-serialized bytes.
    }

    /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
    struct CBOR {
        Buffer buffer;
        uint8 initialByte;
        uint8 majorType;
        uint8 additionalInformation;
        uint64 len;
        uint64 tag;
    }

    /// Iterable bytes buffer.
    struct Buffer {
        bytes data;
        uint32 cursor;
    }

    /// Witnet error codes table.
    enum ErrorCodes {
        // 0x00: Unknown error. Something went really bad!
        Unknown,
        // Script format errors
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR,
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid Data Request.
        SourceScriptNotRADON,
        /// Unallocated
        ScriptFormat0x04,
        ScriptFormat0x05,
        ScriptFormat0x06,
        ScriptFormat0x07,
        ScriptFormat0x08,
        ScriptFormat0x09,
        ScriptFormat0x0A,
        ScriptFormat0x0B,
        ScriptFormat0x0C,
        ScriptFormat0x0D,
        ScriptFormat0x0E,
        ScriptFormat0x0F,
        // Complexity errors
        /// 0x10: The request contains too many sources.
        RequestTooManySources,
        /// 0x11: The script contains too many calls.
        ScriptTooManyCalls,
        /// Unallocated
        Complexity0x12,
        Complexity0x13,
        Complexity0x14,
        Complexity0x15,
        Complexity0x16,
        Complexity0x17,
        Complexity0x18,
        Complexity0x19,
        Complexity0x1A,
        Complexity0x1B,
        Complexity0x1C,
        Complexity0x1D,
        Complexity0x1E,
        Complexity0x1F,
        // Operator errors
        /// 0x20: The operator does not exist.
        UnsupportedOperator,
        /// Unallocated
        Operator0x21,
        Operator0x22,
        Operator0x23,
        Operator0x24,
        Operator0x25,
        Operator0x26,
        Operator0x27,
        Operator0x28,
        Operator0x29,
        Operator0x2A,
        Operator0x2B,
        Operator0x2C,
        Operator0x2D,
        Operator0x2E,
        Operator0x2F,
        // Retrieval-specific errors
        /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
        HTTP,
        /// 0x31: Retrieval of at least one of the sources timed out.
        RetrievalTimeout,
        /// Unallocated
        Retrieval0x32,
        Retrieval0x33,
        Retrieval0x34,
        Retrieval0x35,
        Retrieval0x36,
        Retrieval0x37,
        Retrieval0x38,
        Retrieval0x39,
        Retrieval0x3A,
        Retrieval0x3B,
        Retrieval0x3C,
        Retrieval0x3D,
        Retrieval0x3E,
        Retrieval0x3F,
        // Math errors
        /// 0x40: Math operator caused an underflow.
        Underflow,
        /// 0x41: Math operator caused an overflow.
        Overflow,
        /// 0x42: Tried to divide by zero.
        DivisionByZero,
        /// Unallocated
        Math0x43,
        Math0x44,
        Math0x45,
        Math0x46,
        Math0x47,
        Math0x48,
        Math0x49,
        Math0x4A,
        Math0x4B,
        Math0x4C,
        Math0x4D,
        Math0x4E,
        Math0x4F,
        // Other errors
        /// 0x50: Received zero reveals
        NoReveals,
        /// 0x51: Insufficient consensus in tally precondition clause
        InsufficientConsensus,
        /// 0x52: Received zero commits
        InsufficientCommits,
        /// 0x53: Generic error during tally execution
        TallyExecution,
        /// Unallocated
        OtherError0x54,
        OtherError0x55,
        OtherError0x56,
        OtherError0x57,
        OtherError0x58,
        OtherError0x59,
        OtherError0x5A,
        OtherError0x5B,
        OtherError0x5C,
        OtherError0x5D,
        OtherError0x5E,
        OtherError0x5F,
        /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
        MalformedReveal,
        /// Unallocated
        OtherError0x61,
        OtherError0x62,
        OtherError0x63,
        OtherError0x64,
        OtherError0x65,
        OtherError0x66,
        OtherError0x67,
        OtherError0x68,
        OtherError0x69,
        OtherError0x6A,
        OtherError0x6B,
        OtherError0x6C,
        OtherError0x6D,
        OtherError0x6E,
        OtherError0x6F,
        // Access errors
        /// 0x70: Tried to access a value from an index using an index that is out of bounds
        ArrayIndexOutOfBounds,
        /// 0x71: Tried to access a value from a map using a key that does not exist
        MapKeyNotFound,
        /// Unallocated
        OtherError0x72,
        OtherError0x73,
        OtherError0x74,
        OtherError0x75,
        OtherError0x76,
        OtherError0x77,
        OtherError0x78,
        OtherError0x79,
        OtherError0x7A,
        OtherError0x7B,
        OtherError0x7C,
        OtherError0x7D,
        OtherError0x7E,
        OtherError0x7F,
        OtherError0x80,
        OtherError0x81,
        OtherError0x82,
        OtherError0x83,
        OtherError0x84,
        OtherError0x85,
        OtherError0x86,
        OtherError0x87,
        OtherError0x88,
        OtherError0x89,
        OtherError0x8A,
        OtherError0x8B,
        OtherError0x8C,
        OtherError0x8D,
        OtherError0x8E,
        OtherError0x8F,
        OtherError0x90,
        OtherError0x91,
        OtherError0x92,
        OtherError0x93,
        OtherError0x94,
        OtherError0x95,
        OtherError0x96,
        OtherError0x97,
        OtherError0x98,
        OtherError0x99,
        OtherError0x9A,
        OtherError0x9B,
        OtherError0x9C,
        OtherError0x9D,
        OtherError0x9E,
        OtherError0x9F,
        OtherError0xA0,
        OtherError0xA1,
        OtherError0xA2,
        OtherError0xA3,
        OtherError0xA4,
        OtherError0xA5,
        OtherError0xA6,
        OtherError0xA7,
        OtherError0xA8,
        OtherError0xA9,
        OtherError0xAA,
        OtherError0xAB,
        OtherError0xAC,
        OtherError0xAD,
        OtherError0xAE,
        OtherError0xAF,
        OtherError0xB0,
        OtherError0xB1,
        OtherError0xB2,
        OtherError0xB3,
        OtherError0xB4,
        OtherError0xB5,
        OtherError0xB6,
        OtherError0xB7,
        OtherError0xB8,
        OtherError0xB9,
        OtherError0xBA,
        OtherError0xBB,
        OtherError0xBC,
        OtherError0xBD,
        OtherError0xBE,
        OtherError0xBF,
        OtherError0xC0,
        OtherError0xC1,
        OtherError0xC2,
        OtherError0xC3,
        OtherError0xC4,
        OtherError0xC5,
        OtherError0xC6,
        OtherError0xC7,
        OtherError0xC8,
        OtherError0xC9,
        OtherError0xCA,
        OtherError0xCB,
        OtherError0xCC,
        OtherError0xCD,
        OtherError0xCE,
        OtherError0xCF,
        OtherError0xD0,
        OtherError0xD1,
        OtherError0xD2,
        OtherError0xD3,
        OtherError0xD4,
        OtherError0xD5,
        OtherError0xD6,
        OtherError0xD7,
        OtherError0xD8,
        OtherError0xD9,
        OtherError0xDA,
        OtherError0xDB,
        OtherError0xDC,
        OtherError0xDD,
        OtherError0xDE,
        OtherError0xDF,
        // Bridge errors: errors that only belong in inter-client communication
        /// 0xE0: Requests that cannot be parsed must always get this error as their result.
        /// However, this is not a valid result in a Tally transaction, because invalid requests
        /// are never included into blocks and therefore never get a Tally in response.
        BridgeMalformedRequest,
        /// 0xE1: Witnesses exceeds 100
        BridgePoorIncentives,
        /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
        /// amount of value that is unjustifiably high when compared with the reward they will be getting
        BridgeOversizedResult,
        /// Unallocated
        OtherError0xE3,
        OtherError0xE4,
        OtherError0xE5,
        OtherError0xE6,
        OtherError0xE7,
        OtherError0xE8,
        OtherError0xE9,
        OtherError0xEA,
        OtherError0xEB,
        OtherError0xEC,
        OtherError0xED,
        OtherError0xEE,
        OtherError0xEF,
        OtherError0xF0,
        OtherError0xF1,
        OtherError0xF2,
        OtherError0xF3,
        OtherError0xF4,
        OtherError0xF5,
        OtherError0xF6,
        OtherError0xF7,
        OtherError0xF8,
        OtherError0xF9,
        OtherError0xFA,
        OtherError0xFB,
        OtherError0xFC,
        OtherError0xFD,
        OtherError0xFE,
        // This should not exist:
        /// 0xFF: Some tally error is not intercepted but should
        UnhandledIntercept
    }
}
// File: contracts\interfaces\IWitnetRequestBoardRequestor.sol
/// @title Witnet Requestor Interface
/// @notice It defines how to interact with the Witnet Request Board in order to:
///   - request the execution of Witnet Radon scripts (data request);
///   - upgrade the resolution reward of any previously posted request, in case gas price raises in mainnet;
///   - read the result of any previously posted request, eventually reported by the Witnet DON.
///   - remove from storage all data related to past and solved data requests, and results.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardRequestor {
    /// Retrieves a copy of all Witnet-provided data related to a previously posted request, removing the whole query from the WRB storage.
    /// @dev Fails if the `_queryId` is not in 'Reported' status, or called from an address different to
    /// @dev the one that actually posted the given request.
    /// @param _queryId The unique query identifier.
    function deleteQuery(uint256 _queryId) external returns (Witnet.Response memory);

    /// Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @dev - provided script is zero address.
    /// @dev - provided script bytecode is empty.
    /// @param _addr The address of the IWitnetRequest contract that can provide the actual Data Request bytecode.
    /// @return _queryId An unique query identifier.
    function postRequest(IWitnetRequest _addr) external payable returns (uint256 _queryId);

    /// Increments the reward of a previously posted request by adding the transaction value to it.
    /// @dev Updates request `gasPrice` in case this method is called with a higher 
    /// @dev gas price value than the one used in previous calls to `postRequest` or
    /// @dev `upgradeReward`. 
    /// @dev Fails if the `_queryId` is not in 'Posted' status.
    /// @dev Fails also in case the request `gasPrice` is increased, and the new 
    /// @dev reward value gets below new recalculated threshold. 
    /// @param _queryId The unique query identifier.
    function upgradeReward(uint256 _queryId) external payable;
}
// File: contracts\interfaces\IWitnetRequestBoardView.sol
/// @title Witnet Request Board info interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardView {
    /// Estimates the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the rewards.
    function estimateReward(uint256 _gasPrice) external view returns (uint256);

    /// Returns next query id to be generated by the Witnet Request Board.
    function getNextQueryId() external view returns (uint256);

    /// Gets the whole Query data contents, if any, no matter its current status.
    function getQueryData(uint256 _queryId) external view returns (Witnet.Query memory);

    /// Gets current status of given query.
    function getQueryStatus(uint256 _queryId) external view returns (Witnet.QueryStatus);

    /// Retrieves the whole Request record posted to the Witnet Request Board.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been reported
    /// @dev or deleted.
    /// @param _queryId The unique identifier of a previously posted query.
    function readRequest(uint256 _queryId) external view returns (Witnet.Request memory);

    /// Retrieves the serialized bytecode of a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid, or if the related script bytecode 
    /// @dev got changed after being posted. Returns empty array once it gets reported, 
    /// @dev or deleted.
    /// @param _queryId The unique query identifier.
    function readRequestBytecode(uint256 _queryId) external view returns (bytes memory);

    /// Retrieves the gas price that any assigned reporter will have to pay when reporting 
    /// result to a previously posted Witnet data request.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifie
    function readRequestGasPrice(uint256 _queryId) external view returns (uint256);

    /// Retrieves the reward currently set for the referred query.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifier.
    function readRequestReward(uint256 _queryId) external view returns (uint256);

    /// Retrieves the whole `Witnet.Response` record referred to a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponse(uint256 _queryId) external view returns (Witnet.Response memory);

    /// Retrieves the hash of the Witnet transaction hash that actually solved the referred query.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseDrTxHash(uint256 _queryId) external view returns (bytes32);    

    /// Retrieves the address that reported the result to a previously-posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseReporter(uint256 _queryId) external view returns (address);

    /// Retrieves the Witnet-provided CBOR-bytes result of a previously posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseResult(uint256 _queryId) external view returns (Witnet.Result memory);

    /// Retrieves the timestamp in which the result to the referred query was solved by the Witnet DON.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseTimestamp(uint256 _queryId) external view returns (uint256);
}
// File: contracts\interfaces\IWitnetRequestParser.sol
/// @title The Witnet interface for decoding Witnet-provided request to Data Requests.
/// This interface exposes functions to check for the success/failure of
/// a Witnet-provided result, as well as to parse and convert result into
/// Solidity types suitable to the application level. 
/// @author The Witnet Foundation.
interface IWitnetRequestParser {

    /// Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory _cborBytes) external pure returns (Witnet.Result memory);

    /// Decode a CBOR value into a Witnet.Result instance.
    /// @param _cborValue An instance of `Witnet.CBOR`.
    /// @return A `Witnet.Result` instance.
    function resultFromCborValue(Witnet.CBOR memory _cborValue) external pure returns (Witnet.Result memory);

    /// Tell if a Witnet.Result is successful.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if successful, `false` if errored.
    function isOk(Witnet.Result memory _result) external pure returns (bool);

    /// Tell if a Witnet.Result is errored.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function isError(Witnet.Result memory _result) external pure returns (bool);

    /// Decode a bytes value from a Witnet.Result as a `bytes` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes` decoded from the Witnet.Result.
    function asBytes(Witnet.Result memory _result) external pure returns (bytes memory);

    /// Decode a bytes value from a Witnet.Result as a `bytes32` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes32` decoded from the Witnet.Result.
    function asBytes32(Witnet.Result memory _result) external pure returns (bytes32);

    /// Decode an error code from a Witnet.Result as a member of `Witnet.ErrorCodes`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `CBORValue.Error memory` decoded from the Witnet.Result.
    function asErrorCode(Witnet.Result memory _result) external pure returns (Witnet.ErrorCodes);


    /// Generate a suitable error message for a member of `Witnet.ErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param _result An instance of `Witnet.Result`.
    /// @return A tuple containing the `CBORValue.Error memory` decoded from the `Witnet.Result`, plus a loggable error message.
    function asErrorMessage(Witnet.Result memory _result) external pure returns (Witnet.ErrorCodes, string memory);

    /// Decode a raw error from a `Witnet.Result` as a `uint64[]`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `uint64[]` raw error as decoded from the `Witnet.Result`.
    function asRawError(Witnet.Result memory _result) external pure returns(uint64[] memory);

    /// Decode a boolean value from a Witnet.Result as an `bool` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bool` decoded from the Witnet.Result.
    function asBool(Witnet.Result memory _result) external pure returns (bool);

    /// Decode a fixed16 (half-precision) numeric value from a Witnet.Result as an `int32` value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asFixed16(Witnet.Result memory _result) external pure returns (int32);

    /// Decode an array of fixed16 values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asFixed16Array(Witnet.Result memory _result) external pure returns (int32[] memory);

    /// Decode a integer numeric value from a Witnet.Result as an `int128` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asInt128(Witnet.Result memory _result) external pure returns (int128);

    /// Decode an array of integer numeric values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asInt128Array(Witnet.Result memory _result) external pure returns (int128[] memory);

    /// Decode a string value from a Witnet.Result as a `string` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asString(Witnet.Result memory _result) external pure returns (string memory);

    /// Decode an array of string values from a Witnet.Result as a `string[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asStringArray(Witnet.Result memory _result) external pure returns (string[] memory);

    /// Decode a natural numeric value from a Witnet.Result as a `uint64` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64` decoded from the Witnet.Result.
    function asUint64(Witnet.Result memory _result) external pure returns(uint64);

    /// Decode an array of natural numeric values from a Witnet.Result as a `uint64[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64[]` decoded from the Witnet.Result.
    function asUint64Array(Witnet.Result memory _result) external pure returns (uint64[] memory);

}
// File: contracts\WitnetRequestBoard.sol
/// @title Witnet Request Board functionality base contract.
/// @author The Witnet Foundation.
abstract contract WitnetRequestBoard is
    IWitnetRequestBoardEvents,
    IWitnetRequestBoardReporter,
    IWitnetRequestBoardRequestor,
    IWitnetRequestBoardView,
    IWitnetRequestParser
{
    receive() external payable {
        revert("WitnetRequestBoard: no transfers accepted");
    }
}
// File: contracts\patterns\Proxiable.sol
interface Proxiable {
    /// @dev Complying with EIP-1822: Universal Upgradable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID() external pure returns (bytes32);
}
// File: contracts\patterns\Initializable.sol
interface Initializable {
    /// @dev Initialize contract's storage context.
    function initialize(bytes calldata) external;
}
// File: contracts\patterns\Upgradable.sol
/* solhint-disable var-name-mixedcase */




abstract contract Upgradable is Initializable, Proxiable {

    address internal immutable _BASE;
    bytes32 internal immutable _CODEHASH;
    bool internal immutable _UPGRADABLE;

    /// Emitted every time the contract gets upgraded.
    /// @param from The address who ordered the upgrading. Namely, the WRB operator in "trustable" implementations.
    /// @param baseAddr The address of the new implementation contract.
    /// @param baseCodehash The EVM-codehash of the new implementation contract.
    /// @param versionTag Ascii-encoded version literal with which the implementation deployer decided to tag it.
    event Upgraded(
        address indexed from,
        address indexed baseAddr,
        bytes32 indexed baseCodehash,
        bytes32 versionTag
    );

    constructor (bool _isUpgradable) {
        address _base = address(this);
        bytes32 _codehash;        
        assembly {
            _codehash := extcodehash(_base)
        }
        _BASE = _base;
        _CODEHASH = _codehash;        
        _UPGRADABLE = _isUpgradable;
    }

    /// @dev Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address from) virtual external view returns (bool);


    /// TODO: the following methods should be all declared as pure 
    ///       whenever this Solidity's PR gets merged and released: 
    ///       https://github.com/ethereum/solidity/pull/10240

    /// @dev Retrieves base contract. Differs from address(this) when via delegate-proxy pattern.
    function base() public view returns (address) {
        return _BASE;
    }

    /// @dev Retrieves the immutable codehash of this contract, even if invoked as delegatecall.
    /// @return _codehash This contracts immutable codehash.
    function codehash() public view returns (bytes32 _codehash) {
        return _CODEHASH;
    }
    
    /// @dev Determines whether current instance allows being upgraded.
    /// @dev Returned value should be invariant from whoever is calling.
    function isUpgradable() public view returns (bool) {        
        return _UPGRADABLE;
    }

    /// @dev Retrieves human-redable named version of current implementation.
    function version() virtual public view returns (bytes32); 
}
// File: contracts\impls\WitnetProxy.sol
/// @title WitnetProxy: upgradable delegate-proxy contract that routes Witnet data requests coming from a 
/// `UsingWitnet`-inheriting contract to a currently active `WitnetRequestBoard` implementation. 
/// @author The Witnet Foundation.
contract WitnetProxy {

    struct WitnetProxySlot {
        address implementation;
    }

    /// Event emitted every time the implementation gets updated.
    event Upgraded(address indexed implementation);  

    /// Constructor with no params as to ease eventual support of Singleton pattern (i.e. ERC-2470).
    constructor () {}

    /// WitnetProxies will never accept direct transfer of ETHs.
    receive() external payable {
        revert("WitnetProxy: no transfers accepted");
    }

    /// Payable fallback accepts delegating calls to payable functions.  
    fallback() external payable { /* solhint-disable no-complex-fallback */
        address _implementation = implementation();

        assembly { /* solhint-disable avoid-low-level-calls */
            // Gas optimized delegate call to 'implementation' contract.
            // Note: `msg.data`, `msg.sender` and `msg.value` will be passed over 
            //       to actual implementation of `msg.sig` within `implementation` contract.
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
                case 0  { 
                    // pass back revert message:
                    revert(ptr, size) 
                }
                default {
                  // pass back same data as returned by 'implementation' contract:
                  return(ptr, size) 
                }
        }
    }

    /// Returns proxy's current implementation address.
    function implementation() public view returns (address) {
        return _proxySlot().implementation;
    }

    /// Upgrades the `implementation` address.
    /// @param _newImplementation New implementation address.
    /// @param _initData Raw data with which new implementation will be initialized.
    /// @return Returns whether new implementation would be further upgradable, or not.
    function upgradeTo(address _newImplementation, bytes memory _initData)
        public returns (bool)
    {
        // New implementation cannot be null:
        require(_newImplementation != address(0), "WitnetProxy: null implementation");

        address _oldImplementation = implementation();
        if (_oldImplementation != address(0)) {
            // New implementation address must differ from current one:
            require(_newImplementation != _oldImplementation, "WitnetProxy: nothing to upgrade");

            // Assert whether current implementation is intrinsically upgradable:
            try Upgradable(_oldImplementation).isUpgradable() returns (bool _isUpgradable) {
                require(_isUpgradable, "WitnetProxy: not upgradable");
            } catch {
                revert("WitnetProxy: unable to check upgradability");
            }

            // Assert whether current implementation allows `msg.sender` to upgrade the proxy:
            (bool _wasCalled, bytes memory _result) = _oldImplementation.delegatecall(
                abi.encodeWithSignature(
                    "isUpgradableFrom(address)",
                    msg.sender
                )
            );
            require(_wasCalled, "WitnetProxy: not compliant");
            require(abi.decode(_result, (bool)), "WitnetProxy: not authorized");
            require(
                Upgradable(_oldImplementation).proxiableUUID() == Upgradable(_newImplementation).proxiableUUID(),
                "WitnetProxy: proxiableUUIDs mismatch"
            );
        }

        // Initialize new implementation within proxy-context storage:
        (bool _wasInitialized,) = _newImplementation.delegatecall(
            abi.encodeWithSignature(
                "initialize(bytes)",
                _initData
            )
        );
        require(_wasInitialized, "WitnetProxy: unable to initialize");

        // If all checks and initialization pass, update implementation address:
        _proxySlot().implementation = _newImplementation;
        emit Upgraded(_newImplementation);

        // Asserts new implementation complies w/ minimal implementation of Upgradable interface:
        try Upgradable(_newImplementation).isUpgradable() returns (bool _isUpgradable) {
            return _isUpgradable;
        }
        catch {
            revert ("WitnetProxy: not compliant");
        }
    }

    /// @dev Complying with EIP-1967, retrieves storage struct containing proxy's current implementation address.
    function _proxySlot() private pure returns (WitnetProxySlot storage _slot) {
        assembly {
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            _slot.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        }
    }

}
// File: contracts\impls\WitnetRequestBoardUpgradableBase.sol
/* solhint-disable var-name-mixedcase */

// Inherits from:




// Eventual deployment dependencies:


/// @title Witnet Request Board base contract, with an Upgradable (and Destructible) touch.
/// @author The Witnet Foundation.
abstract contract WitnetRequestBoardUpgradableBase
    is
        Proxiable,
        Upgradable,
        WitnetRequestBoard
{
    bytes32 internal immutable _VERSION;

    constructor(
            bool _upgradable,
            bytes32 _versionTag
        )
        Upgradable(_upgradable)
    {
        _VERSION = _versionTag;
    }

    /// @dev Reverts if proxy delegatecalls to unexistent method.
    fallback() external payable {
        revert("WitnetRequestBoardUpgradableBase: not implemented");
    }

    // ================================================================================================================
    // --- Overrides 'Proxiable' --------------------------------------------------------------------------------------

    /// @dev Gets immutable "heritage blood line" (ie. genotype) as a Proxiable, and eventually Upgradable, contract.
    ///      If implemented as an Upgradable touch, upgrading this contract to another one with a different 
    ///      `proxiableUUID()` value should fail.
    function proxiableUUID() external pure override returns (bytes32) {
        return (
            /* keccak256("io.witnet.proxiable.board") */
            0x9969c6aff411c5e5f0807500693e8f819ce88529615cfa6cab569b24788a1018
        );
    }   

    // ================================================================================================================
    // --- Overrides 'Upgradable' --------------------------------------------------------------------------------------

    /// Retrieves human-readable version tag of current implementation.
    function version() public view override returns (bytes32) {
        return _VERSION;
    }

}
// File: contracts\data\WitnetBoardData.sol
/// @title Witnet Request Board base data model. 
/// @author The Witnet Foundation.
abstract contract WitnetBoardData {  

    bytes32 internal constant _WITNET_BOARD_DATA_SLOTHASH =
        /* keccak256("io.witnet.boards.data") */
        0xf595240b351bc8f951c2f53b26f4e78c32cb62122cf76c19b7fdda7d4968e183;

    struct WitnetBoardState {
        address base;
        address owner;    
        uint256 numQueries;
        mapping (uint => Witnet.Query) queries;
    }

    constructor() {
        _state().owner = msg.sender;
    }

    /// Asserts the given query is currently in the given status.
    modifier inStatus(uint256 _queryId, Witnet.QueryStatus _status) {
      require(
          _getQueryStatus(_queryId) == _status,
          _getQueryStatusRevertMessage(_status)
        );
      _;
    }

    /// Asserts the given query was previously posted and that it was not yet deleted.
    modifier notDeleted(uint256 _queryId) {
        require(_queryId > 0 && _queryId <= _state().numQueries, "WitnetBoardData: not yet posted");
        require(_getRequester(_queryId) != address(0), "WitnetBoardData: deleted");
        _;
    }

    /// Asserts caller corresponds to the current owner. 
    modifier onlyOwner {
        require(msg.sender == _state().owner, "WitnetBoardData: only owner");
        _;    
    }

    /// Asserts the give query was actually posted before calling this method.
    modifier wasPosted(uint256 _queryId) {
        require(_queryId > 0 && _queryId <= _state().numQueries, "WitnetBoardData: not yet posted");
        _;
    }

    // ================================================================================================================
    // --- Internal functions -----------------------------------------------------------------------------------------

    /// Gets current status of given query.
    function _getQueryStatus(uint256 _queryId)
      internal view
      returns (Witnet.QueryStatus)
    {
      if (_queryId == 0 || _queryId > _state().numQueries) {
        // "Unknown" status if queryId is out of range:
        return Witnet.QueryStatus.Unknown;
      }
      else {
        Witnet.Query storage _query = _state().queries[_queryId];
        if (_query.response.drTxHash != 0) {
          // Query is in "Reported" status as soon as the hash of the
          // Witnet transaction that solved the query is reported
          // back from a Witnet bridge:
          return Witnet.QueryStatus.Reported;
        }
        else if (
          _query.from != address(0)
            || _query.request.requester != address(0) // (avoids breaking change when upgrading from 0.5.3 to 0.5.4)
        ) {
          // Otherwise, while address from which the query was posted
          // is kept in storage, the query remains in "Posted" status:
          return Witnet.QueryStatus.Posted;
        }
        else {
          // Requester's address is removed from storage only if
          // the query gets "Deleted" by its requester.
          return Witnet.QueryStatus.Deleted;
        }
      }
    }

    function _getQueryStatusRevertMessage(Witnet.QueryStatus _status)
      internal pure
      returns (string memory)
    {
      if (_status == Witnet.QueryStatus.Posted) {
        return "WitnetBoardData: not in Posted status";
      } else if (_status == Witnet.QueryStatus.Reported) {
        return "WitnetBoardData: not in Reported status";
      } else if (_status == Witnet.QueryStatus.Deleted) {
        return "WitnetBoardData: not in Deleted status";
      } else {
        return "WitnetBoardData: bad mood";
      }
    }

    /// Gets from of a given query.
    function _getRequester(uint256 _queryId)
      internal view
      returns (address)
    {
      return _state().queries[_queryId].from;
    }

    /// Gets the Witnet.Request part of a given query.
    function _getRequestData(uint256 _queryId)
      internal view
      returns (Witnet.Request storage)
    {
        return _state().queries[_queryId].request;
    }

    /// Gets the Witnet.Result part of a given query.
    function _getResponseData(uint256 _queryId)
      internal view
      returns (Witnet.Response storage)
    {
        return _state().queries[_queryId].response;
    }

    /// Returns storage pointer to contents of 'WitnetBoardState' struct.
    function _state()
      internal pure
      returns (WitnetBoardState storage _ptr)
    {
        assembly {
            _ptr.slot := _WITNET_BOARD_DATA_SLOTHASH
        }
    }

}
// File: contracts\data\WitnetBoardDataACLs.sol
/// @title Witnet Access Control Lists storage layout, for Witnet-trusted request boards.
/// @author The Witnet Foundation.
abstract contract WitnetBoardDataACLs
    is
        WitnetBoardData
{
    bytes32 internal constant _WITNET_BOARD_ACLS_SLOTHASH =
        /* keccak256("io.witnet.boards.data.acls") */
        0xa6db7263983f337bae2c9fb315730227961d1c1153ae1e10a56b5791465dd6fd;

    struct WitnetBoardACLs {
        mapping (address => bool) isReporter_;
    }

    constructor() {
        _acls().isReporter_[msg.sender] = true;
    }

    modifier onlyReporters {
        require(
            _acls().isReporter_[msg.sender],
            "WitnetBoardDataACLs: unauthorized reporter"
        );
        _;
    } 

    // ================================================================================================================
    // --- Internal functions -----------------------------------------------------------------------------------------

    function _acls() internal pure returns (WitnetBoardACLs storage _struct) {
        assembly {
            _struct.slot := _WITNET_BOARD_ACLS_SLOTHASH
        }
    }
}
// File: contracts\interfaces\IWitnetRequestBoardAdmin.sol
/// @title Witnet Request Board basic administration interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardAdmin {
    event OwnershipTransferred(address indexed from, address indexed to);

    /// Gets admin/owner address.
    function owner() external view returns (address);

    /// Transfers ownership.
    function transferOwnership(address) external;
}
// File: contracts\interfaces\IWitnetRequestBoardAdminACLs.sol
/// @title Witnet Request Board ACLs administration interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardAdminACLs {
    event ReportersSet(address[] reporters);
    event ReportersUnset(address[] reporters);

    /// Tells whether given address is included in the active reporters control list.
    function isReporter(address) external view returns (bool);

    /// Adds given addresses to the active reporters control list.
    /// @dev Can only be called from the owner address.
    /// @dev Emits the `ReportersSet` event. 
    function setReporters(address[] calldata reporters) external;

    /// Removes given addresses from the active reporters control list.
    /// @dev Can only be called from the owner address.
    /// @dev Emits the `ReportersUnset` event. 
    function unsetReporters(address[] calldata reporters) external;
}
// File: contracts\libs\WitnetBuffer.sol
/// @title A convenient wrapper around the `bytes memory` type that exposes a buffer-like interface
/// @notice The buffer has an inner cursor that tracks the final offset of every read, i.e. any subsequent read will
/// start with the byte that goes right after the last one in the previous read.
/// @dev `uint32` is used here for `cursor` because `uint16` would only enable seeking up to 8KB, which could in some
/// theoretical use cases be exceeded. Conversely, `uint32` supports up to 512MB, which cannot credibly be exceeded.
/// @author The Witnet Foundation.
library WitnetBuffer {

  // Ensures we access an existing index in an array
  modifier notOutOfBounds(uint32 index, uint256 length) {
    require(index < length, "WitnetBuffer: Tried to read from a consumed Buffer (must rewind it first)");
    _;
  }

  /// @notice Read and consume a certain amount of bytes from the buffer.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @param _length How many bytes to read and consume from the buffer.
  /// @return A `bytes memory` containing the first `_length` bytes from the buffer, counting from the cursor position.
  function read(Witnet.Buffer memory _buffer, uint32 _length) internal pure returns (bytes memory) {
    // Make sure not to read out of the bounds of the original bytes
    require(_buffer.cursor + _length <= _buffer.data.length, "WitnetBuffer: Not enough bytes in buffer when reading");

    // Create a new `bytes memory destination` value
    bytes memory destination = new bytes(_length);

    // Early return in case that bytes length is 0
    if (_length != 0) {
      bytes memory source = _buffer.data;
      uint32 offset = _buffer.cursor;

      // Get raw pointers for source and destination
      uint sourcePointer;
      uint destinationPointer;
      assembly {
        sourcePointer := add(add(source, 32), offset)
        destinationPointer := add(destination, 32)
      }
      // Copy `_length` bytes from source to destination
      memcpy(destinationPointer, sourcePointer, uint(_length));

      // Move the cursor forward by `_length` bytes
      seek(_buffer, _length, true);
    }
    return destination;
  }

  /// @notice Read and consume the next byte from the buffer.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The next byte in the buffer counting from the cursor position.
  function next(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor, _buffer.data.length) returns (bytes1) {
    // Return the byte at the position marked by the cursor and advance the cursor all at once
    return _buffer.data[_buffer.cursor++];
  }

  /// @notice Move the inner cursor of the buffer to a relative or absolute position.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @param _offset How many bytes to move the cursor forward.
  /// @param _relative Whether to count `_offset` from the last position of the cursor (`true`) or the beginning of the
  /// buffer (`true`).
  /// @return The final position of the cursor (will equal `_offset` if `_relative` is `false`).
  // solium-disable-next-line security/no-assign-params
  function seek(Witnet.Buffer memory _buffer, uint32 _offset, bool _relative) internal pure returns (uint32) {
    // Deal with relative offsets
    if (_relative) {
      require(_offset + _buffer.cursor > _offset, "WitnetBuffer: Integer overflow when seeking");
      _offset += _buffer.cursor;
    }
    // Make sure not to read out of the bounds of the original bytes
    require(_offset <= _buffer.data.length, "WitnetBuffer: Not enough bytes in buffer when seeking");
    _buffer.cursor = _offset;
    return _buffer.cursor;
  }

  /// @notice Move the inner cursor a number of bytes forward.
  /// @dev This is a simple wrapper around the relative offset case of `seek()`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @param _relativeOffset How many bytes to move the cursor forward.
  /// @return The final position of the cursor.
  function seek(Witnet.Buffer memory _buffer, uint32 _relativeOffset) internal pure returns (uint32) {
    return seek(_buffer, _relativeOffset, true);
  }

  /// @notice Move the inner cursor back to the first byte in the buffer.
  /// @param _buffer An instance of `Witnet.Buffer`.
  function rewind(Witnet.Buffer memory _buffer) internal pure {
    _buffer.cursor = 0;
  }

  /// @notice Read and consume the next byte from the buffer as an `uint8`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint8` value of the next byte in the buffer counting from the cursor position.
  function readUint8(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor, _buffer.data.length) returns (uint8) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint8 value;
    assembly {
      value := mload(add(add(bytesValue, 1), offset))
    }
    _buffer.cursor++;

    return value;
  }

  /// @notice Read and consume the next 2 bytes from the buffer as an `uint16`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint16` value of the next 2 bytes in the buffer counting from the cursor position.
  function readUint16(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 1, _buffer.data.length) returns (uint16) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint16 value;
    assembly {
      value := mload(add(add(bytesValue, 2), offset))
    }
    _buffer.cursor += 2;

    return value;
  }

  /// @notice Read and consume the next 4 bytes from the buffer as an `uint32`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readUint32(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 3, _buffer.data.length) returns (uint32) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint32 value;
    assembly {
      value := mload(add(add(bytesValue, 4), offset))
    }
    _buffer.cursor += 4;

    return value;
  }

  /// @notice Read and consume the next 8 bytes from the buffer as an `uint64`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint64` value of the next 8 bytes in the buffer counting from the cursor position.
  function readUint64(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 7, _buffer.data.length) returns (uint64) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint64 value;
    assembly {
      value := mload(add(add(bytesValue, 8), offset))
    }
    _buffer.cursor += 8;

    return value;
  }

  /// @notice Read and consume the next 16 bytes from the buffer as an `uint128`.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint128` value of the next 16 bytes in the buffer counting from the cursor position.
  function readUint128(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 15, _buffer.data.length) returns (uint128) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint128 value;
    assembly {
      value := mload(add(add(bytesValue, 16), offset))
    }
    _buffer.cursor += 16;

    return value;
  }

  /// @notice Read and consume the next 32 bytes from the buffer as an `uint256`.
  /// @return The `uint256` value of the next 32 bytes in the buffer counting from the cursor position.
  /// @param _buffer An instance of `Witnet.Buffer`.
  function readUint256(Witnet.Buffer memory _buffer) internal pure notOutOfBounds(_buffer.cursor + 31, _buffer.data.length) returns (uint256) {
    bytes memory bytesValue = _buffer.data;
    uint32 offset = _buffer.cursor;
    uint256 value;
    assembly {
      value := mload(add(add(bytesValue, 32), offset))
    }
    _buffer.cursor += 32;

    return value;
  }

  /// @notice Read and consume the next 2 bytes from the buffer as an IEEE 754-2008 floating point number enclosed in an
  /// `int32`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `float16`
  /// use cases. In other words, the integer output of this method is 10,000 times the actual value. The input bytes are
  /// expected to follow the 16-bit base-2 format (a.k.a. `binary16`) in the IEEE 754-2008 standard.
  /// @param _buffer An instance of `Witnet.Buffer`.
  /// @return The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readFloat16(Witnet.Buffer memory _buffer) internal pure returns (int32) {
    uint32 bytesValue = readUint16(_buffer);
    // Get bit at position 0
    uint32 sign = bytesValue & 0x8000;
    // Get bits 1 to 5, then normalize to the [-14, 15] range so as to counterweight the IEEE 754 exponent bias
    int32 exponent = (int32(bytesValue & 0x7c00) >> 10) - 15;
    // Get bits 6 to 15
    int32 significand = int32(bytesValue & 0x03ff);

    // Add 1024 to the fraction if the exponent is 0
    if (exponent == 15) {
      significand |= 0x400;
    }

    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    int32 result = 0;
    if (exponent >= 0) {
      result = int32((int256(1 << uint256(int256(exponent))) * 10000 * int256(uint256(int256(significand)) | 0x400)) >> 10);
    } else {
      result = int32(((int256(uint256(int256(significand)) | 0x400) * 10000) / int256(1 << uint256(int256(- exponent)))) >> 10);
    }

    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= - 1;
    }
    return result;
  }

  /// @notice Copy bytes from one memory address into another.
  /// @dev This function was borrowed from Nick Johnson's `solidity-stringutils` lib, and reproduced here under the terms
  /// of [Apache License 2.0](https://github.com/Arachnid/solidity-stringutils/blob/master/LICENSE).
  /// @param _dest Address of the destination memory.
  /// @param _src Address to the source memory.
  /// @param _len How many bytes to copy.
  // solium-disable-next-line security/no-assign-params
  function memcpy(uint _dest, uint _src, uint _len) private pure {
    require(_len > 0, "WitnetBuffer: Cannot copy 0 bytes");

    // Copy word-length chunks while possible
    for (; _len >= 32; _len -= 32) {
      assembly {
        mstore(_dest, mload(_src))
      }
      _dest += 32;
      _src += 32;
    }
    if (_len > 0) {
      // Copy remaining bytes
      uint mask = 256 ** (32 - _len) - 1;
      assembly {
        let srcpart := and(mload(_src), not(mask))
        let destpart := and(mload(_dest), mask)
        mstore(_dest, or(destpart, srcpart))
      }
    }
  }

}
// File: contracts\libs\WitnetDecoderLib.sol
/// @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
/// @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
/// the gas cost of decoding them into a useful native type.
/// @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
/// @author The Witnet Foundation.
/// 
/// TODO: add support for Array (majorType = 4)
/// TODO: add support for Map (majorType = 5)
/// TODO: add support for Float32 (majorType = 7, additionalInformation = 26)
/// TODO: add support for Float64 (majorType = 7, additionalInformation = 27) 

library WitnetDecoderLib {

  using WitnetBuffer for Witnet.Buffer;

  uint32 constant internal _UINT32_MAX = type(uint32).max;
  uint64 constant internal _UINT64_MAX = type(uint64).max;

  /// @notice Decode a `Witnet.CBOR` structure into a native `bool` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as a `bool` value.
  function decodeBool(Witnet.CBOR memory _cborValue) public pure returns(bool) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(_cborValue.majorType == 7, "WitnetDecoderLib: Tried to read a `bool` value from a `Witnet.CBOR` with majorType != 7");
    if (_cborValue.len == 20) {
      return false;
    } else if (_cborValue.len == 21) {
      return true;
    } else {
      revert("WitnetDecoderLib: Tried to read `bool` from a `Witnet.CBOR` with len different than 20 or 21");
    }
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `bytes` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as a `bytes` value.   
  function decodeBytes(Witnet.CBOR memory _cborValue) public pure returns(bytes memory) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    if (_cborValue.len == _UINT32_MAX) {
      bytes memory bytesData;

      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 itemLength = uint32(readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType));
      if (itemLength < _UINT32_MAX) {
        bytesData = abi.encodePacked(bytesData, _cborValue.buffer.read(itemLength));
        itemLength = uint32(readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType));
        if (itemLength < _UINT32_MAX) {
          bytesData = abi.encodePacked(bytesData, _cborValue.buffer.read(itemLength));
        }
      }
      return bytesData;
    } else {
      return _cborValue.buffer.read(uint32(_cborValue.len));
    }
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `bytes32` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return _bytes32 The value represented by the input, as a `bytes32` value.
  function decodeBytes32(Witnet.CBOR memory _cborValue) public pure returns(bytes32 _bytes32) {
    bytes memory _bb = decodeBytes(_cborValue);
    uint _len = _bb.length > 32 ? 32 : _bb.length;
    for (uint _i = 0; _i < _len; _i ++) {
        _bytes32 |= bytes32(_bb[_i] & 0xff) >> (_i * 8);
    }
  }

  /// @notice Decode a `Witnet.CBOR` structure into a `fixed16` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
  /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function decodeFixed16(Witnet.CBOR memory _cborValue) public pure returns(int32) {
    require(_cborValue.majorType == 7, "WitnetDecoderLib: Tried to read a `fixed` value from a `WT.CBOR` with majorType != 7");
    require(_cborValue.additionalInformation == 25, "WitnetDecoderLib: Tried to read `fixed16` from a `WT.CBOR` with additionalInformation != 25");
    return _cborValue.buffer.readFloat16();
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `int128[]` value whose inner values follow the same convention.
  /// as explained in `decodeFixed16`.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `int128[]` value.
  function decodeFixed16Array(Witnet.CBOR memory _cborValue) external pure returns(int32[] memory) {
    require(_cborValue.majorType == 4, "WitnetDecoderLib: Tried to read `int128[]` from a `Witnet.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < _UINT64_MAX, "WitnetDecoderLib: Indefinite-length CBOR arrays are not supported");

    int32[] memory array = new int32[](length);
    for (uint64 i = 0; i < length; i++) {
      Witnet.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeFixed16(item);
    }

    return array;
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `int128` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function decodeInt128(Witnet.CBOR memory _cborValue) public pure returns(int128) {
    if (_cborValue.majorType == 1) {
      uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
      return int128(-1) - int128(uint128(length));
    } else if (_cborValue.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int128(uint128(decodeUint64(_cborValue)));
    }
    revert("WitnetDecoderLib: Tried to read `int128` from a `Witnet.CBOR` with majorType not 0 or 1");
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `int128[]` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `int128[]` value.
  function decodeInt128Array(Witnet.CBOR memory _cborValue) external pure returns(int128[] memory) {
    require(_cborValue.majorType == 4, "WitnetDecoderLib: Tried to read `int128[]` from a `Witnet.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < _UINT64_MAX, "WitnetDecoderLib: Indefinite-length CBOR arrays are not supported");

    int128[] memory array = new int128[](length);
    for (uint64 i = 0; i < length; i++) {
      Witnet.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeInt128(item);
    }

    return array;
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `string` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as a `string` value.
  function decodeString(Witnet.CBOR memory _cborValue) public pure returns(string memory) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    if (_cborValue.len == _UINT64_MAX) {
      bytes memory textData;
      bool done;
      while (!done) {
        uint64 itemLength = readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType);
        if (itemLength < _UINT64_MAX) {
          textData = abi.encodePacked(textData, readText(_cborValue.buffer, itemLength / 4));
        } else {
          done = true;
        }
      }
      return string(textData);
    } else {
      return string(readText(_cborValue.buffer, _cborValue.len));
    }
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `string[]` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `string[]` value.
  function decodeStringArray(Witnet.CBOR memory _cborValue) external pure returns(string[] memory) {
    require(_cborValue.majorType == 4, "WitnetDecoderLib: Tried to read `string[]` from a `Witnet.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < _UINT64_MAX, "WitnetDecoderLib: Indefinite-length CBOR arrays are not supported");

    string[] memory array = new string[](length);
    for (uint64 i = 0; i < length; i++) {
      Witnet.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeString(item);
    }

    return array;
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `uint64` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `uint64` value.
  function decodeUint64(Witnet.CBOR memory _cborValue) public pure returns(uint64) {
    require(_cborValue.majorType == 0, "WitnetDecoderLib: Tried to read `uint64` from a `Witnet.CBOR` with majorType != 0");
    return readLength(_cborValue.buffer, _cborValue.additionalInformation);
  }

  /// @notice Decode a `Witnet.CBOR` structure into a native `uint64[]` value.
  /// @param _cborValue An instance of `Witnet.CBOR`.
  /// @return The value represented by the input, as an `uint64[]` value.
  function decodeUint64Array(Witnet.CBOR memory _cborValue) external pure returns(uint64[] memory) {
    require(_cborValue.majorType == 4, "WitnetDecoderLib: Tried to read `uint64[]` from a `Witnet.CBOR` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < _UINT64_MAX, "WitnetDecoderLib: Indefinite-length CBOR arrays are not supported");

    uint64[] memory array = new uint64[](length);
    for (uint64 i = 0; i < length; i++) {
      Witnet.CBOR memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeUint64(item);
    }

    return array;
  }

  /// @notice Decode a Witnet.CBOR structure from raw bytes.
  /// @dev This is the main factory for Witnet.CBOR instances, which can be later decoded into native EVM types.
  /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
  /// @return A `Witnet.CBOR` instance containing a partially decoded value.
  function valueFromBytes(bytes memory _cborBytes) external pure returns(Witnet.CBOR memory) {
    Witnet.Buffer memory buffer = Witnet.Buffer(_cborBytes, 0);

    return valueFromBuffer(buffer);
  }

  /// @notice Decode a Witnet.CBOR structure from raw bytes.
  /// @dev This is an alternate factory for Witnet.CBOR instances, which can be later decoded into native EVM types.
  /// @param _buffer A Buffer structure representing a CBOR-encoded value.
  /// @return A `Witnet.CBOR` instance containing a partially decoded value.
  function valueFromBuffer(Witnet.Buffer memory _buffer) public pure returns(Witnet.CBOR memory) {
    require(_buffer.data.length > 0, "WitnetDecoderLib: Found empty buffer when parsing CBOR value");

    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 tag = _UINT64_MAX;

    bool isTagged = true;
    while (isTagged) {
      // Extract basic CBOR properties from input bytes
      initialByte = _buffer.readUint8();
      majorType = initialByte >> 5;
      additionalInformation = initialByte & 0x1f;

      // Early CBOR tag parsing.
      if (majorType == 6) {
        tag = readLength(_buffer, additionalInformation);
      } else {
        isTagged = false;
      }
    }

    require(majorType <= 7, "WitnetDecoderLib: Invalid CBOR major type");

    return Witnet.CBOR(
      _buffer,
      initialByte,
      majorType,
      additionalInformation,
      0,
      tag);
  }

  /// Reads the length of the next CBOR item from a buffer, consuming a different number of bytes depending on the
  /// value of the `additionalInformation` argument.
  function readLength(Witnet.Buffer memory _buffer, uint8 additionalInformation) private pure returns(uint64) {
    if (additionalInformation < 24) {
      return additionalInformation;
    }
    if (additionalInformation == 24) {
      return _buffer.readUint8();
    }
    if (additionalInformation == 25) {
      return _buffer.readUint16();
    }
    if (additionalInformation == 26) {
      return _buffer.readUint32();
    }
    if (additionalInformation == 27) {
      return _buffer.readUint64();
    }
    if (additionalInformation == 31) {
      return _UINT64_MAX;
    }
    revert("WitnetDecoderLib: Invalid length encoding (non-existent additionalInformation value)");
  }

  /// Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  /// as many bytes as specified by the first byte.
  function readIndefiniteStringLength(Witnet.Buffer memory _buffer, uint8 majorType) private pure returns(uint64) {
    uint8 initialByte = _buffer.readUint8();
    if (initialByte == 0xff) {
      return _UINT64_MAX;
    }
    uint64 length = readLength(_buffer, initialByte & 0x1f);
    require(length < _UINT64_MAX && (initialByte >> 5) == majorType, "WitnetDecoderLib: Invalid indefinite length");
    return length;
  }

  /// Read a text string of a given length from a buffer. Returns a `bytes memory` value for the sake of genericness,
  /// but it can be easily casted into a string with `string(result)`.
  // solium-disable-next-line security/no-assign-params
  function readText(Witnet.Buffer memory _buffer, uint64 _length) private pure returns(bytes memory) {
    bytes memory result;
    for (uint64 index = 0; index < _length; index++) {
      uint8 value = _buffer.readUint8();
      if (value & 0x80 != 0) {
        if (value < 0xe0) {
          value = (value & 0x1f) << 6 |
            (_buffer.readUint8() & 0x3f);
          _length -= 1;
        } else if (value < 0xf0) {
          value = (value & 0x0f) << 12 |
            (_buffer.readUint8() & 0x3f) << 6 |
            (_buffer.readUint8() & 0x3f);
          _length -= 2;
        } else {
          value = (value & 0x0f) << 18 |
            (_buffer.readUint8() & 0x3f) << 12 |
            (_buffer.readUint8() & 0x3f) << 6  |
            (_buffer.readUint8() & 0x3f);
          _length -= 3;
        }
      }
      result = abi.encodePacked(result, value);
    }
    return result;
  }
}
// File: contracts\libs\WitnetParserLib.sol
/// @title A library for decoding Witnet request results
/// @notice The library exposes functions to check the Witnet request success.
/// and retrieve Witnet results from CBOR values into solidity types.
/// @author The Witnet Foundation.
library WitnetParserLib {

    using WitnetDecoderLib for bytes;
    using WitnetDecoderLib for Witnet.CBOR;

    /// @notice Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes calldata _cborBytes)
        external pure
        returns (Witnet.Result memory)
    {
        Witnet.CBOR memory cborValue = _cborBytes.valueFromBytes();
        return resultFromCborValue(cborValue);
    }

    /// @notice Decode a CBOR value into a Witnet.Result instance.
    /// @param _cborValue An instance of `Witnet.Value`.
    /// @return A `Witnet.Result` instance.
    function resultFromCborValue(Witnet.CBOR memory _cborValue)
        public pure
        returns (Witnet.Result memory)    
    {
        // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
        // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
        bool success = _cborValue.tag != 39;
        return Witnet.Result(success, _cborValue);
    }

    /// @notice Tell if a Witnet.Result is successful.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if successful, `false` if errored.
    function isOk(Witnet.Result memory _result)
        external pure
        returns (bool)
    {
        return _result.success;
    }

    /// @notice Tell if a Witnet.Result is errored.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function isError(Witnet.Result memory _result)
      external pure
      returns (bool)
    {
        return !_result.success;
    }

    /// @notice Decode a bytes value from a Witnet.Result as a `bytes` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes` decoded from the Witnet.Result.
    function asBytes(Witnet.Result memory _result)
        external pure
        returns(bytes memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read bytes value from errored Witnet.Result");
        return _result.value.decodeBytes();
    }

    /// @notice Decode a bytes value from a Witnet.Result as a `bytes32` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes32` decoded from the Witnet.Result.
    function asBytes32(Witnet.Result memory _result)
        external pure
        returns(bytes32)
    {
        require(_result.success, "WitnetParserLib: tried to read bytes32 value from errored Witnet.Result");
        return _result.value.decodeBytes32();
    }

    /// @notice Decode an error code from a Witnet.Result as a member of `Witnet.ErrorCodes`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `CBORValue.Error memory` decoded from the Witnet.Result.
    function asErrorCode(Witnet.Result memory _result)
        external pure
        returns (Witnet.ErrorCodes)
    {
        uint64[] memory error = asRawError(_result);
        if (error.length == 0) {
            return Witnet.ErrorCodes.Unknown;
        }
        return _supportedErrorOrElseUnknown(error[0]);
    }

    /// @notice Generate a suitable error message for a member of `Witnet.ErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param _result An instance of `Witnet.Result`.
    /// @return A tuple containing the `CBORValue.Error memory` decoded from the `Witnet.Result`, plus a loggable error message.
    function asErrorMessage(Witnet.Result memory _result)
      public pure
      returns (Witnet.ErrorCodes, string memory)
    {
        uint64[] memory error = asRawError(_result);
        if (error.length == 0) {
            return (Witnet.ErrorCodes.Unknown, "Unknown error (no error code)");
        }
        Witnet.ErrorCodes errorCode = _supportedErrorOrElseUnknown(error[0]);
        bytes memory errorMessage;

        if (errorCode == Witnet.ErrorCodes.SourceScriptNotCBOR && error.length >= 2) {
            errorMessage = abi.encodePacked(
                "Source script #",
                _utoa(error[1]),
                " was not a valid CBOR value"
            );
        } else if (errorCode == Witnet.ErrorCodes.SourceScriptNotArray && error.length >= 2) {
            errorMessage = abi.encodePacked(
                "The CBOR value in script #",
                _utoa(error[1]),
                " was not an Array of calls"
            );
        } else if (errorCode == Witnet.ErrorCodes.SourceScriptNotRADON && error.length >= 2) {
            errorMessage = abi.encodePacked(
                "The CBOR value in script #",
                _utoa(error[1]),
                " was not a valid Data Request"
            );
        } else if (errorCode == Witnet.ErrorCodes.RequestTooManySources && error.length >= 2) {
            errorMessage = abi.encodePacked(
                "The request contained too many sources (", 
                _utoa(error[1]), 
                ")"
            );
        } else if (errorCode == Witnet.ErrorCodes.ScriptTooManyCalls && error.length >= 4) {
            errorMessage = abi.encodePacked(
                "Script #",
                _utoa(error[2]),
                " from the ",
                stageName(error[1]),
                " stage contained too many calls (",
                _utoa(error[3]),
                ")"
            );
        } else if (errorCode == Witnet.ErrorCodes.UnsupportedOperator && error.length >= 5) {
            errorMessage = abi.encodePacked(
                "Operator code 0x",
                _utohex(error[4]),
                " found at call #",
                _utoa(error[3]),
                " in script #",
                _utoa(error[2]),
                " from ",
                stageName(error[1]),
                " stage is not supported"
            );
        } else if (errorCode == Witnet.ErrorCodes.HTTP && error.length >= 3) {
            errorMessage = abi.encodePacked(
                "Source #",
                _utoa(error[1]),
                " could not be retrieved. Failed with HTTP error code: ",
                _utoa(error[2] / 100),
                _utoa(error[2] % 100 / 10),
                _utoa(error[2] % 10)
            );
        } else if (errorCode == Witnet.ErrorCodes.RetrievalTimeout && error.length >= 2) {
            errorMessage = abi.encodePacked(
                "Source #",
                _utoa(error[1]),
                " could not be retrieved because of a timeout"
            );
        } else if (errorCode == Witnet.ErrorCodes.Underflow && error.length >= 5) {
              errorMessage = abi.encodePacked(
                "Underflow at operator code 0x",
                _utohex(error[4]),
                " found at call #",
                _utoa(error[3]),
                " in script #",
                _utoa(error[2]),
                " from ",
                stageName(error[1]),
                " stage"
            );
        } else if (errorCode == Witnet.ErrorCodes.Overflow && error.length >= 5) {
            errorMessage = abi.encodePacked(
                "Overflow at operator code 0x",
                _utohex(error[4]),
                " found at call #",
                _utoa(error[3]),
                " in script #",
                _utoa(error[2]),
                " from ",
                stageName(error[1]),
                " stage"
            );
        } else if (errorCode == Witnet.ErrorCodes.DivisionByZero && error.length >= 5) {
            errorMessage = abi.encodePacked(
                "Division by zero at operator code 0x",
                _utohex(error[4]),
                " found at call #",
                _utoa(error[3]),
                " in script #",
                _utoa(error[2]),
                " from ",
                stageName(error[1]),
                " stage"
            );
        } else if (errorCode == Witnet.ErrorCodes.BridgeMalformedRequest) {
            errorMessage = "The structure of the request is invalid and it cannot be parsed";
        } else if (errorCode == Witnet.ErrorCodes.BridgePoorIncentives) {
            errorMessage = "The request has been rejected by the bridge node due to poor incentives";
        } else if (errorCode == Witnet.ErrorCodes.BridgeOversizedResult) {
            errorMessage = "The request result length exceeds a bridge contract defined limit";
        } else {
            errorMessage = abi.encodePacked("Unknown error (0x", _utohex(error[0]), ")");
        }
        return (errorCode, string(errorMessage));
    }

    /// @notice Decode a raw error from a `Witnet.Result` as a `uint64[]`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `uint64[]` raw error as decoded from the `Witnet.Result`.
    function asRawError(Witnet.Result memory _result)
        public pure
        returns(uint64[] memory)
    {
        require(
            !_result.success,
            "WitnetParserLib: Tried to read error code from successful Witnet.Result"
        );
        return _result.value.decodeUint64Array();
    }

    /// @notice Decode a boolean value from a Witnet.Result as an `bool` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bool` decoded from the Witnet.Result.
    function asBool(Witnet.Result memory _result)
        external pure
        returns (bool)
    {
        require(_result.success, "WitnetParserLib: Tried to read `bool` value from errored Witnet.Result");
        return _result.value.decodeBool();
    }

    /// @notice Decode a fixed16 (half-precision) numeric value from a Witnet.Result as an `int32` value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asFixed16(Witnet.Result memory _result)
        external pure
        returns (int32)
    {
        require(_result.success, "WitnetParserLib: Tried to read `fixed16` value from errored Witnet.Result");
        return _result.value.decodeFixed16();
    }

    /// @notice Decode an array of fixed16 values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asFixed16Array(Witnet.Result memory _result)
        external pure
        returns (int32[] memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `fixed16[]` value from errored Witnet.Result");
        return _result.value.decodeFixed16Array();
    }

    /// @notice Decode a integer numeric value from a Witnet.Result as an `int128` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asInt128(Witnet.Result memory _result)
      external pure
      returns (int128)
    {
        require(_result.success, "WitnetParserLib: Tried to read `int128` value from errored Witnet.Result");
        return _result.value.decodeInt128();
    }

    /// @notice Decode an array of integer numeric values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asInt128Array(Witnet.Result memory _result)
        external pure
        returns (int128[] memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `int128[]` value from errored Witnet.Result");
        return _result.value.decodeInt128Array();
    }

    /// @notice Decode a string value from a Witnet.Result as a `string` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asString(Witnet.Result memory _result)
        external pure
        returns(string memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `string` value from errored Witnet.Result");
        return _result.value.decodeString();
    }

    /// @notice Decode an array of string values from a Witnet.Result as a `string[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asStringArray(Witnet.Result memory _result)
        external pure
        returns (string[] memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `string[]` value from errored Witnet.Result");
        return _result.value.decodeStringArray();
    }

    /// @notice Decode a natural numeric value from a Witnet.Result as a `uint64` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64` decoded from the Witnet.Result.
    function asUint64(Witnet.Result memory _result)
        external pure
        returns(uint64)
    {
        require(_result.success, "WitnetParserLib: Tried to read `uint64` value from errored Witnet.Result");
        return _result.value.decodeUint64();
    }

    /// @notice Decode an array of natural numeric values from a Witnet.Result as a `uint64[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64[]` decoded from the Witnet.Result.
    function asUint64Array(Witnet.Result memory _result)
        external pure
        returns (uint64[] memory)
    {
        require(_result.success, "WitnetParserLib: Tried to read `uint64[]` value from errored Witnet.Result");
        return _result.value.decodeUint64Array();
    }

    /// @notice Convert a stage index number into the name of the matching Witnet request stage.
    /// @param _stageIndex A `uint64` identifying the index of one of the Witnet request stages.
    /// @return The name of the matching stage.
    function stageName(uint64 _stageIndex)
        public pure
        returns (string memory)
    {
        if (_stageIndex == 0) {
            return "retrieval";
        } else if (_stageIndex == 1) {
            return "aggregation";
        } else if (_stageIndex == 2) {
            return "tally";
        } else {
            return "unknown";
        }
    }

    /// @notice Get an `Witnet.ErrorCodes` item from its `uint64` discriminant.
    /// @param _discriminant The numeric identifier of an error.
    /// @return A member of `Witnet.ErrorCodes`.
    function _supportedErrorOrElseUnknown(uint64 _discriminant)
        private pure
        returns (Witnet.ErrorCodes)
    {
        return Witnet.ErrorCodes(_discriminant);
    }

    /// @notice Convert a `uint64` into a 1, 2 or 3 characters long `string` representing its.
    /// three less significant decimal values.
    /// @param _u A `uint64` value.
    /// @return The `string` representing its decimal value.
    function _utoa(uint64 _u)
        private pure
        returns (string memory)
    {
        if (_u < 10) {
            bytes memory b1 = new bytes(1);
            b1[0] = bytes1(uint8(_u) + 48);
            return string(b1);
        } else if (_u < 100) {
            bytes memory b2 = new bytes(2);
            b2[0] = bytes1(uint8(_u / 10) + 48);
            b2[1] = bytes1(uint8(_u % 10) + 48);
            return string(b2);
        } else {
            bytes memory b3 = new bytes(3);
            b3[0] = bytes1(uint8(_u / 100) + 48);
            b3[1] = bytes1(uint8(_u % 100 / 10) + 48);
            b3[2] = bytes1(uint8(_u % 10) + 48);
            return string(b3);
        }
    }

    /// @notice Convert a `uint64` into a 2 characters long `string` representing its two less significant hexadecimal values.
    /// @param _u A `uint64` value.
    /// @return The `string` representing its hexadecimal value.
    function _utohex(uint64 _u)
        private pure
        returns (string memory)
    {
        bytes memory b2 = new bytes(2);
        uint8 d0 = uint8(_u / 16) + 48;
        uint8 d1 = uint8(_u % 16) + 48;
        if (d0 > 57)
            d0 += 7;
        if (d1 > 57)
            d1 += 7;
        b2[0] = bytes1(d0);
        b2[1] = bytes1(d1);
        return string(b2);
    }
}
// File: contracts\interfaces\IERC20.sol
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /// Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// Returns the amount of tokens owned by `_account`.
    function balanceOf(address _account) external view returns (uint256);

    /// Moves `_amount` tokens from the caller's account to `_recipient`.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// Emits a {Transfer} event.
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    /// Returns the remaining number of tokens that `_spender` will be
    /// allowed to spend on behalf of `_owner` through {transferFrom}. This is
    /// zero by default.
    /// This value changes when {approve} or {transferFrom} are called.
    function allowance(address _owner, address _spender) external view returns (uint256);

    /// Sets `_amount` as the allowance of `_spender` over the caller's tokens.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// 
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk
    /// that someone may use both the old and the new allowance by unfortunate
    /// transaction ordering. One possible solution to mitigate this race
    /// condition is to first reduce the spender's allowance to 0 and set the
    /// desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Emits an {Approval} event.     
    function approve(address _spender, uint256 _amount) external returns (bool);

    /// Moves `amount` tokens from `_sender` to `_recipient` using the
    /// allowance mechanism. `amount` is then deducted from the caller's
    /// allowance.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// Emits a {Transfer} event. 
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    /// Emitted when `value` tokens are moved from one account (`from`) to
    /// another (`to`).
    /// Note that `:value` may be zero.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// Emitted when the allowance of a `spender` for an `owner` is set by
    /// a call to {approve}. `value` is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts\patterns\Payable.sol
abstract contract Payable {
    IERC20 public immutable currency;

    event Received(address from, uint256 amount);
    event Transfer(address to, uint256 amount);

    constructor(address _currency) {
        currency = IERC20(_currency);
    }

    /// Gets current transaction price.
    function _getGasPrice() internal view virtual returns (uint256);

    /// Gets current payment value.
    function _getMsgValue() internal view virtual returns (uint256);

    /// Perform safe transfer or whatever token is used for paying rewards.
    function _safeTransferTo(address payable, uint256) internal virtual;
}
// File: contracts\impls\trustable\WitnetRequestBoardTrustableBase.sol
/// @title Witnet Request Board "trustable" base implementation contract.
/// @notice Contract to bridge requests to Witnet Decentralized Oracle Network.
/// @dev This contract enables posting requests that Witnet bridges will insert into the Witnet network.
/// The result of the requests will be posted back to this contract by the bridge nodes too.
/// @author The Witnet Foundation
abstract contract WitnetRequestBoardTrustableBase
    is 
        Payable,
        IWitnetRequestBoardAdmin,
        IWitnetRequestBoardAdminACLs,        
        WitnetBoardDataACLs,
        WitnetRequestBoardUpgradableBase        
{
    using Witnet for bytes;
    using WitnetParserLib for Witnet.Result;
    
    constructor(bool _upgradable, bytes32 _versionTag, address _currency)
        Payable(_currency)
        WitnetRequestBoardUpgradableBase(_upgradable, _versionTag)
    {}


    // ================================================================================================================
    // --- Overrides 'Upgradable' -------------------------------------------------------------------------------------

    /// Initialize storage-context when invoked as delegatecall. 
    /// @dev Must fail when trying to initialize same instance more than once.
    function initialize(bytes memory _initData) virtual external override {
        address _owner = _state().owner;
        if (_owner == address(0)) {
            // set owner if none set yet
            _owner = msg.sender;
            _state().owner = _owner;
        } else {
            // only owner can initialize:
            require(msg.sender == _owner, "WitnetRequestBoardTrustableBase: only owner");
        }        

        if (_state().base != address(0)) {
            // current implementation cannot be initialized more than once:
            require(_state().base != base(), "WitnetRequestBoardTrustableBase: already initialized");
        }        
        _state().base = base();

        emit Upgraded(msg.sender, base(), codehash(), version());

        // Do actual base initialization:
        setReporters(abi.decode(_initData, (address[])));
    }

    /// Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address _from) external view override returns (bool) {
        address _owner = _state().owner;
        return (
            // false if the WRB is intrinsically not upgradable, or `_from` is no owner
            isUpgradable()
                && _owner == _from
        );
    }


    // ================================================================================================================
    // --- Full implementation of 'IWitnetRequestBoardAdmin' ----------------------------------------------------------

    /// Gets admin/owner address.
    function owner()
        public view
        override
        returns (address)
    {
        return _state().owner;
    }

    /// Transfers ownership.
    function transferOwnership(address _newOwner)
        external
        virtual override
        onlyOwner
    {
        address _owner = _state().owner;
        if (_newOwner != _owner) {
            _state().owner = _newOwner;
            emit OwnershipTransferred(_owner, _newOwner);
        }
    }


    // ================================================================================================================
    // --- Full implementation of 'IWitnetRequestBoardAdminACLs' ------------------------------------------------------

    /// Tells whether given address is included in the active reporters control list.
    /// @param _reporter The address to be checked.
    function isReporter(address _reporter) public view override returns (bool) {
        return _acls().isReporter_[_reporter];
    }

    /// Adds given addresses to the active reporters control list.
    /// @dev Can only be called from the owner address.
    /// @dev Emits the `ReportersSet` event. 
    /// @param _reporters List of addresses to be added to the active reporters control list.
    function setReporters(address[] memory _reporters)
        public
        override
        onlyOwner
    {
        for (uint ix = 0; ix < _reporters.length; ix ++) {
            address _reporter = _reporters[ix];
            _acls().isReporter_[_reporter] = true;
        }
        emit ReportersSet(_reporters);
    }

    /// Removes given addresses from the active reporters control list.
    /// @dev Can only be called from the owner address.
    /// @dev Emits the `ReportersUnset` event. 
    /// @param _exReporters List of addresses to be added to the active reporters control list.
    function unsetReporters(address[] memory _exReporters)
        public
        override
        onlyOwner
    {
        for (uint ix = 0; ix < _exReporters.length; ix ++) {
            address _reporter = _exReporters[ix];
            _acls().isReporter_[_reporter] = false;
        }
        emit ReportersUnset(_exReporters);
    }


    // ================================================================================================================
    // --- Full implementation of 'IWitnetRequestBoardReporter' -------------------------------------------------------

    /// Reports the Witnet-provided result to a previously posted request. 
    /// @dev Will assume `block.timestamp` as the timestamp at which the request was solved.
    /// @dev Fails if:
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique identifier of the data request.
    /// @param _drTxHash The hash of the solving tally transaction in Witnet.
    /// @param _cborBytes The result itself as bytes.
    function reportResult(
            uint256 _queryId,
            bytes32 _drTxHash,
            bytes calldata _cborBytes
        )
        external
        override
        onlyReporters
        inStatus(_queryId, Witnet.QueryStatus.Posted)
    {
        // solhint-disable not-rely-on-time
        _reportResult(_queryId, block.timestamp, _drTxHash, _cborBytes);
    }

    /// Reports the Witnet-provided result to a previously posted request.
    /// @dev Fails if:
    /// @dev - called from unauthorized address;
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique query identifier
    /// @param _timestamp The timestamp of the solving tally transaction in Witnet.
    /// @param _drTxHash The hash of the solving tally transaction in Witnet.
    /// @param _cborBytes The result itself as bytes.
    function reportResult(
            uint256 _queryId,
            uint256 _timestamp,
            bytes32 _drTxHash,
            bytes calldata _cborBytes
        )
        external
        override
        onlyReporters
        inStatus(_queryId, Witnet.QueryStatus.Posted)
    {
        _reportResult(_queryId, _timestamp, _drTxHash, _cborBytes);
    }
    

    // ================================================================================================================
    // --- Full implementation of 'IWitnetRequestBoardRequestor' ------------------------------------------------------

    /// Retrieves copy of all response data related to a previously posted request, removing the whole query from storage.
    /// @dev Fails if the `_queryId` is not in 'Reported' status, or called from an address different to
    /// @dev the one that actually posted the given request.
    /// @param _queryId The unique query identifier.
    function deleteQuery(uint256 _queryId)
        public
        virtual override
        inStatus(_queryId, Witnet.QueryStatus.Reported)
        returns (Witnet.Response memory _response)
    {
        Witnet.Query storage __query = _state().queries[_queryId];
        require(
            msg.sender == __query.from
                // (avoids breaking change when upgrading from 0.5.3 to 0.5.4)
                || msg.sender == __query.request.requester,
            "WitnetRequestBoardTrustableBase: only requester"
        );
        _response = __query.response;
        delete _state().queries[_queryId];
        emit DeletedQuery(_queryId, msg.sender);
    }

    /// Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @dev - provided script is zero address.
    /// @dev - provided script bytecode is empty.
    /// @param _addr The address of a IWitnetRequest contract, containing the actual Data Request seralized bytecode.
    /// @return _queryId An unique query identifier.
    function postRequest(IWitnetRequest _addr)
        public payable
        virtual override
        returns (uint256 _queryId)
    {
        uint256 _value = _getMsgValue();
        uint256 _gasPrice = _getGasPrice();

        // Checks the tally reward is covering gas cost
        uint256 minResultReward = estimateReward(_gasPrice);
        require(_value >= minResultReward, "WitnetRequestBoardTrustableBase: reward too low");

        // Validates provided script:
        require(address(_addr) != address(0), "WitnetRequestBoardTrustableBase: null script");
        bytes memory _bytecode = _addr.bytecode();
        require(_bytecode.length > 0, "WitnetRequestBoardTrustableBase: empty script");

        _queryId = ++ _state().numQueries;
        _state().queries[_queryId].from = msg.sender;

        Witnet.Request storage _request = _getRequestData(_queryId);
        _request.addr = _addr;
        _request.hash = _bytecode.hash();
        _request.gasprice = _gasPrice;
        _request.reward = _value;

        // Let observers know that a new request has been posted
        emit PostedRequest(_queryId, msg.sender);
    }
    
    /// Increments the reward of a previously posted request by adding the transaction value to it.
    /// @dev Updates request `gasPrice` in case this method is called with a higher 
    /// @dev gas price value than the one used in previous calls to `postRequest` or
    /// @dev `upgradeReward`. 
    /// @dev Fails if the `_queryId` is not in 'Posted' status.
    /// @dev Fails also in case the request `gasPrice` is increased, and the new 
    /// @dev reward value gets below new recalculated threshold. 
    /// @param _queryId The unique query identifier.
    function upgradeReward(uint256 _queryId)
        public payable
        virtual override      
        inStatus(_queryId, Witnet.QueryStatus.Posted)
    {
        Witnet.Request storage _request = _getRequestData(_queryId);

        uint256 _newReward = _request.reward + _getMsgValue();
        uint256 _newGasPrice = _getGasPrice();

        // If gas price is increased, then check if new rewards cover gas costs
        if (_newGasPrice > _request.gasprice) {
            // Checks the reward is covering gas cost
            uint256 _minResultReward = estimateReward(_newGasPrice);
            require(
                _newReward >= _minResultReward,
                "WitnetRequestBoardTrustableBase: reward too low"
            );
            _request.gasprice = _newGasPrice;
        }
        _request.reward = _newReward;
    }


    // ================================================================================================================
    // --- Full implementation of 'IWitnetRequestBoardView' -----------------------------------------------------------

    /// Estimates the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the rewards.
    function estimateReward(uint256 _gasPrice)
        public view
        virtual override
        returns (uint256);

    /// Returns next request id to be generated by the Witnet Request Board.
    function getNextQueryId()
        external view 
        override
        returns (uint256)
    {
        return _state().numQueries + 1;
    }

    /// Gets the whole Query data contents, if any, no matter its current status.
    function getQueryData(uint256 _queryId)
      external view
      override
      returns (Witnet.Query memory)
    {
        return _state().queries[_queryId];
    }

    /// Gets current status of given query.
    function getQueryStatus(uint256 _queryId)
        external view
        override
        returns (Witnet.QueryStatus)
    {
        return _getQueryStatus(_queryId);

    }

    /// Retrieves the whole Request record posted to the Witnet Request Board.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been reported
    /// @dev or deleted.
    /// @param _queryId The unique identifier of a previously posted query.
    function readRequest(uint256 _queryId)
        external view
        override
        inStatus(_queryId, Witnet.QueryStatus.Posted)
        returns (Witnet.Request memory _request)
    {
        Witnet.Query storage __query = _state().queries[_queryId];
        _request = __query.request;
        if (__query.from != address(0)) {
            _request.requester = __query.from;
        }
    }
    
    /// Retrieves the serialized bytecode of a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid, or if the related script bytecode 
    /// @dev got changed after being posted. Returns empty array once it gets reported, 
    /// @dev or deleted.
    /// @param _queryId The unique query identifier.
    function readRequestBytecode(uint256 _queryId)
        external view
        override
        returns (bytes memory _bytecode)
    {
        require(
            _getQueryStatus(_queryId) != Witnet.QueryStatus.Unknown,
            "WitnetRequestBoardTrustableBase: not yet posted"
        );
        Witnet.Request storage _request = _getRequestData(_queryId);
        if (address(_request.addr) != address(0)) {
            // if DR's request contract address is not zero,
            // we assume the DR has not been deleted, so
            // DR's bytecode can still be fetched:
            _bytecode = _request.addr.bytecode();
            require(
                _bytecode.hash() == _request.hash,
                "WitnetRequestBoardTrustableBase: bytecode changed after posting"
            );
        } 
    }

    /// Retrieves the gas price that any assigned reporter will have to pay when reporting 
    /// result to a previously posted Witnet data request.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifier
    function readRequestGasPrice(uint256 _queryId)
        external view
        override
        inStatus(_queryId, Witnet.QueryStatus.Posted)
        returns (uint256)
    {
        return _state().queries[_queryId].request.gasprice;
    }

    /// Retrieves the reward currently set for a previously posted request.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifier
    function readRequestReward(uint256 _queryId)
        external view
        override
        inStatus(_queryId, Witnet.QueryStatus.Posted)
        returns (uint256)
    {
        return _state().queries[_queryId].request.reward;
    }

    /// Retrieves the Witnet-provided result, and metadata, to a previously posted request.    
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier
    function readResponse(uint256 _queryId)
        external view
        override
        inStatus(_queryId, Witnet.QueryStatus.Reported)
        returns (Witnet.Response memory _response)
    {
        return _getResponseData(_queryId);
    }

    /// Retrieves the hash of the Witnet transaction that actually solved the referred query.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseDrTxHash(uint256 _queryId)
        external view        
        override
        inStatus(_queryId, Witnet.QueryStatus.Reported)
        returns (bytes32)
    {
        return _getResponseData(_queryId).drTxHash;
    }

    /// Retrieves the address that reported the result to a previously-posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier
    function readResponseReporter(uint256 _queryId)
        external view
        override
        inStatus(_queryId, Witnet.QueryStatus.Reported)
        returns (address)
    {
        return _getResponseData(_queryId).reporter;
    }

    /// Retrieves the Witnet-provided CBOR-bytes result of a previously posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier
    function readResponseResult(uint256 _queryId)
        external view
        override
        inStatus(_queryId, Witnet.QueryStatus.Reported)
        returns (Witnet.Result memory)
    {
        Witnet.Response storage _response = _getResponseData(_queryId);
        return WitnetParserLib.resultFromCborBytes(_response.cborBytes);
    }

    /// Retrieves the timestamp in which the result to the referred query was solved by the Witnet DON.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseTimestamp(uint256 _queryId)
        external view
        override
        inStatus(_queryId, Witnet.QueryStatus.Reported)
        returns (uint256)
    {
        return _getResponseData(_queryId).timestamp;
    }


    // ================================================================================================================
    // --- Full implementation of 'IWitnetRequestParser' interface ----------------------------------------------------

    /// Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory _cborBytes)
        external pure
        override
        returns (Witnet.Result memory)
    {
        return WitnetParserLib.resultFromCborBytes(_cborBytes);
    }

    /// Decode a CBOR value into a Witnet.Result instance.
    /// @param _cborValue An instance of `Witnet.CBOR`.
    /// @return A `Witnet.Result` instance.
    function resultFromCborValue(Witnet.CBOR memory _cborValue)
        external pure
        override
        returns (Witnet.Result memory)
    {
        return WitnetParserLib.resultFromCborValue(_cborValue);
    }

    /// Tell if a Witnet.Result is successful.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if successful, `false` if errored.
    function isOk(Witnet.Result memory _result)
        external pure
        override
        returns (bool)
    {
        return _result.isOk();
    }

    /// Tell if a Witnet.Result is errored.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function isError(Witnet.Result memory _result)
        external pure
        override
        returns (bool)
    {
        return _result.isError();
    }

    /// Decode a bytes value from a Witnet.Result as a `bytes` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes` decoded from the Witnet.Result.
    function asBytes(Witnet.Result memory _result)
        external pure
        override
        returns (bytes memory)
    {
        return _result.asBytes();
    }

    /// Decode a bytes value from a Witnet.Result as a `bytes32` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes32` decoded from the Witnet.Result.
    function asBytes32(Witnet.Result memory _result)
        external pure
        override
        returns (bytes32)
    {
        return _result.asBytes32();
    }

    /// Decode an error code from a Witnet.Result as a member of `Witnet.ErrorCodes`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `CBORValue.Error memory` decoded from the Witnet.Result.
    function asErrorCode(Witnet.Result memory _result)
        external pure
        override
        returns (Witnet.ErrorCodes)
    {
        return _result.asErrorCode();
    }

    /// Generate a suitable error message for a member of `Witnet.ErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param _result An instance of `Witnet.Result`.
    /// @return A tuple containing the `CBORValue.Error memory` decoded from the `Witnet.Result`, plus a loggable error message.
    function asErrorMessage(Witnet.Result memory _result)
        external pure
        override
        returns (Witnet.ErrorCodes, string memory)
    {
        try _result.asErrorMessage() returns (Witnet.ErrorCodes _code, string memory _message) {
            return (_code, _message);
        } 
        catch Error(string memory _reason) {
            return (Witnet.ErrorCodes.Unknown, _reason);
        }
        catch (bytes memory) {
            return (Witnet.ErrorCodes.UnhandledIntercept, "WitnetRequestBoardTrustableBase: failing assert");
        }
    }

    /// Decode a raw error from a `Witnet.Result` as a `uint64[]`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `uint64[]` raw error as decoded from the `Witnet.Result`.
    function asRawError(Witnet.Result memory _result)
        external pure
        override
        returns(uint64[] memory)
    {
        return _result.asRawError();
    }

    /// Decode a boolean value from a Witnet.Result as an `bool` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bool` decoded from the Witnet.Result.
    function asBool(Witnet.Result memory _result)
        external pure
        override
        returns (bool)
    {
        return _result.asBool();
    }

    /// Decode a fixed16 (half-precision) numeric value from a Witnet.Result as an `int32` value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asFixed16(Witnet.Result memory _result)
        external pure
        override
        returns (int32)
    {
        return _result.asFixed16();
    }

    /// Decode an array of fixed16 values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asFixed16Array(Witnet.Result memory _result)
        external pure
        override
        returns (int32[] memory)
    {
        return _result.asFixed16Array();
    }

    /// Decode a integer numeric value from a Witnet.Result as an `int128` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asInt128(Witnet.Result memory _result)
        external pure
        override
        returns (int128)
    {
        return _result.asInt128();
    }

    /// Decode an array of integer numeric values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asInt128Array(Witnet.Result memory _result)
        external pure
        override
        returns (int128[] memory)
    {
        return _result.asInt128Array();
    }

    /// Decode a string value from a Witnet.Result as a `string` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asString(Witnet.Result memory _result)
        external pure
        override
        returns (string memory)
    {
        return _result.asString();
    }

    /// Decode an array of string values from a Witnet.Result as a `string[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asStringArray(Witnet.Result memory _result)
        external pure
        override
        returns (string[] memory)
    {
        return _result.asStringArray();
    }

    /// Decode a natural numeric value from a Witnet.Result as a `uint64` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64` decoded from the Witnet.Result.
    function asUint64(Witnet.Result memory _result)
        external pure 
        override
        returns(uint64)
    {
        return _result.asUint64();
    }

    /// Decode an array of natural numeric values from a Witnet.Result as a `uint64[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64[]` decoded from the Witnet.Result.
    function asUint64Array(Witnet.Result memory _result)
        external pure
        override
        returns (uint64[] memory)
    {
        return _result.asUint64Array();
    }


    // ================================================================================================================
    // --- Internal functions -----------------------------------------------------------------------------------------

    function _reportResult(
            uint256 _queryId,
            uint256 _timestamp,
            bytes32 _drTxHash,
            bytes memory _cborBytes
        )
        internal
    {
        require(_drTxHash != 0, "WitnetRequestBoardTrustableDefault: Witnet drTxHash cannot be zero");
        // Ensures the result byes do not have zero length
        // This would not be a valid encoding with CBOR and could trigger a reentrancy attack
        require(_cborBytes.length != 0, "WitnetRequestBoardTrustableDefault: result cannot be empty");

        Witnet.Query storage __query = _state().queries[_queryId];
        Witnet.Response storage __response = __query.response;

        // solhint-disable not-rely-on-time
        __response.timestamp = _timestamp;
        __response.drTxHash = _drTxHash;
        __response.reporter = msg.sender;
        __response.cborBytes = _cborBytes;

        _safeTransferTo(payable(msg.sender), __query.request.reward);
        emit PostedResult(_queryId, msg.sender);

        __query.request.addr = IWitnetRequest(address(0));
        __query.request.hash = 0;
        __query.request.gasprice = 0;
        __query.request.reward = 0;
    }
}
// File: contracts\patterns\Destructible.sol
interface Destructible {
    /// @dev Self-destruct the whole contract.
    function destruct() external;
}
// File: contracts\impls\trustable\WitnetRequestBoardTrustableDefault.sol
/* solhint-disable var-name-mixedcase */




/// @title Witnet Request Board "trustable" implementation contract.
/// @notice Contract to bridge requests to Witnet Decentralized Oracle Network.
/// @dev This contract enables posting requests that Witnet bridges will insert into the Witnet network.
/// The result of the requests will be posted back to this contract by the bridge nodes too.
/// @author The Witnet Foundation
contract WitnetRequestBoardTrustableDefault
    is 
        Destructible,
        WitnetRequestBoardTrustableBase
{  
    uint256 internal immutable _ESTIMATED_REPORT_RESULT_GAS;

    constructor(
        bool _upgradable,
        bytes32 _versionTag,
        uint256 _reportResultGasLimit
    )
        WitnetRequestBoardTrustableBase(_upgradable, _versionTag, address(0))
    {
        _ESTIMATED_REPORT_RESULT_GAS = _reportResultGasLimit;
    }


    // ================================================================================================================
    // --- Overrides implementation of 'IWitnetRequestBoardView' ------------------------------------------------------

    /// Estimates the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the rewards.
    function estimateReward(uint256 _gasPrice)
        public view
        virtual override
        returns (uint256)
    {
        return _gasPrice * _ESTIMATED_REPORT_RESULT_GAS;
    }


    // ================================================================================================================
    // --- Overrides 'Destructible' -----------------------------------------------------------------------------------

    /// Destroys current instance. Only callable by the owner.
    function destruct() external override onlyOwner {
        selfdestruct(payable(msg.sender));
    }


    // ================================================================================================================
    // --- Overrides 'Payable' ----------------------------------------------------------------------------------------

    /// Gets current transaction price.
    function _getGasPrice()
        internal view
        override
        returns (uint256)
    {
        return tx.gasprice;
    }

    /// Gets current payment value.
    function _getMsgValue()
        internal view
        override
        returns (uint256)
    {
        return msg.value;
    }

    /// Transfers ETHs to given address.
    /// @param _to Recipient address.
    /// @param _amount Amount of ETHs to transfer.
    function _safeTransferTo(address payable _to, uint256 _amount)
        internal
        override
    {
        payable(_to).transfer(_amount);
    }   
}