/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// File: contracts/Interfaces/CompanyRegistryInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface CompanyRegistryInterface {
    
    function addNewCompany(string memory companyName, address companyIdentityAddress) external returns (uint);
    
    function addNewCompanyStock(uint companyId, address companyStockToken) external;
    function removeCompanyStock(uint companyId, address companyStockToken) external;
    
    function getCompanyIdByToken(address tokenAddress) external view returns (uint);
    function getCompaniesRegistry(uint companyId) external view returns(address);
    function getCompanyActivity(uint companyId) external view returns (bool);
    
    
     function whitelistContractAddress(address registryAddress, address contractAddress) external returns (bool);
    
    ///
    /// AccessControl
    ///
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}




// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/Counters.sol

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/introspection/ERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/Strings.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/Context.sol


pragma solidity ^0.8.0;

/*
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/access/AccessControl.sol


pragma solidity ^0.8.0;




/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/BlockchainRegistryContract.sol

pragma solidity 0.8.6;





struct PersonalIdentityData {
    bytes32 title;
    bytes32 firstName;
    bytes32 lastName;
    bytes32 dateOfBirth;
    bytes32 placeOfLiving;
    bytes32 countryOfLiving;
    bytes32 email;
    bytes32 birthday;
}

struct CorporateIdentityData {
    bytes32 companyName;
    bytes32 headOfficeAddress;
    bytes32 postalAddress;
    bytes32 country;
    bytes32 email;
    bytes32 registrationNumber;
    bytes32 registryCode;
    bytes32 placeOfRegistration; // String 32 letters
    bytes32 dateOfRegistration;
}

contract BlockchainRegistryContract is AccessControl {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    
    using Counters for Counters.Counter;
    Counters.Counter private _personalIdentityId;
    Counters.Counter private _corporateIdentityId;
    
    CompanyRegistryInterface private _companyRegistryInstance;

    mapping (uint => PersonalIdentityData) _personalIdDataMap;
    mapping (uint => CorporateIdentityData) _corporateIdDataMap;
    mapping (address => uint) _personalAddressToIdMap;
    mapping (address => uint) _corporateAddressToIdMap;
    mapping (uint => address) _personalIdToAddressMap;
    mapping (uint => address) _corporateIdToAddressMap;
    
    mapping (address => bool) _frozenAccounts;
    
    mapping (address => bool) _whitelistedContractAddresses;
    
    event IdentityAdded(address indexed userAddress, bool isCorporate, uint identityId);
    event IdentityEdited(bool isCorporate, uint identityId);
    event IdentityAddressChanged(bool isCorporate, uint identityId);
    
    constructor(address defaultAdminAddress, address companyRegistryAddress) {
        _personalIdentityId.increment();
        _corporateIdentityId.increment();
        
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdminAddress);
        _setupRole(WHITELISTER_ROLE, companyRegistryAddress);
        _companyRegistryInstance = CompanyRegistryInterface(companyRegistryAddress);
    }
    
    ///
    /// User section
    ///
    function editPersonalInformation(
        address querryAddress, 
        bytes32 title, 
        bytes32 firstName, 
        bytes32 lastName, 
        bytes32 dateOfBirth, 
        bytes32 placeOfLiving, 
        bytes32 countryOfLiving, 
        bytes32 email, 
        bytes32 birthday) public {
        
        require (hasRole(MODERATOR_ROLE, msg.sender) || msg.sender == querryAddress);
        uint identityId; 
        (,identityId)= getIdentityId(querryAddress);
        require(identityId != 0, "Address is not verified!");
        
        if (title.length > 0){
            _personalIdDataMap[identityId].title = title;
        }
        if (firstName.length > 0){
            _personalIdDataMap[identityId].firstName = firstName;
        }
        if (lastName.length > 0){
            _personalIdDataMap[identityId].lastName = lastName;
        }
        if (dateOfBirth.length > 0){
            _personalIdDataMap[identityId].dateOfBirth = dateOfBirth;
        }
        if (placeOfLiving.length > 0){
            _personalIdDataMap[identityId].placeOfLiving = placeOfLiving;
        }
        if (countryOfLiving.length > 0){
            _personalIdDataMap[identityId].countryOfLiving = countryOfLiving;
        }
        if (email.length > 0){
            _personalIdDataMap[identityId].email = email;
        }
        if (birthday.length > 0){
            _personalIdDataMap[identityId].birthday = birthday;
        }
        
         emit IdentityEdited(false, identityId);
    }
    
    function editCorporateInformation(
        address querryAddress, 
        bytes32 companyName,
        bytes32 headOfficeAddress,
        bytes32 postalAddress,
        bytes32 country,
        bytes32 email,
        bytes32 registrationNumber,
        bytes32 registryCode,
        bytes32 placeOfRegistration,
        bytes32 dateOfRegistration) public {
        
        require (hasRole(MODERATOR_ROLE, msg.sender) || msg.sender == querryAddress);
        uint identityId; 
        (identityId,)= getIdentityId(querryAddress);
        require(identityId != 0, "Address is not verified!");
        
        if (companyName.length > 0){
            _corporateIdDataMap[identityId].companyName = companyName;
        }
        if (headOfficeAddress.length > 0){
            _corporateIdDataMap[identityId].headOfficeAddress = headOfficeAddress;
        }
        if (postalAddress.length > 0){
            _corporateIdDataMap[identityId].postalAddress = postalAddress;
        }
        if (country.length > 0){
            _corporateIdDataMap[identityId].country = country;
        }
        if (email.length > 0){
            _corporateIdDataMap[identityId].email = email;
        }
        if (registrationNumber.length > 0){
            _corporateIdDataMap[identityId].registrationNumber = registrationNumber;
        }
        if (registryCode.length > 0){
            _corporateIdDataMap[identityId].registryCode = registryCode;
        }
        if (placeOfRegistration.length > 0){
            _corporateIdDataMap[identityId].placeOfRegistration = placeOfRegistration;
        }
        if (dateOfRegistration.length > 0){
            _corporateIdDataMap[identityId].dateOfRegistration = dateOfRegistration;
        }
        
         emit IdentityEdited(true, identityId);
    }
    
    ///
    /// Moderator section
    ///
    
    function addNewPersonalIdentity(
        bytes32 title, 
        bytes32 firstName, 
        bytes32 lastName, 
        bytes32 dateOfBirth, 
        bytes32 placeOfLiving, 
        bytes32 countryOfLiving, 
        bytes32 email, 
        bytes32 birthday,
        address identityAddress) public {
        require (hasRole(MODERATOR_ROLE, msg.sender));
        require (_personalAddressToIdMap[identityAddress] == 0 && _corporateAddressToIdMap[identityAddress] == 0);
        
        _personalIdDataMap[_personalIdentityId.current()] = PersonalIdentityData(title, firstName, lastName, dateOfBirth, placeOfLiving, countryOfLiving, email, birthday);
        _personalAddressToIdMap[identityAddress] = _personalIdentityId.current();
        _personalIdToAddressMap[_personalIdentityId.current()] = identityAddress;
        
         emit IdentityAdded(identityAddress, false, _personalIdentityId.current());
        
        _personalIdentityId.increment();
    }
    
    function addNewCorporateIdentity(
        bytes32 companyName,
        bytes32 headOfficeAddress,
        bytes32 postalAddress,
        bytes32 country,
        bytes32 email,
        bytes32 registrationNumber,
        bytes32 registryCode,
        bytes32 placeOfRegistration,
        bytes32 dateOfRegistration,
        address identityAddress) public {
        require (hasRole(MODERATOR_ROLE, msg.sender));
        require (_personalAddressToIdMap[identityAddress] == 0 && _corporateAddressToIdMap[identityAddress] == 0);
        
        _corporateIdDataMap[_corporateIdentityId.current()] = CorporateIdentityData(companyName, headOfficeAddress, postalAddress, country, email, registrationNumber, registryCode, placeOfRegistration, dateOfRegistration);
        _corporateAddressToIdMap[identityAddress] = _corporateIdentityId.current();
        _corporateIdToAddressMap[_corporateIdentityId.current()] = identityAddress;
        
         emit IdentityAdded(identityAddress, true, _corporateIdentityId.current());
        
        _corporateIdentityId.increment();
    }
    
    function changeIdentitiesAddress(bool isCorporate, uint identityId, address newAddress) public returns (bool) {
        require (hasRole(MODERATOR_ROLE, msg.sender));

        address oldAddress;
        if (isCorporate){
            oldAddress = _corporateIdToAddressMap[identityId];
            require(oldAddress != address(0x0), "Identity ID is not set!");
            _corporateAddressToIdMap[oldAddress] = 0;
            _corporateIdToAddressMap[identityId] = newAddress;
            _corporateAddressToIdMap[newAddress] = identityId;
        } else {
            oldAddress = _personalIdToAddressMap[identityId];
            require(oldAddress != address(0x0), "Identity ID is not set!");
            _personalAddressToIdMap[oldAddress] = 0;
            _personalIdToAddressMap[identityId] = newAddress;
            _personalAddressToIdMap[newAddress] = identityId;
        }
        emit IdentityAddressChanged(isCorporate, identityId);
        return true;
    }
    
    function freezeAccount(address userAddress) public returns (bool) {
        require (hasRole(MODERATOR_ROLE, msg.sender));
        
        require(isAddressWhitelisted(userAddress), "Account is not whitelisted!");
        require(_frozenAccounts[userAddress] == false, "Account is already frozen!");
        _frozenAccounts[userAddress] = true;
        return true;
    }
    
    function unFreezeAccount(address userAddress) public returns (bool) {
        require (hasRole(MODERATOR_ROLE, msg.sender));
        
        require(isAddressWhitelisted(userAddress), "Account is not whitelisted!");
        require(_frozenAccounts[userAddress] == true, "Account is already unfrozen!");
        _frozenAccounts[userAddress] = false;
        return true;
    }
    
    ///
    /// WHITELISTER_ROLE section
    //
    
    function whitelistContractsAddress(address contractAddress, bool option) public returns (bool) {
        require (hasRole(WHITELISTER_ROLE, msg.sender));
        require (_personalAddressToIdMap[contractAddress] == 0 && _corporateAddressToIdMap[contractAddress] == 0, "Address is already whitelisted!");

        _whitelistedContractAddresses[contractAddress] = option;
        return true;
    }
    
    ///
    /// DEFAULT_ADMIN_ROLE section
    ///
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) public returns (bool){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        IERC20(tokenAddress).transfer(to, amount);
        return true;
    }
    
    function killContract() public returns (bool){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        selfdestruct(payable(msg.sender));
        return true;
    }
    
    ///
    /// Public section
    ///
    
    function getIdentityId(address querryAddress) public view returns(uint, uint) {
        return (_corporateAddressToIdMap[querryAddress], _personalAddressToIdMap[querryAddress]);
    }
    
    function getPersonalIdentityData(address querryAddress) public view returns(PersonalIdentityData memory) {
        return _personalIdDataMap[_personalAddressToIdMap[querryAddress]];
    }
    function getCorporateIdentityData(address querryAddress) public view returns(CorporateIdentityData memory) {
        return _corporateIdDataMap[_corporateAddressToIdMap[querryAddress]];
    }
    
    function isAddressWhitelisted(address querryAddress) public view returns(bool) {
        return(isUserAddressWhitelisted(querryAddress) || isContractAddressWhitelisted(querryAddress));
    }
    
    function isAddressFrozen(address querryAddress) public view returns (bool) {
        return _frozenAccounts[querryAddress];
    }
    
    function isContractAddressWhitelisted(address contractAddress) public view returns (bool) {
        return _whitelistedContractAddresses[contractAddress];
    }
    
    function isUserAddressWhitelisted(address querryAddress) public view returns (bool) {
        if (_personalAddressToIdMap[querryAddress] == 0 || _corporateAddressToIdMap[querryAddress] == 0) {
            return false;
        }else{
            return true;
        }
    }
    
    function getCompanyRegistryAddress() public view returns (address) {
        return address(_companyRegistryInstance);
    }
}
// File: contracts/Deployers/CompanyDeployer.sol

pragma solidity 0.8.6;



contract CompanyDeployer is AccessControl { 
    
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    CompanyRegistryInterface private _companyRegistryInstance;
    
    event CompanyDeployed(uint companyId, string name, address indexed tokenAddress);
    
    constructor(address companyRegistryAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        _companyRegistryInstance = CompanyRegistryInterface(companyRegistryAddress);
    }

    //
    // MODERATOR_ROLE
    //
    function deployCompany(address defaultAdminAddress, string memory name) public returns (uint, address) {
        require (hasRole(MODERATOR_ROLE, msg.sender), "Sender does not have MODERATOR_ROLE!");
        
        address newContractAddress = address(new BlockchainRegistryContract(defaultAdminAddress, address(_companyRegistryInstance)));
        uint companyId = _companyRegistryInstance.addNewCompany(name, newContractAddress);
        
        emit CompanyDeployed(companyId, name, newContractAddress);
        
        return (companyId, newContractAddress);
    }
    
    //
    // DEFAULT_ADMIN_ROLE
    //
    function setCompanyRegistryAddress(address companyRegistryAddress) public returns (bool) {
        require (hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender does not have DEFAULT_ADMIN_ROLE!");
        _companyRegistryInstance = CompanyRegistryInterface(companyRegistryAddress);
        return true;
    }
    
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) public returns (bool){
        require (hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender does not have DEFAULT_ADMIN_ROLE!");
        IERC20(tokenAddress).transfer(to, amount);
        return true;
    }
    
    function killContract() public returns (bool) {
        require (hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender does not have DEFAULT_ADMIN_ROLE!");
        selfdestruct(payable(msg.sender));
        return true;
    }
    
    ///
    /// Public methods
    ///
    
    function getCompanyRegistryAddress() public view returns (address) {
        return address(_companyRegistryInstance);
    }
    
    function sanityCheck() public view returns (bool companyRegistrySet, bool registryPermissionSet) {
        bool companyRegistrySetB = (address(_companyRegistryInstance) != address(0x0));
        bool registryPermissionSetB = (_companyRegistryInstance.hasRole(keccak256("COMPANY_MANAGER"), address(this)));
        return(companyRegistrySetB, registryPermissionSetB);
    }
}