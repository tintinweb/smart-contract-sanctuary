pragma solidity ^0.4.18;

/**
 *  @title Smart City Crowdsale contract https://www.smartcitycoin.io
 */


contract SmartCityToken {
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {}
    
    function setTokenStart(uint256 _newStartTime) public {}

    function burn() public {}
}

contract SmartCityCrowdsale {
    using SafeMath for uint256;

	/// state
    SmartCityToken public token; // Token Contract
	
	address public owner; // Owner address

	mapping (address => bool) whitelist; // users whithelist

    mapping(address => uint256) public balances; // the array of users along with amounts invested
	
	mapping(address => uint256) public purchases; // the array of users and tokens purchased

    uint256 public raisedEth; // Amount of Ether raised

    uint256 public startTime; // Crowdale start time

    uint256 public tokensSoldTotal = 0; // Sold Tolkens counter

    bool public crowdsaleEnded = false; // if the Campaign is over
	
	bool public paused = false; // if the Campaign is paused

    uint256 public positionPrice = 5730 finney; // Initially 1 investement position costs 5.73 ETH, might be changed by owner afterwards
	
	uint256 public usedPositions = 0; // Initial number of used investment positions
	
	uint256 public availablePositions = 100; // Initial number of open investment positions

    address walletAddress; // address of the wallet contract storing the funds

	/// constants
    uint256 constant public tokensForSale = 164360928100000; // Total amount of tokens allocated for the Crowdsale

	uint256 constant public weiToTokenFactor = 10000000000000;

	uint256 constant public investmentPositions = 4370; // Total number of investment positions

    uint256 constant public investmentLimit = 18262325344444; // the maximum amount of Ether an address is allowed to invest - limited to 1/9 of tokens allocated for sale

	/// events
    event FundTransfer(address indexed _investorAddr, uint256 _amount, uint256 _amountRaised); // fired on transfering funds from investors
	
	event Granted(address indexed party); // user is added to the whitelist
	
	event Revoked(address indexed party); // user is removed from the whitelist
	
	event Ended(uint256 raisedAmount); // Crowdsale is ended

	/// modifiers
	modifier onlyWhenActive() {
		require(now >= startTime && !crowdsaleEnded && !paused);
		_;
	}
	
	modifier whenPositionsAvailable() {
		require(availablePositions > 0);
		_;
	}

	modifier onlyWhitelisted(address party) {
		require(whitelist[party]);
		_; 
	}
	
	modifier onlyNotOnList(address party) {
		require(!whitelist[party]);
		_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

    /**
     *  @dev Crowdsale Contract initialization
     *  @param _owner address Token owner address
     *  @param _tokenAddress address Crowdsale end time
     *  @param _walletAddress address Beneficiary address where the funds are collected
     *  @param _start uint256 Crowdsale Start Time
     */
    function SmartCityCrowdsale (
            address _tokenAddress,
            address _owner,
            address _walletAddress,
            uint256 _start) public {

        owner = _owner;
        token = SmartCityToken(_tokenAddress);
        walletAddress = _walletAddress;

        startTime = _start; // Crowdsale Start Time
    }

    /**
     *  @dev Investment can be done just by sending Ether to Crowdsale Contract
     */
    function() public payable {
        invest();
    }

    /**
     *  @dev Make an investment
     */
    function invest() public payable
				onlyWhitelisted(msg.sender)
				whenPositionsAvailable
				onlyWhenActive
	{
		address _receiver = msg.sender;
        uint256 amount = msg.value; // Transaction value in Wei

        var (positionsCnt, tokensCnt) = getPositionsAndTokensCnt(amount); 

        require(positionsCnt > 0 && positionsCnt <= availablePositions && tokensCnt > 0);

		require(purchases[_receiver].add(tokensCnt) <= investmentLimit); // Check the investment limit is not exceeded

        require(tokensSoldTotal.add(tokensCnt) <= tokensForSale);

        walletAddress.transfer(amount); // Send funds to the Wallet
		
        balances[_receiver] = balances[_receiver].add(amount); // Add the amount invested to Investor&#39;s ballance
		purchases[_receiver] = purchases[_receiver].add(tokensCnt); // Add tokens to Investor&#39;s purchases
        raisedEth = raisedEth.add(amount); // Increase raised funds counter
		availablePositions = availablePositions.sub(positionsCnt);
		usedPositions = usedPositions.add(positionsCnt);
        tokensSoldTotal = tokensSoldTotal.add(tokensCnt); // Increase sold CITY counter

        require(token.transferFrom(owner, _receiver, tokensCnt)); // Transfer CITY purchased to Investor

        FundTransfer(_receiver, amount, raisedEth);
		
		if (usedPositions == investmentPositions) { // Sold Out
			token.burn();
			crowdsaleEnded = true; // mark Crowdsale ended
			
			Ended(raisedEth);
		}
    }
    
    /**
     *  @dev Calculate the amount of Tokens purchased based on the value sent and current Token price
     *  @param _value uint256 Amount invested
     */
    function getPositionsAndTokensCnt(uint256 _value) public constant onlyWhenActive returns(uint256 positionsCnt, uint256 tokensCnt) {
			if (_value % positionPrice != 0 || usedPositions >= investmentPositions) {
				return(0, 0);
			}
			else {
				uint256 purchasedPositions = _value.div(positionPrice);
				uint256 purchasedTokens = ((tokensForSale.sub(tokensSoldTotal)).mul(purchasedPositions)).div(investmentPositions.sub(usedPositions));
				return(purchasedPositions, purchasedTokens);
			}
    }

	function getMinPurchase() public constant onlyWhenActive returns(uint256 minPurchase) {
		return positionPrice;
	}
	
	/// Owner functions
	
    /**
     *  @dev To increace/reduce number of Investment Positions released for sale
     */
    function setAvailablePositions(uint256 newAvailablePositions) public onlyOwner {
        require(newAvailablePositions <= investmentPositions.sub(usedPositions));
		availablePositions = newAvailablePositions;
    }
	
	/**
     *  @dev Allows Investment Position price changes
     */
    function setPositionPrice(uint256 newPositionPrice) public onlyOwner {
        require(newPositionPrice > 0);
		positionPrice = newPositionPrice;
    }
	
	 /**
     *  @dev Emergency function to pause Crowdsale.
     */
    function setPaused(bool _paused) public onlyOwner { paused = _paused; }

	/**
    *   @dev Emergency function to drain the contract of any funds.
    */
	function drain() public onlyOwner { walletAddress.transfer(this.balance); }
	
	/**
    *   @dev Function to manually finalize Crowdsale.
    */
	function endCrowdsale() public onlyOwner {
		usedPositions = investmentPositions;
		availablePositions = 0;
		token.burn(); // burn all unsold tokens
		crowdsaleEnded = true; // mark Crowdsale ended
		
		Ended(raisedEth);
	}

	/// Whitelist functions
	function grant(address _party) public onlyOwner onlyNotOnList(_party)
	{
		whitelist[_party] = true;
		Granted(_party);
	}

	function revoke(address _party) public onlyOwner onlyWhitelisted(_party)
	{
		whitelist[_party] = false;
		Revoked(_party);
	}
	
	function massGrant(address[] _parties) public onlyOwner
	{
		uint len = _parties.length;
		
		for (uint i = 0; i < len; i++) {
			whitelist[_parties[i]] = true;
			Granted(_parties[i]);
		}
	}

	function massRevoke(address[] _parties) public onlyOwner
	{
		uint len = _parties.length;
		
		for (uint i = 0; i < len; i++) {
			whitelist[_parties[i]] = false;
			Revoked(_parties[i]);
		}
	}

	function isWhitelisted(address _party) public constant returns (bool) {
		return whitelist[_party];
	}
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    uint256 c = a / b;
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
	
    /**
    *            CITY 2.0 token by www.SmartCityCoin.io
    * 
    *          .ossssss:                      `+sssss`      
    *         ` +ssssss+` `.://++++++//:.`  .osssss+       
    *            /sssssssssssssssssssssssss+ssssso`        
    *             -sssssssssssssssssssssssssssss+`         
    *            .+sssssssss+:--....--:/ossssssss+.        
    *          `/ssssssssssso`         .sssssssssss/`      
    *         .ossssss+sssssss-       :sssss+:ossssso.     
    *        `ossssso. .ossssss:    `/sssss/  `/ssssss.    
    *        ossssso`   `+ssssss+` .osssss:     /ssssss`   
    *       :ssssss`      /sssssso:ssssso.       +o+/:-`   
    *       osssss+        -sssssssssss+`                  
    *       ssssss:         .ossssssss/                    
    *       osssss/          `+ssssss-                     
    *       /ssssso           :ssssss                      
    *       .ssssss-          :ssssss                      
    *        :ssssss-         :ssssss          `           
    *         /ssssss/`       :ssssss        `/s+:`        
    *          :sssssso:.     :ssssss      ./ssssss+`      
    *           .+ssssssso/-.`:ssssss``.-/osssssss+.       
    *             .+ssssssssssssssssssssssssssss+-         
    *               `:+ssssssssssssssssssssss+:`           
    *                  `.:+osssssssssssso+:.`              
    *                        `/ssssss.`                    
    *                         :ssssss                      
    */