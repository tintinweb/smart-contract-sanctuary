/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: posoco.sol

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


contract SustainImpact is AccessControl {

    // Addresses
    address public admin;

    // Uints
    uint capacityTimeBlock = 1;
    uint requisitionTimeBlock = 1;

    // Structs
    struct DeclaredCapacity {
        uint timeDescription;
        uint power;
        uint techMin;
        uint rampUp;
        uint rampDown;
        uint onBarInstCap;
        address ISGSAddress;
    }

    struct Requisition {
        uint timeDescription;
        uint requisitionEntry;
        address SLDCAddress;
    }

    struct ISGSData{
        address ISGSAddress;
        uint timeBlock;
        uint timestamp;
    }

    struct SLDCData{
        address SLDCAddress;
        uint timeBlock;
        uint timestamp;
    }

    // Defining roles
    bytes32 public constant ISGS_ROLE = keccak256("ISGS_ROLE"); 
    bytes32 public constant RLDC_ROLE = keccak256("RLDC_ROLE");
    bytes32 public constant SLDC_ROLE = keccak256("SLDC_ROLE");

    // Mappings
    // ISGS Address mapped => timblock => => timestamp =>declared capacity
    mapping(address => mapping(uint => mapping(uint => DeclaredCapacity))) public declaredCapacityData;  
    // SLDC address mapped => requisition time block => timestamp => data
    mapping(address => mapping(uint => mapping(uint => Requisition))) public requisitionData;

    // Addresses
    address[] public ISGSAddresses;
    address[] public SLDCAddresses;
    address[] public RLDCAddresses;
    ISGSData[] public isgsData;
    SLDCData[] public sldcData;
 

    // Events
    event NewRoleAdded(bytes32 _role, address _roleAddress);
    event UploadedCapacitySheetByISGS(uint _timeCapacity, uint _power, uint _techMin, uint _rampUp, uint _rampDown, uint _onBarInstCap);
    event UploadedRequisitionBySLDC(uint _timeCapacity, uint _requisitionEntry);

    constructor(address _admin) {
        admin = _admin;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        grantRole(ISGS_ROLE, _admin);
    }

    // Access modifier
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function addNewRole(bytes32 _role, address _roleAddress) public onlyAdmin() {
        if(_role == ISGS_ROLE) {
            ISGSAddresses.push(_roleAddress);
        }
        else if(_role == SLDC_ROLE) {
            SLDCAddresses.push(_roleAddress);
        }
        else if(_role == RLDC_ROLE) {
            RLDCAddresses.push(_roleAddress);
        }
        grantRole(_role, _roleAddress);
        emit NewRoleAdded(_role, _roleAddress);
    }

    // ISGS uploads declared capacity
    function uploadCapacitySheetISGS
    (
        uint _timeCapacity, 
        uint _power, 
        uint _techMin, 
        uint _rampUp, 
        uint _rampDown, 
        uint _onBarInstCap
    ) 
    public 
    {
        require(hasRole(ISGS_ROLE, msg.sender), "Not Authorized");
        declaredCapacityData[msg.sender][capacityTimeBlock][block.timestamp] = DeclaredCapacity(
            _timeCapacity,
            _power,
            _techMin,
            _rampUp,
            _rampDown,
            _onBarInstCap,
            msg.sender
        );
        isgsData.push(ISGSData(msg.sender, capacityTimeBlock, block.timestamp));
        emit UploadedCapacitySheetByISGS(_timeCapacity, _power, _techMin, _rampUp, _rampDown, _onBarInstCap);
        capacityTimeBlock++;
    }

    function uploadCapacitySheetISGSInBulk(
        uint[] memory _timeCapacity, 
        uint[] memory _power, 
        uint[] memory _techMin, 
        uint[] memory _rampUp, 
        uint[] memory _rampDown, 
        uint[] memory _onBarInstCap
    ) public {
        require(hasRole(ISGS_ROLE, msg.sender), "Not Authorized");

        require(_timeCapacity.length == _power.length, "Parameters missing");
        require(_timeCapacity.length == _techMin.length, "Parameters missing");
        require(_timeCapacity.length == _rampUp.length, "Parameters missing");
        require(_timeCapacity.length == _rampDown.length, "Parameters missing");
        require(_timeCapacity.length == _onBarInstCap.length, "Parameters missing");

        for(uint i = 0; i < _timeCapacity.length; i++){
            uploadCapacitySheetISGS(_timeCapacity[i], _power[i], _techMin[i], _rampUp[i], _rampDown[i], _onBarInstCap[i]);
        }
    }
    
    function getISGSAddresses() public view returns(address[] memory){
        return ISGSAddresses;
    }

    function getSLDCAddresses() public view returns(address[] memory){
        return SLDCAddresses;
    }

    function getIsgsData(address user) public view returns(address[] memory _isgsAddress, uint[] memory _timeBlock, uint[] memory _timeStamp){
        _isgsAddress = new address[](isgsData.length);
        _timeBlock = new uint[](isgsData.length);
        _timeStamp = new uint[](isgsData.length);
        
        uint j;
        for(uint i = 0; i < isgsData.length; i++){
            if(isgsData[i].ISGSAddress == user){
                _isgsAddress[j] = isgsData[i].ISGSAddress;
                _timeBlock[j] = isgsData[i].timeBlock;
                _timeStamp[j] = isgsData[i].timestamp;
                j++;
            }
        }
        return (_isgsAddress, _timeBlock, _timeStamp);
    }

    function getSldcData(address user) public view returns(SLDCData[] memory _sldcData){
        uint j;
        for(uint i = 0; i < sldcData.length; i++){
            if(sldcData[i].SLDCAddress == user){
                _sldcData[j] = sldcData[i];
                j++;
            }
        }
        return _sldcData;
    }

    // ISGS and RLDC can view decalred capacities
    function viewCapacitySheet(address _ISGSAddress, uint _timeBlock, uint _timestamp) public view returns(uint, uint, uint, uint, uint, uint) {
        
        require(hasRole(ISGS_ROLE, msg.sender) || hasRole(RLDC_ROLE, msg.sender), "Not Authorized");
        
        if(hasRole(ISGS_ROLE, msg.sender)){
            require(msg.sender == declaredCapacityData[_ISGSAddress][_timeBlock][_timestamp].ISGSAddress, "Not Authorized");
        }

        return (
           declaredCapacityData[_ISGSAddress][_timeBlock][_timestamp].timeDescription,
           declaredCapacityData[_ISGSAddress][_timeBlock][_timestamp].power,
           declaredCapacityData[_ISGSAddress][_timeBlock][_timestamp].techMin,
           declaredCapacityData[_ISGSAddress][_timeBlock][_timestamp].rampUp,
           declaredCapacityData[_ISGSAddress][_timeBlock][_timestamp].rampDown,
           declaredCapacityData[_ISGSAddress][_timeBlock][_timestamp].onBarInstCap
        );
    }

    // Need to be done: RLDC needs to calculate entitlement and publish them

    // SLDC uploads requisitionData
    function uploadRequisitionSLDC(uint _timeCapacity, uint _requisitionEntry) public {
        require(hasRole(SLDC_ROLE, msg.sender), "Not Authorized");
        requisitionData[msg.sender][requisitionTimeBlock][block.timestamp] = Requisition(_timeCapacity, _requisitionEntry, msg.sender);
        sldcData.push(SLDCData(msg.sender, requisitionTimeBlock, block.timestamp));
        requisitionTimeBlock++;
        emit UploadedRequisitionBySLDC(_timeCapacity, _requisitionEntry);
    }

    function uploadRequisitionSLDCInBulk(uint[] memory _timeCapacity, uint[] memory _requisitionEntry) public {
        require(hasRole(SLDC_ROLE, msg.sender), "Not Authorized");

        require(_timeCapacity.length == _requisitionEntry.length, "Parameter Missing");

        for(uint i = 0; i < _timeCapacity.length; i++){
            uploadRequisitionSLDC(_timeCapacity[i], _requisitionEntry[i]);
        }
    }

    // SLDC and RLDC views uploaded requisition
    function viewRequisition(address _SLDCAddress, uint _requisitionTimeBlock, uint _timestamp) public view returns(uint, uint) {
        require(hasRole(SLDC_ROLE, msg.sender) || hasRole(RLDC_ROLE, msg.sender), "Not Authorized");

        if(hasRole(SLDC_ROLE, msg.sender)){
            require(msg.sender == requisitionData[_SLDCAddress][_requisitionTimeBlock][_timestamp].SLDCAddress, "Not Authorized");
        }

        return (
            requisitionData[_SLDCAddress][_requisitionTimeBlock][_timestamp].timeDescription,
            requisitionData[_SLDCAddress][_requisitionTimeBlock][_timestamp].requisitionEntry
        );
    }

    function getAllISGSAddress() public view returns(address[] memory) {
        require(hasRole(RLDC_ROLE, msg.sender), "Not Authorized");
        return (ISGSAddresses);
    }

    function getAllSLDCAddress() public view returns(address[] memory) {
        require(hasRole(RLDC_ROLE, msg.sender), "Not Authorized");
        return (SLDCAddresses);
    }

    // Need to be done: RLDC calculates and publishes the provisional schedule
}