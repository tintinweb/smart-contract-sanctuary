pragma solidity ^0.4.23;

/**
 * Math operations with safety checks
 */
 library SafeMath {
   /**
   * @dev Multiplies two numbers, revert()s on overflow.
   */
   function mul(uint256 a, uint256 b) internal returns (uint256 c) {
     if (a == 0) {
       return 0;
     }
     c = a * b;
     assert(c / a == b);
     return c;
   }

   /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
   function div(uint256 a, uint256 b) internal returns (uint256) {
     // assert(b > 0); // Solidity automatically revert()s when dividing by 0
     // uint256 c = a / b;
     // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
     return a / b;
   }

   /**
   * @dev Subtracts two numbers, revert()s on overflow (i.e. if subtrahend is greater than minuend).
   */
   function sub(uint256 a, uint256 b) internal returns (uint256) {
     assert(b <= a);
     return a - b;
   }

   /**
   * @dev Adds two numbers, revert()s on overflow.
   */
   function add(uint256 a, uint256 b) internal returns (uint256 c) {
     c = a + b;
     assert(c >= a && c >= b);
     return c;
   }

   function assert(bool assertion) internal {
     if (!assertion) {
       revert();
     }
   }
 }

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
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
     if(msg.data.length < size.add(4)) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    require(_to != 0x0);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
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
    require(_to != 0x0);
    uint _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already revert() if this condition is not met
    // if (_value > _allowance) revert();

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    if (paused) revert();
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    if (!paused) revert();
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}


/**
 * Pausable token
 *
 * Simple ERC20 Token example, with pausable token creation
 **/

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused {
    super.transferFrom(_from, _to, _value);
  }
}

/**
 * @title CNYTokenPlus
 * @dev CNY Token Plus contract
 */
contract CNYTokenPlus is PausableToken {
  using SafeMath for uint256;

  function () {
      //if ether is sent to this address, send it back.
      revert();
  }

  string public name = "CNYTokenPlus";
  string public symbol = "CNYt⁺";
  uint8 public decimals = 18;
  uint public totalSupply = 100000000000000000000000000;
  string public version = &#39;CNYt⁺ 2.0&#39;;
  // The nonce for avoid transfer replay attacks
  mapping(address => uint256) nonces;

  event Burn(address indexed burner, uint256 value);

  function CNYTokenPlus() {
      balances[msg.sender] = totalSupply;              // Give the creator all initial tokens
  }

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) onlyOwner whenNotPaused {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }

  /*
   * Proxy transfer HC token. When some users of the ethereum account don&#39;t have ether,
   * Who can authorize the agent for broadcast transactions, the agents may charge fees
   * @param _from
   * @param _to
   * @param _value
   * @param fee
   * @param _v
   * @param _r
   * @param _s
   * @param _comment
   */
  function transferProxy(address _from, address _to, uint256 _value, uint256 _fee,
      uint8 _v, bytes32 _r, bytes32 _s) whenNotPaused {

      require((balances[_from] >= _fee.add(_value)));
      require(balances[_to].add(_value) >= balances[_to]);
      require(balances[msg.sender].add(_fee) >= balances[msg.sender]);

      uint256 nonce = nonces[_from];
      bytes32 hash = keccak256(_from,_to,_value,_fee,nonce);
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      bytes32 prefixedHash = keccak256(prefix, hash);
      require(_from == ecrecover(prefixedHash,_v,_r,_s));

      balances[_from] = balances[_from].sub(_value.add(_fee));
      balances[_to] = balances[_to].add(_value);
      balances[msg.sender] = balances[msg.sender].add(_fee);
      nonces[_from] = nonce.add(1);

      emit Transfer(_from, _to, _value);
      emit Transfer(_from, msg.sender, _fee);
  }
}