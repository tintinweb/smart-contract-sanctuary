pragma solidity 0.4.24;

library Bytes32Utils {
  function bytes32ToStr(bytes32 x) internal pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
        byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[charCount] = char;
            charCount++;
        }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
        bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }  
}

pragma solidity 0.4.24;

import "./Migratable.sol";
import "./RBAC.sol";
import "./MultiSig.sol";
import "./Bytes32Utils.sol";
import "./Debugable.sol";

contract CanWorkAdmin is MultiSig, RBAC, Migratable, Debugable {
  using Bytes32Utils for bytes32;

  string public constant ROLE_OWNER = "owner";
  string public constant ROLE_ADMIN = "admin";  

  function initialize(address initialOwner1, address initialOwner2, address initialOwner3) 
  public 
  isInitializer("CanWorkAdmin", "0.1.2")
  {
    require(initialOwner1 != address(0) && initialOwner2 != address(0) && initialOwner3 != address(0));
    
    addRole(initialOwner1, ROLE_OWNER);
    addRole(initialOwner2, ROLE_OWNER);
    addRole(initialOwner3, ROLE_OWNER);
  } 

  function addOwner(address _owner) 
  public 
  onlyRole(ROLE_OWNER) 
  returns (bool)
  {
    require(_owner != address(0));
    require(!hasRole(_owner, ROLE_OWNER));

    bytes32 uniqueId = keccak256(abi.encodePacked(address(this), _owner, "addOwner"));

    if (getSignersCount(uniqueId) < 2) {
      addSig(msg.sender, uniqueId);
      return false;
    }

    addSig(msg.sender, uniqueId);

    addRole(_owner, ROLE_OWNER);

    resetSignature(uniqueId);
    
    return true;
  }

  function removeOwner(address _owner) 
  public 
  onlyRole(ROLE_OWNER)
  returns (bool)
  {
    require(_owner != address(0));
    require(hasRole(_owner, ROLE_OWNER));

    bytes32 uniqueId = keccak256(abi.encodePacked(address(this), _owner, "removeOwner"));

    if (getSignersCount(uniqueId) < 2) {
      addSig(msg.sender, uniqueId);
      return false;
    }

    addSig(msg.sender, uniqueId);

    resetSignature(uniqueId);

    removeRole(_owner, ROLE_OWNER);
    
    return true;
  }  

  function addAdmin(address _admin) 
  public 
  onlyRole(ROLE_OWNER)
  returns (bool)
  {
    require(_admin != address(0));
    require(!hasRole(_admin, ROLE_ADMIN));

    addRole(_admin, ROLE_ADMIN);
    
    return true;
  }

  function removeAdmin(address _admin) 
  public 
  onlyRole(ROLE_OWNER) 
  returns (bool)
  {
    require(_admin != address(0));
    require(hasRole(_admin, ROLE_ADMIN));

    removeRole(_admin, ROLE_ADMIN);
    
    return true;
  }    

  function getRoleMembersCount(bytes32 roleName)
  public 
  view 
  returns (uint256)
  {
    return size(roleName.bytes32ToStr());
  }

  function getRoleMember(bytes32 roleName, uint256 index) 
  public 
  view 
  returns (address,bool)
  {
    return get(roleName.bytes32ToStr(), index);
  }  

  function getOperationSignersCount(bytes32 operation, address _owner) 
  public 
  view 
  returns(uint)
  {   
    bytes32 uniqueId = keccak256(abi.encodePacked(address(this), _owner, operation.bytes32ToStr()));
    return getSignersCount(uniqueId);
  }

  function getOperationSigner(bytes32 operation, address _owner, uint index) 
  public 
  view 
  returns (address,bool)
  {
    bytes32 uniqueId = keccak256(abi.encodePacked(address(this), _owner, operation.bytes32ToStr()));
    return getSigner(uniqueId, index);    
  }
  
}

pragma solidity 0.4.24;

contract Debugable {
  function getAddress() public view returns (address) { return address(this); }
  function getSender() public view returns (address) { return address(msg.sender); }
}

pragma solidity ^0.4.24;


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
 * WARNING: It is the developer's responsibility to ensure that migrations are
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
   * @dev Modifier to use in the initialization function of a contract.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  modifier isInitializer(string contractName, string migrationId) {
    require(!isMigrated(contractName, migrationId));
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
  }

  /**
   * @dev Modifier to use in the migration of a contract.
   * @param contractName Name of the contract.
   * @param requiredMigrationId Identifier of the previous migration, required
   * to apply new one.
   * @param newMigrationId Identifier of the new migration to be applied.
   */
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId) && !isMigrated(contractName, newMigrationId));
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
}

pragma solidity 0.4.24;


contract MultiSig {
  
  struct Signature {
    address[] signersIndex;
    mapping(address => bool) signers;
    uint8 count;
  }

  mapping(bytes32 => Signature) signedItems;

  event SignatureAdded(address indexed signer, bytes32 id);

  function addSig(address signer, bytes32 id) public returns (uint8) {
    require(signer != address(0));
    require(signedItems[id].signers[signer] != true);    

    signedItems[id].count += 1;
    signedItems[id].signersIndex.push(signer);
    signedItems[id].signers[signer] = true;

    emit SignatureAdded(signer, id);

    return signedItems[id].count;
  }

  function getSignersCount(bytes32 id) public view returns (uint8) {
    return signedItems[id].count;
  }

  function getSigner(bytes32 id, uint index) public view returns (address,bool) {    
    address signer = signedItems[id].signersIndex[index];
    return (signer, signedItems[id].signers[signer]);
  }

  function resetSignature(bytes32 id) public returns (bool) {
    signedItems[id].count = 0;
    for (uint i = 0; i < signedItems[id].signersIndex.length; i++) {
      address signer = signedItems[id].signersIndex[i];      
      signedItems[id].signers[signer] = false;
    }    

    return true;
  }
  
}

pragma solidity ^0.4.21;

import "./Roles.sol";


/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It's also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    require(!hasRole(addr, roleName), "User already has this role");
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  function size(string roleName) public view returns (uint256) {
    return roles[roleName].size();
  }

  function get(string roleName, uint256 index) public view returns (address,bool) {
    return roles[roleName].get(index);
  }


  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

pragma solidity ^0.4.21;


/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct BearerRecord {
    uint256 index;
    bool isActive;
  }

  struct Role {
    address[] indexes;
    mapping (address => BearerRecord) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    BearerRecord storage record = role.bearer[addr];

    if (record.index == 0 && record.isActive == false) {
      record.index = role.indexes.length - 1;
      role.indexes.push(addr);
    } 

    record.isActive = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr].isActive = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr].isActive;
  }

  function size(Role storage role) 
  view 
  internal 
  returns (uint256) 
  {
    return role.indexes.length;
  }

  function get(Role storage role, uint256 index) internal view returns (address,bool) {
    address addr = role.indexes[index];
    return (addr, role.bearer[addr].isActive);
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}