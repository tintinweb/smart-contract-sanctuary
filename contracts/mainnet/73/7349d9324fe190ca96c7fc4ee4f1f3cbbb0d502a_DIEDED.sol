/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// File: contracts/erc721.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface ERC721
{

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


  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;


  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;


  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;


  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);


  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// File: contracts/Ownable.sol

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }


  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/erc721-token-receiver.sol

interface ERC721TokenReceiver
{
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

// File: contracts/erc165.sol


interface ERC165
{

  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}

// File: contracts/supports-interface.sol

contract SupportsInterface is
  ERC165
{


  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor()
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }


  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

// File: contracts/address-utils.sol

library AddressUtils
{


  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}

// File: contracts/nf-token.sol

contract DIEDED_BASE is
  ERC721,
  SupportsInterface,
  Ownable
{
  using AddressUtils for address;

  uint256 constant MAX_MINT_NR = 1000;
  uint256 public nextMintID;

  string baseURI;
  string _symbol;
  string _name;

  address [] whitelisted;
  
  bool public isMintWindowOpen;


  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  mapping (uint256 => address) internal idToOwner;


  mapping (uint256 => address) internal idToApproval;


  mapping (address => uint256) internal ownerToNFTokenCount;

  mapping (address => mapping (address => bool)) internal ownerToOperators;

  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      "003003"
    );
    _;
  }

  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      "003004"
    );
    _;
  }

  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), "003002");
    _;
  }

  constructor()
  {
    _name = "DIEDED";
    _symbol = "DIEDED";
    setBaseTokenURI("https://dieded.art/URIS/");
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }


  function setBaseTokenURI(string memory _baseURI) public onlyOwner{
      baseURI = _baseURI;
  }

  function name() external view returns (string memory name_ret){
      return _name;
  }

  function symbol() external view returns (string memory symbol_ret){
      return _symbol;
  }


  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    require(tokenId <= nextMintID, "ERC721: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
  }


  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), "003001");
    require(idToOwner[_tokenId] == address(0), "003006");

    _addNFToken(_to, _tokenId);
    
    emit Transfer(address(0), _to, _tokenId);
  }


  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, "003007");
    require(_to != address(0), "003001");

    _transfer(_to, _tokenId);
  }

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, "003008");

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), "003001");
    return _getOwnerNFTCount(_owner);
  }

  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), "003002");
  }

  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }


  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, "003007");
    ownerToNFTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), "003006");

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] += 1;
  }


  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    private
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, "003007");
    require(_to != address(0), "003001");

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, "003005");
    }
  }

  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    delete idToApproval[_tokenId];
  }

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

}

// File: contracts/erc721-enumerable.sol

interface ERC721Enumerable
{

  function totalSupply()
    external
    view
    returns (uint256);

  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}

// File: contracts/nf-token-enumerable.sol

contract DIEDED is
  DIEDED_BASE,
  ERC721Enumerable
{


  string constant INVALID_INDEX = "005007";

  uint256[] internal tokens;


  mapping(uint256 => uint256) internal idToIndex;


  mapping(address => uint256[]) internal ownerToIds;

  mapping(uint256 => uint256) internal idToOwnerIndex;

  mapping(address => uint8) internal whitelistedClaimed;

  constructor(address[] memory _whitelisted)
  {  
    nextMintID = 45;

    for (uint8 i=0; i<_whitelisted.length; i++)
    {
        whitelisted.push(_whitelisted[i]);
        whitelistedClaimed[_whitelisted[i]] = 10; //not claimed
    }

    isMintWindowOpen = false;
    supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
  }

  function openCloseMint(bool _status) public onlyOwner{
      isMintWindowOpen = _status;
  }

  function mintForOwner(uint8 section) public onlyOwner{
    if(section == 0){
      for (uint8 i=0; i<45; i++) {    
          _mintForOWner(msg.sender,i); 
      }
    }
    else if(section == 1){
      for (uint8 i=0; i<15; i++) {    
          _mintForOWner(msg.sender,i); 
      }
    }
    else if(section == 2){
      for (uint8 i=15; i<30; i++) {    
          _mintForOWner(msg.sender,i); 
      }
    }
    else if(section == 3){
      for (uint8 i=30; i<45; i++) {    
          _mintForOWner(msg.sender,i); 
      }
    }

  }

  function addToWhitelistArray(address[] memory _whitelisted) public onlyOwner {
    for (uint8 i=0; i<_whitelisted.length; i++)
    {
        whitelisted.push(_whitelisted[i]);
        whitelistedClaimed[_whitelisted[i]] = 10; //not claimed
    }
  }

  function totalSupply()
    external
    override
    view
    returns (uint256)
  {
    return tokens.length;
  }

  function tokenByIndex(
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < tokens.length, INVALID_INDEX);
    return tokens[_index];
  }

  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length, INVALID_INDEX);
    return ownerToIds[_owner][_index];
  }

  function tokenOfOwnerByIndexInternal(
    address _owner,
    uint256 _index
  )
    internal
    view
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length, INVALID_INDEX);
    return ownerToIds[_owner][_index];
  }

  function isEligibleToFutureMints(address who, uint256 _modulo) external view returns (bool)
  {
    
    for (uint256 i=0; i<_getOwnerNFTCount(who); i++)
    {
        uint256 token_id = tokenOfOwnerByIndexInternal(who, i);
        if(token_id % 20 == _modulo)
        {
          return true;
        }
    }

    return false;
  }

  function isWhitelistedAndNotClaimedYet(address isWhitelistedAddr) public view returns (bool) {
    bool result = false;
    for (uint256 i=0; i<whitelisted.length; i++)
    {
        if( whitelisted[i] == isWhitelistedAddr && whitelistedClaimed[isWhitelistedAddr] == 10)
        {
            return true;
        }
    }
    return result;
  } 

  function claim(uint8 mint_num) external payable{
    require(isMintWindowOpen, "Mint window is not open");
    require(mint_num + nextMintID < MAX_MINT_NR+1, "The amount of mints would exceed the supply!");
    require(_getOwnerNFTCount(msg.sender) + mint_num <= 5, "Claiming too many assets per address");

    bool whitelisted_res = isWhitelistedAndNotClaimedYet(msg.sender);

  if( 
      (mint_num == 1 && whitelisted_res == false) ||
      (mint_num == 2 && whitelisted_res == true)
    )
  {
    require(msg.value >= 0.0666 ether, "Claiming such amount of membership costs 0.0666 ETH for this address");
  }
  else if ( 
      (mint_num == 2 && whitelisted_res == false) ||
      (mint_num == 3 && whitelisted_res == true)
    )
  {
    require(msg.value >= 0.1332 ether, "Claiming such amount of membership costs 0.1332 ETH for this address");
  }
  else if ( 
      (mint_num == 3 && whitelisted_res == false) ||
      (mint_num == 4 && whitelisted_res == true)
    )
  {
    require(msg.value >= 0.1998 ether, "Claiming such amount of membership costs 0.1998 ETH for this address");
  }
  else if ( (mint_num == 4 && whitelisted_res == false) ||
            (mint_num == 5 && whitelisted_res == true)
          )
  {
    require(msg.value >= 0.2664 ether, "Claiming such amount of membership costs 0.2664 ETH for this address");
  }
  else if ( (mint_num == 5 && whitelisted_res == false) )
  {
    require(msg.value >= 0.333 ether, "Claiming such amount of membership costs 0.333 ETH for this address");
  }

  for (uint8 i=0; i<mint_num; i++)
  {
    whitelisted_res = isWhitelistedAndNotClaimedYet(msg.sender);
    if ( whitelisted_res == true ){
      whitelistedClaimed[msg.sender] = 20; //claimed
        _mint(msg.sender,nextMintID);
    }
    else{
        _mint(msg.sender,nextMintID);
    }
  }
  // Transfer mint price to contract owner
  payable(owner()).transfer(msg.value);
}


  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require (nextMintID < MAX_MINT_NR);
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length - 1;
    nextMintID += 1;
  }

  function _mintForOWner(
    address _to,
    uint256 _tokenId
  )
    internal onlyOwner
  {
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length - 1;

  }

  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == _from, "003006");
    delete idToOwner[_tokenId];

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex)
    {
      uint256 lastToken = ownerToIds[_from][lastTokenIndex];
      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[_from].pop();
  }

  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == address(0), "003007");
    idToOwner[_tokenId] = _to;

    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
  }

  function _getOwnerNFTCount(
    address _owner
  )
    internal
    override
    virtual
    view
    returns (uint256)
  {
    return ownerToIds[_owner].length;
  }
}