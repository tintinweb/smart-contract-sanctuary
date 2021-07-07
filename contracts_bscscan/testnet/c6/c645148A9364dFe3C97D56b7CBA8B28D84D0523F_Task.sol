// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Folder.sol";

contract Task {
    User users = User(0x18fE3eAe0E47c9ee51af667444288c06AA7ddBd0);
    Folder folders = Folder(0xb5D3659bb672eF856b7216D9c00c6CABdA5C0917);

    struct TaskEntity {
        uint task_id; // id auto increatement
        uint folder_id; // valid id from folder
        string task_name; // name of task
        string description; // description of task, can null
        string status; // default: todo, task status: complete / ready / todo / progress
        string cover_img_url; // cover of task
        string deleted; // default deleted = n; delete = y: can't view on front-end
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }
    TaskEntity[] private tasks;
    
    struct TaskPlus {
        uint task_id; // id auto increatement
        uint order; // order of this task on folder
        uint start_date; // start date (include time), save with unit format, can null
        uint end_date; // end date (include time), save with unit format, can null
        uint estimate; // estimate hours can done this task, is float number, can null
        uint duedate_reminder; // (0) at time of end date / (5) 5 minutes before / (10) 10 minutes before / (15) 15 minutes before / (60) 1 hour before / (120) 2 hours before / (1440) 1 day before / (2880) 2 days before
        uint budget; // task budget / is dollar, can null
        uint spend; // task spend / is dollar, can null
    }
    TaskPlus[] private taskPlus;

    struct TaskUser {
        uint task_id; // valid task id
        uint user_id; // valid user id
        string role; // role of user affects for project ; assignee: full permission, can't delete owner; viewer: only view
        string is_owner; // default y: yes, n: no ; if user is owner task, noone can delete
        string watch; // default y: yes, n: no
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }
    TaskUser[] private taskUsers;
    
    uint private nextTaskOrder = 100000;

    // create task
    function createTask(uint task_id, uint folder_id, string memory task_name, string memory description, uint start_date, uint end_date, uint estimate, uint duedate_reminder, uint budget, uint spend) public returns(bool) {
        uint _folder_id = folders.findFolder(folder_id);
        if (start_date == 0) start_date = block.timestamp + 86400;
        if (end_date == 0) end_date = block.timestamp + 172800;
        if (estimate == 0) estimate = 24;
        tasks.push(TaskEntity(task_id, _folder_id, task_name, description, 'todo', '', 'n', block.timestamp, block.timestamp));
        taskPlus.push(TaskPlus(task_id, nextTaskOrder, start_date, end_date, estimate, duedate_reminder, budget, spend));
        ++nextTaskOrder;

        if (createTaskOwner(task_id) == true) {
            return true;
        }
        return false;
    }

    function createTaskOwner(uint task_id) private returns(bool) {
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        taskUsers.push(TaskUser(task_id, _user_id, 'assignee', 'y', 'y', block.timestamp, block.timestamp));
        return true;
    }

    // set deleted = y
    function deleteTask(uint task_id) public returns(bool) {
        uint i = findTask (task_id);
        require((keccak256(abi.encodePacked(tasks[i].deleted)) == keccak256(abi.encodePacked('n'))), "Task has been deleted before" );
        tasks[i].deleted = 'y';
        tasks[i].update_at = block.timestamp; 
        return true;
    }

    // get list task data
    function getListTask() view public returns(TaskEntity[] memory) {
        return tasks;
    }

    // get list task plus data 
    function getListTaskPlus() view public returns(TaskPlus[] memory) {
        return taskPlus;
    }
    
    // get list task user data 
    function getListTaskUser() view public returns(TaskUser[] memory) {
        return taskUsers;
    }

    // get folder id of task
    function getFolderIdOfTask(uint task_id) view public returns(uint) {
        uint i = findTask(task_id);
        return tasks[i].folder_id;
    }

    // get task detail by Id
    function getTaskDetailById(uint task_id) view public returns(uint, uint, string memory, string memory, string memory, string memory, string memory, uint, uint) {
        uint i = findTask(task_id);
        return (tasks[i].task_id, tasks[i].folder_id, tasks[i].task_name, tasks[i].description, tasks[i].status, tasks[i].cover_img_url, tasks[i].deleted, tasks[i].create_at, tasks[i].update_at);
    }

    function getTaskPlusDetailById(uint task_id) view public returns(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        uint i = findTask(task_id);
        return (taskPlus[i].task_id, taskPlus[i].order, taskPlus[i].start_date, taskPlus[i].end_date, taskPlus[i].estimate, taskPlus[i].duedate_reminder, taskPlus[i].budget, taskPlus[i].spend, tasks[i].create_at, tasks[i].update_at);
    }

    function getTaskUserDetail(uint task_id, uint user_id) view public returns(uint, uint, string memory, string memory, string memory, uint, uint) {
        uint k = 0;
        bool validUser = false;
        for (uint i = 0; i < taskUsers.length; i++) {
            for (uint j = 0; j < taskUsers.length; j++) {
                if ((taskUsers[i].task_id == task_id) && (taskUsers[j].user_id == user_id)) {
                    k = j;
                    validUser = true;
                }
            }
        }
        if (validUser == true) {
            return (taskUsers[k].task_id, taskUsers[k].user_id, taskUsers[k].role, taskUsers[k].is_owner, taskUsers[k].watch, taskUsers[k].create_at, taskUsers[k].update_at);
        } else revert('Cannot find TaskUser');
    }

    // update task
    function updateTask(uint task_id, uint folder_id, string memory task_name, string memory description,  string memory status, string memory cover_img_url) public returns(bool) {
        uint i = findTask(task_id);
        uint _folder_id = folders.findFolder(folder_id);
        tasks[i].folder_id = _folder_id;
        tasks[i].task_name = task_name;
        tasks[i].description = description;
        tasks[i].status = status;
        tasks[i].cover_img_url = cover_img_url;
        tasks[i].update_at = block.timestamp;
        return true;
    }

    function updateTaskPlus(uint task_id, uint order, uint start_date, uint end_date, uint estimate, uint duedate_reminder, uint budget, uint spend)  public returns(bool) {
        uint i = findTask(task_id);
        taskPlus[i].order = order;
        taskPlus[i].start_date = start_date;
        taskPlus[i].end_date = end_date;
        taskPlus[i].estimate = estimate;
        taskPlus[i].duedate_reminder = duedate_reminder;
        taskPlus[i].budget = budget;
        taskPlus[i].spend = spend;
        tasks[i].update_at = block.timestamp;
        return true;
    }

    // is tasks has been deteted?
    function isTaskDeleted(uint task_id) view public returns(bool) {
        uint i = findTask(task_id);
        if (keccak256(abi.encodePacked(tasks[i].deleted)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    function findTask(uint task_id) view public returns(uint) {
        for (uint i = 0; i < tasks.length; i++) {
            if (tasks[i].task_id == task_id) {
                return i;
            }
        }
        revert('Task does not exist');
    }

    // assigner add user to task
    function addUserToTask(uint task_id, uint assignee) public {
        address sender = msg.sender;
        uint assigner = users.getUserId(sender);
        bool validUser = false;
        for (uint i = 0; i < taskUsers.length; i++) {
            for (uint j = 0; j < taskUsers.length; j++) {
                if ((taskUsers[i].task_id == task_id) && (taskUsers[j].user_id == assigner)) validUser = true;
            }
        }
        if (validUser == true) {
            taskUsers.push(TaskUser(task_id, assignee, 'assignee', 'n', 'y', block.timestamp, block.timestamp));
        } else revert('Only user in task must add another user to this task');
    }

    // only owner add user to task as a viewer
    function addViewerToTask(uint task_id, uint viewer_id) public {
        address sender = msg.sender;
        uint owner_id = users.getUserId(sender);
        bool validUser = false;
        for (uint i = 0; i < taskUsers.length; i++) {
            for (uint j = 0; j < taskUsers.length; j++) {
                if ((taskUsers[i].task_id == task_id) && (taskUsers[j].user_id == owner_id) && (keccak256(abi.encodePacked(taskUsers[j].is_owner)) == keccak256(abi.encodePacked('y')))) { // valid user in task is owner
                    validUser = true;
                }
            }
        }
        if (validUser == true) {
            taskUsers.push(TaskUser(task_id, viewer_id, 'viewer', 'n', 'y', block.timestamp, block.timestamp));
        } else revert('Only owner of task can add viewer to this task');
    }

    // only owner in task can remove user
    function removeUserFromTask(uint task_id, uint user_in_task) public {
        address sender = msg.sender;
        uint owner_id = users.getUserId(sender);
        bool validUser = false;
        for (uint i = 0; i < taskUsers.length; i++) {
            for (uint j = 0; j < taskUsers.length; j++) {
                if ((taskUsers[i].task_id == task_id) && (taskUsers[j].user_id == owner_id) && (keccak256(abi.encodePacked(taskUsers[j].is_owner)) == keccak256(abi.encodePacked('y')))) { // valid user in task is owner
                    validUser = true;
                }
            }
        }
        if (validUser == true) {
            for (uint i = 0; i < taskUsers.length; i++) {
                for (uint j = 0; j < taskUsers.length; j++) {
                    if ((taskUsers[i].task_id == task_id) && (taskUsers[j].user_id == user_in_task)) {
                        delete taskUsers[j];
                    }
                }
            }
        } else revert('Only owner of task can remove user from this task');
    }
}