pragma solidity ^0.4.25;


/* Contract used to asign admins to RentPeacefully Rental Agreements */

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


/*Contract used to receive notifications of ALL RentPeacefully users Smart Contracts*/

contract Notifier is owned {

  event Approved(address indexed user, address indexed contractAddress, uint256 timestamp);
  event Deposit(address indexed user, uint256 amount, address indexed contractAddress, uint256 timestamp);
  event Withdraw(address indexed user, uint256 amount, address indexed contractAddress, uint256 timestamp);
  event RentModified(address indexed user, uint256 amount, address indexed contractAddress, uint256 timestamp);
  event Ticket(address indexed user, bool open, address indexed contractAddress, uint256 timestamp);
  event Dispute(address indexed user, bool ongGoing, address indexed contractAddress, uint256 timestamp);

  modifier onlyContract {
      address addr = msg.sender;
      uint256 size;
      assembly { size := extcodesize(addr) }
      require(size>0);
      _;
  }

  function approved(address user) onlyContract public {
    emit Approved(user, msg.sender, now);
  }

  function deposit(address user, uint256 amount) onlyContract public {
    emit Deposit(user, amount, msg.sender, now);
  }

  function withdraw(address user, uint256 amount) onlyContract public {
    emit Withdraw(user, amount, msg.sender, now);
  }

  function rentModified(address user, uint256 amount) onlyContract public {
    emit RentModified(user, amount, msg.sender, now);
  }

  function ticket(address user, bool ticketOpen) onlyContract public {
    emit Ticket(user, ticketOpen, msg.sender, now);
  }

  function dispute(address user, bool ongGoing) onlyContract public {
    emit Dispute(user, ongGoing, msg.sender, now);
  }

}