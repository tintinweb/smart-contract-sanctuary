/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ChoHanCasino {
  address payable public owner;
  uint256 public minimumBet;
  uint256 public totalBet;
  uint256 public numberOfPlayers;
  uint256 public minNumberPlayer = 2;
  address[] public players;
  uint public numberWinner;

  struct Player {
    uint256 amountBet;
    uint256 numberSelected;
  }

  struct Bet {
    uint numberWinner;
    uint totalBet;
  }

  mapping(address => Player) public playerInfo;
  Bet[] public betList;
  event Won(bool _status, address _address, uint _amount);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(uint256 _mininumBet) payable {
    owner = payable(msg.sender);
    if (_mininumBet != 0) 
      minimumBet = _mininumBet;
  }

  fallback() external payable {}
  receive() external payable {}

  function kill() public {
    if (msg.sender == owner)
      selfdestruct(owner);
  }

  function withdraw() public onlyOwner returns(bool) {
    owner.transfer(address(this).balance);
    return true;
  }

  function checkPlayerExists(address player) public view returns(bool) {
    for (uint256 i = 0; i < players.length; i++) {
      if (players[i] == player)
        return true;
    }
    return false;
  }

  function bet(uint256 numberSelected) public payable {
    require(!checkPlayerExists(msg.sender));
    require(numberSelected == 1 || numberSelected == 0);
    require(msg.value >= minimumBet);

    playerInfo[msg.sender].amountBet = msg.value;
    playerInfo[msg.sender].numberSelected = numberSelected;
    numberOfPlayers++;
    players.push(msg.sender);
    totalBet += msg.value;
    if (numberOfPlayers >= minNumberPlayer)
      generateNumberWinner();
  }

   function generateNumberWinner() public {
    uint256 numberGenerated = block.number % 36 + 1;
    numberWinner = numberGenerated;
    distributePrizes(numberGenerated);
  }

  function distributePrizes(uint256 numberWin) public {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    for (uint256 i = 0; i < players.length; i++) {
      address playerAddress = players[i];
      if (playerInfo[playerAddress].numberSelected == numberWin) {
        winners[countWin] = playerAddress;
        countWin++;
      } else {
        losers[countLose] = playerAddress;
        countLose++;
      }
      delete playerInfo[playerAddress];
    }

    if (countWin !=0) {
      uint256 winnerEtherAmount = totalBet/countWin;

      for (uint256 j = 0; j < countWin; j++) {
        if (winners[j] != address(0)) {
          payable(winners[j]).transfer(winnerEtherAmount);
          emit Won(true, winners[j], winnerEtherAmount);
        }
      }
    }

    for (uint256 l =0; l < losers.length; l++) {
      if (losers[l] != address(0))
        emit Won(false, losers[l], 0);
    }
    resetData();
  }


  function resetData() public {
    delete players;
    betList.push(Bet(numberWinner, totalBet));
    totalBet = 0;
    numberOfPlayers = 0;
  }
}