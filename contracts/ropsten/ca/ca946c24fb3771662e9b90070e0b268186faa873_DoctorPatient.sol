pragma solidity 0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/ownership/rbac/Roles.sol

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
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
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
    return role.bearer[addr];
  }
}

// File: node_modules/openzeppelin-solidity/contracts/ownership/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 * to avoid typos.
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
    view
    public
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
    view
    public
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

// File: contracts/AccessControl.sol

contract AccessControl is RBAC {
    constructor(address ziekenhuis, address arts) public {
      // FOR DEMONSTRATION PURPOSES
        addRole(msg.sender, "EIGENAAR");
        addRole(msg.sender, "ZIEKENHUIS");
        addRole(msg.sender, "ARTS");
        /* addRole(ziekenhuis, "ZIEKENHUIS");
        addRole(arts, "ARTS"); */
        addRole(0xc34bf87d269442e8fe6648002ed6e3b06b1991ea, "ZIEKENHUIS"); //Kim&#39;s account
        addRole(0xe1a8308a8d36ed095a9380831853fffade37e9e3, "ZIEKENHUIS"); //Rinke&#39;s account
    }

    function addArts(address doctor) public onlyRole("ZIEKENHUIS") {
        addRole(doctor, "ARTS");
    }

    function removeArts(address doctor) public onlyRole("ZIEKENHUIS") {
        removeRole(doctor, "ARTS");
    }

    function changeOwnerShip(address newOwner) public onlyRole("EIGENAAR") {
        //require(newOwner != address(0));
        addRole(newOwner, "EIGENAAR");
        removeRole(msg.sender, "EIGENAAR");
    }

    function addZiekenhuis(address ziekenhuis) public onlyRole("EIGENAAR") {
        addRole(ziekenhuis, "ZIEKENHUIS");
    }
}

// File: contracts/DoctorPatient.sol

contract DoctorPatient is AccessControl {

    event PatientSet(
        string patientName,
        uint256 DateOfBirth,
        address indexed patient,
        string medicationName,
        string indication,
        uint256 dosage,
        uint256 frequency
    );
    event MedicationTaken(address indexed patient, uint256 time, bool taken);

    constructor(address arts, address patient) AccessControl(arts, patient) public {}

    // Medication not strictly needed for the functionality of the smart contract
    struct Patient {
        string patientName;
        uint256 dateOfBirth;
        uint256 dosage;
        string medicationName;
        uint256 frequency;
        string indication;
    }

    struct Diary {
        uint256 time;
        bool taken;
    }

    mapping(address => Diary) public medicationRegistry;
    mapping(address => Patient) public patientRegistry;

    function setPatient(
        string _patientName,
        uint256 _dateOfBirth,
        address patient,
        string _medicationName,
        string _indication,
        uint256 _dosage,
        uint256 _frequency
    )
        public
        onlyRole("ARTS")
    {
        //in later releases we should check on combination patient / medication
        require(!hasRole(patient, "PATI&#203;NT"));
        addRole(patient, "PATI&#203;NT");
        patientRegistry[patient].patientName = _patientName;
        patientRegistry[patient].dateOfBirth = _dateOfBirth;
        patientRegistry[patient].dosage = _dosage;
        patientRegistry[patient].medicationName = _medicationName;
        patientRegistry[patient].frequency = _frequency;
        patientRegistry[patient].indication = _indication;
        emit PatientSet(
            _patientName,
            _dateOfBirth,
            patient,
            patientRegistry[patient].medicationName,
            patientRegistry[patient].indication,
            patientRegistry[patient].dosage,
            patientRegistry[patient].frequency
            );
    }

    function writeToDiary(uint256 _time, bool _taken) public onlyRole("PATI&#203;NT") {
        // solium-disable-next-line security/no-block-members
        require(_time <= now + 30 minutes);
        medicationRegistry[msg.sender].time = _time;
        medicationRegistry[msg.sender].taken = _taken;
        emit MedicationTaken(msg.sender, _time, _taken);
    }
}