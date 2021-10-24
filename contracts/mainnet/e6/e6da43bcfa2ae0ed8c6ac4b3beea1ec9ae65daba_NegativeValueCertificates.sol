// SPDX-License-Identifier: MIT

import "./Dependencies.sol";

pragma solidity ^0.8.2;


contract NegativeValueCertificates is ERC721, ERC721Burnable, Ownable {
  using Strings for uint256;

  uint private _tokenIdCounter;

  bool public useURIPointer;

  string public baseUrl;
  string public baseUrlExtension;
  string public baseExternalUrl;
  string public baseImgUrl;
  string public imgExtension;
  string public projectDescription;
  string public metadataExtension;
  string public baseNamePrefix;
  string public baseNameSuffix;
  string public license;
  address public mintingAddress;

  address constant public compromisedAddress = 0x7C23C1b7e544e3e805bA675c811E287fc9d71949;
  int256 constant public parValue = -99377340000000000;


  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  constructor(address eventualOwner) ERC721('NegativeValueCertificates', 'NVC', compromisedAddress) {
    useURIPointer = false;
    baseNamePrefix = 'Negative Value Certificate #';
    baseNameSuffix = ' of 256';
    baseUrlExtension = '.json';
    baseUrl = 'https://steviep.xyz/negative-value-certificates/tokens/metadata/';
    baseImgUrl = 'https://steviep.xyz/negative-value-certificates/tokens/images/';
    baseExternalUrl = 'https://steviep.xyz/negative-value-certificates?tokenId=';
    imgExtension = '.png';
    projectDescription = "This certificate has a par value of -0.09937741 ETH, which is backed by a one two hundred fifty-sixth share of the 25.4406 ETH loss sustained by Ethereum address: 0x7c23c1b7e544e3e805ba675c811e287fc9d71949 following the public exposure of its private key on October 15, 2021 at 02:44:49 (UTC). The negative par value indicates that owners of this certificate have a reasonable expectation of loss from holding it.";
    license = 'CC BY-NC 4.0';
    _tokenIdCounter = 1;
    mintingAddress = eventualOwner;
    transferOwnership(eventualOwner);
  }

  function totalSupply() public view virtual returns (uint256) {
    return _tokenIdCounter - 1;
  }

  function safeMint(address to) public {
    require(mintingAddress == _msgSender(), 'Caller is not the minting address');
    require(_tokenIdCounter <= 256, 'Can only mint up to 256 tokens.');
    _safeMint(to, _tokenIdCounter);
    _tokenIdCounter++;
  }

  function setMintingAddress(address minter) public onlyOwner {
    mintingAddress = minter;
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory tokenString = tokenId.toString();

    if (useURIPointer) {
      return string(abi.encodePacked(baseUrl, tokenString, baseUrlExtension));
    }

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "', baseNamePrefix, tokenId.toString(), baseNameSuffix,
            '", "description": "', projectDescription, ' | License: ', license,
            '", "image": "', baseImgUrl, tokenString, imgExtension,
            '", "external_url": "', baseExternalUrl, tokenString,
            '"}'
          )
        )
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));

  }


  function flipUseURIPointer() public onlyOwner {
    useURIPointer = !useURIPointer;
  }


  function updateBaseUrl(string memory _baseUrl, string memory _baseUrlExtension) public onlyOwner {
    baseUrl = _baseUrl;
    baseUrlExtension = _baseUrlExtension;
  }

  function updateProjectDescription(
    string memory _projectDescription
  ) public onlyOwner {
    projectDescription = _projectDescription;
  }

  function updateMetadataParams(
    string memory _baseNamePrefix,
    string memory _baseNameSuffix,
    string memory _baseImgUrl,
    string memory _imgExtension,
    string memory _baseExternalUrl,
    string memory _license
  ) public onlyOwner {
    baseNamePrefix = _baseNamePrefix;
    baseNameSuffix = _baseNameSuffix;
    baseImgUrl = _baseImgUrl;
    imgExtension = _imgExtension;
    baseExternalUrl = _baseExternalUrl;
    license = _license;
  }

  function emitProjectEvent(string memory _eventType, string memory _content) public onlyOwner {
    emit ProjectEvent(_msgSender(), _eventType, _content);
  }

  function emitTokenEvent(uint256 tokenId, string memory _eventType, string memory _content) public {
    require(
      owner() == _msgSender() || ERC721.ownerOf(tokenId) == _msgSender(),
      'Only project or token owner can emit token event'
    );
    emit TokenEvent(_msgSender(), tokenId, _eventType, _content);
  }

}