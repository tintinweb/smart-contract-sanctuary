pragma solidity ^0.4.24;

contract CryptoTomatoes {
 
		uint256 public TIME_TO_MAKE_TOMATOES = 21600; //6 hours

		address public ownerAddress;
		
		bool public getFree = false;
		uint public needToGetFree = 0.001 ether;
		uint256 public STARTING_SEEDS = 500; 
		
		mapping (address => uint256) public ballanceTomatoes; 
		mapping (address => uint256) public claimedSeeds; 
		mapping (address => uint256) public lastEvent; 
		mapping (address => address) public referrals; 
		
		mapping (address => uint256) public totalIn;
		mapping (address => uint256) public totalOut;
		
		uint256 public marketSeeds;
		uint256 PSN = 10000; 
		uint256 PSNH = 5000; 

		constructor() public {
			ownerAddress = msg.sender;
			marketSeeds = 10000000;
		}
		
		modifier onlyOwner() {
		require(msg.sender == ownerAddress);
		_;
		}
		
		function makeTomatoes(address ref) public {
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 seedsUsed = getMySeeds();
        uint256 newTomatos = SafeMath.div(seedsUsed, TIME_TO_MAKE_TOMATOES);
        ballanceTomatoes[msg.sender] = SafeMath.add(ballanceTomatoes[msg.sender], newTomatos);
        claimedSeeds[msg.sender] = 0;
        lastEvent[msg.sender] = now;
        claimedSeeds[referrals[msg.sender]] = SafeMath.add(claimedSeeds[referrals[msg.sender]], SafeMath.div(seedsUsed, 5)); 
        marketSeeds = SafeMath.add(marketSeeds, SafeMath.div(seedsUsed, 10));
		}

		function sellSeeds() public {

        uint256 seedsCount = getMySeeds();
        uint256 seedsValue = calculateSeedSell(seedsCount);
        uint256 fee = devFee(seedsValue);
        ballanceTomatoes[msg.sender] = SafeMath.mul(SafeMath.div(ballanceTomatoes[msg.sender], 3), 2);
        claimedSeeds[msg.sender] = 0;
        lastEvent[msg.sender] = now;
        marketSeeds = SafeMath.add(marketSeeds, seedsCount);
		totalOut[msg.sender] = SafeMath.add(totalOut[msg.sender], seedsValue);
        ownerAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(seedsValue, fee));
    }
	
		uint256 public gamers = 0;
		
		function getGamers() public view returns (uint256){
			return gamers;
		}

		function buySeeds() public payable {

        uint256 seedsBought = calculateSeedBuy(msg.value, SafeMath.sub(this.balance, msg.value));
        seedsBought = SafeMath.sub(seedsBought, devFee(seedsBought));
        claimedSeeds[msg.sender] = SafeMath.add(claimedSeeds[msg.sender], seedsBought);
		if (totalIn[msg.sender] == 0){
			gamers+=1;
		}
		totalIn[msg.sender] = SafeMath.add(totalIn[msg.sender], msg.value);
        ownerAddress.transfer(devFee(msg.value));
    }
	


		function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }

		function calculateSeedSell(uint256 seeds) public view returns(uint256) {
        return calculateTrade(seeds, marketSeeds, this.balance);
    }

		function calculateSeedBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketSeeds);
    }

		function calculateSeedBuySimple(uint256 eth) public view returns(uint256) {
        return calculateSeedBuy(eth, this.balance);
    }

		function devFee(uint256 amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, 4), 100); //4%
    }
	
		function setTIME_TO_MAKE_TOMATOES(uint256 _newTime) public onlyOwner{
		TIME_TO_MAKE_TOMATOES = _newTime;
	}
	
		function setGetFree(bool newGetFree) public onlyOwner {
		getFree = newGetFree;
	}
		
		function setNeedToGetFree(uint newNeedToGetFree) public onlyOwner {
		needToGetFree = newNeedToGetFree;
	}

		function getFreeSeeds() public payable {
		require(getFree);
        require(msg.value == needToGetFree);
        ownerAddress.transfer(msg.value);
        require(ballanceTomatoes[msg.sender] == 0);
        lastEvent[msg.sender] = now;
        ballanceTomatoes[msg.sender] = STARTING_SEEDS;
    }
	
		function setStartingSeeds(uint256 NEW_STARTING_SEEDS) public onlyOwner {
		STARTING_SEEDS = NEW_STARTING_SEEDS;
	}

		function getBalance() public view returns(uint256) {
        return this.balance;
    }

		function getMyTomatoes() public view returns(uint256) {
        return ballanceTomatoes[msg.sender];
    }

		
		function getTotalIn(address myAddress) public view returns(uint256) {
			return totalIn[myAddress];
		}
		
		function getTotalOut(address myAddress) public view returns(uint256) {
			return totalOut[myAddress];
		}


		function getMySeeds() public view returns(uint256) { 
        return SafeMath.add(claimedSeeds[msg.sender], getSeedsSinceLastEvent(msg.sender));
    }

		function getSeedsSinceLastEvent(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(TIME_TO_MAKE_TOMATOES, SafeMath.sub(now, lastEvent[adr]));
        return SafeMath.mul(secondsPassed, ballanceTomatoes[adr]);
    }

		function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
	
}

library SafeMath {

		  /**
		  * @dev Multiplies two numbers, throws on overflow.
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
		  * @dev Integer division of two numbers, truncating the quotient.
		  */
		  function div(uint256 a, uint256 b) internal pure returns (uint256) {
			// assert(b > 0); // Solidity automatically throws when dividing by 0
			uint256 c = a / b;
			// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
			return c;
		  }

		  /**
		  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
		  */
		  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
			assert(b <= a);
			return a - b;
		  }

		  /**
		  * @dev Adds two numbers, throws on overflow.
		  */
		  function add(uint256 a, uint256 b) internal pure returns (uint256) {
			uint256 c = a + b;
			assert(c >= a);
			return c;
		  }
}