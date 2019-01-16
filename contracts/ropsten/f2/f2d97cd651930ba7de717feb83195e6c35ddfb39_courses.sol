pragma solidity ^0.4.18;
contract courses{
    struct Instructor{
        string name;
        uint age;
        string fname;
    }
    mapping (address=>Instructor) instructors;
    address[] instructorAccts;
    function setInstructor(address _address,string _name,string _fname)public {
      
        
        instructors[_address].name=_name;
     instructors[_address].fname=_fname;
        instructorAccts.push(_address) -1;
    }
    function getInstructor() public view returns(address[]){
        return instructorAccts;
    }
    function getInstructor(address _address)public view returns(string,uint,string){
        return(instructors[_address].name, instructors[_address].age, instructors[_address].fname);
    }
}