pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}





















/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}







/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   *  after a `safetransfer`. This function MAY throw to revert and reject the
   *  transfer. This function MUST use 50,000 gas or less. Return of other
   *  than the magic value MUST result in the transaction being reverted.
   *  Note: the contract address is always the message sender.
   * @param _from The sending address
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}




/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}



/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existance of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * @dev The zero address indicates there is no approved address.
   * @dev There can only be one approved address per token at a given time.
   * @dev Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for a the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * @dev An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * @dev Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * @dev The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}



/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {
  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() public view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() public view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * @dev Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * @dev Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}







/// @title The contract that manages all the players that appear in our game.
/// @author The CryptoStrikers Team
contract StrikersPlayerList is Ownable {
  // We only use playerIds in StrikersChecklist.sol (to
  // indicate which player features on instances of a
  // given ChecklistItem), and nowhere else in the app.
  // While it&#39;s not explictly necessary for any of our
  // contracts to know that playerId 0 corresponds to
  // Lionel Messi, we think that it&#39;s nice to have
  // a canonical source of truth for who the playerIds
  // actually refer to. Storing strings (player names)
  // is expensive, so we just use Events to prove that,
  // at some point, we said a playerId represents a given person.

  /// @dev The event we fire when we add a player.
  event PlayerAdded(uint8 indexed id, string name);

  /// @dev How many players we&#39;ve added so far
  ///   (max 255, though we don&#39;t plan on getting close)
  uint8 public playerCount;

  /// @dev Here we add the players we are launching with on Day 1.
  ///   Players are loosely ranked by things like FIFA ratings,
  ///   number of Instagram followers, and opinions of CryptoStrikers
  ///   team members. Feel free to yell at us on Twitter.
  constructor() public {
    addPlayer("Lionel Messi"); // 0
    addPlayer("Cristiano Ronaldo"); // 1
    addPlayer("Neymar"); // 2
    addPlayer("Mohamed Salah"); // 3
    addPlayer("Robert Lewandowski"); // 4
    addPlayer("Kevin De Bruyne"); // 5
    addPlayer("Luka Modrić"); // 6
    addPlayer("Eden Hazard"); // 7
    addPlayer("Sergio Ramos"); // 8
    addPlayer("Toni Kroos"); // 9
    addPlayer("Luis Su&#225;rez"); // 10
    addPlayer("Harry Kane"); // 11
    addPlayer("Sergio Ag&#252;ero"); // 12
    addPlayer("Kylian Mbapp&#233;"); // 13
    addPlayer("Gonzalo Higua&#237;n"); // 14
    addPlayer("David de Gea"); // 15
    addPlayer("Antoine Griezmann"); // 16
    addPlayer("N&#39;Golo Kant&#233;"); // 17
    addPlayer("Edinson Cavani"); // 18
    addPlayer("Paul Pogba"); // 19
    addPlayer("Isco"); // 20
    addPlayer("Marcelo"); // 21
    addPlayer("Manuel Neuer"); // 22
    addPlayer("Dries Mertens"); // 23
    addPlayer("James Rodr&#237;guez"); // 24
    addPlayer("Paulo Dybala"); // 25
    addPlayer("Christian Eriksen"); // 26
    addPlayer("David Silva"); // 27
    addPlayer("Gabriel Jesus"); // 28
    addPlayer("Thiago"); // 29
    addPlayer("Thibaut Courtois"); // 30
    addPlayer("Philippe Coutinho"); // 31
    addPlayer("Andr&#233;s Iniesta"); // 32
    addPlayer("Casemiro"); // 33
    addPlayer("Romelu Lukaku"); // 34
    addPlayer("Gerard Piqu&#233;"); // 35
    addPlayer("Mats Hummels"); // 36
    addPlayer("Diego God&#237;n"); // 37
    addPlayer("Mesut &#214;zil"); // 38
    addPlayer("Son Heung-min"); // 39
    addPlayer("Raheem Sterling"); // 40
    addPlayer("Hugo Lloris"); // 41
    addPlayer("Radamel Falcao"); // 42
    addPlayer("Ivan Rakitić"); // 43
    addPlayer("Leroy San&#233;"); // 44
    addPlayer("Roberto Firmino"); // 45
    addPlayer("Sadio Man&#233;"); // 46
    addPlayer("Thomas M&#252;ller"); // 47
    addPlayer("Dele Alli"); // 48
    addPlayer("Keylor Navas"); // 49
    addPlayer("Thiago Silva"); // 50
    addPlayer("Rapha&#235;l Varane"); // 51
    addPlayer("&#193;ngel Di Mar&#237;a"); // 52
    addPlayer("Jordi Alba"); // 53
    addPlayer("Medhi Benatia"); // 54
    addPlayer("Timo Werner"); // 55
    addPlayer("Gylfi Sigur&#240;sson"); // 56
    addPlayer("Nemanja Matić"); // 57
    addPlayer("Kalidou Koulibaly"); // 58
    addPlayer("Bernardo Silva"); // 59
    addPlayer("Vincent Kompany"); // 60
    addPlayer("Jo&#227;o Moutinho"); // 61
    addPlayer("Toby Alderweireld"); // 62
    addPlayer("Emil Forsberg"); // 63
    addPlayer("Mario Mandžukić"); // 64
    addPlayer("Sergej Milinković-Savić"); // 65
    addPlayer("Shinji Kagawa"); // 66
    addPlayer("Granit Xhaka"); // 67
    addPlayer("Andreas Christensen"); // 68
    addPlayer("Piotr Zieliński"); // 69
    addPlayer("Fyodor Smolov"); // 70
    addPlayer("Xherdan Shaqiri"); // 71
    addPlayer("Marcus Rashford"); // 72
    addPlayer("Javier Hern&#225;ndez"); // 73
    addPlayer("Hirving Lozano"); // 74
    addPlayer("Hakim Ziyech"); // 75
    addPlayer("Victor Moses"); // 76
    addPlayer("Jefferson Farf&#225;n"); // 77
    addPlayer("Mohamed Elneny"); // 78
    addPlayer("Marcus Berg"); // 79
    addPlayer("Guillermo Ochoa"); // 80
    addPlayer("Igor Akinfeev"); // 81
    addPlayer("Sardar Azmoun"); // 82
    addPlayer("Christian Cueva"); // 83
    addPlayer("Wahbi Khazri"); // 84
    addPlayer("Keisuke Honda"); // 85
    addPlayer("Tim Cahill"); // 86
    addPlayer("John Obi Mikel"); // 87
    addPlayer("Ki Sung-yueng"); // 88
    addPlayer("Bryan Ruiz"); // 89
    addPlayer("Maya Yoshida"); // 90
    addPlayer("Nawaf Al Abed"); // 91
    addPlayer("Lee Chung-yong"); // 92
    addPlayer("Gabriel G&#243;mez"); // 93
    addPlayer("Na&#239;m Sliti"); // 94
    addPlayer("Reza Ghoochannejhad"); // 95
    addPlayer("Mile Jedinak"); // 96
    addPlayer("Mohammad Al-Sahlawi"); // 97
    addPlayer("Aron Gunnarsson"); // 98
    addPlayer("Blas P&#233;rez"); // 99
    addPlayer("Dani Alves"); // 100
    addPlayer("Zlatan Ibrahimović"); // 101
  }

  /// @dev Fires an event, proving that we said a player corresponds to a given ID.
  /// @param _name The name of the player we are adding.
  function addPlayer(string _name) public onlyOwner {
    require(playerCount < 255, "You&#39;ve already added the maximum amount of players.");
    emit PlayerAdded(playerCount, _name);
    playerCount++;
  }
}


/// @title The contract that manages checklist items, sets, and rarity tiers.
/// @author The CryptoStrikers Team
contract StrikersChecklist is StrikersPlayerList {
  // High level overview of everything going on in this contract:
  //
  // ChecklistItem is the parent class to Card and has 3 properties:
  //  - uint8 checklistId (000 to 255)
  //  - uint8 playerId (see StrikersPlayerList.sol)
  //  - RarityTier tier (more info below)
  //
  // Two things to note: the checklistId is not explicitly stored
  // on the checklistItem struct, and it&#39;s composed of two parts.
  // (For the following, assume it is left padded with zeros to reach
  // three digits, such that checklistId 0 becomes 000)
  //  - the first digit represents the setId
  //      * 0 = Originals Set
  //      * 1 = Iconics Set
  //      * 2 = Unreleased Set
  //  - the last two digits represent its index in the appropriate set arary
  //
  //  For example, checklist ID 100 would represent fhe first checklist item
  //  in the iconicChecklistItems array (first digit = 1 = Iconics Set, last two
  //  digits = 00 = first index of array)
  //
  // Because checklistId is represented as a uint8 throughout the app, the highest
  // value it can take is 255, which means we can&#39;t add more than 56 items to our
  // Unreleased Set&#39;s unreleasedChecklistItems array (setId 2). Also, once we&#39;ve initialized
  // this contract, it&#39;s impossible for us to add more checklist items to the Originals
  // and Iconics set -- what you see here is what you get.
  //
  // Simple enough right?

  /// @dev We initialize this contract with so much data that we have
  ///   to stage it in 4 different steps, ~33 checklist items at a time.
  enum DeployStep {
    WaitingForStepOne,
    WaitingForStepTwo,
    WaitingForStepThree,
    WaitingForStepFour,
    DoneInitialDeploy
  }

  /// @dev Enum containing all our rarity tiers, just because
  ///   it&#39;s cleaner dealing with these values than with uint8s.
  enum RarityTier {
    IconicReferral,
    IconicInsert,
    Diamond,
    Gold,
    Silver,
    Bronze
  }

  /// @dev A lookup table indicating how limited the cards
  ///   in each tier are. If this value is 0, it means
  ///   that cards of this rarity tier are unlimited,
  ///   which is only the case for the 8 Iconics cards
  ///   we give away as part of our referral program.
  uint16[] public tierLimits = [
    0,    // Iconic - Referral Bonus (uncapped)
    100,  // Iconic Inserts ("Card of the Day")
    1000, // Diamond
    1664, // Gold
    3328, // Silver
    4352  // Bronze
  ];

  /// @dev ChecklistItem is essentially the parent class to Card.
  ///   It represents a given superclass of cards (eg Originals Messi),
  ///   and then each Card is an instance of this ChecklistItem, with
  ///   its own serial number, mint date, etc.
  struct ChecklistItem {
    uint8 playerId;
    RarityTier tier;
  }

  /// @dev The deploy step we&#39;re at. Defaults to WaitingForStepOne.
  DeployStep public deployStep;

  /// @dev Array containing all the Originals checklist items (000 - 099)
  ChecklistItem[] public originalChecklistItems;

  /// @dev Array containing all the Iconics checklist items (100 - 131)
  ChecklistItem[] public iconicChecklistItems;

  /// @dev Array containing all the unreleased checklist items (200 - 255 max)
  ChecklistItem[] public unreleasedChecklistItems;

  /// @dev Internal function to add a checklist item to the Originals set.
  /// @param _playerId The player represented by this checklist item. (see StrikersPlayerList.sol)
  /// @param _tier This checklist item&#39;s rarity tier. (see Rarity Tier enum and corresponding tierLimits)
  function _addOriginalChecklistItem(uint8 _playerId, RarityTier _tier) internal {
    originalChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

  /// @dev Internal function to add a checklist item to the Iconics set.
  /// @param _playerId The player represented by this checklist item. (see StrikersPlayerList.sol)
  /// @param _tier This checklist item&#39;s rarity tier. (see Rarity Tier enum and corresponding tierLimits)
  function _addIconicChecklistItem(uint8 _playerId, RarityTier _tier) internal {
    iconicChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

  /// @dev External function to add a checklist item to our mystery set.
  ///   Must have completed initial deploy, and can&#39;t add more than 56 items (because checklistId is a uint8).
  /// @param _playerId The player represented by this checklist item. (see StrikersPlayerList.sol)
  /// @param _tier This checklist item&#39;s rarity tier. (see Rarity Tier enum and corresponding tierLimits)
  function addUnreleasedChecklistItem(uint8 _playerId, RarityTier _tier) external onlyOwner {
    require(deployStep == DeployStep.DoneInitialDeploy, "Finish deploying the Originals and Iconics sets first.");
    require(unreleasedCount() < 56, "You can&#39;t add any more checklist items.");
    require(_playerId < playerCount, "This player doesn&#39;t exist in our player list.");
    unreleasedChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

  /// @dev Returns how many Original checklist items we&#39;ve added.
  function originalsCount() external view returns (uint256) {
    return originalChecklistItems.length;
  }

  /// @dev Returns how many Iconic checklist items we&#39;ve added.
  function iconicsCount() public view returns (uint256) {
    return iconicChecklistItems.length;
  }

  /// @dev Returns how many Unreleased checklist items we&#39;ve added.
  function unreleasedCount() public view returns (uint256) {
    return unreleasedChecklistItems.length;
  }

  // In the next four functions, we initialize this contract with our
  // 132 initial checklist items (100 Originals, 32 Iconics). Because
  // of how much data we need to store, it has to be broken up into
  // four different function calls, which need to be called in sequence.
  // The ordering of the checklist items we add determines their
  // checklist ID, which is left-padded in our frontend to be a
  // 3-digit identifier where the first digit is the setId and the last
  // 2 digits represents the checklist items index in the appropriate ___ChecklistItems array.
  // For example, Originals Messi is the first item for set ID 0, and this
  // is displayed as #000 throughout the app. Our Card struct declare its
  // checklistId property as uint8, so we have
  // to be mindful that we can only have 256 total checklist items.

  /// @dev Deploys Originals #000 through #032.
  function deployStepOne() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepOne, "You&#39;re not following the steps in order...");

    /* ORIGINALS - DIAMOND */
    _addOriginalChecklistItem(0, RarityTier.Diamond); // 000 Messi
    _addOriginalChecklistItem(1, RarityTier.Diamond); // 001 Ronaldo
    _addOriginalChecklistItem(2, RarityTier.Diamond); // 002 Neymar
    _addOriginalChecklistItem(3, RarityTier.Diamond); // 003 Salah

    /* ORIGINALS - GOLD */
    _addOriginalChecklistItem(4, RarityTier.Gold); // 004 Lewandowski
    _addOriginalChecklistItem(5, RarityTier.Gold); // 005 De Bruyne
    _addOriginalChecklistItem(6, RarityTier.Gold); // 006 Modrić
    _addOriginalChecklistItem(7, RarityTier.Gold); // 007 Hazard
    _addOriginalChecklistItem(8, RarityTier.Gold); // 008 Ramos
    _addOriginalChecklistItem(9, RarityTier.Gold); // 009 Kroos
    _addOriginalChecklistItem(10, RarityTier.Gold); // 010 Su&#225;rez
    _addOriginalChecklistItem(11, RarityTier.Gold); // 011 Kane
    _addOriginalChecklistItem(12, RarityTier.Gold); // 012 Ag&#252;ero
    _addOriginalChecklistItem(13, RarityTier.Gold); // 013 Mbapp&#233;
    _addOriginalChecklistItem(14, RarityTier.Gold); // 014 Higua&#237;n
    _addOriginalChecklistItem(15, RarityTier.Gold); // 015 de Gea
    _addOriginalChecklistItem(16, RarityTier.Gold); // 016 Griezmann
    _addOriginalChecklistItem(17, RarityTier.Gold); // 017 Kant&#233;
    _addOriginalChecklistItem(18, RarityTier.Gold); // 018 Cavani
    _addOriginalChecklistItem(19, RarityTier.Gold); // 019 Pogba

    /* ORIGINALS - SILVER (020 to 032) */
    _addOriginalChecklistItem(20, RarityTier.Silver); // 020 Isco
    _addOriginalChecklistItem(21, RarityTier.Silver); // 021 Marcelo
    _addOriginalChecklistItem(22, RarityTier.Silver); // 022 Neuer
    _addOriginalChecklistItem(23, RarityTier.Silver); // 023 Mertens
    _addOriginalChecklistItem(24, RarityTier.Silver); // 024 James
    _addOriginalChecklistItem(25, RarityTier.Silver); // 025 Dybala
    _addOriginalChecklistItem(26, RarityTier.Silver); // 026 Eriksen
    _addOriginalChecklistItem(27, RarityTier.Silver); // 027 David Silva
    _addOriginalChecklistItem(28, RarityTier.Silver); // 028 Gabriel Jesus
    _addOriginalChecklistItem(29, RarityTier.Silver); // 029 Thiago
    _addOriginalChecklistItem(30, RarityTier.Silver); // 030 Courtois
    _addOriginalChecklistItem(31, RarityTier.Silver); // 031 Coutinho
    _addOriginalChecklistItem(32, RarityTier.Silver); // 032 Iniesta

    // Move to the next deploy step.
    deployStep = DeployStep.WaitingForStepTwo;
  }

  /// @dev Deploys Originals #033 through #065.
  function deployStepTwo() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepTwo, "You&#39;re not following the steps in order...");

    /* ORIGINALS - SILVER (033 to 049) */
    _addOriginalChecklistItem(33, RarityTier.Silver); // 033 Casemiro
    _addOriginalChecklistItem(34, RarityTier.Silver); // 034 Lukaku
    _addOriginalChecklistItem(35, RarityTier.Silver); // 035 Piqu&#233;
    _addOriginalChecklistItem(36, RarityTier.Silver); // 036 Hummels
    _addOriginalChecklistItem(37, RarityTier.Silver); // 037 God&#237;n
    _addOriginalChecklistItem(38, RarityTier.Silver); // 038 &#214;zil
    _addOriginalChecklistItem(39, RarityTier.Silver); // 039 Son
    _addOriginalChecklistItem(40, RarityTier.Silver); // 040 Sterling
    _addOriginalChecklistItem(41, RarityTier.Silver); // 041 Lloris
    _addOriginalChecklistItem(42, RarityTier.Silver); // 042 Falcao
    _addOriginalChecklistItem(43, RarityTier.Silver); // 043 Rakitić
    _addOriginalChecklistItem(44, RarityTier.Silver); // 044 San&#233;
    _addOriginalChecklistItem(45, RarityTier.Silver); // 045 Firmino
    _addOriginalChecklistItem(46, RarityTier.Silver); // 046 Man&#233;
    _addOriginalChecklistItem(47, RarityTier.Silver); // 047 M&#252;ller
    _addOriginalChecklistItem(48, RarityTier.Silver); // 048 Alli
    _addOriginalChecklistItem(49, RarityTier.Silver); // 049 Navas

    /* ORIGINALS - BRONZE (050 to 065) */
    _addOriginalChecklistItem(50, RarityTier.Bronze); // 050 Thiago Silva
    _addOriginalChecklistItem(51, RarityTier.Bronze); // 051 Varane
    _addOriginalChecklistItem(52, RarityTier.Bronze); // 052 Di Mar&#237;a
    _addOriginalChecklistItem(53, RarityTier.Bronze); // 053 Alba
    _addOriginalChecklistItem(54, RarityTier.Bronze); // 054 Benatia
    _addOriginalChecklistItem(55, RarityTier.Bronze); // 055 Werner
    _addOriginalChecklistItem(56, RarityTier.Bronze); // 056 Sigur&#240;sson
    _addOriginalChecklistItem(57, RarityTier.Bronze); // 057 Matić
    _addOriginalChecklistItem(58, RarityTier.Bronze); // 058 Koulibaly
    _addOriginalChecklistItem(59, RarityTier.Bronze); // 059 Bernardo Silva
    _addOriginalChecklistItem(60, RarityTier.Bronze); // 060 Kompany
    _addOriginalChecklistItem(61, RarityTier.Bronze); // 061 Moutinho
    _addOriginalChecklistItem(62, RarityTier.Bronze); // 062 Alderweireld
    _addOriginalChecklistItem(63, RarityTier.Bronze); // 063 Forsberg
    _addOriginalChecklistItem(64, RarityTier.Bronze); // 064 Mandžukić
    _addOriginalChecklistItem(65, RarityTier.Bronze); // 065 Milinković-Savić

    // Move to the next deploy step.
    deployStep = DeployStep.WaitingForStepThree;
  }

  /// @dev Deploys Originals #066 through #099.
  function deployStepThree() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepThree, "You&#39;re not following the steps in order...");

    /* ORIGINALS - BRONZE (066 to 099) */
    _addOriginalChecklistItem(66, RarityTier.Bronze); // 066 Kagawa
    _addOriginalChecklistItem(67, RarityTier.Bronze); // 067 Xhaka
    _addOriginalChecklistItem(68, RarityTier.Bronze); // 068 Christensen
    _addOriginalChecklistItem(69, RarityTier.Bronze); // 069 Zieliński
    _addOriginalChecklistItem(70, RarityTier.Bronze); // 070 Smolov
    _addOriginalChecklistItem(71, RarityTier.Bronze); // 071 Shaqiri
    _addOriginalChecklistItem(72, RarityTier.Bronze); // 072 Rashford
    _addOriginalChecklistItem(73, RarityTier.Bronze); // 073 Hern&#225;ndez
    _addOriginalChecklistItem(74, RarityTier.Bronze); // 074 Lozano
    _addOriginalChecklistItem(75, RarityTier.Bronze); // 075 Ziyech
    _addOriginalChecklistItem(76, RarityTier.Bronze); // 076 Moses
    _addOriginalChecklistItem(77, RarityTier.Bronze); // 077 Farf&#225;n
    _addOriginalChecklistItem(78, RarityTier.Bronze); // 078 Elneny
    _addOriginalChecklistItem(79, RarityTier.Bronze); // 079 Berg
    _addOriginalChecklistItem(80, RarityTier.Bronze); // 080 Ochoa
    _addOriginalChecklistItem(81, RarityTier.Bronze); // 081 Akinfeev
    _addOriginalChecklistItem(82, RarityTier.Bronze); // 082 Azmoun
    _addOriginalChecklistItem(83, RarityTier.Bronze); // 083 Cueva
    _addOriginalChecklistItem(84, RarityTier.Bronze); // 084 Khazri
    _addOriginalChecklistItem(85, RarityTier.Bronze); // 085 Honda
    _addOriginalChecklistItem(86, RarityTier.Bronze); // 086 Cahill
    _addOriginalChecklistItem(87, RarityTier.Bronze); // 087 Mikel
    _addOriginalChecklistItem(88, RarityTier.Bronze); // 088 Sung-yueng
    _addOriginalChecklistItem(89, RarityTier.Bronze); // 089 Ruiz
    _addOriginalChecklistItem(90, RarityTier.Bronze); // 090 Yoshida
    _addOriginalChecklistItem(91, RarityTier.Bronze); // 091 Al Abed
    _addOriginalChecklistItem(92, RarityTier.Bronze); // 092 Chung-yong
    _addOriginalChecklistItem(93, RarityTier.Bronze); // 093 G&#243;mez
    _addOriginalChecklistItem(94, RarityTier.Bronze); // 094 Sliti
    _addOriginalChecklistItem(95, RarityTier.Bronze); // 095 Ghoochannejhad
    _addOriginalChecklistItem(96, RarityTier.Bronze); // 096 Jedinak
    _addOriginalChecklistItem(97, RarityTier.Bronze); // 097 Al-Sahlawi
    _addOriginalChecklistItem(98, RarityTier.Bronze); // 098 Gunnarsson
    _addOriginalChecklistItem(99, RarityTier.Bronze); // 099 P&#233;rez

    // Move to the next deploy step.
    deployStep = DeployStep.WaitingForStepFour;
  }

  /// @dev Deploys all Iconics and marks the deploy as complete!
  function deployStepFour() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepFour, "You&#39;re not following the steps in order...");

    /* ICONICS */
    _addIconicChecklistItem(0, RarityTier.IconicInsert); // 100 Messi
    _addIconicChecklistItem(1, RarityTier.IconicInsert); // 101 Ronaldo
    _addIconicChecklistItem(2, RarityTier.IconicInsert); // 102 Neymar
    _addIconicChecklistItem(3, RarityTier.IconicInsert); // 103 Salah
    _addIconicChecklistItem(4, RarityTier.IconicInsert); // 104 Lewandowski
    _addIconicChecklistItem(5, RarityTier.IconicInsert); // 105 De Bruyne
    _addIconicChecklistItem(6, RarityTier.IconicInsert); // 106 Modrić
    _addIconicChecklistItem(7, RarityTier.IconicInsert); // 107 Hazard
    _addIconicChecklistItem(8, RarityTier.IconicInsert); // 108 Ramos
    _addIconicChecklistItem(9, RarityTier.IconicInsert); // 109 Kroos
    _addIconicChecklistItem(10, RarityTier.IconicInsert); // 110 Su&#225;rez
    _addIconicChecklistItem(11, RarityTier.IconicInsert); // 111 Kane
    _addIconicChecklistItem(12, RarityTier.IconicInsert); // 112 Ag&#252;ero
    _addIconicChecklistItem(15, RarityTier.IconicInsert); // 113 de Gea
    _addIconicChecklistItem(16, RarityTier.IconicInsert); // 114 Griezmann
    _addIconicChecklistItem(17, RarityTier.IconicReferral); // 115 Kant&#233;
    _addIconicChecklistItem(18, RarityTier.IconicReferral); // 116 Cavani
    _addIconicChecklistItem(19, RarityTier.IconicInsert); // 117 Pogba
    _addIconicChecklistItem(21, RarityTier.IconicInsert); // 118 Marcelo
    _addIconicChecklistItem(24, RarityTier.IconicInsert); // 119 James
    _addIconicChecklistItem(26, RarityTier.IconicInsert); // 120 Eriksen
    _addIconicChecklistItem(29, RarityTier.IconicReferral); // 121 Thiago
    _addIconicChecklistItem(36, RarityTier.IconicReferral); // 122 Hummels
    _addIconicChecklistItem(38, RarityTier.IconicReferral); // 123 &#214;zil
    _addIconicChecklistItem(39, RarityTier.IconicInsert); // 124 Son
    _addIconicChecklistItem(46, RarityTier.IconicInsert); // 125 Man&#233;
    _addIconicChecklistItem(48, RarityTier.IconicInsert); // 126 Alli
    _addIconicChecklistItem(49, RarityTier.IconicReferral); // 127 Navas
    _addIconicChecklistItem(73, RarityTier.IconicInsert); // 128 Hern&#225;ndez
    _addIconicChecklistItem(85, RarityTier.IconicInsert); // 129 Honda
    _addIconicChecklistItem(100, RarityTier.IconicReferral); // 130 Alves
    _addIconicChecklistItem(101, RarityTier.IconicReferral); // 131 Zlatan

    // Mark the initial deploy as complete.
    deployStep = DeployStep.DoneInitialDeploy;
  }

  /// @dev Returns the mint limit for a given checklist item, based on its tier.
  /// @param _checklistId Which checklist item we need to get the limit for.
  /// @return How much of this checklist item we are allowed to mint.
  function limitForChecklistId(uint8 _checklistId) external view returns (uint16) {
    RarityTier rarityTier;
    uint8 index;
    if (_checklistId < 100) { // Originals = #000 to #099
      rarityTier = originalChecklistItems[_checklistId].tier;
    } else if (_checklistId < 200) { // Iconics = #100 to #131
      index = _checklistId - 100;
      require(index < iconicsCount(), "This Iconics checklist item doesn&#39;t exist.");
      rarityTier = iconicChecklistItems[index].tier;
    } else { // Unreleased = #200 to max #255
      index = _checklistId - 200;
      require(index < unreleasedCount(), "This Unreleased checklist item doesn&#39;t exist.");
      rarityTier = unreleasedChecklistItems[index].tier;
    }
    return tierLimits[uint8(rarityTier)];
  }
}


/// @title Base contract for CryptoStrikers. Defines what a card is and how to mint one.
/// @author The CryptoStrikers Team
contract StrikersBase is ERC721Token("CryptoStrikers", "STRK") {

  /// @dev Emit this event whenever we mint a new card (see _mintCard below)
  event CardMinted(uint256 cardId);

  /// @dev The struct representing the game&#39;s main object, a sports trading card.
  struct Card {
    // The timestamp at which this card was minted.
    // With uint32 we are good until 2106, by which point we will have not minted
    // a card in like, 88 years.
    uint32 mintTime;

    // The checklist item represented by this card. See StrikersChecklist.sol for more info.
    uint8 checklistId;

    // Cards for a given player have a serial number, which gets
    // incremented in sequence. For example, if we mint 1000 of a card,
    // the third one to be minted has serialNumber = 3 (out of 1000).
    uint16 serialNumber;
  }

  /*** STORAGE ***/

  /// @dev All the cards that have been minted, indexed by cardId.
  Card[] public cards;

  /// @dev Keeps track of how many cards we have minted for a given checklist item
  ///   to make sure we don&#39;t go over the limit for it.
  ///   NB: uint16 has a capacity of 65,535, but we are not minting more than
  ///   4,352 of any given checklist item.
  mapping (uint8 => uint16) public mintedCountForChecklistId;

  /// @dev A reference to our checklist contract, which contains all the minting limits.
  StrikersChecklist public strikersChecklist;

  /*** FUNCTIONS ***/

  /// @dev For a given owner, returns two arrays. The first contains the IDs of every card owned
  ///   by this address. The second returns the corresponding checklist ID for each of these cards.
  ///   There are a few places we need this info in the web app and short of being able to return an
  ///   actual array of Cards, this is the best solution we could come up with...
  function cardAndChecklistIdsForOwner(address _owner) external view returns (uint256[], uint8[]) {
    uint256[] memory cardIds = ownedTokens[_owner];
    uint256 cardCount = cardIds.length;
    uint8[] memory checklistIds = new uint8[](cardCount);

    for (uint256 i = 0; i < cardCount; i++) {
      uint256 cardId = cardIds[i];
      checklistIds[i] = cards[cardId].checklistId;
    }

    return (cardIds, checklistIds);
  }

  /// @dev An internal method that creates a new card and stores it.
  ///  Emits both a CardMinted and a Transfer event.
  /// @param _checklistId The ID of the checklistItem represented by the card (see Checklist.sol)
  /// @param _owner The card&#39;s first owner!
  function _mintCard(
    uint8 _checklistId,
    address _owner
  )
    internal
    returns (uint256)
  {
    uint16 mintLimit = strikersChecklist.limitForChecklistId(_checklistId);
    require(mintLimit == 0 || mintedCountForChecklistId[_checklistId] < mintLimit, "Can&#39;t mint any more of this card!");
    uint16 serialNumber = ++mintedCountForChecklistId[_checklistId];
    Card memory newCard = Card({
      mintTime: uint32(now),
      checklistId: _checklistId,
      serialNumber: serialNumber
    });
    uint256 newCardId = cards.push(newCard) - 1;
    emit CardMinted(newCardId);
    _mint(_owner, newCardId);
    return newCardId;
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
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/// @title The contract that exposes minting functions to the outside world and limits who can call them.
/// @author The CryptoStrikers Team
contract StrikersMinting is StrikersBase, Pausable {

  /// @dev Emit this when we decide to no longer mint a given checklist ID.
  event PulledFromCirculation(uint8 checklistId);

  /// @dev If the value for a checklistId is true, we can no longer mint it.
  mapping (uint8 => bool) public outOfCirculation;

  /// @dev The address of the contract that manages the pack sale.
  address public packSaleAddress;

  /// @dev Only the owner can update the address of the pack sale contract.
  /// @param _address The address of the new StrikersPackSale contract.
  function setPackSaleAddress(address _address) external onlyOwner {
    packSaleAddress = _address;
  }

  /// @dev Allows the contract at packSaleAddress to mint cards.
  /// @param _checklistId The checklist item represented by this new card.
  /// @param _owner The card&#39;s first owner!
  /// @return The new card&#39;s ID.
  function mintPackSaleCard(uint8 _checklistId, address _owner) external returns (uint256) {
    require(msg.sender == packSaleAddress, "Only the pack sale contract can mint here.");
    require(!outOfCirculation[_checklistId], "Can&#39;t mint any more of this checklist item...");
    return _mintCard(_checklistId, _owner);
  }

  /// @dev Allows the owner to mint cards from our Unreleased Set.
  /// @param _checklistId The checklist item represented by this new card. Must be >= 200.
  /// @param _owner The card&#39;s first owner!
  function mintUnreleasedCard(uint8 _checklistId, address _owner) external onlyOwner {
    require(_checklistId >= 200, "You can only use this to mint unreleased cards.");
    require(!outOfCirculation[_checklistId], "Can&#39;t mint any more of this checklist item...");
    _mintCard(_checklistId, _owner);
  }

  /// @dev Allows the owner or the pack sale contract to prevent an Iconic or Unreleased card from ever being minted again.
  /// @param _checklistId The Iconic or Unreleased card we want to remove from circulation.
  function pullFromCirculation(uint8 _checklistId) external {
    bool ownerOrPackSale = (msg.sender == owner) || (msg.sender == packSaleAddress);
    require(ownerOrPackSale, "Only the owner or pack sale can take checklist items out of circulation.");
    require(_checklistId >= 100, "This function is reserved for Iconics and Unreleased sets.");
    outOfCirculation[_checklistId] = true;
    emit PulledFromCirculation(_checklistId);
  }
}



/// @title Contract where we create Standard and Premium sales and load them with the packs to sell.
/// @author The CryptoStrikersTeam
contract StrikersPackFactory is Pausable {

  /*** IMPORTANT ***/
  // Given the imperfect nature of on-chain "randomness", we have found that, for this game, the best tradeoff
  // is to generate the PACKS (each containing 4 random CARDS) off-chain and push them to a SALE in the smart
  // contract. Users can then buy a pack, which will be drawn pseudorandomly from the packs we have pre-loaded.
  // It&#39;s obviously not perfect, but we think it&#39;s a fair tradeoff and tough enough to game, as the packs array is
  // constantly getting re-shuffled as other users buy packs.
  //
  // To save on storage, we use uint32 to represent a pack, with each of the 4 groups of 8 bits representing a checklistId (see Checklist contract).
  // Given that right now we only have 132 checklist items (with the plan to maybe add a few more during the tournament),
  // uint8 is fine (max uint8 is 255...)
  //
  // For example:
  // Pack = 00011000000001100000001000010010
  // Card 1 = 00011000 = checklistId 24
  // Card 2 = 00000110 = checklistId 6
  // Card 3 = 00000010 = checklistId 2
  // Card 4 = 00010010 = checklistId 18
  //
  // Then, when a user buys a pack, he actually mints 4 NFTs, each corresponding to one of those checklistIds (see StrikersPackSale contract).
  //
  // In testing, we were only able to load ~500 packs (recall: each a uint32) per transaction before hititng the block gas limit,
  // which may be less than we need for any given sale, so we load packs in batches. The Standard Sale runs all tournament long, and we
  // will constantly be adding packs to it, up to the limit defined by MAX_STANDARD_SALE_PACKS. As for Premium Sales, we switch over
  // to a new one every day, so while the current one is ongoing, we are able to start prepping the next one using the nextPremiumSale
  // property. We can then load the 500 packs required to start this premium sale in as many transactions as we want, before pushing it
  // live.

  /*** EVENTS ***/

  /// @dev Emit this event each time we load packs for a given sale.
  event PacksLoaded(uint8 indexed saleId, uint32[] packs);

  /// @dev Emit this event when the owner starts a sale.
  event SaleStarted(uint8 saleId, uint256 packPrice, uint8 featuredChecklistItem);

  /// @dev Emit this event when the owner changes the standard sale&#39;s packPrice.
  event StandardPackPriceChanged(uint256 packPrice);

  /*** CONSTANTS ***/

  /// @dev Our Standard sale runs all tournament long but has a hard cap of 75,616 packs.
  uint32 public constant MAX_STANDARD_SALE_PACKS = 75616;

  /// @dev Each Premium sale will contain exactly 500 packs.
  uint16 public constant PREMIUM_SALE_PACK_COUNT = 500;

  /// @dev We can only run a total of 24 Premium sales.
  uint8 public constant MAX_NUMBER_OF_PREMIUM_SALES = 24;

  /*** DATA TYPES ***/

  /// @dev The struct representing a PackSale from which packs are dispensed.
  struct PackSale {
    // A unique identifier for this sale. Based on saleCount at the time of this sale&#39;s creation.
    uint8 id;

    // The card of the day, if it&#39;s a Premium sale. Once that sale ends, we can never mint this card again.
    uint8 featuredChecklistItem;

    // The price, in wei, for 1 pack of cards. The only case where this is 0 is when the struct is null, so
    // we use it as a null check.
    uint256 packPrice;

    // All the packs we have loaded for this sale. Max 500 for each Premium sale, and 75,616 for the Standard sale.
    uint32[] packs;

    // The number of packs loaded so far in this sale. Because people will be buying from the Standard sale as
    // we keep loading packs in, we need this counter to make sure we don&#39;t go over MAX_STANDARD_SALE_PACKS.
    uint32 packsLoaded;

    // The number of packs sold so far in this sale.
    uint32 packsSold;
  }

  /*** STORAGE ***/

  /// @dev A reference to the core contract, where the cards are actually minted.
  StrikersMinting public mintingContract;

  /// @dev Our one and only Standard sale, which runs all tournament long.
  PackSale public standardSale;

  /// @dev The Premium sale that users are currently able to buy from.
  PackSale public currentPremiumSale;

  /// @dev We stage the next Premium sale here before we push it live with startNextPremiumSale().
  PackSale public nextPremiumSale;

  /// @dev How many sales we&#39;ve ran so far. Max is 25 (1 Standard + 24 Premium).
  uint8 public saleCount;

  /*** MODIFIERS  ***/

  modifier nonZeroPackPrice(uint256 _packPrice) {
    require(_packPrice > 0, "Free packs are only available through the whitelist.");
    _;
  }

  /*** CONSTRUCTOR ***/

  constructor(uint256 _packPrice) public {
    // Start contract in paused state so we have can go and load some packs in.
    paused = true;
    // Init Standard sale. (all properties default to 0, except packPrice, which we set here)
    setStandardPackPrice(_packPrice);
    saleCount++;
  }

  /*** SHARED FUNCTIONS (STANDARD & PREMIUM) ***/

  /// @dev Internal function to push a bunch of packs to a PackSale&#39;s packs array.
  /// @param _newPacks An array of 32 bit integers, each representing a shuffled pack.
  /// @param _sale The PackSale we are pushing to.
  function _addPacksToSale(uint32[] _newPacks, PackSale storage _sale) internal {
    for (uint256 i = 0; i < _newPacks.length; i++) {
      _sale.packs.push(_newPacks[i]);
    }
    _sale.packsLoaded += uint32(_newPacks.length);
    emit PacksLoaded(_sale.id, _newPacks);
  }

  /*** STANDARD SALE FUNCTIONS ***/

  /// @dev Load some shuffled packs into the Standard sale.
  /// @param _newPacks The new packs to load.
  function addPacksToStandardSale(uint32[] _newPacks) external onlyOwner {
    bool tooManyPacks = standardSale.packsLoaded + _newPacks.length > MAX_STANDARD_SALE_PACKS;
    require(!tooManyPacks, "You can&#39;t add more than 75,616 packs to the Standard sale.");
    _addPacksToSale(_newPacks, standardSale);
  }

  /// @dev After seeding the Standard sale with a few loads of packs, kick off the sale here.
  function startStandardSale() external onlyOwner {
    require(standardSale.packsLoaded > 0, "You must first load some packs into the Standard sale.");
    unpause();
    emit SaleStarted(standardSale.id, standardSale.packPrice, standardSale.featuredChecklistItem);
  }

  /// @dev Allows us to change the Standard sale pack price while the sale is ongoing, to deal with ETH
  ///   price fluctuations. Premium sale packPrice is set daily (i.e. every time we create a new Premium sale)
  /// @param _packPrice The new Standard pack price, in wei.
  function setStandardPackPrice(uint256 _packPrice) public onlyOwner nonZeroPackPrice(_packPrice) {
    standardSale.packPrice = _packPrice;
    emit StandardPackPriceChanged(_packPrice);
  }

  /*** PREMIUM SALE FUNCTIONS ***/

  /// @dev If nextPremiumSale is null, allows us to create and start setting up the next one.
  /// @param _featuredChecklistItem The card of the day, which we will take out of circulation once the sale ends.
  /// @param _packPrice The price of packs for this sale, in wei. Must be greater than zero.
  function createNextPremiumSale(uint8 _featuredChecklistItem, uint256 _packPrice) external onlyOwner nonZeroPackPrice(_packPrice) {
    require(nextPremiumSale.packPrice == 0, "Next Premium Sale already exists.");
    require(_featuredChecklistItem >= 100, "You can&#39;t have an Originals as a featured checklist item.");
    require(saleCount <= MAX_NUMBER_OF_PREMIUM_SALES, "You can only run 24 total Premium sales.");
    nextPremiumSale.id = saleCount;
    nextPremiumSale.featuredChecklistItem = _featuredChecklistItem;
    nextPremiumSale.packPrice = _packPrice;
    saleCount++;
  }

  /// @dev Load some shuffled packs into the next Premium sale that we created.
  /// @param _newPacks The new packs to load.
  function addPacksToNextPremiumSale(uint32[] _newPacks) external onlyOwner {
    require(nextPremiumSale.packPrice > 0, "You must first create a nextPremiumSale.");
    require(nextPremiumSale.packsLoaded + _newPacks.length <= PREMIUM_SALE_PACK_COUNT, "You can&#39;t add more than 500 packs to a Premium sale.");
    _addPacksToSale(_newPacks, nextPremiumSale);
  }

  /// @dev Moves the sale we staged in nextPremiumSale over to the currentPremiumSale variable, and clears nextPremiumSale.
  ///   Also removes currentPremiumSale&#39;s featuredChecklistItem from circulation.
  function startNextPremiumSale() external onlyOwner {
    require(nextPremiumSale.packsLoaded == PREMIUM_SALE_PACK_COUNT, "You must add exactly 500 packs before starting this Premium sale.");
    if (currentPremiumSale.featuredChecklistItem >= 100) {
      mintingContract.pullFromCirculation(currentPremiumSale.featuredChecklistItem);
    }
    currentPremiumSale = nextPremiumSale;
    delete nextPremiumSale;
  }

  /// @dev Allows the owner to make last second changes to the staged Premium sale before pushing it live.
  /// @param _featuredChecklistItem The card of the day, which we will take out of circulation once the sale ends.
  /// @param _packPrice The price of packs for this sale, in wei. Must be greater than zero.
  function modifyNextPremiumSale(uint8 _featuredChecklistItem, uint256 _packPrice) external onlyOwner nonZeroPackPrice(_packPrice) {
    require(nextPremiumSale.packPrice > 0, "You must first create a nextPremiumSale.");
    nextPremiumSale.featuredChecklistItem = _featuredChecklistItem;
    nextPremiumSale.packPrice = _packPrice;
  }
}


/// @title All the internal functions that govern the act of turning a uint32 pack into 4 NFTs.
/// @author The CryptoStrikers Team
contract StrikersPackSaleInternal is StrikersPackFactory {

  /// @dev Emit this every time we sell a pack.
  event PackBought(address indexed buyer, uint256[] pack);

  /// @dev The number of cards in a pack.
  uint8 public constant PACK_SIZE = 4;

  /// @dev We increment this nonce when grabbing a random pack in _removeRandomPack().
  uint256 internal randNonce;

  /// @dev Function shared by all 3 ways of buying a pack (ETH, kitty burn, whitelist).
  /// @param _sale The sale we are buying from.
  function _buyPack(PackSale storage _sale) internal whenNotPaused {
    require(msg.sender == tx.origin, "Only EOAs are allowed to buy from the pack sale.");
    require(_sale.packs.length > 0, "The sale has no packs available for sale.");
    uint32 pack = _removeRandomPack(_sale.packs);
    uint256[] memory cards = _mintCards(pack);
    _sale.packsSold++;
    emit PackBought(msg.sender, cards);
  }

  /// @dev Iterates over a uint32 pack 8 bits at a time and turns each group of 8 bits into a token!
  /// @param _pack 32 bit integer where each group of 8 bits represents a checklist ID.
  /// @return An array of 4 token IDs, representing the cards we minted.
  function _mintCards(uint32 _pack) internal returns (uint256[]) {
    uint8 mask = 255;
    uint256[] memory newCards = new uint256[](PACK_SIZE);

    for (uint8 i = 1; i <= PACK_SIZE; i++) {
      // Can&#39;t underflow because PACK_SIZE is 4.
      uint8 shift = 32 - (i * 8);
      uint8 checklistId = uint8((_pack >> shift) & mask);
      uint256 cardId = mintingContract.mintPackSaleCard(checklistId, msg.sender);
      newCards[i-1] = cardId;
    }

    return newCards;
  }

  /// @dev Given an array of packs (uint32s), removes one from a random index.
  /// @param _packs The array of uint32s we will be mutating.
  /// @return The random uint32 we removed.
  function _removeRandomPack(uint32[] storage _packs) internal returns (uint32) {
    randNonce++;
    bytes memory packed = abi.encodePacked(now, msg.sender, randNonce);
    uint256 randomIndex = uint256(keccak256(packed)) % _packs.length;
    return _removePackAtIndex(randomIndex, _packs);
  }

  /// @dev Given an array of uint32s, remove the one at a given index and replace it with the last element of the array.
  /// @param _index The index of the pack we want to remove from the array.
  /// @param _packs The array of uint32s we will be mutating.
  /// @return The uint32 we removed from position _index.
  function _removePackAtIndex(uint256 _index, uint32[] storage _packs) internal returns (uint32) {
    // Can&#39;t underflow because we do require(_sale.packs.length > 0) in _buyPack().
    uint256 lastIndex = _packs.length - 1;
    require(_index <= lastIndex);
    uint32 pack = _packs[_index];
    _packs[_index] = _packs[lastIndex];
    _packs.length--;
    return pack;
  }
}


/// @title A contract that manages the whitelist we use for free pack giveaways.
/// @author The CryptoStrikers Team
contract StrikersWhitelist is StrikersPackSaleInternal {

  /// @dev Emit this when the contract owner increases a user&#39;s whitelist allocation.
  event WhitelistAllocationIncreased(address indexed user, uint16 amount, bool premium);

  /// @dev Emit this whenever someone gets a pack using their whitelist allocation.
  event WhitelistAllocationUsed(address indexed user, bool premium);

  /// @dev We can only give away a maximum of 1000 Standard packs, and 500 Premium packs.
  uint16[2] public whitelistLimits = [
    1000, // Standard
    500 // Premium
  ];

  /// @dev Keep track of the allocation for each whitelist so we don&#39;t go over the limit.
  uint16[2] public currentWhitelistCounts;

  /// @dev Index 0 is the Standard whitelist, index 1 is the Premium whitelist. Maps addresses to free pack allocation.
  mapping (address => uint8)[2] public whitelists;

  /// @dev Allows the owner to allocate free packs (either Standard or Premium) to a given address.
  /// @param _premium True for Premium whitelist, false for Standard whitelist.
  /// @param _addr Address of the user who is getting the free packs.
  /// @param _additionalPacks How many packs we are adding to this user&#39;s allocation.
  function addToWhitelistAllocation(bool _premium, address _addr, uint8 _additionalPacks) public onlyOwner {
    uint8 listIndex = _premium ? 1 : 0;
    require(currentWhitelistCounts[listIndex] + _additionalPacks <= whitelistLimits[listIndex]);
    currentWhitelistCounts[listIndex] += _additionalPacks;
    whitelists[listIndex][_addr] += _additionalPacks;
    emit WhitelistAllocationIncreased(_addr, _additionalPacks, _premium);
  }

  /// @dev A way to call addToWhitelistAllocation in bulk. Adds 1 pack to each address.
  /// @param _premium True for Premium whitelist, false for Standard whitelist.
  /// @param _addrs Addresses of the users who are getting the free packs.
  function addAddressesToWhitelist(bool _premium, address[] _addrs) external onlyOwner {
    for (uint256 i = 0; i < _addrs.length; i++) {
      addToWhitelistAllocation(_premium, _addrs[i], 1);
    }
  }

  /// @dev If msg.sender has whitelist allocation for a given pack type, decrement it and give them a free pack.
  /// @param _premium True for the Premium sale, false for the Standard sale.
  function claimWhitelistPack(bool _premium) external {
    uint8 listIndex = _premium ? 1 : 0;
    require(whitelists[listIndex][msg.sender] > 0, "You have no whitelist allocation.");
    // Can&#39;t underflow because of require() check above.
    whitelists[listIndex][msg.sender]--;
    PackSale storage sale = _premium ? currentPremiumSale : standardSale;
    _buyPack(sale);
    emit WhitelistAllocationUsed(msg.sender, _premium);
  }
}


/// @title The contract that manages our referral program -- invite your friends and get rewarded!
/// @author The CryptoStrikers Team
contract StrikersReferral is StrikersWhitelist {

  /// @dev A cap for how many free referral packs we are giving away.
  uint16 public constant MAX_FREE_REFERRAL_PACKS = 5000;

  /// @dev The percentage of each sale that gets paid out to the referrer as commission.
  uint256 public constant PERCENT_COMMISSION = 10;

  /// @dev The 8 bonus cards that you get for your first 8 referrals, in order.
  uint8[] public bonusCards = [
    115, // Kant&#233;
    127, // Navas
    122, // Hummels
    130, // Alves
    116, // Cavani
    123, // &#214;zil
    121, // Thiago
    131 // Zlatan
  ];

  /// @dev Emit this event when a sale gets attributed, so the referrer can see a log of all his referrals.
  event SaleAttributed(address indexed referrer, address buyer, uint256 amount);

  /// @dev How much many of the 8 bonus cards this referrer has claimed.
  mapping (address => uint8) public bonusCardsClaimed;

  /// @dev Use this to track whether or not a user has bought at least one pack, to avoid people gaming our referral program.
  mapping (address => uint16) public packsBought;

  /// @dev Keep track of this to make sure we don&#39;t go over MAX_FREE_REFERRAL_PACKS.
  uint16 public freeReferralPacksClaimed;

  /// @dev Tracks whether or not a user has already claimed their free referral pack.
  mapping (address => bool) public hasClaimedFreeReferralPack;

  /// @dev How much referral income a given referrer has claimed.
  mapping (address => uint256) public referralCommissionClaimed;

  /// @dev How much referral income a given referrer has earned.
  mapping (address => uint256) public referralCommissionEarned;

  /// @dev Tracks how many sales have been attributed to a given referrer.
  mapping (address => uint16) public referralSaleCount;

  /// @dev A mapping to keep track of who referred a given user.
  mapping (address => address) public referrers;

  /// @dev How much ETH is owed to referrers, so we don&#39;t touch it when we withdraw our take from the contract.
  uint256 public totalCommissionOwed;

  /// @dev After a pack is bought with ETH, we call this to attribute the sale to the buyer&#39;s referrer.
  /// @param _buyer The user who bought the pack.
  /// @param _amount The price of the pack bought, in wei.
  function _attributeSale(address _buyer, uint256 _amount) internal {
    address referrer = referrers[_buyer];

    // Can only attribute a sale to a valid referrer.
    // Referral commissions only accrue if the referrer has bought a pack.
    if (referrer == address(0) || packsBought[referrer] == 0) {
      return;
    }

    referralSaleCount[referrer]++;

    // The first 8 referral sales each unlock a bonus card.
    // Any sales past the first 8 generate referral commission.
    if (referralSaleCount[referrer] > bonusCards.length) {
      uint256 commission = _amount * PERCENT_COMMISSION / 100;
      totalCommissionOwed += commission;
      referralCommissionEarned[referrer] += commission;
    }

    emit SaleAttributed(referrer, _buyer, _amount);
  }

  /// @dev A referrer calls this to claim the next of the 8 bonus cards he is owed.
  function claimBonusCard() external {
    uint16 attributedSales = referralSaleCount[msg.sender];
    uint8 cardsClaimed = bonusCardsClaimed[msg.sender];
    require(attributedSales > cardsClaimed, "You have no unclaimed bonus cards.");
    require(cardsClaimed < bonusCards.length, "You have claimed all the bonus cards.");
    bonusCardsClaimed[msg.sender]++;
    uint8 bonusCardChecklistId = bonusCards[cardsClaimed];
    mintingContract.mintPackSaleCard(bonusCardChecklistId, msg.sender);
  }

  /// @dev A user who was referred to CryptoStrikers can call this once to claim their free pack (must have bought a pack first).
  function claimFreeReferralPack() external {
    require(isOwedFreeReferralPack(msg.sender), "You are not eligible for a free referral pack.");
    require(freeReferralPacksClaimed < MAX_FREE_REFERRAL_PACKS, "We&#39;ve already given away all the free referral packs...");
    freeReferralPacksClaimed++;
    hasClaimedFreeReferralPack[msg.sender] = true;
    _buyPack(standardSale);
  }

  /// @dev Checks whether or not a given user is eligible for a free referral pack.
  /// @param _addr The address of the user we are inquiring about.
  /// @return True if user can call claimFreeReferralPack(), false otherwise.
  function isOwedFreeReferralPack(address _addr) public view returns (bool) {
    // _addr will only have a referrer if they&#39;ve already bought a pack (see buyFirstPackFromReferral())
    address referrer = referrers[_addr];

    // To prevent abuse, require that the referrer has bought at least one pack.
    // Guaranteed to evaluate to false if referrer is address(0), so don&#39;t even check for that.
    bool referrerHasBoughtPack = packsBought[referrer] > 0;

    // Lastly, check to make sure _addr hasn&#39;t already claimed a free pack.
    return referrerHasBoughtPack && !hasClaimedFreeReferralPack[_addr];
  }

  /// @dev Allows the contract owner to manually set the referrer for a given user, in case this wasn&#39;t properly attributed.
  /// @param _for The user we want to set the referrer for.
  /// @param _referrer The user who will now get credit for _for&#39;s future purchases.
  function setReferrer(address _for, address _referrer) external onlyOwner {
    referrers[_for] = _referrer;
  }

  /// @dev Allows a user to withdraw the referral commission they are owed.
  function withdrawCommission() external {
    uint256 commission = referralCommissionEarned[msg.sender] - referralCommissionClaimed[msg.sender];
    require(commission > 0, "You are not owed any referral commission.");
    totalCommissionOwed -= commission;
    referralCommissionClaimed[msg.sender] += commission;
    msg.sender.transfer(commission);
  }
}



/// @title The main sale contract, allowing users to purchase packs of CryptoStrikers cards.
/// @author The CryptoStrikers Team
contract StrikersPackSale is StrikersReferral {

  /// @dev The max number of kitties we are allowed to burn.
  uint16 public constant KITTY_BURN_LIMIT = 1000;

  /// @dev Emit this whenever someone sacrifices a cat for a free pack of cards.
  event KittyBurned(address user, uint256 kittyId);

  /// @dev Users are only allowed to burn 1 cat each, so keep track of that here.
  mapping (address => bool) public hasBurnedKitty;

  /// @dev A reference to the CryptoKitties contract so we can transfer cats
  ERC721Basic public kittiesContract;

  /// @dev How many kitties we have burned so far. Think of the cats, make sure we don&#39;t go over KITTY_BURN_LIMIT!
  uint16 public totalKittiesBurned;

  /// @dev Keeps track of our sale volume, in wei.
  uint256 public totalWeiRaised;

  /// @dev Constructor. Can&#39;t change minting and kitties contracts once they&#39;ve been initialized.
  constructor(
    uint256 _standardPackPrice,
    address _kittiesContractAddress,
    address _mintingContractAddress
  )
  StrikersPackFactory(_standardPackPrice)
  public
  {
    kittiesContract = ERC721Basic(_kittiesContractAddress);
    mintingContract = StrikersMinting(_mintingContractAddress);
  }

  /// @dev For a user who was referred, use this function to buy your first back so we can attribute the referral.
  /// @param _referrer The user who invited msg.sender to CryptoStrikers.
  /// @param _premium True if we&#39;re buying from Premium sale, false if we&#39;re buying from Standard sale.
  function buyFirstPackFromReferral(address _referrer, bool _premium) external payable {
    require(packsBought[msg.sender] == 0, "Only assign a referrer on a user&#39;s first purchase.");
    referrers[msg.sender] = _referrer;
    buyPackWithETH(_premium);
  }

  /// @dev Allows a user to buy a pack of cards with enough ETH to cover the packPrice.
  /// @param _premium True if we&#39;re buying from Premium sale, false if we&#39;re buying from Standard sale.
  function buyPackWithETH(bool _premium) public payable {
    PackSale storage sale = _premium ? currentPremiumSale : standardSale;
    uint256 packPrice = sale.packPrice;
    require(msg.value >= packPrice, "Insufficient ETH sent to buy this pack.");
    _buyPack(sale);
    packsBought[msg.sender]++;
    totalWeiRaised += packPrice;
    // Refund excess funds
    msg.sender.transfer(msg.value - packPrice);
    _attributeSale(msg.sender, packPrice);
  }

  /// @notice Magically transform a CryptoKitty into a free pack of cards!
  /// @param _kittyId The cat we are giving up.
  /// @dev Note that the user must first give this contract approval by
  ///   calling approve(address(this), _kittyId) on the CK contract.
  ///   Otherwise, buyPackWithKitty() throws on transferFrom().
  function buyPackWithKitty(uint256 _kittyId) external {
    require(totalKittiesBurned < KITTY_BURN_LIMIT, "Stop! Think of the cats!");
    require(!hasBurnedKitty[msg.sender], "You&#39;ve already burned a kitty.");
    totalKittiesBurned++;
    hasBurnedKitty[msg.sender] = true;
    // Will throw/revert if this contract hasn&#39;t been given approval first.
    // Also, with no way of retrieving kitties from this contract,
    // transferring to "this" burns the cat! (desired behaviour)
    kittiesContract.transferFrom(msg.sender, this, _kittyId);
    _buyPack(standardSale);
    emit KittyBurned(msg.sender, _kittyId);
  }

  /// @dev Allows the contract owner to withdraw the ETH raised from selling packs.
  function withdrawBalance() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > totalCommissionOwed, "There is no ETH for the owner to claim.");
    owner.transfer(totalBalance - totalCommissionOwed);
  }
}