/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract VikingsMatch {

	struct Bet{
		uint256 betId; // id of the bet
		BetStatus betStatus; // status of the bet {Open | Closed | Settled}
		mapping(uint256 => BetterDatum[]) bettersData; // stores bet data
		uint256 correctChoice; // winning team
		uint256 jackpot;
        uint256 minFee;
        uint256 maxFee;
        uint256 minBet;
        uint256 maxBet;
        uint256 roundTimes;
	}

	struct BetterDatum{
		address payable better; // betters address
		uint256 value; // bet value of the better
		uint256 fee; // fee value of the better
	}

	// used for my bets
	struct BetterCacheDatum{
		uint256 betId; // bet id
		uint256 optionId; // option chosen
		uint256 betValue; // bet value of the better
		uint256 feeValue; // fee value of the better
	}
	
	address	payable owner = 0xb0527453dB6FFF587873f758c1683406c26ed799; // store owner address

	mapping(uint256 => Bet) public bets; // store all bet
	uint256 public lengthBets; // length of bets

	mapping(address => BetterCacheDatum[]) betterCacheData; // store betters data for fast access
	// uint public lengthBetterCacheData;

	enum BetStatus {Open, Closed, Settled} //enums for different status of the bet
    enum MatchStatus {Pending, Win, Lose, Tie} //enums for different match status of the bet
    

	// constructor
	constructor() public{
		owner = msg.sender; // set owner
		addBet(8,1,50,1000000000000000,10000000000000000000);
		setJackpot(1,5000000000000000);
	}

	// to restrict access to non admin users
	modifier onlyByOwner{
		require(msg.sender == owner, "Unauthorised Access");
		_;
	}

    // to find if the specific id exists
    function getBetId() public view returns(uint256){
        return lengthBets;
    }

    // to get the specific bet status
    function getBetStatus(uint256 betId) public view returns(uint256){
        require(betId < lengthBets, "overflow bet length");
        uint256 res = 100;
        if(bets[betId].betStatus == BetStatus.Open) res = 10;
        else if (bets[betId].betStatus == BetStatus.Closed) res = 20;
        else res = 30;
        return res;
    }

	// to find if the current user is admin
	function isOwner() public view returns(bool) {
		if(msg.sender == owner) {
			return true;
		} else {
			return false;
		}
	}
    
    // get owner
    function getOwner() public view returns(address){
        return owner;
    }
    
    // find the round id with open status
    function findOpenedId() public view returns(uint256){
        uint256 i;
        for(i=0;i<lengthBets;i++){
            if(bets[i].betStatus==BetStatus.Open)break;
        }
        if(i==lengthBets) return uint256(0);
        return i;
    }
    
	// adds a bet without setting any values
	function addNewEmptyBet() public {
		Bet memory bet;
		bets[lengthBets] = bet;
	}
	
	// to add bet
	function addBet(uint256 roundTimes, uint256 minFee, uint256 maxFee, 
	                uint256 minBet, uint256 maxBet) public onlyByOwner {
		require(maxFee > minFee && minFee > 0, "Error Fee");
		require(maxBet > minBet && minBet > 0, "Error Bet");
		require(roundTimes >= 6, "too small round times(round times >= 6).");
		addNewEmptyBet();
		Bet storage bet = bets[lengthBets];
		bet.betId = lengthBets; //set id
		bet.betStatus = BetStatus.Open; // set status
		bet.minFee = minFee;
		bet.maxFee = maxFee;
		bet.minBet = minBet;
		bet.maxBet = maxBet;
		bet.roundTimes = roundTimes;
		lengthBets+=1;
	}

    // set the jackpot money of admin to contract
    function setJackpot(uint256 betId, uint256 jackpot) public payable onlyByOwner {
		require(jackpot > 0, "Error Jackpot");
		bets[betId].jackpot = jackpot;
    }

	// get total betting value for a given bet and a given team
	function getTotalBetData(uint256 betId, uint256 optionId) public view returns(uint256) {
		uint256 totalBetValue = 0;
		for(uint256 i=0; i<bets[betId].bettersData[optionId].length; i++){
			totalBetValue += bets[betId].bettersData[optionId][i].value;
		}
		return totalBetValue;
	}

	// get total fee value for a given bet and a given team
	function getTotalFeeData(uint256 betId, uint256 optionId) public view returns(uint256) {
		uint256 totalFeeValue = 0;
		for(uint256 i=0; i<bets[betId].bettersData[optionId].length; i++){
			totalFeeValue += bets[betId].bettersData[optionId][i].fee;
		}
		return totalFeeValue;
	}

	// allows the user to bet
	function bet(uint256 betId, uint256 optionId, uint256 betValue, uint256 feeValue) payable public {
	    require(bets[betId].betStatus==BetStatus.Open,"completed match");
		require(msg.value >= betValue);
		require(betValue >= bets[betId].minBet && betValue <= bets[betId].maxBet, "Error Bet Input");
		uint realValue = msg.value-feeValue;
		uint realValue1 = betValue-feeValue;
		bets[betId].bettersData[optionId].push(BetterDatum(msg.sender, realValue, feeValue));
		betterCacheData[msg.sender].push(BetterCacheDatum(betId, optionId, realValue1, feeValue));
	}
	
	// decide the match at the end of round.
	function decideMatch(uint256 betId) public view returns (uint256) {
	    uint redTot = getTotalBetData(betId, 0);
	    uint greenTot = getTotalBetData(betId, 1);
	    if (redTot > greenTot) return 0;
	    else if(greenTot > redTot) return 1;
	    else return 2;
	}
	
	// close a bet before the toss
	function closeBet(uint256 betId) public onlyByOwner {
		bets[betId].betStatus = BetStatus.Closed;
	}

	// start the payout process after the winner is known
	function payout(uint256 betId, uint256 correctChoice) public onlyByOwner {
		if(bets[betId].betStatus == BetStatus.Closed) {
			bets[betId].correctChoice = correctChoice;
			uint256 totWinBet = getTotalBetData(betId, correctChoice);
			uint256 failId = 1 - correctChoice;
			uint256 totFailBet = getTotalBetData(betId, failId);
			require(owner!=address(0),"Error Owner");
			if(totWinBet==0 || totFailBet==0){
			    owner.transfer(bets[betId].jackpot);
        		for(uint256 i=0; i<bets[betId].bettersData[correctChoice].length; i++) {
        			address payable better = bets[betId].bettersData[correctChoice][i].better;
        			uint256 betValue = bets[betId].bettersData[correctChoice][i].value + 
        			                bets[betId].bettersData[correctChoice][i].fee;
        			better.transfer(betValue);
        		}
            } else {
                totFailBet += bets[betId].jackpot;
    			owner.transfer(getTotalFeeData(betId, 0));
    			owner.transfer(getTotalFeeData(betId, 1));
    			for(uint256 i=0; i<bets[betId].bettersData[correctChoice].length; i++) {
    				address payable better = bets[betId].bettersData[correctChoice][i].better;
    				uint256 betValue = bets[betId].bettersData[correctChoice][i].value;
    				uint256 percent = 100*betValue/totWinBet;
    				betValue += totFailBet*percent/100;
    				if(address(this).balance > 0) better.transfer(betValue);
    				else break;
    			}
            }
            owner.transfer(address(this).balance);
		    bets[betId].betStatus = BetStatus.Settled;
		}
	}

	// get ethers held by the contact
	function getBalance() public view onlyByOwner returns(uint256) {
		return address(this).balance;
	}

	// redeem the ethers in the contract
	function redeem() public onlyByOwner {
		if(address(this).balance > 0){	
			bool allBetsSettled = true;
			if(allBetsSettled){
				owner.transfer(address(this).balance);
			}
		}
	}
}