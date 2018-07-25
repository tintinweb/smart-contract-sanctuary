pragma solidity ^0.4.24;


/* Contract used to asign admins to Ethrental Rental Agreements */

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


/*Contract used to receive notifications of ALL EthRental users Smart Contracts*/

contract Notifier is owned {

  event Approved(address indexed user, address indexed contractAddress, uint256 timestamp);
  event Deposit(address indexed user, uint amount, address indexed contractAddress, uint256 timestamp);
  event Withdraw(address indexed user, uint amount, address indexed contractAddress, uint256 timestamp);
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

  function approved() onlyContract public {
    emit Approved(tx.origin, msg.sender, now);
  }

  function deposit(uint amount) onlyContract public {
    emit Deposit(tx.origin, amount, msg.sender, now);
  }

  function withdraw(uint amount) onlyContract public {
    emit Withdraw(tx.origin, amount, msg.sender, now);
  }

  function rentModified(uint256 amount) onlyContract public {
    emit RentModified(tx.origin, amount, msg.sender, now);
  }

  function ticket(bool ticketOpen) onlyContract public {
    emit Ticket(tx.origin, ticketOpen, msg.sender, now);
  }

  function dispute(bool ongGoing) onlyContract public {
    emit Dispute(tx.origin, ongGoing, msg.sender, now);
  }

}