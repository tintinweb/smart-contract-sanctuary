pragma solidity ^0.4.24;

// A common external interface to Braided contracts
interface BraidedInterface {
  function addStrand(uint, address, bytes32, string) external;
  function getStrandCount() external view returns (uint);
  function getStrandContract(uint) external view returns (address);
  function getStrandGenesisBlockHash(uint) external view returns (bytes32);
  function getStrandDescription(uint) external view returns (string);
  function addAgent(address, uint) external;
  function removeAgent(address, uint) external;
  function addBlock(uint, uint, bytes32) external;
  function getBlockHash(uint, uint) external view returns (bytes32);
  function getHighestBlockNumber(uint) external view returns (uint);
  function getPreviousBlockNumber(uint, uint) external view returns (uint);
  function getPreviousBlock(uint, uint) external view returns (uint, bytes32);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

/**
 * @title Superuser
 * @dev The Superuser contract defines a single superuser who can transfer the ownership
 * of a contract to a new address, even if he is not the owner.
 * A superuser can transfer his role to a new address.
 */
contract Superuser is Ownable, RBAC {
  string public constant ROLE_SUPERUSER = "superuser";

  constructor () public {
    addRole(msg.sender, ROLE_SUPERUSER);
  }

  /**
   * @dev Throws if called by any account that&#39;s not a superuser.
   */
  modifier onlySuperuser() {
    checkRole(msg.sender, ROLE_SUPERUSER);
    _;
  }

  modifier onlyOwnerOrSuperuser() {
    require(msg.sender == owner || isSuperuser(msg.sender));
    _;
  }

  /**
   * @dev getter to determine if address has superuser role
   */
  function isSuperuser(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_SUPERUSER);
  }

  /**
   * @dev Allows the current superuser to transfer his role to a newSuperuser.
   * @param _newSuperuser The address to transfer ownership to.
   */
  function transferSuperuser(address _newSuperuser) public onlySuperuser {
    require(_newSuperuser != address(0));
    removeRole(msg.sender, ROLE_SUPERUSER);
    addRole(_newSuperuser, ROLE_SUPERUSER);
  }

  /**
   * @dev Allows the current superuser or owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwnerOrSuperuser {
    _transferOwnership(_newOwner);
  }
}

// Smart contract for interchain linking
contract Braided is BraidedInterface, Superuser {

  // Strand identifies a specific chain + contract on which block/hashes are stored
  struct Strand {
    uint strandID;
    address strandContract; // must support BraidedInterface if present
    bytes32 genesisBlockHash;
    string description;
  }
  
  // identifies a block by number and its hash
  struct Block {
    uint blockNumber;
    bytes32 blockHash;
  }

  // error messages
  string constant INVALID_BLOCK = "invalid block";
  string constant INVALID_STRAND = "invalid strand";
  string constant NO_PERMISSION = "no permission";

  // roles
  mapping (uint => Roles.Role) private addBlockRoles;

  Strand[] public strands;
  mapping(uint => uint) internal strandIndexByStrandID;
  mapping(uint => Block[]) internal blocks;
  mapping(uint => mapping(uint => uint)) internal blockByNumber;

  event BlockAdded(uint indexed strandID, uint indexed blockNumber, bytes32 blockHash);

  constructor() public {
    // Strand 0 is reserved
    strands.push(Strand(0, 0, 0, ""));
  }

  // Add a strand
  function addStrand(uint strandID, address strandContract, bytes32 genesisBlockHash, string description) external onlyOwnerOrSuperuser() {
    // strand 0 is reserved
    require(strandID != 0, INVALID_STRAND);
    // strandID must not already be in use
    require(strandIndexByStrandID[strandID] == 0, INVALID_STRAND);
    // Add the strand
    strands.push(Strand(strandID, strandContract, genesisBlockHash, description));
    // make it possible to find the strand in the array by strandID
    strandIndexByStrandID[strandID] = strands.length - 1;
  }

  // make a method require a known strand
  modifier validStrandID(uint strandID) {
    require(strandIndexByStrandID[strandID] != 0, INVALID_STRAND);
    _;
  }

  // return total number of strands
  function getStrandCount() external view returns (uint) {
    return strands.length - 1;
  }

  // get the Braided Contract deployed on the specified strand (if any).
  // If a new instance of the Braided Contract is deployed, then that will
  // have to be a new Strand ID.
  function getStrandContract(uint strandID) external view validStrandID(strandID) returns (address) {
    return strands[strandIndexByStrandID[strandID]].strandContract;
  }

  // get the genesis block hash for the specified strand
  function getStrandGenesisBlockHash(uint strandID) external view validStrandID(strandID) returns (bytes32) {
    return strands[strandIndexByStrandID[strandID]].genesisBlockHash;
  }

  // get the description for the specified strand
  function getStrandDescription(uint strandID) external view validStrandID(strandID) returns (string) {
    return strands[strandIndexByStrandID[strandID]].description;
  }

  // grant role to specified account
  function addAgent(address agent, uint strandID) external onlyOwnerOrSuperuser() validStrandID(strandID) {
    addBlockRoles[strandID].add(agent);
  }

  // revoke role from specied account
  function removeAgent(address agent, uint strandID) external onlyOwnerOrSuperuser() validStrandID(strandID) {
    addBlockRoles[strandID].remove(agent);
  }

  // add a block to the specified strand
  function addBlock(uint strandID, uint blockNumber, bytes32 blockHash) external validStrandID(strandID) {
    // caller must have permission
    require(addBlockRoles[strandID].has(msg.sender), NO_PERMISSION);
    // the block numbers must increase
    require(blocks[strandID].length == 0 || blocks[strandID][blocks[strandID].length - 1].blockNumber < blockNumber, INVALID_BLOCK);
    // add the block
    blocks[strandID].push(Block(blockNumber, blockHash));
    // make it possible to look up the block by block number
    blockByNumber[strandID][blockNumber] = blocks[strandID].length - 1;
    // add the event for notification
    emit BlockAdded(strandID, blockNumber, blockHash);
  }

  // get the block hash for the block number on the specified strand
  function getBlockHash(uint strandID, uint blockNumber) external view validStrandID(strandID) returns (bytes32) {
    Block memory theBlock = blocks[strandID][blockByNumber[strandID][blockNumber]];
    // blockByNumber has 0 for blocks that don&#39;t exist, 
    // which could give the wrong block, so check.
    require(theBlock.blockNumber == blockNumber, INVALID_BLOCK);
    return theBlock.blockHash;
  }

  // get the highest block number recorded for the specified strand
  function getHighestBlockNumber(uint strandID) external view validStrandID(strandID) returns (uint) {
    return blocks[strandID][blocks[strandID].length - 1].blockNumber;
  }

  // get the previous block number recorded to the one supplied for the
  // specified strand (used to walk the strand backwards)
  function getPreviousBlockNumber(uint strandID, uint blockNumber) external view validStrandID(strandID) returns (uint) {
    return blocks[strandID][blockByNumber[strandID][blockNumber] - 1].blockNumber;
  }

  // get the previous block recorded to the one supplied for the specified
  // strand (used to walk the strand backwards)
  function getPreviousBlock(uint strandID, uint blockNumber) external view validStrandID(strandID)
    returns (uint prevBlockNumber, bytes32 prevBlockHash) { // solium-disable-line lbrace
    Block memory theBlock = blocks[strandID][blockByNumber[strandID][blockNumber] - 1];
    prevBlockNumber = theBlock.blockNumber;
    prevBlockHash = theBlock.blockHash;
  }
}