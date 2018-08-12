pragma solidity ^0.4.24;

contract Certificate {
    struct Date{        //Tạo struct lưu ng&#224;y th&#225;ng năm
        uint8 day;
        uint8 month;
        uint16 year;
    }
    Date public date;
    
    function KiemTraNamNhuan(uint16 _year) public pure returns (uint16) {       //H&#224;m kiểm tra năm nhuận (return 1 l&#224; nhuận)
        if((_year % 4 == 0 && _year % 100 != 0) || (_year % 400 ==0))
            return 1;
        return 0;
    }
    
    function CheckValidDate(uint8 _day, uint8 _month, uint16 _year) public view returns (uint8) {   //H&#224;m kiểm tra t&#237;nh hợp lệ của ng&#224;y nhập v&#224;o (return 1 l&#224; đ&#250;ng)
        if(1>_month||_month>12) return 0;
        if(_day < 1 || _day > 31) return 0;
        if(_day <= 31 && (_month == 1 || _month == 3 ||_month == 5 || _month == 7 ||_month == 8 || _month == 10 || _month == 12))
            return 1;
        if(_day <= 30 && (_month == 4 || _month == 6 ||_month == 9 || _month == 11))
            return 1;
        if(this.KiemTraNamNhuan(_year) == 1 && _day <= 29)
            return 1;
        if(this.KiemTraNamNhuan(_year) == 0 && _day <= 28)
            return 1;
        return 0;
    }
    
    mapping(uint => uint) public CourseId;      //Tạo mảng động to&#224;n cục CourseId kiểu uint để so s&#225;nh hợp lệ 
    
    struct Course {     //Tạo struct Course lưu th&#244;ng tin kh&#243;a học
        string name;
        string description;
        string instructor;
        uint courseid;
        mapping(uint => Date) dates;    //Tạo mảng động dates kiểu Date để lưu ng&#224;y bắt đầu v&#224; kết th&#250;c
    }
    
    struct StudentRequest {     //Tạo struct StudentRequest lưu th&#244;ng tin sinh vi&#234;n
        string name;
        string add;
        string email;
        uint phone;
        uint courseid;
        uint stuid;     //mssv
        uint status;    //Đ&#227; ho&#224;n th&#224;nh kh&#243;a học hay chưa (1 l&#224; đ&#227;, 0 l&#224; chưa)
        uint result;    //Kết quả cấp (2 l&#224; đang chờ, 1 l&#224; được, 0 l&#224; kh&#244;ng được)
        mapping(uint => Date) birthday;     //Tạo mảng động birthday kiểu Date để lưu ng&#224;y sinh
    }
    
    address public educator;    //Lưu địa chỉ người viết code v&#224;o biến educator
    uint public coursecount;    //Biến to&#224;n cục coursecount dạng uint để đếm số kh&#243;a học
    uint public stureqcount;    //Biến to&#224;n cục stureqcount dạng uint để đếm số request
    
    constructor() public {      //H&#224;m constructor tạo gi&#225; trị ban đầu cho c&#225;c biến tr&#234;n
        educator=msg.sender;
        coursecount = 0;
        stureqcount = 0;
    }

    modifier hasPermission(){   //H&#224;m modifier cấp quyền cho người viết code
        require(msg.sender==educator);
        _;
    }
    
    mapping(uint => Course) public courses;     //Tạo mảng động to&#224;n cục courses kiểu struct Course để lưu th&#244;ng tin nhiều kh&#243;a học
    function addCourse(string _name, string _description, string _instructor, uint _coid, uint8 _startday, uint8 _startmonth, uint16 _startyear,uint8 _endday,uint8 _endmonth) external hasPermission returns (string){     //H&#224;m addCourse để th&#234;m kh&#243;a học, c&#243; keyword l&#224; external v&#224; phải c&#243; quyền từ h&#224;m hasPermission
        if(_coid==0)    return "Add Course Fail Due To Invalid Course ID";      //Kiểm tra c&#243; nhập courseid chưa
        if(this.CheckValidDate(_startday,_startmonth,_startyear)==1&&this.CheckValidDate(_endday,_endmonth,_startyear+1)==1){   //Kiểm tra ng&#224;y nhập v&#224;o c&#243; hợp lệ kh&#244;ng
            courses[coursecount].dates[0]=Date(_startday,_startmonth,_startyear);   //g&#225;n ng&#224;y bắt đầu v&#224;o phần tử thứ 0 của mảng dates
           courses[coursecount].dates[1]=Date(_endday,_endmonth,_startyear+1);      //g&#225;n ng&#224;y kết th&#250;c v&#224;o phần tử thứ 1 của mảng dates (Do stack qu&#225; lớn n&#234;n kh&#244;ng th&#234;m được endyear n&#234;n em auto +1 năm)
           for(uint i=0;i<coursecount;i++)      
                if(_coid==CourseId[i])  return "Add Course Fail Due To Course ID Existence!";   //Kiểm tra xem c&#243; bị tr&#249;ng CourseId kh&#244;ng
            courses[coursecount]=Course(_name,_description,_instructor,_coid);      //Push dữ liệu v&#224;o phần tử thứ "coursecount" của mảng courses
            CourseId[coursecount]=_coid;    //Lưu CourseId v&#224;o phần tử thứ "coursecount" của mảng to&#224;n cục CourseId
            coursecount++;  //Tăng biến đếm kh&#243;a học
            return "Add Course Successfully!";  //Khi tất cả hợp lệ v&#224; th&#234;m dữ liệu th&#224;nh c&#244;ng sẽ return chuỗi n&#224;y
        }
        return "Add Course Fail Due To Incorrect Date Format!";     //Khi ng&#224;y th&#234;m kh&#244;ng hợp lệ
    }
    
    function countCourses()  public view returns(uint){     //H&#224;m kiểm tra tổng số kh&#243;a học
        return coursecount;
    }
    
    mapping(uint => StudentRequest) public stureqs;     //Tạo mảng động to&#224;n cục stureqs kiểu struct StudentRequest để lưu th&#244;ng tin sinh vi&#234;n Request
    function applyForCertification(string _name, string _add, string _email, uint _phone, uint _coid, uint _stuid, uint _status, uint8 _day,uint8 _month,uint16 _year) public returns(string) { //H&#224;m tạo request cho mọi người 
        if(_status>1)   return "Apply Fail! Status must be 0 or 1";     //Kiểm tra đ&#227; ho&#224;n th&#224;nh kh&#243;a học hay chưa
        if(coursecount<1)   return "Apply Fail Due To Empty Course List";   //Kiểm tra đ&#227; c&#243; kh&#243;a học mở trước khi được Request
        if(this.CheckValidDate(_day,_month,_year)!=1)   return "Apply Fail Due To Incorrect Date Format!";  //Kiểm tra t&#237;nh hợp lệ của ng&#224;y sinh
        stureqs[stureqcount].birthday[0]=Date(_day,_month,_year);   //Nếu hợp lệ th&#236; th&#234;m dữ liệu v&#224;o phần tử 0 của mảng động birthday
        for(uint k=0;k<coursecount;k++)     
            if(_coid==CourseId[k])
                for(uint l=0;l<stureqcount;l++)
                    if(_stuid==stureqs[l].stuid)    return "Apply Fail Due To Request Existence!";  //Kiểm tra Request 1 kh&#243;a học (CourseId) c&#243; bị 1 sinh vi&#234;n (stuid) nộp 2 lần
        for(uint i=0;i<coursecount;i++)
            if(_coid==CourseId[i]){     //Kiểm tra c&#243; tồn tại kh&#243;a học kh&#244;ng
                stureqs[stureqcount]=StudentRequest(_name,_add,_email,_phone,_coid,_stuid,_status,2);   //Push dữ liệu v&#224;o phần tử thứ stureqcount của mảng động to&#224;n cục StudentRequest với trạng th&#225;i chờ (result =2)
                stureqcount++;  //Tăng biến đếm Request
                return "Apply Successfully";
            }
        return "Apply Fail Due To Wrong Course ID"; //Khi kh&#244;ng tồn tại kh&#243;a học
    }
    
    function countStureq() public view returns(uint){   //H&#224;m kiểm tra tổng số Request
        return stureqcount;
    }
    
    function approveCertification(uint i) external hasPermission returns(bool,string){  //H&#224;m cấp chứng nhận cho sinh vi&#234;n request đ&#227; ho&#224;n tất kh&#243;a học với tham số truyền v&#224;o l&#224; số thứ tự của phần tử trong mảng stureqs v&#224; phải c&#243; quyền hasPermission
        if(i+1>stureqcount)     return (false,"Request doesn&#39;t exist!");    //kiểm tra c&#243; tồn tại request kh&#244;ng
        if(stureqs[i].status==0)    return (false,"Student isn&#39;t qualified");   //Kiểm tra sinh vi&#234;n request c&#243; ho&#224;n th&#224;nh kh&#243;a học chưa
        stureqs[i].result=1;    //Nếu c&#243; tồn tại request v&#224; đ&#227; ho&#224;n th&#224;nh kh&#243;a học th&#236; đồng &#253; cấp (result=1) 
        return (true,"Successfully Approved!"); //return gi&#225; trị true b&#225;o cấp th&#224;nh c&#244;ng
    }
    
    function rejectCertification(uint i) external hasPermission returns(bool,string){   //H&#224;m từ chối cấp với tham số truyền v&#224;o l&#224; số thứ tự của phần tử trong mảng stureqs v&#224; phải c&#243; quyền hasPermission
        if(i+1>stureqcount)     return (false,"Request doesn&#39;t exist!");    //Kiểm tra c&#243; tồn tại request kh&#244;ng
        stureqs[i].result=0;    //Nếu tồn tại Request th&#236; từ chối cấp (result=0)
        return (true,"Request is rejected!");   //return gi&#225; trị true b&#225;o từ chối th&#224;nh c&#244;ng
    }
    
    function clearAllRequest() external hasPermission returns(bool,string) {    //H&#224;m x&#243;a tất cả Request phải c&#243; quyền hasPermission
        if(stureqcount==0)  return (false,"Request List is already Empty!");    //Nếu kh&#244;ng c&#243; Request n&#224;o th&#236; return false th&#244;ng b&#225;o x&#243;a kh&#244;ng th&#224;nh c&#244;ng do list trống
        for(uint i=stureqcount;i>0;i--) delete stureqs[i-1];    //X&#243;a từng phần tử trong mảng stureqs
        delete stureqcount; //reset biến đếm Request;
        return (true,"Request List is cleared!");   //return true th&#244;ng b&#225;o x&#243;a th&#224;nh c&#244;ng
    }
    
    function clearAll() external hasPermission returns(bool,string) {   //H&#224;m x&#243;a tất cả course v&#224; Request phải c&#243; quyền hasPermission
        if(coursecount==0) return (false,"Nothing to clear!");  //Kiểm tra nếu kh&#244;ng c&#243; kh&#243;a học n&#224;o th&#236; return false
        for(uint i=stureqcount;i>0;i--) delete stureqs[i-1];    //X&#243;a từng phần tử trong mảng stureqs trước
        delete stureqcount; //reset biến đếm Request
        for(uint k=coursecount;k>0;k--) delete courses[k-1];    //X&#243;a từng phần tử trong mảng courses
        delete coursecount; //reset biến đếm Course
        return (true,"Course List is cleared!");    //return true sau khi x&#243;a th&#224;nh c&#244;ng
    }
    
    function checkCourse(uint i) public view returns(uint,string){  //H&#224;m kiểm tra chứng chỉ đ&#227; cấp thuộc kh&#243;a học n&#224;o v&#224; return courseid với tham số truyền v&#224;o l&#224; số thứ tự của phần tử trong mảng stureqs
        if(i+1>stureqcount)     return (0,"Request doesn&#39;t exist!");    //kiểm tra xem c&#243; tồn tại request đ&#243; kh&#244;ng
        if(stureqs[i].result!=1) return (0,"Certificate is rejected or in queue!"); //Request c&#243; tồn tại nhưng chưa được cấp chứng chỉ
        return (stureqs[i].courseid,"Found!");  //Request tồn tại v&#224; đ&#227; được cấp chứng chỉ, return courseid
    }
    
    mapping (uint => mapping(uint => uint)) Stu2Cou;    //Tạo mảng 2 chiều (ma trận) lưu th&#244;ng tin kh&#243;a học c&#243; sv n&#224;o học
    function createTable() public returns(string){  //H&#224;m đưa dữ liệu v&#224;o ma trận tr&#234;n
        uint stuidcount=0;  //Biến cục bộ lưu tổng số mssv (1 mssv c&#243; thể c&#243; nhiều Request)
        if(coursecount==0)  return "No Course To List!";    //Kiểm tra nếu kh&#244;ng c&#243; kh&#243;a học
        for(uint i=1;i<=coursecount;i++)    Stu2Cou[0][i]=CourseId[i-1];    //Lưu tất cả c&#225;c CourseId v&#224;o h&#224;ng thứ nhất [0], bắt đầu từ phần tử thứ hai [0][1]
        Stu2Cou[1][0]=stureqs[0].stuid; //Lưu mssv của Request đầu ti&#234;n v&#224;o phần tử thứ hai [1][0] của cột thứ nhất [0]
        for(uint k=2;k<=stureqcount;k++){   //D&#242;ng for để trỏ phần tử từ h&#224;ng 2 ở cột thứ nhất [k][0] đang cần điền v&#224;o của ma trận
            for(uint n=1;n<k;n++){  //D&#242;ng for để duyệt mssv từ Request thứ 2
                if(Stu2Cou[n][0]!=stureqs[k-1].stuid){  //Đảm bảo kh&#244;ng lưu tr&#249;ng mssv
                    Stu2Cou[k][0]=stureqs[k-1].stuid;   //Khi kh&#244;ng tr&#249;ng th&#236; lưu v&#224;o phần tử thứ [k][0]
                    stuidcount++;   //Tăng biến đếm tổng c&#225;c mssv 
                }
            }
        }
        for(uint m=1;m<=stuidcount;m++){    //D&#242;ng for để trỏ phần tử ở h&#224;ng m của ma trận đang cần kiểm tra 
            for(uint p=1;p<=stureqcount;p++){   //D&#242;ng for để duyệt tất cả Request 
                if(stureqs[p-1].stuid==Stu2Cou[m][0]){  //Kiểm tra Request n&#224;o được gửi từ mssv tại phần tử [m][0]
                    for(uint o=1;o<=coursecount;o++){   //D&#242;ng for duyệt tất cả courseid được lưu tại h&#224;ng thứ 1 [0][o]
                        if(stureqs[m-1].courseid==Stu2Cou[0][o])    Stu2Cou[m][o]=1;    //Nếu Request của mssv đ&#243; c&#243; học kh&#243;a học (courseid) n&#224;o tại h&#224;ng thứ 1 th&#236; g&#225;n gi&#225; trị "1" tại phần tử đang trỏ tới [m][o]
                    }
                }
            }
        }
        return "Created Successfully!"; //Lưu th&#224;nh c&#244;ng
    }
}