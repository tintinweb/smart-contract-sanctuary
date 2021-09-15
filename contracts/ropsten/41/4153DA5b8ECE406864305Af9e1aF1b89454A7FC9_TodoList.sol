/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract TodoList {
 uint public taskCount = 0;

 struct Task {
   uint id;
   string taskname;
   bool status;
 }

 mapping(uint => Task) public tasks;

 event TaskCreated(
   uint id,
   string taskname,
   bool status
 );

 event TaskStatus(
   uint id,
   bool status
 );

 constructor() public {
   createTask("Todo List Tutorial");
 }

 function createTask(string memory _taskname) public {
   taskCount ++;
   tasks[taskCount] = Task(taskCount, _taskname, false);
   emit TaskCreated(taskCount, _taskname, false);
 }

 function toggleStatus(uint _id) public {
   Task memory _task = tasks[_id];
   _task.status = !_task.status;
   tasks[_id] = _task;
   emit TaskStatus(_id, _task.status);
 }

}