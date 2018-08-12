pragma solidity ^0.4.17;

contract Cetification {
    
    struct Course{
        string c_Name;
        uint c_ID;
        string startDate;
        string endDate;
        string Description;
        string Instructor;
    }
    
    struct Student{
        string addressStudent;
        string Email;
        string Phone;
        string s_Name;
        uint CourseID;
        bool Status_pass;
    }
    
    mapping (uint => Course) public courses;
    mapping (uint => Student) public studentRequests;
    mapping (uint => Student) public studentPass;
  
    
    address private Educator;
    uint private NumOfCourses = 0;
    uint private requestID = 0;
    uint private NumOfStudentsPass = 0;
    
    constructor () public {
        Educator = msg.sender;
    }
    
    modifier hasPermission {
        require(msg.sender == Educator);
        _;
    }
    
     
    function addCourse (string _c_Name, uint _c_ID, string _startDate, string _endDate, string _Description, string _Instructor) public hasPermission {
        NumOfCourses++;
        courses[NumOfCourses]= Course( _c_Name, _c_ID,  _startDate,  _endDate, _Description, _Instructor);
 
    }

    function coursesLength() public view returns(uint ){
        return  NumOfCourses;
    }
    
    
    function ApplyForCertification ( string _addStudent, string _Email, string _Phone, string _s_Name,uint _CourseID) public{
        
        requestID++;
        studentRequests[requestID] = Student(_addStudent, _Email, _Phone,_s_Name, _CourseID, false);
    }
    
    
    function NumOfStudentsRequests() public view returns(uint ){
        return requestID;
    }
    
    
    function approveCertification(uint _requestID) hasPermission public returns (bool) 
    {
        NumOfStudentsPass++;//1
        
        studentPass[NumOfStudentsPass] = studentRequests[_requestID];
        studentPass[NumOfStudentsPass].Status_pass=true;
        
        studentRequests[_requestID].Status_pass=true;
        return  studentPass[NumOfStudentsPass].Status_pass;
    }
    
    function rejectCertification(uint _requestID) hasPermission public returns (bool)
    {
        studentRequests[_requestID].Status_pass = false;
        return  studentRequests[_requestID].Status_pass;
    }
    
    function _NumOfStudentsPass() public view returns(uint ){
        return NumOfStudentsPass;
    }
    
     function clearAllRequests() public{
         
        while (requestID > 0){
            delete studentRequests[requestID];
            requestID--;
        }
    }

    function CheckCourse(uint _a) public view returns  (string , uint, string, string , string , string){
        uint i = NumOfCourses;
        while (i>0){
        if (studentPass[_a].CourseID == courses[i].c_ID){
            return (courses[i].c_Name, courses[i]. c_ID, courses[i].startDate, courses[i].endDate, courses[i].Description, courses[i].Instructor);
        }
        else
        return ("Null",0,"Null","Null","Null","Null");
        }
    }
}