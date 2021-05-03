/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity 0.8.0;

contract Class_4_1 {
    
     uint public count = 0;

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
    createTask("Test Task");
  }

  function createTask(string memory _content) public {
    count ++;
    tasks[count] = Task(count, _content, false);
    emit TaskCreated(count, _content, false);
  }

  function checkTask(uint _id) public {
    Task memory _task = tasks[_id];
    _task.completed = !_task.completed;
    tasks[_id] = _task;
    emit TaskCompleted(_id, _task.completed);
  }
}