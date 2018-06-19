pragma solidity ^0.4.23;

/*

P3D Charity Mining Pool

- Splits deposit according to feeDivisor (default is 4 = 25% donation)
    - Sends user donation plus current dividends to charity address (Giveth)
    - Uses the rest to buy P3D tokens under the sender&#39;s masternode
    - feeDivisor can be from 2 to 10 (50% to 10% donation range)
- Dividends accumulated by miner can be sent as donation at anytime
- Donors can sell their share of tokens at anytime and withdraw the ETH value!

https://discord.gg/N4UShc3

*/

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract POWH {
    function buy(address) public payable returns(uint256);
    function sell(uint256) public;
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}

contract CharityMiner {
    using SafeMath for uint256;
    
    // Modifiers
    modifier notP3d(address aContract) {
        require(aContract != address(p3d));
        _;
    }
    
    // Events
    event Deposit(uint256 amount, address depositer, uint256 donation);
    event Withdraw(uint256 tokens, address depositer, uint256 tokenValue, uint256 donation);
    event Dividends(uint256 amount, address sender);
    event Paused(bool paused);
    
    // Public Variables
    bool public paused = false;
    address public charityAddress = 0x8f951903C9360345B4e1b536c7F5ae8f88A64e79; // Giveth
    address public owner;
    address public P3DAddress;
    address public largestDonor;
    address public lastDonor;
    uint public totalDonors;
    uint public totalDonated;
    uint public totalDonations;
    uint public largestDonation;
    uint public currentHolders;
    uint public totalDividends;
    
    // Public Mappings
    mapping( address => bool ) public donor;
    mapping( address => uint256 ) public userTokens;
    mapping( address => uint256 ) public userDonations;
    
    // PoWH Contract
    POWH p3d;
	
	// Constructor
	constructor(address powh) public {
	    p3d = POWH(powh);
	    P3DAddress = powh;
	    owner = msg.sender;
	}
	
	// Pause
	// - In case charity address is no longer active or deposits have to be paused for unexpected reason
	// - Cannot be paused while anyone owns tokens
	function pause() public {
	    require(msg.sender == owner && myTokens() == 0);
	    paused = !paused;
	    
	    emit Paused(paused);
	}
	
	// Fallback
	// - Easy deposit, sets default feeDivisor
	function() payable public {
	    if(msg.sender != address(p3d)) { // Need to receive divs from P3D contract
    	    uint8 feeDivisor = 4; // Default 25% donation
    	    deposit(feeDivisor);
	    }
	}

	// Deposit
    // - Divide deposit by feeDivisor then add divs and send as donation
	// - Use the rest to buy P3D tokens under sender&#39;s masternode
	function deposit(uint8 feeDivisor) payable public {
	    require(msg.value > 100000 && !paused);
	    require(feeDivisor >= 2 && feeDivisor <= 10); // 50% to 10% donation range
	    
	    // If we have divs, withdraw them
	    uint divs = myDividends();
	    if(divs > 0){
	        p3d.withdraw();
	    }
	    
	    // Split deposit
	    uint fee = msg.value.div(feeDivisor);
	    uint purchase = msg.value.sub(fee);
	    uint donation = divs.add(fee);
	    
	    // Send donation
	    charityAddress.transfer(donation);
	    
	    // Buy tokens
	    uint tokens = myTokens();
	    p3d.buy.value(purchase)(msg.sender);
	    uint newTokens = myTokens().sub(tokens);
	    
	    // If new donor, add them to stats
	    if(!donor[msg.sender]){
	        donor[msg.sender] = true;
	        totalDonors += 1;
	        currentHolders += 1;
	    }
	    
	    // If largest donor, update stats
	    // Don&#39;t include dividends or token value in user donations
	    if(fee > largestDonation){ 
	        largestDonation = fee;
	        largestDonor = msg.sender;
	    }
	    
	    // Update stats and storage
	    totalDonations += 1;
	    totalDonated += donation;
	    totalDividends += divs;
	    lastDonor = msg.sender;
	    userDonations[msg.sender] = userDonations[msg.sender].add(fee); 
	    userTokens[msg.sender] = userTokens[msg.sender].add(newTokens);
	    
	    // Deposit event
	    emit Deposit(purchase, msg.sender, donation);
	}
	
	// Withdraw
	// - Sell user&#39;s tokens and withdraw the eth value, sends divs as donation
	// - User doesn&#39;t get any of the excess divs
	function withdraw() public {
	    uint tokens = userTokens[msg.sender];
	    require(tokens > 0);
	    
	    // Save divs and balance
	    uint divs = myDividends();
	    uint balance = address(this).balance;
	    
	    // Update before we sell
	    userTokens[msg.sender] = 0;
	    
	    // Sell tokens and withdraw
	    p3d.sell(tokens);
	    p3d.withdraw();
	    
	    // Get value of sold tokens
	    uint tokenValue = address(this).balance.sub(divs).sub(balance);
	    
	    // Send donation and payout
	    charityAddress.transfer(divs);
	    msg.sender.transfer(tokenValue);
	    
	    // Update stats
	    totalDonated += divs;
	    totalDividends += divs;
	    totalDonations += 1;
	    currentHolders -= 1;
	    
	    // Withdraw event
	    emit Withdraw(tokens, msg.sender, tokenValue, divs);
	}
	
	// SendDividends
	// - Withdraw dividends and send as donation (can be called by anyone)
	function sendDividends() public {
	    uint divs = myDividends();
	    // Don&#39;t want to spam them with tiny donations
	    require(divs > 100000);
	    p3d.withdraw();
	    
	    // Send donation
	    charityAddress.transfer(divs);
	    
	    // Update stats
	    totalDonated += divs;
	    totalDividends += divs;
	    totalDonations += 1;
	    
	    // Dividends event
	    emit Dividends(divs, msg.sender);
	}
	
    // MyTokens
    // - Retun tokens owned by this contract
    function myTokens() public view returns(uint256) {
        return p3d.myTokens();
    }
    
	// MyDividends
	// - Return contract&#39;s current dividends including referral bonus
	function myDividends() public view returns(uint256) {
        return p3d.myDividends(true);
    }
	
	// Rescue function to transfer tokens. Cannot be used on P3D.
	function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public notP3d(tokenAddress) returns (bool success) {
		require(msg.sender == owner);
		return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}