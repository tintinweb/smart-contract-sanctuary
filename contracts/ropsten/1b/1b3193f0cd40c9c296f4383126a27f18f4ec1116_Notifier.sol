pragma solidity ^0.4.23;


contract Notifier {

  event Approved(address indexed user);
  event Deposit(address indexed user, uint amount);
  event Withdraw(address indexed user, uint amount);
  event RentModified(uint256 amount);
  event Ticket(bool open);
  event Dispute(bool ongGoing);

  function approved(address user) public {
    emit Approved(user);
  }

  function deposit(address user, uint amount) public {
    emit Deposit(user, amount);
  }

  function withdraw(address user, uint amount) public {
    emit Withdraw(user, amount);
  }

  function rentModified(uint256 amount) public {
    emit RentModified(amount);
  }

  function ticket(bool ticketOpen) public {
    emit Ticket(ticketOpen);
  }

  function dispute(bool ongGoing) public {
    emit Dispute(ongGoing);
  }

}