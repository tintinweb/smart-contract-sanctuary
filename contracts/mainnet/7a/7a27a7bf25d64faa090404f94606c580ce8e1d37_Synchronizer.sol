/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// Be name Khoda
// Bime Abolfazl

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol



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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol



pragma solidity ^0.8.0;



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

// File: synchronizer.sol



pragma solidity 0.8.3;


interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Registrar {
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
}


contract Synchronizer is AccessControl {
	// roles
	bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
	bytes32 public constant FEE_WITHDRAWER_ROLE = keccak256("FEE_WITHDRAWER_ROLE");
	bytes32 public constant COLLATERAL_WITHDRAWER_ROLE = keccak256("COLLATERAL_WITHDRAWER_ROLE");
	bytes32 public constant REMAINING_DOLLAR_CAP_SETTER_ROLE = keccak256("REMAINING_DOLLAR_CAP_SETTER_ROLE");

	// variables
	uint256 public minimumRequiredSignature;
	IERC20 public collateralToken;
	uint256 public remainingDollarCap;
	uint256 public scale = 1e18;
	uint256 public withdrawableFeeAmount;

	// events
	event Buy(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event Sell(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event WithdrawFee(uint256 amount, address recipient);
	event WithdrawCollateral(uint256 amount, address recipient);

	constructor (
		uint256 _remainingDollarCap,
		uint256 _minimumRequiredSignature,
		address _collateralToken
	)
	{
		remainingDollarCap = _remainingDollarCap;
		minimumRequiredSignature = _minimumRequiredSignature;
		collateralToken = IERC20(_collateralToken);

		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(FEE_WITHDRAWER_ROLE, msg.sender);
		_setupRole(COLLATERAL_WITHDRAWER_ROLE, msg.sender);
	}

	function setMinimumRequiredSignature(uint256 _minimumRequiredSignature) external {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
		minimumRequiredSignature = _minimumRequiredSignature;
	}

	function setCollateralToken(address _collateralToken) external {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
		collateralToken = IERC20(_collateralToken);
	}

	function setRemainingDollarCap(uint256 _remainingDollarCap) external {
		require(hasRole(REMAINING_DOLLAR_CAP_SETTER_ROLE, msg.sender), "Caller is not a remainingDollarCap setter");
		remainingDollarCap = _remainingDollarCap;
	}

	function sellFor(
		address _user,
		uint256 multiplier,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256[] memory blockNos,
		uint256[] memory prices,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	)
		external
	{
		uint256 price = prices[0];
		address lastOracle;

		for (uint256 index = 0; index < minimumRequiredSignature; ++index) {
			require(blockNos[index] >= block.number, "Signature is expired");
			if(prices[index] < price) {
				price = prices[index];
			}
			address oracle = getSigner(registrar, 2, multiplier, fee, blockNos[index], prices[index], v[index], r[index], s[index]);
			require(hasRole(ORACLE_ROLE, oracle), "signer is not an oracle");

			require(oracle > lastOracle, "Signers are same");
			lastOracle = oracle;
		}

		//---------------------------------------------------------------------------------

		uint256 collateralAmount = amount * price / scale;
		uint256 feeAmount = collateralAmount * fee / scale;

		remainingDollarCap = remainingDollarCap + (collateralAmount * multiplier);

		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		Registrar(registrar).burn(msg.sender, amount);

		collateralToken.transfer(_user, collateralAmount - feeAmount);

		emit Sell(_user, registrar, amount, collateralAmount, feeAmount);
	}

	function buyFor(
		address _user,
		uint256 multiplier,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256[] memory blockNos,
		uint256[] memory prices,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	)
		external
	{
		uint256 price = prices[0];
        address lastOracle;
        
		for (uint256 index = 0; index < minimumRequiredSignature; ++index) {
			require(blockNos[index] >= block.number, "Signature is expired");
			if(prices[index] > price) {
				price = prices[index];
			}
			address oracle = getSigner(registrar, 3, multiplier, fee, blockNos[index], prices[index], v[index], r[index], s[index]);
			require(hasRole(ORACLE_ROLE, oracle), "Signer is not an oracle");

			require(oracle > lastOracle, "Signers are same");
			lastOracle = oracle;
		}

		//---------------------------------------------------------------------------------
		uint256 collateralAmount = amount * price / scale;
		uint256 feeAmount = collateralAmount * fee / scale;

		remainingDollarCap = remainingDollarCap - (collateralAmount * multiplier);
		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		collateralToken.transferFrom(msg.sender, address(this), collateralAmount + feeAmount);

		Registrar(registrar).mint(_user, amount);

		emit Buy(_user, registrar, amount, collateralAmount, feeAmount);
	}

	function getSigner(
		address registrar,
		uint256 isBuy,
		uint256 multiplier,
		uint256 fee,
		uint256 blockNo,
		uint256 price,
		uint8 v,
		bytes32 r,
		bytes32 s
	)
		pure
		internal
		returns (address)
	{
        bytes32 message = prefixed(keccak256(abi.encodePacked(registrar, isBuy, multiplier, fee, blockNo, price)));
		return ecrecover(message, v, r, s);
    }

	function prefixed(
		bytes32 hash
	)
		internal
		pure
		returns(bytes32)
	{
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

	//---------------------------------------------------------------------------------------

	function withdrawFee(uint256 _amount, address _recipient) external {
		require(hasRole(FEE_WITHDRAWER_ROLE, msg.sender), "Caller is not a FeeWithdrawer");

		withdrawableFeeAmount = withdrawableFeeAmount - _amount;
		collateralToken.transfer(_recipient, _amount);

		emit WithdrawFee(_amount, _recipient);
	}

	function withdrawCollateral(uint256 _amount, address _recipient) external {
		require(hasRole(COLLATERAL_WITHDRAWER_ROLE, msg.sender), "Caller is not a CollateralWithdrawer");

		collateralToken.transfer(_recipient, _amount);

		emit WithdrawCollateral(_amount, _recipient);
	}

}

//Dar panah khoda