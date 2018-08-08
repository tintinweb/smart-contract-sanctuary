pragma solidity ^0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Reference implementation of the ERC220 standard token.
 */
contract StandardToken is Token {
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }
 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 amount);

    /**
    * @dev Anybody can burn a specific amount of their tokens.
    * @param _amount The amount of token to be burned.
    */
    function burn(uint256 _amount) public {
        require(_amount > 0);
        require(_amount <= balances[msg.sender]);
        // no need to require _amount <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = SafeMath.sub(balances[burner],_amount);
        totalSupply = SafeMath.sub(totalSupply,_amount);
        emit Transfer(burner, address(0), _amount);
        emit Burn(burner, _amount);
    }

    /**
    * @dev Owner can burn a specific amount of tokens of other token holders.
    * @param _from The address of token holder whose tokens to be burned.
    * @param _amount The amount of token to be burned.
    */
    function burnFrom(address _from, uint256 _amount) onlyOwner public {
        require(_from != address(0));
        require(_amount > 0);
        require(_amount <= balances[_from]);
        balances[_from] = SafeMath.sub(balances[_from],_amount);
        totalSupply = SafeMath.sub(totalSupply,_amount);
        emit Transfer(_from, address(0), _amount);
        emit Burn(_from, _amount);
    }

}

contract AxpirePausableToken is StandardToken, Pausable,BurnableToken {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

 
}

contract AxpireToken is AxpirePausableToken {
 using SafeMath for uint;
    // metadata
    string public constant name = "aXpire";
    string public constant symbol = "AXPR";
    uint256 public constant decimals = 18;
    
   	address private ethFundDeposit;       
	address private escrowFundDeposit;
		    	
	uint256 public icoTokenExchangeRate = 715; // 715 b66 tokens per 1 ETH
	uint256 public tokenCreationCap =  350 * (10**6) * 10**decimals;  
	
	//address public ;
	// crowdsale parameters
    	bool public tokenSaleActive;              // switched to true in operational state
	bool public haltIco;
	bool public dead = false;

 
    // events 
    event CreateToken(address indexed _to, uint256 _value);
    event Transfer(address from, address to, uint256 value);
    
    // constructor
    constructor (		
       	address _ethFundDeposit,
       	address _escrowFundDeposit
		
		
        	) public {
        	
		tokenSaleActive = true;                   
		haltIco = true;
		paused = true;
			
		require(_ethFundDeposit != address(0));
		require(_escrowFundDeposit != address(0));
		
		ethFundDeposit = _ethFundDeposit;
		escrowFundDeposit=_escrowFundDeposit;
		balances[escrowFundDeposit] = tokenCreationCap;
		totalSupply = tokenCreationCap;
		emit CreateToken(escrowFundDeposit, totalSupply);
		
    }
	
    /// @dev Accepts ether and creates new tge tokens.
    function createTokens() payable external {
      if (!tokenSaleActive) 
        revert();
      if (haltIco) 
	revert();	  
      if (msg.value == 0) 
        revert();
        
      uint256 tokens;
      tokens = SafeMath.mul(msg.value, icoTokenExchangeRate); // check that we&#39;re not over totals
      uint256 checkedSupply = SafeMath.add(totalSupply, tokens);
 
      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) 
        revert();  // odd fractions won&#39;t be found
 
      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;  // safeAdd not needed; bad semantics to use here
      emit CreateToken(msg.sender, tokens);  // logs token creation
    }  
    
    function setIcoTokenExchangeRate (uint _icoTokenExchangeRate) onlyOwner external {		
    	icoTokenExchangeRate = _icoTokenExchangeRate;            
    }        
    
    function setHaltIco(bool _haltIco) onlyOwner external {
	haltIco = _haltIco;            
    }	
    
     /// @dev Ends the funding period and sends the ETH home
    function sendFundHome() onlyOwner external {  // move to operational
      if (!ethFundDeposit.send(address(this).balance)) 
        revert();  // send the eth to tge International
    } 
	
    function sendFundHomeAmt(uint _amt) onlyOwner external {
      if (!ethFundDeposit.send(_amt*10**decimals)) 
        revert();  // send the eth to tge International
    }    
    
      function toggleDead()
          external
          onlyOwner
          returns (bool)
        {
          dead = !dead;
      }
     
        function endIco() onlyOwner external { // end ICO
          // ensure that sale is active. is set to false at the end. can only be performed once.
              require(tokenSaleActive == true);
               tokenSaleActive=false;
        }  
    
      
}