pragma solidity 0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) view public returns (uint256);
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
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  //время заморозки токенов для команды 2018-10-31T00:00:00+00:00 in ISO 8601
  uint public constant timeFreezeTeamTokens = 1540944000;
  
  address public walletTeam = 0x7eF1ac89B028A9Bc20Ce418c1e6973F4c7977eB0;

  modifier onlyPayloadSize(uint size) {
       assert(msg.data.length >= size + 4);
       _;
   }
   
   modifier canTransfer() {
       if(msg.sender == walletTeam){
          require(now > timeFreezeTeamTokens); 
       }
        _;
   }



  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value)canTransfer onlyPayloadSize(2 * 32) public returns (bool) {
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
  function balanceOf(address _owner) view public returns (uint256 balance) {
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
  function transferFrom(address _from, address _to, uint256 _value)canTransfer public returns (bool) {
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
  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
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
  function Ownable() public{
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
  function transferOwnership(address newOwner) onlyOwner public{
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

/**
* @dev https://t.me/devKatAlexeeva
*/

contract LoanBit is BurnableToken, Ownable {
    
    string public constant name = "LoanBit";
    
    string public constant symbol = "LBT";
    
    uint public constant decimals = 18;
    
    
    
    //Внутренние кошельки компании
    address public walletICO =     0x8ffF4a8c4F1bd333a215f072ef9AEF934F677bFa;
    uint public tokenICO = 31450000*10**decimals; 
    address public walletTeam =    0x7eF1ac89B028A9Bc20Ce418c1e6973F4c7977eB0;
    uint public tokenTeam = 2960000*10**decimals; 
    address public walletAdvisor = 0xB6B01233cE7794D004aF238b3A53A0FcB1c5D8BD;
    uint public tokenAdvisor = 1480000*10**decimals; 
    
    //кошельки для баунти программы
    
    address public walletAvatar =   0x9E6bA5600cF5f4656697E3aF2A963f56f522991C;
    uint public tokenAvatar = 444000*10**decimals;
    address public walletFacebook = 0x43827ba49d8eBd20afD137791227d3139E5BD074;
    uint public tokenFacebook = 155400*10**decimals;
    address public walletTwitter =  0xeFF945E9F29eA8c7a94F84Fb9fFd711d179ab520;
    uint public tokenTwitter = 155400*10**decimals;
    address public walletBlogs   =  0x16Df4Dc0Dd47dDD47759d54957C021650c76aed1;
    uint public tokenBlogs = 210900*10**decimals;
    address public walletTranslate =  0x19A903405fDcce9b32f48882C698A3842f09253F;
    uint public tokenTranslate = 133200*10**decimals;
    address public walletEmail   =  0x3912AE42372ff35f56d2f7f26313da7F48Fe5248;
    uint public tokenEmail = 11100*10**decimals;
    
    //кошелек разработчика
    address public walletDev = 0xF4e16e79102B19702Cc10Cbcc02c6EC0CcAD8b1D;
    uint public tokenDev = 6000*10**decimals;
    
    function LoanBit()public{
        
        totalSupply = 37000000*10**decimals;
        
        balances[walletICO] = tokenICO;
        transferFrom(this,walletICO, 0);
        
        
        balances[walletTeam] = tokenTeam;
        transferFrom(this,walletTeam, 0);
        
        
        balances[walletAdvisor] = tokenAdvisor;
        transferFrom(this,walletAdvisor, 0);
        
        balances[walletDev] = tokenDev;
        transferFrom(this,walletDev, 0);
        
        balances[walletAvatar] = tokenAvatar;
        transferFrom(this,walletAvatar, 0);
        
        balances[walletFacebook] = tokenFacebook;
        transferFrom(this,walletFacebook, 0);
        
        balances[walletTwitter] = tokenTwitter;
        transferFrom(this,walletTwitter, 0);
        
        balances[walletBlogs] = tokenBlogs;
        transferFrom(this,walletBlogs, 0);
        
        balances[walletTranslate] = tokenTranslate;
        transferFrom(this,walletTranslate, 0);
        
        balances[walletEmail] = tokenEmail;
        transferFrom(this,walletEmail, 0);
        
    }
    
   
}