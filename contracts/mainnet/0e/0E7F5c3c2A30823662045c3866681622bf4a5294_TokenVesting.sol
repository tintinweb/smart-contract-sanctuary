// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../openzeppelin/access/AccessControl.sol";
import "../openzeppelin/utils/math/SafeMath.sol";
import "../openzeppelin/token/ERC20/SafeERC20.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../sablierhq/Sablier.sol";
import "./ITokenVesting.sol";

/**
 * @title TokenVesting contract for linearly vesting tokens to the respective vesting beneficiary
 * @dev This contract receives accepted proposals from the Manager contract, and pass it to sablier contract
 * @dev all the tokens to be vested by the vesting beneficiary. It releases these tokens when called
 * @dev upon in a continuous-like linear fashion.
 * @notice This contract use https://github.com/sablierhq/sablier-smooth-contracts/blob/master/contracts/Sablier.sol
 */
contract TokenVesting is ITokenVesting, AccessControl {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	address sablier;
	uint256 constant CREATOR_IX = 0;
	uint256 constant ROLL_IX = 1;
	uint256 constant REFERRAL_IX = 2;

	uint256 public constant DAYS_IN_SECONDS = 24 * 60 * 60;
	mapping(address => VestingInfo) public vestingInfo;
	mapping(address => mapping(uint256 => Beneficiary)) public beneficiaries;
	mapping(address => address[]) public beneficiaryTokens;

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(
			hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
			"Ownable: caller is not the owner"
		);
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		grantRole(DEFAULT_ADMIN_ROLE, newOwner);
		revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	constructor(address newOwner) {
		_setupRole(DEFAULT_ADMIN_ROLE, newOwner);
	}

	function setSablier(address _sablier) external onlyOwner {
		sablier = _sablier;
	}

	/**
	 * @dev Method to add a token into TokenVesting
	 * @param _token address Address of token
	 * @param _beneficiaries address[3] memory Address of vesting beneficiary
	 * @param _proportions uint256[3] memory Proportions of vesting beneficiary
	 * @param _vestingPeriodInDays uint256 Period of vesting, in units of Days, to be converted
	 * @notice This emits an Event LogTokenAdded which is indexed by the token address
	 */
	function addToken(
		address _token,
		address[3] calldata _beneficiaries,
		uint256[3] calldata _proportions,
		uint256 _vestingPeriodInDays
	) external override onlyOwner {
		uint256 duration = uint256(_vestingPeriodInDays).mul(DAYS_IN_SECONDS);
		require(duration > 0, "VESTING: period can't be zero");
		uint256 stopTime = block.timestamp.add(duration);
		uint256 initial = IERC20(_token).balanceOf(address(this));

		vestingInfo[_token] = VestingInfo({
			vestingBeneficiary: _beneficiaries[0],
			totalBalance: initial,
			beneficiariesCount: 3, // this is to create a struct compatible with any number but for now is always 3
			start: block.timestamp,
			stop: stopTime
		});

		IERC20(_token).approve(sablier, 2**256 - 1);
		IERC20(_token).approve(address(this), 2**256 - 1);

		for (uint256 i = 0; i < vestingInfo[_token].beneficiariesCount; i++) {
			if (_beneficiaries[i] == address(0)) {
				continue;
			}
			beneficiaries[_token][i].beneficiary = _beneficiaries[i];
			beneficiaries[_token][i].proportion = _proportions[i];

			uint256 deposit = _proportions[i];
			if (deposit == 0) {
				continue;
			}

			// we store the remaing to guarantee deposit be multiple of period. We send that remining at the end of period.
			uint256 remaining = deposit % duration;

			uint256 streamId =
				Sablier(sablier).createStream(
					_beneficiaries[i],
					deposit.sub(remaining),
					_token,
					block.timestamp,
					stopTime
				);

			beneficiaries[_token][i].streamId = streamId;
			beneficiaries[_token][i].remaining = remaining;
			beneficiaryTokens[_beneficiaries[i]].push(_token);
		}

		emit LogTokenAdded(_token, _beneficiaries[0], _vestingPeriodInDays);
	}

	function getBeneficiaryId(address _token, address _beneficiary)
		internal
		view
		returns (uint256)
	{
		for (uint256 i = 0; i < vestingInfo[_token].beneficiariesCount; i++) {
			if (beneficiaries[_token][i].beneficiary == _beneficiary) {
				return i;
			}
		}

		revert("VESTING: invalid vesting address");
	}

	function release(address _token, address _beneficiary) external override {
		uint256 ix = getBeneficiaryId(_token, _beneficiary);
		uint256 streamId = beneficiaries[_token][ix].streamId;
		if (!Sablier(sablier).isEntity(streamId)) {
			return;
		}
		uint256 balance = Sablier(sablier).balanceOf(streamId, _beneficiary);
		bool withdrawResult =
			Sablier(sablier).withdrawFromStream(streamId, balance);
		require(withdrawResult, "VESTING: Error calling withdrawFromStream");

		// if vesting duration already finish then release the final dust
		if (
			vestingInfo[_token].stop < block.timestamp &&
			beneficiaries[_token][ix].remaining > 0
		) {
			IERC20(_token).safeTransferFrom(
				address(this),
				_beneficiary,
				beneficiaries[_token][ix].remaining
			);
		}
	}

	function releaseableAmount(address _token)
		public
		view
		override
		returns (uint256)
	{
		uint256 total = 0;

		for (uint256 i = 0; i < vestingInfo[_token].beneficiariesCount; i++) {
			if (Sablier(sablier).isEntity(beneficiaries[_token][i].streamId)) {
				total =
					total +
					Sablier(sablier).balanceOf(
						beneficiaries[_token][i].streamId,
						beneficiaries[_token][i].beneficiary
					);
			}
		}

		return total;
	}

	function releaseableAmountByAddress(address _token, address _beneficiary)
		public
		view
		override
		returns (uint256)
	{
		uint256 ix = getBeneficiaryId(_token, _beneficiary);
		uint256 streamId = beneficiaries[_token][ix].streamId;
		return Sablier(sablier).balanceOf(streamId, _beneficiary);
	}

	function vestedAmount(address _token)
		public
		view
		override
		returns (uint256)
	{
		VestingInfo memory info = vestingInfo[_token];
		if (block.timestamp >= info.stop) {
			return info.totalBalance;
		} else {
			uint256 duration = info.stop.sub(info.start);
			return
				info.totalBalance.mul(block.timestamp.sub(info.start)).div(
					duration
				);
		}
	}

	function getVestingInfo(address _token)
		external
		view
		override
		returns (VestingInfo memory)
	{
		return vestingInfo[_token];
	}

	function updateVestingAddress(
		address _token,
		uint256 ix,
		address _vestingBeneficiary
	) internal {
		if (
			vestingInfo[_token].vestingBeneficiary ==
			beneficiaries[_token][ix].beneficiary
		) {
			vestingInfo[_token].vestingBeneficiary = _vestingBeneficiary;
		}

		beneficiaries[_token][ix].beneficiary = _vestingBeneficiary;

		uint256 deposit = 0;
		uint256 remaining = 0;
		{
			uint256 streamId = beneficiaries[_token][ix].streamId;
			// if there's no pending this will revert and it's ok because has no sense to update the address
			uint256 pending =
				Sablier(sablier).balanceOf(streamId, address(this));

			uint256 duration = vestingInfo[_token].stop.sub(block.timestamp);
			deposit = pending.add(beneficiaries[_token][ix].remaining);
			remaining = deposit % duration;

			bool cancelResult =
				Sablier(sablier).cancelStream(
					beneficiaries[_token][ix].streamId
				);
			require(cancelResult, "VESTING: Error calling cancelStream");
		}

		uint256 streamId =
			Sablier(sablier).createStream(
				_vestingBeneficiary,
				deposit.sub(remaining),
				_token,
				block.timestamp,
				vestingInfo[_token].stop
			);
		beneficiaries[_token][ix].streamId = streamId;
		beneficiaries[_token][ix].remaining = remaining;

		emit LogBeneficiaryUpdated(_token, _vestingBeneficiary);
	}

	function setVestingAddress(
		address _vestingBeneficiary,
		address _token,
		address _newVestingBeneficiary
	) external override onlyOwner {
		uint256 ix = getBeneficiaryId(_token, _vestingBeneficiary);
		updateVestingAddress(_token, ix, _newVestingBeneficiary);
	}

	function setVestingReferral(
		address _vestingBeneficiary,
		address _token,
		address _vestingReferral
	) external override onlyOwner {
		require(
			_vestingBeneficiary == vestingInfo[_token].vestingBeneficiary,
			"VESTING: Only creator"
		);
		updateVestingAddress(_token, REFERRAL_IX, _vestingReferral);
	}

	function getAllTokensByBeneficiary(address _beneficiary)
		public
		view
		override
		returns (address[] memory)
	{
		return beneficiaryTokens[_beneficiary];
	}

	function releaseAll(address _beneficiary) public override {
		address[] memory array = beneficiaryTokens[_beneficiary];
		for (uint256 i = 0; i < array.length; i++) {
			this.release(array[i], _beneficiary);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		uint256 c = a + b;
		if (c < a) return (false, 0);
		return (true, c);
	}

	/**
	 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function trySub(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b > a) return (false, 0);
		return (true, a - b);
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMul(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) return (true, 0);
		uint256 c = a * b;
		if (c / a != b) return (false, 0);
		return (true, c);
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryDiv(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b == 0) return (false, 0);
		return (true, a / b);
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMod(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		if (b == 0) return (false, 0);
		return (true, a % b);
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
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
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
		require(b <= a, "SafeMath: subtraction overflow");
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
		if (a == 0) return 0;
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0, "SafeMath: division by zero");
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
		require(b > 0, "SafeMath: modulo by zero");
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
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		return a - b;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryDiv}.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		return a / b;
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
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		return a % b;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../utils/math/SafeMath.sol";
import "../../utils/Address.sol";

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
	using SafeMath for uint256;
	using Address for address;

	function safeTransfer(
		IERC20 token,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.transfer.selector, to, value)
		);
	}

	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
		);
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
		// solhint-disable-next-line max-line-length
		require(
			(value == 0) || (token.allowance(address(this), spender) == 0),
			"SafeERC20: approve from non-zero to non-zero allowance"
		);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.approve.selector, spender, value)
		);
	}

	function safeIncreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance =
			token.allowance(address(this), spender).add(value);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(
				token.approve.selector,
				spender,
				newAllowance
			)
		);
	}

	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance =
			token.allowance(address(this), spender).sub(
				value,
				"SafeERC20: decreased allowance below zero"
			);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(
				token.approve.selector,
				spender,
				newAllowance
			)
		);
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

		bytes memory returndata =
			address(token).functionCall(
				data,
				"SafeERC20: low-level call failed"
			);
		if (returndata.length > 0) {
			// Return data is optional
			// solhint-disable-next-line max-line-length
			require(
				abi.decode(returndata, (bool)),
				"SafeERC20: ERC20 operation did not succeed"
			);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

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
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

pragma solidity =0.7.6;

import "../openzeppelin/utils/Pausable.sol";
import "../openzeppelin/access/Ownable.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../openzeppelin/utils/ReentrancyGuard.sol";

import "./compound/Exponential.sol";
import "./interfaces/IERC1620.sol";
import "./Types.sol";

/**
 * @title Sablier's Money Streaming
 * @author Sablier
 */
contract Sablier is IERC1620, Exponential, ReentrancyGuard {
	/*** Storage Properties ***/

	/**
	 * @dev The amount of interest has been accrued per token address.
	 */
	mapping(address => uint256) private earnings;

	/**
	 * @notice The percentage fee charged by the contract on the accrued interest.
	 */
	Exp public fee;

	/**
	 * @notice Counter for new stream ids.
	 */
	uint256 public nextStreamId;

	/**
	 * @dev The stream objects identifiable by their unsigned integer ids.
	 */
	mapping(uint256 => Types.Stream) private streams;

	/*** Modifiers ***/

	/**
	 * @dev Throws if the caller is not the sender of the recipient of the stream.
	 */
	modifier onlySenderOrRecipient(uint256 streamId) {
		require(
			msg.sender == streams[streamId].sender ||
				msg.sender == streams[streamId].recipient,
			"caller is not the sender or the recipient of the stream"
		);
		_;
	}

	/**
	 * @dev Throws if the provided id does not point to a valid stream.
	 */
	modifier streamExists(uint256 streamId) {
		require(streams[streamId].isEntity, "stream does not exist");
		_;
	}

	/*** Contract Logic Starts Here */

	constructor() public {
		nextStreamId = 1;
	}

	/*** View Functions ***/
	function isEntity(uint256 streamId) external view returns (bool) {
		return streams[streamId].isEntity;
	}

	/**
	 * @dev Returns the compounding stream with all its properties.
	 * @dev Throws if the id does not point to a valid stream.
	 * @param streamId The id of the stream to query.
	 * @dev The stream object.
	 */
	function getStream(uint256 streamId)
		external
		view
		override
		streamExists(streamId)
		returns (
			address sender,
			address recipient,
			uint256 deposit,
			address tokenAddress,
			uint256 startTime,
			uint256 stopTime,
			uint256 remainingBalance,
			uint256 ratePerSecond
		)
	{
		sender = streams[streamId].sender;
		recipient = streams[streamId].recipient;
		deposit = streams[streamId].deposit;
		tokenAddress = streams[streamId].tokenAddress;
		startTime = streams[streamId].startTime;
		stopTime = streams[streamId].stopTime;
		remainingBalance = streams[streamId].remainingBalance;
		ratePerSecond = streams[streamId].ratePerSecond;
	}

	/**
	 * @dev Returns either the delta in seconds between `block.timestamp` and `startTime` or
	 *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
	 *  `startTime`, it returns 0.
	 * @dev Throws if the id does not point to a valid stream.
	 * @param streamId The id of the stream for which to query the delta.
	 * @dev The time delta in seconds.
	 */
	function deltaOf(uint256 streamId)
		public
		view
		streamExists(streamId)
		returns (uint256 delta)
	{
		Types.Stream memory stream = streams[streamId];
		if (block.timestamp <= stream.startTime) return 0;
		if (block.timestamp < stream.stopTime)
			return block.timestamp - stream.startTime;
		return stream.stopTime - stream.startTime;
	}

	struct BalanceOfLocalVars {
		MathError mathErr;
		uint256 recipientBalance;
		uint256 withdrawalAmount;
		uint256 senderBalance;
	}

	/**
	 * @dev Returns the available funds for the given stream id and address.
	 * @dev Throws if the id does not point to a valid stream.
	 * @param streamId The id of the stream for which to query the balance.
	 * @param who The address for which to query the balance.
	 * @dev @balance uint256 The total funds allocated to `who` as uint256.
	 */
	function balanceOf(uint256 streamId, address who)
		public
		view
		override
		streamExists(streamId)
		returns (uint256 balance)
	{
		Types.Stream memory stream = streams[streamId];
		BalanceOfLocalVars memory vars;

		uint256 delta = deltaOf(streamId);
		(vars.mathErr, vars.recipientBalance) = mulUInt(
			delta,
			stream.ratePerSecond
		);
		require(
			vars.mathErr == MathError.NO_ERROR,
			"recipient balance calculation error"
		);

		/*
		 * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
		 * We have to subtract the total amount withdrawn from the amount of money that has been
		 * streamed until now.
		 */
		if (stream.deposit > stream.remainingBalance) {
			(vars.mathErr, vars.withdrawalAmount) = subUInt(
				stream.deposit,
				stream.remainingBalance
			);
			assert(vars.mathErr == MathError.NO_ERROR);
			(vars.mathErr, vars.recipientBalance) = subUInt(
				vars.recipientBalance,
				vars.withdrawalAmount
			);
			/* `withdrawalAmount` cannot and should not be bigger than `recipientBalance`. */
			assert(vars.mathErr == MathError.NO_ERROR);
		}

		if (who == stream.recipient) return vars.recipientBalance;
		if (who == stream.sender) {
			(vars.mathErr, vars.senderBalance) = subUInt(
				stream.remainingBalance,
				vars.recipientBalance
			);
			/* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
			assert(vars.mathErr == MathError.NO_ERROR);
			return vars.senderBalance;
		}
		return 0;
	}

	/*** Public Effects & Interactions Functions ***/

	struct CreateStreamLocalVars {
		MathError mathErr;
		uint256 duration;
		uint256 ratePerSecond;
	}

	/**
	 * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.
	 * @dev Throws if paused.
	 *  Throws if the recipient is the zero address, the contract itself or the caller.
	 *  Throws if the deposit is 0.
	 *  Throws if the start time is before `block.timestamp`.
	 *  Throws if the stop time is before the start time.
	 *  Throws if the duration calculation has a math error.
	 *  Throws if the deposit is smaller than the duration.
	 *  Throws if the deposit is not a multiple of the duration.
	 *  Throws if the rate calculation has a math error.
	 *  Throws if the next stream id calculation has a math error.
	 *  Throws if the contract is not allowed to transfer enough tokens.
	 *  Throws if there is a token transfer failure.
	 * @param recipient The address towards which the money is streamed.
	 * @param deposit The amount of money to be streamed.
	 * @param tokenAddress The ERC20 token to use as streaming currency.
	 * @param startTime The unix timestamp for when the stream starts.
	 * @param stopTime The unix timestamp for when the stream stops.
	 * @return The uint256 id of the newly created stream.
	 */
	function createStream(
		address recipient,
		uint256 deposit,
		address tokenAddress,
		uint256 startTime,
		uint256 stopTime
	) public override returns (uint256) {
		require(recipient != address(0x00), "stream to the zero address");
		require(recipient != address(this), "stream to the contract itself");
		require(recipient != msg.sender, "stream to the caller");
		require(deposit > 0, "deposit is zero");
		require(
			startTime >= block.timestamp,
			"start time before block.timestamp"
		);
		require(stopTime > startTime, "stop time before the start time");

		CreateStreamLocalVars memory vars;
		(vars.mathErr, vars.duration) = subUInt(stopTime, startTime);
		/* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */
		assert(vars.mathErr == MathError.NO_ERROR);

		/* Without this, the rate per second would be zero. */
		require(deposit >= vars.duration, "deposit smaller than time delta");

		require(
			deposit % vars.duration == 0,
			"deposit not multiple of time delta"
		);

		(vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);
		/* `divUInt` can only return MathError.DIVISION_BY_ZERO but we know `duration` is not zero. */
		assert(vars.mathErr == MathError.NO_ERROR);

		/* Create and store the stream object. */
		uint256 streamId = nextStreamId;
		streams[streamId] = Types.Stream({
			remainingBalance: deposit,
			deposit: deposit,
			isEntity: true,
			ratePerSecond: vars.ratePerSecond,
			recipient: recipient,
			sender: msg.sender,
			startTime: startTime,
			stopTime: stopTime,
			tokenAddress: tokenAddress
		});

		/* Increment the next stream id. */
		(vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
		require(
			vars.mathErr == MathError.NO_ERROR,
			"next stream id calculation error"
		);

		require(
			IERC20(tokenAddress).transferFrom(
				msg.sender,
				address(this),
				deposit
			),
			"token transfer failure"
		);
		emit CreateStream(
			streamId,
			msg.sender,
			recipient,
			deposit,
			tokenAddress,
			startTime,
			stopTime
		);
		return streamId;
	}

	struct WithdrawFromStreamLocalVars {
		MathError mathErr;
	}

	/**
	 * @notice Withdraws from the contract to the recipient's account.
	 * @dev Throws if the id does not point to a valid stream.
	 *  Throws if the caller is not the sender or the recipient of the stream.
	 *  Throws if the amount exceeds the available balance.
	 *  Throws if there is a token transfer failure.
	 * @param streamId The id of the stream to withdraw tokens from.
	 * @param amount The amount of tokens to withdraw.
	 * @return bool true=success, otherwise false.
	 */
	function withdrawFromStream(uint256 streamId, uint256 amount)
		external
		override
		nonReentrant
		streamExists(streamId)
		onlySenderOrRecipient(streamId)
		returns (bool)
	{
		require(amount > 0, "amount is zero");
		Types.Stream memory stream = streams[streamId];
		WithdrawFromStreamLocalVars memory vars;

		uint256 balance = balanceOf(streamId, stream.recipient);
		require(balance >= amount, "amount exceeds the available balance");

		(vars.mathErr, streams[streamId].remainingBalance) = subUInt(
			stream.remainingBalance,
			amount
		);
		/**
		 * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
		 * as big as `amount`.
		 */
		assert(vars.mathErr == MathError.NO_ERROR);

		if (streams[streamId].remainingBalance == 0) delete streams[streamId];

		require(
			IERC20(stream.tokenAddress).transfer(stream.recipient, amount),
			"token transfer failure"
		);
		emit WithdrawFromStream(streamId, stream.recipient, amount);
		return true;
	}

	/**
	 * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
	 * @dev Throws if the id does not point to a valid stream.
	 *  Throws if the caller is not the sender or the recipient of the stream.
	 *  Throws if there is a token transfer failure.
	 * @param streamId The id of the stream to cancel.
	 * @return bool true=success, otherwise false.
	 */
	function cancelStream(uint256 streamId)
		external
		override
		nonReentrant
		streamExists(streamId)
		onlySenderOrRecipient(streamId)
		returns (bool)
	{
		Types.Stream memory stream = streams[streamId];
		uint256 senderBalance = balanceOf(streamId, stream.sender);
		uint256 recipientBalance = balanceOf(streamId, stream.recipient);

		delete streams[streamId];

		IERC20 token = IERC20(stream.tokenAddress);
		if (recipientBalance > 0)
			require(
				token.transfer(stream.recipient, recipientBalance),
				"recipient token transfer failure"
			);
		if (senderBalance > 0)
			require(
				token.transfer(stream.sender, senderBalance),
				"sender token transfer failure"
			);

		emit CancelStream(
			streamId,
			stream.sender,
			stream.recipient,
			senderBalance,
			recipientBalance
		);
		return true;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

interface ITokenVesting {
	event Released(
		address indexed token,
		address vestingBeneficiary,
		uint256 amount
	);
	event LogTokenAdded(
		address indexed token,
		address vestingBeneficiary,
		uint256 vestingPeriodInDays
	);

	event LogBeneficiaryUpdated(
		address indexed token,
		address vestingBeneficiary
	);

	struct VestingInfo {
		address vestingBeneficiary;
		uint256 totalBalance;
		uint256 beneficiariesCount;
		uint256 start;
		uint256 stop;
	}

	struct Beneficiary {
		address beneficiary;
		uint256 proportion;
		uint256 streamId;
		uint256 remaining;
	}

	function addToken(
		address _token,
		address[3] calldata _beneficiaries,
		uint256[3] calldata _proportions,
		uint256 _vestingPeriodInDays
	) external;

	function release(address _token, address _beneficiary) external;

	function releaseableAmount(address _token) external view returns (uint256);

	function releaseableAmountByAddress(address _token, address _beneficiary)
		external
		view
		returns (uint256);

	function vestedAmount(address _token) external view returns (uint256);

	function getVestingInfo(address _token)
		external
		view
		returns (VestingInfo memory);

	function setVestingAddress(
		address _vestingBeneficiary,
		address _token,
		address _newVestingBeneficiary
	) external;

	function setVestingReferral(
		address _vestingBeneficiary,
		address _token,
		address _vestingReferral
	) external;

	function getAllTokensByBeneficiary(address _beneficiary)
		external
		view
		returns (address[] memory);

	function releaseAll(address _beneficiary) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";

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

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
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
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity =0.7.6;

import "./CarefulMath.sol";

/**
 * @title Exponential module for storing fixed-decision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
	uint256 constant expScale = 1e18;
	uint256 constant halfExpScale = expScale / 2;
	uint256 constant mantissaOne = expScale;

	struct Exp {
		uint256 mantissa;
	}

	/**
	 * @dev Creates an exponential from numerator and denominator values.
	 *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
	 *            or if `denom` is zero.
	 */
	function getExp(uint256 num, uint256 denom)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}

		(MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
		if (err1 != MathError.NO_ERROR) {
			return (err1, Exp({ mantissa: 0 }));
		}

		return (MathError.NO_ERROR, Exp({ mantissa: rational }));
	}

	/**
	 * @dev Adds two exponentials, returning a new exponential.
	 */
	function addExp(Exp memory a, Exp memory b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

		return (error, Exp({ mantissa: result }));
	}

	/**
	 * @dev Subtracts two exponentials, returning a new exponential.
	 */
	function subExp(Exp memory a, Exp memory b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

		return (error, Exp({ mantissa: result }));
	}

	/**
	 * @dev Multiply an Exp by a scalar, returning a new Exp.
	 */
	function mulScalar(Exp memory a, uint256 scalar)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError err0, uint256 scaledMantissa) = mulUInt(a.mantissa, scalar);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}

		return (MathError.NO_ERROR, Exp({ mantissa: scaledMantissa }));
	}

	/**
	 * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
	 */
	function mulScalarTruncate(Exp memory a, uint256 scalar)
		internal
		pure
		returns (MathError, uint256)
	{
		(MathError err, Exp memory product) = mulScalar(a, scalar);
		if (err != MathError.NO_ERROR) {
			return (err, 0);
		}

		return (MathError.NO_ERROR, truncate(product));
	}

	/**
	 * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
	 */
	function mulScalarTruncateAddUInt(
		Exp memory a,
		uint256 scalar,
		uint256 addend
	) internal pure returns (MathError, uint256) {
		(MathError err, Exp memory product) = mulScalar(a, scalar);
		if (err != MathError.NO_ERROR) {
			return (err, 0);
		}

		return addUInt(truncate(product), addend);
	}

	/**
	 * @dev Divide an Exp by a scalar, returning a new Exp.
	 */
	function divScalar(Exp memory a, uint256 scalar)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError err0, uint256 descaledMantissa) =
			divUInt(a.mantissa, scalar);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}

		return (MathError.NO_ERROR, Exp({ mantissa: descaledMantissa }));
	}

	/**
	 * @dev Divide a scalar by an Exp, returning a new Exp.
	 */
	function divScalarByExp(uint256 scalar, Exp memory divisor)
		internal
		pure
		returns (MathError, Exp memory)
	{
		/*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
		(MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}
		return getExp(numerator, divisor.mantissa);
	}

	/**
	 * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
	 */
	function divScalarByExpTruncate(uint256 scalar, Exp memory divisor)
		internal
		pure
		returns (MathError, uint256)
	{
		(MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
		if (err != MathError.NO_ERROR) {
			return (err, 0);
		}

		return (MathError.NO_ERROR, truncate(fraction));
	}

	/**
	 * @dev Multiplies two exponentials, returning a new exponential.
	 */
	function mulExp(Exp memory a, Exp memory b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		(MathError err0, uint256 doubleScaledProduct) =
			mulUInt(a.mantissa, b.mantissa);
		if (err0 != MathError.NO_ERROR) {
			return (err0, Exp({ mantissa: 0 }));
		}

		// We add half the scale before dividing so that we get rounding instead of truncation.
		//  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
		// Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
		(MathError err1, uint256 doubleScaledProductWithHalfScale) =
			addUInt(halfExpScale, doubleScaledProduct);
		if (err1 != MathError.NO_ERROR) {
			return (err1, Exp({ mantissa: 0 }));
		}

		(MathError err2, uint256 product) =
			divUInt(doubleScaledProductWithHalfScale, expScale);
		// The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
		assert(err2 == MathError.NO_ERROR);

		return (MathError.NO_ERROR, Exp({ mantissa: product }));
	}

	/**
	 * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
	 */
	function mulExp(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		return mulExp(Exp({ mantissa: a }), Exp({ mantissa: b }));
	}

	/**
	 * @dev Multiplies three exponentials, returning a new exponential.
	 */
	function mulExp3(
		Exp memory a,
		Exp memory b,
		Exp memory c
	) internal pure returns (MathError, Exp memory) {
		(MathError err, Exp memory ab) = mulExp(a, b);
		if (err != MathError.NO_ERROR) {
			return (err, ab);
		}
		return mulExp(ab, c);
	}

	/**
	 * @dev Divides two exponentials, returning a new exponential.
	 *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
	 *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
	 */
	function divExp(Exp memory a, Exp memory b)
		internal
		pure
		returns (MathError, Exp memory)
	{
		return getExp(a.mantissa, b.mantissa);
	}

	/**
	 * @dev Truncates the given exp to a whole number value.
	 *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
	 */
	function truncate(Exp memory exp) internal pure returns (uint256) {
		// Note: We are not using careful math here as we're performing a division that cannot fail
		return exp.mantissa / expScale;
	}

	/**
	 * @dev Checks if first Exp is less than second Exp.
	 */
	function lessThanExp(Exp memory left, Exp memory right)
		internal
		pure
		returns (bool)
	{
		return left.mantissa < right.mantissa; //TODO: Add some simple tests and this in another PR yo.
	}

	/**
	 * @dev Checks if left Exp <= right Exp.
	 */
	function lessThanOrEqualExp(Exp memory left, Exp memory right)
		internal
		pure
		returns (bool)
	{
		return left.mantissa <= right.mantissa;
	}

	/**
	 * @dev Checks if left Exp > right Exp.
	 */
	function greaterThanExp(Exp memory left, Exp memory right)
		internal
		pure
		returns (bool)
	{
		return left.mantissa > right.mantissa;
	}

	/**
	 * @dev returns true if Exp is exactly zero
	 */
	function isZeroExp(Exp memory value) internal pure returns (bool) {
		return value.mantissa == 0;
	}
}

pragma solidity =0.7.6;

/**
 * @title ERC-1620 Money Streaming Standard
 * @author Sablier
 * @dev See https://eips.ethereum.org/EIPS/eip-1620
 */
interface IERC1620 {
	/**
	 * @notice Emits when a stream is successfully created.
	 */
	event CreateStream(
		uint256 indexed streamId,
		address indexed sender,
		address indexed recipient,
		uint256 deposit,
		address tokenAddress,
		uint256 startTime,
		uint256 stopTime
	);

	/**
	 * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
	 */
	event WithdrawFromStream(
		uint256 indexed streamId,
		address indexed recipient,
		uint256 amount
	);

	/**
	 * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
	 */
	event CancelStream(
		uint256 indexed streamId,
		address indexed sender,
		address indexed recipient,
		uint256 senderBalance,
		uint256 recipientBalance
	);

	function balanceOf(uint256 streamId, address who)
		external
		view
		returns (uint256 balance);

	function getStream(uint256 streamId)
		external
		view
		returns (
			address sender,
			address recipient,
			uint256 deposit,
			address token,
			uint256 startTime,
			uint256 stopTime,
			uint256 remainingBalance,
			uint256 ratePerSecond
		);

	function createStream(
		address recipient,
		uint256 deposit,
		address tokenAddress,
		uint256 startTime,
		uint256 stopTime
	) external returns (uint256 streamId);

	function withdrawFromStream(uint256 streamId, uint256 funds)
		external
		returns (bool);

	function cancelStream(uint256 streamId) external returns (bool);
}

pragma solidity =0.7.6;

/**
 * @title Sablier Types
 * @author Sablier
 */
library Types {
	struct Stream {
		uint256 deposit;
		uint256 ratePerSecond;
		uint256 remainingBalance;
		uint256 startTime;
		uint256 stopTime;
		address recipient;
		address sender;
		address tokenAddress;
		bool isEntity;
	}
}

pragma solidity =0.7.6;

/**
 * @title Careful Math
 * @author Compound
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
	/**
	 * @dev Possible error codes that we can return
	 */
	enum MathError {
		NO_ERROR,
		DIVISION_BY_ZERO,
		INTEGER_OVERFLOW,
		INTEGER_UNDERFLOW
	}

	/**
	 * @dev Multiplies two numbers, returns an error on overflow.
	 */
	function mulUInt(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, uint256)
	{
		if (a == 0) {
			return (MathError.NO_ERROR, 0);
		}

		uint256 c = a * b;

		if (c / a != b) {
			return (MathError.INTEGER_OVERFLOW, 0);
		} else {
			return (MathError.NO_ERROR, c);
		}
	}

	/**
	 * @dev Integer division of two numbers, truncating the quotient.
	 */
	function divUInt(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, uint256)
	{
		if (b == 0) {
			return (MathError.DIVISION_BY_ZERO, 0);
		}

		return (MathError.NO_ERROR, a / b);
	}

	/**
	 * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
	 */
	function subUInt(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, uint256)
	{
		if (b <= a) {
			return (MathError.NO_ERROR, a - b);
		} else {
			return (MathError.INTEGER_UNDERFLOW, 0);
		}
	}

	/**
	 * @dev Adds two numbers, returns an error on overflow.
	 */
	function addUInt(uint256 a, uint256 b)
		internal
		pure
		returns (MathError, uint256)
	{
		uint256 c = a + b;

		if (c >= a) {
			return (MathError.NO_ERROR, c);
		} else {
			return (MathError.INTEGER_OVERFLOW, 0);
		}
	}

	/**
	 * @dev add a and b and then subtract c
	 */
	function addThenSubUInt(
		uint256 a,
		uint256 b,
		uint256 c
	) internal pure returns (MathError, uint256) {
		(MathError err0, uint256 sum) = addUInt(a, b);

		if (err0 != MathError.NO_ERROR) {
			return (err0, 0);
		}

		return subUInt(sum, c);
	}
}

