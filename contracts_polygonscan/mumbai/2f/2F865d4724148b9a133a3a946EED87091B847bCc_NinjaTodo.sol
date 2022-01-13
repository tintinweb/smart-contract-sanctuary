//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract NinjaTodo {

    // VARIABLES
    string private appName;

    string[] private tasks;

    mapping (string => bool) statuses; // task status (false is uncompleted, true is completed)

    // CONSTRUCTOR
    constructor() {
        appName = "Ninja Todo dApp2";
    }

    // READ FUNCTIONS
    function dappName() public view returns (string memory) {
        return appName;
    }

    function getTasksLength() public view returns (uint) {
        return tasks.length;
    }

    function getAllTasks() public view returns (string[] memory) {
        return tasks;
    }

    function getTaskByIndex(uint _index) public view returns (string memory) {
        return tasks[_index];
    }

    function getTaskStatus(string memory _task) public view returns (bool) {
        return statuses[_task];
    }

    // WRITE FUNCTIONS
    function addNewTask(string memory _task) public {
        tasks.push(_task); // add task to the array
        statuses[_task] = false; // set task completion status as false
    }

    function toggleTaskStatus(string memory _task) public {
        statuses[_task] = !statuses[_task]; // change status boolean to the opposite of what it was before
    }
}