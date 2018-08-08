pragma solidity ^0.4.20;

/**&#39;&#39;&#39;&#39;&#39;&#39;
 *  ====    ;
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



  function Ownable() {
    owner = msg.sender;
  }



  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


 
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract POH is Ownable {

  string public constant name = "POH Lottery";
  uint public playersRequired = 125000;
  uint256 public priceOfTicket = 1e15 wei;

  event newWinner(address winner, uint256 ticketNumber);
  // event newRandomNumber_bytes(bytes);
  // event newRandomNumber_uint(uint);
  event newContribution(address contributor, uint value);

  using SafeMath for uint256;
  address[] public players = new address[](399);
  uint256 public lastTicketNumber = 0;
  uint8 public playersSignedUp = 0;
  uint public blockMinedAt;
  uint public amountwon;
  address public TheWinner;
  uint public amounRefferalWon;
  address public theWinningReferral;
  uint public randomNumber;
  uint public balanceOfPot = this.balance;

  struct tickets {
    uint256 startTicket;
    uint256 endTicket;
  }

  mapping (address => tickets[])  ticketsMap;
  mapping(address => address) public referral;
  mapping (address => uint256) public contributions;
  function updateFileds(uint256 _playersRequired, uint256 _priceOfTicket) onlyOwner{
      playersRequired = _playersRequired;
      priceOfTicket = _priceOfTicket;
  }

  function executeLottery() { 
      
        if (playersSignedUp > playersRequired-1) {
          randomNumber = uint(blockhash(block.number-1))%lastTicketNumber + 1;
          address  winner;
          bool hasWon;
          for (uint8 i = 0; i < playersSignedUp; i++) {
            address player = players[i];
            for (uint j = 0; j < ticketsMap[player].length; j++) {
              uint256 start = ticketsMap[player][j].startTicket;
              uint256 end = ticketsMap[player][j].endTicket;
              if (randomNumber >= start && randomNumber < end) {
                winner = player;
                hasWon = true;
                break;
              }
            }
            if(hasWon) break;
          }
          require(winner!=address(0) && hasWon);

          for (uint8 k = 0; k < playersSignedUp; k++) {
            delete ticketsMap[players[k]];
            delete contributions[players[k]];
          }

          playersSignedUp = 0;
          lastTicketNumber = 0;
          blockMinedAt = block.number;

          uint balance = this.balance;
          balanceOfPot = balance;
          amountwon = (balance*80)/100;
          TheWinner = winner;
          if (!owner.send(balance/10)) throw;
          if(referral[winner] != 0x0000000000000000000000000000000000000000){
              amounRefferalWon = (amountwon*10)/100;
              referral[winner].send(amounRefferalWon);
              winner.send(amountwon*90/100);
              theWinningReferral = referral[winner];
          }
          else{
              if (!winner.send(amountwon)) throw;
          }
          newWinner(winner, randomNumber);
          
        }
      
  }

  function getPlayers() constant returns (address[], uint256[]) {
    address[] memory addrs = new address[](playersSignedUp);
    uint256[] memory _contributions = new uint256[](playersSignedUp);
    for (uint i = 0; i < playersSignedUp; i++) {
      addrs[i] = players[i];
      _contributions[i] = contributions[players[i]];
    }
    return (addrs, _contributions);
  }

  function getTickets(address _addr) constant returns (uint256[] _start, uint256[] _end) {
    tickets[] tks = ticketsMap[_addr];
    uint length = tks.length;
    uint256[] memory startTickets = new uint256[](length);
    uint256[] memory endTickets = new uint256[](length);
    for (uint i = 0; i < length; i++) {
      startTickets[i] = tks[i].startTicket;
      endTickets[i] = tks[i].endTicket;
    }
    return (startTickets, endTickets);
  }

  function join()  payable {
    uint256 weiAmount = msg.value;
    require(weiAmount >= 1e16);

    bool isSenderAdded = false;
    for (uint8 i = 0; i < playersSignedUp; i++) {
      if (players[i] == msg.sender) {
        isSenderAdded = true;
        break;
      }
    }
    if (!isSenderAdded) {
      players[playersSignedUp] = msg.sender;
      playersSignedUp++;
    }

    tickets memory senderTickets;
    senderTickets.startTicket = lastTicketNumber;
    uint256 numberOfTickets = (weiAmount/priceOfTicket);
    senderTickets.endTicket = lastTicketNumber.add(numberOfTickets);
    lastTicketNumber = lastTicketNumber.add(numberOfTickets);
    ticketsMap[msg.sender].push(senderTickets);

    contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

    newContribution(msg.sender, weiAmount);

    if(playersSignedUp > playersRequired) {
      executeLottery();
    }
  }
  
    function joinwithreferral(address refer)  payable {
    uint256 weiAmount = msg.value;
    require(weiAmount >= 1e16);

    bool isSenderAdded = false;
    for (uint8 i = 0; i < playersSignedUp; i++) {
      if (players[i] == msg.sender) {
        isSenderAdded = true;
        break;
      }
    }
    if (!isSenderAdded) {
      players[playersSignedUp] = msg.sender;
      referral[msg.sender] = refer;
      playersSignedUp++;
    }

    tickets memory senderTickets;
    senderTickets.startTicket = lastTicketNumber;
    uint256 numberOfTickets = (weiAmount/priceOfTicket);
    senderTickets.endTicket = lastTicketNumber.add(numberOfTickets);
    lastTicketNumber = lastTicketNumber.add(numberOfTickets);
    ticketsMap[msg.sender].push(senderTickets);

    contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

    newContribution(msg.sender, weiAmount);

    if(playersSignedUp > playersRequired) {
      executeLottery();
    }
  }
}