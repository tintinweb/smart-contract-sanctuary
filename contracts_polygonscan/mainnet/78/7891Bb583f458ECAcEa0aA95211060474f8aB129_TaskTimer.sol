/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
// File: contracts/Resolver.sol


pragma solidity ^0.8.0;

abstract contract Resolver {
    address public immutable action;
    address public immutable furuGelato;

    modifier onlyFuruGelato() {
        require(msg.sender == furuGelato, "not FuruGelato");
        _;
    }

    constructor(address _action, address _furuGelato) {
        action = _action;
        furuGelato = _furuGelato;
    }

    function checker(address taskCreator, bytes calldata resolverData)
        external
        view
        virtual
        returns (bool canExec, bytes memory executionData);

    function onCreateTask(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }

    function onCancelTask(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }

    function onExec(address taskCreator, bytes calldata executionData)
        external
        virtual
        onlyFuruGelato
        returns (bool)
    {
        taskCreator;
        executionData;
        return true;
    }
}

// File: contracts/DSProxyTask.sol


pragma solidity ^0.8.0;

contract DSProxyTask {
    /// @notice Return the id of the task.
    /// @param _dsProxy The creator of the task.
    /// @param _resolverAddress The resolver of the task.
    /// @param _executionData The execution data of the task.
    /// @return The task id.
    function getTaskId(
        address _dsProxy,
        address _resolverAddress,
        bytes memory _executionData
    ) public pure returns (bytes32) {
        return
            keccak256(abi.encode(_dsProxy, _resolverAddress, _executionData));
    }
}

// File: contracts/interfaces/IFuruGelato.sol


pragma solidity ^0.8.0;

interface IFuruGelato {
    event TaskCreated(
        address indexed taskCreator,
        bytes32 taskId,
        address indexed resolverAddress,
        bytes executionData
    );
    event TaskCancelled(
        address indexed taskCreator,
        bytes32 taskId,
        address indexed resolverAddress,
        bytes executionData
    );
    event ExecSuccess(
        uint256 indexed txFee,
        address indexed feeToken,
        address indexed taskExecutor,
        bytes32 taskId
    );

    event LogFundsDeposited(address indexed sender, uint256 amount);
    event LogFundsWithdrawn(
        address indexed sender,
        uint256 amount,
        address receiver
    );

    function createTask(address _resolverAddress, bytes calldata _resolverData)
        external;

    function cancelTask(address _resolverAddress, bytes calldata _resolverData)
        external;

    function exec(
        uint256 _fee,
        address _proxy,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external;

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function withdrawFunds(uint256 _amount, address payable _receiver) external;
}

interface IDSProxyBlacklist {
    function banDSProxy(address _dsProxy) external;

    function unbanDSProxy(address _dsProxy) external;

    function isValidDSProxy(address _dsProxy) external view returns (bool);
}

interface IResolverWhitelist {
    function registerResolver(address _resolverAddress) external;

    function unregisterResolver(address _resolverAddress) external;

    function isValidResolver(address _resolverAddress)
        external
        view
        returns (bool);
}

interface ITaskBlacklist {
    function banTask(bytes32 _taskId) external;

    function unbanTask(bytes32 _taskId) external;

    function isValidTask(bytes32 _taskId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: contracts/TaskTimer.sol



pragma solidity 0.8.6;





/// @title Task timer is a implementation of resolver for generating tasks
/// that can be executed repeatedly after a specific time period.
contract TaskTimer is Resolver, DSProxyTask, Ownable {
    /// @notice The last execution time of the task.
    mapping(bytes32 => uint256) public lastExecTimes;

    address public immutable aFurucombo;
    address public immutable aTrevi;
    uint256 public period;

    // solhint-disable
    // prettier-ignore
    bytes4 private constant _HARVEST_SIG =
        bytes4(keccak256(bytes("harvestAngelsAndCharge(address,address[],address[])")));
    // prettier-ignore
    bytes4 private constant _EXEC_SIG =
        bytes4(keccak256(bytes("injectAndBatchExec(address[],uint256[],address[],address[],bytes32[],bytes[])")));
    // prettier-ignore
    bytes4 private constant _DEPOSIT_SIG =
        bytes4(keccak256(bytes("deposit(address,uint256)")));
    // solhint-enable

    event PeriodSet(uint256 period);

    constructor(
        address _action,
        address _furuGelato,
        address _aFurucombo,
        address _aTrevi,
        uint256 _period
    ) Resolver(_action, _furuGelato) {
        aFurucombo = _aFurucombo;
        aTrevi = _aTrevi;
        period = _period;
    }

    /// @notice Checker can generate the execution payload for the given data
    /// that is available for an user, and also examines if the task can be
    /// executed.
    /// @param _taskCreator The creator of the task.
    /// @param _resolverData The data for resolver to generate the task.
    /// Currently identical to the execution data of DSProxy.
    /// @return If the task can be executed.
    /// @return The generated execution data for the given `_resolverData`.
    function checker(address _taskCreator, bytes calldata _resolverData)
        external
        view
        override
        returns (bool, bytes memory)
    {
        // Verify if _taskCreator is valid
        require(
            IDSProxyBlacklist(furuGelato).isValidDSProxy(_taskCreator),
            "Creator not valid"
        );
        // Verify if _resolverData is valid
        require(_isValidResolverData(_resolverData[4:]), "Data not valid");

        // Use `_resolverData` to generate task Id since that exection data
        // is resolver data in TaskTimee's implementation.
        bytes32 task = getTaskId(_taskCreator, address(this), _resolverData);
        // Verify if the task is valid
        require(ITaskBlacklist(furuGelato).isValidTask(task), "Task not valid");
        return (_isReady(task), _resolverData);
    }

    /// @notice Update the last execution time to now when a task is created.
    /// @param _taskCreator The creator of the task.
    /// @param _executionData The execution data of the task.
    function onCreateTask(address _taskCreator, bytes calldata _executionData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 task = getTaskId(_taskCreator, address(this), _executionData);
        lastExecTimes[task] = block.timestamp;

        return true;
    }

    /// @notice Delete the last execution time to now when a task is canceled.
    /// @param _taskCreator The creator of the task.
    /// @param _executionData The execution data of the task.
    function onCancelTask(address _taskCreator, bytes calldata _executionData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 taskId = getTaskId(_taskCreator, address(this), _executionData);
        delete lastExecTimes[taskId];

        return true;
    }

    /// @notice Update the last execution time to now when a task is executed.
    /// @param _taskCreator The creator of the task.
    /// @param _executionData The execution data of the task.
    function onExec(address _taskCreator, bytes calldata _executionData)
        external
        override
        onlyFuruGelato
        returns (bool)
    {
        bytes32 taskId = getTaskId(_taskCreator, address(this), _executionData);
        _reset(taskId);

        return true;
    }

    /// @notice Set the new time period for task execution.
    /// @param _period The new time period.
    function setPeriod(uint256 _period) external onlyOwner {
        period = _period;

        emit PeriodSet(_period);
    }

    function _reset(bytes32 taskId) internal {
        require(_isReady(taskId), "Not yet");
        lastExecTimes[taskId] = block.timestamp;
    }

    function _isReady(bytes32 taskId) internal view returns (bool) {
        if (lastExecTimes[taskId] == 0) {
            return false;
        } else if (block.timestamp < lastExecTimes[taskId] + period) {
            return false;
        } else {
            return true;
        }
    }

    function _isValidResolverData(bytes memory data)
        internal
        view
        returns (bool)
    {
        (address[] memory tos, , bytes[] memory datas) =
            abi.decode(data, (address[], bytes32[], bytes[]));
        require(tos.length == 3, "Invalid tos length");
        require(tos[0] == aTrevi, "Invalid tos[0]");
        require(tos[1] == aFurucombo, "Invalid tos[1]");
        require(tos[2] == aTrevi, "Invalid tos[2]");
        require(bytes4(datas[0]) == _HARVEST_SIG, "Invalid datas[0]");
        require(bytes4(datas[1]) == _EXEC_SIG, "Invalid datas[1]");
        require(bytes4(datas[2]) == _DEPOSIT_SIG, "Invalid datas[2]");

        return true;
    }
}