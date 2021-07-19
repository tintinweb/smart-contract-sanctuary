// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Task.sol";

contract Activity {

    User users;
    Task tasks;

    constructor(address _user_contract, address _task_contract) {
        require(_user_contract != address(0),"Contracts cannot be 0 address");
        require(_task_contract != address(0),"Contracts cannot be 0 address");
        users = User(_user_contract);
        tasks = Task(_task_contract);
    }

    struct ActivityEntity {
        uint activity_id;
        uint task_id; // valid id of task
        uint user_id; // valid id from user
        string activity_content; // content
        string deleted; // default deleted = n; delete = y: can't view on front-end
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }
    ActivityEntity[] private activities;

    struct EmojiEntity {
        uint activity_id; // valid from activity
        uint user_id; // valid from user
        string emoji; // not null
    }
    EmojiEntity[] public emojis;

    // create activity
    function createActivity(uint activity_id, uint task_id, string memory activity_content) public returns(bool) {
        uint _task_id = tasks.findTask(task_id);
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        activities.push(ActivityEntity(activity_id, _task_id, _user_id, activity_content, 'n', block.timestamp, block.timestamp));
        return true;
    }

    function updateActivity(uint activity_id, string memory activity_content) public returns(bool) {
        uint i = findActivity(activity_id);
        activities[i].activity_content = activity_content;
        activities[i].update_at = block.timestamp;
        return true;
    }

    // set deleted = y
    function deleteActivity(uint activity_id) public returns(bool) {
        uint i = findActivity(activity_id);
        require((keccak256(abi.encodePacked(activities[i].deleted)) == keccak256(abi.encodePacked('n'))), "Activity has been deleted before" );
        activities[i].deleted = 'y';
        activities[i].update_at = block.timestamp; 
        return true;
    }

    // get all data from activity
    function getListAcitity() view public returns(ActivityEntity[] memory) {
        return activities;
    }

    // get activity detail by Id
    function getActivityDetailById(uint activity_id) view public returns(uint, uint, uint, string memory, string memory, uint, uint) {
        uint i = findActivity(activity_id);
        return (activities[i].activity_id, activities[i].task_id, activities[i].user_id, activities[i].activity_content, activities[i].deleted, activities[i].create_at, activities[i].update_at);
    }

    // is activity has been deteted?
    function isActivityDeleted(uint activity_id) view public returns(bool) {
        uint i = findActivity(activity_id);
        if (keccak256(abi.encodePacked(activities[i].deleted)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // find activity id
    function findActivity(uint activity_id) public view returns(uint) {
        for (uint i = 0; i < activities.length; i++) {
            if (activities[i].activity_id == activity_id) {
                return i;
            }
        }
        revert('Activity does not exist');
    }

    // emoji user
    function emojiUser(uint activity_id, string memory emoji) public returns(bool) {
        uint _activity_id = findActivity(activity_id);
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        emojis.push(EmojiEntity(_activity_id, _user_id, emoji));
        return true;
    }

    function removeEmoji(uint activity_id, string memory emoji) public {
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        for (uint i = 0; i < emojis.length; i++) {
            for (uint j = 0; j < emojis.length; j++) {
                for (uint k = 0; k < emojis.length; k++) {
                    if ((emojis[i].activity_id == activity_id) && (emojis[j].user_id == _user_id) && keccak256(abi.encodePacked(emojis[k].emoji)) == keccak256(abi.encodePacked(emoji))) {
                        delete emojis[k];
                    }
                }
            }
        }
    }
}