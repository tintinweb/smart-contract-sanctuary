// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;
pragma abicoder v2;


import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDEIPool {
    function mintFractionalDEI(
		uint256 collateral_amount,
		uint256 deus_amount,
		uint256 collateral_price,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external;
}

interface IDEIStablecoin {
    function global_collateral_ratio() external view returns (uint256);
}

interface IUniswapV2Router02 {
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
	function getAmountsOut(
		uint amountIn, 
		address[] memory path
	) external view returns (uint[] memory amounts);
}


contract SSP is AccessControl {
	bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
	bytes32 public constant SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
	bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
	
    struct ProxyInput {
		uint256 collateral_price;
		uint256 deus_price;
		uint256 expire_block;
        uint min_amount_out;
		bytes[] sigs;
    }
    
    /* ========== STATE VARIABLES ========== */

	address public dei_address;
	address public usdc_address;
	address public deus_address;
	address public dei_pool;
	address public uniswap_router;
	address[] public usdc2deus_path;
	address[] public dei2deus_path;
	address[] public dei2usdc_path;
	address[] public usdc2dei_path;
    uint public while_times;
	uint public usdc_scale = 1e6;
	uint public ratio;
	
    uint public fee = 1e16;
    uint public fee_scale = 1e18;
	uint public scale = 1e6; // scale for price
	uint public usdc_missing_decimals_d18 = 1e12; // missing decimal of collateral token
	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;


	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _dei_address, 
		address _usdc_address,
		address _deus_address, 
		address _dei_pool, 
		address _uniswap_router,
		address[] memory _usdc2deus_path,
		address[] memory _dei2usdc_path, 
		address[] memory _usdc2dei_path, 
		address[] memory _dei2deus_path,
		address swapper_address,
		address trusty_address
	) {
		dei_address = _dei_address;
		usdc_address = _usdc_address;
		deus_address = _deus_address;
		dei_pool = _dei_pool;
		uniswap_router = _uniswap_router;
		usdc2deus_path = _usdc2deus_path;
		dei2usdc_path = _dei2usdc_path;
		usdc2dei_path = _usdc2dei_path;
		dei2deus_path = _dei2deus_path;
		while_times = 2;
		IERC20(usdc_address).approve(_uniswap_router, type(uint256).max);
		IERC20(dei_address).approve(_uniswap_router, type(uint256).max);
		IERC20(usdc_address).approve(_dei_pool, type(uint256).max);
		IERC20(deus_address).approve(_dei_pool, type(uint256).max);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		grantRole(SWAPPER_ROLE, swapper_address);
		grantRole(TRUSTY_ROLE, trusty_address);

	}


    function swap(uint usdc_amount) public returns (uint amount) {
        require(hasRole(SWAPPER_ROLE, msg.sender), "Caller is not a swapper");
        amount = usdc_amount * usdc_missing_decimals_d18 * (fee_scale - fee) / fee_scale;

        IERC20(dei_address).transfer(msg.sender, amount);
    }
    
    function getAmountIn(uint dei_amount) public view returns(uint) {
        require(hasRole(SWAPPER_ROLE, msg.sender), "Caller is not a swapper");
        uint usdc_amount = dei_amount * fee_scale / ((fee_scale - fee) * usdc_missing_decimals_d18);
        return usdc_amount;
    }

	function usdcToDeus(uint usdc_amount) internal returns(uint) {
		uint min_amount_deus = calcUsdcToDeus(usdc_amount);
		uint dei_amount = usdc_amount * ratio / (usdc_scale - ratio);
        uint[] memory deus_arr = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(dei_amount, min_amount_deus, dei2deus_path, msg.sender, deadline);
        return deus_arr[deus_arr.length - 1];
	}

	function calcUsdcToDeus(uint usdc_amount) public view returns(uint){
		uint dei_amount = usdc_amount * ratio / (usdc_scale - ratio);
		uint[] memory amount_out =IUniswapV2Router02(uniswap_router).getAmountsOut(dei_amount, dei2deus_path);
		return amount_out[amount_out.length -1];
	}

	function setwhileTimes(uint _while_times) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		while_times = _while_times;
	}

	function setScale(uint _scale) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		scale = _scale;
	}
	
	function setFee(uint _fee) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		fee = _fee;
	}
	
	function setFeeScale(uint _fee_scale) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		fee_scale = _fee_scale;
	}


	function setRatio(uint _ratio) external {
	    require(hasRole(SETTER_ROLE, msg.sender), "Caller is not a setter");
		ratio = _ratio;
	}
    
	
	function refill(ProxyInput memory proxy_input, uint usdc_amount, uint excess_deus) public {
	    require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not a operator");
	    
		uint collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
    
        require(collateral_ratio > 0 && collateral_ratio < scale, "collateral ratio is not valid");
        
        uint usdc_to_dei = getAmountsInUsdcToDei(collateral_ratio, usdc_amount, proxy_input.deus_price);
        uint usdc_to_deus = (usdc_to_dei * (scale - collateral_ratio) / collateral_ratio) + excess_deus;
        
        // usdc to deus
        uint min_amount_deus = getAmountsOutUsdcToDeus(usdc_to_deus);
        uint[] memory deus_arr = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(usdc_to_deus, min_amount_deus, usdc2deus_path, address(this), deadline);
        uint deus = deus_arr[deus_arr.length - 1];

        // usdc , deus to dei
        IDEIPool(dei_pool).mintFractionalDEI(
				usdc_to_dei,
				deus,
				proxy_input.collateral_price,
				proxy_input.deus_price,
				proxy_input.expire_block,
				proxy_input.sigs
			);

        // fix arbitrage
        uint[] memory usdc_arr = IUniswapV2Router02(uniswap_router).swapTokensForExactTokens(usdc_to_deus, type(uint256).max , dei2usdc_path, address(this), deadline);
        uint usdc_earned = usdc_arr[usdc_arr.length - 1];

		emit Mint(usdc_to_dei,deus,usdc_earned);
	}
	
	
	function getAmountsInUsdcToDei(uint collateral_ratio, uint usdc_amount, uint deus_price) public view returns(uint) {
		uint usdc_to_dei;
		uint times = while_times;
		while(times > 0) {
			uint usdc_for_swap = usdc_amount * collateral_ratio / scale;
			
			uint usdc_given_to_pairs = usdc_amount - usdc_for_swap;
			uint deus_amount = getAmountsOutUsdcToDeus(usdc_given_to_pairs);

			uint deus_to_usdc = (deus_amount * deus_price) / (scale * usdc_missing_decimals_d18);
			uint usdc_needed = collateral_ratio * deus_to_usdc / (scale - collateral_ratio);
			
			usdc_to_dei += usdc_needed;
			
			usdc_amount -= usdc_given_to_pairs + usdc_needed;
			times -= 1;
		}
		return usdc_to_dei;
	}
	
	
	function getAmountsOutUsdcToDeus(uint usdc_amount) public view returns(uint) {
	    uint[] memory amount_out =IUniswapV2Router02(uniswap_router).getAmountsOut(usdc_amount, usdc2deus_path);
		return amount_out[amount_out.length -1];
	}
	
	function emergencyWithdrawERC20(address token, address to, uint amount) external {
	    require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
		IERC20(token).transfer(to, amount);
	}

	function emergencyWithdrawETH(address recv, uint amount) external {
	    require(hasRole(TRUSTY_ROLE, msg.sender), "Caller is not a trusty");
		payable(recv).transfer(amount);
	}

	event Mint(uint usdc_to_dei, uint deus, uint usdc_earned);
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
    "runs": 100000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}