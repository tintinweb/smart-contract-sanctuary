// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { AddressArrayUtil } from "../lib/AddressArrayUtil.sol";

import { IController } from "../interfaces/IController.sol";

import { MatrixToken } from "./MatrixToken.sol";

/**
 * @title MatrixTokenFactory
 * @author Matrix
 *
 * @dev MatrixTokenFactory is a smart contract used to deploy new MatrixToken contracts. This contract
 * is a Factory that is enabled by the controller to create and register new MatrixTokens.
 */
contract MatrixTokenFactory {
    using AddressArrayUtil for address[];

    // ==================== Variables ====================

    IController internal _controller;

    // ==================== Events ====================

    event CreateMatrixToken(address indexed matrixToken, address indexed manager, string name, string symbol);

    // ==================== Constructor function ====================

    constructor(IController controller) {
        _controller = controller;
    }

    // ==================== External functions ====================

    function getController() external view returns (address) {
        return address(_controller);
    }

    /**
     * @dev Creates a MatrixToken smart contract and registers the it with the controller.
     * The MatrixToken is composed of positions that are instantiated as DEFAULT (positionState = 0) state.
     *
     * @param components    List of addresses of components for initial Positions
     * @param units         List of units. Each unit is the # of components per 10^18 of a MatrixToken
     * @param modules       List of modules to enable. All modules must be approved by the Controller
     * @param manager       Address of the manager
     * @param name          Name of the MatrixToken
     * @param symbol        Symbol of the MatrixToken
     *
     * @return address      Address of the newly created MatrixToken
     */
    function create(
        address[] memory components,
        int256[] memory units,
        address[] memory modules,
        address manager,
        string memory name,
        string memory symbol
    ) external returns (address) {
        require(manager != address(0), "F0a");
        require(modules.length > 0, "F0b");
        require(components.length > 0, "F0c");
        require(components.length == units.length, "F0d");
        require(!components.hasDuplicate(), "F0e");

        for (uint256 i = 0; i < components.length; i++) {
            require(components[i] != address(0), "F0f");
            require(units[i] > 0, "F0g");
        }

        for (uint256 j = 0; j < modules.length; j++) {
            require(_controller.isModule(modules[j]), "F0h");
        }

        MatrixToken matrixToken = new MatrixToken(components, units, modules, _controller, manager, name, symbol);
        _controller.addMatrix(address(matrixToken));

        emit CreateMatrixToken(address(matrixToken), manager, name, symbol);

        return address(matrixToken);
    }
}

// SPDX-License-Identifier: Apache-2.0

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IMatrixValuer } from "../interfaces/IMatrixValuer.sol";
import { IIntegrationRegistry } from "../interfaces/IIntegrationRegistry.sol";

/**
 * @title IController
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ==================== Internal Imports ====================

import { ExactSafeErc20 } from "../lib/ExactSafeErc20.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { AddressArrayUtil } from "../lib/AddressArrayUtil.sol";

import { IModule } from "../interfaces/IModule.sol";
import { IController } from "../interfaces/IController.sol";
import { IMatrixToken } from "../interfaces/IMatrixToken.sol";

/**
 * @title MatrixToken
 * @author Matrix
 *
 * @dev ERC20 Token contract that allows privileged modules to make modifications to its positions and invoke function calls from the MatrixToken.
 */
contract MatrixToken is ERC20, IMatrixToken {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using ExactSafeErc20 for IERC20;
    using PreciseUnitMath for int256;
    using Address for address;
    using AddressArrayUtil for address[];

    // ==================== Constants ====================

    // The PositionState is the status of the Position
    uint8 internal constant DEFAULT = 0; // held on the MatrixToken
    uint8 internal constant EXTERNAL = 1; // held on a separate smart contract (whether a module or external source)

    // ==================== Variables ====================

    // Address of the controller
    IController internal _controller;

    // The manager has the privelege to add modules, remove, and set a new manager
    address internal _manager;

    // A module that has locked other modules from privileged functionality,
    // typically required for multi-block module actions such as auctions
    address internal _locker;

    // List of initialized Modules; Modules extend the functionality of MatrixTokens
    address[] internal _modules;

    // module address => ModuleState
    // Modules are initialized from NONE -> PENDING -> INITIALIZED
    // through addModule (called by manager) and initialize  (called by module) functions
    mapping(address => IMatrixToken.ModuleState) public _moduleStates;

    // When locked, only the locker (a module) can call privileged functionality
    // Used when a module (e.g. Auction) needs multiple transactions to complete an action without interruption
    bool internal _isLocked;

    // List of components
    address[] internal _components;

    // component address => ComponentPosition
    // Mapping that stores all Default and External position information for a given component.
    // Position quantities are represented as virtual units; Default positions are on the top-level,
    // while external positions are stored in a module array and accessed through its externalPositions mapping
    mapping(address => IMatrixToken.ComponentPosition) private _componentPositions;

    // The multiplier applied to the virtual position unit to achieve the real/actual unit.
    // This multiplier is used for efficiently modifying the entire position units (e.g. streaming fee)
    int256 public _positionMultiplier;

    // ==================== Events ====================

    event Invoke(address indexed target, uint256 indexed value, bytes data, bytes returnValue);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event InitializeModule(address indexed module);
    event EditManager(address newManager, address oldManager);
    event RemovePendingModule(address indexed module);
    event EditPositionMultiplier(int256 newMultiplier);
    event AddComponent(address indexed component);
    event RemoveComponent(address indexed component);
    event EditDefaultPositionUnit(address indexed component, int256 realUnit);
    event EditExternalPositionUnit(address indexed component, address indexed positionModule, int256 realUnit);
    event EditExternalPositionData(address indexed component, address indexed positionModule, bytes data);
    event AddPositionModule(address indexed component, address indexed positionModule);
    event RemovePositionModule(address indexed component, address indexed positionModule);

    // ==================== Constructor function ====================

    /**
     * @dev When a new MatrixToken is created, initializes Positions in default state and adds modules into pending state.
     * All parameter validations are on the MatrixTokenFactory contract. Validations are performed already on the
     * MatrixTokenFactory. Initiates the positionMultiplier as 1e18 (no adjustments).
     *
     * @param components    List of addresses of components for initial Positions
     * @param units         List of units. Each unit is the # of components per 10^18 of a MatrixToken
     * @param modules       List of modules to enable. All modules must be approved by the Controller
     * @param controller    Address of the controller
     * @param manager       Address of the manager
     * @param name          Name of the MatrixToken
     * @param symbol        Symbol of the MatrixToken
     */
    constructor(
        address[] memory components,
        int256[] memory units,
        address[] memory modules,
        IController controller,
        address manager,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _controller = controller;
        _manager = manager;
        _positionMultiplier = PreciseUnitMath.preciseUnitInt();
        _components = components;

        // Modules are put in PENDING state, as they need to be individually initialized by the Module
        for (uint256 i = 0; i < modules.length; i++) {
            _moduleStates[modules[i]] = IMatrixToken.ModuleState.PENDING;
        }

        // Positions are put in default state initially
        for (uint256 j = 0; j < components.length; j++) {
            _componentPositions[components[j]].virtualUnit = units[j];
        }
    }

    // ==================== Receive function ====================

    receive() external payable {}

    // ==================== Modifier functions ====================

    modifier onlyModule() {
        _onlyModule();
        _;
    }

    modifier onlyManager() {
        _onlyManager();
        _;
    }

    modifier onlyLocker() {
        _onlyLocker();
        _;
    }

    // ==================== External functions ====================

    function getController() external view returns (address) {
        return address(_controller);
    }

    function getManager() external view returns (address) {
        return _manager;
    }

    function getLocker() external view returns (address) {
        return _locker;
    }

    function getComponents() external view returns (address[] memory) {
        return _components;
    }

    function getComponent(uint256 index) external view returns (address) {
        return _components[index];
    }

    function getModules() external view returns (address[] memory) {
        return _modules;
    }

    function getModuleState(address module) external view returns (IMatrixToken.ModuleState) {
        return _moduleStates[module];
    }

    function getPositionMultiplier() external view returns (int256) {
        return _positionMultiplier;
    }

    function getDefaultPositionRealUnit(address component) public view returns (int256) {
        return _convertVirtualToRealUnit(_defaultPositionVirtualUnit(component));
    }

    function getExternalPositionRealUnit(address component, address positionModule) public view returns (int256) {
        return _convertVirtualToRealUnit(_externalPositionVirtualUnit(component, positionModule));
    }

    function getExternalPositionModules(address component) external view returns (address[] memory) {
        return _externalPositionModules(component);
    }

    function getExternalPositionData(address component, address positionModule) external view returns (bytes memory) {
        return _externalPositionData(component, positionModule);
    }

    /**
     * @dev Returns a list of Positions, through traversing the components. Each component with a non-zero virtual unit
     * is considered a Default Position, and each externalPositionModule will generate a unique position.
     * Virtual units are converted to real units. This function is typically used off-chain for data presentation purposes.
     */
    function getPositions() external view returns (IMatrixToken.Position[] memory) {
        IMatrixToken.Position[] memory positions = new IMatrixToken.Position[](_getPositionCount());
        uint256 positionCount = 0;

        for (uint256 i = 0; i < _components.length; i++) {
            address component = _components[i];

            // A default position exists if the default virtual unit is > 0
            if (_defaultPositionVirtualUnit(component) > 0) {
                positions[positionCount] = IMatrixToken.Position({
                    component: component,
                    module: address(0),
                    unit: getDefaultPositionRealUnit(component),
                    positionState: DEFAULT,
                    data: ""
                });

                positionCount++;
            }

            address[] memory externalModules = _externalPositionModules(component);
            for (uint256 j = 0; j < externalModules.length; j++) {
                address currentModule = externalModules[j];

                positions[positionCount] = IMatrixToken.Position({
                    component: component,
                    module: currentModule,
                    unit: getExternalPositionRealUnit(component, currentModule),
                    positionState: EXTERNAL,
                    data: _externalPositionData(component, currentModule)
                });

                positionCount++;
            }
        }

        return positions;
    }

    /**
     * @return the total Real Units for a given component, summing the default and external position units.
     */
    function getTotalComponentRealUnits(address component) external view returns (int256) {
        int256 totalUnits = getDefaultPositionRealUnit(component);

        address[] memory externalModules = _externalPositionModules(component);
        for (uint256 i = 0; i < externalModules.length; i++) {
            // We will perform the summation no matter what, as an external position virtual unit can be negative
            totalUnits += getExternalPositionRealUnit(component, externalModules[i]);
        }

        return totalUnits;
    }

    function isLocked() external view returns (bool) {
        return _isLocked;
    }

    function isComponent(address component) public view returns (bool) {
        return _components.contain(component);
    }

    function isExternalPositionModule(address component, address module) public view returns (bool) {
        return _externalPositionModules(component).contain(module);
    }

    /**
     * @dev Only ModuleStates of INITIALIZED modules are considered enabled
     */
    function isInitializedModule(address module) external view returns (bool) {
        return _moduleStates[module] == IMatrixToken.ModuleState.INITIALIZED;
    }

    /**
     * @return Whether the module is in a pending state
     */
    function isPendingModule(address module) external view returns (bool) {
        return _moduleStates[module] == IMatrixToken.ModuleState.PENDING;
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Low level function that allows a module to make an arbitrary function call to any contract.
     *
     * @param target     Address of the smart contract to call
     * @param value      Quantity of Ether to provide the call (typically 0)
     * @param data       Encoded function selector and arguments
     *
     * @return result    Bytes encoded return value
     */
    function invoke(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyModule onlyLocker returns (bytes memory result) {
        result = target.functionCallWithValue(data, value);

        emit Invoke(target, value, data, result);

        return result;
    }

    /**
     * @dev MatrixToken to set approvals of the ERC20 token to a spender.
     *
     * @param token      ERC20 token to approve
     * @param spender    The account allowed to spend the MatrixToken's balance
     * @param amount     The amount of allowance to allow
     */
    function invokeSafeApprove(
        address token,
        address spender,
        uint256 amount
    ) external onlyModule onlyLocker {
        IERC20(token).safeApprove(spender, amount);
    }

    /**
     * @dev MatrixToken transfer ERC20 token to recipient.
     *
     * @param token     ERC20 token to transfer
     * @param to        The recipient account
     * @param amount    The amount to transfer
     */
    function invokeSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyModule onlyLocker {
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev MatrixToken transfer ERC20 tokens to recipient, and verify balance after transfer.
     *
     * @param token     ERC20 token to transfer
     * @param to        The recipient account
     * @param amount    The amount to transfer
     */
    function invokeExactSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyModule onlyLocker {
        IERC20(token).exactSafeTransfer(to, amount);
    }

    function invokeWrapWETH(address weth, uint256 amount) external onlyModule onlyLocker {
        // IWETH(weth).deposit{ value: amount }();
        bytes memory callData = abi.encodeWithSignature("deposit()");
        weth.functionCallWithValue(callData, amount, "invokeWrapWETH fail");
    }

    function invokeUnwrapWETH(address weth, uint256 amount) external onlyModule onlyLocker {
        // IWETH(weth).withdraw(amount);
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", amount);
        weth.functionCallWithValue(callData, 0, "invokeUnwrapWETH fail");
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Low level function that adds a component to the components array.
     */
    function addComponent(address component) external onlyModule onlyLocker {
        require(!isComponent(component), "T0");

        _components.push(component);

        emit AddComponent(component);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Low level function that removes a component from the components array.
     */
    function removeComponent(address component) external onlyModule onlyLocker {
        _components.quickRemoveItem(component);

        emit RemoveComponent(component);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Low level function that edits a component's virtual unit.
     * Takes a real unit and converts it to virtual before committing.
     */
    function editDefaultPositionUnit(address component, int256 realUnit) external onlyModule onlyLocker {
        int256 virtualUnit = _convertRealToVirtualUnit(realUnit);
        _componentPositions[component].virtualUnit = virtualUnit;

        emit EditDefaultPositionUnit(component, realUnit);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Low level function that adds a module to a component's externalPositionModules array
     */
    function addExternalPositionModule(address component, address positionModule) external onlyModule onlyLocker {
        require(!isExternalPositionModule(component, positionModule), "T1"); // "Module already added"

        _componentPositions[component].externalPositionModules.push(positionModule);

        emit AddPositionModule(component, positionModule);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Low level function that removes a module from a component's
     * externalPositionModules array and deletes the associated externalPosition.
     */
    function removeExternalPositionModule(address component, address positionModule) external onlyModule onlyLocker {
        _componentPositions[component].externalPositionModules.quickRemoveItem(positionModule);

        delete _componentPositions[component].externalPositions[positionModule];

        emit RemovePositionModule(component, positionModule);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Low level function that edits a component's external position virtual unit.
     * Takes a real unit and converts it to virtual before committing.
     */
    function editExternalPositionUnit(
        address component,
        address positionModule,
        int256 realUnit
    ) external onlyModule onlyLocker {
        int256 virtualUnit = _convertRealToVirtualUnit(realUnit);
        _componentPositions[component].externalPositions[positionModule].virtualUnit = virtualUnit;

        emit EditExternalPositionUnit(component, positionModule, realUnit);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Low level function that edits a component's external position data
     */
    function editExternalPositionData(
        address component,
        address positionModule,
        bytes calldata data
    ) external onlyModule onlyLocker {
        _componentPositions[component].externalPositions[positionModule].data = data;

        emit EditExternalPositionData(component, positionModule, data);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Modifies the position multiplier. This is typically used to efficiently
     * update all the Positions' units at once in applications where inflation is awarded (e.g. subscription fees).
     */
    function editPositionMultiplier(int256 newMultiplier) external onlyModule onlyLocker {
        _validateNewMultiplier(newMultiplier);

        _positionMultiplier = newMultiplier;

        emit EditPositionMultiplier(newMultiplier);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Increases the "account" balance by the "quantity".
     */
    function mint(address account, uint256 quantity) external onlyModule onlyLocker {
        _mint(account, quantity);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Decreases the "account" balance by the "quantity".
     * _burn checks that the "account" already has the required "quantity".
     */
    function burn(address account, uint256 quantity) external onlyModule onlyLocker {
        _burn(account, quantity);
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. When a MatrixToken is locked, only the locker can call privileged functions.
     */
    function lock() external onlyModule {
        require(!_isLocked, "T2"); // "Must not be locked"
        _locker = msg.sender;
        _isLocked = true;
    }

    /**
     * @dev PRIVELEGED MODULE FUNCTION. Unlocks the MatrixToken and clears the locker
     */
    function unlock() external onlyModule {
        require(_isLocked, "T3a"); // "Must be locked"
        require(_locker == msg.sender, "T3b"); // "Must be locker"
        delete _locker;
        _isLocked = false;
    }

    /**
     * @dev MANAGER ONLY. Adds a module into a PENDING state;
     * @notice Module must later be initialized via module's initialize function
     */
    function addModule(address module) external onlyManager {
        require(_moduleStates[module] == IMatrixToken.ModuleState.NONE, "T4a"); // "Module must not be added"
        require(_controller.isModule(module), "T4b"); // "Must be enabled on Controller"

        _moduleStates[module] = IMatrixToken.ModuleState.PENDING;

        emit AddModule(module);
    }

    /**
     * @dev MANAGER ONLY. Removes a module from the MatrixToken. MatrixToken calls removeModule on module
     * to confirm it is not needed to manage any remaining positions and to remove state.
     */
    function removeModule(address module) external onlyManager {
        require(!_isLocked, "T5a"); // // "Only when unlocked"
        require(_moduleStates[module] == IMatrixToken.ModuleState.INITIALIZED, "T5b"); // "Module must be added"

        IModule(module).removeModule();
        _moduleStates[module] = IMatrixToken.ModuleState.NONE;
        _modules.quickRemoveItem(module);

        emit RemoveModule(module);
    }

    /**
     * @dev MANAGER ONLY. Removes a pending module from the MatrixToken.
     */
    function removePendingModule(address module) external onlyManager {
        require(!_isLocked, "T6a"); // "Only when unlocked"
        require(_moduleStates[module] == IMatrixToken.ModuleState.PENDING, "T6b"); // "Module must be pending"

        _moduleStates[module] = IMatrixToken.ModuleState.NONE;

        emit RemovePendingModule(module);
    }

    /**
     * @dev Initializes an added module from PENDING to INITIALIZED state. Can only call when unlocked.
     * An address can only enter a PENDING state if it is an enabled module added by the manager.
     * Only callable by the module itself, hence msg.sender is the subject of update.
     */
    function initializeModule() external {
        require(!_isLocked, "T7a"); // "Only when unlocked"
        require(_moduleStates[msg.sender] == IMatrixToken.ModuleState.PENDING, "T7b"); // "Module must be pending")

        _moduleStates[msg.sender] = IMatrixToken.ModuleState.INITIALIZED;
        _modules.push(msg.sender);

        emit InitializeModule(msg.sender);
    }

    /**
     * @dev MANAGER ONLY. Changes manager; We allow null addresses in case the manager wishes to wind down the MatrixToken.
     * Modules may rely on the manager state, so only changable when unlocked
     */
    function setManager(address newManager) external onlyManager {
        require(!_isLocked, "T8"); // "Only when unlocked"
        address oldManager = _manager;
        _manager = newManager;

        emit EditManager(newManager, oldManager);
    }

    // ==================== Internal functions ====================

    function _defaultPositionVirtualUnit(address component) internal view returns (int256) {
        return _componentPositions[component].virtualUnit;
    }

    function _externalPositionModules(address component) internal view returns (address[] memory) {
        return _componentPositions[component].externalPositionModules;
    }

    function _externalPositionVirtualUnit(address component, address module) internal view returns (int256) {
        return _componentPositions[component].externalPositions[module].virtualUnit;
    }

    function _externalPositionData(address component, address module) internal view returns (bytes memory) {
        return _componentPositions[component].externalPositions[module].data;
    }

    /**
     * @dev Takes a real unit and divides by the position multiplier to return the virtual unit.
     * Negative units will be rounded away from 0 so no need to check that unit will be rounded down to 0 in conversion.
     */
    function _convertRealToVirtualUnit(int256 realUnit) internal view returns (int256) {
        int256 virtualUnit = realUnit.preciseDivFloor(_positionMultiplier);

        // This check ensures that the virtual unit does not return a result that has rounded down to 0
        if (realUnit > 0 && virtualUnit == 0) {
            revert("T9a"); // "Real to Virtual unit conversion invalid"
        }

        // This check ensures that when converting back to realUnits the unit won't be rounded down to 0
        if (realUnit > 0 && _convertVirtualToRealUnit(virtualUnit) == 0) {
            revert("T9b"); // "Virtual to Real unit conversion invalid"
        }

        return virtualUnit;
    }

    /**
     * @dev Takes a virtual unit and multiplies by the position multiplier to return the real unit
     */
    function _convertVirtualToRealUnit(int256 virtualUnit) internal view returns (int256) {
        return virtualUnit.preciseMulFloor(_positionMultiplier);
    }

    /**
     * @dev To prevent virtual to real unit conversion issues (where real unit may be 0),
     * the product of the positionMultiplier and the lowest absolute virtualUnit value
     * (across default and external positions) must be greater than 0.
     */
    function _validateNewMultiplier(int256 newMultiplier) internal view {
        int256 minVirtualUnit = _getPositionsAbsMinimumVirtualUnit();

        require(minVirtualUnit.preciseMulFloor(newMultiplier) > 0, "T10"); // "New multiplier too small"
    }

    /**
     * @dev Loops through all of the positions and returns the smallest absolute value of the virtualUnit.
     *
     * @return Min virtual unit across positions denominated as int256
     */
    function _getPositionsAbsMinimumVirtualUnit() internal view returns (int256) {
        // Additional assignment happens in the loop below
        uint256 minimumUnit = type(uint256).max;

        for (uint256 i = 0; i < _components.length; i++) {
            address component = _components[i];

            // A default position exists if the default virtual unit is > 0
            uint256 defaultUnit = _defaultPositionVirtualUnit(component).toUint256();
            if (defaultUnit > 0 && defaultUnit < minimumUnit) {
                minimumUnit = defaultUnit;
            }

            address[] memory externalModules = _externalPositionModules(component);
            for (uint256 j = 0; j < externalModules.length; j++) {
                address currentModule = externalModules[j];

                uint256 virtualUnit = _abs(_externalPositionVirtualUnit(component, currentModule));
                if (virtualUnit > 0 && virtualUnit < minimumUnit) {
                    minimumUnit = virtualUnit;
                }
            }
        }

        return minimumUnit.toInt256();
    }

    /**
     * @dev Gets the total number of positions, defined as the following:
     * - Each component has a default position if its virtual unit is > 0
     * - Each component's external positions module is counted as a position
     */
    function _getPositionCount() internal view returns (uint256) {
        uint256 positionCount;
        for (uint256 i = 0; i < _components.length; i++) {
            address component = _components[i];

            // Increment the position count if the default position is > 0
            if (_defaultPositionVirtualUnit(component) > 0) {
                positionCount++;
            }

            // Increment the position count by each external position module
            address[] memory externalModules = _externalPositionModules(component);
            if (externalModules.length > 0) {
                positionCount += externalModules.length;
            }
        }

        return positionCount;
    }

    function _abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }

    // ==================== Private functions ====================

    /**
     * @dev Module must be initialized on the MatrixToken and enabled by the controller
     */
    function _onlyModule() private view {
        require(_moduleStates[msg.sender] == IMatrixToken.ModuleState.INITIALIZED, "T11a"); // "Only the module can call"
        require(_controller.isModule(msg.sender), "T11b"); // "Module must be enabled on controller"
    }

    function _onlyManager() private view {
        require(msg.sender == _manager, "T12"); // "Only manager can call")
    }

    function _onlyLocker() private view {
        require(!_isLocked || (msg.sender == _locker), "T13"); // "When locked, only the locker can call")
    }
}

// SPDX-License-Identifier: Apache-2.0

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IMatrixToken } from "../interfaces/IMatrixToken.sol";

/**
 * @title IMatrixValuer
 * @author Matrix
 */
interface IMatrixValuer {
    // ==================== External functions ====================

    function calculateMatrixTokenValuation(IMatrixToken matrixToken, address quoteAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ExactSafeErc20
 * @author Matrix
 *
 * @dev Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExactSafeErc20 {
    using SafeERC20 for IERC20;

    // ==================== Internal functions ====================

    /**
     * @dev This function checks transfer fees, ensure the recipient received the correct amount.
     *
     * @param token     ERC20 token to approve
     * @param to        The account of recipient
     * @param amount    The quantity to transfer
     */
    function exactSafeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 oldBalance = token.balanceOf(to);
            token.safeTransfer(to, amount);
            uint256 newBalance = token.balanceOf(to);
            require(newBalance == oldBalance + amount, "ES0"); // "Invalid post transfer balance"
        }
    }

    /**
     * @dev This function checks transfer fees, ensure the recipient received the correct amount.
     *
     * @param token     ERC20 token to approve
     * @param from      The account of sender
     * @param to        The account of recipient
     * @param amount    The quantity to transfer
     */
    function exactSafeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 oldBalance = token.balanceOf(to);
            token.safeTransferFrom(from, to, amount);
            uint256 newBalance = token.balanceOf(to);
            require(newBalance == oldBalance + amount, "ES1"); // "Invalid post transfer balance"
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IModule
 * @author Matrix
 */
interface IModule {
    // ==================== External functions ====================

    /**
     * @dev Called by a MatrixToken to notify that this module was removed.
     * Any logic can be included in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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