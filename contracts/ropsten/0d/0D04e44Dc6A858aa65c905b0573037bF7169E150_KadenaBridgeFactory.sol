// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// TODO:
// Twos-complement
// Incorporating James's bytestring library for better gas use.
// -> Decimal Type (tag 0x02 -> converting to Stu --> Integer)

import '@openzeppelin/contracts/math/SafeMath.sol';

/**
 * @title ChainwebProof
 * @dev Validates SPV events proofs from Kadena's Chainweb network.
 */
library ChainwebEventsProof {
  using SafeMath for uint256;

  /**
   * @dev Represents all possible Chainweb Event parameter types.
   * NOTE: Order of enums also corresponds to these type's respective tags
   *       when they are encoded in Chainweb binary representation.
   *       For example, all ByteString parameters start with the `0x00` byte tag.
   */
  enum ParameterType {
    Bytes,  // 0x0
    Integer  // 0x1
  }

  /**
   * @dev Represents the parameter type and associated raw bytes of a Chainweb
   *      Event parameter with type byte tag stripped.
   * NOTE: The `paramValue` field was purposedly made into a bytes array.
   *       This allows grouping parameters that parse to different (Solidity)
   *       types into a single array since Solidity does not allow arrays of
   *       different types nor does it support sum types.
   *
   *       Therefore, to finalize the conversion, clients should utilize
   *       helper functions to convert `paramValue` into the appropriate
   *       Solidity type based on its `paramType`.
   */
  struct Parameter {
    ParameterType paramType;
    bytes paramValue;
  }

  /**
   * @dev Represents a Chainweb event, its parameters, as well as the module
   *      and module hash in which it occurred.
   */
  struct Event {
    bytes eventName;
    bytes eventModule;
    bytes eventModuleHash;
    Parameter[] eventParams;
  }

  /* ===========================
   *  HELPER FUNCTIONS
   * ===========================
   **/

   /**
   * @dev Returns the size in bytes of Chainweb event parameters of type
   *      integer (i.e. they're always 256 bits, or 32 bytes).
   *
   * NOTE: This getter function is needed because libraries in Solidity
   *       cannot have non-constant state variables
   */
   function sizeOfParamInt() internal pure returns (uint256) {
     return 32;
   }

   /**
   * @dev Converts a sub-array of bytes into a little-endian byte integer.
   * @param b Bytes array containing the sub-array of bytes that will be
   *          converted into an integer.
   * @param idx Start index of the sub-array of bytes to convert.
   * @param sizeInBytes Size of the sub-array of bytes to convert.
   */
  /** TODO: negative numbers **/
  function readIntLE(
    bytes memory b,
    uint256 idx,
    uint256 sizeInBytes
  ) internal pure returns (uint256) {
    uint256 value = 0;
    uint256 k = sizeInBytes - 1;

    for (uint256 i = idx; i < (idx + sizeInBytes); i++) {
      value = value + uint256(uint8(b[i]))*(2**(8*(sizeInBytes-(k+1))));
      k -= 1;
    }

    return value;
  }

  /**
  * @dev Converts a sub-array of bytes into a big-endian byte integer.
  * @param b Bytes array containing the sub-array of bytes that will be
  *          converted into an integer.
  * @param idx Start index of the sub-array of bytes to convert.
  * @param sizeInBytes Size of the sub-array of bytes to convert.
  */
 /** TODO: negative numbers **/
 function readIntBE(
   bytes memory b,
   uint256 idx,
   uint256 sizeInBytes
 ) internal pure returns (uint256) {
   uint256 value = 0;
   uint256 k = sizeInBytes - 1;

   /** TODO: WRONG this is little endian
    **/
   for (uint256 i = idx; i < (idx + sizeInBytes); i++) {
     value = value + uint256(uint8(b[i]))*(2**(8*(4-(k+1))));
     // number = number + uint(b[i])*(2**(8*(b.length-(i+1)))); big endian?
     k -= 1;
   }

   return value;
 }

  /**
  * @dev Reads a sub-array of bytes and returns it.
  * @param b Bytes array containing the sub-array of bytes to return.
  * @param idx Start index of the sub-array of bytes.
  * @param sizeInBytes Size of the sub-array of bytes.
  */
  function readByteString(
    bytes memory b,
    uint256 idx,
    uint256 sizeInBytes
  ) internal pure returns (bytes memory) {
    bytes memory value = new bytes(sizeInBytes);
    uint256 j = 0;

    for (uint256 i = idx; i < (idx + sizeInBytes); i++) {
      value[j] = b[i];
      j += 1;
    }

    return value;
  }

  /* =========================
   *  EVENT PARSING FUNCTIONS
   * =========================
   **/

  /**
  * @dev Parses a Chainweb event parameter of type ByteString.
  * @param b Bytes array containing the sub-array of bytes to return.
  * @param idx Start index of the sub-array of bytes.
  *
  * The ByteString event parameter will have the following format:
  * |-- 1 byte (a) --||-- 4 bytes (b) --||-- n bytes (c) --|
  *
  * (a): The first byte is `0x00`, the ByteString Param tag.
  * (b): The next 4 bytes encodes the size (a little-endian integer) of the
  *      ByteString parameter in bytes.
  * (c): The rest `n` bytes encodes the actual parameter ByteString.
  *
  * @return currIdx (Ending index + 1) of the sub-array.
  * @return parsed Just the parsed array of bytes.
  *
  */
  function parseBytesParam(bytes memory b, uint256 idx) public pure
    returns (uint256, bytes memory){
      uint256 currIdx = idx;

      uint256 bytesTag = readIntLE(b, idx, 1);
      currIdx += 1;
      /** TODO: better way to compare tag? **/
      require(bytesTag == uint256(ParameterType.Bytes),
              "parseBytesParam: expected 0x0 tag not found");

      uint256 numOfBytes = readIntLE(b, currIdx, 4);
      currIdx += 4;

      bytes memory parsed = readByteString(b, currIdx, numOfBytes);
      currIdx += numOfBytes;

      return (currIdx, parsed);
  }

  /**
  * @dev Parses a Chainweb event parameter of type (little-endian) Integer.
  * @param b Bytes array containing the sub-array of bytes to convert.
  * @param idx Start index of the sub-array of bytes.
  * @param isTagged Boolean to indicate if sub-array contains the Integer
  *                 parameter tag (i.e. does the byte array start with `0x01`).
  *
  * The Integer event parameter will have the following format:
  * |-- 1 byte (a) --||-- 32 bytes (b) --|
  *
  * (a): The first byte is `0x01`, the Integer Param tag.
  * (b): The next 4 bytes encodes the size `n` (a little-endian integer)
  *      in number of bytes of the ByteString parameter.
  * (c): The next 32 bytes encodes the bytes sub-array representing
  *      the (little-endian) integer parameter.
  *
  * NOTE: This function will mostly be used by clients to convert the raw
  *       integer bytes returned by `parseParam` into a Solidity integer.
  *       Since the `parseParam` function returns the raw bytes without the
  *       integer type tag, then clients should call this function with
  *       `isTagged` set to false.
  *
  * @return currIdx (Ending index + 1) of the sub-array converted.
  * @return value The parsed integer parameter as a Solidity 256 bit (32 byte)
  *               integer.
  *
  */
  function parseIntLEParam(bytes memory b, uint256 idx, bool isTagged) public pure
    returns (uint256, uint256){
      uint256 currIdx = idx;

      if (isTagged == true) {
        uint256 intTag = readIntLE(b, idx, 1);
        currIdx += 1;
        require(intTag == uint256(ParameterType.Integer),
                "parseIntLEParam: expected 0x01 tag not found");
      }

      uint256 value = readIntLE(b, currIdx, sizeOfParamInt());
      currIdx += sizeOfParamInt();

      return (currIdx, value);
  }

  /**
  * @dev Parses a Chainweb event parameter depending on the parameter's type tag.
  * @param b Bytes array containing the sub-array of bytes to convert.
  * @param idx Start index of the sub-array of bytes.
  *
  * The event parameter will have the following format:
  * |-- 1 byte (a) --||-- n bytes (b) --|
  *
  * (a): The first byte is the parameter type tag.
  *      See `ParameterType` for more details.
  * (b): The next n bytes encodes the parameter value using the encoding scheme
  *      determined by its type tag (a).
  *
  * @return currIdx (Ending index + 1) of the sub-array parsed.
  * @return param The Parameter struct containing the type of the parameter,
  *               the raw bytes associated with it, and the size in bytes
  *               of the parameter.
                  NOTE: The raw bytes is stripped of all type
  *               type tags and size encodings for ByteString and Integer types.
  *
  */
  function parseParam(bytes memory b, uint256 idx) internal pure
    returns (uint256, Parameter memory) {
      uint256 currIdx = idx;

      // peek at the value of the type tag, but don't update index
      uint256 tag = readIntLE(b, currIdx, 1);

      if (tag == uint256(ParameterType.Bytes)) {
        uint256 paramEndIdx;
        bytes memory parsed;
        // `parseBytesParam` expects the tag byte
        (paramEndIdx, parsed) = parseBytesParam(b, currIdx);
        currIdx = paramEndIdx;
        Parameter memory param = Parameter(ParameterType.Bytes, parsed);
        return (currIdx, param);
      }
      else if (tag == uint256(ParameterType.Integer)) {
        currIdx += 1;  // skips over tag byte

        // NOTE: Gets raw integer bytes to make it easier to group parameters
        // of different types. Clients will need to use `parseIntLEParam`
        // to convert these bytes into their integer value.
        // See `Parameter` struct documentation for more details.
        bytes memory intBytes = readByteString(b, currIdx, sizeOfParamInt());
        currIdx += sizeOfParamInt();
        Parameter memory param = Parameter(ParameterType.Integer, intBytes);
        return (currIdx, param);
      }
      else {
        revert("parseParam: Invalid event param tag");
      }
  }

  /**
  * @dev Parses an array of Chainweb event parameters.
  * @param b Bytes array containing the sub-array of bytes to convert.
  * @param idx Start index of the sub-array of bytes.
  *
  * The array of event parameters will have the following format:
  * |-- 4 bytes (a) --||-- 1st n bytes (b) --|...|-- jth m bytes (b) --|
  *
  * (a): The first 4 bytes (little-endian) encodes the size of the array in bytes.
  * (b): The rest of the bytes holds the paramters in their respective binary
  *      encoding in sequential order and one right after the other.
  *      See `parseParam` for more details.
  *
  * @return currIdx (Ending index + 1) of the sub-array parsed.
  * @return params The Parameter array containing the parsed parameters.
  *
  */
  function parseParamsArray(bytes memory b, uint256 idx) internal pure
    returns (uint256, Parameter[] memory) {
      uint256 currIdx = idx;

      uint256 numOfParams = readIntLE(b, currIdx, 4);
      currIdx += 4;

      Parameter[] memory params = new Parameter[](numOfParams);

      for (uint256 i = 0; i < numOfParams; i++) {
        uint256 endIdx;
        Parameter memory eventParam;
        (endIdx, eventParam) = parseParam(b, currIdx);
        currIdx = endIdx;
        params[i] = eventParam;
      }

      return (currIdx, params);
    }

  /**
  * @dev Parses a Chainweb event.
  * @param b Bytes array containing the sub-array of bytes to convert.
  * @param idx Start index of the sub-array of bytes.
  *
  * The array of events will have the following format:
  * |-- n bytes (a) --||-- m bytes (b) --||-- o bytes (c) --||-- p bytes (d) --|
  *
  * (a): The first n bytes encodes the event name as a ByteString type
  *      (see `parseBytesParam` for encoding details).
  * (b): The next m bytes encodes as a ByteString type the module name where
  *      this event was emitted.
  * (c): The next o bytes encodes as a ByteString type the hash of the module
  *      where this event was emitted.
  * (d): The next p bytes encodes the array of parameters this event was called
  *      with
  *
  * NOTE: See `parseBytesParam` for encoding details on how (a)-(c) where
  *       parsed, and see `parseParamsArray` for details on how (d) was
  *       parsed.
  *
  * @return currIdx (Ending index + 1) of the sub-array parsed.
  * @return _event The Event struct containing the parsed event fields.
  *
  */
  function parseEvent(bytes memory b, uint256 idx) internal pure
    returns (uint256, Event memory) {
      uint256 currIdx = idx;

      uint256 eventNameEndIdx;
      bytes memory eventName;
      (eventNameEndIdx, eventName) = parseBytesParam(b, currIdx);
      currIdx = eventNameEndIdx;

      uint256 eventModuleEndIdx;
      bytes memory eventModule;
      (eventModuleEndIdx, eventModule) = parseBytesParam(b, currIdx);
      currIdx = eventModuleEndIdx;

      uint256 moduleHashEndIdx;
      bytes memory eventModuleHash;
      (moduleHashEndIdx, eventModuleHash) = parseBytesParam(b, currIdx);
      currIdx = moduleHashEndIdx;

      uint256 paramArrEndIdx;
      Parameter[] memory params;
      (paramArrEndIdx, params) = parseParamsArray(b, currIdx);
      currIdx = paramArrEndIdx;

      Event memory _event = Event(eventName, eventModule, eventModuleHash, params);

      return (currIdx, _event);
  }

  /**
  * @dev Parses an array of Chainweb events.
  * @param b Bytes array containing the sub-array of bytes to convert.
  * @param idx Start index of the sub-array of bytes.
  *
  * The array of events will have the following format:
  * |-- 4 bytes (a) --||-- 1st n bytes (b) --|...|-- jth m bytes (b) --|
  *
  * (a): The first 4 bytes (little-endian) encodes the size of the array in bytes.
  * (b): The rest of the bytes holds the events in their respective binary
  *      encoding in sequential order and one right after the other.
  *      See `parseEvent` for details.
  *
  * @return currIdx (Ending index + 1) of the sub-array parsed.
  * @return events The Event array containing the parsed events.
  *
  */
  function parseEventsArray(bytes memory b, uint256 idx) internal pure
    returns (uint256, Event[] memory) {
      uint256 currIdx = idx;

      uint256 numOfEvents = readIntLE(b, currIdx, 4);
      currIdx += 4;

      Event[] memory events = new Event[] (numOfEvents);

      for (uint256 i = 0; i < numOfEvents; i++) {
        uint256 eventEndIdx;
        Event memory _event;
        (eventEndIdx, _event) = parseEvent(b, currIdx);
        currIdx = eventEndIdx;
        events[i] = _event;
      }

      return (currIdx, events);
  }


  /**
  * @dev Parses an event-based merkle proof subject emitted by Kadena's public
  *      blockchain.
  * @param b Bytes array containing all of the proof subject.
  *
  * The subject will have the following format:
  * |-- n bytes (a) --||-- 1st m bytes (b) --|...|-- jth o bytes (b) --|
  *
  * (a): The first n bytes encodes as a ByteString type the request key of the
  *      transaction emitting the events.
  *      See `parseBytesParam` for more details.
  * (b): The rest of the bytes holds the array of events in its respective binary
  *      encoding, in sequential order, and one right after the other.
  *      See `parseEventsArray` for more details.
  *
  * @return reqKey The bytes of the parsed Request Key.
  * @return events The Event array containing the parsed events.
  *
  */
  function parseProofSubject(bytes memory b) internal pure
    returns (bytes memory, Event[] memory){
      uint256 currIdx = 0;

      uint256 reqKeyEndIdx;
      bytes memory reqKey;
      (reqKeyEndIdx, reqKey) = parseBytesParam(b, currIdx);
      currIdx = reqKeyEndIdx;

      Event[] memory events;
      uint256 _i;
      (_i, events) = parseEventsArray(b, currIdx);

      return (reqKey, events);
  }

  /* =========================
   *  EVENT PROOF FUNCTIONS
   * =========================
   **/

   /**
   * @dev Concatenate bytes with leaf tag and perform a Keccak256 hash.
   * @param b Bytes array to hash.
   */
   function hashLeafKeccak256(bytes memory b) public pure
     returns (bytes32){
       bytes1 leafTag = 0x00;
       bytes32 hsh = keccak256(abi.encodePacked(leafTag, b));
       return hsh;
   }

   /**
   * @dev Concatenate two bytes32 with node tag and perform a Keccak256 hash.
   * @param hsh1 Bytes32 keccak256 hash
   * @param hsh2 Bytes32 keccak256 hash
   *
   * NOTE: Hashes will be concatenating as such before being hashed:
   * |-- nodeTag --||-- hsh1 --||-- hsh2 --|
   *
   */
   function hashNodeKeccak256(bytes32 hsh1, bytes32 hsh2) public pure
     returns (bytes32){
       bytes1 nodeTag = 0x01;
       bytes32 hsh = keccak256(abi.encodePacked(nodeTag, hsh1, hsh2));
       return hsh;
   }

   /**
   * @dev Retrieves the size of Keccak256 hashes (i.e. 32 bytes).
   */
   function sizeOfProofKeccak256() public pure
     returns (uint256){
       return 32;
   }

   /**
   * @dev Execute an inclusion proof. The result of the execution is a
   *      Merkle root that must be compared to the trusted root of the
   *      Merkle tree.
   * @param subj The merkle hash of the subject for
   *             which inclusion is proven.
   * @param stepCount The number of steps in the proof path.
   * @param proofPathHashes The proof object is parsed to create this list
   *                        of merkle hashes corresponding to proof path steps.
   * @param proofPathSides List of sides as bytes1 that indicate where to append
   *                       the corresponding merkle hash in `proofPathHashes`
   *                       to the previously calculated hash to determine the
   *                       current step's hash.
   *
   * NOTE: The original proof object is structured as follows:
   * |-- 4 bytes (a) --||-- 8 bytes (b) --||-- (c) .. --|
   *  (a): The first 4 bytes encodes the number of proof steps
   *       as a big endian value.
   *  (b): The next 8 bytes encodes the index of the proof subject in
   *       the input order as a big endian value.
   *  (c): After the first 12 bytes, the rest of the bytes are the
   *       proof path, composed of a series of proof steps. Each step is
   *       a merkle hash of format:
   *       |--1 byte (i) --||--`hashSize` bytes (ii)--|
   *       (i): '0x00' (representing Left) and '0x01' (representing Right).
   *       (ii): The hash needed to compute the current proof path.
   *
   */
   function runMerkleProofKeccak256(
     bytes memory subj,
     uint256 stepCount,
     bytes32[] memory proofPathHashes,
     bytes1[] memory proofPathSides
   ) public pure returns(bytes32) {
     require(proofPathHashes.length == stepCount,
             "Invalid proof path: List of hashes not expected lenght (stepCount)");
     require(proofPathSides.length == stepCount,
             "Invalid proof path: List of sides not expected lenght (stepCount)");

     bytes32 subjectMerkleHash = hashLeafKeccak256(subj);
     bytes32 root = subjectMerkleHash;

     for (uint i = 0; i < proofPathHashes.length; i++) {
       bytes32 currProof = proofPathHashes[i];
       bytes1 currSide = proofPathSides[i];

       if (currSide == 0x00) {  // concatenate `currProof` to LEFT of `root`
         root = hashNodeKeccak256(currProof, root);
       } else if (currSide == 0x01) {  // concatenate `currProof` to RIGHT of `root`
         root = hashNodeKeccak256(root, currProof);
       } else {
         revert("Invalid proof object: Invalid `side` value provided");
       }
     }
     return root;
   }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract HeaderOracle {
  using SafeMath for uint256;

  uint256 numValidSigners = 0;

  struct SignerInfo {
    bool isAdmin;
    bool isValid;
    // ^ facilitates checking if signer in mapping
    // TODO: Disabling signers needs restructuring to
    //       undo votes by sender for a hash.
  }

  struct Signers {
    address[] keys;
    mapping (address => SignerInfo) map;
  }
  Signers signers;

  struct PayloadInfo {
    string blockHeight;
    string chainId;
    string shaBlockHash;
    uint256 voteCount;
    bool isPresent; // to facilitate checking if key in mapping
  }

  // keccak256 payload receipt root => PayloadInfo
  mapping (bytes32 => PayloadInfo) payloads;

  mapping (address => mapping (bytes32 => bool)) signedHashes;

  modifier validSignerOnly {
      require(signers.map[msg.sender].isValid,
              "Sender is not pre-authorized to add to oracle");
      _;
  }

  constructor(address[] memory admins) public {
    uint adminCount = admins.length;
    numValidSigners += adminCount;
    for (uint i=0; i < adminCount; i++){
      address admin = admins[i];
      SignerInfo memory adminInfo = SignerInfo(true, true);
      signers.keys.push(admin);
      signers.map[admin] = adminInfo;
    }
  }

  function addHash (
    bytes32 keccakPayloadHash,
    string memory blockHeight,
    string memory chainId,
    string memory shaBlockHash
  ) validSignerOnly public {
    if (payloads[keccakPayloadHash].isPresent) {
      if (signedHashes[msg.sender][keccakPayloadHash]) {
        revert("This signer already voted for the provided payload hash");
      } else {
        PayloadInfo memory p = payloads[keccakPayloadHash];

        require(keccak256(abi.encodePacked(p.blockHeight)) ==
                keccak256(abi.encodePacked(blockHeight)),
                "Block height provided does not match");
        require(keccak256(abi.encodePacked(p.chainId)) ==
                keccak256(abi.encodePacked(chainId)),
                "Chain id provided does not match");
        require(keccak256(abi.encodePacked(p.shaBlockHash)) ==
                keccak256(abi.encodePacked(shaBlockHash)),
                "Block hash provided does not match");

        payloads[keccakPayloadHash].voteCount += 1;
        signedHashes[msg.sender][keccakPayloadHash] = true;

        emit HashReceivedVote(
          msg.sender,
          payloads[keccakPayloadHash].voteCount,
          keccakPayloadHash,
          blockHeight,
          chainId,
          shaBlockHash);
      }
    } else {
      PayloadInfo memory info = PayloadInfo(
        blockHeight, chainId, shaBlockHash, 1, true);
      payloads[keccakPayloadHash] = info;
      signedHashes[msg.sender][keccakPayloadHash] = true;
    }
  }

  function totalVotes(
    bytes32 keccakPayloadHash,
    string memory blockHeight,
    string memory chainId,
    string memory shaBlockHash
  ) public view
    returns(uint256) {
      if (payloads[keccakPayloadHash].isPresent) {
        PayloadInfo memory p = payloads[keccakPayloadHash];
        require(keccak256(abi.encodePacked(p.blockHeight)) ==
                keccak256(abi.encodePacked(blockHeight)),
                "Block height provided does not match");
        require(keccak256(abi.encodePacked(p.chainId)) ==
                keccak256(abi.encodePacked(chainId)),
                "Chain id provided does not match");
        require(keccak256(abi.encodePacked(p.shaBlockHash)) ==
                keccak256(abi.encodePacked(shaBlockHash)),
                "Block hash provided does not match");
        return p.voteCount;
      } else {
        revert("Provided payload hash was not found");
      }
  }

  function getPayloadInfo(
    bytes32 keccakPayloadHash
  ) public view
    returns(string memory, string memory, string memory, uint256) {
      require (payloads[keccakPayloadHash].isPresent,
              "Payload hash provided is not pending");
      PayloadInfo memory p = payloads[keccakPayloadHash];
      return (p.blockHeight, p.chainId, p.shaBlockHash, p.voteCount);
  }

  function isSignedBy(
    bytes32 keccakPayloadHash,
    address signer
    ) public view returns (bool) {
      return signedHashes[signer][keccakPayloadHash];
    }

  function getNumValidSigners() public view returns(uint256){
    return numValidSigners;
  }

  event HashReceivedVote(
    address indexed signer,
    uint256 indexed votesSoFar,
    bytes32 indexed keccakPayloadHash,
    string blockHeight,
    string chainId,
    string shaBlockHash
  );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
Source(s):
- https://github.com/radek1st/time-locked-wallets/blob/master/contracts/TimeLockedWalletFactory.sol
*/

import "./KadenaBridgeWallet.sol";
import "./HeaderOracle.sol";

contract KadenaBridgeFactory {

    HeaderOracle oracle;
    mapping(address => address[]) wallets;

    /**
    * @dev Create a new Kadena Bridge Factory and Header Oracle.
    * @param oracleAdmins array of signer addresses.
    */
    constructor(address[] memory oracleAdmins) public {
      oracle = new HeaderOracle(oracleAdmins);
    }

    /**
    * @dev Retrieves which wallets were created or owned by specific user.
    * @param _user The user address
    */
    function getWallets(address _user) public view
      returns(address[] memory){
        return wallets[_user];
    }

    /**
    * @dev Create a new Kadena Bridge wallet and map wallets to their creators
    *      and owners.
    * @param _owner The Ethereum address that owns any released amounts.
    * @param _chainwebOwner String representation of the public key that owns
    *                       the locked amounts in Chainweb.
    */
    function newKadenaBridgeWallet(
        address _owner,
        string memory _chainwebOwner
    ) public returns(address) {
        address oracleAddr = address(oracle);
        KadenaBridgeWallet wallet = new KadenaBridgeWallet(
          msg.sender,
          _owner,
          _chainwebOwner,
          oracleAddr
        );
        address walletAddr = address(wallet);
        wallets[msg.sender].push(walletAddr);
        if (msg.sender != _owner) {
            wallets[_owner].push(walletAddr);
        }
        emit CreatedKadenaBridgeWallet(
          walletAddr,
          msg.sender,
          _owner,
          _chainwebOwner
        );
        return walletAddr;
    }

    /**
    * @dev Prevents sending ether to the factory contract.
    */
    receive() external payable {
        revert();
    }

    event CreatedKadenaBridgeWallet(
      address wallet,
      address creator,
      address indexed owner,
      string indexed chainwebOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./HeaderOracle.sol";
import "./ChainwebEventsProof.sol";

/**
Source(s):
- https://github.com/radek1st/time-locked-wallets/blob/master/contracts/TimeLockedWallet.sol
*/

contract KadenaBridgeWallet {
    using SafeMath for uint256;

    address public creator;
    address public owner;
    string public chainwebOwner;
    HeaderOracle oracle;

    /**
    * @dev Asserts that the transaction sender is the owner specified
    *      when this contract was created.
    */
    modifier onlyOwner {
        require(msg.sender == owner,
                "Sender is not the owner");
        _;
    }


    /**
    * @dev Create a new Kadena Bridge wallet.
    * @param _creator The Ethereum address that created the account.
    * @param _owner The Ethereum address that owns any released amounts.
    * @param _chainwebOwner String representation of the public key that owns
    *                       the locked amounts in Chainweb.
    */
    constructor (
        address _creator,
        address _owner,
        string memory _chainwebOwner,
        address _oracle
    ) public {
        creator = _creator;
        owner = _owner;
        chainwebOwner = _chainwebOwner;
        oracle = HeaderOracle(_oracle);
    }


    /**
    * @dev Only allows receiving eth through `lockETH` function.
    */
    receive() external payable {
        revert("Use `lockETH` to send ether to contract");
    }


    /**
    * @dev Locks up all the ether sent to this contract address.
    * NOTE: `msg.value` contains the amount (in wei == ether / 1e18)
    *       sent in this transaction.
    */
    function lockETH() public payable {
      require(msg.value > 0, "ETH amount locked must be non-zero");
      emit LockedETH(address(this), msg.value, owner, chainwebOwner);
    }


    /**
    * @dev Locks up the specified token amount in an account owned by
    *      this contract.
    * @param _tokenContract The address of the ERC20 token.
    * @param amount The amount to be locked.
    * NOTE: Callable only for Tokens implementing ERC20.
    * TODO: It's possible to transfer tokens to this contract's token account
    *       directly without using this function.
    *       This means that no LockedTokens event would be logged, effectively
    *       "burning" this amount since it won't be able to be released.
    */
    function lockTokens(
        address _tokenContract,
        uint256 amount
    ) public {
      require(amount > 0, "Token amount locked must be non-zero");
      ERC20 token = ERC20(_tokenContract);
      uint256 allowance = token.allowance(msg.sender, address(this));
      require(allowance >= amount,
              "Insufficient token allowance for contract");
      token.transferFrom(msg.sender, address(this), amount);
      emit LockedToken(address(this), _tokenContract, amount, owner, chainwebOwner);
    }


    /**
    * @dev Releases the specified ether amount to the `owner` of this contract.
    * @param proof The string proof of ether being locked in Chainweb.
    * @param amount The amount of ether to be released.
    * NOTE: Callable by the Ethereum `owner` only.
    * NOTE: Callable only with proof that the specified ether amount was
    *       locked up in Chainweb by the `chainwebOwner`.
    */
    function releaseETH(string memory proof, uint256 amount) onlyOwner public {
       require(amount > 0, "Amount locked must be non-zero");
       require(validateRelease(proof),
               "Invalid release proof");
       address payable _owner = msg.sender;
       _owner.transfer(amount);
       emit ReleasedETH(address(this), owner, amount, chainwebOwner);
    }


    /**
    * @dev Releases the specified token amount to the `owner` of this contract.
    * @param _tokenContract The address of the ERC20 token.
    * @param proof The string proof of the tokens being locked in Chainweb.
    * @param amount The token amount to be released.
    * NOTE: Callable only for Tokens implementing ERC20.
    * NOTE: Callable by the Ethereum `owner` only.
    * NOTE: Callable only with proof that the specified token amount was
    *       locked up in Chainweb by the `chainwebOwner`.
    */
    function releaseTokens(
        address _tokenContract,
        string memory proof,
        uint256 amount
    ) onlyOwner public {
       require(amount > 0, "Amount locked must be non-zero");
       require(validateRelease(proof),
              "Invalid release proof");
       ERC20 token = ERC20(_tokenContract);
       token.transfer(owner, amount);
       emit ReleasedTokens(address(this), _tokenContract, owner, amount, chainwebOwner);
    }


    /**
    * @dev Dummy function for confirming that the Chainweb proof is valid.
    * @param proof The string proof of the amount being locked in Chainweb.
    */
    function validateRelease(
        string memory proof
    ) public pure returns(bool) {
      if (keccak256(abi.encodePacked(proof)) ==
          keccak256(abi.encodePacked("invalidProof"))) {  // dummy variable for testing
          return false;
      } else {
          return true;
      }
    }

    /**
    * @dev Retrieves information regarding this contract and its ether balance.
    */
    function infoETH() public view
      returns(address, address, string memory, uint256) {
        return (creator, owner, chainwebOwner, address(this).balance);
    }


    /**
    * @dev Retrieves information regarding this contract and its token balance.
    * @param _tokenContract The address of the ERC20 token.
    * NOTE: Callable only for Tokens implementing ERC20.
    * TODO: Keep ledger in contract tracking which tokens locked up. See
    *       `lockTokens` TODO note.
    */
    function infoToken(address _tokenContract) public view
      returns(address, address, string memory, uint256) {
        ERC20 token = ERC20(_tokenContract);
        uint256 tokenBalance = token.balanceOf(address(this));
        return (creator, owner, chainwebOwner, tokenBalance);
    }


    /**
    * TODO: Which three parameters in events to index?
    */
    event LockedETH(
      address kadenaBridgeContract,
      uint256 indexed weiAmount,
      address indexed ethereumOwner,
      string indexed releasedTo
    );
    event LockedToken(
      address kadenaBridgeContract,
      address indexed tokenContract,
      uint256 amount,
      address indexed ethereumOwner,
      string indexed releasedTo
    );
    event ReleasedETH(
      address indexed kadenaBridgeContract,
      address indexed ethereumOwner,
      uint256 weiAmount,
      string indexed releasedFrom
    );
    event ReleasedTokens(
      address kadenaBridgeContract,
      address indexed tokenContract,
      address indexed ethereumOwner,
      uint256 amount,
      string indexed releasedFrom
    );

    // TODO: document function
    function checkProofInOracle(
      bytes memory subj,
      uint256 stepCount,
      bytes32[] memory proofPathHashes,
      bytes1[] memory proofPathSides,
      string memory blockHeight,
      string memory chainId,
      string memory shaBlockHash
    ) public view returns(bool) {
      bytes32 root = ChainwebEventsProof.runMerkleProofKeccak256(
        subj,
        stepCount,
        proofPathHashes,
        proofPathSides
      );
      uint256 voteCount = oracle.totalVotes(
          root,
          blockHeight,
          chainId,
          shaBlockHash
        );
      uint256 totalPossibleVotes = oracle.getNumValidSigners();
      require(totalPossibleVotes - 1 == voteCount,
              "Hash has not received the required number of votes");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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