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

  struct AdditionalContent {
    string contentLibraryArweaveHash;
    uint16 contentIndex;
    string contentType;
    string slug;
  }

  struct TokenState {
    uint64   soldOn;
    uint256  price;
    address  buyer;

    TokenRedemption[] redemptions;
    AdditionalContent[] additionalContent;
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

  struct MetadataAdditionalContent {
    string slug;
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
    MetadataAdditionalContent[] additionalContent;
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

  function getContentDetails(RightwayDecoder.Drop storage drop, string storage contentApi, uint16 index) public view returns (
    string memory uri,
    string memory contentLibraryArweaveHash,
    uint16 contentIndex,
    string memory contentType
  ) {
    RightwayDecoder.DropContent memory content = RightwayDecoder.decodeDropContent(drop, index);
    RightwayDecoder.DropContentLibrary storage contentLibrary = RightwayDecoder.getDropContentLibrary(drop, content.contentLibrary);

    contentIndex = content.contentIndex;
    contentLibraryArweaveHash = Base64.encode(contentLibrary.arweaveHash);
    if (content.contentType == 0) {
      contentType = 'png';
    } else if (content.contentType == 1) {
      contentType = 'jpg';
    } else if (content.contentType == 2) {
      contentType = 'svg';
    } else if (content.contentType == 3) {
      contentType = 'mp4';
    }
    uri = string(abi.encodePacked(contentApi, '/', contentLibraryArweaveHash, '/', Strings.toString(contentIndex), '.', contentType ));
  }

  function getContent(RightwayDecoder.Drop storage drop, string storage contentApi, uint16 start, uint16 length) internal view returns(MetadataContent[] memory) {
    MetadataContent[] memory result = new MetadataContent[](length);

    for(uint16 idx = 0; idx < length; idx++) {
      (result[idx].uri, result[idx].contentLibraryArweaveHash, result[idx].contentIndex, result[idx].contentType) = getContentDetails(drop, contentApi, start+idx);
    }

    return result;
  }

  function getContents(RightwayDecoder.Drop storage drop, string storage contentApi, RightwayDecoder.DropEdition memory edition, RightwayDecoder.DropTemplate memory template) internal view returns (MetadataContent[] memory) {
    MetadataContent[] memory editionContent = getContent(drop, contentApi, edition.contentStart, edition.contentLength);
    MetadataContent[] memory templateContent = getContent(drop, contentApi, template.contentStart, template.contentLength);

    uint totalContents = editionContent.length + templateContent.length;
    MetadataContent[] memory result = new MetadataContent[](totalContents);

    uint outputIdx = 0;
    for (uint idx = 0; idx < editionContent.length; idx++) {
      result[outputIdx++] = editionContent[idx];
    }

    for (uint idx = 0; idx < templateContent.length; idx++) {
      result[outputIdx++] = templateContent[idx];
    }

    return result;
  }

  function getAdditionalContent(string storage contentApi, AdditionalContent memory content ) internal pure returns (MetadataAdditionalContent memory) {
    MetadataAdditionalContent memory result;
    result.uri = string(abi.encodePacked(contentApi, '/', content.contentLibraryArweaveHash, '/', Strings.toString(content.contentIndex), '.', content.contentType ));
    result.contentLibraryArweaveHash = content.contentLibraryArweaveHash;
    result.contentIndex = content.contentIndex;
    result.contentType = content.contentType;
    result.slug = content.slug;
    return result;
  }

  function getAdditionalContents(string storage contentApi, TokenState memory state) internal pure returns (MetadataAdditionalContent[] memory) {
    MetadataAdditionalContent[] memory result = new MetadataAdditionalContent[](state.additionalContent.length);
    uint outputIdx = 0;
    for (uint idx = 0; idx < state.additionalContent.length; idx++) {
      result[outputIdx++] = getAdditionalContent(contentApi, state.additionalContent[idx]);
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
    result.content = getContents(drop, contentApi, edition, template);
    result.additionalContent = getAdditionalContents(contentApi, state);
  }

  function getStateMetadata(TokenMetadata memory result, TokenState memory state, bool isMinted) public pure {
    result.soldOn = state.soldOn;
    result.buyer = state.buyer;
    result.price = state.price;
    result.isMinted = isMinted;

    uint numRedemptions = state.redemptions.length;
    result.redemptions = new TokenRedemption[](numRedemptions);
    for (uint idx = 0; idx < numRedemptions; idx++) {
      result.redemptions[idx] = state.redemptions[idx];
    }
  }

  function getMetadata(string storage creator, RightwayDecoder.Drop storage drop, string storage contentApi, uint256 tokenId, TokenState memory state, bool isMinted) public view returns (TokenMetadata memory){
    TokenMetadata memory result;
    getTokenMetadata(result, creator, drop, contentApi, tokenId, state);
    getStateMetadata(result, state, isMinted);
    return result;
  }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

import '../sales/Saleable.sol';
import './RightwayDecoder.sol';
import './RightwayMetadata.sol';

contract RightwayToken is ERC721Enumerable, Saleable, AccessControl {
  bytes32 public constant INFRA_ROLE = keccak256('INFRA_ROLE');
  bytes32 public constant REDEEM_ROLE = keccak256('REDEEM_ROLE');
  bytes32 public constant CONTENT_ROLE = keccak256('CONTENT_ROLE');

  event TokenRedeemed(uint256 indexed tokenId);
  event TokenContentAdded(uint256 indexed tokenId);

  constructor(
    string memory name,
    string memory symbol,
    string memory newCreator
  ) ERC721(name, symbol) {
    creator = newCreator;
    dropSealed = false;
    contentApi = 'https://tbd.io/content';
    metadataApi = string(abi.encodePacked('https://tbd.io/metadata/', addressToString(address(this)), '/'));
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }


  string public creator;
  address payable public     royaltyAddress;
  uint256 public             royaltyBps;

  /*
   * drop information
   */
  RightwayDecoder.Drop internal drop;
  bool public dropSealed;

  mapping(uint256 => RightwayMetadata.TokenState) internal stateByToken;

  /*
   * hosting information
   */
  string internal contentApi;
  string internal metadataApi;

  modifier unsealed() {
    require(!dropSealed, 'drop is sealed');
    _;
  }

  modifier issealed() {
    require(dropSealed, 'drop is not sealed');
    _;
  }

  function setDropRoyalties( address payable newRoyaltyAddress, uint256 newRoyaltyBps ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyAddress = newRoyaltyAddress;
    royaltyBps = newRoyaltyBps;
  }

  function setApis( string calldata newContentApi, string calldata newMetadataApi ) public onlyRole(INFRA_ROLE) {
    contentApi = newContentApi;
    metadataApi = string(abi.encodePacked(newMetadataApi, '/', addressToString(address(this)), '/'));
  }

  function addDropContentLibraries( RightwayDecoder.DropContentLibrary[] memory contentLibraries ) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    for (uint idx = 0; idx < contentLibraries.length; idx++) {
      drop.contentLibraries.push(contentLibraries[idx]);
    }
  }

  function addDropContent( bytes32[] calldata content, uint offset ) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < content.length) {
      drop.content[offset + idx] = content[idx];
      idx++;
    }
  }

  function addDropStringData( bytes32[] calldata stringData, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < stringData.length) {
      drop.stringData[offset + idx] = stringData[idx];
      idx++;
    }
  }

  function addDropSentences( bytes32[] calldata sentences, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < sentences.length) {
      drop.sentences[offset + idx] = sentences[idx];
      idx++;
    }
  }

  function addDropAttributes( bytes32[] calldata attributes, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < attributes.length) {
      drop.attributes[offset + idx] = attributes[idx];
      idx++;
    }
  }

  function addDropTemplates( bytes32[] calldata templates, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < templates.length) {
      drop.templates[offset + idx] = templates[idx];
      idx++;
    }
  }

  function addDropEditions( bytes32[] calldata editions, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < editions.length) {
      drop.editions[offset + idx] = editions[idx];
      idx++;
    }
  }

  function addDropTokens( bytes32[] calldata tokens, uint offset, uint length) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < tokens.length) {
      drop.tokens[offset + idx] = tokens[idx];
      idx++;
    }
    drop.numTokens = length;
  }

  function sealDrop() public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    dropSealed = true;
  }

  function addTokenContent( uint256[] calldata tokens, string calldata slug, string calldata contentLibraryArweaveHash, uint16 contentIndex, string calldata contentType) public onlyRole(CONTENT_ROLE) issealed {
    for (uint idx = 0; idx < tokens.length; idx++) {
      require(_exists(tokens[idx]), 'No such token');
      stateByToken[tokens[idx]].additionalContent.push();
      uint cidx = stateByToken[tokens[idx]].additionalContent.length - 1;
      stateByToken[tokens[idx]].additionalContent[cidx].contentLibraryArweaveHash = contentLibraryArweaveHash;
      stateByToken[tokens[idx]].additionalContent[cidx].contentIndex = contentIndex;
      stateByToken[tokens[idx]].additionalContent[cidx].contentType = contentType;
      stateByToken[tokens[idx]].additionalContent[cidx].slug = slug;
      emit TokenContentAdded(tokens[idx]);
    }
  }

  function mint(address to, uint256 tokenId, uint16 attributesStart, uint16 attributesLength) public onlyRole(DEFAULT_ADMIN_ROLE) issealed {
    require(drop.numTokens > tokenId, 'No such token');
    _safeMint(to, tokenId);
    RightwayMetadata.TokenState storage state = stateByToken[tokenId];
    state.attributesStart = attributesStart;
    state.attributesLength = attributesLength;
  }

  function mintBatch(address to, uint256[] calldata tokenIds, uint16 attributesStart, uint16 attributesLength) public onlyRole(DEFAULT_ADMIN_ROLE) issealed {
    for (uint idx = 0; idx < tokenIds.length; idx++) {
      mint(to, tokenIds[idx], attributesStart, attributesLength);
    }
  }

  function redeem(uint256 tokenId, uint64 timestamp, string memory memo) public onlyRole(REDEEM_ROLE) issealed {
    require(_exists(tokenId), 'No such token');
    RightwayMetadata.TokenState storage state = stateByToken[tokenId];
    state.redemptions.push();
    uint redemptionIdx = state.redemptions.length - 1;
    RightwayMetadata.TokenRedemption storage record = state.redemptions[redemptionIdx];
    record.timestamp = timestamp;
    record.memo = memo;
    emit TokenRedeemed(tokenId);
  }

  function addressToString(address addr) internal pure returns(string memory) {
    bytes32 value = bytes32(uint256(uint160(addr)));
    bytes memory alphabet = '0123456789abcdef';

    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < 20; i++) {
      str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }

  function getMetadata(uint256 tokenId) public view returns (RightwayMetadata.TokenMetadata memory) {
    RightwayMetadata.TokenState memory state;
    bool isMinted = false;
    if (_exists(tokenId)) {
      state = stateByToken[tokenId];
      isMinted = true;
    }

    return RightwayMetadata.getMetadata(creator, drop, contentApi, tokenId, state, isMinted);
  }

   /**
    * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
    * in child contracts.
    */
  function _baseURI() internal view virtual override returns (string memory) {
    return metadataApi;
  }

  /**
   *  @dev Saleable interface
   */
  function _processSaleOffering(uint256 offeringId, address buyer, uint256 price) internal override issealed {
    require(drop.numTokens > offeringId, 'No such token');
    _safeMint(buyer, offeringId);
    RightwayMetadata.TokenState storage state = stateByToken[offeringId];

    // solhint-disable-next-line not-rely-on-time
    state.soldOn = uint64(block.timestamp);
    state.buyer = buyer;
    state.price = price;
  }

  function registerSeller(address seller) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _registerSeller(seller);
  }

  function deregisterSeller(address seller) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _deregisterSeller(seller);
  }

  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721Enumerable) returns (bool) {
      return interfaceId == _INTERFACE_ID_FEES || AccessControl.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
  }

  function getFeeRecipients(uint256) public view returns (address payable[] memory) {
    address payable[] memory result = new address payable[](1);
    result[0] = royaltyAddress;
    return result;
  }

  function getFeeBps(uint256) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = royaltyBps;
    return result;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISaleable {
  function processSale(uint256 offeringId, address buyer, uint256 price) external;

  function getSellersFor(uint256 offeringId) external view returns (address[] memory sellers);

  event SellerAdded(address indexed seller, uint256 indexed offeringId);
  event SellerRemoved(address indexed seller, uint256 indexed offeringId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ISaleable.sol';

abstract contract Saleable is ISaleable {
  mapping(uint256 => address[]) public authorizedSellersByOffer;
  mapping(address => bool) public authorizedSellersAllOffers;

  function isAuthorizedSellerOf(address seller, uint256 offeringId) public view returns (bool) {
    if (authorizedSellersAllOffers[seller]) {
      return true;
    }

    for (uint256 idx = 0; idx < authorizedSellersByOffer[offeringId].length; idx++) {
      if (authorizedSellersByOffer[offeringId][idx] == seller) {
        return true;
      }
    }

    return false;
  }

  function _processSaleOffering(uint256, address, uint256) internal virtual {
    require(false, 'Unimplemented');
  }

  function processSale(uint256 offeringId, address buyer, uint256 price) public override {
    require(isAuthorizedSellerOf(msg.sender, offeringId), 'Seller not authorized');
    _processSaleOffering(offeringId, buyer, price);
  }

  function _registerSeller(uint256 offeringId, address seller) internal {
    require(!isAuthorizedSellerOf(seller, offeringId), 'Seller is already authorized');
    authorizedSellersByOffer[offeringId].push(seller);
  }

  function _registerSeller(address seller) internal {
    authorizedSellersAllOffers[seller] = true;
  }

  function _deregisterSeller(uint256 offeringId, address seller) internal {
    require(isAuthorizedSellerOf(seller, offeringId), 'Seller was not authorized');
    uint256 index = 0;
    for (; index < authorizedSellersByOffer[offeringId].length; index++) {
      if (authorizedSellersByOffer[offeringId][index] == seller) {
        break;
      }
    }

    uint256 len = authorizedSellersByOffer[offeringId].length;
    if (index < len - 1) {
      address temp = authorizedSellersByOffer[offeringId][index];
      authorizedSellersByOffer[offeringId][index] = authorizedSellersByOffer[offeringId][len];
      authorizedSellersByOffer[offeringId][len] = temp;
    }

    authorizedSellersByOffer[offeringId].pop();
  }

  function _deregisterSeller(address seller) internal {
    authorizedSellersAllOffers[seller] = false;
  }

  function getSellersFor(uint256 offeringId) public view override returns (address[] memory sellers) {
    sellers = authorizedSellersByOffer[offeringId];
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

    function decodeUint8(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint8, uint, uint) {
      uint8 result = 0;
      result |= uint8(buffers[bufferIdx][offset]);
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (result, bufferIdx, offset);
    }

    function decodeUint16(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
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

    function decodeUint16Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 1]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 2);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint32(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
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

    function decodeUint32Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 3]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 4);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint64(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
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

    function decodeUint64Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
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

  function getString(bytes32[0xFFFF] storage buffers, uint16 index) internal view returns (string memory) {
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

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint16 index) internal view returns (uint16[] memory) {
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

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/home/bart/git/InfinityTokens-contract/contracts/custom/RightwayMetadata.sol": {
      "RightwayMetadata": "0xEdbF1D9Ab63294cDA3965CafDA82E1F8A23A66E5"
    },
    "/home/bart/git/InfinityTokens-contract/contracts/custom/RightwayDecoder.sol": {
      "RightwayDecoder": "0xcFD8AE98cA84D8314ad985ab8787F481c1C1927e"
    }
  },
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