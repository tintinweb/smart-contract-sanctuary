/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity >=0.5.12;


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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(this));
        owner = newOwner;
    }
}

contract Token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function transfer(address _to, uint256 _value) public returns (bool success);
	function balanceOf(address account) external view returns (uint256);
	
}

contract DongyiTokenSale is owned {
	using SafeMath for uint;
	Token public tokenAddress;
    bool public initialized = false;

	address public receiverAddress;
	
	uint public rate = 10000000000000000000;
	uint public start = 1625146298;
	uint public last = 1662039098;
	
	uint public pre_sale = 30;
    uint public bonus_1 = 25;
    uint public bonus_2 = 20;
    uint public bonus_3 = 15;
    uint public bonus_4 = 7;
    uint public bonus_5 = 5;
	
    event Initialized();
    event WithdrawTokens(address destination, uint256 amount);
    event WithdrawAnyTokens(address tokenAddress, address destination, uint256 amount);
    event WithdrawEther(address destination, uint256 amount);
	

	/**
     * Constructor
     *
     * First time rules setup 
     */
    constructor() payable public {
    }


    /**
     * Initialize contract
     *
     * @param _tokenAddress token address
     */
    function init(Token _tokenAddress) onlyOwner public {
        require(!initialized);
        initialized = true;
        tokenAddress = _tokenAddress;
        emit Initialized();
    }


    /**
     * withdrawTokens
     *
     * Withdraw tokens from the contract
     *
     * @param amount is an amount of tokens
     */
    function withdrawTokens(
        uint256 amount
    )
        onlyOwner public
    {
        require(initialized);
        tokenAddress.transfer(msg.sender, amount);
        emit WithdrawTokens(msg.sender, amount);
    }

    /**
     * withdrawAnyTokens
     *
     * Withdraw any tokens from the contract
     *
     * @param _tokenAddress is a token contract address
     * @param amount is an amount of tokens
     */
    function withdrawAnyTokens(
        address _tokenAddress,
        uint256 amount
    )
        onlyOwner public
    {
        Token(_tokenAddress).transfer(msg.sender, amount);
        emit WithdrawAnyTokens(_tokenAddress, msg.sender, amount);
    }
    
    /**
     * withdrawEther
     *
     * Withdraw ether from the contract
     *
     * @param amount is a wei amount 
     */
    function withdrawEther(
        uint256 amount
    )
        onlyOwner public
    {
        msg.sender.transfer(amount);
        emit WithdrawEther(msg.sender, amount);
    }
	
	modifier SaleOnGoing() {
    require(now > start - 28 days && now < last);
    _;
	}
	
	function setRate(uint _rate) public onlyOwner {
		rate = _rate;
	}
	
	function setStart(uint _start) public onlyOwner {
		start = _start;
	}
	
	function setLast(uint _last) public onlyOwner {
		last = _last;
	}
	function setReceiver(address _receiverAddress) public onlyOwner {
		receiverAddress = _receiverAddress;
	}
	
	function SetSale(uint _pre_sale, uint _bonus_1, uint _bonus_2, uint _bonus_3, uint _bonus_4, uint _bonus_5) public onlyOwner {
		pre_sale = _pre_sale;
		bonus_1 = _bonus_1;
		bonus_2 = _bonus_2;
		bonus_3 = _bonus_3;
		bonus_4 = _bonus_4;
		bonus_5 = _bonus_5; 
	}
	
	/**
     * Execute transaction
     *
     * @param transactionBytecode transaction bytecode
     */
    function execute(bytes memory transactionBytecode) onlyOwner public {
        require(initialized);
        (bool success, ) = msg.sender.call.value(0)(transactionBytecode);
            require(success);
    }
	
	
	function BuyDongs() SaleOnGoing payable public {
		address payable wallet = address(uint160(receiverAddress));
		
		uint tokens = rate.mul(msg.value).div(1 ether);
		wallet.transfer(msg.value);
		
		uint BonusDongs = 0;
		
		if(now < start)  {
			BonusDongs = tokens.div(100).mul(pre_sale);
		} else if(now >= start && now < start + 14 days) { 	// 1st-2nd week
			BonusDongs = tokens.div(100).mul(bonus_1);
		} else if(now >= start && now < start + 28 days) { 	// 3rd-4th week
			BonusDongs = tokens.div(100).mul(bonus_2);
		} else if(now >= start && now < start + 42 days) { 	// 5th-6th week
			BonusDongs = tokens.div(100).mul(bonus_3);
		} else if(now >= start && now < start + 56 days) { 	// 7th-8th week
			BonusDongs = tokens.div(100).mul(bonus_4);
		} else if(now >= start && now < start + 77 days) { 	// 9th-11th week
			BonusDongs = tokens.div(100).mul(bonus_5);
		} 
		
		uint amountTobuy = msg.value;
		uint TotalWithBonus = tokens.add(BonusDongs);
		
        uint TokenLeft = Token(tokenAddress).balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        require(TotalWithBonus <= TokenLeft, "Not enough tokens available");
		
		
        Token(tokenAddress).transfer(msg.sender, TotalWithBonus);
		
	}

	function() external payable {
		BuyDongs();
	}
	
}