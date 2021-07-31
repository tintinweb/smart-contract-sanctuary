/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// File: contracts/Interfaces/BlockhainRegistryInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface BlockhainRegistryInterface {

    ///
    /// User section
    ///
    function editIdentityInformation(address querryAddress, string memory title, string memory firstName, string memory lastName, string memory dateOfBirth, string memory placeOfLiving, string memory countryOfLiving, string memory email, string memory birthday) external;
    
    ///
    /// Moderator section
    ///
    function addNewIdentity(string memory title, string memory firstName, string memory lastName, string memory dateOfBirth, string memory placeOfLiving, string memory countryOfLiving, string memory email,  string memory birthday, address identityAddress) external;
    function removeIdentity(address identityAddress) external;
    
    ///
    /// WHITELISTER_ROLE section
    //
    
    function whitelistContractsAddress(address contractAddress, bool option) external returns (bool);
    
    ///
    /// Admin section
    ///
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) external returns (bool);
    function killContract() external;

    ///
    /// Public section
    ///
    function getIdentityId(address querryAddress) external view returns(uint);
    function getIdentityData(uint identityId) external view returns(string memory, string memory, string memory, string memory,string memory,string memory,string memory,string memory);
    function getIdentityAddressProposal(address newAddress) external view returns(uint);
    function isAddressWhitelisted(address querryAddress) external view returns(bool);
    function isAddressFrozen(address querryAddress) external view returns (bool);
    
    function isContractAddressWhitelisted(address contractAddress) external view returns (bool);
    function isUserAddressWhitelisted(address querryAddress) external view returns (bool);
    function getCompanyRegistryAddress() external view returns (address);
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

// File: contracts/CompanyRegistryContract.sol

pragma solidity 0.8.6;




struct CompanyData {
    uint companyId;
    string companyName;
    bool active;
    address[] companyStocks;
    address companyIdentityAddress;
}

contract CompanyRegistryContract is AccessControl {
        
    bytes32 public constant TOKEN_MANAGER = keccak256("TOKEN_MANAGER");
    bytes32 public constant COMPANY_MANAGER = keccak256("COMPANY_MANAGER");
    bytes32 public constant DEPLOYERS = keccak256("DEPLOYERS");
        
    using Counters for Counters.Counter;
    Counters.Counter private _companyIds;

    mapping (uint => CompanyData) private _companyMap;
    mapping (address => uint) private _stockToCompanyMap;
    
    uint private unlistedCompanies;
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _companyIds.increment();
    }
    
    ///
    /// COMPANY_MANAGER section
    ///
    
    function addNewCompany(string memory companyName, address companyIdentityAddress) public returns (uint){
        require (hasRole(COMPANY_MANAGER, msg.sender), "Sender does not have role COMPANY_MANAGER!");

        uint256 newCompanyId = _companyIds.current();
        _companyMap[newCompanyId].companyId = newCompanyId;
        _companyMap[newCompanyId].companyName = companyName;
        _companyMap[newCompanyId].companyIdentityAddress = companyIdentityAddress;
        
        unlistedCompanies++;
        _companyIds.increment();
        return newCompanyId;
    }
    
    function DisableCompany(uint companyId) public {
        require (hasRole(COMPANY_MANAGER, msg.sender), "Sender does not have role COMPANY_MANAGER!");
        require(_companyMap[companyId].companyId != 0, "Company id doesn't exist!");
        require(_companyMap[companyId].active == true, "Company is already disabled!");
        
        _companyMap[companyId].active = false;
        unlistedCompanies++;
    }
    
    function EnableCompany(uint companyId) public {
        require (hasRole(COMPANY_MANAGER, msg.sender), "Sender does not have role COMPANY_MANAGER!");
        require(_companyMap[companyId].companyId != 0, "Company id doesn't exist!");
        require(_companyMap[companyId].active == false, "Company is already enabled!");
        
        _companyMap[companyId].active = true;
        unlistedCompanies--;
    }
    
    function setCompanyName(uint companyId, string memory companyName) public {
        require (hasRole(COMPANY_MANAGER, msg.sender), "Sender does not have role COMPANY_MANAGER!");
        require(_companyMap[companyId].companyId != 0, "Company id doesn't exist!");
        _companyMap[companyId].companyName = companyName;
    }
    
    function setCompanyIdentityAddress(uint companyId, address companyIdentityAddress) public {
        require (hasRole(COMPANY_MANAGER, msg.sender), "Sender does not have role COMPANY_MANAGER!");
        require(_companyMap[companyId].companyId != 0, "Company id doesn't exist!");
        _companyMap[companyId].companyIdentityAddress = companyIdentityAddress;
    }
    
    ///
    /// DEPLOYERS section
    ///
    
    function whitelistContractAddress(address registryAddress, address contractAddress) public returns (bool) {
        require (hasRole(DEPLOYERS, msg.sender), "Sender does not have role DEPLOYERS!");
        BlockhainRegistryInterface(registryAddress).whitelistContractsAddress(contractAddress, true);
        return true;
    }
        
    ///
    /// TOKEN_MANAGER section
    ///
    
    function addNewCompanyStock(uint companyId, address companyStockToken) public {
        require (hasRole(TOKEN_MANAGER, msg.sender), "Sender does not have TOKEN_MANAGER!");

        require(_companyMap[companyId].companyId != 0, "Company id doesn't exist!");
        require(_stockToCompanyMap[companyStockToken] == 0, "Token is already part of the company!");
        _companyMap[companyId].companyStocks.push(companyStockToken);
        _stockToCompanyMap[companyStockToken] = companyId;
    }
    
    function removeCompanyStock(uint companyId, address companyStockToken) public {
        require (hasRole(TOKEN_MANAGER, msg.sender), "Sender does not have TOKEN_MANAGER!");
        require(_stockToCompanyMap[companyStockToken] == companyId, "Token is not part of the company!");
        
        uint i = 0;
        while (_companyMap[companyId].companyStocks[i] != companyStockToken) {
            i++;
        }
        while (i<_companyMap[companyId].companyStocks.length-1) {
            _companyMap[companyId].companyStocks[i] = _companyMap[companyId].companyStocks[i+1];
            i++;
        }
        _companyMap[companyId].companyStocks.pop();
        _stockToCompanyMap[companyStockToken] = 0;
    }
    
    ///
    /// PUBLIC section
    ///
    
    function getCompanyStocks(uint companyId) public view returns (address[] memory) {
        return _companyMap[companyId].companyStocks;
    }    
    
    function getCompanyData(uint companyId) public view returns (uint, string memory, bool) {
        return (_companyMap[companyId].companyId, _companyMap[companyId].companyName, _companyMap[companyId].active);
    }
    
    function getListedCompanies() public view returns (CompanyData[] memory){
        uint companyNumber = _companyIds.current() - unlistedCompanies;
        uint counter = 0;
        
        CompanyData[] memory companyArray = new CompanyData[](companyNumber);
        for (uint i=1; i<_companyIds.current(); i++) {
            if (!_companyMap[i].active) {
                continue;
            }
            companyArray[counter] = _companyMap[i];
            counter++;
        }
        return companyArray;
    }
    
    function getCompanyIdByToken(address tokenAddress) public view returns (uint) {
        uint companyId = _stockToCompanyMap[tokenAddress];
        require(companyId != 0, "Token is not part of any company!");
        return companyId;
    }
    
    function getCompaniesRegistry(uint companyId) public view returns(address) {
        CompanyData memory company = _companyMap[companyId];
        require(company.companyIdentityAddress != address(0x0), "Company does not exist!");
        return company.companyIdentityAddress;
    }
    
    function getCompanyActivity(uint companyId) public view returns (bool) {
        return _companyMap[companyId].active;
    }
}