/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: UNLICENCED

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721Basic is ERC165 {


  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) external view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) external view returns (address _owner);
  function exists(uint256 _tokenId) external view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) external;
  function getApproved(uint256 _tokenId)
    external view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator)
    external view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    external;
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
   
 // bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes memory _data
  )  external  returns(bytes4);

}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a <= b ? a : b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b != 0);
        c =  a % b;
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
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

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
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
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
    override
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
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;


  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256('exists(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /*
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /*
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */

   
  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

  /*
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view override returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view override returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /*
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view override returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) override public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view override returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) override public {
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
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    override
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    override
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
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
    override
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    override
    public
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
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) virtual internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) virtual internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) virtual internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) virtual internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
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
    bytes memory _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;
    address public newOwner;
    bool private initialised;

     event OwnershipTransferred(address indexed from, address indexed to);

    function initOwned(address  _owner) internal {
        require(!initialised);
        owner = address(uint160(_owner));
        initialised = true;
    }
    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner);
        newOwner = _newOwner;
    }
    function acceptOwnership()  public  {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = address(uint160(newOwner));
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Owned: caller is not the owner");
        _;
    }
  
}

contract MyERC721Metadata is ERC165, ERC721BasicToken, Owned {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    string public baseURI = "https://dreamchannel.io/alpha/index.html?tokenId=";

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        initOwned(msg.sender);

        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function uintToBytes(uint256 num) internal pure returns (bytes memory b) {
        if (num == 0) {
            b = new bytes(1);
            b[0] = byte(uint8(48));
        } else {
            uint256 j = num;
            uint256 length;
            while (j != 0) {
                length++;
                j /= 10;
            }
            b = new bytes(length);
            uint k = length - 1;
            while (num != 0) {
                b[k--] = byte(uint8(48 + num % 10));
                num /= 10;
            }
        }
    }

    function setBaseURI(string memory uri) public  onlyOwner  {
        baseURI = uri;
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
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory url = _tokenURIs[tokenId];
        bytes memory urlAsBytes = bytes(url);
        if (urlAsBytes.length == 0) {
            bytes memory baseURIAsBytes = bytes(baseURI);
            bytes memory tokenIdAsBytes = uintToBytes(tokenId);
            bytes memory b = new bytes(baseURIAsBytes.length + tokenIdAsBytes.length);
            uint256 i;
            uint256 j;
            for (i = 0; i < baseURIAsBytes.length; i++) {
                b[j++] = baseURIAsBytes[i];
            }
            for (i = 0; i < tokenIdAsBytes.length; i++) {
                b[j++] = tokenIdAsBytes[i];
            }
            return string(b);
        } else {
            return _tokenURIs[tokenId];
        }
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) override internal {
        super._burn(owner,tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
// ----------------------------------------------------------------------------
// Secondary Accounts Data Structure
// ----------------------------------------------------------------------------
library Accounts {
    struct Account {
        uint timestamp;
        uint index;
        address account;
    }
    struct Data {
        bool initialised;
        mapping(address => Account) entries;
        address[] index;
    }

    event AccountAdded(address owner, address account, uint totalAfter);
    event AccountRemoved(address owner, address account, uint totalAfter);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function hasKey(Data storage self, address account) internal view returns (bool) {
        return self.entries[account].timestamp > 0;
    }
    function add(Data storage self, address owner, address account) internal {
        require(self.entries[account].timestamp == 0);
        self.index.push(account);
        self.entries[account] = Account(block.timestamp, self.index.length - 1, account);
        emit AccountAdded(owner, account, self.index.length);
    }
    function remove(Data storage self, address owner, address account) internal {
        require(self.entries[account].timestamp > 0);
        uint removeIndex = self.entries[account].index;
        emit AccountRemoved(owner, account, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        address lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[account];
        if (self.index.length > 0) {
            self.index.pop();        
            }
    }
    function removeAll(Data storage self, address owner) internal {
        if (self.initialised) {
            while (self.index.length > 0) {
                uint lastIndex = self.index.length - 1;
                address lastIndexKey = self.index[lastIndex];
                emit AccountRemoved(owner, lastIndexKey, lastIndex);
                delete self.entries[lastIndexKey];
                self.index.pop();
            }
        }
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}
// ----------------------------------------------------------------------------
// Attributes Data Structure
// ----------------------------------------------------------------------------
library Attributes {
    struct Value {
        uint timestamp;
        uint index;
        string value;
    }
    struct Data {
        bool initialised;
        mapping(string => Value) entries;
        string[] index;
    }

    event AttributeAdded(uint256 indexed tokenId, string key, string value, uint totalAfter);
    event AttributeRemoved(uint256 indexed tokenId, string key, uint totalAfter);
    event AttributeUpdated(uint256 indexed tokenId, string key, string value);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function hasKey(Data storage self, string memory key) internal view returns (bool) {
        return self.entries[key].timestamp > 0;
    }
    function add(Data storage self, uint256 tokenId, string memory key, string memory value) internal {
        require(self.entries[key].timestamp == 0);
        self.index.push(key);
        self.entries[key] = Value(block.timestamp, self.index.length - 1, value);
        emit AttributeAdded(tokenId, key, value, self.index.length);
    }
    function remove(Data storage self, uint256 tokenId, string memory key) internal {
        require(self.entries[key].timestamp > 0);
        uint removeIndex = self.entries[key].index;
        emit AttributeRemoved(tokenId, key, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        string memory lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[key];
        if (self.index.length > 0) {
            self.index.pop();
        }
    }
    function removeAll(Data storage self, uint256 tokenId) internal {
        if (self.initialised) {
            while (self.index.length > 0) {
                uint lastIndex = self.index.length - 1;
                string memory lastIndexKey = self.index[lastIndex];
                emit AttributeRemoved(tokenId, lastIndexKey, lastIndex);
                delete self.entries[lastIndexKey];
                self.index.pop();
            }
        }
    }
    function setValue(Data storage self, uint256 tokenId, string memory key, string memory value) internal {
        Value storage _value = self.entries[key];
        require(_value.timestamp > 0);
        _value.timestamp = block.timestamp;
        emit AttributeUpdated(tokenId, key, value);
        _value.value = value;
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}

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

contract DreamChannelNFT is MyERC721Metadata {
    using Attributes for Attributes.Data;
    using Attributes for Attributes.Value;
    using Counters for Counters.Counter;
    using Accounts for Accounts.Data;
    using Accounts for Accounts.Account;

    string public constant TYPE_KEY = "type";
    string public constant SUBTYPE_KEY = "subtype";
    string public constant NAME_KEY = "name";
    string public constant DESCRIPTION_KEY = "description";
    string public constant TAGS_KEY = "tags";

    mapping(uint256 => Attributes.Data) private attributesByTokenIds;
    Counters.Counter private _tokenIds;
    mapping(address => Accounts.Data) private secondaryAccounts;

    // Duplicated from Attributes for NFT contract ABI to contain events
    event AttributeAdded(uint256 indexed tokenId, string key, string value, uint totalAfter);
    event AttributeRemoved(uint256 indexed tokenId, string key, uint totalAfter);
    event AttributeUpdated(uint256 indexed tokenId, string key, string value);

    event AccountAdded(address owner, address account, uint totalAfter);
    event AccountRemoved(address owner, address account, uint totalAfter);

    constructor() MyERC721Metadata("DreamChannel NFT", "DCNFT") public {
    }

    // Mint and burn

    /**
     * @dev Mint token
     *
     * @param _to address of token owner
     * @param _type Type of token, mandatory
     * @param _subtype Subtype of token, optional
     * @param _name Name of token, optional
     * @param _description Description of token, optional
     * @param _tags Tags of token, optional
     */
    function mint(address _to, string memory _type, string memory _subtype, string memory _name, string memory _description, string memory _tags) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(_to, newTokenId);

        bytes memory typeInBytes = bytes(_type);
        require(typeInBytes.length > 0);

        Attributes.Data storage attributes = attributesByTokenIds[newTokenId];
        attributes.init();
        attributes.add(newTokenId, TYPE_KEY, _type);

        bytes memory subtypeInBytes = bytes(_subtype);
        if (subtypeInBytes.length > 0) {
            attributes.add(newTokenId, SUBTYPE_KEY, _subtype);
        }

        bytes memory nameInBytes = bytes(_name);
        if (nameInBytes.length > 0) {
            attributes.add(newTokenId, NAME_KEY, _name);
        }

        bytes memory descriptionInBytes = bytes(_description);
        if (descriptionInBytes.length > 0) {
            attributes.add(newTokenId, DESCRIPTION_KEY, _description);
        }

        bytes memory tagsInBytes = bytes(_tags);
        if (tagsInBytes.length > 0) {
            attributes.add(newTokenId, TAGS_KEY, _tags);
        }

        return newTokenId;
    }

    function burn(uint256 tokenId) public {
        _burn(msg.sender, tokenId);
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (attributes.initialised) {
            attributes.removeAll(tokenId);
            delete attributesByTokenIds[tokenId];
        }
    }

    // Attributes
    function numberOfAttributes(uint256 tokenId) public view returns (uint) {
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            return 0;
        } else {
            return attributes.length();
        }
    }

    function getKey(uint256 tokenId, uint _index) public view returns (string memory) {
         Attributes.Data storage attributes = attributesByTokenIds[tokenId];
         if (attributes.initialised) {
             if (_index < attributes.index.length) {
                 return attributes.index[_index];
             }
         }
         return "";
     }

     function getValue(uint256 tokenId, string memory key) public view returns (uint _exists, uint _index, string memory _value) {
         Attributes.Data storage attributes = attributesByTokenIds[tokenId];
         if (!attributes.initialised) {
             return (0, 0, "");
         } else {
             Attributes.Value memory attribute = attributes.entries[key];
             return (attribute.timestamp, attribute.index, attribute.value);
         }
     }
    function getAttributeByIndex(uint256 tokenId, uint256 _index) public view returns (string memory _key, string memory _value, uint timestamp) {
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (attributes.initialised) {
            if (_index < attributes.index.length) {
                string memory key = attributes.index[_index];
                bytes memory keyInBytes = bytes(key);
                if (keyInBytes.length > 0) {
                    Attributes.Value memory attribute = attributes.entries[key];
                    return (key, attribute.value, attribute.timestamp);
                }
            }
        }
        return ("", "", 0);
    }
    function addAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(isOwnerOf(tokenId, msg.sender), "DreamChannelNFT: add attribute of token that is not own");
        require(keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(TYPE_KEY)));
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            attributes.init();
        }
        require(attributes.entries[key].timestamp == 0);
        attributes.add(tokenId, key, value);
    }
    function setAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(isOwnerOf(tokenId, msg.sender), "DreamChannelNFT: set attribute of token that is not own");
        require(keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(TYPE_KEY)));
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            attributes.init();
        }
        if (attributes.entries[key].timestamp > 0) {
            attributes.setValue(tokenId, key, value);
        } else {
            attributes.add(tokenId, key, value);
        }
    }
    function removeAttribute(uint256 tokenId, string memory key) public {
        require(isOwnerOf(tokenId, msg.sender), "DreamChannelNFT: remove attribute of token that is not own");
        require(keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(TYPE_KEY)));
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        require(attributes.initialised);
        attributes.remove(tokenId, key);
    }
    function updateAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(isOwnerOf(tokenId, msg.sender), "DreamChannelNFT: update attribute of token that is not own");
        require(keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(TYPE_KEY)));
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        require(attributes.initialised);
        require(attributes.entries[key].timestamp > 0);
        attributes.setValue(tokenId, key, value);
    }

    function isOwnerOf(uint tokenId, address account) public view returns (bool) {
        address owner = ownerOf(tokenId);
        if (owner == account) {
            return true;
        } else {
            Accounts.Data storage accounts = secondaryAccounts[owner];
            if (accounts.initialised) {
                if (accounts.hasKey(account)) {
                    return true;
                }
            }
        }
        return false;
    }
    function addSecondaryAccount(address account) public {
        require(account != address(0), "DreamChannelNFT: cannot add null secondary account");
        Accounts.Data storage accounts = secondaryAccounts[msg.sender];
        if (!accounts.initialised) {
            accounts.init();
        }
        require(accounts.entries[account].timestamp == 0);
        accounts.add(msg.sender, account);
    }
    function removeSecondaryAccount(address account) public {
        require(account != address(0), "DreamChannelNFT: cannot remove null secondary account");
        Accounts.Data storage accounts = secondaryAccounts[msg.sender];
        require(accounts.initialised);
        accounts.remove(msg.sender, account);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public{
        require(isOwnerOf(tokenId, msg.sender), "DreamChannelNFT: set Token URI of token that is not own");
        _setTokenURI(tokenId, _tokenURI);
    }

    
}