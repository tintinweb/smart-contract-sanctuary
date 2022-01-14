/**
 *Submitted for verification at FtmScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract UltiBetsJuventusVSUdinese{
  enum Side { JuventusTurin, Udinese }
  
  struct Result {
    Side winner;
    Side loser;
  }
  Result result;
  
  bool public isEventFinished;
  bool public isEventCancelled;
  
 
  mapping(Side => uint) public bets;
  mapping(address => uint) public amountperBettor;
  mapping(address => mapping(Side => uint)) public betsAmountPerBettor;
  
  address public admin;
  address public oracle;
  uint256 public feePercentage = 2;
  uint256 public feeBalance;
  address public UltiBetTreasury;

  event betPlaced(address indexed bettor, Side bets, uint amountperBettor);

  constructor(address _oracle, address _UltiBetTreasury) {
    admin = msg.sender;
    oracle = _oracle;
    UltiBetTreasury = _UltiBetTreasury;
  }

  function placeBet(Side _side) external payable {
    require(isEventFinished == false, 'Event is finished');
    
    uint256 betAmount = msg.value;
    
    bets[_side] += betAmount;
    betsAmountPerBettor[msg.sender][_side] += betAmount;
    amountperBettor[msg.sender] += betAmount;
    emit betPlaced(msg.sender, _side, betAmount);
  }

    function stopBet() external {
    require(oracle == msg.sender, 'Only the oracle can stop the current Bet');
    isEventFinished = true;
  }

  function cancelEvent() external {
    require(oracle == msg.sender, 'Only the oracle can cancel the current Event');
    isEventCancelled = true;
    isEventFinished = true;
  }

  function claimBetCancelledEvent(Side _side) external {
    require(isEventCancelled == true, 'Event is not cancelled');
    
    uint256 BettorBet = betsAmountPerBettor[msg.sender][_side];
    require(BettorBet > 0, 'You did not make any bets');
    
    bets[_side] -= BettorBet;
 
    betsAmountPerBettor[msg.sender][Side.JuventusTurin] = 0;
    betsAmountPerBettor[msg.sender][Side.Udinese] = 0;
    
    msg.sender.transfer(BettorBet);
  }
  
  function withdrawGain() external {
    uint256 BettorBet = amountperBettor[msg.sender];
    uint256 feeBettorBet = (BettorBet * feePercentage) / 100;
    uint BettorBetWinner = betsAmountPerBettor[msg.sender][result.winner] - feeBettorBet;
    
    require(BettorBetWinner > 0, 'You do not have any winning bet');  
    require(isEventFinished == true, 'Event not finished yet');
    require(isEventCancelled == false, 'Event is cancelled');
    
    uint gain = BettorBetWinner + bets[result.loser] * BettorBetWinner / bets[result.winner];
    
    betsAmountPerBettor[msg.sender][Side.JuventusTurin] = 0;
    betsAmountPerBettor[msg.sender][Side.Udinese] = 0;
    
    msg.sender.transfer(gain);
  }

  function reportResult(Side _winner, Side _loser) external {
    require(oracle == msg.sender, 'Only the oracle can report the current Event results');
    
    result.winner = _winner;
    result.loser = _loser;

    uint256 feeBet = (address(this).balance * feePercentage) / 100;
    feeBalance += feeBet;

    address payable to = payable(UltiBetTreasury);
    to.transfer(feeBalance);
    
    feeBalance = 0;
    
    isEventFinished = true;
  }
  
  
    function withdrawEarnedFees() public {
    require(admin == msg.sender, 'Only the admin can withdraw the earned fees');
    require(feeBalance > 0, 'No fees to withdraw');
    
    address payable to = payable(UltiBetTreasury);
    to.transfer(feeBalance);
    feeBalance -= feeBalance;
  }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

     function EmergencySafeWithdraw() public {
    require(admin == msg.sender, 'Only the admin can make an emergency withdraw in case of a bug/vulnerability to avoid the Contract getting drained');
    
    address payable to = payable(UltiBetTreasury);
    to.transfer(address(this).balance);
  }
    
}