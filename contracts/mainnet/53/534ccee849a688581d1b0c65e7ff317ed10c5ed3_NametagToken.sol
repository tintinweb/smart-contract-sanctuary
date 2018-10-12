pragma solidity ^0.4.24;




/*

NAMETAG TOKEN

An ERC721 non-fungible token with the hash of your unique Alias imprinted upon it.

Register your handle by minting a new token with that handle.
Then, others can send Ethereum Assets directly to you handle (not your address) by sending it to the account which holds that token!

________

For example, one could register the handle @bob and then alice can use wallet services to send payments to @bob.
The wallet will be ask this contract which account the @bob token resides in and will send the payment there!

*/



// File: contracts/util/IERC165.sol

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

// File: contracts/ERC721/IERC721.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

// File: contracts/ERC721/IERC721Receiver.sol

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
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}

// File: contracts/util/SafeMath.sol

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

// File: contracts/util/Address.sol

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
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

// File: contracts/util/ERC165.sol

/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) internal _supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(_InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

// File: contracts/ERC721/ERC721.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) private _tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) private _ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_InterfaceId_ERC721);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
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
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
    // solium-disable-next-line arg-overflow
    require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
  }

  /**
   * @dev Returns whether the specified token exists
   * @param tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
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
   *  is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param owner owner of the token
   * @param tokenId uint256 ID of the token to be transferred
   */
  function _clearApproval(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallSafeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }
}

// File: contracts/ERC721/IERC721Metadata.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) public view returns (string);
}

// File: contracts/NametagToken.sol




contract NametagToken  is ERC165, ERC721, IERC721Metadata {
  // Token name
  string internal _name;

  // Token symbol
  string internal _symbol;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;



    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    /**
     * 0x5b5e139f ===
     *   bytes4(keccak256(&#39;name()&#39;)) ^
     *   bytes4(keccak256(&#39;symbol()&#39;)) ^
     *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
     */

    /**
     * @dev Constructor function
     */
    constructor(string name, string symbol) public {
      _name = name;
      _symbol = symbol;

      // register the supported interfaces to conform to ERC721 via ERC165
      _registerInterface(InterfaceId_ERC721Metadata);
    }





  function claimNametagToken(
    address to,
    bytes32 name
  )
    public
    returns (bool)
  {

    uint256 tokenId = (uint256) (keccak256(name));
    string memory metadata = bytes32ToString(name);

    _mint(to, tokenId);
    _setTokenURI(tokenId, metadata);
    return true;
  }


  function bytes32ToTokenId(bytes32 x) public constant returns (uint256) {
    return  (uint256) (keccak256(x));
  }

  function bytes32ToString(bytes32 x) public constant returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[charCount] = char;
            charCount++;
        }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
    }
      return string(bytesStringTrimmed);
  }



  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return _name;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return _symbol;
  }




  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 tokenId) public view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }


  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param tokenId uint256 ID of the token to set its URI
   * @param uri string URI to assign
   */
  function _setTokenURI(uint256 tokenId, string uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
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