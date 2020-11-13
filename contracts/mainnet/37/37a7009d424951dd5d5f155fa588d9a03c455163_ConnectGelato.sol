pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// Gelato Data Types
struct Provider {
    address addr;  //  if msg.sender == provider => self-Provider
    address module;  //  e.g. DSA Provider Module
}

struct Condition {
    address inst;  // can be AddressZero for self-conditional Actions
    bytes data;  // can be bytes32(0) for self-conditional Actions
}

enum Operation { Call, Delegatecall }

enum DataFlow { None, In, Out, InAndOut }

struct Action {
    address addr;
    bytes data;
    Operation operation;
    DataFlow dataFlow;
    uint256 value;
    bool termsOkCheck;
}

struct Task {
    Condition[] conditions;  // optional
    Action[] actions;
    uint256 selfProviderGasLimit;  // optional: 0 defaults to gelatoMaxGas
    uint256 selfProviderGasPriceCeil;  // optional: 0 defaults to NO_CEIL
}

struct TaskReceipt {
    uint256 id;
    address userProxy;
    Provider provider;
    uint256 index;
    Task[] tasks;
    uint256 expiryDate;
    uint256 cycleId;  // auto-filled by GelatoCore. 0 for non-cyclic/chained tasks
    uint256 submissionsLeft;
}

struct TaskSpec {
    address[] conditions;   // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

// Gelato Interface
interface IGelatoInterface {

    /**
     * @dev API to submit a single Task.
    */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external;


    /**
     * @dev A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be only be an even number
    */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;


    /**
     * @dev A Gelato Task Chain consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be an odd number
    */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external;

    /**
     * @dev Cancel multiple tasks at once
    */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /**
     * @dev Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external
        payable;


    /**
     * @dev De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external;
}


interface MemoryInterface {
    function setUint(uint _id, uint _val) external;
    function getUint(uint _id) external returns (uint);
}

contract Helpers {

    /**
     * @dev Return Memory Variable Address
    */
    function getMemoryAddr() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
    */
    function setUint(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    }

    /**
     * @dev Get Uint value from InstaMemory Contract.
    */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    }

    /**
     * @dev Connector Details
    */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 42);
    }
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }
}

contract GelatoHelpers is Helpers, DSMath {

    /**
     * @dev Return Gelato Core Address
    */
    function getGelatoCoreAddr() internal pure returns (address) {
        return 0x1d681d76ce96E4d70a88A00EBbcfc1E47808d0b8; // Gelato Core address
    }

    /**
     * @dev Return Instapp DSA Provider Module Address
    */
    function getInstadappProviderModuleAddr() internal pure returns (address) {
        return 0x0C25452d20cdFeEd2983fa9b9b9Cf4E81D6f2fE2; // ProviderModuleDSA Address
    }

}


contract GelatoResolver is GelatoHelpers {

    event LogMultiProvide(address indexed executor, TaskSpec[] indexed taskspecs, address[] indexed modules, uint256 ethToDeposit, uint256 getId, uint256 setId);

    event LogSubmitTask(Provider indexed provider, Task indexed task, uint256 indexed expiryDate, uint256 getId, uint256 setId);

    event LogSubmitTaskCycle(Provider indexed provider, Task[] indexed tasks, uint256 indexed expiryDate, uint256 getId, uint256 setId);

    event LogSubmitTaskChain(Provider indexed provider, Task[] indexed tasks, uint256 indexed expiryDate, uint256 getId, uint256 setId);

    event LogMultiUnprovide(TaskSpec[] indexed taskspecs, address[] indexed modules, uint256 ethToWithdraw, uint256 getId, uint256 setId);

    event LogMultiCancelTasks(TaskReceipt[] indexed taskReceipt, uint256 getId, uint256 setId);


    // ===== Gelato ENTRY APIs ======

    /**
     * @dev Enables first time users to  pre-fund eth, whitelist an executor & register the
     * ProviderModuleDSA.sol to be able to use Gelato
     * @param _executor address of single execot node or gelato'S decentralized execution market
     * @param _taskSpecs enables external providers to whitelist TaskSpecs on gelato
     * @param _modules address of ProviderModuleDSA
     * @param _ethToDeposit amount of eth to deposit on Gelato, only for self-providers
    */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules,
        uint256 _ethToDeposit,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
    {
        uint256 ethToDeposit = getUint(_getId, _ethToDeposit);
        ethToDeposit = ethToDeposit == uint(-1) ? address(this).balance : ethToDeposit;

        IGelatoInterface(getGelatoCoreAddr()).multiProvide.value(ethToDeposit)(
            _executor,
            _taskSpecs,
            _modules
        );

        setUint(_setId, ethToDeposit);

        emit LogMultiProvide(_executor, _taskSpecs, _modules, ethToDeposit, _getId, _setId);
    }

    /**
     * @dev Submits a single, one-time task to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _task Task specifying the condition and the action connectors
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
    */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external
        payable
    {
        IGelatoInterface(getGelatoCoreAddr()).submitTask(_provider, _task, _expiryDate);

        emit LogSubmitTask(_provider, _task, _expiryDate, 0, 0);
    }

    /**
     * @dev Submits single or mulitple Task Sequences to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _cycles How often the Task List should be executed, e.g. 5 times
    */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external
        payable
    {
        IGelatoInterface(getGelatoCoreAddr()).submitTaskCycle(
            _provider,
            _tasks,
            _expiryDate,
            _cycles
        );

        emit LogSubmitTaskCycle(_provider, _tasks, _expiryDate, 0, 0);
    }

    /**
     * @dev Submits single or mulitple Task Chains to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
     * that should have occured once the cycle is complete
    */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external
        payable
    {
        IGelatoInterface(getGelatoCoreAddr()).submitTaskChain(
            _provider,
            _tasks,
            _expiryDate,
            _sumOfRequestedTaskSubmits
        );

        emit LogSubmitTaskChain(_provider, _tasks, _expiryDate, 0, 0);
    }

    // ===== Gelato EXIT APIs ======

    /**
     * @dev Withdraws funds from Gelato, de-whitelists TaskSpecs and Provider Modules
     * in one tx
     * @param _withdrawAmount Amount of ETH to withdraw from Gelato
     * @param _taskSpecs List of Task Specs to de-whitelist, default empty []
     * @param _modules List of Provider Modules to de-whitelist, default empty []
    */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
    {
        uint256 withdrawAmount = getUint(_getId, _withdrawAmount);
        uint256 balanceBefore = address(this).balance;

        IGelatoInterface(getGelatoCoreAddr()).multiUnprovide(
            withdrawAmount,
            _taskSpecs,
            _modules
        );

        uint256 actualWithdrawAmount = sub(address(this).balance, balanceBefore);

        setUint(_setId, actualWithdrawAmount);

        emit LogMultiUnprovide(_taskSpecs, _modules, actualWithdrawAmount, _getId, _setId);
    }

    /**
     * @dev Cancels outstanding Tasks
     * @param _taskReceipts List of Task Receipts to cancel
    */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts)
        external
        payable
    {
        IGelatoInterface(getGelatoCoreAddr()).multiCancelTasks(_taskReceipts);

        emit LogMultiCancelTasks(_taskReceipts, 0, 0);
    }
}


contract ConnectGelato is GelatoResolver {
    string public name = "Gelato-v1.0";
}