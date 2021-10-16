// SPDX-License-Identifier: MIT
// https://hypeblocks.com
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import './Base64.sol';

string constant SIGNATURE_PREFIX = "\x19Ethereum Signed Message:\n32";

contract HypeBlocks is ERC721Enumerable, Ownable {
  /**
   * Token IDs counter.
   *
   * Provides an auto-incremented ID for each token minted.
   */
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIDs;
  Counters.Counter private _generalCollection;
  Counters.Counter private _curatedCollection;
  Counters.Counter private _limitedCollection;
  Counters.Counter private _hypeCollection;

  /**
   * Collection upper bounds.
   *
   * Curated: 10,000
   * Limited: 1,000
   * Hype: 100
   */
  uint private _totalCurated;
  uint private _totalLimited;
  uint private _totalHype;

  /**
   * Collection mint fees.
   */
  uint private _feeCurated;
  uint private _feeLimited;
  uint private _feeHype;

  /**
   * Mapping of tokenIDs to hypecode.
   */
  mapping(uint256 => bytes) private _hypecodes;

  /**
   * Mapping of artwork hashes to tokenIDs.
   */
  mapping(bytes32 => uint) private _proofOfHype;

  /**
   * Mapping of token to collection.
   */
  mapping(uint => uint) private _tokenCollection;

  /**
   * Mapping of token to image.
   */
  mapping(uint => string) private _images;

  /**
   * Mapping of token to creator.
   */
  mapping(uint => address) private _creators;

  /**
   * Collection sets.
   */
  uint[] private _generalTokens;
  uint[] private _curatedTokens;
  uint[] private _limitedTokens;
  uint[] private _hypeTokens;

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
   * Constructor to deploy the contract.
   *
   * Sets the initial settings for the contract.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory __contractURI,
    address __verificationSigner,
    uint __totalCurated,
    uint __totalLimited,
    uint __totalHype,
    uint __feeCurated,
    uint __feeLimited,
    uint __feeHype
  ) ERC721(_name, _symbol) {
    _contractURI = __contractURI;
    _verificationSigner = __verificationSigner;
    _totalCurated = __totalCurated;
    _totalLimited = __totalLimited;
    _totalHype = __totalHype;
    _feeCurated = __feeCurated;
    _feeLimited = __feeLimited;
    _feeHype = __feeHype;
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
   * Curated total supply
   *
   * Gets the maximum curated collection size.
   */
  function curatedTotalSupply() public view returns (uint) {
    return _totalCurated;
  }

  /**
   * Limited total supply
   *
   * Gets the maximum limited collection size.
   */
  function limitedTotalSupply() public view returns (uint) {
    return _totalLimited;
  }

  /**
   * Hype total supply
   *
   * Gets the maximum hype collection size.
   */
  function hypeTotalSupply() public view returns (uint) {
    return _totalHype;
  }

  /**
   * Total general
   *
   * Gets the general collection size.
   */
  function totalGeneral() public view returns (uint) {
    return _generalCollection.current();
  }


  /**
   * Total curated
   *
   * Gets the curated collection size.
   */
  function totalCurated() public view returns (uint) {
    return _curatedCollection.current();
  }

  /**
   * Total limited
   *
   * Gets the limited collection size.
   */
  function totalLimited() public view returns (uint) {
    return _limitedCollection.current();
  }

  /**
   * Total hype
   *
   * Gets the hype collection size.
   */
  function totalHype() public view returns (uint) {
    return _hypeCollection.current();
  }

  /**
   * Get hype
   *
   * Gets the hypecode associated with a tokenID.
   */
  function getHypecode(uint _tokenID) public view returns (bytes memory) {
    require(_tokenID > 0 && _tokenID <= _tokenIDs.current(), "Token doesn't exist.");

    return _hypecodes[_tokenID];
  }

  /**
   * Get artist
   *
   * Gets the creator of a token.
   */
  function getArtist(uint _tokenID) public view returns (address) {
    require(_tokenID > 0 && _tokenID <= _tokenIDs.current(), "Token doesn't exist.");

    return _creators[_tokenID];
  }

  /**
   * Get collection token
   *
   * Gets the token by collection index.
   */
  function getCollectionToken(uint _collection, uint _idx) public view returns (uint) {
    require(_collection < 4, "Collection doesn't exist.");

    if (_collection == 0) {
      require(_idx + 1 < _generalCollection.current(), "Token doesn't exist.");
      return _generalTokens[_idx];
    } else if (_collection == 1) {
      require(_idx + 1 < _curatedCollection.current(), "Token doesn't exist.");
      return _curatedTokens[_idx];
    } else if (_collection == 2) {
      require(_idx + 1 < _limitedCollection.current(), "Token doesn't exist.");
      return _limitedTokens[_idx];
    } else {
      require(_idx + 1 < _hypeCollection.current(), "Token doesn't exist.");
      return _hypeTokens[_idx];
    }
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
    bytes memory _hypecode,
    string memory _imageURI
  ) private pure returns (bytes32) {
    return keccak256(abi.encode(_to, _hypecode, _imageURI));
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
    bytes memory _hypecode,
    string memory _imageURI,
    bytes memory _signature
  ) private view returns (bool) {
    bytes32 messageHash = _getMessageHash(_to, _hypecode, _imageURI);
    bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

    return _recoverSigner(ethSignedMessageHash, _signature) == _verificationSigner;
  }

  /**
   * Token URI
   * Returns a base-64 encoded SVG.
   */
  function tokenURI(uint256 _tokenID) override public view returns (string memory) {
    require(_tokenID <= _tokenIDs.current(), "Token doesn't exist.");

    string memory collection = _collectionName(_tokenCollection[_tokenID]);

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      '{"name":"HypeBlocks #',
      Strings.toString(_tokenID),
      '","description":"HypeBlocks is the hypest collaboration of on-chain generative artwork. A collective of crypto artists from across the metaverse have gathered here to share works of profound beauty and inspiration through the language of hypecode. There are 3 curated collections of ascending rarity: Curated, Limited, and Hype.","attributes":[{"value":"',
      collection,
      '"}],"image":"ipfs://',
      _images[_tokenID],
      '"}'
    ))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  /**
   * Collection name
   *
   * Internal helper to get the collection name.
   */
  function _collectionName(uint _collection) private pure returns (string memory) {
    if (_collection == 1) return "Curated";
    if (_collection == 2) return "Limited";
    if (_collection == 3) return "Hype";

    return "General";
  }

  /**
   * Mint Fee
   *
   * Gets the artwork minting fee by collection rarity.
   */
  function mintFee(uint _collection) public view returns (uint) {
    if (_collection == 1) return _feeCurated; // Curated
    if (_collection == 2) return _feeLimited; // Limited
    if (_collection == 3) return _feeHype; // Hype

    return 0; // General
  }

  /**
   * Mint To
   *
   * Requires payment of _mintFee.
   */
  function mintTo(
    address _to,
    uint _collection,
    bytes memory _hypecode,
    string memory _imageURI,
    bytes memory _signature
  ) public payable returns (uint) {
    uint fee = mintFee(_collection);
    if (fee > 0) {
      require(msg.value >= fee, "Requires minimum fee.");

      payable(owner()).transfer(msg.value);
    }

    require(_verify(msg.sender, _hypecode, _imageURI, _signature), "Unauthorized.");

    bytes32 hypeHash = keccak256(abi.encodePacked(_hypecode));
    require(_proofOfHype[hypeHash] == 0, "In use.");

    _tokenIDs.increment();
    uint tokenID = _tokenIDs.current();

    _mint(_to, tokenID);
    _proofOfHype[hypeHash] = tokenID;
    _tokenCollection[tokenID] = _collection;
    _hypecodes[tokenID] = _hypecode;
    _images[tokenID] = _imageURI;
    _creators[tokenID] = msg.sender;

    if (_collection == 0) {
      _generalCollection.increment();
      _generalTokens.push(tokenID);
    } else if (_collection == 1) {
      require(_curatedCollection.current() < _totalCurated, "Curated collection complete.");
      _curatedCollection.increment();
      _curatedTokens.push(tokenID);
    } else if (_collection == 2) {
      require(_limitedCollection.current() < _totalLimited, "Limited collection complete.");
      _limitedCollection.increment();
      _limitedTokens.push(tokenID);
    } else if (_collection == 3) {
      require(_hypeCollection.current() < _totalHype, "Hype collection complete.");
      _hypeCollection.increment();
      _hypeTokens.push(tokenID);
    } else if (_collection > 3) {
      revert("Unknown collection.");
    }

    return tokenID;
  }

  /**
   * Mint
   *
   * Requires contribution of _mintFee.
   */
  function mint(
    uint _collection,
    bytes memory _hypecode,
    string memory _imageURI,
    bytes memory _signature
  ) public payable returns (uint) {
    return mintTo(msg.sender, _collection, _hypecode, _imageURI, _signature);
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
   * Admin function: Update fee
   *
   * Updates the mint fee for a collection.
   */
  function adminUpdateFee(uint _collection, uint _fee) public onlyOwner {
    if (_collection == 1) {
      _feeCurated = _fee;
    } else if (_collection == 2) {
      _feeLimited = _fee;
    } else if (_collection == 3) {
      _feeHype = _fee;
    }
  }
}