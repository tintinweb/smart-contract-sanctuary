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
  event RentModified(address indexed user, uint256 amount, address indexed contractAddress);
  event Ticket(address indexed user, bool open, address indexed contractAddress);
  event Dispute(address indexed user, bool ongGoing, address indexed contractAddress);

  function approved(address user) public {
    emit Approved(user, msg.sender);
  }

  function deposit(address user, uint amount) public {
    emit Deposit(user, amount, msg.sender);
  }

  function withdraw(address user, uint amount) public {
    emit Withdraw(user, amount, msg.sender);
  }

  function rentModified(address user, uint256 amount) public {
    emit RentModified(user, amount, msg.sender);
  }

  function ticket(address user, bool ticketOpen) public {
    emit Ticket(user, ticketOpen, msg.sender);
  }

  function dispute(address user, bool ongGoing) public {
    emit Dispute(user, ongGoing, msg.sender);
  }

}