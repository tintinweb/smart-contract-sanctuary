// SPDX-License-Identifier: MIT
// Copyright © 2021 InProject

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./Project.sol";

contract Folder {

    Project projects = Project(0x8dDE04C86e7DE0Fbd9292895357d2D27fC4Ab3B2);

    struct FolderEntity {
        uint folder_id; // id auto increatement
        uint project_id; // valid id from project
        string folder_name; // not null
        string visible; // default visible = y: everyone can view; visible = n: only project_user can view
        string deleted; // default deleted = n; delete = y: can't view on front-end
        uint create_at; // timestamp, save with unit format
        uint update_at; // timestamp, save with unit format
    }

    FolderEntity[] private folders;     

    // create folder
    function createFolder(
        uint folder_id,
        uint project_id,
        string memory folder_name
    ) public returns(bool) {
        uint _project_id = projects.findProject(project_id);
        folders.push(FolderEntity(folder_id, _project_id, folder_name, 'y', 'n', block.timestamp, block.timestamp));
        return true;
    }

    // update folder
    function updateFolder(uint folder_id, uint project_id, string memory folder_name, string memory visible) public returns(bool) {
        uint i = findFolder(folder_id);
        uint _project_id = projects.findProject(project_id);
        folders[i].project_id = _project_id;
        folders[i].folder_name = folder_name;
        if (keccak256(abi.encodePacked(visible)) == keccak256(abi.encodePacked('n'))) {
            folders[i].visible = 'n';
        } else {
            folders[i].visible = 'y';
        }
        folders[i].update_at = block.timestamp;
        return true;
    }

    // set deleted = y
    function deleteFolder(uint folder_id) public returns(bool) {
        uint i = findFolder(folder_id);
        require((keccak256(abi.encodePacked(folders[i].deleted)) == keccak256(abi.encodePacked('n'))), "Folder has been deleted before" );
        folders[i].deleted = 'y';
        folders[i].update_at = block.timestamp; 
        return true;
    }

    // get all data from folder
    function getListFolder() view public returns(FolderEntity[] memory) {
        return folders;
    }

    // get project id of folder
    function getProjectIdOfFolder(uint folder_id) view public returns(uint) {
        uint i = findFolder(folder_id);
        return folders[i].project_id;
    }

    // get folder detail by Id
    function getFolderDetailById(uint folder_id) view public returns(uint, uint, string memory, string memory, string memory, uint, uint) {
        uint i = findFolder(folder_id);
        return (folders[i].folder_id, folders[i].project_id, folders[i].folder_name, folders[i].visible, folders[i].deleted, folders[i].create_at, folders[i].update_at);
    }

    // is folder visible?
    function isFolderVisible(uint folder_id) view public returns(bool) {
        uint i = findFolder(folder_id);
        if (keccak256(abi.encodePacked(folders[i].visible)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }

    // is folder has been deteted?
    function isFolderDeleted(uint folder_id) view public returns(bool) {
        uint i = findFolder(folder_id);
        if (keccak256(abi.encodePacked(folders[i].deleted)) == keccak256(abi.encodePacked('y'))) {
            return true;
        }
        return false;
    }
    
    function findFolder(uint folder_id) view public returns(uint) {
        for (uint i = 0; i < folders.length; i++) {
            if (folders[i].folder_id == folder_id) {
                return i;
            }
        }
        revert('Folder does not exist');
    }
}