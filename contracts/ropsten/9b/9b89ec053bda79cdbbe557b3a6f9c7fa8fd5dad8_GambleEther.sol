pragma solidity ^0.4.0;

contract GambleEther {
	
    
	function GambleEther() {
		owner = msg.sender;
		lastRoundTime = block.timestamp;
		UserStatus(&#39; Round gamble has started&#39;, msg.sender, 0, block.timestamp);
	}
    
    
    uint public transfersPercentaje = 100;
	uint public winnerPercentaje = 90;
	uint public companyPercentaje = 10;
	

	///address public vaultAddress = 0x4c62717955C4A3F3ccB057532F65Ba7fc0254bFF;

	address public owner;

	uint256 public lastRoundTime;

	uint256 public timeRound = 60;

	uint public potAmount = 0;
	uint public lastWinnerPotAmount;
	address public lastWinner;

	Participant[] public participants;

	uint public basePrice = 0.01 ether;

	event UserStatus(string _msg, address user, uint amount, uint256 time);

	struct Participant {
		address adr;
		uint tickets;
	}

	
    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }
	

function getEtherTicket() payable {
		bool isParticipant = false;
		if(msg.value >= basePrice) {
			UserStatus(&#39;Ticket Bought&#39;, msg.sender, msg.value, block.timestamp);
			for(uint i = 0; i < participants.length; i++) {
            	if(participants[i].adr == msg.sender) {
                	participants[i].tickets += 1;
                	isParticipant = true;
            	}
       		}
        	if(isParticipant == false) {
            	participants.push(Participant({
                	adr: msg.sender,
               	 tickets: 1
           	 }));
			potAmount = this.balance;
       	 }
		} else {
			revert();
		}
	}


	function FinishRoundGamble() {
		if(block.timestamp > (lastRoundTime + timeRound)) {
			uint random = uint(block.blockhash(block.number-1))%(participants.length + 1);
			potAmount = this.balance;
			lastWinnerPotAmount = (potAmount * winnerPercentaje / 100);
			participants[random].adr.transfer(potAmount * winnerPercentaje / 100);
			owner.transfer(potAmount * companyPercentaje / 100);
			///vaultAddress.transfer(potAmount * transfersPercentaje / 100);
			lastRoundTime = block.timestamp;
			potAmount = 0;
			lastWinner = participants[random].adr;
			for (uint i = 0; i<participants.length; i++){
            	delete participants[i];
        	}
        	UserStatus(&#39;Round gamble has ended, The Winner is:&#39;, lastWinner, lastWinnerPotAmount, block.timestamp);

		}
	}
}