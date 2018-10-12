pragma solidity ^0.4.24;

// File: @ensdomains/ens/contracts/ENS.sol

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;
    function setResolver(bytes32 node, address resolver) public;
    function setOwner(bytes32 node, address owner) public;
    function setTTL(bytes32 node, uint64 ttl) public;
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (address);
    function ttl(bytes32 node) public view returns (uint64);

}

// File: contracts/Roles.sol

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
   * @dev give an account access to this role
   */
  function add(Role storage _role, address _account)
    internal
  {
    _role.bearer[_account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage _role, address _account)
    internal
  {
    _role.bearer[_account] = false;
  }

  /**
   * @dev check if an account has this role
   * // reverts
   */
  function check(Role storage _role, address _account)
    internal
    view
  {
    require(has(_role, _account));
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage _role, address _account)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_account];
  }
}

// File: contracts/RBAC.sol

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
  function _addRole(address _operator, string _role)
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
  function _removeRole(address _operator, string _role)
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

// File: contracts/OwnerResolver.sol

contract OwnerResolver {
    ENS public ens;

    constructor(ENS _ens) public {
        ens = _ens;
    }

    function addr(bytes32 node) public view returns(address) {
        return ens.owner(node);
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x01ffc9a7 || interfaceID == 0x3b3b57de;
    }
}

// File: contracts/OwnedRegistrar.sol

pragma experimental ABIEncoderV2;




/**
 * OwnedRegistrar implements an ENS registrar that accepts registrations by a
 * list of approved parties (IANA registrars). Registrations must be submitted
 * by a "transactor", and signed by a "registrar". Registrars can be added or
 * removed by an account with the "authoriser" role.
 *
 * An audit of this code is available here: https://hackmd.io/s/SJcPchO57
 */
contract OwnedRegistrar is RBAC {
    ENS public ens;
    OwnerResolver public resolver;
    mapping(uint=>mapping(address=>bool)) public registrars; // Maps IANA IDs to authorised accounts
    mapping(bytes32=>uint) public nonces; // Maps namehashes to domain nonces

    event RegistrarAdded(uint id, address registrar);
    event RegistrarRemoved(uint id, address registrar);
    event Associate(bytes32 indexed node, bytes32 indexed subnode, address indexed owner);
    event Disassociate(bytes32 indexed node, bytes32 indexed subnode);

    constructor(ENS _ens) public {
        ens = _ens;
        resolver = new OwnerResolver(_ens);
        _addRole(msg.sender, "owner");
    }

    function addRole(address addr, string role) external onlyRole("owner") {
        _addRole(addr, role);
    }

    function removeRole(address addr, string role) external onlyRole("owner") {
        // Don&#39;t allow owners to remove themselves
        require(keccak256(abi.encode(role)) != keccak256(abi.encode("owner")) || msg.sender != addr);
        _removeRole(addr, role);
    }

    function setRegistrar(uint id, address registrar) public onlyRole("authoriser") {
        registrars[id][registrar] = true;
        emit RegistrarAdded(id, registrar);
    }

    function unsetRegistrar(uint id, address registrar) public onlyRole("authoriser") {
        registrars[id][registrar] = false;
        emit RegistrarRemoved(id, registrar);
    }

    function associateWithSig(bytes32 node, bytes32 label, address owner, uint nonce, uint registrarId, bytes32 r, bytes32 s, uint8 v) public onlyRole("transactor") {
        bytes32 subnode = keccak256(abi.encode(node, label));
        require(nonce == nonces[subnode]);
        nonces[subnode]++;

        bytes32 sighash = keccak256(abi.encode(subnode, owner, nonce));
        address registrar = ecrecover(sighash, v, r, s);
        require(registrars[registrarId][registrar]);

        ens.setSubnodeOwner(node, label, address(this));
        if(owner == 0) {
            ens.setResolver(subnode, 0);
        } else {
            ens.setResolver(subnode, resolver);
        }
        ens.setOwner(subnode, owner);

        emit Associate(node, label, owner);
    }

    function multicall(bytes[] calls) public {
        for(uint i = 0; i < calls.length; i++) {
            require(address(this).delegatecall(calls[i]));
        }
    }
}