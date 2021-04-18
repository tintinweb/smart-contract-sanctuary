/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// SPDX-License-Identifier: MIT;

pragma solidity >=0.7.0 <0.9.0;

// pragma experimental ABIEncoderV2;

contract DeFiLance{
    
    address payable public employer;       
    address payable public freelancer;
    string public projectName;
    bool locked = false;
    uint public deadline;
    uint public budget;
    
    
    
    
    enum WorkflowStatus {
        hireFreelancer,
        createProject, 
        acceptProject,
        startProject,
        completeProject
    }
    
    WorkflowStatus public workflowStatus;
    
    // Structs
    
    struct Project {
        string projectName;
        uint256 amount;
        uint deadline;
        bool accepted;
        bool completed;
        address payable undertaker;
    }
    
    Project[] public projects;
    
    struct SubmitRequest {
        uint projectId;
        string title;
        uint256 amount;
        bool locked;
        bool paid;
    }
    
    SubmitRequest[] public submitRequests;
    
    
    
    //Modifiers 
    
    modifier onlyFreelancer() {
        require(msg.sender == freelancer, "Only Freelancer!");
        _;
    }
    modifier onlyEmployer() {
        require(msg.sender == employer, "Only Employer!");
        _;
    }
    modifier onlyAssignedUndertaker(uint _index) {
        require(msg.sender == projects[_index].undertaker, "Only assigned undertaker");
        _;
    }
    modifier onlyAfterHiringFreelancer() {
     require(workflowStatus == WorkflowStatus.hireFreelancer, "this function can only be called when a Freelancer has been hired");
     _;
    }
    modifier onlyAfterCreatingProject() {
     require(workflowStatus == WorkflowStatus.createProject, "this function can only be called after creating a project");
     _;
    }
    modifier onlyAfterAcceptingProject() {
     require(workflowStatus == WorkflowStatus.acceptProject, "this function can only be called when you have accepted the project");
     _;
    }
    modifier onlyAfterCompletingProject(uint _projectId) {
     require(projects[_projectId].completed == true, "Only when project is marked completed");
        _;
    }
    modifier checkDoubleSubmission(uint _projectId) {
     require(projects[_projectId].completed != true, "You have already submitted this project");
        _;
    }
    modifier onlyAfterPayingFreelancer(uint _requestId) {
     require(submitRequests[_requestId].paid == true, "You have not paid the freelancer's request");
        _;
    }
    
    
    //Events
    
    event ProjectCreated(string projectName, uint256 amount, bool accepted, bool completed, address Freelancer);
    event ProjectAccepted(bool accepted);
    event ProjectBrokenDown(uint projectId, string stageName, uint stageCost);
    event RequestUnlocked(bool locked);
    event RequestCreated(string title, uint256 amount, bool locked, bool paid);
    event RequestPaid(address receiver, uint256 amount);
    event EmployerRefunded(address receiver, uint amount);
    event WorkflowStatusChangeEvent (WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
    
    
    
    
    
    constructor(address payable _freelancer) payable {
        employer = payable(msg.sender); //msg.sender cannot be implicitly converted to a payable address
        freelancer = _freelancer;
        budget = msg.value;
        workflowStatus = WorkflowStatus.hireFreelancer;
        
    }
    
    receive () external payable {
        budget += msg.value; 
    }
    
    //Employer creates projects for a freelancer
    
    function createProject(string memory _projectName, uint256 _amount, uint _deadline) public onlyEmployer onlyAfterHiringFreelancer{
       Project memory project = Project({
          projectName: _projectName,
          amount: (_amount * 1000000000000000000),
          deadline: _deadline,
          accepted: false,
          completed: false,
          undertaker: freelancer
        });
       projects.push(project);
       workflowStatus = WorkflowStatus.createProject;
       
       emit ProjectCreated(_projectName, _amount, project.accepted, project.completed, freelancer);
       
       emit WorkflowStatusChangeEvent(
            WorkflowStatus.hireFreelancer, workflowStatus);
    }
    
    // Freelancer accepts project
    
    function acceptProject(uint _index) public onlyAssignedUndertaker(_index) onlyAfterCreatingProject{
        projects[_index].accepted = true;
        
         workflowStatus = WorkflowStatus.acceptProject;
        
        emit ProjectAccepted(projects[_index].accepted);
        
        	        
        emit WorkflowStatusChangeEvent(
            WorkflowStatus.createProject, workflowStatus);
    }
   
    
    
    function submitProject(uint _projectId, string memory _title, uint256 _amount) public onlyAssignedUndertaker(_projectId) checkDoubleSubmission(_projectId){
       require((_amount * 1000000000000000000) == projects[_projectId].amount, "You are not charging what you accepted earlier");
       SubmitRequest memory submitRequest = SubmitRequest({
          projectId: _projectId,
          title: _title,
          amount: (_amount * 1000000000000000000),
          locked: true,
          paid: false
        });
       submitRequests.push(submitRequest);
       
       emit RequestCreated(_title, _amount, submitRequest.locked, submitRequest.paid);
    }
    
    function getAllRequests() public view returns (SubmitRequest[] memory) {
        return submitRequests;
    }
    
    function approveProject(uint256 _requestIndex, uint _projectId) public onlyEmployer{
        SubmitRequest storage submitRequest = submitRequests[_requestIndex];
        require(submitRequest.locked, "Already unlocked");
        submitRequest.locked = false;
        
        projects[_projectId].completed = true;
        
        emit RequestUnlocked(submitRequest.locked);
    }
    
    function receivePayment(uint256 _requestIndex, uint _projectId) public onlyAssignedUndertaker(_projectId) onlyAfterCompletingProject(_projectId) {
        
        require(!locked,'Reentrant detected!');
        
        SubmitRequest storage submitRequest = submitRequests[_requestIndex];
        require(!submitRequest.locked, "Request is locked");
        require(!submitRequest.paid, "Already paid");
        
        locked = true;
        
        (bool success, bytes memory transactionBytes) = 
        freelancer.call{value:submitRequest.amount}('');
        
        require(success, "Transfer failed.");
        
        submitRequest.paid = true;
        
        locked = false;
        
        budget -= submitRequest.amount;
        
        emit RequestPaid(msg.sender, submitRequest.amount);
    } 
    
    function refundEmployerBalance (uint _requestId) public onlyEmployer onlyAfterPayingFreelancer(_requestId) {
        (bool success, bytes memory transactionBytes) = 
        employer.call{value:budget}('');
        
        require(success, "Transfer failed.");
        
        emit EmployerRefunded(msg.sender, budget);
        
        budget = 0;
    }
    
    function showBalance () public onlyEmployer view returns (uint) {
        return budget;
    }
  
}