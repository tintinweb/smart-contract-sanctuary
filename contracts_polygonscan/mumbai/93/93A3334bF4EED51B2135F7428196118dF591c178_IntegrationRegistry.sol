// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// ==================== Internal Imports ====================

import { IController } from "../interfaces/IController.sol";
import { IIntegrationRegistry } from "../interfaces/IIntegrationRegistry.sol";

/**
 * @title IntegrationRegistry
 * @author Matrix
 *
 * @dev IntegrationRegistry holds state relating to the Modules and the integrations they are connected with.
 * The state is combined into a single Registry to allow governance updates to be aggregated to one contract.
 */
contract IntegrationRegistry is Ownable, IIntegrationRegistry {
    // ==================== Variables ====================

    IController internal immutable _controller;

    // module => integration identifier => adapter address
    mapping(address => mapping(bytes32 => address)) private _integrations;

    // ==================== Constructor function ====================

    constructor(IController controller) {
        _controller = controller;
    }

    // ==================== External functions ====================

    function getController() external view returns (address) {
        return address(_controller);
    }

    function getIntegrationAdapter(address module, string memory name) external view returns (address) {
        return _integrations[module][_hashName(name)];
    }

    function getIntegrationAdapterWithHash(address module, bytes32 nameHash) external view returns (address) {
        return _integrations[module][nameHash];
    }

    function isValidIntegration(address module, string memory name) external view returns (bool) {
        return _integrations[module][_hashName(name)] != address(0);
    }

    /**
     * @dev GOVERNANCE FUNCTION: Add a new integration to the registry
     *
     * @param module     The address of the module associated with the integration
     * @param name       Human readable string identifying the integration
     * @param adapter    Address of the adapter contract to add
     */
    function addIntegration(
        address module,
        string memory name,
        address adapter
    ) external onlyOwner {
        _addIntegration(module, name, adapter);
    }

    /**
     * @dev GOVERNANCE FUNCTION: Batch add new adapters. Reverts if exists on any module and name
     *
     * @param modules     Array of addresses of the modules associated with integration
     * @param names       Array of human readable strings identifying the integration
     * @param adapters    Array of addresses of the adapter contracts to add
     */
    function batchAddIntegration(
        address[] memory modules,
        string[] memory names,
        address[] memory adapters
    ) external onlyOwner {
        uint256 modulesCount = modules.length;
        require(modulesCount > 0, "R0a");
        require(modulesCount == names.length, "R0b");
        require(modulesCount == adapters.length, "R0c");

        for (uint256 i = 0; i < modulesCount; i++) {
            _addIntegration(modules[i], names[i], adapters[i]);
        }
    }

    /**
     * @dev GOVERNANCE FUNCTION: Edit an existing integration on the registry
     *
     * @param module     The address of the module associated with the integration
     * @param name       Human readable string identifying the integration
     * @param adapter    Address of the adapter contract to edit
     */
    function editIntegration(
        address module,
        string memory name,
        address adapter
    ) external onlyOwner {
        _editIntegration(module, name, adapter);
    }

    /**
     * @dev GOVERNANCE FUNCTION: Batch edit adapters for modules. Reverts if module and
     * adapter name don't map to an adapter address
     *
     * @param modules     Array of addresses of the modules associated with integration
     * @param names       Array of human readable strings identifying the integration
     * @param adapters    Array of addresses of the adapter contracts to add
     */
    function batchEditIntegration(
        address[] memory modules,
        string[] memory names,
        address[] memory adapters
    ) external onlyOwner {
        uint256 modulesCount = modules.length;
        require(modulesCount > 0, "R1a");
        require(modulesCount == names.length, "R1b");
        require(modulesCount == adapters.length, "R1c");

        for (uint256 i = 0; i < modulesCount; i++) {
            _editIntegration(modules[i], names[i], adapters[i]);
        }
    }

    /**
     * @dev GOVERNANCE FUNCTION: Remove an existing integration on the registry
     *
     * @param module    The address of the module associated with the integration
     * @param name      Human readable string identifying the integration
     */
    function removeIntegration(address module, string memory name) external onlyOwner {
        bytes32 hashedName = _hashName(name);
        require(_integrations[module][hashedName] != address(0), "R2");

        address oldAdapter = _integrations[module][hashedName];
        delete _integrations[module][hashedName];

        emit RemoveIntegration(module, oldAdapter, name);
    }

    // ==================== Internal functions ====================

    /**
     * @dev Hashes the string and returns a bytes32 value
     */
    function _hashName(string memory name) internal pure returns (bytes32) {
        return keccak256(bytes(name));
    }

    function _addIntegration(
        address module,
        string memory name,
        address adapter
    ) internal {
        require(adapter != address(0), "R3a");
        require(_controller.isModule(module), "R3b");
        bytes32 hashedName = _hashName(name);
        require(_integrations[module][hashedName] == address(0), "R3c");

        _integrations[module][hashedName] = adapter;

        emit AddIntegration(module, adapter, name);
    }

    function _editIntegration(
        address module,
        string memory name,
        address adapter
    ) internal {
        require(adapter != address(0), "R4a");
        require(_controller.isModule(module), "R4b");
        bytes32 hashedName = _hashName(name);
        require(_integrations[module][hashedName] != address(0), "R4c");

        _integrations[module][hashedName] = adapter;

        emit EditIntegration(module, adapter, name);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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