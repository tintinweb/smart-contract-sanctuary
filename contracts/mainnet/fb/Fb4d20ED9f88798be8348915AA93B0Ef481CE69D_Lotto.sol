pragma solidity ^0.4.18;
contract Lotto {

  address public owner = msg.sender;
  address[] internal playerPool;
  uint seed = 0;
  uint amount = 1 ether;
  // events
  event Payout(address from, address to, uint quantity);
  event BoughtIn(address from);
  event Rejected();

  modifier onlyBy(address _account) {
    require(msg.sender == _account);
    _;
  }
  
  function changeOwner(address _newOwner) public onlyBy(owner) {
    owner = _newOwner;
  }

/*
The reasoning behind this method to get a random number is, because I&#39;m not
displaying the current number of players, no one should know who the 11th player
will be, and that should be random enough to prevent anyone from cheating the system.
The reward is only 1 ether so it&#39;s low enough that miners won&#39;t try to influence it
... i hope.
*/
  function random(uint upper) internal returns (uint) {
    seed = uint(keccak256(keccak256(playerPool[playerPool.length -1], seed), now));
    return seed % upper;
  }

  // only accepts a value of 0.1 ether. no extra eth please!! don&#39;t be crazy!
  // i&#39;ll make contracts for different sized bets eventually.
  function buyIn() payable public returns (uint) {
    if (msg.value * 10 != 1 ether) {
      revert();
      Rejected();
    } else {
      playerPool.push(msg.sender);
      BoughtIn(msg.sender);
      if (playerPool.length >= 11) {
        selectWinner();
      }
    }
    return playerPool.length;
  }

  function selectWinner() private {
    address winner = playerPool[random(playerPool.length)];
    
    winner.transfer(amount);
    playerPool.length = 0;
    owner.transfer(this.balance);
    Payout(this, winner, amount);
    
  }
  
/*
If the contract becomes stagnant and new players haven&#39;t signed up for awhile,
this function will return the money to all the players. The function is made
payable so I can send some ether with the transaction to pay for gas. this way
I can make sure all players are paid back. 

as a note, 100 finney == 0.1 ether.
*/
  function refund() public onlyBy(owner) payable {
    require(playerPool.length > 0);
    for (uint i = 0; i < playerPool.length; i++) {
      playerPool[i].transfer(100 finney);
    }
      playerPool.length = 0;
  }
  
/*
Self destruct just in case. Also, will refund all ether to the players before it
explodes into beautiful digital star dust.
*/
  function close() public onlyBy(owner) {
    refund();
    selfdestruct(owner);
  }


// fallback function acts the same as buyIn(), omitting the return of course.
  function () public payable {
    require(msg.value * 10 == 1 ether);
    playerPool.push(msg.sender);
    BoughtIn(msg.sender);
    if (playerPool.length >= 11) {
      selectWinner();
    }
  }
}