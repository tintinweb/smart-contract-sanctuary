pragma solidity ^0.4.24;



/* ********** Zeppelin Solidity - v1.3.0 ********** */



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
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
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
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
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
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
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
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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



/* ********** RxEAL Token Contract ********** */



/**
 * @title RxEALTokenContract
 * @author RxEAL.com
 *
 * ERC20 Compatible token
 * Zeppelin Solidity - v1.3.0
 */

contract RxEALTokenContract is StandardToken {

  /* ********** Token Predefined Information ********** */

  // Predefine token info
  string public constant name = "RxEAL";
  string public constant symbol = "RXL";
  uint256 public constant decimals = 18;

  /* ********** Defined Variables ********** */

  // Total tokens supply 96 000 000
  // For ethereum wallets we added decimals constant
  uint256 public constant INITIAL_SUPPLY = 96000000 * (10 ** decimals);
  // Vault where tokens are stored
  address public vault = this;
  // Sale agent who has permissions to sell tokens
  address public salesAgent;
  // Array of token owners
  mapping (address => bool) public owners;

  /* ********** Events ********** */

  // Contract events
  event OwnershipGranted(address indexed _owner, address indexed revoked_owner);
  event OwnershipRevoked(address indexed _owner, address indexed granted_owner);
  event SalesAgentPermissionsTransferred(address indexed previousSalesAgent, address indexed newSalesAgent);
  event SalesAgentRemoved(address indexed currentSalesAgent);
  event Burn(uint256 value);

  /* ********** Modifiers ********** */

  // Throws if called by any account other than the owner
  modifier onlyOwner() {
    require(owners[msg.sender] == true);
    _;
  }

  /* ********** Functions ********** */

  // Constructor
  function RxEALTokenContract() {
    owners[msg.sender] = true;
    totalSupply = INITIAL_SUPPLY;
    balances[vault] = totalSupply;
  }

  // Allows the current owner to grant control of the contract to another account
  function grantOwnership(address _owner) onlyOwner public {
    require(_owner != address(0));
    owners[_owner] = true;
    OwnershipGranted(msg.sender, _owner);
  }

  // Allow the current owner to revoke control of the contract from another owner
  function revokeOwnership(address _owner) onlyOwner public {
    require(_owner != msg.sender);
    owners[_owner] = false;
    OwnershipRevoked(msg.sender, _owner);
  }

  // Transfer sales agent permissions to another account
  function transferSalesAgentPermissions(address _salesAgent) onlyOwner public {
    SalesAgentPermissionsTransferred(salesAgent, _salesAgent);
    salesAgent = _salesAgent;
  }

  // Remove sales agent from token
  function removeSalesAgent() onlyOwner public {
    SalesAgentRemoved(salesAgent);
    salesAgent = address(0);
  }

  // Transfer tokens from vault to account if sales agent is correct
  function transferTokensFromVault(address _from, address _to, uint256 _amount) public {
    require(salesAgent == msg.sender);
    balances[vault] = balances[vault].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(_from, _to, _amount);
  }

  // Allow the current owner to burn a specific amount of tokens from the vault
  function burn(uint256 _value) onlyOwner public {
    require(_value > 0);
    balances[vault] = balances[vault].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_value);
  }

}



/* ********** RxEAL Distribution Contract ********** */



contract RxEALDistributionTokens {

  address public owner;
  RxEALTokenContract internal token;

  address[] internal addresses = [
    0x2a3B2C39AE3958B875033349fd573eD14886C2Ee,
    0x2d039F29929f2560e66A4A41656CBdE3D877951D,
    0x44b12554bDB95c40fd7A58d5745c8B33ab20e7B3
  ];

  uint256[] internal values = [
    600,
    600,
    1800
  ];

  constructor() public {
    owner = msg.sender;
    token = RxEALTokenContract(0xD6682Db9106e0cfB530B697cA0EcDC8F5597CD15);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }

  function _distribution(address[] _to, uint256[] _value) internal {
    assert(_to.length == _value.length);
    assert(_to.length <= 1000);

    for (uint8 i = 0; i < _to.length; i++) {
      uint256 _real_value = _value[i] * (10 ** token.decimals());
      token.transferTokensFromVault(msg.sender, _to[i], _real_value);
    }
  }

  function distributeTokens() public onlyOwner {
    _distribution(addresses, values);
  }

  function distributeTokens2(address[] _to, uint256[] _value) public onlyOwner {
    _distribution(_to, _value);
  }

}