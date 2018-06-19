pragma solidity 0.4.24;


/**
 * 
 * This contract is used to set admin to the contract  which has some additional features such as minting , burning etc
 * 
 */
    contract Owned {
        address public owner;

        function owned() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
        
        /* This function is used to transfer adminship to new owner
         * @param  _newOwner - address of new admin or owner        
         */

        function transferOwnership(address _newOwner) onlyOwner public {
            owner = _newOwner;
        }          
    }

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 This is interface to transfer Railz tokens , created by Railz token contract
 */
interface RailzToken {
    function transfer(address _to, uint256 _value) public returns (bool);
}


/**
 * This is the main Railz Token Sale contract
 */
contract RailzTokenSale is Owned {
	using SafeMath for uint256;

	mapping (address=> uint256) contributors;
	mapping (address=> uint256) public tokensAllocated;
    
	// start and end timestamps when contributions are allowed  (both inclusive)
	uint256 public presalestartTime =1528099200 ;     //4th June 8:00 am UTC
	uint256 public presaleendTime = 1530489599;       //1st July 23:59 pm UTC
	uint256 public publicsalestartTime = 1530518400;  //2nd July 8:00 am UTC
	uint256 public publicsalesendTime = 1532908799;   //29th July 23:59 pm UTC


	//token caps for each round
	uint256 public presalesCap = 120000000 * (1e18);
	uint256 public publicsalesCap = 350000000 * (1e18);

	//token price for each round
	uint256 public presalesTokenPriceInWei =  80000000000000 ; // 0.00008 ether;
	uint256 public publicsalesTokenPriceInWei = 196000000000000 ;// 0.000196 ether;

	// address where all funds collected from token sale are stored , this will ideally be address of MutliSig wallet
	address wallet;

	// amount of raised money in wei
	uint256 public weiRaised=0;

	//amount of tokens sold
	uint256 public numberOfTokensAllocated=0;

	// maximum gas price for contribution transactions - 60 GWEI
	uint256 public maxGasPrice = 60000000000  wei;  

	// The token being sold
	RailzToken public token;

	bool hasPreTokenSalesCapReached = false;
	bool hasTokenSalesCapReached = false;

	// events for funds received and tokens
	event ContributionReceived(address indexed contributor, uint256 value, uint256 numberOfTokens);
	event TokensTransferred(address indexed contributor, uint256 numberOfTokensTransferred);
	event ManualTokensTransferred(address indexed contributor, uint256 numberOfTokensTransferred);
	event PreTokenSalesCapReached(address indexed contributor);
	event TokenSalesCapReached(address indexed contributor);

	function RailzTokenSale(RailzToken _addressOfRewardToken, address _wallet) public {        
  		require(presalestartTime >= now); 
  		require(_wallet != address(0));   
        
  		token = RailzToken (_addressOfRewardToken);
  		wallet = _wallet;
		owner = msg.sender;
	}

	// verifies that the gas price is lower than max gas price
	modifier validGasPrice() {
		assert(tx.gasprice <= maxGasPrice);
		_;
	}

	// fallback function  used to buy tokens , this function is called when anyone sends ether to this contract
	function ()  payable public validGasPrice {  
		require(msg.sender != address(0));                      //contributor&#39;s address should not be zero00/80
		require(msg.value != 0);                                //amount should be greater then zero            
        require(msg.value>=0.1 ether);                          //minimum contribution is 0.1 eth
		require(isContributionAllowed());                       //Valid time of contribution and cap has not been reached 11
	
		// Add to mapping of contributor
		contributors[msg.sender] = contributors[msg.sender].add(msg.value);
		weiRaised = weiRaised.add(msg.value);
		uint256 numberOfTokens = 0;

		//calculate number of tokens to be given
		if (isPreTokenSaleActive()) {
			numberOfTokens = msg.value/presalesTokenPriceInWei;
            numberOfTokens = numberOfTokens * (1e18);
			require((numberOfTokens + numberOfTokensAllocated) <= presalesCap);			//Check whether remaining tokens are greater than tokens to allocate

			tokensAllocated[msg.sender] = tokensAllocated[msg.sender].add(numberOfTokens);
			numberOfTokensAllocated = numberOfTokensAllocated.add(numberOfTokens);
			
			//forward fund received to Railz multisig Account
		    forwardFunds(); 

			//Notify server that an contribution has been received
			emit ContributionReceived(msg.sender, msg.value, numberOfTokens);

		} else if (isTokenSaleActive()) {
			numberOfTokens = msg.value/publicsalesTokenPriceInWei;
			numberOfTokens = numberOfTokens * (1e18);
			require((numberOfTokens + numberOfTokensAllocated) <= (presalesCap + publicsalesCap));	//Check whether remaining tokens are greater than tokens to allocate

			tokensAllocated[msg.sender] = tokensAllocated[msg.sender].add(numberOfTokens);
			numberOfTokensAllocated = numberOfTokensAllocated.add(numberOfTokens);

            //forward fund received to Railz multisig Account
		    forwardFunds();

			//Notify server that an contribution has been received
		    emit ContributionReceived(msg.sender, msg.value, numberOfTokens);
		}        

		// check if hard cap has been reached or not , if it has reached close the contract
		checkifCapHasReached();
	}

	/**
	* This function is used to check if an contribution is allowed or not
	*/
	function isContributionAllowed() public view returns (bool) {    
		if (isPreTokenSaleActive())
			return  (!hasPreTokenSalesCapReached);
		else if (isTokenSaleActive())
			return (!hasTokenSalesCapReached);
		else
			return false;
	}

	// send ether to the fund collection wallet  , this ideally would be an multisig wallet
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}

	//Pre Token Sale time
	function isPreTokenSaleActive() internal view returns (bool) {
		return ((now >= presalestartTime) && (now <= presaleendTime));  
	}

	//Token Sale time
	function isTokenSaleActive() internal view returns (bool) {
		return (now >= (publicsalestartTime) && (now <= publicsalesendTime));  
	}

	// Called by owner when preico token cap has been reached
	function preTokenSalesCapReached() internal {
		hasPreTokenSalesCapReached = true;
		emit PreTokenSalesCapReached(msg.sender);
	}

	// Called by owner when ico token cap has been reached
	function tokenSalesCapReached() internal {
		hasTokenSalesCapReached = true;
		emit TokenSalesCapReached(msg.sender);
	}

	//This function is used to transfer token to contributor after successful audit
	function transferToken(address _contributor) public onlyOwner {
		require(_contributor != 0);
        uint256 numberOfTokens = tokensAllocated[_contributor];
        tokensAllocated[_contributor] = 0;    
		token.transfer(_contributor, numberOfTokens);
		emit TokensTransferred(_contributor, numberOfTokens);
	}


	//This function is used to do bulk transfer token to contributor after successful audit manually
	 function manualBatchTransferToken(uint256[] amount, address[] wallets) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            token.transfer(wallets[i], amount[i]);
			emit TokensTransferred(wallets[i], amount[i]);
        }
    }

	//This function is used to do bulk transfer token to contributor after successful audit
	 function batchTransferToken(address[] wallets) public onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
			uint256 amountOfTokens = tokensAllocated[wallets[i]];
			require(amountOfTokens > 0);
			tokensAllocated[wallets[i]]=0;
            token.transfer(wallets[i], amountOfTokens);
			emit TokensTransferred(wallets[i], amountOfTokens);
        }
    }
	
	//This function is used refund contribution of a contributor in case soft cap is not reached or audit of an contributor failed
	function refundContribution(address _contributor, uint256 _weiAmount) public onlyOwner returns (bool) {
		require(_contributor != 0);                                                                                                                                     
		if (!_contributor.send(_weiAmount)) {
			return false;
		} else {
			contributors[_contributor] = 0;
			return true;
		}
	}

	// This function check whether ICO is currently active or not
    function checkifCapHasReached() internal {
    	if (isPreTokenSaleActive() && (numberOfTokensAllocated > presalesCap))  
        	hasPreTokenSalesCapReached = true;
     	else if (isTokenSaleActive() && (numberOfTokensAllocated > (presalesCap + publicsalesCap)))     
        	hasTokenSalesCapReached = true;     	
    }

  	//This function allows the owner to update the gas price limit public onlyOwner     
    function setGasPrice(uint256 _gasPrice) public onlyOwner {
    	maxGasPrice = _gasPrice;
    }
}