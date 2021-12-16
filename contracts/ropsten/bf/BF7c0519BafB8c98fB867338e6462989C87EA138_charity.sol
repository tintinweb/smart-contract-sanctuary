/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

pragma solidity ^0.5.1;

contract charity{
    address payable owner; 
    address payable getter;
    uint date;
    uint amount;
    string name;
    string about;
    //сохраняем адрес донатера и сумму его пожертвования
    mapping(address => uint) public balances;
    //Получаем адрес создателя контракта
   constructor(string memory _name, address payable _getter, uint _amount, uint _date, string memory _about) public { 
        owner = msg.sender;
        name = _name;
        amount = _amount;
        getter = _getter;
        date = _date;
        about = _about;
    }
    //Передает всю информацию о сборе
    function getInfo() public view returns (string memory, address, string memory, address, uint ,uint, uint) {
        return(name, getter, about, address(this), balanceView(), amount, date);
    }

    modifier onlyOwner(address _owner) {
        require(_owner==owner);
        _;
    }
   function changeOwner(address payable _newOwner) public onlyOwner(msg.sender) {
      owner = _newOwner;
   }
   
    //Устанавливает адрес, на который в конце поступят деньги
    function setGetter(address payable _getter) public onlyOwner(msg.sender){
        getter=_getter;
    }
    //Устанавливает дату до которой осуществляется наш сбор в unix формате
    function setDate(uint _date) public onlyOwner(msg.sender){
        date=_date;
    }
    //Устанавливает сумму, которую собирают всего
    function setAmount(uint _amount)public onlyOwner(msg.sender){
        amount=_amount;
    }
    //Получаем адрес, на который в конце поступят деньги
    function getGetter() public view returns (address){
       return getter;
    }
    //Получаем дату до которой осуществляется наш сбор в unix формате
    function getDate() public view returns (uint){
        return date;
    }
    //Получаем сумму, которую собирают всего
    function getAmount()public view returns (uint){
        return amount;
    }
    //Выводим уже имеющийся баланс на контракте
    function balanceView() public view returns (uint) {
       uint balance = address(this).balance;
       return balance;
    }
   modifier onlyAfter() {
      require( now > date);
      _;
   }
    modifier enoughSum() {
      require( balanceView() >= amount);
      _;
   }
   modifier onlyBefore() {
      require( now <= date);
      _;
   }
    modifier notEnoughSum() {
      require( balanceView() <= amount);
      _;
   }
   //Функция перевода денег на этот контракт, которую может вызвать любой пользователь
    function donation() public payable notEnoughSum() onlyBefore() {
        //сохраняем в мэп адрес донатера и сумму его пожертвования
        balances[msg.sender] = msg.value;
    }    
    //Если сумма=заявленной, то деньги пересылаются на конечный адрес
    function send() public onlyOwner(msg.sender) enoughSum(){
      getter.transfer(amount);
    } 
    //Если сумма не = заявленной И сроки сбора окончены, то ДОНАТЕР сможет вернуть свои деньги, вызвав данную функцию
    function sendIfFail() public notEnoughSum() onlyAfter() {
        uint value = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(value);
    } 

}