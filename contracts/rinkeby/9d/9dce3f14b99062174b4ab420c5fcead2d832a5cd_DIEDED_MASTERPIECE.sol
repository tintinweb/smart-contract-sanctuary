/**
 *Submitted for verification at Etherscan.io on 2021-12-04
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

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
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

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
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

interface BaseInterface{
    function isEligibleToFutureMints(address who, uint256 _modulo) external view returns (bool);
}

contract DIEDED_MASTERPIECE is
  ERC721,
  SupportsInterface,
  Ownable
{

  using AddressUtils for address;

  //Mainnet vs. testnet address
  //Testnet is: 0x35EEB32Ed3A4741c6a731Ad9B6257f04f9C376D1
  //Mainnet is: 0x7349d9324Fe190Ca96C7fC4EE4f1F3CBbb0d502a
  //Usage baseDiededContract.isEligibleToFutureMints(msg.sender, ID_TO_BE_MINTED)

  address ckAddress = 0x35EEB32Ed3A4741c6a731Ad9B6257f04f9C376D1;
  BaseInterface baseDiededContract = BaseInterface(ckAddress);

  uint256 public nextMintID;

  string baseURI;
  string _symbol;
  string _name;

  // Masterpiece cycle counter
  // 1 cycle consist of 20 masterpieces
  uint8 public cycleCounter;

  address [] whitelisted;
  
  bool public isMintWindowOpen;

  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  mapping (uint256 => address) internal idToOwner;

  mapping (uint256 => address) internal idToApproval;

  mapping (address => uint256) internal ownerToNFTokenCount;

  mapping (address => mapping (address => bool)) internal ownerToOperators;

  //Each ID belongs to which masterpiece basically
  mapping (uint256 => uint256) internal idToType;
  //Each masterpieceMintID shall contain less than 70 mints !
  mapping (uint256 => uint8) internal mpieceToCount;

  //Whitelisted addresses
  mapping(address => uint8) internal whitelistedClaimed;

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

  function addToWhitelistArray(address[] memory _whitelisted) public onlyOwner {
    for (uint8 i=0; i<_whitelisted.length; i++)
    {
        whitelisted.push(_whitelisted[i]);
        whitelistedClaimed[_whitelisted[i]] = 10; //not claimed
    }
  }

  constructor(address[] memory _whitelisted)
  {
    _name = "MPDIED";
    _symbol = "MPDIED";
    setBaseTokenURI("https://dieded.art/URIS_MP/");
    supportedInterfaces[0x80ac58cd] = true; // ERC721
    isMintWindowOpen = true;
    cycleCounter = 1;
    nextMintID = 0;
    for (uint8 i=0; i<_whitelisted.length; i++)
    {
        whitelisted.push(_whitelisted[i]);
        whitelistedClaimed[_whitelisted[i]] = 10; //not claimed
    }
  }

//On 'closing' we shall increment cycle counter
  function openCloseMint(bool _status) public onlyOwner{
      isMintWindowOpen = _status;
      if(_status != false)
      {
        cycleCounter +=1;
      }
  }

//Just in case needed
  function adjustCycleCounter(uint8 _counter) public onlyOwner{
      cycleCounter = _counter;
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
    nextMintID += 1;
    emit Transfer(address(0), _to, _tokenId);
  }

  function claim(uint256 masterpieceID, uint8 extra) external payable{
    require(isMintWindowOpen && masterpieceID < (uint256(cycleCounter * 20) - 1) && masterpieceID >= (uint256((cycleCounter-1) * 20)), "Mint window is not open");
    require(mpieceToCount[masterpieceID] < 70, "The amount of mints/masterpiece would exceed the hard cap of 70!");
    
    //Extra for whitelisted members costs : 0.01 ETH
    //Extra for non-whitelisted memebrs: costs: 0.02 ETH

    //Check free mints
    bool freeClaim = false;
    bool isfreeClaimFromMembership = false;
    bool isfreeClaimFromWL = isWhitelistedAndNotClaimedYet(msg.sender);
    if(!isfreeClaimFromWL){
      isfreeClaimFromMembership = baseDiededContract.isEligibleToFutureMints(msg.sender, masterpieceID);
      if(isfreeClaimFromMembership)
      {
        //So if anyone want he/she can mint the whole number up to 70
        freeClaim = true;
      }
    }

    //Setting freeClaim flag
    if(isfreeClaimFromWL)
    {
      whitelistedClaimed[msg.sender] = 20; //claimed
      freeClaim = true;
    }

    //If whitelisted and want an extra masterpiece it costs +0.01 ETH
    if (freeClaim == true && extra > 0)
    {
        require(msg.value >= 0.01 ether, "Claiming a masterpiece +1 extra costs 0.01 ETH for this address");
    }
    
    //If non-whitelisted and want an extra masterpiece it costs +0.02 ETH (and the original 0.03 ETH)
    if( freeClaim == false && extra > 0 )
    {
        require(msg.value >= 0.05 ether, "Claiming a masterpiece +1 extra costs 0.05 ETH for this address"); 
    }
    else if( freeClaim == false && extra == 0)
    {
        require(msg.value >= 0.03 ether, "Claiming a masterpiece costs 0.03 ETH for this address");
    }

    idToType[nextMintID] = masterpieceID;
    mpieceToCount[masterpieceID] += 1;
    _mint(msg.sender,nextMintID);

    if( extra > 0 )
    {
      idToType[nextMintID] = masterpieceID;
      mpieceToCount[masterpieceID] += 1;
      _mint(msg.sender,nextMintID);
    }
  }

  function viewMpieceType(uint256 tokenID) public view returns(uint256) {
    return idToType[tokenID];
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

  function withdraw(address payable recipient) public onlyOwner {
      uint256 balance = address(this).balance;
      recipient.transfer(balance);
  }

}