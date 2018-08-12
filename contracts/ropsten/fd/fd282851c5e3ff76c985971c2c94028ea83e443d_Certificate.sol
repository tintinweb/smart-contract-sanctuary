pragma solidity ^0.4.22;


contract Certificate {
  struct Course{
    uint idCourse;
    string TimeStart;
    string TimeEnd;
    string Description;
    string TeacherName;
  }

  struct StudentRequest{
    string StuAddr;
    string email;
    string phone;
    string StudentName;
    uint idCourse;
    bool isComplete;
  }

  address staffaddr;    //Show the staff address
  mapping(uint=>Course) courses;    //List of courses
  mapping(uint=>StudentRequest) students;   //List of StudentRequest
  mapping (uint=>bool) checkCourse; //Check course base on idCourse
  mapping(uint=>bool) checkStudent; //Check student base on idStudent
  uint public idCount;  //Variable represent of amoumt of courses
  uint public idStudent;    //Variable represent of amount of student  Request 
  uint public StudentCount=0;
  
  constructor() public{
    staffaddr=msg.sender;
  }
 
    //Define the person who have priviledge to do sth
    modifier onlyStaff {
        require(msg.sender==staffaddr);
        _;
  }
    
    //Add student who want to become the member of some courses
    function AddStudent() onlyStaff public{
        StudentCount++;
        checkStudent[StudentCount]=true;
    }

    //1
    function AddNewCourse(string start, string end, string des, string teachername) onlyStaff public{
        idCount++;
        courses[idCount].idCourse=idCount;
        courses[idCount].TimeStart=start;
        courses[idCount].TimeEnd=end;
        courses[idCount].Description=des;
        courses[idCount].TeacherName=teachername;
        checkCourse[idCount]=true;
  }

    //2
    function getCoursesCount() public view returns (uint){
        return idCount;
    }
    
    
    //3
    function applyForCandidate(string stAddr1, uint idcourse, string name, string phone, string email, uint id, bool iscomp) onlyStaff public {
        require(checkCourse[idcourse]==true);
        idStudent++;    //Count the number of student want to be provided certificate
        
        //Add information
        students[id].StuAddr=stAddr1;
        students[id].StudentName=name;
        students[id].email=email;
        students[id].phone=phone;
        students[id].idCourse=idcourse;
        students[id].isComplete=iscomp;
    }
    
    //4
    function getStudent() public view returns (uint){
        return idStudent;
    }    

    //5.1
    function provideCertificate(uint idStu, uint idCours) onlyStaff view public returns (uint, string, string, uint, string){
        return(courses[idCours].idCourse, courses[idCours].TeacherName, students[idStu].StudentName,idStudent, "Completed");
    }
    
    function approveCertificate(uint idStu, uint idCours) onlyStaff view public returns (bool){
        require(checkStudent[idStu]==true);
        require (checkCourse[idCours]==true);
        if(students[idStu].isComplete==true)
            provideCertificate(idStu, idCours);
        return true;
    }
  
    //5.2
    function rejectCertificate(uint idStu, uint idCours) onlyStaff public returns(string) {
        if(approveCertificate(idStu, idCours)==false){
            delete(students[idStu]);
            idStudent--;
            return "Not Found!!";
        }
    }
    
    //5.3 
    function clearAllRequest()onlyStaff public{
        for(uint i=0; i<idStudent; i++){
            delete(students[i+1]);
            idStudent=0;
        }
    }
    
    //6 
    function FindCourseBaseOnIdStudent(uint id) public view returns(string, string, uint, string, string){
        require(checkStudent[id]==true);
        uint i=students[id].idCourse;
        
        return(courses[i].Description, courses[i].TeacherName, courses[i].idCourse, courses[i].TimeStart, courses[i].TimeEnd);
    }
    
    //7 
    mapping (uint => Course) public CourseBaseOnIdStudent;
    function CourseBaseOnIdStudentFunct(uint idStu) public
    {
        require(checkStudent[idStu]==true);
        uint i=students[idStu].idCourse;
        CourseBaseOnIdStudent[idStu]=Course(i, courses[i].TimeStart, courses[i].TimeEnd, courses[i].Description, courses[i].TeacherName);
    }
    
    function provideInfoCourseBaseOnIdStudent(uint idStu) public view returns(uint, string, string, string, string){
        return (CourseBaseOnIdStudent[idStu].idCourse, CourseBaseOnIdStudent[idStu].TimeStart, CourseBaseOnIdStudent[idStu].TimeEnd, CourseBaseOnIdStudent[idStu].Description, CourseBaseOnIdStudent[idStu].TeacherName);
    }
}