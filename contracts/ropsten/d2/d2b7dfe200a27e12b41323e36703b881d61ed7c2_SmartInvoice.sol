/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity ^0.6.4;


contract SmartInvoice {
  uint public dueDate;
  uint public invoiceAmount;
  address serviceProvider;

  constructor(uint _invoiceAmount) public {
    dueDate = block.timestamp;
    invoiceAmount = _invoiceAmount;
    serviceProvider = msg.sender;
  }

  fallback () payable external {
    require(
      msg.value == invoiceAmount,
      'Payment should be the invoiced amount. not '
    );
  }

  function getContractBalance() public view returns(uint) {
    return address(this).balance;
  }

  function withdraw() public {
    require(
      msg.sender == serviceProvider,
      'Only the service provider can withdraw the payment.'
    );
    require(
      block.timestamp > dueDate,
      'Due date has not been reached.'
    );
    msg.sender.transfer(address(this).balance);
  }
  
  function pay () payable external {
    require(
      msg.value == invoiceAmount,
      'Payment should be the invoiced amount. not '
    );
  }
}