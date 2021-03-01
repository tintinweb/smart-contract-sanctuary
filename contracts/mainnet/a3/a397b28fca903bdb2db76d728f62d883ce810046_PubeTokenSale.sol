/**
 *Submitted for verification at Etherscan.io on 2021-02-28
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

contract PubeTokenSale is owned {
	using SafeMath for uint;
	Token public tokenAddress;
    bool public initialized = false;

	address public receiverAddress;
	
	uint public rate = 4000000000000;
	uint public start;
	uint public end;
	
	uint public pre_sale = 40;
    uint public bonus_1 = 30;
    uint public bonus_2 = 20;
    uint public bonus_3 = 15;
    uint public bonus_4 = 10;
    uint public bonus_5 = 5;
	
    event Initialized();
    event WithdrawTokens(address destination, uint256 amount);
    event WithdrawAnyTokens(address tokenAddress, address destination, uint256 amount);
    event WithdrawEther(address destination, uint256 amount);
	

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
	
	function SaleRate(uint _rate) public onlyOwner {
		rate = _rate;
	}
	
	function StartSale(uint _start) public onlyOwner {
		start = _start;
	}
	
	function EndSale(uint _last) public onlyOwner {
		end = _last;
	}
	
	function EthReceiver(address _receiverAddress) public onlyOwner {
		receiverAddress = _receiverAddress;
	}
	
	modifier OnGoing() {
    require(now > start && now < end);
    _;
	}
	
	function SetBonus(uint _pre_sale, uint _bonus_1, uint _bonus_2, uint _bonus_3, uint _bonus_4, uint _bonus_5) public onlyOwner {
		pre_sale = _pre_sale;
		bonus_1 = _bonus_1;
		bonus_2 = _bonus_2;
		bonus_3 = _bonus_3;
		bonus_4 = _bonus_4;
		bonus_5 = _bonus_5; 
	}

	function BuyPubes() OnGoing payable public {
		
		uint tokens = rate.mul(msg.value).div(1 ether);
		
		uint BonusPubes = 0;
		
		if(now < start)  {
			BonusPubes = tokens.div(100).mul(pre_sale);
		} else if(now >= start && now < start + 7 days) { 	// 1st week
			BonusPubes = tokens.div(100).mul(bonus_1);
		} else if(now >= start && now < start + 14 days) { 	// 2nd week
			BonusPubes = tokens.div(100).mul(bonus_2);
		} else if(now >= start && now < start + 21 days) { 	// 3rd week
			BonusPubes = tokens.div(100).mul(bonus_3);
		} else if(now >= start && now < start + 35 days) { 	// 4th week
			BonusPubes = tokens.div(100).mul(bonus_4);
		} else if(now >= start && now < start + 42 days) { 	// 5th week
			BonusPubes = tokens.div(100).mul(bonus_5);
		} 
		
		uint amountTobuy = msg.value;
		uint TotalWithBonus = tokens.add(BonusPubes);
		
        uint TokenLeft = Token(tokenAddress).balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        require(TotalWithBonus <= TokenLeft, "Not enough tokens available");
		
		address payable wallet = address(uint160(receiverAddress));
		wallet.transfer(msg.value);
		
        Token(tokenAddress).transfer(msg.sender, TotalWithBonus);
		
	}

	function() external payable {
		BuyPubes();
	}
	
}