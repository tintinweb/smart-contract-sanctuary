/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity ^0.5.10;

contract ChainDotPrivateSale {
  address payable owner;
  uint public goal;
  uint public endTime;
  bool open = true;
  address public topDonor;

  mapping(address=>uint) donations;
  
  event OwnerWithdraw(uint amount, uint withdrawTime);
  event UserWithdraw(address user, uint amount, uint withdrawTime);
  event Donation(uint amount, address contributor);
  
  constructor(uint _goal, uint _timelimit) public {
    owner = msg.sender;
    goal = _goal;
    endTime = block.number + _timelimit;
  }

  function add() public payable {
    donations[msg.sender] += msg.value;
    if(donations[msg.sender] > donations[topDonor]) {
      topDonor = msg.sender;
    }
    emit Donation(msg.value, msg.sender);
  }

  function withdrawOwner() public {
    require(msg.sender == owner, "You must be the owner");
    emit OwnerWithdraw(address(this).balance, now);
    owner.transfer(address(this).balance);
  }

  function withdraw() public {
    require(address(this).balance < goal, "Fundraising campaign was successful");
    require(now > endTime, "Fundraising campaign is still ongoing");
    msg.sender.transfer(donations[msg.sender]);
    emit UserWithdraw(msg.sender, donations[msg.sender], now);
    donations[msg.sender] = 0;
  }
  
  function percentageComplete() public view returns (uint) {
    require(goal != 0, "goal is 0, cannot divide by 0");
    return 100 * (address(this).balance / goal);
  }
}