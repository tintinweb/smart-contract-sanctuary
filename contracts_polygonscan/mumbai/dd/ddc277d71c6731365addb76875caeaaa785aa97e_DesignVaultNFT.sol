/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;

library AddressUtils {
  function isContract(address _address) internal view returns (bool addressCheck){
    bytes32 codeHash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly {codeHash := extcodehash(_address)}
    // solhint-disable-line
    addressCheck = (codeHash != 0x0 && codeHash != accountHash);
  }
}

interface ERC165 {
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}
interface ERC721Metadata {
  function name() external view returns (string memory _name);

  function symbol() external view returns (string memory _symbol);

  function tokenURI(uint256 _tokenId) external view returns (string memory);
}
interface ERC721 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

  function transferFrom(address _from, address _to, uint256 _tokenId) external;

  function approve(address _approved, uint256 _tokenId) external;

  function setApprovalForAll(address _operator, bool _approved) external;

  function balanceOf(address _owner) external view returns (uint256);

  function ownerOf(uint256 _tokenId) external view returns (address);

  function getApproved(uint256 _tokenId) external view returns (address);

  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface ERC721TokenReceiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}


contract SupportsInterface is ERC165 {
  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor() {
    supportedInterfaces[0x01ffc9a7] = true;
  }

  function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
    return supportedInterfaces[_interfaceID];
  }
}
contract NFToken is ERC721, SupportsInterface {
  using AddressUtils for address;

  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  /**
   * @dev Magic value of a smart contract that can receive NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  mapping(uint256 => address) internal idToOwner;
  mapping(uint256 => address) internal idToApproval;
  mapping(address => uint256) private ownerToNFTokenCount;
  mapping(address => mapping(address => bool)) internal ownerToOperators;

  modifier canOperate(uint256 _tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  modifier canTransfer(uint256 _tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  modifier validNFToken(uint256 _tokenId) {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  constructor() {
    supportedInterfaces[0x80ac58cd] = true;
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external override {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(address _owner) external override view returns (uint256) {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  function ownerOf(uint256 _tokenId) external override view returns (address _owner){
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  function getApproved(uint256 _tokenId) external override view validNFToken(_tokenId) returns (address) {
    return idToApproval[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
    return ownerToOperators[_owner][_operator];
  }

  function _transfer(address _to, uint256 _tokenId) internal virtual {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }

  function _mint(address _to, uint256 _tokenId) internal virtual {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  function _burn(uint256 _tokenId) internal virtual validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

  function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  function _addNFToken(address _to, uint256 _tokenId) internal virtual {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] += 1;
  }

  function _getOwnerNFTCount(address _owner) internal virtual view returns (uint256){
    return ownerToNFTokenCount[_owner];
  }

  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract()) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  function _clearApproval(uint256 _tokenId) private {
    delete idToApproval[_tokenId];
  }
}
contract NFTokenMetadata is NFToken, ERC721Metadata {
  string internal nftName;
  string internal nftSymbol;
  mapping(uint256 => string) internal idToUri;

  constructor() {
    supportedInterfaces[0x5b5e139f] = true;
  }

  function name() external override view returns (string memory _name) {
    _name = nftName;
  }

  function symbol() external override view returns (string memory _symbol) {
    _symbol = nftSymbol;
  }

  function tokenURI(uint256 _tokenId) external override view validNFToken(_tokenId) returns (string memory) {
    return _tokenURI(_tokenId);
  }

  function _tokenURI(uint256 _tokenId) internal virtual view returns (string memory) {
    return idToUri[_tokenId];
  }

  function _burn(uint256 _tokenId) internal virtual override {
    super._burn(_tokenId);
    delete idToUri[_tokenId];
  }

  function _setTokenUri(uint256 _tokenId, string memory _uri) internal validNFToken(_tokenId) {
    idToUri[_tokenId] = _uri;
  }
}


abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner() {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract DesignVaultNFT is NFTokenMetadata, Ownable {
  constructor() {
    nftName = "Design Vault NFT";
    nftSymbol = "DV-NFT";
  }

  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner() {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
}