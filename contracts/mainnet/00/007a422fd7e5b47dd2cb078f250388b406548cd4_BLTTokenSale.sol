pragma solidity ^0.4.16;


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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  
   //@dev transfer token for a specified address
  // @param _to The address to transfer to.
   //@param _value The amount to be transferred.
   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  
   //@dev Gets the balance of the specified address.
   //@param _owner The address to query the the balance of. 
  // @return An uint256 representing the amount owned by the passed address.
  
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until 
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint256 _addedValue) 
    returns (bool success) 
    {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint256 _subtractedValue) 
    returns (bool success) 
    {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract Ownable {
  address public owner;

    //@dev The Ownable constructor sets the original `owner` of the contract to the sender account.
   function Ownable() {
    owner = msg.sender;
  }

    //@dev Throws if called by any account other than the owner.
   modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

    //@dev Allows the current owner to transfer control of the contract to a newOwner.
    //@param newOwner The address to transfer ownership to.
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

    //@title Pausable
    //@dev Base contract which allows children to implement an emergency stop mechanism for trading.
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

    //@dev Modifier to make a function callable only when the contract is not paused.
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

    //@dev Modifier to make a function callable only when the contract is paused.
  modifier whenPaused() {
    require(paused);
    _;
  }

    //@dev called by the owner to pause, triggers stopped state
  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }
    //@dev called by the owner to unpause, returns to normal state
  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}

    //@title Pausable
    //@dev Base contract which allows children to implement an emergency stop mechanism for crowdsale.
contract SalePausable is Ownable {
  event SalePause();
  event SaleUnpause();

  bool public salePaused = false;

    //@dev Modifier to make a function callable only when the contract is not paused.
  modifier saleWhenNotPaused() {
    require(!salePaused);
    _;
  }

    //@dev Modifier to make a function callable only when the contract is paused.
  modifier saleWhenPaused() {
    require(salePaused);
    _;
  }

    //@dev called by the owner to pause, triggers stopped state
  function salePause() onlyOwner saleWhenNotPaused {
    salePaused = true;
    SalePause();
  }
    //@dev called by the owner to unpause, returns to normal state
  function saleUnpause() onlyOwner saleWhenPaused {
    salePaused = false;
    SaleUnpause();
  }
}

contract PriceUpdate is Ownable {
  uint256 public price;

    //@dev The Ownable constructor sets the original `price` of the BLT token to the sender account.
   function PriceUpdate() {
    price = 400;
  }

    //@dev Allows the current owner to change the price of the token per ether.
  function newPrice(uint256 _newPrice) onlyOwner {
    require(_newPrice > 0);
    price = _newPrice;
  }

}

contract BLTToken is StandardToken, Ownable, PriceUpdate, Pausable, SalePausable {
	using SafeMath for uint256;
	mapping(address => uint256) balances;
	uint256 public totalSupply;
    uint256 public totalCap = 100000000000000000000000000;
    string 	public constant name = "BitLifeAndTrust";
	string 	public constant symbol = "BLT";
	uint256	public constant decimals = 18;
	//uint256 public price = 400;  moved to price setting contract
    
    address public bltRetainedAcc = 0x48259a35030c8dA6aaA1710fD31068D30bfc716C;  //holds blt company retained
    address public bltOwnedAcc =    0x1CA33C197952B8D9dd0eDC9EFa20018D6B3dcF5F;  //holds blt company owned
    address public bltMasterAcc =   0xACc2be4D782d472cf4f928b116054904e5513346; //master account to hold BLT

    uint256 public bltRetained = 15000000000000000000000000;
    uint256 public bltOwned =    15000000000000000000000000;
    uint256 public bltMaster =   70000000000000000000000000;


	function balanceOf(address _owner) constant returns (uint256 balance) {
	    return balances[_owner];
	}


	function transfer(address _to, uint256 _value) whenNotPaused returns (bool success) {
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    Transfer(msg.sender, _to, _value);
	    return true;
	}


	function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool success) {
	    
	    var allowance = allowed[_from][msg.sender];
	    
	    balances[_to] = balances[_to].add(_value);
	    balances[_from] = balances[_from].sub(_value);
	    allowed[_from][msg.sender] = allowance.sub(_value);
	    Transfer(_from, _to, _value);
	    return true;
	}


	function approve(address _spender, uint256 _value) returns (bool success) {
	    allowed[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
	    return true;
	}


	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
	    return allowed[_owner][_spender];
	}


	function BLTToken() {
		balances[bltRetainedAcc] = bltRetained;             // fund BLT Retained account
        balances[bltOwnedAcc] = bltOwned;                   // fund BLT Owned account
        balances[bltMasterAcc] = bltMaster;                 // fund BLT master account
        
        allowed[bltMasterAcc][msg.sender] = bltMaster;

        totalSupply = bltRetained + bltOwned + bltMaster;

        Transfer(0x0,bltRetainedAcc,bltRetained);
        Transfer(0x0,bltOwnedAcc,bltOwned);
        Transfer(0x0,bltMasterAcc,bltMaster);

	}

}


contract BLTTokenSale is BLTToken {
    using SafeMath for uint256;    

    BLTToken public token;
    uint256 public etherRaised;
    uint256 public saleStartTime = now;
    //uint256 public saleEndTime = now + 1 weeks;
    address public ethDeposits = 0x50c19a8D73134F8e649bB7110F2E8860e4f6cfB6;        //ether goes to this account
    address public bltMasterToSale = 0xACc2be4D782d472cf4f928b116054904e5513346;    //BLT available for sale

    event MintedToken(address from, address to, uint256 value1);                    //event that Tokens were sent
    event RecievedEther(address from, uint256 value1);                               //event that ether received function ran     

    function () payable {
		createTokens(msg.sender,msg.value);
	}

        //initiates the sale of the token
	function createTokens(address _recipient, uint256 _value) saleWhenNotPaused {
        
        require (_value != 0);                                                      //value must be greater than zero
        require (now >= saleStartTime);                                             //only works during token sale
        require (_recipient != 0x0);                                                //not a contract validation
		uint256 tokens = _value.mul(PriceUpdate.price);                             //calculate the number of tokens from the ether sent
        uint256 remainingTokenSuppy = balanceOf(bltMasterToSale);

        if (remainingTokenSuppy >= tokens) {                                        //only works if there is still a supply in the master account
            require(mint(_recipient, tokens));                                      //execute the movement of tokens
            etherRaised = etherRaised.add(_value);
            forwardFunds();
            RecievedEther(msg.sender,_value);
        }                                        

	}
    
     //transfers BLT from storage account into the purchasers account   
    function mint(address _to, uint256 _tokens) internal saleWhenNotPaused returns (bool success) {
        
        address _from = bltMasterToSale;
	    var allowance = allowed[_from][owner];
	    
	    balances[_to] = balances[_to].add(_tokens);
	    balances[_from] = balances[_from].sub(_tokens);
	    allowed[_from][owner] = allowance.sub(_tokens);
        Transfer(_from, _to, _tokens);                                               //capture event in logs
	    MintedToken(_from,_to, _tokens); 
      return true;
	}    
      //forwards ether to storage wallet  
      function forwardFunds() internal {
        ethDeposits.transfer(msg.value);
        
        }
}