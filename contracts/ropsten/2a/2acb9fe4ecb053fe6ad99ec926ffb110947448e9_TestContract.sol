pragma solidity ^0.4.18; // solhint-disable-line



contract TestContract{
  mapping (address => uint) public balances;
  mapping (address => uint) public upgradelevels;
  uint public nextClaim=now+30 days;
  function getTotalEth() public view returns(uint){
    return this.balance;
  }
  function getTokenBalance(address addr) public view returns(uint){
    return balances[addr];
  }
  function claimToken() public{
    balances[msg.sender]+=1;
  }
  function buyUpgrade() public payable{
    upgradelevels[msg.sender]+=1;
  }
}