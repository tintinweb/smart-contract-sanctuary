pragma solidity ^0.4.24;

contract Certificate {
    enum Status { unconfirmed, finished, unfinished }
    
    struct StudentRequest {
        string name;
        string email;
        string phone;
        string std_address;
        uint128 courseId;
        Status status;                      // request được x&#225;c nhận hay chưa, nếu rồi th&#236; l&#224; đ&#227; ho&#224;n th&#224;nh hay chưa ho&#224;n th&#224;nh
    }
    struct Course {
        int128 id;
        string start_date;
        string end_date;
        string description;
        string instructor;
    }
    
    
    address public educator;
    Course[] courses;
    // StudentRequest[] studentRequests;
    mapping (address => StudentRequest) studentRequest;        // lưu trữ th&#244;ng tin request tương ứng với địa chỉ gửi request đi,
                                                                // gi&#250;p đảm bảo một nơi chỉ được gửi một request
    address[] addresses;                                        // mảng lưu trữ c&#225;c địa chỉ c&#243; trong studentRequest
    mapping(address => uint) student2Course; //phone number to course id
    
    constructor () public {
        educator = msg.sender;
    }
    
    // modifer c&#243; nhiệm vụ giới hạn quyền cho một số h&#224;m
    modifier hasPermission {
        require(msg.sender == educator, "Sender not authorized.");
        _;
    }
    
    function addNewCourse(int128 _id, string start, string end, string des, string instr) 
        public hasPermission {
        Course memory newCourse = Course({
            id: _id,
            start_date: start,
            end_date: end,
            description: des,
            instructor: instr
        });
        courses.push(newCourse);
    }    
    
    function getNumberOfCourses() public view returns (uint numOfCourses) {
        return courses.length;
    }
    
    function applyForCertification(string _name, string _email, string _phone, string _address, uint128 _courseid) 
        public {
        StudentRequest memory newRequest = StudentRequest({
            name: _name,
            email: _email,
            phone: _phone,
            std_address: _address,
            courseId: _courseid,
            status: Status.unconfirmed 
        });
        studentRequest[msg.sender] = newRequest;
        addresses.push(msg.sender);
    }

    function getNumberOfRequests() public view returns (uint numOfReq) {
        return addresses.length;
    }
    
    // truyền địa chỉ nơi gửi y&#234;u cầu để kiểm tra, nếu y&#234;u cầu đ&#243; chưa được x&#225;c nhận th&#236; sẽ chấp nhận ho&#224;n th&#224;nh
    // nếu y&#234;u cầu đ&#227; được x&#225;c minh trước đ&#243; th&#236; trả về false do thao t&#225;c kh&#244;ng th&#224;nh c&#244;ng
    function approveCertificate(address s) public hasPermission view returns (bool) {
        if (studentRequest[s].status == Status.unconfirmed) {
            studentRequest[s].status = Status.finished;
            return true;
        }
        return false;
    }
    
    // truyền địa chỉ nơi gửi y&#234;u cầu để kiểm tra, nếu y&#234;u cầu đ&#243; chưa được x&#225;c nhận th&#236; sẽ g&#225;n l&#224; chưa ho&#224;n th&#224;nh
    // nếu y&#234;u cầu đ&#227; được x&#225;c minh trước đ&#243; th&#236; trả về false do thao t&#225;c kh&#244;ng th&#224;nh c&#244;ng
    function rejectCertificate(address s) public  hasPermission view returns (bool) {
        if (studentRequest[s].status == Status.unconfirmed) {
            studentRequest[s].status = Status.unfinished;
            return true;
        }
        return false;
    }
    
    // do kh&#244;ng thể delete to&#224;n bộ mapping n&#234;n em sẽ duyệt từng địa chỉ trong addresses, delete theo địa chỉ v&#224; sau đ&#243; delete mảng address
    function clearAllRequest() public hasPermission {
        for (uint i = 0; i < addresses.length; i++) {
            delete studentRequest[addresses[i]];
        }
        delete addresses;
    }
    
    // X&#225;c nhận sinh vi&#234;n thuộc kh&#243;a học n&#224;o
    // tham số truyền v&#224;o l&#224; địa chỉ nơi request được gửi v&#224; trả về course id  tương ứng
    function getCourseIdOfStudent(address s) public view returns (uint){
        return student2Course[s];
    }

    // x&#225;c nhận sinh vi&#234;n c&#243; đ&#227; ho&#224;n th&#224;nh kh&#243;a học hay chưa
    function verifyCertificate(address s, uint courseId) public view returns (bool) {
        return getCourseIdOfStudent(s) == courseId;
    }
}