pragma solidity ^0.4.24;

// File: openzeppelin-zos/contracts/introspection/ERC165.sol

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

// File: openzeppelin-zos/contracts/token/ERC721/ERC721Basic.sol

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

// File: openzeppelin-zos/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
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

// File: openzeppelin-zos/contracts/token/ERC721/ERC721Receiver.sol

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

// File: openzeppelin-zos/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: openzeppelin-zos/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
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
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: openzeppelin-zos/contracts/introspection/ERC165Support.sol

/**
 * @title ERC165Support
 * @dev Implements ERC165 returning true for ERC165 interface identifier
 */
contract ERC165Support is ERC165 {

  bytes4 internal constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool) 
  {
    return _supportsInterface(_interfaceId);
  }

  function _supportsInterface(bytes4 _interfaceId)
    internal
    view
    returns (bool) 
  {
    return _interfaceId == InterfaceId_ERC165;
  }
}

// File: openzeppelin-zos/contracts/token/ERC721/ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC165Support, ERC721Basic {

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
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  function _supportsInterface(bytes4 _interfaceId)
    internal
    view
    returns (bool)
  {
    return super._supportsInterface(_interfaceId) || 
      _interfaceId == InterfaceId_ERC721 || _interfaceId == InterfaceId_ERC721Exists;
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
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
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

// File: zos-lib/contracts/migrations/Migratable.sol

/**
 * @title Migratable
 * Helper contract to support intialization and migration schemes between
 * different implementations of a contract in the context of upgradeability.
 * To use it, replace the constructor with a function that has the
 * `isInitializer` modifier starting with `"0"` as `migrationId`.
 * When you want to apply some migration code during an upgrade, increase
 * the `migrationId`. Or, if the migration code must be applied only after
 * another migration has been already applied, use the `isMigration` modifier.
 * This helper supports multiple inheritance.
 * WARNING: It is the developer&#39;s responsibility to ensure that migrations are
 * applied in a correct order, or that they are run at all.
 * See `Initializable` for a simpler version.
 */
contract Migratable {
  /**
   * @dev Emitted when the contract applies a migration.
   * @param contractName Name of the Contract.
   * @param migrationId Identifier of the migration applied.
   */
  event Migrated(string contractName, string migrationId);

  /**
   * @dev Mapping of the already applied migrations.
   * (contractName => (migrationId => bool))
   */
  mapping (string => mapping (string => bool)) internal migrated;

  /**
   * @dev Internal migration id used to specify that a contract has already been initialized.
   */
  string constant private INITIALIZED_ID = "initialized";


  /**
   * @dev Modifier to use in the initialization function of a contract.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  modifier isInitializer(string contractName, string migrationId) {
    validateMigrationIsPending(contractName, INITIALIZED_ID);
    validateMigrationIsPending(contractName, migrationId);
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
    migrated[contractName][INITIALIZED_ID] = true;
  }

  /**
   * @dev Modifier to use in the migration of a contract.
   * @param contractName Name of the contract.
   * @param requiredMigrationId Identifier of the previous migration, required
   * to apply new one.
   * @param newMigrationId Identifier of the new migration to be applied.
   */
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId), "Prerequisite migration ID has not been run yet");
    validateMigrationIsPending(contractName, newMigrationId);
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

  /**
   * @dev Returns true if the contract migration was applied.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   * @return true if the contract migration was applied, false otherwise.
   */
  function isMigrated(string contractName, string migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }

  /**
   * @dev Initializer that marks the contract as initialized.
   * It is important to run this if you had deployed a previous version of a Migratable contract.
   * For more information see https://github.com/zeppelinos/zos-lib/issues/158.
   */
  function initialize() isInitializer("Migratable", "1.2.1") public {
  }

  /**
   * @dev Reverts if the requested migration was already executed.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  function validateMigrationIsPending(string contractName, string migrationId) private view {
    require(!isMigrated(contractName, migrationId), "Requested target migration ID has already been run");
  }
}

// File: openzeppelin-zos/contracts/token/ERC721/ERC721Token.sol

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is Migratable, ERC165Support, ERC721BasicToken, ERC721 {

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

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

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
  function initialize(string _name, string _symbol) public isInitializer("ERC721Token", "1.9.0") {
    name_ = _name;
    symbol_ = _symbol;
  }

  function _supportsInterface(bytes4 _interfaceId)
    internal
    view
    returns (bool)
  {
    return super._supportsInterface(_interfaceId) || 
      _interfaceId == InterfaceId_ERC721Enumerable || _interfaceId == InterfaceId_ERC721Metadata;
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
    return tokenURIs[_tokenId];
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
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

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
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

// File: openzeppelin-zos/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Migratable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function initialize(address _sender) public isInitializer("Ownable", "1.9.0") {
    owner = _sender;
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/estate/IEstateRegistry.sol

contract IEstateRegistry {
  function mint(address to, string metadata) external returns (uint256);
  function ownerOf(uint256 _tokenId) public view returns (address _owner); // from ERC721

  // Events

  event CreateEstate(
    address indexed _owner,
    uint256 indexed _estateId,
    string _data
  );

  event AddLand(
    uint256 indexed _estateId,
    uint256 indexed _landId
  );

  event RemoveLand(
    uint256 indexed _estateId,
    uint256 indexed _landId,
    address indexed _destinatary
  );

  event Update(
    uint256 indexed _assetId,
    address indexed _holder,
    address indexed _operator,
    string _data
  );

  event UpdateOperator(
    uint256 indexed _estateId,
    address indexed _operator
  );

  event SetLANDRegistry(
    address indexed _registry
  );
}

// File: contracts/estate/EstateStorage.sol

contract LANDRegistry {
  function decodeTokenId(uint value) external pure returns (int, int);
  function updateLandData(int x, int y, string data) external;
  function ping() public;
  function ownerOf(uint256 tokenId) public returns (address);
  function safeTransferFrom(address, address, uint256) public;
}


contract EstateStorage {
  bytes4 internal constant InterfaceId_GetMetadata = bytes4(keccak256("getMetadata(uint256)"));
  bytes4 internal constant InterfaceId_VerifyFingerprint = bytes4(
    keccak256("verifyFingerprint(uint256,bytes)")
  );

  LANDRegistry public registry;

  // From Estate to list of owned LAND ids (LANDs)
  mapping(uint256 => uint256[]) public estateLandIds;

  // From LAND id (LAND) to its owner Estate id
  mapping(uint256 => uint256) public landIdEstate;

  // From Estate id to mapping of LAND id to index on the array above (estateLandIds)
  mapping(uint256 => mapping(uint256 => uint256)) public estateLandIndex;

  // Metadata of the Estate
  mapping(uint256 => string) internal estateData;

  // Operator of the Estate
  mapping (uint256 => address) internal updateOperator;
}

// File: contracts/estate/EstateRegistry.sol

/**
 * @title ERC721 registry of every minted Estate and their owned LANDs
 * @dev Usings we are inheriting and depending on:
 * From ERC721Token:
 *   - using SafeMath for uint256;
 *   - using AddressUtils for address;
 */
// solium-disable-next-line max-len
contract EstateRegistry is Migratable, IEstateRegistry, ERC721Token, ERC721Receiver, Ownable, EstateStorage {
  modifier canTransfer(uint256 estateId) {
    require(isApprovedOrOwner(msg.sender, estateId), "Only owner or operator can transfer");
    _;
  }

  modifier onlyRegistry() {
    require(msg.sender == address(registry), "Only the registry can make this operation");
    _;
  }

  modifier onlyUpdateAuthorized(uint256 estateId) {
    require(_isUpdateAuthorized(msg.sender, estateId), "Unauthorized user");
    _;
  }

  /**
   * @dev Mint a new Estate with some metadata
   * @param to The address that will own the minted token
   * @param metadata Set an initial metadata
   * @return An uint256 representing the new token id
   */
  function mint(address to, string metadata) external onlyRegistry returns (uint256) {
    return _mintEstate(to, metadata);
  }

  /**
   * @notice Transfer a LAND owned by an Estate to a new owner
   * @param estateId Current owner of the token
   * @param landId LAND to be transfered
   * @param destinatary New owner
   */
  function transferLand(
    uint256 estateId,
    uint256 landId,
    address destinatary
  )
    external
    canTransfer(estateId)
  {
    return _transferLand(estateId, landId, destinatary);
  }

  /**
   * @notice Transfer many tokens owned by an Estate to a new owner
   * @param estateId Current owner of the token
   * @param landIds LANDs to be transfered
   * @param destinatary New owner
   */
  function transferManyLands(
    uint256 estateId,
    uint256[] landIds,
    address destinatary
  )
    external
    canTransfer(estateId)
  {
    uint length = landIds.length;
    for (uint i = 0; i < length; i++) {
      _transferLand(estateId, landIds[i], destinatary);
    }
  }

  /**
   * @notice Get the Estate id for a given LAND id
   * @dev This information also lives on estateLandIds,
   *   but it being a mapping you need to know the Estate id beforehand.
   * @param landId LAND to search
   * @return The corresponding Estate id
   */
  function getLandEstateId(uint256 landId) external view returns (uint256) {
    return landIdEstate[landId];
  }

  function setLANDRegistry(address _registry) external onlyOwner {
    require(_registry.isContract(), "The LAND registry address should be a contract");
    require(_registry != 0, "The LAND registry address should be valid");
    registry = LANDRegistry(_registry);
    emit SetLANDRegistry(registry);
  }

  function ping() external {
    registry.ping();
  }

  /**
   * @notice Return the amount of tokens for a given Estate
   * @param estateId Estate id to search
   * @return Tokens length
   */
  function getEstateSize(uint256 estateId) external view returns (uint256) {
    return estateLandIds[estateId].length;
  }

  /**
   * @notice Update the metadata of an Estate
   * @dev Reverts if the Estate does not exist or the user is not authorized
   * @param estateId Estate id to update
   * @param metadata string metadata
   */
  function updateMetadata(
    uint256 estateId,
    string metadata
  )
    external
    onlyUpdateAuthorized(estateId)
  {
    _updateMetadata(estateId, metadata);

    emit Update(
      estateId,
      ownerOf(estateId),
      msg.sender,
      metadata
    );
  }

  function getMetadata(uint256 estateId) external view returns (string) {
    return estateData[estateId];
  }

  function setUpdateOperator(uint256 estateId, address operator) external canTransfer(estateId) {
    updateOperator[estateId] = operator;
    emit UpdateOperator(estateId, operator);
  }

  function isUpdateAuthorized(address operator, uint256 estateId) external view returns (bool) {
    return _isUpdateAuthorized(operator, estateId);
  }

  function initialize(
    string _name,
    string _symbol,
    address _registry
  )
    public
    isInitializer("EstateRegistry", "0.0.2")
  {
    require(_registry != 0, "The registry should be a valid address");

    ERC721Token.initialize(_name, _symbol);
    Ownable.initialize(msg.sender);
    registry = LANDRegistry(_registry);
  }

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
    bytes _data
  )
    public
    onlyRegistry
    returns (bytes4)
  {
    uint256 estateId = _bytesToUint(_data);
    _pushLandId(estateId, _tokenId);
    return ERC721_RECEIVED;
  }

  /**
   * @dev Creates a checksum of the contents of the Estate
   * @param estateId the estateId to be verified
   */
  function getFingerprint(uint256 estateId)
    public
    view
    returns (bytes32 result)
  {
    result = keccak256(abi.encodePacked("estateId", estateId));

    uint256 length = estateLandIds[estateId].length;
    for (uint i = 0; i < length; i++) {
      result ^= keccak256(abi.encodePacked(estateLandIds[estateId][i]));
    }
    return result;
  }

  /**
   * @dev Verifies a checksum of the contents of the Estate
   * @param estateId the estateid to be verified
   * @param fingerprint the user provided identification of the Estate contents
   */
  function verifyFingerprint(uint256 estateId, bytes fingerprint) public view returns (bool) {
    return getFingerprint(estateId) == _bytesToBytes32(fingerprint);
  }

  /**
   * @dev Safely transfers the ownership of multiple Estate IDs to another address
   * @dev Delegates to safeTransferFrom for each transfer
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param estateIds uint256 array of IDs to be transferred
  */
  function safeTransferManyFrom(address from, address to, uint256[] estateIds) public {
    safeTransferManyFrom(
      from,
      to,
      estateIds,
      ""
    );
  }

  /**
   * @dev Safely transfers the ownership of multiple Estate IDs to another address
   * @dev Delegates to safeTransferFrom for each transfer
   * @dev Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param estateIds uint256 array of IDs to be transferred
   * @param data bytes data to send along with a safe transfer check
  */
  function safeTransferManyFrom(
    address from,
    address to,
    uint256[] estateIds,
    bytes data
  )
    public
  {
    for (uint i = 0; i < estateIds.length; i++) {
      safeTransferFrom(
        from,
        to,
        estateIds[i],
        data
      );
    }
  }

  /**
   * @dev update LAND data owned by an Estate
   * @param estateId Estate
   * @param landId LAND to be updated
   * @param data string metadata
   */
  function updateLandData(uint256 estateId, uint256 landId, string data) public {
    _updateLandData(estateId, landId, data);
  }

  /**
   * @dev update LANDs data owned by an Estate
   * @param estateId Estate id
   * @param landIds LANDs to be updated
   * @param data string metadata
   */
  function updateManyLandData(uint256 estateId, uint256[] landIds, string data) public {
    uint length = landIds.length;
    for (uint i = 0; i < length; i++) {
      _updateLandData(estateId, landIds[i], data);
    }
  }

  // check the supported interfaces via ERC165
  function _supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
    // solium-disable-next-line operator-whitespace
    return super._supportsInterface(_interfaceId) ||
      _interfaceId == InterfaceId_GetMetadata ||
      _interfaceId == InterfaceId_VerifyFingerprint;
  }

  /**
   * @dev Internal function to mint a new Estate with some metadata
   * @param to The address that will own the minted token
   * @param metadata Set an initial metadata
   * @return An uint256 representing the new token id
   */
  function _mintEstate(address to, string metadata) internal returns (uint256) {
    require(to != address(0), "You can not mint to an empty address");
    uint256 estateId = _getNewEstateId();
    _mint(to, estateId);
    _updateMetadata(estateId, metadata);
    emit CreateEstate(to, estateId, metadata);
    return estateId;
  }

  /**
   * @dev Internal function to update an Estate metadata
   * @dev Does not require the Estate to exist, for a public interface use `updateMetadata`
   * @param estateId Estate id to update
   * @param metadata string metadata
   */
  function _updateMetadata(uint256 estateId, string metadata) internal {
    estateData[estateId] = metadata;
  }

  /**
   * @notice Return a new unique id
   * @dev It uses totalSupply to determine the next id
   * @return uint256 Representing the new Estate id
   */
  function _getNewEstateId() internal view returns (uint256) {
    return totalSupply().add(1);
  }

  /**
   * @dev Appends a new LAND id to an Estate updating all related storage
   * @param estateId Estate where the LAND should go
   * @param landId Transfered LAND
   */
  function _pushLandId(uint256 estateId, uint256 landId) internal {
    require(exists(estateId), "The Estate id should exist");
    require(landIdEstate[landId] == 0, "The LAND is already owned by an Estate");
    require(registry.ownerOf(landId) == address(this), "The EstateRegistry cannot manage the LAND");

    estateLandIds[estateId].push(landId);

    landIdEstate[landId] = estateId;

    estateLandIndex[estateId][landId] = estateLandIds[estateId].length;

    emit AddLand(estateId, landId);
  }

  /**
   * @dev Removes a LAND from an Estate and transfers it to a new owner
   * @param estateId Current owner of the LAND
   * @param landId LAND to be transfered
   * @param destinatary New owner
   */
  function _transferLand(
    uint256 estateId,
    uint256 landId,
    address destinatary
  )
    internal
  {
    require(destinatary != address(0), "You can not transfer LAND to an empty address");

    uint256[] storage landIds = estateLandIds[estateId];
    mapping(uint256 => uint256) landIndex = estateLandIndex[estateId];

    /**
     * Using 1-based indexing to be able to make this check
     */
    require(landIndex[landId] != 0, "The LAND is not part of the Estate");

    uint lastIndexInArray = landIds.length.sub(1);

    /**
     * Get the landIndex of this token in the landIds list
     */
    uint indexInArray = landIndex[landId].sub(1);

    /**
     * Get the landId at the end of the landIds list
     */
    uint tempTokenId = landIds[lastIndexInArray];

    /**
     * Store the last token in the position previously occupied by landId
     */
    landIndex[tempTokenId] = indexInArray.add(1);
    landIds[indexInArray] = tempTokenId;

    /**
     * Delete the landIds[last element]
     */
    delete landIds[lastIndexInArray];
    landIds.length = lastIndexInArray;

    /**
     * Drop this landId from both the landIndex and landId list
     */
    landIndex[landId] = 0;

    /**
     * Drop this landId Estate
     */
    landIdEstate[landId] = 0;

    registry.safeTransferFrom(this, destinatary, landId);

    emit RemoveLand(estateId, landId, destinatary);
  }

  function _isUpdateAuthorized(address operator, uint256 estateId) internal view returns (bool) {
    return isApprovedOrOwner(operator, estateId) || updateOperator[estateId] == operator;
  }

  function _bytesToUint(bytes b) internal pure returns (uint256) {
    return uint256(_bytesToBytes32(b));
  }

  function _bytesToBytes32(bytes b) internal pure returns (bytes32) {
    bytes32 out;

    for (uint i = 0; i < b.length; i++) {
      out |= bytes32(b[i] & 0xFF) >> i.mul(8);
    }

    return out;
  }

  function _updateLandData(
    uint256 estateId,
    uint256 landId,
    string data
  )
    internal
    onlyUpdateAuthorized(estateId)
  {
    require(landIdEstate[landId] == estateId, "The LAND is not part of the Estate");
    int x;
    int y;
    (x, y) = registry.decodeTokenId(landId);
    registry.updateLandData(x, y, data);
  }
}