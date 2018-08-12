pragma solidity ^0.4.23;

contract Cetificate{
    
    //định nghĩa một cấu tr&#250;c y&#234;u cầu sinh vi&#234;n c&#243; th&#244;ng tin c&#225; nh&#226;n sv
    struct studentsRequest{
        string _ten;
        string _idSV;
        string _diachi;
        string _email;
        string _sdt;
        string _courseID;
        bool _dat;
    }
    //định nghĩa một cấu tr&#250; khoa học
    struct Course{
        string _tenKH;
        string _ngayBD;
        string _ngayKt;
        string _mota;
        string _gv;
        string _courseID;
        //uint256 _loaiKH;
    }
    
    //mảng lưu c&#225;c y&#234;u cầu sv
    studentsRequest[] public studentsRequests;
    //mảng lưu th&#244;ng tin c&#225;c kh&#243;a học
    Course[] public courses;
    //Bảng lưu th&#244;ng tin sv tương ứng vs khoa học
    mapping (address => studentsRequest) Student2Coure;
    //nhằm lưu trữ địa chỉ th&#244;ng tin của một sinh vi&#234;n đ&#227; y&#234;u cầu cấp chứng chỉ 
    address public Student;
  	mapping (address => studentsRequest) Students;
  	
  	address public educator; 

  	constructor() public{
  		educator = msg.sender;
  	}
 	//hạn chế truy cập, chỉ c&#243; người tạo  mới được truy cập
 	modifier hasPermission{ 
 		require (msg.sender == educator); 
 		_; 
 	}
  	
    function addCourses(string tenkh, string ngaybd,string ngaykt, 
                    string mota, string gv, string coursesid) hasPermission public {
                        Course memory newcourses = Course({
                            _tenKH:tenkh,
                            _ngayBD:ngaybd,
                            _ngayKt:ngaykt,
                            _mota:mota,
                            _gv:gv,
                            _courseID:coursesid
                            });
                        courses.push(newcourses);
    }
    
    //
    //lưu c&#225;c y&#234;u c&#226;u của sinh vi&#234;n 
    function applyforCetification(string tensv, string idsv, string diachi, string email,
                                    string sdt, string courseid, bool dat)public{
                                     
                                     studentsRequest memory newstudentrequest= studentsRequest({
                                         _ten:tensv,
                                         _idSV:idsv,
                                         _diachi:diachi,
                                         _email:email,
                                         _sdt:sdt,
                                         _courseID:courseid,
                                         _dat:dat
                                     });
                                     
                        studentsRequests.push(newstudentrequest);
        
    }
 
    //ki&#234;m tra co bao nhieu khoa học
    function getcoursesLenght() returns(uint256 count){//ki&#234;m tra co bao nhieu khoa học
        count = courses.length;
        return count;
    }
    
   //kiem tra co bao nhi&#234;u sv y&#234;u cầu cấp chứng chỉ
    function checkStudentsApply() returns(uint256 count){
        return studentsRequests.length;
    }
    //x&#225;c nhận cấp chứng chỉ cho sv
    function approveCetification(address stu) public hasPermission {
        Students[stu]._dat=true;
    }
    //kh&#244;ng cấp chứng chỉ cho sv
    function rejectCetification(address stu)public hasPermission{
        Students[stu]._dat=false;
    }
   // xoa to&#224;n bộ c&#225;c y&#234;u cầu cấp chứng chỉ
    function clearAllrequest() public{
        delete studentsRequests;
    }
    
    function checkcoursestudent(address st) returns(string cou){
       return Student2Coure[st]._courseID;
    }
    
}