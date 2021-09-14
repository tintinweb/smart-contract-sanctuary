/**
 *Submitted for verification at Etherscan.io on 2021-09-14
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
  function isContract(address _addr) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) }
    return (codehash != 0x0 && codehash != accountHash);
  }
}

contract nft {

  // ERC721 standard
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId );
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  
  mapping (uint256 => address) public ownerOf;
  mapping (uint256 => address) public getApproved;
  mapping (address => mapping (address => bool)) public isApprovedForAll;
  mapping (address=>uint256) public balanceOf;
  uint256 public totalSupply;
  string public base;
  string public name;
  string public symbol;
    
  // ERC721 Metadata
  mapping (uint256 => string) internal idToString;
  /***********/
  
  // ERC165 standards
  mapping (bytes4 => bool) public supportsInterface;
  /***********/
  
  // Minters and initializers
  event NFTMinterChanged(address);
  event Initialized();
  address NFTMinter;
  bool public initialized;
  /***********/

  constructor() {
    initialize();
  }
  function initialize() public{
    emit Initialized();
    require(initialized==false,"Already initialized");
    initialized=true;
    supportsInterface[0x80ac58cd] = true; // ERC721
    supportsInterface[0x01ffc9a7] = true; // EIP165
    supportsInterface[0x01ffc9a7] = true; // ERC721 metadata
    NFTMinter=msg.sender;
  }

  function mint(address owner,uint _tokenId) external onlyMinter {
    _mint(owner,_tokenId);
  }

  function mintWithMetadata(address owner,uint _tokenId,string memory metadata) external onlyMinter {
    _mint(owner,_tokenId);
    idToString[_tokenId]=metadata;
  }
  
  function _mint(address _to, uint256 nftId) internal {
    require(ownerOf[nftId]==address(0),"Token already exists");
    ownerOf[nftId] = _to;
    balanceOf[_to]++;
    totalSupply++;
    emit Transfer(address(0), _to, nftId);
  }
  
  function burn(uint nftId) external onlyMinter {
    require(ownerOf[nftId] != address(0), "Nof valid NFT");
    address tokenOwner = ownerOf[nftId];
    delete getApproved[nftId];
    delete ownerOf[nftId];
    totalSupply--;
    balanceOf[tokenOwner]--;
    emit Transfer(tokenOwner, address(0), nftId);
  }

  function safeTransferFrom(address _from, address _to, uint256 nftId, bytes calldata _data) external {
    _safeTransferFrom(_from, _to, nftId, _data);
  }

  function safeTransferFrom(address _from, address _to, uint256 nftId) external {
    _safeTransferFrom(_from, _to, nftId, "");
  }

  function approve(address _approved, uint256 nftId) external {
    address tokenOwner = ownerOf[nftId];
    require(
      tokenOwner == msg.sender || isApprovedForAll[tokenOwner][msg.sender],
      "Must be owner or operator"
    );
    
    require(
      tokenOwner == msg.sender || isApprovedForAll[tokenOwner][msg.sender],
      "Must be owner or operator"
    );
    
    getApproved[nftId] = _approved;
    emit Approval(tokenOwner, _approved, nftId);
  }

  function setApprovalForAll(address _operator, bool _approved) external {
    isApprovedForAll[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function _safeTransferFrom(address _from, address _to, uint256 nftId, bytes memory _data) 
            private {
                
    transferFromInternal(_from,_to,nftId);

    if (utils.isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, nftId, _data);
      require(retval == 0x150b7a02, "Smart contract not able to receive tokens");
    }
  }
  
  function transferFrom(address _from, address _to, uint256 nftId)
    external
  {
    transferFromInternal(_from,_to,nftId);
  }
  
  function transferFromInternal(address _from,address _to, uint256 nftId ) internal {
    address tokenOwner = ownerOf[nftId];
    
    require(tokenOwner == _from, "Must be owner");
    require(_to != address(0), "Must sent to to a valid address");
    
    // you have permission
    require(
      tokenOwner == msg.sender
      || getApproved[nftId] == msg.sender
      || isApprovedForAll[tokenOwner][msg.sender],
      "Must be approved or operator"
    );
    
    delete getApproved[nftId];
    balanceOf[tokenOwner]--;
    ownerOf[nftId] = _to;
    balanceOf[_to]++;
    emit Transfer(tokenOwner, _to, nftId);
 
  }
  
  modifier onlyMinter() {
      require(msg.sender==NFTMinter);
      _;
  }

  modifier tokenExist(uint256 tokenId) {
      require(ownerOf[tokenId]!=address(0),"Token must exists");
      _;
  }

  function setNFTMinter(address newMinter) external onlyMinter{
    NFTMinter=newMinter;
    emit NFTMinterChanged(NFTMinter);
  }
  
  function tokenURI(uint256 _tokenId) external view tokenExist(_tokenId) returns (string memory) {
    return string(abi.encodePacked(base,utils.uint2str(_tokenId)));
  }
  
  function setBase(string memory newValue) external onlyMinter{
      base=newValue;
  }
  
  function setName(string memory newValue) external onlyMinter{
      name=newValue;
  }
  
  function setSymbol(string memory newValue) external onlyMinter{
      symbol=newValue;
  }
  
  function setTokenMetadata(uint tokenId,string memory metadata) external onlyMinter{
    idToString[tokenId]=metadata;
  }
  
  function getTokenMetadata(uint tokenId) public view tokenExist(tokenId) returns(string memory) {
    return idToString[tokenId];
  }
}