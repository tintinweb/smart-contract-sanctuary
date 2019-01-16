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
        owner = newOwner;
    }
}



/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items
*/
contract TBProject is owned {
    
    
    struct Milestones {
        string milestoneData;
    }
    
     struct Project {        
        string projectData;
    }

    struct Items {
        
        address owner;
        string projectName;
        
        Project projectDetails;
        Milestones milestoneDetails;
        
        string[] paymentData;
        string[] activityData;
    }
    
    address owner;
    mapping (uint256 => Items) public items;
    
    uint256 public projectCount;
    uint256 public paymentCount;
    uint256 public activityCount;
    
    constructor() public {
           
    }

    // mint the project with the project name, project data and the milestone details during the project creation.
    
    function mintProject(string _project_name, string _project_data, string _milestone_data, address _owner)
    external onlyOwner returns(uint256 _id) {
        require(owner == _owner);
        
        _id = ++projectCount;

        items[_id].owner = msg.sender;
        items[_id].projectName = _project_name;
        
        items[_id].projectDetails.projectData = _project_data;
        items[_id].milestoneDetails.milestoneData= _milestone_data;
    }


    // Set payment details which will include milestone few details as well
    function set_payment_details(uint256 _id, string _payment_data, address _owner)
    external onlyOwner returns(uint256) {
        require(owner == _owner);
        
        items[_id].paymentData[paymentCount] = _payment_data;
        ++paymentCount;
    }
    
    // Set activity details in the project
    function set_activity_details(uint256 _id, string _activity_data, address _owner)
    external onlyOwner returns(uint256) {
        require(owner == _owner);

        items[_id].activityData[activityCount] = _activity_data;
        ++activityCount;
    }

    // Getters for project all detialed Information
    function get_all_project_information(uint256 _id, address _owner) onlyOwner public returns(string, string, string[], string[]) {
        
        require(owner == _owner);
        
        return (
            items[_id].projectDetails.projectData,
            items[_id].milestoneDetails.milestoneData,
            items[_id].paymentData,
            items[_id].activityData);
            }
            
     // Getters for milestones Information
    function get_milestone_information(uint256 _id, address _owner) onlyOwner public returns(string) {
        require(owner == _owner);
        
        return (
            items[_id].milestoneDetails.milestoneData);
            }
            
    // Getters for project Information
    function get_project_information(uint256 _id, address _owner) onlyOwner public returns(string) {
        require(owner == _owner);
        
        return (
            items[_id].projectDetails.projectData);
            }
            
    // Getters for payment all Information
    function get_all_payment(uint256 _id, address _owner) onlyOwner public returns(string[]) {
        require(owner == _owner);
        
        return (
            items[_id].paymentData);
            }
            
    // Getters for activity all Information
    function get_all_activity(uint256 _id, address _owner) onlyOwner public returns(string[]) {
        require(owner == _owner);
        
        return (
            items[_id].activityData);
            }
            
    // Getters for payment single Information
    function get_payment_by_id(uint256 _id, uint256 _p_id, address _owner) onlyOwner public returns(string) {
        require(owner == _owner);
        
        return (
            items[_id].paymentData[_p_id]);
            }
            
     // Getters for activity single Information
    function get_activity_by_id(uint256 _id, uint256 _a_id, address _owner) onlyOwner public returns(string) {
        require(owner == _owner);
        
        return (
            items[_id].activityData[_a_id]);
            }
}