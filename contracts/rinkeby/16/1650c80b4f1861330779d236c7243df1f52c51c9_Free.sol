// SPDX-License-Identifier: MIT

import "./Dependencies.sol";

// import "hardhat/console.sol";


pragma solidity ^0.8.11;


contract Free is ERC721, Ownable {
  using Strings for uint256;
  uint256 private _tokenIdCounter;
  uint256 private _collectionIdCounter;

  string constant public license = 'CC0';

  struct Metadata {
    uint256 collectionId;
    string namePrefix;
    string externalUrl;
    string imgUrl;
    string imgExtension;
    string description;
  }

  mapping(uint256 => Metadata) public collectionIdToMetadata;
  mapping(uint256 => uint256) public tokenIdToCollectionId;
  mapping(uint256 => uint256) public tokenIdToCollectionCount;
  mapping(uint256 => address) public collectionIdToMinter;
  mapping(uint256 => uint256) public collectionSupply;
  mapping(uint256 => string) public tokenIdToAttributes;
  mapping(address => bool) attributeUpdateAllowList;


  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  constructor() ERC721('Free', 'FREE') {
    _tokenIdCounter = 0;
    _collectionIdCounter = 0;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _tokenIdCounter;
  }

  function createCollection(
    address minter,
    string calldata _namePrefix,
    string calldata _externalUrl,
    string calldata _imgUrl,
    string calldata _imgExtension,
    string calldata _description
  ) public onlyOwner {
    collectionIdToMinter[_collectionIdCounter] = minter;
    attributeUpdateAllowList[minter] = true;

    Metadata storage metadata = collectionIdToMetadata[_collectionIdCounter];
    metadata.namePrefix = _namePrefix;
    metadata.externalUrl = _externalUrl;
    metadata.imgUrl = _imgUrl;
    metadata.imgExtension = _imgExtension;
    metadata.description = _description;

    _collectionIdCounter++;
  }

  function mint(uint256 collectionId, address to) public {
    require(collectionIdToMinter[collectionId] == _msgSender(), 'Caller is not the minting address');
    require(collectionId < _collectionIdCounter, 'Collection ID does not exist');

    _mint(to, _tokenIdCounter);
    tokenIdToCollectionId[_tokenIdCounter] = collectionId;

    tokenIdToCollectionCount[_tokenIdCounter] = collectionSupply[collectionId];
    collectionSupply[collectionId]++;
    _tokenIdCounter++;
  }

  function appendAttributeToToken(uint256 tokenId, string calldata attrKey, string calldata attrValue) public {
    require(attributeUpdateAllowList[msg.sender], "Sender not on attribute update allow list.");

    string memory existingAttrs = tokenIdToAttributes[tokenId];

    tokenIdToAttributes[tokenId] = string(abi.encodePacked(
      existingAttrs, ',{"trait_type":"', attrKey,'","value":', attrValue,'}'
    ));
  }


  function setMintingAddress(uint256 collectionId, address minter) public onlyOwner {
    require(collectionId < _collectionIdCounter, 'Collection ID does not exist');

    address existingMinter = collectionIdToMinter[collectionId];
    attributeUpdateAllowList[existingMinter] = false;
    attributeUpdateAllowList[minter] = true;
    collectionIdToMinter[collectionId] = minter;
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    Metadata memory metadata = collectionIdToMetadata[tokenIdToCollectionId[tokenId]];
    string memory tokenIdString = tokenId.toString();
    string memory collectionIdString = tokenIdToCollectionId[tokenId].toString();
    string memory collectionCountString = tokenIdToCollectionCount[tokenId].toString();
    string memory tokenAttributes = tokenIdToAttributes[tokenId];

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "', metadata.namePrefix, collectionCountString,
            '", "description": "', metadata.description,
            '", "license": "', license,
            '", "image": "', metadata.imgUrl, metadata.imgExtension,
            '", "external_url": "', metadata.externalUrl, '?collectionId=', collectionIdString, '&tokenId=', tokenIdString,
            '", "attributes": [{"trait_type":"Collection", "value":"', collectionIdString,'"}', tokenAttributes, ']}'
          )
        )
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));

  }


  function updateMetadataParams(
    uint256 collectionId,
    string calldata _namePrefix,
    string calldata _externalUrl,
    string calldata _imgUrl,
    string calldata _imgExtension,
    string calldata _description
  ) public onlyOwner {
    Metadata storage metadata = collectionIdToMetadata[collectionId];

    metadata.namePrefix = _namePrefix;
    metadata.externalUrl = _externalUrl;
    metadata.imgUrl = _imgUrl;
    metadata.imgExtension = _imgExtension;
    metadata.description = _description;
  }

  function emitProjectEvent(string calldata _eventType, string calldata _content) public onlyOwner {
    emit ProjectEvent(_msgSender(), _eventType, _content);
  }

  function emitTokenEvent(uint256 tokenId, string calldata _eventType, string calldata _content) public {
    require(
      owner() == _msgSender() || ERC721.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, _eventType, _content);
  }
}