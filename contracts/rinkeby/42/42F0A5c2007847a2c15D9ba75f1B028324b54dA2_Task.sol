//SPDX-License-Identifier: None
pragma solidity ^0.8.3;
import "./Model.sol";

contract Task {
    Model.Task task;

    mapping(address=> Model.Task[]) tasks;
    event TaskStarted (address indexed owner, Model.Task task);
    event TaskStopped (address indexed owner, Model.Task task);

//    function start(Model.CreateTask calldata _task, uint taskNumber) public {
//        tasks[msg.sender][taskNumber] = Model.Task(_task.Title,
//            _task.Description,
//            block.timestamp,
//            0,
//            Model.TaskStatus.Started,
//            msg.sender);
//
//        emit TaskStarted(msg.sender, tasks[msg.sender][taskNumber]);
//    }

    function start(Model.CreateTask calldata _task) public {
        Model.Task memory _newTask = Model.Task(_task.Title,
            _task.Description,
            block.timestamp,
            0,
            Model.TaskStatus.Started,
            msg.sender);

        tasks[msg.sender].push(_newTask);

        emit TaskStarted(msg.sender, _newTask);
    }

    function getTask(uint taskNumber) public view returns(Model.Task memory){
        return tasks[msg.sender][taskNumber];
    }

//    function getTasks(address owner, uint[] memory requiredTasks)  public view returns(Model.Task[] memory){
//        Model.Task[] memory array = new Model.Task[]();
//
//        for (uint counter = 0; counter < requiredTasks.length; counter++) {
//            array.push(tasks[owner][requiredTasks[counter]]);
//        }
//        return array;
//    }

    function end(uint taskNumber) public {
        tasks[msg.sender][taskNumber].Status  = Model.TaskStatus.Ended;
        tasks[msg.sender][taskNumber].EndDate  = block.timestamp;
        emit TaskStopped(msg.sender, tasks[msg.sender][taskNumber]);
    }
}