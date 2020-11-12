pragma solidity ^0.5.10;
/*
 * date: 10/6/2020
 * title: CryptoBoard - Simple smart contract billboard that charges users a set price to update the image, the price to update is then increased by a set amount (25% markup in this example)
 *						The received funds are then split between the developer and a charity
 * author: Crypto [Neo] - Check me out on twitter! (@neoaikon), if you like my work feel free to send me a tip at 0x5E294C8db9FdE66C19665ed42c6cb4552B0f5e73
 */
contract CryptoBoard {
	address private owner;		
	// Billboard parameters
	string public urlCharity;
	string public nameCharity;	
	string public urlBillboard;
	string public lcdMessage;
	// Payment parameters	
	address payable public payeeDev;
	address payable public payeeCharity;
	uint256 public minCost;
	uint256 public lastEpoch;
	uint256 public updateCost;
	uint8 public split;
	uint8 public markup;
	
	/// Modifier so only the owner can change the Minimum Cost, Markup and Split amounds, as well as the Dev and Charity addresses
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	// Constructor
	constructor(address payable initDevPayee, string memory initCharityName, address payable initCharityPayee, string memory initCharityUrl) public {
		// Set owner, developer, and charity addresses
		owner = msg.sender;
		payeeDev = initDevPayee;
		payeeCharity = initCharityPayee;
		// Initialize the initial image, charity name and icon
		nameCharity = initCharityName;
		urlCharity = initCharityUrl;
		// Initialize the billboard
		urlBillboard = "https://ipfs.io/ipfs/Qmej3Wu3NxqaHCJ1wdDuQUu3PWwLoPoA6mX9ts5YjPGgrJ";
		// Initialize the LCD message
		lcdMessage = "Cryptoboard - The interwebs Ethereum powered billboard!";
		// Initialize the last updated time
		lastEpoch = now;
		// Initialze the price variables
		markup = 125; // 25%
		split = 5; // 5%
		minCost = .01 ether;
		updateCost = minCost;
	}

	// Update the image displayed on the billboard	
	function updateBillboard(string memory newBillboardUrl) public payable {
	    require(bytes(newBillboardUrl).length != 0, "Billboard URL cannot be blank");
		require(msg.value > 0, "You need to actually send ETH!");
		// Get the cost of the update
		updateCost = getCost();
		// Make sure the amount of ETH sent matches the update cost
		require(msg.value >= updateCost, "You didn't send enough wei, check getCost()");
		// Update the LUT, image URL, and increase the cos by 10%
		lastEpoch = now;
		urlBillboard = newBillboardUrl;		
		updateCost = updateCost * markup / 100;
		
		performDonation(msg.value);
	}
	
	// Update the message displayed under the billboard	
	function updateLcdMessage(string memory newLcdMessage) public payable {
	    require(bytes(newLcdMessage).length != 0, "LCD message cannot be blank");
		require(msg.value > 0, "You need to actually send ETH!");				
		require(msg.value >= minCost/2, "You didn't send enough wei, cost=mincost/2");
		lcdMessage = newLcdMessage;		
		performDonation(msg.value);		
	}
	
	// Owner Only - Change the Developer payout address
	function setDevData(address payable newPayeeDev) public onlyOwner {
		require(newPayeeDev != address(0), "Developer payout cannot be burned");
		payeeDev = newPayeeDev;
	}
	
	// Owner Only - Change the Charity name, payout address and display icon
	function setCharityData(string memory newCharityName, address payable newPayeeCharity, string memory newCharityUrl) public onlyOwner {
		require(bytes(newCharityName).length != 0, "Charity name cannot be blank");
		require(bytes(newCharityUrl).length != 0, "Charity URL cannot be blank");
		require(newPayeeCharity != address(0), "Charity payout cannot be burned! Are you crazy?!");
		nameCharity = newCharityName;
		payeeCharity = newPayeeCharity;
		urlCharity = newCharityUrl;
	}

	// Owner Only - Change the minimum cost to set the billboard, as well as the markup and split parameters
	function setCostData(uint256 newMinCost, uint8 newMarkup, uint8 newSplit) public onlyOwner {
	    require(newMinCost != 0 && newMarkup != 0 && newSplit != 0, "All cost parameters must be > 0");
		minCost = newMinCost;
		markup = newMarkup;
		split = newSplit;
	}
	
	// Calculate the payment split and send it to the Dev and Charity
	function performDonation(uint256 v) private {
		uint256 devSplit = v * split / 100;
		// Send payouts to the developer and a charity
		payeeDev.transfer(devSplit);
		payeeCharity.transfer(msg.value-devSplit);
	}
	
	// Use this function when fetching the cost as it returns the calculated depreceated value
	function getCost() public view returns (uint256) {
		// Get number of days since last update
		uint256 updateDelta = (now - lastEpoch) / 1 days;
		// Over time the update cost will return to the minCost value
		// at a rate of 10% per day	since last update
		uint256 tmpCost = updateCost;
		for(uint256 i = 0; i < updateDelta; i++)
		{
			tmpCost -= tmpCost * 10 / 100;
			if(tmpCost < minCost) {
				tmpCost = minCost;
				break;
			}
		}
		return tmpCost;
	}
}