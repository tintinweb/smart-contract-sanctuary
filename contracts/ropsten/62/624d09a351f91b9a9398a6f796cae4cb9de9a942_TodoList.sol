/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TodoList {
    uint256 public taskCount = 0;

    struct Task {
        uint256 id;
        string taskname;
        bool status;
    }

    mapping(uint256 => Task) public tasks;

    event TaskCreated(uint256 id, string taskname, bool status);

    event TaskStatus(uint256 id, bool status);

    constructor() public {
        createTask("Todo List Tutorial");
    }

    function createTask(string memory _taskname) public {
        taskCount++;
        tasks[taskCount] = Task(taskCount, _taskname, false);
        emit TaskCreated(taskCount, _taskname, false);
    }

    function toggleStatus(uint256 _id) public {
        Task memory _task = tasks[_id];
        _task.status = !_task.status;
        tasks[_id] = _task;
        emit TaskStatus(_id, _task.status);
    }
}