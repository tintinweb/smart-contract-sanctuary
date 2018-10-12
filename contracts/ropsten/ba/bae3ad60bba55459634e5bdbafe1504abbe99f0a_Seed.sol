contract P3D {
  uint256 public stakingRequirement;
  function buy(address _referredBy) public payable returns(uint256) {}
  function balanceOf(address _customerAddress) view public returns(uint256) {}
  function exit() public {}
  function calculateTokensReceived(uint256 _ethereumToSpend) public view returns(uint256) {}
  function calculateEthereumReceived(uint256 _tokensToSell) public view returns(uint256) { }
  function myDividends(bool _includeReferralBonus) public view returns(uint256) {}
  function withdraw() public {}
  function totalSupply() public view returns(uint256);
}

contract Fomo {
  function round_(uint256 _round) public view returns(uint256, uint256, uint256, bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  uint256 public rID_;
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

contract Seed {
  // This contract allows bets to be placed on the outcome of several 
  // fomo3d variables including winner, winning team, end time, pot, etc..
  
  using SafeMath for uint256;
  
  // constants
  Fomo constant public fomo = Fomo(0xA62142888ABa8370742bE823c1782D17A0389Da1);
  P3D constant public p3d = P3D(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
  uint256 constant MAX_PARTICIPANTS = 20;
  
  struct Round {
    uint256 plyr;   // pID of player in lead
    uint256 team;   // tID of team in lead
    uint256 end;    // time ends/ended
    bool ended;     // has round end function been ran
    uint256 strt;   // time round started
    uint256 keys;   // keys
    uint256 eth;    // total eth in
    uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
    uint256 mask;   // global mask
    uint256 ico;    // total eth sent in during ICO phase
    uint256 icoGen; // total eth for gen during ICO phase
    uint256 icoAvg; // average key price for ICO phase
  }
    
  enum BetType {
    WINNER,
    TEAM,
    END,
    ETH,
    POT,
    KEYS
  }
  
  enum Status {
    OPEN,
    CLOSED
  }
  
  enum Operator {
    EQ,
    LT,
    GT
  }
  
  struct Bet {
    uint256 round;
    uint256 amount;
    uint256 total;
    BetType betType;
    Status status;
    Operator operator;
    uint256 outcome;
    address [] participants;
    address [] winners;
    mapping (address => bool) votes;
  }
  
  uint256 betIds;
  mapping(uint256 => Bet) public bets;
  mapping(address => uint256) public vaults;
  
  event Created(uint256 indexed betId, address creator, uint256 round, uint256 amount, BetType betType, Operator operator);
  event Joined(uint256 indexed betId, address joiner);
  event Cancelled(uint256 indexed betId);
  event Closed(uint256 indexed betId, address[] winners, uint256 rewardPerWinner);
 
  
  // Create a new bet
  // _betType is what fomo3d variable you want to bet on
  // _operator represents the logical operators you want to apply (== < >)
  // _outcome is the value you want to compare to the final result
  // _vote is what you think the outcome will be
  // e.g. Will the winning team (_betType) equal (_operator) snake (_outcome)? I bet that it will (_vote).
  function create(uint256 _betType, uint256 _operator, uint256 _outcome, bool _vote) external payable {
    require(msg.value != 0);
    
    BetType betType = BetType(_betType);
    Operator operator = Operator(_operator);
    
    // winner and team bets require equality operator
    if (
      betType == BetType.TEAM
      || betType == BetType.WINNER
    ) {
      require(operator == Operator.EQ);
    }
    
    // can only bet on the current running round
    uint256 roundNum = fomo.rID_();
    require(canBetOnRound(roundNum));
    
    // create bet
    bets[betIds].round = roundNum;
    bets[betIds].amount = msg.value;
    bets[betIds].total = msg.value;
    bets[betIds].betType = betType;
    bets[betIds].status = Status.OPEN;
    bets[betIds].operator = operator;
    bets[betIds].outcome = _outcome;
    bets[betIds].participants.push(msg.sender);
    bets[betIds].votes[msg.sender] = _vote;
    
    emit Created(betIds, msg.sender, roundNum, msg.value, betType, operator);
    
    betIds++;
    
    // pay out any divs to sender vault
    uint256 divs = p3d.myDividends(true);
    if (divs > 0) {
      vaults[msg.sender] = vaults[msg.sender].add(divs);
    }
  }
  
  function join(uint256 _betId, bool _vote) external payable {
    Bet storage bet = bets[_betId];
     
    // bet must exist
    require(bet.amount != 0);
    
    // the bet must still be open 
    require(bet.status == Status.OPEN);
    
    // value sent must be equal to bet amount
    require(msg.value == bet.amount);
    
    // make sure round has not ended
    require(canBetOnRound(bet.round));
    
    // must not exceed max participants
    require(bet.participants.length < MAX_PARTICIPANTS);
    
    // add participant
    bet.participants.push(msg.sender);
    
    // add to the total
    bet.total = bet.total.add(msg.value);
    
    // add vote
    bet.votes[msg.sender] = _vote;
    
    emit Joined(_betId, msg.sender);
  }
   
  function cancel(uint256 _betId) external {
    Bet storage bet = bets[_betId];
   
    // bet must exist
    require(bet.amount != 0);
   
    // the bet must still be open 
    require(bet.status == Status.OPEN);
   
    // there must only be one participant
    require(bet.participants.length == 1);
   
    // and that participant must be the caller
    require(bet.participants[0] == msg.sender);
   
    // close the bet
    bet.status = Status.CLOSED;
    
    // return eth
    vaults[msg.sender] = vaults[msg.sender].add(bet.total);

    emit Cancelled(_betId);
  }
  
  function validate(uint256 _betId) external {
    Bet storage bet = bets[_betId];
    
    // check if this bet can be validated
    require(canBeValidated(_betId));
    
    // get round
    Round memory round = getRound(bet.round);
    
    // close the bet
    bet.status = Status.CLOSED;
    
    // get the outcome of the bet
    bool outcome = getResult(bet, round);
 
    // determine the winners
    for (uint256 i = 0; i < bet.participants.length; i++) {
      address participant = bet.participants[i];
      if (bet.votes[participant] == outcome) {
        bet.winners.push(participant);
      }
    }
    
    // take out 10% tax
    uint256 tax = bet.total.div(10);
    uint256 taxedTotal = bet.total.sub(tax);
    
    if (bet.winners.length > 0) {
      // award the winners
      uint256 rewardPerWinner = taxedTotal.div(bet.winners.length);
      for (i = 0; i < bet.winners.length; i++) {
        // add to vault
        address winner = bet.winners[i];
        vaults[winner] = vaults[winner].add(rewardPerWinner);
      }
      emit Closed(_betId, bet.winners, rewardPerWinner);
    } else {
      // if no winners, return eth
      uint256 refundPerParticpant = taxedTotal.div(bet.participants.length);
      for (i = 0; i < bet.participants.length; i++) {
        // add to vault
        address refundee = bet.participants[i];
        vaults[refundee] = vaults[refundee].add(refundPerParticpant);
      }
      emit Closed(_betId, bet.winners, 0);
    }
    
    // buy p3d with validator as the masternode
    p3d.buy.value(tax)(msg.sender);
  }
  
  function withdraw() external {
    // get vault
    uint256 vault = vaults[msg.sender];
    
    // zero out vault
    vaults[msg.sender] = 0;
    
    // transfer vault to owner
    msg.sender.transfer(vault);
  }
  
  function getResult(Bet bet, Round round) internal pure returns (bool) {
    // determine the outcome
    if (bet.betType == BetType.WINNER) {
      return round.plyr == bet.outcome;
    } else if (bet.betType == BetType.TEAM) {
      return round.team == bet.outcome;
    } else if (bet.betType == BetType.END) {
      return process(bet.operator, round.end, bet.outcome);
    } else if (bet.betType == BetType.ETH) {
      return process(bet.operator, round.eth, bet.outcome);
    } else if (bet.betType == BetType.POT) {
      return process(bet.operator, round.pot, bet.outcome);
    } else if (bet.betType == BetType.KEYS) {
      return process(bet.operator, round.keys, bet.outcome);
    }
  }
  
  function process(Operator operator, uint256 _value, uint256 _outcome) internal pure returns (bool) {
    if (operator == Operator.EQ) {
      return _value == _outcome;
    } else if (operator == Operator.LT) {
      return _value < _outcome;
    } else if (operator == Operator.GT) {
      return _value > _outcome;
    }
  }

  function canBetOnRound(uint256 _roundNum) internal view returns (bool) {
    Round memory round = getRound(_roundNum);
    if (
      round.ended == false
      && now < round.end
    ) {
      return true;
    }
  }
  
  function canBeValidated(uint256 _betId) public view returns (bool) {
    Bet memory bet = bets[_betId];
    Round memory round = getRound(bet.round);
    if (
      bet.amount != 0 // bet must exist
      && bet.status == Status.OPEN // bet must be open
      && bet.participants.length > 1 // must have more than 1 participant
      && round.ended // round must have ended
    ) {
      return true;
    }
  }
  
  function getRound(uint256 _roundNum) internal view returns (Round) {
    (
    uint256 plyr,
    uint256 team,
    uint256 end,
    bool ended,
    uint256 strt,
    uint256 keys,
    uint256 eth,
    uint256 pot,
    uint256 mask,
    uint256 ico,
    uint256 icoGen,
    uint256 icoAvg
    ) = fomo.round_(_roundNum);
    return Round(
      plyr,
      team,
      end,
      ended,
      strt,
      keys,
      eth,
      pot,
      mask,
      ico,
      icoGen,
      icoAvg
    );
  }
}