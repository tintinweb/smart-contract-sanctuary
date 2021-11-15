// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./access/AccessControlEnumerable.sol";
import "./token/IERC20.sol";
import "./token/IERC20Mintable.sol";
import "./security/ReentrancyGuard.sol";
import "./security/Pausable.sol";
import "./utils/Address.sol";
import "./utils/Context.sol";
import "./staking/Sigmoid.sol";

/**
 * @title Staking
 *
 * TODO
 */
contract Staking is Context, Pausable, AccessControlEnumerable, ReentrancyGuard {
	using Address for address;

	/**
	 * @dev Emitted when a user deposits tokens.
	 * @param sender User address
	 * @param poolIdentifier Pool's unique ID
	 * @param depositIdentifier User's unique deposit ID
	 * @param startTime Time when deposit was created
	 * @param amount Depsoited balance
	 */
	event Deposited(
		address indexed sender, 
		uint256 indexed poolIdentifier, 
		uint256 depositIdentifier, 
		uint256 startTime, 
		uint256 amount
	);
	
	/**
	 * @dev Emitted when a user claims tokens back.
	 * @param sender User address
	 * @param poolIdentifier Pool's unique ID
	 * @param depositIdentifier User's unique deposit ID
	 * @param releaseTime Time when claim was created
	 * @param amount Claimed balance
	 * @param delay Additional lock period
	 */
	event Claimed(
		address indexed sender, 
		uint256 indexed poolIdentifier, 
		uint256 depositIdentifier, 
		uint256 releaseTime, 
		uint256 amount, 
		uint256 delay
	);

	
	/**
	 * @dev Emitted when new tokens minted as a reward.
	 * @param receiver User address
	 * @param poolIdentifier Pool's unique ID
	 * @param amount Amount of new issuance
	 */
	event Minted(
		address indexed receiver, 
		uint256 indexed poolIdentifier, 
		uint256 amount
	);

	/**
	 * @dev Emitted when a user withdraws tokens back to her wallet.
	 * @param receiver User address
	 * @param poolIdentifier Pool's unique ID
	 * @param depositIdentifier User's unique deposit ID
	 * @param amount Withdrawn balance
	 */
	event Withdrawn(
		address indexed receiver, 
		uint256 indexed poolIdentifier, 
		uint256 indexed depositIdentifier, 
		uint256 amount
	);

	/**
	 * @dev Emitted when a user force withdraw.
	 * @param receiver User address
	 * @param poolIdentifier Pool's unique ID
	 * @param depositIdentifier User's unique deposit ID
	 * @param amount Tokens to be withdrawn
	 */
	event EmergencyWithdrawn(
		address indexed receiver, 
		uint256 indexed poolIdentifier, 
		uint256 indexed depositIdentifier, 
		uint256 amount
	);

	/**
	 * @dev Emitted when a new pool added.
	 * @param admin Admin address
	 * @param poolIdentifier Pool's unique ID
	 * @param liquidityPool Token address for incoming token
	 * @param multiplicator Coeficient for internal and LP tokens 
	 * @param sigmoidA Numerator factor, sigmoid height
	 * @param sigmoidB Minimal lock period
	 * @param sigmoidC Denominator factor, increase rate for sigmoid
	 */
	event PoolAdded(
		address indexed admin, 
		uint256 indexed poolIdentifier, 
		address liquidityPool, 
		uint256 multiplicator, 
		uint256 sigmoidA, 
		int256 sigmoidB, 
		uint256 sigmoidC
	);

	/**
	 * @dev Emitted when a pool multiplicator updated.
	 * @param admin Admin address
	 * @param poolIdentifier Pool's unique ID
	 * @param newPoolMultiplicator New coeficient for internal and LP tokens 
	 */
	event PoolMultiplicatorUpdated(
		address indexed admin, 
		uint256 indexed poolIdentifier, 
		uint256 newPoolMultiplicator
	);

	/**
	 * @dev Emitted when a pool sigmoid parameters get updated.
	 * @param admin Admin address
	 * @param poolIdentifier Pool's unique ID
	 * @param newSigmoidA New numerator factor, sigmoid height
	 * @param newSigmoidB New minimal lock period
	 * @param newSigmoidC New denominator factor, increase rate for sigmoid
	 */
	event PoolSigmoidParametersUpdated(
		address indexed admin, 
		uint256 indexed poolIdentifier, 
		uint256 newSigmoidA, 
		int256 newSigmoidB, 
		uint256 newSigmoidC
	);

	/**
	 * @dev Emitted when admin rescues some 'limbo' funds.
	 * @param admin Admin address
	 * @param receiver User address, which gets tokens
	 * @param asset Address of a rescued token
	 * @param amount Amount of rescued tokens 
	 */
	event AssetsRescued(address indexed admin, address indexed receiver, address asset, uint256 amount);
	
	/**
	 * @dev Set reward token address
	 *
	 * @param admin Admin address
	 * @param tokenAddress New address of new token
	 */
	event TokenSet(address indexed admin, address indexed tokenAddress);

	bytes32 public constant PAUSER_ROLE        = keccak256("PAUSER_ROLE");
	bytes32 public constant OWNER_ROLE         = keccak256("OWNER_ROLE");
	
	struct DepositInfo {
		uint256 amount;            // how many LP tokens user provided
		uint256 depositDate;       // block number when deposited
		uint256 claims;            // claimed amount of ERC20s tokens
		uint256 claimedDate;       // block number when tokens become availiable
	}

	struct PoolInfo {
		address lpToken;           // Address of LP token contract
		uint256 totalStaked;       // Total amount of tokens in pool in the moment
		uint256 multiplicator;     // pool MAD multiplicator
		Sigmoid sigmoid;           // Sigmoid value for the pool
	}

	address private _token;
	uint256 private _totalEmissioned = 0;
    PoolInfo[] private _poolInfo;
    mapping (uint256 => mapping (address =>  mapping (uint256 => DepositInfo))) private _depositInfo;
    mapping (address => uint256) private _deposits;
	uint256 private _minimumClaimWait = 60 minutes;

    modifier depositExists(uint256 _pid, uint256 _id, address _who) {
    	require(_id <=  _deposits[_who], "MadStaking: depositExists bad id parameter");
		require(_pid <= _poolInfo.length, "MadStaking: depositExists bad pid parameter");
    	_;
    }

    modifier poolExists (uint256 _pid) {
    	require(_pid <= _poolInfo.length, "MadStaking: poolExists bad pid parameter");
    	_;
    }

    /**
     * @dev Initialize the smart contract. By default Liquidity Pool is empty, admin should add as much
     * as she wants to add. Transaction sender gets admin role, owner role and pauser role.
     *
     * Requirements:
     *	- _tokenAddress must be a smart contract address
     *
     * @param _tokenAddress Address of internal token that will be minted as reward
     */
    constructor (address _tokenAddress) {
        require(_tokenAddress.isContract(), "MadStaking: not a contract address for MDB");

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
       
        require(_setToken(_tokenAddress), "MadStaking: internal error occured");
    }

	/**
	 * @dev Returns amount of pools.
	 */
	function poolLength() public view returns (uint256) {
		return _poolInfo.length;
	}

	/**
	 * @dev Returns time for minimum claim wait
	 */
	function minimumClaimWait() public view returns (uint256) {
		return _minimumClaimWait;
	}

	/**
	 * @dev Returns total emissioned internal tokens.
	 */
	function totalEmission() public view returns (uint256) {
		return _totalEmissioned;
	}

	/**
	 * @dev Returns internal token address.
	 */
	function token() public view returns (address) {
		return _token;
	}

	/**
	 * @dev Returns amount of deposits for the sender address.
	 */
	function depositLength(address _who) public view returns (uint256) {
		return _deposits[_who];
	}

	/**
	 * @dev Returns full information of the existant pool.
	 * @param _pid Pool unique ID
	 */
	function poolInfo(uint256 _pid) public view poolExists(_pid) returns (PoolInfo memory) {
		return _poolInfo[_pid];
	}

	/**
	 * @dev Returns full deposit information.
	 * @param _pid Pool unique ID
	 * @param _id Unique user's deposit ID
	 */
	function depositInfo(uint256 _pid, uint256 _id, address _who) public view depositExists(_pid, _id, _who) returns(DepositInfo memory) {
		return _depositInfo[_pid][_who][_id];
	}

	/**
	 * @dev Returns sigmoid parameters.
	 * @param _pid Pool unique ID
	 */
    function sigmoidParameters(uint256 _pid) public view poolExists(_pid) returns (uint256 a, int256 b, uint256 c) {
        return poolInfo(_pid).sigmoid.getParameters();
    }

    function multiplicatorParameter(uint256 _pid) public view poolExists(_pid) returns (uint256) {
    	return poolInfo(_pid).multiplicator;
    }

	/**
	 * @dev Calculate emission for the specific parameters. This function uses sigmoid and
	 * specific formula `MAD_AMOUNT * (SIGMOID_RES / 100) * (MULTIPLICATOR + DELAY_IN_BLOCKS)`
	 *
	 * @param _pid Pool unique ID
	 * @param _id Unique user's deposit ID
	 * @param _amount Amount of staked tokens to claim back
	 * @param _delay Additional number of blocks to wait before withdraw  
	 */
    function getEmission(uint256 _pid, uint256 _id, address _who, uint256 _amount, uint256 _delay) public view depositExists(_pid, _id, _who) returns (uint256) {
		
		DepositInfo memory currentDeposit = depositInfo(_pid, _id, _who);
		require(currentDeposit.amount >= _amount, "MadStaking: getEmission insufficient funds");
        if (currentDeposit.depositDate <= 0 || currentDeposit.depositDate > _now()) return 0;

		uint256 timePassed = _now() - depositInfo(_pid, _id, _who).depositDate;
        if (timePassed == 0) return 0;

		PoolInfo memory currentPool = poolInfo(_pid);
        // MDB_AMOUNT = MAD_AMOUNT * SIGMOID_RES(TIME_PASSED + 2 * MULTIPLICATOR * EXPECTED_DELAY) * MULTIPLICATOR
        uint256 userEmissionRate = _amount * 
			poolInfo(_pid).sigmoid.calculate(int256(timePassed) + int256(2 * currentPool.multiplicator * _delay)) * 
			currentPool.multiplicator;
		if (userEmissionRate == 0) return 0;

		return userEmissionRate;
    }

	/**
	 * @dev Provides user possibility to deposit tokens into smart contract
	 *
	 * @param _pid Pool unique ID
	 * @param _amount Amount of user's tokens to deposit
	 */
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant whenNotPaused poolExists(_pid) returns (bool) {
    	require(!paused(), "MadStaking: deposit staking on pause");
		require(_amount > 0, "MadStaking: deposit amount should be greater than zero");
    	address depositedToken = poolInfo(_pid).lpToken;
    	require(IERC20(depositedToken).balanceOf(_msgSender()) >= _amount, "MadStaking: deposit insufficient funds");
    	require(IERC20(depositedToken).allowance(_msgSender(), address(this)) >= _amount, "MadStaking: deposit not enough allowance");
        require(IERC20(depositedToken).transferFrom(_msgSender(), address(this), _amount), "MadStaking: deposit transfer failed");
        
        require(_deposit(_pid, _amount), "MadStaking: deposit internal error occured");

		return true;
    }

    /**
     * @dev Provides user possibility to lock deposited tokens
     * for some period of time and get newly minted internal tokens.
     *
     * @param _pid Pool unique ID
     * @param _id Unique user's deposit ID
     * @param _amount Amount of LP tokens to be locked
     * @param _delay Additional number of blocks to wait before withdraw
     */
	function claim(uint256 _pid, uint256 _id, uint256 _amount, uint256 _delay) external nonReentrant depositExists(_pid, _id, _msgSender()) returns (bool) {
		require(depositInfo(_pid, _id, _msgSender()).amount >= _amount, "MadStaking: claim not enough balance");

		uint256 timePassed = _now() - depositInfo(_pid, _id, _msgSender()).depositDate;
		require(timePassed >= 0, "MadStaking: claim the has not come yet");

		uint256 issuance = getEmission(_pid, _id, _msgSender(), _amount, _delay);
		require(issuance > 0, "MadStaking: claim nothing to mint");

		require(_claim(_pid, _id, _amount, _delay), "MadStaking: claim internal error occured");

		if (!paused()) {
			 require(_mint(_pid, issuance), "MadStaking: claim minting error occured");
		}
		
		return true;
	}

	/**
	 * @dev Provides user possibility to withdraw claimed tokens.
	 *
	 * @param _pid Pool unique ID
	 * @param _id Unique user's deposit ID
	 * @param _amount Amount of unlocked tokens to withdraw
	 */
    function withdraw(uint256 _pid, uint256 _id, uint256 _amount) external nonReentrant depositExists(_pid, _id, _msgSender()) returns (bool) {
    	require(depositInfo(_pid, _id, _msgSender()).claims >= _amount, "MadStaking: withdraw not enough claimed balance");
    	require(depositInfo(_pid, _id, _msgSender()).claimedDate <= _now(), "MadStaking: withdraw claim not ready yet");

		require(_withdraw(_pid, _id, _amount), "MadStaking: withdraw internal error occured");

		return true;
    }

	/**
	 * @dev Provides user possibility to withdraw deposited tokens.
	 * No newly internal tokens will be minted. Just get back LP tokens
	 * right in the moment.
	 *
	 * @param _pid Pool unique ID
	 * @param _id Unique user's deposit ID
	 */
    function emergencyWithdraw(uint256 _pid, uint256 _id) external nonReentrant depositExists(_pid, _id, _msgSender()) returns (bool) {
    	require(depositInfo(_pid, _id, _msgSender()).amount > 0, "MadStaking: emergencyWithdraw insufficient funds to withdraw");
    	require(_emergencyWithdraw(_pid, _id), "MadStaking: emergencyWithdraw internal error occured");

    	return true;
    }


	/* ================ Owner Functions ================ */
	
	/* ================     1. Pools    ================ */

	/**
	 * @dev New pool pushed to the PoolInfo array.
	 *
	 * @param _lpToken Liquidity token address
	 * @param _multiplicator Coeficient for internal and LP tokens
	 * @param _a Sigmoid parameter A
	 * @param _b Sigmoid parameter B
	 * @param _c Sigmoid parameter C
	 */
	function addPool(address _lpToken, uint256 _multiplicator, uint256 _a, int256 _b, uint256 _c) external onlyRole(OWNER_ROLE) returns (bool) {
		require(_b > 0, "MadStaking: addPool parameter B must be greater than zero");
		require(_c > 0, "MadStaking: addPool parameter C must be greater than zero");
		require(_lpToken.isContract(), "MadStaking: addPool address should be smart contract");
		for (uint256 pid = 0; pid < poolLength(); pid++) {
			// in order to avoid pool duplications
			require(_poolInfo[pid].lpToken != _lpToken, "MadStaking: addPool address for new lp token exists");
		}

        _poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            totalStaked: 0,
            multiplicator: _multiplicator,
            sigmoid: new Sigmoid(_a,_b,_c)
        }));

        emit PoolAdded(_msgSender(), poolLength(), address(_lpToken), _multiplicator, _a, _b, _c);

        return true;
    }

    /**
     * @dev Update multiplicator for the existent pool.
     *
     * @param _pid Pool's unique ID
     * @param _multiplicator New coeficient for internal and LP tokens
     */
    function updatePoolMultiplicator(uint256 _pid, uint256 _multiplicator) external onlyRole(OWNER_ROLE) poolExists(_pid) returns (bool) {
    	_poolInfo[_pid].multiplicator = _multiplicator;
    	emit PoolMultiplicatorUpdated(_msgSender(), _pid, _multiplicator);
    	return true;
    }

    /**
     * @dev Update sigmoid parameters for the existent pool.
     *
     * @param _pid Pool's unique ID
	 * @param _a Sigmoid parameter A
	 * @param _b Sigmoid parameter B
	 * @param _c Sigmoid parameter C
     */
    function updatePoolSigmoidParameters(uint256 _pid, uint256 _a, int256 _b, uint256 _c) external onlyRole(OWNER_ROLE) poolExists(_pid) returns (bool) {
    	require(_b != 0, "MadStaking: updatePoolSigmoidParameters parameter B must be greater than zero");
    	_poolInfo[_pid].sigmoid.setParameter(_a, _b, _c);
    	emit PoolSigmoidParametersUpdated(_msgSender(), _pid, _a, _b, _c );
    	return true;
    }

	/* ================     2. Other    ================ */

	/**
	 * @dev Funtionality to set minimum claim wait
	 *
	 * @param _newTime Time in seconds to wait
	 */
	function setMinimumClaimWait(uint256 _newTime) external onlyRole(OWNER_ROLE) returns (bool) {
		require(_newTime > 20, "MadStaking: setMinimumClaimWait time must be greater");
		_minimumClaimWait = _newTime;
		return true;
	}

	/**
	 * @dev Functionality to rescue locked funds in 'limbo'. If user occasionally will send
	 * any EIP-20 applicable token or ether to this smart contract, admin can manually send
	 * them back.
	 *
	 * @param _rescueToken Address of the token to be rescued
	 * @param _to Address where tokens should be transfered
	 * @param _amount Amount of tokens to be transfered
	 */
    function rescueFunds(address _rescueToken, address payable _to, uint256 _amount) external onlyRole(OWNER_ROLE) returns (bool) {
        require(_to != address(0) && _to != address(this), "MadStaking: rescueFunds not a valid recipient");
        require(_amount > 0, "MadStaking: rescueFunds amount should be greater than 0");
		
		if (_rescueToken == address(0)) {
			_to.transfer(_amount);
		} else {
			for (uint256 i = 0; i < poolLength(); i = i + 1) {
				if (poolInfo(i).lpToken == _rescueToken) {
					_amount = IERC20(poolInfo(i).lpToken).balanceOf(address(this)) - poolInfo(i).totalStaked;
				}
			}
        	require(_amount > 0, "MadStaking: rescueFunds insufficient funds to rescue");
			IERC20(_rescueToken).transfer(_to, _amount);
		}

        emit AssetsRescued(_msgSender(), _to, _rescueToken, _amount);

        return true;
    }

    /**
     * @dev Set internal token (reward token).
     * @param _newToken New address to be set
     */
    function setToken(address _newToken) external onlyRole(OWNER_ROLE) returns (bool) {
    	require(_setToken(_newToken), "MadStaking: setToken internal error occured");
    	return true;
    }

	/**
	 * @dev Pause smart contract
	 */
	function pause() external onlyRole(PAUSER_ROLE) whenNotPaused() returns (bool) {
		_pause();
		return true;
	}

	/**
	 * @dev Unause smart contract
	 */
	function unpause() external onlyRole(PAUSER_ROLE) whenPaused() returns (bool) {
		_unpause();
		return true;
	}

	/* ================ Internal Functions ================ */

	/**
	 * @dev Create new deposit for the sender address.
	 *
	 * @param _pid Pools' unique ID
	 * @param _amount Amount of tokens to deposit
	 */
    function _deposit(uint256 _pid, uint256 _amount) private returns (bool) {
    	uint256 depositId = depositLength(_msgSender()) + 1;
        _deposits[_msgSender()] = depositId;
        _depositInfo[_pid][_msgSender()][depositId] = DepositInfo({
        	amount: _amount, 
        	depositDate: _now(), 
        	claims: 0, 
        	claimedDate: 0
        });
        _poolInfo[_pid].totalStaked += _amount;

        emit Deposited(_msgSender(), _pid, depositId, _now(), _amount);

        return true;
    }

    /**
     * @dev Create new claim for the existent deposit.
     *
     * @param _pid Pool's unique ID
     * @param _id User's unique deposit ID
     * @param _amount Amount of LP tokens to lock
     * @param _delay Additional lock period
     */
    function _claim(uint256 _pid, uint256 _id, uint256 _amount, uint256 _delay) private returns (bool) {
    	_depositInfo[_pid][_msgSender()][_id].amount -= _amount;
		_depositInfo[_pid][_msgSender()][_id].claims += _amount;
		_depositInfo[_pid][_msgSender()][_id].claimedDate = _now() + _minimumClaimWait + _delay;
		_poolInfo[_pid].totalStaked -= _amount;

		emit Claimed(_msgSender(), _pid, _id, _now(), _amount, _delay);

		return true;
    }

    /**
     * @dev Mint reward tokens and increase total emission.
     *
     * @param _pid Pool's unique ID
     * @param _issuance Amount of tokens to be minted
     */
    function _mint(uint256 _pid, uint256 _issuance) private returns (bool) {
    	require(IERC20Mintable(token()).mint(_msgSender(), _issuance), "MadStaking: claim can not mint");
		_totalEmissioned += _issuance;
		
		emit Minted(_msgSender(), _pid, _issuance);

		return true;
    }

    /**
     * @dev Transfer unlocked tokens to the deposit owner.
     *
     * @param _pid Pool's unqiue ID
     * @param _id User's unique deposit ID
     * @param _amount Amount of tokens to be withdrawn
     */
    function _withdraw(uint256 _pid, uint256 _id, uint256 _amount) private returns (bool) {
    	_depositInfo[_pid][_msgSender()][_id].claims -= _amount;
    	IERC20(poolInfo(_pid).lpToken).transfer(_msgSender(), _amount);

    	emit Withdrawn(_msgSender(), _pid, _id, _amount);

    	return true;
    }

    /**
     * @dev Transfer LP tokens with decreasing of pool's total staked field.
     *
     * @param _pid Pool's unqiue ID
     * @param _id User's unique deposit ID
     */
    function _emergencyWithdraw(uint256 _pid, uint256 _id) private returns (bool) {
    	uint256 amount = depositInfo(_pid, _id, _msgSender()).amount;
		require(amount > 0, "MadStaking: _emergencyWithdraw insufficient funds");
    	_depositInfo[_pid][_msgSender()][_id].amount -= amount;
		_poolInfo[_pid].totalStaked -= amount;
    	IERC20(poolInfo(_pid).lpToken).transfer(_msgSender(), amount);

    	emit EmergencyWithdrawn(_msgSender(), _pid, _id, amount);

    	return true;
    }

    /**
     * @dev Sets internal/reward token for current smart contract.
     * @param _newToken New token address
     */
    function _setToken(address _newToken) private returns (bool) {
    	require(_newToken.isContract(), "MadStaking: _setToken address is not a contract");
    	_token = _newToken;
		emit TokenSet(_msgSender(), _newToken);
    	return true;
    }

    /**
     * @dev Gets current block's timestamp as seconds since unix epoch
     */
    function _now() private view returns (uint256) {
        return uint256(block.timestamp); 
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

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor () {
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

pragma solidity 0.8.0;

// Should be contract
contract Sigmoid {

	// the period after which the new value of the parameter is set
	uint256 public constant PARAM_UPDATE_DELAY = 20;

	struct Params {
		uint256 a;
	   	int256 b;
	   	uint256 c;
   	}

	struct State {
		Params oldParams;
		Params newParams;
		uint256 timestamp;
	}
    
    Params private _params;
    State private _state;
    address private _owner;
    
    modifier onlyCreator() {
        require(msg.sender == _owner, "MadStaking: sigmoid not owner");
        _;
    }
    
    constructor (uint256 _a, int256 _b, uint256 _c) {
        _state.oldParams = Params(_a, _b, _c);
        _state.newParams = Params(_a, _b, _c);
		_state.timestamp = block.timestamp;
        _owner = msg.sender;
    }
    
	/**
	 * @dev Sets sigmoid parameters
	 * @param _a - sigmoid's parameter A.
	 * @param _b - sigmoid's parameter B.
	 * @param _c - sigmoid's parameter C.
	 */
	function setParameter(uint256 _a, int256 _b, uint256 _c) public onlyCreator {
		require(_c != 0, "MadStaking: 'C' should be greater than 0");
		uint256 currentTimestamp = block.timestamp;
		if (_state.timestamp == 0) {
			_state.oldParams = Params(_a, _b, _c);
		} else if (currentTimestamp > _state.timestamp + PARAM_UPDATE_DELAY) {
			_state.oldParams = _state.newParams;
		}

		_state.newParams = Params(_a, _b, _c);
		_state.timestamp = currentTimestamp;
	}

	/**
	 * @return Sigmoid parameters
	 */
	function getParameters() public view onlyCreator returns(uint256, int256, uint256) {
		bool isUpdated = block.timestamp > _state.timestamp + PARAM_UPDATE_DELAY;
		return isUpdated ?
			(_state.newParams.a, _state.newParams.b, _state.newParams.c) :
			(_state.oldParams.a, _state.oldParams.b, _state.oldParams.c);
	}

	/**
	 * @return The corresponding Y value for a given X value
	 */
	function calculate(int256 _x) public view onlyCreator returns (uint256) {
		(uint256 a, int256 b, uint256 c) = getParameters();
		int256 k = _x - b;
		if (k < 0) return 0;
		uint256 uk = uint256(k);
		return (a * uk) / sqrt(pow2(uk) + c);
	}

	/* ========== Extended Math ========== */

	/**
	 * @return The given number to the power of 2
	 */
	function pow2(uint256 a) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * a;
		// never should happen because of solc 0.8.0
		assert (c / a == a);
		return c;
	}

	/**
	 * @return The square root of the given number
	 */
	function sqrt(uint y) internal pure returns (uint) {
	    uint z = 1;
		if (y > 3) {
			z = y;
			uint x = y / 2 + 1;
			while (x < z) {
				 z = x;
				 x = (y / x + x) / 2;
			}
		}
		
		return z;
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
	 * @dev Mint some additional tokens to `recipient` address.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event from zero address to `recipient`.
	 */

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
  
pragma solidity 0.8.0;

interface IERC20Mintable {
	/**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
	function mint(address account, uint256 amount) external returns (bool);
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
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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

