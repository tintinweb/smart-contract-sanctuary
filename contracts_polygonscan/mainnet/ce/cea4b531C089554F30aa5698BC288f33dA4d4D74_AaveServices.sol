/**
 *Submitted for verification at polygonscan.com on 2021-07-05
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/enums/EAaveService.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// All Types of Services
enum TaskType {Protection}

abstract contract ATaskStorage {
    mapping(address => mapping(TaskType => bytes32)) public taskByUser;

    event LogTaskSubmitted(
        bytes32 indexed taskHash,
        TaskType taskType,
        address indexed owner,
        bytes payload,
        bool isPermanent
    );
    event LogTaskCancelled(bytes32 indexed taskHash, address indexed owner);

    function isTaskSubmitted(
        address _user,
        bytes32 _taskHash,
        TaskType _taskType
    ) external view returns (bool) {
        return isUserTask(_user, _taskHash, _taskType);
    }

    function isUserTask(
        address _user,
        bytes32 _taskHash,
        TaskType _taskType
    ) public view returns (bool) {
        return _taskHash == taskByUser[_user][_taskType];
    }

    function hashTask(
        address _user,
        address _aaveAction,
        bytes memory _payload,
        bool _isPermanent
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(_user, _aaveAction, _payload, _isPermanent));
    }

    function _submitTask(
        address _user,
        TaskType _taskType,
        address _aaveAction,
        bytes memory _payload,
        bool _isPermanent
    ) internal {
        require(
            taskByUser[_user][_taskType] == bytes32(0),
            "ATaskStorage._submitTask : user has task."
        );

        bytes32 taskHash = hashTask(_user, _aaveAction, _payload, _isPermanent);
        taskByUser[_user][_taskType] = taskHash;

        emit LogTaskSubmitted(
            taskHash,
            _taskType,
            _user,
            _payload,
            _isPermanent
        );
    }

    function _cancelTask(TaskType _taskType) internal {
        bytes32 userTask = taskByUser[msg.sender][_taskType];
        _removeTask(msg.sender, _taskType);
        emit LogTaskCancelled(userTask, msg.sender);
    }

    function _verifyAndRemoveTask(
        address _user,
        TaskType _taskType,
        address _aaveAction,
        bytes memory _payload,
        bool _isPermanent
    ) internal returns (bytes32 taskHash) {
        taskHash = _verifyTask(
            _user,
            _taskType,
            _aaveAction,
            _payload,
            _isPermanent
        );
        _removeTask(_user, _taskType);
    }

    function _removeTask(address _user, TaskType _taskType) internal {
        delete taskByUser[_user][_taskType];
    }

    function _modifyTask(
        TaskType _taskType,
        address _aaveAction,
        bytes memory _payload,
        bool _isPermanent
    ) internal {
        _cancelTask(_taskType);

        bytes32 taskHash =
            hashTask(msg.sender, _aaveAction, _payload, _isPermanent);
        taskByUser[msg.sender][_taskType] = taskHash;

        emit LogTaskSubmitted(
            taskHash,
            _taskType,
            msg.sender,
            _payload,
            _isPermanent
        );
    }

    function _verifyTask(
        address _user,
        TaskType _taskType,
        address _aaveAction,
        bytes memory _payload,
        bool _isPermanent
    ) internal view returns (bytes32 taskHash) {
        taskHash = hashTask(_user, _aaveAction, _payload, _isPermanent);
        require(
            isUserTask(_user, taskHash, _taskType),
            "ATaskStorage._verifyTask: !ownerTask"
        );
    }
}

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
        TaskType _taskType,
        address _aaveAction,
        bytes memory _payload,
        bool _isPermanent
    ) {
        _submitTask(msg.sender, _taskType, _aaveAction, _payload, _isPermanent);
        _;
    }

    modifier gelatoCancel(TaskType _taskType) {
        _cancelTask(_taskType);
        _;
    }

    modifier gelatoModify(
        TaskType _taskType,
        address _aaveAction,
        bytes memory _payload,
        bool _isPermanent
    ) {
        _modifyTask(_taskType, _aaveAction, _payload, _isPermanent);
        _;
    }

    modifier gelatofy(
        address _user,
        TaskType _taskType,
        address _aaveAction,
        bytes memory _payload,
        bool _isPermanent
    ) {
        // Only GELATO vetted Executors can call
        require(
            address(GELATO) == msg.sender,
            "ASimpleServiceStandard: msg.sender != gelato"
        );

        // Verifies and removes task
        bytes32 taskHash =
            _verifyAndRemoveTask(
                _user,
                _taskType,
                _aaveAction,
                _payload,
                _isPermanent
            );
        _;

        emit LogExecSuccess(taskHash, _user, tx.origin);
    }

    constructor(address _gelato) {
        GELATO = _gelato;
    }
}

interface IAction {
    function exec(bytes memory _data, bytes memory _offChainData) external;
}

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

/// @author Gelato Digital
/// @title Aave Automated Services Contract.
/// @dev Automate any type of task related to Aave.
contract AaveServices is ASimpleServiceStandard {
    using GelatoBytes for bytes;

    constructor(address _gelato) ASimpleServiceStandard(_gelato) {}

    /// Submit Aave Task.
    /// @param _taskType Type of action (for example Protection)
    /// @param _aaveAction Task's executor address.
    /// @param _taskData Data needed to perform the task.
    /// @param _isPermanent Defining if it's a permanent task.
    function submitTask(
        TaskType _taskType,
        address _aaveAction,
        bytes memory _taskData,
        bool _isPermanent
    ) external gelatoSubmit(_taskType, _aaveAction, _taskData, _isPermanent) {}

    /// Cancel Aave Task.
    /// @param _taskType Type of action (for example Protection)
    function cancelTask(TaskType _taskType) external gelatoCancel(_taskType) {}

    /// Update Aave Task.
    /// @param _taskType Type of action (for example Protection)
    /// @param _aaveAction Task's executor address.
    /// @param _data new data needed to perform the task.
    /// @param _isPermanent Defining if it's a permanent task.
    function updateTask(
        TaskType _taskType,
        address _aaveAction,
        bytes memory _data,
        bool _isPermanent
    ) external gelatoModify(_taskType, _aaveAction, _data, _isPermanent) {}

    /// Execution of Aave Task.
    /// @param _user User onbehalf who we execute the task.
    /// @param _taskType Type of action (for example Protection)
    /// @param _aaveAction Task's executor address.
    /// @param _data Data needed to perform the task.
    /// @param _offChainData Data computed off-chain and needed to perform the task.
    /// @param _isPermanent Defining if it's a permanent task.
    function exec(
        address _user,
        TaskType _taskType,
        address _aaveAction,
        bytes memory _data,
        bytes memory _offChainData,
        bool _isPermanent
    ) external gelatofy(_user, _taskType, _aaveAction, _data, _isPermanent) {
        bytes memory payload =
            abi.encodeWithSelector(IAction.exec.selector, _data, _offChainData);
        (bool success, bytes memory returndata) = _aaveAction.call(payload);
        if (!success) returndata.revertWithError("AaveServices._exec:");

        if (_isPermanent)
            _submitTask(_user, _taskType, _aaveAction, _data, _isPermanent);
    }
}