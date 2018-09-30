pragma solidity ^0.4.6;

contract FourWaySplit {

  // balances and account list are publicly visible

  mapping(address => uint) public beneficiaryBalance;
  address[4] public beneficiaryList;

  // emit events for real-time listeners and state history

  event LogReceived(address sender, uint amount);
  event LogWithdrawal(address beneficiary, uint amount);

  // give the constructor four addresses for the split

  function FourWaySplit(address addressA, address addressB, address addressC, address addressD) {
    beneficiaryList[0]=addressA;
    beneficiaryList[1]=addressB;
    beneficiaryList[2]=addressC;
    beneficiaryList[3]=addressD;
  }

  // send ETH

  function pay() 
    public
    payable
    returns(bool success)
  {
    if(msg.value==0) throw;

    // ignoring values not evenly divisible by 4. We round down and keep the change.
    // (No way to remove the loose change, so it&#39;s effectively destroyed.)

    uint forth = msg.value / 4;

    beneficiaryBalance[beneficiaryList[0]] += forth;
    beneficiaryBalance[beneficiaryList[1]] += forth;
    beneficiaryBalance[beneficiaryList[2]] += forth;
    beneficiaryBalance[beneficiaryList[3]] += forth;
    LogReceived(msg.sender, msg.value);
    return true;
  }

  function withdraw(uint amount)
    public
    returns(bool success)
  {
    if(beneficiaryBalance[msg.sender] < amount) throw; // insufficient funds
    beneficiaryBalance[msg.sender] -= amount;          // Optimistic accounting.
    if(!msg.sender.send(amount)) throw;                // failed to transfer funds
    LogWithdrawal(msg.sender, amount);
    return true;
  }

}