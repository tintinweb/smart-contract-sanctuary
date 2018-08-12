pragma solidity ^0.4.22;

contract Lottery {

  address owner;
  address public beneficiary;
  mapping(address => bool) public playersMap;
  address[] public players;
  uint public playerEther = 0.01 ether;
  uint playerCountGoal;
  bool public isLotteryClosed = false;
  uint public rewards;

  event GoalReached(address recipient, uint totalAmountRaised);
  event FundTransfer(address backer, uint amount, bool isContribution);

  constructor() public {
    // playerCountGoal will be in [10000, 10100]
    playerCountGoal = 10000 + randomGen(block.number - 1, 101);
    owner = msg.sender;
  }

  /**
    * Fallback function
    *
    * The function without name is the default function that is called whenever anyone sends funds to a contract
    */
  function () public payable {
    require(!isLotteryClosed && msg.value == playerEther, "Lottery should not be closed and player should send exact ethers");
    require(!playersMap[msg.sender], "player should not attend twice");
    players.push(msg.sender);
    playersMap[msg.sender] = true;
    
    emit FundTransfer(msg.sender, msg.value, true);

    checkGoalReached();
  }

  modifier afterGoalReached() { 
    if (players.length >= playerCountGoal) _; 
  }

  function checkGoalReached() internal afterGoalReached {
    require(!isLotteryClosed, "lottery must be opened");
    isLotteryClosed = true;
    uint playerCount = players.length;

    // calculate the rewards
    uint winnerIndex = randomGen(block.number - 2, playerCount);
    beneficiary = players[winnerIndex];
    rewards = playerEther * playerCount * 4 / 5;

    emit GoalReached(beneficiary, rewards);
  }

  /* Generates a random number from 0 to 100 based on the last block hash */
  function randomGen(uint seed, uint count) private view returns (uint randomNumber) {
    return uint(keccak256(abi.encodePacked(block.number-3, seed))) % count;
  }

  function safeWithdrawal() public afterGoalReached {
    require(isLotteryClosed, "lottery must be closed");
    
    if (beneficiary == msg.sender) {
      beneficiary.transfer(rewards);
      emit FundTransfer(beneficiary, rewards, false);
    }

    if (owner == msg.sender) {
      uint fee = playerEther * players.length / 5;
      owner.transfer(fee);
      emit FundTransfer(owner, fee, false);
    }
  }

}