// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./User.sol";

contract Workspace {

    User users;

    constructor(address _user_contract) {
        require(_user_contract != address(0),"Contracts cannot be 0x address");
        users = User(_user_contract);
    }

    struct WorkspaceEntity {
        uint workspace_id; // id
        string workspace_name; // not null
        string thumbnail_url; // can null
        string visible; // default visible = n: only workspace_user can view; visible = y: everyone can view
        string deleted; // default deleted = n; delete = y: can't view on front-end
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }
    WorkspaceEntity[] private workspaces;

    struct WorkspaceUser {
        uint workspace_id; // valid workspace id
        uint user_id; // valid user id
        string role; // role of user affects for workspace ; assignee: full permission, can't delete owner; viewer: only view
        string is_owner; // default y: yes, n: no ; if user is owner workspace, noone can delete this user
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }
    WorkspaceUser[] private workspaceUsers;

    // create workspace
    function createWorkspace(uint workspace_id, string memory workspace_name, string memory thumbnail_url) public returns(bool) {
        workspaces.push(WorkspaceEntity(workspace_id, workspace_name, thumbnail_url, 'y', 'n', block.timestamp, block.timestamp));
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        workspaceUsers.push(WorkspaceUser(workspace_id, _user_id, 'assignee', 'y', block.timestamp, block.timestamp));
        return true;
    }

    // update workspace instance
    function updateWorkspace(uint workspace_id, string memory workspace_name, string memory thumbnail_url, string memory visible) public returns(bool) {
        uint i = findWorkspace(workspace_id);
        workspaces[i].workspace_name = workspace_name;
        workspaces[i].thumbnail_url = thumbnail_url;
        if (keccak256(abi.encodePacked(visible)) == keccak256(abi.encodePacked('n'))) {
            workspaces[i].visible = 'n';
        } else {
            workspaces[i].visible = 'y';
        }
        workspaces[i].update_at = block.timestamp;
        return true;
    }

    // set deleted = y
    function deleteWorkspace(uint workspace_id) public returns(bool) {
        uint i = findWorkspace(workspace_id);
        require((keccak256(abi.encodePacked(workspaces[i].deleted)) == keccak256(abi.encodePacked('n'))), "Workspace has been deleted before" );
        workspaces[i].deleted = 'y';
        workspaces[i].update_at = block.timestamp; 
        return true;
    }

    // get all data from workspace
    function getListWorkspace() view public returns(WorkspaceEntity[] memory) {
        return workspaces;
    }
    
    // get all data from workspace user
    function getListWorkspaceUser() view public returns(WorkspaceUser[] memory) {
        return workspaceUsers;
    }

    // get workspace detail by Id
    function getWorkspaceDetailById(uint workspace_id) view public returns(uint, string memory, string memory, string memory, string memory, uint, uint) {
        uint i = findWorkspace(workspace_id);
        return (workspaces[i].workspace_id, workspaces[i].workspace_name, workspaces[i].thumbnail_url, workspaces[i].visible, workspaces[i].deleted, workspaces[i].create_at, workspaces[i].update_at);
    }

    // get workspace user detail
    function getWorkspaceUserDetail(uint workspace_id, uint user_id) view public returns(uint, uint, string memory, string memory, uint, uint) {
        uint k = 0;
        bool validUser = false;
        for (uint i = 0; i < workspaceUsers.length; i++) {
            for (uint j = 0; j < workspaceUsers.length; j++) {
                if ((workspaceUsers[i].workspace_id == workspace_id) && (workspaceUsers[j].user_id == user_id)) {
                    k = j;
                    validUser = true;
                }
            }
        }
        if (validUser == true) {
            return (workspaceUsers[k].workspace_id, workspaceUsers[k].user_id, workspaceUsers[k].role, workspaceUsers[k].is_owner, workspaceUsers[k].create_at, workspaceUsers[k].update_at);
        } else revert('Cannot find WorkspaceUser');
    }

    // is workspace visible?
    function isWorkspaceVisible(uint workspace_id) view public returns(bool) {
        uint i = findWorkspace(workspace_id);
        if (keccak256(abi.encodePacked(workspaces[i].visible)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // is workspace has been deteted?
    function isWorkspaceDeleted(uint workspace_id) view public returns(bool) {
        uint i = findWorkspace(workspace_id);
        if (keccak256(abi.encodePacked(workspaces[i].deleted)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // find workspace id
    function findWorkspace(uint workspace_id) public view returns(uint) {
        for (uint i = 0; i < workspaces.length; i++) {
            if (workspaces[i].workspace_id == workspace_id) {
                return i;
            }
        }
        revert('Workspace does not exist');
    }

    // assigner add user to workspace
    function addUserToWorkspace(uint workspace_id, uint assignee) public {
        workspaceUsers.push(WorkspaceUser(workspace_id, assignee, 'assignee', 'n', block.timestamp, block.timestamp));
    }

    // assigner add viewer to workspace
    function addViewerToWorkspace(uint workspace_id, uint viewer_id) public {
        workspaceUsers.push(WorkspaceUser(workspace_id, viewer_id, 'viewer', 'n', block.timestamp, block.timestamp));
    }

    // remove user from workspace
    function removeUserFromWorkspace(uint workspace_id, uint user_in_workspace) public {
        for (uint i = 0; i < workspaceUsers.length; i++) {
            for (uint j = 0; j < workspaceUsers.length; j++) {
                if ((workspaceUsers[i].workspace_id == workspace_id) && (workspaceUsers[j].user_id == user_in_workspace)) {
                    delete workspaceUsers[j];
                }
            }
        }
        revert('Cannot remove user');
    }
}