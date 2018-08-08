pragma experimental "v0.5.0";

//Micro Etheroll contract
//version 0.8.0

//// minimal Etheroll "interface"

contract Etheroll {
    function playerRollDice(uint rollUnder) public payable;
    function playerWithdrawPendingTransactions() public returns (bool);
}

//// Proxy contract for Micro Etheroll - providing a cheap and empty payable fallback function

contract Proxy {
    address etheroll;
    address micro;
    address owner;
    uint roundID = 0;

    event GotFunds(uint indexed roundID, address indexed sender, uint indexed amount);
    event SentFunds(uint indexed roundID, uint indexed amount, uint indexed rollUnder);
    event WithdrawPendingTransactionsResult(bool indexed result);

    constructor(address etherollAddress, address ownerAddress) public {
        etheroll = etherollAddress;
        owner = ownerAddress;
        micro = msg.sender;
        roundID = 0;
    }

//// Getters

    function getBalance() view external returns (uint) {
        return address(this).balance;
    }

    function getRoundID() view external returns (uint) {
        return roundID;
    }

    function getEtherollAddress() view external returns (address) {
        return etheroll;
    }


//// Secutity modifier

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMicro {
        require(msg.sender == micro);
        _;
    }

//// Insecure public payable fallback function

    function () external payable {
        emit GotFunds(roundID, msg.sender, msg.value);
    }

//// Sending bets and withdrawing winnings

    function sendToEtheroll(uint rollUnder, uint newRoundID) external payable
            onlyMicro
    {
        roundID = newRoundID;
        Etheroll e = Etheroll(etheroll);
        e.playerRollDice.value(msg.value)(rollUnder);
        emit SentFunds(roundID, msg.value, rollUnder);
    }

    function withdrawWinnings() external
            onlyMicro
    {
        Micro m = Micro(micro);
        m.withdrawWinnings.value(address(this).balance)();
    }

//// Owner security & maintenance functions

    function withdrawRefund() external
            onlyMicro
    {
        Micro m = Micro(micro);
        m.withdrawRefund.value(address(this).balance)();
    }
    
    function withdrawPendingTransactions() external
            onlyOwner
    {
        Etheroll e = Etheroll(etheroll);
        emit WithdrawPendingTransactionsResult(e.playerWithdrawPendingTransactions());
    }
    
    function ownerWithdraw() external
            onlyOwner
    {
        owner.transfer(address(this).balance);
    }
    
    function setEtherollAddress(address etherollAddress) external
            onlyOwner
    {
        etheroll = etherollAddress;
    }
    
}

//// Main Micro Etheroll Contract

contract Micro {
    address[110] bets;
    address proxy;
    address owner;

    uint roundID;

    bool betsState = true;
    bool rolled = false;
    bool emergencyBlock = false;
    bool betsBlock = false;

    uint rollUnder = 90;
    uint participants = 10; // Number of effective participants (without extraBets)
    uint extraBets = 1;
    uint oneBet = 0.01 ether;
    uint8 numberOfBets = 0;

    uint houseEdgeDivisor = 1000;
    uint houseEdge = 990;

    uint expectedReturn;

    event GotBet(uint indexed roundID, address indexed sender, uint8 indexed numberOfBets);
    event BetResult(uint indexed roundID, uint8 indexed result, uint indexed amount);
    event ReadyToRoll(uint indexed roundID, uint indexed participants, uint indexed oneBet);
    event SendError(uint indexed roundID, address addr, uint amount);
    event Emergency(uint indexed roundID);

    constructor(address etherollAddress) public {
        owner = msg.sender;
        proxy = new Proxy(etherollAddress, owner);
        setExpectedReturn((((((oneBet*participants) * (100-(rollUnder-1))) / (rollUnder-1)+(oneBet*participants)))*houseEdge/houseEdgeDivisor) / 0.01 ether);
        roundID = 0;
    }

//// Getters and Setter



    function setExpectedReturn(uint rounded) internal {
        expectedReturn = rounded * 0.01 ether;
    }

    function getBetsState() external view returns (bool) {
        return betsState;
    }
    
    function getRolled() external view returns (bool) {
        return rolled;
    }

    function getExpectedReturn() external view returns (uint) {
        return expectedReturn;
    }

    function getNumberOfBets() external view returns (uint) {
        return numberOfBets;
    }

    function getRollUnder() external view returns (uint) {
        return rollUnder;
    }

    function getOneBet() external view returns (uint) {
        return oneBet;
    }

    function getParticipants() external view returns (uint) {
        return participants;
    }
    
    function getExtraBets() external view returns (uint) {
        return extraBets;
    }

    function getBetsBlock() external view returns (bool) {
        return betsBlock;
    }

    function getRoundID() view external returns (uint) {
        return roundID;
    }

    function getWaitingState() external view returns (uint) {
        if (!betsState && !rolled) return 1; //waiting for roll()
        if (!betsState && rolled && (address(proxy).balance > 0)) return 2; //waiting for wakeUpProxy(), but needs a check if funds on proxy are winnings
        if (emergencyBlock) return 9; //is in emergency block
        if (betsBlock) return 8; //bets block active
        if (betsState && !rolled) return 0; //not waiting, accepting bids
        return 5; // unknown state, probably waiting for etheroll 
    }
    
    // Combined "one-request" getState for web-requests optimisation
    function getState() external view returns (bool, bool, uint, uint, uint, uint, uint, uint, bool, uint, uint) {
        return (this.getBetsState(),
                this.getRolled(),
                this.getExpectedReturn(),
                this.getNumberOfBets(),
                this.getRollUnder(),
                this.getOneBet(),
                this.getParticipants(),
                this.getExtraBets(),
                this.getBetsBlock(),
                this.getRoundID(),
                this.getWaitingState());
    }

//// Security function modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyProxy {
        require(msg.sender == proxy);
        _;
    }

    modifier betsOver {
        require (!betsState);
        _;
    }

    modifier betsActive {
        require (betsState);
        _;
    }

    modifier noBets {
        require (numberOfBets == 0);
        _;
    }

    modifier hasRolled {
        require(rolled);
        _;
    }

    modifier hasntRolled {
        require(!rolled);
        _;
    }

    modifier hasMoney {
        require(address(proxy).balance > 0);
        _;
    }

    modifier noEmergencyBlock {
        require(!emergencyBlock);
        _;
    }

//// Secure payable fallback function - receives bets

    function () external payable {
        require((msg.value == oneBet) || (msg.sender == owner));
        if (msg.sender != owner) {
            require(betsState && !emergencyBlock);
            require(!betsBlock);
            if (numberOfBets < participants+(extraBets-1)) {
                bets[numberOfBets] = msg.sender;
                numberOfBets++;
                emit GotBet(roundID, msg.sender, numberOfBets);
            } else {
                bets[numberOfBets] = msg.sender;
                numberOfBets++;
                emit GotBet(roundID, msg.sender, numberOfBets);
                betsState = false;
                emit ReadyToRoll(roundID, participants+extraBets, oneBet);
            }
        }
    }


//// Main contract callable functions

    function roll() external
            betsOver
            hasntRolled
            noEmergencyBlock
    {
        require(numberOfBets == (participants + extraBets));
        rolled = true;
        Proxy p = Proxy(proxy);
        p.sendToEtheroll.value((participants) * oneBet)(rollUnder, roundID);
	  }

    function wakeUpProxy() external
            onlyOwner
            betsOver
            hasRolled
            hasMoney
            noEmergencyBlock
    {
        rolled = false;
        Proxy p = Proxy(proxy);
        p.withdrawWinnings();
    }

//// Withdraw and distribute winnings

    function withdrawWinnings() external payable
            onlyProxy
    {
        if ((msg.value > expectedReturn) && !emergencyBlock) {
            emit BetResult(roundID, 1, msg.value); // We won! Set 1
            distributeWinnings(msg.value);
        } else {
            emit BetResult(roundID, 0, msg.value); // We lost :( Set 0
        }
        
        numberOfBets = 0;
        betsState = true;
        roundID++;
    }

    function proxyGetRefund() external
            onlyOwner
            betsOver
            hasRolled
            hasMoney
    {
        rolled = false;
        Proxy p = Proxy(proxy);
        p.withdrawRefund();
    }

    function withdrawRefund() external payable
            onlyProxy
    {
        emit BetResult(roundID, 2, msg.value); // Set 2 for Refund
        distributeWinnings(msg.value+(oneBet*extraBets)); // Distribute the refund and return extraBets
        
        numberOfBets = 0;
        betsState = true;
        roundID++;
    }

    function distributeWinnings(uint value) internal
            betsOver
    {
        require(numberOfBets == (participants + extraBets)); // Check if count of participants+extraBets matches numberOfBets

        uint share = value / (numberOfBets); // Calculate the share out of value received div by number of bets
        for (uint i = 0; i<(numberOfBets); i++) {
            if (!(bets[i].send(share))) emit SendError(roundID, bets[i], share); // Send an SendError event if something goes wrong
        }
    }

//// Owner security & maintenance functions

    function resetState() external
        onlyOwner
    {
        numberOfBets = 0;
        betsState = true;
        rolled = false;
        roundID++;
    }

    function returnBets() external
            onlyOwner
    {
        require(emergencyBlock || betsBlock);
        require(numberOfBets>0);
        for (uint i = 0; i<(numberOfBets); i++) {
            if (!(bets[i].send(oneBet))) emit SendError(roundID, bets[i], oneBet); // Send an SendError event if something goes wrong
        }
        numberOfBets = 0;
        betsState = true;
        rolled = false;
        roundID++;        
    }
        

    function changeParticipants(uint newParticipants) external
            onlyOwner
            betsActive
    {
        require((newParticipants <= 100) && (newParticipants > numberOfBets)); //Check that newParticipants don&#39;t exceed bets array length and exceed current round existing bets
        participants = newParticipants;
        setExpectedReturn((((((oneBet*participants) * (100-(rollUnder-1))) / (rollUnder-1)+(oneBet*participants)))*houseEdge/houseEdgeDivisor) / 0.01 ether);
    }

    function changeExtraBets(uint newExtraBets) external
            onlyOwner
            betsActive
    {
        require(participants+newExtraBets < bets.length);
        require(participants+newExtraBets > numberOfBets);
        extraBets = newExtraBets;
    }

    function changeOneBet(uint newOneBet) external
            onlyOwner
            betsActive
            noBets
    {
        require(newOneBet > 0);
        oneBet = newOneBet;
        setExpectedReturn((((((oneBet*participants) * (100-(rollUnder-1))) / (rollUnder-1)+(oneBet*participants)))*houseEdge/houseEdgeDivisor) / 0.01 ether);
    }

    function changeRollUnder(uint newRollUnder) external
            onlyOwner
            betsActive
    {
        require((newRollUnder > 1) && (newRollUnder < 100));
        rollUnder = newRollUnder;
        setExpectedReturn((((((oneBet*participants) * (100-(rollUnder-1))) / (rollUnder-1)+(oneBet*participants)))*houseEdge/houseEdgeDivisor) / 0.01 ether);
    }

    function enableEmergencyBlock() external
            onlyOwner
    {
        emergencyBlock = true;
        emit Emergency(roundID);
    }

    function disableEmergencyBlock() external
            onlyOwner
    {
        emergencyBlock = false;
    }

    function enableBets() external
            onlyOwner
    {
        betsBlock = false;
    }

    function disableBets() external
            onlyOwner
    {
        betsBlock = true;
    }

    function ownerWithdraw() external
            onlyOwner
    {
        owner.transfer(address(this).balance);
    }

    function ownerkill() external
		    onlyOwner
	  {
		selfdestruct(owner);
	  }
}