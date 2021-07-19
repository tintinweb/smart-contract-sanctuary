// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Task.sol";

contract Label {

    User users;
    Task tasks;

    constructor(address _user_contract, address _task_contract) {
        require(_user_contract != address(0),"Contracts cannot be 0 address");
        require(_task_contract != address(0),"Contracts cannot be 0 address");
        users = User(_user_contract);
        tasks = Task(_task_contract);
    }

    struct LabelEntity {
        uint label_id;
        uint user_id; // user id
        string label_name; // name of label
        string label_color; // background color of label

    }
    LabelEntity[] private labels;

    struct LabelTask {
        uint label_id;
        uint task_id;
        uint user_id;
    }
    LabelTask[] private labelTasks;

    // create label by user
    function create(uint label_id, string memory label_name, string memory label_color) public returns(bool) {
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        labels.push(LabelEntity(label_id, _user_id, label_name, label_color));
        return true;
    }

    // update label
    function update(uint label_id, string memory label_name, string memory label_color) public returns(bool) {
        uint i = findLabel(label_id);
        labels[i].label_name = label_name;
        labels[i].label_color = label_color;
        return true;
    }

    // delete label
    function deleteLabel(uint label_id) public {
        uint _label_id = findLabel(label_id);
        delete labels[_label_id];
    }

    // add label to task
    function addLabelToTask(uint label_id, uint task_id) public returns(bool) {
        uint _label_id = findLabel(label_id);
        uint _task_id = tasks.findTask(task_id);
        address sender = msg.sender;
        uint assigner = users.getUserId(sender);
        labelTasks.push(LabelTask(_label_id, _task_id, assigner));
        return true;
    }

    // remove label from task
    function removeLabelFromTask(uint label_id, uint task_id) public {
        bool valid = false;
        uint k = 0;
        for (uint i = 0; i < labelTasks.length; i++) {
            for (uint j = 0; j < labelTasks.length; j++) {
                if ((labelTasks[i].label_id == label_id) && (labelTasks[j].task_id == task_id)) {
                    valid = true;
                    k = j;
                }
            }
        }
        if (valid == true) {
            delete labelTasks[k];
        } else revert('Cannot remove label from task');
    }

    // get list label data
    function getList() view virtual public returns(LabelEntity[] memory) {
        return labels;
    }

    // get label by Id
    function getLabelDetailById(uint label_id) view public returns(uint, uint, string memory, string memory) {
        uint i = findLabel(label_id);
        return (labels[i].label_id, labels[i].user_id, labels[i].label_name, labels[i].label_color);
    }

    // find label id
    function findLabel(uint label_id) view public returns(uint) {
        for (uint i = 0; i < labels.length; i++) {
            if (labels[i].label_id == label_id) {
                return i;
            }
        }
        revert('Label does not exist');
    }

}