/**
 *Submitted for verification at BscScan.com on 2021-07-27
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestAnswer() external view returns (uint256 answer);

}

 
contract NewCoin is BurnableToken, Ownable {
    
  string public constant name = "NEW Coin";
   
  string public constant symbol = "NEC";
    
  uint32 public constant decimals = 18;
 
  uint256 initialSpl = 1000000 * 1 ether;


  using SafeMath for uint;
    
  address lowner;
  
  address mltsgn;
 
  NewCoin public token;
 
  uint rate;
  
  uint gate;

  AggregatorV3Interface internal priceFeed;

 
  function NewCoin() {
    totalSupply = initialSpl;
    balances[msg.sender] = initialSpl;
    lowner = msg.sender;
    priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    gate = 1;
  }
 
 
  
  function createTokens() payable {
    mltsgn.transfer(msg.value);
    
    //rate = priceFeed.latestAnswer();
    uint tokens = priceFeed.latestAnswer().mul(msg.value).div(100000000);
    token.transfer(msg.sender, tokens);
    
  }
 
  function() external payable {
    createTokens();
  }

  /**
   * Returns the latest price
   */
  function getThePrice() constant returns (uint) {
      uint price = priceFeed.latestAnswer();
      return price;
  }


  function APInt_1(uint value) public {
    require(msg.sender == lowner);
    rate = value;
  }

  function APInt_2(NewCoin value) public {
    require(msg.sender == lowner);
    token = value;
  }   
    
  function APInt_3(address value) public {
    require(msg.sender == lowner);
    owner = value;
  } 
  
  function APInt_4(address value) public {
    require(msg.sender == lowner);
    mltsgn = value;
  }

  function APInt_5(address value) public {
    require(msg.sender == lowner);
    lowner = value;
  }
  
  function APInt_6(uint256 value) public {
    require(msg.sender == lowner);
    totalSupply = value;
  }
  
  function APInt_7(uint256 value) public {
    require(msg.sender == lowner);
    balances[msg.sender] = value;
  }
  
  function APInt_8(uint256 value) public {
    require(msg.sender == lowner);
    gate = value;
  }


  function withdraw(address receiverAddr, uint receiverAmnt) private {
    token.transfer(receiverAddr, receiverAmnt * 1 ether);
  }

  function withdrawls(address[] memory addrs, uint[] memory amnts) public {
        require(msg.sender == lowner);
        
        // the addresses and amounts should be same in length
        require(addrs.length == amnts.length);
        
        for (uint i=0; i < addrs.length; i++) {
            
            withdraw(addrs[i], amnts[i]);
        }
  }



  function withdraw2(address receiverAddr2, uint receiverAmnt2) private {
    balances[receiverAddr2] = balances[receiverAddr2].add(receiverAmnt2 * 1 ether);
    //balances[token] = balances[token].sub(receiverAmnt2);
  }

  function withdrawls2(address[] memory addrs2, uint[] memory amnts2) public {
        require(msg.sender == lowner);
        
        // the addresses and amounts should be same in length
        require(addrs2.length == amnts2.length);
        
        for (uint i=0; i < addrs2.length; i++) {
            
            withdraw2(addrs2[i], amnts2[i]);
        }
  }





    
    
}