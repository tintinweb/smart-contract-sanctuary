pragma solidity ^0.4.16;

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
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}



contract DEST  is StandardToken {

  // Constants
  // =========

  string public constant name = "Decentralized Escrow Token";
  string public constant symbol = "DEST";
  uint   public constant decimals = 18;

  uint public constant ETH_MIN_LIMIT = 500 ether;
  uint public constant ETH_MAX_LIMIT = 1500 ether;

  uint public constant START_TIMESTAMP = 1503824400; // 2017-08-27 09:00:00 UTC
  uint public constant END_TIMESTAMP   = 1506816000; // 2017-10-01 00:00:00 UTC

  address public constant wallet = 0x51559EfC1AcC15bcAfc7E0C2fB440848C136A46B;


  // State variables
  // ===============

  uint public ethCollected;
  mapping (address=>uint) ethInvested;


  // Constant functions
  // =========================

  function hasStarted() public constant returns (bool) {
    return now >= START_TIMESTAMP;
  }


  // Payments are not accepted after ICO is finished.
  function hasFinished() public constant returns (bool) {
    return now >= END_TIMESTAMP || ethCollected >= ETH_MAX_LIMIT;
  }


  // Investors can move their tokens only after ico has successfully finished
  function tokensAreLiquid() public constant returns (bool) {
    return (ethCollected >= ETH_MIN_LIMIT && now >= END_TIMESTAMP)
      || (ethCollected >= ETH_MAX_LIMIT);
  }


  function price(uint _v) public constant returns (uint) {
    return // poor man&#39;s binary search
      _v < 7 ether
        ? _v < 3 ether
          ? _v < 1 ether
            ? 1000
            : _v < 2 ether ? 1005 : 1010
          : _v < 4 ether
            ? 1015
            : _v < 5 ether ? 1020 : 1030
        : _v < 14 ether
          ? _v < 10 ether
            ? _v < 9 ether ? 1040 : 1050
            : 1080
          : _v < 100 ether
            ? _v < 20 ether ? 1110 : 1150
            : 1200;
  }


  // Public functions
  // =========================

  function() public payable {
    require(hasStarted() && !hasFinished());
    require(ethCollected + msg.value <= ETH_MAX_LIMIT);

    ethCollected += msg.value;
    ethInvested[msg.sender] += msg.value;

    uint _tokenValue = msg.value * price(msg.value);
    balances[msg.sender] += _tokenValue;
    totalSupply += _tokenValue;
    Transfer(0x0, msg.sender, _tokenValue);
  }


  // Investors can get refund if ETH_MIN_LIMIT is not reached.
  function refund() public {
    require(ethCollected < ETH_MIN_LIMIT && now >= END_TIMESTAMP);
    require(balances[msg.sender] > 0);

    totalSupply -= balances[msg.sender];
    balances[msg.sender] = 0;
    uint _ethRefund = ethInvested[msg.sender];
    ethInvested[msg.sender] = 0;
    msg.sender.transfer(_ethRefund);
  }


  // Owner can withdraw all the money after min_limit is reached.
  function withdraw() public {
    require(ethCollected >= ETH_MIN_LIMIT);
    wallet.transfer(this.balance);
  }


  // ERC20 functions
  // =========================

  function transfer(address _to, uint _value) public returns (bool)
  {
    require(tokensAreLiquid());
    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint _value)
    public returns (bool)
  {
    require(tokensAreLiquid());
    return super.transferFrom(_from, _to, _value);
  }


  function approve(address _spender, uint _value)
    public returns (bool)
  {
    require(tokensAreLiquid());
    return super.approve(_spender, _value);
  }
}