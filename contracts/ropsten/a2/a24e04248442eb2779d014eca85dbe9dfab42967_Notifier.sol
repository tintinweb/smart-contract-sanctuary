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

  event Approved(address indexed user, address indexed contractAddress, uint256 timestamp);
  event Deposit(address indexed user, uint amount, address indexed contractAddress, uint256 timestamp);
  event Withdraw(address indexed user, uint amount, address indexed contractAddress, uint256 timestamp);
  event RentModified(address indexed user, uint256 amount, address indexed contractAddress, uint256 timestamp);
  event Ticket(address indexed user, bool open, address indexed contractAddress, uint256 timestamp);
  event Dispute(address indexed user, bool ongGoing, address indexed contractAddress, uint256 timestamp);

  function approved(address user, uint256 timestamp) public {
    emit Approved(user, msg.sender, timestamp);
  }

  function deposit(address user, uint amount, uint256 timestamp) public {
    emit Deposit(user, amount, msg.sender, timestamp);
  }

  function withdraw(address user, uint amount, uint256 timestamp) public {
    emit Withdraw(user, amount, msg.sender, timestamp);
  }

  function rentModified(address user, uint256 amount, uint256 timestamp) public {
    emit RentModified(user, amount, msg.sender, timestamp);
  }

  function ticket(address user, bool ticketOpen, uint256 timestamp) public {
    emit Ticket(user, ticketOpen, msg.sender, timestamp);
  }

  function dispute(address user, bool ongGoing, uint256 timestamp) public {
    emit Dispute(user, ongGoing, msg.sender, timestamp);
  }

}