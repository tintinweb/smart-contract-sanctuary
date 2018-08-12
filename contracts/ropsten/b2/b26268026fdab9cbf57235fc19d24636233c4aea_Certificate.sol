pragma solidity ^0.4.24;
contract Certificate {
    
    uint private courseCount=0; //so luong course
    uint private requestCount=0; //so luong request
    address public educator;
    struct course {
        uint c_id;//auto generate
        string c_name;
        string c_starttime;
        string c_endtime;
        string c_description;
        string c_instructor;
    }
    
    struct studentRequest {
        uint s_id;//auto generate
        string s_name;
        string s_address;
        string s_email;
        string s_phone;
        uint c_id; //courseID
    }
    mapping(address => mapping(uint => uint)) public student2course;
    // bang sinh vien tham gia cac khoa hoc tuong ung
    course[] public courseList; // mang luu danh dach course
    studentRequest[] public requestList; //mang luu danh sach request
    
    constructor() { //constructor
        educator =msg.sender;
    }
    modifier hasPermission(){ // restriction access
        require (msg.sender==educator); 
        _;
        
    }
    
    // them course
    function addCourse (string c_name,string c_starttime,string c_endtime,string c_description,string c_instructor) 
        hasPermission() {
        courseCount++;
        courseList[courseCount]=course(courseCount,c_name,c_starttime,c_endtime,c_description,c_instructor);
    }
    
    //co bao nhieu course
    function getCoursesLength() public view returns(uint) {
            return courseCount;
    }
    
    //them request
    function applyForCertification (string s_name,string s_address,string s_email,string s_phone,uint s_c_id){
        requestCount++;
        requestList[requestCount]=studentRequest(requestCount,s_name,s_address,s_email,s_phone,s_c_id);
    }
    
    //co bao nhieu request
    function getStudentRequestsLength() public view returns(uint) {
            return requestCount;
    }
    
    //phat hanh chung chi
    function approveCertificate (uint reID)
        hasPermission() returns (bool) {
            return student2course[msg.sender][requestList[reID].c_id]==1; //pass course
    }

    //tu choi cap chung chi
    function rejectCertificate (uint reID)
        hasPermission() returns (bool) {
            return student2course[msg.sender][requestList[reID].c_id]==2; //fail course
        
    }
    //xac nhan Sinh vien - Khoa hoc
    function verifyCertificate (address studentAddress, uint courseID) public view
        returns (bool) {
            return (student2course[studentAddress][courseList[courseID].c_id]!=0);
            //verified student of this course
    }
    //xoa toan bo request
    function clearAllRequests() 
        hasPermission() {
            requestCount=0;
    }
    
}