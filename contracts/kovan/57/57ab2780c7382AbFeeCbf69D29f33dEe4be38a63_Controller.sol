/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/lib/PreciseUnitMath.sol


pragma solidity ^0.8.0;

/**
 * @title PreciseUnitMath
 * @author Matrix
 *
 * @dev Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from dYdX's BaseMath library.
 */
library PreciseUnitMath {
    // ==================== Constants ====================

    // The number One in precise units.
    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;

    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    // ==================== Internal functions ====================

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down), both a and b are numbers with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / PRECISE_UNIT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero), both a and b are numbers with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / PRECISE_UNIT_INT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up), both a and b are numbers with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b - 1) / PRECISE_UNIT + 1;
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM0");

        return (a * PRECISE_UNIT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "PM1");

        return (a * PRECISE_UNIT_INT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM2");

        return a > 0 ? ((a * PRECISE_UNIT - 1) / b + 1) : 0;
    }

    // int256(5) / int256(2) == (2, 1)
    // int256(5) / int256(-2) == (-2, 1)
    // int256(-5) / int256(2) == (-2, -1)
    // int256(-5) / int256(-2) == (2, -1)

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseMulFloor(int256 a, int256 b) internal pure returns (int256 result) {
        int256 numerator = a * b;
        result = numerator / PRECISE_UNIT_INT;
        if ((numerator < 0) && (numerator % PRECISE_UNIT_INT != 0)) {
            result--;
        }
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0). When `a` is 0, 0 is
     * returned. When `b` is 0, method reverts with divide-by-zero error.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM3");

        int256 numerator = a * PRECISE_UNIT_INT;
        result = numerator / b; // not check overflow: numerator == MIN_INT_256 && b == -1
        if ((numerator ^ b > 0) && (numerator % b != 0)) {
            result++;
        }
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseDivFloor(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM4");

        int256 numerator = a * PRECISE_UNIT_INT;
        result = numerator / b; // not check overflow: numerator == MIN_INT_256 && b == -1
        if ((numerator ^ b < 0) && (numerator % b != 0)) {
            result--;
        }
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(
        uint256 a,
        uint256 b,
        uint256 range
    ) internal pure returns (bool) {
        if (a >= b) {
            return a - b <= range;
        } else {
            return b - a <= range;
        }
    }

    /**
     * @dev Returns the absolute value of int256 `a` as a uint256
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}


// File contracts/lib/AddressArrayUtil.sol


pragma solidity ^0.8.0;

/**
 * @title AddressArrayUtil
 * @author Matrix
 *
 * @dev Utility functions to handle Address Arrays
 */
library AddressArrayUtil {
    // ==================== Internal functions ====================

    /**
     * @dev Check the array whether contains duplicate elements.
     *
     * @param array    The input array to search.
     *
     * @return bool    Whether array has duplicate elements.
     */
    function hasDuplicate(address[] memory array) internal pure returns (bool) {
        if (array.length > 1) {
            uint256 lastIndex = array.length - 1;
            for (uint256 i = 0; i < lastIndex; i++) {
                address value = array[i];
                for (uint256 j = i + 1; j < array.length; j++) {
                    if (value == array[j]) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * @dev Search element in array
     *
     * @param array     The input array to search.
     * @param value     The element to search.
     *
     * @return index    The first element's position in array, start from 0.
     * @return found    Whether find element in array.
     */
    function indexOf(address[] memory array, address value) internal pure returns (uint256 index, bool found) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (i, true);
            }
        }

        return (type(uint256).max, false);
    }

    /**
     * @dev search element in array.
     *
     * @param array    The input array to search.
     * @param value    The element to search.
     *
     * @return bool    Whether value is in array.
     */
    function contain(address[] memory array, address value) internal pure returns (bool) {
        (, bool found) = indexOf(array, value);
        return found;
    }

    /**
     * @dev remove the first specified element, and keep order of other elements.
     *
     * @param array    The input array to search.
     * @param value    The element to remove.
     */
    function removeValue(address[] memory array, address value) internal pure returns (address[] memory) {
        (uint256 index, bool found) = indexOf(array, value);
        require(found, "A0");

        address[] memory result = new address[](array.length - 1);
        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }

        for (uint256 i = index + 1; i < array.length; i++) {
            result[index] = array[i];
            index = i;
        }

        return result;
    }

    /**
     * @dev remove the first specified element, and keep order of other elements.
     *
     * @param array    The input array to search.
     * @param item     The element to remove.
     */
    function removeItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A1");

        for (uint256 right = index + 1; right < array.length; right++) {
            array[index] = array[right];
            index = right;
        }

        array.pop();
    }

    /**
     * @dev Remove the first specified element from array, not keep order of other elements.
     *
     * @param array    The input array to search.
     * @param item     The element to remove.
     */
    function quickRemoveItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A2");

        array[index] = array[array.length - 1]; // to save gas we not check index == array.length - 1
        array.pop();
    }

    /**
     * @dev Combine two arrays.
     *
     * @param array1        The first input array.
     * @param array2        The second input array.
     *
     * @return address[]    The new array which is array1 + array2
     */
    function merge(address[] memory array1, address[] memory array2) internal pure returns (address[] memory) {
        address[] memory result = new address[](array1.length + array2.length);
        for (uint256 i = 0; i < array1.length; i++) {
            result[i] = array1[i];
        }

        uint256 index = array1.length;
        for (uint256 j = 0; j < array2.length; j++) {
            result[index++] = array2[j];
        }

        return result;
    }

    /**
     * @dev Validate that address and uint array lengths match.
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of uint
     */
    function validateArrayPairs(address[] memory array1, uint256[] memory array2) internal pure {
        require(array1.length == array2.length, "A3");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bool array lengths match.
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bool
     */
    function validateArrayPairs(address[] memory array1, bool[] memory array2) internal pure {
        require(array1.length == array2.length, "A4");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and string array lengths match.
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of strings
     */
    function validateArrayPairs(address[] memory array1, string[] memory array2) internal pure {
        require(array1.length == array2.length, "A5");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address array lengths match, and calling address array are not empty
     * and not contain duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of addresses
     */
    function validateArrayPairs(address[] memory array1, address[] memory array2) internal pure {
        require(array1.length == array2.length, "A6");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bytes
     */
    function validateArrayPairs(address[] memory array1, bytes[] memory array2) internal pure {
        require(array1.length == array2.length, "A7");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate address array is not empty and contains no duplicate elements.
     *
     * @param array    Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory array) internal pure {
        require(array.length > 0, "A8a");
        require(!hasDuplicate(array), "A8b");
    }
}


// File contracts/interfaces/IPriceOracle.sol


pragma solidity ^0.8.0;

/**
 * @title IPriceOracle
 * @author Matrix
 *
 * @dev Interface for interacting with PriceOracle
 */
interface IPriceOracle {
    // ==================== External functions ====================

    function getPrice(address asset1, address asset2) external view returns (uint256);

    function getMasterQuoteAsset() external view returns (address);
}


// File contracts/interfaces/IMatrixToken.sol


pragma solidity ^0.8.0;

// ==================== External Imports ====================

/**
 * @title IMatrixToken
 * @author Matrix
 *
 * @dev Interface for operating with MatrixToken.
 */
interface IMatrixToken is IERC20 {
    // ==================== Enums ====================

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    // ==================== Structs ====================

    /**
     * @dev The base definition of a MatrixToken Position.
     *
     * @param unit             Each unit is the # of components per 10^18 of a MatrixToken
     * @param module           If not in default state, the address of associated module
     * @param component        Address of token in the Position
     * @param positionState    Position ENUM. Default is 0; External is 1
     * @param data             Arbitrary data
     */
    struct Position {
        int256 unit;
        address module;
        address component;
        uint8 positionState;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's external position details including virtual unit and any auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
        int256 virtualUnit;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency updating all units at once
                                            via the positionMultiplier. Virtual units are achieved by dividing a "real" value by the "positionMultiplier"
     * @param externalPositionModules   External modules attached to each external position. Each module maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getManager() external view returns (address);

    function getLocker() external view returns (address);

    function getComponents() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getModuleState(address module) external view returns (ModuleState);

    function getPositionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(address component) external view returns (int256);

    function getDefaultPositionRealUnit(address component) external view returns (int256);

    function getExternalPositionRealUnit(address component, address positionModule) external view returns (int256);

    function getExternalPositionModules(address component) external view returns (address[] memory);

    function getExternalPositionData(address component, address positionModule) external view returns (bytes memory);

    function isExternalPositionModule(address component, address module) external view returns (bool);

    function isComponent(address component) external view returns (bool);

    function isInitializedModule(address module) external view returns (bool);

    function isPendingModule(address module) external view returns (bool);

    function isLocked() external view returns (bool);

    function setManager(address manager) external;

    function addComponent(address component) external;

    function removeComponent(address component) external;

    function editDefaultPositionUnit(address component, int256 realUnit) external;

    function addExternalPositionModule(address component, address positionModule) external;

    function removeExternalPositionModule(address component, address positionModule) external;

    function editExternalPositionUnit(address component, address positionModule, int256 realUnit) external; // prettier-ignore

    function editExternalPositionData(address component, address positionModule, bytes calldata data) external; // prettier-ignore

    function invoke(address target, uint256 value, bytes calldata data) external returns (bytes memory); // prettier-ignore

    function invokeSafeApprove(address token, address spender, uint256 amount) external; // prettier-ignore

    function invokeSafeTransfer(address token, address to, uint256 amount) external; // prettier-ignore

    function invokeExactSafeTransfer(address token, address to, uint256 amount) external; // prettier-ignore

    function invokeWrapWETH(address weth, uint256 amount) external;

    function invokeUnwrapWETH(address weth, uint256 amount) external;

    function editPositionMultiplier(int256 newMultiplier) external;

    function mint(address account, uint256 quantity) external;

    function burn(address account, uint256 quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function initializeModule() external;
}


// File contracts/interfaces/IMatrixValuer.sol


pragma solidity ^0.8.0;

/**
 * @title IMatrixValuer
 * @author Matrix
 */
interface IMatrixValuer {
    // ==================== External functions ====================

    function calculateMatrixTokenValuation(IMatrixToken matrixToken, address quoteAsset) external view returns (uint256);
}


// File contracts/interfaces/IIntegrationRegistry.sol


pragma solidity ^0.8.0;

/*
 * @title IIntegrationRegistry
 * @author Matrix
 */
interface IIntegrationRegistry {
    // ==================== Events ====================

    event AddIntegration(address indexed module, address indexed adapter, string integrationName);
    event RemoveIntegration(address indexed module, address indexed adapter, string integrationName);
    event EditIntegration(address indexed module, address newAdapter, string integrationName);

    // ==================== External functions ====================

    function getIntegrationAdapter(address module, string memory id) external view returns (address);

    function getIntegrationAdapterWithHash(address module, bytes32 id) external view returns (address);

    function isValidIntegration(address module, string memory id) external view returns (bool);

    function addIntegration(address module, string memory id, address wrapper) external; // prettier-ignore

    function batchAddIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function editIntegration(address module, string memory name, address adapter) external; // prettier-ignore

    function batchEditIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function removeIntegration(address module, string memory name) external;
}


// File contracts/interfaces/IController.sol


pragma solidity ^0.8.0;

// ==================== Internal Imports ====================



/**
 * @title Position
 * @author Matrix
 */
interface IController {
    // ==================== Events ====================

    event AddFactory(address indexed factory);
    event RemoveFactory(address indexed factory);
    event AddFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFeeRecipient(address newFeeRecipient);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event AddResource(address indexed resource, uint256 id);
    event RemoveResource(address indexed resource, uint256 id);
    event AddMatrix(address indexed matrixToken, address indexed factory);
    event RemoveMatrix(address indexed matrixToken);

    // ==================== External functions ====================

    function isMatrix(address matrixToken) external view returns (bool);

    function isFactory(address addr) external view returns (bool);

    function isModule(address addr) external view returns (bool);

    function isResource(address addr) external view returns (bool);

    function isSystemContract(address contractAddress) external view returns (bool);

    function getFeeRecipient() external view returns (address);

    function getModuleFee(address module, uint256 feeType) external view returns (uint256);

    function getFactories() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getResources() external view returns (address[] memory);

    function getResource(uint256 id) external view returns (address);

    function getMatrixs() external view returns (address[] memory);

    function getIntegrationRegistry() external view returns (IIntegrationRegistry);

    function getPriceOracle() external view returns (IPriceOracle);

    function getMatrixValuer() external view returns (IMatrixValuer);

    function initialize(
        address[] memory factories,
        address[] memory modules,
        address[] memory resources,
        uint256[] memory resourceIds
    ) external;

    function addMatrix(address matrixToken) external;

    function removeMatrix(address matrixToken) external;

    function addFactory(address factory) external;

    function removeFactory(address factory) external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function addResource(address resource, uint256 id) external;

    function removeResource(uint256 id) external;

    function addFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFeeRecipient(address newFeeRecipient) external;
}


// File contracts/protocol/Controller.sol


pragma solidity ^0.8.0;

// ==================== External Imports ====================


// ==================== Internal Imports ====================






/**
 * @title Controller
 * @author Matrix
 *
 * @dev houses state for approvals and system contracts such as added matrix,
 * modules, factories, resources (like price oracles), and protocol fee configurations.
 */
contract Controller is Ownable, IController {
    using AddressArrayUtil for address[];

    // ==================== Constants ====================

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 internal constant INTEGRATION_REGISTRY_RESOURCE_ID = 0;

    // PriceOracle will always be resource ID 1 in the system
    uint256 internal constant PRICE_ORACLE_RESOURCE_ID = 1;

    // MatrixValuer resource will always be resource ID 2 in the system
    uint256 internal constant MATRIX_VALUER_RESOURCE_ID = 2;

    // ==================== Variables ====================

    // Eenabled matrixs
    address[] internal _matrixs;

    // Enabled factories of MatrixToken
    address[] internal _factories;

    // Enabled Modules; Modules extend the functionality of MatrixToken
    address[] internal _modules;

    // Enabled Resources; Resources provide data, functionality, or permissions that can be drawn upon from Module, MatrixToken or factories
    address[] internal _resources;

    // Mappings to check whether address is valid Matrix, Factory, Module or Resource
    mapping(address => bool) internal _isMatrix;
    mapping(address => bool) internal _isFactory;
    mapping(address => bool) internal _isModule;
    mapping(address => bool) internal _isResource;

    // Mapping of modules to fee types to fee percentage. A module can have multiple feeTypes. Fee is denominated in precise unit percentages (100% = 1e18, 1% = 1e16)
    mapping(address => mapping(uint256 => uint256)) internal _fees;

    // Resource ID => resource address, allows contracts to fetch the correct resource while providing an ID
    mapping(uint256 => address) internal _resourceIds;

    // Recipient of protocol fees
    address internal _feeRecipient;

    bool internal _isInitialized;

    // ==================== Constructor function ====================

    /**
     * @param feeRecipient    Address of the initial protocol fee recipient
     */
    constructor(address feeRecipient) {
        _feeRecipient = feeRecipient;
    }

    // ==================== Modifier functions ====================

    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    modifier onlyInitialized() {
        _onlyInitialized();
        _;
    }

    // ==================== External functions ====================

    function isInitialized() external view returns (bool) {
        return _isInitialized;
    }

    function isMatrix(address addr) external view returns (bool) {
        return _isMatrix[addr];
    }

    function isFactory(address addr) external view returns (bool) {
        return _isFactory[addr];
    }

    function isModule(address addr) external view returns (bool) {
        return _isModule[addr];
    }

    function isResource(address addr) external view returns (bool) {
        return _isResource[addr];
    }

    /**
     * @dev Check if a contract address is a matrix, module, resource, factory or controller
     *
     * @param addr    The contract address to check
     */
    function isSystemContract(address addr) external view returns (bool) {
        return (_isMatrix[addr] || _isModule[addr] || _isResource[addr] || _isFactory[addr] || addr == address(this));
    }

    function getFeeRecipient() external view returns (address) {
        return _feeRecipient;
    }

    function getModuleFee(address moduleAddress, uint256 feeType) external view returns (uint256) {
        return _fees[moduleAddress][feeType];
    }

    function getFactories() external view returns (address[] memory) {
        return _factories;
    }

    function getModules() external view returns (address[] memory) {
        return _modules;
    }

    function getResources() external view returns (address[] memory) {
        return _resources;
    }

    function getResource(uint256 id) external view returns (address) {
        return _resourceIds[id];
    }

    function getMatrixs() external view returns (address[] memory) {
        return _matrixs;
    }

    /**
     * @dev Gets the instance of integration registry stored on Controller.
     * @notice IntegrationRegistry is stored as index 0 on the Controller.
     */
    function getIntegrationRegistry() external view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_resourceIds[INTEGRATION_REGISTRY_RESOURCE_ID]);
    }

    /**
     * @dev Gets instance of price oracle on Controller.
     * @notice PriceOracle is stored as index 1 on the Controller.
     */
    function getPriceOracle() external view returns (IPriceOracle) {
        return IPriceOracle(_resourceIds[PRICE_ORACLE_RESOURCE_ID]);
    }

    /**
     * @dev Gets the instance of matrix valuer on Controller.
     * @notice MatrixValuer is stored as index 2 on the Controller.
     */
    function getMatrixValuer() external view returns (IMatrixValuer) {
        return IMatrixValuer(_resourceIds[MATRIX_VALUER_RESOURCE_ID]);
    }

    /**
     * @dev Initializes any predeployed factories, modules, and resources post deployment.
     * @notice This function can only be called by the owner once to batch initialize the initial system contracts.
     *
     * @param factories      factories to add
     * @param modules        modules to add
     * @param resources      resources to add
     * @param resourceIds    resource IDs associated with the resources
     */
    function initialize(
        address[] memory factories,
        address[] memory modules,
        address[] memory resources,
        uint256[] memory resourceIds
    ) external onlyOwner {
        require(!_isInitialized, "C0a");
        require(resources.length == resourceIds.length, "C0b");

        _factories = factories;
        _modules = modules;
        _resources = resources;

        // Loop through and initialize isModule, isFactory, and isResource mapping
        for (uint256 i = 0; i < factories.length; i++) {
            address factory = factories[i];
            require(factory != address(0), "C0c");

            _isFactory[factory] = true;
        }

        for (uint256 i = 0; i < modules.length; i++) {
            address module = modules[i];
            require(module != address(0), "C0d");

            _isModule[module] = true;
        }

        for (uint256 i = 0; i < resources.length; i++) {
            address resource = resources[i];
            require(resource != address(0), "C0e");

            uint256 resourceId = resourceIds[i];
            require(_resourceIds[resourceId] == address(0), "C0f");

            _isResource[resource] = true;
            _resourceIds[resourceId] = resource;
        }

        _isInitialized = true;
    }

    /**
     * @dev PRIVILEGED FACTORY FUNCTION. Adds a newly deployed MatrixToken as an enabled MatrixToken.
     *
     * @param matrixToken    Address of the MatrixToken contract to add
     */
    function addMatrix(address matrixToken) external onlyInitialized onlyFactory {
        require(!_isMatrix[matrixToken], "C1");

        _isMatrix[matrixToken] = true;
        _matrixs.push(matrixToken);

        emit AddMatrix(matrixToken, msg.sender);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a Set
     *
     * @param matrixToken    Address of the MatrixToken contract to remove
     */
    function removeMatrix(address matrixToken) external onlyInitialized onlyOwner {
        require(_isMatrix[matrixToken], "C2");

        _matrixs.quickRemoveItem(matrixToken);
        _isMatrix[matrixToken] = false;

        emit RemoveMatrix(matrixToken);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a factory
     *
     * @param factory    Address of the factory contract to add
     */
    function addFactory(address factory) external onlyInitialized onlyOwner {
        require(!_isFactory[factory], "C3");

        _isFactory[factory] = true;
        _factories.push(factory);

        emit AddFactory(factory);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a factory
     *
     * @param factory    Address of the factory contract to remove
     */
    function removeFactory(address factory) external onlyInitialized onlyOwner {
        require(_isFactory[factory], "C4");

        _factories.quickRemoveItem(factory);
        _isFactory[factory] = false;

        emit RemoveFactory(factory);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a module
     *
     * @param module    Address of the module contract to add
     */
    function addModule(address module) external onlyInitialized onlyOwner {
        require(!_isModule[module], "C5");

        _isModule[module] = true;
        _modules.push(module);

        emit AddModule(module);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a module
     *
     * @param module    Address of the module contract to remove
     */
    function removeModule(address module) external onlyInitialized onlyOwner {
        require(_isModule[module], "C6");

        _modules.quickRemoveItem(module);
        _isModule[module] = false;

        emit RemoveModule(module);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a resource
     *
     * @param resource    Address of the resource contract to add
     * @param id          New ID of the resource contract
     */
    function addResource(address resource, uint256 id) external onlyInitialized onlyOwner {
        require(!_isResource[resource], "C7a");
        require(_resourceIds[id] == address(0), "C7b");

        _isResource[resource] = true;
        _resourceIds[id] = resource;
        _resources.push(resource);

        emit AddResource(resource, id);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a resource
     *
     * @param id    ID of the resource contract to remove
     */
    function removeResource(uint256 id) external onlyInitialized onlyOwner {
        address resourceToRemove = _resourceIds[id];
        require(resourceToRemove != address(0), "C8");

        _resources.quickRemoveItem(resourceToRemove);
        delete _resourceIds[id];
        _isResource[resourceToRemove] = false;

        emit RemoveResource(resourceToRemove, id);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a fee to a module
     *
     * @param module              Address of the module contract to add fee to
     * @param feeType             Type of the fee to add in the module
     * @param newFeePercentage    Percentage of fee to add in the module (denominated in preciseUnits eg 1% = 1e16)
     */
    function addFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external onlyInitialized onlyOwner {
        require(_isModule[module], "C9a");
        require(_fees[module][feeType] == 0, "C9b");

        _fees[module][feeType] = newFeePercentage;

        emit AddFee(module, feeType, newFeePercentage);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit a fee in an existing module
     *
     * @param module              Address of the module contract to edit fee
     * @param feeType             Type of the fee to edit in the module
     * @param newFeePercentage    Percentage of fee to edit in the module (denominated in preciseUnits eg 1% = 1e16)
     */
    function editFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external onlyInitialized onlyOwner {
        require(_isModule[module], "C10a");
        require(_fees[module][feeType] != 0, "C10b");

        _fees[module][feeType] = newFeePercentage;

        emit EditFee(module, feeType, newFeePercentage);
    }

    /**
     * @dev PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol fee recipient
     *
     * @param newFeeRecipient    Address of the new protocol fee recipient
     */
    function editFeeRecipient(address newFeeRecipient) external onlyInitialized onlyOwner {
        require(newFeeRecipient != address(0), "C11");

        _feeRecipient = newFeeRecipient;

        emit EditFeeRecipient(newFeeRecipient);
    }

    // ==================== Private functions ====================

    function _onlyFactory() private view {
        require(_isFactory[msg.sender], "C12");
    }

    function _onlyInitialized() private view {
        require(_isInitialized, "C13");
    }
}