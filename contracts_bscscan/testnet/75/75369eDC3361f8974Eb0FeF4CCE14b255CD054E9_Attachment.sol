// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Task.sol";

contract Attachment {

    User users = User(0xa0a2D9f65809f46A970097a7FAdD301F688a2754);
    Task tasks = Task(0xB73C545161c10EdC5B515Ebe9802C39b5f54608f);
    
    struct AttachmentEntity {
        uint attachment_id; // id
        string attachment_name; // name of attachment, can null
        string attachment_link; // link out, for frontend
        string deleted; // default deleted = n; delete = y: can't view on front-end
        uint task_id; // valid id of task
        uint activity_id; //  valid id of activity
        uint user_id; //  valid id of user
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }

    AttachmentEntity[] public attachments;

    // create attachment
    function createAttachment(uint attachment_id, string memory attachment_name, string memory attachment_link, uint task_id, uint activity_id) public returns(bool) {
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        attachments.push(AttachmentEntity(attachment_id, attachment_name, attachment_link, 'n', task_id, activity_id, _user_id, block.timestamp, block.timestamp));
        return true;
    }

    // update attachment
    function updateAttachment(uint attachment_id, string memory attachment_name) public returns(bool) {
        uint i = findAttachment(attachment_id);
        attachments[i].attachment_name = attachment_name;
        attachments[i].update_at = block.timestamp;
        return true;
    }
    
    // set deleted = y
    function deleteAttachment(uint attachment_id) public returns(bool) {
        uint i = findAttachment(attachment_id);
        require((keccak256(abi.encodePacked(attachments[i].deleted)) == keccak256(abi.encodePacked('n'))), "Attachment has been deleted before" );
        attachments[i].deleted = 'y';
        attachments[i].update_at = block.timestamp; 
        return true;
    }

    function findAttachment(uint attachment_id) view public returns(uint) {
        for (uint i = 0; i < attachments.length; i++) {
            if (attachments[i].attachment_id == attachment_id) {
                return i;
            }
        }
        revert('Attachment does not exist');
    }
    
}