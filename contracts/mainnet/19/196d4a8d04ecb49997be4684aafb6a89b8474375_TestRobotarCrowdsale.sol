pragma solidity ^0.4.21;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint a, uint b) internal pure returns (uint c) {
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
  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  uint totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract RobotarTestToken is MintableToken {
    
  // Constants
  // =========
  
    string public constant name = "Robotar token";
    
    string public constant symbol = "TTAR";
    
    uint32 public constant decimals = 18;
    
    // Tokens are frozen until ICO ends.
    
    bool public frozen = true;
    
    
  address public ico;
  modifier icoOnly { require(msg.sender == ico); _; }
  
  
  // Constructor
  // ===========
  
  function RobotarTestToken(address _ico) public {
    ico = _ico;
  }
  
    function defrost() external icoOnly {
    frozen = false;
  }
    
     // ERC20 functions
  // =========================

  function transfer(address _to, uint _value)  public returns (bool) {
    require(!frozen);
    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(!frozen);
    return super.transferFrom(_from, _to, _value);
  }


  function approve(address _spender, uint _value) public returns (bool) {
    require(!frozen);
    return super.approve(_spender, _value);
  }
    
 /**  
  // Save tokens from contract
  function withdrawToken(address _tokenContract, address where, uint _value) external icoOnly {
    ERC20 _token = ERC20(_tokenContract);
    _token.transfer(where, _value);
  }
  */
  
  function supplyBezNolei() public view returns(uint) {
  return totalSupply().div(1 ether);
  }
    
}


contract TestRobotarCrowdsale is Ownable {
    
    using SafeMath for uint;
    
    address multisig;

   RobotarTestToken public token = new RobotarTestToken(this);

// uint public created_time = now;

    
  uint rate = 1000;
       
	uint PresaleStart = 0;
	uint CrowdsaleStart = 0;
	uint PresalePeriod = 1 days;
	uint CrowdsalePeriod = 1 days;
	uint public threshold = 1000000000000000;	
	
	uint bountyPercent = 10;
	uint foundationPercent = 50;
	uint teamPercent = 40;
	
	address bounty;
	address foundation;
	address team;
	
 // Crowdsale constructor
 
    function TestRobotarCrowdsale() public {
        
	multisig = owner;	
			
	      }
	      	      
	      function setPresaleStart(uint _presaleStart) onlyOwner public returns (bool) {
	      PresaleStart = _presaleStart;
	 //     require(PresaleStart > now) ;
	      return true;
	      }
	      
	       function setCrowdsaleStart(uint _crowdsaleStart)  onlyOwner public returns (bool) {
	       CrowdsaleStart = _crowdsaleStart;
	 //      require(CrowdsaleStart > now && CrowdsaleStart > PresaleStart + 7 days ) ;
	       return true;
	       }
      
   /**    modifier saleIsOn() {
require(now > testStart && now < testEnd || now > PresaleStart && now < PresaleStart + PresalePeriod || now > CrowdsaleStart && now <  CrowdsaleStart + CrowdsalePeriod);
    	_;
    } **/
    

   function createTokens() public payable  {
       uint tokens = 0;
       uint bonusTokens = 0;
       
         if (now > PresaleStart && now < PresaleStart + PresalePeriod) {
       tokens = rate.mul(msg.value);
        bonusTokens = tokens.div(4);
        } 
        else if (now > CrowdsaleStart && now <  CrowdsaleStart + CrowdsalePeriod){
        tokens = rate.mul(msg.value);
        
        if(now < CrowdsaleStart + CrowdsalePeriod/4) {bonusTokens = tokens.mul(15).div(100);}
        else if(now >= CrowdsaleStart + CrowdsalePeriod/4 && now < CrowdsaleStart + CrowdsalePeriod/2) {bonusTokens = tokens.div(10);} 
        else if(now >= CrowdsaleStart + CrowdsalePeriod/2 && now < CrowdsaleStart + CrowdsalePeriod*3/4) {bonusTokens = tokens.div(20);}
        
        }      
                 
        tokens += bonusTokens;
       if (tokens>0) {token.mint(msg.sender, tokens);}
    }        
       

   function() external payable {
   if (msg.value >= threshold) createTokens();   
   
        }
   
       
    
   
    
    function finishICO(address _team, address _foundation, address _bounty) external onlyOwner {
	uint issuedTokenSupply = token.totalSupply();
	uint bountyTokens = issuedTokenSupply.mul(bountyPercent).div(100);
	uint foundationTokens = issuedTokenSupply.mul(foundationPercent).div(100);
	uint teamTokens = issuedTokenSupply.mul(teamPercent).div(100);
	bounty = _bounty;
	foundation = _foundation;
	team = _team;
	
	token.mint(bounty, bountyTokens);
	token.mint(foundation, foundationTokens);
	token.mint(team, teamTokens);
	
        token.finishMinting();
      
            }

function defrost() external onlyOwner {
token.defrost();
}
  
  function withdrawEther(uint _value) external onlyOwner {
    multisig.transfer(_value);
  }
  
 /**
      
  
  // Save tokens from contract
  function withdrawToken(address _tokenContract, uint _value) external onlyOwner {
    ERC20 _token = ERC20(_tokenContract);
    _token.transfer(multisig, _value);
  }
  function withdrawTokenFromTAR(address _tokenContract, uint _value) external onlyOwner {
    token.withdrawToken(_tokenContract, multisig, _value);
  }
  
//the end    
  */
}