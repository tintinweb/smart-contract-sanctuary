/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity ^0.5.1;

contract charity{
    address payable owner; 
    address payable getter;
    uint date;
    uint amount;
    // адрес этого смарт-контракта
    address payable wallet;
    //Адрес создателя котракта получаем
    constructor() public { 
        owner = msg.sender;
    }
    modifier onlyOwner(address _owner) {
        require(_owner==owner);
        _;
    }
   function changeOwner(address payable _newOwner) public onlyOwner(owner) {
      owner = _newOwner;
   }
   function setWalletAddress(address payable _wallet) public onlyOwner(owner){
        wallet=_wallet;
    }
    //Устанавливает адрес, на который в конце поступят деньги
    function setGetter(address payable _getter) public onlyOwner(owner){
        getter=_getter;
    }
    //Устанавливает дату до которой осуществляется наш сбор в unix формате
    function setDate(uint _date) public onlyOwner(owner){
        date=_date;
    }
    //Устанавливает сумму, которую собирают всего
    function setAmount(uint _amount)public onlyOwner(owner){
        amount=_amount;
    }
    //Выводим уже имеющийся баланс на кошельке сбора
    function balanceView() public view returns (uint) {
       uint balance = address(wallet).balance;
       return balance;
    }
   modifier onlyAfter(uint time) {
      require( now > time);
      _;
   }
    modifier enoughSum(uint sum) {
      require( balanceView() >= sum);
      _;
   }
   modifier onlyBefore(uint _time) {
      require( now <= _time);
      _;
   }
    modifier notEnoughSum(uint summ) {
      require( balanceView() < summ);
      _;
   }
   
   // Событие вызываемое в момент пополнения счета.
    event Donation(address indexed from,address indexed to, uint value);
    //Функция перевода денег на этот контракт, которую может вызвать любой пользователь
    function donation(uint _sum) public payable notEnoughSum(balanceView()) onlyBefore(date) {
      wallet.transfer(_sum);
      emit Donation(msg.sender,wallet,_sum);
    }
  
   
    
 //Если сумма=заявленной, то деньги пересылаются на адрес магазина
//Если сумма не= заявленной И дата просрочена, то деньги переводятся на адрес благотворительной организации
  function send() public payable onlyOwner(owner) enoughSum(amount){
      getter.transfer(amount);
      } 
 function sendIfFail() public payable onlyAfter(date) onlyOwner(owner) notEnoughSum(amount){
      owner.transfer(amount);
      } 



}