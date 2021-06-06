/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

pragma solidity ^0.8.0;

contract Todo {
  event NewTask (
    string content,
    bool completed
  );

  event CompleteTask (
    bool completed
  );

  struct Task {
    string content;
    bool completed;
  }

  uint public taskCount = 0;

  mapping(uint => Task) public tasks;


  constructor(string memory _firstTodo) {
    newTask(_firstTodo);
  }

  function newTask(string memory _content) public {
    taskCount++;
    tasks[taskCount] = Task(_content, false);
    emit NewTask(_content, false);
  }

  function complete(uint _id) public {
    Task memory _task = tasks[_id];
    _task.completed = true;
    tasks[_id] = _task;
    emit CompleteTask(_task.completed);
  }

}