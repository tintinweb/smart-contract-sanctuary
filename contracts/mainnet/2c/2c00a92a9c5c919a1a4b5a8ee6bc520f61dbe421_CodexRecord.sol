pragma solidity 0.4.24;

// File: contracts/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  // bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
  // bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
  // bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
  // bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
  // bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
  // bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
  // bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
  // bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
  // bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;));
  bytes4 constant INTERFACE_ERC721 = 0x80ac58cd;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool indexed _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);

  // Note: This is not in the official ERC-721 standard so it&#39;s not included in the interface hash
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId) public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId) public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data) public;
}

// File: contracts/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  // bytes4(keccak256(&#39;totalSupply()&#39;)) ^
  // bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
  // bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;));
  bytes4 constant INTERFACE_ERC721_ENUMERABLE = 0x780e9d63;

  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  // bytes4(keccak256(&#39;name()&#39;)) ^
  // bytes4(keccak256(&#39;symbol()&#39;)) ^
  // bytes4(keccak256(&#39;tokenURI(uint256)&#39;));
  bytes4 constant INTERFACE_ERC721_METADATA = 0x5b5e139f;

  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
/* solium-disable-next-line no-empty-blocks */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: contracts/ERC165/ERC165.sol

/**
 * @dev A standard for detecting smart contract interfaces.
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
contract ERC165 {

  // bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
  bytes4 constant INTERFACE_ERC165 = 0x01ffc9a7;

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   */
  function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
    return _interfaceID == INTERFACE_ERC165;
  }
}

// File: contracts/library/AddressUtils.sol

/**
 * @title Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * @notice Returns whether there is code in the target address
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address address to check
   * @return whether there is code in the target address
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;

    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }

    return size > 0;
  }
}

// File: contracts/library/SafeMath.sol

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

// File: contracts/ERC721/ERC721Receiver.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   *  after a `safetransfer`. This function MAY throw to revert and reject the
   *  transfer. Returns other than the magic value MUST result in the
   *  transaction being reverted.
   *  Note: the contract address is always the message sender.
   * @param _from The sending address
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data)
    public
    returns(bytes4);
}

// File: contracts/ERC721/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic, ERC165 {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant ERC721_RECEIVED = 0x150b7a02;

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
   * @dev Checks if the smart contract includes a specific interface.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   */
  function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
    return super.supportsInterface(_interfaceID) || _interfaceID == INTERFACE_ERC721;
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
      emit Approval(owner, _to, _tokenId);
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
    emit ApprovalForAll(msg.sender, _to, _approved);
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
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    internalTransferFrom(
      _from,
      _to,
      _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
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
  {
    internalSafeTransferFrom(
      _from,
      _to,
      _tokenId,
      "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   *  the transfer is reverted.
   * @dev Requires the msg sender to be the owner, approved, or operator
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
  {
    internalSafeTransferFrom(
      _from,
      _to,
      _tokenId,
      _data);
  }

  function internalTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address owner = ownerOf(_tokenId);
    require(_from == owner);
    require(_to != address(0));

    address sender = msg.sender;

    require(
      sender == owner || isApprovedForAll(owner, sender) || getApproved(_tokenId) == sender,
      "Not authorized to transfer"
    );

    // Resetting the approved address if it&#39;s set
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }

    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);

    emit Transfer(_from, _to, _tokenId);
  }

  function internalSafeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
  {
    internalTransferFrom(_from, _to, _tokenId);

    require(
      checkAndCallSafeTransfer(
        _from,
        _to,
        _tokenId,
        _data)
    );
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

    bytes4 retval = ERC721Receiver(_to)
      .onERC721Received(
        msg.sender,
        _from,
        _tokenId,
        _data
      );

    return (retval == ERC721_RECEIVED);
  }
}

// File: contracts/ERC721/ERC721Token.sol

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

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
  * @dev Constructor function
  */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

  /**
    * @dev Checks if the smart contract includes a specific interface.
    * @param _interfaceID The interface identifier, as specified in ERC-165.
    */
  function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
    return super.supportsInterface(_interfaceID) || _interfaceID == INTERFACE_ERC721_ENUMERABLE || _interfaceID == INTERFACE_ERC721_METADATA;
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

  function internalTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    internal
  {
    super.internalTransferFrom(_from, _to, _tokenId);

    uint256 removeTokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][removeTokenIndex] = lastToken;
    ownedTokens[_from].length--;
    ownedTokensIndex[lastToken] = removeTokenIndex;

    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = ownedTokens[_to].length - 1;
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
}

// File: contracts/CodexRecordMetadata.sol

/**
 * @title CodexRecordMetadata
 * @dev Storage, mutators, and modifiers for CodexRecord metadata.
 */
contract CodexRecordMetadata is ERC721Token {
  struct CodexRecordData {
    bytes32 nameHash;
    bytes32 descriptionHash;
    bytes32[] fileHashes;
  }

  event Modified(
    address indexed _from,
    uint256 _tokenId,
    bytes32 _newNameHash,
    bytes32 _newDescriptionHash,
    bytes32[] _newFileHashes,
    bytes _data
  );

  // Mapping from token ID to token data
  mapping(uint256 => CodexRecordData) internal tokenData;

  // Global tokenURIPrefix prefix. The token ID will be appended to the uri when accessed
  //  via the tokenURI method
  string public tokenURIPrefix;

  /**
   * @dev Updates token metadata hashes to whatever is passed in
   * @param _tokenId uint256 The token ID
   * @param _newNameHash bytes32 The new sha3 hash of the name
   * @param _newDescriptionHash bytes32 The new sha3 hash of the description
   * @param _newFileHashes bytes32[] The new sha3 hashes of the files associated with the token
   * @param _data (optional) bytes Additional data that will be emitted with the Modified event
   */
  function modifyMetadataHashes(
    uint256 _tokenId,
    bytes32 _newNameHash,
    bytes32 _newDescriptionHash,
    bytes32[] _newFileHashes,
    bytes _data
  )
    public
    onlyOwnerOf(_tokenId)
  {
    // nameHash is only overridden if it&#39;s not a blank string, since name is a
    //  required value. Emptiness is determined if the first element is the null-byte
    if (!bytes32IsEmpty(_newNameHash)) {
      tokenData[_tokenId].nameHash = _newNameHash;
    }

    // descriptionHash can always be overridden since it&#39;s an optional value
    //  (e.g. you can "remove" a description by setting it to a blank string)
    tokenData[_tokenId].descriptionHash = _newDescriptionHash;

    // fileHashes is only overridden if it has one or more value, since at
    //  least one file (i.e. mainImage) is required
    bool containsNullHash = false;
    for (uint i = 0; i < _newFileHashes.length; i++) {
      if (bytes32IsEmpty(_newFileHashes[i])) {
        containsNullHash = true;
        break;
      }
    }
    if (_newFileHashes.length > 0 && !containsNullHash) {
      tokenData[_tokenId].fileHashes = _newFileHashes;
    }

    emit Modified(
      msg.sender,
      _tokenId,
      tokenData[_tokenId].nameHash,
      tokenData[_tokenId].descriptionHash,
      tokenData[_tokenId].fileHashes,
      _data
    );
  }

  /**
   * @dev Gets the token given a token ID.
   * @param _tokenId token ID
   * @return CodexRecordData token data for the given token ID
   */
  function getTokenById(
    uint256 _tokenId
  )
    public
    view
    returns (bytes32 nameHash, bytes32 descriptionHash, bytes32[] fileHashes)
  {
    return (
      tokenData[_tokenId].nameHash,
      tokenData[_tokenId].descriptionHash,
      tokenData[_tokenId].fileHashes
    );
  }

  /**
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist.
   *
   * @dev To save on gas, we will host a standard metadata endpoint for each token.
   *  For Collector privacy, specific token metadata is stored off chain, which means
   *  the metadata returned by this endpoint cannot include specific details about
   *  the physical asset the token represents unless the Collector has made it public.
   *
   * @dev This metadata will be a JSON blob that includes:
   *  name - Codex Record
   *  description - Information about the Provider that is hosting the off-chain metadata
   *  imageUri - A generic Codex Record image
   *
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(
    uint256 _tokenId
  )
    public
    view
    returns (string)
  {
    bytes memory prefix = bytes(tokenURIPrefix);
    if (prefix.length == 0) {
      return "";
    }

    // Rather than store a string representation of _tokenId, we just convert it on the fly
    // since this is just a &#39;view&#39; function (i.e., there&#39;s no gas cost if called off chain)
    bytes memory tokenId = uint2bytes(_tokenId);
    bytes memory output = new bytes(prefix.length + tokenId.length);

    // Index counters
    uint256 i;
    uint256 outputIndex = 0;

    // Copy over the prefix into the new bytes array
    for (i = 0; i < prefix.length; i++) {
      output[outputIndex++] = prefix[i];
    }

    // Copy over the tokenId into the new bytes array
    for (i = 0; i < tokenId.length; i++) {
      output[outputIndex++] = tokenId[i];
    }

    return string(output);
  }

  /**
   * @dev Based on MIT licensed code @ https://github.com/oraclize/ethereum-api
   * @dev Converts an incoming uint256 to a dynamic byte array
   */
  function uint2bytes(uint256 i) internal pure returns (bytes) {
    if (i == 0) {
      return "0";
    }

    uint256 j = i;
    uint256 length;
    while (j != 0) {
      length++;
      j /= 10;
    }

    bytes memory bstr = new bytes(length);
    uint256 k = length - 1;
    j = i;
    while (j != 0) {
      bstr[k--] = byte(48 + j % 10);
      j /= 10;
    }

    return bstr;
  }

  /**
   * @dev Returns whether or not a bytes32 array is empty (all null-bytes)
   * @param _data bytes32 The array to check
   * @return bool Whether or not the array is empty
   */
  function bytes32IsEmpty(bytes32 _data) internal pure returns (bool) {
    for (uint256 i = 0; i < 32; i++) {
      if (_data[i] != 0x0) {
        return false;
      }
    }

    return true;
  }
}

// File: contracts/ERC900/ERC900.sol

/**
 * @title ERC900 Simple Staking Interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract ERC900 {
  event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
  event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

  function stake(uint256 amount, bytes data) public;
  function stakeFor(address user, uint256 amount, bytes data) public;
  function unstake(uint256 amount, bytes data) public;
  function totalStakedFor(address addr) public view returns (uint256);
  function totalStaked() public view returns (uint256);
  function token() public view returns (address);
  function supportsHistory() public pure returns (bool);

  // NOTE: Not implementing the optional functions
  // function lastStakedFor(address addr) public view returns (uint256);
  // function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
  // function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}

// File: contracts/CodexStakeContractInterface.sol

contract CodexStakeContractInterface is ERC900 {

  function stakeForDuration(
    address user,
    uint256 amount,
    uint256 lockInDuration,
    bytes data)
    public;

  function spendCredits(
    address user,
    uint256 amount)
    public;

  function creditBalanceOf(
    address user)
    public
    view
    returns (uint256);
}

// File: contracts/library/DelayedOwnable.sol

/**
 * @title DelayedOwnable
 * @dev The DelayedOwnable contract has an owner address, and provides basic authorization control
 *  functions, this simplifies the implementation of "user permissions".
 * @dev This is different than the original Ownable contract because intializeOwnable
 *  must be specifically called after creation to create an owner.
 */
contract DelayedOwnable {
  address public owner;
  bool public isInitialized = false;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function initializeOwnable(address _owner) external {
    require(
      !isInitialized,
      "The owner has already been set");

    isInitialized = true;
    owner = _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));

    emit OwnershipTransferred(owner, _newOwner);

    owner = _newOwner;
  }
}

// File: contracts/library/DelayedPausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract DelayedPausable is DelayedOwnable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/CodexRecordFees.sol

/**
 * @title CodexRecordFees
 * @dev Storage, mutators, and modifiers for fees when using the token.
 *  This also includes the DelayedPausable contract for the onlyOwner modifier.
 */
contract CodexRecordFees is CodexRecordMetadata, DelayedPausable {

  // Implementation of the ERC20 Codex Protocol Token, used for fees in the contract
  ERC20 public codexCoin;

  // Implementation of the ERC900 Codex Protocol Stake Container,
  //  used to calculate discounts on fees
  CodexStakeContractInterface public codexStakeContract;

  // Address where all contract fees are sent, i.e., the Community Fund
  address public feeRecipient;

  // Fee to create new tokens. 10^18 = 1 token
  uint256 public creationFee = 0;

  // Fee to transfer tokens. 10^18 = 1 token
  uint256 public transferFee = 0;

  // Fee to modify tokens. 10^18 = 1 token
  uint256 public modificationFee = 0;

  modifier canPayFees(uint256 _baseFee) {
    if (feeRecipient != address(0) && _baseFee > 0) {
      bool feePaid = false;

      if (codexStakeContract != address(0)) {
        uint256 discountCredits = codexStakeContract.creditBalanceOf(msg.sender);

        // Regardless of what the baseFee is, all transactions can be paid by using exactly one credit
        if (discountCredits > 0) {
          codexStakeContract.spendCredits(msg.sender, 1);
          feePaid = true;
        }
      }

      if (!feePaid) {
        require(
          codexCoin.transferFrom(msg.sender, feeRecipient, _baseFee),
          "Insufficient funds");
      }
    }

    _;
  }

  /**
   * @dev Sets the address of the ERC20 token used for fees in the contract.
   *  Fees are in the smallest denomination, e.g., 10^18 is 1 token.
   * @param _codexCoin ERC20 The address of the ERC20 Codex Protocol Token
   * @param _feeRecipient address The address where the fees are sent
   * @param _creationFee uint256 The new creation fee.
   * @param _transferFee uint256 The new transfer fee.
   * @param _modificationFee uint256 The new modification fee.
   */
  function setFees(
    ERC20 _codexCoin,
    address _feeRecipient,
    uint256 _creationFee,
    uint256 _transferFee,
    uint256 _modificationFee
  )
    external
    onlyOwner
  {
    codexCoin = _codexCoin;
    feeRecipient = _feeRecipient;
    creationFee = _creationFee;
    transferFee = _transferFee;
    modificationFee = _modificationFee;
  }

  function setStakeContract(CodexStakeContractInterface _codexStakeContract) external onlyOwner {
    codexStakeContract = _codexStakeContract;
  }
}

// File: contracts/CodexRecordCore.sol

/**
 * @title CodexRecordCore
 * @dev Core functionality of the token, namely minting.
 */
contract CodexRecordCore is CodexRecordFees {

  /**
   * @dev This event is emitted when a new token is minted and allows providers
   *  to discern which Minted events came from transactions they submitted vs
   *  transactions submitted by other platforms, as well as providing information
   *  about what metadata record the newly minted token should be associated with.
   */
  event Minted(uint256 _tokenId, bytes _data);

  /**
   * @dev Sets the global tokenURIPrefix for use when returning token metadata.
   *  Only callable by the owner.
   * @param _tokenURIPrefix string The new tokenURIPrefix
   */
  function setTokenURIPrefix(string _tokenURIPrefix) external onlyOwner {
    tokenURIPrefix = _tokenURIPrefix;
  }

  /**
   * @dev Creates a new token
   * @param _to address The address the token will get transferred to after minting
   * @param _nameHash bytes32 The sha3 hash of the name
   * @param _descriptionHash bytes32 The sha3 hash of the description
   * @param _data (optional) bytes Additional data that will be emitted with the Minted event
   */
  function mint(
    address _to,
    bytes32 _nameHash,
    bytes32 _descriptionHash,
    bytes32[] _fileHashes,
    bytes _data
  )
    public
  {
    // All new tokens will be the last entry in the array
    uint256 newTokenId = allTokens.length;
    internalMint(_to, newTokenId);

    // Add metadata to the newly created token
    tokenData[newTokenId] = CodexRecordData({
      nameHash: _nameHash,
      descriptionHash: _descriptionHash,
      fileHashes: _fileHashes
    });

    emit Minted(newTokenId, _data);
  }

  function internalMint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));

    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);

    ownedTokensIndex[_tokenId] = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);

    allTokens.push(_tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }
}

// File: contracts/CodexRecordAccess.sol

/**
 * @title CodexRecordAccess
 * @dev Override contract functions
 */
contract CodexRecordAccess is CodexRecordCore {

  /**
   * @dev Make mint() pausable
   */
  function mint(
    address _to,
    bytes32 _nameHash,
    bytes32 _descriptionHash,
    bytes32[] _fileHashes,
    bytes _data
  )
    public
    whenNotPaused
    canPayFees(creationFee)
  {
    return super.mint(
      _to,
      _nameHash,
      _descriptionHash,
      _fileHashes,
      _data);
  }

  /**
   * @dev Make trasferFrom() pausable
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    whenNotPaused
    canPayFees(transferFee)
  {
    return super.transferFrom(
      _from,
      _to,
      _tokenId);
  }

  /**
   * @dev Make safeTrasferFrom() pausable
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    whenNotPaused
    canPayFees(transferFee)
  {
    return super.safeTransferFrom(
      _from,
      _to,
      _tokenId);
  }

  /**
   * @dev Make safeTrasferFrom() pausable
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    whenNotPaused
    canPayFees(transferFee)
  {
    return super.safeTransferFrom(
      _from,
      _to,
      _tokenId,
      _data
    );
  }

  /**
   * @dev Make modifyMetadataHashes() pausable
   */
  function modifyMetadataHashes(
    uint256 _tokenId,
    bytes32 _newNameHash,
    bytes32 _newDescriptionHash,
    bytes32[] _newFileHashes,
    bytes _data
  )
    public
    whenNotPaused
    canPayFees(modificationFee)
  {
    return super.modifyMetadataHashes(
      _tokenId,
      _newNameHash,
      _newDescriptionHash,
      _newFileHashes,
      _data);
  }
}

// File: contracts/CodexRecord.sol

/**
 * @title CodexRecord, an ERC721 token for arts & collectables
 * @dev Developers should never interact with this smart contract directly!
 *  All transactions/calls should be made through CodexRecordProxy. Storage will be maintained
 *  in that smart contract so that the governing body has the ability
 *  to upgrade the contract in the future in the event of an emergency or new functionality.
 */
contract CodexRecord is CodexRecordAccess {
  /**
   * @dev Constructor function
   */
  constructor() public ERC721Token("Codex Record", "CR") { }

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
  }
}