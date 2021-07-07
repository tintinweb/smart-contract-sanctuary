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

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.0 <0.8.0;

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

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/21/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {
  /**
   * Finds the index of the first occurrence of the given element.
   * @param A The input array to search
   * @param a The value to find
   * @return Returns (index and isIn) for the first occurrence starting from index 0
   */
  function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
    uint256 length = A.length;
    for (uint256 i = 0; i < length; i++) {
      if (A[i] == a) {
        return (i, true);
      }
    }
    return (uint256(-1), false);
  }

  /**
   * Returns true if the value is present in the list. Uses indexOf internally.
   * @param A The input array to search
   * @param a The value to find
   * @return Returns isIn for the first occurrence starting from index 0
   */
  function contains(address[] memory A, address a) internal pure returns (bool) {
    (, bool isIn) = indexOf(A, a);
    return isIn;
  }

  /**
   * Returns true if there are 2 elements that are the same in an array
   * @param A The input array to search
   * @return Returns boolean for the first occurrence of a duplicate
   */
  function hasDuplicate(address[] memory A) internal pure returns (bool) {
    require(A.length > 0, "A is empty");

    for (uint256 i = 0; i < A.length - 1; i++) {
      address current = A[i];
      for (uint256 j = i + 1; j < A.length; j++) {
        if (current == A[j]) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * @param A The input array to search
   * @param a The address to remove
   * @return Returns the array with the object removed.
   */
  function remove(address[] memory A, address a) internal pure returns (address[] memory) {
    (uint256 index, bool isIn) = indexOf(A, a);
    if (!isIn) {
      revert("Address not in array.");
    } else {
      (address[] memory _A, ) = pop(A, index);
      return _A;
    }
  }

  /**
   * @param A The input array to search
   * @param a The address to remove
   */
  function removeStorage(address[] storage A, address a) internal {
    (uint256 index, bool isIn) = indexOf(A, a);
    if (!isIn) {
      revert("Address not in array.");
    } else {
      uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
      if (index != lastIndex) {
        A[index] = A[lastIndex];
      }
      A.pop();
    }
  }

  /**
   * Removes specified index from array
   * @param A The input array to search
   * @param index The index to remove
   * @return Returns the new array and the removed entry
   */
  function pop(address[] memory A, uint256 index)
    internal
    pure
    returns (address[] memory, address)
  {
    uint256 length = A.length;
    require(index < A.length, "Index must be < A length");
    address[] memory newAddresses = new address[](length - 1);
    for (uint256 i = 0; i < index; i++) {
      newAddresses[i] = A[i];
    }
    for (uint256 j = index + 1; j < length; j++) {
      newAddresses[j - 1] = A[j];
    }
    return (newAddresses, A[index]);
  }

  /**
   * Returns the combination of the two arrays
   * @param A The first array
   * @param B The second array
   * @return Returns A extended by B
   */
  function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
    uint256 aLength = A.length;
    uint256 bLength = B.length;
    address[] memory newAddresses = new address[](aLength + bLength);
    for (uint256 i = 0; i < aLength; i++) {
      newAddresses[i] = A[i];
    }
    for (uint256 j = 0; j < bLength; j++) {
      newAddresses[aLength + j] = B[j];
    }
    return newAddresses;
  }

  /**
   * Validate that address and uint array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of uint
   */
  function validatePairsWithArray(address[] memory A, uint256[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and bool array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of bool
   */
  function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and string array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of strings
   */
  function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address array lengths match, and calling address array are not empty
   * and contain no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of addresses
   */
  function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate that address and bytes array lengths match. Validate address array is not empty
   * and contains no duplicate elements.
   *
   * @param A         Array of addresses
   * @param B         Array of bytes
   */
  function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
    require(A.length == B.length, "Array length mismatch");
    _validateLengthAndUniqueness(A);
  }

  /**
   * Validate address array is not empty and contains no duplicate elements.
   *
   * @param A          Array of addresses
   */
  function _validateLengthAndUniqueness(address[] memory A) internal pure {
    require(A.length > 0, "Array length must be > 0");
    require(!hasDuplicate(A), "Cannot duplicate addresses");
  }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AddressArrayUtils} from "../lib/AddressArrayUtils.sol";

/**
 * @title Controller
 * @author Set Protocol
 *
 * Contract that houses state for approvals and system contracts such as added Sets,
 * modules, factories, resources (like price oracles), and protocol fee configurations.
 */
contract Controller is Ownable {
  using AddressArrayUtils for address[];

  /* ============ Events ============ */

  event FactoryAdded(address indexed _factory);
  event FactoryRemoved(address indexed _factory);
  event FeeEdited(address indexed _module, uint256 indexed _feeType, uint256 _feePercentage);
  event FeeRecipientChanged(address _newFeeRecipient);
  event ModuleAdded(address indexed _module);
  event ModuleRemoved(address indexed _module);
  event ResourceAdded(address indexed _resource, uint256 _id);
  event ResourceRemoved(address indexed _resource, uint256 _id);
  event SetAdded(address indexed _setToken, address indexed _factory);
  event SetRemoved(address indexed _setToken);

  /* ============ Modifiers ============ */

  /**
   * Throws if function is called by any address other than a valid factory.
   */
  modifier onlyFactory() {
    require(isFactory[msg.sender], "Only valid factories can call");
    _;
  }

  modifier onlyInitialized() {
    require(isInitialized, "Contract must be initialized.");
    _;
  }

  /* ============ State Variables ============ */

  // List of enabled Sets
  address[] public sets;
  // List of enabled factories of SetTokens
  address[] public factories;
  // List of enabled Modules; Modules extend the functionality of SetTokens
  address[] public modules;
  // List of enabled Resources; Resources provide data, functionality, or
  // permissions that can be drawn upon from Module, SetTokens or factories
  address[] public resources;

  // Mappings to check whether address is valid Set, Factory, Module or Resource
  mapping(address => bool) public isSet;
  mapping(address => bool) public isFactory;
  mapping(address => bool) public isModule;
  mapping(address => bool) public isResource;

  // Mapping of modules to fee types to fee percentage. A module can have multiple feeTypes
  // Fee is denominated in precise unit percentages (100% = 1e18, 1% = 1e16)
  mapping(address => mapping(uint256 => uint256)) public fees;

  // Mapping of resource ID to resource address, which allows contracts to fetch the correct
  // resource while providing an ID
  mapping(uint256 => address) public resourceId;

  // Recipient of protocol fees
  address public feeRecipient;

  // Return true if the controller is initialized
  bool public isInitialized;

  /* ============ Constructor ============ */

  /**
   * Initializes the initial fee recipient on deployment.
   *
   * @param _feeRecipient          Address of the initial protocol fee recipient
   */
  constructor(address _feeRecipient) {
    feeRecipient = _feeRecipient;
  }

  /* ============ External Functions ============ */

  /**
   * Initializes any predeployed factories, modules, and resources post deployment. Note: This function can
   * only be called by the owner once to batch initialize the initial system contracts.
   *
   * @param _factories             List of factories to add
   * @param _modules               List of modules to add
   * @param _resources             List of resources to add
   * @param _resourceIds           List of resource IDs associated with the resources
   */
  function initialize(
    address[] memory _factories,
    address[] memory _modules,
    address[] memory _resources,
    uint256[] memory _resourceIds
  ) external onlyOwner {
    require(!isInitialized, "Controller is already initialized");
    require(_resources.length == _resourceIds.length, "Array lengths do not match.");

    factories = _factories;
    modules = _modules;
    resources = _resources;

    // Loop through and initialize isModule, isFactory, and isResource mapping
    for (uint256 i = 0; i < _factories.length; i++) {
      require(_factories[i] != address(0), "Zero address submitted.");
      isFactory[_factories[i]] = true;
    }
    for (uint256 i = 0; i < _modules.length; i++) {
      require(_modules[i] != address(0), "Zero address submitted.");
      isModule[_modules[i]] = true;
    }

    for (uint256 i = 0; i < _resources.length; i++) {
      require(_resources[i] != address(0), "Zero address submitted.");
      require(resourceId[_resourceIds[i]] == address(0), "Resource ID already exists");
      isResource[_resources[i]] = true;
      resourceId[_resourceIds[i]] = _resources[i];
    }

    // Set to true to only allow initialization once
    isInitialized = true;
  }

  /**
   * PRIVILEGED FACTORY FUNCTION. Adds a newly deployed SetToken as an enabled SetToken.
   *
   * @param _setToken               Address of the SetToken contract to add
   */
  function addSet(address _setToken) external onlyInitialized onlyFactory {
    require(!isSet[_setToken], "Set already exists");

    isSet[_setToken] = true;

    sets.push(_setToken);

    emit SetAdded(_setToken, msg.sender);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a Set
   *
   * @param _setToken               Address of the SetToken contract to remove
   */
  function removeSet(address _setToken) external onlyInitialized onlyOwner {
    require(isSet[_setToken], "Set does not exist");

    sets = sets.remove(_setToken);

    isSet[_setToken] = false;

    emit SetRemoved(_setToken);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a factory
   *
   * @param _factory               Address of the factory contract to add
   */
  function addFactory(address _factory) external onlyInitialized onlyOwner {
    require(!isFactory[_factory], "Factory already exists");

    isFactory[_factory] = true;

    factories.push(_factory);

    emit FactoryAdded(_factory);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a factory
   *
   * @param _factory               Address of the factory contract to remove
   */
  function removeFactory(address _factory) external onlyInitialized onlyOwner {
    require(isFactory[_factory], "Factory does not exist");

    factories = factories.remove(_factory);

    isFactory[_factory] = false;

    emit FactoryRemoved(_factory);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a module
   *
   * @param _module               Address of the module contract to add
   */
  function addModule(address _module) external onlyInitialized onlyOwner {
    require(!isModule[_module], "Module already exists");

    isModule[_module] = true;

    modules.push(_module);

    emit ModuleAdded(_module);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a module
   *
   * @param _module               Address of the module contract to remove
   */
  function removeModule(address _module) external onlyInitialized onlyOwner {
    require(isModule[_module], "Module does not exist");

    modules = modules.remove(_module);

    isModule[_module] = false;

    emit ModuleRemoved(_module);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a resource
   *
   * @param _resource               Address of the resource contract to add
   * @param _id                     New ID of the resource contract
   */
  function addResource(address _resource, uint256 _id) external onlyInitialized onlyOwner {
    require(!isResource[_resource], "Resource already exists");

    require(resourceId[_id] == address(0), "Resource ID already exists");

    isResource[_resource] = true;

    resourceId[_id] = _resource;

    resources.push(_resource);

    emit ResourceAdded(_resource, _id);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a resource
   *
   * @param _id               ID of the resource contract to remove
   */
  function removeResource(uint256 _id) external onlyInitialized onlyOwner {
    address resourceToRemove = resourceId[_id];

    require(resourceToRemove != address(0), "Resource does not exist");

    resources = resources.remove(resourceToRemove);

    delete resourceId[_id];

    isResource[resourceToRemove] = false;

    emit ResourceRemoved(resourceToRemove, _id);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a fee to a module
   *
   * @param _module               Address of the module contract to add fee to
   * @param _feeType              Type of the fee to add in the module
   * @param _newFeePercentage     Percentage of fee to add in the module (denominated in preciseUnits eg 1% = 1e16)
   */
  function addFee(
    address _module,
    uint256 _feeType,
    uint256 _newFeePercentage
  ) external onlyInitialized onlyOwner {
    require(isModule[_module], "Module does not exist");

    require(fees[_module][_feeType] == 0, "Fee type already exists on module");

    fees[_module][_feeType] = _newFeePercentage;

    emit FeeEdited(_module, _feeType, _newFeePercentage);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit a fee in an existing module
   *
   * @param _module               Address of the module contract to edit fee
   * @param _feeType              Type of the fee to edit in the module
   * @param _newFeePercentage     Percentage of fee to edit in the module (denominated in preciseUnits eg 1% = 1e16)
   */
  function editFee(
    address _module,
    uint256 _feeType,
    uint256 _newFeePercentage
  ) external onlyInitialized onlyOwner {
    require(isModule[_module], "Module does not exist");

    require(fees[_module][_feeType] != 0, "Fee type does not exist on module");

    fees[_module][_feeType] = _newFeePercentage;

    emit FeeEdited(_module, _feeType, _newFeePercentage);
  }

  /**
   * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol fee recipient
   *
   * @param _newFeeRecipient      Address of the new protocol fee recipient
   */
  function editFeeRecipient(address _newFeeRecipient) external onlyInitialized onlyOwner {
    require(_newFeeRecipient != address(0), "Address must not be 0");

    feeRecipient = _newFeeRecipient;

    emit FeeRecipientChanged(_newFeeRecipient);
  }

  /* ============ External Getter Functions ============ */

  function getModuleFee(address _moduleAddress, uint256 _feeType) external view returns (uint256) {
    return fees[_moduleAddress][_feeType];
  }

  function getFactories() external view returns (address[] memory) {
    return factories;
  }

  function getModules() external view returns (address[] memory) {
    return modules;
  }

  function getResources() external view returns (address[] memory) {
    return resources;
  }

  function getSets() external view returns (address[] memory) {
    return sets;
  }

  /**
   * Check if a contract address is a module, Set, resource, factory or controller
   *
   * @param  _contractAddress           The contract address to check
   */
  function isSystemContract(address _contractAddress) external view returns (bool) {
    return (isSet[_contractAddress] ||
      isModule[_contractAddress] ||
      isResource[_contractAddress] ||
      isFactory[_contractAddress] ||
      _contractAddress == address(this));
  }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}