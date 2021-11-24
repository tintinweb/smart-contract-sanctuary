/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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




/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IAccessControl.sol";
////import "../utils/Context.sol";
////import "../utils/Strings.sol";
////import "../utils/introspection/ERC165.sol";

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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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




/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


/** 
 *  SourceUnit: /home/edusu/open/biomasa/c/contracts/contracts/HashRegister.sol
*/

pragma solidity >=0.8.0 <0.9.0;

////import "@openzeppelin/contracts/security/Pausable.sol";
////import "@openzeppelin/contracts/access/AccessControl.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";

///@title HashRegister
///@notice Contrato para el registro de hashes
contract HashRegister is Pausable, Ownable, AccessControl {

    struct HashBlockNumer {
        bytes32 hash;
        uint256 blockNumber;
    }

    bytes32 private constant USER_ROLE = keccak256("USER_ROLE");


    mapping(bytes32 => uint256) private timestampByHash;
    mapping(bytes32 => HashBlockNumer []) private bnHistoryById;
    mapping(bytes32 => HashBlockNumer) private id2hash;

    constructor() {
        _setupRole(USER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ///@notice Registra un hash sin asociarlo a ningun ID.
    ///@param huella El hash a registrar
    ///@dev El parametro {_hash} no puede ser cero.
    function registerHash(bytes32 huella) public whenNotPaused onlyRole(USER_ROLE) {
        require (huella != 0);
        if(timestampByHash[huella] == 0) {
            timestampByHash[huella] = block.timestamp;
        }
    }

    ///@notice Registra un hash asociandolo a un ID externo. 
    ///@param huella El hash a registrar. No puede ser cero.
    ///@param externalId El id externo al que se va a asociar el hash. Por ejemplo su identificador en la base de datos. No puede ser cero.
    ///@param appId El nombre de la aplicacion que registra el hash: Xej:Biomasa. No puede ser cero.
    ///@dev Se recomienda el que se garantice que el ID sea único.
    function registerHashWithId(bytes32 huella, string calldata externalId, string calldata appId) external whenNotPaused onlyRole(USER_ROLE){
        require(!isEmpty(appId) && !isEmpty(externalId));
        registerHash(huella);

        bytes32 id = keccak256(abi.encode(appId, externalId));
        HashBlockNumer memory actual = id2hash[id];
        bool esPrimeraVez = (actual.blockNumber == 0);

        id2hash[id] = HashBlockNumer(huella, block.number);

        if(!esPrimeraVez && actual.hash != huella) {
            HashBlockNumer [] storage history = bnHistoryById[id];
            history.push(actual);
        }
    }



    ///@notice Devuelve el timestamp asociado a un hash, si este hash está almacenado en el SC, en otro caso devuelve cero.
    ///@param huella El hash a buscar
    function getTimestampByHash(bytes32 huella) public view returns (uint256 timestamp) {
        return timestampByHash[huella];
    }
    
    ///@notice Devuelve el último hash asociado a un ID y su timestamp si el ID tiene algún hash almacenado en el SC, en otro caso devuelve (0 - 0).
    ///@param externalId El id externo por el que buscar el hash. Por ejemplo su identificador en la base de datos
    ///@param appId El nombre de la aplicacion que registró el hash: Xej:Biomasa
    ///@return huella El hash asociado al id 
    ///@return timestamp El timestamp en el que se registró el hash 
    ///@return hasOlderVersions Boolean true si tiene versiones pasadas ,false en caso contrario
    function getHashById(string calldata externalId, string calldata appId) external view returns (bytes32 huella, uint256 timestamp, bool hasOlderVersions) {
        bytes32 id = keccak256(abi.encode(appId, externalId));

        HashBlockNumer memory actual = id2hash[id];
        uint256 ts = getTimestampByHash(actual.hash);

        HashBlockNumer [] memory history = bnHistoryById[id];
        bool tieneVersionesAntiguas = (history.length > 0);

        return (actual.hash, ts, tieneVersionesAntiguas);
    }

    ///@notice Devuelve el historico de hashes asociado a un ID si el ID tiene algún hash almacenado en el SC, en otro caso devuelve un array vacio.
    ///@param externalId El id externo por el que buscar el hash. Por ejemplo su identificador en la base de datos
    ///@param appId El nombre de la aplicacion que registró el hash: Xej:Biomasa
    ///@return hashes Información de los hashes y su número de bloque de ethereum asociado
    function getHashesHistoryById(string calldata externalId, string calldata appId) external view returns (HashBlockNumer [] memory hashes) {
        bytes32 id = keccak256(abi.encode(appId, externalId));
        HashBlockNumer memory current = id2hash[id]; 
        if (current.blockNumber == 0) {
            return new HashBlockNumer [] (0);
        }

        HashBlockNumer [] storage history = bnHistoryById[id];
        HashBlockNumer [] memory arrayHistorico = new HashBlockNumer [] (history.length + 1);

        for (uint256 i = 0; i<arrayHistorico.length-1; i++) {
                arrayHistorico[i] = history[i];
        }
        arrayHistorico[arrayHistorico.length-1] = current;

        return arrayHistorico;
    }

    ///@notice Transfiere la propiedad del contrato a la address especificada
    ///@param newOwner La address del nuevo propietario
    ///@dev La address del nuevo propietario no puede ser la misma que el actual, además tampoco puede ser cero.
    function transferOwnership(address newOwner) public override onlyOwner {
        require(msg.sender != newOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(USER_ROLE, newOwner);
        super.transferOwnership(newOwner);
        super.revokeRole(USER_ROLE, msg.sender);
        super.revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ///@notice Asigna un rol a una cuenta espeficica
    ///@param role El rol a asignar
    ///@param account La cuenta a la cual se va a asignar el rol
    ///@dev El rol de DEFAULT_ADMIN_ROLE no puede ser asignado de esta manera.
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(role != DEFAULT_ADMIN_ROLE);
        super.grantRole(role, account);
    }

    ///@notice Añade el rol USER_ROLE A la address especificada
    ///@param _userAddress La cuenta a la cual se va a dar el rol USER_ROLE
    function grantUserRole(address _userAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(USER_ROLE, _userAddress);
    }

    ///@notice Elimina el rol especificado de la cuenta especificada.
    ///@param role El rol a eliminar
    ///@param account La cuenta de la cual se va a eliminar el rol
    ///@dev El rol de DEFAULT_ADMIN_ROLE no puede ser revocado de esta manera.
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(role != DEFAULT_ADMIN_ROLE); //sobrescribir grantrole
        super.revokeRole(role, account);
    }

    ///@notice Pausa el contrato bloqueando aquellas funciones que requieran que el contrato esté activo para ejecutarse.
    ///@dev aquellas funciones maracdas con el decorador WhenNotPaused revertirán si son llamadas con el contrato pausado.
    function pause() external onlyOwner {
        _pause();
    }

    ///@notice Activa el contrato desbloqueando aquellas funciones que requieran que el contrato esté activo para ejecutarse.
    ///@dev aquellas funciones marcadas con el decorador WhenNotPaused revertirán si son llamadas con el contrato pausado.
    function unpause() external onlyOwner {
        _unpause();
    }

    ///@notice Funcion que determina si un string está vacío o no
    ///@param str El string a comprobar
    ///@return True si el string está vacío, False en otro caso.
    function isEmpty(string memory str) private pure returns (bool){
        bytes memory tempEmptyStringTest = bytes(str); 
        return tempEmptyStringTest.length == 0;
    }

}