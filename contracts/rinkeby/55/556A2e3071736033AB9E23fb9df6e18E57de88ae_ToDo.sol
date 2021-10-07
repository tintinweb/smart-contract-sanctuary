/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ToDo{
    struct Task{
        uint id;
        uint date;
        string content;
        string author;
        bool done;
    }
    uint lastTaskId;
    uint[] taskId;
    mapping(uint => Task) tasks;
  constructor()  {
    lastTaskId = 0;
    }
    event TaskCreated(uint id, uint date, string content, string author, bool done);
    function createTask(string memory _content, string memory _author) public{
        lastTaskId ++;
        tasks[lastTaskId] = Task(lastTaskId, 1, _content, _author, false);
        taskId.push(lastTaskId);
       emit TaskCreated(lastTaskId, 1, _content, _author, false);
    }
    
    function getTaskId() public view returns (uint[] memory){
        return taskId;
    }
    function getTask(uint id) public view returns(uint,uint,string memory,string memory,bool){
        require(tasks[id].id > 0, "Not found id");
            return (id, tasks[id].date,tasks[id].content,tasks[id].author,tasks[id].done);
        }
}