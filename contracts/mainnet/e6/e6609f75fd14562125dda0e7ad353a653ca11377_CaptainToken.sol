pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The Priate Conquest Project.  All rights reserved.
/* 
/* https://www.pirateconquest.com One of the world&#39;s slg games of blockchain 
/*  
/* authors rainy@livestar.com/Jonny.Fu@livestar.com
/*                 
/* ==================================================================== */
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /*
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract AccessAdmin is Pausable {

  /// @dev Admin Address
  mapping (address => bool) adminContracts;

  /// @dev Trust contract
  mapping (address => bool) actionContracts;

  function setAdminContract(address _addr, bool _useful) public onlyOwner {
    require(_addr != address(0));
    adminContracts[_addr] = _useful;
  }

  modifier onlyAdmin {
    require(adminContracts[msg.sender]); 
    _;
  }

  function setActionContract(address _actionAddr, bool _useful) public onlyAdmin {
    actionContracts[_actionAddr] = _useful;
  }

  modifier onlyAccess() {
    require(actionContracts[msg.sender]);
    _;
  }
}


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
contract ERC721 /* is ERC165 */ {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
     function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f
interface ERC721Metadata /* is ERC721 */ {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x780e9d63
interface ERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract CaptainToken is AccessAdmin, ERC721 {
  using SafeMath for SafeMath;
  //event 
  event CreateCaptain(uint tokenId,uint32 captainId, address _owner, uint256 _price);
  //ERC721
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  struct Captain {
    uint32 captainId;  
    uint32 color;   
    uint32 atk; 
    uint32 defense;
    uint32 atk_min;
    uint32 atk_max;
  }


  Captain[] public captains; //dynamic Array
  function CaptainToken() public {
    captains.length += 1;
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }

  /**MAPPING**/
  /// @dev tokenId to owner  tokenId -> address
  mapping (uint256 => address) public captainTokenIdToOwner;
  /// @dev Equipment token ID search in owner array captainId -> tokenId
  mapping (uint256 => uint256) captainIdToOwnerIndex;  
  /// @dev captains owner by the owner (array)
  mapping (address => uint256[]) ownerToCaptainArray;
  /// @dev price of each token
  mapping (uint256 => uint256) captainTokenIdToPrice;
  /// @dev token count of captain
  mapping (uint32 => uint256) tokenCountOfCaptain;
  /// @dev tokens by the captain
  mapping (uint256 => uint32) IndexToCaptain;
  /// @dev The authorized address for each Captain
  mapping (uint256 => address) captainTokenIdToApprovals;
  /// @dev The authorized operators for each address
  mapping (address => mapping (address => bool)) operatorToApprovals;
  mapping(uint256 => bool) tokenToSell;
  /// @dev captain by the owner (array)
  mapping (address => uint256[]) ownerToCaptainsArray;
  

  /*** CONSTRUCTOR ***/
  /// @dev Amount of tokens destroyed
  uint256 destroyCaptainCount;
  
  // modifier
  /// @dev Check if token ID is valid
  modifier isValidToken(uint256 _tokenId) {
    require(_tokenId >= 1 && _tokenId <= captains.length);
    require(captainTokenIdToOwner[_tokenId] != address(0)); 
    _;
  }
  modifier canTransfer(uint256 _tokenId) {
    require(msg.sender == captainTokenIdToOwner[_tokenId] || msg.sender == captainTokenIdToApprovals[_tokenId]);
    _;
  }
  /// @dev Creates a new Captain with the given name.
  function CreateCaptainToken(address _owner,uint256 _price, uint32 _captainId, uint32 _color,uint32 _atk,uint32 _defense,uint32 _atk_min,uint32 _atk_max) public onlyAccess {
    _createCaptainToken(_owner,_price,_captainId,_color,_atk,_defense,_atk_min,_atk_max);
  }

  function checkCaptain(address _owner,uint32 _captainId) external view returns (bool) {
    uint256 len = ownerToCaptainsArray[_owner].length;
    bool bexist = false;
    for (uint256 i=0;i<len;i++) {
      if (ownerToCaptainsArray[_owner][i] == _captainId) {
        bexist = true;
      }
      }
    return bexist;
  }

  /// For creating CaptainToken
  function _createCaptainToken(address _owner, uint256 _price, uint32 _captainId, uint32 _color, uint32 _atk, uint32 _defense,uint32 _atk_min, uint32 _atk_max) 
  internal {
    uint256 newTokenId = captains.length;
    Captain memory _captain = Captain({
      captainId: _captainId,
      color: _color,
      atk: _atk,
      defense: _defense,
      atk_min: _atk_min,
      atk_max: _atk_max
    });
    captains.push(_captain);
    //event
    CreateCaptain(newTokenId, _captainId, _owner, _price);
    captainTokenIdToPrice[newTokenId] = _price;
    IndexToCaptain[newTokenId] = _captainId;
    ownerToCaptainsArray[_owner].push(_captainId);
    tokenCountOfCaptain[_captainId] = SafeMath.add(tokenCountOfCaptain[_captainId],1);
    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newTokenId);
  } 
  /// @dev set the token price
  function setTokenPrice(uint256 _tokenId, uint256 _price) external onlyAccess {
    captainTokenIdToPrice[_tokenId] = _price;
  }

  /// @dev let owner set the token price
  function setTokenPriceByOwner(uint256 _tokenId, uint256 _price) external {
    require(captainTokenIdToOwner[_tokenId] == msg.sender);
    captainTokenIdToPrice[_tokenId] = _price;
  }

  /// @dev set sellable
  function setSelled(uint256 _tokenId, bool fsell) external onlyAccess {
    tokenToSell[_tokenId] = fsell;
  }

  function getSelled(uint256 _tokenId) external view returns (bool) {
    return tokenToSell[_tokenId];
  }

  /// @dev Do the real transfer with out any condition checking
  /// @param _from The old owner of this Captain(If created: 0x0)
  /// @param _to The new owner of this Captain 
  /// @param _tokenId The tokenId of the Captain
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    if (_from != address(0)) {
      uint256 indexFrom = captainIdToOwnerIndex[_tokenId];  // tokenId -> captainId
      uint256[] storage cpArray = ownerToCaptainArray[_from];
      require(cpArray[indexFrom] == _tokenId);

      // If the Captain is not the element of array, change it to with the last
      if (indexFrom != cpArray.length - 1) {
        uint256 lastTokenId = cpArray[cpArray.length - 1];
        cpArray[indexFrom] = lastTokenId; 
        captainIdToOwnerIndex[lastTokenId] = indexFrom;
      }
      cpArray.length -= 1; 
    
      if (captainTokenIdToApprovals[_tokenId] != address(0)) {
        delete captainTokenIdToApprovals[_tokenId];
      }      
    }

    // Give the Captain to &#39;_to&#39;
    captainTokenIdToOwner[_tokenId] = _to;
    ownerToCaptainArray[_to].push(_tokenId);
    captainIdToOwnerIndex[_tokenId] = ownerToCaptainArray[_to].length - 1;
        
    Transfer(_from != address(0) ? _from : this, _to, _tokenId);
  }


  /// @notice Returns all the relevant information about a specific tokenId.
  /// @param _tokenId The tokenId of the captain
  function getCaptainInfo(uint256 _tokenId) external view returns (
    uint32 captainId,  
    uint32 color, 
    uint32 atk,
    uint32 atk_min,
    uint32 atk_max,
    uint32 defense,
    uint256 price,
    address owner,
    bool selled
  ) {
    Captain storage captain = captains[_tokenId];
    captainId = captain.captainId;
    color = captain.color;
    atk = captain.atk;
    atk_min = captain.atk_min;
    atk_max = captain.atk_max;
    defense = captain.defense;
    price = captainTokenIdToPrice[_tokenId];
    owner = captainTokenIdToOwner[_tokenId];
    selled = tokenToSell[_tokenId];
  }

  /// ERC721 

  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownerToCaptainArray[_owner].length;
  }

  function ownerOf(uint256 _tokenId) external view returns (address) {
    return captainTokenIdToOwner[_tokenId];
  }
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
    _safeTransferFrom(_from, _to, _tokenId, data);
  }
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /// @dev Actually perform the safeTransferFrom
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
    internal
    isValidToken(_tokenId) 
    canTransfer(_tokenId)
    {
    address owner = captainTokenIdToOwner[_tokenId];
    require(owner != address(0) && owner == _from);
    require(_to != address(0));
        
    _transfer(_from, _to, _tokenId);

    // Do the callback after everything is done to avoid reentrancy attack
    /*uint256 codeSize;
    assembly { codeSize := extcodesize(_to) }
    if (codeSize == 0) {
      return;
    }*/
    bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
    // bytes4(keccak256("onERC721Received(address,uint256,bytes)")) = 0xf0b9e5ba;
    require(retval == 0xf0b9e5ba);
  }
    
  /// @dev Transfer ownership of an Captain, &#39;_to&#39; must be a vaild address, or the WAR will lost
  /// @param _from The current owner of the Captain
  /// @param _to The new owner
  /// @param _tokenId The Captain to transfer
  function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
        isValidToken(_tokenId)
        canTransfer(_tokenId)
        payable
    {
    address owner = captainTokenIdToOwner[_tokenId];
    require(owner != address(0));
    require(owner == _from);
    require(_to != address(0));
        
    _transfer(_from, _to, _tokenId);
  }

  /// @dev Safe transfer by trust contracts
  function safeTransferByContract(address _from,address _to, uint256 _tokenId) 
  external
  whenNotPaused
  {
    require(actionContracts[msg.sender]);

    require(_tokenId >= 1 && _tokenId <= captains.length);
    address owner = captainTokenIdToOwner[_tokenId];
    require(owner != address(0));
    require(_to != address(0));
    require(owner != _to);
    require(_from == owner);

    _transfer(owner, _to, _tokenId);
  }

  /// @dev Set or reaffirm the approved address for an captain
  /// @param _approved The new approved captain controller
  /// @param _tokenId The captain to approve
  function approve(address _approved, uint256 _tokenId)
    external
    whenNotPaused 
    payable
  {
    address owner = captainTokenIdToOwner[_tokenId];
    require(owner != address(0));
    require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

    captainTokenIdToApprovals[_tokenId] = _approved;
    Approval(owner, _approved, _tokenId);
  }

  /// @dev Enable or disable approval for a third party ("operator") to manage all your asset.
  /// @param _operator Address to add to the set of authorized operators.
  /// @param _approved True if the operators is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) 
    external 
    whenNotPaused
  {
    operatorToApprovals[msg.sender][_operator] = _approved;
    ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @dev Get the approved address for a single Captain
  /// @param _tokenId The WAR to find the approved address for
  /// @return The approved address for this WAR, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
    return captainTokenIdToApprovals[_tokenId];
  }
  
  /// @dev Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the WARs
  /// @param _operator The address that acts on behalf of the owner
  /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return operatorToApprovals[_owner][_operator];
  }
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() public pure returns(string) {
    return "Pirate Conquest Token";
  }
  /// @notice An abbreviated name for NFTs in this contract
  function symbol() public pure returns(string) {
    return "PCT";
  }
  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  //function tokenURI(uint256 _tokenId) external view returns (string);

  /// @notice Count NFTs tracked by this contract
  /// @return A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256) {
    return captains.length - destroyCaptainCount -1;
  }
  /// @notice Enumerate valid NFTs
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index<(captains.length - destroyCaptainCount));
    //return captainIdToOwnerIndex[_index];
    return _index;
  }
  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
  ///  `_owner` is the zero address, representing invalid NFTs.
  /// @param _owner An address where we are interested in NFTs owned by them
  /// @param _index A counter less than `balanceOf(_owner)`
  /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerToCaptainArray[_owner].length);
    if (_owner != address(0)) {
      uint256 tokenId = ownerToCaptainArray[_owner][_index];
      return tokenId;
    }
  }

  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Persons array looking for persons belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) external view returns (uint256[],uint32[]) {
    uint256 len = ownerToCaptainArray[_owner].length;
    uint256[] memory tokens = new uint256[](len);
    uint32[] memory captainss = new uint32[](len);
    uint256 icount;
    if (_owner != address(0)) {
      for (uint256 i=0;i<len;i++) {
        tokens[i] = ownerToCaptainArray[_owner][icount];
        captainss[i] = IndexToCaptain[ownerToCaptainArray[_owner][icount]];
        icount++;
      }
    }
    return (tokens,captainss);
  }

  /// @param _captainId The captain whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Persons array looking for persons belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfCaptain(uint32 _captainId) public view returns(uint256[] captainTokens) {
    uint256 tokenCount = tokenCountOfCaptain[_captainId];
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalcaptains = captains.length - destroyCaptainCount - 1;
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalcaptains; tokenId++) {
        if (IndexToCaptain[tokenId] == _captainId) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  } 

  function tokensOfSell() external view returns (uint256[],bool[],address[],uint32[]) {
    uint256 len = captains.length - destroyCaptainCount -1;
    uint256[] memory tokens = new uint256[](len);
    bool[] memory captainss = new bool[](len);
    address[] memory owner = new address[](len);
    uint32[] memory captainId = new uint32[](len);
    uint256 icount;
    for (uint256 i=0;i<len;i++) {
      icount++;
      tokens[i] = icount;
      owner[i] = captainTokenIdToOwner[icount];
      captainId[i] = IndexToCaptain[icount];
      if (tokenToSell[icount] == true) {
        captainss[i] = true;
      }else{
        captainss[i] = false;
      }
    }
    
    return (tokens,captainss,owner,captainId);
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function div32(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function add32(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}