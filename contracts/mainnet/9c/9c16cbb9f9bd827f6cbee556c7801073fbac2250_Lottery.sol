pragma solidity ^0.4.23;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Lottery is Ownable {
  using SafeMath for uint256;
  address[] private players;
  address[] public winners;
  uint256[] public payments;
  uint256 private feeValue;
  address public lastWinner;
  address[] private last10Winners = [0,0,0,0,0,0,0,0,0,0];  
  uint256 public lastPayOut;
  uint256 public amountRised;
  address public house;
  uint256 public round;
  uint256 public playValue;
  uint256 public roundEnds;
  bool public stopped;
  mapping (address => uint256) public payOuts;
  uint256 private _seed;

  
  function bitSlice(uint256 n, uint256 bits, uint256 slot) private pure returns(uint256) {
    uint256 offset = slot * bits;
    uint256 mask = uint256((2**bits) - 1) << offset;
    return uint256((n & mask) >> offset);
  }

  function maxRandom() private returns (uint256 randomNumber) {
    _seed = uint256(keccak256(_seed, blockhash(block.number - 1), block.coinbase, block.difficulty));
    return _seed;
  }


  function random(uint256 upper) private returns (uint256 randomNumber) {
    return maxRandom() % upper;
  }
    
  function setHouseAddress(address _house) onlyOwner public {
    house = _house;
  }

  function setFee(uint256 _fee) onlyOwner public {
    feeValue = _fee;
  }
  
  function setPlayValue(uint256 _amount) onlyOwner public {
    playValue = _amount;
  }

  function stopLottery(bool _stop) onlyOwner public {
    stopped = _stop;
  }

  function produceRandom(uint256 upper) private returns (uint256) {
    uint256 rand = random(upper);
    //output = rand;
    return rand;
  }

  function getPayOutAmount() private view returns (uint256) {
    //uint256 balance = address(this).balance;
    uint256 fee = amountRised.mul(feeValue).div(100);
    return (amountRised - fee);
  }

  function draw() public {
    require(now > roundEnds);
    uint256 howMuchBets = players.length;
    uint256 k;
    lastWinner = players[produceRandom(howMuchBets)];
    lastPayOut = getPayOutAmount();
    
    winners.push(lastWinner);
    if (winners.length > 9) {
      for (uint256 i = (winners.length - 10); i < winners.length; i++) {
        last10Winners[k] = winners[i];
        k += 1;
      }
    }

    payments.push(lastPayOut);
    payOuts[lastWinner] += lastPayOut;
    lastWinner.transfer(lastPayOut);
    
    players.length = 0;
    round += 1;
    amountRised = 0;
    roundEnds = now + (1 * 1 days);
    
    emit NewWinner(lastWinner, lastPayOut);
  }

  function play() payable public {
    require (msg.value == playValue);
    require (!stopped);
    if (players.length == 0) {
      roundEnds = now + (1 * 1 days);
    }
    if (now > roundEnds) {
      draw();
    }
    players.push(msg.sender);
    amountRised = amountRised.add(msg.value);
  }

  function() payable public {
    play();
  }

  constructor() public {
    house = msg.sender;
    feeValue = 5;
    playValue = 1 finney;
  }
    
  function getBalance() onlyOwner public {
    uint256 thisBalance = address(this).balance;
    house.transfer(thisBalance);
  }
  
  function getPlayersCount() public view returns (uint256) {
      return players.length;
  }
  
  function getWinnerCount() public view returns (uint256) {
      return winners.length;
  }
  
  function getPlayers() public view returns (address[]) {
      return players;
  }
  
  function last10() public view returns (address[]) {
    if (winners.length < 11) {
      return winners;
    } else {
      return last10Winners;
    }
  }
  event NewWinner(address _winner, uint256 _amount);
  event Conso(uint a, uint b);
}