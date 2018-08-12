pragma solidity ^0.4.22;

contract certificate_UIT_DZ_MAX{
    struct StudentRequest{
        address addressStudent;
        string email;
        string phone;
        string nameStudent;
        uint courseid;
        bool isDone;
    }
    
    struct Course{
        string name;
        uint id;
        uint dayStart;
        uint dayEnd;
        string lecturer;
    }
    //lưu trữ sinh vi&#234;n tham gia kh&#243;a học tương ứng.
    mapping(address=>mapping(uint=>bool)) student2course;
    
    //định nghĩa mảng d&#249;ng để lưu trữ c&#225;c kh&#243;a học
    Course[] public courses;
    // định nghĩa 1 mảng d&#249;ng để lưu trữ c&#225;c y&#234;u cầu cấp chứng chỉ.
    StudentRequest[] public student_requests;
    //store courses count
    // h&#224;m khởi tạo 
    //uint public index_student;
    
    address public educater = msg.sender;
    
    modifier hasPermission(){
        require(
            msg.sender ==educater,//just educater have permission
            "Just owner have permission"
        );
        _;//continue executing rest of method body
    }
    
    
    //1 khởi tạo th&#234;m th&#244;ng tin 1 kh&#243;a học mới v&#224;o constract
    function addCourse(string _name, uint _id, uint _dayStart, uint _dayEnd, string _lecturer)public{
        courses.push(Course(_name,_id,_dayStart,_dayEnd, _lecturer));
    }
    
    //2 kiểm tra xem c&#243; bao nhi&#234;u kh&#243;a học
    function numCourse() public view returns(uint){
        return courses.length;
    } 
    
    //3 cho người học nhập th&#244;ng tin
    function applyForCertification(string _email, string _phone, string nameStudent, uint _courseid, bool _isDone  ) public{ 
        //index_student++;
        student_requests.push(StudentRequest(msg.sender, _email ,_phone, nameStudent, _courseid, _isDone));
    }
    
    //4 kiểm tra xem c&#243; bao nhi&#234;u sinh vi&#234;n y&#234;u cầu cấp chứng chỉ
    function numStudentRequest()public view returns(uint){
        return student_requests.length;
    }
    
    //5.1 ph&#225;t h&#224;nh chứng chỉ kh&#243;a học cho sinh vi&#234;n
    function approveCertificate(uint _requestID)public{
        StudentRequest storage request = student_requests[_requestID];//lưu trữ 1 request từ 1 idrequest trong tất cả c&#225;c request
        request.isDone = true;//chứng nhận đ&#227; đ&#227; ho&#224;n th&#224;nh
        student2course[request.addressStudent][request.courseid]=true;//d&#249;ng để l&#224;m c&#226;u 6
    }
    
    //5.2
    function rejectCertificate(uint _requestID)public{
        StudentRequest storage request = student_requests[_requestID];
        request.isDone = false;//chuyển qua false, từ chối cấp
    }
    
    //5.3
    function clearAllrequest()public{
        //giả sử tất cả c&#225;c sinh vi&#234;n đề ho&#224;n th&#224;nh th&#224;nh kh&#243;a học
        bool allCompleted =true;
        for(uint i = 0; i < student_requests.length;i++){//duyệt tất cả c&#225;c y&#234;u cầu
            allCompleted = allCompleted && student_requests[i].isDone;
            //nếu c&#243; 1 y&#234;u cầu chưa ho&#224;n th&#224;nh th&#236; kh&#244;ng được x&#243;a
            if(!allCompleted){
                return;
            }
        }
        //require(allCompleted);
        //nếu tất cả y&#234;u cầu đều đ&#227; ok th&#236; x&#243;a tất cả
        student_requests.length=0;//delete all element in array.
    }
    
    //6 
    function verifyCertification(address _studentAddress, uint _courseid) view public returns(string){
        string memory courseName;
        if(student2course[_studentAddress][_courseid]){//kiểm tra xem đ&#227; được cấp chứng chỉ hay chưa??,
            courseName =courses[_courseid].name;
            //nếu rồi th&#236; lấy t&#234;n của kh&#243;a học đ&#243;
        }
        return courseName;//trả về t&#234;n kh&#243;a học
        
    }
    
}