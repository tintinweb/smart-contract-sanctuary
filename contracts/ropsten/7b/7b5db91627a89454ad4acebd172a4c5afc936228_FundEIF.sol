pragma solidity ^0.4.25;

contract FundEIF {
  
  mapping(address => uint256) public receivedFunds; //doesn&#39;t include interest returned but allows other addresses to send funds
  uint256 public totalSent;                         //includes reinvested interest + totalOtherReceived outside PoEIF
  uint256 public totalOtherReceived;                //total received outside PoEIF
  uint256 public totalInterestReinvested;           //updated for promotional reasons
  address public EIF;
  address public PoEIF;
  event INCOMING(address indexed sender, uint amount, uint256 timestamp);
  event OUTGOING(address indexed sender, uint amount, uint256 timestamp);

  constructor() public {
    EIF = 0x775C009Be15f6a7EC577C4172961F2bf82DB37f1;    //EasyInvestForever
    PoEIF = 0x5706E4602643eFd7c49D1E25e4e32BD1a3eb1A41;  //PoEIF
  }
  
  function () external payable {
      emit INCOMING(msg.sender, msg.value, now);  //msg.sender is EIF if it is interest
      if (msg.sender != EIF) {                    //will only use more gas if not a returned interest payment
          receivedFunds[msg.sender] += msg.value; //update totals for this sender (normally PoEIF)
          if (msg.sender != PoEIF) {              //update totalsOtherReceived updates if non-PoEIF
              totalOtherReceived += msg.value;
          }
      }
  }
  
  function PayEIF() external {
      uint256 currentBalance=address(this).balance;
      totalSent += currentBalance;                                                 //update totalSent
      totalInterestReinvested = totalSent-receivedFunds[PoEIF]-totalOtherReceived; //update totalInterestReinvested
      emit OUTGOING(msg.sender, currentBalance, now);
      if(!EIF.call.value(currentBalance)()) revert();
  }
}