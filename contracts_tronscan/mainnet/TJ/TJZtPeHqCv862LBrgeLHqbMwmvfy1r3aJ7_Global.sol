//SourceUnit: global.sol

// A global scope contract for users on World Builder
pragma solidity ^0.4.25;

contract Owned {
  address public owner;
  address public oldOwner;
  uint public tokenId = 1002567;
  uint lastChangedOwnerAt;

  constructor() {
    owner = msg.sender;
    oldOwner = owner;
  }
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }
  modifier isOldOwner() {
    require(msg.sender == oldOwner);
    _;
  }
  modifier sameOwner() {
    address addr = msg.sender;
    // Ensure that the address is a contract
    uint size;
    assembly { size := extcodesize(addr) }
    require(size > 0);

    // Ensure that the contract's parent is
    Owned own = Owned(addr);
    require(own.owner() == owner);
     _;
  }
  // Be careful with this option!
  function changeOwner(address newOwner) isOwner {
    lastChangedOwnerAt = now;
    oldOwner = owner;
    owner = newOwner;
  }
  // Allow a revert to old owner ONLY IF it has been less than a day
  function revertOwner() isOldOwner {
    require(oldOwner != owner);
    require((now - lastChangedOwnerAt) * 1 seconds < 86400);
    owner = oldOwner;
  }
}

contract Global is Owned {
  mapping (address => bool) public registered; // Is the user registered?
  mapping (address => address) public referrers; // Referrals
  mapping (address => uint) public referrals; // Number of referrals obtained
  uint public totalUsers;
  event Registered(address addr);

  function register(address referrerAddress) public {
    require(!registered[msg.sender]);
    require(referrerAddress != msg.sender);
    if (registered[referrerAddress]) {
        referrers[msg.sender] = referrerAddress;
        referrals[referrerAddress]++;
        referrerAddress.transferToken(1000000000, tokenId);
    }

    totalUsers++;
    registered[msg.sender] = true;
    msg.sender.transferToken(1000000000, tokenId);
    emit Registered(msg.sender);
  }
  function isRegistered(address user) public view returns (bool) {
    return registered[user];
  }
  function referrer(address user) public view returns (address) {
    return referrers[user];
  }
}