pragma solidity 0.4.25;

contract HighwayCertificates {
    
    event NewCertificate(uint256, string, string, string, string, string);
    
    struct Certificate {
        
        string student_name;
        string course_name;
        string project_name;
        string mentor_name;
        string course_dates;
    }
    
    address public owner;
    uint256 public count = 0;
    mapping(uint256 => Certificate) public certificates;
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can use this function");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function addCertificate(string student, string course, string project, string mentor, string dates) public onlyOwner {
        count++;
        emit NewCertificate(count, student, course, project, mentor, dates);
    }
}