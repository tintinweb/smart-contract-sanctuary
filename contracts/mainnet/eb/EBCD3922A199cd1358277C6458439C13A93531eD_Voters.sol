//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
This contract allows XRUNE holders and LPs to lock some of their tokens up for
vXRUNE, the Thorstarter DAO's voting token. It's an ERC20 but without the
transfer methods.
It supports snapshoting and delegation of voting power.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IVoters.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC677Receiver.sol";

contract Voters is IVoters, IERC677Receiver, AccessControl { 
    using SafeERC20 for IERC20;
    
    struct UserInfo {
        uint lastFeeGrowth;
        uint lockedToken;
        uint lockedSsLpValue;
        uint lockedSsLpAmount;
        uint lockedTcLpValue;
        uint lockedTcLpAmount;
        address delegate;
    }
    struct Snapshots {
        uint[] ids;
        uint[] values;
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Snapshot(uint id);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    string public constant name = "Thorstarter Voting Token";
    string public constant symbol = "vXRUNE";
    uint8 public constant decimals = 18;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER");
    bytes32 public constant SNAPSHOTTER_ROLE = keccak256("SNAPSHOTTER");
    IERC20 public token;
    IERC20 public sushiLpToken;
    uint public lastFeeGrowth;
    uint public totalSupply;
    mapping(address => UserInfo) private _userInfos;
    uint public currentSnapshotId;
    Snapshots private _totalSupplySnapshots;
    mapping(address => Snapshots) private _balancesSnapshots;
    mapping(address => uint) private _votes;
    mapping(address => Snapshots) private _votesSnapshots;
    mapping(address => bool) public historicalTcLps;
    address[] private _historicalTcLpsList;
    mapping(address => uint) public lastLockBlock;

    constructor(address _owner, address _token, address _sushiLpToken) {
        _setRoleAdmin(KEEPER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(SNAPSHOTTER_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _owner);
        _setupRole(KEEPER_ROLE, _owner);
        _setupRole(SNAPSHOTTER_ROLE, _owner);
        token = IERC20(_token);
        sushiLpToken = IERC20(_sushiLpToken);
        currentSnapshotId = 1;
    }

    function userInfo(address user) external view returns (uint, uint, uint, uint, uint, uint, address) {
      UserInfo storage userInfo = _userInfos[user];
      return (
        userInfo.lastFeeGrowth,
        userInfo.lockedToken,
        userInfo.lockedSsLpValue,
        userInfo.lockedSsLpAmount,
        userInfo.lockedTcLpValue,
        userInfo.lockedTcLpAmount,
        userInfo.delegate
      );
    }

    function balanceOf(address user) override public view returns (uint) {
        UserInfo storage userInfo = _userInfos[user];
        return _userInfoTotal(userInfo);
    }

    function balanceOfAt(address user, uint snapshotId) override external view returns (uint) {
        (bool snapshotted, uint value) = _valueAt(_balancesSnapshots[user], snapshotId);
        return snapshotted ? value : balanceOf(user);
    }

    function votes(address user) public view returns (uint) {
        return _votes[user];
    }

    function votesAt(address user, uint snapshotId) override external view returns (uint) {
        (bool snapshotted, uint value) = _valueAt(_votesSnapshots[user], snapshotId);
        return snapshotted ? value : votes(user);
    }

    function totalSupplyAt(uint snapshotId) override external view returns (uint) {
        (bool snapshotted, uint value) = _valueAt(_totalSupplySnapshots, snapshotId);
        return snapshotted ? value : totalSupply;
    }

    function approve(address spender, uint amount) external returns (bool) {
        revert("not implemented");
    }

    function transfer(address to, uint amount) external returns (bool) {
        revert("not implemented");
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        revert("not implemented");
    }

    function snapshot() override external onlyRole(SNAPSHOTTER_ROLE) returns (uint) {
        currentSnapshotId += 1;
        emit Snapshot(currentSnapshotId);
        return currentSnapshotId;
    }

    function _valueAt(Snapshots storage snapshots, uint snapshotId) private view returns (bool, uint) {
        if (snapshots.ids.length == 0) {
            return (false, 0);
        }
        uint lower = 0;
        uint upper = snapshots.ids.length;
        while (lower < upper) {
            uint mid = (lower & upper) + (lower ^ upper) / 2;
            if (snapshots.ids[mid] > snapshotId) {
                upper = mid;
            } else {
                lower = mid + 1;
            }
        }

        uint index = lower;
        if (lower > 0 && snapshots.ids[lower - 1] == snapshotId) {
          index = lower -1;
        }

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateSnapshot(Snapshots storage snapshots, uint value) private {
        uint currentId = currentSnapshotId;
        uint lastSnapshotId = 0;
        if (snapshots.ids.length > 0) {
            lastSnapshotId = snapshots.ids[snapshots.ids.length - 1];
        }
        if (lastSnapshotId < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(value);
        }
    }

    function delegate(address delegatee) external {
        require(delegatee != address(0), "zero address provided");
        UserInfo storage userInfo = _userInfos[msg.sender];
        address currentDelegate = userInfo.delegate;
        userInfo.delegate = delegatee;

        _updateSnapshot(_votesSnapshots[currentDelegate], votes(currentDelegate));
        _updateSnapshot(_votesSnapshots[delegatee], votes(delegatee));
        uint amount = balanceOf(msg.sender);
        _votes[currentDelegate] -= amount;
        _votes[delegatee] += amount;

        emit DelegateChanged(msg.sender, currentDelegate, delegatee);
    }

    function _lock(address user, uint amount) private {
        require(amount > 0, "!zero");
        UserInfo storage userInfo = _userInfo(user);

        // track last time a user called the lock method to prevent flash loan attacks
        lastLockBlock[user] = block.number;

        _updateSnapshot(_totalSupplySnapshots, totalSupply);
        _updateSnapshot(_balancesSnapshots[user], balanceOf(user));
        _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

        totalSupply += amount;
        userInfo.lockedToken += amount;
        _votes[userInfo.delegate] += amount;
        emit Transfer(address(0), user, amount);
    }

    function lock(uint amount) external {
        _transferFrom(token, msg.sender, amount);
        _lock(msg.sender, amount);
    }

    function onTokenTransfer(address user, uint amount, bytes calldata _data) external override {
        require(msg.sender == address(token), "onTokenTransfer: not xrune");
        _lock(user, amount);
    }

    function unlock(uint amount) external {
        require(block.number > lastLockBlock[msg.sender], "no lock-unlock in same tx");

        UserInfo storage userInfo = _userInfo(msg.sender);
        require(amount <= userInfo.lockedToken, "locked balance too low");

        _updateSnapshot(_totalSupplySnapshots, totalSupply);
        _updateSnapshot(_balancesSnapshots[msg.sender], balanceOf(msg.sender));
        _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

        totalSupply -= amount;
        userInfo.lockedToken -= amount;
        _votes[userInfo.delegate] -= amount;
        emit Transfer(msg.sender, address(0), amount);

        if (amount > 0) {
            token.safeTransfer(msg.sender, amount);
        }
    }

    function lockSslp(uint lpAmount) external {
        UserInfo storage userInfo = _userInfo(msg.sender);
        require(lpAmount > 0, "!zero");
        _transferFrom(sushiLpToken, msg.sender, lpAmount);

        _updateSnapshot(_totalSupplySnapshots, totalSupply);
        _updateSnapshot(_balancesSnapshots[msg.sender], balanceOf(msg.sender));
        _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

        // Subtract current LP value
        uint previousValue = userInfo.lockedSsLpValue;
        totalSupply -= userInfo.lockedSsLpValue;
        _votes[userInfo.delegate] -= userInfo.lockedSsLpValue;

        // Increment LP amount
        userInfo.lockedSsLpAmount += lpAmount;

        // Calculated updated *full* LP amount value and set (not increment)
        // We do it like this and not based on just amount added so that unlock
        // knows that the lockedSsLpValue is based on one rate and not multiple adds
        uint lpTokenSupply = sushiLpToken.totalSupply();
        uint lpTokenReserve = token.balanceOf(address(sushiLpToken));
        require(lpTokenSupply > 0, "lp token supply can not be zero");
        uint amount = (2 * userInfo.lockedSsLpAmount * lpTokenReserve) / lpTokenSupply;
        totalSupply += amount; // Increment as we decremented
        _votes[userInfo.delegate] += amount; // Increment as we decremented
        userInfo.lockedSsLpValue = amount; // Set a we didn't ajust and amount is full value
        if (previousValue < userInfo.lockedSsLpValue) {
            emit Transfer(address(0), msg.sender, userInfo.lockedSsLpValue - previousValue);
        } else if (previousValue > userInfo.lockedSsLpValue) {
            emit Transfer(msg.sender, address(0), previousValue - userInfo.lockedSsLpValue);
        }
    }

    function unlockSslp(uint lpAmount) external {
        UserInfo storage userInfo = _userInfo(msg.sender);
        require(lpAmount > 0, "amount can't be 0");
        require(lpAmount <= userInfo.lockedSsLpAmount, "locked balance too low");

        _updateSnapshot(_totalSupplySnapshots, totalSupply);
        _updateSnapshot(_balancesSnapshots[msg.sender], balanceOf(msg.sender));
        _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

        // Proportionally decrement lockedSsLpValue & supply & delegated votes
        uint amount = lpAmount * userInfo.lockedSsLpValue / userInfo.lockedSsLpAmount;
        totalSupply -= amount;
        userInfo.lockedSsLpValue -= amount;
        userInfo.lockedSsLpAmount -= lpAmount;
        _votes[userInfo.delegate] -= amount;
        emit Transfer(msg.sender, address(0), amount);

        sushiLpToken.safeTransfer(msg.sender, lpAmount);
    }

    function updateTclp(address[] calldata users, uint[] calldata amounts, uint[] calldata values) external onlyRole(KEEPER_ROLE) {
        require(users.length == amounts.length && users.length == values.length, "length");
        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            UserInfo storage userInfo = _userInfo(user);
            _updateSnapshot(_totalSupplySnapshots, totalSupply);
            _updateSnapshot(_balancesSnapshots[user], balanceOf(user));
            _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

            uint previousValue = userInfo.lockedTcLpValue;
            totalSupply = totalSupply - previousValue + values[i];
            _votes[userInfo.delegate] = _votes[userInfo.delegate] - previousValue + values[i];
            userInfo.lockedTcLpValue = values[i];
            userInfo.lockedTcLpAmount = amounts[i];
            if (previousValue < values[i]) {
                emit Transfer(address(0), user, values[i] - previousValue);
            } else if (previousValue > values[i]) {
                emit Transfer(user, address(0), previousValue - values[i]);
            }

            // Add to historicalTcLpsList for keepers to use
            if (!historicalTcLps[user]) {
              historicalTcLps[user] = true;
              _historicalTcLpsList.push(user);
            }
        }
    }

    function historicalTcLpsList(uint page, uint pageSize) external view returns (address[] memory) {
      address[] memory list = new address[](pageSize);
      for (uint i = page * pageSize; i < (page + 1) * pageSize && i < _historicalTcLpsList.length; i++) {
        list[i-(page*pageSize)] = _historicalTcLpsList[i];
      }
      return list;
    }

    function donate(uint amount) override external {
        _transferFrom(token, msg.sender, amount);
        lastFeeGrowth += (amount * 1e12) / totalSupply;
    }

    function _userInfo(address user) private returns (UserInfo storage) {
        require(user != address(0), "zero address provided");
        UserInfo storage userInfo = _userInfos[user];
        if (userInfo.delegate == address(0)) {
            userInfo.delegate = user;
        }
        if (userInfo.lastFeeGrowth == 0 && lastFeeGrowth != 0) {
            userInfo.lastFeeGrowth = lastFeeGrowth;
        } else {
            uint fees = (_userInfoTotal(userInfo) * (lastFeeGrowth - userInfo.lastFeeGrowth)) / 1e12;
            if (fees > 0) {
                _updateSnapshot(_totalSupplySnapshots, totalSupply);
                _updateSnapshot(_balancesSnapshots[user], balanceOf(user));
                _updateSnapshot(_votesSnapshots[userInfo.delegate], votes(userInfo.delegate));

                totalSupply += fees;
                userInfo.lockedToken += fees;
                userInfo.lastFeeGrowth = lastFeeGrowth;
                _votes[userInfo.delegate] += fees;
                emit Transfer(address(0), user, fees);
            }
        }
        return userInfo;
    }

    function _userInfoTotal(UserInfo storage userInfo) private view returns (uint) {
        return userInfo.lockedToken + userInfo.lockedSsLpValue + userInfo.lockedTcLpValue;
    }

    function _transferFrom(IERC20 token, address from, uint amount) private {
        uint balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        uint balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore == amount, "_transferFrom: balance change does not match amount");
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
pragma solidity 0.8.6;

interface IVoters {
  function snapshot() external returns (uint);
  function totalSupplyAt(uint snapshotId) external view returns (uint);
  function votesAt(address account, uint snapshotId) external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function balanceOfAt(address account, uint snapshotId) external view returns (uint);
  function donate(uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677Receiver {
  function onTokenTransfer(address _sender, uint _value, bytes calldata _data) external;
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

{
  "optimizer": {
    "enabled": true,
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