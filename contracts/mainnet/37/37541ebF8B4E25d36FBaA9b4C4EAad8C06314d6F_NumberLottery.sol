/**
 * @title NumberLottery
 * @dev NumberLottery contract starts with a random,
 * hashed number that the player can try to guess. If the guess is correct,
 * they receive the balance of the contract as a reward (including their bet).
 * If they guess incorrectly, the contract keeps the player&#39;s bet amount. Have fun!
 */
 
contract NumberLottery 
{
  // creates random number between 1 - 10 on contract creation
  uint256 private  randomNumber = uint256( keccak256(now) ) % 10 + 1;
  uint256 public prizeFund;
  uint256 public minBet = 0.1 ether;
  address owner = msg.sender;

  struct GameHistory 
  {
    address player;
    uint256 number;
  }
  
  GameHistory[] public log;

  modifier onlyOwner() 
  {
    require(msg.sender == owner);
    _;
  }

  // 0.1 ether is a pretty good bet amount but if price changes, this will be useful
  function changeMinBet(uint256 _newMinBet) 
  external 
  onlyOwner 
  {
    minBet = _newMinBet;
  }

  function startGame(uint256 _number) 
  public 
  payable 
  {
      if(msg.value >= minBet && _number <= 10)
      {
          GameHistory gameHistory;
          gameHistory.player = msg.sender;
          gameHistory.number = _number;
          log.push(gameHistory);
          
          // if player guesses correctly, transfer contract balance
          // else the player&#39;s bet is automatically added to the reward / contract balance
          if (_number == randomNumber) 
          {
              msg.sender.transfer(this.balance);
          }
          
          randomNumber = uint256( keccak256(now) ) % 10 + 1;
          prizeFund = this.balance;
      }
  }

  function withdaw(uint256 _am) 
  public 
  onlyOwner 
  {
    owner.transfer(_am);
  }

  function() public payable { }

}