pragma solidity ^0.4.24;



contract owned {
  address public owner;
  mapping (address => bool) public admin;

  constructor() public {
    owner = msg.sender;
    admin[owner] = true;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAdmin {
    require(admin[msg.sender]);
    _;
  }

  function addAdmin(address newAdmin) onlyOwner public {
    admin[newAdmin] = true;
  }

  function removeAdmin(address oldAdmin) onlyOwner public {
    admin[oldAdmin] = false;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    owner = newOwner;
  }
}


contract Notifier is owned {

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