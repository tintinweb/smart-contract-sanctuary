pragma solidity ^0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Crowdsale is Owned{

  	using SafeMath for uint256;
  	
  	ERC20Interface private token;
  	
  	// Amount Raised
  	uint256 public weiRaised;
	
	// Wallet where funds will be transfered
	address public wallet;
	
	// Is the crowdsale paused?
	bool isCrowdsalePaused = false;
	
	// the exchange rate
	uint256 public rate;
	
	// total ETH for sale
	uint256 public cap;
	
	uint8 public decimals;
	
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	constructor() public {
		wallet = 0x73b8D31A7FF02C3608FDaF3770D40c487CA9b11D;
		token = ERC20Interface(0x5D9f5D8d878Deb8DB5a4940fE7e86664E58c38FA);
		decimals = 18;
	 	cap = 20000 * 10**uint(decimals);
    	rate = 1000;
    	require(wallet != address(0));
		require(token != address(0));
		require(cap > 0);
		require(rate > 0);
	}
	
	function () external payable {
    	buyTokens(msg.sender);
 	}
 	
 	function buyTokens(address beneficiary) public payable {
 	
   		require(beneficiary != 0x0);

	    uint256 amount = msg.value;
	    
	    require(isCrowdsalePaused == false);
	    
	    require(weiRaised.add(amount) <= cap);

    	uint256 tokens = getTokenAmount(amount);

    	weiRaised = weiRaised.add(amount);

    	processPurchase(beneficiary, tokens);
    	
		emit TokenPurchase(msg.sender, beneficiary, amount, tokens);

    	forwardFunds();
    	
	}
	
	function rate() public view returns(uint256){
		return rate;
	}
	
	function weiRaised() public view returns (uint256) {
    	return weiRaised;
	}
	
	function deliverTokens(address beneficiary,uint256 tokenAmount) internal{
		token.transferFrom(wallet, beneficiary, tokenAmount);
	}
	
	function processPurchase(address beneficiary,uint256 tokenAmount) internal{
		deliverTokens(beneficiary, tokenAmount);
	}

	function getTokenAmount(uint256 amount) internal view returns (uint256){
    	return rate.mul(amount);
  	}
  	
  	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}
	
	function remainingTokens() public view returns (uint256) {
		return token.allowance(wallet, this);
	}

	function capReached() public view returns (bool) {
		return weiRaised >= cap;
	}
	
	function pauseCrowdsale() public onlyOwner {
        isCrowdsalePaused = true;
    }
    
    function resumeCrowdsale() public onlyOwner {
        isCrowdsalePaused = false;
    }
    
    function takeTokensBack() public onlyOwner
     {
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(owner,remainingTokensInTheContract);
     }
}