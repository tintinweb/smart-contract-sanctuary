/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

pragma solidity ^0.8.0;

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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]

pragma solidity ^0.8.0;

abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

pragma solidity ^0.8.0;


abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }


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
    uint256[49] private __gap;
}


// File contracts/Interfaces/ILosslessERC20.sol

pragma solidity 0.8.4;

interface ILERC20 {
    function name() external view returns (string memory);
    function admin() external view returns (address);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function getAdmin() external view returns (address);
    
    function transferOutBlacklistedFunds(address[] calldata from) external;
    function setLosslessAdmin(address newAdmin) external;
    function transferRecoveryAdminOwnership(address candidate, bytes32 keyHash) external;
    function acceptRecoveryAdminOwnership(bytes memory key) external;
    function proposeLosslessTurnOff() external;
    function executeLosslessTurnOff() external;
    function executeLosslessTurnOn() external;
}


// File contracts/Interfaces/ILosslessControllerV3.sol

pragma solidity 0.8.4;


interface ILssController {
    function getLockedAmount(address token, address account) external view returns (uint256);
    function getAvailableAmount(address token, address account) external view returns (uint256 amount);
    function retrieveBlacklistedFunds(address[] calldata _addresses, address token, uint256 reportId) external returns(uint256);
    function erroneousCompensation() external view returns (uint256);
    function reportLifetime() external returns (uint256);
    function stakeAmount() external view returns (uint256);
    function reportingAmount() external returns (uint256);
    function whitelist(address _adr) external view returns (bool);
    function dexList(address dexAddress) external returns (bool);
    function getReporterPayoutStatus(address _reporter, uint256 reportId) external view returns (bool);
    function setReporterPayoutStatus(address _reporter, bool status, uint256 reportId) external; 
    function blacklist(address _adr) external view returns (bool);
    function admin() external view returns (address);
    function pauseAdmin() external view returns (address);
    function recoveryAdmin() external view returns (address);
    function guardian() external view returns (address);
    function stakingToken() external view returns (address);
    function losslessStaking() external view returns (address);
    function losslessReporting() external view returns (address);
    function lockCheckpointExpiration() external view returns (uint256);
    function dexTranferThreshold() external view returns (uint256);
    function settlementTimeLock() external view returns (uint256);
    function tokenLockTimeframe(address token) external view returns (uint256);
    function proposedTokenLockTimeframe(address token) external view returns (uint256);
    function changeSettlementTimelock(address token) external view returns (uint256);
    function isNewSettlementProposed(address token) external view returns (bool);
    
    function pause() external;
    function unpause() external;
    function setAdmin(address newAdmin) external;
    function setRecoveryAdmin(address newRecoveryAdmin) external;
    function setPauseAdmin(address newPauseAdmin) external;
    function setStakingToken(address _stakingToken) external;
    function setSettlementTimeLock(uint256 newTimelock) external;
    function setDexTrasnferThreshold(uint256 newThreshold) external;
    function setCompensationAmount(uint256 amount) external;
    function setLocksLiftUpExpiration(uint256 time) external;
    function setDexList(address[] calldata _dexList, bool value) external;
    function setWhitelist(address[] calldata _addrList, bool value) external;
    function addToBlacklist(address _adr) external;
    function resolvedNegatively(address _adr) external;
    function setStakingContractAddress(address _adr) external;
    function setReportingContractAddress(address _adr) external; 
    function setGovernanceContractAddress(address _adr) external;
    function proposeNewSettlementPeriod(address token, uint256 _seconds) external;
    function executeNewSettlementPeriod(address token) external;
    function activateEmergency(address token) external;
    function deactivateEmergency(address token) external;
    function setGuardian(address newGuardian) external;
    function removeProtectedAddress(address token, address protectedAddresss) external;
    function beforeTransfer(address sender, address recipient, uint256 amount) external;
    function beforeTransferFrom(address msgSender, address sender, address recipient, uint256 amount) external;
    function beforeApprove(address sender, address spender, uint256 amount) external;
    function beforeIncreaseAllowance(address msgSender, address spender, uint256 addedValue) external;
    function beforeDecreaseAllowance(address msgSender, address spender, uint256 subtractedValue) external;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event PauseAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event GuardianSet(address indexed oldGuardian, address indexed newGuardian);
    event ProtectedAddressSet(address indexed token, address indexed protectedAddress, address indexed strategy);
    event RemovedProtectedAddress(address indexed token, address indexed protectedAddress);
    event NewSettlementPeriodProposed(address token, uint256 _seconds);
    event SettlementPeriodChanged(address token, uint256 proposedTokenLockTimeframe);
}


// File contracts/Interfaces/ILosslessStaking.sol

pragma solidity 0.8.4;

interface ILssStaking {
  function stakingToken() external returns(address);
  function losslessReporting() external returns(address);
  function losslessController() external returns(address);
  function losslessGovernance() external returns(address);
  function stakingAmount() external returns(uint256);
  function stakers() external returns(address[] memory);
  function totalStakedOnReport(uint256 reportId) external returns(uint256);
  function losslessPayed(uint256 reportId) external returns(bool);
  function getVersion() external pure returns (uint256);
  function getIsAccountStaked(uint256 reportId, address account) external view returns(bool);
  function getStakerCoefficient(uint256 reportId, address _address) external view returns (uint256);
  function stakerClaimableAmount(uint256 reportId) external view returns (uint256);
  
  function pause() external;
  function unpause() external;
  function setLssReporting(address _losslessReporting) external;
  function setStakingToken(address _stakingToken) external;
  function setLosslessGovernance(address _losslessGovernance) external;
  function setStakingAmount(uint256 _stakingAmount) external;
  function stake(uint256 reportId) external;
  function stakerClaim(uint256 reportId) external;
  function losslessClaim(uint256 reportId) external;

  event Staked(address indexed token, address indexed account, uint256 reportId);
}


// File contracts/Interfaces/ILosslessReporting.sol

pragma solidity 0.8.4;

interface ILssReporting {
  function reporterReward() external returns(uint256);
  function losslessReward() external returns(uint256);
  function stakersReward() external returns(uint256);
  function committeeReward() external returns(uint256);
  function reportLifetime() external view returns(uint256);
  function reportingAmount() external returns(uint256);
  function reportCount() external returns(uint256);
  function stakingToken() external returns(address);
  function losslessController() external returns(address);
  function losslessGovernance() external returns(address);
  function reporter(uint256 reportId) external returns(address);
  function reportedAddress(uint256 reportId) external returns(address);
  function secondReportedAddress(uint256 reportId) external returns(address);
  function reportTimestamps(uint256 reportId) external view returns(uint256);
  function reportTokens(uint256 reportId) external returns(address);
  function secondReports(uint256 reportId) external returns(bool);
  function getVersion() external pure returns (uint256);
  function getRewards() external view returns (uint256 reporter, uint256 lossless, uint256 committee, uint256 stakers);
  function report(address token, address account) external returns (uint256);
  function reporterClaimableAmount(uint256 reportId) external view returns (uint256);
  
  function pause() external;
  function unpause() external;
  function setStakingToken(address _stakingToken) external;
  function setLosslessGovernance(address _losslessGovernance) external;
  function setReportingAmount(uint256 _reportingAmount) external;
  function setReporterReward(uint256 reward) external;
  function setLosslessReward(uint256 reward) external;
  function setStakersReward(uint256 reward) external;
  function setCommitteeReward(uint256 reward) external;
  function setReportLifetime(uint256 _lifetime) external;
  function secondReport(uint256 reportId, address account) external;
  function reporterClaim(uint256 reportId) external;
  function retrieveCompensation(address adr, uint256 amount) external;

  event ReportSubmitted(address indexed token, address indexed account, uint256 reportId);
  event SecondReportsubmitted(address indexed token, address indexed account, uint256 reportId);
  event ReportingAmountChanged(uint256 indexed newAmount);
}


// File contracts/LosslessGovernance.sol

pragma solidity 0.8.4;

contract LosslessGovernance is Initializable, AccessControlUpgradeable, PausableUpgradeable {

    uint256 public lssTeamVoteIndex;
    uint256 public tokenOwnersVoteIndex;
    uint256 public committeeVoteIndex;

    bytes32 private constant COMMITTEE_ROLE = keccak256("COMMITTEE_ROLE");

    uint256 public committeeMembersCount;

    uint256 public walletDisputePeriod;

    ILssReporting public losslessReporting;
    ILssController public losslessController;
    ILssStaking public losslessStaking;

    struct Vote {
        mapping(address => bool) committeeMemberVoted;
        mapping(address => bool) committeeMemberClaimed;
        bool[] committeeVotes;
        bool[3] votes;
        bool[3] voted;
        bool resolved;
        bool resolution;
    }

    mapping(uint256 => Vote) public reportVotes;
    mapping(uint256 => uint256) public amountReported;
    mapping(uint256 => uint256) private retrievalAmount;

    mapping(uint256 => ProposedWallet) public proposedWalletOnReport;

    mapping(uint256 => bool) public losslessPayed;

    struct ProposedWallet {
        uint16 proposal;
        address wallet;
        uint256 timestamp;
        bool status;
        bool losslessVote;
        bool losslessVoted;
        bool tokenOwnersVote;
        bool tokenOwnersVoted;
        bool walletAccepted;
        uint16 committeeDisagree;
        mapping (uint16 => MemberVotesOnProposal) memberVotesOnProposal;
    }

    struct Compensation {
        uint256 amount;
        bool payed;
    }

    struct MemberVotesOnProposal {
        mapping (address => bool) memberVoted;
    }

    mapping(address => Compensation) private compensation;

    address[] private reportedAddresses;

    event NewCommitteeMembers(address[] indexed members);
    event CommitteeMembersRemoved(address[] indexed members);
    event LosslessTeamVoted(uint256 indexed reportId, bool indexed vote);
    event TokenOwnersVoted(uint256 indexed reportId, bool indexed vote);
    event CommitteeMemberVoted(uint256 indexed reportId, address indexed member, bool indexed vote);
    event ReportResolved(uint256 indexed reportId, bool indexed resolution);
    event WalletProposed(uint256 indexed reportId, address indexed wallet);
    event WalletRejected(uint256 indexed reportId, address indexed wallet);
    event FundsRetrieved(uint256 indexed reportId, address indexed wallet);
    event CompensationRetrieved(address indexed wallet, uint256 indexed amount);
    event LosslessClaimed(address indexed token, uint256 indexed reportID, uint256 indexed amount);
    event CommitteeMemberClaimed(uint256 indexed reportID, address indexed member, uint256 indexed amount);
    event CommitteeMajorityReached(uint256 indexed reportId, bool indexed result);

    function initialize(address _losslessReporting, address _losslessController, address _losslessStaking) public initializer {
        losslessReporting = ILssReporting(_losslessReporting);
        losslessController = ILssController(_losslessController);
        losslessStaking = ILssStaking(_losslessStaking);
        walletDisputePeriod = 7 days;
        tokenOwnersVoteIndex = 1;
        committeeVoteIndex = 2;
        _setupRole(DEFAULT_ADMIN_ROLE, losslessController.admin());
    }

    modifier onlyLosslessAdmin() {
        require(losslessController.admin() == msg.sender, "LSS: Must be admin");
        _;
    }

    // --- ADMINISTRATION ---

    function pause() public onlyLosslessAdmin  {
        _pause();
    }    
    
    function unpause() public onlyLosslessAdmin {
        _unpause();
    }

    
    /// @notice This function gets the contract version
    /// @return Version of the contract
    function getVersion() external pure returns (uint256) {
        return 1;
    }
    
    /// @notice This function determines if an address belongs to the Committee
    /// @param account Address to be verified
    /// @return True if the address is a committee member
    function isCommitteeMember(address account) public view returns(bool) {
        return hasRole(COMMITTEE_ROLE, account);
    }

    /// @notice This function returns if a report has been voted by one of the three fundamental parts
    /// @param reportId Report number to be checked
    /// @param voterIndex Voter Index to be checked
    /// @return True if it has been voted
    function getIsVoted(uint256 reportId, uint256 voterIndex) public view returns(bool) {
        return reportVotes[reportId].voted[voterIndex];
    }

    /// @notice This function returns the resolution on a report by a team 
    /// @param reportId Report number to be checked
    /// @param voterIndex Voter Index to be checked
    /// @return True if it has voted
    function getVote(uint256 reportId, uint256 voterIndex) public view returns(bool) {
        return reportVotes[reportId].votes[voterIndex];
    }

    /// @notice This function returns if report has been resolved    
    /// @param reportId Report number to be checked
    /// @return True if it has been solved
    function isReportSolved(uint256 reportId) public view returns(bool){
        return reportVotes[reportId].resolved;
    }

    /// @notice This function returns report resolution     
    /// @param reportId Report number to be checked
    /// @return True if it has been resolved positively
    function reportResolution(uint256 reportId) public view returns(bool){
        return reportVotes[reportId].resolution;
    }

    /// @notice This function sets the address of the staking token
    /// @dev Only can be called by the Lossless Admin
    /// @param _stakingToken Address corresponding to the staking token
/*     function setStakingToken(address _stakingToken) public onlyLosslessAdmin {
        require(_stakingToken != address(0), "LERC20: Cannot be zero address");
        stakingToken = ILERC20(_stakingToken);
    } */

    /// @notice This function sets the wallet dispute period
    /// @param timeFrame Time in seconds for the dispute period
    function setDisputePeriod(uint256 timeFrame) public onlyLosslessAdmin whenNotPaused {
        walletDisputePeriod = timeFrame;
    }
    
    /// @notice This function returns if the majority of the commitee voted and the resolution of the votes
    /// @param reportId Report number to be checked
    /// @return isMajorityReached result Returns True if the majority has voted and the true if the result is positive
    function _getCommitteeMajorityReachedResult(uint256 reportId) private view returns(bool isMajorityReached, bool result) {        
        Vote storage reportVote = reportVotes[reportId];

        uint256 agreeCount;
        for(uint256 i; i < reportVote.committeeVotes.length; i++) {
            if (reportVote.committeeVotes[i]) {
                agreeCount += 1;
            }
        }

        if (agreeCount >= ((committeeMembersCount/2)+1)) {
            return (true, true);
        }

        if ((reportVote.committeeVotes.length - agreeCount) >= ((committeeMembersCount/2)+1)) {
            return (true, false);
        }

        return (false, false);
    }

    /// @notice This function adds committee members    
    /// @param members Array of members to be added
    function addCommitteeMembers(address[] memory members) public onlyLosslessAdmin whenNotPaused {
        committeeMembersCount += members.length;

        for (uint256 i; i < members.length; ++i) {
            require(!isCommitteeMember(members[i]), "LSS: duplicate members");
            grantRole(COMMITTEE_ROLE, members[i]);
        }

        emit NewCommitteeMembers(members);
    } 

    /// @notice This function removes Committee members    
    /// @param members Array of members to be added
    function removeCommitteeMembers(address[] memory members) public onlyLosslessAdmin whenNotPaused {  
        require(committeeMembersCount != 0, "LSS: committee has no members");

        committeeMembersCount -= members.length;

        for (uint256 i; i < members.length; ++i) {
            require(isCommitteeMember(members[i]), "LSS: An address is not member");
            revokeRole(COMMITTEE_ROLE, members[i]);
        }

        emit CommitteeMembersRemoved(members);
    }

    /// @notice This function emits a vote on a report by the Lossless Team
    /// @dev Only can be run by the Lossless Admin
    /// @param reportId Report to cast the vote
    /// @param vote Resolution
    function losslessVote(uint256 reportId, bool vote) public onlyLosslessAdmin whenNotPaused {
        require(!isReportSolved(reportId), "LSS: Report already solved");
        require(isReportActive(reportId), "LSS: report is not valid");
        
        Vote storage reportVote = reportVotes[reportId];
        
        require(!reportVotes[reportId].voted[lssTeamVoteIndex], "LSS: LSS already voted");

        reportVote.voted[lssTeamVoteIndex] = true;
        reportVote.votes[lssTeamVoteIndex] = vote;

        emit LosslessTeamVoted(reportId, vote);
    }

    /// @notice This function emits a vote on a report by the Token Owners
    /// @dev Only can be run by the Token admin
    /// @param reportId Report to cast the vote
    /// @param vote Resolution
    function tokenOwnersVote(uint256 reportId, bool vote) public whenNotPaused {
        require(!isReportSolved(reportId), "LSS: Report already solved");
        require(isReportActive(reportId), "LSS: report is not valid");
        require(ILERC20(losslessReporting.reportTokens(reportId)).admin() == msg.sender, "LSS: Must be token owner");

        Vote storage reportVote = reportVotes[reportId];

        require(!reportVote.voted[tokenOwnersVoteIndex], "LSS: owners already voted");
        
        reportVote.voted[tokenOwnersVoteIndex] = true;
        reportVote.votes[tokenOwnersVoteIndex] = vote;

        emit TokenOwnersVoted(reportId, vote);
    }

    /// @notice This function emits a vote on a report by a Committee member
    /// @dev Only can be run by a committee member
    /// @param reportId Report to cast the vote
    /// @param vote Resolution
    function committeeMemberVote(uint256 reportId, bool vote) public whenNotPaused {
        require(!isReportSolved(reportId), "LSS: Report already solved");
        require(isCommitteeMember(msg.sender), "LSS: Must be a committee member");
        require(isReportActive(reportId), "LSS: report is not valid");

        Vote storage reportVote = reportVotes[reportId];

        require(!reportVote.committeeMemberVoted[msg.sender], "LSS: Member already voted");
        
        reportVote.committeeMemberVoted[msg.sender] = true;
        reportVote.committeeVotes.push(vote);

        (bool isMajorityReached, bool result) = _getCommitteeMajorityReachedResult(reportId);

        if (isMajorityReached) {
            reportVote.votes[committeeVoteIndex] = result;
            reportVote.voted[committeeVoteIndex] = true;
            emit CommitteeMajorityReached(reportId, result);
        }

        emit CommitteeMemberVoted(reportId, msg.sender, vote);
    }

    /// @notice This function solves a report based on the voting resolution of the three pilars
    /// @dev Only can be run by the three pilars.
    /// When the report gets resolved, if it's resolved negatively, the reported address gets removed from the blacklist
    /// If the report is solved positively, the funds of the reported account get retrieved in order to be distributed among stakers and the reporter.
    /// @param reportId Report to be resolved
    function resolveReport(uint256 reportId) public whenNotPaused {

        require(!isReportSolved(reportId), "LSS: Report already resolved");
        
        if (losslessReporting.reportTimestamps(reportId) + losslessReporting.reportLifetime() > block.timestamp) {
            _resolveActive(reportId);
        } else {
            _resolveExpired(reportId);
        }
        
        reportVotes[reportId].resolved = true;
        delete reportedAddresses;

        emit ReportResolved(reportId, reportVotes[reportId].resolution);
    }

    /// @notice This function has the logic to solve a report that it's still active
    /// @param reportId Report to be resolved
    function _resolveActive(uint256 reportId) private {
                
        address token = losslessReporting.reportTokens(reportId);
        Vote storage reportVote = reportVotes[reportId];

        uint256 aggreeCount;
        uint256 voteCount;

        if (getIsVoted(reportId, lssTeamVoteIndex)){voteCount += 1;
        if (getVote(reportId, lssTeamVoteIndex)){ aggreeCount += 1;}}
        if (getIsVoted(reportId, tokenOwnersVoteIndex)){voteCount += 1;
        if (getVote(reportId, tokenOwnersVoteIndex)){ aggreeCount += 1;}}

        (bool committeeResoluted, bool committeeResolution) = _getCommitteeMajorityReachedResult(reportId);
        if (committeeResoluted) {voteCount += 1;
        if (committeeResolution) {aggreeCount += 1;}}

        require(voteCount >= 2, "LSS: Not enough votes");
        require(!(voteCount == 2 && aggreeCount == 1), "LSS: Need another vote to untie");

        address reportedAddress = losslessReporting.reportedAddress(reportId);

        reportedAddresses.push(reportedAddress);

        if (losslessReporting.secondReports(reportId)) {
            reportedAddresses.push(losslessReporting.secondReportedAddress(reportId));
        }

        if (aggreeCount > (voteCount - aggreeCount)){
            reportVote.resolution = true;
            for(uint256 i; i < reportedAddresses.length; i++) {
                amountReported[reportId] += ILERC20(token).balanceOf(reportedAddresses[i]);
            }
            retrievalAmount[reportId] = losslessController.retrieveBlacklistedFunds(reportedAddresses, token, reportId);
            losslessController.deactivateEmergency(token);
        }else{
            reportVote.resolution = false;
            _compensateAddresses(reportedAddresses);
        }
    } 

    /// @notice This function has the logic to solve a report that it's expired
    /// @param reportId Report to be resolved
    function _resolveExpired(uint256 reportId) private {
        address reportedAddress = losslessReporting.reportedAddress(reportId);

        reportedAddresses.push(reportedAddress);

        if (losslessReporting.secondReports(reportId)) {
            reportedAddresses.push(losslessReporting.secondReportedAddress(reportId));
        }

        reportVotes[reportId].resolution = false;
        _compensateAddresses(reportedAddresses);
    }

    /// @notice This compensates the addresses wrongly reported
    /// @dev The array of addresses will contain the main reported address and the second reported address
    /// @param addresses Array of addresses to be compensated
    function _compensateAddresses(address[] memory addresses) private {
        uint256 compensationAmount = losslessController.erroneousCompensation();
        uint256 reportingAmount = losslessReporting.reportingAmount();
        
        for(uint256 i; i < addresses.length; i++) {
            losslessController.resolvedNegatively(addresses[i]);      
            compensation[addresses[i]].amount +=  (reportingAmount * compensationAmount) / 10**2;
        }
    }

    function isReportActive(uint256 reportId) public view returns(bool) {
        uint256 reportTimestamp = losslessReporting.reportTimestamps(reportId);
        return reportTimestamp != 0 && reportTimestamp + losslessReporting.reportLifetime() > block.timestamp;
    }

    // REFUND PROCESS

    /// @notice This function proposes a wallet where the recovered funds will be returned
    /// @dev Only can be run by lossless team or token owners.
    /// @param reportId Report to propose the wallet
    /// @param wallet proposed address
    function proposeWallet(uint256 reportId, address wallet) public whenNotPaused {
        require(msg.sender == losslessController.admin() || 
                msg.sender == ILERC20(losslessReporting.reportTokens(reportId)).admin(),
                "LSS: Role cannot propose");
        require(reportResolution(reportId), "LSS: Report solved negatively");
        require(wallet != address(0), "LSS: Wallet cannot ber zero adr");
        require(proposedWalletOnReport[reportId].wallet == address(0), "LSS: Wallet already proposed");

        proposedWalletOnReport[reportId].wallet = wallet;
        proposedWalletOnReport[reportId].timestamp = block.timestamp;
        proposedWalletOnReport[reportId].losslessVote = true;
        proposedWalletOnReport[reportId].tokenOwnersVote = true;
        proposedWalletOnReport[reportId].walletAccepted = true;

        emit WalletProposed(reportId, wallet);
    }

    /// @notice This function is used to reject the wallet proposal
    /// @dev Only can be run by the three pilars.
    /// @param reportId Report to propose the wallet
    function rejectWallet(uint256 reportId) public whenNotPaused {

        require(block.timestamp <= (proposedWalletOnReport[reportId].timestamp + walletDisputePeriod), "LSS: Dispute period closed");

        bool isMember = hasRole(COMMITTEE_ROLE, msg.sender);
        bool isLosslessTeam = msg.sender == losslessController.admin();
        bool isTokenOwner = msg.sender == ILERC20(losslessReporting.reportTokens(reportId)).admin();

        require(isMember || isLosslessTeam || isTokenOwner, "LSS: Role cannot reject");

        if (isMember) {
            require(!proposedWalletOnReport[reportId].memberVotesOnProposal[proposedWalletOnReport[reportId].proposal].memberVoted[msg.sender], "LSS: Already Voted");
            proposedWalletOnReport[reportId].committeeDisagree += 1;
            proposedWalletOnReport[reportId].memberVotesOnProposal[proposedWalletOnReport[reportId].proposal].memberVoted[msg.sender] = true;
        } else if (isLosslessTeam) {
            require(!proposedWalletOnReport[reportId].losslessVoted, "LSS: Already Voted");
            proposedWalletOnReport[reportId].losslessVote = false;
            proposedWalletOnReport[reportId].losslessVoted = true;
        } else {
            require(!proposedWalletOnReport[reportId].tokenOwnersVoted, "LSS: Already Voted");
            proposedWalletOnReport[reportId].tokenOwnersVote = false;
            proposedWalletOnReport[reportId].tokenOwnersVoted = true;
        }

        _determineProposedWallet(reportId);

        emit WalletRejected(reportId, proposedWalletOnReport[reportId].wallet);
    }

    /// @notice This function retrieves the fund to the accepted proposed wallet
    /// @param reportId Report to propose the wallet
    function retrieveFunds(uint256 reportId) public whenNotPaused {
        require(block.timestamp >= (proposedWalletOnReport[reportId].timestamp + walletDisputePeriod), "LSS: Dispute period not closed");
        require(!proposedWalletOnReport[reportId].status, "LSS: Funds already claimed");
        require(proposedWalletOnReport[reportId].walletAccepted, "LSS: Wallet rejected");
        require(proposedWalletOnReport[reportId].wallet == msg.sender, "LSS: Only proposed adr can claim");

        proposedWalletOnReport[reportId].status = true;

        ILERC20(losslessReporting.reportTokens(reportId)).transfer(msg.sender, retrievalAmount[reportId]);

        emit FundsRetrieved(reportId, msg.sender);
    }

    /// @notice This function determins if the refund wallet was accepted
    /// @param reportId Report to propose the wallet
    function _determineProposedWallet(uint256 reportId) private returns(bool){
        
        uint256 agreementCount;
        
        if (proposedWalletOnReport[reportId].committeeDisagree < (committeeMembersCount/2)+1 ){
            agreementCount += 1;
        }

        if (proposedWalletOnReport[reportId].losslessVote) {
            agreementCount += 1;
        }

        if (proposedWalletOnReport[reportId].tokenOwnersVote) {
            agreementCount += 1;
        }
        
        if (agreementCount >= 2) {
            return true;
        }

        proposedWalletOnReport[reportId].wallet = address(0);
        proposedWalletOnReport[reportId].timestamp = block.timestamp;
        proposedWalletOnReport[reportId].status = false;
        proposedWalletOnReport[reportId].losslessVote = true;
        proposedWalletOnReport[reportId].losslessVoted = false;
        proposedWalletOnReport[reportId].tokenOwnersVote = true;
        proposedWalletOnReport[reportId].tokenOwnersVoted = false;
        proposedWalletOnReport[reportId].walletAccepted = false;
        proposedWalletOnReport[reportId].committeeDisagree = 0;
        proposedWalletOnReport[reportId].proposal += 1;

        return false;
    }

    /// @notice This lets an erroneously reported account to retrieve compensation
    function retrieveCompensation() public whenNotPaused {
        require(!compensation[msg.sender].payed, "LSS: Already retrieved");
        require(compensation[msg.sender].amount > 0, "LSS: No retribution assigned");
        
        compensation[msg.sender].payed = true;

        losslessReporting.retrieveCompensation(msg.sender, compensation[msg.sender].amount);

        emit CompensationRetrieved(msg.sender, compensation[msg.sender].amount);

        compensation[msg.sender].amount = 0;
    }

    ///@notice This function is for committee members to claim their rewards
    ///@param reportId report ID to claim reward from
    function claimCommitteeReward(uint256 reportId) public whenNotPaused {
        require(reportResolution(reportId), "LSS: Report solved negatively");
        require(reportVotes[reportId].committeeMemberVoted[msg.sender], "LSS: Did not vote on report");
        require(!reportVotes[reportId].committeeMemberClaimed[msg.sender], "LSS: Already claimed");

        uint256 numberOfMembersVote = reportVotes[reportId].committeeVotes.length;
        uint256 committeeReward = losslessReporting.committeeReward();

        uint256 compensationPerMember = (amountReported[reportId] * committeeReward /  10**2) / numberOfMembersVote;

        address token = losslessReporting.reportTokens(reportId);

        reportVotes[reportId].committeeMemberClaimed[msg.sender] = true;

        ILERC20(token).transfer(msg.sender, compensationPerMember);

        emit CommitteeMemberClaimed(reportId, msg.sender, compensationPerMember);
    }

    
    /// @notice This function is for the Lossless to claim the rewards
    /// @param reportId report worked on
    function losslessClaim(uint256 reportId) public whenNotPaused onlyLosslessAdmin {
        require(reportResolution(reportId), "LSS: Report solved negatively");   
        require(!losslessPayed[reportId], "LSS: Already claimed");

        uint256 amountToClaim = amountReported[reportId] * losslessReporting.losslessReward() / 10**2;
        losslessPayed[reportId] = true;
        ILERC20(losslessReporting.reportTokens(reportId)).transfer(losslessController.admin(), amountToClaim);

        emit LosslessClaimed(losslessReporting.reportTokens(reportId), reportId, amountToClaim);
    }

}