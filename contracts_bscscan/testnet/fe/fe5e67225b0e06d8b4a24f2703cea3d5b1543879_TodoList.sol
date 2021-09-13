/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity ^0.5.0;

contract TodoList {

    uint public taskCount = 0;

    //model task object
    struct Task {
        uint id;
        address owner;
        string content;
        bool completed;
    }

    //put tasks in state
    mapping(uint => Task) public tasks;
    
    //my tasks
    mapping(address => uint[]) public taskOwners;

    event TaskCreated(
        uint indexed id,
        address indexed owner,
        string content,
        bool completed
    );

    event TaskCompleted(
        uint id,
        bool completed
    );

    constructor() public {
        createTask("Default task");
    }

    //add new task
    function createTask(string memory _content) public {
        taskCount++;
        tasks[taskCount] = Task(taskCount, msg.sender, _content, false);
        taskOwners[msg.sender].push(taskCount);
        emit TaskCreated(taskCount, msg.sender, _content, false);
    }

    function toggleCompleted(uint _id) public {
        Task memory _task = tasks[_id];
        _task.completed = !_task.completed;
        tasks[_id] = _task;
        emit TaskCompleted(_id, _task.completed);
    }
    
    function getOwnerTask(address _owners) public view returns (uint[] memory) {
        return taskOwners[_owners];
    }

}