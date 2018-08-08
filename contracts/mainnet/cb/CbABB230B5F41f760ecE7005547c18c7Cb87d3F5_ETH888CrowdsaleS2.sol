pragma solidity ^0.4.11;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract VanilCoin is MintableToken {
  	
	string public name = "Vanil";
  	string public symbol = "VAN";
  	uint256 public decimals = 18;
  
  	// tokens locked for one week after ICO, 8 Oct 2017, 0:0:0 GMT: 1507420800
  	uint public releaseTime = 1507420800;
  
	modifier canTransfer(address _sender, uint256 _value) {
		require(_value <= transferableTokens(_sender, now));
	   	_;
	}
	
	function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) returns (bool) {
		return super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}
	
	function transferableTokens(address holder, uint time) constant public returns (uint256) {
		
		uint256 result = 0;
				
		if(time > releaseTime){
			result = balanceOf(holder);
		}
		
		return result;
	}
	
}

contract ETH888CrowdsaleS2 {

	using SafeMath for uint256;
	
	// The token being sold
	address public vanilAddress;
	VanilCoin public vanilCoin;
	
	// address where funds are collected
	address public wallet;
	
	// how many token units a buyer gets per wei
	uint256 public rate = 400;
	
	// timestamps for ICO starts and ends
	uint public startTimestamp;
	uint public endTimestamp;
	
	// amount of raised money in wei
	uint256 public weiRaised;
	
	mapping(uint8 => uint64) public rates;
	// week 2, 5 May 2018, 000:00:00 GMT
	uint public timeTier1 = 1525478400;
	// week 3, 12 May 2018, 000:00:00 GMT
	uint public timeTier2 = 1526083200;
	// week 4, 19 May 2018, 000:00:00 GMT
	uint public timeTier3 = 1526688000;

	/**
	   * event for token purchase logging
	   * @param purchaser who paid for the tokens
	   * @param beneficiary who got the tokens
	   * @param value weis paid for purchase
	   * @param amount amount of tokens purchased
	   */ 
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	function ETH888CrowdsaleS2(address _wallet, address _vanilAddress) {
		
		require(_wallet != 0x0 && _vanilAddress != 0x0);
		
		// 28 April 2018, 00:00:00 GMT: 1524873600
		startTimestamp = 1524873600;
		
		// 28 May 2018, 00:00:00 GMT: 1527465600
		endTimestamp = 1527465600;
		
		rates[0] = 400;
		rates[1] = 300;
		rates[2] = 200;
		rates[3] = 100;

		wallet = _wallet;
		vanilAddress = _vanilAddress;
		vanilCoin = VanilCoin(vanilAddress);
	}
		
	// fallback function can be used to buy tokens
	function () payable {
	    buyTokens(msg.sender);
	}
	
	// low level token purchase function
	function buyTokens(address beneficiary) payable {
		require(beneficiary != 0x0 && validPurchase() && validAmount());

		if(now < timeTier1)
			rate = rates[0];
		else if(now < timeTier2)
			rate = rates[1];
		else if(now < timeTier3)
			rate = rates[2];
		else
			rate = rates[3];

		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(rate);

		// update state
		weiRaised = weiRaised.add(weiAmount);
		vanilCoin.transfer(beneficiary, tokens);

		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		forwardFunds();
	}

	function totalSupply() public constant returns (uint)
	{
		return vanilCoin.totalSupply();
	}

	function vanilAddress() public constant returns (address)
	{
		return vanilAddress;
	}

	// send ether to the fund collection wallet
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}	
	
	function validAmount() internal constant returns (bool)
	{
		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(rate);

		return (vanilCoin.balanceOf(this) >= tokens);
	}

	// @return true if investors can buy at the moment
	function validPurchase() internal constant returns (bool) {
		
		uint current = now;
		bool withinPeriod = current >= startTimestamp && current <= endTimestamp;
		bool nonZeroPurchase = msg.value != 0;
		
		return withinPeriod && nonZeroPurchase && msg.value >= 1000 szabo;
	}

	// @return true if crowdsale event has ended
	function hasEnded() public constant returns (bool) {
		
		return now > endTimestamp;
	}
	
}