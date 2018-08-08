pragma solidity 0.4.14;

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
   * @dev revert()s if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
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



/**
 * Math operations with safety checks
 */
library SafeMath {
  
  
  function mul256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div256(uint256 a, uint256 b) internal returns (uint256) {
    require(b > 0); // Solidity automatically revert()s when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub256(uint256 a, uint256 b) internal returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add256(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }  
  

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev ERC20 interface with allowances. 
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    balances[_to] = balances[_to].add256(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 * @dev Implemantation of the basic standart token.
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value > _allowance) revert();

    balances[_to] = balances[_to].add256(_value);
    balances[_from] = balances[_from].sub256(_value);
    allowed[_from][msg.sender] = _allowance.sub256(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    //  To change the approve amount you first have to reduce the addresses
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



/**
 * @title TeuToken
 * @dev The main TEU token contract
 * 
 */
 
contract TeuToken is StandardToken, Ownable{
  string public name = "20-footEqvUnit";
  string public symbol = "TEU";
  uint public decimals = 18;

  event TokenBurned(uint256 value);
  
  function TeuToken() {
    totalSupply = (10 ** 8) * (10 ** decimals);
    balances[msg.sender] = totalSupply;
  }

  /**
   * @dev Allows the owner to burn the token
   * @param _value number of tokens to be burned.
   */
  function burn(uint _value) onlyOwner {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub256(_value);
    totalSupply = totalSupply.sub256(_value);
    TokenBurned(_value);
  }

}