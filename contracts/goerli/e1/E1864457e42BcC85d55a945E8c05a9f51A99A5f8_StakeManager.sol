/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity ^0.5.2;

/**
 * @title IERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.2;
/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721 is IERC165 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId) public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator) public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId) public;

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.5.2;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safeTransfer`. This function MUST return the function selector,
   * otherwise the caller will revert the transaction. The selector to be
   * returned can be obtained as `this.onERC721Received.selector`. This
   * function MAY throw to revert and reject the transfer.
   * Note: the ERC721 contract address is always the message sender.
   * @param operator The address which called `safeTransferFrom` function
   * @param from The address which previously owned the token
   * @param tokenId The NFT identifier which is being transferred
   * @param data Additional data with no specified format
   * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
  public returns (bytes4);
}

pragma solidity ^0.5.2;

/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
  /*
   * 0x01ffc9a7 ===
   *     bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) private _supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor () internal {
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  /**
   * @dev internal method for registering an interface
   */
  function _registerInterface(bytes4 interfaceId) internal {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.5.2;

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165, IERC721 {
  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => Counters.Counter) private _ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *     bytes4(keccak256('balanceOf(address)')) ^
   *     bytes4(keccak256('ownerOf(uint256)')) ^
   *     bytes4(keccak256('approve(address,uint256)')) ^
   *     bytes4(keccak256('getApproved(uint256)')) ^
   *     bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *     bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *     bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  constructor () public {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner].current();
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param tokenId uint256 ID of the token to query the owner of
   * @return address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function transferFrom(address from, address to, uint256 tokenId) public {
    require(_isApprovedOrOwner(msg.sender, tokenId));

    _transferFrom(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
    transferFrom(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

  /**
   * @dev Returns whether the specified token exists
   * @param tokenId uint256 ID of the token to query the existence of
   * @return bool whether the token exists
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   * is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    require(!_exists(tokenId));

    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to].increment();

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * Deprecated, use _burn(uint256) instead.
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner);

    _clearApproval(tokenId);

    _ownedTokensCount[owner].decrement();
    _tokenOwner[tokenId] = address(0);

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(uint256 tokenId) internal {
    _burn(ownerOf(tokenId), tokenId);
  }

  /**
   * @dev Internal function to transfer ownership of a given token ID to another address.
   * As opposed to transferFrom, this imposes no restrictions on msg.sender.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _transferFrom(address from, address to, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    require(to != address(0));

    _clearApproval(tokenId);

    _ownedTokensCount[from].decrement();
    _ownedTokensCount[to].increment();

    _tokenOwner[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
  internal returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }

    bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

  /**
   * @dev Private function to clear current approval of a given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.5.2;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity ^0.5.2;

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  /*
   * 0x780e9d63 ===
   *     bytes4(keccak256('totalSupply()')) ^
   *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *     bytes4(keccak256('tokenByIndex(uint256)'))
   */

  /**
   * @dev Constructor function
   */
  constructor () public {
    // register the supported interface to conform to ERC721Enumerable via ERC165
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param owner address owning the tokens list to be accessed
   * @param index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

  /**
   * @dev Internal function to transfer ownership of a given token ID to another address.
   * As opposed to transferFrom, this imposes no restrictions on msg.sender.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _transferFrom(address from, address to, uint256 tokenId) internal {
    super._transferFrom(from, to, tokenId);

    _removeTokenFromOwnerEnumeration(from, tokenId);

    _addTokenToOwnerEnumeration(to, tokenId);
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to address the beneficiary that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _addTokenToOwnerEnumeration(to, tokenId);

    _addTokenToAllTokensEnumeration(tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * Deprecated, use _burn(uint256) instead
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    _removeTokenFromOwnerEnumeration(owner, tokenId);
    // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
    _ownedTokensIndex[tokenId] = 0;

    _removeTokenFromAllTokensEnumeration(tokenId);
  }

  /**
   * @dev Gets the list of token IDs of the requested owner
   * @param owner address owning the tokens
   * @return uint256[] List of token IDs owned by the requested address
   */
  function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
    return _ownedTokens[owner];
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
  }

  /**
   * @dev Private function to add a token to this extension's token tracking data structures.
   * @param tokenId uint256 ID of the token to be added to the tokens list
   */
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    _ownedTokens[from].length--;

    // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
    // lastTokenId, or just over the end of the array if the token was the last one).
  }

  /**
   * @dev Private function to remove a token from this extension's token tracking data structures.
   * This has O(1) time complexity, but alters the order of the _allTokens array.
   * @param tokenId uint256 ID of the token to be removed from the tokens list
   */
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 tokenIndex = _allTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    // This also deletes the contents at the last position of the array
    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity ^0.5.2;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol

pragma solidity ^0.5.2;

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  /*
   * 0x5b5e139f ===
   *     bytes4(keccak256('name()')) ^
   *     bytes4(keccak256('symbol()')) ^
   *     bytes4(keccak256('tokenURI(uint256)'))
   */

  /**
   * @dev Constructor function
   */
  constructor (string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param tokenId uint256 ID of the token to set its URI
   * @param uri string URI to assign
   */
  function _setTokenURI(uint256 tokenId, string memory uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * Deprecated, use _burn(uint256) instead
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}


pragma solidity ^0.5.2;

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
    // solhint-disable-previous-line no-empty-blocks
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
   * @dev Total number of tokens in existence
   */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param owner The address to query the balance of.
   * @return A uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  /**
   * @dev Transfer token to a specified address
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another.
   * Note that while this function emits an Approval event, this is not required as per the specification,
   * and other compliant implementations may not emit the event.
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to tr vbmansfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when _allowed[msg.sender][spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * Emits an Approval event.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * Emits an Approval event.
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  /**
   * @dev Transfer token for a specified addresses
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Approve an address to spend another addresses' tokens.
   * @param owner The address that owns the tokens.
   * @param spender The address that will spend the tokens.
   * @param value The number of tokens that can be spent.
   */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * Emits an Approval event (reflecting the reduced allowance).
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    _burn(account, value);
    _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }
}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   * @notice Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/


// File: openzeppelin-solidity/contracts/math/Math.sol

pragma solidity ^0.5.2;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Calculates the average of two numbers. Since these are integers,
   * averages of an even and odd number cannot be represented, and will be
   * rounded down.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: solidity-rlp/contracts/RLPReader.sol

/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
pragma solidity ^0.5.0;

library RLPReader {
  uint8 constant STRING_SHORT_START = 0x80;
  uint8 constant STRING_LONG_START  = 0xb8;
  uint8 constant LIST_SHORT_START   = 0xc0;
  uint8 constant LIST_LONG_START    = 0xf8;
  uint8 constant WORD_SIZE = 32;

  struct RLPItem {
    uint len;
    uint memPtr;
  }

  struct Iterator {
    RLPItem item;   // Item that's being iterated over.
    uint nextPtr;   // Position of the next item in the list.
  }

  /*
  * @dev Returns the next element in the iteration. Reverts if it has not next element.
  * @param self The iterator.
  * @return The next element in the iteration.
  */
  function next(Iterator memory self) internal pure returns (RLPItem memory) {
    require(hasNext(self));

    uint ptr = self.nextPtr;
    uint itemLength = _itemLength(ptr);
    self.nextPtr = ptr + itemLength;

    return RLPItem(itemLength, ptr);
  }

  /*
  * @dev Returns true if the iteration has more elements.
  * @param self The iterator.
  * @return true if the iteration has more elements.
  */
  function hasNext(Iterator memory self) internal pure returns (bool) {
    RLPItem memory item = self.item;
    return self.nextPtr < item.memPtr + item.len;
  }

  /*
  * @param item RLP encoded bytes
  */
  function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
    uint memPtr;
    assembly {
      memPtr := add(item, 0x20)
    }

    return RLPItem(item.length, memPtr);
  }

  /*
  * @dev Create an iterator. Reverts if item is not a list.
  * @param self The RLP item.
  * @return An 'Iterator' over the item.
  */
  function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
    require(isList(self));

    uint ptr = self.memPtr + _payloadOffset(self.memPtr);
    return Iterator(self, ptr);
  }

  /*
  * @param item RLP encoded bytes
  */
  function rlpLen(RLPItem memory item) internal pure returns (uint) {
    return item.len;
  }

  /*
  * @param item RLP encoded bytes
  */
  function payloadLen(RLPItem memory item) internal pure returns (uint) {
    return item.len - _payloadOffset(item.memPtr);
  }

  /*
  * @param item RLP encoded list in bytes
  */
  function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
    require(isList(item));

    uint items = numItems(item);
    RLPItem[] memory result = new RLPItem[](items);

    uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint dataLen;
    for (uint i = 0; i < items; i++) {
      dataLen = _itemLength(memPtr);
      result[i] = RLPItem(dataLen, memPtr);
      memPtr = memPtr + dataLen;
    }

    return result;
  }

  // @return indicator whether encoded payload is a list. negate this function call for isData.
  function isList(RLPItem memory item) internal pure returns (bool) {
    if (item.len == 0) return false;

    uint8 byte0;
    uint memPtr = item.memPtr;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < LIST_SHORT_START)
      return false;
    return true;
  }

  /** RLPItem conversions into data types **/

  // @returns raw rlp encoding in bytes
  function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
    bytes memory result = new bytes(item.len);
    if (result.length == 0) return result;

    uint ptr;
    assembly {
      ptr := add(0x20, result)
    }

    copy(item.memPtr, ptr, item.len);
    return result;
  }

  // any non-zero byte is considered true
  function toBoolean(RLPItem memory item) internal pure returns (bool) {
    require(item.len == 1);
    uint result;
    uint memPtr = item.memPtr;
    assembly {
      result := byte(0, mload(memPtr))
    }

    return result == 0 ? false : true;
  }

  function toAddress(RLPItem memory item) internal pure returns (address) {
    // 1 byte for the length prefix
    require(item.len == 21);

    return address(toUint(item));
  }

  function toUint(RLPItem memory item) internal pure returns (uint) {
    require(item.len > 0 && item.len <= 33);

    uint offset = _payloadOffset(item.memPtr);
    uint len = item.len - offset;

    uint result;
    uint memPtr = item.memPtr + offset;
    assembly {
      result := mload(memPtr)

    // shfit to the correct location if neccesary
      if lt(len, 32) {
        result := div(result, exp(256, sub(32, len)))
      }
    }

    return result;
  }

  // enforces 32 byte length
  function toUintStrict(RLPItem memory item) internal pure returns (uint) {
    // one byte prefix
    require(item.len == 33);

    uint result;
    uint memPtr = item.memPtr + 1;
    assembly {
      result := mload(memPtr)
    }

    return result;
  }

  function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
    require(item.len > 0);

    uint offset = _payloadOffset(item.memPtr);
    uint len = item.len - offset; // data length
    bytes memory result = new bytes(len);

    uint destPtr;
    assembly {
      destPtr := add(0x20, result)
    }

    copy(item.memPtr + offset, destPtr, len);
    return result;
  }

  /*
  * Private Helpers
  */

  // @return number of payload items inside an encoded list.
  function numItems(RLPItem memory item) private pure returns (uint) {
    if (item.len == 0) return 0;

    uint count = 0;
    uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint endPtr = item.memPtr + item.len;
    while (currPtr < endPtr) {
      currPtr = currPtr + _itemLength(currPtr); // skip over an item
      count++;
    }

    return count;
  }

  // @return entire rlp item byte length
  function _itemLength(uint memPtr) private pure returns (uint) {
    uint itemLen;
    uint byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START)
      itemLen = 1;

    else if (byte0 < STRING_LONG_START)
      itemLen = byte0 - STRING_SHORT_START + 1;

    else if (byte0 < LIST_SHORT_START) {
      assembly {
        let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
        memPtr := add(memPtr, 1) // skip over the first byte

      /* 32 byte word size */
        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
        itemLen := add(dataLen, add(byteLen, 1))
      }
    }

    else if (byte0 < LIST_LONG_START) {
      itemLen = byte0 - LIST_SHORT_START + 1;
    }

    else {
      assembly {
        let byteLen := sub(byte0, 0xf7)
        memPtr := add(memPtr, 1)

        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
        itemLen := add(dataLen, add(byteLen, 1))
      }
    }

    return itemLen;
  }

  // @return number of bytes until the data
  function _payloadOffset(uint memPtr) private pure returns (uint) {
    uint byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START)
      return 0;
    else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
      return 1;
    else if (byte0 < LIST_SHORT_START)  // being explicit
      return byte0 - (STRING_LONG_START - 1) + 1;
    else
      return byte0 - (LIST_LONG_START - 1) + 1;
  }

  /*
  * @param src Pointer to source
  * @param dest Pointer to destination
  * @param len Amount of memory to copy from the source
  */
  function copy(uint src, uint dest, uint len) private pure {
    if (len == 0) return;

    // copy as many word sizes as possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }

      src += WORD_SIZE;
      dest += WORD_SIZE;
    }

    // left over bytes. Mask is used to remove unwanted bytes from the word
    uint mask = 256 ** (WORD_SIZE - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask)) // zero out src
      let destpart := and(mload(dest), mask) // retrieve the bytes
      mstore(dest, or(destpart, srcpart))
    }
  }
}

pragma solidity ^0.5.2;

/**
 * Utility library of inline functions on addresses
 */
library Address {
  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solhint-disable-next-line no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}

// File: openzeppelin-solidity/contracts/drafts/Counters.sol

pragma solidity ^0.5.2;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
  using SafeMath for uint256;

  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
  }
}


// Library for RLP encoding a list of bytes arrays.
// Modeled after ethereumjs/rlp (https://github.com/ethereumjs/rlp)
// [Very] modified version of Sam Mayo's library.
pragma solidity ^0.5.2;

library RLPEncode {
  // Encode an item (bytes memory)
  function encodeItem(bytes memory self)
  internal
  pure
  returns (bytes memory)
  {
    bytes memory encoded;
    if (self.length == 1 && uint8(self[0] & 0xFF) < 0x80) {
      encoded = new bytes(1);
      encoded = self;
    } else {
      encoded = BytesLib.concat(encodeLength(self.length, 128), self);
    }
    return encoded;
  }

  // Encode a list of items
  function encodeList(bytes[] memory self)
  internal
  pure
  returns (bytes memory)
  {
    bytes memory encoded;
    for (uint256 i = 0; i < self.length; i++) {
      encoded = BytesLib.concat(encoded, encodeItem(self[i]));
    }
    return BytesLib.concat(encodeLength(encoded.length, 192), encoded);
  }

  // Hack to encode nested lists. If you have a list as an item passed here, included
  // pass = true in that index. E.g.
  // [item, list, item] --> pass = [false, true, false]
  // function encodeListWithPasses(bytes[] memory self, bool[] pass) internal pure returns (bytes memory) {
  //   bytes memory encoded;
  //   for (uint i=0; i < self.length; i++) {
  // 		if (pass[i] == true) {
  // 			encoded = BytesLib.concat(encoded, self[i]);
  // 		} else {
  // 			encoded = BytesLib.concat(encoded, encodeItem(self[i]));
  // 		}
  //   }
  //   return BytesLib.concat(encodeLength(encoded.length, 192), encoded);
  // }

  // Generate the prefix for an item or the entire list based on RLP spec
  function encodeLength(uint256 L, uint256 offset)
  internal
  pure
  returns (bytes memory)
  {
    if (L < 56) {
      bytes memory prefix = new bytes(1);
      prefix[0] = bytes1(uint8(L + offset));
      return prefix;
    } else {
      // lenLen is the length of the hex representation of the data length
      uint256 lenLen;
      uint256 i = 0x1;

      while (L / i != 0) {
        lenLen++;
        i *= 0x100;
      }

      bytes memory prefix0 = getLengthBytes(offset + 55 + lenLen);
      bytes memory prefix1 = getLengthBytes(L);
      return BytesLib.concat(prefix0, prefix1);
    }
  }

  function getLengthBytes(uint256 x) internal pure returns (bytes memory b) {
    // Figure out if we need 1 or two bytes to express the length.
    // 1 byte gets us to max 255
    // 2 bytes gets us to max 65535 (no payloads will be larger than this)
    uint256 nBytes = 1;
    if (x > 255) {
      nBytes = 2;
    }

    b = new bytes(nBytes);
    // Encode the length and return it
    for (uint256 i = 0; i < nBytes; i++) {
      b[i] = bytes1(uint8(x / (2**(8 * (nBytes - 1 - i)))));
    }
  }
}



/*
 * @title MerklePatriciaVerifier
 * @author Sam Mayo ([email protected])
 *
 * @dev Library for verifing merkle patricia proofs.
 */
pragma solidity ^0.5.2;

library MerklePatriciaProof {
  /*
 * @dev Verifies a merkle patricia proof.
 * @param value The terminating value in the trie.
 * @param encodedPath The path in the trie leading to value.
 * @param rlpParentNodes The rlp encoded stack of nodes.
 * @param root The root hash of the trie.
 * @return The boolean validity of the proof.
 */
  function verify(
    bytes memory value,
    bytes memory encodedPath,
    bytes memory rlpParentNodes,
    bytes32 root
  ) internal pure returns (bool) {
    RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
    RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

    bytes memory currentNode;
    RLPReader.RLPItem[] memory currentNodeList;

    bytes32 nodeKey = root;
    uint256 pathPtr = 0;

    bytes memory path = _getNibbleArray(encodedPath);
    if (path.length == 0) {
      return false;
    }

    for (uint256 i = 0; i < parentNodes.length; i++) {
      if (pathPtr > path.length) {
        return false;
      }

      currentNode = RLPReader.toRlpBytes(parentNodes[i]);
      if (nodeKey != keccak256(currentNode)) {
        return false;
      }
      currentNodeList = RLPReader.toList(parentNodes[i]);

      if (currentNodeList.length == 17) {
        if (pathPtr == path.length) {
          if (
            keccak256(RLPReader.toBytes(currentNodeList[16])) ==
            keccak256(value)
          ) {
            return true;
          } else {
            return false;
          }
        }

        uint8 nextPathNibble = uint8(path[pathPtr]);
        if (nextPathNibble > 16) {
          return false;
        }
        nodeKey = bytes32(
          RLPReader.toUintStrict(currentNodeList[nextPathNibble])
        );
        pathPtr += 1;
      } else if (currentNodeList.length == 2) {
        pathPtr += _nibblesToTraverse(
          RLPReader.toBytes(currentNodeList[0]),
          path,
          pathPtr
        );
        if (pathPtr == path.length) {
          //leaf node
          if (
            keccak256(RLPReader.toBytes(currentNodeList[1])) ==
            keccak256(value)
          ) {
            return true;
          } else {
            return false;
          }
        }

        //extension node
        if (
          _nibblesToTraverse(
            RLPReader.toBytes(currentNodeList[0]),
            path,
            pathPtr
          ) ==
          0
        ) {
          return false;
        }

        nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
      } else {
        return false;
      }
    }
  }

  function _nibblesToTraverse(
    bytes memory encodedPartialPath,
    bytes memory path,
    uint256 pathPtr
  ) private pure returns (uint256) {
    uint256 len;
    // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
    // and slicedPath have elements that are each one hex character (1 nibble)
    bytes memory partialPath = _getNibbleArray(encodedPartialPath);
    bytes memory slicedPath = new bytes(partialPath.length);

    // pathPtr counts nibbles in path
    // partialPath.length is a number of nibbles
    for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
      bytes1 pathNibble = path[i];
      slicedPath[i - pathPtr] = pathNibble;
    }

    if (keccak256(partialPath) == keccak256(slicedPath)) {
      len = partialPath.length;
    } else {
      len = 0;
    }
    return len;
  }

  // bytes b must be hp encoded
  function _getNibbleArray(bytes memory b)
  private
  pure
  returns (bytes memory)
  {
    bytes memory nibbles;
    if (b.length > 0) {
      uint8 offset;
      uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
      if (hpNibble == 1 || hpNibble == 3) {
        nibbles = new bytes(b.length * 2 - 1);
        bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
        nibbles[0] = oddNibble;
        offset = 1;
      } else {
        nibbles = new bytes(b.length * 2 - 2);
        offset = 0;
      }

      for (uint256 i = offset; i < nibbles.length; i++) {
        nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
      }
    }
    return nibbles;
  }

  function _getNthNibbleOfBytes(uint256 n, bytes memory str)
  private
  pure
  returns (bytes1)
  {
    return
    bytes1(
      n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10
    );
  }
}


pragma solidity ^0.5.2;

library Merkle {
  function checkMembership(
    bytes32 leaf,
    uint256 index,
    bytes32 rootHash,
    bytes memory proof
  ) public pure returns (bool) {
    require(proof.length % 32 == 0, "Invalid proof length");
    uint256 proofHeight = proof.length / 32;
    // Proof of size n means, height of the tree is n+1.
    // In a tree of height n+1, max #leafs possible is 2 ^ n
    require(index < 2 ** proofHeight, "Leaf index is too big");

    bytes32 proofElement;
    bytes32 computedHash = leaf;
    for (uint256 i = 32; i <= proof.length; i += 32) {
      assembly {
        proofElement := mload(add(proof, i))
      }

      if (index % 2 == 0) {
        computedHash = keccak256(
          abi.encodePacked(computedHash, proofElement)
        );
      } else {
        computedHash = keccak256(
          abi.encodePacked(proofElement, computedHash)
        );
      }

      index = index / 2;
    }
    return computedHash == rootHash;
  }
}


pragma solidity ^0.5.2;

/**
 * @title RootChainable
 */
contract RootChainable is Ownable {
  address public rootChain;

  // Rootchain changed
  event RootChainChanged(
    address indexed previousRootChain,
    address indexed newRootChain
  );

  //
  // Only root chain
  //

  // only root chain
  modifier onlyRootChain() {
    require(msg.sender == rootChain);
    _;
  }

  /**
 * @dev Allows the current owner to change root chain address.
 * @param newRootChain The address to new rootchain.
 */
  function changeRootChain(address newRootChain) public onlyOwner {
    require(newRootChain != address(0));
    emit RootChainChanged(rootChain, newRootChain);
    rootChain = newRootChain;
  }
}



pragma solidity ^0.5.2;

contract ERC20NonTransferable is ERC20 {
  function _transfer(
    address from,
    address to,
    uint256 value
  ) internal {
    revert("Disabled");
  }
}


pragma solidity ^0.5.2;

library ECVerify {
  function ecrecovery(bytes32 hash, bytes memory sig)
  public
  pure
  returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return address(0x0);
    }

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := and(mload(add(sig, 65)), 255)
    }

    // https://github.com/ethereum/go-ethereum/issues/2053
    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return address(0x0);
    }

    // get address out of hash and signature
    address result = ecrecover(hash, v, r, s);

    // ecrecover returns zero on error
    require(result != address(0x0));

    return result;
  }

  function ecrecovery(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
  public
  pure
  returns (address)
  {
    // get address out of hash and signature
    address result = ecrecover(hash, v, r, s);

    // ecrecover returns zero on error
    require(result != address(0x0), "signature verification failed");

    return result;
  }

  function ecverify(bytes32 hash, bytes memory sig, address signer)
  public
  pure
  returns (bool)
  {
    return signer == ecrecovery(hash, sig);
  }
}

pragma solidity ^0.5.2;

library BytesLib {
  function concat(bytes memory _preBytes, bytes memory _postBytes)
  internal
  pure
  returns (bytes memory)
  {
    bytes memory tempBytes;
    assembly {
    // Get a location of some free memory and store it in tempBytes as
    // Solidity does for memory variables.
      tempBytes := mload(0x40)

    // Store the length of the first bytes array at the beginning of
    // the memory for tempBytes.
      let length := mload(_preBytes)
      mstore(tempBytes, length)

    // Maintain a memory counter for the current write location in the
    // temp bytes array by adding the 32 bytes for the array length to
    // the starting location.
      let mc := add(tempBytes, 0x20)
    // Stop copying when the memory counter reaches the length of the
    // first bytes array.
      let end := add(mc, length)

      for {
      // Initialize a copy counter to the start of the _preBytes data,
      // 32 bytes into its memory.
        let cc := add(_preBytes, 0x20)
      } lt(mc, end) {
      // Increase both counters by 32 bytes each iteration.
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
      // Write the _preBytes data into the tempBytes memory 32 bytes
      // at a time.
        mstore(mc, mload(cc))
      }

    // Add the length of _postBytes to the current length of tempBytes
    // and store it as the new length in the first 32 bytes of the
    // tempBytes memory.
      length := mload(_postBytes)
      mstore(tempBytes, add(length, mload(tempBytes)))

    // Move the memory counter back from a multiple of 0x20 to the
    // actual end of the _preBytes data.
      mc := end
    // Stop copying when the memory counter reaches the new combined
    // length of the arrays.
      end := add(mc, length)

      for {
        let cc := add(_postBytes, 0x20)
      } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        mstore(mc, mload(cc))
      }

    // Update the free-memory pointer by padding our last write location
    // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
    // next 32 byte block, then round down to the nearest multiple of
    // 32. If the sum of the length of the two arrays is zero then add
    // one before rounding down to leave a blank 32 bytes (the length block with 0).
      mstore(
      0x40,
      and(
      add(add(end, iszero(add(length, mload(_preBytes)))), 31),
      not(31) // Round down to the nearest 32 bytes.
      )
      )
    }
    return tempBytes;
  }

  function slice(bytes memory _bytes, uint256 _start, uint256 _length)
  internal
  pure
  returns (bytes memory)
  {
    require(_bytes.length >= (_start + _length));
    bytes memory tempBytes;
    assembly {
      switch iszero(_length)
      case 0 {
      // Get a location of some free memory and store it in tempBytes as
      // Solidity does for memory variables.
        tempBytes := mload(0x40)

      // The first word of the slice result is potentially a partial
      // word read from the original array. To read it, we calculate
      // the length of that partial word and start copying that many
      // bytes into the array. The first word we copy will start with
      // data we don't care about, but the last `lengthmod` bytes will
      // land at the beginning of the contents of the new array. When
      // we're done copying, we overwrite the full first word with
      // the actual length of the slice.
        let lengthmod := and(_length, 31)

      // The multiplication in the next line is necessary
      // because when slicing multiples of 32 bytes (lengthmod == 0)
      // the following copy loop was copying the origin's length
      // and then ending prematurely not copying everything it should.
        let mc := add(
        add(tempBytes, lengthmod),
        mul(0x20, iszero(lengthmod))
        )
        let end := add(mc, _length)

        for {
        // The multiplication in the next line has the same exact purpose
        // as the one above.
          let cc := add(
          add(
          add(_bytes, lengthmod),
          mul(0x20, iszero(lengthmod))
          ),
          _start
          )
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

      //update free-memory pointer
      //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)
        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  // Pad a bytes array to 32 bytes
  function leftPad(bytes memory _bytes) internal pure returns (bytes memory) {
    // may underflow if bytes.length < 32. Hence using SafeMath.sub
    bytes memory newBytes = new bytes(SafeMath.sub(32, _bytes.length));
    return concat(newBytes, _bytes);
  }

  function toBytes32(bytes memory b) internal pure returns (bytes32) {
    require(b.length >= 32, "Bytes array should atleast be 32 bytes");
    bytes32 out;
    for (uint256 i = 0; i < 32; i++) {
      out |= bytes32(b[i] & 0xFF) >> (i * 8);
    }
    return out;
  }

  function toBytes4(bytes memory b) internal pure returns (bytes4 result) {
    assembly {
      result := mload(add(b, 32))
    }
  }

  function fromBytes32(bytes32 x) internal pure returns (bytes memory) {
    bytes memory b = new bytes(32);
    for (uint256 i = 0; i < 32; i++) {
      b[i] = bytes1(uint8(uint256(x) / (2**(8 * (31 - i)))));
    }
    return b;
  }

  function fromUint(uint256 _num) internal pure returns (bytes memory _ret) {
    _ret = new bytes(32);
    assembly {
      mstore(add(_ret, 32), _num)
    }
  }

  function toUint(bytes memory _bytes, uint256 _start)
  internal
  pure
  returns (uint256)
  {
    require(_bytes.length >= (_start + 32));
    uint256 tempUint;
    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }
    return tempUint;
  }

  function toAddress(bytes memory _bytes, uint256 _start)
  internal
  pure
  returns (address)
  {
    require(_bytes.length >= (_start + 20));
    address tempAddress;
    assembly {
      tempAddress := div(
      mload(add(add(_bytes, 0x20), _start)),
      0x1000000000000000000000000
      )
    }

    return tempAddress;
  }
}


pragma solidity ^0.5.2;

contract Lockable {
  bool public locked;

  modifier onlyWhenUnlocked() {
    _assertUnlocked();
    _;
  }

  function _assertUnlocked() private view {
    require(!locked, "locked");
  }

  function lock() public {
    locked = true;
  }

  function unlock() public {
    locked = false;
  }
}

pragma solidity ^0.5.2;

contract OwnableLockable is Lockable, Ownable {
  function lock() public onlyOwner {
    super.lock();
  }

  function unlock() public onlyOwner {
    super.unlock();
  }
}


pragma solidity ^0.5.2;

contract ProxyStorage is Ownable {
  address internal proxyTo;
}


/*
 * SPDX-License-Identitifer:    MIT
 */

pragma solidity ^0.5.2;

// See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-897.md

interface ERCProxy {
  function proxyType() external pure returns (uint256 proxyTypeId);
  function implementation() external view returns (address codeAddr);
}


pragma solidity ^0.5.2;

contract DelegateProxy is ERCProxy {
  function proxyType() external pure returns (uint256 proxyTypeId) {
    // Upgradeable proxy
    proxyTypeId = 2;
  }

  function implementation() external view returns (address);

  function delegatedFwd(address _dst, bytes memory _calldata) internal {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let result := delegatecall(
      sub(gas, 10000),
      _dst,
      add(_calldata, 0x20),
      mload(_calldata),
      0,
      0
      )
      let size := returndatasize

      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)

    // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
    // if the call returned error data, forward it
      switch result
      case 0 {
        revert(ptr, size)
      }
      default {
        return(ptr, size)
      }
    }
  }
}


pragma solidity ^0.5.2;

contract UpgradableProxy is DelegateProxy {
  event ProxyUpdated(address indexed _new, address indexed _old);
  event ProxyOwnerUpdate(address _new, address _old);

  bytes32 constant IMPLEMENTATION_SLOT = keccak256("matic.network.proxy.implementation");
  bytes32 constant OWNER_SLOT = keccak256("matic.network.proxy.owner");

  constructor(address _proxyTo) public {
    setProxyOwner(msg.sender);
    setImplementation(_proxyTo);
  }

  function() external payable {
    // require(currentContract != 0, "If app code has not been set yet, do not call");
    // Todo: filter out some calls or handle in the end fallback
    delegatedFwd(loadImplementation(), msg.data);
  }

  modifier onlyProxyOwner() {
    require(loadProxyOwner() == msg.sender, "NOT_OWNER");
    _;
  }

  function proxyOwner() external view returns(address) {
    return loadProxyOwner();
  }

  function loadProxyOwner() internal view returns(address) {
    address _owner;
    bytes32 position = OWNER_SLOT;
    assembly {
      _owner := sload(position)
    }
    return _owner;
  }

  function implementation() external view returns (address) {
    return loadImplementation();
  }

  function loadImplementation() internal view returns(address) {
    address _impl;
    bytes32 position = IMPLEMENTATION_SLOT;
    assembly {
      _impl := sload(position)
    }
    return _impl;
  }

  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0), "ZERO_ADDRESS");
    emit ProxyOwnerUpdate(newOwner, loadProxyOwner());
    setProxyOwner(newOwner);
  }

  function setProxyOwner(address newOwner) private {
    bytes32 position = OWNER_SLOT;
    assembly {
      sstore(position, newOwner)
    }
  }

  function updateImplementation(address _newProxyTo) public onlyProxyOwner {
    require(_newProxyTo != address(0x0), "INVALID_PROXY_ADDRESS");
    require(isContract(_newProxyTo), "DESTINATION_ADDRESS_IS_NOT_A_CONTRACT");

    emit ProxyUpdated(_newProxyTo, loadImplementation());

    setImplementation(_newProxyTo);
  }

  function updateAndCall(address _newProxyTo, bytes memory data) payable public onlyProxyOwner {
    updateImplementation(_newProxyTo);

    (bool success, bytes memory returnData) = address(this).call.value(msg.value)(data);
    require(success, string(returnData));
  }

  function setImplementation(address _newProxyTo) private {
    bytes32 position = IMPLEMENTATION_SLOT;
    assembly {
      sstore(position, _newProxyTo)
    }
  }

  function isContract(address _target) internal view returns (bool) {
    if (_target == address(0)) {
      return false;
    }

    uint256 size;
    assembly {
      size := extcodesize(_target)
    }
    return size > 0;
  }
}


pragma solidity ^0.5.2;

interface IGovernance {
  function update(address target, bytes calldata data) external;
}

pragma solidity ^0.5.2;

contract Governable {
  IGovernance public governance;

  constructor(address _governance) public {
    governance = IGovernance(_governance);
  }

  modifier onlyGovernance() {
    require(
      msg.sender == address(governance),
      "Only governance contract is authorized"
    );
    _;
  }
}

pragma solidity ^0.5.2;

contract GovernanceLockable is Lockable, Governable {
  constructor(address governance) public Governable(governance) {}

  function lock() public onlyGovernance {
    super.lock();
  }

  function unlock() public onlyGovernance {
    super.unlock();
  }
}

pragma solidity ^0.5.2;

contract Initializable {
  bool inited = false;

  modifier initializer() {
    require(!inited, "already inited");
    inited = true;

    _;
  }
}

pragma solidity ^0.5.2;

contract Registry is Governable {
  // @todo hardcode constants
  bytes32 private constant WETH_TOKEN = keccak256("wethToken");
  bytes32 private constant DEPOSIT_MANAGER = keccak256("depositManager");
  bytes32 private constant STAKE_MANAGER = keccak256("stakeManager");
  bytes32 private constant VALIDATOR_SHARE = keccak256("validatorShare");
  bytes32 private constant WITHDRAW_MANAGER = keccak256("withdrawManager");
  bytes32 private constant CHILD_CHAIN = keccak256("childChain");
  bytes32 private constant STATE_SENDER = keccak256("stateSender");
  bytes32 private constant SLASHING_MANAGER = keccak256("slashingManager");

  address public erc20Predicate;
  address public erc721Predicate;

  mapping(bytes32 => address) public contractMap;
  mapping(address => address) public rootToChildToken;
  mapping(address => address) public childToRootToken;
  mapping(address => bool) public proofValidatorContracts;
  mapping(address => bool) public isERC721;

  enum Type {Invalid, ERC20, ERC721, Custom}
  struct Predicate {
    Type _type;
  }
  mapping(address => Predicate) public predicates;

  event TokenMapped(address indexed rootToken, address indexed childToken);
  event ProofValidatorAdded(address indexed validator, address indexed from);
  event ProofValidatorRemoved(address indexed validator, address indexed from);
  event PredicateAdded(address indexed predicate, address indexed from);
  event PredicateRemoved(address indexed predicate, address indexed from);
  event ContractMapUpdated(bytes32 indexed key, address indexed previousContract, address indexed newContract);

  constructor(address _governance) public Governable(_governance) {}

  function updateContractMap(bytes32 _key, address _address) external onlyGovernance {
    emit ContractMapUpdated(_key, contractMap[_key], _address);
    contractMap[_key] = _address;
  }

  /**
   * @dev Map root token to child token
   * @param _rootToken Token address on the root chain
   * @param _childToken Token address on the child chain
   * @param _isERC721 Is the token being mapped ERC721
   */
  function mapToken(
    address _rootToken,
    address _childToken,
    bool _isERC721
  ) external onlyGovernance {
    require(_rootToken != address(0x0) && _childToken != address(0x0), "INVALID_TOKEN_ADDRESS");
    rootToChildToken[_rootToken] = _childToken;
    childToRootToken[_childToken] = _rootToken;
    isERC721[_rootToken] = _isERC721;
    IWithdrawManager(contractMap[WITHDRAW_MANAGER]).createExitQueue(_rootToken);
    emit TokenMapped(_rootToken, _childToken);
  }

  function addErc20Predicate(address predicate) public onlyGovernance {
    require(predicate != address(0x0), "Can not add null address as predicate");
    erc20Predicate = predicate;
    addPredicate(predicate, Type.ERC20);
  }

  function addErc721Predicate(address predicate) public onlyGovernance {
    erc721Predicate = predicate;
    addPredicate(predicate, Type.ERC721);
  }

  function addPredicate(address predicate, Type _type) public onlyGovernance {
    require(predicates[predicate]._type == Type.Invalid, "Predicate already added");
    predicates[predicate]._type = _type;
    emit PredicateAdded(predicate, msg.sender);
  }

  function removePredicate(address predicate) public onlyGovernance {
    require(predicates[predicate]._type != Type.Invalid, "Predicate does not exist");
    delete predicates[predicate];
    emit PredicateRemoved(predicate, msg.sender);
  }

  function getValidatorShareAddress() public view returns (address) {
    return contractMap[VALIDATOR_SHARE];
  }

  function getWethTokenAddress() public view returns (address) {
    return contractMap[WETH_TOKEN];
  }

  function getDepositManagerAddress() public view returns (address) {
    return contractMap[DEPOSIT_MANAGER];
  }

  function getStakeManagerAddress() public view returns (address) {
    return contractMap[STAKE_MANAGER];
  }

  function getSlashingManagerAddress() public view returns (address) {
    return contractMap[SLASHING_MANAGER];
  }

  function getWithdrawManagerAddress() public view returns (address) {
    return contractMap[WITHDRAW_MANAGER];
  }

  function getChildChainAndStateSender() public view returns (address, address) {
    return (contractMap[CHILD_CHAIN], contractMap[STATE_SENDER]);
  }

  function isTokenMapped(address _token) public view returns (bool) {
    return rootToChildToken[_token] != address(0x0);
  }

  function isTokenMappedAndIsErc721(address _token) public view returns (bool) {
    require(isTokenMapped(_token), "TOKEN_NOT_MAPPED");
    return isERC721[_token];
  }

  function isTokenMappedAndGetPredicate(address _token) public view returns (address) {
    if (isTokenMappedAndIsErc721(_token)) {
      return erc721Predicate;
    }
    return erc20Predicate;
  }

  function isChildTokenErc721(address childToken) public view returns (bool) {
    address rootToken = childToRootToken[childToken];
    require(rootToken != address(0x0), "Child token is not mapped");
    return isERC721[rootToken];
  }
}

pragma solidity ^0.5.2;

contract StakingNFT is ERC721Full, Ownable {
  constructor(string memory name, string memory symbol)
  public
  ERC721Full(name, symbol)
  {
    // solhint-disable-previous-line no-empty-blocks
  }

  function mint(address to, uint256 tokenId) public onlyOwner {
    require(
      balanceOf(to) == 0,
      "Validators MUST NOT own multiple stake position"
    );
    _mint(to, tokenId);
  }

  function burn(uint256 tokenId) public onlyOwner {
    _burn(tokenId);
  }

  function _transferFrom(address from, address to, uint256 tokenId) internal {
    require(
      balanceOf(to) == 0,
      "Validators MUST NOT own multiple stake position"
    );
    super._transferFrom(from, to, tokenId);
  }
}

pragma solidity ^0.5.2;

contract ISlashingManager {
  bytes32 public heimdallId;
  uint8 public constant VOTE_TYPE = 2;
  uint256 public reportRate = 5; // dummy default value
  uint256 public proposerRate = 50; // dummy default value
  uint256 public jailCheckpoints = 5; // checkpoints
  uint256 public slashingNonce;
  Registry public registry;
  StakingInfo public logger;
}

pragma solidity ^0.5.2;

// dummy interface to avoid cyclic dependency
contract IStakeManagerLocal {
  enum Status {Inactive, Active, Locked, Unstaked}

  struct Validator {
    uint256 amount;
    uint256 reward;
    uint256 activationEpoch;
    uint256 deactivationEpoch;
    uint256 jailTime;
    address signer;
    address contractAddress;
    Status status;
  }

  mapping(uint256 => Validator) public validators;
  bytes32 public accountStateRoot;
  uint256 public activeAmount; // delegation amount from validator contract
  uint256 public validatorRewards;

  function currentValidatorSetTotalStake() public view returns (uint256);

  // signer to Validator mapping
  function signerToValidator(address validatorAddress)
  public
  view
  returns (uint256);

  function isValidator(uint256 validatorId) public view returns (bool);
}

pragma solidity ^0.5.2;

contract StakingInfo is Ownable {
  using SafeMath for uint256;
  mapping(uint256 => uint256) public validatorNonce;

  /// @dev Emitted when validator stakes in '_stakeFor()' in StakeManager.
  /// @param signer validator address.
  /// @param validatorId unique integer to identify a validator.
  /// @param nonce to synchronize the events in heimdal.
  /// @param activationEpoch validator's first epoch as proposer.
  /// @param amount staking amount.
  /// @param total total staking amount.
  /// @param signerPubkey public key of the validator
  event Staked(
    address indexed signer,
    uint256 indexed validatorId,
    uint256 nonce,
    uint256 indexed activationEpoch,
    uint256 amount,
    uint256 total,
    bytes signerPubkey
  );

  /// @dev Emitted when validator unstakes in 'unstakeClaim()'
  /// @param user address of the validator.
  /// @param validatorId unique integer to identify a validator.
  /// @param amount staking amount.
  /// @param total total staking amount.
  event Unstaked(
    address indexed user,
    uint256 indexed validatorId,
    uint256 amount,
    uint256 total
  );

  /// @dev Emitted when validator unstakes in '_unstake()'.
  /// @param user address of the validator.
  /// @param validatorId unique integer to identify a validator.
  /// @param nonce to synchronize the events in heimdal.
  /// @param deactivationEpoch last epoch for validator.
  /// @param amount staking amount.
  event UnstakeInit(
    address indexed user,
    uint256 indexed validatorId,
    uint256 nonce,
    uint256 deactivationEpoch,
    uint256 indexed amount
  );

  /// @dev Emitted when the validator public key is updated in 'updateSigner()'.
  /// @param validatorId unique integer to identify a validator.
  /// @param nonce to synchronize the events in heimdal.
  /// @param oldSigner old address of the validator.
  /// @param newSigner new address of the validator.
  /// @param signerPubkey public key of the validator.
  event SignerChange(
    uint256 indexed validatorId,
    uint256 nonce,
    address indexed oldSigner,
    address indexed newSigner,
    bytes signerPubkey
  );
  event Restaked(uint256 indexed validatorId, uint256 amount, uint256 total);
  event Jailed(
    uint256 indexed validatorId,
    uint256 indexed exitEpoch,
    address indexed signer
  );
  event UnJailed(uint256 indexed validatorId, address indexed signer);
  event Slashed(uint256 indexed nonce, uint256 indexed amount);
  event ThresholdChange(uint256 newThreshold, uint256 oldThreshold);
  event DynastyValueChange(uint256 newDynasty, uint256 oldDynasty);
  event ProposerBonusChange(
    uint256 newProposerBonus,
    uint256 oldProposerBonus
  );

  event RewardUpdate(uint256 newReward, uint256 oldReward);

  /// @dev Emitted when validator confirms the auction bid and at the time of restaking in confirmAuctionBid() and restake().
  /// @param validatorId unique integer to identify a validator.
  /// @param nonce to synchronize the events in heimdal.
  /// @param newAmount the updated stake amount.
  event StakeUpdate(
    uint256 indexed validatorId,
    uint256 indexed nonce,
    uint256 indexed newAmount
  );
  event ClaimRewards(
    uint256 indexed validatorId,
    uint256 indexed amount,
    uint256 indexed totalAmount
  );
  event StartAuction(
    uint256 indexed validatorId,
    uint256 indexed amount,
    uint256 indexed auctionAmount
  );
  event ConfirmAuction(
    uint256 indexed newValidatorId,
    uint256 indexed oldValidatorId,
    uint256 indexed amount
  );
  event TopUpFee(address indexed user, uint256 indexed fee);
  event ClaimFee(address indexed user, uint256 indexed fee);
  // Delegator events
  event ShareMinted(
    uint256 indexed validatorId,
    address indexed user,
    uint256 indexed amount,
    uint256 tokens
  );
  event ShareBurned(
    uint256 indexed validatorId,
    address indexed user,
    uint256 indexed amount,
    uint256 tokens
  );
  event DelegatorClaimedRewards(
    uint256 indexed validatorId,
    address indexed user,
    uint256 indexed rewards
  );
  event DelegatorRestaked(
    uint256 indexed validatorId,
    address indexed user,
    uint256 indexed totalStaked
  );
  event DelegatorUnstaked(
    uint256 indexed validatorId,
    address indexed user,
    uint256 amount
  );
  event UpdateCommissionRate(
    uint256 indexed validatorId,
    uint256 indexed newCommissionRate,
    uint256 indexed oldCommissionRate
  );

  Registry public registry;

  modifier onlyValidatorContract(uint256 validatorId) {
    address _contract;
    (, , , , , , _contract, ) = IStakeManagerLocal(
      registry.getStakeManagerAddress()
    )
    .validators(validatorId);
    require(_contract == msg.sender,
      "Invalid sender, not validator");
    _;
  }

  modifier StakeManagerOrValidatorContract(uint256 validatorId) {
    address _contract;
    address _stakeManager = registry.getStakeManagerAddress();
    (, , , , , , _contract, ) = IStakeManagerLocal(_stakeManager).validators(
      validatorId
    );
    require(_contract == msg.sender || _stakeManager == msg.sender,
      "Invalid sender, not stake manager or validator contract");
    _;
  }

  modifier onlyStakeManager() {
    require(registry.getStakeManagerAddress() == msg.sender,
      "Invalid sender, not stake manager");
    _;
  }
  modifier onlySlashingManager() {
    require(registry.getSlashingManagerAddress() == msg.sender,
      "Invalid sender, not slashing manager");
    _;
  }

  constructor(address _registry) public {
    registry = Registry(_registry);
  }

  function updateNonce(
    uint256[] calldata validatorIds,
    uint256[] calldata nonces
  ) external onlyOwner {
    require(validatorIds.length == nonces.length, "args length mismatch");

    for (uint256 i = 0; i < validatorIds.length; ++i) {
      validatorNonce[validatorIds[i]] = nonces[i];
    }
  }

  function logStaked(
    address signer,
    bytes memory signerPubkey,
    uint256 validatorId,
    uint256 activationEpoch,
    uint256 amount,
    uint256 total
  ) public onlyStakeManager {
    validatorNonce[validatorId] = validatorNonce[validatorId].add(1);
    emit Staked(
      signer,
      validatorId,
      validatorNonce[validatorId],
      activationEpoch,
      amount,
      total,
      signerPubkey
    );
  }

  function logUnstaked(
    address user,
    uint256 validatorId,
    uint256 amount,
    uint256 total
  ) public onlyStakeManager {
    emit Unstaked(user, validatorId, amount, total);
  }

  function logUnstakeInit(
    address user,
    uint256 validatorId,
    uint256 deactivationEpoch,
    uint256 amount
  ) public onlyStakeManager {
    validatorNonce[validatorId] = validatorNonce[validatorId].add(1);
    emit UnstakeInit(
      user,
      validatorId,
      validatorNonce[validatorId],
      deactivationEpoch,
      amount
    );
  }

  function logSignerChange(
    uint256 validatorId,
    address oldSigner,
    address newSigner,
    bytes memory signerPubkey
  ) public onlyStakeManager {
    validatorNonce[validatorId] = validatorNonce[validatorId].add(1);
    emit SignerChange(
      validatorId,
      validatorNonce[validatorId],
      oldSigner,
      newSigner,
      signerPubkey
    );
  }

  function logRestaked(uint256 validatorId, uint256 amount, uint256 total)
  public
  onlyStakeManager
  {
    emit Restaked(validatorId, amount, total);
  }

  function logJailed(uint256 validatorId, uint256 exitEpoch, address signer)
  public
  onlyStakeManager
  {
    emit Jailed(validatorId, exitEpoch, signer);
  }

  function logUnjailed(uint256 validatorId, address signer)
  public
  onlyStakeManager
  {
    emit UnJailed(validatorId, signer);
  }

  function logSlashed(uint256 nonce, uint256 amount)
  public
  onlySlashingManager
  {
    emit Slashed(nonce, amount);
  }

  function logThresholdChange(uint256 newThreshold, uint256 oldThreshold)
  public
  onlyStakeManager
  {
    emit ThresholdChange(newThreshold, oldThreshold);
  }

  function logDynastyValueChange(uint256 newDynasty, uint256 oldDynasty)
  public
  onlyStakeManager
  {
    emit DynastyValueChange(newDynasty, oldDynasty);
  }

  function logProposerBonusChange(
    uint256 newProposerBonus,
    uint256 oldProposerBonus
  ) public onlyStakeManager {
    emit ProposerBonusChange(newProposerBonus, oldProposerBonus);
  }

  function logRewardUpdate(uint256 newReward, uint256 oldReward)
  public
  onlyStakeManager
  {
    emit RewardUpdate(newReward, oldReward);
  }

  function logStakeUpdate(uint256 validatorId)
  public
  StakeManagerOrValidatorContract(validatorId)
  {
    validatorNonce[validatorId] = validatorNonce[validatorId].add(1);
    emit StakeUpdate(
      validatorId,
      validatorNonce[validatorId],
      totalValidatorStake(validatorId)
    );
  }

  function logClaimRewards(
    uint256 validatorId,
    uint256 amount,
    uint256 totalAmount
  ) public onlyStakeManager {
    emit ClaimRewards(validatorId, amount, totalAmount);
  }

  function logStartAuction(
    uint256 validatorId,
    uint256 amount,
    uint256 auctionAmount
  ) public onlyStakeManager {
    emit StartAuction(validatorId, amount, auctionAmount);
  }

  function logConfirmAuction(
    uint256 newValidatorId,
    uint256 oldValidatorId,
    uint256 amount
  ) public onlyStakeManager {
    emit ConfirmAuction(newValidatorId, oldValidatorId, amount);
  }

  function logTopUpFee(address user, uint256 fee) public onlyStakeManager {
    emit TopUpFee(user, fee);
  }

  function logClaimFee(address user, uint256 fee) public onlyStakeManager {
    emit ClaimFee(user, fee);
  }

  function getStakerDetails(uint256 validatorId)
  public
  view
  returns (
    uint256 amount,
    uint256 reward,
    uint256 activationEpoch,
    uint256 deactivationEpoch,
    address signer,
    uint256 _status
  )
  {
    IStakeManagerLocal stakeManager = IStakeManagerLocal(
      registry.getStakeManagerAddress()
    );
    address _contract;
    IStakeManagerLocal.Status status;
    (
    amount,
    reward,
    activationEpoch,
    deactivationEpoch,
    ,
    signer,
    _contract,
    status
    ) = stakeManager.validators(validatorId);
    _status = uint256(status);
    if (_contract != address(0x0)) {
      reward += IStakeManagerLocal(_contract).validatorRewards();
    }
  }

  function totalValidatorStake(uint256 validatorId)
  public
  view
  returns (uint256 validatorStake)
  {
    address contractAddress;
    (validatorStake, , , , , , contractAddress, ) = IStakeManagerLocal(
      registry.getStakeManagerAddress()
    )
    .validators(validatorId);
    if (contractAddress != address(0x0)) {
      validatorStake += IStakeManagerLocal(contractAddress).activeAmount();
    }
  }

  function getAccountStateRoot()
  public
  view
  returns (bytes32 accountStateRoot)
  {
    accountStateRoot = IStakeManagerLocal(registry.getStakeManagerAddress())
    .accountStateRoot();
  }

  function getValidatorContractAddress(uint256 validatorId)
  public
  view
  returns (address ValidatorContract)
  {
    (, , , , , , ValidatorContract, ) = IStakeManagerLocal(
      registry.getStakeManagerAddress()
    )
    .validators(validatorId);
  }

  // validator Share contract logging func
  function logShareMinted(
    uint256 validatorId,
    address user,
    uint256 amount,
    uint256 tokens
  ) public onlyValidatorContract(validatorId) {
    emit ShareMinted(validatorId, user, amount, tokens);
  }

  function logShareBurned(
    uint256 validatorId,
    address user,
    uint256 amount,
    uint256 tokens
  ) public onlyValidatorContract(validatorId) {
    emit ShareBurned(validatorId, user, amount, tokens);
  }

  function logDelegatorClaimRewards(
    uint256 validatorId,
    address user,
    uint256 rewards
  ) public onlyValidatorContract(validatorId) {
    emit DelegatorClaimedRewards(validatorId, user, rewards);
  }

  function logDelegatorRestaked(
    uint256 validatorId,
    address user,
    uint256 totalStaked
  ) public onlyValidatorContract(validatorId) {
    emit DelegatorRestaked(validatorId, user, totalStaked);
  }

  function logDelegatorUnstaked(uint256 validatorId, address user, uint256 amount)
  public
  onlyValidatorContract(validatorId)
  {
    emit DelegatorUnstaked(validatorId, user, amount);
  }

  function logUpdateCommissionRate(
    uint256 validatorId,
    uint256 newCommissionRate,
    uint256 oldCommissionRate
  ) public onlyValidatorContract(validatorId) {
    emit UpdateCommissionRate(
      validatorId,
      newCommissionRate,
      oldCommissionRate
    );
  }
}

pragma solidity ^0.5.2;

contract IStakeManager {
  // validator replacement
  function startAuction(
    uint256 validatorId,
    uint256 amount,
    bool acceptDelegation,
    bytes calldata signerPubkey
  ) external;

  function confirmAuctionBid(uint256 validatorId, uint256 heimdallFee) external;

  function transferFunds(
    uint256 validatorId,
    uint256 amount,
    address delegator
  ) external returns (bool);

  function delegationDeposit(
    uint256 validatorId,
    uint256 amount,
    address delegator
  ) external returns (bool);

  function stake(
    uint256 amount,
    uint256 heimdallFee,
    bool acceptDelegation,
    bytes calldata signerPubkey
  ) external;

  function unstake(uint256 validatorId) external;

  function totalStakedFor(address addr) external view returns (uint256);

  function stakeFor(
    address user,
    uint256 amount,
    uint256 heimdallFee,
    bool acceptDelegation,
    bytes memory signerPubkey
  ) public;

  function checkSignatures(
    uint256 blockInterval,
    bytes32 voteHash,
    bytes32 stateRoot,
    address proposer,
    bytes memory sigs
  ) public returns (uint256);

  function updateValidatorState(uint256 validatorId, int256 amount) public;

  function ownerOf(uint256 tokenId) public view returns (address);

  function slash(bytes memory slashingInfoList) public returns (uint256);

  function validatorStake(uint256 validatorId) public view returns (uint256);

  function epoch() public view returns (uint256);

  function withdrawalDelay() public view returns (uint256);
}

pragma solidity ^0.5.2;

contract IWithdrawManager {
  function createExitQueue(address token) external;

  function verifyInclusion(
    bytes calldata data,
    uint8 offset,
    bool verifyTxInclusion
  ) external view returns (uint256 age);

  function addExitToQueue(
    address exitor,
    address childToken,
    address rootToken,
    uint256 exitAmountOrTokenId,
    bytes32 txHash,
    bool isRegularExit,
    uint256 priority
  ) external;

  function addInput(
    uint256 exitId,
    uint256 age,
    address utxoOwner,
    address token
  ) external;

  function challengeExit(
    uint256 exitId,
    uint256 inputId,
    bytes calldata challengeData,
    address adjudicatorPredicate
  ) external;
}

pragma solidity ^0.5.2;

contract StakeManagerStorage is GovernanceLockable, RootChainable {
    IERC20 public token;
    address public registry;
    StakingInfo public logger;
    StakingNFT public NFTContract;
    ValidatorShareFactory public factory;
    uint256 public WITHDRAWAL_DELAY; // unit: epoch
    uint256 public currentEpoch;

    // genesis/governance variables
    uint256 public dynasty ; // unit: epoch 50 days
    uint256 public CHECKPOINT_REWARD; // update via governance
    uint256 public minDeposit; // in ERC20 token
    uint256 public minHeimdallFee; // in ERC20 token
    uint256 public checkPointBlockInterval;
    uint256 public signerUpdateLimit;

    uint256 public validatorThreshold; //128
    uint256 public totalStaked;
    uint256 public NFTCounter;
    uint256 public totalRewards;
    uint256 public totalRewardsLiquidated;
    uint256 public auctionPeriod; // 1 week in epochs
    uint256 public proposerBonus; // 10 % of total rewards
    bytes32 public accountStateRoot;
    // Stop validator auction for some time when updating dynasty value
    uint256 public replacementCoolDown;
    bool public delegationEnabled;

    struct Auction {
        uint256 amount;
        uint256 startEpoch;
        address user;
        bool acceptDelegation;
        bytes signerPubkey;
    }

    struct State {
        uint256 amount;
        uint256 stakerCount;
    }

    struct StateChange {
        int256 amount;
        int256 stakerCount;
    }

    enum Status {Inactive, Active, Locked, Unstaked}
    struct Validator {
        uint256 amount;
        uint256 reward;
        uint256 activationEpoch;
        uint256 deactivationEpoch;
        uint256 jailTime;
        address signer;
        address contractAddress;
        Status status;
    }

    mapping(uint256 => Validator) public validators;
    // signer to Validator mapping
    mapping(address => uint256) public signerToValidator;
    State public validatorState;
    mapping(uint256 => StateChange) public validatorStateChanges;

    mapping(address => uint256) public userFeeExit;
    //Ongoing auctions for validatorId
    mapping(uint256 => Auction) public validatorAuction;
    // validatorId to last signer update epoch
    mapping(uint256 => uint256) public latestSignerUpdateEpoch;

    uint256 public totalHeimdallFee;
}

pragma solidity ^0.5.2;

// note this contract interface is only for stakeManager use
contract IValidatorShare {
  function withdrawRewardsValidator() external returns (uint256);

  function addProposerBonus(uint256 _rewards, uint256 valStake) public;

  function withdrawRewards() public;

  function unstakeClaimTokens() public;

  function getLiquidRewards(address user) public view returns (uint256);

  function getActiveAmount() external view returns (uint256);

  function owner() public view returns (address);

  function restake() public;

  function updateRewards(
    uint256 _reward,
    uint256 _totalStake,
    uint256 validatorStake
  ) external returns (uint256);

  function unlockContract() external returns (uint256);

  function lockContract() external returns (uint256);

  function drain(
    address token,
    address payable destination,
    uint256 amount
  ) external;

  function slash(uint256 valPow, uint256 totalAmountToSlash) external returns (uint256);

  function updateDelegation(bool delegation) external;
}

pragma solidity ^0.5.2;

contract ValidatorShare is IValidatorShare, ERC20NonTransferable, OwnableLockable, Initializable {
  struct Delegator {
    uint256 shares;
    uint256 withdrawEpoch;
  }

  uint256 constant EXCHANGE_RATE_PRECISION = 100;
  uint256 constant MAX_COMMISION_RATE = 100;
  uint256 constant REWARD_PRECISION = 10**25;

  StakingInfo public stakingLogger;
  IStakeManager public stakeManager;
  uint256 public validatorId;
  uint256 public validatorRewards;
  uint256 public commissionRate;
  //last checkpoint where validator updated commission rate
  uint256 public lastCommissionUpdate;
  uint256 public minAmount = 10**18;

  uint256 public totalStake;
  uint256 public rewardPerShare;
  uint256 public activeAmount;
  bool public delegation = true;

  uint256 public withdrawPool;
  uint256 public withdrawShares;

  mapping(address => uint256) public amountStaked;
  mapping(address => Delegator) public delegators;
  mapping(address => uint256) public initalRewardPerShare;

  modifier onlyValidator() {
    require(stakeManager.ownerOf(validatorId) == msg.sender, "not validator");
    _;
  }

  // onlyOwner will prevent this contract from initializing, since it's owner is going to be 0x0 address
  function initialize(uint256 _validatorId, address _stakingLogger, address _stakeManager) external initializer  {
    validatorId = _validatorId;
    stakingLogger = StakingInfo(_stakingLogger);
    stakeManager = IStakeManager(_stakeManager);
    _transferOwnership(_stakeManager);

    minAmount = 10**18;
    delegation = true;
  }

  function updateCommissionRate(uint256 newCommissionRate) external onlyValidator {
    uint256 epoch = stakeManager.epoch();
    uint256 _lastCommissionUpdate = lastCommissionUpdate;

    require( // withdrawalDelay == dynasty
      (_lastCommissionUpdate.add(stakeManager.withdrawalDelay()) <= epoch) || _lastCommissionUpdate == 0, // For initial setting of commission rate
      "Commission rate update cooldown period"
    );

    require(newCommissionRate <= MAX_COMMISION_RATE, "Commission rate should be in range of 0-100");
    stakingLogger.logUpdateCommissionRate(validatorId, newCommissionRate, commissionRate);
    commissionRate = newCommissionRate;
    lastCommissionUpdate = epoch;
  }

  function updateRewards(uint256 reward, uint256 checkpointStakePower, uint256 validatorStake)
  external
  onlyOwner
  returns (uint256)
  {
    /**
    restaking is simply buying more shares of pool
    but those needs to be nonswapable/transferrable(to prevent https://en.wikipedia.org/wiki/Tragedy_of_the_commons)

    - calculate rewards for validator stake + delgation
    - keep the validator rewards aside
    - take the commission out
    - add rewards to pool rewards
    - returns total active stake for validator
    */
    uint256 combinedStakePower = validatorStake.add(activeAmount); // validator + delegation stake power
    uint256 rewards = combinedStakePower.mul(reward).div(checkpointStakePower);

    _updateRewards(rewards, validatorStake, combinedStakePower);
    return combinedStakePower;
  }

  function addProposerBonus(uint256 rewards, uint256 validatorStake) public onlyOwner {
    uint256 combinedStakePower = validatorStake.add(activeAmount);
    _updateRewards(rewards, validatorStake, combinedStakePower);
  }

  function _updateRewards(uint256 rewards, uint256 validatorStake, uint256 combinedStakePower) internal {
    uint256 _validatorRewards = validatorStake.mul(rewards).div(combinedStakePower);

    // add validator commission from delegation rewards
    if (commissionRate > 0) {
      _validatorRewards = _validatorRewards.add(
        rewards.sub(_validatorRewards).mul(commissionRate).div(MAX_COMMISION_RATE)
      );
    }

    validatorRewards = validatorRewards.add(_validatorRewards);

    uint256 delegatorsRewards = rewards.sub(_validatorRewards);
    uint256 totalShares = totalSupply();
    if (totalShares > 0) {
      rewardPerShare = rewardPerShare.add(
        delegatorsRewards.mul(REWARD_PRECISION).div(totalShares)
      );
    }
  }

  function withdrawRewardsValidator() external onlyOwner returns (uint256) {
    uint256 _validatorRewards = validatorRewards;
    validatorRewards = 0;
    return _validatorRewards;
  }

  function exchangeRate() public view returns (uint256) {
    uint256 totalShares = totalSupply();
    return
    totalShares == 0
    ? EXCHANGE_RATE_PRECISION
    : activeAmount.mul(EXCHANGE_RATE_PRECISION).div(totalShares);
  }

  function withdrawExchangeRate() public view returns (uint256) {
    uint256 _withdrawShares = withdrawShares;
    return
    _withdrawShares == 0
    ? EXCHANGE_RATE_PRECISION
    : withdrawPool.mul(EXCHANGE_RATE_PRECISION).div(_withdrawShares);
  }

  function buyVoucher(uint256 _amount, uint256 _minSharesToMint) public {
    _withdrawAndTransferReward();
    uint256 amountToDeposit = _buyShares(_amount, _minSharesToMint);
    require(stakeManager.delegationDeposit(validatorId, amountToDeposit, msg.sender), "deposit failed");
  }

  function restake() public {
    uint256 liquidReward = _withdrawReward(msg.sender);
    require(liquidReward >= minAmount, "Too small rewards to restake");

    _buyShares(liquidReward, 0);

    stakingLogger.logDelegatorRestaked(validatorId, msg.sender, amountStaked[msg.sender]);
  }

  function _buyShares(uint256 _amount, uint256 _minSharesToMint) private onlyWhenUnlocked returns(uint256) {
    require(delegation, "Delegation is disabled");

    uint256 rate = exchangeRate();
    uint256 shares = _amount.mul(EXCHANGE_RATE_PRECISION).div(rate);
    require(shares >= _minSharesToMint, "Too much slippage");
    require(delegators[msg.sender].shares == 0, "Ongoing exit");

    _mint(msg.sender, shares);

    _amount = _amount.sub(_amount % rate.mul(shares).div(EXCHANGE_RATE_PRECISION));

    totalStake = totalStake.add(_amount);
    amountStaked[msg.sender] = amountStaked[msg.sender].add(_amount);

    activeAmount = activeAmount.add(_amount);
    stakeManager.updateValidatorState(validatorId, int256(_amount));

    StakingInfo logger = stakingLogger;
    logger.logShareMinted(validatorId, msg.sender, _amount, shares);
    logger.logStakeUpdate(validatorId);

    return _amount;
  }

  function sellVoucher(uint256 _minClaimAmount) public {
    uint256 shares = balanceOf(msg.sender);
    require(shares > 0, "Zero balance");

    uint256 rate = exchangeRate();
    uint256 _amount = rate.mul(shares).div(EXCHANGE_RATE_PRECISION);
    require(_amount >= _minClaimAmount, "Too much slippage");

    _withdrawAndTransferReward();

    _burn(msg.sender, shares);
    stakeManager.updateValidatorState(validatorId, -int256(_amount));

    activeAmount = activeAmount.sub(_amount);
    uint256 _withdrawPoolShare = _amount.mul(EXCHANGE_RATE_PRECISION).div(withdrawExchangeRate());

    withdrawPool = withdrawPool.add(_amount);
    withdrawShares = withdrawShares.add(_withdrawPoolShare);
    delegators[msg.sender] = Delegator({shares: _withdrawPoolShare, withdrawEpoch: stakeManager.epoch()});
    amountStaked[msg.sender] = 0;

    StakingInfo logger = stakingLogger;
    logger.logShareBurned(validatorId, msg.sender, _amount, shares);
    logger.logStakeUpdate(validatorId);
  }

  function _withdrawReward(address user) private returns(uint256) {
    uint256 liquidRewards = getLiquidRewards(user);
    initalRewardPerShare[user] = rewardPerShare;
    return liquidRewards;
  }

  function _withdrawAndTransferReward() private returns(uint256) {
    uint256 liquidRewards = _withdrawReward(msg.sender);

    if (liquidRewards > 0) {
      require(stakeManager.transferFunds(validatorId, liquidRewards, msg.sender), "Insufficent rewards");
      stakingLogger.logDelegatorClaimRewards(validatorId, msg.sender, liquidRewards);
    }

    return liquidRewards;
  }

  function withdrawRewards() public {
    uint256 rewards = _withdrawAndTransferReward();
    require(rewards >= minAmount, "Too small rewards amount");
  }

  function getLiquidRewards(address user) public view returns (uint256) {
    uint256 shares = balanceOf(user);
    if (shares == 0) {
      return 0;
    }

    return rewardPerShare.sub(initalRewardPerShare[user]).mul(shares).div(REWARD_PRECISION);
  }

  function unstakeClaimTokens() public {
    Delegator storage delegator = delegators[msg.sender];

    uint256 shares = delegator.shares;
    require(
      delegator.withdrawEpoch.add(stakeManager.withdrawalDelay()) <= stakeManager.epoch() && shares > 0,
      "Incomplete withdrawal period"
    );

    uint256 _amount = withdrawExchangeRate().mul(shares).div(EXCHANGE_RATE_PRECISION);
    withdrawShares = withdrawShares.sub(shares);
    withdrawPool = withdrawPool.sub(_amount);

    totalStake = totalStake.sub(_amount);

    require(stakeManager.transferFunds(validatorId, _amount, msg.sender), "Insufficent rewards");
    stakingLogger.logDelegatorUnstaked(validatorId, msg.sender, _amount);
    delete delegators[msg.sender];
  }

  function slash(uint256 valPow, uint256 totalAmountToSlash) external onlyOwner returns (uint256) {
    uint256 _withdrawPool = withdrawPool;
    uint256 delegationAmount = activeAmount.add(_withdrawPool);
    if (delegationAmount == 0) {
      return 0;
    }
    // total amount to be slashed from delegation pool (active + inactive)
    uint256 _amountToSlash = delegationAmount.mul(totalAmountToSlash).div(valPow.add(delegationAmount));
    uint256 _amountToSlashWithdrawalPool = _withdrawPool.mul(_amountToSlash).div(delegationAmount);

    // slash inactive pool
    withdrawPool = _withdrawPool.sub(_amountToSlashWithdrawalPool);
    activeAmount = activeAmount.sub(_amountToSlash.sub(_amountToSlashWithdrawalPool));
    return _amountToSlash;
  }

  function updateDelegation(bool _delegation) external onlyOwner {
    delegation = _delegation;
  }

  function drain(
    address token,
    address payable destination,
    uint256 amount
  ) external onlyOwner {
    if (token == address(0x0)) {
      destination.transfer(amount);
    } else {
      require(ERC20(token).transfer(destination, amount), "Drain failed");
    }
  }

  function getActiveAmount() external view returns(uint256) {
    return activeAmount;
  }

  function unlockContract() external onlyOwner returns (uint256) {
    unlock();
    return activeAmount;
  }

  function lockContract() external onlyOwner returns (uint256) {
    lock();
    return activeAmount;
  }
}

pragma solidity ^0.5.2;

contract ValidatorShareProxy is UpgradableProxy {
  constructor(address _registry) public UpgradableProxy(_registry) {}

  function loadImplementation() internal view returns (address) {
    return Registry(super.loadImplementation()).getValidatorShareAddress();
  }
}

pragma solidity ^0.5.2;

contract ValidatorShareFactory {
  /**
  - factory to create new validatorShare contracts
 */
  function create(uint256 validatorId, address loggerAddress, address registry) public returns (address) {
    ValidatorShareProxy proxy = new ValidatorShareProxy(registry);

    proxy.transferProxyOwnership(msg.sender);

    address proxyAddr = address(proxy);
    (bool success, bytes memory data) = proxyAddr.call.gas(gasleft())(
      abi.encodeWithSelector(
        ValidatorShare(proxyAddr).initialize.selector,
        validatorId,
        loggerAddress,
        msg.sender
      )
    );
    require(success, string(data));

    return proxyAddr;
  }
}

pragma solidity ^0.5.2;
contract StakeManager is IStakeManager, StakeManagerStorage, Initializable {
    using SafeMath for uint256;
    using ECVerify for bytes32;
    using Merkle for bytes32;
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint256 private constant INCORRECT_VALIDATOR_ID = 2**256 - 1;

    modifier onlyStaker(uint256 validatorId) {
        _assertOnlyStaker(validatorId);
        _;
    }

    function _assertOnlyStaker(uint256 validatorId) private view {
        require(NFTContract.ownerOf(validatorId) == msg.sender);
    }

    constructor() public GovernanceLockable(address(0x0)) {}

    function initialize(
        address _registry,
        address _rootchain,
        address _token,
        address _NFTContract,
        address _stakingLogger,
        address _validatorShareFactory,
        address _governance,
        address _owner
    ) external initializer {
        governance = IGovernance(_governance);
        registry = _registry;
        rootChain = _rootchain;
        token = IERC20(_token);
        NFTContract = StakingNFT(_NFTContract);
        logger = StakingInfo(_stakingLogger);
        factory = ValidatorShareFactory(_validatorShareFactory);
        _transferOwnership(_owner);

        WITHDRAWAL_DELAY = (2**13); // unit: epoch
        currentEpoch = 1;
        dynasty = 886; // unit: epoch 50 days
        CHECKPOINT_REWARD = 20188 * (10**18); // update via governance
        minDeposit = (10**18); // in ERC20 token
        minHeimdallFee = (10**18); // in ERC20 token
        checkPointBlockInterval = 1024;
        signerUpdateLimit = 100;

        validatorThreshold = 7; //128
        NFTCounter = 1;
        auctionPeriod = (2**13) / 4; // 1 week in epochs
        proposerBonus = 10; // 10 % of total rewards
        delegationEnabled = true;
    }

    function setDelegationEnabled(bool enabled) public onlyGovernance {
        delegationEnabled = enabled;
    }

    // TopUp heimdall fee
    function topUpForFee(address user, uint256 heimdallFee) public onlyWhenUnlocked {
        _transferAndTopUp(user, heimdallFee, 0);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return NFTContract.ownerOf(tokenId);
    }

    function epoch() public view returns (uint256) {
        return currentEpoch;
    }

    function withdrawalDelay() public view returns (uint256) {
        return WITHDRAWAL_DELAY;
    }

    function validatorStake(uint256 validatorId) public view returns (uint256) {
        return validators[validatorId].amount;
    }

    function _transferAndTopUp(
        address user,
        uint256 fee,
        uint256 additionalAmount
    ) private {
        require(fee >= minHeimdallFee, "Not enough heimdall fee");
        require(token.transferFrom(msg.sender, address(this), fee.add(additionalAmount)), "Fee transfer failed");
        totalHeimdallFee = totalHeimdallFee.add(fee);
        logger.logTopUpFee(user, fee);
    }

    function _claimFee(address user, uint256 amount) private {
        totalHeimdallFee = totalHeimdallFee.sub(amount);
        logger.logClaimFee(user, amount);
    }

    function claimFee(
        uint256 accumFeeAmount,
        uint256 index,
        bytes memory proof
    ) public {
        //Ignoring other params becuase rewards distribution is on chain
        require(
            keccak256(abi.encode(msg.sender, accumFeeAmount)).checkMembership(index, accountStateRoot, proof),
            "Wrong acc proof"
        );
        uint256 withdrawAmount = accumFeeAmount.sub(userFeeExit[msg.sender]);
        _claimFee(msg.sender, withdrawAmount);
        userFeeExit[msg.sender] = accumFeeAmount;
        require(token.transfer(msg.sender, withdrawAmount));
    }

    function stake(
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes calldata signerPubkey
    ) external {
        stakeFor(msg.sender, amount, heimdallFee, acceptDelegation, signerPubkey);
    }

    function totalStakedFor(address user) external view returns (uint256) {
        if (user == address(0x0) || NFTContract.balanceOf(user) == 0) {
            return 0;
        }
        return validators[NFTContract.tokenOfOwnerByIndex(user, 0)].amount;
    }

    function startAuction(
        uint256 validatorId,
        uint256 amount,
        bool _acceptDelegation,
        bytes calldata _signerPubkey
    ) external onlyWhenUnlocked {
        uint256 currentValidatorAmount = validators[validatorId].amount;

        require(
            validators[validatorId].deactivationEpoch == 0 && currentValidatorAmount != 0,
            "Invalid validator for an auction"
        );
        uint256 senderValidatorId = signerToValidator[msg.sender];
        // make sure that signer wasn't used already
        require(
            NFTContract.balanceOf(msg.sender) == 0 && // existing validators can't bid
                senderValidatorId != INCORRECT_VALIDATOR_ID,
            "Already used address"
        );

        uint256 _currentEpoch = currentEpoch;
        uint256 _replacementCoolDown = replacementCoolDown;
        // when dynasty period is updated validators are in cooldown period
        require(_replacementCoolDown == 0 || _replacementCoolDown <= _currentEpoch, "Cooldown period");
        // (auctionPeriod--dynasty)--(auctionPeriod--dynasty)--(auctionPeriod--dynasty)
        // if it's auctionPeriod then will get residue smaller then auctionPeriod
        // from (CurrentPeriod of validator )%(auctionPeriod--dynasty)
        // make sure that its `auctionPeriod` window
        // dynasty = 30, auctionPeriod = 7, activationEpoch = 1, currentEpoch = 39
        // residue 1 = (39-1)% (7+30), if residue <= auctionPeriod it's `auctionPeriod`

        require(
            (_currentEpoch.sub(validators[validatorId].activationEpoch) % dynasty.add(auctionPeriod)) < auctionPeriod,
            "Invalid auction period"
        );

        uint256 perceivedStake = currentValidatorAmount;
        address _contract = validators[validatorId].contractAddress;

        if (_contract != address(0x0)) {
            perceivedStake = perceivedStake.add(IValidatorShare(_contract).getActiveAmount());
        }

        Auction storage auction = validatorAuction[validatorId];
        uint256 currentAuctionAmount = auction.amount;

        perceivedStake = Math.max(perceivedStake, currentAuctionAmount);

        require(perceivedStake < amount, "Must bid higher");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer amount failed");

        //replace prev auction
        if (currentAuctionAmount != 0) {
            require(token.transfer(auction.user, currentAuctionAmount), "Bid return failed");
        }

        // create new auction
        auction.amount = amount;
        auction.user = msg.sender;
        auction.acceptDelegation = _acceptDelegation;
        auction.signerPubkey = _signerPubkey;

        logger.logStartAuction(validatorId, currentValidatorAmount, amount);
    }

    function confirmAuctionBid(
        uint256 validatorId,
        uint256 heimdallFee /** for new validator */
    ) external onlyWhenUnlocked {
        Auction storage auction = validatorAuction[validatorId];
        address auctionUser = auction.user;

        require(
            msg.sender == auctionUser || getValidatorId(msg.sender) == validatorId,
            "Only bidder or validator can confirm"
        );

        uint256 _currentEpoch = currentEpoch;
        require(
            _currentEpoch.sub(auction.startEpoch) % auctionPeriod.add(dynasty) >= auctionPeriod,
            "Not allowed before auctionPeriod"
        );
        require(auction.user != address(0x0), "Invalid auction");

        uint256 validatorAmount = validators[validatorId].amount;
        uint256 perceivedStake = validatorAmount;
        uint256 auctionAmount = auction.amount;
        address contractAddr = validators[validatorId].contractAddress;

        if (contractAddr != address(0x0)) {
            perceivedStake = perceivedStake.add(IValidatorShare(contractAddr).getActiveAmount());
        }

        // validator is last auctioner
        if (perceivedStake >= auctionAmount && validators[validatorId].deactivationEpoch == 0) {
            require(token.transfer(auctionUser, auctionAmount), "Bid return failed");
            //cleanup auction data
            auction.startEpoch = _currentEpoch;
            logger.logConfirmAuction(validatorId, validatorId, validatorAmount);
        } else {
            // dethrone
            _transferAndTopUp(auctionUser, heimdallFee, 0);
            _unstake(validatorId, _currentEpoch);

            uint256 newValidatorId = _stakeFor(
                auctionUser,
                auctionAmount,
                auction.acceptDelegation,
                auction.signerPubkey
            );
            logger.logConfirmAuction(newValidatorId, validatorId, auctionAmount);
        }
        uint256 startEpoch = auction.startEpoch;
        delete validatorAuction[validatorId];
        validatorAuction[validatorId].startEpoch = startEpoch;
    }

    function unstake(uint256 validatorId) external onlyStaker(validatorId) {
        require(validatorAuction[validatorId].amount == 0, "Wait for auction completion");
        require(
            validators[validatorId].activationEpoch > 0 &&
                validators[validatorId].deactivationEpoch == 0 &&
                (validators[validatorId].status == Status.Active || validators[validatorId].status == Status.Locked)
        );

        uint256 exitEpoch = currentEpoch.add(1); // notice period
        _unstake(validatorId, exitEpoch);
    }

    // Housekeeping function. @todo remove later
    function forceUnstake(uint256 validatorId) external onlyGovernance {
        _unstake(validatorId, currentEpoch);
    }

    function setCurrentEpoch(uint256 _currentEpoch) external onlyGovernance {
        currentEpoch = _currentEpoch;
    }

    function transferFunds(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool) {
        require(
            Registry(registry).getSlashingManagerAddress() == msg.sender ||
                validators[validatorId].contractAddress == msg.sender,
            "Invalid contract address"
        );
        return token.transfer(delegator, amount);
    }

    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool) {
        require(validators[validatorId].contractAddress == msg.sender, "Invalid contract address");
        return token.transferFrom(delegator, address(this), amount);
    }

    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) public onlyWhenUnlocked {
        require(currentValidatorSetSize() < validatorThreshold, "Validator set Threshold exceeded!");
        require(amount > minDeposit, "min deposit limit failed!");
        _transferAndTopUp(user, heimdallFee, amount);
        _stakeFor(user, amount, acceptDelegation, signerPubkey);
    }

    function unstakeClaim(uint256 validatorId) public onlyStaker(validatorId) {
        uint256 deactivationEpoch = validators[validatorId].deactivationEpoch;
        // can only claim stake back after WITHDRAWAL_DELAY
        require(
            deactivationEpoch > 0 &&
                deactivationEpoch.add(WITHDRAWAL_DELAY) <= currentEpoch &&
                validators[validatorId].status != Status.Unstaked
        );

        uint256 amount = validators[validatorId].amount;
        uint256 newTotalStaked = totalStaked.sub(amount);
        totalStaked = newTotalStaked;

        NFTContract.burn(validatorId);

        signerToValidator[validators[validatorId].signer] = INCORRECT_VALIDATOR_ID;
        validators[validatorId].status = Status.Unstaked;
        require(token.transfer(msg.sender, amount), "Transfer stake failed");
        logger.logUnstaked(msg.sender, validatorId, amount, newTotalStaked);
    }

    // slashing and jail interface
    function restake(
        uint256 validatorId,
        uint256 amount,
        bool stakeRewards
    ) public onlyWhenUnlocked onlyStaker(validatorId) {
        require(validators[validatorId].deactivationEpoch == 0, "No use of restaking");

        if (amount > 0) {
            require(token.transferFrom(msg.sender, address(this), amount), "Transfer stake failed");
        }

        if (stakeRewards) {
            amount = amount.add(validators[validatorId].reward);
            address contractAddr = validators[validatorId].contractAddress;
            if (contractAddr != address(0x0)) {
                amount = amount.add(IValidatorShare(contractAddr).withdrawRewardsValidator());
            }
            validators[validatorId].reward = 0;
        }

        uint256 newTotalStaked = totalStaked.add(amount);
        totalStaked = newTotalStaked;
        validators[validatorId].amount = validators[validatorId].amount.add(amount);

        updateTimeline(int256(amount), 0, 0);

        logger.logStakeUpdate(validatorId);
        logger.logRestaked(validatorId, validators[validatorId].amount, newTotalStaked);
    }

    function _liquidateRewards(uint256 validatorId, address validatorUser, uint256 reward) private {
        totalRewardsLiquidated = totalRewardsLiquidated.add(reward);
        validators[validatorId].reward = 0;
        require(token.transfer(validatorUser, reward), "Insufficent rewards");
        logger.logClaimRewards(validatorId, reward, totalRewardsLiquidated);
    }

    function withdrawRewards(uint256 validatorId) public onlyStaker(validatorId) {
        uint256 reward = validators[validatorId].reward;
        address contractAddr = validators[validatorId].contractAddress;
        if (contractAddr != address(0x0)) {
            reward = reward.add(IValidatorShare(contractAddr).withdrawRewardsValidator());
        }

        _liquidateRewards(validatorId, msg.sender, reward);
    }

    function getValidatorId(address user) public view returns (uint256) {
        return NFTContract.tokenOfOwnerByIndex(user, 0);
    }

    // set staking Token
    function setToken(address _token) public onlyGovernance {
        require(_token != address(0x0));
        token = IERC20(_token);
    }

    // Change the number of validators required to allow a passed header root
    function updateValidatorThreshold(uint256 newThreshold) public onlyGovernance {
        require(newThreshold > 0);
        logger.logThresholdChange(newThreshold, validatorThreshold);
        validatorThreshold = newThreshold;
    }

    function updateCheckPointBlockInterval(uint256 _blocks) public onlyGovernance {
        require(_blocks > 0, "Blocks interval must be non-zero");
        checkPointBlockInterval = _blocks;
    }

    // Change reward for each checkpoint
    function updateCheckpointReward(uint256 newReward) public onlyGovernance {
        require(newReward > 0);
        logger.logRewardUpdate(newReward, CHECKPOINT_REWARD);
        CHECKPOINT_REWARD = newReward;
    }

    // Change delegation contract for a validator
    // @note: Users must exit before this update or all funds may get lost
    function updateContractAddress(uint256 validatorId, address newContractAddress) public onlyGovernance {
        require(IValidatorShare(newContractAddress).owner() == address(this), "Owner of contract must be stakeManager");
        validators[validatorId].contractAddress = newContractAddress;
    }

    function updateValidatorState(uint256 validatorId, int256 amount) public {
        if (amount > 0) {
            // deposit during shares purchase
            require(delegationEnabled, "Delegation is disabled");
        }

        require(validators[validatorId].contractAddress == msg.sender, "Invalid contract address");
        updateTimeline(amount, 0, 0);
    }

    function updateDynastyValue(uint256 newDynasty) public onlyGovernance {
        require(newDynasty > 0);
        logger.logDynastyValueChange(newDynasty, dynasty);
        dynasty = newDynasty;
        WITHDRAWAL_DELAY = newDynasty;
        auctionPeriod = newDynasty.div(4);
        // set cooldown period
        replacementCoolDown = currentEpoch.add(auctionPeriod);
    }

    // Housekeeping function. @todo remove later
    function stopAuctions(uint256 forNCheckpoints) public onlyGovernance {
        replacementCoolDown = currentEpoch.add(forNCheckpoints);
    }

    function updateProposerBonus(uint256 newProposerBonus) public onlyGovernance {
        logger.logProposerBonusChange(newProposerBonus, proposerBonus);
        require(newProposerBonus <= 100, "too big");
        proposerBonus = newProposerBonus;
    }

    function updateSignerUpdateLimit(uint256 _limit) public onlyGovernance {
        signerUpdateLimit = _limit;
    }

    function updateMinAmounts(uint256 _minDeposit, uint256 _minHeimdallFee) public onlyGovernance {
        minDeposit = _minDeposit;
        minHeimdallFee = _minHeimdallFee;
    }

    function updateSigner(uint256 validatorId, bytes memory signerPubkey) public onlyStaker(validatorId) {
        address signer = pubToAddress(signerPubkey);
        require(signer != address(0x0) && signerToValidator[signer] == 0, "Invalid signer");

        uint256 _currentEpoch = currentEpoch;
        require(
            _currentEpoch >= latestSignerUpdateEpoch[validatorId].add(signerUpdateLimit),
            "Invalid checkpoint number!"
        );

        address currentSigner = validators[validatorId].signer;
        // update signer event
        logger.logSignerChange(validatorId, currentSigner, signer, signerPubkey);

        signerToValidator[currentSigner] = INCORRECT_VALIDATOR_ID;
        signerToValidator[signer] = validatorId;
        validators[validatorId].signer = signer;
        // reset update time to current time
        latestSignerUpdateEpoch[validatorId] = _currentEpoch;
    }

    function currentValidatorSetSize() public view returns (uint256) {
        return validatorState.stakerCount;
    }

    function currentValidatorSetTotalStake() public view returns (uint256) {
        return validatorState.amount;
    }

    function getValidatorContract(uint256 validatorId) public view returns (address) {
        return validators[validatorId].contractAddress;
    }

    function isValidator(uint256 validatorId) public view returns (bool) {
        uint256 activationEpoch = validators[validatorId].activationEpoch;
        uint256 deactivationEpoch = validators[validatorId].deactivationEpoch;
        uint256 amount = validators[validatorId].amount;
        Status status = validators[validatorId].status;
        uint256 _currentEpoch = currentEpoch;

        return (amount > 0 &&
            (activationEpoch != 0 && activationEpoch <= _currentEpoch) &&
            (deactivationEpoch == 0 || deactivationEpoch > _currentEpoch) &&
            status == Status.Active);
    }

    function checkSignatures(
        uint256 blockInterval,
        bytes32 voteHash,
        bytes32 stateRoot,
        address proposer,
        bytes memory sigs
    ) public onlyRootChain returns (uint256) {
        // checkpoint rewards are based on BlockInterval multiplied on `CHECKPOINT_REWARD`
        // for bigger checkpoints reward is capped at `CHECKPOINT_REWARD`
        // if interval is 50% of checkPointBlockInterval then reward R is half of `CHECKPOINT_REWARD`
        // and then stakePower is 90% of currentValidatorSetTotalStake then final reward is 90% of R
        uint256 reward = blockInterval.mul(CHECKPOINT_REWARD).div(checkPointBlockInterval);
        reward = Math.min(CHECKPOINT_REWARD, reward);

        uint256 _proposerBonus = reward.mul(proposerBonus).div(100);
        Validator storage _proposer = validators[signerToValidator[proposer]];
        if (_proposer.contractAddress != address(0x0)) {
            IValidatorShare(_proposer.contractAddress).addProposerBonus(_proposerBonus, _proposer.amount);
        } else {
            _proposer.reward = _proposer.reward.add(_proposerBonus);
        }

        reward = reward.sub(_proposerBonus);
        uint256 stakePower = currentValidatorSetTotalStake();
        // update stateMerkleTree root for accounts balance on heimdall chain
        accountStateRoot = stateRoot;
        _finalizeCommit();
        return checkSignature(stakePower, reward, voteHash, sigs);
    }

    function checkSignature(
        uint256 checkpointStakePower,
        uint256 reward,
        bytes32 voteHash,
        bytes memory sigs
    ) internal returns (uint256) {
        // total voting power
        uint256 totalStakePower;
        address lastAdd; // cannot have address(0x0) as an owner
        for (uint64 i = 0; i < sigs.length; i += 65) {
            address signer = voteHash.ecrecovery(BytesLib.slice(sigs, i, 65));
            uint256 validatorId = signerToValidator[signer];
            // check if signer is staker and not proposer
            if (signer == lastAdd) {
                break;
            } else if (isValidator(validatorId) && signer > lastAdd) {
                lastAdd = signer;

                Validator storage validator = validators[validatorId];
                uint256 valPow;
                // add delegation power
                address contractAddr = validator.contractAddress;
                if (contractAddr != address(0x0)) {
                    valPow = IValidatorShare(contractAddr).updateRewards(
                        reward,
                        checkpointStakePower,
                        validatorStake(validatorId)
                    );
                } else {
                    valPow = validator.amount;
                    validator.reward = validator.reward.add(valPow.mul(reward).div(checkpointStakePower));
                }
                totalStakePower = totalStakePower.add(valPow);
            }
        }

        reward = CHECKPOINT_REWARD.mul(totalStakePower).div(currentValidatorSetTotalStake());
        totalRewards = totalRewards.add(reward);
        require(totalStakePower >= currentValidatorSetTotalStake().mul(2).div(3).add(1), "2/3+1 non-majority!");

        return reward;
    }

    function slash(bytes memory _slashingInfoList) public returns (uint256) {
        require(Registry(registry).getSlashingManagerAddress() == msg.sender, "Sender must be slashing manager!");
        RLPReader.RLPItem[] memory slashingInfoList = _slashingInfoList.toRlpItem().toList();
        int256 valJailed = 0;
        uint256 jailedAmount = 0;
        uint256 totalAmount;
        for (uint256 i = 0; i < slashingInfoList.length; i++) {
            RLPReader.RLPItem[] memory slashData = slashingInfoList[i].toList();
            uint256 validatorId = slashData[0].toUint();
            uint256 _amount = slashData[1].toUint();
            totalAmount = totalAmount.add(_amount);

            if (validators[validatorId].contractAddress != address(0x0)) {
                uint256 delSlashedAmount = IValidatorShare(validators[validatorId].contractAddress).slash(
                    validators[validatorId].amount,
                    _amount
                );
                _amount = _amount.sub(delSlashedAmount);
            }

            validators[validatorId].amount = validators[validatorId].amount.sub(_amount);
            if (slashData[2].toBoolean()) {
                jailedAmount = jailedAmount.add(_jail(validatorId, 1));
                valJailed++;
            }
        }

        //update timeline
        updateTimeline(-int256(totalAmount.add(jailedAmount)), -valJailed, 0);

        return totalAmount;
    }

    function unjail(uint256 validatorId) public onlyStaker(validatorId) {
        require(validators[validatorId].status == Status.Locked, "Validator is not jailed");
        require(validators[validatorId].deactivationEpoch == 0, "Validator already unstaking");

        uint256 _currentEpoch = currentEpoch;
        require(validators[validatorId].jailTime <= _currentEpoch, "Incomplete jail period");

        uint256 amount = validators[validatorId].amount;
        require(amount >= minDeposit);

        uint256 delegationAmount = 0;
        if (validators[validatorId].contractAddress != address(0x0)) {
            delegationAmount = IValidatorShare(validators[validatorId].contractAddress).unlockContract();
        }

        // undo timline so that validator is normal validator
        updateTimeline(int256(amount.add(delegationAmount)), 1, 0);

        validators[validatorId].status = Status.Active;
        logger.logUnjailed(validatorId, validators[validatorId].signer);
    }

    function _jail(uint256 validatorId, uint256 jailCheckpoints) internal returns (uint256) {
        uint256 delegationAmount = 0;
        if (validators[validatorId].contractAddress != address(0x0)) {
            delegationAmount = IValidatorShare(validators[validatorId].contractAddress).lockContract();
        }

        uint256 _currentEpoch = currentEpoch;
        validators[validatorId].jailTime = _currentEpoch.add(jailCheckpoints);
        validators[validatorId].status = Status.Locked;
        logger.logJailed(validatorId, _currentEpoch, validators[validatorId].signer);
        return validators[validatorId].amount.add(delegationAmount);
    }

    function _stakeFor(
        address user,
        uint256 amount,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) internal returns (uint256) {
        address signer = pubToAddress(signerPubkey);
        require(signer != address(0x0) && signerToValidator[signer] == 0, "Invalid signer");

        uint256 _currentEpoch = currentEpoch;
        uint256 validatorId = NFTCounter;
        StakingInfo _logger = logger;
        uint256 newTotalStaked = totalStaked.add(amount);
        totalStaked = newTotalStaked;

        validators[validatorId] = Validator({
            reward: 0,
            amount: amount,
            activationEpoch: _currentEpoch,
            deactivationEpoch: 0,
            jailTime: 0,
            signer: signer,
            contractAddress: acceptDelegation ? factory.create(validatorId, address(_logger), registry) : address(0x0),
            status: Status.Active
        });

        latestSignerUpdateEpoch[validatorId] = _currentEpoch;
        NFTContract.mint(user, validatorId);

        signerToValidator[signer] = validatorId;
        updateTimeline(int256(amount), 1, 0);
        // no Auctions for 1 dynasty
        validatorAuction[validatorId].startEpoch = _currentEpoch;
        _logger.logStaked(signer, signerPubkey, validatorId, _currentEpoch, amount, newTotalStaked);
        NFTCounter = validatorId.add(1);

        return validatorId;
    }

    function _unstake(uint256 validatorId, uint256 exitEpoch) internal {
        uint256 amount = validators[validatorId].amount;
        address validator = ownerOf(validatorId);

        validators[validatorId].deactivationEpoch = exitEpoch;

        // unbond all delegators in future
        int256 delegationAmount = 0;
        uint256 rewards = validators[validatorId].reward;
        address contractAddr = validators[validatorId].contractAddress;
        if (contractAddr != address(0x0)) {
            IValidatorShare validatorShare = IValidatorShare(contractAddr);
            rewards = rewards.add(validatorShare.withdrawRewardsValidator());
            delegationAmount = int256(validatorShare.lockContract());
        }

        _liquidateRewards(validatorId, validator, rewards);

        //  update future
        updateTimeline(-(int256(amount) + delegationAmount), -1, exitEpoch);

        logger.logUnstakeInit(validator, validatorId, exitEpoch, amount);
    }

    function _finalizeCommit() internal {
        uint256 _currentEpoch = currentEpoch;
        uint256 nextEpoch = _currentEpoch.add(1);

        StateChange memory changes = validatorStateChanges[nextEpoch];
        updateTimeline(changes.amount, changes.stakerCount, 0);

        delete validatorStateChanges[_currentEpoch];

        currentEpoch = nextEpoch;
    }

    function updateTimeline(
        int256 amount,
        int256 stakerCount,
        uint256 targetEpoch
    ) private {
        if (targetEpoch == 0) {
            // update totalstake and validator count
            if (amount > 0) {
                validatorState.amount = validatorState.amount.add(uint256(amount));
            } else if (amount < 0) {
                validatorState.amount = validatorState.amount.sub(uint256(amount * -1));
            }

            if (stakerCount > 0) {
                validatorState.stakerCount = validatorState.stakerCount.add(uint256(stakerCount));
            } else if (stakerCount < 0) {
                validatorState.stakerCount = validatorState.stakerCount.sub(uint256(stakerCount * -1));
            }
        } else {
            validatorStateChanges[targetEpoch].amount += amount;
            validatorStateChanges[targetEpoch].stakerCount += stakerCount;
        }
    }

    function pubToAddress(bytes memory pub) private pure returns (address) {
        require(pub.length == 64, "Invalid pubkey");
        return address(uint160(uint256(keccak256(pub))));
    }

    function reinitialize(
        address _NFTContract,
        address _stakingLogger,
        address _validatorShareFactory
    ) external onlyGovernance {
        NFTContract = StakingNFT(_NFTContract);
        logger = StakingInfo(_stakingLogger);
        factory = ValidatorShareFactory(_validatorShareFactory);
    }

    function updateValidatorDelegation(bool delegation) external {
        uint256 validatorId = signerToValidator[msg.sender];
        require(isValidator(validatorId), "not a validator");

        address contractAddr = validators[validatorId].contractAddress;
        require(contractAddr != address(0x0), "delegation not enabled");

        IValidatorShare(contractAddr).updateDelegation(delegation);
    }
}