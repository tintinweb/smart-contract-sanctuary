//SourceUnit: KleverBank.sol

pragma solidity ^0.4.25;

/**
*                                                        
* KLEVER BANK
* 
* SAVE KLV AND TRX TODAY! 
* 
* Official Site:
* https://KleverBank.io
* 
* Download Klever: www.klever.io 
* 
* Telegram: 
* kleverbank.io/tme
* 
**/

contract KleverBank  {
  using SafeMath for uint;
  
  struct Interest {
    uint time;
    uint percent;
  }
  
  struct Saving {
    uint interest;
    uint amount;
    uint at;
  }
  
  struct Client {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint balanceRef;
    uint totalRef;
    Saving[] savings;
    uint saved;
    uint paidAt;
    uint withdrawn;
  }
  
  uint MIN_DEPOSIT = 10 trx;
  uint START_AT = 22442985;
  
  address public owner;
  address public Marketing;

  
  Interest[] public interests;
  uint[] public refRewards;
  uint public totalClients;
  uint public totalSaved;
  uint public totalRefRewards;
  mapping (address => Client) public clients;

  event SavingAt(address user, uint interest, uint amount);
  event Withdraw(address user, uint amount);
  
  function register(address referer) internal {
    if (!clients[msg.sender].registered) {
      clients[msg.sender].registered = true;
      totalClients++;
      
      if (clients[referer].registered && referer != msg.sender) {
        clients[msg.sender].referer = referer;
        
        address rec = referer;
        for (uint i = 0; i < refRewards.length; i++) {
          if (!clients[rec].registered) {
            break;
          }
          
          if (i == 0) {
            clients[rec].referrals_tier1++;
          }
          if (i ==1) {
            clients[rec].referrals_tier2++;
          }
  
          rec = clients[rec].referer;
        }
      }
    }
  }
  
  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if (!clients[rec].registered) {
        break;
      }
      
      uint a = amount * refRewards[i] / 100;
      clients[rec].balanceRef += a;
      clients[rec].totalRef += a;
      totalRefRewards += a;
      
      rec = clients[rec].referer;
    }
  }
  
    constructor(address _Marketing) public {
        owner = msg.sender;
        Marketing = _Marketing;
    
    
    interests.push(Interest(120 * 28800, 204));
    interests.push(Interest(60 * 28800, 162));

    
    for (uint i = 5; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function saving(uint interest, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(interest < interests.length);
    
    register(referer);
    rewardReferers(msg.value, clients[msg.sender].referer);
    
    clients[msg.sender].saved += msg.value;
    totalSaved += msg.value;
    
    clients[msg.sender].savings.push(Saving(interest, msg.value, block.number));
    
    owner.transfer(msg.value.mul(2).div(100));
    Marketing.transfer(msg.value.mul(7).div(100));

    
    emit SavingAt(msg.sender, interest, msg.value);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Client storage client = clients[user];
    
    for (uint i = 0; i < client.savings.length; i++) {
      Saving storage dep = client.savings[i];
      Interest storage interest = interests[dep.interest];
      
      uint finish = dep.at + interest.time;
      uint since = client.paidAt > dep.at ? client.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * interest.percent / interest.time / 100;
      }
    }
  }
  
  function profit() internal returns (uint) {
    Client storage client = clients[msg.sender];
    
    uint amount = withdrawable(msg.sender);
    
    amount += client.balanceRef;
    client.balanceRef = 0;
    
    client.paidAt = block.number;
    
    return amount;

  }

  function withdraw() external {
    uint amount = profit();
    if (msg.sender.send(amount)) {
      clients[msg.sender].withdrawn += amount;

      emit Withdraw(msg.sender, amount);
    }
  }
  
  
  function deposit (address investor) external payable {
    investor.transfer(msg.value);
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