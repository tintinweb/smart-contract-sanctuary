/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// GyungHwan lee

pragma solidity 0.8.0;

contract likelion_5 {
    uint public taskCount = 0;
    
    struct Task {
        uint id;
        string content;
        bool completed;
    }
    
    mapping(uint => Task) public tasks;
    
    event TaskCreated(
        uint id,
        string content,
        bool completed
    );
    
    event TaskCompleted(
        uint id,
        bool completed
    );
    
    constructor() public {
        createTask("check out");
    }
    
    function createTask(string memory _content) public {
        taskCount ++;
        tasks[taskCount] = Task(taskCount, _content, false);
        emit TaskCreated(taskCount, _content, false);
    }
    
    function toggleCompleted(uint _id) public {
        Task memory _task = tasks[_id];
        _task.completed = !_task.completed;
        tasks[_id] = _task;
        emit TaskCompleted(_id, _task.completed);
    }
    
}