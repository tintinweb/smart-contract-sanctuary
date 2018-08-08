pragma solidity ^0.4.20;

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

contract Ownable {
	address public owner;
	address public controller;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyController() {
		require(msg.sender == controller);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
	
	function setControler(address _controller) public onlyOwner {
		controller = _controller;
	}
}

contract OwnableToken {
	address public owner;
	address public minter;
	address public burner;
	address public controller;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function OwnableToken() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyMinter() {
		require(msg.sender == minter);
		_;
	}
	
	modifier onlyBurner() {
		require(msg.sender == burner);
		_;
	}
	modifier onlyController() {
		require(msg.sender == controller);
		_;
	}
  
	modifier onlyPayloadSize(uint256 numwords) {                                       
		assert(msg.data.length == numwords * 32 + 4);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
	
	function setMinter(address _minterAddress) public onlyOwner {
		minter = _minterAddress;
	}
	
	function setBurner(address _burnerAddress) public onlyOwner {
		burner = _burnerAddress;
	}
	
	function setControler(address _controller) public onlyOwner {
		controller = _controller;
	}
}

contract KYCControl is OwnableToken {
	event KYCApproved(address _user, bool isApproved);
	mapping(address => bool) public KYCParticipants;
	
	function isKYCApproved(address _who) view public returns (bool _isAprroved){
		return KYCParticipants[_who];
	}

	function approveKYC(address _userAddress) onlyController public {
		KYCParticipants[_userAddress] = true;
		emit KYCApproved(_userAddress, true);
	}
}

contract VernamCrowdSaleToken is OwnableToken, KYCControl {
	using SafeMath for uint256;
	
    event Transfer(address indexed from, address indexed to, uint256 value);
    
	/* Public variables of the token */
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public _totalSupply;
	
	/*Private Variables*/
	uint256 constant POW = 10 ** 18;
	uint256 _circulatingSupply;
	
	/* This creates an array with all balances */
	mapping (address => uint256) public balances;
		
	// This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);
	event Mint(address indexed _participant, uint256 value);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function VernamCrowdSaleToken() public {
		name = "Vernam Crowdsale Token";                            // Set the name for display purposes
		symbol = "VCT";                               				// Set the symbol for display purposes
		decimals = 18;                            					// Amount of decimals for display purposes
		_totalSupply = SafeMath.mul(1000000000, POW);     			//1 Billion Tokens with 18 Decimals
		_circulatingSupply = 0;
	}
	
	function mintToken(address _participant, uint256 _mintedAmount) public onlyMinter returns (bool _success) {
		require(_mintedAmount > 0);
		require(_circulatingSupply.add(_mintedAmount) <= _totalSupply);
		KYCParticipants[_participant] = false;

        balances[_participant] =  balances[_participant].add(_mintedAmount);
        _circulatingSupply = _circulatingSupply.add(_mintedAmount);
		
		emit Transfer(0, this, _mintedAmount);
        emit Transfer(this, _participant, _mintedAmount);
		emit Mint(_participant, _mintedAmount);
		
		return true;
    }
	
	function burn(address _participant, uint256 _value) public onlyBurner returns (bool _success) {
        require(_value > 0);
		require(balances[_participant] >= _value);   							// Check if the sender has enough
		require(isKYCApproved(_participant) == true);
		balances[_participant] = balances[_participant].sub(_value);            // Subtract from the sender
		_circulatingSupply = _circulatingSupply.sub(_value);
        _totalSupply = _totalSupply.sub(_value);                      			// Updates totalSupply
		emit Transfer(_participant, 0, _value);
        emit Burn(_participant, _value);
        
		return true;
    }
  
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}
	
	function circulatingSupply() public view returns (uint256) {
		return _circulatingSupply;
	}
	
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
}

contract VernamCrowdSale is Ownable {
	using SafeMath for uint256;
	
	// After day 7 you can contribute only more than 10 ethers 
	uint constant TEN_ETHERS = 10 ether;
	// Minimum and maximum contribution amount
	uint constant minimumContribution = 100 finney;
	uint constant maximumContribution = 500 ether;
	
	// 
	uint constant FIRST_MONTH = 0;
	uint constant SECOND_MONTH = 1;
	uint constant THIRD_MONTH = 2;
	uint constant FORTH_MONTH = 3;
	uint constant FIFTH_MONTH = 4;
	uint constant SIXTH_MONTH = 5;	
	
	address public benecifiary;
	
    // Check if the crowdsale is active
	bool public isInCrowdsale;
	
	// The start time of the crowdsale
	uint public startTime;
	// The total sold tokens
	uint public totalSoldTokens;
	
	// The total contributed wei
	uint public totalContributedWei;

    // Public parameters for all the stages
	uint constant public threeHotHoursDuration = 3 hours;
	uint constant public threeHotHoursPriceOfTokenInWei = 63751115644524 wei; //0.00006375111564452380 ETH per Token // 15686 VRN per ETH
		
	uint public threeHotHoursTokensCap; 
	uint public threeHotHoursCapInWei; 
	uint public threeHotHoursEnd;

	uint public firstStageDuration = 8 days;
	uint public firstStagePriceOfTokenInWei = 85005100306018 wei;    //0.00008500510030601840 ETH per Token // 11764 VRN per ETH

	uint public firstStageEnd;
	
	uint constant public secondStageDuration = 12 days;
	uint constant public secondStagePriceOfTokenInWei = 90000900009000 wei;     //0.00009000090000900010 ETH per Token // 11111 VRN per ETH
    
	uint public secondStageEnd;
	
	uint constant public thirdStageDuration = 41 days;
	uint constant public thirdStagePriceOfTokenInWei = 106258633513973 wei;          //0.00010625863351397300 ETH per Token // 9411 VRN per ETH
	
	uint constant public thirdStageDiscountPriceOfTokenInWei = 95002850085503 wei;  //0.00009500285008550260 ETH per Token // 10526 VRN per ETH
	
	uint public thirdStageEnd;
	
	uint constant public TOKENS_HARD_CAP = 500000000000000000000000000; // 500 000 000 with 18 decimals
	
	// 18 decimals
	uint constant POW = 10 ** 18;
	
	// Constants for Realase Three Hot Hours
	uint constant public LOCK_TOKENS_DURATION = 30 days;
	uint public firstMonthEnd;
	uint public secondMonthEnd;
	uint public thirdMonthEnd;
	uint public fourthMonthEnd;
	uint public fifthMonthEnd;
    
    // Mappings
	mapping(address => uint) public contributedInWei;
	mapping(address => uint) public threeHotHoursTokens;
	mapping(address => mapping(uint => uint)) public getTokensBalance;
	mapping(address => mapping(uint => bool)) public isTokensTaken;
	mapping(address => bool) public isCalculated;
	
	VernamCrowdSaleToken public vernamCrowdsaleToken;
	
	// Modifiers
    modifier afterCrowdsale() {
        require(block.timestamp > thirdStageEnd);
        _;
    }
    
    modifier isAfterThreeHotHours {
	    require(block.timestamp > threeHotHoursEnd);
	    _;
	}
	
    // Events
    event CrowdsaleActivated(uint startTime, uint endTime);
    event TokensBought(address participant, uint weiAmount, uint tokensAmount);
    event ReleasedTokens(uint _amount);
    event TokensClaimed(address _participant, uint tokensToGetFromWhiteList);
    
    /** @dev Constructor 
      * @param _benecifiary 
      * @param _vernamCrowdSaleTokenAddress The address of the crowdsale token.
      * 
      */
	constructor(address _benecifiary, address _vernamCrowdSaleTokenAddress) public {
		benecifiary = _benecifiary;
		vernamCrowdsaleToken = VernamCrowdSaleToken(_vernamCrowdSaleTokenAddress);
        
		isInCrowdsale = false;
	}
	
	/** @dev Function which activates the crowdsale 
      * Only the owner can call the function
      * Activates the threeHotHours and the whole crowdsale
      * Set the duration of crowdsale stages 
      * Set the tokens and wei cap of crowdsale stages 
      * Set the duration in which the tokens bought in threeHotHours will be locked
      */
	function activateCrowdSale() public onlyOwner {
	    		
		setTimeForCrowdsalePeriods();
		
		threeHotHoursTokensCap = 100000000000000000000000000;
		threeHotHoursCapInWei = threeHotHoursPriceOfTokenInWei.mul((threeHotHoursTokensCap).div(POW));
	    
		timeLock();
		
		isInCrowdsale = true;
		
	    emit CrowdsaleActivated(startTime, thirdStageEnd);
	}
	
	/** @dev Fallback function.
      * Provides functionality for person to buy tokens.
      */
	function() public payable {
		buyTokens(msg.sender,msg.value);
	}
	
	/** @dev Buy tokens function
      * Provides functionality for person to buy tokens.
      * @param _participant The investor which want to buy tokens.
      * @param _weiAmount The wei amount which the investor want to contribute.
      * @return success Is the buy tokens function called successfully.
      */
	function buyTokens(address _participant, uint _weiAmount) public payable returns(bool success) {
	    // Check if the crowdsale is active
		require(isInCrowdsale == true);
		// Check if the wei amount is between minimum and maximum contribution amount
		require(_weiAmount >= minimumContribution);
		require(_weiAmount <= maximumContribution);
		
		// Vaidates the purchase 
		// Check if the _participant address is not null and the weiAmount is not zero
		validatePurchase(_participant, _weiAmount);

		uint currentLevelTokens;
		uint nextLevelTokens;
		// Returns the current and next level tokens amount
		(currentLevelTokens, nextLevelTokens) = calculateAndCreateTokens(_weiAmount);
		uint tokensAmount = currentLevelTokens.add(nextLevelTokens);
		
		// If the hard cap is reached the crowdsale is not active anymore
		if(totalSoldTokens.add(tokensAmount) > TOKENS_HARD_CAP) {
			isInCrowdsale = false;
			return;
		}
		
		// Transfer Ethers
		benecifiary.transfer(_weiAmount);
		
		// Stores the participant&#39;s contributed wei
		contributedInWei[_participant] = contributedInWei[_participant].add(_weiAmount);
		
		// If it is in threeHotHours tokens will not be minted they will be stored in mapping threeHotHoursTokens
		if(threeHotHoursEnd > block.timestamp) {
			threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].add(currentLevelTokens);
			isCalculated[_participant] = false;
			// If we overflow threeHotHours tokens cap the tokens for the next level will not be zero
			// So we should deactivate the threeHotHours and mint tokens
			if(nextLevelTokens > 0) {
				vernamCrowdsaleToken.mintToken(_participant, nextLevelTokens);
			} 
		} else {	
			vernamCrowdsaleToken.mintToken(_participant, tokensAmount);        
		}
		
		// Store total sold tokens amount
		totalSoldTokens = totalSoldTokens.add(tokensAmount);
		
		// Store total contributed wei amount
		totalContributedWei = totalContributedWei.add(_weiAmount);
		
		emit TokensBought(_participant, _weiAmount, tokensAmount);
		
		return true;
	}
	
	/** @dev Function which gets the tokens amount for current and next level.
	  * If we did not overflow the current level cap, the next level tokens will be zero.
      * @return _currentLevelTokensAmount and _nextLevelTokensAmount Returns the calculated tokens for the current and next level
      * It is called by calculateAndCreateTokens function
      */
	function calculateAndCreateTokens(uint weiAmount) internal view returns (uint _currentLevelTokensAmount, uint _nextLevelTokensAmount) {

		if(block.timestamp < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokensCap) {
		    (_currentLevelTokensAmount, _nextLevelTokensAmount) = tokensCalculator(weiAmount, threeHotHoursPriceOfTokenInWei, firstStagePriceOfTokenInWei, threeHotHoursCapInWei);
			return (_currentLevelTokensAmount, _nextLevelTokensAmount);
		}
		
		if(block.timestamp < firstStageEnd) {
		    _currentLevelTokensAmount = weiAmount.div(firstStagePriceOfTokenInWei);
	        _currentLevelTokensAmount = _currentLevelTokensAmount.mul(POW);
	        
		    return (_currentLevelTokensAmount, 0);
		}
		
		if(block.timestamp < secondStageEnd) {		
		    _currentLevelTokensAmount = weiAmount.div(secondStagePriceOfTokenInWei);
	        _currentLevelTokensAmount = _currentLevelTokensAmount.mul(POW);
	        
		    return (_currentLevelTokensAmount, 0);
		}
		
		if(block.timestamp < thirdStageEnd && weiAmount >= TEN_ETHERS) {
		    _currentLevelTokensAmount = weiAmount.div(thirdStageDiscountPriceOfTokenInWei);
	        _currentLevelTokensAmount = _currentLevelTokensAmount.mul(POW);
	        
		    return (_currentLevelTokensAmount, 0);
		}
		
		if(block.timestamp < thirdStageEnd){	
		    _currentLevelTokensAmount = weiAmount.div(thirdStagePriceOfTokenInWei);
	        _currentLevelTokensAmount = _currentLevelTokensAmount.mul(POW);
	        
		    return (_currentLevelTokensAmount, 0);
		}
		
		revert();
	}
	
	/** @dev Realase the tokens from the three hot hours.
      */
	function release() public {
	    releaseThreeHotHourTokens(msg.sender);
	}
	
	/** @dev Realase the tokens from the three hot hours.
	  * It can be called after the end of three hot hours
      * @param _participant The investor who want to release his tokens
      * @return success Is the release tokens function called successfully.
      */
	function releaseThreeHotHourTokens(address _participant) public isAfterThreeHotHours returns(bool success) { 
	    // Check if the _participants tokens are realased
	    // If not calculate his tokens for every month and set the isCalculated to true
		if(isCalculated[_participant] == false) {
		    calculateTokensForMonth(_participant);
		    isCalculated[_participant] = true;
		}
		
		// Unlock the tokens amount for the _participant
		uint _amount = unlockTokensAmount(_participant);
		
		// Substract the _amount from the threeHotHoursTokens mapping
		threeHotHoursTokens[_participant] = threeHotHoursTokens[_participant].sub(_amount);
		
		// Mint to the _participant vernamCrowdsaleTokens
		vernamCrowdsaleToken.mintToken(_participant, _amount);        

		emit ReleasedTokens(_amount);
		
		return true;
	}
	
	/** @dev Get contributed amount in wei.
      * @return contributedInWei[_participant].
      */
	function getContributedAmountInWei(address _participant) public view returns (uint) {
        return contributedInWei[_participant];
    }
	
	/** @dev Function which calculate tokens for every month (6 months).
      * @param weiAmount Participant&#39;s contribution in wei.
      * @param currentLevelPrice Price of the tokens for the current level.
      * @param nextLevelPrice Price of the tokens for the next level.
      * @param currentLevelCap Current level cap in wei.
      * @return _currentLevelTokensAmount and _nextLevelTokensAmount Returns the calculated tokens for the current and next level
      * It is called by three hot hours
      */
      
	function tokensCalculator(uint weiAmount, uint currentLevelPrice, uint nextLevelPrice, uint currentLevelCap) internal view returns (uint _currentLevelTokensAmount, uint _nextLevelTokensAmount){
	    uint currentAmountInWei = 0;
		uint remainingAmountInWei = 0;
		uint currentLevelTokensAmount = 0;
		uint nextLevelTokensAmount = 0;
		
		// Check if the contribution overflows and you should buy tokens on next level price
		if(weiAmount.add(totalContributedWei) > currentLevelCap) {
		    remainingAmountInWei = (weiAmount.add(totalContributedWei)).sub(currentLevelCap);
		    currentAmountInWei = weiAmount.sub(remainingAmountInWei);
            
            currentLevelTokensAmount = currentAmountInWei.div(currentLevelPrice);
            nextLevelTokensAmount = remainingAmountInWei.div(nextLevelPrice); 
	    } else {
	        currentLevelTokensAmount = weiAmount.div(currentLevelPrice);
			nextLevelTokensAmount = 0;
	    }
	    currentLevelTokensAmount = currentLevelTokensAmount.mul(POW);
	    nextLevelTokensAmount = nextLevelTokensAmount.mul(POW);
		
		
		return (currentLevelTokensAmount, nextLevelTokensAmount);
	}
	
	/** @dev Function which calculate tokens for every month (6 months).
      * @param _participant The investor whose tokens are calculated.
      * It is called once from the releaseThreeHotHourTokens function
      */
	function calculateTokensForMonth(address _participant) internal {
	    // Get the max balance of the participant  
	    uint maxBalance = threeHotHoursTokens[_participant];
	    
	    // Start from 10% for the first three months
	    uint percentage = 10;
	    for(uint month = 0; month < 6; month++) {
	        // The fourth month the unlock tokens percentage is increased by 10% and for the fourth and fifth month will be 20%
	        // It will increase one more by 10% in the last month and will become 30% 
	        if(month == 3 || month == 5) {
	            percentage += 10;
	        }
	        
	        // Set the participant at which month how much he will get
	        getTokensBalance[_participant][month] = maxBalance.div(percentage);
	        
	        // Set for every month false to see the tokens for the month is not get it 
	        isTokensTaken[_participant][month] = false; 
	    }
	}
	
		
	/** @dev Function which validates if the participan is not null address and the wei amount is not zero
      * @param _participant The investor who want to unlock his tokens
      * @return _tokensAmount Tokens which are unlocked
      */
	function unlockTokensAmount(address _participant) internal returns (uint _tokensAmount) {
	    // Check if the _participant have tokens in threeHotHours stage
		require(threeHotHoursTokens[_participant] > 0);
		
		// Check if the _participant got his tokens in first month and if the time for the first month end has come 
        if(block.timestamp < firstMonthEnd && isTokensTaken[_participant][FIRST_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, FIRST_MONTH.add(1)); // First month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is in the period between first and second month end
        if(((block.timestamp >= firstMonthEnd) && (block.timestamp < secondMonthEnd)) 
            && isTokensTaken[_participant][SECOND_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, SECOND_MONTH.add(1)); // Second month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is in the period between second and third month end
        if(((block.timestamp >= secondMonthEnd) && (block.timestamp < thirdMonthEnd)) 
            && isTokensTaken[_participant][THIRD_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, THIRD_MONTH.add(1)); // Third month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is in the period between third and fourth month end
        if(((block.timestamp >= thirdMonthEnd) && (block.timestamp < fourthMonthEnd)) 
            && isTokensTaken[_participant][FORTH_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, FORTH_MONTH.add(1)); // Forth month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is in the period between forth and fifth month end
        if(((block.timestamp >= fourthMonthEnd) && (block.timestamp < fifthMonthEnd)) 
            && isTokensTaken[_participant][FIFTH_MONTH] == false) {
            // Go and get the tokens for the current month
            return getTokens(_participant, FIFTH_MONTH.add(1)); // Fifth month
        } 
        
        // Check if the _participant got his tokens in second month and if the time is after the end of the fifth month
        if((block.timestamp >= fifthMonthEnd) 
            && isTokensTaken[_participant][SIXTH_MONTH] == false) {
            return getTokens(_participant, SIXTH_MONTH.add(1)); // Last month
        }
    }
    
    /** @dev Function for getting the tokens for unlock
      * @param _participant The investor who want to unlock his tokens
      * @param _period The period for which will be unlocked the tokens
      * @return tokensAmount Returns the amount of tokens for unlocing
      */
    function getTokens(address _participant, uint _period) internal returns(uint tokensAmount) {
        uint tokens = 0;
        for(uint month = 0; month < _period; month++) {
            // Check if the tokens fot the current month unlocked
            if(isTokensTaken[_participant][month] == false) { 
                // Set the isTokensTaken to true
                isTokensTaken[_participant][month] = true;
                
                // Calculates the tokens
                tokens += getTokensBalance[_participant][month];
                
                // Set the balance for the curren month to zero
                getTokensBalance[_participant][month] = 0;
            }
        }
        
        return tokens;
    }
	
	/** @dev Function which validates if the participan is not null address and the wei amount is not zero
      * @param _participant The investor who want to buy tokens
      * @param _weiAmount The amount of wei which the investor want to contribute
      */
	function validatePurchase(address _participant, uint _weiAmount) pure internal {
        require(_participant != address(0));
        require(_weiAmount != 0);
    }
	
	 /** @dev Function which set the duration of crowdsale stages
      * Called by the activateCrowdSale function 
      */
	function setTimeForCrowdsalePeriods() internal {
		startTime = block.timestamp;
		threeHotHoursEnd = startTime.add(threeHotHoursDuration);
		firstStageEnd = threeHotHoursEnd.add(firstStageDuration);
		secondStageEnd = firstStageEnd.add(secondStageDuration);
		thirdStageEnd = secondStageEnd.add(thirdStageDuration);
	}
	
	/** @dev Function which set the duration in which the tokens bought in threeHotHours will be locked
      * Called by the activateCrowdSale function 
      */
	function timeLock() internal {
		firstMonthEnd = (startTime.add(LOCK_TOKENS_DURATION)).add(threeHotHoursDuration);
		secondMonthEnd = firstMonthEnd.add(LOCK_TOKENS_DURATION);
		thirdMonthEnd = secondMonthEnd.add(LOCK_TOKENS_DURATION);
		fourthMonthEnd = thirdMonthEnd.add(LOCK_TOKENS_DURATION);
		fifthMonthEnd = fourthMonthEnd.add(LOCK_TOKENS_DURATION);
	}
	
	function getPrice(uint256 time, uint256 weiAmount) public view returns (uint levelPrice) {

		if(time < threeHotHoursEnd && totalSoldTokens < threeHotHoursTokensCap) {
            return threeHotHoursPriceOfTokenInWei;
		}
		
		if(time < firstStageEnd) {
            return firstStagePriceOfTokenInWei;
		}
		
		if(time < secondStageEnd) {
            return secondStagePriceOfTokenInWei;
		}
		
		if(time < thirdStageEnd && weiAmount > TEN_ETHERS) {
            return thirdStageDiscountPriceOfTokenInWei;
		}
		
		if(time < thirdStageEnd){		
		    return thirdStagePriceOfTokenInWei;
		}
	}
	
	function setBenecifiary(address _newBenecifiary) public onlyOwner {
		benecifiary = _newBenecifiary;
	}
}
contract OwnableController {
	address public owner;
	address public KYCTeam;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	modifier onlyKYCTeam() {
		require(msg.sender == KYCTeam);
		_;
	}
	
	function setKYCTeam(address _KYCTeam) public onlyOwner {
		KYCTeam = _KYCTeam;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}
contract Controller is OwnableController {
    
    VernamCrowdSale public vernamCrowdSale;
	VernamCrowdSaleToken public vernamCrowdsaleToken;
	VernamToken public vernamToken;
	
	mapping(address => bool) public isParticipantApproved;
    
    event Refunded(address _to, uint amountInWei);
	event Convert(address indexed participant, uint tokens);
    
    function Controller(address _crowdsaleAddress, address _vernamCrowdSaleToken) public {
        vernamCrowdSale = VernamCrowdSale(_crowdsaleAddress);
		vernamCrowdsaleToken = VernamCrowdSaleToken(_vernamCrowdSaleToken);
    }
    
    function releaseThreeHotHourTokens() public {
        vernamCrowdSale.releaseThreeHotHourTokens(msg.sender);
    }
	
	function convertYourTokens() public {
		convertTokens(msg.sender);
	}
	
	function convertTokens(address _participant) public {
	    bool isApproved = vernamCrowdsaleToken.isKYCApproved(_participant);
		if(isApproved == false && isParticipantApproved[_participant] == true){
			vernamCrowdsaleToken.approveKYC(_participant);
			isApproved = vernamCrowdsaleToken.isKYCApproved(_participant);
		}
	    
	    require(isApproved == true);
	    
		uint256 tokens = vernamCrowdsaleToken.balanceOf(_participant);
		
		require(tokens > 0);
		vernamCrowdsaleToken.burn(_participant, tokens);
		vernamToken.transfer(_participant, tokens);
		
		emit Convert(_participant, tokens);
	}
	
	function approveKYC(address _participant) public onlyKYCTeam returns(bool _success) {
	    vernamCrowdsaleToken.approveKYC(_participant);
		isParticipantApproved[_participant] = vernamCrowdsaleToken.isKYCApproved(_participant);
	    return isParticipantApproved[_participant];
	}
	
	function setVernamOriginalToken(address _vernamToken) public onlyOwner {
		vernamToken = VernamToken(_vernamToken);
	}
}

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract VernamToken is ERC20 {
	using SafeMath for uint256;
	
	/* Public variables of the token */
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public _totalSupply;
		
	modifier onlyPayloadSize(uint256 numwords) {                                         //https://blog.golemproject.net/how-to-find-10m-by-just-reading-blockchain-6ae9d39fcd95
		assert(msg.data.length == numwords * 32 + 4);
		_;
	}
	
	/* This creates an array with all balances */
	mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function VernamToken(uint256 _totalSupply_) public {
		name = "Vernam Token";                                   	// Set the name for display purposes
		symbol = "VRN";                               				// Set the symbol for display purposes
		decimals = 18;                            					// Amount of decimals for display purposes
		_totalSupply = _totalSupply_;     			//1 Billion Tokens with 18 Decimals
		balances[msg.sender] = _totalSupply_;
	}

	function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool _success) {
		return _transfer(msg.sender, _to, _value);
	}
	
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(_value <= allowed[_from][msg.sender]);     								// Check allowance
        
		_transfer(_from, _to, _value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		
		return true;
    }
	
	/* Internal transfer, only can be called by this contract */
	function _transfer(address _from, address _to, uint256 _value) internal returns (bool _success) {
		require (_to != address(0x0));														// Prevent transfer to 0x0 address.
		require(_value >= 0);
		require (balances[_from] >= _value);                								// Check if the sender has enough
		require (balances[_to].add(_value) > balances[_to]); 								// Check for overflows
		
		uint256 previousBalances = balances[_from].add(balances[_to]);					// Save this for an assertion in the future
		
		balances[_from] = balances[_from].sub(_value);        				   				// Subtract from the sender
		balances[_to] = balances[_to].add(_value);                            				// Add the same to the recipient
		
		emit Transfer(_from, _to, _value);
		
		// Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances); //add safeMath
		
		return true;
	}

	function increaseApproval(address _spender, uint256 _addedValue) onlyPayloadSize(2) public returns (bool _success) {
		require(allowed[msg.sender][_spender].add(_addedValue) <= balances[msg.sender]);
		
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		
		return true;
	}

	function decreaseApproval(address _spender, uint256 _subtractedValue) onlyPayloadSize(2) public returns (bool _success) {
		uint256 oldValue = allowed[msg.sender][_spender];
		
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		
		return true;
	}
	
	function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool _success) {
		require(_value <= balances[msg.sender]);
		
		allowed[msg.sender][_spender] = _value;
		
		emit Approval(msg.sender, _spender, _value);
		
		return true;
	}
  
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}
	
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
	
	function allowance(address _owner, address _spender) public view returns (uint256 _remaining) {
		return allowed[_owner][_spender];
	}
}