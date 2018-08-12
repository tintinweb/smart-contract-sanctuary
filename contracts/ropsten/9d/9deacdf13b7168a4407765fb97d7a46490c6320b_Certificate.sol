pragma solidity ^0.4.2;

/**
 * The Certificate contract does this and that...
 */
contract Certificate {
    struct Course {
        //course id is index of array courses
        //uint id;
        uint dateStart;
        uint dateEnd;
        string name;
        string description;
        string instructorName;
    }

    struct StudentRequest {
        address studentAddress;
        string studentName;
        string studentEmail;
        string studentPhone;
        uint courseId; //get id from index of courses array below
        bool isCompleted;
    }
    

    Course[] public courses;
    StudentRequest[] public requests;
    mapping (address => mapping (uint => bool)) public student2course;
    
    address[] public instructors; //list of instructors

    constructor () public {
        instructors.push(msg.sender);
    }

    modifier onlyInstructor (address instructor) {
        //find in instructors array
        for(uint i = 0; i < instructors.length; i++) {
        	if (instructors[i] == instructor) {
        		_;	
        	}
        }
    }

    function addCourse (uint _dateStart, uint _dateEnd,
     string _name, string _description, string _instructorName) 
    onlyInstructor(msg.sender)
    public {
        Course memory temp = Course({
            dateStart: _dateStart,
            dateEnd: _dateEnd,
            name: _name,
            description: _description,
            instructorName: _instructorName
        });
        courses.push(temp);
    }    

    function getNumberOfCourse () public view returns(uint) {
    	return courses.length;
    }

    function applyFromCertificate (string _name, string _email,
    string _phone, uint _courseId )
    public {
    	StudentRequest memory temp = StudentRequest({
    		studentAddress: msg.sender,
    		studentName: _name,
    		studentEmail: _email,
    		studentPhone: _phone,
    		courseId: _courseId,
    		isCompleted: false
    		});

    	requests.push(temp);
    }

    function getNumberOfRequest () public view returns(uint) {
    	return requests.length;
    }

    function approveCertificate (uint _index)
    onlyInstructor(msg.sender)
    public {
    	// _index is index of requests array

    	// get an element in array into a varialbe. Actually  reference
    	StudentRequest storage request = requests[_index];

    	// change isCompleted into True value
    	request.isCompleted = true;

    	// store record into student2course
    	student2course[request.studentAddress][request.courseId] = true;
    }


    function rejectCertificate (uint _index)
    onlyInstructor(msg.sender)
    public {
    	// _index is index of requests array

    	// get an element in array into a varialbe. Actually reference
    	StudentRequest storage request = requests[_index];

    	// change isCompleted into True value
    	request.isCompleted = true;
    }
    
    function clearAllRequest () onlyInstructor(msg.sender) public {
    	for(uint i = 0; i < requests.length; i++) {
    		if (requests[i].isCompleted == false) {
    			return;
    		}
    	}

    	requests.length = 0;
    }
}