/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ProjectsFundraising {
  enum Status { Open, Paused, Closed }
    
  struct AddressSet {
    address payable[] values;
    mapping (address => bool) exists;
  }

  struct Project {
    string name;
    uint256 goal;
    address payable owner;
    Status status;
    uint256 balance;
  }
  
  /**
  * @dev All funders by project
  */
  mapping(uint256 => AddressSet) funders;
  
  /**
  * @dev All funds by project and address
  */
  mapping(uint256 => mapping(address => uint256)) funds;
  
  Project[] projects;
  
  event ProjectFunded(
    uint256 index,
    address sender,
    uint256 sent
  );
  
  event ProjectClosed(uint256 index);
  
  function registerProject(
    string calldata _name,
    uint256 _goal
  ) public returns(uint256) {
    require(
      _goal > 0,
      "The goal must be greater than 0"
    );
    projects.push(
      Project(
        _name,
        _goal,
        payable(msg.sender),
        Status.Open,
        0
      )
    );
    return projects.length - 1;
  }

  modifier onlyOwner(uint256 projectIndex) {
    require(
      msg.sender == projects[projectIndex].owner,
      "Just the owner can modify this project"
    );
    _;
  }
  
  modifier notOwner(uint256 projectIndex) {
    require(
      msg.sender != projects[projectIndex].owner,
      "As onwer you cant fund your own project"
    );
    _;
  }
  
  modifier projectExists(uint256 projectIndex) {
    require(
      projects.length > projectIndex,
      "Project doesnt exists"
    );
    _;
  }
  
  /**
  * @dev Function to add a new funder to a project only if not already exists
  */
  function _addFunder(uint256 projectIndex, address _funder) private {
    if(!funders[projectIndex].exists[_funder]) {
      funders[projectIndex].values.push(payable(_funder));
      funders[projectIndex].exists[_funder] = true;
    }
  }

  function fundProject(uint256 projectIndex) payable public notOwner(projectIndex) {
    Project storage project = projects[projectIndex];
    require(
      project.status != Status.Paused,
      "Project is paused for fund raising. Stay tuned!"
    );
    require(
      project.status != Status.Closed,
      "Project is closed for fund raising"
    );
    require(
      uint(msg.value) > 0,
      "Amount must be greater than 0"
    );
    require(
      project.balance + uint(msg.value) <= project.goal,
      "Amount exceeds goal"
    );
    
    funds[projectIndex][msg.sender] += msg.value;
    _addFunder(projectIndex, msg.sender);
    
    project.balance += uint(msg.value);
    
    emit ProjectFunded(projectIndex, msg.sender, msg.value);

    if (project.balance == project.goal) {
      project.status = Status.Closed; 
      project.owner.transfer(project.goal);
      emit ProjectClosed(projectIndex);
    }
  }

  function getProject(uint256 projectIndex) projectExists(projectIndex) public view returns (Project memory) {
    return projects[projectIndex];
  }
  
  function getOwner(uint256 projectIndex) projectExists(projectIndex) public view returns (address) {
    return projects[projectIndex].owner;
  }
  
  function getTotalFunders(uint256 projectIndex) projectExists(projectIndex) public view returns (uint256) {
    return funders[projectIndex].values.length;
  }
  
  function getStatus(uint256 projectIndex) projectExists(projectIndex) public view returns (string memory) {
    if (projects[projectIndex].status == Status.Open) return "The project is open";
    if (projects[projectIndex].status == Status.Closed) return "The project is closed";
    if (projects[projectIndex].status == Status.Paused) return "The project is paused";
    return "";
  }

  function isClosed(uint256 projectIndex) projectExists(projectIndex) public view returns (bool) {
    return projects[projectIndex].status == Status.Closed;
  }

  function getRemainingAmount(uint256 projectIndex) projectExists(projectIndex) public view returns (uint256) {
    return projects[projectIndex].goal - projects[projectIndex].balance;
  }
  
  function getName(uint256 projectIndex) projectExists(projectIndex) public view returns (string memory) {
    return projects[projectIndex].name;
  }

  function setName(uint256 projectIndex, string calldata _name) projectExists(projectIndex) onlyOwner(projectIndex) public {
    projects[projectIndex].name = _name;
  }
  
  function getMyContribution(uint256 projectIndex) projectExists(projectIndex) notOwner(projectIndex) public view returns (uint256) {
    return funds[projectIndex][msg.sender];
  }
  
  function pauseProject(uint256 projectIndex) projectExists(projectIndex) onlyOwner(projectIndex) public {
    require(
      projects[projectIndex].status == Status.Open,
      "This project is not open and cant be paused"
    );
    projects[projectIndex].status = Status.Paused;
  }
  
  function resumeProject(uint256 projectIndex) projectExists(projectIndex) onlyOwner(projectIndex) public {
    require(
      projects[projectIndex].status == Status.Paused,
      "This project is not paused and cant be resumed"
    );
    projects[projectIndex].status = Status.Open;
  }

  function closeProject(uint256 projectIndex) projectExists(projectIndex) onlyOwner(projectIndex) public {
    require(
      projects[projectIndex].status != Status.Closed,
      "This project is already closed"
    );
    Project memory project = projects[projectIndex];
    project.status = Status.Closed;
    emit ProjectClosed(projectIndex);
    
    for(uint8 i; i < funders[projectIndex].values.length; i++) {
      funders[projectIndex].values[i].transfer(
        funds[projectIndex][funders[projectIndex].values[i]]
      );
    }
  }
}