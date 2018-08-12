pragma solidity ^0.4.23;
contract Certificate {

    // Khai b&#225;o struct kh&#243;a học gốm c&#225;c thuộc t&#237;nh id, name, start(ng&#224;y bắt đầu), end (ng&#224;y kết th&#250;c), descrip (m&#244; tả), instructor (người dạy)
    struct Course {
        uint id;
        string name;
        uint16 start;
        uint16 end;
        string descrip;
        string instructor;
    }
    //Kh&#225;i b&#225;o struct y&#234;u cầu cấp chứng chỉ của student với c&#225;c trường name, courseid,result,addr,email,fonenum
    //result lưu kết quả true/false. Mặc đinh l&#224; false nếu qua th&#236; người cấp sẽ thiết lập result l&#224; true
    struct StudentReq{
        string name;
        uint courseid;
        bool result;
        string addr;
        string email;
        uint fonenum;
    }
    //Khai b&#225;o mảng 
    Course[] public courses;
    StudentReq[] public studentreqs;
    
    //Biến d&#250;ng để lưu trữ sinh vi&#234;n tham gia kh&#243;a học tương ứng
    mapping(address => uint) public student2course;
    
    //mapping(uint => StudentReq) public studentreqs;
    uint public amountCourse; // d&#249;ng để đếm số kh&#243;a học
    uint public amountReq;// d&#249;ng để đếm số request
    address public educator=msg.sender;
    
    //Restriction access. Người gửi l&#224; educator mới được thực thi
    modifier hasPermission(address _educator){
        require(msg.sender==_educator);
        _;
    }  
    
    //H&#224;m th&#234;m kh&#243;a học
    function _addCourse (uint _id, string _name, uint16 _start,uint16 _end, string _descrip, string _instructor) public hasPermission(educator) {
        courses.push(Course(_id,_name,_start,_end, _descrip,_instructor));
        amountCourse++;
    }
    /*
    function printCourse0 (uint _index) public returns (uint){
        return courses[_index].id; 
    }
    function resultOf(uint _index) public returns (bool){
        return studentreqs[_index].result;
    }
    */
    // Trả về số lượng kh&#243;a học 
    function _amountCourse() public returns (uint ){
        //_amount=amountCourse;
        return amountCourse;
    }
    //H&#224;m y&#234;u cầu Certificate
    //Sinh vi&#234;n kh&#244;ng được nhập kết quả n&#234;n mặc định sẽ l&#224; false
    function _applyForCertifation(string _name, uint _courseid, bool _result,string _addr, string _email,uint _fonenum) public {
        _result=false;
        studentreqs.push(StudentReq(_name,_courseid,_result,_addr,_email,_fonenum));
        amountReq++; // Biến đếm tăng l&#234;n mỗi lần gọi h&#224;m _applyForCertifation
    }
    //H&#224;m trả về số lượng req
    function _amountReq() public returns ( uint _amount){
        _amount= amountReq;
        return _amount;
    }
    

    //Việc chấp nhận cấp chứng chỉ chỉ đơn giản l&#224; thiết lập result l&#224; true
    function _approveCertificate(uint _index, bool _result) public  hasPermission(educator) {
        _result=true;
        studentreqs[_index].result= _result; 
    }
    //Nếu reject th&#236; trả về result l&#224; false
    function _rejectCertificate(uint _index,bool _result) public  hasPermission(educator){
        _result=false;
        studentreqs[_index].result=_result;
    }
    //H&#224;m x&#243;a tất cả req v&#224; số lượng trả về 0
    function _clearAllRequest() public  hasPermission(educator){
        delete studentreqs; // X&#243;a nguy&#234;n mảng
        amountReq=studentreqs.length;
    }
    
    //H&#224;m in ra 1 kh&#243;a học
    function _printACourse(uint _index) public  hasPermission(educator) returns (uint,string, uint16,uint16,string,string) {
        return(courses[_index].id,courses[_index].name,courses[_index].start,courses[_index].end,courses[_index].descrip,courses[_index].instructor);
    }
    //X&#225;c nhận kh&#243;a học n&#224;o l&#224; của sinh vi&#234;n n&#224;o dựa v&#224;o courseid
    function _whichCourse(uint _index) public returns(uint,string, uint16,uint16,string,string) {
        for (uint i=0;i<amountCourse;i++){
            //Tra course id tương ứng th&#236; sẽ in ra kh&#243;a học tương ứng
            if (courses[i].id == studentreqs[_index].courseid){
                return _printACourse(i);
                //return "AHIHI";
            }
        }
    } 
    
}