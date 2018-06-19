pragma solidity ^0.4.19;

/**
 * @title GuessNumber
 * @dev My first smart contract! GuessNumber contract starts with a random,
 * hashed number that the player can try to guess. If the guess is correct,
 * they receive the balance of the contract as a reward (including their bet).
 * If they guess incorrectly, the contract keeps the player&#39;s bet amount. Have fun!
 */
contract GuessNumber {
  // creates random number between 1 - 10 on contract creation
  uint256 private randomNumber = uint256( keccak256(now) ) % 10 + 1;
  uint256 public lastPlayed;
  uint256 public minBet = 0.1 ether;
  address owner;

  struct GuessHistory {
    address player;
    uint256 number;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function GuessNumber() public {
    owner = msg.sender;
  }

  // 0.1 ether is a pretty good bet amount but if price changes, this will be useful
  function changeMinBet(uint256 _newMinBet) external onlyOwner {
    minBet = _newMinBet;
  }

  function guessNumber(uint256 _number) public payable {
    require(msg.value >= minBet && _number <= 10);

    GuessHistory guessHistory;
    guessHistory.player = msg.sender;
    guessHistory.number = _number;

    // if player guesses correctly, transfer contract balance
    // else the player&#39;s bet is automatically added to the reward / contract balance
    if (_number == randomNumber) {
      msg.sender.transfer(this.balance);
    }

    lastPlayed = now;
  }

  function kill() public onlyOwner {
    selfdestruct(owner);
  }

  function() public payable { }

}