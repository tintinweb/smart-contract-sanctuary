// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./Strings.sol";

library AbiDecoder {
  /**
   * @notice Extract all params from calldata given a list of param types and raw calldata bytes
   */
  function getParamsFromCalldata(
    string[] memory paramTypes,
    bytes calldata data
  ) public pure returns (bytes[] memory) {
    uint256 numberOfParams = paramTypes.length;
    bytes[] memory results = new bytes[](numberOfParams);
    for (uint256 paramIdx = 0; paramIdx < numberOfParams; paramIdx++) {
      string memory paramType = paramTypes[paramIdx];
      bytes memory param = getParamFromCalldata(data, paramType, paramIdx);
      results[paramIdx] = param;
    }
    return results;
  }

  /**
   * @notice Extract param bytes given calldata, param type and param index
   */
  function getParamFromCalldata(
    bytes calldata data,
    string memory paramType,
    uint256 paramIdx
  ) public pure returns (bytes memory) {
    uint256 paramsStartIdx = 0x04; // Start after method selector
    uint256 paramOffset = 0x20 * paramIdx;
    bytes memory paramDescriptorValue = bytes(
      data[paramsStartIdx + paramOffset:paramsStartIdx + paramOffset + 0x20]
    );

    bool paramTypeIsStringOrBytes = Strings.stringsEqual(paramType, "bytes") ||
      Strings.stringsEqual(paramType, "string");
    bool paramTypeIsStringArrayOrBytesArray = Strings.stringsEqual(
      paramType,
      "bytes[]"
    ) || Strings.stringsEqual(paramType, "string[]");
    bool _paramTypeIsArray = paramTypeIsArray(paramType);

    uint256 paramStartIdx = uint256(bytes32(paramDescriptorValue)) + 0x04;
    if (paramTypeIsStringOrBytes) {
      return extractParamForBytesType(data, paramStartIdx);
    } else if (paramTypeIsStringArrayOrBytesArray) {
      return extractParamForBytesArrayType(data, paramStartIdx);
    } else if (_paramTypeIsArray) {
      return extractParamForSimpleArray(data, paramStartIdx);
    } else {
      return paramDescriptorValue;
    }
  }

  /**
   * @notice Extract param for "bytes" and "string" types given calldata and a param start index
   */
  function extractParamForBytesType(bytes calldata data, uint256 paramStartIdx)
    public
    pure
    returns (bytes memory)
  {
    uint256 paramEndIdx = paramStartIdx + 0x20;
    bytes32 bytesLengthBytes = bytes32(data[paramStartIdx:paramEndIdx]);
    uint256 bytesLength = uint256(bytesLengthBytes);
    bytes memory dataToAdd = abi.encodePacked(
      uint256(0x20),
      bytes32(bytesLengthBytes)
    );
    uint256 numberOfRowsOfBytes = (bytesLength / 32) + 1;
    for (uint256 rowIdx; rowIdx < numberOfRowsOfBytes; rowIdx++) {
      uint256 rowStartIdx = paramEndIdx + (0x20 * rowIdx);
      dataToAdd = abi.encodePacked(
        dataToAdd,
        data[rowStartIdx:rowStartIdx + 0x20]
      );
    }
    return dataToAdd;
  }

  /**
   * @notice Extract param for "bytes[]" and "string[]" types given calldata and a param start index
   */
  function extractParamForBytesArrayType(
    bytes calldata data,
    uint256 paramStartIdx
  ) public pure returns (bytes memory) {
    uint256 paramEndIdx = paramStartIdx + 0x20;
    bytes32 arrayLengthBytes = bytes32(data[paramStartIdx:paramEndIdx]);
    uint256 arrayLength = uint256(arrayLengthBytes);
    bytes memory dataToAdd = abi.encodePacked(
      uint256(0x20),
      bytes32(arrayLengthBytes)
    );
    uint256 lastOffsetStartIdx = paramEndIdx + (0x20 * arrayLength) - 0x20;
    uint256 lastOffset = uint256(
      bytes32(data[lastOffsetStartIdx:lastOffsetStartIdx + 0x20])
    );
    bytes32 lastElementBytesLengthBytes = bytes32(
      data[paramEndIdx + lastOffset:paramEndIdx + lastOffset + 0x20]
    );
    uint256 lastElementBytesLength = uint256(lastElementBytesLengthBytes);
    uint256 numberOfRowsOfBytesForLastElement = (lastElementBytesLength / 32) +
      1;
    uint256 dataEndIdx = paramEndIdx +
      lastOffset +
      0x20 +
      (0x20 * numberOfRowsOfBytesForLastElement);
    dataToAdd = abi.encodePacked(dataToAdd, data[paramEndIdx:dataEndIdx]);
    return dataToAdd;
  }

  /**
   * @notice Extract param for "*[]" types given calldata and a param start index, assuming each element is 32 bytes
   */
  function extractParamForSimpleArray(
    bytes calldata data,
    uint256 paramStartIdx
  ) public pure returns (bytes memory) {
    uint256 paramEndIdx = paramStartIdx + 0x20;
    bytes32 arrayLengthBytes = bytes32(data[paramStartIdx:paramEndIdx]);
    uint256 arrayLength = uint256(arrayLengthBytes);
    bytes memory dataToAdd = abi.encodePacked(
      uint256(0x20),
      bytes32(arrayLengthBytes)
    );
    for (uint256 rowIdx; rowIdx < arrayLength; rowIdx++) {
      uint256 rowStartIdx = paramEndIdx + (0x20 * rowIdx);
      dataToAdd = abi.encodePacked(
        dataToAdd,
        data[rowStartIdx:rowStartIdx + 0x20]
      );
    }
    return dataToAdd;
  }

  /**
   * @notice Check to see if the last two characters of a string are "[]"
   */
  function paramTypeIsArray(string memory paramType)
    internal
    pure
    returns (bool)
  {
    bytes32 lastTwoCharacters;
    assembly {
      let len := mload(paramType)
      lastTwoCharacters := mload(add(add(paramType, 0x20), sub(len, 2)))
    }
    return lastTwoCharacters == bytes32(bytes("[]"));
  }
}