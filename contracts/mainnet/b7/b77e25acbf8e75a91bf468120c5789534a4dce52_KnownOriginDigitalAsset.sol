pragma solidity ^0.4.21;

// File: contracts/ERC165.sol

interface ERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}

// File: contracts/ERC721Basic.sol

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
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

// File: contracts/ERC721.sol

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

// File: contracts/ERC721Receiver.sol

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

// File: zeppelin-solidity/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether there is code in the target address
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address address to check
   * @return whether there is code in the target address
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts/ERC721BasicToken.sol

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
      Approval(owner, _to, _tokenId);
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
    ApprovalForAll(msg.sender, _to, _approved);
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

    Transfer(_from, _to, _tokenId);
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
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
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
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
    transferFrom(_from, _to, _tokenId);
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
    Transfer(address(0), _to, _tokenId);
  }

  /**
  * @dev Internal function to burn a specific token
  * @dev Reverts if the token does not exist
  * @param _tokenId uint256 ID of the token being burned by the msg.sender
  */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    Transfer(_owner, address(0), _tokenId);
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
      Approval(_owner, address(0), _tokenId);
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
  function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// File: contracts/ERC721Token.sol

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

// File: contracts/Strings.sol

library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
    return strConcat(_a, _b, _c, _d, "");
  }

  function strConcat(string _a, string _b, string _c) internal pure returns (string) {
    return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string _a, string _b) internal pure returns (string) {
    return strConcat(_a, _b, "", "", "");
  }

  function bytes16ToStr(bytes16 _bytes16, uint8 _start, uint8 _end) internal pure returns (string) {
    bytes memory bytesArray = new bytes(_end - _start);
    uint8 pos = 0;
    for (uint8 i = _start; i < _end; i++) {
      bytesArray[pos] = _bytes16[i];
      pos++;
    }
    return string(bytesArray);
  }
}

// File: contracts/KnownOriginDigitalAsset.sol

/**
* @title KnownOriginDigitalAsset
*
* http://www.knownorigin.io/
*
* ERC721 compliant digital assets for real-world artwork.
* BE ORIGINAL. BUY ORIGINAL.
*
*/
contract KnownOriginDigitalAsset is ERC721Token, ERC165 {
  using SafeMath for uint256;

  bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
    /*
    bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
    */

  bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
    /*
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;));
    */

  bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    /*
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;tokenURI(uint256)&#39;));
    */

  bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
    /*
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
    bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
    bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;));
    */

  bytes4 public constant InterfaceSignature_ERC721Optional =- 0x4f558e79;
    /*
    bytes4(keccak256(&#39;exists(uint256)&#39;));
    */

  /**
   * @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
   * @dev Returns true for any standardized interfaces implemented by this contract.
   * @param _interfaceID bytes4 the interface to check for
   * @return true for any standardized interfaces implemented by this contract.
   */
  function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
    return ((_interfaceID == InterfaceSignature_ERC165)
    || (_interfaceID == InterfaceSignature_ERC721)
    || (_interfaceID == InterfaceSignature_ERC721Optional)
    || (_interfaceID == InterfaceSignature_ERC721Enumerable)
    || (_interfaceID == InterfaceSignature_ERC721Metadata));
  }

  struct CommissionStructure {
    uint8 curator;
    uint8 developer;
  }

  string internal tokenBaseURI = "https://ipfs.infura.io/ipfs/";

  // creates and owns the original assets all primary purchases transferred to this account
  address public curatorAccount;

  // the person who is responsible for designing and building the contract
  address public developerAccount;

  // total wei been processed through the contract
  uint256 public totalPurchaseValueInWei;

  // number of assets sold of any type
  uint256 public totalNumberOfPurchases;

  // A pointer to the next token to be minted, zero indexed
  uint256 public tokenIdPointer = 0;

  enum PurchaseState {Unsold, EtherPurchase, FiatPurchase}

  mapping(string => CommissionStructure) internal editionTypeToCommission;
  mapping(uint256 => PurchaseState) internal tokenIdToPurchased;

  mapping(uint256 => bytes16) internal tokenIdToEdition;
  mapping(uint256 => uint256) internal tokenIdToPriceInWei;
  mapping(uint256 => uint32) internal tokenIdToPurchaseFromTime;

  mapping(bytes16 => uint256) internal editionToEditionNumber;
  mapping(bytes16 => address) internal editionToArtistAccount;

  event PurchasedWithEther(uint256 indexed _tokenId, address indexed _buyer);

  event PurchasedWithFiat(uint256 indexed _tokenId);

  event PurchasedWithFiatReversed(uint256 indexed _tokenId);

  modifier onlyCurator() {
    require(msg.sender == curatorAccount);
    _;
  }

  modifier onlyUnsold(uint256 _tokenId) {
    require(tokenIdToPurchased[_tokenId] == PurchaseState.Unsold);
    _;
  }

  modifier onlyFiatPurchased(uint256 _tokenId) {
    require(tokenIdToPurchased[_tokenId] == PurchaseState.FiatPurchase);
    _;
  }

  modifier onlyKnownOriginOwnedToken(uint256 _tokenId) {
    require(tokenOwner[_tokenId] == curatorAccount || tokenOwner[_tokenId] == developerAccount);
    _;
  }

  modifier onlyKnownOrigin() {
    require(msg.sender == curatorAccount || msg.sender == developerAccount);
    _;
  }

  modifier onlyAfterPurchaseFromTime(uint256 _tokenId) {
    require(tokenIdToPurchaseFromTime[_tokenId] <= block.timestamp);
    _;
  }


  function KnownOriginDigitalAsset(address _curatorAccount) public ERC721Token("KnownOriginDigitalAsset", "KODA") {
    developerAccount = msg.sender;
    curatorAccount = _curatorAccount;
  }

  // don&#39;t accept payment directly to contract
  function() public payable {
    revert();
  }

  /**
   * @dev Mint a new KODA token
   * @dev Reverts if not called by management
   * @param _tokenURI the IPFS or equivalent hash
   * @param _edition the identifier of the edition - leading 3 bytes are the artist code, trailing 3 bytes are the asset type
   * @param _priceInWei the price of the KODA token
   * @param _auctionStartDate the date when the token is available for sale
   */
  function mint(string _tokenURI, bytes16 _edition, uint256 _priceInWei, uint32 _auctionStartDate, address _artistAccount) external onlyKnownOrigin {
    require(_artistAccount != address(0));

    uint256 _tokenId = tokenIdPointer;

    super._mint(msg.sender, _tokenId);
    super._setTokenURI(_tokenId, _tokenURI);

    editionToArtistAccount[_edition] = _artistAccount;

    _populateTokenData(_tokenId, _edition, _priceInWei, _auctionStartDate);

    tokenIdPointer = tokenIdPointer.add(1);
  }

  function _populateTokenData(uint _tokenId, bytes16 _edition, uint256 _priceInWei, uint32 _purchaseFromTime) internal {
    tokenIdToEdition[_tokenId] = _edition;
    editionToEditionNumber[_edition] = editionToEditionNumber[_edition].add(1);
    tokenIdToPriceInWei[_tokenId] = _priceInWei;
    tokenIdToPurchaseFromTime[_tokenId] = _purchaseFromTime;
  }

  /**
   * @dev Burns a KODA token
   * @dev Reverts if token is not unsold or not owned by management
   * @param _tokenId the KODA token ID
   */
  function burn(uint256 _tokenId) public onlyKnownOrigin onlyUnsold(_tokenId) onlyKnownOriginOwnedToken(_tokenId) {
    require(exists(_tokenId));
    super._burn(ownerOf(_tokenId), _tokenId);

    bytes16 edition = tokenIdToEdition[_tokenId];

    delete tokenIdToEdition[_tokenId];
    delete tokenIdToPriceInWei[_tokenId];
    delete tokenIdToPurchaseFromTime[_tokenId];

    editionToEditionNumber[edition] = editionToEditionNumber[edition].sub(1);
  }

  /**
   * @dev Utility function for updating a KODA assets token URI
   * @dev Reverts if not called by management
   * @param _tokenId the KODA token ID
   * @param _uri the token URI, will be concatenated with baseUri
   */
  function setTokenURI(uint256 _tokenId, string _uri) external onlyKnownOrigin {
    require(exists(_tokenId));
    _setTokenURI(_tokenId, _uri);
  }

  /**
   * @dev Utility function for updating a KODA assets price
   * @dev Reverts if token is not unsold or not called by management
   * @param _tokenId the KODA token ID
   * @param _priceInWei the price in wei
   */
  function setPriceInWei(uint _tokenId, uint256 _priceInWei) external onlyKnownOrigin onlyUnsold(_tokenId) {
    require(exists(_tokenId));
    tokenIdToPriceInWei[_tokenId] = _priceInWei;
  }

  /**
   * @dev Used to pre-approve a purchaser in order for internal purchase methods
   * to succeed without calling approve() directly
   * @param _tokenId the KODA token ID
   * @return address currently approved for a the given token ID
   */
  function _approvePurchaser(address _to, uint256 _tokenId) internal {
    address owner = ownerOf(_tokenId);
    require(_to != address(0));

    tokenApprovals[_tokenId] = _to;
    Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Updates the commission structure for the given _type
   * @dev Reverts if not called by management
   * @param _type the asset type
   * @param _curator the curators commission
   * @param _developer the developers commission
   */
  function updateCommission(string _type, uint8 _curator, uint8 _developer) external onlyKnownOrigin {
    require(_curator > 0);
    require(_developer > 0);
    require((_curator + _developer) < 100);

    editionTypeToCommission[_type] = CommissionStructure({curator : _curator, developer : _developer});
  }

  /**
   * @dev Utility function for retrieving the commission structure for the provided _type
   * @param _type the asset type
   * @return the commission structure or zero for both values when not found
   */
  function getCommissionForType(string _type) public view returns (uint8 _curator, uint8 _developer) {
    CommissionStructure storage commission = editionTypeToCommission[_type];
    return (commission.curator, commission.developer);
  }

  /**
   * @dev Purchase the provide token in Ether
   * @dev Reverts if token not unsold and not available to be purchased
   * msg.sender will become the owner of the token
   * msg.value needs to be >= to the token priceInWei
   * @param _tokenId the KODA token ID
   * @return true/false depending on success
   */
  function purchaseWithEther(uint256 _tokenId) public payable onlyUnsold(_tokenId) onlyKnownOriginOwnedToken(_tokenId) onlyAfterPurchaseFromTime(_tokenId) {
    require(exists(_tokenId));

    uint256 priceInWei = tokenIdToPriceInWei[_tokenId];
    require(msg.value >= priceInWei);

    // approve sender as they have paid the required amount
    _approvePurchaser(msg.sender, _tokenId);

    // transfer assets from contract creator (curator) to new owner
    safeTransferFrom(curatorAccount, msg.sender, _tokenId);

    // now purchased - don&#39;t allow re-purchase!
    tokenIdToPurchased[_tokenId] = PurchaseState.EtherPurchase;

    totalPurchaseValueInWei = totalPurchaseValueInWei.add(msg.value);
    totalNumberOfPurchases = totalNumberOfPurchases.add(1);

    // Only apply commission if the art work has value
    if (priceInWei > 0) {
      _applyCommission(_tokenId);
    }

    PurchasedWithEther(_tokenId, msg.sender);
  }

  /**
   * @dev Purchase the provide token in FIAT, management command only for taking fiat payments during KODA physical exhibitions
   * Equivalent to taking the KODA token off the market and marking as sold
   * @dev Reverts if token not unsold and not available to be purchased and not called by management
   * @param _tokenId the KODA token ID
   */
  function purchaseWithFiat(uint256 _tokenId) public onlyKnownOrigin onlyUnsold(_tokenId) onlyAfterPurchaseFromTime(_tokenId) {
    require(exists(_tokenId));

    // now purchased - don&#39;t allow re-purchase!
    tokenIdToPurchased[_tokenId] = PurchaseState.FiatPurchase;

    totalNumberOfPurchases = totalNumberOfPurchases.add(1);

    PurchasedWithFiat(_tokenId);
  }

  /**
   * @dev Reverse a fiat purchase made by calling purchaseWithFiat()
   * @dev Reverts if token not purchased with fiat and not available to be purchased and not called by management
   * @param _tokenId the KODA token ID
   */
  function reverseFiatPurchase(uint256 _tokenId) public onlyKnownOrigin onlyFiatPurchased(_tokenId) onlyAfterPurchaseFromTime(_tokenId) {
    require(exists(_tokenId));

    // reset to Unsold
    tokenIdToPurchased[_tokenId] = PurchaseState.Unsold;

    totalNumberOfPurchases = totalNumberOfPurchases.sub(1);

    PurchasedWithFiatReversed(_tokenId);
  }

  /**
   * @dev Internal function for apply commission on purchase
   */
  function _applyCommission(uint256 _tokenId) internal {
    bytes16 edition = tokenIdToEdition[_tokenId];

    string memory typeCode = getTypeFromEdition(edition);

    CommissionStructure memory commission = editionTypeToCommission[typeCode];

    // split & transfer fee for curator
    uint curatorAccountFee = msg.value / 100 * commission.curator;
    curatorAccount.transfer(curatorAccountFee);

    // split & transfer fee for developer
    uint developerAccountFee = msg.value / 100 * commission.developer;
    developerAccount.transfer(developerAccountFee);

    // final payment to commission would be the remaining value
    uint finalCommissionTotal = msg.value - (curatorAccountFee + developerAccountFee);

    // send ether
    address artistAccount = editionToArtistAccount[edition];
    artistAccount.transfer(finalCommissionTotal);
  }

  /**
   * @dev Retrieve all asset information for the provided token
   * @param _tokenId the KODA token ID
   * @return tokenId, owner, purchaseState, priceInWei, purchaseFromDateTime
   */
  function assetInfo(uint _tokenId) public view returns (
    uint256 _tokId,
    address _owner,
    PurchaseState _purchaseState,
    uint256 _priceInWei,
    uint32 _purchaseFromTime
  ) {
    return (
      _tokenId,
      tokenOwner[_tokenId],
      tokenIdToPurchased[_tokenId],
      tokenIdToPriceInWei[_tokenId],
      tokenIdToPurchaseFromTime[_tokenId]
    );
  }

  /**
   * @dev Retrieve all edition information for the provided token
   * @param _tokenId the KODA token ID
   * @return tokenId, edition, editionNumber, tokenUri
   */
  function editionInfo(uint256 _tokenId) public view returns (
    uint256 _tokId,
    bytes16 _edition,
    uint256 _editionNumber,
    string _tokenURI,
    address _artistAccount
  ) {
    bytes16 edition = tokenIdToEdition[_tokenId];
    return (
      _tokenId,
      edition,
      editionToEditionNumber[edition],
      tokenURI(_tokenId),
      editionToArtistAccount[edition]
    );
  }

  function tokensOf(address _owner) public view returns (uint256[] _tokenIds) {
    return ownedTokens[_owner];
  }

  /**
   * @dev Return the total number of assets in an edition
   * @param _edition the edition identifier
   */
  function numberOf(bytes16 _edition) public view returns (uint256) {
    return editionToEditionNumber[_edition];
  }

  /**
   * @dev Get the token purchase state for the given token
   * @param _tokenId the KODA token ID
   * @return the purchase sate, either 0, 1, 2, reverts if token not found
   */
  function isPurchased(uint256 _tokenId) public view returns (PurchaseState _purchased) {
    require(exists(_tokenId));
    return tokenIdToPurchased[_tokenId];
  }

  /**
   * @dev Get the edition identifier for the given token
   * @param _tokenId the KODA token ID
   * @return the edition is found, reverts if token not found
   */
  function editionOf(uint256 _tokenId) public view returns (bytes16 _edition) {
    require(exists(_tokenId));
    return tokenIdToEdition[_tokenId];
  }

  /**
   * @dev Get the purchase from time for the given token
   * @param _tokenId the KODA token ID
   * @return the purchased from time, reverts if token not found
   */
  function purchaseFromTime(uint256 _tokenId) public view returns (uint32 _purchaseFromTime) {
    require(exists(_tokenId));
    return tokenIdToPurchaseFromTime[_tokenId];
  }

  /**
   * @dev Get the price in wei for the given token
   * @param _tokenId the KODA token ID
   * @return the price in wei, reverts if token not found
   */
  function priceInWei(uint256 _tokenId) public view returns (uint256 _priceInWei) {
    require(exists(_tokenId));
    return tokenIdToPriceInWei[_tokenId];
  }

  /**
   * @dev Get the type for the provided edition, useful for testing purposes
   * @param _edition the edition identifier
   * @return the type or blank string
   */
  function getTypeFromEdition(bytes16 _edition) public pure returns (string) {
    // return last 3 chars that represent the edition type
    return Strings.bytes16ToStr(_edition, 13, 16);
  }

  /**
   * @dev Get token URI fro the given token, useful for testing purposes
   * @param _tokenId the KODA token ID
   * @return the token ID or only the base URI if not found
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    return Strings.strConcat(tokenBaseURI, tokenURIs[_tokenId]);
  }

  /**
   * @dev Allows management to update the base tokenURI path
   * @dev Reverts if not called by management
   * @param _newBaseURI the new base URI to set
   */
  function setTokenBaseURI(string _newBaseURI) external onlyKnownOrigin {
    tokenBaseURI = _newBaseURI;
  }

  /**
   * @dev Allows management to update the artist account (where commission is sent)
   * @dev Reverts if not called by management
   * @param _edition edition to adjust
    * @param _artistAccount address of artist on blockchain
   */
  function setArtistAccount(bytes16 _edition, address _artistAccount) external onlyKnownOrigin {
    require(_artistAccount != address(0));

    editionToArtistAccount[_edition] = _artistAccount;
  }
}