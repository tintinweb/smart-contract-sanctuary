pragma solidity 0.8.4;

contract BetSwap {
    enum BetType { Lay, Back }
    enum Outcome { Win, Lose, Refund }
    
    uint256 betCount;
    mapping(uint256 => BetSlip) public bets;
    mapping(uint256 => Settlement) public settlements;
    
    struct BetSlip {
        uint256 id;
        string fixtureId;
        string marketId;
        BetType betType;
        uint256 odds;
        uint256 amount;
        address user;
    }
    
    struct BetPlacement {
        string fixtureId;
        string marketId;
        BetType betType;
        uint256 odds;
    }
    
    struct Settlement {
        uint256 betId;
        uint256 matchedAmount;
        uint256 unmatchedAmount;
        uint256 payout;
        Outcome outcome;
    }
    
    event BetPlaced(
        uint256 id,
        string fixtureId,
        string marketId,
        BetType betType,
        uint256 odds,
        uint256 amount,
        address user
    );
    
    event Settled(
        uint256 betId,
        uint256 matchedAmount,
        uint256 unmatchedAmount,
        uint256 payout,
        Outcome outcome
    );
    
    constructor() {
    }

    function placeBet(BetPlacement memory betPlacement) public payable returns(uint256) {
        require(msg.value > 0, "value should be greater than zero");
        
        BetSlip storage betSlip = bets[betCount];
        betSlip.id = betCount;
        betSlip.fixtureId = betPlacement.fixtureId;
        betSlip.marketId = betPlacement.marketId;
        betSlip.betType = betPlacement.betType;
        betSlip.odds = betPlacement.odds;
        betSlip.amount = msg.value;
        betSlip.user = msg.sender;
        
        betCount++;
        emit BetPlaced(
            betSlip.id,
            betSlip.fixtureId,
            betSlip.marketId,
            betSlip.betType,
            betSlip.odds,
            betSlip.amount,
            betSlip.user);
            
        return betSlip.id;
    }
    
    function getBet(uint256 id) public view returns(BetSlip memory) {
        return bets[id];
    }
    
    function settle(Settlement memory settlement) public {
        BetSlip memory betSlip = bets[settlement.betId];
        
        address payable _user = payable(betSlip.user);
        if (settlement.outcome == Outcome.Win) {
            _user.transfer(settlement.payout);
        }
        if (settlement.outcome == Outcome.Refund) {
            require(betSlip.amount >= settlement.payout, "bet amount should be larger or equal to refund amount");
            _user.transfer(settlement.payout);
        }
        
        Settlement storage _settlement = settlements[settlement.betId];
        _settlement.betId = settlement.betId;
        _settlement.matchedAmount = settlement.matchedAmount;
        _settlement.unmatchedAmount = settlement.unmatchedAmount;
        _settlement.payout = settlement.payout;
        _settlement.outcome = settlement.outcome;
        
        emit Settled(
            settlement.betId,
            settlement.matchedAmount,
            settlement.unmatchedAmount,
            settlement.payout,
            settlement.outcome);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}