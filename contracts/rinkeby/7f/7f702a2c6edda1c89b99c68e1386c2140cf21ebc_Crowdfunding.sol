/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: GLP-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Crowdfunding {
	enum FundraisingState { Opened, Closed}

	struct Contribution {
		address contributor;
		uint value;
	}
	
	struct Project{
		string id;
		string name;
		string description;
		address payable author;
		FundraisingState state;
		uint funds;
		uint fundraisingGoal;
	}
	
	Project[] public projects;
	mapping(string => Contribution[]) public contributions;
	
	event ProjectCreated(
		string projectId,
		string name,
		string description,
		uint fundraisingGoal
	);
	
	event ProjectFunded(
		string projectId,
		uint value
	);
	
	event ProjectStateChanged(
		string id,
		FundraisingState state
	);
	
	//constructor(string memory, _id, string memory _name, string memory _description, uint _fundraisingGoal) {
	//	project = Project(
	//		_id,
	//		_name,
	//		_description,
	//		payable(msg.sender),
	//		FundraisingState.Opened,
	//		0,
	//		_fundraisingGoal
	//	);
	//}
	
	modifier isAuthor(uint projectIndex) {
		require(projects[projectIndex].author == msg.sender, "Your need to be the project author");
		_;
	}
	
	modifier isNotAuthor(uint projectIndex) {
		require(projects[projectIndex].author != msg.sender, "As author you can not fund your own project");
		_;
	}
	
	function createProject(string calldata id, string calldata name, string calldata description, uint fundraisingGoal) public {
		require(fundraisingGoal > 0, "fundraising goal must be greater than 0");
		Project memory project = Project(id, name, description, payable(msg.sender), FundraisingState.Opened, 0, fundraisingGoal);
		projects.push(project);
		emit ProjectCreated(id, name, description, fundraisingGoal);
	}
	
	function fundProject(uint projectIndex) public payable isNotAuthor(projectIndex) {
		Project memory project = projects[projectIndex];
		require(project.state != FundraisingState.Closed, "The project can not recieve funds");
		require(msg.value > 0, "Fund value must be grater tan 0");
		project.author.transfer(msg.value);
		project.funds += msg.value;
		projects[projectIndex] = project;
		
		contributions[project.id].push(Contribution(msg.sender, msg.value));
		
		emit ProjectFunded(project.id, msg.value);
	}
	
	function changeProjectState(FundraisingState newState, uint projectIndex) public isAuthor(projectIndex) {
		Project memory project = projects[projectIndex];
		require(project.state != newState, "New state must be different");
		project.state = newState;
		projects[projectIndex] = project;
		emit ProjectStateChanged(project.id, newState);
	}
}