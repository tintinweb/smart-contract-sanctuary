/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TodoList {
uint public taskCount = 0;
    struct Task {
        uint id;
        string content;
        bool completed;
    }

    event TaskCreated (
        uint id,
        string content,
        bool completed
    );

    event TaskCompleted (
        uint id,
        bool completed
    );

    constructor() public {
        createTask("This a placeholder task");
    }

    mapping(uint => Task) public tasks;

    function createTask(string memory _content) public {
        taskCount ++;
        tasks[taskCount] = Task(taskCount, _content, false);
        emit TaskCreated(taskCount, _content, false);
    }

    function toggleComplete(uint _id) public {
        Task memory _task = tasks[_id];
        _task.completed = ! _task.completed;
        tasks[_id] = _task;
        emit TaskCompleted(_id, _task.completed);

    }
}