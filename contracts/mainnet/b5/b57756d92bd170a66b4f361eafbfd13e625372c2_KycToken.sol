pragma solidity ^0.4.24;

// File: @0xcert/ethereum-erc721/contracts/tokens/ERC721Enumerable.sol

/**
 * @dev Optional enumeration extension for ERC-721 non-fungible token standard.
 * See https://goo.gl/pc9yoS.
 */
interface ERC721Enumerable {

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   */
  function totalSupply()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
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
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}

// File: @0xcert/ethereum-erc721/contracts/tokens/ERC721.sol

/**
 * @dev ERC-721 non-fungible token standard. See https://goo.gl/pc9yoS.
 */
interface ERC721 {

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
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls `onERC721Received`
   * on `_to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
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
   * they mayb be permanently lost.
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
   * `msg.sender`&#39;s assets. It also emits the ApprovalForAll event.
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
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
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
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// File: @0xcert/ethereum-erc721/contracts/tokens/ERC721TokenReceiver.sol

/**
 * @dev ERC-721 interface for accepting safe transfers. See https://goo.gl/pc9yoS.
 */
interface ERC721TokenReceiver {

  /**
   * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
   * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
   * of other than the magic value MUST result in the transaction being reverted.
   * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
   * @notice The contract address is always the message sender. A wallet/broker/auction application
   * MUST implement the wallet interface if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function.
   * @param _from The sending address.
   * @param _tokenId The NFT identifier which is being transferred.
   * @param _data Additional data with no specified format.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    external
    returns(bytes4);
    
}

// File: @0xcert/ethereum-utils/contracts/math/SafeMath.sol

/**
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   * @param _a Factor number.
   * @param _b Factor number.
   */
  function mul(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   * @param _a Dividend number.
   * @param _b Divisor number.
   */
  function div(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a / _b;
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _a Minuend number.
   * @param _b Subtrahend number.
   */
  function sub(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   * @param _a Number.
   * @param _b Number.
   */
  function add(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }

}

// File: @0xcert/ethereum-utils/contracts/ownership/Ownable.sol

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code
 * at https://goo.gl/n2ZGVt.
 */
contract Ownable {
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
    public
  {
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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: @0xcert/ethereum-utils/contracts/utils/AddressUtils.sol

/**
 * @dev Utility library of inline functions on addresses.
 */
library AddressUtils {

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool)
  {
    uint256 size;

    /**
     * XXX Currently there is no better way to check if there is a contract in an address than to
     * check the size of the code at that address.
     * See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
     * TODO: Check this again before the Serenity release, because all addresses will be
     * contracts then.
     */
    assembly { size := extcodesize(_addr) } // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: @0xcert/ethereum-utils/contracts/utils/ERC165.sol

/**
 * @dev A standard for detecting smart contract interfaces. See https://goo.gl/cxQCse.
 */
interface ERC165 {

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * @notice This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);

}

// File: @0xcert/ethereum-utils/contracts/utils/SupportsInterface.sol

/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces.
   * @notice You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
    public
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

// File: @0xcert/ethereum-erc721/contracts/tokens/NFToken.sol

/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFToken is
  Ownable,
  ERC721,
  SupportsInterface
{
  using SafeMath for uint256;
  using AddressUtils for address;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;

  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApprovals;

   /**
   * @dev Mapping from owner address to count of his tokens.
   */
  mapping (address => uint256) internal ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Magic value of a smart contract that can recieve NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   * @param _from Sender of NFT (if address is zero address it indicates token creation).
   * @param _to Receiver of NFT (if address is zero address it indicates token destruction).
   * @param _tokenId The NFT that got transfered.
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
   * @param _owner Owner of NFT.
   * @param _approved Address that we are approving.
   * @param _tokenId NFT which we are approving.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   * @param _owner Owner of NFT.
   * @param _operator Address to which we are setting operator rights.
   * @param _approved Status of operator rights(true if operator rights are given and false if
   * revoked).
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(
    uint256 _tokenId
  ) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
    _;
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  ) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || getApproved(_tokenId) == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );

    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  ) {
    require(idToOwner[_tokenId] != address(0));
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor()
    public
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256)
  {
    require(_owner != address(0));
    return ownerToNFTokenCount[_owner];
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0));
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls `onERC721Received`
   * on `_to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    external
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

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
    external
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they maybe be permanently lost.
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
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);
  }

  /**
   * @dev Set or reaffirm the approved address for an NFT.
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
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);

    idToApprovals[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`&#39;s assets. It also emits the ApprovalForAll event.
   * @notice This works even if sender doesn&#39;t own any tokens at the time.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
  {
    require(_operator != address(0));
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId ID of the NFT to query the approval of.
   */
  function getApproved(
    uint256 _tokenId
  )
    public
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApprovals[_tokenId];
  }

  /**
   * @dev Checks if `_operator` is an approved operator for `_owner`.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool)
  {
    require(_owner != address(0));
    require(_operator != address(0));
    return ownerToOperators[_owner][_operator];
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
    bytes _data
  )
    internal
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);

    if (_to.isContract()) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED);
    }
  }

  /**
   * @dev Actually preforms the transfer.
   * @notice Does NO checks.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    private
  {
    address from = idToOwner[_tokenId];

    clearApproval(from, _tokenId);
    removeNFToken(from, _tokenId);
    addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is a private function which should be called from user-implemented external
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
  {
    require(_to != address(0));
    require(_tokenId != 0);
    require(idToOwner[_tokenId] == address(0));

    addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is a private function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _owner Address of the NFT owner.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    address _owner,
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    internal
  {
    clearApproval(_owner, _tokenId);
    removeNFToken(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Clears the current approval of a given NFT ID.
   * @param _tokenId ID of the NFT to be transferred.
   */
  function clearApproval(
    address _owner,
    uint256 _tokenId
  )
    internal
  {
    delete idToApprovals[_tokenId];
    emit Approval(_owner, 0, _tokenId);
  }

  /**
   * @dev Removes a NFT from owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function removeNFToken(
    address _from,
    uint256 _tokenId
  )
   internal
  {
    require(idToOwner[_tokenId] == _from);
    assert(ownerToNFTokenCount[_from] > 0);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from].sub(1);
    delete idToOwner[_tokenId];
  }

  /**
   * @dev Assignes a new NFT to owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(idToOwner[_tokenId] == address(0));

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }

}

// File: @0xcert/ethereum-erc721/contracts/tokens/NFTokenEnumerable.sol

/**
 * @dev Optional enumeration implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenEnumerable is
  NFToken,
  ERC721Enumerable
{

  /**
   * @dev Array of all NFT IDs.
   */
  uint256[] internal tokens;

  /**
   * @dev Mapping from owner address to a list of owned NFT IDs.
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
    public
  {
    supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is a private function which should be called from user-implemented external
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
  {
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is a private function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _owner Address of the NFT owner.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    address _owner,
    uint256 _tokenId
  )
    internal
  {
    assert(tokens.length > 0);
    super._burn(_owner, _tokenId);

    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length.sub(1);
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;
    tokens[lastTokenIndex] = 0;

    tokens.length--;
    idToIndex[_tokenId] = 0;
    idToIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function removeNFToken(
    address _from,
    uint256 _tokenId
  )
   internal
  {
    super.removeNFToken(_from, _tokenId);
    assert(ownerToIds[_from].length > 0);

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);
    uint256 lastToken = ownerToIds[_from][lastTokenIndex];

    ownerToIds[_from][tokenToRemoveIndex] = lastToken;

    ownerToIds[_from].length--;
    idToOwnerIndex[_tokenId] = 0;
    idToOwnerIndex[lastToken] = tokenToRemoveIndex;
  }

  /**
   * @dev Assignes a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    super.addNFToken(_to, _tokenId);

    uint256 length = ownerToIds[_to].length;
    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = length;
  }

  /**
   * @dev Returns the count of all existing NFTokens.
   */
  function totalSupply()
    external
    view
    returns (uint256)
  {
    return tokens.length;
  }

  /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256)
  {
    require(_index < tokens.length);
    return tokens[_index];
  }

  /**
   * @dev returns the n-th NFT ID from a list of owner&#39;s tokens.
   * @param _owner Token owner&#39;s address.
   * @param _index Index number representing n-th token in owner&#39;s list of tokens.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length);
    return ownerToIds[_owner][_index];
  }

}

// File: @0xcert/ethereum-erc721/contracts/tokens/ERC721Metadata.sol

/**
 * @dev Optional metadata extension for ERC-721 non-fungible token standard.
 * See https://goo.gl/pc9yoS.
 */
interface ERC721Metadata {

  /**
   * @dev Returns a descriptive name for a collection of NFTs in this contract.
   */
  function name()
    external
    view
    returns (string _name);

  /**
   * @dev Returns a abbreviated name for a collection of NFTs in this contract.
   */
  function symbol()
    external
    view
    returns (string _symbol);

  /**
   * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
   * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
   * that conforms to the "ERC721 Metadata JSON Schema".
   */
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string);

}

// File: @0xcert/ethereum-erc721/contracts/tokens/NFTokenMetadata.sol

/**
 * @dev Optional metadata implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

  /**
   * @dev A descriptive name for a collection of NFTs.
   */
  string internal nftName;

  /**
   * @dev An abbreviated name for NFTokens.
   */
  string internal nftSymbol;

  /**
   * @dev Mapping from NFT ID to metadata uri.
   */
  mapping (uint256 => string) internal idToUri;

  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don&#39;t forget to set nftName and nftSymbol.
   */
  constructor()
    public
  {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }

  /**
   * @dev Burns a NFT.
   * @notice This is a internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _owner Address of the NFT owner.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    address _owner,
    uint256 _tokenId
  )
    internal
  {
    super._burn(_owner, _tokenId);

    if (bytes(idToUri[_tokenId]).length != 0) {
      delete idToUri[_tokenId];
    }
  }

  /**
   * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
   * @notice this is a internal function which should be called from user-implemented external
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _tokenId Id for which we want uri.
   * @param _uri String representing RFC 3986 URI.
   */
  function _setTokenUri(
    uint256 _tokenId,
    string _uri
  )
    validNFToken(_tokenId)
    internal
  {
    idToUri[_tokenId] = _uri;
  }

  /**
   * @dev Returns a descriptive name for a collection of NFTokens.
   */
  function name()
    external
    view
    returns (string _name)
  {
    _name = nftName;
  }

  /**
   * @dev Returns an abbreviated name for NFTokens.
   */
  function symbol()
    external
    view
    returns (string _symbol)
  {
    _symbol = nftSymbol;
  }

  /**
   * @dev A distinct URI (RFC 3986) for a given NFT.
   * @param _tokenId Id for which we want uri.
   */
  function tokenURI(
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    external
    view
    returns (string)
  {
    return idToUri[_tokenId];
  }

}

// File: contracts/tokens/Xcert.sol

/**
 * @dev Xcert implementation.
 */
contract Xcert is NFTokenEnumerable, NFTokenMetadata {
  using SafeMath for uint256;
  using AddressUtils for address;

  /**
   * @dev Unique ID which determines each Xcert smart contract type by its JSON convention.
   * @notice Calculated as bytes4(keccak256(jsonSchema)).
   */
  bytes4 internal nftConventionId;

  /**
   * @dev Maps NFT ID to proof.
   */
  mapping (uint256 => string) internal idToProof;

  /**
   * @dev Maps NFT ID to protocol config.
   */
  mapping (uint256 => bytes32[]) internal config;

  /**
   * @dev Maps NFT ID to convention data.
   */
  mapping (uint256 => bytes32[]) internal data;

  /**
   * @dev Maps address to authorization of contract.
   */
  mapping (address => bool) internal addressToAuthorized;

  /**
   * @dev Emits when an address is authorized to some contract control or the authorization is revoked.
   * The _target has some contract controle like minting new NFTs.
   * @param _target Address to set authorized state.
   * @param _authorized True if the _target is authorised, false to revoke authorization.
   */
  event AuthorizedAddress(
    address indexed _target,
    bool _authorized
  );

  /**
   * @dev Guarantees that msg.sender is allowed to mint a new NFT.
   */
  modifier isAuthorized() {
    require(msg.sender == owner || addressToAuthorized[msg.sender]);
    _;
  }

  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don&#39;t forget to set nftConventionId, nftName and
   * nftSymbol.
   */
  constructor()
    public
  {
    supportedInterfaces[0x6be14f75] = true; // Xcert
  }

  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _id The NFT to be minted by the msg.sender.
   * @param _uri An URI pointing to NFT metadata.
   * @param _proof Cryptographic asset imprint.
   * @param _config Array of protocol config values where 0 index represents token expiration
   * timestamp, other indexes are not yet definied but are ready for future xcert upgrades.
   * @param _data Array of convention data values.
   */
  function mint(
    address _to,
    uint256 _id,
    string _uri,
    string _proof,
    bytes32[] _config,
    bytes32[] _data
  )
    external
    isAuthorized()
  {
    require(_config.length > 0);
    require(bytes(_proof).length > 0);
    super._mint(_to, _id);
    super._setTokenUri(_id, _uri);
    idToProof[_id] = _proof;
    config[_id] = _config;
    data[_id] = _data;
  }

  /**
   * @dev Returns a bytes4 of keccak256 of json schema representing 0xcert protocol convention.
   */
  function conventionId()
    external
    view
    returns (bytes4 _conventionId)
  {
    _conventionId = nftConventionId;
  }

  /**
   * @dev Returns proof for NFT.
   * @param _tokenId Id of the NFT.
   */
  function tokenProof(
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    external
    view
    returns(string)
  {
    return idToProof[_tokenId];
  }

  /**
   * @dev Returns convention data value for a given index field.
   * @param _tokenId Id of the NFT we want to get value for key.
   * @param _index for which we want to get value.
   */
  function tokenDataValue(
    uint256 _tokenId,
    uint256 _index
  )
    validNFToken(_tokenId)
    public
    view
    returns(bytes32 value)
  {
    require(_index < data[_tokenId].length);
    value = data[_tokenId][_index];
  }

  /**
   * @dev Returns expiration date from 0 index of token config values.
   * @param _tokenId Id of the NFT we want to get expiration time of.
   */
  function tokenExpirationTime(
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    external
    view
    returns(bytes32)
  {
    return config[_tokenId][0];
  }

  /**
   * @dev Sets authorised address for minting.
   * @param _target Address to set authorized state.
   * @param _authorized True if the _target is authorised, false to revoke authorization.
   */
  function setAuthorizedAddress(
    address _target,
    bool _authorized
  )
    onlyOwner
    external
  {
    require(_target != address(0));
    addressToAuthorized[_target] = _authorized;
    emit AuthorizedAddress(_target, _authorized);
  }

  /**
   * @dev Sets mint authorised address.
   * @param _target Address for which we want to check if it is authorized.
   * @return Is authorized or not.
   */
  function isAuthorizedAddress(
    address _target
  )
    external
    view
    returns (bool)
  {
    require(_target != address(0));
    return addressToAuthorized[_target];
  }
}

// File: contracts/tokens/MutableXcert.sol

/**
 * @dev Xcert implementation where token data can be changed by authorized address.
 */
contract MutableXcert is Xcert {

  /**
   * @dev Emits when an Token data is changed.
   * @param _id NFT that data got changed.
   * @param _data New data.
   */
  event TokenDataChange(
    uint256 indexed _id,
    bytes32[] _data
  );

  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don&#39;t forget to set nftConventionId, nftName and
   * nftSymbol.
   */
  constructor()
    public
  {
    supportedInterfaces[0x59118221] = true; // MutableXcert
  }

  /**
   * @dev Modifies convention data by setting a new value for a given index field.
   * @param _tokenId Id of the NFT we want to set key value data.
   * @param _data New token data.
   */
  function setTokenData(
    uint256 _tokenId,
    bytes32[] _data
  )
    validNFToken(_tokenId)
    isAuthorized()
    external
  {
    data[_tokenId] = _data;
    emit TokenDataChange(_tokenId, _data);
  }
}

// File: contracts/tokens/PausableXcert.sol

/**
 * @dev Xcert implementation where tokens transfer can be paused/unpaused.
 */
contract PausableXcert is Xcert {

  /**
   * @dev This emits when ability of beeing able to transfer NFTs changes (paused/unpaused).
   */
  event IsPaused(bool _isPaused);

  /**
   * @dev Are NFT paused or not.
   */
  bool public isPaused;

  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don&#39;t forget to set nftConventionId, nftName,
   * nftSymbol and isPaused.
   */
  constructor()
    public
  {
    supportedInterfaces[0xbedb86fb] = true; // PausableXcert
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address owner = idToOwner[_tokenId];
    require(!isPaused && (
      owner == msg.sender
      || getApproved(_tokenId) == msg.sender
      || ownerToOperators[owner][msg.sender])
    );

    _;
  }

  /**
   * @dev Sets if NFTs are paused or not.
   * @param _isPaused Pause status.
   */
  function setPause(
    bool _isPaused
  )
    external
    onlyOwner
  {
    require(isPaused != _isPaused);
    isPaused = _isPaused;
    emit IsPaused(_isPaused);
  }

}

// File: contracts/tokens/RevokableXcert.sol

/**
 * @dev Xcert implementation where tokens can be destroyed by the issuer.
 */
contract RevokableXcert is Xcert {

  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don&#39;t forget to set nftConventionId, nftName and
   * nftSymbol.
   */
  constructor()
    public
  {
    supportedInterfaces[0x20c5429b] = true; // RevokableXcert
  }

  /**
   * @dev Revokes a specified NFT.
   * @param _tokenId Id of the NFT we want to revoke.
   */
  function revoke(
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    onlyOwner
    external
  {
    address tokenOwner = idToOwner[_tokenId];
    super._burn(tokenOwner, _tokenId);
    delete data[_tokenId];
    delete config[_tokenId];
    delete idToProof[_tokenId];
  }
}

// File: contracts/mocks/KycToken.sol

contract KycToken is
  PausableXcert,
  RevokableXcert,
  MutableXcert
{

  constructor()
    public
  {
    nftName = "0xcert KYC";
    nftSymbol = "KYC";
    nftConventionId = 0xfc3ee448;
    isPaused = true;
  }

}