pragma solidity ^0.4.23;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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

// File: contracts/FreezableToken.sol

/**
* @title Freezable Token
* @dev Token that can be freezed for chosen token holder.
*/
contract FreezableToken is Ownable {

    mapping (address => bool) public frozenList;

    event FrozenFunds(address indexed wallet, bool frozen);

    /**
    * @dev Owner can freeze the token balance for chosen token holder.
    * @param _wallet The address of token holder whose tokens to be frozen.
    */
    function freezeAccount(address _wallet) public onlyOwner {
        require(_wallet != address(0));
        frozenList[_wallet] = true;
        emit FrozenFunds(_wallet, true);
    }

    /**
    * @dev Owner can unfreeze the token balance for chosen token holder.
    * @param _wallet The address of token holder whose tokens to be unfrozen.
    */
    function unfreezeAccount(address _wallet) public onlyOwner {
        require(_wallet != address(0));
        frozenList[_wallet] = false;
        emit FrozenFunds(_wallet, false);
    }

    /**
    * @dev Check the specified token holder whether his/her token balance is frozen.
    * @param _wallet The address of token holder to check.
    */ 
    function isFrozen(address _wallet) public view returns (bool) {
        return frozenList[_wallet];
    }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: contracts/TokenTimelock.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    constructor(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
    * @notice Transfers tokens held by timelock to beneficiary.
    */
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        // Change  safeTransfer -> transfer because issue with assert function with ref type.
        token.transfer(beneficiary, amount);
    }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
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

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

// File: contracts/SaifuToken.sol

contract SaifuToken is StandardToken, FreezableToken {
    using SafeMath for uint256;

    string public constant name = "Saifu";
    string public constant symbol = "SFU";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_TOTAL_SUPPLY = 200e6 * (10 ** uint256(decimals));
    uint256 public constant AMOUNT_TOKENS_FOR_SELL = 130e6 * (10 ** uint256(decimals));

    uint256 public constant RESERVE_FUND = 20e6 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_FOR_TEAM = 50e6 * (10 ** uint256(decimals));

    uint256 public constant RESERVED_TOTAL_AMOUNT = 70e6 * (10 ** uint256(decimals));
    
    uint256 public alreadyReservedForTeam = 0;

    address public burnAddress;

    bool private isReservedFundsDone = false;

    uint256 private setBurnAddressCount = 0;

    // Key: address of wallet, Value: address of contract.
    mapping (address => address) private lockedList;

    /**
    * @dev Throws if called by any account other than the burnable account.
    */
    modifier onlyBurnAddress() {
        require(msg.sender == burnAddress);
        _;
    }

    /**
    * @dev Create SaifuToken contract
    */
    constructor() public {
        totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);

        balances[owner] = balances[owner].add(AMOUNT_TOKENS_FOR_SELL);
        emit Transfer(address(0), owner, AMOUNT_TOKENS_FOR_SELL);

        balances[this] = balances[this].add(RESERVED_TOTAL_AMOUNT);
        emit Transfer(address(0), this, RESERVED_TOTAL_AMOUNT);
    }

     /**
    * @dev Transfer token for a specified address.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!isFrozen(msg.sender));
        return super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!isFrozen(msg.sender));
        require(!isFrozen(_from));
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Set burn address.
    * @param _address New burn address
    */
    function setBurnAddress(address _address) public onlyOwner {
        require(setBurnAddressCount < 3);
        require(_address != address(0));
        burnAddress = _address;
        setBurnAddressCount = setBurnAddressCount.add(1);
    }

    /**
    * @dev Reserve funds.
    * @param _address the address for reserve funds. 
    */
    function reserveFunds(address _address) public onlyOwner {
        require(_address != address(0));

        require(!isReservedFundsDone);

        sendFromContract(_address, RESERVE_FUND);
        
        isReservedFundsDone = true;
    }

    /**
    * @dev Get locked contract address.
    * @param _address the address of owner these tokens.
    */
    function getLockedContract(address _address) public view returns(address) {
        return lockedList[_address];
    }

    /**
    * @dev Reserve for team.
    * @param _address the address for reserve. 
    * @param _amount the specified amount for reserve. 
    * @param _time the specified freezing time (in days). 
    */
    function reserveForTeam(address _address, uint256 _amount, uint256  _time) public onlyOwner {
        require(_address != address(0));
        require(_amount > 0 && _amount <= RESERVED_FOR_TEAM.sub(alreadyReservedForTeam));

        if (_time > 0) {
            address lockedAddress = new TokenTimelock(this, _address, now.add(_time * 1 days));
            lockedList[_address] = lockedAddress;
            sendFromContract(lockedAddress, _amount);
        } else {
            sendFromContract(_address, _amount);
        }
        
        alreadyReservedForTeam = alreadyReservedForTeam.add(_amount);
    }

    /**
    * @dev Send tokens which will be frozen for specified time.
    * @param _address the address for send. 
    * @param _amount the specified amount for send. 
    * @param _time the specified freezing time (in seconds). 
    */
    function sendWithFreeze(address _address, uint256 _amount, uint256  _time) public onlyOwner {
        require(_address != address(0) && _amount > 0 && _time > 0);

        address lockedAddress = new TokenTimelock(this, _address, now.add(_time));
        lockedList[_address] = lockedAddress;
        transfer(lockedAddress, _amount);
    }

    /**
    * @dev Unlock frozen tokens.
    * @param _address the address for which to release already unlocked tokens. 
    */
    function unlockTokens(address _address) public {
        require(lockedList[_address] != address(0));

        TokenTimelock lockedContract = TokenTimelock(lockedList[_address]);

        lockedContract.release();
    }

    /**
    * @dev Burn a specific amount of tokens.
    * @param _amount The Amount of tokens.
    */
    function burnFromAddress(uint256 _amount) public onlyBurnAddress {
        require(_amount > 0);
        require(_amount <= balances[burnAddress]);

        balances[burnAddress] = balances[burnAddress].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Transfer(burnAddress, address(0), _amount);
    }

    /*
    * @dev Send tokens from contract.
    * @param _address the address destination. 
    * @param _amount the specified amount for send.
     */
    function sendFromContract(address _address, uint256 _amount) internal {
        balances[this] = balances[this].sub(_amount);
        balances[_address] = balances[_address].add(_amount);
        emit Transfer(this, _address, _amount);
    }
}