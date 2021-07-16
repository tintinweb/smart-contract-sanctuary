//SourceUnit: Trxfuture.sol

 pragma solidity ^0.4.25;
 contract Trxfuture {
    
    struct Instructor {
        
        string pass;

    }
        mapping(address => uint256) private balances;
    mapping (address => Instructor) instructors;
    //mapping (address => Instructor.pass) public password;
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
    
    function withdrawFunds(uint amount,string memory sc) public {   
           address userAddress=msg.sender;
           string memory  pass=getInstructor(userAddress);
            if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(sc))) {
            balances[msg.sender] -= amount;
                     // optimistic accounting
            msg.sender.transfer(amount);
                        // transfer
               //return userAddress; 
            }            
            
    }
}