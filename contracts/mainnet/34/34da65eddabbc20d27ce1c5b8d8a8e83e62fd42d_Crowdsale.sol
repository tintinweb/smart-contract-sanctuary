/*
Xsearch Token
*/
pragma solidity ^0.4.16;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
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
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }

  event Burn(address indexed burner, uint indexed value);

}

contract XsearchToken is BurnableToken {
    
  string public constant name = "XSearch Token";
   
  string public constant symbol = "XSE";
    
  uint32 public constant decimals = 18;

  uint256 public INITIAL_SUPPLY = 30000000 * 1 ether;

  function XsearchToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
    
}

contract Crowdsale is Ownable {
    
  using SafeMath for uint;
    
  address multisig;

  uint restrictedPercent;

  address restricted;

  XsearchToken public token = new XsearchToken();

  uint start;
    
  uint period;

  uint rate;

  function Crowdsale() {
    multisig = 0xd4DB7d2086C46CDd5F21c46613B520290ABfC9D6; //escrow wallet
    restricted = 0x25fbfaA7bB3FfEb697Fe59Bb464Fc49299ef5563; // wallet for 15%
    restrictedPercent = 15; // 15% procent for Founders, Bounties, Distribution cost, Management costs
    rate = 1000000000000000000000; //rate
    start = 1522195200;  //start date
    period = 63; // ico period
  }

  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }

    /*
    Bonus: 
    private ico 40% (min 20 eth) 28.03-05.04
    pre-ico 30% (min 0.5 eth) 05.04-20.04
    main ico
    R1(20.04-26.04): +15%min deposit 0.1ETH;    
    R2(27.04-06.05): +10% min deposit 0.1ETH;  
    R3(07.05-15.05): +5% bonus; min deposit 0.1ETH;  
    R4(16.05-30.05): 0% bonus;  min deposit 0.1ETH;
    */    

function createTokens() saleIsOn payable {
   multisig.transfer(msg.value);
   uint tokens = rate.mul(msg.value).div(1 ether);
   uint bonusTokens = 0;
   uint saleTime = period * 1 days;
   if(now >= start && now < start + 8 * 1 days) {
       bonusTokens = tokens.mul(40).div(100);
   } else if(now >= start + 8 * 1 days && now < start + 24 * 1 days) {
       bonusTokens = tokens.mul(30).div(100);
   } else if(now >= start + 24 * 1 days && now <= start + 30 * 1 days) {
       bonusTokens = tokens.mul(15).div(100);
   } else if(now >= start + 31 * 1 days && now <= start + 40 * 1 days) {
       bonusTokens = tokens.mul(10).div(100);
   } else if(now >= start + 41 * 1 days && now <= start + 49 * 1 days) {
       bonusTokens = tokens.mul(5).div(100);
   } else if(now >= start + 50 * 1 days && now <= start + 64 * 1 days) {
       bonusTokens = 0;
   } else {
       bonusTokens = 0;
   }
   uint tokensWithBonus = tokens.add(bonusTokens);
   token.transfer(msg.sender, tokensWithBonus);
   uint restrictedTokens = tokens.mul(restrictedPercent).div(100 - restrictedPercent);
   token.transfer(restricted, restrictedTokens);
 }

  function() external payable {
    createTokens();
  }
    
}