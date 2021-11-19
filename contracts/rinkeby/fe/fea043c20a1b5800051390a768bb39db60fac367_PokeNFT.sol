/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

abstract contract Owned {
    address public owner;
    address public manager;

    constructor() {
        owner = msg.sender;
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function transferManager(address newManager) public onlyOwner {
        manager = newManager;
    }
}

interface KAP721Metadata{
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

library AddressUtils {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface KAP165 {
  function supportsInterface( bytes4 _interfaceID ) external view returns (bool);
}

contract SupportsInterface is KAP165 {

  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor() {
    supportedInterfaces[0x01ffc9a7] = true; // KAP165
  }

  function supportsInterface( bytes4 _interfaceID ) external override view returns (bool) {
    return supportedInterfaces[_interfaceID];
  }
}

interface KAP721TokenReceiver {
  function onKAP721Received( address _operator, address _from, uint256 _tokenId, bytes calldata _data ) external returns(bytes4);
}

interface KAP721 {

  event Transfer( address indexed _from, address indexed _to, uint256 indexed _tokenId );
  event Approval( address indexed _owner, address indexed _approved, uint256 indexed _tokenId );
  event ApprovalForAll( address indexed _owner, address indexed _operator, bool _approved );

  function safeTransferFrom( address _from, address _to, uint256 _tokenId, bytes calldata _data ) external;
  function safeTransferFrom( address _from, address _to, uint256 _tokenId ) external;
  function transferFrom( address _from, address _to, uint256 _tokenId ) external;
  function approve( address _approved, uint256 _tokenId ) external;
  function setApprovalForAll( address _operator, bool _approved ) external;
  function balanceOf( address _owner ) external view returns (uint256);
  function ownerOf( uint256 _tokenId ) external view returns (address);
  function getApproved( uint256 _tokenId ) external view returns (address);
  function isApprovedForAll( address _owner, address _operator ) external view returns (bool);
}

contract NFToken is KAP721, SupportsInterface {
  using AddressUtils for address;

  bytes4 internal constant MAGIC_ON_KAP721_RECEIVED = 0x150b7a02;

  mapping (uint256 => address) internal idToOwner;
  mapping (uint256 => address) internal idToApproval;
  mapping (address => uint256) private ownerToTokenCount;
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  modifier canOperate( uint256 _tokenId ) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]
    );
    _;
  }

  modifier canTransfer( uint256 _tokenId ) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );
    _;
  }

  modifier validNFToken( uint256 _tokenId ) {
    require(idToOwner[_tokenId] != address(0));
    _;
  }

  constructor() {
    supportedInterfaces[0x80ac58cd] = true; // KAP721
  }

  function safeTransferFrom( address _from, address _to, uint256 _tokenId, bytes calldata _data ) external override { 
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom( address _from, address _to, uint256 _tokenId ) external override {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom( address _from, address _to, uint256 _tokenId ) external override canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);
  }

  function approve( address _approved, uint256 _tokenId ) external override canOperate(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll( address _operator, bool _approved ) external override {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf( address _owner ) external override view returns (uint256) {
    require(_owner != address(0));
    return _getTokenCount(_owner);
  }

  function ownerOf( uint256 _tokenId ) external override view returns (address _owner) {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0));
  }

  function getApproved( uint256 _tokenId ) external override view validNFToken(_tokenId) returns (address) {
    return idToApproval[_tokenId];
  }

  function isApprovedForAll( address _owner, address _operator ) external override view returns (bool) {
    return ownerToOperators[_owner][_operator];
  }

  function _transfer( address _to, uint256 _tokenId ) internal { 
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeToken(from, _tokenId);
    _addToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }

  function _mint( address _to, uint256 _tokenId ) internal virtual {
    require(_to != address(0));
    require(idToOwner[_tokenId] == address(0));

    _addToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  function _burn( uint256 _tokenId ) internal virtual validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }


  function _removeToken( address _from, uint256 _tokenId ) internal virtual {
    require(idToOwner[_tokenId] == _from);
    ownerToTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  function _addToken( address _to, uint256 _tokenId ) internal virtual { 
    require(idToOwner[_tokenId] == address(0));
    idToOwner[_tokenId] = _to;
    ownerToTokenCount[_to] += 1;
  }

  function _getTokenCount( address _owner ) internal virtual view returns (uint256) {
    return ownerToTokenCount[_owner];
  }

  function _safeTransferFrom( address _from, address _to, uint256 _tokenId, bytes memory _data ) private canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);

    if (_to.isContract()){
      bytes4 retval = KAP721TokenReceiver(_to).onKAP721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_KAP721_RECEIVED);
    }
  }

  function _clearApproval(
    uint256 _tokenId
  )
    private {
    delete idToApproval[_tokenId];
  }

}

contract NFTokenMetadata is
  NFToken,
  KAP721Metadata {

  string internal nftName;
  string internal nftSymbol;
  string internal baseUri='https://ipfs.infura.io/ipfs/';
  mapping (uint256 => string) internal idToUri;

  constructor() {
    supportedInterfaces[0x5b5e139f] = true;
  }

  function name() external override view returns (string memory _name) {
    _name = nftName;
  }

  function symbol() external override view returns (string memory _symbol) {
    _symbol = nftSymbol;
  }

  function tokenURI( uint256 _tokenId ) external override view validNFToken(_tokenId) returns (string memory) {
    return string(abi.encodePacked(baseUri, idToUri[_tokenId]));
  }

  function _burn( uint256 _tokenId ) internal override virtual {
    super._burn(_tokenId);
    delete idToUri[_tokenId];
  }

  function _setBaseUri( string memory _uri ) internal {
    baseUri =  _uri;
  }
  function _setTokenUri( uint256 _tokenId, string memory _uri ) internal validNFToken(_tokenId) {
    idToUri[_tokenId] =  _uri;
  }
}
 
contract PokeNFT is NFTokenMetadata, Owned {
 
  uint tokenId = 0;
  
  constructor() {
    nftName = "Poke NFT";
    nftSymbol = "POKE";
  }
 
  function mint(address _to, string calldata _hash) external onlyOwner {
    tokenId++;
    super._mint(_to, tokenId);
    super._setTokenUri(tokenId, _hash);
  }
 
}