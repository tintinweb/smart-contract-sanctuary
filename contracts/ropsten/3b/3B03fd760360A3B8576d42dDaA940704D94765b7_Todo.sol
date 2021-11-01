/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity 0.5.1;

contract Todo {
    uint public taskCount = 0;
    struct Task {
        string task;
        uint task_id;
        bool completed;
    }
    mapping(uint => Task) public tasks;
    
    event TaskCreated(
        string content,
        uint id,
        bool completed
    );
    event TaskCompleted(
        uint id,
        bool completed
    );
    function createTask(string memory _content) public {
        taskCount++;
        tasks[taskCount] = Task( _content, taskCount, false );
        emit TaskCreated( _content, taskCount, false);
    }
    function toggleCompleted(uint _id) public {
        Task memory _task = tasks[_id];
        _task.completed = !_task.completed;
        tasks[_id] = _task;
        emit TaskCompleted(_id, _task.completed);
    }
     function getTask(uint _id) view public returns (string memory content , bool completed) {
        return (tasks[_id].task, tasks[_id].completed);
    }
}