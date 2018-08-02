pragma solidity ^0.4.18;


contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


contract Hold is Ownable {
    uint public deadline = 1546230000;
    uint public amountRaised;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);


    function () payable public {
        uint amount = msg.value;
        amountRaised += amount;
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    function safeWithdrawal() public afterDeadline {
        if (owner.send(amountRaised)) {
               emit FundTransfer(owner, amountRaised, false);
        }
    }
}