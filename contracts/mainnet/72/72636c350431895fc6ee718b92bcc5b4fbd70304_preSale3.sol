pragma solidity ^0.4.18;
 
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
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

  function div(uint256 a, uint256 b) internal pure  returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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
contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
  function approve(address _spender, uint256 _value) public returns (bool) {
 
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
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}
 
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
 
contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();
 
  bool public mintingFinished = false;
 
  address public saleAgent;
  
   modifier canMint() {
   require(!mintingFinished);
    _;
  }
  
   modifier onlySaleAgent() {
   require(msg.sender == saleAgent);
    _;
  }

  function setSaleAgent(address newSaleAgent) public onlyOwner {
   saleAgent = newSaleAgent;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) public onlySaleAgent canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
 
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlySaleAgent returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}
 
contract AgroTechFarmToken is MintableToken {
    
    string public constant name = "Agro Tech Farm";
    
    string public constant symbol = "ATF";
    
    uint32 public constant decimals = 18;
}
 





contract preSale3 is Ownable {    
    using SafeMath for uint;        
    AgroTechFarmToken public token;
    bool public preSale3Finished = false;
    string public constant name = "ATF Token";
    address public multisig;
    address public preSale = 0x02Dcc61022771015b1408323D29C790066CBe2e4;
    address public preSale1 = 0xfafbb19945fc2d79828e4c5813a619d5683074ba;
    address public preSale2 = 0x62451D37Ca2EC1f0499996Bc3C7e2BAF258E9729;  
    uint public rate;
    uint public start;
    uint public end;
    uint public hardcap;
    address public restricted;
	uint public restrictedPercent;

    function preSale3() public {        
	    token = AgroTechFarmToken(0xa55ffAeA5c8cf32B550F663bf17d4F7b739534ff); 
		multisig = 0x227917ac3C1F192874d43031cF4D40fd40Ae6127;
		rate = 83333333333000000000; 
		start = 1520640000;
        end = 1522047600; 
	    hardcap = 500000000000000000000;
	    restricted = 0xbcCd749ecCCee5B4898d0E38D2a536fa84Ea9Ef6;   
	    restrictedPercent = 35;
          
    }
 
   modifier saleIsOn() {
    	require(now > start && now < end);
    	_;
    }
	
    modifier isUnderHardCap() {
      require(this.balance <= hardcap);
        _;
    } 


  function balancePreSale3() public constant returns (uint) {
     return this.balance;
    }

 
  function finishPreSale3() public onlyOwner returns (bool)  {
        if(now > end || this.balance >= hardcap) {                     
         multisig.transfer(this.balance);
         preSale3Finished = true;
         return true;
         } else return false;     
      }
 
   function createTokens() public isUnderHardCap saleIsOn payable {
        uint tokens = rate.mul(msg.value).div(1 ether);           
        uint bonusTokens = tokens.mul(35).div(100);       
        tokens += bonusTokens;     
        token.mint(msg.sender, tokens);
       
	    uint restrictedTokens = tokens.mul(restrictedPercent).div(100); 
        token.mint(restricted, restrictedTokens);        
        
    }
 

    function() external payable {
        createTokens();
    } 
}