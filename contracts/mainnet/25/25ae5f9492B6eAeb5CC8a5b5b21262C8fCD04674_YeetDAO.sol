// SPDX-License-Identifier: MIT
// https://yeetdao.com
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import './Base64.sol';
import './BokkyPooBahsDateTimeLibrary.sol';

string constant SVG_HEAD = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><style>text{font-size:18px;font-weight:700}</style><defs><filter id="f"><feTurbulence type="turbulence" baseFrequency=".15" numOctaves="3" result="turbulence"/><feDisplacementMap in2="turbulence" in="SourceGraphic" scale="1.75" xChannelSelector="R" yChannelSelector="G"/></filter>';
string constant SVG_TAIL = '</svg>';
string constant TEXT_HEAD_1 = '</defs><rect width="32" height="32" style="fill:#';
string constant TEXT_HEAD_2 = '"/><text style="filter:url(#f)" x="50%" y="50%" fill="url(#c)" dominant-baseline="middle" text-anchor="middle">';
string constant TEXT_HEAD_3 = '<text x="50%" y="50%" fill="#';
string constant TEXT_HEAD_4 = '" dominant-baseline="middle" text-anchor="middle">';
string constant TEXT_TAIL = '</text>';
string constant GRADIENT_PROPS_1 = '<radialGradient id="c" cx="0.';
string constant GRADIENT_PROPS_2 = '" cy="0.';
string constant GRADIENT_PROPS_3 = '">';
string constant GRADIENT_PROPS_4 = '<stop offset="';
string constant GRADIENT_PROPS_5 = '%" stop-color="#';
string constant GRADIENT_PROPS_6 = '"/>';
string constant GRADIENT_PROPS_7 = '</radialGradient>';
string constant UNICORN_RAINBOW = hex'F09FA684F09F8C88';
string constant SIGNATURE_PREFIX = "\x19Ethereum Signed Message:\n32";

contract YeetDAO is ERC721Enumerable, Ownable {
  /**
   * Token IDs counter.
   *
   * Provides an auto-incremented ID for each token minted.
   */
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIDs;

  /**
   * Mapping of tokenIDs to characters.
   */
  mapping(uint256 => string) private _characters;

  /**
   * Mapping of membership hashes to tokenIDs.
   */
  mapping(bytes32 => uint) private _members;

  /**
   * Mapping of tokenIDs to images.
   */
  mapping(uint256 => string) private _images;

  /**
   * Max supply
   *
   * Defines the maximum collection size.
   */
  uint private _totalSupplyMax;

  /**
   * Contract URI
   *
   * Defines the contract metadata URI.
   */
  string private _contractURI;

  /**
   * Signer address
   *
   * Validation signature address.
   */
  address private _verificationSigner;

  /**
   * DAO address
   *
   * Vault for DAO split.
   */
  address private _daoAddress;

  /**
   * Token Rendering-Mode
   *
   * Returns the rendering mode.
   */
   mapping(uint => uint) private _renderingMode;

  /**
   * Time offset
   *
   * Changes the hour offset.
   */
   mapping(uint => int8) private _timezoneOffset;

  /**
   * Constructor to deploy the contract.
   *
   * Sets the initial settings for the contract.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory __contractURI,
    uint __totalSupplyMax,
    address __verificationSigner,
    address __daoAddress
  ) ERC721(_name, _symbol) {
    _contractURI = __contractURI;
    _totalSupplyMax = __totalSupplyMax;
    _verificationSigner = __verificationSigner;
    _daoAddress = __daoAddress;
  }

  /**
   * Contract metadata URI
   *
   * Provides the URI for the contract metadata.
   */
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked('ipfs://', _contractURI));
  }

  /**
   * Get the mint fee.
   *
   * Combined genesis creation + YeetDAO contribution.
   */
  function mintFee() public pure returns (uint) {
    uint genesisMint = 1 ether;
    uint daoContribution = 0.1337 ether;

    return genesisMint + daoContribution;
  }

  /**
   * Get the maximum token supply.
   *
   * Returns the upper bound on the collection size.
   */
  function totalSupplyMax() public view returns (uint) {
    return _totalSupplyMax;
  }

  /**
   * Get character tokenURI.
   *
   * Returns the tokenURI for a character.
   */
  function characterTokenURI(string memory _character) public view returns (uint) {
    bytes32 memberHash = keccak256(abi.encodePacked(_character));
    return _members[memberHash];
  }

  /**
   * PRNG
   *
   * Returns a random number.
   */
  function _rnd(string memory _key) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(_key)));
  }

  /**
   * Split Signature
   *
   * Validation utility
   */
  function _splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(sig.length == 65, "Invalid signature length.");

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
  }

  /**
   * Recover Signer
   *
   * Validation utility
   */
  function _recoverSigner(
    bytes32 _hash,
    bytes memory _sig
  ) private pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_sig);

    return ecrecover(_hash, v, r, s);
  }

  /**
   * Get Message Hash
   *
   * Validation utility.
   */
  function _getMessageHash(
    address _to,
    string memory _character,
    string memory _imageURI
  ) private pure returns (bytes32) {
    return keccak256(abi.encode(_to, _character, _imageURI));
  }

  /**
   * Get Eth Signed Message Hash
   *
   * Validation utility.
   */
  function _getEthSignedMessageHash(bytes32 _messageHash) private pure returns (bytes32) {
    return keccak256(
      abi.encodePacked(SIGNATURE_PREFIX, _messageHash)
    );
  }

  /**
   * Verify
   *
   * Validation utility.
   */
  function _verify(
    address _to,
    string memory _character,
    string memory _imageURI,
    bytes memory _signature
  ) private view returns (bool) {
    bytes32 messageHash = _getMessageHash(_to, _character, _imageURI);
    bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

    return _recoverSigner(ethSignedMessageHash, _signature) == _verificationSigner;
  }

  /**
   * Generate Image
   *
   * Returns a dynamic SVG by current time of day.
   */
  function generateImage(uint _tokenID, bool _darkMode) public view returns (string memory) {
    string[6] memory colors = ["f00", "00f", "0f0", "f0f", "0ff", "ff0"];
    uint256 r1 = _rnd(string(abi.encodePacked("r1", Strings.toString(_tokenID))));
    uint256 r2 = _rnd(string(abi.encodePacked("r2", Strings.toString(_tokenID))));

    string memory char = _characters[_tokenID];

    bytes memory out = abi.encodePacked(
      SVG_HEAD,
      GRADIENT_PROPS_1,
      Strings.toString(r1 % 100),
      GRADIENT_PROPS_2,
      Strings.toString(r2 % 100),
      GRADIENT_PROPS_3,
      GRADIENT_PROPS_4,
      "0"
    );
    out = abi.encodePacked(
      out,
      GRADIENT_PROPS_5,
      colors[r1 % colors.length],
      GRADIENT_PROPS_6,
      GRADIENT_PROPS_4,
      "75",
      GRADIENT_PROPS_5,
      colors[(r1 + 1) % colors.length],
      GRADIENT_PROPS_6
    );
    out = abi.encodePacked(
      out,
      GRADIENT_PROPS_4,
      "90",
      GRADIENT_PROPS_5,
      colors[(r1 + 2) % colors.length],
      GRADIENT_PROPS_6,
      GRADIENT_PROPS_4,
      "100",
      GRADIENT_PROPS_5
    );
    out = abi.encodePacked(
      out,
      colors[(r1 + 3) % colors.length],
      GRADIENT_PROPS_6,
      GRADIENT_PROPS_7,
      TEXT_HEAD_1,
      _darkMode ? "000" : "fff",
      TEXT_HEAD_2,
      char,
      TEXT_TAIL
    );
    out = abi.encodePacked(
      out,
      TEXT_HEAD_3,
      _darkMode ? "fff" : "000",
      TEXT_HEAD_4,
      char,
      TEXT_TAIL,
      SVG_TAIL
    );

    return string(abi.encodePacked("data:image/svg+xml;base64,",Base64.encode(bytes(out))));
  }

  /**
   * Get Timezone Offset
   *
   * Returns the added timezone offset on the dynamic renderer.
   */
  function getTimezoneOffset(uint _tokenID) public view returns (int8) {
    return _timezoneOffset[_tokenID];
  }

  /**
   * Get Image
   *
   * Returns the dynamic image by rendering mode.
   */
  function getImage(uint _tokenID) public view returns (string memory) {
    uint mode = _renderingMode[_tokenID];
    if (mode == 0) return string(abi.encodePacked("ipfs://", _images[_tokenID]));

    return generateImage(_tokenID, true);
  }

  /**
   * Get Hour
   *
   * Internal dynamic rendering utility.
   */
  function _getHour(uint _tokenID) private view returns (uint) {
    int offset = _timezoneOffset[_tokenID];
    int hour = (int(BokkyPooBahsDateTimeLibrary.getHour(block.timestamp)) + offset) % 24;

    return hour < 0 ? uint(hour + 24) : uint(hour);
  }

  /**
   * Token URI
   * Returns a base-64 encoded SVG.
   */
  function tokenURI(uint256 _tokenID) override public view returns (string memory) {
    require(_tokenID <= _tokenIDs.current(), "Token doesn't exist.");
    uint mode = _renderingMode[_tokenID];

    uint hour = _getHour(_tokenID);
    bool nightMode = hour < 5 || hour > 18;

    string memory char = _characters[_tokenID];
    string memory image = mode == 0 ? getImage(_tokenID) : generateImage(_tokenID, nightMode);
    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      '{"name":"YeetDAO #',
      Strings.toString(_tokenID),
      ' (',
      char,
      ')","description":"We are artists.\\nWe are developers.\\nWe are musicians.\\nWe are storytellers.\\nWe are curators.\\nWe are futurists.\\n\\nWe are Yeet. ',
      UNICORN_RAINBOW,
      '","attributes":[{"trait_type":"character","value":"',
      char,
      '"}',
      nightMode ? ',{"value":"gn"}' : ',{"value":"gm"}'
      ,'],"image":"',
      image,
      '"}'
    ))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  /**
   * Mint To
   *
   * Requires payment of _mintFee.
   */
  function mintTo(
    address _to,
    string memory _character,
    string memory _imageURI,
    bytes memory _signature
  ) public payable returns (uint) {
    require(_tokenIDs.current() + 1 <= _totalSupplyMax, "Total supply reached.");

    uint fee = mintFee();
    if (fee > 0) {
      require(msg.value >= fee, "Requires minimum fee.");

      uint daoSplit = 0.1337 ether;
      payable(owner()).transfer(msg.value - daoSplit);
      (bool success, ) = _daoAddress.call{value:daoSplit}("");
      require(success, "Transfer failed.");
    }

    require(_verify(msg.sender, _character, _imageURI, _signature), "Unauthorized.");

    bytes32 memberHash = keccak256(abi.encodePacked(_character));
    require(characterTokenURI(_character) == 0, "In use.");

    _tokenIDs.increment();
    uint tokenID = _tokenIDs.current();
    _mint(_to, tokenID);
    _characters[tokenID] = _character;
    _images[tokenID] = _imageURI;
    _members[memberHash] = tokenID;

    return tokenID;
  }

  /**
   * Mint
   *
   * Requires payment of _mintFee.
   */
  function mint(
    string memory _character,
    string memory _imageURI,
    bytes memory _signature
  ) public payable returns (uint) {
    return mintTo(msg.sender, _character, _imageURI, _signature);
  }

  /**
   * Update Rendering Mode
   *
   * Allows a token owner to change their rendering mode.
   */
  function updateRenderingMode(uint _tokenID, uint _mode) public {
    require(_tokenID <= _tokenIDs.current(), "Token doesn't exist.");
    require(ownerOf(_tokenID) == msg.sender, "Unauthorized.");
    require(_mode < 2, "Unsupported rendering mode.");
    require(totalSupply() == _totalSupplyMax, "Feature locked until collect is minted.");

    _renderingMode[_tokenID] = _mode;
  }

  /**
   * Update Timezone Offset
   *
   * Allows a token owner to change their timezone offset.
   */
  function updateTimezoneOffset(uint _tokenID, int8 _offset) public {
    require(_tokenID <= _tokenIDs.current(), "Token doesn't exist.");
    require(ownerOf(_tokenID) == msg.sender, "Unauthorized.");
    require(_offset > -24 && _offset < 24, "Offset overflow.");

    _timezoneOffset[_tokenID] = _offset;
  }

  /**
   * Admin function: Update Signer
   *
   * Updates the verification address.
   */
  function adminUpdateSigner(address _newSigner) public onlyOwner {
    _verificationSigner = _newSigner;
  }

  /**
   * Admin function: Update DAO safe
   *
   * Updates the DAO safe address.
   */
  function adminUpdateSafe(address _newSafe) public onlyOwner {
    _daoAddress = _newSafe;
  }
}