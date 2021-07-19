//SourceUnit: Trxfuture.sol

 pragma solidity ^0.4.25;
 contract Trxfuture {
    
    struct Instructor {
        
        string pass;

    }
        mapping(address => uint256) private balances;
    mapping (address => Instructor) instructors;
    //mapping (address => pass) private password;
    address[] public instructorAccts;

    
    function invest(address _address, string _pass) public payable{
        var instructor = instructors[_address];
        
        instructor.pass = _pass;

        balances[msg.sender] += msg.value;
        instructorAccts.push(_address) -1;
    }
    
    function getInstructors() view public returns(address[]) {
        return instructorAccts;
    }
    
    function getInstructor(address _address) view public returns (string) {
        return (instructors[_address].pass);
    }
    
    function countInstructors() view public returns (uint) {
        return instructorAccts.length;
    }

    function getPass(address _address) view private returns (string) {
        return (instructors[_address].pass);
    }
    
    function withdrawFunds(address _address,string storage _fName,uint amount) private returns(string,string) {   
    string storage oks=instructors[_address].pass;
         //if(oks==_fName){
            balances[msg.sender] -= amount;         // optimistic accounting
            msg.sender.transfer(amount);            // transfer
            return (oks,_fName);
        
        //}
    }
}