pragma solidity ^0.4.23;


contract Notifier {

  event Approved(address indexed user, address indexed contractAddress);
  event Deposit(address indexed user, uint amount, address indexed contractAddress);
  event Withdraw(address indexed user, uint amount, address indexed contractAddress);
  event RentModified(uint256 amount, address indexed contractAddress);
  event Ticket(bool open, address indexed contractAddress);
  event Dispute(bool ongGoing, address indexed user, address indexed contractAddress);

  function approved(address user) public {
    emit Approved(user, msg.sender);
  }

  function deposit(address user, uint amount) public {
    emit Deposit(user, amount, msg.sender);
  }

  function withdraw(address user, uint amount) public {
    emit Withdraw(user, amount, msg.sender);
  }

  function rentModified(uint256 amount) public {
    emit RentModified(amount, msg.sender);
  }

  function ticket(bool ticketOpen) public {
    emit Ticket(ticketOpen, msg.sender);
  }

  function dispute(bool ongGoing, address user) public {
    emit Dispute(ongGoing, user, msg.sender);
  }

}