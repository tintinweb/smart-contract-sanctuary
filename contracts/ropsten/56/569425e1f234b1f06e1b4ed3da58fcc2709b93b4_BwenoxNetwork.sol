pragma solidity ^0.4.24;

/**
 * Bwenox.Network!
 *
 * Hey, 
 * 
 * You know the rules of Investing already,
 * but let me briefly explain how this one works ;)
 * 
 * This is your personal 365 days power Etherem bank!
 * 
 * 1. Send fixed amount of ether every 24 hours (5900 blocks).
 * 2. With every new transaction collect exponentially greater return!
 * 3. Keep sending the same amount of ether! (can&#39;t trick the code, bro)
 * 4. Don&#39;t send too often (early transactions will be rejected, uh oh)
 * 5. Don&#39;t be late, you won&#39;t loose your %, but who wants to be the last?
 * 6. 12 hour funding from bwenox dice and roll game profit.
 *  
 * Play by the rules and save up to 500%!
 * 
 * Basic smart operation
 * 12% sent to game contract
 * 0.5 % team funding
 * 60 % game 12 hours profit brought back for daily operation funding.
 * Guaranteed smart contract funding for investor.
 * want to Exit or Quite with your shares ! Send 0.00001111 ether.
 * 
 * RECOMMENDED GAS LIMIT
 * Gas limit: 200 000 (only the first time, average ~ 50 000)
 * Gas price: https://ethgasstation.info/
 *
 */
 
 library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

 
contract Owned {
    address public owner;
    function Owned() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    
}
contract BwenoxNetwork is Owned {
    using SafeMath
    for uint;
    string public constant name = " Bwenox ↓ Network ↓ Investment";
    
    string public constant symbol = "GetEth";
    

    struct User {
        uint value;
        uint index;
        uint atBlock;
    }

    mapping (address => User) public users;
    
    uint public ShareTotalBalance;
    uint public ProfitDepo;

    uint public team;
    uint public ReferalBonus = 1;
    
    uint public charityPercent = 1;
    uint public countOfCharity = 0;
    address public charityFund;
    
    
    uint public BwenowprojectPercent = 10;
    uint public BwenowprojectCount = 0;
    address public BwenowprojectFund = 0x5c2dE3aE2C761994e11493c039aD7080E86CF981;
   
    address public teamAddress;
    address public BwenowprojectAddress;

    constructor(address _teamAddress) public {
        
        teamAddress = _teamAddress;
    }
    
   function DepositProjectProfit() payable onlyOwner{
      ProfitDepo += msg.value; 
       
   }

    function buyshares(address refadd) public payable {
        require(msg.value == 0.00001111 ether || (msg.value >= 0.01 ether && msg.value <= 5 ether), "Min: 0.01 ether, Max: 5 ether, Exit: 0.00001111 eth");

        User storage user = users[msg.sender]; // this is you

        if (msg.value != 0.00001111 ether) {
            ShareTotalBalance += msg.value;                 // ShareTotalBalance 
            team += msg.value / 50;  // 0.5% team
            
            uint ProjectMoney = msg.value.mul(BwenowprojectPercent).div(100);
            BwenowprojectCount+=ProjectMoney;
            BwenowprojectFund.transfer(ProjectMoney);
            
            
            
            charityFund= refadd;
            uint charityMoney = msg.value.mul(charityPercent).div(100);
            countOfCharity+=charityMoney;
            charityFund.transfer(charityMoney);
            
            
            
            if (user.value == 0) { 
                user.value = msg.value;
                user.atBlock = block.number;
                user.index = 1;     
            } else {
                require(msg.value == user.value, "Amount should be the same");
                require(block.number - user.atBlock >= 5900, "Too soon, try again later");

                uint idx = ++user.index;
                
                if (idx == 365) {
                    user.value = 0; // game over for you, my friend!
                } else {
                    // if you are late for more than 4 hours (984 blocks)
                    // then next deposit/payment will be delayed accordingly
                    if (block.number - user.atBlock - 5900 < 984) { 
                        user.atBlock += 5900;
                    } else {
                        user.atBlock = block.number - 984;
                    }
                }

                 
                msg.sender.transfer(msg.value * idx * idx * (24400 - 500 * msg.value / 1 ether) / 10000000);
            }
        } else {
            require(user.index <= 10, "It&#39;s too late to request a refund at this point");

            msg.sender.transfer(user.index * user.value * 70 / 100);
            user.value = 0;
        }
        
    }

    /**
     * This one is easy, claim reserved ether for the team or Bwenowproject
       
     */ 
     
    function ClaimFeesFromSharesBought(uint amount) public {
         
        if (msg.sender == teamAddress) {
            require(amount > 0 && amount <= team, "Can&#39;t claim more than was reserved");

            team -= amount;
            msg.sender.transfer(amount);
        }
    }
}