// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library DateTimeHelper {
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
    }

    uint public constant MINUTE = 1 minutes;
    uint public constant HOUR = 1 hours;
    uint public constant DAY = 1 days;
    uint public constant YEAR = DAY * 365;
    uint public constant LEAP_YEAR = DAY * 366;

    uint16 private constant YEAR_1970 = 1970;

    function _leapYearsBefore(uint year) private pure returns(uint) {
        year--;
        return year / 4 - year / 100 + year / 400;
    }

    function _getDaysInMonth(uint8 month, uint16 year) private pure returns(uint8) {
        if (month == 2)
            return isLeapYear(year) ? 29 : 28;
        else if (month == 4 || month == 6 || month == 9 || month == 11)
            return 30;
        else
            return 31;
    }

    function _parseTimestamp(uint timestamp) private pure returns(_DateTime memory dt) {
        uint16 year = uint16(YEAR_1970 + timestamp / YEAR);
        uint leapYearsCount = _leapYearsBefore(year) - _leapYearsBefore(YEAR_1970);

        uint extraSeconds = LEAP_YEAR * leapYearsCount;
        extraSeconds += YEAR * (year - YEAR_1970 - leapYearsCount);

        while (extraSeconds > timestamp) {
            extraSeconds -= isLeapYear(uint16(year - 1)) ? LEAP_YEAR : YEAR;
            year--;
        }

        uint8 month;
        for (uint8 i = 1; i <= 12; i++) {
            uint secondsInMonth = DAY * _getDaysInMonth(i, year);
            if (secondsInMonth + extraSeconds > timestamp) {
                month = i;
                break;
            }
            extraSeconds += secondsInMonth;
        }

        uint8 day;
        for (uint8 i = 1; i <= _getDaysInMonth(month, year); i++) {
            if (DAY + extraSeconds > timestamp) {
                day = i;
                break;
            }
            extraSeconds += DAY;
        }

        dt.year = year;
        dt.month = month;
        dt.day = day;
        dt.hour = getHour(timestamp);
        dt.minute = getMinute(timestamp);
        dt.second = getSecond(timestamp);
    }

    function isLeapYear(uint16 year) internal pure returns(bool) {
        if (year % 4 != 0)
            return false;
        if (year % 100 != 0)
            return true;
        if (year % 400 != 0)
            return false;

        return true;
    }

    function getYear(uint timestamp) internal pure returns(uint16) {
        return _parseTimestamp(timestamp).year;
    }

    function getMonth(uint timestamp) internal pure returns(uint8) {
        return _parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) internal pure returns(uint8) {
        return _parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) internal pure returns(uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) internal pure returns(uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) internal pure returns(uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) internal pure returns(uint8) {
        // 1970-01-01 was Thursday
        // So adding 3 days from Monday (first day of the week)
        // Getting reminder from div by 7
        return uint8((timestamp / DAY + 3) % 7);
    }

    function getDateOnly(uint timestamp) internal pure returns(uint) {
        timestamp -= getHour(timestamp) * HOUR;
        timestamp -= getMinute(timestamp) * MINUTE;
        timestamp -= getSecond(timestamp);
        return timestamp;
    }

    function getMondayStart(uint timestamp) internal pure returns(uint) {
        timestamp -= getWeekday(timestamp) * DAY;
        return getDateOnly(timestamp);
    }

    function getSundayEnd(uint timestamp) internal pure returns(uint) {
        timestamp += (7 - getWeekday(timestamp)) * DAY;
        return getDateOnly(timestamp) - 1;
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) internal pure returns(uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) internal pure returns(uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) internal pure returns(uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) internal pure returns(uint timestamp) {
        for (uint16 i = YEAR_1970; i < year; i++)
            timestamp += isLeapYear(i) ? LEAP_YEAR : YEAR;

        for (uint8 i = 1; i < month; i++)
            timestamp += DAY * _getDaysInMonth(i, year);

        timestamp += DAY * (day - 1);
        timestamp += HOUR * (hour);
        timestamp += MINUTE * (minute);
        timestamp += second;

        return timestamp;
    }

    // EXTERNAL (proxies used by js tests without extra linking on contract deployment)
    function isLeapYearEx(uint16 year) external pure returns(bool) {
        return isLeapYear(year);
    }
    function getYearEx(uint timestamp) external pure returns(uint16) {
        return getYear(timestamp);
    }
    function getMonthEx(uint timestamp) external pure returns(uint8) {
        return getMonth(timestamp);
    }
    function getDayEx(uint timestamp) external pure returns(uint8) {
        return getDay(timestamp);
    }
    function getHourEx(uint timestamp) external pure returns(uint8) {
        return getHour(timestamp);
    }
    function getMinuteEx(uint timestamp) external pure returns(uint8) {
        return getMinute(timestamp);
    }
    function getSecondEx(uint timestamp) external pure returns(uint8) {
        return getSecond(timestamp);
    }
    function getWeekdayEx(uint timestamp) external pure returns(uint8) {
        return getWeekday(timestamp);
    }
    function getDateOnlyEx(uint timestamp) external pure returns(uint) {
        return getDateOnly(timestamp);
    }    
    function getMondayStartEx(uint timestamp) external pure returns(uint) {
        return getMondayStart(timestamp);
    }
    function getSundayEndEx(uint timestamp) external pure returns(uint) {
        return getSundayEnd(timestamp);
    }
    function toTimestampEx(uint16 year, uint8 month, uint8 day) external pure returns(uint timestamp) {
        return toTimestamp(year, month, day);
    }
    function toTimestampEx(uint16 year, uint8 month, uint8 day, uint8 hour) external pure returns(uint timestamp) {
        return toTimestamp(year, month, day, hour);
    }
    function toTimestampEx(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) external pure returns(uint timestamp) {
        return toTimestamp(year, month, day, hour, minute);
    }
    function toTimestampEx(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) external pure returns(uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, second);
    }
}



library PayoutsHelper {
    uint256 private constant DECIMAL = 10000000000; //10┬á000┬á000┬á000
    uint256 private constant EXTRA_DECIMAL = 1000;
    uint256 private constant PERCENT = 100;

    function _sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function _getCoefs(uint256 itmCount) private pure returns (uint256, uint256, uint256) {
        if (itmCount <= 15)
            return (6500000000, 9200000000, 1500000000);
        else if (itmCount <= 40)
            return (5300000000, 9000000000, 6000000000);
        else if (itmCount <= 90)
            return (4550000000, 8900000000, 9900000000);
        else if (itmCount <= 300)
            return (4500000000, 8800000000, 9900000000);
        else if (itmCount <= 600)
            return (4760000000, 10500000000, 300000000);
        return (4820000000, 11000000000, 0);
    }

    function _getItmCount(uint256 participantsCount, uint256 equalDistributionLimit, uint256 itmPercentage) private pure returns (uint256) {
        uint256 result = participantsCount <= equalDistributionLimit ? participantsCount : ((participantsCount * itmPercentage / PERCENT) + 2);
        return result <= participantsCount ? result : participantsCount;
    }

    function _getRoughPayouts(uint256 participantsCount, uint256 equalDistributionLimit, uint256 itmPercentage, uint256 prizePool) private pure returns (uint256[] memory) {
        uint256 itmCount = _getItmCount(participantsCount, equalDistributionLimit, itmPercentage);
        uint256[] memory result = new uint256[](itmCount);

        if (participantsCount <= equalDistributionLimit) {
            // equal distribution
            for (uint256 i = 0; i < itmCount; i++)
                result[i] = prizePool / itmCount;
        }
        else {
            // hyperbolic distribution
            (uint256 a, uint256 b, uint256 c) = _getCoefs(itmCount);
            uint256 divider = a * _sqrt(b * itmCount * DECIMAL) / DECIMAL + c;
            
            for (uint256 i = 0; i < itmCount; i++) {
                uint256 payout = ((100 * DECIMAL * DECIMAL)/((i + 2) * DECIMAL) + DECIMAL) * DECIMAL / divider * EXTRA_DECIMAL;
                payout = payout * prizePool / PERCENT / EXTRA_DECIMAL;
                result[i] = payout / DECIMAL;
            }
        }

        return result;
    }

    function getPayouts(uint256 participantsCount, uint256 equalDistributionLimit, uint256 itmPercentage, uint256 prizePool) internal pure returns (uint256[] memory) {
        uint256[] memory result = _getRoughPayouts(participantsCount, equalDistributionLimit, itmPercentage, prizePool);
        uint256 itmCount = result.length;

        uint256 total;
        for (uint i = 0; i < itmCount; i++)
            total += result[i];

        uint256 diff;
        uint256 counter;

        // rounding leftover distribution
        while (prizePool > total) {
            diff = (prizePool - total) / itmCount;
            if (diff == 0) diff = 1;
            result[counter % itmCount] += diff;
            total += diff;
            counter++;
        }

        // divergence fix (600+ itm)
        while (total > prizePool) {
            diff = (total - prizePool) / itmCount;
            if (diff == 0) diff = 1;
            result[counter % itmCount] -= diff;
            total -= diff;
            counter++;
        }

        return result;
    }

    function getPayoutsEx(uint256 participantsCount, uint256 equalDistributionLimit, uint256 itmPercentage, uint256 prizePool) external pure returns (uint256[] memory) {
        return getPayouts(participantsCount, equalDistributionLimit, itmPercentage, prizePool);
    }
}



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

    function toString(bytes32 value) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && value[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && value[i] != 0; i++) {
            bytesArray[i] = value[i];
        }
        return string(bytesArray);
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
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via _msgSender() and msg.data, they should not be accessed in such a direct
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
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}



/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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
 * @dev Interface of a contract containing identifier for Default Admin role.
 */
interface IRoleContainerDefaultAdmin {
    /**
    * @dev Returns Default Admin role identifier.
    */
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
abstract contract AccessControl is Context, ERC165Storage, IAccessControl, IRoleContainerDefaultAdmin {
    /**
    * @dev Default Admin role identifier.
    */
    bytes32 public constant DEFAULT_ADMIN_ROLE = "Admin";

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    constructor() {
        _registerInterface(type(IAccessControl).interfaceId);
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toString(role)
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



/**
 * @dev Interface for contract which allows to pause and unpause the contract.
 */
interface IPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);
    
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
    * @dev Pauses the contract.
    */
    function pause() external;

    /**
    * @dev Unpauses the contract.
    */
    function unpause() external;
}



/**
 * @dev Interface of a contract containing identifier for Pauser role.
 */
interface IRoleContainerPauser {
    /**
    * @dev Returns Pauser role identifier.
    */
    function PAUSER_ROLE() external view returns (bytes32);
}


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is AccessControl, IPausable, IRoleContainerPauser {
    /**
    * @dev Pauser role identifier.
    */
    bytes32 public constant PAUSER_ROLE = "Pauser";

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _registerInterface(type(IPausable).interfaceId);
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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
   
    /**
    * @dev This function is called before pausing the contract.
    * Override to add custom pausing conditions or actions.
    */
    function _beforePause() internal virtual {
    }

    /**
    * @dev This function is called before unpausing the contract.
    * Override to add custom unpausing conditions or actions.
    */
    function _beforeUnpause() internal virtual {
    }

    /**
    * @dev Pauses the contract.
    * Requirements:
    * - Caller must have 'PAUSER_ROLE';
    * - Contract must be unpaused.
    */
    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _beforePause();
        _pause();
    }

    /**
    * @dev Unpauses the contract.
    * Requirements:
    * - Caller must have 'PAUSER_ROLE';
    * - Contract must be unpaused;
    */
    function unpause() external onlyRole(PAUSER_ROLE) whenPaused {
        _beforeUnpause();
        _unpause();
    }
}



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


/**
 * @dev Contract module which allows to perform basic checks on arguments.
 */
abstract contract RequirementsChecker {
    function _requireNonZeroAddress(address _address, string memory paramName) internal pure {
        require(_address != address(0), string(abi.encodePacked(paramName, ": cannot use zero address")));
    }

    function _requireArrayData(address[] memory _array, string memory paramName) internal pure {
        require(_array.length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireArrayData(uint256[] memory _array, string memory paramName) internal pure {
        require(_array.length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireStringData(string memory _string, string memory paramName) internal pure {
        require(bytes(_string).length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireSameLengthArrays(address[] memory _array1, uint256[] memory _array2, string memory paramName1, string memory paramName2) internal pure {
        require(_array1.length == _array2.length, string(abi.encodePacked(paramName1, ", ", paramName2, ": lengths must be equal")));
    }

    function _requireInRange(uint256 value, uint256 minValue, uint256 maxValue, string memory paramName) internal pure {
        string memory maxValueString = maxValue == 0 ? "inf" : Strings.toString(maxValue);
        require(minValue <= value && (maxValue == 0 || value <= maxValue), string(abi.encodePacked(paramName, ": must be in [", Strings.toString(minValue), "..", maxValueString, "] range")));
    }
}



/**
 * @dev Interface of a contract module which allows authorized account to withdraw assets in case of emergency.
 */
interface IEmergencyWithdrawer {
    /**
     * @dev Emitted when emergency withdrawal occurs.
     */
    event EmergencyWithdrawn(address asset, uint256[] ids, address to, string reason);

    /**
    * @dev Withdraws all balance of certain asset.
    * Emits a {EmergencyWithdrawn} event.
    */
    function emergencyWithdrawal(address asset, uint256[] calldata ids, address to, string calldata reason) external;
}



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


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


/**
 * @dev Contract module which allows authorized account to withdraw assets in case of emergency.
 */
abstract contract EmergencyWithdrawer is AccessControl, RequirementsChecker, IEmergencyWithdrawer {

    constructor () {
        _registerInterface(type(IEmergencyWithdrawer).interfaceId);
    }

    /**
    * @dev Withdraws all balance of certain asset.
    * @param asset Address of asset to withdraw.
    * @param ids Array of NFT ids to withdraw - if it is empty, withdrawing asset is considered to be IERC20, otherwise - IERC1155.
    * @param to Address where to transfer specified asset.
    * Requirements:
    * - Caller must have 'DEFAULT_ADMIN_ROLE';
    * - 'asset' address must be non-zero;
    * - 'to' address must be non-zero;
    * - 'reason' must be provided.
    * Emits {EmergencyWithdrawn} event.
    */
    function emergencyWithdrawal(address asset, uint256[] calldata ids, address to, string calldata reason) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _requireNonZeroAddress(asset, "asset");
        _requireNonZeroAddress(to, "to");
        _requireStringData(reason, "reason");

        if (ids.length == 0) {
            IERC20 token = IERC20(asset);
            token.transfer(to, token.balanceOf(address(this)));
        }
        else {
            IERC1155 token = IERC1155(asset);

            address[] memory addresses = new address[](ids.length);
            for(uint256 i = 0; i < ids.length; i++)
                addresses[i] = address(this); // actually only this one, but multiple times to call balanceOfBatch

            uint256[] memory balances = token.balanceOfBatch(addresses, ids);
            token.safeBatchTransferFrom(address(this), to, ids, balances, "");
        }

        emit EmergencyWithdrawn(asset, ids, to, reason);
    }
}


/**
 * @dev Interface of extension of {IERC165} that allows to handle receipts on receiving {IERC1155} assets.
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. _msgSender())
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
        @param operator The address which initiated the batch transfer (i.e. _msgSender())
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


/**
 * @dev Extension of {ERC165} that allows to handle receipts on receiving {ERC1155} assets.
 */
abstract contract ERC1155Receiver is ERC165Storage, IERC1155Receiver {

    constructor() {
        _registerInterface(type(IERC1155Receiver).interfaceId);
    }
}


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
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


/**
 * @dev Interface of extension of {IERC1155} that allows authorized account to mint new tokens.
 */
interface IERC1155Mintable is IERC1155 {
    /**
     * @notice Creates `amount` tokens of token type `id`, and assigns them to `account`.
     * @dev Should be callable only by MintableERC1155Predicate
     * Make sure minting is done only by this function
     * @param account user address for whom token is being minted
     * @param id token which is being minted
     * @param amount amount of token being minted
     * @param data extra byte data to be accompanied with minted tokens
     */
    function mint(address account, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @notice Batched version of singular token minting, where
     * for each token in `ids` respective amount to be minted from `amounts`
     * array, for address `to`.
     * @dev Should be callable only by MintableERC1155Predicate
     * Make sure minting is done only by this function
     * @param to user address for whom token is being minted
     * @param ids tokens which are being minted
     * @param amounts amount of each token being minted
     * @param data extra byte data to be accompanied with minted tokens
     */
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}



/**
 * @dev Interface of a contract containing identifier for Minter role.
 */
interface IRoleContainerMinter {
    /**
    * @dev Returns Minter role identifier.
    */
    function MINTER_ROLE() external view returns (bytes32);
}


interface IFearNft is IERC1155Mintable, IAccessControl, IRoleContainerMinter {
}


/**
 * @dev Contract implementing Fear PlayToEarn Competition.
 *
 * Using this contract caller can participate in Fear competitions and claim rewards.
 */
contract FearCompetition is AccessControl, Pausable, ReentrancyGuard, EmergencyWithdrawer, ERC1155Holder {
    /**
     * @dev Emitted when competition have been marked as finished and rewards have been distributed.
     */
    event CompetitionFinished(uint256 id, address[] indexed winners, uint256[] payouts);
    /**
     * @dev Emitted when user has claimed rewards.
     */
    event RewardsClaimed(address indexed caller, uint256[] ids, uint256[] amounts);

    /**
    * @dev Manager role identifier.
    */
    bytes32 public constant MANAGER_ROLE = "Manager";

    uint256 public constant BUYIN_NFT_ID = 17;
    uint256 public constant TROPHY_1ST_NFT_ID = 19;
    uint256 public constant TROPHY_2ND_NFT_ID = 20;
    uint256 public constant TROPHY_3RD_NFT_ID = 21;

    IFearNft private fearNftToken;

    uint256 private defaultBuyin = 10;
    uint256 private defaultEqualLimit = 10;
    uint256 private defaultItmPercentage = 33;

    struct Competition {
        string title;
        uint256 id;
        uint256 start;
        uint256 end;
        uint256 buyin;
        uint256 bonus;
        uint256 equalLimit;
        uint256 itmPercentage;
        uint16 participantsCount;
        bool finalized;
    }

    uint256[] private competitionsIds; // array of timewise sorted competitions ids
    uint256[] private nftIds = [BUYIN_NFT_ID, TROPHY_1ST_NFT_ID, TROPHY_2ND_NFT_ID, TROPHY_3RD_NFT_ID];
    mapping (uint256 => Competition) private competitions;
    mapping (uint256 => mapping (address => bool)) private participationStatus;
    mapping (address => mapping (uint256 => uint256)) private rewardsBalance;

    constructor(address fearNftTokenAddress) {
        fearNftToken = IFearNft(fearNftTokenAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        competitionsIds.push(0);

        // contract is paused at deployment time
        _pause();
    }

    function _beforeUnpause() internal view virtual override {
        require(fearNftToken.hasRole(fearNftToken.MINTER_ROLE(), address(this)), "Not a minter");
    }

    function _requireNotFinalizedCompetition(uint256 id) private view {
        Competition memory competition = competitions[id];
        require(competition.id > 0, "Competition is not found");
        require(!competition.finalized, "Competition is finalized");
    }

    function _competitionAt(uint i) private view returns (Competition memory) {
        return competitions[competitionsIds[i]];
    }

    function _getCurrentCompetitionId() private view returns (uint256) {
        for (uint i = competitionsIds.length - 1; i > 0; i--) {
            if (_competitionAt(i).start <= block.timestamp && block.timestamp <= _competitionAt(i).end) // timestamp inside competition start/end
                return competitionsIds[i];
            if (_competitionAt(i).end < block.timestamp) // sorted lookup cutoff - no need to iterate further (everything else will have earlier start/end)
                break;
        }
        return 0;
    }

    function _getClosestAvailableStartDate() private view returns (uint256) {
        uint256 mondayStart = DateTimeHelper.getMondayStart(block.timestamp);
        for (uint i = competitionsIds.length - 1; i > 0; i--) {
            if (_competitionAt(i).start <= mondayStart && mondayStart <= _competitionAt(i).end)
                return _competitionAt(i).end + 1;
            if (_competitionAt(i).end < mondayStart) // sorted lookup cutoff
                break;
        }
        return mondayStart;
    }

    function _getClosestAvailableEndDate() private view returns (uint256) {
        uint256 sundayEnd = DateTimeHelper.getSundayEnd(block.timestamp);
        for (uint i = competitionsIds.length - 1; i > 0; i--) {
            if (_competitionAt(i).start <= sundayEnd && sundayEnd <= _competitionAt(i).end)
                return _competitionAt(i).start - 1;
            if (_competitionAt(i).end < sundayEnd) // sorted lookup cutoff
                break;
        }
        return sundayEnd;
    }

    function _getNextDefaultCompetition() private view returns (Competition memory) {
        return Competition("", competitionsIds.length, _getClosestAvailableStartDate(), _getClosestAvailableEndDate(),
                            defaultBuyin, 0, defaultEqualLimit, defaultItmPercentage, 0, false);
    }

    function _checkParticipation(uint256 id, address user) private view returns (bool) {
        return participationStatus[id][user];
    }

    function _getCompetitionPayouts(uint256 id) private view returns (uint256[] memory) {
        return PayoutsHelper.getPayouts(competitions[id].participantsCount,
                                        competitions[id].equalLimit,
                                        competitions[id].itmPercentage,
                                        competitions[id].participantsCount * competitions[id].buyin + competitions[id].bonus);
    }

    function _getRewardBalance(address user) private view returns (uint256[] memory, uint256[] memory) {
        uint nonZeroCount;
        for (uint i = 0; i < nftIds.length; i++)
            if (rewardsBalance[user][nftIds[i]] > 0)
                nonZeroCount++;

        uint256[] memory ids = new uint256[](nonZeroCount);
        uint256[] memory amounts = new uint256[](nonZeroCount);

        uint counter;
        for (uint i = 0; i < nftIds.length; i++)
            if (rewardsBalance[user][nftIds[i]] > 0) {
                ids[counter] = nftIds[i];
                amounts[counter] = rewardsBalance[user][nftIds[i]];
                counter++;
            }

        return (ids, amounts);
    }
   
    function _createCompetition(string memory title, uint256 id, uint256 start, uint256 end, uint256 buyin, uint256 equalLimit, uint256 itmPercentage) private {
        competitions[id] = Competition(title, id, start, end, buyin, 0, equalLimit, itmPercentage, 0, false);

        // adding new index and rebuilding sorted indices (pushing new one down to its position)
        competitionsIds.push(id);
        for (uint i = competitionsIds.length - 1; i >= 1; i--) {
            if (_competitionAt(i).start < _competitionAt(i - 1).end)
                (competitionsIds[i], competitionsIds[i - 1]) = (competitionsIds[i - 1], competitionsIds[i]);
            else
                break;
        }
    }

    /**
    * @dev Returns current competition.
    * @return Competition that takes place in current time.
    * Requirements:
    * - Contract must not be paused;
    */
    function getCurrentCompetition() external view whenNotPaused returns (Competition memory) {
        Competition memory result = competitions[_getCurrentCompetitionId()];
        return result.id != 0 ? result : _getNextDefaultCompetition(); // if nothing is found, return stub result (this competition will be lazy-initialized on next call to 'enter' function)
    }

    /**
    * @dev Allows caller to enter current competition.
    * Requirements:
    * - Contract must not be paused;
    * - Caller must not participate in current competition;
    * - Caller must have enough tokens on his balance to pay for current competition buyin;
    * - Contract must be approved to transfer caller's NFTs.
    */
    function enterCurrentCompetition() external whenNotPaused nonReentrant {
        uint256 id = _getCurrentCompetitionId();
        if (id == 0) {
            Competition memory next = _getNextDefaultCompetition();
            id = next.id;
            _createCompetition("", id, next.start, next.end, next.buyin, next.equalLimit, next.itmPercentage);
        }

        require(!participationStatus[id][_msgSender()], "You are participating in current competition already");

        participationStatus[id][_msgSender()] = true;
        Competition storage curCompetition = competitions[id];
        curCompetition.participantsCount++;

        // if caller has enough tokens for buyin in his rewards balance, he can use it to enter the competition without transferring to the contract (they are already here)
        if (rewardsBalance[_msgSender()][BUYIN_NFT_ID] >= curCompetition.buyin)
            rewardsBalance[_msgSender()][BUYIN_NFT_ID] -= curCompetition.buyin;
        else
            fearNftToken.safeTransferFrom(_msgSender(), address(this), BUYIN_NFT_ID, curCompetition.buyin, "");
    }

    /**
    * @dev Returns caller's participation status in current competition.
    * @return True if caller participates in current competition. False oterwise.
    * Requirements:
    * - Contract must not be paused.
    */
    function checkCurrentCompetitionParticipation() external view whenNotPaused returns (bool) {
        return _checkParticipation(_getCurrentCompetitionId(), _msgSender());
    }

    /**
    * @dev Returns current competition payouts.
    * @return Array of NFT amounts players get for taking winning places.
    * Requirements:
    * - Contract must not be paused.
    */
    function getCurrentCompetitionPayouts() external view whenNotPaused returns (uint256[] memory) {
        return _getCompetitionPayouts(_getCurrentCompetitionId());
    }

    /**
    * @dev Returns caller's reward balance.
    * @return ids NFT ids caller has on contract balance
    * @return amounts Corresponding array of amounts for each NFT
    */
    function getRewardBalance() external view returns (uint256[] memory, uint256[] memory) {
        return _getRewardBalance(_msgSender());
    }

    /**
    * @dev Allows caller to withdraw all rewards to his account.
    * Nothing happens if caller doesn't have any rewards on contract balance.
    */
    function claimRewards() external nonReentrant {
        uint256[] memory ids;
        uint256[] memory amounts;
        (ids, amounts) = _getRewardBalance(_msgSender());

        for (uint i = 0; i < ids.length; i++)
            rewardsBalance[_msgSender()][ids[i]] = 0;

        fearNftToken.safeBatchTransferFrom(address(this), _msgSender(), ids, amounts, "");

        emit RewardsClaimed(_msgSender(), ids, amounts);
    }

    /**
    * @dev Returns all existing competitions ids for certain time period.
    * @param fromTime Timestamp of period start.
    * @param toTime Timestamp of period end.
    * @return Array of ids of competitions that start/end timestamps intersect with specified period.
    * Requirements:
    * - Caller must have 'MANAGER_ROLE';
    * - 'fromTime' must be less or equal to 'toTime'.
    */
    function getCompetitionIds(uint256 fromTime, uint256 toTime) external view onlyRole(MANAGER_ROLE) returns (uint256[] memory) {
        require(fromTime <= toTime, "fromTime must be less or equal to toTime");

        uint256[] memory result;
        uint firstIndex;
        uint lastIndex;

        for (uint i = competitionsIds.length - 1; i > 0; i--) {
            if (_competitionAt(i).end < fromTime)
                break;
            if (_competitionAt(i).end >= fromTime)
                firstIndex = i;
            if (lastIndex == 0 && _competitionAt(i).start <= toTime)
                lastIndex = i;
        }

        if (firstIndex != 0 && lastIndex >= firstIndex) {
            result = new uint256[](lastIndex - firstIndex + 1);
            uint counter;
            for (uint i = firstIndex; i <= lastIndex; i++) {
                result[counter] = competitionsIds[i];
                counter++;
            }
        }

        return result;
    }

    /**
    * @dev Returns certain competition.
    * @param id Competition id.
    * @return Competition with specified id.
    * Requirements:
    * - Caller must have 'MANAGER_ROLE'.
    */
    function getCompetition(uint256 id) external view onlyRole(MANAGER_ROLE) returns (Competition memory) {
        return competitions[id];
    }
    
    /**
    * @dev Returns participation status of certain user in certain competition.
    * @param id Competition id.
    * @param user User address.
    * @return True if the user participates/participated in the competition. False oterwise.
    * Requirements:
    * - Caller must have 'MANAGER_ROLE'.
    */
    function checkParticipation(uint256 id, address user) external view onlyRole(MANAGER_ROLE) returns (bool) {
        return _checkParticipation(id, user);
    }

    /**
    * @dev Adds competition.
    * @param start Timestamp of competition start.
    * @param end Timestamp of competition end.
    * @param buyin Buyin amount to enter the competition.
    * Requirements:
    * - Caller must have 'MANAGER_ROLE';
    * - start must be less than end;
    * - buyin must be in [1..inf] range;
    * - itmPercentage must be in [1..100] range;
    * - Competition period must not intersect any other existing competition period.
    */
    function addCompetition(string memory title, uint256 start, uint256 end, uint256 buyin, uint256 equalLimit, uint256 itmPercentage) external onlyRole(MANAGER_ROLE) {
        require(start < end, "start must be less than end");
        _requireInRange(buyin, 1, 0, "buyin");
        _requireInRange(itmPercentage, 1, 100, "itmPercentage");

        for (uint i = competitionsIds.length - 1; i > 0; i--) {
            if ((_competitionAt(i).start <= start && start <= _competitionAt(i).end)
                || (_competitionAt(i).start <= end && end <= _competitionAt(i).end)
                || (_competitionAt(i).start >= start && _competitionAt(i).end <= end)) // new competition covers existing one
                revert("Intersecting start/end found");
            if (_competitionAt(i).end < start) // sorted lookup cutoff
                break;
        }

        _createCompetition(title, competitionsIds.length, start, end, buyin, equalLimit, itmPercentage);
    }

    /**
    * @dev Allows to add bonus to certain competition prize pool.
    * @param id Competition id.
    * @param bonusAmount Amount of NFTs to add to the prize pool.
    * Requirements:
    * - Caller must have 'MANAGER_ROLE';
    * - Competition with specified id must exist;
    * - Competition must not be finalized.
    */
    function addBonus(uint256 id, uint256 bonusAmount) external onlyRole(MANAGER_ROLE) {
        _requireNotFinalizedCompetition(id);
        
        Competition storage competition = competitions[id];
        competition.bonus += bonusAmount;
        fearNftToken.mint(address(this), BUYIN_NFT_ID, bonusAmount, "");
    }

    /**
    * @dev Sets winners to certain competition.
    * @param id Competition id.
    * @param winners Array of winners address (according to the ranking).
    * Requirements:
    * - Caller must have 'MANAGER_ROLE';
    * - Competition with specified id must exist;
    * - Competition must not be finalized;
    * - Competition must be ended at the current time;
    * - Winners count must be equal to the competition payouts length;
    * - All specified addresses actually participated in the competition.
    */
    function setWinners(uint256 id, address[] calldata winners) external onlyRole(MANAGER_ROLE) {
        _requireNotFinalizedCompetition(id);
        require(competitions[id].end < block.timestamp, "Competition must be ended");

        uint256[] memory payouts = _getCompetitionPayouts(id);
        _requireSameLengthArrays(winners, payouts, "winners", "payouts");

        for (uint i = 0; i < winners.length; i++)
            require(participationStatus[id][winners[i]], "Not a participant");

        Competition storage competition = competitions[id];
        competition.finalized = true;

        for (uint i = 0; i < winners.length; i++)
            rewardsBalance[winners[i]][BUYIN_NFT_ID] += payouts[i];

        // trophies
        rewardsBalance[winners[0]][TROPHY_1ST_NFT_ID] += 1;
        fearNftToken.mint(address(this), TROPHY_1ST_NFT_ID, 1, "");

        if (winners.length >= 2) {
            rewardsBalance[winners[1]][TROPHY_2ND_NFT_ID] += 1;
            fearNftToken.mint(address(this), TROPHY_2ND_NFT_ID, 1, "");
        }
        if (winners.length >= 3) {
            rewardsBalance[winners[2]][TROPHY_3RD_NFT_ID] += 1;
            fearNftToken.mint(address(this), TROPHY_3RD_NFT_ID, 1, "");
        }

        emit CompetitionFinished(id, winners, payouts);
    }
    
    /**
    * @dev Allows to set default payout distribution params.
    * @param buyin Participants limit for equal rewards distribution.
    * @param equalLimit Participants limit for equal rewards distribution.
    * @param itmPercentage Percentage of paid places comparing to participants count.
    * Requirements:
    * - Caller must have 'MANAGER_ROLE';
    * - buyin must be in [1..inf] range;
    * - itmPercentage must be in [1..100] range.
    */
    function setDefaultCompetitionParams(uint256 buyin, uint256 equalLimit, uint256 itmPercentage) external onlyRole(MANAGER_ROLE) {
        _requireInRange(buyin, 1, 0, "buyin");
        _requireInRange(itmPercentage, 1, 100, "itmPercentage");
        defaultBuyin = buyin;
        defaultEqualLimit = equalLimit;
        defaultItmPercentage = itmPercentage;
    }
}