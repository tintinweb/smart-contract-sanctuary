//SourceUnit: KraftNft.sol

pragma solidity ^0.5.5;
import "./minterRole.sol";
import "./abstract.sol";
import "./library.sol";
import "./safeMath.sol";



/**
 * @dev Implementation of the {ITRC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract TRC165 is ITRC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_TRC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for TRC165 itself here
        _registerInterface(_INTERFACE_ID_TRC165);
    }

    /**
     * @dev See {ITRC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual TRC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {ITRC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the TRC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "TRC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
contract IKtyNft is  Context,TRC165,IKraftNft,BlockRole{

  using Strings for uint256;


  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMap for EnumerableMap.UintToAddressMap;



  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _TRC721_RECEIVED = 0x5175f878;

  // Mapping from holder address to their (enumerable) set of owned tokens
  mapping (address => EnumerableSet.UintSet) private _holderTokens;

  // Enumerable mapping from token ids to their owners
  EnumerableMap.UintToAddressMap private _tokenOwners;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;


  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Base URI
  string private _baseURI;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;



  /*
   *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
   *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
   *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
   *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
   *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
   *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
   *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
   *
   *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
   *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
   */
  bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;

  /*
   *     bytes4(keccak256('name()')) == 0x06fdde03
   *     bytes4(keccak256('symbol()')) == 0x95d89b41
   *
   *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
   */
  bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f;

  /*
   *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
   *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
   *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
   *
   *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
   */
  bytes4 private constant _INTERFACE_ID_TRC721_ENUMERABLE = 0x780e9d63;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor (string memory name, string memory symbol) public {
      _name = name;
      _symbol = symbol;

      // register the supported interfaces to conform to TRC721 via TRC165
      _registerInterface(_INTERFACE_ID_TRC721);
      _registerInterface(_INTERFACE_ID_TRC721_METADATA);
      _registerInterface(_INTERFACE_ID_TRC721_ENUMERABLE);
  }

  /**
   * @dev Gets the token name.
   * @return string representing the token name
   */
  function name() external view returns (string memory) {
      return _name;
  }

  /**
   * @dev Gets the token symbol.
   * @return string representing the token symbol
   */
  function symbol() external view returns (string memory) {
      return _symbol;
  }

  /**
   * @dev Returns the URI for a given token ID. May return an empty string.
   *
   * If the token's URI is non-empty and a base URI was set (via
   * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
   *
   * Reverts if the token ID does not exist.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
      require(_exists(tokenId), "IKtyNft: URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];

      // Even if there is a base URI, it is only appended to non-empty token-specific URIs
      if (bytes(_tokenURI).length == 0) {
          _tokenURI = tokenId.toString();
      }
      // abi.encodePacked is being used to concatenate strings
      return string(abi.encodePacked(_baseURI, _tokenURI));
  }

  /**
   * @dev Internal function to set the token URI for a given token.
   *
   * Reverts if the token ID does not exist.
   *
   * TIP: if all token IDs share a prefix (e.g. if your URIs look like
   * `http://api.myproject.com/token/<id>`), use {_setBaseURI} to store
   * it and save gas.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
      require(_exists(tokenId), "TRC721Metadata: URI set of nonexistent token");
      _tokenURIs[tokenId] = _tokenURI;
  }

  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI}.
   *
   * _Available since v2.5.0._
   */
  function _setBaseURI(string memory baseURI) internal {
      _baseURI = baseURI;
  }

  /**
  * @dev Returns the base URI set via {_setBaseURI}. This will be
  * automatically added as a preffix in {tokenURI} to each token's URI, when
  * they are non-empty.
  *
  * _Available since v2.5.0._
  */
  function baseURI() external view returns (string memory) {
      return _baseURI;
  }
  /**
   * @dev Gets the balance of the specified address.
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view returns (uint256) {
      require(owner != address(0), "IKtyNft: balance query for the zero address");

      return _holderTokens[owner].length();
  }

  /**
   * @dev Gets the owner of the specified token ID.
   * @param tokenId uint256 ID of the token to query the owner of
   * @return address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    return _tokenOwners.get(tokenId, "IKtyNft: owner query for nonexistent token");

  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner.
   * @param owner address owning the tokens list to be accessed
   * @param index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < _holderTokens[owner].length(), "IKtyNft: owner index out of bounds");
      return _holderTokens[owner].at(index);
  }
  /**
   * @dev Gets all the tokens ID list of the requested owner.
   * @param owner address owning the tokens list to be accessed
   * @return uint256 array list owned by the requested address
   */
  function tokensOfOwner(address owner) public view returns (uint256 [] memory) {
      return _holderTokens[owner].all();
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract.
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
      // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
      return _tokenOwners.length();
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens.
   * @param index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "IKtyNft: global index out of bounds");
      (uint256 tokenId, ) = _tokenOwners.at(index);
      return tokenId;
  }


  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(_msgSender())

  {
      address owner = ownerOf(tokenId);
      require(to != owner, "IKtyNft: approval to current owner");

      require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
          "IKtyNft: approve caller is not owner nor approved for all"
      );

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

      require(_exists(tokenId), "IKtyNft: approved query for nonexistent token");

      return _tokenApprovals[tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf.
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address to, bool approved)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(_msgSender())
  {
      require(to != _msgSender(), "IKtyNft: approve to caller");

      _operatorApprovals[_msgSender()][to] = approved;
      emit ApprovalForAll(_msgSender(), to, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner.
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address owner, address operator) public view returns (bool) {
      return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address.
   * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   * Requires the msg.sender to be the owner, approved, or operator.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function transferFrom(address from, address to, uint256 tokenId)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(from)
  {
      //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "IKtyNft: transfer caller is not owner nor approved");

      _transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement {ITRC721Receiver-onTRC721Received},
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function safeTransferFrom(address from, address to, uint256 tokenId)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(from)
  {
      safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement {ITRC721Receiver-onTRC721Received},
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the _msgSender() to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(from)
   {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "IKtyNft: transfer caller is not owner nor approved");
      _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
      _transfer(from, to, tokenId);
      require(_checkOnTRC721Received(from, to, tokenId, _data), "IKtyNft: transfer to non TRC721Receiver implementer");
  }

  /**
   * @dev Returns whether the specified token exists.
   * @param tokenId uint256 ID of the token to query the existence of
   * @return bool whether the token exists
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
      return _tokenOwners.contains(tokenId);
  }


  /**
   * @dev Returns whether the given spender can transfer a given token ID.
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   * is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
      require(_exists(tokenId), "IKtyNft: operator query for nonexistent token");
      address owner = ownerOf(tokenId);
      return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Internal function to safely mint a new token.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _safeMint(address to, uint256 tokenId) internal {
      _safeMint(to, tokenId, "");
  }

  /**
   * @dev Internal function to safely mint a new token.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   * @param _data bytes data to send along with a safe transfer check
   */
  function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
      _mint(to, tokenId);
      require(_checkOnTRC721Received(address(0), to, tokenId, _data), "IKtyNft: minting to non TRC721Receiver implementer");
  }

  /**
   * @dev Internal function to mint a new token.
   * Reverts if the given token ID already exists.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _mint(address to, uint256 tokenId) internal {
      require(to != address(0), "IKtyNft: mint to the zero address");
      require(!_exists(tokenId), "IKtyNft: token already minted");

      _holderTokens[to].add(tokenId);

      _tokenOwners.set(tokenId, to);

      emit Transfer(address(0), to, tokenId);
  }
  /**
   * @dev Function to burn a specific token.
   * @param tokenId The token id to burned.
   * Reverts if the token does not exist.
   * return true if burned
   */
  function burn(uint256 tokenId)
  public
  isNotPaused
  isNotBlackListed(_msgSender())
  returns (bool) {
      require(_exists(tokenId), "IKtyNft: operator query for nonexistent token");
      _burn(tokenId,_msgSender());
      return true;
  }

  /**
   * @dev Internal function to burn a specific token.
   * Reverts if the token does not exist.
   * Deprecated, use {_burn} instead.
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(uint256 tokenId,address owner) internal {
      require(ownerOf(tokenId) == owner, "IKtyNft: burn of token that is not own");

      _clearApproval(tokenId);


      _holderTokens[owner].remove(tokenId);

      _tokenOwners.remove(tokenId);

      emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(address from, address to, uint256 tokenId) internal {
      require(ownerOf(tokenId) == from, "IKtyNft: transfer of token that is not own");
      require(to != address(0), "IKtyNft: transfer to the zero address");

      // Clear approvals from the previous owner
      _clearApproval(tokenId);


      _holderTokens[from].remove(tokenId);
      _holderTokens[to].add(tokenId);

      _tokenOwners.set(tokenId, to);

      emit Transfer(from, to, tokenId);
  }


  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnTRC721Received(address from, address to, uint256 tokenId, bytes memory _data)
      internal returns (bool)
  {
      if (!to.isContract) {
          return true;
      }
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
          ITRC721Receiver(to).onTRC721Received.selector,
          _msgSender(),
          from,
          tokenId,
          _data
      ));
      if (!success) {
          if (returndata.length > 0) {
              // solhint-disable-next-line no-inline-assembly
              assembly {
                  let returndata_size := mload(returndata)
                  revert(add(32, returndata), returndata_size)
              }
          } else {
              revert("TRC721: transfer to non TRC721Receiver implementer");
          }
      } else {
          bytes4 retval = abi.decode(returndata, (bytes4));
          return (retval == _TRC721_RECEIVED);
      }
  }

  function _clearApproval(uint256 tokenId) private {
      if (_tokenApprovals[tokenId] != address(0)) {
          _tokenApprovals[tokenId] = address(0);
          emit Approval(ownerOf(tokenId), address(0), tokenId);

      }
  }

}




contract KraftNft is Context, MinterControl,IKtyNft{
  using SafeMath for uint256;
  // total number of nft minted in series
  uint256 private serialCount;


  constructor() public IKtyNft("KRAFT NFT", "KNFT") {
    serialCount = 1;
  }
  /**
   * @dev  Function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI}.
   * return true, if baseURI set successfully
   *
   * _Available since v2.5.0._
   */
  function setBaseURI(string memory baseURI) public onlyMinter returns(bool){
      _setBaseURI(baseURI);
      return true;
  }

  /*
  *@dev function returns successfully minted nft by serial number
  */
  function getSerialMintedCount() public view returns (uint256){
    return serialCount;
  }
  /*
  * @dev function to update serial count of nft in case minted by other function mistakely
  */
  function updateSerialCount(uint256 value) public onlyMinter{
    require(value > 0,"MintNft: null Value provided");
     serialCount = value;
  }
  /**
   * @dev Internal function to safely mint a new token of serialised tokenId.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   */
  function serialMint(address to) public
  onlyMinter
  isNotPaused
  returns (uint256) {
      _safeMint(to, serialCount);
      serialCount += 1;
      return serialCount -1;
  }
  /**
   * @dev Internal function to safely mint a new token of serialised tokenId.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenURI The token URI of the minted token.

   */
  function serialMint(address to, string memory tokenURI) public
  onlyMinter
  isNotPaused
  returns (uint256) {
      _safeMint(to, serialCount);
      _setTokenURI(serialCount, tokenURI);
      serialCount += 1;
      return serialCount-1;
  }
  /**
   * @dev Function to mint tokens.
   * @param to The address that will receive the minted tokens.
   * @param tokenId The token id to mint.
   * @param tokenURI The token URI of the minted token.
   * @return A boolean that indicates if the operation was successful.
   */
  function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public
  onlyMinter
  isNotPaused
  returns (bool) {
      _mint(to, tokenId);
      _setTokenURI(tokenId, tokenURI);
      return true;
  }
  /**
   * @dev Function to mint tokens.
   * @param to The address that will receive the minted token.
   * @param tokenId The token id to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address to, uint256 tokenId) public
  onlyMinter
  isNotPaused
  returns (bool) {
      _mint(to, tokenId);
      return true;
  }
  /**
   * @dev Function to safely mint tokens.
   * @param to The address that will receive the minted token.
   * @param tokenId The token id to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function safeMint(address to, uint256 tokenId) public
  onlyMinter
  isNotPaused
  returns (bool) {
      _safeMint(to, tokenId);
      return true;
  }

  /**
   * @dev Function to safely mint tokens.
   * @param to The address that will receive the minted token.
   * @param tokenId The token id to mint.
   * @param _data bytes data to send along with a safe transfer check.
   * @return A boolean that indicates if the operation was successful.
   */
  function safeMint(address to, uint256 tokenId, bytes memory _data) public
  onlyMinter
  isNotPaused
  returns (bool) {
      _safeMint(to, tokenId, _data);
      return true;
  }



}


//SourceUnit: abstract.sol

pragma solidity ^0.5.5;
/**
 * @dev Interface of the TRC165 standard.
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({TRC165Checker}).
 *
 * For an implementation, see {TRC165}.
 */
interface ITRC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




/**
 * @dev Required interface of an TRC721 compliant contract.
 */
contract ITRC721 is ITRC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


/**
 * @title TRC-721 Non-Fungible Token Standard, optional metadata extension
 */
contract ITRC721Metadata is ITRC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
/**
 * @title TRC-721 Non-Fungible Token Standard, optional enumeration extension
 */
contract ITRC721Enumerable is ITRC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

//interface of TRC721 contract name
contract IKraftNft is ITRC721Metadata,ITRC721Enumerable{

}

/**
 * @title TRC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from TRC721 asset contracts.
 */
contract ITRC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The TRC721 smart contract calls this function on the recipient
     * after a {ITRC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onTRC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the TRC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`
     */
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}


//SourceUnit: context.sol

pragma solidity ^0.5.5;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: library.sol

pragma solidity ^0.5.5;


library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 tokenIds and owners.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _tokenId;
        bytes32 _owner;
    }

    struct UintToAddressMap {
        // Storage of map tokenIds and owners
        MapEntry[] _entries;

        // Position of the entry defined by a tokenId in the `entries` array, plus 1
        // because index 0 means a tokenId is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a tokenId-owner pair to a map, or updates the owner for an existing
     * tokenId. O(1).
     *
     */

    function set(UintToAddressMap storage map, uint256 tokenId, address owner) internal {

        bytes32 _TokenIdInBytes = bytes32(tokenId);
        bytes32 _ownerInBytes = bytes32(uint256(owner));

        // We read and store the tokenId's index to prevent multiple reads from the same storage slot
        uint256 tokenIdIndex = map._indexes[_TokenIdInBytes];

        if (tokenIdIndex == 0) { // Equivalent to !contains(map, tokenId)
            map._entries.push(MapEntry({ _tokenId: _TokenIdInBytes, _owner: _ownerInBytes }));
            // The entry is stored at length-1, but we add 1 to all indexes
            map._indexes[_TokenIdInBytes] = map._entries.length;
        } else {
            map._entries[tokenIdIndex - 1]._owner = _ownerInBytes;
        }
    }
    /**
     * @dev Removes a owner from a set. O(1).
     *
     * Returns true if the tokenId was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 tokenId) internal {
      bytes32 _TokenIdInBytes = bytes32(tokenId);

        // We read and store the tokenId's index to prevent multiple reads from the same storage slot
        uint256 tokenIdIndex = map._indexes[_TokenIdInBytes];
        require(tokenIdIndex != 0,"EnumerableMap: remove tokenId is nonexistent");

            // To delete a tokenId-owner pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = tokenIdIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._tokenId] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[_TokenIdInBytes];

    }

    /**
     * @dev Returns true if the tokenId is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 tokenId) internal view returns (bool) {
        return map._indexes[bytes32(tokenId)] != 0;
    }

    /**
     * @dev Returns the number of tokenId-owner pairs in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the tokenId-owner pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */

     function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
         require(map._entries.length > index, "EnumerableMap: index out of bounds");

         MapEntry storage entry = map._entries[index];
         return (uint256(entry._tokenId), address(uint256(entry._owner)));
     }

    /**
     * @dev Returns the owner associated with `tokenId`.  O(1).
     *
     * Requirements:
     *
     * - `tokenId` must be in the map.
     */


    function get(UintToAddressMap storage map, uint256 tokenId) internal view returns (address) {
        return _get(map, tokenId, "EnumerableMap: nonexistent tokenId");
    }
    /**
     * @dev Same as {get}, with a custom error message when `tokenId` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 tokenId, string memory errorMessage) internal view returns (address) {
        return _get(map, tokenId, errorMessage);
        return address(uint256(_get(map, tokenId, errorMessage)));
    }

    /**
     * @dev Same as {_get}, with a custom error message when `tokenId` is not in the map.
     */
    function _get(UintToAddressMap storage map, uint256 tokenId, string memory errorMessage) private view returns (address) {
        uint256 tokenIdIndex = map._indexes[bytes32(tokenId)];
        require(tokenIdIndex != 0, errorMessage); // Equivalent to contains(map, tokenId)
        return address(uint256(map._entries[tokenIdIndex - 1]._owner));
    }




}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // uint256 tokenIds.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct UintSet {
        // Storage of set tokenIds
        uint256[] _ownedTokens;

        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) _ownedTokensIndex;
    }

    /**
     * @dev Add a tokenId to a set. O(1).
     *
     * Returns true if the tokenId was added to the set, that is if it was not
     * already present.
     */

    function add(UintSet storage set, uint256 tokenId) internal{
      require(!_contains(set, tokenId),"EnumerableSet: tokenId already contain");
      set._ownedTokens.push(tokenId);
      // The tokenId is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel tokenId
      set._ownedTokensIndex[tokenId] = set._ownedTokens.length;
    }


    /**
     * @dev Removes a tokenId from a set. O(1).
     *
     * Returns true if the tokenId was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 tokenId) internal{
      require(_contains(set, tokenId),"EnumerableSet: tokenId not belongs to owner");
      // We read and store the tokenId's index to prevent multiple reads from the same storage slot
      uint256 tokenIdIndex = set._ownedTokensIndex[tokenId];
      // To delete an element from the _ownedTokens array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = tokenIdIndex - 1;
      uint256 lastIndex = set._ownedTokens.length - 1;

      // When the tokenId to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      uint256 lasttokenId = set._ownedTokens[lastIndex];

      // Move the last tokenId to the index where the tokenId to delete is
      set._ownedTokens[toDeleteIndex] = lasttokenId;
      // Update the index for the moved tokenId
      set._ownedTokensIndex[lasttokenId] = toDeleteIndex + 1; // All indexes are 1-based

      // Delete the slot where the moved tokenId was stored
      set._ownedTokens.pop();

      // Delete the index for the deleted slot
      delete set._ownedTokensIndex[tokenId];

    }
    /**
     * @dev Returns true if the tokenId is in the set. O(1).
     */
    function _contains(UintSet storage set, uint256 tokenId) private view returns (bool) {
        return set._ownedTokensIndex[tokenId] != 0;
    }
    /**
     * @dev Returns true if the tokenId is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 tokenId) internal view returns (bool) {
      return _contains(set,tokenId);
    }
    /**
     * @dev Returns all tokenIds of owner.
     * WARNING call can be vast sometime , use it with caution
     */
    function all(UintSet storage set) internal view returns (uint256 [] memory) {
      return set._ownedTokens;
    }

    /**
     * @dev Returns the number of tokenIds on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return set._ownedTokens.length;
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
      require(set._ownedTokens.length > index, "EnumerableSet: index out of bounds");
      return set._ownedTokens[index];
    }
}
/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}


//SourceUnit: minterRole.sol

pragma solidity ^0.5.5;
import "./roles.sol";
import "./context.sol";
// import "./interface.sol";
import "./abstract.sol";



contract MinterRole is Context{

    using Minters for Minters.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event OwnershipTransfer(address indexed account);

    Minters.Role private _admins;
    address private ownerAddr;
    bool public currentState;


    constructor () internal {
        _addMinter(_msgSender());
        _changeOwner(_msgSender());
        currentState = true;

    }

    modifier onlyOwner() {
        require(_msgSender() == Owner(),"MinterRole: caller is not owner");
        _;
      }

    modifier onlyMinter() {
        require(isMinter(_msgSender()) || _msgSender() == Owner(),"MinterRole: caller does not have the Minter role");
        _;
    }
    modifier isNotPaused() {
        require(currentState,"ContractMinter : paused contract for action");
        _;
    }

    function changeState(bool _state) public onlyMinter returns(bool){
        require(_state != currentState,"ContractMinter : same state");
        currentState = _state;
        return _state;
    }

    function Owner() public view returns (address) {
        return ownerAddr;
    }

    function changeOwner(address account) external onlyOwner {
      _changeOwner(account);
    }

    function _changeOwner(address account)internal{
      require(account != address(0) && account != ownerAddr ,"MinterRole: Address is Owner or zero address");
       ownerAddr = account;
       emit OwnershipTransfer(account);
    }

    function isMinter(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addMinter(address account) public onlyMinter {

        _addMinter(account);
    }
    function removeMinter(address account) public onlyMinter {
        _removeMinter(account);
    }

    function renounceMinter() public{
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _admins.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _admins.remove(account);
        emit MinterRemoved(account);
    }
}


contract BlockRole is MinterRole{

  using blocks for blocks.Role;

  event BlockAdded(address indexed account);
  event BlockRemoved(address indexed account);

  blocks.Role private _blockedUser;


  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

    modifier isNotBlackListed(address account){
       require(!getBlackListStatus(account),"BlockRole : Address restricted");
        _;
    }

    function addBlackList(address account) public onlyMinter {
      _addBlackList(account);
    }

    function removeBlackList(address account) public onlyMinter {
      _removeBlackList(account);
    }

    function getBlackListStatus(address account) public view returns (bool) {
      return _blockedUser.has(account);
    }

    function _addBlackList(address account) internal {
      _blockedUser.add(account);
      emit BlockAdded(account);
    }

    function _removeBlackList(address account) internal {
      _blockedUser.remove(account);
      emit BlockRemoved(account);

    }

}

contract FundController is Context,MinterRole{

constructor() internal {}


    /*
    * @title claimTRX
    * @dev it can let admin withdraw trx from contract
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function claimTRX(address payable to, uint256 value)
    external
    onlyMinter
    returns (bool)
    {
      require(address(this).balance >= value, "FundController: insufficient balance");

      (bool success, ) = to.call.value(value)("");
      require(success, "FundController: unable to send value, accepter may have reverted");
      return true;
    }
    /*
    * @title claimTRC10
    * @dev it can let admin withdraw any trc10 from contract
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @param token The tokenId of token to be transferred.

    */
     function claimTRC10(address payable to, uint256 value, uint256 token)
     external
     onlyMinter
     returns (bool)
    {
      require(value <=  address(this).tokenBalance(token), "FundController: Not enought Token Available");
      to.transferToken(value, token);
      return true;
    }
    /*
    * @title claimTRC20
    * @dev it can let admin withdraw any trc20 from contract
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @param token The contract address of token to be transferred.

    */
    function claimTRC20(address to, uint256 value, address token)
    external
    onlyMinter
    returns (bool)
    {
      (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
      bool result = success && (data.length == 0 || abi.decode(data, (bool)));
      require(result, "FundController: unable to transfer value, recipient or token may have reverted");
      return true;
    }
  /*
  * @title claimTRC721
  * @dev it can let admin withdraw any trc721 from contract
  * @param to The address to transfer to.
  * @param tokenId of token to be transferred.
  * @param token The contract address of token to be transferred.
  */
  function claimTRC721(address payable to,uint256 tokenId , address token)
  external
  onlyMinter
  returns (bool)
  {
      ITRC721(token).safeTransferFrom(address(this),to,tokenId);
      return true;
  }
    //Fallback
    function () external payable { }


    function kill() public onlyOwner {
      selfdestruct(_msgSender());
    }
//
}
contract MinterControl is MinterRole,FundController{
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.

  constructor () internal { }

}


//SourceUnit: roles.sol

pragma solidity ^0.5.5;

/**
 * @title Minters
 * @dev Library for managing addresses assigned to a Role.
 */
library Minters {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Minters: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Minters: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Minters: account is the zero address");
        return role.bearer[account];
    }
}
/**
 * @title blocks
 * @dev Library for managing addresses assigned to restriction.
 */

library blocks {

  struct Role{
    /// @dev Black Lists
    mapping (address => bool) bearer;
  }

  /**
   * @dev remove an account access to this contract
   */
  function add(Role storage role, address account) internal {
      require(!has(role, account),"blocks: account already has role");

      role.bearer[account] = true;
  }

  /**
   * @dev give back an blocked account's access to this contract
   */
  function remove(Role storage role, address account) internal {
      require(has(role, account), "blocks: account does not have role");

      role.bearer[account] = false;
  }

  /**
   * @dev check if an account has blocked to use this contract
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "blocks: account is the zero address");
      return role.bearer[account];
  }

}


//SourceUnit: safeMath.sol

pragma solidity ^0.5.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}