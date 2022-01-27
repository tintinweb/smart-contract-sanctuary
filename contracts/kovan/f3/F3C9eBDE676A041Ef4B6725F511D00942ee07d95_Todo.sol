/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Todo{
    uint id;
    constructor(){
        id = 0;
    }

    event taskCreated(uint indexed id, string indexed taskName);

    struct Task{
        string taskName;
        bool active;
    }

    mapping (uint => Task) tasks;

    function addTask(string memory _taskName) external {
        tasks[id] = Task(_taskName, true);
        emit taskCreated(id, _taskName);
        id++;
    }

    function completeTask(uint _id) external {
        tasks[_id].active = false;
    }

    function getNumberofTasks() external view returns(uint){
        return id;
    }

    function getActiveTasks() external view returns(string memory){
        string memory t;
        for(uint i = 0; i< id; i++){
            Task memory temp = tasks[i];
            if(temp.active == true){
                //return temp.taskName;
                t = concat(t, temp.taskName);
            }
        }
        return t;
    }

    function concat(string memory a, string memory b) internal pure returns(string memory){
        return(string(abi.encodePacked(a," ",b)));
    }

    function getNumberofActiveTasks() external view returns(uint){
        uint active = 0;
        for(uint i = 0; i< id; i++){
            Task memory temp = tasks[i];
            if(temp.active == true){
                active++;
            }
        }
        return active;
    }

    function getNumberofCompletedTasks() external view returns(uint){
        uint completed = 0;
        for(uint i = 0; i< id; i++){
            Task memory temp = tasks[i];
            if(temp.active == false){
                completed++;
            }
        }
        return completed;
    }

}