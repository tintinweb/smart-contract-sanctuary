// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./access/Adminable.sol";
import "./interfaces/ICompanyManager.sol";


contract CompanyManager is Adminable, ICompanyManager {

    /**
    * Available roles for users
    */
    bytes32 public constant ALL_ROLE = keccak256("ALL_ROLE");
    bytes32 public constant CREATE_ROLE = keccak256("CREATE_ROLE");
    bytes32 public constant UPDATE_ROLE = keccak256("UPDATE_ROLE");
    bytes32 public constant DELETE_ROLE = keccak256("DELETE_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /**
    * Available states for a company or address (whitelist)
    */
    bytes32 public constant ACTIVED_STATE = keccak256("ACTIVED_STATE");
    bytes32 public constant BLOCKED_STATE = keccak256("BLOCKED_STATE");

    /**
    * Role structure
    */
    struct Role {
        bytes32 role;
        bool revoked;
    }

    /**
    * Structs representing every company user/address
    * And its roles in it
    */
    struct WhitelistedAddress {
        address addr;
        mapping(bytes32 => Role) roles;
        bytes32 state;
        address createdBy;
        bool exists;
    }

    /**
    * Struct representing a Veros Company
    */
    struct Company {
        string id;
        string name;
        address inventory;
        bytes32 state;
        address owner;
        mapping(address => WhitelistedAddress) whitelisted;
        bool exists;
    }

    /**
    * Mapping with all companies controlled by Veros 
    */
    mapping(string => Company) public companies;

    /**
    * Function used to add a new company 
    * And deploy its inventory contracts
    */
    function addCompany(string memory _idCPMY, string memory _name, address _owner, address _inventory) external onlyOwnerOrAdmin returns (bool){
        require(companies[_idCPMY].exists != true, 'Already exists a company with the same ID!');
        Company storage _cpmy = companies[_idCPMY];
        _cpmy.id = _idCPMY;
        _cpmy.name = _name;
        _cpmy.inventory = _inventory;
        _cpmy.state = ACTIVED_STATE;
        _cpmy.owner = _owner;
        _cpmy.exists = true;

        emit CompanyCreated(_idCPMY, _name, _owner, _inventory);
        return true;
    }

    /**
    * Used to add whitelisted address an its roles
    * The "roles" array will be applied for all addrs in the execution
    */
    function grantRoleToAddrs(string memory _idCPMY, address[] memory _addrs, bytes32 _role, address _creator) external onlyOwnerOrAdmin {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        Company storage _cpmy = companies[_idCPMY];

        for (uint i=0; i < _addrs.length; i++) {
            WhitelistedAddress storage _cl = _cpmy.whitelisted[_addrs[i]];
            if(!_cl.exists) {
                _cl.addr = _addrs[i];
                _cl.state = ACTIVED_STATE;
                _cl.createdBy = _creator;
                _cl.exists = true;
            }

            _cl.roles[_role].role = _role;
            _cl.roles[_role].revoked = false;
        }

        emit RoleGrantedToAddrs(_idCPMY, _addrs, _role, _creator);
    }
    
    /**
    * Add a new role for a address in whitelist
    */
    function grantRoleToAddr(string memory _idCPMY, address _addr, bytes32 _role, address _creator) external onlyOwnerOrAdmin {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        WhitelistedAddress storage _cl = companies[_idCPMY].whitelisted[_addr];

        if(!_cl.exists) {
            _cl.addr = _addr;
            _cl.state = ACTIVED_STATE;
            _cl.createdBy = _creator;
            _cl.exists = true;
        }
            
        _cl.roles[_role].role = _role;
        _cl.roles[_role].revoked = false;
        emit RoleGrantedToAddr(_idCPMY, _addr, _role);
    }

    /**
    * Revoke a role from an address in whitelist
    */
    function revokeAddrRole(string memory _idCPMY, address _addr, bytes32 _role) external onlyOwnerOrAdmin {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        require(companies[_idCPMY].whitelisted[_addr].exists == true, 'The address does not exists in this company whitelist');
        require(companies[_idCPMY].whitelisted[_addr].roles[_role].revoked == false, 'The role is already revoked');
        companies[_idCPMY].whitelisted[_addr].roles[_role].revoked = true;
        emit RoleGrantedToAddr(_idCPMY, _addr, _role);
    }

    /**
    * Verify if address has role and if is not revoked
    * Or if user is the company owner
    */
    function hasAddrRole(string calldata _idCPMY, address _addr, bytes32 _role) external view returns (bool) {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        require(companies[_idCPMY].whitelisted[_addr].exists == true, 'The address does not exists in this company whitelist');
        Role storage _rl = companies[_idCPMY].whitelisted[_addr].roles[_role];
        if(!isCompanyOwner(_idCPMY, _addr) && (_rl.revoked == true || _rl.role[0] == 0)) {
            return false;
        }
        return true;
    }

    /**
    * Verify if address has permission to created things for the company
    */
    function isAbleToCreate(string calldata _idCPMY, address _addr) external view returns (bool) {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        require(companies[_idCPMY].state == ACTIVED_STATE, 'The company is blocked');
        WhitelistedAddress storage _wl = companies[_idCPMY].whitelisted[_addr];

        if(isCompanyOwner(_idCPMY, _addr)) {
            return true;
        }

        if(!isActived(_wl.state)) {
            return false;
        }

        Role storage _rla = companies[_idCPMY].whitelisted[_addr].roles[ALL_ROLE];
        Role storage _rlc = companies[_idCPMY].whitelisted[_addr].roles[CREATE_ROLE];
        return isValidRole(_rla) || isValidRole(_rlc);
    }

    /**
    * Verify if address has permission to update things for the company
    */
    function isAbleToUpdate(string calldata _idCPMY, address _addr) external view returns (bool) {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        require(companies[_idCPMY].state == ACTIVED_STATE, 'The company is blocked');
        WhitelistedAddress storage _wl = companies[_idCPMY].whitelisted[_addr];
        
        if(isCompanyOwner(_idCPMY, _addr)) {
            return true;
        }

        if(!isActived(_wl.state)) {
            return false;
        }

        Role storage _rla = companies[_idCPMY].whitelisted[_addr].roles[ALL_ROLE];
        Role storage _rlu = companies[_idCPMY].whitelisted[_addr].roles[UPDATE_ROLE];
        return isValidRole(_rla) || isValidRole(_rlu);
    }

    /**
    * Verify if address has permission to update things for the company
    */
    function isAbleToDelete(string calldata _idCPMY, address _addr) external view returns (bool) {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        require(companies[_idCPMY].state == ACTIVED_STATE, 'The company is blocked');
        WhitelistedAddress storage _wl = companies[_idCPMY].whitelisted[_addr];
        
        if(isCompanyOwner(_idCPMY, _addr)) {
            return true;
        }

        if(!isActived(_wl.state)) {
            return false;
        }

        Role storage _rla = companies[_idCPMY].whitelisted[_addr].roles[ALL_ROLE];
        Role storage _rld = companies[_idCPMY].whitelisted[_addr].roles[DELETE_ROLE];
        return isValidRole(_rla) || isValidRole(_rld);
    }

    /**
    * Verify if address has permission to update things for the company
    */
    function isAbleToTransfer(string calldata _idCPMY, address _addr) external view returns (bool) {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        require(companies[_idCPMY].state == ACTIVED_STATE, 'The company is blocked');
        WhitelistedAddress storage _wl = companies[_idCPMY].whitelisted[_addr];
        
        if(isCompanyOwner(_idCPMY, _addr)) {
            return true;
        }

        if(!isActived(_wl.state)) {
            return false;
        }

        Role storage _rla = companies[_idCPMY].whitelisted[_addr].roles[ALL_ROLE];
        Role storage _rlt = companies[_idCPMY].whitelisted[_addr].roles[TRANSFER_ROLE];
        return isValidRole(_rla) || isValidRole(_rlt);
    }

    /**
    * Update company inventory
    */
    function setCompanyInventory(string calldata _idCPMY, address _inventory) external onlyOwnerOrAdmin {
        require(companies[_idCPMY].exists == true, 'The company does not exists');
        require(companies[_idCPMY].state == ACTIVED_STATE, 'The company is blocked');
        companies[_idCPMY].inventory = _inventory;
        emit CompanyInventoryUpdated(_idCPMY, _inventory);
    }

    /**
    * Return if address is the company owner
    */
    function isCompanyOwner(string calldata _idCPMY, address _addr) internal view returns (bool) {
        return companies[_idCPMY].owner == _addr;
    }

    /**
    * Verify if is valid role
    */
    function isValidRole(Role storage _role) internal view returns(bool) {
        return !_role.revoked && _role.role[0] != 0;
    }

    /**
    * Verify if state is actived
    */
    function isActived(bytes32 state) internal pure returns(bool) {
        return state == ACTIVED_STATE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICompanyManager {
    /**
    * Events
    */
    event CompanyCreated(string id, string name, address owner, address inventory);
    event RoleGrantedToAddrs(string id, address[] addrs, bytes32 role, address creator);
    event RoleGrantedToAddr(string id, address addr, bytes32 role);
    event CompanyInventoryUpdated(string id, address inventory);

    /**
    * Functions
    */
    function addCompany(string calldata _idCPMY, string calldata _name, address _owner, address _inventory) external returns (bool);
    function grantRoleToAddrs(string calldata _idCPMY, address[] calldata _addrs, bytes32 _role, address _creator) external;
    function grantRoleToAddr(string calldata _idCPMY, address _addr, bytes32 _role, address _creator) external;
    function revokeAddrRole(string calldata _idCPMY, address _addr, bytes32 _role) external;
    function hasAddrRole(string calldata _idCPMY, address _addr, bytes32 _role) external view returns (bool);
    function isAbleToCreate(string calldata _idCPMY, address _addr) external view returns (bool);
    function isAbleToUpdate(string calldata _idCPMY, address _addr) external view returns (bool);
    function isAbleToDelete(string calldata _idCPMY, address _addr) external view returns (bool);
    function isAbleToTransfer(string calldata _idCPMY, address _addr) external view returns (bool);
    function setCompanyInventory(string calldata _idCPMY, address _inventory) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Adminable is Ownable, AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyOwnerOrAdmin() {
        require(
            owner() == _msgSender() ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Adminable: caller is not the owner or admin"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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