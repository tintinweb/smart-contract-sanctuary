pragma solidity ^0.4.11;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EthCapsule is Ownable {
  struct Depositor {
    uint numCapsules;
    mapping (uint => Capsule) capsules;
  }

  mapping (address => Depositor) depositors;

  struct Capsule {
    uint value;
    uint id;
    uint lockTime;
    uint unlockTime;
    uint withdrawnTime;
  }

  uint public minDeposit = 1000000000000000;
  uint public minDuration = 0;
  uint public maxDuration = 157680000;
  uint public totalCapsules;
  uint public totalValue;
  uint public totalBuriedCapsules;

  function bury(uint unlockTime) payable {
    require(msg.value >= minDeposit);
    require(unlockTime <= block.timestamp + maxDuration);

    if (unlockTime < block.timestamp + minDuration) {
      unlockTime = SafeMath.add(block.timestamp, minDuration);
    }

    if (depositors[msg.sender].numCapsules <= 0) {
        depositors[msg.sender] = Depositor({ numCapsules: 0 });
    }

    Depositor storage depositor = depositors[msg.sender];

    depositor.numCapsules++;
    depositor.capsules[depositor.numCapsules] = Capsule({
        value: msg.value,
        id: depositors[msg.sender].numCapsules,
        lockTime: block.timestamp,
        unlockTime: unlockTime,
        withdrawnTime: 0
    });

    totalBuriedCapsules++;
    totalCapsules++;
    totalValue = SafeMath.add(totalValue, msg.value);
  }

  function dig(uint capsuleNumber) {
    Capsule storage capsule = depositors[msg.sender].capsules[capsuleNumber];

    require(capsule.unlockTime <= block.timestamp);
    require(capsule.withdrawnTime == 0);

    totalBuriedCapsules--;
    capsule.withdrawnTime = block.timestamp;
    msg.sender.transfer(capsule.value);
  }

  function setMinDeposit(uint min) onlyOwner {
    minDeposit = min;
  }

  function setMinDuration(uint min) onlyOwner {
    minDuration = min;
  }

  function setMaxDuration(uint max) onlyOwner {
    maxDuration = max;
  }
  
  function getCapsuleInfo(uint capsuleNum) constant returns (uint, uint, uint, uint, uint) {
    return (
        depositors[msg.sender].capsules[capsuleNum].value,
        depositors[msg.sender].capsules[capsuleNum].id,
        depositors[msg.sender].capsules[capsuleNum].lockTime,
        depositors[msg.sender].capsules[capsuleNum].unlockTime,
        depositors[msg.sender].capsules[capsuleNum].withdrawnTime
    );
  }

  function getNumberOfCapsules() constant returns (uint) {
    return depositors[msg.sender].numCapsules;
  }

  function totalBuriedValue() constant returns (uint) {
    return this.balance;
  }
}