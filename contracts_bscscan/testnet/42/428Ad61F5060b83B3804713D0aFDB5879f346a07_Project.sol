// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Workspace.sol";

contract Project {
    
    
    User users;
    Workspace workspaces;

    constructor(address _user_contract, address _workspace_contract) {
        require(_user_contract != address(0),"Contracts cannot be 0 address");
        require(_workspace_contract != address(0),"Contracts cannot be 0 address");
        users = User(_user_contract);
        workspaces = Workspace(_workspace_contract);
    }

    struct ProjectEntity {
        uint project_id; // id auto increatement
        uint workspace_id; // valid id from workspace
        string project_name; // not null
        string visible; // default visible = y: everyone can view; visible = n: only project_user can view
        string deleted; // default deleted = n; delete = y: can't view on front-end
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }

    ProjectEntity[] private projects;

    struct ProjectUser {
        uint project_id; // valid project id
        uint user_id; // valid user id
        string role; // role of user affects for project ; assignee: full permission, can't delete owner ; viewer: only view
        string is_owner; // default y: yes, n: no ; if user is owner project, noone can delete this user
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }

    ProjectUser[] private projectUsers;

    // create project
    function createProject(uint project_id, uint workspace_id, string memory project_name) public returns(bool) {
        uint _workspace_id = workspaces.findWorkspace(workspace_id);
        address sender = msg.sender;
        uint _user_id = users.getUserId(sender);
        projects.push(ProjectEntity(project_id, _workspace_id, project_name, 'y', 'n', block.timestamp, block.timestamp));
        projectUsers.push(ProjectUser(project_id, _user_id, 'assignee', 'y', block.timestamp, block.timestamp));
        return true;
    }

    // set deleted = y
    function deleteProject(uint project_id) public returns(bool) {
        uint i = findProject (project_id);
        require((keccak256(abi.encodePacked(projects[i].deleted)) == keccak256(abi.encodePacked('n'))), "Project has been deleted before" );
        projects[i].deleted = 'y';
        projects[i].update_at = block.timestamp; 
        return true;
    }

    // update project's name
    function updateProject(uint project_id, uint workspace_id, string memory project_name, string memory visible) public returns(bool) {
        uint i = findProject (project_id);
        uint _workspace_id = workspaces.findWorkspace(workspace_id);
        projects[i].workspace_id = _workspace_id;
        projects[i].project_name = project_name;
        if (keccak256(abi.encodePacked(visible)) == keccak256(abi.encodePacked('n'))) {
            projects[i].visible = 'n';
        } else {
            projects[i].visible = 'y';
        }
        projects[i].update_at = block.timestamp;
        return true;
    }

    // get all data from project
    function getListProject() view public returns(ProjectEntity[] memory) {
        return projects;
    }

    // get project detail by Id
    function getProjectDetailById(uint project_id) view public returns(uint, uint, string memory, string memory, string memory, uint, uint) {
        uint i = findProject(project_id);
        return (projects[i].project_id, projects[i].workspace_id, projects[i].project_name, projects[i].visible, projects[i].deleted, projects[i].create_at, projects[i].update_at);
    }

    function getProjectUserDetail(uint project_id, uint user_id) view public returns(uint, uint, string memory, string memory, uint, uint) {
        uint k = 0;
        bool validUser = false;
        for (uint i = 0; i < projectUsers.length; i++) {
            for (uint j = 0; j < projectUsers.length; j++) {
                if ((projectUsers[i].project_id == project_id) && (projectUsers[j].user_id == user_id)) {
                    k = j;
                    validUser = true;
                }
            }
        }
        if (validUser == true) {
            return (projectUsers[k].project_id, projectUsers[k].user_id, projectUsers[k].role, projectUsers[k].is_owner, projectUsers[k].create_at, projectUsers[k].update_at);
        } else revert('Cannot find ProjectUser');
    }

    // is project visible?
    function isProjectVisible(uint project_id) view public returns(bool) {
        uint i = findProject(project_id);
        if (keccak256(abi.encodePacked(projects[i].visible)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // is project has been deteted?
    function isProjectDeleted(uint project_id) view public returns(bool) {
        uint i = findProject(project_id);
        if (keccak256(abi.encodePacked(projects[i].deleted)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // find project id
    function findProject(uint project_id) view public returns(uint) {
        for (uint i = 0; i < projects.length; i++) {
            if (projects[i].project_id == project_id) {
                return i;
            }
        }
        revert('Project does not exist');
    }

    // add user to project
    function addUserToProject(uint project_id, uint assignee) public {
        projectUsers.push(ProjectUser(project_id, assignee, 'assignee', 'n', block.timestamp, block.timestamp));
    }

    // add viewer to project
    function addViewerToProject(uint project_id, uint viewer_id) public {
        projectUsers.push(ProjectUser(project_id, viewer_id, 'viewer', 'n', block.timestamp, block.timestamp));
    }

    // remove user from project
    function removeUserFromProject(uint project_id, uint user_in_project) public {
        for (uint i = 0; i < projectUsers.length; i++) {
            for (uint j = 0; j < projectUsers.length; j++) {
                if ((projectUsers[i].project_id == project_id) && (projectUsers[j].user_id == user_in_project)) {
                    delete projectUsers[j];
                }
            }
        }
    }
}