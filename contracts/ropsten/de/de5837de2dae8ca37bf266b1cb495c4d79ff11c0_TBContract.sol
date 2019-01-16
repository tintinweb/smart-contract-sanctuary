pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;


contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        
        require(newOwner != address(0));
        owner = newOwner;
    }
}



/**
  TBProject holds all the infromation from the project.
  Contains the activity within the project from the users.
  Information of the payments made 
*/
contract TBContract is owned {
    
    
    struct Milestones {
        string milestoneData;
    }
    
     struct ProjectDetails {        
        string projectData;
    }

    struct TBProjects {
        
        address owner;
        string projectName;
        
        Milestones milestoneDetails;
        ProjectDetails projectDetails;
        
        string[] paymentData;
        string[] activityData;
    }
    
    address owner;
    mapping (uint256 => TBProjects) public tbProject;
    
    uint256 public projectCount;
    uint256 public paymentCount;
    uint256 public activityCount;
    
    constructor() public {
           
    }

    // mint the project with the project name, project data and the milestone details during the project creation.
    
    function initProject(string _project_name, string _project_data, string _milestone_data)
    external onlyOwner returns(uint256 _id) {
        
        _id = ++projectCount;

        tbProject[_id].owner = msg.sender;
        tbProject[_id].projectName = _project_name;
        
        tbProject[_id].projectDetails.projectData = _project_data;
        tbProject[_id].milestoneDetails.milestoneData= _milestone_data;
    }


    // Set payment details which will include milestone few details as well
    function setPaymentDetails(uint256 _id, string _payment_data)
    external onlyOwner returns(uint256) {
        
        tbProject[_id].paymentData[paymentCount] = _payment_data;
        ++paymentCount;
    }
    
    // Set activity details in the project
    function setActivityDetails(uint256 _id, string _activity_data)
    external onlyOwner returns(uint256) {

        tbProject[_id].activityData[activityCount] = _activity_data;
        ++activityCount;
    }

    // Getters for project by id for all detialed Information
    function getProjectById(uint256 _id) onlyOwner public returns(string, string, string[], string[]) {
        
        return (
            tbProject[_id].projectDetails.projectData,
            tbProject[_id].milestoneDetails.milestoneData,
            tbProject[_id].paymentData,
            tbProject[_id].activityData);
    }
            
     // Getters for milestones Information
    function getMilestoneInformation(uint256 _id) onlyOwner public returns(string) {
    
        return (
            tbProject[_id].milestoneDetails.milestoneData);
    }
            
    // Getters for project Information
    function getProjectInformation(uint256 _id) onlyOwner public returns(string) {
       
        return (
            tbProject[_id].projectDetails.projectData);
    }
            
    // Getters for payment all Information
    function getAllPayment(uint256 _id) onlyOwner public returns(string[]) {
        
        return (
            tbProject[_id].paymentData);
    }
            
    // Getters for activity all Information
    function getAllActivity(uint256 _id) onlyOwner public returns(string[]) {
        
        return (
            tbProject[_id].activityData);
    }
            
    // Getters for payment single Information
    function getPaymentById(uint256 _id, uint256 _p_id) onlyOwner public returns(string) {
        
        return (
            tbProject[_id].paymentData[_p_id]);
    }
            
     // Getters for activity single Information
    function getActivityById(uint256 _id, uint256 _a_id) onlyOwner public returns(string) {
        
        return (
            tbProject[_id].activityData[_a_id]);
    }
}