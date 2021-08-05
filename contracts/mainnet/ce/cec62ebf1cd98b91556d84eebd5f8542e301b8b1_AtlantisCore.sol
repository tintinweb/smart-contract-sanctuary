/**
 *Submitted for verification at Etherscan.io on 2020-12-30
*/

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/AtlantisCore.sol

pragma solidity <=0.6.2;


interface ITask {
    function check(uint _requirement) external view returns (uint256);
    function execute() external;
}

interface IWhirlpool {
    function claim() external;
    function getAllInfoFor(address _user) external view returns (bool isActive, uint256[12] memory info);
}

interface ISURF3D {
    function dividendsOf(address _user) external view returns (uint256);
    function withdraw() external returns (uint256);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

contract AtlantisCore is Ownable {
    IFreeFromUpTo public constant gst = IFreeFromUpTo(0x0000000000b3F879cb30FE243b4Dfee438691c04);
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    address private constant _surf = 0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c;
    address private constant _surf3D = 0xeb620A32Ea11FcAa1B3D70E4CFf6500B85049C97;
    address private constant _whirlpool = 0x999b1e6EDCb412b59ECF0C5e14c20948Ce81F40b;

    address[] public processors;

    // track the total amount of incentive burned by this core
    uint private _totalBurned;

    // track the total amount of tasks created
    uint private _totalTasks;

    // mapping of task IDs to respective struct
    mapping (uint => Task) private _taskMap;

    // mapping of addresses to total incentive received
    mapping (address => uint) private _totalIncentiveReceived;
    
    // mapping of addresses to total tasks executed
    mapping (address => uint) private _totalTasksByProcessor;

    // mapping of task IDs to when they were last executed (unix timestamp). used for throttle
    mapping (uint => uint) private _taskTimestamp;

    // mapping indiciating that an address has processed for this core at least once
    mapping (address => bool) private _processed;

    // mapping of processor addressses to when they were last seen by this core
    mapping (address => uint) public processorTimestamp;

    struct Task {
        // address of the contract which implements the ITask interface
        address process;
        // is this task enabled?
        bool enabled;
        // how much SURF will incentivize this task
        uint incentive;
        // ratio of incentive to burn, send rest to caller. 0 = disabled, 1 = 100%, 2 = 50%, 3 = 33%, 4 = 25%, etc
        uint burnRatio;
        // how much time to wait before allowing this task to be executed again. 0 = disable
        uint throttle;
        // task requirement variable - used for minimum balance checks etc
        uint requirement;
    }

    modifier discountGST {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        gst.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }

    constructor()
    public {
        _taskMap[0] = Task({
            process: address(0x0),
            enabled: true,
            incentive: 200 ether,       // 200 SURF (100 received)
            burnRatio: 2,               // burn 50%
            throttle: 1 weeks,          // every week
            requirement: 1000 ether     // if the whirlpool rewards are more than 1000 SURF
        });

        _totalTasks++;
    }

    function _check(uint _requirement)
    internal view returns (uint256) {
       (, uint256[12] memory userData) = IWhirlpool(_whirlpool).getAllInfoFor(address(this));

        if(userData[10] >= _requirement)
            return 0;
        else
            return _requirement - userData[10];
    }

    function _execute()
    internal {
        IWhirlpool(_whirlpool).claim();

        if(ISURF3D(_surf3D).dividendsOf(address(this)) > 0)
            ISURF3D(_surf3D).withdraw();
    }

    function _process(uint _taskID, address _processor)
    internal {
        // only allow execution if the timestamp throttle is expired
        require(block.timestamp >= _taskTimestamp[_taskID] + _taskMap[_taskID].throttle, "");
        // only allow execution if the task is enabled (incentives active)
        require(_taskMap[_taskID].enabled, "");

        // load requirement
        uint requirement = _taskMap[_taskID].requirement;
        address taskProcess = _taskMap[_taskID].process;

        // only allow execution if the task requirements are met - if any
        if(requirement > 0)
            require(_taskID == 0 ? _check(requirement) == 0 : ITask(taskProcess).check(requirement) == 0, "");

        // load other variables 
        uint incentive = _taskMap[_taskID].incentive;
        uint burnRatio = _taskMap[_taskID].burnRatio;
        
        // execute the task
        _taskID == 0 ? _execute() : ITask(taskProcess).execute();

        // if this is the first time they are processing a task
        if(!_processed[_processor]) {
            _processed[_processor] = true;
            processors.push(_processor);
        }

        processorTimestamp[_processor] = block.timestamp;

        // burn whatever amount of tokens specified by the burnRatio - if any
        if(burnRatio != 0)
            IERC20(_surf).transfer(_surf, incentive / burnRatio);

        uint incentiveReceived = burnRatio == 0 ? incentive : incentive - (incentive / burnRatio);

        IERC20(_surf).transfer(_processor, incentiveReceived);

        _totalIncentiveReceived[_processor] += incentiveReceived;

        if(incentive - incentiveReceived > 0)
            _totalBurned += (incentive - incentiveReceived);

        _totalTasksByProcessor[_processor]++;
        _taskTimestamp[_taskID] = block.timestamp;
    }

    function addTask(address _taskProcess, uint _incentive, uint _burnRatio, uint _throttle, uint _requirement)
    external onlyOwner {
        _taskMap[_totalTasks] = Task({
            process: _taskProcess,
            enabled: true,
            incentive: _incentive,
            burnRatio: _burnRatio,
            throttle: _throttle,
            requirement: _requirement
        });

        _totalTasks++;
    }

    function editTask(uint _taskID, address _taskProcess, bool _enabled, uint _incentive, uint _burnRatio, uint _throttle, uint _requirement)
    external onlyOwner {
        _taskMap[_taskID] = Task({
            process: _taskProcess,
            enabled: _enabled,
            incentive: _incentive,
            burnRatio: _burnRatio,
            throttle: _throttle,
            requirement: _requirement
        });
    }

    function process(uint _taskID, address _processor)
    external {
        // if the contract is calling itself via the bulkProcess() loop
        if(msg.sender == address(this))
            _process(_taskID, _processor);
        else
            _process(_taskID, msg.sender);
    }

    function processCHI(uint _taskID)
    external discountCHI {
        _process(_taskID, msg.sender);
    }

    function processGST(uint _taskID)
    external discountGST {
        _process(_taskID, msg.sender);
    }

    function bulkProcess(uint256[] calldata _taskIDs)
    external {
        // loop through all specified task IDs
        for(uint x = 0; x < _taskIDs.length; x++)
            // manually call process() - if the tx fails (due to task being executed while tx is in transit etc) we ignore it and proceed instead of reverting the entire tx
            address(this).call(abi.encodeWithSignature("process(uint256,address)", _taskIDs[x], msg.sender));
    }

    function bulkProcessCHI(uint256[] calldata _taskIDs)
    external discountCHI {
        // loop through all specified task IDs
        for(uint x = 0; x < _taskIDs.length; x++)
            // manually call process() - if the tx fails (due to task being executed while tx is in transit etc) we ignore it and proceed instead of reverting the entire tx
            address(this).call(abi.encodeWithSignature("process(uint256,address)", _taskIDs[x], msg.sender));
    }

    function bulkProcessGST(uint256[] calldata _taskIDs)
    external discountGST {
        // loop through all specified task IDs
        for(uint x = 0; x < _taskIDs.length; x++)
            // manually call process() - if the tx fails (due to task being executed while tx is in transit etc) we ignore it and proceed instead of reverting the entire tx
            address(this).call(abi.encodeWithSignature("process(uint256,address)", _taskIDs[x], msg.sender));
    }

    function check(uint _requirement)
    external view returns (uint256) {
        return _check(_requirement);
    }

    function viewStatsFor(address _processor)
    external view returns (uint256, uint256) {
        return (_totalIncentiveReceived[_processor], _totalTasksByProcessor[_processor]);
    }

    function viewCore()
    external view returns (uint256, uint256) {
        return (_totalBurned, _totalTasks);
    }

    function viewAllStatsFor(address _processor)
    external view returns (uint256, uint256, uint256, uint256) {
        return (_totalIncentiveReceived[_processor], _totalTasksByProcessor[_processor], _totalBurned, _totalTasks);
    }

    function viewTask(uint _taskID)
    external view returns (bool, uint256, uint256, uint256, uint256) {
        return (_taskMap[_taskID].enabled, _taskMap[_taskID].incentive, _taskMap[_taskID].burnRatio, _taskMap[_taskID].throttle, _taskMap[_taskID].requirement);
    }

    // returns time left and requirement left (if any)
    function viewTaskCheck(uint _taskID)
    external view returns (uint256, uint256) {
        uint throttleTimeLeft;

        if(_taskTimestamp[_taskID] + _taskMap[_taskID].throttle > block.timestamp)
            throttleTimeLeft = (_taskTimestamp[_taskID] + _taskMap[_taskID].throttle) - block.timestamp;
        else
            throttleTimeLeft = 0;

        return (throttleTimeLeft, _taskID == 0 ? _check(_taskMap[_taskID].requirement) : ITask(_taskMap[_taskID].process).check(_taskMap[_taskID].requirement));
    }

    function viewProcessorLength()
    external view returns (uint256) {
        return processors.length;
    }

    function viewProcessors()
    external view returns (address[] memory) {
        return processors;
    }
}