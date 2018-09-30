pragma solidity ^ 0.4.24;

/*contract FactoryAuction{
	address[] public deployedAuctions;
	
	function createAuction() public {
		address newAuction = new Auction(msg.sender);
		deployedAuctions.push(newAuction);
	}
	
	function getDeployedAuctions() public view returns (address[]){
		return deployedAuctions;
	}
}*/

contract Auction{

	//current highest bidder for Auction2
	//address highestBidder;

	//current highest bid
	//uint public highestBid; 
	
	// Auction Owner
	address public auction_owner;
	
	// Minimum Increment
	uint public min_increment;

	
	//current bidder amount h1,h2,h3
	uint public h1A; 
	uint h2A; 
	uint h3A; 
	
	// Current bidder rank h1,h2,h3
	address h1; 
	address h2; 
	address h3; 
	
	constructor() public {
		h1A = 0;
		h2A = 0;
		h3A = 0;
		h1 = address(0);
		h2 = address(0);
		h3 = address(0);
		min_increment = 2;
		auction_owner = msg.sender;
	}
	
	//
	// Bid Function 
	//
	function bid(uint amount)public payable {
		// Check Bid Amount 		
		if (amount < (h1A+min_increment)) { 
			revert(&#39;Invalid Bid Amount.&#39;);
		}else{
			// Auction Owner Could Not Allow in Biding
			if(msg.sender == auction_owner){
				revert(&#39;You can not bid in this auction. Because you are auction owner !!!&#39;);
			}else{
				/*highestBidder = msg.sender;
				highestBid = amount;*/
				
				h3 = h2;
				h3A = h2A;
				
				h2 = h1;
				h2A = h1A;
				
				h1 = msg.sender;
				h1A = amount;
			}
		}
	}

	//
	// Getters
	// Get Highest Bidder
	/* function getHighestBidder()public restricted view returns (address) {
		return highestBidder;
	} */
	
	// Get Bidder Position H1
	function getH1Bidder()public restricted view returns (address) {
		return h1;
	}
	
	// Get Bidder Position H2
	function getH2Bidder()public restricted view returns (address) {
		return h2;
	}
	
	// Get Bidder Position H3
	function getH3Bidder()public restricted view returns (address) {
		return h3;
	}
	
	
	// Get Bidder Amount H1A
	function getH1Amount()public view returns (uint) {
		return h1A;
	}
	
	// Get Bidder Position H2
	function getH2Amount()public view returns (uint) {
		return h2A;
	}
	
	// Get Bidder Position H3
	function getH3Amount()public view returns (uint) {
		return h3A;
	}
	
	// IS Bidder h1 OR NOT
	function amIH1()public view returns (string memory) {
		string memory returnvar = &#39;--&#39;;
		if(msg.sender == h1){
			returnvar = &#39;H1&#39;;
		}
		return returnvar;
	}
	
	// 
	// Validate this method only used by auction owner
	//
	modifier restricted(){
		if(msg.sender != auction_owner){
			revert(&#39;Sorry, Its only for Auction Owner&#39;);
			/* require(msg.sender == auction_owner); */
		}else{
			_;
		}
    }
 
	//
	//For testing 
	//
	/* function reset()public {
		highestBid = 0;
		highestBidder = this;
	}  */
}