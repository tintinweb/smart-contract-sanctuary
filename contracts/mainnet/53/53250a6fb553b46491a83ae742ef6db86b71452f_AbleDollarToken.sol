/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of &quot;user permissions&quot;. 
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
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
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
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    //  To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require(_value == 0);
    require(allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;


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
  function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
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
 * @title AbleTokoen
 * @dev The main ABLE token contract
 * 
 * ABI 
 * [{&quot;constant&quot;: true,&quot;inputs&quot;: [],&quot;name&quot;: &quot;mintingFinished&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;bool&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: true,&quot;inputs&quot;: [],&quot;name&quot;: &quot;name&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;string&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: false,&quot;inputs&quot;: [{&quot;name&quot;: &quot;_spender&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;name&quot;: &quot;_value&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;name&quot;: &quot;approve&quot;,&quot;outputs&quot;: [],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;nonpayable&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: true,&quot;inputs&quot;: [],&quot;name&quot;: &quot;totalSupply&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: false,&quot;inputs&quot;: [{&quot;name&quot;: &quot;_from&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;name&quot;: &quot;_to&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;name&quot;: &quot;_value&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;name&quot;: &quot;transferFrom&quot;,&quot;outputs&quot;: [],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;nonpayable&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: false,&quot;inputs&quot;: [],&quot;name&quot;: &quot;startTrading&quot;,&quot;outputs&quot;: [],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;nonpayable&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: true,&quot;inputs&quot;: [],&quot;name&quot;: &quot;decimals&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: false,&quot;inputs&quot;: [{&quot;name&quot;: &quot;_to&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;name&quot;: &quot;_amount&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;name&quot;: &quot;mint&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;bool&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;nonpayable&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: true,&quot;inputs&quot;: [],&quot;name&quot;: &quot;tradingStarted&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;bool&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: true,&quot;inputs&quot;: [{&quot;name&quot;: &quot;_owner&quot;,&quot;type&quot;: &quot;address&quot;}],&quot;name&quot;: &quot;balanceOf&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;balance&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: false,&quot;inputs&quot;: [],&quot;name&quot;: &quot;stopTrading&quot;,&quot;outputs&quot;: [],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;nonpayable&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: false,&quot;inputs&quot;: [],&quot;name&quot;: &quot;finishMinting&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;bool&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;nonpayable&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: true,&quot;inputs&quot;: [],&quot;name&quot;: &quot;owner&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;address&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: true,&quot;inputs&quot;: [],&quot;name&quot;: &quot;symbol&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;&quot;,&quot;type&quot;: &quot;string&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: false,&quot;inputs&quot;: [{&quot;name&quot;: &quot;_to&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;name&quot;: &quot;_value&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;name&quot;: &quot;transfer&quot;,&quot;outputs&quot;: [],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;nonpayable&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: true,&quot;inputs&quot;: [{&quot;name&quot;: &quot;_owner&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;name&quot;: &quot;_spender&quot;,&quot;type&quot;: &quot;address&quot;}],&quot;name&quot;: &quot;allowance&quot;,&quot;outputs&quot;: [{&quot;name&quot;: &quot;remaining&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;view&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;constant&quot;: false,&quot;inputs&quot;: [{&quot;name&quot;: &quot;newOwner&quot;,&quot;type&quot;: &quot;address&quot;}],&quot;name&quot;: &quot;transferOwnership&quot;,&quot;outputs&quot;: [],&quot;payable&quot;: false,&quot;stateMutability&quot;: &quot;nonpayable&quot;,&quot;type&quot;: &quot;function&quot;},{&quot;anonymous&quot;: false,&quot;inputs&quot;: [{&quot;indexed&quot;: true,&quot;name&quot;: &quot;to&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;indexed&quot;: false,&quot;name&quot;: &quot;value&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;name&quot;: &quot;Mint&quot;,&quot;type&quot;: &quot;event&quot;},{&quot;anonymous&quot;: false,&quot;inputs&quot;: [],&quot;name&quot;: &quot;MintFinished&quot;,&quot;type&quot;: &quot;event&quot;},{&quot;anonymous&quot;: false,&quot;inputs&quot;: [{&quot;indexed&quot;: true,&quot;name&quot;: &quot;owner&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;indexed&quot;: true,&quot;name&quot;: &quot;spender&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;indexed&quot;: false,&quot;name&quot;: &quot;value&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;name&quot;: &quot;Approval&quot;,&quot;type&quot;: &quot;event&quot;},{&quot;anonymous&quot;: false,&quot;inputs&quot;: [{&quot;indexed&quot;: true,&quot;name&quot;: &quot;from&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;indexed&quot;: true,&quot;name&quot;: &quot;to&quot;,&quot;type&quot;: &quot;address&quot;},{&quot;indexed&quot;: false,&quot;name&quot;: &quot;value&quot;,&quot;type&quot;: &quot;uint256&quot;}],&quot;name&quot;: &quot;Transfer&quot;,&quot;type&quot;: &quot;event&quot;}]
 */
contract AbleDollarToken is MintableToken {

  string public name = &quot;ABLE Dollar Token&quot;;
  string public symbol = &quot;ABLD&quot;;
  uint public decimals = 18;

  bool public tradingStarted = false;

  /**
   * @dev modifier that throws if trading has not started yet
   */
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

  /**
   * @dev Allows the owner to enable the trading.
   */
  function startTrading() onlyOwner {
    tradingStarted = true;
  }
  
  /**
   * @dev Allows the owner to disable the trading.
   */
  function stopTrading() onlyOwner {
    tradingStarted = false;
  }

  /**
   * @dev Allows anyone to transfer the ABLE tokens once trading has started
   * @param _to the recipient address of the tokens. 
   * @param _value number of tokens to be transfered. 
   */
  function transfer(address _to, uint _value) hasStartedTrading {
    super.transfer(_to, _value);
  }

   /**
   * @dev Allows anyone to transfer the ABLE tokens once trading has started
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading {
    super.transferFrom(_from, _to, _value);
  }

}