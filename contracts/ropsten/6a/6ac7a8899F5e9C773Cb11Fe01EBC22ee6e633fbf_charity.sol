/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

pragma solidity ^0.5.1;

contract charity{
    address payable owner; 
    address payable getter;
    uint date;
    string name;
    uint amount;
    string about;
    // адрес этого смарт-контракта
    address payable wallet;
    //Ђдрес создателЯ контракта получаем
    constructor(string memory _name, address payable _getter, uint _amount, uint _date, string memory _about) public { 
        owner = msg.sender;
        name = _name;
        amount = _amount;
        getter = _getter;
        date = _date;
        about = _about;
    }

    function getInfo() public view returns (string memory, address, string memory, address, uint ,uint, uint) {
        return(name, getter, about, address(this), balanceView(), amount, date);
    }

    modifier onlyOwner(address _owner) {
        require(_owner==owner);
        _;
    }
   function changeOwner(address payable _newOwner) external onlyOwner(owner) {
      owner = _newOwner;
   }
   function setWalletAddress(address payable _wallet) external onlyOwner(owner){
        wallet=_wallet;
    }
    //“станавливает адрес, на который в конце поступЯт деньги
    function setGetter(address payable _getter) external onlyOwner(owner){
        getter=_getter;
    }
    //“станавливает дату до которой осуществлЯетсЯ наш сбор в unix формате
    function setDate(uint _date) external onlyOwner(owner){
        date=_date;
    }
    //“станавливает сумму, которую собирают всего
    function setAmount(uint _amount)external onlyOwner(owner){
        amount=_amount;
    }
   modifier onlyAfter(uint time) {
      require( now > time);
      _;
   }
    modifier enoughSum(uint sum) {
      require( msg.value >= sum);
      _;
   }
   modifier onlyBefore(uint _time) {
      require( now <= _time);
      _;
   }
    modifier notEnoughSum(uint summ) {
      require( msg.value < summ);
      _;
   }
   //‚ыводим уже имеющийсЯ баланс на кошельке сбора
    function balanceView() public view returns (uint) {
       uint balance = address(this).balance;
       return balance;
    }
   // ‘обытие вызываемое в момент пополнениЯ счета.
    event Donation(address indexed from, uint value);
    //”ункциЯ перевода денег на этот контракт, которую может вызвать любой пользователь
    function donation(uint _sum) public payable notEnoughSum(balanceView()) onlyBefore(date) {
        wallet.transfer(_sum);
       emit Donation(msg.sender, msg.value);
    }
    
 //…сли сумма=заЯвленной, то деньги пересылаютсЯ на адрес магазина
//…сли сумма не= заЯвленной € дата просрочена, то деньги переводЯтсЯ на адрес благотворительной организации
  function send() external payable onlyOwner(owner) enoughSum(amount){
      getter.transfer(amount);
      } 
 function sendIfFail() external payable onlyAfter(date) onlyOwner(owner) notEnoughSum(amount){
      owner.transfer(amount);
      } 



}