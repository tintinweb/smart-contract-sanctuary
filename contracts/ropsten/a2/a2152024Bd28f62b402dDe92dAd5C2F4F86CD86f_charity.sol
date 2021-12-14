/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity ^0.5.1;

contract charity{
    string Name;
    string about;
    address payable owner; 
    address payable getter;
    uint date;
    uint amount;
    //Џолучаем адрес создателЯ контракта
    constructor(string memory _name, string memory _about, uint _date, uint _amount) public {
        Name = _name;
        about = _about;
        date = _date;
        amount = _amount;
        owner = msg.sender;
    }
    modifier onlyOwner(address _owner) {
        require(_owner==owner);
        _;
    }
   function changeOwner(address payable _newOwner) public onlyOwner(msg.sender) {
      owner = _newOwner;
   }
   
    //“станавливает адрес, на который в конце поступЯт деньги
    function setGetter(address payable _getter) public onlyOwner(msg.sender){
        getter=_getter;
    }
    //“станавливает дату до которой осуществлЯетсЯ наш сбор в unix формате
    function setDate(uint _date) public onlyOwner(msg.sender){
        date=_date;
    }
    //“станавливает сумму, которую собирают всего
    function setAmount(uint _amount)public onlyOwner(msg.sender){
        amount=_amount;
    }
    //Џолучаем адрес, на который в конце поступЯт деньги
    function getGetter() public view returns (address){
       return getter;
    }
    function getInfo()public view returns (string memory, string memory, address, uint, uint, uint){ 
        return(Name, about, address(this), amount, balanceView(), date);
    }
    //Џолучаем дату до которой осуществлЯетсЯ наш сбор в unix формате
    function getDate() public view returns (uint){
        return date;
    }
    //Џолучаем сумму, которую собирают всего
    function getAmount()public view returns (uint){
        return amount;
    }
    //‚ыводим уже имеющийсЯ баланс на контракте
    function balanceView() public view returns (uint) {
       uint balance = address(this).balance;
       return balance;
    }
   modifier onlyAfter(uint time) {
      require( now > time);
      _;
   }
    modifier enoughSum() {
      require( balanceView() >= amount);
      _;
   }
   modifier onlyBefore(uint _time) {
      require( now <= _time);
      _;
   }
    modifier notEnoughSum() {
      require( balanceView() < amount);
      _;
   }
   
   
    //”ункциЯ перевода денег на этот контракт, которую может вызвать любой пользователь
    function donation() public payable notEnoughSum() onlyBefore(date) {
    }
  
   
    
 //…сли сумма=заЯвленной, то деньги пересылаютсЯ на адрес магазина
//…сли сумма не= заЯвленной € дата просрочена, то деньги переводЯтсЯ на адрес благотворительной организации
  function send() public onlyOwner(msg.sender) enoughSum(){
      getter.transfer(amount);
      } 
 function sendIfFail() public onlyOwner(msg.sender) notEnoughSum(){
      owner.transfer(amount);
      } 

//„описать функциЯ возврата денег отправителЯм, если сумма не собрана и сроки просрочены


}