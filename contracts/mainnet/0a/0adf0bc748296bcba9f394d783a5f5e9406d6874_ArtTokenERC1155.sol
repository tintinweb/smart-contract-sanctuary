// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./Ownable.sol";
import './ERC1155.sol';
import './ERC1155MintBurn.sol';
import './IERC1155Metadata.sol';
import "./StringsUtil.sol";

contract ArtTokenERC1155 is IERC1155Metadata, ERC1155, ERC1155MintBurn, Ownable {
  using StringsUtil for string;

  uint256 private _currentTokenID = 0;
  mapping (uint256 => uint256) public tokenSupply;

  string internal baseMetadataURI;
  mapping (uint256 => string) internal _tokenURIs;


  /*
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  //  function _logURIs(uint256[] memory _tokenIDs) internal {
  //    string memory baseURL = baseMetadataURI;
  //    string memory tokenURI;
  //
  //    for (uint256 i = 0; i < _tokenIDs.length; i++) {
  //      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
  //      emit URI(tokenURI, _tokenIDs[i]);
  //    }
  //  }

  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  mapping (uint256 => address) public creators;

  mapping(bytes32 => bool) private _uniqTitleSet;

  constructor() {
    name = "Portion Art Token";
    symbol = "PAT";
  }

  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }

  /**
    * @dev Creates a new token type and assigns _quantity to an creator (i.e. the message sender)
    * @param _title unique art title
    * @param _quantity art's quantity
    * @param _uri token's type metadata uri
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
  function createArt(
    bytes32 _title,
    uint256 _quantity,
    string calldata _uri,
    bytes calldata _data
  ) external returns (uint) {
    bytes32 hash = keccak256(abi.encodePacked(_title));
    require(!_uniqTitleSet[hash], "ArtTokenERC1155#createArt: TITLE_NOT_UNIQUE");
    _uniqTitleSet[hash] = true;

    _currentTokenID += 1;
    uint256 _id = _currentTokenID;

    creators[_id] = msg.sender;

    if (bytes(_uri).length > 0) {
      _tokenURIs[_id] = _uri;
      emit URI(_uri, _id);
    } else {
      require(bytes(baseMetadataURI).length > 0, "ArtTokenERC1155#createArt: NO_DEFAULT_URI");
    }

    _mint(_msgSender(), _id, _quantity, _data);
    tokenSupply[_id] = _quantity;
    return _id;
  }


  /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }


  function uri(
    uint256 _id
  ) public override view returns (string memory) {
    require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");

    string memory _tokenURI = _tokenURIs[_id];

    if (bytes(baseMetadataURI).length == 0) {
      return _tokenURI;
    }

    return StringsUtil.strConcat(baseMetadataURI, StringsUtil.uint2str(_id), ".json");
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155Metadata).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }

  /**
    * @dev Returns whether the specified token exists by checking to see if it has a creator
    * @param _id uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return creators[_id] != address(0);
  }
}