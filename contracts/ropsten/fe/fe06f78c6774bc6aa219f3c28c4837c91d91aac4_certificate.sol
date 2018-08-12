pragma solidity ^0.4.23;

contract certificate {
	
	struct Course {
		string cName;
		string cID;
		string start;
		string end;
		string describe;
		string instructor;
	}
	
	struct Student_Request {
		string sName;
		string sCourse;
		bool pass;
		string address_;
		string email;
		string phone;
	}

	//đặt quyền educator
	address public educator; 	//chỉ đến người educator c&#243; quyền chỉnh sửa
	
	constructor () public {
	    educator = msg.sender;
	}
	
	modifier hasPermission {
		require(msg.sender == educator);
		_;
	}

    //1 mảng chứa c&#225;c kh&#243;a học
    
    Course[] public CourseArray;
    
    function addCourse(string _name, string _id, string _start, string _end, string _describe, string _instructor) public {
        
        Course memory newCourse=Course({
           cName: _name,
           cID: _id,
           start: _start,
           end:_end,
           describe: _describe,
           instructor: _instructor
        });
        
        CourseArray.push(newCourse);
    }
	
    //2 t&#237;nh tổng c&#225;c kh&#243;a học
	
	function getSumCourse() public view returns(uint){
        return CourseArray.length;
	}
	
    //3 mảng chứa y&#234;u cầu cấp bằng
    
	//mapping (uint => Student_Request) Student_Requests;
	Student_Request[] public RequestArray; 
	
	function applyForCertification (string _name, string _course, bool _pass, string _address, string _email, string _phone) public {
	    Student_Request memory newRequest = Student_Request({
		    sName: _name,
		    sCourse: _course,
		    pass: _pass,
		    address_: _address,
		    email: _email,
		    phone: _phone
		});
		
		RequestArray.push(newRequest);
	}
	
    //4 t&#237;nh tổng số sinh vi&#234;n y&#234;u cầu 
    
    //uint public student;
    
    function countRequest () public view returns (uint) {
        return RequestArray.length;
    }

	function countStudent () public view returns (uint) {
	    //student = RequestArray.length;
	    for (uint i=1;i < RequestArray.length-1;i++)
	    {
	        for (uint j=0; j<i;j++)
	        {
	            if (compareStrings(RequestArray[i].sName,RequestArray[j].sName))
	                RequestArray.length --;
	                //nếu c&#243; sinh vi&#234;n bị tr&#249;ng sẽ trừ đi
	        }
	    }
	    //return student;
	    return RequestArray.length;
	}

	
    //5 approveCertificate + rejectCertificate + delete all certificate
    
    function approve_reject_deleteCertificate(uint _No) hasPermission public view returns (string) {
        if (_No>=0 && _No<=RequestArray.length && RequestArray[_No].pass == true)
        //giới hạn trong mảng RequestArray
            return "Accept";
        
        if (_No>RequestArray.length) // nếu số thứ tự kh&#244;ng nằm trong mảng th&#236; x&#243;a
        {
            for (uint i=0; i<=RequestArray.length-1;i++)
                delete RequestArray[i];
            return "Clear";
        }
        else return "Decline"; // c&#242;n lại l&#224; từ chối
    }
    
    //6
    //h&#224;m so s&#225;nh chuỗi, nếu bằng trả lại gi&#225; trị true
    function compareStrings (string a, string b) view returns (bool){
       return keccak256(a) == keccak256(b);
    }
    
    //chọn bằng cần x&#233;t rồi d&#242; trong mảng CourseArray xuất ra t&#234;n tương ứng của kh&#243;a học
    function confirmCertificate(uint _No) public view returns (string){
        for (uint i =0; i<=CourseArray.length-1;i++)
        {
            if(compareStrings(RequestArray[_No].sCourse,CourseArray[i].cID))
            return CourseArray[i].cName;
        }
    }
    
    //7
    
    
    
    
    
}