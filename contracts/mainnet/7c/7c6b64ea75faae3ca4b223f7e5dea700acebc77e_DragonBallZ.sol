pragma solidity ^0.4.18;

/*
Game: Dragon Ball Super ( Tournament of Power )
Domain: EtherDragonBall.com
*/

contract DragonBallZ {
    
    //The contract creator and dev fee addresses are defined here
	address contractCreator = 0x606A19ea257aF8ED76D160Ad080782C938660A33;
    address devFeeAddress = 0xAe406d5900DCe1bB7cF3Bc5e92657b5ac9cBa34B;

	struct Hero {
		string heroName;
		address ownerAddress;
		address DBZHeroOwnerAddress;
		uint256 currentPrice;
		uint currentLevel;
	}
	Hero[] heroes;
	
	//The number of heroes in Tournament of Power
	uint256 heroMax = 55;
	
	//The array defined for winner variable
    uint256[] winners;


	modifier onlyContractCreator() {
        require (msg.sender == contractCreator);
        _;
    }

    bool isPaused;
    
    
    /*
    We use the following functions to pause and unpause the game.
    */
    function pauseGame() public onlyContractCreator {
        isPaused = true;
    }
    function unPauseGame() public onlyContractCreator {
        isPaused = false;
    }
    function GetGamestatus() public view returns(bool) {
        return(isPaused);
    }

    /*
    This function allows users to purchase Tournament of Power heroes 
    The price is automatically multiplied by 2 after each purchase.
    Users can purchase multiple heroes.
    */
	function purchaseHero(uint _heroId) public payable {
	    //Check if current price of hero is equal with the price entered to purchase the hero
		require(msg.value == heroes[_heroId].currentPrice);
		
		//Check if the game is not PAUSED
		require(isPaused == false);
		
		// Calculate the 10% of Tournament of Power prize fee
		uint256 TournamentPrizeFee = (msg.value / 10); // => 10%
	    
		// Calculate the 5% - Dev fee
		uint256 devFee = ((msg.value / 10)/2);  // => 5%
		
		// Calculate the 10% commission - Dragon Ball Z Hero Owner
		uint256 DBZHeroOwnerCommission = (msg.value / 10); // => 10%

		// Calculate the current hero owner commission on this sale & transfer the commission to the owner.		
		uint256 commissionOwner = (msg.value - (devFee + TournamentPrizeFee + DBZHeroOwnerCommission)); 
		heroes[_heroId].ownerAddress.transfer(commissionOwner); // => 75%

		// Transfer the 10% commission to the DBZ Hero Owner
		heroes[_heroId].DBZHeroOwnerAddress.transfer(DBZHeroOwnerCommission); // => 10% 								

		
		// Transfer the 5% commission to the Dev
		devFeeAddress.transfer(devFee); // => 5% 
		
		//The hero will be leveled up after new purchase
		heroes[_heroId].currentLevel +=1;

		// Update the hero owner and set the new price (2X)
		heroes[_heroId].ownerAddress = msg.sender;
		heroes[_heroId].currentPrice = mul(heroes[_heroId].currentPrice, 2);
	}
	
	/*
	This function will be used to update the details of DBZ hero details by the contract creator
	*/
	function updateDBZHeroDetails(uint _heroId, string _heroName,address _ownerAddress, address _newDBZHeroOwnerAddress, uint _currentLevel) public onlyContractCreator{
	    require(heroes[_heroId].ownerAddress != _newDBZHeroOwnerAddress);
		heroes[_heroId].heroName = _heroName;		
		heroes[_heroId].ownerAddress = _ownerAddress;
	    heroes[_heroId].DBZHeroOwnerAddress = _newDBZHeroOwnerAddress;
	    heroes[_heroId].currentLevel = _currentLevel;
	}
	
	/*
	This function can be used by the owner of a hero to modify the price of its hero.
	The hero owner can make the price lesser than the current price only.
	*/
	function modifyCurrentHeroPrice(uint _heroId, uint256 _newPrice) public {
	    require(_newPrice > 0);
	    require(heroes[_heroId].ownerAddress == msg.sender);
	    require(_newPrice < heroes[_heroId].currentPrice);
	    heroes[_heroId].currentPrice = _newPrice;
	}
	
	// This function will return all of the details of the Tournament of Power heroes
	function getHeroDetails(uint _heroId) public view returns (
        string heroName,
        address ownerAddress,
        address DBZHeroOwnerAddress,
        uint256 currentPrice,
        uint currentLevel
    ) {
        Hero storage _hero = heroes[_heroId];

        heroName = _hero.heroName;
        ownerAddress = _hero.ownerAddress;
        DBZHeroOwnerAddress = _hero.DBZHeroOwnerAddress;
        currentPrice = _hero.currentPrice;
        currentLevel = _hero.currentLevel;
    }
    
    // This function will return only the price of a specific hero
    function getHeroCurrentPrice(uint _heroId) public view returns(uint256) {
        return(heroes[_heroId].currentPrice);
    }
    
    // This function will return only the price of a specific hero
    function getHeroCurrentLevel(uint _heroId) public view returns(uint256) {
        return(heroes[_heroId].currentLevel);
    }
    
    // This function will return only the owner address of a specific hero
    function getHeroOwner(uint _heroId) public view returns(address) {
        return(heroes[_heroId].ownerAddress);
    }
    
    // This function will return only the DBZ owner address of a specific hero
    function getHeroDBZHeroAddress(uint _heroId) public view returns(address) {
        return(heroes[_heroId].DBZHeroOwnerAddress);
    }
    
    // This function will return only Tournament of Power total prize
    function getTotalPrize() public view returns(uint256) {
        return this.balance;
    }
    
    /**
    @dev Multiplies two numbers, throws on overflow. => From the SafeMath library
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    @dev Integer division of two numbers, truncating the quotient. => From the SafeMath library
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
	// This function will be used to add a new hero by the contract creator
	function addHero(string _heroName, address _ownerAddress, address _DBZHeroOwnerAddress, uint256 _currentPrice, uint _currentLevel) public onlyContractCreator {
        heroes.push(Hero(_heroName,_ownerAddress,_DBZHeroOwnerAddress,_currentPrice,_currentLevel));
    }
     
    /*
	This function will be used by the contract creator to generate 5 heroes ID randomly out of 55 heroes
	and it can be generated only once and cannot be altered at all even by contractCreator
	*/   
    function getWinner() public onlyContractCreator returns (uint256[]) {
        uint i;
		
		//Loop to generate 5 random hero IDs from 55 heroes	
		for(i=0;i<=4;i++){
		    //Block timestamp and number used to generate the random number
			winners.push(uint256(sha256(block.timestamp, block.number-i-1)) % heroMax);
		}
		
		return winners;
    }

    // This function will return only the winner&#39;s hero id
    function getWinnerDetails(uint _winnerId) public view returns(uint256) {
        return(winners[_winnerId]);
    }
    
    /*
	This function can be used by the contractCreator to start the payout to the lucky 5 winners
	The payout will be initiated in a week time
	*/
    function payoutWinners() public onlyContractCreator {
        //Assign 20% of total contract eth
        uint256 TotalPrize20PercentShare = (this.balance/5);
        uint i;
			for(i=0;i<=4;i++){
			    // Get the hero ID from getWinnerDetails function - Randomly generated
			    uint _heroID = getWinnerDetails(i);
			    // Assign the owner address of hero ID - Randomly generated
			    address winner = heroes[_heroID].ownerAddress;
			    
			    if(winner != address(0)){
			     // Transfer the 20% of total contract eth to each winner (5 winners in total)  
                 winner.transfer(TotalPrize20PercentShare);			       
			    }
			    
			    // Reset the winner&#39;s address after payout for next loop
			    winner = address(0);
			}
    }
    
}