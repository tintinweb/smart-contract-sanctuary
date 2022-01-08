/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
 */  
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}interface ERC721TokenReceiver
{

  /**
   * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
   * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
   * of other than the magic value MUST result in the transaction being reverted.
   * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
   * @notice The contract address is always the message sender. A wallet/broker/auction application
   * MUST implement the wallet interface if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function.
   * @param _from The address which previously owned the token.
   * @param _tokenId The NFT identifier which is being transferred.
   * @param _data Additional data with no specified format.
   * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}interface ERC165
{

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);
    
}
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces. You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   * @return True if _interfaceID is supported, false otherwise.
   */
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
library AddressUtils
{

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   * @return addressCheck True if _addr is a contract, false if not.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}
interface ERC721Metadata
{

  /**
   * @dev Returns a descriptive name for a collection of NFTs in this contract.
   * @return _name Representing name.
   */
  function name()
    external
    view
    returns (string memory _name);

  /**
   * @dev Returns a abbreviated name for a collection of NFTs in this contract.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    view
    returns (string memory _symbol);

  /**
   * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
   * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
   * that conforms to the "ERC721 Metadata JSON Schema".
   * @return URI of _tokenId.
   */
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

}

contract NFToken is
  ERC721,
  SupportsInterface
{
  using AddressUtils for address;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  /**
   * @dev Magic value of a smart contract that can receive NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;
  
  /**
   *  mapping from Owner to list of NFT id.
   */
  mapping (address => uint256 []) internal tokenIdsOwnedBy;
  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApproval;

   /**
   * @dev Mapping from owner address to count of his tokens.
   */
  mapping (address => uint256) private ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  /**
   * @dev Contract constructor.
   */
    
  constructor()
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
    //owner = msg.sender;
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
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

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
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

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
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
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  /**
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved Address to be approved for the given NFT ID.
   * @param _tokenId ID of the token to be approved.
   */
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
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice This works even if sender doesn't own any tokens at the time.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
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

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return _owner Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId ID of the NFT to query the approval of.
   * @return Address that _tokenId is approved for.
   */
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

  /**
   * @dev Checks if `_operator` is an approved operator for `_owner`.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
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

  /**
   * @dev Actually performs the transfer.
   * @notice Does NO checks.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
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

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }


  /**
   * @dev Removes a NFT from owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from which we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
    
    for(uint index = 0;index < tokenIdsOwnedBy[_from].length;index++){
        if(tokenIdsOwnedBy[_from][index]==_tokenId){
            delete tokenIdsOwnedBy[_from][index];
            break;
            }
        }
    
  }

  /**
   * @dev Assigns a new NFT to owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to which we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to] + 1;
    tokenIdsOwnedBy[_to].push(_tokenId);
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage (gas optimization) of owner NFT count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
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

  /**
   * @dev Actually perform the safeTransferFrom.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
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
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract())
    {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  /**
   * @dev Clears the current approval of a given NFT ID.
   * @param _tokenId ID of the NFT to be transferred.
   */
  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    if (idToApproval[_tokenId] != address(0))
    {
      delete idToApproval[_tokenId];
    }
  }

}

abstract contract NFTInterface {

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) virtual external;
    
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    
    function ownerOf(uint __artId) virtual public view returns ( address artOwner);
    
    function safeTransferFrom( address _from, address _to, uint256 _tokenId) virtual public;
    
    function tokenURI(uint256 _tokenId) virtual external returns (string memory);

    function getNftTokenIds() virtual public view returns (uint [] memory);
    /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()virtual
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )virtual
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
   * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
   * representing invalid NFTs.
   * @param _owner An address where we are interested in NFTs owned by them.
   * @param _index A counter less than `balanceOf(_owner)`.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )virtual
    external
    view
    returns (uint256);
 }
 
 
contract NFTokenNBA is
  NFToken, 
  ERC721Metadata
{
  address public owner;
  string internal nftName;
  string internal nftSymbol;

   uint256 public tokenPrice = 15 ether;
   uint256 public nftTokenIdLast = 0;
    
   mapping (uint256 => string) internal idToUri;

    string public baseURI;
    
    struct nftPurchaser {
    address [] purchaserArray; 
    }
    mapping(uint => nftPurchaser) tokenIdOwners;
    
    uint256 [] nftTokenIds;
    uint256 constant public TOTAL_SUPPLY = 10000;
    
    
    event newTokenMinted(
       uint newNFT
    );
    
  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don't forget to set nftName and nftSymbol.
   */
  constructor()
  {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
    supportedInterfaces[0x780e9d63] = true; // ERC721Enumarable
    nftName = "Not a Bored Ape";
    nftSymbol = "NBA";
    owner = msg.sender;
    baseURI = "ipfs://QmaDRm8iCUwtaXCLAq9pu3VFDtcZ5PUU9n36E3ri3p33PH/";
  }
    
  /**
   * @dev Returns a descriptive name for a collection of NFTokens.
   * @return _name Representing name.
   */
  function name()
    external
    override
    view
    returns (string memory _name)
  {
    _name = nftName;
  }

  /**
   * @dev Returns an abbreviated name for NFTokens.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    override
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }
  function mint(
    address _to,
    uint256 _tokenId,
    string memory _uri
  )
    internal
  {     
       _mint(_to, _tokenId);
       _setTokenUri(_tokenId, _uri);
  }
  /**
   * @dev A distinct URI (RFC 3986) for a given NFT.
   * @param _tokenId Id for which we want uri.
   * @return URI of _tokenId.
   */
  function tokenURI(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    //return idToUri[_tokenId];
    return string(abi.encodePacked(baseURI,uintToString(_tokenId)));
  }


  /**
   * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
   * @notice This is an internal function which should be called from user-implemented external
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _tokenId Id for which we want URI.
   * @param _uri String representing RFC 3986 URI.
   */
  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }
  
  function uintToString(uint v) public pure returns (string memory) {
    uint maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    while (v != 0) {
        uint remainder = v % 10;
        v = v / 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i); // i + 1 is inefficient
    for (uint j = 0; j < i; j++) {
        s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
    }
    string memory str = string(s);  // memory isn't implicitly convertible to storage
    return str;
}
  /* CONTRACT FUNCTIONS*/
  function setTokenPrice(uint256 _price) public {
  require(msg.sender == owner ,"Only owner can act here");
  tokenPrice = _price;
  }

  function buyTokenNFT (uint _numTokens)  external payable returns (bool success){//override
        uint256 amount = msg.value;
       
        require(amount >= tokenPrice * _numTokens,"Not enought amount to buy this NFT");

        for(uint i = 0; i < _numTokens; i++){
         require(nftTokenIds.length <= TOTAL_SUPPLY,"Collection is not more available");
         nftTokenIdLast += 1;
         string memory URI = string(abi.encodePacked(baseURI,uintToString(nftTokenIdLast)));
        
         mint(msg.sender,nftTokenIdLast,URI);
                     
         tokenIdOwners[nftTokenIdLast].purchaserArray.push(msg.sender);
         nftTokenIds.push(nftTokenIdLast);
         
        }
        emit newTokenMinted(nftTokenIdLast);
        payable(owner).transfer(amount);
        
        return true;
    }

    /* ENUMERABLE FUNCTIONS*/

  function getTokenIdOwners(uint __tokenId) public view returns (address [] memory) {
      return tokenIdOwners[__tokenId].purchaserArray;
  } 

    function getNftTokenIds() public view returns (uint256 [] memory) {
      return nftTokenIds;
    }
  function getTokenIdsOwnedBy(address  _owner) virtual public view returns (uint256 [] memory){
     return tokenIdsOwnedBy[_owner];
  }
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view returns (uint256) {
        return tokenIdsOwnedBy[_owner][index];
    }
    
    function totalSupply()public view  returns (uint256) {
      return nftTokenIds.length;
    }

    function tokenByIndex(uint256 index) external view   returns (uint256) {
      return nftTokenIds[index];
    }

    receive() external payable { revert();}

}