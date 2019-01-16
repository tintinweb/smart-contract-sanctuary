pragma solidity ^0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

// File: node_modules/openzeppelin-solidity/contracts/introspection/ERC165.sol

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

// File: node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {
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

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: contracts/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the 
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

// File: node_modules/openzeppelin-solidity/contracts/AddressUtils.sol

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

// File: node_modules/openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol

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

// File: contracts/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
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

    bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
    /*
    * 0x4f558e79 ===
    *   bytes4(keccak256(&#39;exists(uint256)&#39;))
    */

    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

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
        require(isApprovedOrOwner(msg.sender, _tokenId)); //, "canTransfer"
        _;
    }

    constructor()
        public
    {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256);

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
    * @param _tokenId uint256 ID of the token to query the existence of
    * @return whether the token exists
    */
    function exists(uint256 _tokenId) public view returns (bool) {
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
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner); //, "_to eq owner"
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    /**
    * @dev Gets the approved address for a token ID, or zero if no address set
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return address currently approved for the given token ID
    */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
    * @dev Sets or unsets the approval of a given operator
    * An operator is allowed to transfer all tokens of the sender on their behalf
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
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
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
        canTransfer(_tokenId)
    {
        require(_from != address(0)); //, "transferFrom 1"
        require(_to != address(0)); //, "transferFrom 2"

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
        canTransfer(_tokenId)
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
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * Reverts if the token does not exist
    * @param _tokenId uint256 ID of the token being burned by the msg.sender
    */
    function _burn(address _owner, uint256 _tokenId) internal {
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
        require(ownerOf(_tokenId) == _owner); //, "clearApproval"
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
        }
    }

    /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0)); //, "addTokenTo"
        tokenOwner[_tokenId] = _to;
    }

    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from); //, "removeTokenFrom"
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
        bytes _data
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

// File: contracts/IEntityStorage.sol

interface IEntityStorage {
    function storeBulk(uint256[] _tokenIds, uint256[] _attributes) external;
    function store(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds) external;
    function remove(uint256 _tokenId) external;
    function list() external view returns (uint256[] tokenIds);
    function getAttributes(uint256 _tokenId) external view returns (uint256 attrs, uint256[] compIds);
    function updateAttributes(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds) external;
    function totalSupply() external view returns (uint256);
}

// File: contracts/ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md Customized to support non-transferability.
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

    IEntityStorage internal cbStorage;

    bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
    /**
    * 0x780e9d63 ===
    *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
    *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
    */

    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    /**
    * 0x5b5e139f ===
    *   bytes4(keccak256(&#39;name()&#39;)) ^
    *   bytes4(keccak256(&#39;symbol()&#39;)) ^
    *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
    */

    string internal uriPrefix;

    // Token name
    string internal name_;

    // Token symbol
    string internal symbol_;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;
    
    // Array with transferable Tokens
    uint256[] internal transferableTokens;

    /**
    * @dev Constructor function
    */
    constructor(string _name, string _symbol, string _uriPrefix, address _storage) public {
        require(_storage != address(0), "Storage Address is required");
        name_ = _name;
        symbol_ = _symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721Enumerable);
        _registerInterface(InterfaceId_ERC721Metadata);
        cbStorage = IEntityStorage(_storage);
        uriPrefix = _uriPrefix;
    }

    /**
    * @dev Gets the token name
    * @return string representing the token name
    */
    function name() external view returns (string) {
        return name_;
    }

    /**
    * @dev Gets the token symbol
    * @return string representing the token symbol
    */
    function symbol() external view returns (string) {
        return symbol_;
    }

    /**
    * @dev Returns an URI for a given token ID
    * Throws if the token ID does not exist. May return an empty string.
    * @param _tokenId uint256 ID of the token to query
    */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return strConcat(uriPrefix, uintToString(_tokenId));
    }

    /**
    * @dev Gets the total amount of tokens stored by the contract
    * @return uint256 representing the total amount of tokens
    */
    function totalSupply() public view returns (uint256) {
        return cbStorage.totalSupply();
    }

    /**
    * @dev Internal function to add a token ID to the list owned by a given address
    * @param _to address representing the new owner of the token ID
    * @param _tokenId uint256 ID of the token to be added 
    */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        ownedTokens[_to].push(_tokenId);
    }

    /**
    * @dev Internal function to remove a token ID from the list owned by a given address
    * @param _from address representing the previous owner of the token ID
    * @param _tokenId uint256 ID of the token to be removed
    */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = 0;
        while (ownedTokens[_from][tokenIndex] != _tokenId && tokenIndex < ownedTokens[_from].length) {
            tokenIndex++;
        }
        // Reorg allTokens array
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].length--;
    }

    /**
    * @dev Internal function to burn a specific token
    * Reverts if the token does not exist, or is marked transferable
    * @param _owner owner address of the token being burned
    * @param _tokenId uint256 ID of the token being burned 
    */
    function _burn(address _owner, uint256 _tokenId) internal {
        // cannot burn a token that is up for sale
        require(!isTransferable(_tokenId)); //, "_burn"
        super._burn(_owner, _tokenId);
        cbStorage.remove(_tokenId);
    }

    /**
    * @dev Gets the number of tokens owned by the specified address
    * @param _owner address of the token owner
    * @return uint256 the number of tokens owned 
    */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokens[_owner].length;
    }

        /**
    * @dev List all token Ids that can be transfered
    * @return array of token IDs
    */
    function listTransferableTokens() public view returns(uint256[]) {
        return transferableTokens;
    } 

    /**
    * @dev Is Token Transferable
    * @param _tokenId uint256 ID of the token
    * @return bool is tokenId transferable 
    */
    function isTransferable(uint256 _tokenId) public view returns (bool) {
        for (uint256 index = 0; index < transferableTokens.length; index++) {
            if (transferableTokens[index] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Returns whether the given spender can transfer a given token ID
    * @param _spender address of the spender to query
    * @param _tokenId uint256 ID of the token to be transferred
    * @return bool whether the token is transferable and msg.sender is approved for the given token ID,
    *  is an operator of the owner, or is the owner of the token
    */
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        if (isTransferable(_tokenId)) {
            return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
        }
        return false;
    }

    /**
    * Converts a uint, such aa a token ID number, to a string
    */
    function uintToString(uint v) internal pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    /**
    * Basic smashing together of strings.
    */
    function strConcat(string _a, string _b)internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory ba = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) ba[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) ba[k++] = _bb[i];
        return string(ba);
    }
}

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;
    
    // mapping for creature Type to Sale
    address[] internal controllers;
    //mapping(address => address) internal controllers;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }
   
    /**
    * @dev Throws if called by any account that&#39;s not a superuser.
    */
    modifier onlyController() {
        require(isController(msg.sender), "only Controller");
        _;
    }

    modifier onlyOwnerOrController() {
        require(msg.sender == owner || isController(msg.sender), "only Owner Or Controller");
        _;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "sender address must be the owner&#39;s address");
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner, "new owner address must not be the owner&#39;s address");
        newOwner = _newOwner;
    }

    /**
    * @dev Allows the new owner to confirm that they are taking control of the contract..tr
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "sender address must not be the new owner&#39;s address");
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }

    function isController(address _controller) internal view returns(bool) {
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                return true;
            }
        }
        return false;
    }

    function getControllers() public onlyOwner view returns(address[]) {
        return controllers;
    }

    /**
    * @dev Allows a new controllers to be added
    * @param _controller The address controller.
    */
    function addController(address _controller) public onlyOwner {
        require(address(0) != _controller, "controller address must not be 0");
        require(_controller != owner, "controller address must not be the owner&#39;s address");
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                return;
            }
        }
        controllers.push(_controller);
    }

    /**
    * @dev Allows a new controllers to be added
    * @param _controller The address controller.
    */
    function removeController(address _controller) public onlyOwner {
        require(address(0) != _controller, "controller address must not be 0");
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                delete controllers[index];
            }
        }
    }
}

// File: contracts/ICryptoBeastiesToken.sol

interface ICryptoBeastiesToken {
    function bulk(uint256[] _tokenIds, uint256[] _attributes, address[] _owners) external;
    function create(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds, address _owner) external;
    function tokensOfOwner(address _owner) external view returns (uint256[] tokens);
    function getProperties(uint256 _tokenId) external view returns (uint256 attrs, uint256[] compIds); 
    function updateAttributes(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds) external; 
    function updateStorage(address _storage) external;
    function listTokens() external view returns (uint256[] tokens);
    function setURI(string _uriPrefix) external;
    function setTransferable(uint256 _tokenId) external;
    function removeTransferable(uint256 _tokenId) external;
}

// File: contracts/CryptoBeastiesToken.sol

/**
 * @title CryptoBeasties Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard,
 * plus references a separate storage contract for recording the game-specific data for each token. 
 */
contract CryptoBeastiesToken is ERC721Token, Ownable, ICryptoBeastiesToken { 
    using SafeMath for uint256;

    address proxyRegistryAddress;

    /**
    * @dev Constructor function
    * @param _storage address for Creature Storage
    * @param _uriPrefix string for url prefix
    */
    constructor(address _storage, string _uriPrefix) 
        ERC721Token("CryptoBeasties Token", "CRYB", _uriPrefix, _storage) public {
        proxyRegistryAddress = address(0);
    }

    /**
    * @dev Set a Proxy Registry Address, to be used by 3rd-party marketplaces.
    * @param _proxyRegistryAddress Address of the marketplace&#39;s proxy registry address
    */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwnerOrController {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
    * @dev Bulk load a number of tokens, as a way of reducing gas fees and migration time.
    * @param _tokenIds Array of tokenIds
    * @param _attributes Matching array of CryptoBeasties attributes
    * @param _owners Matching array of token owner addresses
    */
    function bulk(uint256[] _tokenIds, uint256[] _attributes, address[] _owners) external onlyOwnerOrController {
        for (uint index = 0; index < _tokenIds.length; index++) {
            ownedTokens[_owners[index]].push(_tokenIds[index]);
            tokenOwner[_tokenIds[index]] = _owners[index];
            emit Transfer(address(0), _owners[index], _tokenIds[index]);
        }
        cbStorage.storeBulk(_tokenIds, _attributes);
    }

    /**
    * @dev Create CryptoBeasties Token 
    * @param _tokenId ID of the new token
    * @param _attributes CryptoBeasties attributes
    * @param _owner address of the token owner
    */
    function create(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds, address _owner) external onlyOwnerOrController {
        require(!super.exists(_tokenId));
        require(_owner != address(0));
        require(_attributes > 0); 
        super._mint(_owner, _tokenId);
        cbStorage.store(_tokenId, _attributes, _componentIds);
    }

   /**
   * Override isApprovedForAll to whitelist a 3rd-party marketplace&#39;s proxy accounts to enable gas-less listings.
   */
    function isApprovedForAll(
        address owner,
        address operator
    )
    public
    view
    returns (bool)
    {
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (proxyRegistry.proxies(owner) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
    * @dev List all token ids for a owner
    * @param _owner address of the token owner
    */
    function tokensOfOwner(address _owner) external view returns (uint256[]) {
        return ownedTokens[_owner];
    }
    
    /**
    * @dev List all token ids, an array of their attributes and an array componentIds (i.e. PowerStones)
    * @param _owner address for the given token ID
    */
    function getOwnedTokenData(
        address _owner
        ) 
        public 
        view 
        returns 
        (
            uint256[] tokens, 
            uint256[] attrs, 
            uint256[] componentIds, 
            bool[] isTransferable
        ) {

        uint256[] memory tokenIds = this.tokensOfOwner(_owner);
        uint256[] memory attribs = new uint256[](tokenIds.length);
        uint256[] memory firstCompIds = new uint256[](tokenIds.length);
        bool[] memory transferable = new bool[](tokenIds.length);
        
        uint256[] memory compIds;

        for (uint i = 0; i < tokenIds.length; i++) {
            (attribs[i], compIds) = cbStorage.getAttributes(tokenIds[i]);
            transferable[i] = this.isTransferable(tokenIds[i]);
            if (compIds.length > 0)
            {
                firstCompIds[i] = compIds[0];
            }
        }
        return (tokenIds, attribs, firstCompIds, transferable);
    }

    /**
    * @dev Get attributes and Component Ids (i.e. PowerStones) CryptoBeastie
    * @param _tokenId uint256 for the given token
    */
    function getProperties(uint256 _tokenId) external view returns (uint256 attrs, uint256[] compIds) {
        return cbStorage.getAttributes(_tokenId);
    }

    /**
    * @dev attributes and Component Ids (i.e. PowerStones) CryptoBeastie
    * @param _tokenId uint256 for the given token
    * @param _attributes Cryptobeasties attributes
    * @param _componentIds Array of Cryptobeasties componentIds (i.e. PowerStones)
    */
    function updateAttributes(uint256 _tokenId, uint256 _attributes, uint256[] _componentIds) external {
        require(ownerOf(_tokenId) == msg.sender || owner == msg.sender || isController(msg.sender)); //, "token owner"
        cbStorage.updateAttributes(_tokenId, _attributes, _componentIds);
    }

    /**
    * @dev Update the reference to the CryptoBeasties storage contract
    * @param _storage address for CryptoBeasties storage contract
    */
    function updateStorage(address _storage) external  onlyOwnerOrController {
        cbStorage = IEntityStorage(_storage);
    }

    /**
    * @dev List all of the CryptoBeasties token Ids held in the Storage Contract
    */
    function listTokens() external view returns (uint256[] tokens) {
        return cbStorage.list();
    }

    /**
    * @dev Update the URI prefix
    * @param _uriPrefix string for url prefix
    */
    function setURI(string _uriPrefix) external onlyOwnerOrController {
        uriPrefix = _uriPrefix;
    }

    /**
    * @dev Bulk setup of token Ids that can be transferred
    * @param _tokenIds array of token Ids that will be set for transfer
    */
    function bulkTransferable(uint256[] _tokenIds) external {
        address _owner = ownerOf(_tokenIds[0]);
        require(_owner == msg.sender || owner == msg.sender || isController(msg.sender)); //, "token owner"
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            if (_owner == msg.sender) {
                require(ownerOf(_tokenIds[index]) == _owner); //, "token owner"
            } 
            transferableTokens.push(_tokenIds[index]);
        }
    }

    /**
    * @dev Set a Token Id that can be transfer
    * @param _tokenId Token Id that will be set for transfer
    */
    function setTransferable(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender || owner == msg.sender || isController(msg.sender)); //, "token owner"
        transferableTokens.push(_tokenId);
    }

    /**
    * @dev Bulk remove transferability of token Ids
    * @param _tokenIds array of token Ids that will be removed for transfer
    */
    function bulkRemoveTransferable(uint256[] _tokenIds) external {
        address _owner = ownerOf(_tokenIds[0]);
        require(_owner == msg.sender || owner == msg.sender || isController(msg.sender)); //, "token owner"
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            if (_owner == msg.sender) {
                require(ownerOf(_tokenIds[index]) == _owner); //, "token owner"
            }
            _removeTransfer(_tokenIds[index]);
        }
    }

    /**
    * @dev A token Id that will be removed from transfer
    * @param _tokenId Token Id that will be removed for transfer
    */
    function removeTransferable(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender || owner == msg.sender || isController(msg.sender)); //, "token owner"
        _removeTransfer(_tokenId);
    }

    /**
    * @dev Internal function to remove transferability of a token Id
    * @param _tokenId Token Id that will be removed for Transfer
    */
    function _removeTransfer(uint256 _tokenId) internal {
        uint256 tokenIndex = 0;
        while (transferableTokens[tokenIndex] != _tokenId && tokenIndex < transferableTokens.length) {
            tokenIndex++;
        }

        // Reorg allTokens array
        uint256 lastTokenIndex = transferableTokens.length.sub(1);
        uint256 lastToken = transferableTokens[lastTokenIndex];

        transferableTokens[tokenIndex] = lastToken;
        transferableTokens[lastTokenIndex] = 0;

        transferableTokens.length--;
    }

    /**
    * @dev Support merging multiple tokens into one, to increase XP and level-up the target.
    * @param _mergeTokenIds Array of tokens to be removed and merged into the target
    * @param _targetTokenId The token whose attributes will be improved by the merge
    * @param _targetAttributes The new improved attributes for the target token
    */
    function mergeTokens(uint256[] _mergeTokenIds, uint256 _targetTokenId, uint256 _targetAttributes) external {
        address _owner = ownerOf(_targetTokenId);
        require(_owner == msg.sender || owner == msg.sender || isController(msg.sender)); //, "token owner"
        require(_mergeTokenIds.length > 0); //, "mergeTokens"
        require(!isTransferable(_targetTokenId)); // cannot target a token that is up for sale


        // remove merge material tokens
        for (uint256 index = 0; index < _mergeTokenIds.length; index++) {
            require(ownerOf(_mergeTokenIds[index]) == _owner); //, "array"
            _burn(_owner, _mergeTokenIds[index]);
        }

        // update target token
        uint256 attribs;
        uint256[] memory compIds;
        (attribs, compIds) = cbStorage.getAttributes(_targetTokenId);
        cbStorage.updateAttributes(_targetTokenId, _targetAttributes, compIds);
    }
}

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}