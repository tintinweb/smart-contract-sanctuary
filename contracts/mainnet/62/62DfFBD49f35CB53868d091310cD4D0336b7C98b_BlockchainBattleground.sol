pragma solidity ^0.4.18;

contract BlockchainBattleground {
    address public owner;
    address public owner2 = 0xc49D45ff52B1ABF1901B6c4f3D3e0615Ff85b9a3;
    uint public matchCount;
    Match private currentMatch;
    bool matchPaidOff;

    struct Gladiator {
    	string name;
    	uint totalAmount;
    	address[] backersList; // list with unique payers (no duplicates)
    	mapping(address => uint) amountPaid; // no need to initialize the mapping explicitly
    }

    struct Match {
    	uint matchId;
    	uint creationTime;
    	uint durationTime;
    	string matchName;
    	Gladiator left;
    	Gladiator right;
    }

    function BlockchainBattleground() public payable {
        owner = msg.sender;
	matchCount = 0;
	matchPaidOff = true;

	createMatch("Bitcoin Cash", "Bitcoin", 7 days, "Which is the real Bitcoin?");
    }

    function createMatch(string leftName, string rightName, uint duration, string matchQuestion) public onlyOwner matchPaidOffModifier {
	    Gladiator memory leftGlad = Gladiator(leftName, 0, new address[](0));
	    Gladiator memory rightGlad = Gladiator(rightName, 0, new address[](0));

	    currentMatch = Match(matchCount, block.timestamp, duration, matchQuestion, leftGlad, rightGlad);

	    matchCount += 1;
	    matchPaidOff = false;
    }

    function payOff() public matchTimeOver {
	    // Anybody can call this and pay off the winners, after the match is over
	    Gladiator memory winnerGladiator;
	    uint winner;
	    if (currentMatch.left.totalAmount > currentMatch.right.totalAmount) {
		     winnerGladiator = currentMatch.left;
		     winner = 0;
	    }
	    else {
		    winnerGladiator = currentMatch.right;
		    winner = 1;
	    }
	    uint jackpot = (this.balance - winnerGladiator.totalAmount) * 96 / 100;
	    payWinningGladiator(winner, jackpot);
            // we get the remaining 4% of the losing team
	    owner.transfer(this.balance / 2); 
	    owner2.transfer(this.balance);

	    matchPaidOff = true;
    }

    function payWinningGladiator(uint winner, uint jackpot) private {
	    Gladiator winnerGlad = (winner == 0) ? currentMatch.left : currentMatch.right;
            for (uint i = 0; i < winnerGlad.backersList.length; i++) {
		    address backerAddress = winnerGlad.backersList[i];
		    uint valueToPay = winnerGlad.amountPaid[backerAddress] + winnerGlad.amountPaid[backerAddress] * jackpot / winnerGlad.totalAmount;
		    backerAddress.transfer(valueToPay);
	    }
    }

    function payForYourGladiator(uint yourChoice) public payable matchTimeNotOver {
	    Gladiator currGlad = (yourChoice == 0) ? currentMatch.left : currentMatch.right;
	    if (currGlad.amountPaid[msg.sender] == 0)  {
		    currGlad.backersList.push(msg.sender);
	    }
	    currGlad.amountPaid[msg.sender] += msg.value;
	    currGlad.totalAmount += msg.value;
    }

    function getMatchInfo() public view returns (string leftGladName,
                                              string rightGladName,
                                              uint leftGladAmount,
                                              uint rightGladAmount,
                                              string matchName,
                                              uint creationTime,
                                              uint durationTime,
					      bool matchPaidOffReturn,
					      uint blockTimestamp) {
        return (currentMatch.left.name,
                currentMatch.right.name,
                currentMatch.left.totalAmount,
                currentMatch.right.totalAmount,
                currentMatch.matchName,
                currentMatch.creationTime,
                currentMatch.durationTime,
	        matchPaidOff,
	        block.timestamp);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier matchTimeOver() {
        require(block.timestamp > currentMatch.creationTime + currentMatch.durationTime);
        _;
    }

    modifier matchTimeNotOver() {
        require(block.timestamp < currentMatch.creationTime + currentMatch.durationTime);
        _;
    }

    modifier matchPaidOffModifier() {
	require(matchPaidOff);
	_;
    }

}