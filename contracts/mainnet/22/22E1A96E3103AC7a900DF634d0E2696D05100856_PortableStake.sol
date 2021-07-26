/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: BeStaked.com
pragma solidity ^0.8.0;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
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

}

// File: contracts\ethereum-erc721\tokens\erc721-token-receiver.sol


pragma solidity ^0.8.0;

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
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

}

// File: contracts\ethereum-erc721\utils\erc165.sol


pragma solidity ^0.8.0;

/**
 * @dev A standard for detecting smart contract interfaces. 
 * See: https://eips.ethereum.org/EIPS/eip-165.
 */
interface ERC165
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

// File: contracts\ethereum-erc721\utils\supports-interface.sol


pragma solidity ^0.8.0;


/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
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

// File: contracts\ethereum-erc721\utils\address-utils.sol


pragma solidity ^0.8.0;

/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
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

// File: contracts\ethereum-erc721\tokens\nf-token.sol


pragma solidity ^0.8.0;





/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
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
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external burn
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
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

// File: contracts\ethereum-erc721\tokens\erc721-enumerable.sol


pragma solidity ^0.8.0;

/**
 * @dev Optional enumeration extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Enumerable
{

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()
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
  )
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
  )
    external
    view
    returns (uint256);

}

// File: contracts\ethereum-erc721\tokens\nf-token-enumerable.sol


pragma solidity ^0.8.0;



/**
 * @dev Optional enumeration implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenEnumerable is
  NFToken,
  ERC721Enumerable
{

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant INVALID_INDEX = "005007";

  /**
   * @dev Array of all NFT IDs.
   */
  uint256[] internal tokens;

  /**
   * @dev Mapping from token ID to its index in global tokens array.
   */
  mapping(uint256 => uint256) internal idToIndex;

  /**
   * @dev Mapping from owner to list of owned NFT IDs.
   */
  mapping(address => uint256[]) internal ownerToIds;

  /**
   * @dev Mapping from NFT ID to its index in the owner tokens list.
   */
  mapping(uint256 => uint256) internal idToOwnerIndex;

  /**
   * @dev Contract constructor.
   */
  constructor()
  {
    supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
  }

  /**
   * @dev Returns the count of all existing NFTokens.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    override
    view
    returns (uint256)
  {
    return tokens.length;
  }

  /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
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

  /**
   * @dev returns the n-th NFT ID from a list of owner's tokens.
   * @param _owner Token owner's address.
   * @param _index Index number representing n-th token in owner's list of tokens.
   * @return Token id.
   */
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
    override
    virtual
  {
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length - 1;
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.pop();
    // This wastes gas if you are burning the last token but saves a little gas if you are not.
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
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

  /**
   * @dev Assigns a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    idToOwner[_tokenId] = _to;

    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner NFT count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
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

// File: contracts\ethereum-erc721\tokens\erc721-metadata.sol


pragma solidity ^0.8.0;

/**
 * @dev Optional metadata extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
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

// File: contracts\ethereum-erc721\utils\Context1.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context1 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts\ethereum-erc721\ownership\ownable.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context1 {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\ERC20\IERC20.sol


pragma solidity ^0.8.0;
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * Copied from https://github.com/PacktPublishing/Mastering-Blockchain-Programming-with-Solidity/blob/master/Chapter09/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\lib\SafeMath.sol


pragma solidity ^0.8.0;

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

// File: contracts\ERC20\ERC20.sol


pragma solidity ^0.8.0;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 * Copied from https://github.com/PacktPublishing/Mastering-Blockchain-Programming-with-Solidity/blob/master/Chapter09/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

// File: contracts\Stakeable\IStakeable.sol


pragma solidity ^0.8.0;

interface IStakeable{
    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param amount Amount to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 amount, uint256 newStakedDays)external;
    /**
     * @dev PUBLIC FACING: Unlocks a completed stake, distributing the proceeds of any penalty
     * immediately. The staker must still call stakeEnd() to retrieve their stake return (if any).
     * @param stakerAddr Address of staker
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam)external;
    /**
     * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
     * a stake id is used to reject stale indexes.
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;
    /**
     * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
    function stakeCount(address stakerAddr)
        external
        view
        returns (uint256);
    
}
/**
* This contract is never instantiated or inherited from
* Its purpose is to allow strongly typed access to the HEX contract without including its source
 */
abstract contract StakeableRef is IStakeable, ERC20{
     struct StakeStore {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }
    mapping(address => StakeStore[]) public stakeLists;
    function currentDay() external virtual view returns (uint256);
    function symbol() public virtual view returns ( string memory);
    function name() public virtual view returns ( string memory);
}

// File: contracts\Wrapping\IERC20Wrapper.sol


 pragma solidity ^0.8.0;

 interface IERC20Wrapper {
     function getWrappedContract()external view returns(IERC20);
     function wrappedSymbol()external returns(string memory);
     function wrappedName()external returns(string memory);
 }

// File: contracts\lib\Reward.sol


pragma solidity ^0.8.0;
library Reward{
    function calcExpReward(uint256 principal,uint8 waitedDays, uint8 rewardStretchingDays)internal pure returns (uint256 rewardAmount){
        if(waitedDays == 0){
            return rewardAmount;
        }
        rewardAmount = principal;
        if(waitedDays > rewardStretchingDays){
            return rewardAmount;
        }
        uint8 base = 2;
        uint8 divisionTimes = uint8(rewardStretchingDays - waitedDays);
        for (uint i = 0; i < divisionTimes; i++){
            rewardAmount = rewardAmount / base;
            if(rewardAmount < base){break;}
        }            
        return rewardAmount;
    }
}

// File: contracts\Fees\FeeCollectorBase.sol


 pragma solidity ^0.8.0;

 abstract contract FeeCollectorBase{   
     IERC20 public PaymentContract;
     mapping(address=>uint256) public redeemableFees;
     constructor (IERC20 paymentContract){
         PaymentContract = paymentContract;
     }
     function redeemFees()external {
        address collector = address(msg.sender);
        uint256 amount = redeemableFees[collector];
        require(amount > 0, "no fees to redeem");
        if(PaymentContract.transfer(collector, amount)){
            redeemableFees[collector] = 0;
        }
     }
     function chargeFee(uint256 principal, uint256 fee, address collector)public returns (uint256 newPrincipal){
         if(fee <= principal && fee > 0 && collector != address(0)){
            uint256 amount = redeemableFees[collector];
            amount = amount + fee;
            redeemableFees[collector] = amount;
            newPrincipal = principal - fee;
         }else{
             newPrincipal = principal;
         }
     }
 }

// File: contracts\IERC165.sol

//Source: https://eips.ethereum.org/EIPS/eip-165
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts\Stakeable\PortableStake.sol


 pragma solidity ^0.8.0;

abstract contract Maintainable is Ownable{
    string public  Name = "BeStaked";
    string public  Symbol = "BSTHEX";
    string public  Domain = "bestaked";
    function setConstants(string calldata n, string calldata s, string calldata d,uint8 ds, uint8 m, uint8 o)external onlyOwner() {
        Name = n;
        Symbol = s;
        Domain = d;
        DEFAULT_REWARD_STRETCHING = ds;
        MAX_REFERRAL_FEE_PERMILLE = m;
        if(o <= MAX_OWNER_FEE_PERMILLE){
            OWNER_FEE_PERMILLE = o;
        }        
    }
    uint8 public constant MIN_REWARD_STRETCHING = 10;
    uint8 public DEFAULT_REWARD_STRETCHING = 60;
    uint8 public constant MAX_REWARD_STRETCHING = 255;
    uint8 public MAX_REFERRAL_FEE_PERMILLE = 100;//10%
    uint8 public constant MAX_OWNER_FEE_PERMILLE = 10;//1%
    uint8 public OWNER_FEE_PERMILLE = 2;//0.2%
}
contract PortableStake is NFTokenEnumerable,ERC721Metadata,IERC20Wrapper,Maintainable,FeeCollectorBase{
    event PortableStakeStart(
        uint256 tokenId, 
        uint256 stakeId,
        address owner,
        uint256 feeAmount, 
        uint256 stakedAmount, 
        uint16 stakeLength,
        uint8 rewardStretching
    );
     event PortableStakeEnd(
        uint256 tokenId, 
        uint256 stakeId,
        address owner,
        address actor,
        uint256 stakedAmount, 
        uint256 unStakedAmount, 
        uint256 actorRewardAmount, 
        uint256 returnedToOwnerAmount, 
        uint16 startDay,
        uint16 stakeLength,
        uint8 lateDays
    );
 
    struct TokenStore{
         uint256 tokenId;         
         uint256 amount;
         uint40 stakeId;
         uint8 rewardStretching;
     }
     
     StakeableRef/* StakeableToken */ public StakeableTokenContract;
     uint16 public MAX_STAKE_DAYS;
     uint8 public MIN_STAKE_DAYS;
     mapping(uint256 => TokenStore) public idToToken;
     
     constructor (StakeableRef stakeableTokenContract, uint8 minStakeDays, uint16 maxStakeDays) FeeCollectorBase(stakeableTokenContract) {
         StakeableTokenContract = stakeableTokenContract;
         MIN_STAKE_DAYS = minStakeDays;
         MAX_STAKE_DAYS = maxStakeDays;
         supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
     }
     function getWrappedContract()external override view returns(IERC20){
         return StakeableTokenContract;
     }
     function wrappedSymbol()external override view returns(string memory){
         return StakeableTokenContract.symbol();
     }
     function wrappedName()external override view returns(string memory){
         return StakeableTokenContract.name();
     }
    
    /**Represents the next token id to use. Increment after using.*/
    uint256 public TokenIdCounter = 1;
    /** 
     *@dev Returns a descriptive name for a collection of NFTs in this contract. 
     *@return _name Representing name.
     */
    function name()external override view returns (string memory _name){ return Name;}

    /**
   * @dev Returns a abbreviated name for a collection of NFTs in this contract. Not applicable.
   * @return _symbol Representing symbol.
   */
    function symbol() external override view returns (string memory _symbol){return Symbol;}

    /**
    * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
    * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
    * that conforms to the "ERC721 Metadata JSON Schema".
    * @return URI of _tokenId.
    */
    function tokenURI(uint256 _tokenId) external override view validNFToken(_tokenId) returns (string memory)  {
        //return "http://" + Domain + "/" + Symbol + "/token" + _tokenId + "metadata" + ".json";
        return string(abi.encodePacked("http://", Domain, "/", Symbol, "/token",_tokenId, "metadata", ".json"));
    }
    struct MintingInfo{
        address owner;
        address referrer;
        uint256 amount;  
        uint256 fee;
        uint16 stakeDays;
        uint8 rewardStretching;
     }
     /** 
    * Takes possession of the amount    
    * Subtracts fees
    * Stakes the amount
    * Mints token
    */
    function mintMaxDays(uint256 amount)external{        
        _mintPS(MintingInfo(address(msg.sender),address(0), amount, 0,MAX_STAKE_DAYS, DEFAULT_REWARD_STRETCHING));
    }
    function mintCustomDays(uint256 amount, uint16 stakeDays) external{
        _mintPS(MintingInfo(address(msg.sender),address(0), amount, 0,stakeDays, DEFAULT_REWARD_STRETCHING));
    }    
    function mintReferred(uint256 amount, uint16 stakeDays, address referrer, uint256 referralFee) external{
        _mintPS(MintingInfo(address(msg.sender),referrer, amount, referralFee,stakeDays, DEFAULT_REWARD_STRETCHING));
       //_mintPS(MintingInfo(address(msg.sender),amount, stakeDays, referrer,referralFee, DEFAULT_REWARD_STRETCHING));
    }
    function mintCustomRewardStretching(uint256 amount, uint16 stakeDays, address referrer, uint256 referralFee, uint8 rewardStretching)external{
        _mintPS(MintingInfo(address(msg.sender),referrer, amount, referralFee,stakeDays, rewardStretching));
        //_mintPS(MintingInfo(address(msg.sender),amount, stakeDays, referrer,referralFee, rewardStretching));
    }
    function _mintPS(MintingInfo memory info)internal{
        //Check input
        _checkInput(info);

        //Take posession of the amount
        _takePosession(info.owner, info.amount);        
        
        //Calculate stake amount by subtracting fees from the amount 
        (uint256 feeAmount, uint256 stakeAmount) = _calculateAndChargeFees(info.amount, info.fee, info.referrer); 
             
        //Note current stake count or future stake index
        uint256 stakeIndex = StakeableTokenContract.stakeCount(address(this));        
        //Stake the amount
        _startStake(stakeAmount, info.stakeDays);
        //Get stakeId
        uint40 stakeId = _confirmStake(stakeIndex);        

        //Record and broadcast
        uint256 tokenId = _mintToken(stakeId, info.rewardStretching, info.owner);
        emit PortableStakeStart(tokenId, stakeId, info.owner, feeAmount, stakeAmount, info.stakeDays, info.rewardStretching);
    }
   
    
    /** Consumes 3 400 gas */
    function _checkInput(MintingInfo memory info) public view{
        require(info.amount > 0, "PortableStake: amount is zero");
        require(info.stakeDays >= MIN_STAKE_DAYS, "PortableStake: newStakedDays lower than minimum");
        require(info.stakeDays <= MAX_STAKE_DAYS, "PortableStake: newStakedDays higher than maximum");        
        require(info.rewardStretching >= MIN_REWARD_STRETCHING, "rewardStretcing out of bounds");
        require(info.rewardStretching <= MAX_REWARD_STRETCHING, "rewardStretcing out of bounds");
    }     
      
    /** Consumes 20 000 gas */
    function _takePosession(address owner,uint256 amount) internal {
        //Check balance
        uint256 balance = StakeableTokenContract.balanceOf(owner);
        require(balance >= amount, "PortableStake: Insufficient funds");           
        //Check allowance
        uint256 allowance = StakeableTokenContract.allowance(owner, address(this));
        require(allowance >= amount, "PortableStake: allowance insufficient");
        //Take posession
        StakeableTokenContract.transferFrom(owner, address(this), amount);   
    }    
    
    function calculateReward(uint256 principal,uint8 waitedDays, uint8 rewardStretchingDays)public pure returns (uint256 rewardAmount){
        return Reward.calcExpReward(principal, waitedDays, rewardStretchingDays); 
    }
    
     /** Calculates and subtracts fees from principal. Allocates fees for future redemption on this contract. Returns new principal.  */
     function _calculateAndChargeFees(uint256 principal, uint256 requestedReferrerFee, address referrer)internal returns (uint256 feesCharged, uint256 newPrincipal){
        (uint256 referrerFee,uint256 ownerFee) = calculateFees(principal, requestedReferrerFee);
        newPrincipal = chargeFee(principal, referrerFee, referrer);
        newPrincipal = chargeFee(newPrincipal, ownerFee, owner());
        feesCharged = referrerFee + ownerFee;
     }
     /** Caps referrer fee and calculates owner fee. Returns both. */
    function calculateFees(uint256 principal, uint256 requestedReferrerFee) public view returns(uint256 referrerFee, uint256 ownerFee){
        uint256 perMille = principal / 1000;
        uint256 maxReferrerFee = perMille * MAX_REFERRAL_FEE_PERMILLE;
        if(requestedReferrerFee > maxReferrerFee){
            referrerFee = maxReferrerFee;
        }else{
            referrerFee = requestedReferrerFee;
        }
        ownerFee = perMille * OWNER_FEE_PERMILLE;
    }   
    /**Wraps stakeable _stakeStart method */
     function _startStake(uint256 amount, uint16 stakeDays)internal {
        StakeableTokenContract.stakeStart(amount, stakeDays);
    }  
    /** Confirms that the stake was started */
   function _confirmStake(uint256 id)internal view returns (uint40 ){
       (
            uint40 stakeId, 
            /* uint72 stakedHearts */,
            /* uint72 stakeShares */, 
            /* uint16 lockedDay */, 
            /* uint16 stakedDays */,
            /* uint16 unlockedDay */,
            /* bool isAutoStake */
        ) = StakeableTokenContract.stakeLists(address(this), id);
    return stakeId;
   }
   function _mintToken(uint40 stakeId, /* uint256 stakeIndex, */ uint8 stretch, address owner)internal returns (uint256 tokenId){
            tokenId = TokenIdCounter++;
            idToToken[tokenId] = TokenStore(tokenId, /* stakeIndex, */ 0,stakeId, stretch);
            super._mint(owner, tokenId);
    }  
    /** Gets the index of the stake. It is required for ending stake. */
    function getStakeIndex(uint256 tokenId)public view returns (uint256){

        uint256 targetStakeId = idToToken[tokenId].stakeId;
        uint256 currentStakeId = 0;
        uint256 stakeCount = StakeableTokenContract.stakeCount(address(this));
        for (uint256 i = 0; i < stakeCount; i++) {
            (
                currentStakeId, 
            /* uint72 stakedHearts */,
            /* uint72 stakeShares */, 
            /* uint16 lockedDay */, 
            /* uint16 stakedDays */,
            /* uint16 unlockedDay */,
            /* bool isAutoStake */
            ) = StakeableTokenContract.stakeLists(address(this), i);
            if(currentStakeId == targetStakeId){
                return i;
            }
        }
        return stakeCount;
    }
    /** Ends stake, pays reward, returns wrapped tokens to staker and burns the wrapping token. */
    function settle(uint256 tokenId, uint256 stakeIndex) validNFToken(tokenId) external{
        address owner = idToOwner[tokenId];
        address actor = address(msg.sender);        
        
        TokenStore memory token = idToToken[tokenId];
        require(token.stakeId > 0, "PortableStake: stakeId missing");
        (
            /* uint256 currentDay */, 
            uint256 stakedAmount,
            uint256 unStakedAmount, 
            uint16 startDay,
            uint16 stakeLength,
            uint8 lateDays
        )  = _endStake(token.stakeId, stakeIndex/* token.stakeIndex */);
        //require(unStakedAmount > 0, "unstaked amount = 0");
        token.amount = token.amount + unStakedAmount;
        uint256 rewardAmount;
        if(actor != owner){
            rewardAmount = Reward.calcExpReward(token.amount, lateDays, token.rewardStretching); 
            require(unStakedAmount >= rewardAmount,"Reward is larger than principal");                 
        }
        if(rewardAmount > 0){
            token.amount = chargeFee(token.amount, rewardAmount, actor);
        }        
        uint256 returnedToOwnerAmount = token.amount;
        if(StakeableTokenContract.transfer(owner, returnedToOwnerAmount)){
            token.amount = token.amount - returnedToOwnerAmount;
        }
        if(token.amount == 0){
            _burn(tokenId);
            delete idToToken[tokenId];
        }
        emit PortableStakeEnd(
            tokenId, 
            token.stakeId, 
            owner, 
            msg.sender, 
            stakedAmount, 
            unStakedAmount,
            rewardAmount,
            returnedToOwnerAmount,
            startDay,
            stakeLength,
            lateDays
        );
    }    
    /** Ends stake and leaves the wrapped token on this contract */
    function _endStake(uint40 id, uint256 index)internal returns(
        uint256 currentDay, 
        uint256 stakedAmount,
        uint256 unStakedAmount, 
        uint16 startDay,
        uint16 stakeLength,
        uint8 lateDays
        ){
        currentDay = StakeableTokenContract.currentDay();
        //Get the stake details
        (
            uint40 stakeId, 
            uint72 stakedHearts,
            /* uint72 stakeShares */, 
            uint16 lockedDay, 
            uint16 stakedDays,
            /* uint16 unlockedDay */,
            /* bool isAutoStake */
        ) = StakeableTokenContract.stakeLists(address(this), index);
        require(id == stakeId);
        stakedAmount = stakedHearts;
        startDay = lockedDay;
        stakeLength = stakedDays;
        uint16 servedDays = uint16(currentDay - lockedDay);
        require(servedDays >= stakedDays, "stake is not mature");
        
        lateDays = uint8(servedDays - stakedDays);
        uint256 initialBalance = StakeableTokenContract.balanceOf(address(this));        
        StakeableTokenContract.stakeEnd(index, stakeId);
        uint256 finalBalance = StakeableTokenContract.balanceOf(address(this));
        require(finalBalance > initialBalance, "stake yield <= 0");
        unStakedAmount = finalBalance - initialBalance;
    }
}