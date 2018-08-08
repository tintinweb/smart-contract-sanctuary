pragma solidity ^0.4.18;

// Latino Token - Latinos Unidos Impulsando la CriptoEconom&#237;a - latinotoken.com


/**
 * @title ERC20Basic interface
 * @dev Basic version of ERC20 interface
 */

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev Standard version of ERC20 interface
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

  function mod(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a % b;
    //uint256 z = a / b;
    assert(a == (a / b) * b + c); // There is no case in which this doesn&#39;t hold
    return c;
  }

}

/**
 * @title Ownable
 * @dev The modified Ownable contract has two owner addresses to provide authorization control
 * functions.
 */
contract Ownable {

  address public owner;
  address public ownerManualMinter; 

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    /**
    * ownerManualMinter contains the eth address of the party allowed to manually mint outside the crowdsale contract
    * this is setup at construction time 
    */ 

    ownerManualMinter = 0xd97c302e9b5ee38ab900d3a07164c2ad43ffc044 ; // To be changed right after contract is deployed
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == ownerManualMinter);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * This shall be invoked with the ICO crowd sale smart contract address once it&#180;s ready
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

/**
   * @dev After the manual minting process ends, this shall be invoked passing the ICO crowd sale contract address so that
   * nobody else will be ever able to mint more tokens
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnershipManualMinter(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    ownerManualMinter = newOwner;
  }

}

contract Restrictable is Ownable {
    
    address public restrictedAddress;
    
    event RestrictedAddressChanged(address indexed restrictedAddress);
    
    function Restrictable() {
        restrictedAddress = address(0);
    }
    
    //that function could be called only ONCE!!! After that nothing could be reverted!!! 
    function setRestrictedAddress(address _restrictedAddress) onlyOwner public {
      restrictedAddress = _restrictedAddress;
      RestrictedAddressChanged(_restrictedAddress);
      transferOwnership(_restrictedAddress);
    }
    
    modifier notRestricted(address tryTo) {
        if(tryTo == restrictedAddress) {
            revert();
        }
        _;
    }
}

/**
 * @title ERC20Basic Token
 * @dev Implementation of the basic token.
 */

contract BasicToken is ERC20Basic, Restrictable {

  using SafeMath for uint256;

  mapping(address => uint256) balances;
  uint256 public constant icoEndDatetime = 1521035143 ; 

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */

  function transfer(address _to, uint256 _value) notRestricted(_to) public returns (bool) {
    require(_to != address(0));
    
    // We won&#180;t allow to transfer tokens until the ICO finishes
    require(now > icoEndDatetime ); 

    require(_value <= balances[msg.sender]);
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
 * @title Standard ERC20 Token
 * @dev Implementation of the standard token.
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) notRestricted(_to) public returns (bool) {
    require(_to != address(0));
    
    // We won&#180;t allow to transfer tokens until the ICO finishes
    require(now > icoEndDatetime) ; 


    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
  function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729


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

 /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Mintable token
 * @dev ERC20 Token, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {

  uint32 public constant decimals = 4;
  uint256 public constant MAX_SUPPLY = 700000000 * (10 ** uint256(decimals)); // 700MM tokens hard cap

  event Mint(address indexed to, uint256 amount);

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */

  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    uint256 newTotalSupply = totalSupply.add(_amount);
    require(newTotalSupply <= MAX_SUPPLY); // never ever allows to create more than the hard cap limit
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

}

contract LATIME is MintableToken 
{
  string public constant name = "LATIME";
  string public constant symbol = "LATIME";

 function LATIME() { totalSupply = 0 ; } // initializes to 0 the total token supply 
}