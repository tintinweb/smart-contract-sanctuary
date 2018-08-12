pragma solidity ^0.4.17;
contract CertificateUniversity {
    //Lưu trữ th&#244;ng tin của 1 kh&#243;a học = struct chứa c&#225;c thuộc t&#237;nh như dưới
    struct Course{
        string NameCourse;
        uint CourseID;
        string StartDay;
        string EndDay;
        string Description;
        string Instructor;
    }
    //Lưu trữ th&#244;ng tin của 1 học vi&#234;n = struct chứa c&#225;c thuộc t&#237;nh như dưới
    struct Student{
        string Address;
        string Email;
        string Phone;
        string StudentName;
        uint CourseIDofStudent;
        bool CompleteCer;
    }
    
    //Biến xem trạng th&#225;i học vi&#234;n đ&#243; đ&#227; đạt chứng chỉ hay chưa
    bool public Status = false;
    
    //Mảng lưu trữ th&#244;ng tin c&#225;c kh&#243;a học
    mapping (uint => Course) public ListCourses; 
    //Mảng lưu trữ y&#234;u cầu cấp chứng chỉ kh&#243;a học
    mapping (uint => Student) public StudentRequests;
    //Mảng lưu trữ c&#225;c học vi&#234;n đ&#227; đạt chứng chỉ kh&#243;a học
    mapping (uint => Student) public StudentComplete; 
    
    //C&#225;c biến to&#224;n cục để sử dụng trong c&#225;c h&#224;m
    uint private CountCourse = 0; //Biến đếm kh&#243;a học
    uint private CountStudent = 0; //Biến đếm người học
    uint private CountStudentComplete = 0; //Biến đếm học vi&#234;n đ&#227; đạt chứng chỉ
    
    //H&#224;m khởi tạo địa chỉ người sở hữu.
    address public educator ;
    constructor () public {
       educator = msg.sender;
    }
    
    //H&#224;m cấp quyền cho người sở hữu để cập nhật dữ liệu
    modifier hasPermission {
        require(msg.sender == educator);
        _;
    }
    
    //H&#224;m th&#234;m th&#244;ng tin 1 kh&#243;a học v&#224;o contract
      //D&#249;ng hasPermission v&#236; th&#234;m kh&#243;a học chỉ người sở hữu mới d&#249;ng được
    function addCourse (
        string _NameCourse, uint _CourseID, string _StartDay, string _EndDay, 
        string _Description, string _Instructor
    ) hasPermission public {
        CountCourse++; //Biến đếm kh&#243;a học n&#224;y sẽ tăng l&#234;n khi th&#234;m 1 kh&#243;a học
        ListCourses[CountCourse] = Course(_NameCourse,_CourseID,_StartDay,_EndDay,_Description,_Instructor);
    } 
    
    //H&#224;m kiểm tra xem c&#243; bao nhi&#234;u kh&#243;a học
    function CountCourses () public view returns(uint ){
        return CountCourse;
    }
    
    //H&#224;m cho người học nhập th&#244;ng tin (Student Request)
     //Khi nhập th&#244;ng tin v&#224;o, gi&#225; trị đ&#227; ho&#224;n th&#224;nh kh&#243;a học hay chưa mặc định l&#224; false
    function ApplyForCertification (
        string _Address, string _Email, string _Phone, 
        string _StudentName, uint _CourseIDofStudent
    ) public{
        CountStudent++; //Biến đếm kh&#243;a học n&#224;y sẽ tăng l&#234;n khi th&#234;m 1 học vi&#234;n
        StudentRequests[CountCourse]=Student(
            _Address,_Email,_Phone,_StudentName,_CourseIDofStudent,false
        );
    }
    
    //H&#224;m kiểm tra xem c&#243; bao nhi&#234;u học vi&#234;n gửi y&#234;u cầu cấp chứng chỉ kh&#243;a học
    function CountStudentnRequests() public view returns(uint ){
        return CountStudent;
    }
    
    //H&#224;m cấp chứng chỉ cho học vi&#234;n
      //D&#249;ng hasPermission v&#236; th&#234;m kh&#243;a học chỉ người sở hữu mới d&#249;ng được
    function approveCertification() public hasPermission
    {
        CountStudentComplete++;
        //Cập nhật v&#224;o mảng StudentComplete Request của học vi&#234;n được cấp chứng chỉ
          //V&#224; sửa lại gi&#225; trị ho&#224;n th&#224;nh chứng chỉ "CompleteCer = true" (ho&#224;n th&#224;nh chứng chỉ)
        StudentComplete[CountStudentComplete] = StudentRequests[CountStudent];
        
        StudentComplete[CountStudentComplete].CompleteCer = true;
        StudentRequests[CountStudent].CompleteCer = true;
    }
    
    //H&#224;m từ chối cấp chứng chỉ
      //Sửa lại gi&#225; trị Request mới th&#234;m của Học vi&#234;n th&#224;nh false
    function rejectCertification() public hasPermission
    {
        StudentRequests[CountStudent].CompleteCer=false;
    }
    
    //H&#224;m x&#243;a tất cả c&#225;c Request
    function DeleteAllRequests() public{
        uint i = CountStudent;
        while (i > 0){
            delete StudentRequests[i];
            i--;
        }
    }

    //H&#224;m x&#225;c nhận chứng chỉ kh&#243;a học đ&#243; thuộc kh&#243;a học n&#224;o
    function CheckStudentofCourse(uint _k) public view returns (string _NameCourse, uint, string, string , string , string){
            uint i = CountCourse;
            while (i>0){
                //Nếu c&#225;i id chứng chỉ của sinh vi&#234;n (CourseIDofStudent) bằng với id kh&#243;a học
                //->return kh&#243;a học đ&#243; ListCourses thứ i.
                if (StudentComplete[_k].CourseIDofStudent==ListCourses[i].CourseID){
                    return (ListCourses[i].NameCourse, ListCourses[i].CourseID, ListCourses[i].StartDay, 
                    ListCourses[i].EndDay, ListCourses[i].Description, ListCourses[i].Instructor);
                }
                else
            return ("NULL",0,"NULL","NULL","NULL","NULL");
            }
    }
}