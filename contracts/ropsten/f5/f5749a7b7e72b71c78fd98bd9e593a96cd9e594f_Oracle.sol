pragma solidity ^0.4.24;

// File: contracts/UsingOracleI.sol

interface UsingOracleI {
    function __callback(bytes32 _id, string _value, uint _errorCode) external;
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/access/rbac/Roles.sol

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

// File: openzeppelin-solidity/contracts/access/rbac/RBAC.sol

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

// File: contracts/auth/Authorizable.sol

contract Authorizable is Ownable, RBAC {

    string public constant AUTHORIZED_ROLE = "authorized_role";

    function grantAccessToAddress(address _authorizedAddress) public onlyOwner {
        addRole(_authorizedAddress, AUTHORIZED_ROLE);
    }

    function revokeAccessFromAddress(address _addressToRevoke) public onlyOwner {
        removeRole(_addressToRevoke, AUTHORIZED_ROLE);
    }
}

// File: contracts/Oracle.sol

contract Oracle is Authorizable {

    struct Request {
        address requestAddress;
        uint validFrom;
    }

    address public trustedServer;

    /* This uint is a date written in unix timestamp as a limit,
    when delay is bigger then we consider uint as timestamp, otherwise we take delay as a second.
    Limit date is 2018/01/01 00:00:00.
    */
    uint constant LIMIT_DATE = 1514764800;

    mapping(bytes32 => Request) pendingRequests;

    event DataRequested(bytes32 id, string url);
    event DelayedDataRequested(bytes32 id, string url, uint validFrom);
    event RequestFulfilled(bytes32 id, string value, uint errorCode);

    constructor(address _trustedServer) public {
        trustedServer = _trustedServer;
    }

    function request(string _url) public onlyRole(AUTHORIZED_ROLE) returns(bytes32 id) {
        id = keccak256(abi.encodePacked(_url, msg.sender, now));
        pendingRequests[id].requestAddress = msg.sender;
        pendingRequests[id].validFrom = now;
        emit DataRequested(id, _url);
    }

    function delayedRequest(string _url, uint _delay) public returns(bytes32 id) {
        if (_delay > LIMIT_DATE) {
            require(_delay - now <= 2 years, "Invalid request timestamp delay");
            id = keccak256(abi.encodePacked(_url, msg.sender, _delay));
            pendingRequests[id].requestAddress = msg.sender;
            pendingRequests[id].validFrom = _delay;
            emit DelayedDataRequested(id, _url, pendingRequests[id].validFrom);
        } else {
            require(_delay <= 2 years, "Invalid request delay");
            id = keccak256(abi.encodePacked(_url, msg.sender, now, _delay));
            pendingRequests[id].requestAddress = msg.sender;
            pendingRequests[id].validFrom = now + _delay;
            emit DelayedDataRequested(id, _url, pendingRequests[id].validFrom);
        }
    }

    function fillRequest(bytes32 _id, string _value, uint _errorCode) external
    onlyFromTrustedServer onlyIfValidRequestId(_id) onlyIfValidTimestamp(_id) {
        address callbackContract = pendingRequests[_id].requestAddress;
        delete pendingRequests[_id];

        UsingOracleI(callbackContract).__callback(_id, _value, _errorCode);

        emit RequestFulfilled(_id, _value, _errorCode);
    }

    modifier onlyFromTrustedServer() {
        require(msg.sender == trustedServer, "Sender address doesn&#39;t equal trusted server");
        _;
    }

    modifier onlyIfValidRequestId(bytes32 _id) {
        require(pendingRequests[_id].requestAddress != address(0), "Invalid request id");
        _;
    }

    modifier onlyIfValidTimestamp(bytes32 _id) {
        require(pendingRequests[_id].validFrom <= now, "Invalid request delay as timestamp");
        _;
    }
}