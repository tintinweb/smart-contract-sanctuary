pragma solidity 0.4.24;

contract Certification {
    
    struct Course {
        uint idCourse;
        string name;
        uint startDate;
        uint endDate;
        string description;
        string instructor;
    }
    
    struct StudentRequest {
        address addr;
        string name;
        string email;
        string phone;
        uint idCourse;
        bool complete;
    }
    
    Course[] public  courses;
    
    
    StudentRequest[] public studentRequests;
    
    address public educator;
    mapping(address => mapping (uint => bool)) public students;
    
    function Certification() public {
        educator = msg.sender;
    }
    
    modifier hasPermission() {
        require(msg.sender == educator);
        _;
    }

    function addCourse(uint _idCourse, string _name, uint _daystart, uint _dayend, string _description, string _instructor) hasPermission public {
        courses.push(Course(_idCourse, _name, _daystart, _dayend, _description, _instructor));
    }
    
    function countCourse() public view returns (uint){
        return courses.length;
    }
    
    function applyForCertification(string _name, string _email, string _phone, uint _idCourse) {
        studentRequests.push(StudentRequest(msg.sender,_name, _email, _phone, _idCourse, false));
    }
    
    function countStudentRequest() public view returns (uint) {
        return studentRequests.length;
    }
    
    function approveCertification(uint _indexRequest) hasPermission public  {
        StudentRequest storage request = studentRequests[_indexRequest];
        request.complete = true;
        students[request.addr][request.idCourse] = true;
    }
    
    function rejectCertification(uint _indexRequest) hasPermission public {
        StudentRequest storage request = studentRequests[_indexRequest];
        request.complete = true;
    }
    
    function clearAllRequest() hasPermission public {
        bool flag = true;
        for(uint i=0 ;i<studentRequests.length; i++){
            flag = flag && studentRequests[i].complete;
            if(!flag){
                return;
            }
        }
        require(flag);
        studentRequests.length = 0;
    }
    
    function verifyCertification(address _addrStudent, uint _idCourse) view public returns(string) {
        string storage courseName;
        if(students[_addrStudent][_idCourse]){
            courseName = courses[_idCourse].name;
        }
        return courseName;
    } 
    
    
}