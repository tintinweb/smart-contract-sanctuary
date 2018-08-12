pragma solidity ^0.4.23;

contract Cestificate{
    //lưu trữ th&#244;ng tin của 1 sinh vi&#234;n
    struct student{
        address addr;                           //địa chỉ (address)
        string email;                           //địa chỉ email
        uint phone;                             //số điện thoại
        string name;                            //t&#234;n sinh vi&#234;n
        uint courseId;                          //m&#227; số kh&#243;a học
        bool check;                             //kiểm tra đ&#227; ho&#224;n th&#224;nh hay chưa
        //mapping(address => course) courses_std;
    }
    
    //lưu trữ th&#244;ng tin của 1 kh&#243;a học
    struct course{
        string name;                            //t&#234;n của kh&#243;a học
        uint id;                                //m&#227; số (id) của kh&#243;a học
        uint dbegin;                            //ng&#224;y bắt đầu
        uint dend;                              //ng&#224;y kết th&#250;c
        string decription;                      //m&#244; tả kh&#243;a học
        string lecture;                         //gi&#225;o vi&#234;n
        //mapping(address => student) students;
    }
    
    //biến loại mapping để lưu trữ bảng c&#225;c SV tham gia kh&#243;a học tương ứng
    mapping(address => mapping(uint => bool)) student2course;
    
    //mảng để lưu trữ c&#225;c kh&#243;a học
    course[] public courses;
    
    //mảng để lưu trữ c&#225;c y&#234;u cầu cấp chứng chỉ của kh&#243;a học
    student[] public studentRequest;
    
    //khởi tạo th&#234;m th&#244;ng tin của 1 kh&#243;a học mới
    function addCourse(string _name, uint _id, uint _begin, uint _dend, string _description, string _lecture) public{
        courses.push(course(_name, _id, _begin, _dend, _description, _lecture));       
    }
    
    //Kiểm tra xem c&#243; bao nhi&#234;u kh&#243;a học
    function getCourseLength() public view returns(uint){
        return courses.length;
    }
    
    //nhập th&#244;ng tin sinh vi&#234;n
    function applyForCertifition(address _addr, string _email, uint _phone, string _name, uint _courseId, bool _check) public{
        studentRequest.push(student(_addr, _email, _phone, _name, _courseId, _check));
    }
    
    //kiểm tra xem c&#243; bao nhi&#234;u sinh vi&#234;n gửi y&#234;u cầu cấp chứng chỉ    
    function getStudentRequest() public view returns(uint){
        return studentRequest.length;
    }
    
    //ph&#225;t h&#224;nh chứng chỉ kh&#243;a học cho sinh vi&#234;n
    function approCertificate(uint _requestId) public{
        student storage request = studentRequest[_requestId];
        request.check = true;
        student2course[request.addr][request.courseId] = true;
    }
    
    //từ chối cấp chứng chỉ
    function rejectCertificate(uint _requestId) public {
        student storage request = studentRequest[_requestId];
        request.check = true;
    }
    
    //xoa tất cả c&#225;c y&#234;u cầu
    function clearAllRequests() public {
        //do đề kh&#244;ng y&#234;u cầu kiểm tra xem sanh di&#234;n đ&#243; c&#243; được cấp hay chưa n&#234;n chỉ cần x&#243;a hết x&#243;a hết l&#224; ok
        /*bool completed = true;
        for (uint i = 0; i < studentRequest.length; i++){
            completed = completed && studentRequest[i].check;
            if (!completed){
                return;
            }
        }
        require(completed);*/
        studentRequest.length = 0;
    }
    
    //x&#225;c thự xem chứng chỉ của sinh vi&#234;n thuộc kh&#243;a học n&#224;o
    function verifyCestificate(address _addr, uint _courseId) public view returns(string) {
        string memory courseName;
        if (student2course[_addr][_courseId]){
            courseName = courses[_courseId].name;
        }
        return courseName;
    }

}