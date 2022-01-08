/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=  0.8.6 <= 0.9.0;

contract TaskContract {

    uint nextId;

    struct Task {
        uint id;
        string name;
        string description;
    }

    Task[] tasks;

    function createTask(string memory _name, string memory _description) public  {
        tasks.push(Task(nextId, _name, _description));
        nextId++;
    }

    function findIndex(uint _id) internal view returns(uint){
        for(uint i; i < tasks.length; i++){
            if(tasks[i].id == _id){
                return i;
            }
        }
        revert('Task no found');
    }

    function readTask(uint _id) public view returns(uint, string memory , string memory){
       uint i = findIndex(_id);
       return (tasks[i].id, tasks[i].name, tasks[i].description);
    }

    function updateTask(uint _id, string memory _name, string memory _description) public {
        uint i = findIndex(_id);
        tasks[i].name = _name; 
        tasks[i].description = _description; 
    }

    function deleteTask(uint _id) public{
        uint i = findIndex(_id);
        delete tasks[i];
    }
    
}