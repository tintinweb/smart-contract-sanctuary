/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract TodoList {
  uint public taskCount = 0;

  struct Task {
    uint id;
    string content;
    bool completed;
  }
  mapping(uint => Task) public tasks;

  uint public rowNum;
  string[][] public data;
  mapping(uint => string[]) public uploadedData;

  constructor() {
    createTask('study blockChain');
    rowNum = 0;
  }

  function createTask(string memory _content) public {
    taskCount++;
    tasks[taskCount] = Task(taskCount, _content, false);
  }

  function completeTask(uint _id) public {
    require(_id <= taskCount);
    Task memory _task = tasks[_id];
    _task.completed = true;
    tasks[_id] = _task;
  }

  function uploadData(string[][] memory _data, uint[] memory _indexs, uint[] memory cpus) public {
    for(uint i = 0; i < _data.length; i++) {
      if(cpus[6] > 80) {
          uploadedData[_indexs[i]] = _data[i];
      }
    }
  }
  
  function getDataById(uint id) public view returns (string[] memory) {
      require(uploadedData[id].length > 0, "Empty value");
      return uploadedData[id];
  }
}