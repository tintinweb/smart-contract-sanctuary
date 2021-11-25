// SPDX-License-Identifier: MIT


/*
  /$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$    /$$ /$$$$$$ /$$$$$$$$ /$$$$$$$
 /$$__  $$|__  $$__/| $$_____/| $$   | $$|_  $$_/| $$_____/| $$__  $$
| $$  \__/   | $$   | $$      | $$   | $$  | $$  | $$      | $$  \ $$
|  $$$$$$    | $$   | $$$$$   |  $$ / $$/  | $$  | $$$$$   | $$$$$$$/
 \____  $$   | $$   | $$__/    \  $$ $$/   | $$  | $$__/   | $$____/
 /$$  \ $$   | $$   | $$        \  $$$/    | $$  | $$      | $$
|  $$$$$$/   | $$   | $$$$$$$$   \  $/    /$$$$$$| $$$$$$$$| $$
 \______/    |__/   |________/    \_/    |______/|________/|__/

*/

import "./Dependencies.sol";

pragma solidity ^0.8.2;


contract NaturalFlavors is ERC721, ERC721Burnable, Ownable {
  using Strings for uint256;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  uint private _tokenIdCounter;

  string public baseDefaultUrl;
  string public baseDefaultUrlExtension;

  string public license;

  address public mintingAddress;
  address public royaltyBenificiary;
  uint public royaltyBasisPoints;

  mapping(uint256 => string) public tokenIdToMetadata;

  event ProjectEvent(address indexed poster, string indexed eventType, string content);
  event TokenEvent(address indexed poster, uint256 indexed tokenId, string indexed eventType, string content);

  constructor(
    string memory _baseDefaultUrl
  ) ERC721('NaturalFlavors', 'FLAV') {
    baseDefaultUrl = _baseDefaultUrl;
    baseDefaultUrlExtension = '.json';

    license = 'CC BY-NC 4.0';

    royaltyBasisPoints = 750;
    _tokenIdCounter = 0;

    mintingAddress = msg.sender;
    royaltyBenificiary = msg.sender;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _tokenIdCounter - 1;
  }

  function mint(address to) public {
    require(mintingAddress == _msgSender(), 'Caller is not the minting address');
    _mint(to, _tokenIdCounter);
    _tokenIdCounter++;
  }

  function batchMint(address[] memory addresses) public {
    require(mintingAddress == _msgSender(), 'Caller is not the minting address');
    for (uint i = 0; i < addresses.length; i++) {
      _mint(addresses[i], _tokenIdCounter);
      _tokenIdCounter++;
    }
  }

  function setMintingAddress(address minter) public onlyOwner {
    mintingAddress = minter;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    bytes memory stringBytes = bytes(tokenIdToMetadata[tokenId]);
    if (stringBytes.length == 0) {
      string memory tokenString = tokenId.toString();
      return string(abi.encodePacked(baseDefaultUrl, tokenString, baseDefaultUrlExtension));
    }

    string memory json = Base64.encode(stringBytes);
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function updateBaseUrl(string memory _baseDefaultUrl, string memory _baseUrlExtension) public onlyOwner {
    baseDefaultUrl = _baseDefaultUrl;
    baseDefaultUrlExtension = _baseUrlExtension;
  }

  function updateTokenMetadata(
    uint256 tokenId,
    string memory tokenMetadata
  ) public onlyOwner {
    tokenIdToMetadata[tokenId] = tokenMetadata;
  }

  function updateLicense(
    string memory _license
  ) public onlyOwner {
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

  function updatRoyaltyInfo(
    address _royaltyBenificiary,
    uint256 _royaltyBasisPoints
  ) public onlyOwner {
    royaltyBenificiary = _royaltyBenificiary;
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
    return (royaltyBenificiary, _salePrice * royaltyBasisPoints / 10000);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
  }
}