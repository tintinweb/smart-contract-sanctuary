pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public{
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner,newOwner);
        owner = newOwner;
    }
}

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

interface token {
    function balanceOf(address who) external constant returns (uint256);
	  function transfer(address to, uint256 value) external returns (bool);
	  function getTotalSupply() external view returns (uint256);
}

contract ApolloSeptemBaseCrowdsale {
    using SafeMath for uint256;

    // The token being sold
    token public tokenReward;
	
    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;
	
    // token address
    address public tokenAddress;

    // amount of raised money in wei
    uint256 public weiRaised;
    
    // ICO period (includes holidays)
    uint public constant  ICO_PERIOD = 180 days;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event ApolloSeptemTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ApolloSeptemTokenSpecialPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

    function ApolloSeptemBaseCrowdsale(address _wallet, address _tokens) public{		
        require(_wallet != address(0));
        tokenAddress = _tokens;
        tokenReward = token(tokenAddress);
        wallet = _wallet;

    }

    // fallback function can be used to buy tokens
    function () public payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token to be substracted
        uint256 tokens = computeTokens(weiAmount);

        require(isWithinTokenAllocLimit(tokens));

        // update state
        weiRaised = weiRaised.add(weiAmount);

        // send tokens to beneficiary
        tokenReward.transfer(beneficiary, tokens);

        ApolloSeptemTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    //transfer used for special contribuitions
    function specialTransfer(address _to, uint _amount) internal returns(bool){
        require(_to != address(0));
        require(_amount > 0);
      
        // calculate token to be substracted
        uint256 tokens = _amount * (10 ** 18);
      
        tokenReward.transfer(_to, tokens);		
        ApolloSeptemTokenSpecialPurchase(msg.sender, _to, tokens);
      
        return true;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
		
        return withinPeriod && nonZeroPurchase && isWithinICOTimeLimit();
    }
    
    function isWithinICOTimeLimit() internal view returns (bool) {
        return now <= endTime;
    }
	
    function isWithinICOLimit(uint256 _tokens) internal view returns (bool) {			
        return tokenReward.balanceOf(this).sub(_tokens) >= 0;
    }

    function isWithinTokenAllocLimit(uint256 _tokens) internal view returns (bool) {
        return (isWithinICOTimeLimit() && isWithinICOLimit(_tokens));
    }
	
    function sendAllToOwner(address beneficiary) internal returns(bool){
        tokenReward.transfer(beneficiary, tokenReward.balanceOf(this));
        return true;
    }

    function computeTokens(uint256 weiAmount) internal pure returns (uint256) {
		    // 1 ETH = 4200 APO 
        return weiAmount.mul(4200);
    }
}

/**
 * @title ApolloSeptemCappedCrowdsale
 * @dev Extension of ApolloSeptemBaseCrowdsale with a max amount of funds raised
 */
contract ApolloSeptemCappedCrowdsale is ApolloSeptemBaseCrowdsale{
    using SafeMath for uint256;

    // HARD_CAP = 30,000 ether 
    uint256 public constant HARD_CAP = (3 ether)*(10**4);

    function ApolloSeptemCappedCrowdsale() public {}

    // overriding ApolloSeptemBaseCrowdsale#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal view returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= HARD_CAP;

        return super.validPurchase() && withinCap;
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= HARD_CAP;
        return super.hasEnded() || capReached;
    }
}

/**
 * @title ApolloSeptemCrowdsaleExtended
 * @dev This is ApolloSeptem&#39;s crowdsale contract.
 */
contract ApolloSeptemCrowdsaleExtended is ApolloSeptemCappedCrowdsale, Ownable {

    bool public isFinalized = false;
    bool public isStarted = false;

    event ApolloSeptemStarted();
    event ApolloSeptemFinalized();

    function ApolloSeptemCrowdsaleExtended(address _wallet,address _tokensAddress) public
        ApolloSeptemCappedCrowdsale()
        ApolloSeptemBaseCrowdsale(_wallet,_tokensAddress) 
    {}
	
  	/**
    * @dev Must be called to start the crowdsale. 
    */
    function start(uint256 _weiRaised) onlyOwner public {
        require(!isStarted);

        starting(_weiRaised);
        ApolloSeptemStarted();

        isStarted = true;
    }

    function starting(uint256 _weiRaised) internal {
        startTime = now;
        weiRaised = _weiRaised;
        endTime = startTime + ICO_PERIOD;
    }
	
    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        ApolloSeptemFinalized();

        isFinalized = true;
    }	
	
    /**
    * @dev Must be called only in special cases 
    */
    function apolloSpecialTransfer(address _beneficiary, uint _amount) onlyOwner public {		 
        specialTransfer(_beneficiary, _amount);
    }
	
    /**
    *@dev Must be called after the crowdsale ends, to send the remaining tokens back to owner
    **/
    function sendRemaningBalanceToOwner(address _tokenOwner) onlyOwner public {
        require(_tokenOwner != address(0));
        
        sendAllToOwner(_tokenOwner);	
    }
}