pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/Mortal.sol

/**
 * @title Mortal
 * @notice The mortal makes a contract killable
 */
contract Mortal is Ownable {
    /**
     * @notice Kill the contract
     */
    function finish() public onlyOwner {
        selfdestruct(msg.sender);
    }
}

// File: contracts/Pausable.sol

/**
 * @title Pausable
 * @notice The Pausable enhances a contract with a emergency stop
 */
contract Pausable is Ownable {
    bool private _running;

    constructor () public {
        _running = true;
    }

    /**
     * @notice Get for running
     */
    function running() public view returns (bool) {
        return _running;
    }

    /**
     * @notice isRunning fails if the contract is paused
     */
    modifier isRunning() {
        require(_running, "You need to resume the contract");
        _;
    }

    /**
     * @notice isPaused fails if the contract is running
     */
    modifier isPaused() {
        require(!_running, "You need to pause the contract");
        _;
    }

    /**
     * @notice Pause the contract
     */
    function pause() public onlyOwner isRunning {
        _running = false;
    }

    /**
     * @notice  Resume the contract
     */
    function resume() public onlyOwner isPaused {
        _running = true;
    }

}

// File: contracts/Storage.sol

/**
 * @title Storage
 * @notice The Storage contract holds the data of Checksys inspect platform
 */
contract Storage is Mortal, Pausable {
    using SafeMath for uint256;
    uint8 public constant TASK_REQUIRES_IMAGE = 1;
    uint8 public constant TASK_REQUIRES_INFO = 2;
    uint256 public numChecklists;
    uint256 public numInspections;
    mapping(uint256 => Checklist) public checklists;
    mapping(address => Assignment) public assignments;
    enum StatusChecklist { Editing, Ready }
    enum StatusInspection { Pending, Done }

    event NewChecklist(uint256 checklist, string name);
    event ChecklistReady(uint256 checklist);
    event NewTask(uint256 checklist, uint8 task, uint8 rules, string description);
    event AssignInspection(uint256 inspection, uint256 checklist, address accountable, uint256 deadline, bytes32 id);
    event AssignmentDone(uint256 inspection);

    struct Task {
        string description;
        uint8 rules;
    }
    
    /**
     * @notice Checklist is a group of tasks that must be executed
     */
    struct Checklist {
        string name;
        uint256 createAt;
        StatusChecklist status;
        uint8 numTasks;
        mapping(uint8 => Task) tasks;
    }

    /**
     * @notice Check is the result of a executed Task
     */
    struct Check {
        bool ok;
        string info;
        string image;
    }

    /**
     * @notice Inspection is a Checklist that was appointed
     */
    struct Inspection {
        bytes32 id;
        uint256 deadline;
        uint256 checklist;
        uint256 number;
        StatusInspection status;
        uint256 assignedAt;
        uint256 executedAt;
        mapping(uint8 => Check) checks;
    }

    /**
     * @notice Assingment is a group of Inspection that someone is accountable to execute
     */
    struct Assignment {
        uint256 numAssignments;
        mapping(uint256 => Inspection) inspections;
    }
    
    /**
     * @notice Assigns a checklist creating an inspection to someone that will accoutable for its execution
     * @param _checklist Checklist index
     * @param _accountable Accountable address for its execution
     * @param _deadline Deadline date to deliver the inspection
     * @param _id Id of what is under inspection Ex. A serial number of equipament
     * @return uint256 Assignment index
     */
    function assignInspection(uint256 _checklist, address _accountable, uint256 _deadline, bytes32 _id)
    public onlyOwner
    returns (uint256) {
        // TODO: checklist must exist <= numChecklists 
        // TODO: checklist must be ready
        Assignment storage a = assignments[_accountable];
        numInspections = numInspections.add(1);
        a.numAssignments = a.numAssignments.add(1);
        a.inspections[a.numAssignments] = Inspection(_id, _deadline, _checklist, numInspections, StatusInspection.Pending, now, 0);
        emit AssignInspection(numInspections, _checklist, _accountable, _deadline, _id);
        return numInspections;
    }

    /**
     * @notice Returns the requested Inspection of an Assigment
     * @param _accountable Accountable address
     * @param _assignment Assignment index that points to the Inspection
     * @return bytes Inspection id
     * @return uint256 Inspection deadline
     * @return uint256 Inspection checklist index
     * @return uint256 Inspection number (global id)
     * @return StatusInspection Inspection status (enum)
     * @return uint256 Inspection assignedAt
     * @return uint256 Inspection executedAt
     */
    function getAssignment(address _accountable, uint256 _assignment)
    public view
    returns (bytes32, uint256, uint256, uint256, StatusInspection, uint256, uint256)
    {
        Assignment storage a = assignments[_accountable];
        Inspection storage i = a.inspections[_assignment];
        return (i.id, i.deadline, i.checklist, i.number, i.status, i.assignedAt, i.executedAt);
    }

    /**
     * @notice Returns the requested Check of a Task
     * @param _accountable Accountable address
     * @param _assignment Assignment index that points to the Inspection
     * @param _task Task index of the Checklist
     * @return bool Check ok
     * @return string Check info
     * @return string Check image
     */
    function getCheck(address _accountable, uint256 _assignment, uint8 _task)
    public view
    returns (bool, string memory, string memory)
    {
        Assignment storage a = assignments[_accountable];
        Inspection storage i = a.inspections[_assignment];
        Check storage c = i.checks[_task];
        return (c.ok, c.info, c.image);
    }

    /**
     * @notice Executes a Task creating a Check with the data
     * @notice It requires the contract to be *running* (not in emergency stop)
     * @param _assignment Assignment index that points to the Inspection
     * @param _task Task index of the Checklist
     * @param _ok The decision about the Task result
     * @param _info Information about the Task result
     * @param _image The path to the image that contains the Task result
     */
    function executeTask(uint256 _assignment, uint8 _task, bool _ok, string memory _info, string memory _image)
    public isRunning
    {
        // TODO: Assignment must be valid < contador
        Assignment storage a = assignments[msg.sender];
        Inspection storage i = a.inspections[_assignment];
        // TODO: require(_assignment > a.numAssignments, "Assignment does not exist!")
        // TODO: require(_info != "", "Must provide info") if requireInfo
        // TODO: require(_image != "", "Must provide image") if requireImage
        i.checks[_task] = Check(_ok, _info, _image);
    }

    /**
     * @notice Creates a Checklist
     * @param _name Name of the Checklist
     * @return uint256 Checklist index
     */
    function createChecklist(string memory _name)
    public onlyOwner
    returns (uint256) {
        require(bytes(_name).length > 0, "Checklist name is required");
        numChecklists = numChecklists.add(1);
        checklists[numChecklists] = Checklist(_name, now, StatusChecklist.Editing, 0);
        emit NewChecklist(numChecklists, _name);
        return numChecklists;
    }

    /**
     * @notice Add a Task to a Checklist
     * @param _checklist Checklist index
     * @param _description Description of the Task, what need to be executed
     * @param _rules Rules of the Task, if it requires some data
     * @return uint8 Task index
     */
    function addTask(uint256 _checklist, string memory _description, uint8 _rules)
    public onlyOwner
    returns (uint8) {
        // TODO: require(_checklist > numChecklists, "Checklist must exist");
        // TODO: check if has reached the task limit! (will overflow otherwise);
        Checklist storage c = checklists[_checklist];
        c.numTasks++;
        c.tasks[c.numTasks] = Task(_description, _rules);
        emit NewTask(_checklist, c.numTasks, _rules, _description);
        return c.numTasks;
    }

    /**
     * @notice Returns the requested Task of the Checklist
     * @param _checklist Checklist index
     * @param _task Task index
     * @return string Task description
     * @return uint8 Task rules
     */
    function getTask(uint256 _checklist, uint8 _task) 
    public view
    returns (string memory, uint8) {
        Checklist storage c = checklists[_checklist];
        Task storage t = c.tasks[_task];
        return (t.description, t.rules);
    }

    /**
     * @notice Change the Checklist status to Ready
     * @param _checklist Checklist index
     */
    function setChecklistReady(uint256 _checklist)
    public onlyOwner
    {
        // TODO: must have at least one task
        Checklist storage c = checklists[_checklist];
        c.status = StatusChecklist.Ready;
        emit ChecklistReady(_checklist);
    }

    /**
     * @notice Change the Inspection status to Done
     * @notice It requires the contract to be *running* (not in emergency stop)
     * @param _assignment Assignment index that points to the Inspection
     */
    function setAssignmentDone(uint256 _assignment)
    public isRunning
    {
        // TODO: all task must be executed
        Assignment storage a = assignments[msg.sender];
        Inspection storage i = a.inspections[_assignment];
        i.status = StatusInspection.Done;
        i.executedAt = now;
        emit AssignmentDone(_assignment);
    }

    /**
     * @notice Prevent accounts from directly transferring ether to the contract
     */
    function () public payable {
        revert("Don&#39;t send ETH to this contract");
    }
}