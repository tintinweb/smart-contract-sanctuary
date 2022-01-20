//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import {Math} from "@openzeppelin/contracts-0.8/utils/math/Math.sol";
import {AccessControl} from "@openzeppelin/contracts-0.8/access/AccessControl.sol";
import {IRewardCalculator} from "../interfaces/IRewardCalculator.sol";

contract TwoPeriodsRewardCalculator is IRewardCalculator, AccessControl {
    event InitialCampaign(
        uint256 reward,
        uint256 duration,
        uint256 finish1,
        uint256 rate1,
        uint256 finish2,
        uint256 rate2
    );
    event NextCampaign(
        uint256 reward,
        uint256 duration,
        uint256 finish1,
        uint256 rate1,
        uint256 finish2,
        uint256 rate2
    );
    event UpdateCampaign(
        uint256 reward,
        uint256 duration,
        uint256 finish1,
        uint256 rate1,
        uint256 finish2,
        uint256 rate2
    );

    // This role is in charge of configuring reward distribution
    bytes32 public constant REWARD_DISTRIBUTION = keccak256("REWARD_DISTRIBUTION");
    // Each time a parameter that affects the reward distribution is changed the rewards are distributed by the reward
    // pool contract this is the restart time.
    uint256 public lastUpdateTime;
    // This variable is only used when a new campaign starts (notifyRewardAmount is called)
    // We need to save the rewards accumulated between the last call to restartRewards and the call to notifyRewardAmount
    uint256 public savedRewards;
    // The reward distribution is divided in two periods with two different rated
    //                   |            |            |************|*
    //                   |            |          **|            |*
    //                   |            |        **  |            |*
    //                   |            |      **    |            |*
    //                   |            |    **      |            |*
    //                   |            |  **        |            |*
    //                   |            |**          |            |*
    //                   |        ****|            |            |*
    //                   |    ****    |            |            |*
    //                   |****        |            |            |*
    // zero -> **********|            |            |            |********************
    //                   |<-perido1-> |<-period2-> |<-restart-> |
    uint256 public finish1;
    uint256 public rate1;
    uint256 public finish2;
    uint256 public rate2;

    // The address of the reward pool, the only one authorized to restart rewards
    address public rewardPool;

    constructor(address rewardPool_) {
        rewardPool = rewardPool_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // At any point in time this function must return the accumulated rewards from last call to restartRewards
    function getRewards() external view override returns (uint256) {
        return savedRewards + _getRewards();
    }

    // The main contract has distributed the rewards until this point, this must start from scratch => getRewards() == 0
    function restartRewards() external override {
        require(msg.sender == rewardPool, "not reward pool");
        lastUpdateTime = block.timestamp;
        savedRewards = 0;
    }

    // Useful when switching reward calculators to set an initial reward.
    function setSavedRewards(uint256 reward) external {
        require(hasRole(REWARD_DISTRIBUTION, _msgSender()), "not reward distribution");
        savedRewards = reward;
        lastUpdateTime = block.timestamp;
    }

    // This is a helper function, it is better to call setInitialCampaign or updateNextCampaign directly
    function runCampaign(uint256 reward, uint256 duration) external {
        require(hasRole(REWARD_DISTRIBUTION, _msgSender()), "not reward distribution");
        if (block.timestamp >= finish2) {
            _initialCampaign(reward, duration);
        } else {
            _updateNextCampaign(reward, duration);
        }
    }

    // Start an initial campaign, set the period1 of reward distribution, period2 rate is zero
    function setInitialCampaign(uint256 reward, uint256 duration) external {
        require(hasRole(REWARD_DISTRIBUTION, _msgSender()), "not reward distribution");
        require(block.timestamp >= finish2, "initial campaign running");
        _initialCampaign(reward, duration);
    }

    // Update the period2 of rate distribution, must be called after an initial campaign is set
    // If period1 is running, period2 is set with the rate reward/duration.
    // If period1 is finished it is updated with the values of period2 and period2 is set with the rate reward/duration.
    function updateNextCampaign(uint256 reward, uint256 duration) external {
        require(hasRole(REWARD_DISTRIBUTION, _msgSender()), "not reward distribution");
        require(block.timestamp < finish2, "initial campaign not running");
        _updateNextCampaign(reward, duration);
    }

    function updateCurrentCampaign(uint256 reward, uint256 duration) external {
        require(hasRole(REWARD_DISTRIBUTION, _msgSender()), "not reward distribution");
        require(block.timestamp < finish2, "initial campaign not running");
        _updateCurrentCampaign(reward, duration);
    }

    // Check if both periods already ended => campaign is finished
    function isCampaignFinished() external view returns (bool) {
        return (block.timestamp >= finish2);
    }

    // Check if some of the periods are still running
    function isCampaignRunning() external view returns (bool) {
        return (block.timestamp < finish2);
    }

    function _initialCampaign(uint256 reward, uint256 duration) internal {
        // block.timestamp >= finish2
        _saveRewards();
        finish1 = block.timestamp + duration;
        rate1 = reward / duration;
        finish2 = block.timestamp + duration;
        rate2 = 0;
        emit InitialCampaign(reward, duration, finish1, rate1, finish2, rate2);
    }

    function _updateNextCampaign(uint256 reward, uint256 duration) internal {
        // block.timestamp < finish2
        _saveRewards();
        if (block.timestamp >= finish1) {
            // The next campaign is new.
            finish1 = finish2;
            rate1 = rate2;
        }
        finish2 = finish1 + duration;
        rate2 = reward / duration;
        emit NextCampaign(reward, duration, finish1, rate1, finish2, rate2);
    }

    // TODO: we need to check the logic for this one, what to do with the remainder rewards and the next campaign duration ?
    // TODO: Right now we restart the current campaign forgetting the old values and leaving next one untouched.
    function _updateCurrentCampaign(uint256 reward, uint256 duration) internal {
        _saveRewards();
        if (block.timestamp >= finish1) {
            // The next campaign is new.
            finish1 = finish2;
            rate1 = rate2;
            rate2 = 0;
        }
        assert(finish1 <= finish2);
        uint256 duration2 = finish2 - finish1;
        finish1 = block.timestamp + duration;
        finish2 = finish1 + duration2;
        rate1 = reward / duration;
        emit UpdateCampaign(reward, duration, finish1, rate1, finish2, rate2);
    }

    function _saveRewards() internal {
        savedRewards = savedRewards + _getRewards();
        lastUpdateTime = block.timestamp;
    }

    function _getRewards() internal view returns (uint256) {
        assert(lastUpdateTime <= block.timestamp);
        assert(finish1 <= finish2);
        if (lastUpdateTime >= finish2) {
            return 0;
        }
        if (block.timestamp <= finish1) {
            return (block.timestamp - lastUpdateTime) * rate1;
        }
        // block.timestamp > finish1
        uint256 rewards2 = (Math.min(block.timestamp, finish2) - Math.max(lastUpdateTime, finish1)) * rate2;
        if (lastUpdateTime < finish1) {
            // add reward1 + reward2
            return (finish1 - lastUpdateTime) * rate1 + rewards2;
        }
        return rewards2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/// @title Plugins for the SandRewardPool that calculate the rewards must implement this interface
interface IRewardCalculator {
    /// @dev At any point in time this function must return the accumulated rewards from the last call to restartRewards
    function getRewards() external view returns (uint256);

    /// @dev The main contract has distributed the rewards (getRewards()) until this point, this must start
    /// @dev from scratch => getRewards() == 0
    function restartRewards() external;
}

// SPDX-License-Identifier: MIT

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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