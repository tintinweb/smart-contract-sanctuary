pragma solidity ^0.4.11;

/**
 *================ 
 * Avalon tokens =
 *================
 *
 * Please be careful before trusting a contract. Counter-ways may exist. To ensure that the contract is genuine, 
 * check that the address of the contract is the one that these authors have made public. 
 * Please refer only to the websites you trust. It can be:
 * - https://avalon.nu/CertificateOfAuthenticitity
 * - https://www.facebook.com/avalonplatform/
 * - https://github.com/AvalonPlatform/AvalonToken
 * - Use the token search engine of etherscan.io and make sure you have the green check mark (token verified)
 */

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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  uint256 public tokenCapped = 0;  //Limit number of tokens created


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
    require(totalSupply.add(_amount) <= tokenCapped);
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


/**
 * Avalon tokens
 */
contract AvalonToken is MintableToken {
  string public constant name = "Avalon";
  string public constant symbol = "AVA";
  uint public constant decimals = 4;
 
  function AvalonToken() {
     tokenCapped = 100000000000; // Capped to 10 million of tokens 

     // The minting is entirely carried out in this constructor function.

     // 8,700,000 AVA are sent to TokenLot for distribution
     mint(0x993ca291697eb994e17a1f0dbe9053d57b8aec8e,87000000000);

     // 1,300,000 AVA are kept by Avalon (= 65,000 * 20)
     mint(0x94325b00aeebdac34373ee7e15f899d51a17af42,650000000);
     mint(0x6720919702089684870d4afd0f5175c77f82c051,650000000);
     mint(0x77c3ff7ee29896943fd99d0339a67bae5762234c,650000000);
     mint(0x66585aafe1dcf5c4a382f55551a8efbb93b023b3,650000000);
     mint(0x13adbcbaf8da7f85fc3c7fd2e4e08bc6afcb59f3,650000000);
     mint(0x2f7444f6bdbc5ff4adc310e08ed8e2d288cbf81f,650000000);
     mint(0xb88f5ae2d3afcc057359a678d745fb6e7d9d4567,650000000);
     mint(0x21df7143f56e71c2c49c7ecc585fa88d70bd3d11,650000000);
     mint(0xb4e3603b879f152766e8f58829dae173a048f6da,650000000);
     mint(0xf58184d03575d5f8be93839adca9e0ed5280d4a8,650000000);
     mint(0x313d17995920f4d1349c1c6aaeacc6b5002cc4c2,650000000);
     mint(0xdbf062603dd285ec3e4b4fab97ecde7238bd3ee4,650000000);
     mint(0x6047c67e3c7bcbb8e909f4d8ae03631ec9b94dab,650000000);
     mint(0x0871ea40312df5e72bb6bde14973deddab17cf15,650000000);
     mint(0xc321024cfb029bcde6d6a541553e1b262e95f834,650000000);
     mint(0x1247e829e74ad09b0bb1a95830efacebfa7f472b,650000000);
     mint(0x04ff81425d96f12eaae5f320e2bd4e0c5d2d575a,650000000);
     mint(0xbc1425541f61958954cfd31843bd9f6c15319c66,650000000);
     mint(0xd890ab57fbd2724ae28a02108c29c191590e1045,650000000);
     mint(0xf741f6a1d992cd8cc9cbec871c7dc4ed4d683376,650000000);

     finishMinting(); // Double security to prevent the minting of new tokens later
  } 
}