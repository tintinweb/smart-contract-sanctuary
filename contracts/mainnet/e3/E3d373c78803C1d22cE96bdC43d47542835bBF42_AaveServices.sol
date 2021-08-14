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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        return msg.data;
    }
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
pragma solidity 0.8.7;

interface IAction {
    function exec(
        bytes32 _taskHash,
        bytes memory _data,
        bytes memory _offChainData
    ) external;
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.7;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity 0.8.7;

import {ASimpleServiceStandard} from "../abstract/ASimpleServiceStandard.sol";
import {IAction} from "../../interfaces/services/actions/IAction.sol";
import {GelatoBytes} from "../../lib/GelatoBytes.sol";
import {ExecutionData} from "../../structs/SProtection.sol";

/// @author Gelato Digital
/// @title Aave Automated Services Contract.
/// @dev Automate any type of task related to Aave.
contract AaveServices is ASimpleServiceStandard {
    using GelatoBytes for bytes;

    constructor(address _gelato) ASimpleServiceStandard(_gelato) {}

    /// Submit Aave Task.
    /// @param _action Task's executor address.
    /// @param _taskData Data needed to perform the task.
    /// @param _isPermanent Defining if it's a permanent task.
    function submitTask(
        address _action,
        bytes memory _taskData,
        bool _isPermanent
    )
        external
        isActionOk(_action)
        gelatoSubmit(_action, _taskData, _isPermanent)
    {}

    /// Cancel Aave Task.
    /// @param _action Type of action (for example Protection)
    function cancelTask(address _action) external gelatoCancel(_action) {}

    /// Update Aave Task.
    /// @param _action Task's executor address.
    /// @param _data new data needed to perform the task.
    /// @param _isPermanent Defining if it's a permanent task.
    function updateTask(
        address _action,
        bytes memory _data,
        bool _isPermanent
    ) external isActionOk(_action) gelatoModify(_action, _data, _isPermanent) {}

    /// Execution of Aave Task.
    /// @param _execData data containing user, action Addr, on chain data, off chain data, is permanent.
    function exec(ExecutionData memory _execData)
        external
        isActionOk(_execData.action)
        gelatofy(
            _execData.user,
            _execData.action,
            _execData.subBlockNumber,
            _execData.data,
            _execData.isPermanent
        )
    {
        bytes memory payload = abi.encodeWithSelector(
            IAction.exec.selector,
            hashTask(
                _execData.user,
                _execData.subBlockNumber,
                _execData.data,
                _execData.isPermanent
            ),
            _execData.data,
            _execData.offChainData
        );
        (bool success, bytes memory returndata) = _execData.action.call(
            payload
        );
        if (!success) returndata.revertWithError("AaveServices.exec:");

        if (_execData.isPermanent)
            _submitTask(
                _execData.user,
                _execData.action,
                _execData.data,
                _execData.isPermanent
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ATaskStorage} from "./ATaskStorage.sol";

abstract contract ASimpleServiceStandard is ATaskStorage {
    // solhint-disable  var-name-mixedcase
    address public immutable GELATO;
    // solhint-enable var-name-mixed-case

    event LogExecSuccess(
        bytes32 indexed taskHash,
        address indexed user,
        address indexed executor
    );

    modifier gelatoSubmit(
        address _action,
        bytes memory _payload,
        bool _isPermanent
    ) {
        _submitTask(msg.sender, _action, _payload, _isPermanent);
        _;
    }

    modifier gelatoCancel(address _action) {
        _cancelTask(_action);
        _;
    }

    modifier gelatoModify(
        address _action,
        bytes memory _payload,
        bool _isPermanent
    ) {
        _modifyTask(_action, _payload, _isPermanent);
        _;
    }

    modifier gelatofy(
        address _user,
        address _action,
        uint256 _subBlockNumber,
        bytes memory _payload,
        bool _isPermanent
    ) {
        // Only GELATO vetted Executors can call
        require(
            address(GELATO) == msg.sender,
            "ASimpleServiceStandard: msg.sender != gelato"
        );

        // Verifies and removes task
        bytes32 taskHash = _verifyAndRemoveTask(
            _user,
            _action,
            _subBlockNumber,
            _payload,
            _isPermanent
        );
        _;

        emit LogExecSuccess(taskHash, _user, tx.origin);
    }

    modifier isActionOk(address _action) {
        require(
            isActionWhitelisted(_action),
            "ASimpleServiceStandard.isActionOk: notWhitelistedAction"
        );
        _;
    }

    constructor(address _gelato) {
        GELATO = _gelato;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ATaskStorage is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => mapping(address => bytes32)) public taskByUsersAction;
    EnumerableSet.AddressSet internal _actions;

    event LogTaskSubmitted(
        bytes32 indexed taskHash,
        address indexed user,
        address indexed action,
        uint256 subBlockNumber,
        bytes payload,
        bool isPermanent
    );
    event LogTaskCancelled(bytes32 indexed taskHash, address indexed user);

    function addAction(address _action) external onlyOwner returns (bool) {
        return _actions.add(_action);
    }

    function removeAction(address _action) external onlyOwner returns (bool) {
        return _actions.remove(_action);
    }

    function isTaskSubmitted(
        address _user,
        bytes32 _taskHash,
        address _action
    ) external view returns (bool) {
        return isUserTask(_user, _taskHash, _action);
    }

    function isActionWhitelisted(address _action) public view returns (bool) {
        return _actions.contains(_action);
    }

    function actions() public view returns (address[] memory actions_) {
        uint256 length = numberOfActions();
        actions_ = new address[](length);
        for (uint256 i; i < length; i++) actions_[i] = _actions.at(i);
    }

    function numberOfActions() public view returns (uint256) {
        return _actions.length();
    }

    function isUserTask(
        address _user,
        bytes32 _taskHash,
        address _action
    ) public view returns (bool) {
        return _taskHash == taskByUsersAction[_user][_action];
    }

    function hashTask(
        address _user,
        uint256 _subBlockNumber,
        bytes memory _payload,
        bool _isPermanent
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(_user, _subBlockNumber, _payload, _isPermanent)
            );
    }

    function _submitTask(
        address _user,
        address _action,
        bytes memory _payload,
        bool _isPermanent
    ) internal {
        require(
            taskByUsersAction[_user][_action] == bytes32(0),
            "ATaskStorage._submitTask : userHasTask."
        );

        bytes32 taskHash = hashTask(
            _user,
            block.number,
            _payload,
            _isPermanent
        );
        taskByUsersAction[_user][_action] = taskHash;

        emit LogTaskSubmitted(
            taskHash,
            _user,
            _action,
            block.number,
            _payload,
            _isPermanent
        );
    }

    function _cancelTask(address _action) internal {
        bytes32 userTask = taskByUsersAction[msg.sender][_action];
        require(
            userTask != bytes32(0),
            "ATaskStorage._cancelTask: noTaskToCancel"
        );

        _removeTask(msg.sender, _action);

        emit LogTaskCancelled(userTask, msg.sender);
    }

    function _verifyAndRemoveTask(
        address _user,
        address _action,
        uint256 _subBlockNumber,
        bytes memory _payload,
        bool _isPermanent
    ) internal returns (bytes32 taskHash) {
        taskHash = _verifyTask(
            _user,
            _action,
            _subBlockNumber,
            _payload,
            _isPermanent
        );
        _removeTask(_user, _action);
    }

    function _removeTask(address _user, address _action) internal {
        delete taskByUsersAction[_user][_action];
    }

    function _modifyTask(
        address _action,
        bytes memory _payload,
        bool _isPermanent
    ) internal {
        _cancelTask(_action);

        bytes32 taskHash = hashTask(
            msg.sender,
            block.number,
            _payload,
            _isPermanent
        );
        taskByUsersAction[msg.sender][_action] = taskHash;

        emit LogTaskSubmitted(
            taskHash,
            msg.sender,
            _action,
            block.number,
            _payload,
            _isPermanent
        );
    }

    function _verifyTask(
        address _user,
        address _action,
        uint256 _subBlockNumber,
        bytes memory _payload,
        bool _isPermanent
    ) internal view returns (bytes32 taskHash) {
        taskHash = hashTask(_user, _subBlockNumber, _payload, _isPermanent);
        require(
            isUserTask(_user, taskHash, _action),
            "ATaskStorage._verifyTask: !userTask"
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

struct ProtectionPayload {
    bytes32 taskHash;
    address colToken;
    address debtToken;
    uint256 rateMode;
    uint256 amtToFlashBorrow;
    uint256 amtOfDebtToRepay;
    uint256 minimumHealthFactor;
    uint256 wantedHealthFactor;
    address onBehalfOf;
    uint256 protectionFeeInETH;
    address[] swapActions;
    bytes[] swapDatas;
}

struct ExecutionData {
    address user;
    address action;
    uint256 subBlockNumber;
    bytes data;
    bytes offChainData;
    bool isPermanent;
}

struct ProtectionDataCompute {
    address colToken;
    address debtToken;
    uint256 totalCollateralETH;
    uint256 totalBorrowsETH;
    uint256 currentLiquidationThreshold;
    uint256 colLiquidationThreshold;
    uint256 wantedHealthFactor;
    uint256 colPrice;
    uint256 debtPrice;
    address onBehalfOf;
    uint256 protectionFeeInETH;
    uint256 flashloanPremiumBps;
}

struct FlashLoanData {
    address[] assets;
    uint256[] amounts;
    uint256[] premiums;
    bytes params;
}

struct FlashLoanParamsData {
    uint256 minimumHealthFactor;
    bytes32 taskHash;
    address debtToken;
    uint256 amtOfDebtToRepay;
    uint256 rateMode;
    address onBehalfOf;
    uint256 protectionFeeInETH;
    address[] swapActions;
    bytes[] swapDatas;
}

struct RepayAndFlashBorrowData {
    bytes32 id;
    address user;
    address colToken;
    address debtToken;
    uint256 wantedHealthFactor;
    uint256 protectionFeeInETH;
}

struct RepayAndFlashBorrowResult {
    bytes32 id;
    uint256 amtToFlashBorrow;
    uint256 amtOfDebtToRepay;
    string message;
}

struct CanExecData {
    bytes32 id;
    address user;
    uint256 minimumHF;
    address colToken;
    address spender;
}

struct CanExecResult {
    bytes32 id;
    bool isPositionUnSafe;
    bool isATokenAllowed;
    string message;
}

{
  "evmVersion": "london",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 2000
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