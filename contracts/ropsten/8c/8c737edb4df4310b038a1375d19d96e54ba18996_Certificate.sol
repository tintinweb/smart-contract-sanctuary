pragma solidity ^0.4.22;

contract Certificate {

 	struct Course { //kh&#243;a học
 		string name; //t&#234;n kh&#243;a học
     	uint256 id;// ID
    	string start;// ng&#224;y bắt đầu
    	string end;//ng&#224;y kết th&#250;c
    	string description;//m&#244; tả kh&#243;a học
    	string instructor;//giảng vi&#234;n 
  	}

  	struct StudentRequest { //sinh vi&#234;n
  		string email;
  		string studentaddress;// địa chỉ
  		string phone;// số điện thoại
  		string name;//t&#234;n sinh vi&#234;n
  		uint256 courseid;//ID của kh&#243;a học đang tham gia
  		bool ok;//trạng th&#225;i ho&#224;n tất(đạt) kh&#243;a học hay chưa
  		
  	}
  	
  	Course[] public Courses; //mảng lưu trữ c&#225;c kh&#243;a học
  	StudentRequest[] public StudentRequests; //mảng lưu trữ c&#225;c y&#234;u cầu cấp chứng chỉ kh&#243;a học

  	address public Student;
  	mapping (address => StudentRequest) Students;
  	//nhằm lưu trữ địa chỉ th&#244;ng tin của một sinh vi&#234;n đ&#227; y&#234;u cầu cấp chứng chỉ
  	
  	mapping (address => Course) student2Course;
  	//định nghĩa c&#225;c sinh vi&#234;n tham gia kh&#243;a học tương ứng

  	address public educator; 

  	constructor() public{
  		educator = msg.sender;
  	}
 	
 	modifier hasPermission{ //hạn chế truy cập, chỉ c&#243; người tạo  mới được truy cập
 		require (msg.sender == educator); 
 		_; 
 	}
 	
 	function addCourse(//h&#224;m th&#234;m th&#244;ng tin kh&#243;a học mới v&#224;o contract
 		string _name,uint256 _id, string _start, string _end, string _description,
 		string _instructor) hasPermission public  {

 		Course memory newCourse = Course({
 			name:_name,
 			id:_id,
 			start:_start,
 			end:_end,
 			description:_description,
 			instructor:_instructor
 			});
 		Courses.push(newCourse);//đem th&#244;ng tin kh&#243;a học v&#224;o mảng c&#225;c kh&#243;a học
 	}

  	function getCountCourse() public view returns(uint count) {//h&#224;m kiểm tra xem c&#243; bao kh&#243;a học
    return Courses.length;
	}

	function applyForCertification(//h&#224;m nhập th&#244;ng tin sinh vi&#234;n 
 		string _email, string _studentaddress, string _phone, string _name, uint256 _courseid) public {

 		StudentRequest memory newStudentRequest = StudentRequest({
 		    email:_email,
 			studentaddress:_studentaddress,
 			phone:_phone,
 			name:_name,
 			courseid:_courseid,
 			ok:false//khi sinh vi&#234;n tham gia kh&#243;a học th&#236; false đ&#225;nh dấu l&#224; chưa được cấp chứng chỉ(mặc định)
 			});
 		Students[msg.sender]=newStudentRequest;//đem th&#244;ng tin sinh vi&#234;n v&#224;o mapping để lưu trữ
 		StudentRequests.push(newStudentRequest);//đem th&#244;ng tin sinh vi&#234;n v&#224;o mảng chứa c&#225;c y&#234;u cầu
 	}

 	function getCountApplyForCertification() public view returns(uint count) {//h&#224;m kiểm tra xem c&#243; bao sinh vi&#234;n y&#234;u cầu cấp chứng chỉ kh&#243;a học
    return StudentRequests.length;// lấy độ d&#224;i của mảng 
	}


	function approveCertificate(address _address) public hasPermission{//ph&#225;t h&#224;nh chứng chỉ kh&#243;a học cho sinh vi&#234;n
		Students[_address].ok = true;// cấp chứng chỉ kh&#243;a học
	}
	
	function rejectCertificate(address _address) public hasPermission {//từ chối cấp chứng chỉ
		Students[_address].ok = false;// từ chối cấp chứng chỉ
	}

	function clearAllRequest() public hasPermission {//x&#243;a tất cả c&#225;c Request của sinh vi&#234;n 
		delete StudentRequests;// x&#243;a mảng chứa y&#234;u cầu cấp chứng chỉ
	}

	function getCourseID(address _address) public view returns(uint256 _id) {// nhận v&#224;o địa chỉ th&#244;ng tin sinh vi&#234;n v&#224; trả về kh&#243;a học sinh vi&#234;n tham gia
		return Students[_address].courseid;
	}

}