/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

pragma solidity ^0.8.6;

interface ERC721TokenReceiver {
  function onERC721Received( address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

library utils {
  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
  function isContract(address _addr) internal view returns (bool addressCheck) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }
}

contract nft {

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId );
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event NFTMinterChanged(address);
 
  address NFTMinter;
  
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;     
  string base;
  string name;
  string symbol;
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";
  string constant INVALID_INDEX = "005007";

  uint256[] internal tokens;
  mapping (uint256 => uint256) internal idToIndex;
  mapping (address => uint256[]) internal ownerToIds;
  mapping (uint256 => uint256) internal idToOwnerIndex;
  mapping (uint256 => address) internal idToOwner;
  mapping (uint256 => address) internal idToApproval;
  mapping (uint256 => string) internal idToString;
  mapping (address => uint256) private ownerToNFTokenCount;
  mapping (address => mapping (address => bool)) internal ownerToOperators;
  mapping (bytes4 => bool) public supportedInterfaces;
  
  constructor() {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
    supportedInterfaces[0x01ffc9a7] = true; // ercc721 metadata
    supportedInterfaces[0x780e9d63] = true; // erc721 enumerate
    NFTMinter=msg.sender;
  }
  
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

  modifier onlyNFTMinter() {
    require(msg.sender==NFTMinter);
    _;
  }
  
  function setNFTMinter(address newMinter) public onlyNFTMinter {
    NFTMinter=newMinter;
    emit NFTMinterChanged(NFTMinter);
  }
  
  function mint(address owner,uint _tokenId) external onlyNFTMinter
        returns(bool){
    _mint(owner,_tokenId);
    //idToApproval[_tokenId] = _approved;
    //idToString[_tokenId]=metadata;
    return true;
  }
  
//   function setTokenMetadata(uint tokenId,string memory metadata) external onlyNFTMinter validNFToken(tokenId){
//     idToString[tokenId]=metadata;
//   }
  
//   function getTokenMetadata(uint tokenId) public view validNFToken(tokenId) returns(string memory) {
//     return idToString[tokenId];
//   }
  
  function burn(uint nftId) public onlyNFTMinter {
    _burn(nftId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(address _from, address _to, uint256 _tokenId)
    external
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);
    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0), ZERO_ADDRESS);
    return ownerToIds[_owner].length;
  }

  function ownerOf(uint256 _tokenId) external view returns (address _owner) {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address) {
    return idToApproval[_tokenId];
  }

  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return ownerToOperators[_owner][_operator];
  }

  function _transfer(address _to, uint256 _tokenId ) internal {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);
    emit Transfer(from, _to, _tokenId);
  }

  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) 
            private canTransfer(_tokenId) validNFToken(_tokenId) {
                
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);
    _transfer(_to, _tokenId);

    if (utils.isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  function _clearApproval(uint256 _tokenId) private {
    delete idToApproval[_tokenId];
  }

  function totalSupply() external view returns (uint256) {
    return tokens.length;
  }

  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index < tokens.length, INVALID_INDEX);
    return tokens[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerToIds[_owner].length, INVALID_INDEX);
    return ownerToIds[_owner][_index];
  }

  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    _addNFToken(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length - 1;
  }

  function _burn(uint256 _tokenId) internal validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);

    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.pop();
    // This wastes gas if you are burning the last token but saves a little gas if you are not.
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }


  function _removeNFToken(address _from, uint256 _tokenId) internal {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    delete idToOwner[_tokenId];

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex) {
      uint256 lastToken = ownerToIds[_from][lastTokenIndex];
      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }
    ownerToIds[_from].pop();
  }

  function _addNFToken(address _to, uint256 _tokenId) internal {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    idToOwner[_tokenId] = _to;
    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
  }

  function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
    return string(abi.encodePacked(base,utils.uint2str(_tokenId)));
  }
  
  function setBase(string memory newValue) public onlyNFTMinter{
      base=newValue;
  }
  
  function setName(string memory newValue) public onlyNFTMinter{
      name=newValue;
  }
  
  function setSymbol(string memory newValue) public onlyNFTMinter{
      symbol=newValue;
  }
}