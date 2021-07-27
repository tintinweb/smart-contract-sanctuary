// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Task.sol";

contract Checklist {

    User users;
    Task tasks;

    constructor(address _user_contract, address _task_contract) {
        require(_user_contract != address(0),"Contracts cannot be 0x address");
        require(_task_contract != address(0),"Contracts cannot be 0x address");
        users = User(_user_contract);
        tasks = Task(_task_contract);
    }

    
    struct ChecklistEntity {
        uint checklist_id;
        uint task_id; // valid task id from task
        string checklist_title; // checklist name, not null
        string deleted; // default deleted = n; delete = y: can't view on front-end
        string show_checked_item; // default y: show, n: hide
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format

    }
    ChecklistEntity[] private checklists;

    struct ChecklistItem {
        uint item_id;
        uint checklist_id; // valid from checklist
        uint order; // order of checklist_item on checklist
        string item_name; // name of item
        string status; // default: not yet / done
        uint end_date; // end date (include time), save with unit format, can null
        string deleted; // default deleted = n; delete = y: can't view on front-end
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }
    ChecklistItem[] private checklistItems;

    struct ChecklistItemUser {
        uint item_id; // valid item id
        uint user_id; // valid user id
        string is_assigner; // default y: yes, n: no ; if user is owner task, noone can delete
        string is_assignee; // default y: yes, n: no
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }
    ChecklistItemUser[] private checklistItemUsers;

    uint private nextChecklistItemOrder = 100000;

    // create checklist
    function createChecklist(uint checklist_id, uint task_id, string memory checklist_title) public returns(bool) {
        uint _task_id = tasks.findTask(task_id);
        checklists.push(ChecklistEntity(checklist_id, _task_id, checklist_title, 'n', 'y', block.timestamp, block.timestamp));
        return true;
    }

    // update checklist
    function updateChecklist(uint checklist_id, string memory checklist_title, string memory show_checked_item) public returns(bool) {
        uint i = findChecklist(checklist_id);
        checklists[i].checklist_title = checklist_title;
        if (keccak256(abi.encodePacked(show_checked_item)) == keccak256(abi.encodePacked('n'))) {
            checklists[i].show_checked_item = 'n';
        } else {
            checklists[i].show_checked_item = 'y';
        }
        checklists[i].update_at = block.timestamp;
        return true;
    }

    // set deleted = y
    function deleteChecklist(uint checklist_id) public returns(bool) {
        uint i = findChecklist(checklist_id);
        require((keccak256(abi.encodePacked(checklists[i].deleted)) == keccak256(abi.encodePacked('n'))), "Checklist has been deleted before" );
        checklists[i].deleted = 'y';
        checklists[i].update_at = block.timestamp; 
        return true;
    }

    // get all data from checklist
    function getListChecklist() view public returns(ChecklistEntity[] memory) {
        return checklists;
    }

    // get checklist detail by Id
    function getChecklistDetailById(uint checklist_id) view public returns(uint, uint, string memory, string memory, string memory, uint, uint) {
        uint i = findChecklist(checklist_id);
        return (checklists[i].checklist_id, checklists[i].task_id, checklists[i].checklist_title, checklists[i].deleted, checklists[i].show_checked_item, checklists[i].create_at, checklists[i].update_at);
    }

    // is checklist has been deteted?
    function isChecklistDeleted(uint checklist_id) view public returns(bool) {
        uint i = findChecklist(checklist_id);
        if (keccak256(abi.encodePacked(checklists[i].deleted)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // show checked item?
    function isShowCheckedItem(uint checklist_id) view public returns(bool) {
        uint i = findChecklist(checklist_id);
        if (keccak256(abi.encodePacked(checklists[i].show_checked_item)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // find checklist id
    function findChecklist(uint checklist_id) public view returns(uint) {
        for (uint i = 0; i < checklists.length; i++) {
            if (checklists[i].checklist_id == checklist_id) {
                return i;
            }
        }
        revert('Checklist does not exist');
    }

    // create checklist item
    function createChecklistItem(uint item_id, uint checklist_id, string memory item_name) public returns(bool) {
        uint _checklist_id = findChecklist(checklist_id);
        checklistItems.push(ChecklistItem(item_id, _checklist_id, nextChecklistItemOrder, item_name, 'todo', block.timestamp + 86400, 'n', block.timestamp, block.timestamp));
        ++nextChecklistItemOrder;
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        checklistItemUsers.push(ChecklistItemUser(item_id, _user_id, 'y', 'y', block.timestamp, block.timestamp));
        return true;
    }

    // update checklist item
    function updateChecklistItem(uint item_id, uint order, string memory item_name, string memory status, uint end_date) public returns(bool) {
        uint i = findChecklistItem(item_id);
        checklistItems[i].order = order;
        checklistItems[i].item_name = item_name;
        checklistItems[i].status = status;
        checklistItems[i].end_date = end_date;
        checklists[i].update_at = block.timestamp;
        return true;
    }

    // set deleted = y
    function deleteChecklistItem(uint item_id) public returns(bool) {
        uint i = findChecklistItem (item_id);
        require((keccak256(abi.encodePacked(checklistItems[i].deleted)) == keccak256(abi.encodePacked('n'))), "Checklist item has been deleted before" );
        checklistItems[i].deleted = 'y';
        checklistItems[i].update_at = block.timestamp; 
        return true;
    }

    // get all data from checklist item
    function getListChecklistItem() view public returns(ChecklistItem[] memory) {
        return checklistItems;
    }

    // get checklist detail by Id
    function getChecklistItemDetailById(uint item_id) view public returns(uint, uint, uint, string memory, string memory, uint, string memory, uint, uint) {
        uint i = findChecklistItem(item_id);
        return (checklistItems[i].item_id, checklistItems[i].checklist_id, checklistItems[i].order, checklistItems[i].item_name, checklistItems[i].status, checklistItems[i].end_date, checklistItems[i].deleted, checklistItems[i].create_at, checklistItems[i].update_at);
    }

    function getChecklistItemUserDetail(uint item_id, uint user_id) view public returns(uint, uint, string memory, string memory, uint, uint) {
        uint k = 0;
        bool validUser = false;
        for (uint i = 0; i < checklistItemUsers.length; i++) {
            for (uint j = 0; j < checklistItemUsers.length; j++) {
                if ((checklistItemUsers[i].item_id == item_id) && (checklistItemUsers[j].user_id == user_id)) {
                    k = j;
                    validUser = true;
                }
            }
        }
        if (validUser == true) {
            return (checklistItemUsers[k].item_id, checklistItemUsers[k].user_id, checklistItemUsers[k].is_assigner, checklistItemUsers[k].is_assignee, checklistItemUsers[k].create_at, checklistItemUsers[k].update_at);
        } else revert('Cannot find ChecklistItemUser');
    }

    // is checklist item has been deteted?
    function isChecklistItemDeleted(uint item_id) view public returns(bool) {
        uint i = findChecklistItem(item_id);
        if (keccak256(abi.encodePacked(checklistItems[i].deleted)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // find checklist item id
    function findChecklistItem(uint item_id) public view returns(uint) {
        for (uint i = 0; i < checklistItems.length; i++) {
            if (checklistItems[i].item_id == item_id) {
                return i;
            }
        }
        revert('Checklist item does not exist');
    }

    // assigner add user to item
    function addUserToChecklistItem(uint item_id, uint assignee) public {
        checklistItemUsers.push(ChecklistItemUser(item_id, assignee, 'n', 'y', block.timestamp, block.timestamp));
    }

    // remove user from item
    function removeUserFromChecklistItem(uint item_id, uint user_in_item) public {
        for (uint i = 0; i < checklistItemUsers.length; i++) {
            for (uint j = 0; j < checklistItemUsers.length; j++) {
                if ((checklistItemUsers[i].item_id == item_id) && (checklistItemUsers[j].user_id == user_in_item)) {
                    delete checklistItemUsers[j];
                }
            }
        }
    }
}