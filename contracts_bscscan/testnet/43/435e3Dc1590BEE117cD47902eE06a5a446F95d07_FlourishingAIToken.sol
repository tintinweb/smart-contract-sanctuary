//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20VestableInTimestamp.sol";

contract FlourishingAIToken is ERC20VestableInTimestamp {
    uint8 private constant DECIMALS = 18;
    uint256 private constant TOKEN_WEI = 10**uint256(DECIMALS);

    uint256 private constant INITIAL_WHOLE_TOKENS = uint256(55 * (10**6)); // 55 million
    uint256 private constant INITIAL_SUPPLY =
        uint256(INITIAL_WHOLE_TOKENS) * uint256(TOKEN_WEI);

    constructor(address admin) ERC20("Flourishing AI Token", "AI") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(GRANTOR_ROLE, admin);

        _mint(admin, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 amount) public onlyAdmin {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract ERC20VestableInTimestamp is ERC20Burnable, AccessControl {
    bytes32 public constant GRANTOR_ROLE = keccak256("GRANTOR_ROLE");
    using SafeMath for uint256;

    // Date-related constants for sanity-checking dates to reject obvious erroneous inputs
    // and conversions from seconds to days and years that are more or less leap year-aware.
    uint256 private constant TEN_YEARS_SECONDS = 60 * 60 * 24 * 365 * 10; /* Seconds in ten years */
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60; /* 86400 seconds in a day */
    uint256 private constant JAN_1_2000 = 946684800; /* Saturday, January 1, 2000 0:00:00 (GMT) (see https://www.epochconverter.com/) */
    uint256 private constant JAN_1_3000 = 32503680000;

    /**
     * Vesting
     */
    struct VestingSchedule {
        bool isActive; //
        uint256 startDay; //
        uint256 cliffDuration; //
        uint256 duration; //
        uint256 interval; //
    }

    /**
     * User's veting information
     */
    struct UserVestingInfo {
        uint256 scheduleId;
        uint256 vestingAmount;
    }

    // Info of each vesting schedule.
    mapping(uint256 => VestingSchedule) public vestingSchedules;
    // Vesting info of user.
    mapping(address => UserVestingInfo) public userVestingInfo;
    // Timestamp allows to spend token.
    uint256 public endTimeLock;
    // Addresses which are allowed to spend within locking period.
    mapping(address => bool) public whiteLists;

    event VestingScheduleUpdated(
        uint256 id,
        bool isActive,
        uint256 startDay,
        uint256 cliffDuration,
        uint256 indexed duration,
        uint256 interval
    );

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "must have admin role");
        _;
    }

    modifier onlyGrantor() {
        require(isGrantor(_msgSender()), "must have grantor role");
        _;
    }

    modifier onlyGrantorOrSelf(address account) {
        require(
            isGrantor(_msgSender()) || _msgSender() == account,
            "must have grantor role or self"
        );
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isGrantor(address account) public view returns (bool) {
        return hasRole(GRANTOR_ROLE, account);
    }

    // ===========================================================
    // === Adminstrators's config functions.
    // ===========================================================

    // Set a batch of addresses as whitelists.
    function setWhiteList(address[] memory whiteListAddresses, bool status)
        public
        onlyGrantor
    {
        require(whiteListAddresses.length > 0, "invalid length");
        for (uint256 i = 0; i < whiteListAddresses.length; i++) {
            require(!whiteLists[whiteListAddresses[i]], "already whitelist");
            whiteLists[whiteListAddresses[i]] = status;
        }
    }

    function setEndTimeLock(uint256 _endTimeLock) public onlyGrantor {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have grantor role"
        );
        require(
			_endTimeLock > block.timestamp,
			"end lock time past"
        );
        endTimeLock = _endTimeLock;
    }

    function updateVestingSchedule(
        uint256 _id,
        bool _isActive,
        uint256 _startDay,
        uint256 _cliffDuration,
        uint256 _duration,
        uint256 _interval
    ) public onlyGrantor {
        // Chech for a valid vesting schedule give (disallow absurd values to reject likely bad input).
        require(
            _duration > 0 &&
                _duration <= TEN_YEARS_SECONDS &&
                _cliffDuration < _duration &&
                _interval >= 1,
            "invalid vesting schedule"
        );

        // Make sure the duration values are in harmony with interval (both should be an exact multiple of interval).
        require(
            _duration % _interval == 0 && _cliffDuration % _interval == 0,
            "invalid cliff/duration for interval"
        );

        require(
            _startDay >= JAN_1_2000 && _startDay < JAN_1_3000,
            "invalid start day"
        );

        VestingSchedule storage vestingSchedule = vestingSchedules[_id];
        vestingSchedule.isActive = _isActive;
        vestingSchedule.startDay = _startDay;
        vestingSchedule.cliffDuration = _cliffDuration;
        vestingSchedule.duration = _duration;
        vestingSchedule.interval = _interval;
    }

    // ============================================================
    // === Adminstrator's functions to apply a vesting schedule for user.
    // ============================================================

    /**
     * @dev This one-time operation permanently establishes a vesting schedule in the given account.
     *
     * For standard grants, this establishes the vesting schedule in the beneficiary's account.
     * For uniform grants, this establishes the vesting schedule in the linked grantor's account.
     *
     * @param _vestingLocation = Account into which to store the vesting schedule. Can be the account
     *   of the beneficiary (for one-off grants) or the account of the grantor (for uniform grants
     *   made from grant pools).
     * @param _vestingType = Type of Vesting schedule.
     * @param _vestingAmount = The amount of token will be vested.
     */
    function _applyVestingSchedule(
        address _vestingLocation,
        uint256 _vestingType,
        uint256 _vestingAmount
    ) internal returns (bool) {
        require(_vestingType != 0, "invalid vesting schedule type");
        UserVestingInfo storage user = userVestingInfo[_vestingLocation];
        require(user.scheduleId == 0, "already apply vesting schedule");
        require(
            vestingSchedules[_vestingType].isActive == true,
            "vesting schedule is inactive"
        );
        user.scheduleId = _vestingType;
        user.vestingAmount = _vestingAmount;

        return true;
    }

    function _hasVestingSchedule(address _account)
        internal
        view
        returns (bool)
    {
        if (userVestingInfo[_account].scheduleId == 0) return false;
        return vestingSchedules[userVestingInfo[_account].scheduleId].isActive;
    }

    /**
     * @dev Immediately set vesting schedule to an address, the token in their wallet will vest over time
     * according to this schedule. The overall duration and cliff duration of the grant must
     * be an even multiple of the vesting interval.
     *
     * @param beneficiaries = Addresses to which tokens will be vested.
     * @param vestingTypes = Type of vesting schedule.
     * @param vestingAmounts = The amount of user will be vested.
     */
    function applyVestingSchedule(
        address[] calldata beneficiaries,
        uint256[] calldata vestingTypes,
        uint256[] calldata vestingAmounts
    ) public onlyGrantor returns (bool ok) {
        require(beneficiaries.length == vestingTypes.length, "invalid length");
        require(vestingTypes.length == vestingAmounts.length, "invalid length");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            // The vesting schedule is unique to this wallet and so will be stored here,
            _applyVestingSchedule(
                beneficiaries[i],
                vestingTypes[i],
                vestingAmounts[i]
            );
        }

        return true;
    }

    // ============================================================
    // === Check vesting.
    // ============================================================

    // Get the timestamp of the current day, in seconds since the UNIX epoch.
    function today() public view returns (uint256) {
        return block.timestamp;
    }

    function _effectiveDay(uint256 onDayOrToday)
        internal
        view
        returns (uint256)
    {
        return onDayOrToday == 0 ? today() : onDayOrToday;
    }

    /**
     * @dev Determines the amount of token that have not vested in the give account.
     *
     * notVestAmount = vestingAmount * (endDate - onDate)/(endDate - startDate)
     *
     * @param _grantHolder = The account to check
     * @param _onDayOrToday = The day to check, in seconds since the UNIX epoch.
     * Pass `0` if indicate TODAY.
     */
    function _getNotVestedAmount(address _grantHolder, uint256 _onDayOrToday)
        internal
        view
        returns (uint256)
    {
        UserVestingInfo storage user = userVestingInfo[_grantHolder];
        if (user.scheduleId == 0) return uint256(0);
        VestingSchedule storage vesting = vestingSchedules[user.scheduleId];
        uint256 onDay = _effectiveDay(_onDayOrToday);

        // If there's no schedule, or before the vesting cliff, then the full amount is not vested.
        if (
            !vesting.isActive ||
            onDay < vesting.startDay.add(vesting.cliffDuration)
        ) {
            // None are vested (all are not vested)
            return user.vestingAmount;
        }
        // If after end of cliff + vesting, then the not vested amount is zero (all are vested).
        else if (
            onDay >=
            vesting.startDay.add(vesting.cliffDuration.add(vesting.duration))
        ) {
            // All are vested (none are not vested)
            return uint256(0);
        }
        // Otherwise a fractional amount is vested.
        else {
            // Compute the exact number of days vested.
            uint256 daysVested =
                onDay.sub(vesting.startDay.add(vesting.cliffDuration));
            // Adjust result rounding down to take into consideration the interval.
            uint256 effectiveDaysVested =
                (daysVested.div(vesting.interval)).mul(vesting.interval);

            // Compute the fraction vested from schedule using 224.32 fixed point math for date range ratio.
            // Note: This is safe in 256-bit math because max value of X billion tokens = X*10^27 wei, and
            // typical token amounts can fit into 90 bits. Scaling using a 32 bits value results in only 125
            // bits before reducing back to 90 bits by dividing. There is plenty of room left, even for token
            // amounts many orders of magnitude greater than mere billions.
            uint256 vested =
                user.vestingAmount.mul(effectiveDaysVested).div(vesting.duration);
            return user.vestingAmount.sub(vested);
        }
    }

    /**
     * @dev Computes the amount of funds in the given account which are available for use as of
     * the given day. If there's no vesting schedule then 0 tokens are considered to be vested and
     * this just returns the full account balance.
     *
     * availableAmount = totalFunds - notVestedAmount.
     *
     * @param _grantHolder = The account to check.
     * @param _onDay = The day to check for, in seconds since the UNIX epoch.
     */
    function _getAvailableAmount(address _grantHolder, uint256 _onDay)
        internal
        view
        returns (uint256)
    {
        uint256 totalTokens = balanceOf(_grantHolder);
        uint256 vested =
            totalTokens.sub(
                _getNotVestedAmount(_grantHolder, _onDay)
            );
        return vested;
    }

    function vestingForAccountAsOf(address holder, uint256 onDayOrToday)
        public
        view
        onlyGrantorOrSelf(holder)
        returns (
            uint256 amountVested,
            uint256 amountNotVested,
            uint256 amountOfGrant,
            uint256 vestStartDay,
            uint256 vestDuration,
            uint256 cliffDuration,
            uint256 vestIntervalDays,
            bool isActive
        )
    {
        UserVestingInfo storage user = userVestingInfo[holder];
        VestingSchedule storage vesting =
            vestingSchedules[user.scheduleId];
        uint256 notVestedAmount =
            _getNotVestedAmount(holder, onDayOrToday);

        return (
            user.vestingAmount.sub(notVestedAmount),
            notVestedAmount,
            user.vestingAmount,
            vesting.startDay,
            vesting.duration,
            vesting.cliffDuration,
            vesting.interval,
            vesting.isActive
        );
    }

    /**
     * @dev returns all information about the grant's vesting as of the given day
     * for the current account, to be called by the account holder.
     *
     * @param onDayOrToday = The day to check for, in seconds since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     */
    function vestingAsOf(uint256 onDayOrToday)
        public
        view
        returns (
            uint256 amountVested,
            uint256 amountNotVested,
            uint256 amountOfGrant,
            uint256 vestStartDay,
            uint256 cliffDuration,
            uint256 vestDuration,
            uint256 vestIntervalDays,
            bool isActive
        )
    {
        return vestingForAccountAsOf(_msgSender(), onDayOrToday);
    }

    /**
     * @dev returns true if the account has sufficient funds available to cover the given amount,
     *   including consideration for vesting tokens.
     *
     * @param _account = The account to check.
     * @param _amount = The required amount of vested funds.
     * @param _onDay = The day to check for, in seconds since the UNIX epoch.
     */
    function _fundsAreAvailableOn(
        address _account,
        uint256 _amount,
        uint256 _onDay
    ) internal view returns (bool) {
        return (_amount <= _getAvailableAmount(_account, _onDay));
    }

    /**
     * @dev Modifier to make a function callable only when the amount is sufficiently vested right now.
     *
     * @param account = The account to check.
     * @param amount = The required amount of vested funds.
     */
    modifier onlyIfFundsAvailableNow(address account, uint256 amount) {
        // Distinguish insufficient overall balance from insufficient vested funds balance in failure msg.
        require(
            _fundsAreAvailableOn(account, amount, today()),
            balanceOf(account) < amount
                ? "insufficient funds"
                : "insufficient vested funds"
        );
        _;
    }

    // =========================================================================
    // === Overridden ERC20 functionality
    // =========================================================================

    /**
     * @dev Methods transfer() and approve() require an additional available funds check to
     * prevent spending held but non-vested tokens. Note that transferFrom() does NOT have this
     * additional check because approved funds come from an already set-aside allowance, not from the wallet.
     */
    function transfer(address to, uint256 value)
        public
        override
        onlyIfFundsAvailableNow(_msgSender(), value)
        returns (bool)
    {
        if (endTimeLock != 0 && block.timestamp <= endTimeLock) {
            require(
                whiteLists[_msgSender()] || isGrantor(_msgSender()),
                "sender is not allowed to transfer until lock time end"
            );
        }

        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override onlyIfFundsAvailableNow(from, value) returns (bool) {
        if (endTimeLock != 0 && block.timestamp <= endTimeLock) {
            require(
                whiteLists[from] || isGrantor(_msgSender()),
                "sender is not allowed to transfer until lock time end"
            );
        }

        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Additional available funds check to prevent spending held but non-vested tokens.
     */
    function approve(address spender, uint256 value)
        public
        override
        onlyIfFundsAvailableNow(_msgSender(), value)
        returns (bool)
    {
        return super.approve(spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
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
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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