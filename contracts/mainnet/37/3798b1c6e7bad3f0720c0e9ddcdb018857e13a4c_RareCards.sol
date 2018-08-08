pragma solidity ^0.4.18;
/* ==================================================================== */
/* Copyright (c) 2018 The MagicAcademy Project.  All rights reserved.
/* 
/* https://www.magicacademy.io One of the world&#39;s first idle strategy games of blockchain 
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

contract AccessAdmin is Ownable {

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
/*interface ERC721Metadata is ERC721{
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) external view returns (string);
}*/

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x780e9d63
interface ERC721Enumerable /* is ERC721 */ {
  function totalSupply() external view returns (uint256);
  function tokenByIndex(uint256 _index) external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract RareCards is AccessAdmin, ERC721 {
  using SafeMath for SafeMath;
  // event
  event eCreateRare(uint256 tokenId, uint256 price, address owner);

  // ERC721
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  struct RareCard {
    uint256 rareId;     // rare item id
    uint256 rareClass;  // upgrade level of rare item
    uint256 cardId;     // related to basic card ID 
    uint256 rareValue;  // upgrade value of rare item
  }

  RareCard[] public rareArray; // dynamic Array

  function RareCards() public {
    rareArray.length += 1;
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }

  /*** CONSTRUCTOR ***/
  uint256 private constant PROMO_CREATION_LIMIT = 20;
  uint256 private constant startPrice = 0.5 ether;

  address thisAddress = this;
  uint256 PLATPrice = 65000;
  /**mapping**/
  /// @dev map tokenId to owner (tokenId -> address)
  mapping (uint256 => address) public IndexToOwner;
  /// @dev search rare item index in owner&#39;s array (tokenId -> index)
  mapping (uint256 => uint256) indexOfOwnedToken;
  /// @dev list of owned rare items by owner
  mapping (address => uint256[]) ownerToRareArray;
  /// @dev search token price by tokenId
  mapping (uint256 => uint256) IndexToPrice;
  /// @dev get the authorized address for each rare item
  mapping (uint256 => address) public IndexToApproved;
  /// @dev get the authorized operators for each rare item
  mapping (address => mapping(address => bool)) operatorToApprovals;

  /** Modifier **/
  /// @dev Check if token ID is valid
  modifier isValidToken(uint256 _tokenId) {
    require(_tokenId >= 1 && _tokenId <= rareArray.length);
    require(IndexToOwner[_tokenId] != address(0)); 
    _;
  }
  /// @dev check the ownership of token
  modifier onlyOwnerOf(uint _tokenId) {
    require(msg.sender == IndexToOwner[_tokenId] || msg.sender == IndexToApproved[_tokenId]);
    _;
  }

  /// @dev create a new rare item
  function createRareCard(uint256 _rareClass, uint256 _cardId, uint256 _rareValue) public onlyOwner {
    require(rareArray.length < PROMO_CREATION_LIMIT); 
    _createRareCard(thisAddress, startPrice, _rareClass, _cardId, _rareValue);
  }


  /// steps to create rare item 
  function _createRareCard(address _owner, uint256 _price, uint256 _rareClass, uint256 _cardId, uint256 _rareValue) internal returns(uint) {
    uint256 newTokenId = rareArray.length;
    RareCard memory _rarecard = RareCard({
      rareId: newTokenId,
      rareClass: _rareClass,
      cardId: _cardId,
      rareValue: _rareValue
    });
    rareArray.push(_rarecard);
    //event
    eCreateRare(newTokenId, _price, _owner);

    IndexToPrice[newTokenId] = _price;
    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newTokenId);

  } 

  /// @dev transfer the ownership of tokenId
  /// @param _from The old owner of rare item(If created: 0x0)
  /// @param _to The new owner of rare item
  /// @param _tokenId The tokenId of rare item
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    if (_from != address(0)) {
      uint256 indexFrom = indexOfOwnedToken[_tokenId];
      uint256[] storage rareArrayOfOwner = ownerToRareArray[_from];
      require(rareArrayOfOwner[indexFrom] == _tokenId);

      // Switch the positions of selected item and last item
      if (indexFrom != rareArrayOfOwner.length - 1) {
        uint256 lastTokenId = rareArrayOfOwner[rareArrayOfOwner.length - 1];
        rareArrayOfOwner[indexFrom] = lastTokenId;
        indexOfOwnedToken[lastTokenId] = indexFrom;
      }
      rareArrayOfOwner.length -= 1;

      // clear any previously approved ownership exchange
      if (IndexToApproved[_tokenId] != address(0)) {
        delete IndexToApproved[_tokenId];
      } 
    }
    //transfer ownership
    IndexToOwner[_tokenId] = _to;
    ownerToRareArray[_to].push(_tokenId);
    indexOfOwnedToken[_tokenId] = ownerToRareArray[_to].length - 1;
    // Emit the transfer event.
    Transfer(_from != address(0) ? _from : this, _to, _tokenId);
  }

  /// @notice Returns all the relevant information about a specific tokenId.
  /// @param _tokenId The tokenId of the rarecard.
  function getRareInfo(uint256 _tokenId) external view returns (
      uint256 sellingPrice,
      address owner,
      uint256 nextPrice,
      uint256 rareClass,
      uint256 cardId,
      uint256 rareValue
  ) {
    RareCard storage rarecard = rareArray[_tokenId];
    sellingPrice = IndexToPrice[_tokenId];
    owner = IndexToOwner[_tokenId];
    nextPrice = SafeMath.div(SafeMath.mul(sellingPrice,125),100);
    rareClass = rarecard.rareClass;
    cardId = rarecard.cardId;
    rareValue = rarecard.rareValue;
  }

  /// @notice Returns all the relevant information about a specific tokenId.
  /// @param _tokenId The tokenId of the rarecard.
  function getRarePLATInfo(uint256 _tokenId) external view returns (
    uint256 sellingPrice,
    address owner,
    uint256 nextPrice,
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  ) {
    RareCard storage rarecard = rareArray[_tokenId];
    sellingPrice = SafeMath.mul(IndexToPrice[_tokenId],PLATPrice);
    owner = IndexToOwner[_tokenId];
    nextPrice = SafeMath.div(SafeMath.mul(sellingPrice,125),100);
    rareClass = rarecard.rareClass;
    cardId = rarecard.cardId;
    rareValue = rarecard.rareValue;
  }


  function getRareItemsOwner(uint256 rareId) external view returns (address) {
    return IndexToOwner[rareId];
  }

  function getRareItemsPrice(uint256 rareId) external view returns (uint256) {
    return IndexToPrice[rareId];
  }

  function getRareItemsPLATPrice(uint256 rareId) external view returns (uint256) {
    return SafeMath.mul(IndexToPrice[rareId],PLATPrice);
  }

  function setRarePrice(uint256 _rareId, uint256 _price) external onlyAccess {
    IndexToPrice[_rareId] = _price;
  }

  function rareStartPrice() external pure returns (uint256) {
    return startPrice;
  }

  /// ERC721
  /// @notice Count all the rare items assigned to an owner
  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownerToRareArray[_owner].length;
  }

  /// @notice Find the owner of a rare item
  function ownerOf(uint256 _tokenId) external view returns (address _owner) {
    return IndexToOwner[_tokenId];
  }

  /// @notice Transfers the ownership of a rare item from one address to another address
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
    _safeTransferFrom(_from, _to, _tokenId, data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /// @dev steps to implement the safeTransferFrom
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
    internal
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
  {
    address owner = IndexToOwner[_tokenId];
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

  // function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
  //   _transfer(msg.sender, _to, _tokenId);
  // }

  /// @notice Transfers the ownership of a rare item from one address to another address
  /// @dev Transfer ownership of a rare item, &#39;_to&#39; must be a vaild address, or the card will lost
  /// @param _from The current owner of rare item
  /// @param _to The new owner
  /// @param _tokenId The rare item to transfer
  function transferFrom(address _from, address _to, uint256 _tokenId) 
    external 
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
    payable 
  {
    address owner = IndexToOwner[_tokenId];
    // require(_owns(_from, _tokenId));
    // require(_approved(_to, _tokenId));
    require(owner != address(0) && owner == _from);
    require(_to != address(0));
    _transfer(_from, _to, _tokenId);
  }

  //   /// For checking approval of transfer for address _to
  //   function _approved(address _to, uint256 _tokenId) private view returns (bool) {
  //     return IndexToApproved[_tokenId] == _to;
  //   }
  //  /// Check for token ownership
  //   function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
  //     return claimant == IndexToOwner[_tokenId];
  //   }

  /// @dev Set or reaffirm the approved address for a rare item
  /// @param _approved The new approved rare item controller
  /// @param _tokenId The rare item to approve
  function approve(address _approved, uint256 _tokenId) 
    external 
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
    payable 
  {
    address owner = IndexToOwner[_tokenId];
    require(operatorToApprovals[owner][msg.sender]);
    IndexToApproved[_tokenId] = _approved;
    Approval(owner, _approved, _tokenId);
  }


  /// @dev Enable or disable approval for a third party ("operator") to manage all your asset.
  /// @param _operator Address to add to the set of authorized operators.
  /// @param _approved True if the operators is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) 
    external 
  {
    operatorToApprovals[msg.sender][_operator] = _approved;
    ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @dev Get the approved address for a single rare item
  /// @param _tokenId The rare item to find the approved address for
  /// @return The approved address for this rare item, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
    return IndexToApproved[_tokenId];
  }

  /// @dev Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the rare item
  /// @param _operator The address that acts on behalf of the owner
  /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return operatorToApprovals[_owner][_operator];
  }

  /// @notice Count rare items tracked by this contract
  /// @return A count of valid rare items tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() external view returns (uint256) {
    return rareArray.length -1;
  }

  /// @notice Enumerate valid rare items
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`the rare item,
  ///  (sort order not specified)
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index <= (rareArray.length - 1));
    return _index;
  }

  /// @notice Enumerate rare items assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
  ///  `_owner` is the zero address, representing invalid rare items.
  /// @param _owner An address where we are interested in rare items owned by them
  /// @param _index A counter less than `balanceOf(_owner)`
  /// @return The token identifier for the `_index`the rare item assigned to `_owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerToRareArray[_owner].length);
    if (_owner != address(0)) {
      uint256 tokenId = ownerToRareArray[_owner][_index];
      return tokenId;
    }
  }

  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Persons array looking for persons belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) external view returns(uint256[]) {
    uint256 tokenCount = ownerToRareArray[_owner].length;
    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalRare = rareArray.length - 1;
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalRare; tokenId++) {
        if (IndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  //transfer token 
  function transferToken(address _from, address _to, uint256 _tokenId) external onlyAccess {
    _transfer(_from,  _to, _tokenId);
  }

  // transfer token in contract-- for raffle
  function transferTokenByContract(uint256 _tokenId,address _to) external onlyAccess {
    _transfer(thisAddress,  _to, _tokenId);
  }

  // owner & price list 
  function getRareItemInfo() external view returns (address[], uint256[], uint256[]) {
    address[] memory itemOwners = new address[](rareArray.length-1);
    uint256[] memory itemPrices = new uint256[](rareArray.length-1);
    uint256[] memory itemPlatPrices = new uint256[](rareArray.length-1);
        
    uint256 startId = 1;
    uint256 endId = rareArray.length-1;
        
    uint256 i;
    while (startId <= endId) {
      itemOwners[i] = IndexToOwner[startId];
      itemPrices[i] = IndexToPrice[startId];
      itemPlatPrices[i] = SafeMath.mul(IndexToPrice[startId],PLATPrice);
      i++;
      startId++;
    }   
    return (itemOwners, itemPrices, itemPlatPrices);
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

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
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

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}