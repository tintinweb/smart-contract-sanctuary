// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import './interfaces/IVersionedContract.sol';
import './library/RandomNumber.sol';

contract Kitchen is AccessControlUpgradeable, ReentrancyGuardUpgradeable, IVersionedContract {
	using CountersUpgradeable for CountersUpgradeable.Counter;

	struct BaseIngredient {
		string name;
		uint256 totalVariations;
		uint256[] variationIds;
	}

	struct BaseVariation {
		uint256 baseId;
		string name;
		string svg;
	}

	struct DishType {
		string name;
		uint256 totalBaseIngredients;
		uint256[] baseIngredientIds;
		uint256[] x;
		uint256[] y;
	}

	/*
  	=======================================================================
   	======================== Public Variables ============================
   	=======================================================================
 	*/
	uint256 public totalCoordinates;

	// dishTypeId => DishType
	mapping(uint256 => DishType) public dishType;
	// basIngredientId => BaseIngredient
	mapping(uint256 => BaseIngredient) public baseIngredient;
	// variationId => variation svg
	mapping(uint256 => BaseVariation) public baseVariation;

	/*
   	=======================================================================
   	======================== Private Variables ============================
   	=======================================================================
 	*/
	bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

	CountersUpgradeable.Counter private dishTypeCounter;
	CountersUpgradeable.Counter private baseIngredientCounter;
	CountersUpgradeable.Counter private baseVariationCounter;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/

	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 */
	function initialize() external virtual initializer {
		__AccessControl_init();
		__ReentrancyGuard_init();

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		totalCoordinates = 7;
	}

	/*
   	=======================================================================
   	======================== Modifiers ====================================
   	=======================================================================
 	*/
	modifier onlyOperator() {
		require(hasRole(OPERATOR_ROLE, _msgSender()), 'Kitchen: ONLY_OPERATOR_CAN_CALL');
		_;
	}

	modifier onlyValidDishTypeId(uint256 _dishTypeId) {
		require(
			_dishTypeId > 0 && _dishTypeId <= dishTypeCounter.current(),
			'Kitchen: INVALID_DISH_ID'
		);
		_;
	}

	modifier onlyValidBaseIngredientId(uint256 _baseIngredientId) {
		require(
			_baseIngredientId > 0 && _baseIngredientId <= baseIngredientCounter.current(),
			'Kitchen: INVALID_BASE_INGREDIENT_ID'
		);
		_;
	}

	/*
  	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/
	/**
	 * @notice This method allows admin to add the dishType name in which baseIngredients will be added
	 * @param _name - indicates the name of the dishType
	 * @param _x - indicates the list of x coordinates for positioning the ingredient
	 * @param _y - indicates the list of y coordinates for positioning the ingredient
	 * @return dishTypeId - indicates the generated id of the dishType
	 */
	function addDishType(
		string memory _name,
		uint256[] memory _x,
		uint256[] memory _y
	) external onlyOperator returns (uint256 dishTypeId) {
		require(bytes(_name).length > 0, 'Kitchen: INVALID_DISH_NAME');
		require(
			_x.length == totalCoordinates && _x.length == _y.length,
			'Kitchen: INVALID_COORDINATES'
		);

		dishTypeCounter.increment();
		dishTypeId = dishTypeCounter.current();

		dishType[dishTypeId].name = _name;
		dishType[dishTypeId].x = _x;
		dishType[dishTypeId].y = _y;
	}

	/**
	 * @notice This method allows admin to add the baseIngredients for the dishType.
	 * @param _dishTypeId - indicates the dishType id for adding the base ingredient
	 * @param _name - indicates the name of the base ingredient
	 * @return baseIngredientId - indicates the name of the baseIngredient.
	 */
	function addBaseIngredientForDishType(uint256 _dishTypeId, string memory _name)
		external
		onlyOperator
		onlyValidDishTypeId(_dishTypeId)
		returns (uint256 baseIngredientId)
	{
		require(bytes(_name).length > 0, 'Kitchen: INVALID_BASE_INGREDIENT_NAME');

		baseIngredientCounter.increment();
		baseIngredientId = baseIngredientCounter.current();

		baseIngredient[baseIngredientId].name = _name;

		dishType[_dishTypeId].totalBaseIngredients += 1;
		dishType[_dishTypeId].baseIngredientIds.push(baseIngredientId);
	}

	/**
	 * @notice This method allows admin to add the different variations for the base ingredient
	 * @param _baseIngredientId - indicates the base ingredient id
	 * @param _variationName - indicates the variation name
	 * @param _svg - indicates the svg string of the base ingredient svg
	 * @param baseVariationId - indicates the newly generated variation id
	 */
	function addBaseIngredientVariation(
		uint256 _baseIngredientId,
		string memory _variationName,
		string memory _svg
	)
		external
		onlyOperator
		onlyValidBaseIngredientId(_baseIngredientId)
		returns (uint256 baseVariationId)
	{
		require(bytes(_variationName).length > 0, 'Kitchen: INVALID_VARIATION_NAME');
		require(bytes(_svg).length > 0, 'Kitchen: INVALID_SVG');

		// increment variation Id
		baseVariationCounter.increment();
		baseVariationId = baseVariationCounter.current();

		baseVariation[baseVariationId] = BaseVariation(_baseIngredientId, _variationName, _svg);

		baseIngredient[_baseIngredientId].totalVariations += 1;
		baseIngredient[_baseIngredientId].variationIds.push(baseVariationId);
	}

	/**
	 * @notice This method allows admin to update the total number of coordinates
	 */
	function updateTotalCoordinates(uint256 _newTotal) external onlyOperator {
		require(_newTotal != totalCoordinates && _newTotal > 0, 'Kitchen: INVALID_COORDINATES');
		totalCoordinates = _newTotal;
	}

	/*
   	=======================================================================
   	======================== Getter Methods ===============================
   	=======================================================================
 	*/
	function getBaseVariationHash(uint256 _dishTypeId, uint256 nonce)
		external
		view
		onlyValidDishTypeId(_dishTypeId)
		returns (
			uint256 baseVariationHash,
			string memory dishName,
			uint256 totalBaseIngredients
		)
	{
		totalBaseIngredients = dishType[_dishTypeId].totalBaseIngredients;
		require(totalBaseIngredients > 0, 'Kitchen: INSUFFICIENT_BASE_INGREDINETS');

		// get base Variation Hash
		for (uint256 baseIndex = 0; baseIndex < totalBaseIngredients; baseIndex++) {
			uint256 baseIngredientId = dishType[_dishTypeId].baseIngredientIds[baseIndex];
			uint256 baseVariationCount = baseIngredient[baseIngredientId].totalVariations;

			require(baseVariationCount > 0, 'Kitchen: NO_BASE_VARIATIONS');

			uint256 randomVarionIndex = RandomNumber.getRandomVariation(nonce, baseVariationCount);
			uint256 baseVariationId = baseIngredient[baseIngredientId].variationIds[randomVarionIndex];

			baseVariationHash += baseVariationId * 256**baseIndex;
		}
		dishName = dishType[_dishTypeId].name;
	}

	/**
	 * @notice This method returns the baseIngredient id from the base ingredients list of given dishType at given index.
	 * @param _dishTypeId - indicates the dishType id
	 * @param _index - indicates the index for the base ingredient list
	 * @return returns the base ingredient id
	 */
	function getBaseIngredientId(uint256 _dishTypeId, uint256 _index)
		external
		view
		onlyValidDishTypeId(_dishTypeId)
		returns (uint256)
	{
		DishType memory _dishType = dishType[_dishTypeId];
		require(_index < _dishType.baseIngredientIds.length, 'Kitchen: INVALID_BASE_INDEX');
		return _dishType.baseIngredientIds[_index];
	}

	/**
	 * @notice This method returns the variation id from the variation list of given base ingredient at given index.
	 * @param _baseIngredientId - indicates the base ingredient id
	 * @param _index - indicates the index for the variation list
	 * @return returns the variation id
	 */
	function getBaseVariationId(uint256 _baseIngredientId, uint256 _index)
		external
		view
		onlyValidBaseIngredientId(_baseIngredientId)
		returns (uint256)
	{
		BaseIngredient memory _baseIngredient = baseIngredient[_baseIngredientId];

		require(_index < _baseIngredient.totalVariations, 'Kitchen: INVALID_VARIATION_INDEX');
		return _baseIngredient.variationIds[_index];
	}

	/**
	 * @notice This method returns the current dishType id
	 */
	function getCurrentDishTypeId() external view returns (uint256) {
		return dishTypeCounter.current();
	}

	/**
	 * @notice This method returns the current base ingredient id
	 */
	function getCurrentBaseIngredientId() external view returns (uint256) {
		return baseIngredientCounter.current();
	}

	/**
	 * @notice This method returns the current base variation id
	 */
	function getCurrentBaseVariationId() external view returns (uint256) {
		return baseVariationCounter.current();
	}

	/**
	 * @notice This method returns the x coordinate located at index for ingredient
	 */
	function getXCoordinateAtIndex(uint256 _dishTypeId, uint256 _index)
		external
		view
		onlyValidDishTypeId(_dishTypeId)
		returns (uint256)
	{
		require(_index < dishType[_dishTypeId].x.length, 'Kitchen: INVALID_INDEX');
		return dishType[_dishTypeId].x[_index];
	}

	/**
	 * @notice This method returns the y coordinate located at index for ingredient
	 */
	function getYCoordinateAtIndex(uint256 _dishTypeId, uint256 _index)
		external
		view
		onlyValidDishTypeId(_dishTypeId)
		returns (uint256)
	{
		require(_index < dishType[_dishTypeId].y.length, 'Kitchen: INVALID_INDEX');
		return dishType[_dishTypeId].y[_index];
	}

	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		virtual
		override
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		return (1, 0, 0);
	}
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library RandomNumber {
	function getRandomVariation(uint256 _seed, uint256 _max)
		internal
		view
		returns (uint256 randomVariation)
	{
		randomVariation = random(_seed, _max);
		require(randomVariation < _max, 'LaCucinaUtils: INVALID_VARIATION');
	}

	function random(uint256 _seed, uint256 _max) internal view returns (uint256) {
		require(_max > 0, 'LaCucinaUtils: INVALID_MAX');
		uint256 randomnumber = uint256(
			keccak256(
				abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, _seed)
			)
		) % _max;

		return randomnumber;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVersionedContract {
	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		returns (
			uint256,
			uint256,
			uint256
		);
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
 * @dev String operations.
 */
library StringsUpgradeable {
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}