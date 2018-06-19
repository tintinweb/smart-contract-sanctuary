pragma solidity ^0.4.0;
	contract CashCow {
	address public owner;
	uint256 private numberOfEntries;
	uint256 public cycleLength = 100;
	uint256 public price = 71940622590480000;
	uint256 public totalValue = 0;
	struct Player {
		uint256 lastCashOut;
		uint256[] entries;
	}
	// The address of the player and => the user info
	mapping(address => Player) public playerInfo;

	function() public payable {}

	constructor() public {
		owner = msg.sender;
		playerInfo[msg.sender].lastCashOut = 0;
		playerInfo[msg.sender].entries.push(numberOfEntries);
		numberOfEntries++;
	}

	function kill() public {
		if(msg.sender == owner) selfdestruct(owner);
	}


	//returns amount of ether a player is able to withdraw 
	function checkBalance(address player) public constant returns(uint256){
		uint256 lastCashOut = playerInfo[player].lastCashOut;
		uint256[] entries = playerInfo[player].entries;
		if(entries.length == 0){
			return 0;
		}
		uint256 totalBalance = 0;
		for(uint i = 0; i < entries.length; i++){
			uint256 entry = entries[i];
			uint256 cycle = entry / cycleLength;
			uint256 cycleEnd = (cycle+1) * cycleLength;
			//check if we have completed that cycle
			if(numberOfEntries >= cycleEnd) {
			    uint256 entryBalence;
				if(lastCashOut <= entry) {
					entryBalence = calculateBalance(entry % 100, 99);
					totalBalance += entryBalence;
				}
				if(lastCashOut > entry && lastCashOut < cycleEnd){
					entryBalence = calculateBalance(lastCashOut % 100, 99);
					totalBalance += entryBalence;
				}
			}
			if(numberOfEntries < cycleEnd) {
				if(lastCashOut <= entry) {
					entryBalence = calculateBalance(entry % 100, (numberOfEntries - 1) % 100);
					totalBalance += entryBalence;
				}
				if(lastCashOut > entry && lastCashOut < numberOfEntries){
					entryBalence = calculateBalance(lastCashOut % 100, (numberOfEntries - 1) % 100);
					totalBalance += entryBalence;
				}
			}
		}
		return totalBalance;
	}

	function calculateBalance(uint256 start, uint256 stop) public constant returns(uint256){
		if (start >= stop) return 0;
		uint256 balance  = 0;
		for(uint i = start + 1; i <= stop; i++) {
			balance += price / i;
		}
		return balance;
	}

	// buy into the contract
	function buy() public payable {
		require(msg.value >= price);
		playerInfo[msg.sender].entries.push(numberOfEntries);
		numberOfEntries++;
		totalValue += msg.value;
		//check if this starts a new cycle
		if(numberOfEntries % cycleLength == 0){
			playerInfo[owner].entries.push(numberOfEntries);
			numberOfEntries++;
		} 
	}


	function checkDeletable(address player) public constant returns(bool){
		uint256 finalEntry = playerInfo[player].entries[playerInfo[player].entries.length - 1];
		uint256 lastCycle = (finalEntry / cycleLength);
		uint256 cycleEnd = (lastCycle + 1) * cycleLength;
		return (numberOfEntries > cycleEnd);

	}

	function withdraw() public{
		uint256 balance = checkBalance(msg.sender); //check the balence to be withdrawn
		if(balance == 0) return;
		if(checkDeletable(msg.sender)){
			delete playerInfo[msg.sender];
		}
		else {
		    playerInfo[msg.sender].lastCashOut = numberOfEntries - 1;
		}
		totalValue -= balance;
		msg.sender.transfer(balance);
	}
}