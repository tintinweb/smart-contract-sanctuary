pragma solidity 0.4.24;

contract Certification {
    
    struct Course {
        string name;
        uint startDate;
        uint endDate;
        string description;
        string instructor;
    }
    
    struct StudentRequest {
        address studentAddress;
        string studentName;
        string studentEmail;
        string studentPhone;
        uint courseId;
        bool complete;
    }
    
    address public educator;
    Course[] public courses;
    StudentRequest[] public studentRequests;
    mapping(address => mapping(uint => bool)) public student2course;
    
    constructor() public {
        educator = msg.sender;
    }
    
    modifier hasPermission {
        require(msg.sender == educator);
        _;
    }
    
    function addCourse(
        string _name, uint _startDate, uint _endDate, 
        string _description, string _instructor
    ) hasPermission public {
        Course memory newCourse = Course({
            name: _name,
            startDate: _startDate,
            endDate: _endDate,
            description: _description,
            instructor: _instructor
        });
        
        courses.push(newCourse);
    }
    
    function getCoursesLength() public view returns (uint) {
        return courses.length;
    }
    
    function applyForCertification(
        string _studentName, string _studentEmail, 
        string _studentPhone, uint _courseId
    ) public {
        StudentRequest memory newStudentRequest = StudentRequest({
            studentAddress: msg.sender,
            studentName: _studentName,
            studentEmail: _studentEmail,
            studentPhone: _studentPhone,
            courseId: _courseId,
            complete: false
        });
        
        studentRequests.push(newStudentRequest);
    }
    
    function getStudentRequestsLength() public view returns (uint) {
        return studentRequests.length;
    }
    
    function approveCertification(uint _requestId) hasPermission public {
        StudentRequest storage request = studentRequests[_requestId];
        request.complete = true;
        student2course[request.studentAddress][request.courseId] = true;
    }
    
    function rejectCertification(uint _requestId) hasPermission public {
        StudentRequest storage request = studentRequests[_requestId];
        request.complete = true;
    }
    
    function verifyCertification(address _studentAddress, uint _courseId) 
    view public returns (string) {
        string memory courseName;
        if (student2course[_studentAddress][_courseId]) {
            courseName = courses[_courseId].name;
        }
        
        return (courseName);
    }
    
    function clearAllRequests() hasPermission public {
        bool allCompleted = true;
        for (uint i = 0; i < studentRequests.length; i++) {
            allCompleted = allCompleted && studentRequests[i].complete;
            if (!allCompleted) {
                return;
            }
        }
        
        require(allCompleted);
        studentRequests.length = 0;
    }
}