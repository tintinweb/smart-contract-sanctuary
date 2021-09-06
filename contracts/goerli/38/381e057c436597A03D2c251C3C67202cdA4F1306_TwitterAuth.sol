// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// Import the UsingWitnet library that enables interacting with Witnet
import "witnet-ethereum-bridge/contracts/UsingWitnet.sol";
// Import the WitnetRequest contract that enables creating requests on the spot
import "witnet-ethereum-bridge/contracts/requests/WitnetRequest.sol";

/// Linking Twitter user to Ethereum address using the Twitter oracle
/// @author Rick
contract TwitterAuth is UsingWitnet {
  struct User {
    string twitterId;
    uint256 witnetQueryId;
  }

  mapping(address => User) public users;

  event ResultError(string msg);

  constructor(WitnetRequestBoard _wrb) UsingWitnet(_wrb) {}

  /// Check whether the twitter id is not being checked yet.
  modifier notChecked() {
    require(
      users[msg.sender].witnetQueryId == 0,
      "TwitterAuth: Twitter ID is already requested"
    );
    _;
  }

  /// Check whether the twitter id has already been requested.
  modifier checked() {
    require(
      users[msg.sender].witnetQueryId > 0,
      "TwitterAuth: Twitter ID needs to be requested"
    );
    _;
  }

  /// Check whether there is a pending update.
  modifier notPending() {
    require(
      _witnetCheckResultAvailability(users[msg.sender].witnetQueryId),
      "TwitterAuth: Twitter ID is currently being requested"
    );
    _;
  }

  /// Sends a data request to Witnet so as to get the Twitter user id linked to the sender address
  function checkTwitterID(string calldata _TweetId)
    external
    payable
    notChecked
  {
    WitnetRequest request = new WitnetRequest(
      bytes(
        abi.encodePacked(
          hex"0a6408c3d4d789061246123768747470733a2f2f6170692d6d6964646c6577617265732e76657263656c2e6170702f6170692f747769747465722f7477656574732f",
          _TweetId,
          hex"1a0b82187782186164617574681a090a050808120180100222090a050808120180100210c0843d186420e80728333080c8afa025"
        )
      )
    );

    // Keerp track of the Witnet query ID
    users[msg.sender].witnetQueryId = _witnetPostRequest(request);
  }

  function deleteTwitterID() external checked {
    users[msg.sender].witnetQueryId = 0;
    users[msg.sender].twitterId = "";
  }

  function getTwitterID() public notPending checked {
    //Extracting data
    Witnet.Result memory result = _witnetReadResult(
      users[msg.sender].witnetQueryId
    );

    if (witnet.isOk(result)) {
      // We got a valid id!
      string[] memory values = witnet.asStringArray(result);
      if (compareAddress(values[1], msg.sender)) {
        users[msg.sender].twitterId = values[0];
      } else {
        users[msg.sender].witnetQueryId = 0;
        emit ResultError("Address is not matching");
      }
    } else {
      string memory errorMessage;
      // Try to read the value as an error message, catch error bytes if read fails
      try witnet.asErrorMessage(result) returns (
        Witnet.ErrorCodes,
        string memory e
      ) {
        errorMessage = e;
      } catch (bytes memory errorBytes) {
        errorMessage = string(errorBytes);
      }

      // The Witnet query failed. Set query ID to 0 so it can be retried using `checkLikes()` again
      users[msg.sender].witnetQueryId = 0;
      emit ResultError(errorMessage);
    }
  }

  function compareAddress(string memory _addressStr, address _address)
    internal
    pure
    returns (bool)
  {
    bool matching = (keccak256(abi.encodePacked(_addressStr)) ==
      keccak256(abi.encodePacked(toAsciiString(_address))));
    return matching;
  }

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
    }
    return string(abi.encodePacked("0x", s));
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetRequestBoard.sol";

/// @title The UsingWitnet contract
/// @dev Witnet-aware contracts can inherit from this contract in order to interact with Witnet.
/// @author The Witnet Foundation.
abstract contract UsingWitnet {

    WitnetRequestBoard public immutable witnet;

    /// Include an address to specify the WitnetRequestBoard entry point address.
    /// @param _wrb The WitnetRequestBoard entry point address.
    constructor(WitnetRequestBoard _wrb)
    {
        require(address(_wrb) != address(0), "UsingWitnet: zero address");
        witnet = _wrb;
    }

    /// Provides a convenient way for client contracts extending this to block the execution of the main logic of the
    /// contract until a particular request has been successfully solved and reported by Witnet.
    modifier witnetRequestSolved(uint256 _id) {
        require(
                _witnetCheckResultAvailability(_id),
                "UsingWitnet: request not solved"
            );
        _;
    }

    /// Check if a data request has been solved and reported by Witnet.
    /// @dev Contracts depending on Witnet should not start their main business logic (e.g. receiving value from third.
    /// parties) before this method returns `true`.
    /// @param _id The unique identifier of a previously posted data request.
    /// @return A boolean telling if the request has been already resolved or not. Returns `false` also, if the result was deleted.
    function _witnetCheckResultAvailability(uint256 _id)
        internal view
        returns (bool)
    {
        return witnet.getQueryStatus(_id) == Witnet.QueryStatus.Reported;
    }

    /// Estimate the reward amount.
    /// @param _gasPrice The gas price for which we want to retrieve the estimation.
    /// @return The reward to be included for the given gas price.
    function _witnetEstimateReward(uint256 _gasPrice)
        internal view
        returns (uint256)
    {
        return witnet.estimateReward(_gasPrice);
    }

    /// Send a new request to the Witnet network with transaction value as a reward.
    /// @param _request An instance of `IWitnetRequest` contract.
    /// @return Sequential identifier for the request included in the WitnetRequestBoard.
    function _witnetPostRequest(IWitnetRequest _request)
        internal
        returns (uint256)
    {
        return witnet.postRequest{value: msg.value}(_request);
    }

    /// Upgrade the reward for a previously posted request.
    /// @dev Call to `upgradeReward` function in the WitnetRequestBoard contract.
    /// @param _id The unique identifier of a request that has been previously sent to the WitnetRequestBoard.
    function _witnetUpgradeReward(uint256 _id)
        internal
    {
        witnet.upgradeReward{value: msg.value}(_id);
    }

    /// Read the Witnet-provided result to a previously posted request.
    /// @param _id The unique identifier of a request that was posted to Witnet.
    /// @return The result of the request as an instance of `Witnet.Result`.
    function _witnetReadResult(uint256 _id)
        internal view
        returns (Witnet.Result memory)
    {
        return witnet.readResponseResult(_id);
    }

    /// Retrieves copy of all response data related to a previously posted request, removing the whole query from storage.
    /// @param _id The unique identifier of a previously posted request.
    /// @return The Witnet-provided result to the request.
    function _witnetDeleteQuery(uint256 _id)
        internal
        returns (Witnet.Response memory)
    {
        return witnet.deleteQuery(_id);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IWitnetRequestBoardEvents.sol";
import "./interfaces/IWitnetRequestBoardReporter.sol";
import "./interfaces/IWitnetRequestBoardRequestor.sol";
import "./interfaces/IWitnetRequestBoardView.sol";
import "./interfaces/IWitnetRequestParser.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    /// A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

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

    /// Retrieves the whole `Witnet.Request` record referred to a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid or, if it has been deleted,
    /// @dev or if the related script bytecode got changed after being posted.
    /// @param _queryId The unique query identifier.
    function readRequest(uint256 _queryId) external view returns (Witnet.Request memory);

    /// Retrieves the serialized bytecode of a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid or, if it has been deleted,
    /// @dev or if the related script bytecode got changed after being posted.
    /// @param _queryId The unique query identifier.
    function readRequestBytecode(uint256 _queryId) external view returns (bytes memory);

    /// Retrieves the gas price that any assigned reporter will have to pay when reporting result 
    /// to the referred query.
    /// @dev Fails if the `_queryId` is not valid or, if it has been deleted,
    /// @dev or if the related script bytecode got changed after being posted.
    /// @param _queryId The unique query identifier.
    function readRequestGasPrice(uint256 _queryId) external view returns (uint256);

    /// Retrieves the reward currently set for the referred query.
    /// @dev Fails if the `_queryId` is not valid or, if it has been deleted,
    /// @dev or if the related script bytecode got changed after being posted.
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../libs/Witnet.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IWitnetRequest.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./WitnetRequestBase.sol";

contract WitnetRequest
    is
        WitnetRequestBase
{
    using Witnet for bytes;
    constructor(bytes memory _bytecode) {
        bytecode = _bytecode;
        hash = _bytecode.hash();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "../libs/Witnet.sol";

abstract contract WitnetRequestBase
    is
        IWitnetRequest
{
    /// Contains a well-formed Witnet Data Request, encoded using Protocol Buffers.
    bytes public override bytecode;

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    bytes32 public override hash;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}