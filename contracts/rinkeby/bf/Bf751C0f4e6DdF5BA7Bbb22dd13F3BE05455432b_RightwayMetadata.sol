// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/BinaryDecoder.sol';
import '../utils/PackedVarArray.sol';


library RightwayDecoder {
  struct DropContentLibrary {
    uint256 arweaveHash;
  }

  /*
   * content types:
   * 0 - image
   * 1 - vector
   * 2 - video
   * 3 - audio
   */
  struct DropContent {
    uint8  contentLibrary;
    uint8  contentType;
    uint16 contentIndex;
  }

  // encoded as uint16 keyref, uint8 array (0/1), uint16 value-ref
  // arrays will have multiple entries
  struct DropAttribute {
    uint16   key;        // from drop.stringData
    bool     isArray;
    uint16   value;     // from drop.stringData
  }

  struct DropTemplate {
    uint16   name;             // from drop.sentences joined with ' '
    uint16   description;      // from drop.sentences joined with ' '
    uint8    redemptions;
    uint64   redemptionExpiration;

    uint16   attributesStart;   // from drop.attributes
    uint16   attributesLength;  // from drop.attributes
    uint16   contentStart;      // from drop.content
    uint16   contentLength;     // from drop.content
  }

  struct DropEdition {
    uint16   template;
    uint16   size;
    uint16   attributesStart;  // from drop.attributes
    uint16   attributesLength; // from drop.attributes
    uint16   contentStart;     // from drop.content
    uint16   contentLength;    // from drop.content
  }

  struct DropToken {
    uint16   edition;
    uint16   serial;
  }

  struct Drop {
    DropContentLibrary[] contentLibraries; // max of 256 content libraries
    bytes32[0xFFFF] content;
    bytes32[0xFFFF] stringData; // max of 64k strings
    bytes32[0xFFFF] sentences;  // max of 64k strings
    bytes32[0xFFFF] attributes;
    bytes32[0xFFFF] templates;
    bytes32[0xFFFF] editions;
    bytes32[0xFFFF] tokens;
    uint numTokens;
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function decodeDropAttribute(Drop storage drop, uint16 idx) public view returns ( DropAttribute memory ) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 6);
    DropAttribute memory result;

    uint8 isArray = 0;
    (result.key, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.attributes, bufferIndex, offset);
    (result.value, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.attributes, bufferIndex, offset);
    (isArray,,) = BinaryDecoder.decodeUint8(drop.attributes, bufferIndex, offset);
    result.isArray = isArray != 0;

    return result;
  }

  function decodeDropString(Drop storage drop, uint16 idx) public view returns ( string memory ) {
    return PackedVarArray.getString(drop.stringData, idx);
  }

  function copyBytesUsafe( bytes memory from, bytes memory to, uint offset) internal pure returns (uint){
    for (uint idx = 0; idx < from.length; idx++) {
      to[offset + idx] = from[idx];
    }
    return offset + from.length;
  }

  function decodeDropSentence(Drop storage drop, uint16 index ) public view returns (string memory) {
    uint16[] memory words = PackedVarArray.getUint16Array(drop.sentences, index);
    uint strLen = words.length - 1; // initialized to the number of spaces

    string[] memory strings = new string[](words.length);
    for (uint idx = 0; idx < words.length; idx++) {
      strings[idx] = PackedVarArray.getString(drop.stringData, words[idx]);
      strLen += bytes(strings[idx]).length;
    }

    bytes memory strRaw = new bytes(strLen);
    uint offset = 0;
    for (uint idx = 0; idx < words.length - 1; idx++) {
      offset = copyBytesUsafe(bytes(strings[idx]), strRaw, offset);
      strRaw[offset++] = 0x20; // ascii/utf8 space
    }

    copyBytesUsafe(bytes(strings[words.length - 1]), strRaw, offset);

    return string(strRaw);
  }

  function decodeDropEdition(Drop storage drop, uint16 idx) public view returns(DropEdition memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 12);
    DropEdition memory result;

    (result.template, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.size, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.attributesStart, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.attributesLength, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.contentStart, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);
    (result.contentLength, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.editions, bufferIndex, offset);

    return result;
  }

  function decodeDropTemplate(Drop storage drop, uint16 idx) public view returns(DropTemplate memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 32);
    DropTemplate memory result;

    (result.name, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.description, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.redemptions, bufferIndex, offset) = BinaryDecoder.decodeUint8(drop.templates, bufferIndex, offset);
    (result.redemptionExpiration, bufferIndex, offset) = BinaryDecoder.decodeUint64Aligned(drop.templates, bufferIndex, offset);
    (result.attributesStart, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.attributesLength, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.contentStart, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);
    (result.contentLength, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.templates, bufferIndex, offset);

    return result;
  }

  function decodeDropToken(Drop storage drop, uint16 idx) public view returns(DropToken memory) {
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 4);
    DropToken memory result;

    (result.edition, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.tokens, bufferIndex, offset);
    (result.serial, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.tokens, bufferIndex, offset);

    return result;
  }

  function decodeDropContent(Drop storage drop, uint16 idx) public view returns(DropContent memory) {
    DropContent memory result;
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(idx, 4);
    (result.contentLibrary, bufferIndex, offset) = BinaryDecoder.decodeUint8(drop.content, bufferIndex, offset);
    (result.contentType, bufferIndex, offset) = BinaryDecoder.decodeUint8(drop.content, bufferIndex, offset);
    (result.contentIndex, bufferIndex, offset) = BinaryDecoder.decodeUint16Aligned(drop.content, bufferIndex, offset);
    return result;
  }

  function getDropContentLibrary(Drop storage drop, uint16 idx) public view returns(DropContentLibrary storage) {
    return drop.contentLibraries[idx];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../utils/Base64.sol';
import './RightwayDecoder.sol';


library RightwayMetadata {
  /*
   * token state information
   */
  struct TokenRedemption {
    uint64 timestamp;
    string memo;
  }

  struct TokenState {
    uint64   soldOn;
    uint256  price;
    address  buyer;

    TokenRedemption[] redemptions;
    uint16[] additionalContent;
    uint16   attributesStart;
    uint16   attributesLength;
  }

  struct MetadataAttribute {
    bool isArray;
    string key;
    string[] values;
  }

  struct MetadataContent {
    string uri;
    string contentLibraryArweaveHash;
    uint16 contentIndex;
    string contentType;
  }

  struct TokenMetadata {
    string name;
    string description;
    MetadataAttribute[] attributes;
    uint256 editionSize;
    uint256 editionNumber;
    uint256 totalRedemptions;
    uint64 redemptionExpiration;
    MetadataContent[] content;
    TokenRedemption[] redemptions;
    uint64 soldOn;
    address buyer;
    uint256 price;
    bool isMinted;
  }


  function reduceDropAttributes(RightwayDecoder.Drop storage drop, RightwayDecoder.DropAttribute[] memory dropAttribute ) internal view returns ( MetadataAttribute[] memory ) {
    if (dropAttribute.length == 0) {
      return new MetadataAttribute[](0);
    }


    uint resultCount = 0;
    uint16 lastKey = 0xFFFF;
    for (uint16 idx = 0; idx < dropAttribute.length; idx++) {
      if (!dropAttribute[idx].isArray || dropAttribute[idx].key != lastKey) {
        resultCount++;
        lastKey = dropAttribute[idx].key;
      }
    }

    MetadataAttribute[] memory result = new MetadataAttribute[](resultCount);
    resultCount = 0;
    lastKey = dropAttribute[0].key;
    for (uint16 idx = 0; idx < dropAttribute.length; idx++) {
      if (!dropAttribute[idx].isArray || dropAttribute[idx].key != lastKey) {
        result[resultCount].isArray = dropAttribute[idx].isArray;
        result[resultCount].key = RightwayDecoder.decodeDropString(drop, dropAttribute[idx].key);
        result[resultCount].values = new string[](1);
        result[resultCount].values[0] = RightwayDecoder.decodeDropString(drop, dropAttribute[idx].value);
        resultCount++;
        lastKey = dropAttribute[idx].key;
      } else {
        string[] memory oldValues = result[resultCount - 1].values;
        result[resultCount - 1].values = new string[](oldValues.length + 1);
        for( uint vidx = 0; vidx < oldValues.length; vidx++) {
          result[resultCount - 1].values[vidx] = oldValues[vidx];
        }
        result[resultCount - 1].values[oldValues.length] = RightwayDecoder.decodeDropString(drop, dropAttribute[idx].value);
      }
    }

    return result;
  }

  function getAttributes(RightwayDecoder.Drop storage drop, uint16 start, uint16 length) internal view returns ( MetadataAttribute[] memory ) {
    if (length == 0) {
      return new MetadataAttribute[](0);
    }

    RightwayDecoder.DropAttribute[] memory dropAttributes = new RightwayDecoder.DropAttribute[](length);
    for (uint16 idx = 0; idx < length; idx++) {
      dropAttributes[idx] = RightwayDecoder.decodeDropAttribute(drop, idx + start);
    }

    return reduceDropAttributes(drop, dropAttributes);
  }

  function getAttributes(string storage creator, RightwayDecoder.Drop storage drop, TokenState memory state, RightwayDecoder.DropEdition memory edition, RightwayDecoder.DropTemplate memory template) internal view returns ( MetadataAttribute[] memory ) {
    MetadataAttribute[] memory tokenAttributes = getAttributes(drop, state.attributesStart, state.attributesLength);
    MetadataAttribute[] memory editionAttributes = getAttributes(drop, edition.attributesStart, edition.attributesLength);
    MetadataAttribute[] memory templateAttributes = getAttributes(drop, template.attributesStart, template.attributesLength);

    uint totalAttributes = tokenAttributes.length + editionAttributes.length + templateAttributes.length + 1;
    MetadataAttribute[] memory result = new MetadataAttribute[](totalAttributes);

    uint outputIdx = 0;
    for (uint idx = 0; idx < tokenAttributes.length; idx++) {
      result[outputIdx++] = tokenAttributes[idx];
    }

    for (uint idx = 0; idx < editionAttributes.length; idx++) {
      result[outputIdx++] = editionAttributes[idx];
    }

    for (uint idx = 0; idx < templateAttributes.length; idx++) {
      result[outputIdx++] = templateAttributes[idx];
    }

    result[outputIdx].isArray = false;
    result[outputIdx].key = 'creator';
    result[outputIdx].values = new string[](1);
    result[outputIdx].values[0] = creator;

    return result;
  }

  function getContent(RightwayDecoder.Drop storage drop, string storage contentApi, uint16 start, uint16 length) internal view returns(MetadataContent[] memory) {
    MetadataContent[] memory result = new MetadataContent[](length);

    for(uint16 idx = 0; idx < length; idx++) {
      RightwayDecoder.DropContent memory content = RightwayDecoder.decodeDropContent(drop, start+idx);
      RightwayDecoder.DropContentLibrary storage contentLibrary = RightwayDecoder.getDropContentLibrary(drop, content.contentLibrary);

      result[idx].contentIndex = content.contentIndex;
      result[idx].contentLibraryArweaveHash = Base64.encode(contentLibrary.arweaveHash);
      if (content.contentType == 0) {
        result[idx].contentType = 'png';
      } else if (content.contentType == 1) {
        result[idx].contentType = 'jpg';
      } else if (content.contentType == 2) {
        result[idx].contentType = 'svg';
      } else if (content.contentType == 3) {
        result[idx].contentType = 'mp4';
      }
      result[idx].uri = string(abi.encodePacked(contentApi, '/', result[idx].contentLibraryArweaveHash, '/', Strings.toString(result[idx].contentIndex), '.', result[idx].contentType ));
    }

    return result;
  }

  function getContents(RightwayDecoder.Drop storage drop, string storage contentApi, RightwayDecoder.DropEdition memory edition, RightwayDecoder.DropTemplate memory template, TokenState memory state) internal view returns (MetadataContent[] memory) {
    MetadataContent[] memory editionContent = getContent(drop, contentApi, edition.contentStart, edition.contentLength);
    MetadataContent[] memory templateContent = getContent(drop, contentApi, template.contentStart, template.contentLength);

    uint totalContents = editionContent.length + templateContent.length + state.additionalContent.length;
    MetadataContent[] memory result = new MetadataContent[](totalContents);

    uint outputIdx = 0;
    for (uint idx = 0; idx < editionContent.length; idx++) {
      result[outputIdx++] = editionContent[idx];
    }

    for (uint idx = 0; idx < templateContent.length; idx++) {
      result[outputIdx++] = templateContent[idx];
    }

    for (uint idx = 0; idx < state.additionalContent.length; idx++) {
      result[outputIdx++] = getContent(drop, contentApi, state.additionalContent[idx], 1)[0];
    }

    return result;
  }

  function getTemplateMetadata(RightwayDecoder.Drop storage drop, TokenMetadata memory result, RightwayDecoder.DropTemplate memory template) public view {
    result.name = RightwayDecoder.decodeDropSentence(drop, template.name);
    result.description = RightwayDecoder.decodeDropSentence(drop, template.description);
    result.totalRedemptions = template.redemptions;
    result.redemptionExpiration = template.redemptionExpiration;
  }

  function getEditionMetadata(TokenMetadata memory result, RightwayDecoder.DropEdition memory edition ) public pure {
    result.editionSize = edition.size;
  }

  function getTokenMetadata(TokenMetadata memory result, string storage creator, RightwayDecoder.Drop storage drop, string storage contentApi, uint256 tokenId, TokenState memory state) public view {
    require(tokenId < drop.numTokens, 'No such token');
    RightwayDecoder.DropToken memory token = RightwayDecoder.decodeDropToken(drop, uint16(tokenId));
    RightwayDecoder.DropEdition memory edition = RightwayDecoder.decodeDropEdition(drop, token.edition);
    RightwayDecoder.DropTemplate memory template = RightwayDecoder.decodeDropTemplate(drop, edition.template);

    getTemplateMetadata(drop, result, template);
    getEditionMetadata(result, edition);
    result.editionNumber = token.serial;
    result.attributes = getAttributes(creator, drop, state, edition, template);
    result.content = getContents(drop, contentApi, edition, template, state);
  }

  function getStateMetadata(TokenMetadata memory result, TokenState memory state) public pure {
    result.soldOn = state.soldOn;
    result.buyer = state.buyer;
    result.price = state.price;

    uint numRedemptions = state.redemptions.length;
    result.redemptions = new TokenRedemption[](numRedemptions);
    for (uint idx = 0; idx < numRedemptions; idx++) {
      result.redemptions[idx] = state.redemptions[idx];
    }
  }

  function getMetadata(string storage creator, RightwayDecoder.Drop storage drop, string storage contentApi, uint256 tokenId, TokenState memory state) public view returns (TokenMetadata memory){
    TokenMetadata memory result;
    getTokenMetadata(result, creator, drop, contentApi, tokenId, state);
    getStateMetadata(result, state);
    return result;
  }


}

// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin public expiriment
// @dev see https://github.com/OpenZeppelin/solidity-jwt/blob/2a787f1c12c50da649eed1670b3a6d9c0221dd8e/contracts/Base64.sol for original
pragma solidity ^0.8.0;

library Base64 {

    bytes constant private BASE_64_URL_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

    function encode(uint256 bigint) external pure returns (string memory) {
        bytes32 buffer = bytes32(bigint);
        bytes memory res = new bytes(43);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= 32; i += 3) {
            (res[j], res[j+1], res[j+2], res[j+3]) = encode3(
                uint8(buffer[i]),
                uint8(buffer[i+1]),
                uint8(buffer[i+2])
            );

            j += 4;
        }
        (res[j], res[j+1], res[j+2], ) = encode3(uint8(buffer[30]), uint8(buffer[31]), 0);
        return string(res);
    }

    function encode3(uint256 a0, uint256 a1, uint256 a2)
        private
        pure
        returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
    {

        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >>  6) & 63;
        uint256 c3 = (n      ) & 63;

        b0 = BASE_64_URL_CHARS[c0];
        b1 = BASE_64_URL_CHARS[c1];
        b2 = BASE_64_URL_CHARS[c2];
        b3 = BASE_64_URL_CHARS[c3];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BinaryDecoder {
    function increment(uint bufferIdx, uint offset, uint amount) internal pure returns (uint, uint) {
      offset+=amount;
      return (bufferIdx + (offset / 32), offset % 32);
    }

    function decodeUint8(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint8, uint, uint) {
      uint8 result = 0;
      result |= uint8(buffers[bufferIdx][offset]);
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (result, bufferIdx, offset);
    }

    function decodeUint16(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint16, uint, uint) {
      uint result = 0;
      if (offset % 32 < 31) {
        return decodeUint16Aligned(buffers, bufferIdx, offset);
      }

      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint16Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint16, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 1]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 2);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint32(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint32, uint, uint) {
      if (offset % 32 < 29) {
        return decodeUint32Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint32Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint32, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 3]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 4);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint64(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint64, uint, uint) {
      if (offset % 32 < 25) {
        return decodeUint64Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 48;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 40;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 32;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint64(result), bufferIdx, offset);
    }

    function decodeUint64Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) public view returns (uint64, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 48;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 40;
      result |= uint(uint8(buffers[bufferIdx][offset + 3])) << 32;
      result |= uint(uint8(buffers[bufferIdx][offset + 4])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 5])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 6])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 7]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 8);
      return (uint64(result), bufferIdx, offset);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BinaryDecoder.sol';

library PackedVarArray {
  function getString(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (string memory) {
    bytes memory result = new bytes(len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while( bufferOffset < lastOffset) {
        result[outIdx++] = buffer[bufferOffset++];
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return string(result);
  }

  function getString(bytes32[0xFFFF] storage buffers, uint16 index) external view returns (string memory) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFFFF;
    uint stringLen = stringOffsetLen >> 24;

    return getString(buffers, stringOffset, stringLen);
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (uint16[] memory) {
    uint16[] memory result = new uint16[](len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len * 2;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while (bufferOffset < lastOffset) {
        result[outIdx]  = uint16(uint8(buffer[bufferOffset++])) << 8;
        result[outIdx] |= uint16(uint8(buffer[bufferOffset++]));
        outIdx++;
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return result;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint16 index) external view returns (uint16[] memory) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;

    return getUint16Array(buffers, arrOffset, arrLen);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

