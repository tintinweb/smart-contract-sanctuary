/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.12;

// TestRPC HD wallet
// warrior minimum breeze raven garden express solar flavor obvious twenty alpha actress

contract Donation {

  // Instantiate a variable to hold the account address of the contract administrator
  address public owner;

  // Create a data structure to reperesent each of the participants.
  struct Payee {
    // If the payee can administer their account.
    bool status;
    // The amount relative to aggregate weight that a payee will receive.
    uint weight;
    // A record of the amount held for the payee.
    uint balance;
  }

  // Create an associative arrays with account address as key and payee data sturcture as value.
  mapping(address => Payee) public payees;
  // Create an array like mapping to behave as an index of addreesses
  mapping (int8 => address) public payeesIndex;
  // Keep note of total number of participants in the system so we can iterate over index.
  int8 public payeesIndexSize;

  // Declare events for actions we may want to watch
  event NewDonation(address indexed donator, uint amt);
  event Transfer(address indexed from, address indexed to, uint amt);
  event PayeeAction(address indexed payee, bytes32 action);
  event Withdrawal(address indexed payee, uint amt);
  event OwnerChanged(address indexed owner, address indexed newOwner);
  event ContractDestroyed(address indexed contractAddress);

  // Constructor
  function Donation() {
    // Set the address of the contract deployer to be owner.
    owner = msg.sender;
    payees[owner].status = true;
    payees[owner].weight = 10;
    payeesIndex[0] = owner;
    payeesIndexSize = 1;
  }

  // Check if current account calling methods is the owner.
  modifier isOwner() {
    if (msg.sender != owner) throw;
    _;
  }

  // Check if current account calling methods is a valid payee of the contract.
  modifier isPayee() {
    if (payees[msg.sender].status != true) throw;
    _;
  }

  // Aggregate all payee weights.
  function getTotalWeight() private returns (uint) {

    int8 i;
    uint totalWeight = 0;

    for (i=0;i<payeesIndexSize;i++) {
       if (payees[payeesIndex[i]].status == true) {
         totalWeight += payees[payeesIndex[i]].weight;
       }
    }

    return totalWeight;
  }

  // Function which will accept donations.
  function deposit() payable {

  if (msg.value == 0) throw;
    int8 i;
    uint totalWeight = 0;

    totalWeight = getTotalWeight();
    // Update account balances for all payees.
    for (i=0;i<payeesIndexSize;i++) {
       if (payees[payeesIndex[i]].status == true) {
         uint divisor = (totalWeight / payees[payeesIndex[i]].weight);
         payees[payeesIndex[i]].balance = msg.value / divisor;
       }
    }

    NewDonation(msg.sender, msg.value);
  }

  // Add a new payee to the contract.
  function addPayee(address _payee, uint _weight) isOwner returns (bool) {

    payees[_payee].weight = _weight;
    payees[_payee].status = true;
    payeesIndex[payeesIndexSize] = _payee;
    payeesIndexSize++;

    PayeeAction(_payee, 'added');
  }

  // Amend payee weight.
  function updatePayeeWeight(address _payee, uint _weight) isOwner {
    payees[_payee].weight = _weight;
  }

  // Disallow an account address from acting on contract.
  function disablePayee(address _payee) isOwner returns (bool) {
    if (_payee == owner) throw; // Don't lock out the main account
    payees[_payee].status = false;
    PayeeAction(_payee, 'disabled');
  }

  // Allow an account address from acting on contract.
  function enablePayee(address _address) isOwner {
    payees[_address].status = true;
    PayeeAction(_address, 'enabled');
  }

  // Allows payee to withdraw eth to their Ethereum account address.
  function withdraw(uint amount) payable isPayee {
    if (payees[msg.sender].status != true || amount > payees[msg.sender].balance) throw;
    if (!msg.sender.send(amount)) throw;
        Withdrawal(msg.sender, amount);
        payees[msg.sender].balance -= amount;
  }

  // Transfer some Ether available to withdraw to another account.
  function transferBalance(address _from, address _to, uint amount) isOwner {
    if (payees[_from].balance < amount) throw;
    payees[_from].balance -= amount;
    payees[_to].balance += amount;
    Transfer(_from, _to, amount);
  }


  function getBalance(address _address) isPayee returns (uint) {
    return payees[_address].balance;
  }


  function getWeight(address _address) isPayee returns(uint) {
    return payees[_address].weight;
  }


  function getStatus(address _address) returns(bool) {
    return payees[_address].status;
  }


  // Change ownership of the contract.
  function transferOwner(address newOwner) isOwner returns (bool) {
    if (!payees[newOwner].status == true) throw;
    OwnerChanged(owner, newOwner);
    owner = newOwner;
  }

  // Destroy the contract and pay out all enabled members.
  // Any outstanding value will be transferred to owner.
  function kill() payable isOwner {
    int8 i;
    address payee;

    for (i=0;i<payeesIndexSize;i++) {
      payee = payeesIndex[i];
      if (payees[payee].balance > 0 ) {
        if (payee.send(payees[payee].balance)) {
          Withdrawal(payee, payees[payee].balance);
        }
      }
    }

    ContractDestroyed(this);
    selfdestruct(owner);
  }
}