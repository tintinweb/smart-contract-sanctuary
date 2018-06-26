pragma solidity ^0.4.23;

 /**
 * FLEX Network v0.1.16 (flexnetwork@avn.systems)
 * The official website is https://flexnetwork.avn.systems
 * 
 * Faucet smart contract for ERC20Basic Tokens
 * 
 * The uints are all in wei and atto tokens (*10^-18)

 * The contract code itself, as usual, is at the end, after all the connected libraries
 * Developed by Allan Avelar (contact@allanavelar.com)
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint a, uint b) internal pure returns (uint) {
    return a >= b ? a : b;
  }
  function min256(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
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
   * Fix for the ERC20 short address attack  
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
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
  
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(_to != address(0) && _value <= balances[_from] && _value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Deprecated is Ownable {

    bool private _deprecated;

    modifier deprecated {
        assert(!_deprecated);
        _;
    }
    function setDeprecated(bool _status) public onlyOwner {
        _deprecated = _status;
    }
    function isDeprecated() public view returns (bool) {
        return _deprecated;
    }
}

contract FlexFaucet is Deprecated {
    using SafeMath for uint;
    
    string public name;
    string public version;

    event Deposit(address indexed sender, uint256 value);
    
    event TokenSent(address receiver, uint amout);
    
    event FaucetOn(bool status);
    event FaucetOff(bool status);

    uint private constant atto = 1000000000000000000;
    uint private constant hour = 1 hours;
    
    uint private maxDrip = 30 * atto;
    
    bool public faucetStatus;
    mapping(address => uint256) status;

    modifier faucetOn {
        require(faucetStatus);
        _;
    }
    modifier faucetOff {
        require(!faucetStatus);
        _;
    }

    constructor(string _name, string _version) public {
        version = _version;
        name = _name;
        
        faucetStatus = true;
        emit FaucetOn(faucetStatus);
    }

    function() public payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }
    
    function transfer(
        address _erc, address _to, uint _value
        ) public onlyOwner faucetOn
        returns (bool) {
        uint oldERCBalance = ERC20(_erc).balanceOf(_to);
        if (!StandardToken(_erc).transfer(_to, _value)) {
            if (ERC20(_erc).balanceOf(_to) <= oldERCBalance ||
            ERC20(_erc).balanceOf(_to) != oldERCBalance.add(_value)) {
                revert();
            }
        }
        return true;
    }
    function turnFaucetOn()
        public onlyOwner faucetOff
        returns(bool) {
        faucetStatus = true;
        emit FaucetOn(faucetStatus);
        return true;
    }
    function turnFaucetOff()
        public onlyOwner faucetOn()
        returns(bool) {
        faucetStatus = false;
        emit FaucetOff(faucetStatus);
        return true;
    }

    function dripToken(
        address _erc, uint amount
        ) public faucetOn
        returns(bool) {
        require(
            canDrip(msg.sender) && amount >= atto && amount <= maxDrip
            && StandardToken(_erc).balanceOf(address(this)) >= amount
        );
        
        uint oldERCBalance = ERC20(_erc).balanceOf(msg.sender);
        if (!StandardToken(_erc).transfer(msg.sender, amount)) {
            if (ERC20(_erc).balanceOf(msg.sender) <= oldERCBalance ||
            ERC20(_erc).balanceOf(msg.sender) != oldERCBalance.add(amount)) {
                revert();
            }
        }
        
        updateStatus(msg.sender, ((amount / atto) * hour));

        emit TokenSent(msg.sender, amount);
        return true;
    }

    function canDrip(
        address _address
        ) public view
        returns (bool) {
        return (status[_address] == 0)  ? true :
            (block.timestamp >= status[_address])
                ? true : false;
    }

    function waitTime(
        address _address
        ) public view
        returns (uint) {
        return status[_address] > 0 ? status[_address].sub(block.timestamp) : 0;
    }

    function updateStatus(
        address _address, uint256 _timelock
        ) internal
        returns (bool) {
        status[_address] = block.timestamp.add(_timelock);
        return true;
    }

}