/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title AMProject
 * @dev Stores project metadata such as file hashes
 */
contract AMProject {
    
    struct File {
        string hash;
        address author;
    }
   
    struct Project {
        address author;
        File[] files;
    }


    Project[] public projectList;
    mapping(uint256 => Project) projects;
    uint256 public projectCount = 0;


    function addProject() public returns (Project memory){
        Project storage new_project = projects[projectCount];
        new_project.author = msg.sender;
        
        projectList.push(new_project);

        projectCount++;
        
        return projects[projectCount-1];
    }


    function addFile(uint _projectid, string memory _checksum) public returns (uint){
        require(_projectid < projectCount, "Project ID does not exist.");
        File memory new_file = File(_checksum, msg.sender);
        projects[_projectid].files.push(new_file);
        
        return projects[_projectid].files.length;
    }
    
    
    function getProject(uint _projectid) public view returns (Project memory) {
        require(_projectid < projectCount, "Project ID does not exist.");
        return projects[_projectid];
    }
    
    
    function getFile(uint _projectid, uint _fileid) public view returns (File memory) {
        require(_projectid < projectCount, "Project ID does not exist.");
        require(_fileid < projects[_projectid].files.length, "File ID does not exist.");
        return projects[_projectid].files[_fileid]; // tuple(hash: string, author: address)
    }
    
    
    function listProjects() public view returns (Project[] memory) {
        return projectList;
    }
    
    
    function getProjectCount() public view returns (uint){
        return projectList.length;
    }
}