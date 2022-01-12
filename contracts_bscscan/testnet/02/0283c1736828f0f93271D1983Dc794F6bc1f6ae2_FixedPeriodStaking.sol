// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FixedPeriodStaking is AccessControl{

    event PoolsSet (PoolInfo[]);
    event PoolsDurationChange (uint256 poolId, uint256 duration);
    event NewDeposit (address user, uint256 amount, uint256 depositId);
    event Withdrawal (address user, uint256 amount, uint256 depositId);
    event NewPoolsSnapshot (uint256 cycleNumber);

    struct PoolInfo{
        uint256 duration;
        uint256 poolShare;
        uint256 pendingShares;
        uint256 totalShares;
        uint256 unsharedBalance;
    }

    struct PoolSnapshot{
        uint256 PPS;
        uint256 cycleNumber;
    }

    struct LastUpdate{
        uint256 contractBalance;
        uint256 cycleNumber;
    }

    struct Deposit {
        uint256 poolId;
        uint256 amount;         //amount deposited
        uint256 shares;         //shares
        uint256 cycleNumber;
        bool active;
    }

    bytes32 internal constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    IERC20 public stakeToken;
    PoolInfo[] public pools;
    LastUpdate public lastUpdate;
    //address => deposits
    mapping(address => Deposit[]) public deposits;
    //poolId => PoolSnapshots
    mapping(uint256 => PoolSnapshot[]) public poolSnapshots;

    uint256 public cycleDuration;
    uint256 public currentCycle;
    uint256 public lastCycleTimestamp;
    uint256 public snapshotRewardPerSecond;
    uint256 private newDepositsAmount = 0;
    uint256 private newWithdrawalsAmount = 0;


    /*
     * IERC20 _stakeToken - Stake token address
     * uint256 _cycleDuration - Cycle duration (in seconds)
     * uint256 _snapshotRewardPerSecond - Reward per second for making snapshot.
     *** (Counts starting from the first second of end of cycle)
     * address governanceAddress - Address of governance contract
     */
    constructor(
        IERC20 _stakeToken,
        uint256 _cycleDuration,
        uint256 _snapshotRewardPerSecond,
        address governanceAddress
    ){
        stakeToken = _stakeToken;
        cycleDuration = _cycleDuration;
        snapshotRewardPerSecond = _snapshotRewardPerSecond;
        _setupRole(GOVERNANCE_ROLE, governanceAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, governanceAddress);
    }


    /*
     * Params
     * uint256 poolId - ID index of pool
     * uint256 amount - Amount to stake
     *
     * User stakes specific amount of tokens for a number of cycles according to chosen pool
     * User should allow {transferFrom} for this contract
     * Returns deposit ID index
     */
    function stake(uint256 poolId, uint256 amount) external returns(uint256 depositId) {
        require(pools.length > poolId, "Invalid pool ID");
        require(stakeToken.balanceOf(msg.sender) >= amount, "Not enough balance");
        require(stakeToken.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");


        stakeToken.transferFrom(msg.sender, address(this), amount);
        uint256 shares = amount / 10**9;

        bool toNextCycle = block.timestamp > (lastCycleTimestamp + cycleDuration/2);
        uint256 depositStartingCycle;
        if(toNextCycle){
            depositStartingCycle = currentCycle + 1;
            pools[poolId].pendingShares += shares;
        } else {
            depositStartingCycle = currentCycle;
            pools[poolId].totalShares += shares;
        }

        deposits[msg.sender].push(Deposit({
        poolId: poolId,
        amount: amount,
        shares: shares,
        cycleNumber: depositStartingCycle,
        active: true
        }));

        newDepositsAmount += amount;

        uint256 depositId = deposits[msg.sender].length - 1;
        emit NewDeposit(msg.sender, amount, depositId);

        if(lastUpdate.cycleNumber == 0) {
            lastUpdate.cycleNumber = currentCycle;
        }
        return depositId;
    }


    /*
     * Params
     * uint256 depositId - ID index of deposit
     *
     * User withdraws deposited amount of tokens + reward amount, earned in pool
     */
    function withdraw(uint256 depositId) external {
        require(deposits[msg.sender].length > depositId, "Invalid depositId");
        Deposit storage userDeposit = deposits[msg.sender][depositId];
        uint256 poolId = userDeposit.poolId;
        require(userDeposit.active == true, "Already withdrawn");
        uint256 allowedCycleToWithdraw = userDeposit.cycleNumber + pools[poolId].duration;
        require(currentCycle >= allowedCycleToWithdraw, "Can't withdraw yet");

        PoolSnapshot[] memory snapshots = poolSnapshots[poolId];

        uint256 rewardAmount = 0;
        uint256 startCycle = userDeposit.cycleNumber - snapshots[1].cycleNumber + 1;
        uint256 endCycle = startCycle + pools[userDeposit.poolId].duration;
        for(uint i = startCycle; i < endCycle; i++) {
            if(snapshots[i].cycleNumber >= userDeposit.cycleNumber){
                rewardAmount += snapshots[i].PPS * userDeposit.shares;
            }
        }
        uint256 amountToTransfer = rewardAmount + userDeposit.amount;
        userDeposit.active = false;
        stakeToken.transfer(msg.sender, amountToTransfer);
        newWithdrawalsAmount += amountToTransfer;
        pools[poolId].totalShares -= userDeposit.shares;
        uint256 depositId = deposits[msg.sender].length - 1;
        emit Withdrawal(msg.sender, amountToTransfer, depositId);
    }


    /*
     * Function creates pools snapshot for current cycle
     * Can be called once in a cycle
     * Caller will receive reward of {seconds_after_last_cycle_end} * {snapshotRewardPerSecond} tokens
     */
    function snapshotPools() external {
        require(block.timestamp >= lastCycleTimestamp + cycleDuration, "Can't snapshot yet");
        uint256 balance = stakeToken.balanceOf(address(this));
        uint256 snapshotReward = getSnapshotRewardAmount();
        stakeToken.transfer(msg.sender, snapshotReward);

        uint256 toSplit = getCycleIncome();

        lastUpdate.cycleNumber = currentCycle;
        lastUpdate.contractBalance = balance;

        for(uint i = 0; i < pools.length; i++){
            //making snapshot
            uint256 income = toSplit * pools[i].poolShare / 10000;
            uint256 PPS;
            if(pools[i].totalShares > 0) {
                if(pools[i].unsharedBalance > 0) {
                    income += pools[i].unsharedBalance;
                    pools[i].unsharedBalance = 0;
                }
                PPS = income / pools[i].totalShares;
            } else {
                pools[i].unsharedBalance += income;
                income = 0;
                PPS = 0;
            }
            poolSnapshots[i].push(PoolSnapshot({
                PPS: PPS,
                cycleNumber: currentCycle
            }));

            if(pools[i].pendingShares > 0) {
                pools[i].totalShares += pools[i].pendingShares;
                pools[i].pendingShares = 0;
            }
        }

        newDepositsAmount = 0;
        newWithdrawalsAmount = 0;

        currentCycle += 1;
        lastCycleTimestamp += cycleDuration;
        emit NewPoolsSnapshot(currentCycle);
    }


    /*
     * Function calculates reward amount for calling snapshotPools() function
     */
    function getSnapshotRewardAmount() public view returns(uint256) {
        if(block.timestamp >= lastCycleTimestamp + cycleDuration){
            uint256 snapshotReward;
            uint256 income = getCycleIncome();
            uint256 calculatedReward = (block.timestamp - (lastCycleTimestamp + cycleDuration))
                    * snapshotRewardPerSecond;

            if(income > calculatedReward) {
                return calculatedReward;
            } else {
                return income;
            }
        }
        return 0;
    }


    /*
     * Function returns contract income amount since last snapshot
     */
    function getCycleIncome() private view returns(uint256) {
        return stakeToken.balanceOf(address(this))
        - newDepositsAmount
        + newWithdrawalsAmount
        - lastUpdate.contractBalance;
    }


    /*
     * Params
     * uint256[] calldata _duration - Array of duration (in cycles) for which users deposits will be locked
     * uint256[] calldata _poolShare - Array of shares of income tokens, that pools will receive (in basis points)
     * (sum of shares must be 10000)
     *
     * Function sets pools with specific shares and durations
     *** Example: [1,4], [4000, 6000] will set 2 pools:
     *** Pool #1: will have duration of 1 cycle and will get 40% of token income
     *** Pool #2: will have duration of 4 cycles and will get 60% of token income
     *** User, that stakes in pool #1, will have his funds locked for 1 cycle and will be able to withdraw afterwards
     */
    function setPools (
        uint256[] calldata _duration,
        uint256[] calldata _poolShare
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(_duration.length == _poolShare.length, "Invalid arrays");
        require(_duration.length >= pools.length, "Invalid array length");

        uint256 totalShares = 0;
        for(uint i = 0; i < _duration.length; i++){
            totalShares += _poolShare[i];
            if(pools.length <= i){
                pools.push(PoolInfo({
                duration : _duration[i],
                poolShare : _poolShare[i],
                pendingShares : 0,
                totalShares : 0,
                unsharedBalance : 0
                }));
            } else {
                pools[i].duration = _duration[i];
                pools[i].poolShare = _poolShare[i];
            }

            if(poolSnapshots[i].length == 0) {
                poolSnapshots[i].push(PoolSnapshot({
                    PPS: 0,
                    cycleNumber: currentCycle
                }));
            }
        }
        require(totalShares == 10000, "Shares sum is not 10000");

        if(lastCycleTimestamp == 0){
            lastCycleTimestamp = block.timestamp;
        }

        emit PoolsSet(pools);
    }


    /*
     * Params
     * uint256 poolId - ID index of pool
     * uint256 _duration - Duration (in cycles)
     *
     * Function changes pool duration for specific pools
     */
    function changePoolDuration (
        uint256 poolId,
        uint256 _duration
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(pools.length > poolId, "Invalid pool ID");

        pools[poolId].duration = _duration;
        emit PoolsDurationChange(poolId, _duration);
    }


    /*
     * Params
     * uint256 _cycleDuration - Cycle duration in seconds
     *
     * Sets cycle duration
     */
    function setCycleDuration (
        uint256 _cycleDuration
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(cycleDuration != _cycleDuration, "Already set");
        require(_cycleDuration > 0);
        cycleDuration = _cycleDuration;
    }


    /*
     * Params
     * uint256 _snapshotRewardPerSecond - Reward per second for making snapshot
     *
     * Sets reward per second for making snapshot
     *** Example: If _snapshotRewardPerSecond == $0.001
     *** and user calls snapshotPools() in 3600 seconds (1 hour) after the end of last cycle
     *** he will receive $3.6 (3600 * 0.001), but no more than contract income for the last cycle
     */
    function setSnapshotRewardPerSecond (
        uint256 _snapshotRewardPerSecond
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(_snapshotRewardPerSecond != snapshotRewardPerSecond, "Already set");
        snapshotRewardPerSecond = _snapshotRewardPerSecond;
    }


    /*
     * Returns array of pool information
     */
    function getPoolInfo() external view returns(PoolInfo[] memory){
        return pools;
    }


    /*
     * Params
     * address user - User address
     *
     * Returns data about users deposits
     */
    function getUserDeposits(address user) external view returns(Deposit[] memory){
        return deposits[user];
    }


    /*
     * Params
     * address user - User address
     * uint256 depositId - ID index of deposit
     *
     * Returns collected reward amount for specific user deposit
     */
    function getPendingReward(
        address user,
        uint256 depositId
    ) external view returns(
        uint256 rewardAmount
    ){
        Deposit memory userDeposit = deposits[user][depositId];
        PoolSnapshot[] memory snapshots = poolSnapshots[userDeposit.poolId];

        uint256 rewardAmount = 0;
        uint256 startCycle = userDeposit.cycleNumber - snapshots[1].cycleNumber + 1;
        uint256 endCycle = startCycle + pools[userDeposit.poolId].duration;
        for(uint i = startCycle; i < endCycle; i++) {
            if(snapshots[i].cycleNumber >= userDeposit.cycleNumber){
                rewardAmount += snapshots[i].PPS * userDeposit.shares;
            }
        }
        return rewardAmount;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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