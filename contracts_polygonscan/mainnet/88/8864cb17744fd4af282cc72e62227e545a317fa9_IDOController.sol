// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../vesting/FixedPoolLinearVesting.sol";
import "../IDOPool/IFixedPool.sol";
import "../PowerController/IPowerController.sol";
import "../vesting/IVesting.sol";
import "../Proxy/BeaconProxy.sol";
import "../Loggers/ILogger.sol";

contract IDOController is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    modifier validateProjectIndex(uint256 projectIndex) {
        require(
            projectIndex < _projectIndex,
            "IDOCOntroller: Pool does not exist"
        );
        _;
    }

    //Contracts
    address private _powerController;
    address private _kycContract;
    address private _beacon;
    ILogger private _logger;

    //Events
    event ScheduleIDO(
        uint256 indexed projectIndex,
        address indexed token,
        uint256 totalTokens,
        uint256 start,
        uint256 end
    );
    event UpdateIDO(
        uint256 indexed projectIndex,
        address indexed token,
        uint256 totalTokens,
        uint256 start,
        uint256 end
    );
    event StartIDO(address indexed idoPoolAddress, uint256 indexed poolId);
    event EndIDO(
        uint256 indexed idoIndex,
        address indexed poolBeneficiary,
        address indexed tokenSource,
        address vestingAddress
    );
    event RevokeIDO(uint256 indexed idoIndex);
    event SetKYCContract(address kycContractAddress);
    event SetLoggerContract(address loggerAddress);
    event SetPowerContract(address powerControllerAddress);
    event SetBeaconContract(address beaconAddress);

    struct IDO {
        address token; // 20 bytes 12 free
        address poolContract; // 20bytes
        address vestingContract; // 20bytes
        bool isRevoked; // 1bit
        bool isStarted; // 1bit
        bool isEnded; // 1bit
        uint256 totalTokens; // 32 taken
        uint64 start; // 8bytes 24 free
        uint64 end; // 8bytes
    }
    uint256 private _projectIndex;
    mapping(uint256 => IDO) private _idos;

    function initialize(address beacon) public initializer {
        require(
            Address.isContract(beacon),
            "ERC1967: provided beacon is not a contract"
        );
        _beacon = beacon;
        _projectIndex = 0;
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function scheduleIDO(
        address token,
        uint256 totalTokens,
        uint64 start,
        uint64 end
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        {
            IDO memory newIdo =
                IDO(
                    token,
                    address(0),
                    address(0),
                    false,
                    false,
                    false,
                    totalTokens,
                    start,
                    end
                );
            _idos[_projectIndex] = newIdo;
        }

        emit ScheduleIDO(_projectIndex++, token, totalTokens, start, end);
    }

    function updateScheduledIDO(
        uint256 projectIndex,
        address token,
        uint256 totalTokens,
        uint64 start,
        uint64 end
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IDO storage ido = _idos[projectIndex];
        ido.start = start;
        ido.end = end;
        ido.token = token;
        ido.totalTokens = totalTokens;

        emit UpdateIDO(projectIndex, token, totalTokens, start, end);
    }

    function startIDO(
        uint256 idoIndex,
        bytes calldata poolData,
        bytes32 poolTemplateId,
        bytes[] calldata tokenSwapRates
    ) external onlyRole(DEFAULT_ADMIN_ROLE) validateProjectIndex(idoIndex) {
        IDO storage ido = _idos[idoIndex];
        require(!ido.isRevoked, "IDO Controller:IDO is revoked");
        require(!ido.isStarted, "IDO Controller:IDO is already started");
        require(
            ido.start > 0 && block.number >= ido.start,
            "IDO Controller:IDO cannot be started yet"
        );
        ido.isStarted = true;
        // create and deploy a proxy pointing to the instance by checing type
        BeaconProxy IDOProxy = new BeaconProxy(_beacon, poolTemplateId);
        ido.poolContract = address(IDOProxy);
        IFixedPool(address(IDOProxy)).initialize(
            idoIndex,
            msg.sender,
            ido.end,
            _powerController,
            _kycContract,
            _logger
        );
        IFixedPool(address(IDOProxy)).setupPool(tokenSwapRates, poolData);
        _logger.grantIDORole(address(IDOProxy), idoIndex);

        IPowerController(_powerController).grantRole(
            keccak256("POOL_ROLE"),
            address(IDOProxy)
        );

        emit StartIDO(address(IDOProxy), idoIndex);
    }

    function endIDO(
        uint256 idoIndex,
        bytes32 whitelistedRoot,
        bytes32 nonWhitelistedRoot,
        address poolBeneficiary,
        address tokenSource,
        bytes calldata vestingData,
        bytes[] calldata tokenDisperseData,
        bytes32 vestingTemplateId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) validateProjectIndex(idoIndex) {
        IDO storage ido = _idos[idoIndex];
        require(ido.isStarted, "IDO is not started yet");
        require(!ido.isEnded, "IDO already ended");
        require(
            ido.end < block.number,
            "IDOController: IDO Cannot be ended yet"
        );
        require(
            poolBeneficiary != address(0),
            "IDOController: Beneficiary not set correctly"
        );
        IFixedPool(ido.poolContract).endIDO(
            poolBeneficiary,
            tokenDisperseData,
            nonWhitelistedRoot
        );
        BeaconProxy VestingProxy = new BeaconProxy(_beacon, vestingTemplateId);
        IVesting(address(VestingProxy)).initialize(
            idoIndex,
            msg.sender,
            _logger
        );
        _logger.grantVestingRole(address(VestingProxy));
        IVesting(address(VestingProxy)).startVesting(
            ido.token,
            whitelistedRoot,
            vestingData
        );
        ido.vestingContract = address(VestingProxy);
        ido.isEnded = true;
        IERC20(ido.token).safeTransferFrom(
            tokenSource,
            address(VestingProxy),
            ido.totalTokens
        );

        emit EndIDO(
            idoIndex,
            poolBeneficiary,
            tokenSource,
            address(VestingProxy)
        );
    }

    function revokeIDO(uint256 idoIndex)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        validateProjectIndex(idoIndex)
    {
        IDO storage ido = _idos[idoIndex];
        require(block.number < ido.start, "IDO Controller:IDO already started");
        ido.isRevoked = true;

        emit RevokeIDO(idoIndex);
    }

    function setPowerController(address powerController)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            powerController != address(0),
            "IDOController: powerController is a zero address"
        );
        _powerController = powerController;
        emit SetPowerContract(powerController);
    }

    function setKYCContract(address kycContractAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            kycContractAddress != address(0),
            "IDOController: kycContractAddress is a zero address"
        );
        _kycContract = kycContractAddress;
        emit SetKYCContract(kycContractAddress);
    }

    function setLoggerContract(address logger)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            logger != address(0),
            "IDOController: Logger is a zero address"
        );
        _logger = ILogger(logger);
        emit SetLoggerContract(logger);
    }

    function setBeacon(address beacon) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            Address.isContract(beacon),
            "ERC1967: provided beacon is not a contract"
        );
        _beacon = beacon;
        emit SetBeaconContract(beacon);
    }

    function getPowerController() external view returns (address) {
        return _powerController;
    }

    function getLoggerContract() external view returns (address) {
        return address(_logger);
    }

    function getKYCContract() external view returns (address) {
        return _kycContract;
    }

    function getIDOVestingContract(uint256 idoIndex)
        external
        view
        returns (address)
    {
        return _idos[idoIndex].vestingContract;
    }

    function getIDOPoolContract(uint256 idoIndex)
        external
        view
        returns (address)
    {
        return _idos[idoIndex].poolContract;
    }

    function getIDOToken(uint256 idoIndex) external view returns (address) {
        return _idos[idoIndex].token;
    }

    function getIDOStart(uint256 idoIndex) external view returns (uint256) {
        return _idos[idoIndex].start;
    }

    function getIDOEnd(uint256 idoIndex) external view returns (uint256) {
        return _idos[idoIndex].end;
    }

    function getIsIDORevoked(uint256 idoIndex) external view returns (bool) {
        return _idos[idoIndex].isRevoked;
    }

    function getIsIDOStarted(uint256 idoIndex) external view returns (bool) {
        return _idos[idoIndex].isStarted;
    }

    function getIsIDOEnded(uint256 idoIndex) external view returns (bool) {
        return _idos[idoIndex].isEnded;
    }

    function getBeacon() external view returns (address) {
        return _beacon;
    }

    function getNextProjectIndex() external view returns (uint256) {
        return _projectIndex;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
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
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ILogger} from "../Loggers/ILogger.sol";

import "./IVesting.sol";

/**
 * @title FixedPoolLinearVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme.
 */
contract FixedPoolLinearVesting is
    Initializable,
    AccessControlUpgradeable,
    IVesting
{
    using SafeERC20 for IERC20;
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    //Private Variabels

    IERC20 private _token;
    ILogger private _logger;
    uint256 private _releasePerBlock;
    uint256 private _firstRelease;
    uint256 private _start;
    uint256 private _end;
    uint256 private _userAllocation;
    mapping(address => uint256) private _tokensClaimed;
    //merkle
    bytes32 private _whitelistedMerkleRoot;
    uint256 private _projectIndex;

    // modifiers

    modifier whitelistedMembersOnly(
        address user,
        bytes32[] memory merkleProof
    ) {
        require(
            verifyWhitelistProof(user, merkleProof),
            "FixedPoolLinearVesting:Invalid Proof"
        );
        _;
    }

    function initialize(uint256 projectIndex, address admin, ILogger logger)
        external
        override
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(CONTROLLER_ROLE, msg.sender);
        _projectIndex = projectIndex;
        _logger = logger;
    }

    function startVesting(
        address token,
        bytes32 whitelistedUsersMerkleRoot,
        bytes memory vestingData
    ) external override onlyRole(CONTROLLER_ROLE) {
        (
            uint256 start,
            uint256 firstRelease,
            uint256 releasePerBlock,
            uint256 userAllocation
        ) = abi.decode(vestingData, (uint256, uint256, uint256, uint256));
        require(
            token != address(0),
            "FixedPoolLinearVesting: token is the zero address!"
        );
        require(
            firstRelease <= userAllocation,
            "FixedPoolLinearVesting:First Release cannot be larger than user allocation"
        );
        require(
            (userAllocation == firstRelease) ||
            (start + ((userAllocation - firstRelease) / releasePerBlock) >= block.number),
            "FixedPoolLinearVesting: end block cannot be lesser than the current block"
        );
        require(
            releasePerBlock >= 0,
            "FixedPoolLinearVesting:Bad release per block"
        );
        require(
            userAllocation > 0,
            "FixedPoolLinearVesting:Bad User Allocation"
        );

        _token = IERC20(token);
        _start = start;
        _end = userAllocation == firstRelease ? start : start + ((userAllocation - firstRelease) / releasePerBlock); // gotta make sure this comes out to be a perfect block number.
        _releasePerBlock = releasePerBlock;
        _firstRelease = firstRelease;
        _userAllocation = userAllocation;
        _whitelistedMerkleRoot = whitelistedUsersMerkleRoot;

        //Emit event
        _logger.emitVestingStarted(token, address(this), start, _end, releasePerBlock, firstRelease, userAllocation);
    }

    // public Functions

    function verifyWhitelistProof(address user, bytes32[] memory merkleProof)
        public
        view
        returns (bool)
    {
        return
            MerkleProofUpgradeable.verify(
                merkleProof,
                _whitelistedMerkleRoot,
                bytes32(uint256(uint160(user)))
            );
    }

    function firstClaim(address user, bytes32[] memory merkleProof)
        external
        whitelistedMembersOnly(user, merkleProof)
    {
        //release any tokens possible till now.
        uint256 claimableTokens = _getClaimableTokens(user);
        require(
            claimableTokens > 0,
            "FixedPoolLinearVesting:No tokens left to claim"
        );
        _tokensClaimed[user] = _tokensClaimed[user] + claimableTokens;
        //transfer these tokens to the user now.
        _token.safeTransfer(user, claimableTokens);

        //Emit event.
        _logger.emitVestingClaimed(address(_token), address(this), user, claimableTokens);
    }

    function claim(address user) external {
        //release any tokens possible till now.
        require(
            _tokensClaimed[user] > 0,
            "FixedPoolLinearVesting:Not eligible"
        );
        uint256 claimableTokens = _getClaimableTokens(user);
        require(
            claimableTokens > 0,
            "FixedPoolLinearVesting:No tokens left to claim"
        );
        _tokensClaimed[user] = _tokensClaimed[user] + claimableTokens;

        //transfer these tokens to the user now.
        _token.safeTransfer(user, claimableTokens);

        //Emit Event
        _logger.emitVestingClaimed(address(_token), address(this), user, claimableTokens);
    }

    function _getClaimableTokens(address user) private view returns (uint256) {
        uint256 vestedAmount = _getTotalVested();
        uint256 claimableTokens = vestedAmount - _tokensClaimed[user];
        return claimableTokens;
    }

    function _getTotalVested() private view returns (uint256) {
        require(
            block.number > _start,
            "FixedPoolLinearVesting:Nothing to claim yet"
        );
        uint256 totalVested =
            _firstRelease + (block.number - _start) * _releasePerBlock;
        if (totalVested > _userAllocation) return _userAllocation;
        else return totalVested;
    }

    // public getters

    // This will always return an amount whether the user is eligible or not.
    // The eligibility will be checked only while trying to withdraw or from an offchain db
    function getClaimableTokens(address user) external view returns (uint256) {
        return _getClaimableTokens(user);
    }

    function getUserAllocation() external view returns (uint256) {
        return _userAllocation;
    }

    function getStartBlock() external view returns (uint256) {
        return _start;
    }

    function getReleasePerBlock() external view returns (uint256) {
        return _releasePerBlock;
    }

    function getFirstRelease() external view returns (uint256) {
        return _firstRelease;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return _whitelistedMerkleRoot;
    }

    function getClaimedTokens(address user) external view returns (uint256) {
        return _tokensClaimed[user];
    }

    function getProjectIndex() external view returns (uint256) {
        return _projectIndex;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import {ILogger} from "../Loggers/ILogger.sol";

interface IFixedPool {
    function endIDO(
        address beneficiaryAddress,
        bytes[] memory tokenDisperseData,
        bytes32 merkleRoot
    ) external;

    function initialize(
        uint256 projectIndex,
        address admin,
        uint256 idoEnd,
        address powerContract,
        address kycContract,
        ILogger logger
    ) external;

    function setupPool(
        bytes[] memory tokenSwapRates,
        bytes memory poolData // contains maxTokens
    ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract IPowerController {
    function increasePower(
        address user,
        uint256 power,
        bytes32 reason
    ) external virtual;

    function decreasePower(
        address user,
        uint256 power,
        bytes32 reason
    ) external virtual;

    function lockPower(address user, uint256 power) external virtual;

    function unlockPower(address user, uint256 power) external virtual;

    function unlockFullPower(address user) external virtual;

    function grantRole(bytes32 role, address account) external virtual;

    function initialize(address idoControllerAddress) public virtual;

    // ------ external Getter Functions ------

    function getTotalPower() external view virtual returns (uint256);

    function getUserTotalPower(address user)
        external
        view
        virtual
        returns (uint256);

    function getGeneratedManagerPower(address user, address manager)
        external
        view
        virtual
        returns (uint256);

    function getLockedPoolPower(address user, address pool)
        external
        view
        virtual
        returns (uint256);

    function getLockedPower(address user)
        external
        view
        virtual
        returns (uint256);

    function getUnlockedPower(address user)
        external
        view
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import {ILogger} from "../Loggers/ILogger.sol";

interface IVesting {
    function initialize(uint256 projectIndex, address admin, ILogger logger) external;

    function startVesting(
        address token,
        bytes32 whitelistedUsersMerkleRoot,
        bytes memory vestingData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    bytes32 public immutable templateId;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(
        address beacon,
        // bytes memory data,
        bytes32 templateId_
    ) payable {
        assert(
            _BEACON_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1)
        );
        templateId = templateId_;
        _setBeacon(beacon, templateId_);
        emit BeaconUpgraded(beacon);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return IBeacon(_getBeacon()).implementation(templateId);
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon, bytes32 templateId_) private {
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(newBeacon).implementation(templateId_)),
            "ERC1967: beacon implementation with provided template is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ILogger {
    function initialize(address idoControllerAddress) public virtual;

    function grantIDORole(address idoPoolAddress, uint256 idoIndex) external virtual;

    function grantVestingRole(address vestingAddress) external virtual;

    function emitLockFundMatic(
        uint256 amount,
        address user
    ) external virtual;

    function emitLockFund(
        uint256 amount,
        address user,
        address tokenAddress
    ) external virtual;

    function emitUnlockFundMatic(
        uint256 amount,
        address user
    ) external virtual;

    function emitUnlockFund(
        uint256 amount,
        address user,
        address tokenAddress
    ) external virtual;

    function emitTransferMaticFundToBeneficiary(
        uint256 amount,
        address projectAddress
    ) external virtual;

    function emitTransferFundToBeneficiary(
        uint256 amount,
        address projectAddress,
        address tokenAddress
    ) external virtual;

    function emitVestingStarted(
        address tokenAddress,
        address vestingContract,
        uint256 startBlock,
        uint256 endBlock,
        uint256 releasePerBlock,
        uint256 firstRelease,
        uint256 userAllocation
    ) external virtual;

    function emitVestingFirstClaim(
        address tokenAddress,
        address vestingContract,
        address user,
        uint256 amount
    ) external virtual;

    function emitVestingClaimed(
        address tokenAddress,
        address vestingContract,
        address user,
        uint256 amount
    ) external virtual;

    function emitPolysVestingStarted(
        address tokenAddress,
        bytes32 whitelistedUsersMerkleRoot,
        bytes calldata vestingData
    ) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./IBeacon.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting =
            StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(
                oldImplementation == _getImplementation(),
                "ERC1967Upgrade: upgrade breaks further upgrades"
            );
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    //TODO override this??

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            // Address.functionDelegateCall(
            //     IBeacon(newBeacon).implementation(),
            //     data
            // );
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) internal virtual {
        // require(
        //     Address.isContract(newBeacon),
        //     "ERC1967: new beacon is not a contract"
        // );
        // require(
        //     Address.isContract(IBeacon(newBeacon).implementation()),
        //     "ERC1967: beacon implementation is not a contract"
        // );
        // StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation(bytes32 templateId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}