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