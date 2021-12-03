// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./AggregatorBase.sol";
import "../interfaces/ISignatureVerifier.sol";
import "../libraries/SignatureUtil.sol";

contract SignatureVerifier is AggregatorBase, ISignatureVerifier {
    using SignatureUtil for bytes;
    using SignatureUtil for bytes32;

    /* ========== STATE VARIABLES ========== */
    /// @dev Number of required confirmations per block after the extra check is enabled
    uint8 public confirmationThreshold;
    /// @dev submissions count in current block
    uint40 public submissionsInBlock;
    /// @dev Current block
    uint40 public currentBlock;

    /// @dev Debridge gate address
    address public debridgeAddress;

    /* ========== ERRORS ========== */

    error NotConfirmedByRequiredOracles();
    error NotConfirmedThreshold();
    error SubmissionNotConfirmed();
    error DuplicateSignatures();

    /* ========== MODIFIERS ========== */

    modifier onlyDeBridgeGate() {
        if (msg.sender != debridgeAddress) revert DeBridgeGateBadRole();
        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    /// @dev Constructor that initializes the most important configurations.
    /// @param _minConfirmations Common confirmations count.
    /// @param _confirmationThreshold Confirmations per block after the extra check is enabled.
    /// @param _excessConfirmations Confirmations count in case of excess activity.
    function initialize(
        uint8 _minConfirmations,
        uint8 _confirmationThreshold,
        uint8 _excessConfirmations,
        address _debridgeAddress
    ) public initializer {
        AggregatorBase.initializeBase(_minConfirmations, _excessConfirmations);
        confirmationThreshold = _confirmationThreshold;
        debridgeAddress = _debridgeAddress;
    }


    /// @inheritdoc ISignatureVerifier
    function submit(
        bytes32 _submissionId,
        bytes memory _signatures,
        uint8 _excessConfirmations
    ) external override onlyDeBridgeGate {
        //Need confirmation to confirm submission
        uint8 needConfirmations = _excessConfirmations > minConfirmations
        ? _excessConfirmations
        : minConfirmations;
        // Count of required(DSRM) oracles confirmation
        uint256 currentRequiredOraclesCount;
        // stack variable to aggregate confirmations and write to storage once
        uint8 confirmations;
        uint256 signaturesCount = _countSignatures(_signatures);
        address[] memory validators = new address[](signaturesCount);
        for (uint256 i = 0; i < signaturesCount; i++) {
            (bytes32 r, bytes32 s, uint8 v) = _signatures.parseSignature(i * 65);
            address oracle = ecrecover(_submissionId.getUnsignedMsg(), v, r, s);
            if (getOracleInfo[oracle].isValid) {
                for (uint256 k = 0; k < i; k++) {
                    if (validators[k] == oracle) revert DuplicateSignatures();
                }
                validators[i] = oracle;

                confirmations += 1;
                emit Confirmed(_submissionId, oracle);
                if (getOracleInfo[oracle].required) {
                    currentRequiredOraclesCount += 1;
                }
                if (
                    confirmations >= needConfirmations &&
                    currentRequiredOraclesCount >= requiredOraclesCount
                ) {
                    break;
                }
            }
        }

        if (currentRequiredOraclesCount != requiredOraclesCount)
            revert NotConfirmedByRequiredOracles();

        if (confirmations >= minConfirmations) {
            if (currentBlock == uint40(block.number)) {
                submissionsInBlock += 1;
            } else {
                currentBlock = uint40(block.number);
                submissionsInBlock = 1;
            }
            emit SubmissionApproved(_submissionId);
        }

        if (submissionsInBlock > confirmationThreshold) {
            if (confirmations < excessConfirmations) revert NotConfirmedThreshold();
        }

        if (confirmations < needConfirmations) revert SubmissionNotConfirmed();
    }

    /* ========== ADMIN ========== */

    /// @dev Sets minimal required confirmations.
    /// @param _confirmationThreshold Confirmation info.
    function setThreshold(uint8 _confirmationThreshold) external onlyAdmin {
        if (_confirmationThreshold == 0) revert WrongArgument();
        confirmationThreshold = _confirmationThreshold;
    }

    /// @dev Sets core debridge conrtact address.
    /// @param _debridgeAddress Debridge address.
    function setDebridgeAddress(address _debridgeAddress) external onlyAdmin {
        debridgeAddress = _debridgeAddress;
    }

    /* ========== VIEW ========== */

    /// @dev Check is valid signature
    /// @param _submissionId Submission identifier.
    /// @param _signature signature by oracle.
    function isValidSignature(bytes32 _submissionId, bytes memory _signature)
    external
    view
    returns (bool)
    {
        (bytes32 r, bytes32 s, uint8 v) = _signature.splitSignature();
        address oracle = ecrecover(_submissionId.getUnsignedMsg(), v, r, s);
        return getOracleInfo[oracle].isValid;
    }

    /* ========== INTERNAL ========== */

    function _countSignatures(bytes memory _signatures) internal pure returns (uint256) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }

    // ============ Version Control ============
    /// @dev Get this contract's version
    function version() external pure returns (uint256) {
        return 101; // 1.0.1
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/IAggregatorBase.sol";

contract AggregatorBase is Initializable, AccessControlUpgradeable, IAggregatorBase {
    /* ========== STATE VARIABLES ========== */

    uint8 public minConfirmations; // minimal required confirmations
    uint8 public excessConfirmations; // minimal required confirmations in case of too many confirmations
    uint8 public requiredOraclesCount; // count of required oracles

    address[] public oracleAddresses;
    mapping(address => OracleInfo) public getOracleInfo; // oracle address => oracle details

    /* ========== ERRORS ========== */

    error AdminBadRole();
    error OracleBadRole();
    error DeBridgeGateBadRole();


    error OracleAlreadyExist();
    error OracleNotFound();

    error WrongArgument();
    error LowMinConfirmations();

    error SubmittedAlready();


    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }
    modifier onlyOracle() {
        if (!getOracleInfo[msg.sender].isValid) revert OracleBadRole();
        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    /// @dev Constructor that initializes the most important configurations.
    /// @param _minConfirmations Common confirmations count.
    function initializeBase(uint8 _minConfirmations, uint8 _excessConfirmations) internal {
        if (_minConfirmations == 0 || _excessConfirmations < _minConfirmations) revert LowMinConfirmations();
        minConfirmations = _minConfirmations;
        excessConfirmations = _excessConfirmations;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== ADMIN ========== */

    /// @dev Sets minimal required confirmations.
    /// @param _minConfirmations Confirmation info.
    function setMinConfirmations(uint8 _minConfirmations) external onlyAdmin {
        if (_minConfirmations < oracleAddresses.length / 2 + 1) revert LowMinConfirmations();
        minConfirmations = _minConfirmations;
    }

    /// @dev Sets minimal required confirmations.
    /// @param _excessConfirmations new excessConfirmations count.
    function setExcessConfirmations(uint8 _excessConfirmations) external onlyAdmin {
        if (_excessConfirmations < minConfirmations) revert LowMinConfirmations();
        excessConfirmations = _excessConfirmations;
    }

    /// @dev Add oracle.
    /// @param _oracles Oracles addresses.
    /// @param _required Without this oracle, the transfer will not be confirmed
    function addOracles(
        address[] memory _oracles,
        bool[] memory _required
    ) external onlyAdmin {
        if (_oracles.length != _required.length) revert WrongArgument();
        if (minConfirmations < (oracleAddresses.length +  _oracles.length) / 2 + 1) revert LowMinConfirmations();

        for (uint256 i = 0; i < _oracles.length; i++) {
            OracleInfo storage oracleInfo = getOracleInfo[_oracles[i]];
            if (oracleInfo.exist) revert OracleAlreadyExist();

            oracleAddresses.push(_oracles[i]);

            if (_required[i]) {
                requiredOraclesCount += 1;
            }

            oracleInfo.exist = true;
            oracleInfo.isValid = true;
            oracleInfo.required = _required[i];

            emit AddOracle(_oracles[i], _required[i]);
        }
    }

    /// @dev Update oracle.
    /// @param _oracle Oracle address.
    /// @param _isValid is valid oracle
    /// @param _required Without this oracle, the transfer will not be confirmed
    function updateOracle(
        address _oracle,
        bool _isValid,
        bool _required
    ) external onlyAdmin {
        //If oracle is invalid, it must be not required
        if (!_isValid && _required) revert WrongArgument();

        OracleInfo storage oracleInfo = getOracleInfo[_oracle];
        if (!oracleInfo.exist) revert OracleNotFound();

        if (oracleInfo.required && !_required) {
            requiredOraclesCount -= 1;
        } else if (!oracleInfo.required && _required) {
            requiredOraclesCount += 1;
        }
        if (oracleInfo.isValid && !_isValid) {
            // remove oracle from oracleAddresses array without keeping an order
            for (uint256 i = 0; i < oracleAddresses.length; i++) {
                if (oracleAddresses[i] == _oracle) {
                    oracleAddresses[i] = oracleAddresses[oracleAddresses.length - 1];
                    oracleAddresses.pop();
                    break;
                }
            }
        } else if (!oracleInfo.isValid && _isValid) {
            if (minConfirmations < (oracleAddresses.length + 1) / 2 + 1) revert LowMinConfirmations();
            oracleAddresses.push(_oracle);
        }
        oracleInfo.isValid = _isValid;
        oracleInfo.required = _required;
        emit UpdateOracle(_oracle, _required, _isValid);
    }


    /* ========== VIEW ========== */

    /// @dev Calculates asset identifier.
    function getDeployId(
        bytes32 _debridgeId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_debridgeId, _name, _symbol, _decimals));
    }

    /// @dev Calculates asset identifier.
    /// @param _chainId Current chain id.
    /// @param _tokenAddress Address of the asset on the other chain.
    function getDebridgeId(uint256 _chainId, bytes memory _tokenAddress)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_chainId, _tokenAddress));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISignatureVerifier {

    /* ========== EVENTS ========== */

    /// @dev Emitted once the submission is confirmed by one oracle.
    event Confirmed(bytes32 submissionId, address operator);
    /// @dev Emitted once the submission is confirmed by min required amount of oracles.
    event DeployConfirmed(bytes32 deployId, address operator);

    /* ========== FUNCTIONS ========== */

    /// @dev Check confirmation (validate signatures) for the transfer request.
    /// @param _submissionId Submission identifier.
    /// @param _signatures Array of signatures by oracles.
    /// @param _excessConfirmations override min confirmations count
    function submit(
        bytes32 _submissionId,
        bytes memory _signatures,
        uint8 _excessConfirmations
    ) external;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

library SignatureUtil {
    /* ========== ERRORS ========== */

    error WrongArgumentLength();
    error SignatureInvalidLength();
    error SignatureInvalidV();

    /// @dev Prepares raw msg that was signed by the oracle.
    /// @param _submissionId Submission identifier.
    function getUnsignedMsg(bytes32 _submissionId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _submissionId));
    }

    /// @dev Splits signature bytes to r,s,v components.
    /// @param _signature Signature bytes in format r+s+v.
    function splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (_signature.length != 65) revert SignatureInvalidLength();
        return parseSignature(_signature, 0);
    }

    function parseSignature(bytes memory _signatures, uint256 offset)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;
        if (v != 27 && v != 28) revert SignatureInvalidV();
    }

    function toUint256(bytes memory _bytes, uint256 _offset)
        internal
        pure
        returns (uint256 result)
    {
        if (_bytes.length < _offset + 32) revert WrongArgumentLength();

        assembly {
            result := mload(add(add(_bytes, 0x20), _offset))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAggregatorBase {
    /* ========== STRUCTS ========== */

    struct OracleInfo {
        bool exist; // exist oracle
        bool isValid; // is valid oracle
        bool required; // without this oracle (DSRM), the transfer will not be confirmed
    }

    /* ========== EVENTS ========== */

    event AddOracle(address oracle, bool required); // add oracle by admin
    event UpdateOracle(address oracle, bool required, bool isValid); // update oracle by admin
    event DeployApproved(bytes32 deployId); // emitted once the submission is confirmed by min required aount of oracles
    event SubmissionApproved(bytes32 submissionId); // emitted once the submission is confirmed by min required aount of oracles
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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