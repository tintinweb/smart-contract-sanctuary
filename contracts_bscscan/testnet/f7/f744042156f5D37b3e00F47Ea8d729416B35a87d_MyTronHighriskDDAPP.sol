/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity 0.5.10;


contract MyTronHighriskDDAPP{

  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;


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
    address referrer; 
    uint referral_counter; 
    uint balanceRef; 
    uint totalRef; 
    Deposit[] deposits; 
    uint invested; 
    uint lastPaidAt; 
    uint withdrawn; 
  }


  Tariff[] public tariffs;

  mapping (address=>Investor) public investors;
  bool private _paused;

  address payable public owner;

  event InvestedAt(address user,uint value);

  constructor() public{
    owner=msg.sender;
    _paused=false;
    tariffs.push(Tariff(8 * 28800,140));
    tariffs.push(Tariff(12 * 28800,160));
    tariffs.push(Tariff(20 * 28800,200));
  }

  function invest(uint tariff, address referrer) public minimumInvest(msg.value) payable{
    require(tariff<3);

    if(!investors[msg.sender].registered){ 
      totalInvestors++;
      investors[msg.sender].registered=true;

      if(investors[referrer].registered && referrer!=msg.sender){
        investors[msg.sender].referrer=referrer;
        investors[referrer].referral_counter++;
      }
    }

    investors[referrer].balanceRef+=msg.value *5 / 100;
    investors[referrer].totalRef+=msg.value *5 / 100;
    totalRefRewards+=msg.value *5 / 100;


    investors[msg.sender].invested+=msg.value;
    totalInvested+=msg.value;
    investors[msg.sender].deposits.push(Deposit(tariff,msg.value,block.number));

    owner.transfer(msg.value /20);
    emit InvestedAt(msg.sender,msg.value);
    
  }

  function withdrawable(address user) public view returns(uint amount){
    
    for (uint index = 0; index < investors[user].deposits.length; index++) {
      Deposit storage dep=investors[user].deposits[index];
      Tariff storage tariff=tariffs[dep.tariff];

      uint finishDate=dep.at + tariff.time;
      uint fromDate=investors[user].lastPaidAt > dep.at ? investors[user].lastPaidAt : dep.at;
      uint toDAte= block.number > finishDate ? finishDate: block.number;

      if(fromDate < toDAte){
        amount += dep.amount * (toDAte - fromDate) * tariff.percent / tariff.time / 100;
      }

    }

  }
 
  function withdraw() public ifNotPaused{

    Investor storage investor=investors[msg.sender];
    uint amount=withdrawable(msg.sender);
    amount+=investor.balanceRef; 


    investor.lastPaidAt=block.number;

  if(msg.sender.send(amount)){
    investor.withdrawn+=amount;
    investor.balanceRef=0;
  }


  }

  function pause() public onlyOwner ifNotPaused{
    _paused=true;
  }

  function unpause() public onlyOwner ifPaused{
    _paused=false;
  }

  modifier onlyOwner(){
    require(owner==msg.sender,"Only owner !");
    _;
  }

  modifier minimumInvest(uint val){
    require(val>100000000,"Minimum invest is 100 TRX");
    _;
  }

  modifier ifPaused(){
    require(_paused,"");
    _;
  }

  modifier ifNotPaused(){
    require(!_paused,"");
    _;
  }
}