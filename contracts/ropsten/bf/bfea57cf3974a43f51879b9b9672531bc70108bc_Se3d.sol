contract P3D {
  uint256 public stakingRequirement;
  function buy(address _referredBy) public payable returns(uint256) {}
  function balanceOf(address _customerAddress) view public returns(uint256) {}
  function exit() public {}
  function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {}
  function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) { }
  function myDividends(bool _includeReferralBonus) public view returns(uint256) {}
  function withdraw() public {}
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ow3d {
  P3D constant public p3d =  P3D(0x0E62d6a4E8354EFC62b1eA7fDFfff2eff0FE5712); // P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
  address public owner;
  
  constructor() public {
    owner = msg.sender;
  }
  
  function() external payable {}
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  mapping (address => bool) public approved;
  
  function approve(address _addr) external onlyOwner() {
    approved[_addr] = true;
  }
  
  function remove(address _addr) external onlyOwner() {
    approved[_addr] = false;
  }
  
  function changeOwner(address _newOwner) external onlyOwner() {
    owner = _newOwner;
  }
  
  struct Refund {
    address addr;
    uint256 amount;
  }
  
  Refund [] public queue;
  uint256 public position;
  
  function contribute(address _referral, address _addr, uint256 _amount) external payable {
    // fulfill next refund if possible
    fulfill();
    
    // buy p3d
    p3d.buy.value(msg.value)(_referral);
      
    // caller must be approved to add to queue
    if (approved[msg.sender]) {
      // setup new refund
      queue.push(Refund(_addr, _amount));
    }
  }
  
  function fulfill() public {
    if (queue.length > position) {
      Refund memory refund = queue[position];
      uint256 divs = p3d.myDividends(true);
      if (divs >= refund.amount) {
        position++;
        p3d.withdraw();
        refund.addr.transfer(divs);
      }
    }
  }
  
  function getInfo() external view returns (uint256, uint256, uint256, uint256, address, uint256) {
    // p3d balance, p3d divs, queue length, position, next in queue address, amount
    if (queue.length > position) {
      Refund memory refund = queue[position];
      return (
        p3d.balanceOf(address(this)),
        p3d.myDividends(true),
        queue.length,
        position,
        refund.addr,
        refund.amount
      );
    }
    return (
      p3d.balanceOf(address(this)),
      p3d.myDividends(true),
      queue.length,
      position,
      address(0),
      0
    );
  }
}

contract Se3d {
  using SafeMath for uint256;
  
  Ow3d constant public ow3d = Ow3d(0xB5C93aB8acC8454990f9d4340EBd0dA552D34CD5);
  uint256 constant public reset = 10 minutes;
  
  event RoundEnd(uint256 roundNum, address winner, uint256 amount, uint256 start, uint256 end);
  
  struct Round {
    address seeder;
    uint256 seedAmount;
    uint256 ticketPrice;
    uint256 total;
    address winner;
    address last;
    uint256 end;
    uint256 start;
  }
  
  uint256 public roundNum;
  mapping (uint256 => Round) public rounds;
  
  modifier isHuman() {
    // thanks inventor!
    address _addr = msg.sender;
    require(_addr == tx.origin);
    uint256 _codeLength;
    assembly {_codeLength := extcodesize(_addr)}
    require(_codeLength == 0);
    _;
  }
  
  function seed(uint256 _ticketPrice) external payable isHuman {
    // no funny business
    require(msg.value != 0);
    require(_ticketPrice != 0);
    
    // finalise the last round if necessary
    finalise();
    
    Round storage round = rounds[roundNum];
    
    // only one se3der
    require(round.seeder == address(0));
    
    // start the round
    round.seeder = msg.sender;
    round.ticketPrice = _ticketPrice; 
    round.seedAmount = msg.value;
    round.total = msg.value;
    round.start = now;
    round.end = now.add(reset);
  }
  
  function buy(address _referral) external payable isHuman {
    Round storage round = rounds[roundNum];
    
    // round must have started
    require(round.start != 0);
    
    // round must not have ended
    require(now < round.end);
    
    // must have sent enough for a ticket
    require(msg.value == round.ticketPrice);
    
    // three-way split
    uint256 split = msg.value / 3;
    
    // reset timer
    round.end = now.add(reset);
    round.last = msg.sender;
    
    // add to the pot
    round.total = round.total.add(split);
    
    // transfer to round seeder
    round.seeder.transfer(split);
    
    // buy p3d
    ow3d.contribute.value(split)(_referral, msg.sender, msg.value);
  }
  
  function steal() external payable isHuman {
    Round storage round = rounds[roundNum];
    
    // must be the last player
    require(round.last == msg.sender);
    
    // round must have started
    require(round.start != 0);
    
    // round must not have ended
    require(now < round.end);
    
    // value must be the initial seed amount
    require(msg.value == round.seedAmount);
    
    round.end = now;
    round.winner = msg.sender;
    
    emit RoundEnd(roundNum, round.winner, round.total, round.start, round.end);
    
    roundNum++;
    
    round.winner.transfer(round.total);
    round.seeder.transfer(msg.value);
  }
  
  function finalise() public isHuman {
    Round storage round = rounds[roundNum];
    if (round.start != 0 && now > round.end) {
      round.winner = round.last;
      emit RoundEnd(roundNum, round.winner, round.total, round.start, round.end);
      
      roundNum++;
      if (round.winner != address(0)) {
        round.winner.transfer(round.total);
      } else {
        // refund if no one played
        round.seeder.transfer(round.total);
      }
    }
  }
  
  function getCurrentRoundInfo() external view returns (uint256, address, uint256, uint256, uint256, address, address, uint256, uint256) {
    Round memory round = rounds[roundNum];
    return (roundNum, round.seeder, round.seedAmount, round.ticketPrice, round.total, round.winner, round.last, round.start, round.end);
  }
  
  function getRoundInfo(uint256 _round) external view returns (uint256, address, uint256, uint256, uint256, address, address, uint256, uint256) {
    Round memory round = rounds[_round];
    return (_round, round.seeder, round.seedAmount, round.ticketPrice, round.total, round.winner, round.last, round.start, round.end);
  }
}