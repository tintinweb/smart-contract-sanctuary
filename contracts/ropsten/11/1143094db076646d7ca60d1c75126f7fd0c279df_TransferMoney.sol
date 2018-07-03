pragma solidity ^0.4.24;

contract TransferMoney {

  mapping (address => uint) bankAccountMoney;

  // 取得合約餘額
  function contractMoneyBalance() constant public returns(uint){
    return this.balance;
  }

  // 取得帳戶餘額
  function addressMoneyBalance() constant public returns(uint){
    return bankAccountMoney[msg.sender];
  }



  // 存款到合約
  function depositMoney(string message) payable public{
    require(msg.value >= 0);

    if (bankAccountMoney[msg.sender] == 0) {
      // wei
      bankAccountMoney[msg.sender] = msg.value;
    } else {
      bankAccountMoney[msg.sender] = bankAccountMoney[msg.sender] + msg.value;
    }

  }


  



}