// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/AccessControl.sol';
//import './ModaConstants.sol';
import './ModaPoolBase.sol';

/**
 * @title Moda Core Pool
 *
 * @notice Core pools represent permanent pools like MODA or MODA/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See ModaPoolBase for more details
 */
contract ModaCorePool is ModaPoolBase {
	/// @dev Pool tokens value available in the pool;
	///      pool token examples are MODA (MODA core pool) or MODA/ETH pair (LP core pool)
	/// @dev For LP core pool this value doesn't count for MODA tokens received as Vault rewards
	///      while for MODA core pool it does count for such tokens as well
	uint256 public poolTokenReserve;

	/**
	 * @dev Creates/deploys an instance of the core pool
	 *
	 * @param _moda MODA ERC20 Token ModaERC20 address
	 * @param _modaPool MODA ERC20 Liquidity Pool contract address
	 * @param _poolToken token the pool operates on, for example MODA or MODA/ETH pair
	 * @param _weight number representing a weight of the pool, actual weight fraction
	 *      is calculated as that number divided by the total pools weight and doesn't exceed one
	 * @param _modaPerSecond initial MODA/block value for rewards
	 * @param _secondsPerUpdate how frequently the rewards gets updated (decreased by 3%), seconds
	 * @param _initTimestamp initial block timestamp used to calculate the rewards
	 * @param _endTimestamp block timestamp when farming stops and rewards cannot be updated anymore
	 */
	constructor(
		address _moda,
		address _modaPool,
		address _poolToken,
		uint32 _weight,
		uint256 _modaPerSecond,
		uint256 _secondsPerUpdate,
		uint256 _initTimestamp,
		uint256 _endTimestamp
	)
		ModaPoolBase(
			_moda,
			_modaPool,
			_poolToken,
			_weight,
			_modaPerSecond,
			_secondsPerUpdate,
			_initTimestamp,
			_endTimestamp
		)
	{
		poolTokenReserve = 0;
	}

	/**
	 * @notice Service function to calculate and pay pending vault and yield rewards to the sender
	 *
	 * @dev Internally executes similar function `_processRewards` from the parent smart contract
	 *      to calculate and pay yield rewards; adds vault rewards processing
	 *
	 * @dev Can be executed by anyone at any time, but has an effect only when
	 *      executed by deposit holder and when at least one block passes from the
	 *      previous reward processing
	 * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
	 * @dev When timing conditions are not met (executed too frequently, or after
	 *      end block), function doesn't throw and exits silently
	 */
	function processRewards() external override {
		_processRewards(msg.sender, true);
	}

	/**
	 * @dev Executed internally by the pool itself (from the parent `ModaPoolBase` smart contract)
	 *      as part of yield rewards processing logic (`ModaPoolBase._processRewards` function)
	 * @dev Executed when pool is not an MODA pool - see `ModaPoolBase._processRewards`
	 *
	 * @param _staker an address which stakes (the yield reward)
	 * @param _amount amount to be staked (yield reward amount)
	 */
	function stakeAsPool(address _staker, uint256 _amount)
		external
		onlyRole(ModaConstants.ROLE_POOL_STAKING)
	{
		_sync();
		User storage user = users[_staker];
		if (user.tokenAmount > 0) {
			_processRewards(_staker, false);
		}
		uint256 depositWeight = _amount * YEAR_STAKE_WEIGHT_MULTIPLIER;
		Deposit memory newDeposit = Deposit({
			tokenAmount: _amount,
			lockedFrom: block.timestamp,
			lockedUntil: block.timestamp + 365 days,
			weight: depositWeight,
			isYield: true
		});
		user.tokenAmount += _amount;
		user.totalWeight += depositWeight;
		user.deposits.push(newDeposit);

		usersLockingWeight += depositWeight;

		user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

		// update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
		poolTokenReserve += _amount;
	}

	/**
	 * @inheritdoc ModaPoolBase
	 *
	 * @dev Additionally to the parent smart contract,
	 *      and updates (increases) pool token reserve (pool tokens value available in the pool)
	 */
	function _stake(
		address _staker,
		uint256 _amount,
		uint256 _lockUntil,
		bool _isYield
	) internal override {
		super._stake(_staker, _amount, _lockUntil, _isYield);
		poolTokenReserve += _amount;
	}

	/**
	 * @inheritdoc ModaPoolBase
	 *
	 * @dev Additionally to the parent smart contract,
	 *      and updates (decreases) pool token reserve
	 *      (pool tokens value available in the pool)
	 */
	function _unstake(
		address _staker,
		uint256 _depositId,
		uint256 _amount
	) internal override {
		User storage user = users[_staker];
		Deposit memory stakeDeposit = user.deposits[_depositId];
		require(
			stakeDeposit.lockedFrom == 0 || block.timestamp > stakeDeposit.lockedUntil,
			'deposit not yet unlocked'
		);
		poolTokenReserve -= _amount;
		super._unstake(_staker, _depositId, _amount);
	}

	/**
	 * @inheritdoc ModaPoolBase
	 *
	 * @dev Additionally to the parent smart contract,
	 *      and for MODA pool updates (increases) pool token reserve
	 *      (pool tokens value available in the pool)
	 */
	function _processRewards(
		address _staker,
		bool _withUpdate
	) internal override returns (uint256 rewards) {
		rewards = super._processRewards(_staker, _withUpdate);

		// update `poolTokenReserve` only if this is a MODA Core Pool
		if (poolToken == moda) {
			poolTokenReserve += rewards;
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
pragma solidity 0.8.6;

//import 'hardhat/console.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './IPool.sol';
import './ICorePool.sol';
import './ModaConstants.sol';
import './EscrowedModaERC20.sol';
import './ModaPoolFactory.sol';

/**
 * @title Moda Pool Base
 *
 * @notice An abstract contract containing common logic for any MODA pool,
 *      be it core pool (permanent pool like MODA/ETH or MODA core pool) or something else.
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must have 3 token instance addresses defined on deployment:
 *          - MODA token address
 *          - pool token address, it can be MODA token address, MODA/ETH pair address, and others
 */
abstract contract ModaPoolBase is
	IPool,
	ModaAware,
	ModaPoolFactory,
	ReentrancyGuard,
	AccessControl
{
	// @dev POOL_UID defined to add another check to ensure compliance with the contract.
	function POOL_UID() public pure returns (uint256) {
		return ModaConstants.POOL_UID;
	}

	// @dev modaPool MODA ERC20 Liquidity Pool contract address.
	// @dev This value is address(0) for the default MODA Core Pool.
	// @dev This value MUST be provided for any pool created which is not a MODA pool.
	// @dev This is used in the case where poolToken != moda.
	//      The use case relates to shadowing Liquidity Pool stakes
	//      by allowing people to store the LP tokens here to gain
	//      further MODA rewards. I'm not sure it's both. (dex 2021.09.16)
	address modaPool;

	/// @dev Data structure representing token holder using a pool
	struct User {
		// @dev Total staked amount
		uint256 tokenAmount;
		// @dev Total weight
		uint256 totalWeight;
		// @dev Auxiliary variable for yield calculation
		uint256 subYieldRewards;
		// @dev Auxiliary variable for vault rewards calculation
		uint256 subVaultRewards;
		// @dev An array of holder's deposits
		Deposit[] deposits;
	}

	/// @dev Token holder storage, maps token holder address to their data record
	mapping(address => User) public users;

	/// @dev Link to the pool token instance, for example MODA or MODA/ETH pair
	address public immutable override poolToken;

	/// @dev Pool weight, 100 for MODA pool or 900 for MODA/ETH
	uint32 public override weight;

	/// @dev Block timestamp of the last yield distribution event
	/// This gets initialised at the first rewards pass after rewardStartTime.
	uint256 public override lastYieldDistribution;

	/// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
	uint256 public override usersLockingWeight;

	/**
	 * @dev Stake weight is proportional to deposit amount and time locked, precisely
	 *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
	 * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
	 *      weight is stored multiplied by 1e6 constant, as an integer
	 * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e6
	 * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
	 *      weight is a deposit amount multiplied by 2 * 1e6
	 */
	uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

	/// @dev Used to calculate yield rewards
	/// @dev This value is different from "reward per token" used in locked pool
	/// @dev Note: stakes are different in duration and "weight" reflects that
	uint256 public override yieldRewardsPerWeight;

	/**
	 * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
	 *      we use simplified calculation and use the following constant instead previos one
	 */
	uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

	/**
	 * @dev Rewards per weight are stored multiplied by 1e12, as integers.
	 */
	uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

	/**
	 * @dev Fired in _stake() and stake()
	 *
	 * @param _by an address which performed an operation, usually token holder
	 * @param _from token holder address, the tokens will be returned to that address
	 * @param amount amount of tokens staked
	 */
	event Staked(address indexed _by, address indexed _from, uint256 amount);

	/**
	 * @dev Fired in _updateStakeLock() and updateStakeLock()
	 *
	 * @param _by an address which performed an operation
	 * @param depositId updated deposit ID
	 * @param lockedFrom deposit locked from value
	 * @param lockedUntil updated deposit locked until value
	 */
	event StakeLockUpdated(
		address indexed _by,
		uint256 depositId,
		uint256 lockedFrom,
		uint256 lockedUntil
	);

	/**
	 * @dev Fired in _unstake() and unstake()
	 *
	 * @param _by an address which performed an operation, usually token holder
	 * @param _to an address which received the unstaked tokens, usually token holder
	 * @param amount amount of tokens unstaked
	 */
	event Unstaked(address indexed _by, address indexed _to, uint256 amount);

	/**
	 * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
	 *
	 * @param _by an address which performed an operation
	 * @param yieldRewardsPerWeight updated yield rewards per weight value
	 * @param lastYieldDistribution usually, current block timestamp
	 */
	event Synchronized(
		address indexed _by,
		uint256 yieldRewardsPerWeight,
		uint256 lastYieldDistribution
	);

	/**
	 * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
	 *
	 * @param _by an address which performed an operation
	 * @param _to an address which claimed the yield reward
	 * @param amount amount of yield paid
	 */
	event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

	/**
	 * @dev Fired in setWeight()
	 *
	 * @param _by an address which performed an operation, always a factory
	 * @param _fromVal old pool weight value
	 * @param _toVal new pool weight value
	 */
	event PoolWeightUpdated(address indexed _by, uint32 _fromVal, uint32 _toVal);

	/**
	 * @dev Overridden in sub-contracts to construct the pool
	 *
	 * @param _moda MODA ERC20 Token ModaERC20 address
	 * @param _modaPool MODA ERC20 Liquidity Pool contract address
	 * @param _poolToken token the pool operates on, for example MODA or MODA/ETH pair
	 * @param _initTimestamp initial block used to calculate the rewards
	 *      note: _initTimestamp can be set to the future effectively meaning _sync() calls will do nothing
	 * @param _weight number representing a weight of the pool, actual weight fraction
	 *      is calculated as that number divided by the total pools weight and doesn't exceed one
	 * @param _modaPerSecond initial MODA/block value for rewards
	 * @param _secondsPerUpdate how frequently the rewards gets updated (decreased by 3%), seconds
	 * @param _endTimestamp block timestamp when farming stops and rewards cannot be updated anymore
	 */
	constructor(
		address _moda,
		address _modaPool,
		address _poolToken,
		uint32 _weight,
		uint256 _modaPerSecond,
		uint256 _secondsPerUpdate,
		uint256 _initTimestamp,
		uint256 _endTimestamp
	) ModaPoolFactory(_moda, _modaPerSecond, _secondsPerUpdate, _initTimestamp, _endTimestamp) {
		// verify the inputs are set
		require(_poolToken != address(0), 'pool token address not set');
		require(_initTimestamp >= block.timestamp, 'init timestamp already passed');
		require(_weight > 0, 'pool weight not set');
		require(
			((_poolToken == _moda ? 1 : 0) ^ (_modaPool != address(0) ? 1 : 0)) == 1,
			'The pool is either a MODA pool or manages external tokens, never both'
		);

		// verify MODA instance supplied
		require(Token(_moda).TOKEN_UID() == ModaConstants.TOKEN_UID, 'MODA TOKEN_UID invalid');

		if (_modaPool != address(0)) {
			require(ModaPoolBase(_modaPool).POOL_UID() == ModaConstants.POOL_UID);
		}
		// save the inputs into internal state variables
		modaPool = _modaPool;
		poolToken = _poolToken;
		_setWeight(_weight);

		// init the dependent internal state variables
		lastYieldDistribution = _initTimestamp;

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setRoleAdmin(ModaConstants.ROLE_TOKEN_CREATOR, DEFAULT_ADMIN_ROLE);
		grantRole(ModaConstants.ROLE_TOKEN_CREATOR, _msgSender());
	}

	/**
	 * @dev Granting privileges required for allowing ModaCorePool and whatever else later,
	 *     the ability to mint Tokens as required.
	 */
	function grantPrivilege(bytes32 _role, address _account) public onlyOwner {
		grantRole(_role, _account);
	}

	/**
	 * @notice Calculates current yield rewards value available for address specified
	 *
	 * @param _staker an address to calculate yield rewards value for
	 * @return calculated yield reward value for the given address
	 */
	function pendingYieldRewards(address _staker) external view override returns (uint256) {
		// `newYieldRewardsPerWeight` will store stored a recalculated value for `yieldRewardsPerWeight`
		uint256 newYieldRewardsPerWeight;

		// if smart contract state was not updated recently, `yieldRewardsPerWeight` value
		// is outdated and we need to recalculate it in order to calculate pending rewards correctly
		if (block.timestamp > lastYieldDistribution && usersLockingWeight != 0) {
			uint256 endTimestamp = endTimestamp;
			uint256 multiplier = block.timestamp > endTimestamp
				? endTimestamp - lastYieldDistribution
				: block.timestamp - lastYieldDistribution;
			uint256 modaRewards = (multiplier * weight * modaPerSecond) / totalWeight;

			// recalculated value for `yieldRewardsPerWeight`
			newYieldRewardsPerWeight =
				rewardToWeight(modaRewards, usersLockingWeight) +
				yieldRewardsPerWeight;
		} else {
			// if smart contract state is up to date, we don't recalculate
			newYieldRewardsPerWeight = yieldRewardsPerWeight;
		}

		// based on the rewards per weight value, calculate pending rewards;
		User memory user = users[_staker];
		uint256 pending = weightToReward(user.totalWeight, newYieldRewardsPerWeight) -
			user.subYieldRewards;

		return pending;
	}

	/**
	 * @notice Returns total staked token balance for the given address
	 *
	 * @param _user an address to query balance for
	 * @return total staked token balance
	 */
	function balanceOf(address _user) external view override returns (uint256) {
		// read specified user token amount and return
		return users[_user].tokenAmount;
	}

	/**
	 * @notice Returns information on the given deposit for the given address
	 *
	 * @dev See getDepositsLength
	 *
	 * @param _user an address to query deposit for
	 * @param _depositId zero-indexed deposit ID for the address specified
	 * @return deposit info as Deposit structure
	 */
	function getDeposit(address _user, uint256 _depositId)
		external
		view
		override
		returns (Deposit memory)
	{
		// read deposit at specified index and return
		return users[_user].deposits[_depositId];
	}

	/**
	 * @notice Returns number of deposits for the given address. Allows iteration over deposits.
	 *
	 * @dev See getDeposit
	 *
	 * @param _user an address to query deposit length for
	 * @return number of deposits for the given address
	 */
	function getDepositsLength(address _user) external view override returns (uint256) {
		// read deposits array length and return
		return users[_user].deposits.length;
	}

	/**
	 * @notice Stakes specified amount of tokens for the specified amount of time,
	 *      and pays pending yield rewards if any
	 *
	 * @dev Requires amount to stake to be greater than zero
	 *
	 * @param _amount amount of tokens to stake
	 * @param _lockUntil stake period as unix timestamp; zero means no locking
	 */
	function stake(
		uint256 _amount,
		uint256 _lockUntil
	) external override {
		// delegate call to an internal function
		_stake(msg.sender, _amount, _lockUntil,  false);
	}

	/**
	 * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
	 *
	 * @dev Requires amount to unstake to be greater than zero
	 *
	 * @param _depositId deposit ID to unstake from, zero-indexed
	 * @param _amount amount of tokens to unstake
	 */
	function unstake(
		uint256 _depositId,
		uint256 _amount
	) external override {
		// delegate call to an internal function
		//console.log('ModaPoolBase unstake', _msgSender());
		_unstake(msg.sender, _depositId, _amount);
	}

	/**
	 * @notice Extends locking period for a given deposit
	 *
	 * @dev Requires new lockedUntil value to be:
	 *      higher than the current one, and
	 *      in the future, but
	 *      no more than 1 year in the future
	 *
	 * @param depositId updated deposit ID
	 * @param lockedUntil updated deposit locked until value
	 */
	function updateStakeLock(
		uint256 depositId,
		uint256 lockedUntil
	) external {
		// sync and call processRewards
		_sync();
		_processRewards(msg.sender, false);
		// delegate call to an internal function
		_updateStakeLock(msg.sender, depositId, lockedUntil);
	}

	/**
	 * @notice Service function to synchronize pool state with current time
	 *
	 * @dev Can be executed by anyone at any time, but has an effect only when
	 *      at least one block passes between synchronizations
	 * @dev Executed internally when staking, unstaking, processing rewards in order
	 *      for calculations to be correct and to reflect state progress of the contract
	 * @dev When timing conditions are not met (executed too frequently, or after factory
	 *      end block), function doesn't throw and exits silently
	 */
	function sync() external override {
		// delegate call to an internal function
		_sync();
	}

	/**
	 * @notice Service function to calculate and pay pending yield rewards to the sender
	 *
	 * @dev Can be executed by anyone at any time, but has an effect only when
	 *      executed by deposit holder and when at least one block passes from the
	 *      previous reward processing
	 * @dev When timing conditions are not met (executed too frequently, or after
	 *      end block), function doesn't throw and exits silently
	 */
	function processRewards() external virtual override {
		// delegate call to an internal function
		_processRewards(msg.sender, true);
	}

	/**
	 * @dev Executed by the factory to modify pool weight; the factory is expected
	 *      to keep track of the total pools weight when updating
	 *
	 * @dev Set weight to zero to disable the pool
	 *
	 * @param _weight new weight to set for the pool
	 */
	function setWeight(uint32 _weight) external override onlyOwner {
		_setWeight(_weight);
	}

	/**
	 * @dev Executed by the factory to modify pool weight; the factory is expected
	 *      to keep track of the total pools weight when updating
	 *
	 * @dev Set weight to zero to disable the pool
	 *
	 * @param _weight new weight to set for the pool
	 */
	function _setWeight(uint32 _weight) internal onlyOwner {
		///TODO: this could be more efficient.
		// order of operations is important here.
		_changePoolWeight(_weight);
		// set the new weight value
		weight = _weight;
		// emit an event logging old and new weight values
		emit PoolWeightUpdated(msg.sender, weight, _weight);
	}

	/**
	 * @dev Similar to public pendingYieldRewards, but performs calculations based on
	 *      current smart contract state only, not taking into account any additional
	 *      time/blocks which might have passed
	 *
	 * @param _staker an address to calculate yield rewards value for
	 * @return pending calculated yield reward value for the given address
	 */
	function _pendingYieldRewards(address _staker) internal view returns (uint256 pending) {
		// read user data structure into memory
		User memory user = users[_staker];

		// and perform the calculation using the values read
		return weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
	}

	/**
	 * @dev Used internally, mostly by children implementations, see stake()
	 *
	 * @param _staker an address which stakes tokens and which will receive them back
	 * @param _amount amount of tokens to stake
	 * @param _lockUntil stake period as unix timestamp; zero means no locking
	 * @param _isYield a flag indicating if that stake is created to store yield reward
	 *      from the previously unstaked stake
	 */
	function _stake(
		address _staker,
		uint256 _amount,
		uint256 _lockUntil,
		bool _isYield
	) internal virtual {
		// validate the inputs
		// console.log('lockUntil', _lockUntil);
		// console.log('timestamp', block.timestamp);
		require(_amount > 0, 'zero amount');
		require(
			_lockUntil == 0 ||
				(_lockUntil > block.timestamp && _lockUntil - block.timestamp <= 365 days),
			'invalid lock interval'
		);

		// update smart contract state
		_sync();

		// get a link to user data struct, we will write to it later
		User storage user = users[_staker];
		// process current pending rewards if any
		if (user.tokenAmount > 0) {
			_processRewards(_staker, false);
		}

		// in most of the cases added amount `addedAmount` is simply `_amount`
		// however for deflationary tokens this can be different

		// read the current balance
		uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
		// transfer `_amount`; note: some tokens may get burnt here
		transferPoolTokenFrom(address(msg.sender), address(this), _amount);
		// read new balance, usually this is just the difference `previousBalance - _amount`
		uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
		// calculate real amount taking into account deflation
		uint256 addedAmount = newBalance - previousBalance;

		// set the `lockFrom` and `lockUntil` taking into account that
		// zero value for `_lockUntil` means "no locking" and leads to zero values
		// for both `lockFrom` and `lockUntil`
		uint256 lockFrom = _lockUntil > 0 ? block.timestamp : 0;
		uint256 lockUntil = _lockUntil;

		// stake weight formula rewards for locking
		uint256 stakeWeight = (((lockUntil - lockFrom) * WEIGHT_MULTIPLIER) /
			365 days +
			WEIGHT_MULTIPLIER) * addedAmount;

		// makes sure stakeWeight is valid
		assert(stakeWeight > 0);

		// create and save the deposit (append it to deposits array)
		Deposit memory deposit = Deposit({
			tokenAmount: addedAmount,
			weight: stakeWeight,
			lockedFrom: lockFrom,
			lockedUntil: lockUntil,
			isYield: _isYield
		});
		// deposit ID is an index of the deposit in `deposits` array
		user.deposits.push(deposit);

		// update user record
		user.tokenAmount += addedAmount;
		user.totalWeight += stakeWeight;
		user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

		// update global variable
		usersLockingWeight += stakeWeight;

		// emit an event
		emit Staked(msg.sender, _staker, _amount);
	}

	/**
	 * @dev Used internally, mostly by children implementations, see unstake()
	 *
	 * @param _staker an address which unstakes tokens (which previously staked them)
	 * @param _depositId deposit ID to unstake from, zero-indexed
	 * @param _amount amount of tokens to unstake
	 */
	function _unstake(
		address _staker,
		uint256 _depositId,
		uint256 _amount
	) internal virtual {
		// verify an amount is set
		require(_amount > 0, 'zero amount');

		// get a link to user data struct, we will write to it later
		User storage user = users[_staker];
		// get a link to the corresponding deposit, we may write to it later
		Deposit storage stakeDeposit = user.deposits[_depositId];
		// deposit structure may get deleted, so we save isYield flag to be able to use it
		bool isYield = stakeDeposit.isYield;

		// verify available balance
		// if staker address ot deposit doesn't exist this check will fail as well
		require(stakeDeposit.tokenAmount >= _amount, 'amount exceeds stake');

		// update smart contract state
		_sync();
		// and process current pending rewards if any
		_processRewards(_staker, false);

		// recalculate deposit weight
		uint256 previousWeight = stakeDeposit.weight;
		uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) *
			WEIGHT_MULTIPLIER) /
			365 days +
			WEIGHT_MULTIPLIER) * (stakeDeposit.tokenAmount - _amount);

		// update the deposit, or delete it if its depleted
		if (stakeDeposit.tokenAmount - _amount == 0) {
			delete user.deposits[_depositId];
		} else {
			stakeDeposit.tokenAmount -= _amount;
			stakeDeposit.weight = newWeight;
		}

		// update user record
		user.tokenAmount -= _amount;
		user.totalWeight = user.totalWeight - previousWeight + newWeight;
		user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

		// update global variable
		usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

		// if the deposit was created by the pool itself as a yield reward
		if (isYield) {
			// mint the yield via the factory
			mintYieldTo(msg.sender, _amount);
		} else {
			// otherwise just return tokens back to holder
			transferPoolToken(msg.sender, _amount);
		}

		// emit an event
		emit Unstaked(msg.sender, _staker, _amount);
	}

	/**
	 * @dev Used internally, mostly by children implementations, see sync()
	 *
	 * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
	 *      updates factory state via `updateMODAPerSecond`
	 */
	function _sync() internal virtual {
		// update MODA per block value in factory if required
		if (shouldUpdateRatio()) {
			updateMODAPerSecond();
		}

		// check bound conditions and if these are not met -
		// exit silently, without emitting an event
		uint256 lastTimestamp = endTimestamp;
		if (lastYieldDistribution >= lastTimestamp) {
			return;
		}
		if (block.timestamp <= lastYieldDistribution) {
			return;
		}
		// if locking weight is zero - update only `lastYieldDistribution` and exit
		if (usersLockingWeight == 0) {
			lastYieldDistribution = block.timestamp;
			return;
		}

		// to calculate the reward we need to know how much time has passed, and reward per seconds
		uint256 currentTimestamp = block.timestamp > endTimestamp ? endTimestamp : block.timestamp;
		uint256 secondsPassed = currentTimestamp - lastYieldDistribution;

		// calculate the reward
		uint256 modaReward = (secondsPassed * modaPerSecond * weight) / totalWeight;

		// update rewards per weight and `lastYieldDistribution`
		yieldRewardsPerWeight += rewardToWeight(modaReward, usersLockingWeight);
		lastYieldDistribution = currentTimestamp;

		// emit an event
		emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
	}

	/**
	 * @dev Used internally, mostly by children implementations, see processRewards()
	 *
	 * @param _staker an address which receives the reward (which has staked some tokens earlier)
	 * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
	 * @return pendingYield the rewards calculated and optionally re-staked
	 */
	function _processRewards(
		address _staker,
		bool _withUpdate
	) internal virtual returns (uint256 pendingYield) {
		// update smart contract state if required
		if (_withUpdate) {
			_sync();
		}

		// calculate pending yield rewards, this value will be returned
		pendingYield = _pendingYieldRewards(_staker);

		// if pending yield is zero - just return silently
		if (pendingYield == 0) return 0;

		// get link to a user data structure, we will write into it later
		User storage user = users[_staker];

		if (poolToken == moda) {
			// calculate pending yield weight,
			// 2e6 is the bonus weight when staking for 1 year
			uint256 depositWeight = pendingYield * YEAR_STAKE_WEIGHT_MULTIPLIER;

			// if the pool is MODA Pool - create new MODA deposit
			// and save it - push it into deposits array
			Deposit memory newDeposit = Deposit({
				tokenAmount: pendingYield,
				lockedFrom: block.timestamp,
				lockedUntil: block.timestamp + 365 days, // staking yield for 1 year
				weight: depositWeight,
				isYield: true
			});
			user.deposits.push(newDeposit);

			// update user record
			user.tokenAmount += pendingYield;
			user.totalWeight += depositWeight;

			// update global variable
			usersLockingWeight += depositWeight;
		} else {
			// Force a hard error in this case.
			// The pool was somehow not constructed correctly.
			assert(modaPool != address(0));
			// for other pools - stake as pool.
			// NB: the target modaPool must be configured to give
			// this contract instance the ROLE_TOKEN_CREATOR role/privilege.
			ICorePool(modaPool).stakeAsPool(_staker, pendingYield);
		}

		// update users's record for `subYieldRewards` if requested
		if (_withUpdate) {
			user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
		}

		// emit an event
		emit YieldClaimed(msg.sender, _staker, pendingYield);
	}

	/**
	 * @dev See updateStakeLock()
	 *
	 * @param _staker an address to update stake lock
	 * @param _depositId updated deposit ID
	 * @param _lockedUntil updated deposit locked until value
	 */
	function _updateStakeLock(
		address _staker,
		uint256 _depositId,
		uint256 _lockedUntil
	) internal {
		// validate the input time
		require(_lockedUntil > block.timestamp, 'lock should be in the future');

		// get a link to user data struct, we will write to it later
		User storage user = users[_staker];
		// get a link to the corresponding deposit, we may write to it later
		Deposit storage stakeDeposit = user.deposits[_depositId];

		// validate the input against deposit structure
		require(_lockedUntil > stakeDeposit.lockedUntil, 'invalid new lock');

		// verify locked from and locked until values
		if (stakeDeposit.lockedFrom == 0) {
			require(_lockedUntil - block.timestamp <= 365 days, 'max lock period is 365 days');
			stakeDeposit.lockedFrom = block.timestamp;
		} else {
			require(
				_lockedUntil - stakeDeposit.lockedFrom <= 365 days,
				'max lock period is 365 days'
			);
		}

		// update locked until value, calculate new weight
		stakeDeposit.lockedUntil = _lockedUntil;
		uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) *
			WEIGHT_MULTIPLIER) /
			365 days +
			WEIGHT_MULTIPLIER) * stakeDeposit.tokenAmount;

		// save previous weight
		uint256 previousWeight = stakeDeposit.weight;
		// update weight
		stakeDeposit.weight = newWeight;

		// update user total weight and global locking weight
		user.totalWeight = user.totalWeight - previousWeight + newWeight;
		usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

		// emit an event
		emit StakeLockUpdated(_staker, _depositId, stakeDeposit.lockedFrom, _lockedUntil);
	}

	/**
	 * @dev Converts stake weight (not to be mixed with the pool weight) to
	 *      MODA reward value, applying the 10^12 division on weight
	 *
	 * @param _weight stake weight
	 * @param rewardPerWeight MODA reward per weight
	 * @return reward value normalized to 10^12
	 */
	function weightToReward(uint256 _weight, uint256 rewardPerWeight)
		public
		pure
		returns (uint256)
	{
		// apply the formula and return
		return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
	}

	/**
	 * @dev Converts reward MODA value to stake weight (not to be mixed with the pool weight),
	 *      applying the 10^12 multiplication on the reward
	 *      - OR -
	 * @dev Converts reward MODA value to reward/weight if stake weight is supplied as second
	 *      function parameter instead of reward/weight
	 *
	 * @param reward yield reward
	 * @param rewardPerWeight reward/weight (or stake weight)
	 * @return stake weight (or reward/weight)
	 */
	function rewardToWeight(uint256 reward, uint256 rewardPerWeight) public pure returns (uint256) {
		// apply the reverse formula and return
		return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
	}

	/**
	 * @dev Executes SafeERC20.safeTransfer on a pool token
	 *
	 * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
	 */
	function transferPoolToken(address _to, uint256 _value) internal nonReentrant {
		// just delegate call to the target
		SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
	}

	/**
	 * @dev Executes SafeERC20.safeTransferFrom on a pool token
	 *
	 * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
	 */
	function transferPoolTokenFrom(
		address _from,
		address _to,
		uint256 _value
	) internal nonReentrant {
		// just delegate call to the target
		SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
	}

	function _poolWeight() internal view override returns (uint32) {
		return weight;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor () {
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
pragma solidity >=0.8.4;

import './ILinkedToMODA.sol';

/**
 * @title Moda Pool
 *
 * @notice An abstraction representing a pool, see ModaPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IPool is ILinkedToMODA {
	/**
	 * @dev Deposit is a key data structure used in staking,
	 *      it represents a unit of stake with its amount, weight and term (time interval)
	 */
	struct Deposit {
		// @dev token amount staked
		uint256 tokenAmount;
		// @dev stake weight
		uint256 weight;
		// @dev locking period - from
		uint256 lockedFrom;
		// @dev locking period - until
		uint256 lockedUntil;
		// @dev indicates if the stake was created as a yield reward
		bool isYield;
	}

	// for the rest of the functions see Soldoc in ModaPoolBase

	function poolToken() external view returns (address);

	//function isFlashPool() external view returns (bool);

	function weight() external view returns (uint32);

	function lastYieldDistribution() external view returns (uint256);

	function yieldRewardsPerWeight() external view returns (uint256);

	function usersLockingWeight() external view returns (uint256);

	function pendingYieldRewards(address _user) external view returns (uint256);

	function balanceOf(address _user) external view returns (uint256);

	function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

	function getDepositsLength(address _user) external view returns (uint256);

	function stake(
		uint256 _amount,
		uint256 _lockedUntil
	) external;

	function unstake(
		uint256 _depositId,
		uint256 _amount
	) external;

	function sync() external;

	function processRewards() external;

	function setWeight(uint32 _weight) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import './IPool.sol';

interface ICorePool is IPool {
	function vaultRewardsPerToken() external view returns (uint256);

	function poolTokenReserve() external view returns (uint256);

	function stakeAsPool(address _staker, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library ModaConstants {
	/**
	 * @dev Smart contract unique identifier, a random number
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 * @dev Generated using https://www.random.org/bytes/
	 */
	uint256 public constant TOKEN_UID =
		0xc8de2a18ae1c61538a5f880f5c8eb7ff85aa3996c4363a27b1c6112a190e65b4;

	/**
	 * @dev Smart contract unique identifier, a random number
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 * @dev Generated using https://www.random.org/bytes/
	 */
	uint256 public constant ESCROWTOKEN_UID =
		0x0a9a93ba9d22fa5ed507ff32440b8750c8951e4864438c8afc02be22ad238ebf;

	/**
	 * @dev Smart contract unique identifier, a random number
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 * @dev Generated using https://www.random.org/bytes/
	 */
	uint256 public constant POOL_UID =
		0x8ca5f5bb5e4f02345a019a993ce37018dd549b22e88027f4f5c1f614ef6fb3c0;

	/**
	 * @notice Upgrader is responsible for managing future versions
	 *         of the contract.
	 */
	bytes32 public constant ROLE_UPGRADER = '\x00\x0A\x00\x00';

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (calling `mint` function)
	 */
	bytes32 public constant ROLE_TOKEN_CREATOR = '\x00\x0B\x00\x00';

	/**
	 * @notice Token stakeAsPool is responsible for stakes in Moda Pools
	 *         for an arbitrary address.
	 * @dev Role ROLE_POOL_STAKING allows creating stakes for non-Moda tokens.
	 */
	bytes32 public constant ROLE_POOL_STAKING = '\x00\x0C\x00\x00';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './ModaConstants.sol';

contract EscrowedModaERC20 is ERC20('Escrowed Moda', 'sMODA'), AccessControl, Ownable {
	function ESCROWTOKEN_UID() public pure returns (uint256) {
		return ModaConstants.ESCROWTOKEN_UID;
	}

	constructor() {
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setRoleAdmin(ModaConstants.ROLE_TOKEN_CREATOR, DEFAULT_ADMIN_ROLE);
		grantRole(ModaConstants.ROLE_TOKEN_CREATOR, _msgSender());
	}

	/**
	 * @dev Granting privileges required for allowing ModaCorePool and whatever else later,
	 *     the ability to mint Tokens as required.
	 */
	function grantPrivilege(bytes32 _role, address _account) public onlyOwner {
		grantRole(_role, _account);
	}

	/**
	 * @notice Must be called by ROLE_TOKEN_CREATOR addresses.
	 *
	 * @param recipient address to receive the tokens.
	 * @param amount number of tokens to be minted.
	 */
	function mint(address recipient, uint256 amount)
		external
		onlyRole(ModaConstants.ROLE_TOKEN_CREATOR)
	{
		_mint(recipient, amount);
	}

	/**
	 * @param amount number of tokens to be burned.
	 */
	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import './ModaAware.sol';
import './EscrowedModaERC20.sol';

/**
 * @title Moda Core Pool
 *
 * @notice Core pools represent permanent pools like MODA or MODA/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev Pulled from the original Factory code to provide the weight calculations.
 */
abstract contract ModaPoolFactory is ModaAware, Ownable {
	/**
	 * @dev MODA/block determines yield farming reward base
	 *      used by the yield pools controlled by the factory
	 */
	uint256 public modaPerSecond;

	/**
	 * @dev The yield is distributed proportionally to pool weights;
	 *      total weight is here to help in determining the proportion
	 */
	uint32 public totalWeight;

	/**
	 * @dev MODA/block decreases by 3% every blocks/update (set to 91252 blocks during deployment);
	 *      an update is triggered by executing `updateMODAPerSecond` public function
	 */
	uint256 public immutable secondsPerUpdate;

	/**
	 * @dev End timestamp is the last timestamp when MODA/block can be decreased;
	 *      it is implied that yield farming stops after that timestamp
	 */
	uint256 public endTimestamp;

	/**
	 * @dev Each time the MODA/block ratio gets updated, the block timestamp
	 *      when the operation has occurred gets recorded into `lastRatioUpdate`
	 * @dev This block timestamp is then used to check if blocks/update `secondsPerUpdate`
	 *      has passed when decreasing yield reward by 3%
	 */
	uint256 public lastRatioUpdate;

	/**
	 * @dev Fired in _changePoolWeight()
	 *
	 * @param _by an address which executed an action
	 * @param poolAddress deployed pool instance address
	 * @param weight new pool weight
	 */
	event WeightUpdated(address indexed _by, address indexed poolAddress, uint32 weight);

	/**
	 * @dev Fired in updateILVPerBlock()
	 *
	 * @param _by an address which executed an action
	 * @param newIlvPerBlock new ILV/block value
	 */
	event ModaRatioUpdated(address indexed _by, uint256 newIlvPerBlock);

	/**
	 * @dev Creates/deploys a factory instance
	 *
	 * @param _moda MODA ERC20 token address
	 * @param _modaPerSecond initial MODA/block value for rewards
	 * @param _secondsPerUpdate how frequently the rewards gets updated (decreased by 3%), seconds
	 * @param _initTimestamp block timestamp to measure _secondsPerUpdate from
	 * @param _endTimestamp block timestamp when farming stops and rewards cannot be updated anymore
	 */
	constructor(
		address _moda,
		uint256 _modaPerSecond,
		uint256 _secondsPerUpdate,
		uint256 _initTimestamp,
		uint256 _endTimestamp
	) ModaAware(_moda) {
		// verify the inputs are set
		require(_modaPerSecond > 0, 'MODA/block not set');
		require(_secondsPerUpdate > 0, 'blocks/update not set');
		require(_initTimestamp > 0, 'init timestamp not set');
		require(_endTimestamp > _initTimestamp, 'invalid end timestamp: must be greater than init timestamp');

		// save the inputs into internal state variables
		modaPerSecond = _modaPerSecond;
		secondsPerUpdate = _secondsPerUpdate;
		lastRatioUpdate = _initTimestamp;
		endTimestamp = _endTimestamp;
	}

	/**
	 * @dev Verifies if `secondsPerUpdate` has passed since last MODA/block
	 *      ratio update and if MODA/block reward can be decreased by 3%
	 *
	 * @return true if enough time has passed and `updateMODAPerSecond` can be executed
	 */
	function shouldUpdateRatio() internal view returns (bool) {
		// if yield farming period has ended
		if (block.timestamp > endTimestamp) {
			// MODA/block reward cannot be updated anymore
			return false;
		}

		// check if blocks/update (91252 blocks) have passed since last update
		return block.timestamp >= lastRatioUpdate + secondsPerUpdate;
	}

	/**
	 * @notice Decreases MODA/block reward by 3%, can be executed
	 *      no more than once per `secondsPerUpdate` blocks
	 */
	function updateMODAPerSecond() internal {
		// checks if ratio can be updated i.e. if enough time has passed
		require(shouldUpdateRatio(), 'too frequent');

		// decreases MODA/block reward by 3%
		modaPerSecond = (modaPerSecond * 97) / 100;

		// set current block as the last ratio update block
		lastRatioUpdate = block.timestamp;

		// emit an event
		emit ModaRatioUpdated(msg.sender, modaPerSecond);
	}

	/**
	 * @dev Mints MODA tokens; executed by MODA Pool only
	 *
	 * @dev Requires caller to have ROLE_TOKEN_CREATOR permission
	 *      on the MODA ERC20 token instance
	 *
	 * @param _to an address to mint tokens to
	 * @param _amount amount of MODA tokens to mint
	 */
	function mintYieldTo(address _to, uint256 _amount) internal {
		// mint MODA tokens as required
		//console.log('ModaPoolFactory.mintYieldTo', address(this), _msgSender(), _to);
		mintModa(_to, _amount);
	}

	/**
	 * @dev Provided a virtual accessor to the IPool.weight()
	 *      implemented in ModaPoolBase.
	 * @dev This is used by _changePoolWeight in place of the
	 *      original implementation's pool address parameter.
	 */
	function _poolWeight() internal view virtual returns (uint32);

	/**
	 * @dev Changes the weight of the pool;
	 *      executed by the pool itself or by the factory owner
	 *
	 * @param newWeight new weight value to set to
	 */
	function _changePoolWeight(uint32 newWeight) internal onlyOwner {
		// recalculate total weight
		totalWeight = totalWeight + newWeight - _poolWeight();

		// emit an event
		emit WeightUpdated(msg.sender, address(this), newWeight);
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
pragma solidity 0.8.6;

/**
 * @title Linked to moda Marker Interface
 *
 * @notice Marks smart contracts which are linked to ModaERC20 token instance upon construction,
 *      all these smart contracts share a common moda() address getter
 *
 * @notice Implementing smart contracts MUST verify that they get linked to real ModaERC20 instance
 *      and that moda() getter returns this very same instance address
 *
 * @author Basil Gorin
 */
interface ILinkedToMODA {
  /**
   * @notice Getter for a verified MODAERC20 instance address
   *
   * @return MODAERC20 token instance address smart contract is linked to
   */
  function moda() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
pragma solidity 0.8.6;

import './ILinkedToMODA.sol';
import './ModaConstants.sol';
import './Token.sol';

/**
 * @title Moda Aware
 *
 * @notice Helper smart contract to be inherited by other smart contracts requiring to
 *      be linked to verified ModaERC20 instance and performing some basic tasks on it
 *
 * @author Basil Gorin
 * @author Kevin Brown (Moda DAO)
 */
abstract contract ModaAware is ILinkedToMODA {
	/// @dev Link to MODA ERC20 Token ModaERC20 instance
	address public immutable override moda;

	/**
	 * @dev Creates ModaAware instance, requiring to supply deployed ModaERC20 instance address
	 *
	 * @param _moda deployed ModaERC20 instance address
	 */
	constructor(address _moda) {
		// verify MODA address is set and is correct
		require(_moda != address(0), 'MODA address not set');
		require(Token(_moda).TOKEN_UID() == ModaConstants.TOKEN_UID, 'unexpected TOKEN_UID');

		// write MODA address
		moda = _moda;
	}

	/**
	 * @dev Executes ModaERC20.mint(_to, _values)
	 *      on the bound ModaERC20 instance
	 *
	 * @dev Reentrancy safe due to the ModaERC20 design
	 */
	function mintModa(address _to, uint256 _value) internal {
		// just delegate call to the target
		Token(moda).mint(_to, _value);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import './IMintableToken.sol';
import './ModaConstants.sol';

contract Token is
	Initializable,
	ERC20Upgradeable,
	UUPSUpgradeable,
	AccessControlUpgradeable,
	IMintableToken
{
	uint256 public holderCount;
	address public vestingContract;

	function TOKEN_UID() public pure returns (uint256) {
		return ModaConstants.TOKEN_UID;
	}

	/**
	 * @dev Our constructor (with UUPS upgrades we need to use initialize(), but this is only
	 *      able to be called once because of the initializer modifier.
	 */
	function initialize(address[] memory recipients, uint256[] memory amounts) public initializer {
		require(recipients.length == amounts.length, 'Token: recipients and amounts must match');

		__ERC20_init('moda', 'MODA');

		uint256 length = recipients.length;
		for (uint256 i = 0; i < length; i++) {
			_mintWithCount(recipients[i], amounts[i]);
		}

		__AccessControl_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(ModaConstants.ROLE_UPGRADER, _msgSender());
		_setupRole(ModaConstants.ROLE_TOKEN_CREATOR, _msgSender());
	}

	/**
	 * @dev This function is required by Open Zeppelin's UUPS proxy implementation
	 *      and indicates whether a contract upgrade should go ahead or not.
	 *
	 *      This implementation only allows the contract owner to perform upgrades.
	 */
	function _authorizeUpgrade(address) internal view override onlyRole(ModaConstants.ROLE_UPGRADER) {}

	/**
	 * @dev Internal function to manage the holderCount variable that should be called
	 *      BEFORE transfers alter balances.
	 */
	function _updateCountOnTransfer(
		address from,
		address to,
		uint256 amount
	) private {
		if (from != to) {
			if (balanceOf(to) == 0 && amount > 0) {
				++holderCount;
			}

			if (balanceOf(from) == amount && amount > 0) {
				--holderCount;
			}
		}
	}

	/**
	 * @dev A private function that mints while maintaining the holder count variable.
	 */
	function _mintWithCount(address to, uint256 amount) private {
		_updateCountOnTransfer(address(0), to, amount);
		_mint(to, amount);
	}

	/**
	 * @dev Mints (creates) some tokens to address specified
	 * @dev The value specified is treated as is without taking
	 *      into account what `decimals` value is
	 * @dev Behaves effectively as `mintTo` function, allowing
	 *      to specify an address to mint tokens to
	 * @dev Requires sender to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @dev Throws on overflow, if totalSupply + _value doesn't fit into uint256
	 *
	 * @param _to an address to mint tokens to
	 * @param _value an amount of tokens to mint (create)
	 */
	function mint(address _to, uint256 _value) public override onlyRole(ModaConstants.ROLE_TOKEN_CREATOR) {
		// non-zero recipient address check
		require(_to != address(0), 'ERC20: mint to the zero address'); // Zeppelin msg
		if (_value == 0) return;

		// non-zero _value and arithmetic overflow check on the total supply
		// this check automatically secures arithmetic overflow on the individual balance
		require(totalSupply() + _value > totalSupply(), 'zero value mint or arithmetic overflow');

		// uint256 overflow check (required by voting delegation)
		require(totalSupply() + _value <= type(uint192).max, 'total supply overflow (uint192)');

		// perform mint with ERC20 transfer event
		_mintWithCount(_to, _value);
	}

	/**
	 * @dev ERC20 transfer function. Overridden to maintain holder count variable.
	 */
	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_updateCountOnTransfer(_msgSender(), recipient, amount);
		return super.transfer(recipient, amount);
	}

	/**
	 * @dev ERC20 transferFrom function. Overridden to maintain holder count variable.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_updateCountOnTransfer(sender, recipient, amount);
		return super.transferFrom(sender, recipient, amount);
	}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @dev Interface for a token that will allow mints from a vesting contract
 */
interface IMintableToken {
	function mint(address to, uint256 amount) external;
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

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /*
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
library StorageSlotUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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