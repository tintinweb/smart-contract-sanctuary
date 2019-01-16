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
        string milestone_data;
    }
    
     struct Project {        
        string project_data;
    }

    struct Items {
        
        address owner;
        string project_name;
        
        Project project_details;
        Milestones milestone_details;
        
        string[] payment_data;
        string[] activity_data;
    }
    
    address owner;
    mapping (uint256 => Items) public items;
    
    uint256 public project_count;
    uint256 public payment_count;
    uint256 public activity_count;
    
    constructor() public {
           
    }

    // mint the project with the project name, project data and the milestone details during the project creation.
    
    function mint(string _project_name, string _project_data, string _milestone_data)
    external onlyOwner returns(uint256 _id) {
        _id = ++project_count;

        items[_id].owner = msg.sender;
        items[_id].project_name = _project_name;
        
        items[_id].project_details.project_data = _project_data;
        items[_id].milestone_details.milestone_data= _milestone_data;
    }


    // Set payment details which will include milestone few details as well
    function set_payment_details(uint256 _id, string _payment_data)
    external onlyOwner returns(uint256) {
        
        items[_id].payment_data[payment_count] = _payment_data;
        ++payment_count;
    }
    
    // Set activity details in the project
    function set_activity_details(uint256 _id, string _activity_data)
    external onlyOwner returns(uint256) {

        items[_id].activity_data[activity_count] = _activity_data;
        ++activity_count;
    }

    // Getters for project all detialed Information
    function get_all_project_information(uint256 _id) onlyOwner public returns(string, string, string[], string[]) {
        return (
            items[_id].project_details.project_data,
            items[_id].milestone_details.milestone_data,
            items[_id].payment_data,
            items[_id].activity_data);
            }
            
     // Getters for milestones Information
    function get_milestone_information(uint256 _id) onlyOwner public returns(string) {
        return (
            items[_id].milestone_details.milestone_data);
            }
            
    // Getters for project Information
    function get_project_information(uint256 _id) onlyOwner public returns(string) {
        return (
            items[_id].project_details.project_data);
            }
            
    // Getters for payment all Information
    function get_all_payment(uint256 _id) onlyOwner public returns(string[]) {
        return (
            items[_id].payment_data);
            }
            
    // Getters for activity all Information
    function get_all_activityn(uint256 _id) onlyOwner public returns(string[]) {
        return (
            items[_id].activity_data);
            }
            
    // Getters for payment single Information
    function get_payment_by_id(uint256 _id, uint256 _p_id) onlyOwner public returns(string) {
        return (
            items[_id].payment_data[_p_id]);
            }
            
     // Getters for activity single Information
    function get_activity_by_id(uint256 _id, uint256 _a_id) onlyOwner public returns(string) {
        return (
            items[_id].activity_data[_a_id]);
            }
}