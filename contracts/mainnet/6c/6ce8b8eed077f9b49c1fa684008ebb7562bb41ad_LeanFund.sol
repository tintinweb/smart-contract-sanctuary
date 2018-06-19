pragma solidity ^0.4.1;

contract LeanFund {

  // Poloniex Exchange Rate 2017-08-06: 266 USD / ETH
  uint8 constant public version = 2;

  address public beneficiary;

  // These are for Ethereum backers only
  mapping (address => uint) public contributionsETH;
  mapping (address => uint) public payoutsETH;

  uint public fundingGoal;     // in wei, the amount we&#39;re aiming for
  uint public payoutETH;       // in wei, the amount withdrawn as fee
  uint public amountRaised;    // in wei, the total amount raised

  address public owner;
  uint    public fee; // the contract fee is 1.5k USD, or ~5.63 ETH
  uint    public feeWithdrawn; // in wei

  uint public creationTime;
  uint public deadlineBlockNumber;
  bool public open;            // has the funding period started, and contract initialized

  function LeanFund() {
    owner = msg.sender;
    creationTime = now;
    open = false;
  }

  // We can only initialize once, but don&#39;t add beforeDeadline guard or check deadline
  function initialize(uint _fundingGoalInWei, address _beneficiary, uint _deadlineBlockNumber) {
    if (open || msg.sender != owner) throw; // we can only initialize once
    if (_deadlineBlockNumber < block.number + 40) throw; // deadlines must be at least ten minutes hence
    beneficiary = _beneficiary;
    payoutETH = 0;
    amountRaised = 0;
    fee = 0;
    feeWithdrawn = 0;
    fundingGoal = _fundingGoalInWei;

    // If we pass in a deadline in the past, set it to be 10 minutes from now.
    deadlineBlockNumber = _deadlineBlockNumber;
    open = true;
  }

  modifier beforeDeadline() { if ((block.number < deadlineBlockNumber) && open) _; else throw; }
  modifier afterDeadline() { if ((block.number >= deadlineBlockNumber) && open) _; else throw; }

  // Normal pay-in function, where msg.sender is the contributor
  function() payable beforeDeadline {
    if (msg.value != 1 ether) { throw; } // only accept payments of 1 ETH exactly
    if (payoutsETH[msg.sender] == 0) { // defend against re-entrancy
        contributionsETH[msg.sender] += msg.value; // allow multiple contributions
        amountRaised += msg.value;
    }
  }

  function getContribution() constant returns (uint retVal) {
    return contributionsETH[msg.sender];
  }

  /* As a safeguard, if we were able to pay into account without being a contributor
     allow contract owner to clean it up. */
  function safeKill() afterDeadline {
    if ((msg.sender == owner) && (this.balance > amountRaised)) {
      uint amount = this.balance - amountRaised;
      if (owner.send(amount)) {
        open = false; // make this resettable to make testing easier
      }
    }
  }

  /* Each backer is responsible for their own safe withdrawal, because it costs gas */
  function safeWithdrawal() afterDeadline {
    uint amount = 0;
    if (amountRaised < fundingGoal && payoutsETH[msg.sender] == 0) {
      // Ethereum backers can only withdraw the full amount they put in, and only once
      amount = contributionsETH[msg.sender];
      payoutsETH[msg.sender] += amount;
      contributionsETH[msg.sender] = 0;
      if (!msg.sender.send(amount)) {
        payoutsETH[msg.sender] = 0;
        contributionsETH[msg.sender] = amount;
      }
    } else if (payoutETH == 0) {
      // anyone can withdraw the crowdfunded amount to the beneficiary after the deadline
      fee = amountRaised * 563 / 10000; // 5.63% fee, only after beneficiary has received payment
      amount = amountRaised - fee;
      payoutETH += amount;
      if (!beneficiary.send(amount)) {
        payoutETH = 0;
      }
    } else if (msg.sender == owner && feeWithdrawn == 0) {
      // only the owner can withdraw the fee and any excess funds (rounding errors)
      feeWithdrawn += fee;
      selfdestruct(owner);
    }
  }

}