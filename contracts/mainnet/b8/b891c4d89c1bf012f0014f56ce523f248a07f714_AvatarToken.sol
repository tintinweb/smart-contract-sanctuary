pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
   * as the code is not actually created until after the constructor finishes.
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
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

library UrlStr {
  
  // generate url by tokenId
  // baseUrl must end with 00000000
  function generateUrl(string url,uint256 _tokenId) internal pure returns (string _url){
    _url = url;
    bytes memory _tokenURIBytes = bytes(_url);
    uint256 base_len = _tokenURIBytes.length - 1;
    _tokenURIBytes[base_len - 7] = byte(48 + _tokenId / 10000000 % 10);
    _tokenURIBytes[base_len - 6] = byte(48 + _tokenId / 1000000 % 10);
    _tokenURIBytes[base_len - 5] = byte(48 + _tokenId / 100000 % 10);
    _tokenURIBytes[base_len - 4] = byte(48 + _tokenId / 10000 % 10);
    _tokenURIBytes[base_len - 3] = byte(48 + _tokenId / 1000 % 10);
    _tokenURIBytes[base_len - 2] = byte(48 + _tokenId / 100 % 10);
    _tokenURIBytes[base_len - 1] = byte(48 + _tokenId / 10 % 10);
    _tokenURIBytes[base_len - 0] = byte(48 + _tokenId / 1 % 10);
  }
}


/**
  if a ERC721 item want to mount to avatar, it must to inherit this.
 */
interface AvatarChildService {
  /**
      @dev if you want your contract become a avatar child, please let your contract inherit this interface
      @param _tokenId1  first child token id
      @param _tokenId2  second child token id
      @return  true will unmount first token before mount ,false will directly mount child
   */
   function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res);
}

interface AvatarService {
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external;
  function createAvatar(address _owner, string _name, uint256 _dna) external  returns(uint256);
  function getMountTokenIds(address _owner,uint256 _tokenId, address _avatarItemAddress) external view returns(uint256[]); 
  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna);
  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds);
}

interface ERC165 {
  
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}


interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`&#39;s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface ERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata /* is ERC721 */ {
  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string _name);

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external view returns (string _symbol);

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint256 _tokenId) external view returns (string);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}


/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


/**
 * @title BitGuildAccessAdmin
 * @dev Allow two roles: &#39;owner&#39; or &#39;operator&#39;
 *      - owner: admin/superuser (e.g. with financial rights)
 *      - operator: can update configurations
 */
contract BitGuildAccessAdmin {
  address public owner;
  address[] public operators;

  uint public MAX_OPS = 20; // Default maximum number of operators allowed

  mapping(address => bool) public isOperator;

  event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
  );
  event OperatorAdded(address operator);
  event OperatorRemoved(address operator);

  // @dev The BitGuildAccessAdmin constructor: sets owner to the sender account
  constructor() public {
    owner = msg.sender;
  }

  // @dev Throws if called by any account other than the owner.
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // @dev Throws if called by any non-operator account. Owner has all ops rights.
  modifier onlyOperator {
    require(
      isOperator[msg.sender] || msg.sender == owner,
      "Permission denied. Must be an operator or the owner.");
    _;
  }

  /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(
      _newOwner != address(0),
      "Invalid new owner address."
    );
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  /**
    * @dev Allows the current owner or operators to add operators
    * @param _newOperator New operator address
    */
  function addOperator(address _newOperator) public onlyOwner {
    require(
      _newOperator != address(0),
      "Invalid new operator address."
    );

    // Make sure no dups
    require(
      !isOperator[_newOperator],
      "New operator exists."
    );

    // Only allow so many ops
    require(
      operators.length < MAX_OPS,
      "Overflow."
    );

    operators.push(_newOperator);
    isOperator[_newOperator] = true;

    emit OperatorAdded(_newOperator);
  }

  /**
    * @dev Allows the current owner or operators to remove operator
    * @param _operator Address of the operator to be removed
    */
  function removeOperator(address _operator) public onlyOwner {
    // Make sure operators array is not empty
    require(
      operators.length > 0,
      "No operator."
    );

    // Make sure the operator exists
    require(
      isOperator[_operator],
      "Not an operator."
    );

    // Manual array manipulation:
    // - replace the _operator with last operator in array
    // - remove the last item from array
    address lastOperator = operators[operators.length - 1];
    for (uint i = 0; i < operators.length; i++) {
      if (operators[i] == _operator) {
        operators[i] = lastOperator;
      }
    }
    operators.length -= 1; // remove the last element

    isOperator[_operator] = false;
    emit OperatorRemoved(_operator);
  }

  // @dev Remove ALL operators
  function removeAllOps() public onlyOwner {
    for (uint i = 0; i < operators.length; i++) {
      isOperator[operators[i]] = false;
    }
    operators.length = 0;
  } 

}


contract BitGuildAccessAdminExtend is BitGuildAccessAdmin {

  event FrozenFunds(address target, bool frozen);

  bool public isPaused = false;
  
  mapping(address => bool)  frozenAccount;

  modifier whenNotPaused {
    require(!isPaused);
    _;
  }

  modifier whenPaused {
    require(isPaused);
    _;  
  }

  function doPause() external  whenNotPaused onlyOwner {
    isPaused = true;
  }

  function doUnpause() external  whenPaused onlyOwner {
    isPaused = false;
  }

  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }

}


interface ERC998ERC721TopDown {
  event ReceivedChild(address indexed _from, uint256 indexed _tokenId, address indexed _childContract, uint256 _childTokenId);
  event TransferChild(uint256 indexed tokenId, address indexed _to, address indexed _childContract, uint256 _childTokenId);
  // gets the address and token that owns the supplied tokenId. isParent says if parentTokenId is a parent token or not.
  function tokenOwnerOf(uint256 _tokenId) external view returns (address tokenOwner, uint256 parentTokenId, uint256 isParent);
  function ownerOfChild(address _childContract, uint256 _childTokenId) external view returns (uint256 parentTokenId, uint256 isParent);
  function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns(bytes4);
  function onERC998Removed(address _operator, address _toContract, uint256 _childTokenId, bytes _data) external;
  function transferChild(address _to, address _childContract, uint256 _childTokenId) external;
  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId) external;
  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId, bytes _data) external;
  // getChild function enables older contracts like cryptokitties to be transferred into a composable
  // The _childContract must approve this contract. Then getChild can be called.
  function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external;
}

interface ERC998ERC721TopDownEnumerable {
  function totalChildContracts(uint256 _tokenId) external view returns(uint256);
  function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract);
  function totalChildTokens(uint256 _tokenId, address _childContract) external view returns(uint256);
  function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId);
}

interface ERC998ERC20TopDown {
  event ReceivedERC20(address indexed _from, uint256 indexed _tokenId, address indexed _erc223Contract, uint256 _value);
  event TransferERC20(uint256 indexed _tokenId, address indexed _to, address indexed _erc223Contract, uint256 _value);

  function tokenOwnerOf(uint256 _tokenId) external view returns (address tokenOwner, uint256 parentTokenId, uint256 isParent);
  function tokenFallback(address _from, uint256 _value, bytes _data) external;
  function balanceOfERC20(uint256 _tokenId, address __erc223Contract) external view returns(uint256);
  function transferERC20(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value) external;
  function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external;
  function getERC20(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) external;

}

interface ERC998ERC20TopDownEnumerable {
  function totalERC20Contracts(uint256 _tokenId) external view returns(uint256);
  function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns(address);
}

interface ERC20AndERC223 {
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function transfer(address to, uint value) external returns (bool success);
  function transfer(address to, uint value, bytes data) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract ComposableTopDown is ERC721, ERC998ERC721TopDown, ERC998ERC721TopDownEnumerable,
                                     ERC998ERC20TopDown, ERC998ERC20TopDownEnumerable, BitGuildAccessAdminExtend{
                            
  // tokenOwnerOf.selector;
  uint256 constant TOKEN_OWNER_OF = 0x89885a59;
  uint256 constant OWNER_OF_CHILD = 0xeadb80b8;

  // tokenId => token owner
  mapping (uint256 => address) internal tokenIdToTokenOwner;

  // root token owner address => (tokenId => approved address)
  mapping (address => mapping (uint256 => address)) internal rootOwnerAndTokenIdToApprovedAddress;

  // token owner address => token count
  mapping (address => uint256) internal tokenOwnerToTokenCount;

  // token owner => (operator address => bool)
  mapping (address => mapping (address => bool)) internal tokenOwnerToOperators;


  //from zepellin ERC721Receiver.sol
  //old version
  bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
  //new version
  bytes4 constant ERC721_RECEIVED_NEW = 0x150b7a02;
    /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */
  bytes4  constant InterfaceId_ERC998 = 0x520bdcbe;
              //InterfaceId_ERC998 = bytes4(keccak256(&#39;tokenOwnerOf(uint256)&#39;)) ^
              // bytes4(keccak256(&#39;ownerOfChild(address,uint256)&#39;)) ^
              // bytes4(keccak256(&#39;onERC721Received(address,address,uint256,bytes)&#39;)) ^
              // bytes4(keccak256(&#39;onERC998RemovedChild(address,address,uint256,bytes)&#39;)) ^
              // bytes4(keccak256(&#39;transferChild(address,address,uint256)&#39;)) ^
              // bytes4(keccak256(&#39;safeTransferChild(address,address,uint256)&#39;)) ^
              // bytes4(keccak256(&#39;safeTransferChild(address,address,uint256,bytes)&#39;)) ^
              // bytes4(keccak256(&#39;getChild(address,address,uint256,uint256)&#39;));




  ////////////////////////////////////////////////////////
  // ERC721 implementation
  ////////////////////////////////////////////////////////
  
  function _mint(address _to,uint256 _tokenId) internal whenNotPaused {
    tokenIdToTokenOwner[_tokenId] = _to;
    tokenOwnerToTokenCount[_to]++;
    emit Transfer(address(0), _to, _tokenId);
  }

  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

  function tokenOwnerOf(uint256 _tokenId) external view returns (address tokenOwner, uint256 parentTokenId, uint256 isParent) {
    tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(tokenOwner != address(0));
    if(tokenOwner == address(this)) {
      (parentTokenId, isParent) = ownerOfChild(address(this), _tokenId);
    }
    else {
      bool callSuccess;
      // 0xeadb80b8 == ownerOfChild(address,uint256)
      bytes memory calldata = abi.encodeWithSelector(0xeadb80b8, address(this), _tokenId);
      assembly {
        callSuccess := staticcall(gas, tokenOwner, add(calldata, 0x20), mload(calldata), calldata, 0x40)
        if callSuccess {
          parentTokenId := mload(calldata)
          isParent := mload(add(calldata,0x20))
        }
      }
      if(callSuccess && isParent >> 8 == OWNER_OF_CHILD) {
        isParent = TOKEN_OWNER_OF << 8 | uint8(isParent);
      }
      else {
        isParent = TOKEN_OWNER_OF << 8;
        parentTokenId = 0;
      }
    }
    return (tokenOwner, parentTokenId, isParent);
  }

  function ownerOf(uint256 _tokenId) external view returns (address rootOwner) {
    return _ownerOf(_tokenId);
  }
  
  // returns the owner at the top of the tree of composables
  function _ownerOf(uint256 _tokenId) internal view returns (address rootOwner) {
    rootOwner = tokenIdToTokenOwner[_tokenId];
    require(rootOwner != address(0));
    uint256 isParent = 1;
    bool callSuccess;
    bytes memory calldata;
    while(uint8(isParent) > 0) {
      if(rootOwner == address(this)) {
        (_tokenId, isParent) = ownerOfChild(address(this), _tokenId);
        if(uint8(isParent) > 0) {
          rootOwner = tokenIdToTokenOwner[_tokenId];
        }
      }
      else {
        if(isContract(rootOwner)) {
          //0x89885a59 == "tokenOwnerOf(uint256)"
          calldata = abi.encodeWithSelector(0x89885a59, _tokenId);
          assembly {
            callSuccess := staticcall(gas, rootOwner, add(calldata, 0x20), mload(calldata), calldata, 0x60)
            if callSuccess {
              rootOwner := mload(calldata)
              _tokenId := mload(add(calldata,0x20))
              isParent := mload(add(calldata,0x40))
            }
          }
          
          if(callSuccess == false || isParent >> 8 != TOKEN_OWNER_OF) {
            //0x6352211e == "_ownerOf(uint256)"
            calldata = abi.encodeWithSelector(0x6352211e, _tokenId);
            assembly {
              callSuccess := staticcall(gas, rootOwner, add(calldata, 0x20), mload(calldata), calldata, 0x20)
              if callSuccess {
                rootOwner := mload(calldata)
              }
            }
            require(callSuccess, "rootOwnerOf failed");
            isParent = 0;
          }
        }
        else {
          isParent = 0;
        }
      }
    }
    return rootOwner;
  }

  function balanceOf(address _tokenOwner)  external view returns (uint256) {
    require(_tokenOwner != address(0));
    return tokenOwnerToTokenCount[_tokenOwner];
  }


  function approve(address _approved, uint256 _tokenId) external whenNotPaused {
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    address rootOwner = _ownerOf(_tokenId);
    require(tokenOwner != address(0));
    require(
      rootOwner == msg.sender || 
      tokenOwnerToOperators[rootOwner][msg.sender] || 
      tokenOwner == msg.sender || 
      tokenOwnerToOperators[tokenOwner][msg.sender]);

    rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
    emit Approval(rootOwner, _approved, _tokenId);
  }

  function getApproved(uint256 _tokenId) external view returns (address)  {
    address rootOwner = _ownerOf(_tokenId);
    return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
  }

  function setApprovalForAll(address _operator, bool _approved) external whenNotPaused {
    require(_operator != address(0));
    tokenOwnerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function isApprovedForAll(address _owner, address _operator ) external  view returns (bool)  {
    require(_owner != address(0));
    require(_operator != address(0));
    return tokenOwnerToOperators[_owner][_operator];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
    require(!frozenAccount[_from]);                  
    require(!frozenAccount[_to]); 
    // tokenIdToTokenOwner[_tokenId] = _to;
    // tokenOwnerToTokenCount[_to]++;
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));
    address rootOwner = _ownerOf(_tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);

    // clear approval
    if(rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] != address(0)) {
      delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    // remove and transfer token
    if(_from != _to) {
      assert(tokenOwnerToTokenCount[_from] > 0);
      tokenOwnerToTokenCount[_from]--;
      tokenIdToTokenOwner[_tokenId] = _to;
      tokenOwnerToTokenCount[_to]++;
    }
    emit Transfer(_from, _to, _tokenId);

    if(isContract(_from)) {
      //0x0da719ec == "onERC998Removed(address,address,uint256,bytes)"
      bytes memory calldata = abi.encodeWithSelector(0x0da719ec, msg.sender, _to, _tokenId,"");
      assembly {
        let success := call(gas, _from, 0, add(calldata, 0x20), mload(calldata), calldata, 0)
      }
    }

  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    _transfer(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
    _transfer(_from, _to, _tokenId);
    if(isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "");
      require(retval == ERC721_RECEIVED_OLD);
    }
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
    _transfer(_from, _to, _tokenId);
    if(isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == ERC721_RECEIVED_OLD);
    }
  }

  ////////////////////////////////////////////////////////
  // ERC998ERC721 and ERC998ERC721Enumerable implementation
  ////////////////////////////////////////////////////////

  // tokenId => child contract
  mapping(uint256 => address[]) internal childContracts;

  // tokenId => (child address => contract index+1)
  mapping(uint256 => mapping(address => uint256)) internal childContractIndex;

  // tokenId => (child address => array of child tokens)
  mapping(uint256 => mapping(address => uint256[])) internal childTokens;

  // tokenId => (child address => (child token => child index+1)
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal childTokenIndex;

  // child address => childId => tokenId
  mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

  function onERC998Removed(address _operator, address _toContract, uint256 _childTokenId, bytes _data) external {
    uint256 tokenId = childTokenOwner[msg.sender][_childTokenId];
    _removeChild(tokenId, msg.sender, _childTokenId);
  }


  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId) external {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    _removeChild(tokenId, _childContract, _childTokenId);
    ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId, bytes _data) external {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    _removeChild(tokenId, _childContract, _childTokenId);
    ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId, _data);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

  function transferChild(address _to, address _childContract, uint256 _childTokenId) external {
    _transferChild(_to, _childContract,_childTokenId);
  }
 
  function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external {
    _getChild(_from, _tokenId, _childContract,_childTokenId);
  }

  function onERC721Received(address _from, uint256 _childTokenId, bytes _data) external returns(bytes4) {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
    require(isContract(msg.sender), "msg.sender is not a contract.");
    /**************************************
    * TODO move to library
    **************************************/
    // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
    uint256 tokenId;
    assembly {
      // new onERC721Received
      //tokenId := calldataload(164)
      tokenId := calldataload(132)
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
    //END TODO

    //require(this == ERC721Basic(msg.sender)._ownerOf(_childTokenId), "This contract does not own the child token.");

    _receiveChild(_from, tokenId, msg.sender, _childTokenId);
    //cause out of gas error if circular ownership
    _ownerOf(tokenId);
    return ERC721_RECEIVED_OLD;
  }


  function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns(bytes4) {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
    require(isContract(msg.sender), "msg.sender is not a contract.");
    /**************************************
    * TODO move to library
    **************************************/
    // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
    uint256 tokenId;
    assembly {
      // new onERC721Received
      tokenId := calldataload(164)
      //tokenId := calldataload(132)
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
    //END TODO

    //require(this == ERC721Basic(msg.sender)._ownerOf(_childTokenId), "This contract does not own the child token.");

    _receiveChild(_from, tokenId, msg.sender, _childTokenId);
    //cause out of gas error if circular ownership
    _ownerOf(tokenId);
    return ERC721_RECEIVED_NEW;
  }

  function _transferChild(address _to, address _childContract, uint256 _childTokenId) internal {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    _removeChild(tokenId, _childContract, _childTokenId);
    //this is here to be compatible with cryptokitties and other old contracts that require being owner and approved
    // before transferring.
    //does not work with current standard which does not allow approving self, so we must let it fail in that case.
    //0x095ea7b3 == "approve(address,uint256)"
    bytes memory calldata = abi.encodeWithSelector(0x095ea7b3, this, _childTokenId);
    assembly {
      let success := call(gas, _childContract, 0, add(calldata, 0x20), mload(calldata), calldata, 0)
    }
    ERC721(_childContract).transferFrom(this, _to, _childTokenId);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

  // this contract has to be approved first in _childContract
  function _getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal {
    _receiveChild(_from, _tokenId, _childContract, _childTokenId);
    require(
      _from == msg.sender || ERC721(_childContract).isApprovedForAll(_from, msg.sender) ||
    ERC721(_childContract).getApproved(_childTokenId) == msg.sender);
    ERC721(_childContract).transferFrom(_from, this, _childTokenId);
    //cause out of gas error if circular ownership
    _ownerOf(_tokenId);
  }

  function _receiveChild(address _from,  uint256 _tokenId, address _childContract, uint256 _childTokenId) private whenNotPaused {  
    require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
    require(childTokenIndex[_tokenId][_childContract][_childTokenId] == 0, "Cannot receive child token because it has already been received.");
    uint256 childTokensLength = childTokens[_tokenId][_childContract].length;
    if(childTokensLength == 0) {
      childContractIndex[_tokenId][_childContract] = childContracts[_tokenId].length;
      childContracts[_tokenId].push(_childContract);
    }
    childTokens[_tokenId][_childContract].push(_childTokenId);
    childTokenIndex[_tokenId][_childContract][_childTokenId] = childTokensLength + 1;
    childTokenOwner[_childContract][_childTokenId] = _tokenId;
    emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
  }
  
  function _removeChild(uint256 _tokenId, address _childContract, uint256 _childTokenId) private whenNotPaused {
    uint256 tokenIndex = childTokenIndex[_tokenId][_childContract][_childTokenId];
    require(tokenIndex != 0, "Child token not owned by token.");

    // remove child token
    uint256 lastTokenIndex = childTokens[_tokenId][_childContract].length-1;

    uint256 lastToken = childTokens[_tokenId][_childContract][lastTokenIndex];

    //if(_childTokenId == lastToken) {
    
    childTokens[_tokenId][_childContract][tokenIndex-1] = lastToken;
    childTokenIndex[_tokenId][_childContract][lastToken] = tokenIndex;
    //}
  
    childTokens[_tokenId][_childContract].length--;

    delete childTokenIndex[_tokenId][_childContract][_childTokenId];
    delete childTokenOwner[_childContract][_childTokenId];

    // remove contract
    if(lastTokenIndex == 0) {
      uint256 lastContractIndex = childContracts[_tokenId].length - 1;
      address lastContract = childContracts[_tokenId][lastContractIndex];
      if(_childContract != lastContract) {
        uint256 contractIndex = childContractIndex[_tokenId][_childContract];
        childContracts[_tokenId][contractIndex] = lastContract;
        childContractIndex[_tokenId][lastContract] = contractIndex;
      }
      childContracts[_tokenId].length--;
      delete childContractIndex[_tokenId][_childContract];
    }
  }

  function ownerOfChild(address _childContract, uint256 _childTokenId) public view returns (uint256 parentTokenId, uint256 isParent) {
    parentTokenId = childTokenOwner[_childContract][_childTokenId];
    if(parentTokenId == 0 && childTokenIndex[parentTokenId][_childContract][_childTokenId] == 0) {
      return (0, OWNER_OF_CHILD << 8);
    }
    return (parentTokenId, OWNER_OF_CHILD << 8 | 1);
  }

  function childExists(address _childContract, uint256 _childTokenId) external view returns (bool) {
    uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
    return childTokenIndex[tokenId][_childContract][_childTokenId] != 0;
  }

  function totalChildContracts(uint256 _tokenId) external view returns(uint256) {
    return childContracts[_tokenId].length;
  }

  function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract) {
    require(_index < childContracts[_tokenId].length, "Contract address does not exist for this token and index.");
    return childContracts[_tokenId][_index];
  }

  function totalChildTokens(uint256 _tokenId, address _childContract) external view returns(uint256) {
    return childTokens[_tokenId][_childContract].length;
  }

  function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId) {
    require(_index < childTokens[_tokenId][_childContract].length, "Token does not own a child token at contract address and index.");
    return childTokens[_tokenId][_childContract][_index];
  }

  ////////////////////////////////////////////////////////
  // ERC998ERC223 and ERC998ERC223Enumerable implementation
  ////////////////////////////////////////////////////////

  // tokenId => token contract
  mapping(uint256 => address[]) erc223Contracts;

  // tokenId => (token contract => token contract index)
  mapping(uint256 => mapping(address => uint256)) erc223ContractIndex;
  
  // tokenId => (token contract => balance)
  mapping(uint256 => mapping(address => uint256)) erc223Balances;
  
  function balanceOfERC20(uint256 _tokenId, address _erc223Contract) external view returns(uint256) {
    return erc223Balances[_tokenId][_erc223Contract];
  }

  function removeERC223(uint256 _tokenId, address _erc223Contract, uint256 _value) private whenNotPaused {
    if(_value == 0) {
      return;
    }
    uint256 erc223Balance = erc223Balances[_tokenId][_erc223Contract];
    require(erc223Balance >= _value, "Not enough token available to transfer.");
    uint256 newERC223Balance = erc223Balance - _value;
    erc223Balances[_tokenId][_erc223Contract] = newERC223Balance;
    if(newERC223Balance == 0) {
      uint256 lastContractIndex = erc223Contracts[_tokenId].length - 1;
      address lastContract = erc223Contracts[_tokenId][lastContractIndex];
      if(_erc223Contract != lastContract) {
        uint256 contractIndex = erc223ContractIndex[_tokenId][_erc223Contract];
        erc223Contracts[_tokenId][contractIndex] = lastContract;
        erc223ContractIndex[_tokenId][lastContract] = contractIndex;
      }
      erc223Contracts[_tokenId].length--;
      delete erc223ContractIndex[_tokenId][_erc223Contract];
    }
  }
  
  
  function transferERC20(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(_tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeERC223(_tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transfer(_to, _value), "ERC20 transfer failed.");
    emit TransferERC20(_tokenId, _to, _erc223Contract, _value);
  }
  
  // implementation of ERC 223
  function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(_tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeERC223(_tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transfer(_to, _value, _data), "ERC223 transfer failed.");
    emit TransferERC20(_tokenId, _to, _erc223Contract, _value);
  }

  // this contract has to be approved first by _erc223Contract
  function getERC20(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) public {
    bool allowed = _from == msg.sender;
    if(!allowed) {
      uint256 remaining;
      // 0xdd62ed3e == allowance(address,address)
      bytes memory calldata = abi.encodeWithSelector(0xdd62ed3e,_from,msg.sender);
      bool callSuccess;
      assembly {
        callSuccess := staticcall(gas, _erc223Contract, add(calldata, 0x20), mload(calldata), calldata, 0x20)
        if callSuccess {
          remaining := mload(calldata)
        }
      }
      require(callSuccess, "call to allowance failed");
      require(remaining >= _value, "Value greater than remaining");
      allowed = true;
    }
    require(allowed, "not allowed to getERC20");
    erc223Received(_from, _tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transferFrom(_from, this, _value), "ERC20 transfer failed.");
  }

  function erc223Received(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) private {
    require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
    if(_value == 0) {
      return;
    }
    uint256 erc223Balance = erc223Balances[_tokenId][_erc223Contract];
    if(erc223Balance == 0) {
      erc223ContractIndex[_tokenId][_erc223Contract] = erc223Contracts[_tokenId].length;
      erc223Contracts[_tokenId].push(_erc223Contract);
    }
    erc223Balances[_tokenId][_erc223Contract] += _value;
    emit ReceivedERC20(_from, _tokenId, _erc223Contract, _value);
  }
  
  // used by ERC 223
  function tokenFallback(address _from, uint256 _value, bytes _data) external {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the token to.");
    require(isContract(msg.sender), "msg.sender is not a contract");
    /**************************************
    * TODO move to library
    **************************************/
    // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
    uint256 tokenId;
    assembly {
      tokenId := calldataload(132)
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
    //END TODO
    erc223Received(_from, tokenId, msg.sender, _value);
  }
  
  function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns(address) {
    require(_index < erc223Contracts[_tokenId].length, "Contract address does not exist for this token and index.");
    return erc223Contracts[_tokenId][_index];
  }
  
  function totalERC20Contracts(uint256 _tokenId) external view returns(uint256) {
    return erc223Contracts[_tokenId].length;
  }
  
}

contract ERC998TopDownToken is SupportsInterfaceWithLookup, ERC721Enumerable, ERC721Metadata, ComposableTopDown {

  using SafeMath for uint256;

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */
  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
              
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

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
  constructor() public {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
    _registerInterface(InterfaceId_ERC998);
  }

  modifier existsToken(uint256 _tokenId){
    address owner = tokenIdToTokenOwner[_tokenId];
    require(owner != address(0), "This tokenId is invalid"); 
    _;
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return "Bitizen";
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return "BTZN";
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) external view existsToken(_tokenId) returns (string) {
    return "";
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(address(0) != _owner);
    require(_index < tokenOwnerToTokenCount[_owner]);
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
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) existsToken(_tokenId) internal {
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenTo(address _to, uint256 _tokenId) internal whenNotPaused {
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFrom(address _from, uint256 _tokenId) internal whenNotPaused {
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
   * Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal whenNotPaused {
    super._mint(_to, _tokenId);
    _addTokenTo(_to,_tokenId);
    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  //override
  //add Enumerable info
  function _transfer(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
    super._transfer(_from, _to, _tokenId);
    _addTokenTo(_to,_tokenId);
    _removeTokenFrom(_from, _tokenId);
  }
}


contract AvatarToken is ERC998TopDownToken, AvatarService {
  
  using UrlStr for string;

  event BatchMount(address indexed from, uint256 parent, address indexed childAddr, uint256[] children);
  event BatchUnmount(address indexed from, uint256 parent, address indexed childAddr, uint256[] children);
 
  struct Avatar {
    // avatar name
    string name;
    // avatar gen,this decide the avatar appearance 
    uint256 dna;
  }

  // For erc721 metadata
  string internal BASE_URL = "https://www.bitguild.com/bitizens/api/avatar/getAvatar/00000000";

  Avatar[] avatars;

  function createAvatar(address _owner, string _name, uint256 _dna) external onlyOperator returns(uint256) {
    return _createAvatar(_owner, _name, _dna);
  }

  function getMountTokenIds(address _owner, uint256 _tokenId, address _avatarItemAddress)
  external
  view 
  onlyOperator
  existsToken(_tokenId) 
  returns(uint256[]) {
    require(tokenIdToTokenOwner[_tokenId] == _owner);
    return childTokens[_tokenId][_avatarItemAddress];
  }
  
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external onlyOperator existsToken(_tokenId){
    require(_owner != address(0), "Invalid address");
    require(_owner == tokenIdToTokenOwner[_tokenId] || msg.sender == owner);
    Avatar storage avatar = avatars[allTokensIndex[_tokenId]];
    avatar.name = _name;
    avatar.dna = _dna;
  }

  function updateBaseURI(string _url) external onlyOperator {
    BASE_URL = _url;
  }

  function tokenURI(uint256 _tokenId) external view existsToken(_tokenId) returns (string) {
    return BASE_URL.generateUrl(_tokenId);
  }

  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds) {
    _tokenIds = ownedTokens[_owner];
  }

  function getAvatarInfo(uint256 _tokenId) external view existsToken(_tokenId) returns(string _name, uint256 _dna) {
    Avatar storage avatar = avatars[allTokensIndex[_tokenId]];
    _name = avatar.name;
    _dna = avatar.dna;
  }

  function batchMount(address _childContract, uint256[] _childTokenIds, uint256 _tokenId) external {
    uint256 _len = _childTokenIds.length;
    require(_len > 0, "No token need to mount");
    address tokenOwner = _ownerOf(_tokenId);
    require(tokenOwner == msg.sender);
    for(uint8 i = 0; i < _len; ++i) {
      uint256 childTokenId = _childTokenIds[i];
      require(ERC721(_childContract).ownerOf(childTokenId) == tokenOwner);
      _getChild(msg.sender, _tokenId, _childContract, childTokenId);
    }
    emit BatchMount(msg.sender, _tokenId, _childContract, _childTokenIds);
  }
 
  function batchUnmount(address _childContract, uint256[] _childTokenIds, uint256 _tokenId) external {
    uint256 len = _childTokenIds.length;
    require(len > 0, "No token need to unmount");
    address tokenOwner = _ownerOf(_tokenId);
    require(tokenOwner == msg.sender);
    for(uint8 i = 0; i < len; ++i) {
      uint256 childTokenId = _childTokenIds[i];
      _transferChild(msg.sender, _childContract, childTokenId);
    }
    emit BatchUnmount(msg.sender,_tokenId,_childContract,_childTokenIds);
  }

  // create avatar 
  function _createAvatar(address _owner, string _name, uint256 _dna) private returns(uint256 _tokenId) {
    require(_owner != address(0));
    Avatar memory avatar = Avatar(_name, _dna);
    _tokenId = avatars.push(avatar);
    _mint(_owner, _tokenId);
  }

  function _unmountSameSocketItem(address _owner, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal {
    uint256[] storage tokens = childTokens[_tokenId][_childContract];
    for(uint256 i = 0; i < tokens.length; ++i) {
      // if the child no compareItemSlots(uint256,uint256) ,this will lead to a error and stop this operate
      if(AvatarChildService(_childContract).compareItemSlots(tokens[i], _childTokenId)) {
        // unmount the old avatar item
        _transferChild(_owner, _childContract, tokens[i]);
      }
    }
  }

  // override  
  function _transfer(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
    // not allown to transfer when  only one  avatar 
    require(tokenOwnerToTokenCount[_from] > 1);
    super._transfer(_from, _to, _tokenId);
  }

  // override
  function _getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal {
    _unmountSameSocketItem(_from, _tokenId, _childContract, _childTokenId);
    super._getChild(_from, _tokenId, _childContract, _childTokenId);
  }

  function () external payable {
    revert();
  }

}