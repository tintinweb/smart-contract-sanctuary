// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../../Initializable.sol";
import "./interfaces/IBlockManagerParams.sol";
import "./interfaces/IRewardManagerParams.sol";
import "./interfaces/IStakeManagerParams.sol";
import "./interfaces/IVoteManagerParams.sol";
import "./interfaces/IAssetManagerParams.sol";
import "./interfaces/IDelegatorParams.sol";
import "./interfaces/IRandomNoManagerParams.sol";
import "../storage/Constants.sol";
import "./ACL.sol";

// slither-reason : Disabled as slither is suggesting to have params interfaces to be inherited here
// Though function signatures are same, meaning is diff
// also two interfaces are going to have some common functions in this case
// slither-disable-next-line missing-inheritance
contract Governance is Initializable, ACL, Constants {
    IBlockManagerParams public blockManagerParams;
    IRewardManagerParams public rewardManagerParams;
    IStakeManagerParams public stakeManagerParams;
    IVoteManagerParams public voteManagerParams;
    IAssetManagerParams public assetManagerParams;
    IDelegatorParams public delegatorParams;
    IRandomNoManagerParams public randomNoManagerParams;

    bytes32 public constant GOVERNER_ROLE = 0x704c992d358ec8f6051d88e5bd9f92457afedcbc3e2d110fcd019b5eda48e52e;

    //event to be emitted when any governance parameter value changes.
    event ParameterChanged(address admin, string parameterName, uint256 valueChangedTo, uint256 timestamp);

    function initialize(
        address blockManagerAddress,
        address rewardManagerAddress,
        address stakeManagerAddress,
        address voteManagerAddress,
        address assetManagerAddress,
        address delegatorAddress,
        address randomNoManagerAddress
    ) external initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        blockManagerParams = IBlockManagerParams(blockManagerAddress);
        rewardManagerParams = IRewardManagerParams(rewardManagerAddress);
        stakeManagerParams = IStakeManagerParams(stakeManagerAddress);
        voteManagerParams = IVoteManagerParams(voteManagerAddress);
        assetManagerParams = IAssetManagerParams(assetManagerAddress);
        delegatorParams = IDelegatorParams(delegatorAddress);
        randomNoManagerParams = IRandomNoManagerParams(randomNoManagerAddress);
    }

    function setPenaltyNotRevealNum(uint16 _penaltyNotRevealNumerator) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "penaltyNotRevealNum", _penaltyNotRevealNumerator, block.timestamp);
        rewardManagerParams.setPenaltyNotRevealNum(_penaltyNotRevealNumerator);
    }

    function setSlashParams(
        uint16 _bounty,
        uint16 _burn,
        uint16 _keep
    ) external initialized onlyRole(GOVERNER_ROLE) {
        require(_bounty + _burn + _keep <= BASE_DENOMINATOR, "Slash nums addtion exceeds 10000");
        emit ParameterChanged(msg.sender, "bountySlashNum", _bounty, block.timestamp);
        emit ParameterChanged(msg.sender, "burnSlashNum", _burn, block.timestamp);
        emit ParameterChanged(msg.sender, "keepSlashNum", _keep, block.timestamp);
        stakeManagerParams.setSlashParams(_bounty, _burn, _keep);
    }

    function setWithdrawLockPeriod(uint8 _withdrawLockPeriod) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "withdrawLockPeriod", _withdrawLockPeriod, block.timestamp);
        stakeManagerParams.setWithdrawLockPeriod(_withdrawLockPeriod);
    }

    function setWithdrawReleasePeriod(uint8 _withdrawReleasePeriod) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "withdrawReleasePeriod", _withdrawReleasePeriod, block.timestamp);
        stakeManagerParams.setWithdrawReleasePeriod(_withdrawReleasePeriod);
    }

    function setExtendLockPenalty(uint8 _extendLockPenalty) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "extendLockPenalty", _extendLockPenalty, block.timestamp);
        stakeManagerParams.setExtendLockPenalty(_extendLockPenalty);
    }

    function setMaxAltBlocks(uint8 _maxAltBlocks) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "maxAltBlocks", _maxAltBlocks, block.timestamp);
        blockManagerParams.setMaxAltBlocks(_maxAltBlocks);
    }

    function setMinStake(uint256 _minStake) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "minStake", _minStake, block.timestamp);
        stakeManagerParams.setMinStake(_minStake);
        voteManagerParams.setMinStake(_minStake);
        blockManagerParams.setMinStake(_minStake);
    }

    function setBlockReward(uint256 _blockReward) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "blockReward", _blockReward, block.timestamp);
        blockManagerParams.setBlockReward(_blockReward);
        rewardManagerParams.setBlockReward(_blockReward);
    }

    function setGracePeriod(uint16 _gracePeriod) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "gracePeriod", _gracePeriod, block.timestamp);
        rewardManagerParams.setGracePeriod(_gracePeriod);
        stakeManagerParams.setGracePeriod(_gracePeriod);
    }

    function setMaxAge(uint32 _maxAge) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "maxAge", _maxAge, block.timestamp);
        rewardManagerParams.setMaxAge(_maxAge);
    }

    function setMaxCommission(uint8 _maxCommission) external initialized onlyRole(GOVERNER_ROLE) {
        require(_maxCommission <= 100, "Invalid Max Commission Update");
        emit ParameterChanged(msg.sender, "maxCommission", _maxCommission, block.timestamp);
        stakeManagerParams.setMaxCommission(_maxCommission);
    }

    function disableEscapeHatch() external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "escapeHatchEnabled", 0, block.timestamp);
        stakeManagerParams.disableEscapeHatch();
    }

    function setEpochLength(uint16 _epochLength) external initialized onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "epochLength", _epochLength, block.timestamp);
        blockManagerParams.setEpochLength(_epochLength);
        rewardManagerParams.setEpochLength(_epochLength);
        stakeManagerParams.setEpochLength(_epochLength);
        voteManagerParams.setEpochLength(_epochLength);
        assetManagerParams.setEpochLength(_epochLength);
        delegatorParams.setEpochLength(_epochLength);
        randomNoManagerParams.setEpochLength(_epochLength);
    }

    function setDeltaCommission(uint8 _deltaCommission) external onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "deltaCommission", _deltaCommission, block.timestamp);
        stakeManagerParams.setDeltaCommission(_deltaCommission);
    }

    function setEpochLimitForUpdateCommission(uint16 _epochLimitForUpdateCommission) external onlyRole(GOVERNER_ROLE) {
        emit ParameterChanged(msg.sender, "epochLimitForUpdateCommission", _epochLimitForUpdateCommission, block.timestamp);
        stakeManagerParams.setEpochLimitForUpdateCommission(_epochLimitForUpdateCommission);
    }
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
 *
 * Forked from OZ's (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/b9125001f0a1c44d596ca3a47536f1a467e3a29d/contracts/proxy/utils/Initializable.sol)
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
        require(_initializing || !_initialized, "contract already initialized");

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

    modifier initialized() {
        require(_initialized, "Contract should be initialized");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBlockManagerParams {
    function setEpochLength(uint16 _epochLength) external;

    function setMaxAltBlocks(uint8 _maxAltBlocks) external;

    function setBlockReward(uint256 _blockReward) external;

    function setMinStake(uint256 _minStake) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRewardManagerParams {
    function setEpochLength(uint16 _epochLength) external;

    function setPenaltyNotRevealNum(uint16 _penaltyNotRevealNumerator) external;

    function setBlockReward(uint256 _blockReward) external;

    function setGracePeriod(uint16 _gracePeriod) external;

    function setMaxAge(uint32 _maxAge) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStakeManagerParams {
    function setEpochLength(uint16 _epochLength) external;

    function setSlashParams(
        uint16 _bounty,
        uint16 _burn,
        uint16 _keep
    ) external;

    function setWithdrawLockPeriod(uint8 _withdrawLockPeriod) external;

    function setWithdrawReleasePeriod(uint8 _withdrawReleasePeriod) external;

    function setExtendLockPenalty(uint8 _extendLockPenalty) external;

    function setMinStake(uint256 _minStake) external;

    function setGracePeriod(uint16 _gracePeriod) external;

    function setMaxCommission(uint8 _maxCommission) external;

    function setDeltaCommission(uint8 _deltaCommission) external;

    function setEpochLimitForUpdateCommission(uint16 _epochLimitForUpdateCommission) external;

    function disableEscapeHatch() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVoteManagerParams {
    function setEpochLength(uint16 _epochLength) external;

    function setMinStake(uint256 _minStake) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAssetManagerParams {
    function setEpochLength(uint16 _epochLength) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDelegatorParams {
    function setEpochLength(uint16 _epochLength) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRandomNoManagerParams {
    function setEpochLength(uint16 _epochLength) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Constants {
    enum State {
        Commit,
        Reveal,
        Propose,
        Dispute,
        Confirm
    }

    enum StakeChanged {
        BlockReward,
        InactivityPenalty,
        RandaoPenalty,
        Slashed
    }

    uint8 public constant NUM_STATES = 5;
    address public constant BURN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint16 public constant BASE_DENOMINATOR = 10000;
    // keccak256("BLOCK_CONFIRMER_ROLE")
    bytes32 public constant BLOCK_CONFIRMER_ROLE = 0x18797bc7973e1dadee1895be2f1003818e30eae3b0e7a01eb9b2e66f3ea2771f;

    // keccak256("ASSET_CONFIRMER_ROLE")
    bytes32 public constant ASSET_CONFIRMER_ROLE = 0xed202a1bc048f9b31cb3937bc52e7c8fe76413f0674b9146ff4bcc15612ccbc2;

    // keccak256("STAKER_ACTIVITY_UPDATER_ROLE")
    bytes32 public constant STAKER_ACTIVITY_UPDATER_ROLE = 0x4cd3070aaa07d03ab33731cbabd0cb27eb9e074a9430ad006c96941d71b77ece;

    // keccak256("STAKE_MODIFIER_ROLE")
    bytes32 public constant STAKE_MODIFIER_ROLE = 0xdbaaaff2c3744aa215ebd99971829e1c1b728703a0bf252f96685d29011fc804;

    // keccak256("REWARD_MODIFIER_ROLE")
    bytes32 public constant REWARD_MODIFIER_ROLE = 0xcabcaf259dd9a27f23bd8a92bacd65983c2ebf027c853f89f941715905271a8d;

    // keccak256("ASSET_MODIFIER_ROLE")
    bytes32 public constant ASSET_MODIFIER_ROLE = 0xca0fffcc0404933256f3ec63d47233fbb05be25fc0eacc2cfb1a2853993fbbe4;

    // keccak256("VOTE_MODIFIER_ROLE")
    bytes32 public constant VOTE_MODIFIER_ROLE = 0xca0fffcc0404933256f3ec63d47233fbb05be25fc0eacc2cfb1a2853993fbbe5;

    // keccak256("DELEGATOR_MODIFIER_ROLE")
    bytes32 public constant DELEGATOR_MODIFIER_ROLE = 0x6b7da7a33355c6e035439beb2ac6a052f1558db73f08690b1c9ef5a4e8389597;

    // keccak256("SECRETS_MODIFIER_ROLE")
    bytes32 public constant SECRETS_MODIFIER_ROLE = 0x46aaf8a125792dfff6db03d74f94fe1acaf55c8cab22f65297c15809c364465c;

    // keccak256("PAUSE_ROLE")
    bytes32 public constant PAUSE_ROLE = 0x139c2898040ef16910dc9f44dc697df79363da767d8bc92f2e310312b816e46d;

    // keccak256("GOVERNANCE_ROLE")
    bytes32 public constant GOVERNANCE_ROLE = 0x71840dc4906352362b0cdaf79870196c8e42acafade72d5d5a6d59291253ceb1;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract ACL is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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