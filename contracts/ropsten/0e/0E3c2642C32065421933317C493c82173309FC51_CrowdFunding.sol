// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import './EnumerableSet.sol';

contract CrowdFunding {
  constructor() {
    name = 'Crowdfundig dapp gbpiet';
  }
  string public name;

  uint256 public projectCount = 0;

  mapping(uint256 => Project) public projects;
  mapping(uint256 => mapping(address => uint256)) public contributions;

  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(uint256 => EnumerableSet.AddressSet) private contributors;

  struct Project {uint256 id;   string name;   string desc;   address owner;   uint256 endDate;   bool exists;         uint256 balance;   uint256 target;
  }

  event ProjectCreated(uint256 id,   string name,   string desc,   address owner,   uint256 endDate,   bool exists,
    uint256 balance,   uint256 target
  );



  event ProjectFunded(uint256 id, address owner, address funder, uint256 amount);

  event ProjectEnded(uint256 id, string name, uint256 balance);

  modifier OnlyOwner(uint256 projectId) {
    require(msg.sender == projects[projectId].owner, 'Only owner can close this project');
    _;
  }
  modifier ProjectExists(uint256 projectId) {
    require(projects[projectId].exists == true, 'Project doesnot exist');
    _;
  }

  function createProject(   string memory _name,   string memory _desc,   uint256 _endDate,   uint256 _target) public {
    require(bytes(_name).length > 0);
    require(_target > 0);
    require(_endDate > 0);
    projectCount++;
    // Create the project
    projects[projectCount] = Project(projectCount,   _name,   _desc,   msg.sender,   _endDate,   true,   0,  _target
    );
    // trigger an event
    emit ProjectCreated(projectCount, _name, _desc, msg.sender, _endDate, true, 0, _target);
  }

  function fundProject(uint256 _id) public payable ProjectExists(_id) {
    // Fetch the Project
    Project memory _project = projects[_id];
    address _owner = _project.owner;
    // Make sure the project has valid ID
    require(_project.id > 0 && _project.id <= projectCount);
    // Check if the Project end Date is greater than now
    require(block.timestamp < _project.endDate, 'Project is closed.');
    // Check if the owner is trying to fund and reject it
    require(_owner != msg.sender, "Owner can't fund the project created by themselves.");
    //Sent ether must be greater than 0
    require(msg.value > 0);
    // Fund it
    _project.balance += msg.value;
    // Update the Project
    projects[_id] = _project;
    // contributors can again send the money
    contributions[_id][msg.sender] += msg.value;

    if (contributors[_id].contains(msg.sender) != true) {
      contributors[_id].add(msg.sender);
    }
    // Trigger the event
    emit ProjectFunded(_project.id, _project.owner, msg.sender, msg.value);
  }
  

  

  function closeProject(uint256 _id) public OnlyOwner(_id) ProjectExists(_id) {
    // Fetch the Project
    Project memory _project = projects[_id];
    _project.exists = false;
    payable(_project.owner).transfer(_project.balance);
    _project.balance = 0;
    projects[_id] = _project;
    emit ProjectEnded(_project.id, _project.name, _project.balance);
  }

  function getContibutionsLength(uint256 project_id) public view ProjectExists(project_id) returns (uint256 length) {
    return contributors[project_id].length();
  }

  function getContributor(uint256 project_id, uint256 position) public view ProjectExists(project_id) returns (address){
    address _contributorsAddress = contributors[project_id].at(position);
    return _contributorsAddress;
  }

  function balanceOfProjects() public view returns (uint256) {
    return address(this).balance;
  }
  function showProjectByid(uint _id) public view returns(Project memory){
      return projects[_id];
  }
}