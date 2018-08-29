pragma solidity ^0.4.24;

contract dapBetting {
    
    /* Types */
    
    enum eventStatus{ open, finished, closed }
    
    struct bid{
        uint id;
        bytes32 name;
        address[] whoBet;
        uint amountReceived;
    }
    
    struct betEvent{
        uint id;
        bytes32 name;
        address creator;
        address arbitrator;
        bytes32 winner;
        uint arbitratorFee;
        uint256 endBlock;
        uint256 minBid;
        uint256 maxBid;
        bid[] bids;
        bet[] bets;
        eventStatus status;
    }
    
    struct bet{
        address person;
        bytes32 bidName;
        uint amount;
    }
    
    /* Storage */
    
    mapping (address => betEvent[]) public betEvents;
    mapping (address => uint) public pendingWithdrawals;
    
    /* Events */
    
    event eventCreated(uint id, address creator);
    event betMade(uint value, uint id);
    event eventStatusChanged(uint status);
    event withdrawalDone(uint amount);
    
    /* Modifiers */
    modifier onlyFinished(address creator, uint eventId){
        if (betEvents[creator][eventId].status == eventStatus.finished || betEvents[creator][eventId].endBlock < block.number){
            _;
        }
    }
    modifier onlyArbitrator(address creator, uint eventId){
        if (betEvents[creator][eventId].arbitrator == msg.sender){
            _;
        }
    }
    /* Methods */
    
    function createEvent(bytes32 name, bytes32[] names, address arbitrator, uint fee, uint256 endBlock, uint256 minBid, uint256 maxBid) external{
        
        require(fee < 100);
        /* check whether event with such name already exist */
        bool found;
        for (uint8 x = 0;x<betEvents[msg.sender].length;x++){
            if(betEvents[msg.sender][x].name == name){
                found = true;
            }
        }
        require(!found);
        
        /* check names for duplicates */
        for (uint8 y=0;i<names.length;i++){
            require(names[y] != names[y+1]);
        }
        
        uint newId = betEvents[msg.sender].length++;
        betEvents[msg.sender][newId].id = newId;
        betEvents[msg.sender][newId].name = name;
        betEvents[msg.sender][newId].arbitrator = arbitrator;
        betEvents[msg.sender][newId].status = eventStatus.open;
        betEvents[msg.sender][newId].creator = msg.sender;
        betEvents[msg.sender][newId].endBlock = endBlock;
        betEvents[msg.sender][newId].minBid = minBid;
        betEvents[msg.sender][newId].maxBid = maxBid;
        betEvents[msg.sender][newId].arbitratorFee = fee;
        
        for (uint8 i = 0;i < names.length; i++){
            uint newBidId = betEvents[msg.sender][newId].bids.length++;
            betEvents[msg.sender][newId].bids[newBidId].name = names[i];
            betEvents[msg.sender][newId].bids[newBidId].id = newBidId;
        }
        
        emit eventCreated(newId, msg.sender);
    }
    
    function makeBet(address creator, uint eventId, bytes32 bidName) payable external{
        require(betEvents[creator][eventId].status == eventStatus.open);
        if (betEvents[creator][eventId].endBlock > 0){
        	require(block.number > betEvents[creator][eventId].endBlock);
        }
        /* check whether bid with given name actually exists */
        bool found;
        for (uint8 i=0;i<betEvents[creator][eventId].bids.length;i++){
            if (betEvents[creator][eventId].bids[i].name == bidName){
                bid storage foundBid = betEvents[creator][eventId].bids[i];
                found = true;
            }
        }
        require(found);
        //check for block
        if (betEvents[creator][eventId].endBlock > 0){
        	require(betEvents[creator][eventId].endBlock < block.number);
        }
        //check for minimal amount
        if (betEvents[creator][eventId].minBid > 0){
        	require(msg.value > betEvents[creator][eventId].minBid);
        }
        //check for maximal amount
        if (betEvents[creator][eventId].maxBid > 0){
        	require(msg.value < betEvents[creator][eventId].maxBid);
        }
        foundBid.whoBet.push(msg.sender);
        foundBid.amountReceived += msg.value;
        uint newBetId = betEvents[creator][eventId].bets.length++;
        betEvents[creator][eventId].bets[newBetId].person = msg.sender;
        betEvents[creator][eventId].bets[newBetId].amount = msg.value;
        betEvents[creator][eventId].bets[newBetId].bidName = bidName;
        
        emit betMade(msg.value, newBetId);
    }
    
    function finishEvent(address creator, uint eventId) external{
        require(betEvents[creator][eventId].status == eventStatus.open && betEvents[creator][eventId].endBlock == 0);
        require(msg.sender == betEvents[creator][eventId].arbitrator);
        betEvents[creator][eventId].status = eventStatus.finished;
        emit eventStatusChanged(1);
    }
    
    function determineWinner(address creator, uint eventId, bytes32 bidName) external onlyFinished(creator, eventId) onlyArbitrator(creator, eventId){
        require (findBid(creator, eventId, bidName));
        betEvent storage cEvent = betEvents[creator][eventId];
        cEvent.winner = bidName;
        uint amountLost;
        uint amountWon;
        uint lostBetsLen;
        /*Calculating amount of all lost bets */
        for (uint x=0;x<betEvents[creator][eventId].bids.length;x++){
            if (cEvent.bids[x].name != cEvent.winner){
                amountLost += cEvent.bids[x].amountReceived;
            }
        }
        
        /* Calculating amount of all won bets */
        for (x=0;x<cEvent.bets.length;x++){
            if(cEvent.bets[x].bidName == cEvent.winner){
                uint wonBetAmount = cEvent.bets[x].amount;
                amountWon += wonBetAmount;
                pendingWithdrawals[cEvent.bets[x].person] += wonBetAmount;
            } else {
                lostBetsLen++;
            }
        }
        /* If we do have win bets */
        if (amountWon > 0){
            pendingWithdrawals[cEvent.arbitrator] += amountLost/100*cEvent.arbitratorFee;
            amountLost = amountLost - (amountLost/100*cEvent.arbitratorFee);
            for (x=0;x<cEvent.bets.length;x++){
            if(cEvent.bets[x].bidName == cEvent.winner){
                //uint wonBetPercentage = cEvent.bets[x].amount*100/amountWon;
                uint wonBetPercentage = percent(cEvent.bets[x].amount, amountWon, 2);
                pendingWithdrawals[cEvent.bets[x].person] += (amountLost/100)*wonBetPercentage;
            }
        }
        } else {
            /* If we dont have any bets won, we pay all the funds back except arbitrator fee */
            for(x=0;x<cEvent.bets.length;x++){
                pendingWithdrawals[cEvent.bets[x].person] += cEvent.bets[x].amount-((cEvent.bets[x].amount/100) * cEvent.arbitratorFee);
                pendingWithdrawals[cEvent.arbitrator] += (cEvent.bets[x].amount/100) * cEvent.arbitratorFee;
            }
        }
        cEvent.status = eventStatus.closed;
        emit eventStatusChanged(2);
    }
    
    function withdraw(address person) private{
        uint amount = pendingWithdrawals[person];
        pendingWithdrawals[person] = 0;
        person.transfer(amount);
        emit withdrawalDone(amount);
    }
    
    function requestWithdraw() external {
        //require(pendingWithdrawals[msg.sender] != 0);
        withdraw(msg.sender);
    }
    
    function findBid(address creator, uint eventId, bytes32 bidName) private view returns(bool){
        for (uint8 i=0;i<betEvents[creator][eventId].bids.length;i++){
            if(betEvents[creator][eventId].bids[i].name == bidName){
                return true;
            }
        }
    }
    
    function calc(uint one, uint two) private pure returns(uint){
        return one/two;
    }
    function percent(uint numerator, uint denominator, uint precision) public 

    pure returns(uint quotient) {
           // caution, check safe-to-multiply here
          uint _numerator  = numerator * 10 ** (precision+1);
          // with rounding of last digit
          uint _quotient =  ((_numerator / denominator) + 5) / 10;
          return ( _quotient);
    }
    /* Getters */
    
    function getBidsNum(address creator, uint eventId) external view returns (uint){
        return betEvents[creator][eventId].bids.length;
    }
    
    function getBid(address creator, uint eventId, uint bidId) external view returns (uint, bytes32, uint){
        bid storage foundBid = betEvents[creator][eventId].bids[bidId];
        return(foundBid.id, foundBid.name, foundBid.amountReceived);
    }

    function getBetsNums(address creator, uint eventId) external view returns (uint){
        return betEvents[creator][eventId].bets.length;
    }

    function getWhoBet(address creator, uint eventId, uint bidId) external view returns (address[]){
        return betEvents[creator][eventId].bids[bidId].whoBet;
    }
    
    function getBet(address creator, uint eventId, uint betId) external view returns(address, bytes32, uint){
        bet storage foundBet = betEvents[creator][eventId].bets[betId];
        return (foundBet.person, foundBet.bidName, foundBet.amount);
    }
    
    function getEventId(address creator, bytes32 eventName) external view returns (uint, bool){
        for (uint i=0;i<betEvents[creator].length;i++){
            if(betEvents[creator][i].name == eventName){
                return (betEvents[creator][i].id, true);
            }
        }
    }
}