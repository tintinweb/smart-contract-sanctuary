pragma solidity ^0.4.23;

contract Certificate {
    
    struct Course {   // khai b&#225;o struct Kh&#243;a học (Course) gồm c&#225;c trường id, t&#234;n, m&#244; tả, người dạy, ng&#224;y bắt đầu v&#224; kết th&#250;c
        string id;
        string name;
        string description;
        string instructor;
        uint8 start;
        uint8 end;
    }
    
    struct StudentReq { // khai b&#225;o struct Y&#234;u cầu cấp chứng chỉ của sinh vi&#234;n gồm c&#225;c trường địa chỉ, email, sdt, t&#234;n, 
        string addr;                // id kh&#243;a học, kết quả v&#224; chứng chỉ ( biến n&#224;y để kiểm tra xem sinh vi&#234;n đ&#243; đ&#227; được cấp chứng chỉ hay chưa)
        string email;
        string phone;
        string name;
        string courseID;
        string result;
        string certificate;
    }
    
    mapping (uint => Course) public course;    // Định nghĩa mảng để lưu trữ c&#225;c kh&#243;a học
    mapping (uint => StudentReq) public studentreq;   // Định nghĩa mảng để lưu trữ y&#234;u cầu c&#225;c sinh vi&#234;n
    
    
   
    
    
    
    
    
    address public educator;
    constructor () public{       // constructor cho contract
        educator = msg.sender;
    }
    modifier onlybyEducator()                   // modifier để giới hạn người c&#243; quyền modify một số chức năng của contract
    {
        require( msg.sender == educator );
        _;
    
    }
    
    uint public coursescount;  // khai b&#225;o biến đến kh&#243;a học 
    function addCourse (string _id, string _name, string _descrition, string _instructor, uint8 _start, uint8 _end)  public onlybyEducator() {
        // h&#224;m th&#234;m th&#234;m th&#244;ng tin 1 kh&#243;a học mới
        course[coursescount] = Course(_id,_name,_descrition,_instructor,_start,_end);
        coursescount++;
        
    }
    
    function countCourse () public view returns (uint){    // đếm số kh&#243;a học
        return coursescount;
    }
    
    
    
    
    
    uint public studentcount;   // biến đếm số request của sinh vi&#234;n
    function ApplyforCertification (string _addr,string _phone, string _email, string _name, string _courseID,string _result) public {
        // h&#224;m cho ph&#233;p sinh vi&#234;n nhập y&#234;u cầu xin cấp chứng chỉ
        studentreq[studentcount] = StudentReq(_addr,_email,_phone,_name,_courseID,_result,"");
        studentcount++;
    }
    
    function countStudent () public view returns (uint){  // đếm số request của sinh vi&#234;n
        return studentcount;
    }
    
    
    modifier approval(uint _num){      // modifier để kiểm tra việc cấp chứng chỉ cho sinh vi&#234;n, y&#234;u cầu l&#224; sinh vi&#234;n phải chưa được cấp
    // chứng chỉ(certificate = "") v&#224; kết quả(result) phải l&#224; Pass
        require(keccak256(abi.encodePacked(studentreq[_num].certificate)) == keccak256(abi.encodePacked("")) && keccak256(abi.encodePacked(studentreq[_num].result)) == keccak256("Pass"));
        _;
    }
    
    function approveCertificate(uint _num) public approval(_num) onlybyEducator() {  // h&#224;m cấp chứng chỉ cho sinh vi&#234;n
        studentreq[_num].certificate = "Accept";
    }
    
    modifier reject(uint _num){   // modifier kiểm tra việc từ chối cấp chứng chỉ cho sinh vi&#234;n, hoặc l&#224; sinh vi&#234;n đ&#227; được cấp chứng chỉ (Accept)
    // hoặc l&#224; result của sinh vi&#234;n = Fail th&#236; sẽ từ chối cấp chứng chỉ
        require(keccak256(abi.encodePacked(studentreq[_num].certificate)) == keccak256("Accept") || keccak256(abi.encodePacked(studentreq[_num].result)) == keccak256("Fail"));
        _;
    }
    
    function rejectCertificate(uint _num) public reject(_num) onlybyEducator(){  // H&#224;m từ chối cấp chứng chỉ cho sinh vi&#234;n
        studentreq[_num].certificate = "Reject";
    }
    
    function clearRequest(uint _num) public onlybyEducator() {   // h&#224;m x&#243;a 1 request của sinh vi&#234;n bất kỳ
        delete(studentreq[_num]);
    }
    
    function clearAllRequest() public onlybyEducator() {   // x&#243;a tất cả request của sinh vi&#234;n
        for(uint i=0; i < countStudent(); i++) {
            clearRequest(i);
        }
        studentcount = 0;
    }
    
    
    
     modifier checkCertificate(uint _index) {     // modifier để kiểm tra chứng chỉ của sinh vi&#234;n thuộc kh&#243;a học n&#224;o, điều kiện l&#224; sinh vi&#234;n đ&#227; được
     // cấp chứng chỉ (Accept) v&#224; kết quả (Result) của sinh vi&#234;n đ&#243; phải l&#224; Pass
         require(keccak256(abi.encodePacked(studentreq[_index].certificate)) == keccak256("Accept") && keccak256(abi.encodePacked(studentreq[_index].result)) == keccak256("Pass"));
        _;       
    }
    
    function checkCertificates(uint _index) public view checkCertificate(_index) returns (string, string, string) {
        // h&#224;m kiểm tra chứng chỉ sinh vi&#234;n thuộc kh&#243;a học n&#224;o, ta sẽ so s&#225;nh chứng chỉ của sinh vi&#234;n đ&#243; vs to&#224;n bộ id của c&#225;c kh&#243;a học 
        for(uint i=0; i < countCourse(); i++) {
            if(keccak256(abi.encodePacked(course[i].id)) == keccak256(abi.encodePacked(studentreq[_index].courseID))) {
                return (course[i].name, course[i].description, course[i].instructor); // kết quả nếu tr&#249;ng th&#236; xuất ra t&#234;n kh&#243;a học, m&#244; tả v&#224; giảng vi&#234;n
            }
        }
    }
    
    
    // Lưu &#253;: với những function c&#243; sử dụng modifier th&#236; việc gọi h&#224;m nhưng lại kh&#244;ng thỏa điều kiện trong require th&#236; sẽ dẫn đến lỗi
    //revert, nghĩa l&#224; to&#224;n bộ transaction sẽ bị đưa về trạng th&#225;i ban đầu
    // Trong require v&#224; if, c&#225;c đối số được sử dụng phải ở trạng th&#225;i l&#224; uint n&#234;n phải d&#249;ng h&#224;m keccak256 để hash nếu đối số đưa v&#224;o l&#224; string
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}