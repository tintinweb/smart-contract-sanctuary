pragma solidity >=0.4.0 <0.6.0;
contract Courses {
    struct Instructor{
        uint age;
        string fname;
        string lname;
    }
    mapping(address => Instructor)instructors;
    address[] public instructoraccnts;

    function setInstructor( address _address, uint _age,string memory _fname,string memory   _lname)public{
        Instructor storage ins = instructors[_address];
        ins.age = _age;
        ins.fname = _fname;
        ins.lname = _lname;
        instructoraccnts.push(_address) - 1;

    }

    function getInstructors() public view returns(address[] memory){
        return instructoraccnts;
    }

    function getInstructor(address _address) public view returns(uint,string memory,string memory){
        return (instructors[_address].age,instructors[_address].fname,instructors[_address].lname);
    }
}