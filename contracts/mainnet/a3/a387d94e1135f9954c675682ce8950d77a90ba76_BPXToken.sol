pragma solidity ^0.4.21;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev Owner validator
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


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title BasicToken
 * @dev Implementation of ERC20Basic
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in exsitence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function msgSender() 
        public
        view
        returns (address)
    {
        return msg.sender;
    }

    function transfer(
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);
        
        _preValidateTransfer(msg.sender, _to, _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function _preValidateTransfer(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        internal 
    {

    }
}

/**
 * @title StandardToken
 * @dev Base Of token
 */
contract StandardToken is ERC20, BasicToken, Ownable {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address the address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        _preValidateTransfer(_from, _to, _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].sub(_value);  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true; 
    } 

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
.   * @param _spender The address which will spend the funds.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed jto a spender. 
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

/**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
 * @title MintableToken
 * @dev Minting of total balance 
 */
contract MintableToken is StandardToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }
   
    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint
    * @return A boolean that indicated if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner   canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful. 
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}


/**
 * @title LockableToken
 * @dev locking of granted balance
 */
contract LockableToken is MintableToken {

    using SafeMath for uint256;

    /**
     * @dev Lock defines a lock of token
     */
    struct Lock {
        uint256 amount;
        uint256 expiresAt;
    }

    // granted to locks;
    mapping (address => Lock[]) public grantedLocks;

    function addLock(
        address _granted, 
        uint256 _amount, 
        uint256 _expiresAt
    ) 
        public 
        onlyOwner 
    {
        require(_amount > 0);
        require(_expiresAt > now);

        grantedLocks[_granted].push(Lock(_amount, _expiresAt));
    }

    function deleteLock(
        address _granted, 
        uint8 _index
    ) 
        public 
        onlyOwner 
    {
        Lock storage lock = grantedLocks[_granted][_index];

        delete grantedLocks[_granted][_index];
        for (uint i = _index; i < grantedLocks[_granted].length - 1; i++) {
            grantedLocks[_granted][i] = grantedLocks[_granted][i+1];
        }
        grantedLocks[_granted].length--;

        if (grantedLocks[_granted].length == 0)
            delete grantedLocks[_granted];
    }

    function transferWithLock(
        address _to, 
        uint256 _value,
        uint256[] _expiresAtList
    ) 
        public 
        onlyOwner
        returns (bool) 
    {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);

        uint256 count = _expiresAtList.length;
        if (count > 0) {
            uint256 devidedValue = _value.div(count);
            for (uint i = 0; i < count; i++) {
                addLock(_to, devidedValue, _expiresAtList[i]);  
            }
        }

        return transfer(_to, _value);
    }

    /**
        @param _from - _granted
        @param _to - no usable
        @param _value - amount of transfer
     */
    function _preValidateTransfer(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        internal
    {
        super._preValidateTransfer(_from, _to, _value);
        
        uint256 lockedAmount = getLockedAmount(_from);
        uint256 balanceAmount = balanceOf(_from);

        require(balanceAmount.sub(lockedAmount) >= _value);
    }


    function getLockedAmount(
        address _granted
    ) 
        public
        view
        returns(uint256)
    {

        uint256 lockedAmount = 0;

        Lock[] storage locks = grantedLocks[_granted];
        for (uint i = 0; i < locks.length; i++) {
            if (now < locks[i].expiresAt) {
                lockedAmount = lockedAmount.add(locks[i].amount);
            }
        }
        //uint256 balanceAmount = balanceOf(_granted);
        //return balanceAmount.sub(lockedAmount);

        return lockedAmount;
    }
    
}


contract BPXToken is LockableToken {

  string public constant name = "Bitcoin Pay";
  string public constant symbol = "BPX";
  uint32 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));

  /**
  * @dev Constructor that gives msg.sender all of existing tokens.
  */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
}