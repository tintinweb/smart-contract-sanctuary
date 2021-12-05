/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.5.0;
contract ContractToDoList {    
    struct taskRecord {
        address owner;
        bool done;
        string task;
    }
    
    taskRecord[] public toDoArray;

    event TaskLog(address owner, string task, bool done);

    function addTask(string memory task) public {
        taskRecord memory newTask = taskRecord(msg.sender, false, task);
        toDoArray.push(newTask);
        emit TaskLog(newTask.owner, newTask.task, newTask.done);
    }
    function completeTask(string memory task) public {
        taskRecord memory newTask = taskRecord(msg.sender, true, task);
        emit TaskLog(newTask.owner, newTask.task, newTask.done);
        for (uint i; i < toDoArray.length; i++) {
            string memory memoryTask = toDoArray[i].task;
            if ((keccak256(abi.encodePacked((memoryTask))) == keccak256(abi.encodePacked((task)))) && (toDoArray[i].owner == msg.sender)) {
                toDoArray[i] = newTask;
            }
        }
    }
    function getToDoList() public view returns (taskRecord[] memory) {
        return toDoArray;
    }
}