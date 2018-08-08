pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
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


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

/**
 * @title Autonomy
 * @dev Simpler version of an Democracy organization contract
 * @dev the inheritor should implement &#39;initialCongress&#39; at first
 */
contract Autonomy is Ownable {
    address public congress;

    modifier onlyCongress() {
        require(msg.sender == congress);
        _;
    }

    /**
     * @dev initialize a Congress contract address for this token 
     *
     * @param _congress address the congress contract address
     */
    function initialCongress(address _congress) onlyOwner public {
        require(_congress != address(0));
        congress = _congress;
    }

    /**
     * @dev set a Congress contract address for this token
     * must change this address by the last congress contract 
     *
     * @param _congress address the congress contract address
     */
    function changeCongress(address _congress) onlyCongress public {
        require(_congress != address(0));
        congress = _congress;
    }
}


interface tokenRecipient { 
    function receiveApproval(
        address _from, 
        uint256 _value,
        address _token, 
        bytes _extraData
    ) external; 
}

contract DRCToken is BurnableToken, MintableToken, PausableToken, Claimable, Autonomy {    
    string public name = "DRC Token";
    string public symbol = "DRCT";
    uint8 public decimals = 18;
    uint public INITIAL_SUPPLY = 0;

    // add map for recording the accounts that will not be allowed to transfer tokens
    mapping (address => bool) public frozenAccount;
    // record the amount of tokens that have been frozen
    mapping (address => uint256) public frozenAmount;
    event FrozenFunds(address indexed _target, bool _frozen);
    event FrozenFundsPartialy(address indexed _target, bool _frozen, uint256 _value);

    event BurnFrom(address from, address burner, uint256 value);

    /**
     * contruct the token by total amount 
     *
     * initial balance is set. 
     */
    function DRCToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
    
    /**
     * @dev freeze the account&#39;s balance 
     *
     * by default all the accounts will not be frozen until set freeze value as true. 
     * 
     * @param _target address the account should be frozen
     * @param _freeze bool if true, the account will be frozen
     */
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        require(_target != address(0));

        frozenAccount[_target] = _freeze;
        frozenAmount[_target] = balances[_target];
        FrozenFunds(_target, _freeze);
    }

    /**
     * @dev freeze the account&#39;s balance 
     * 
     * @param _target address the account should be frozen
     * @param _value uint256 the amount of tokens that will be frozen
     */
    function freezeAccountPartialy(address _target, uint256 _value) onlyOwner public {
        require(_target != address(0));
        require(_value <= balances[_target]);

        frozenAccount[_target] = true;
        frozenAmount[_target] = _value;
        FrozenFundsPartialy(_target, true, _value);
    }

    /**
     * @dev transfer token for a specified address with froze status checking
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(!frozenAccount[msg.sender] || (_value <= balances[msg.sender].sub(frozenAmount[msg.sender])));

        return super.transfer(_to, _value);
    }
  
    /**
     * @dev Transfer tokens from one address to another with checking the frozen status
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(!frozenAccount[_from] || (_value <= balances[_from].sub(frozenAmount[_from])));

        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev transfer token for a specified address with froze status checking
     * @param _toMulti The addresses to transfer to.
     * @param _values The array of the amount to be transferred.
     */
    // function transferMultiAddress(address[] _toMulti, uint256[] _values) public whenNotPaused returns (bool) {
    //     require(!frozenAccount[msg.sender]);
    //     assert(_toMulti.length == _values.length);

    //     uint256 i = 0;
    //     while (i < _toMulti.length) {
    //         require(_toMulti[i] != address(0));
    //         require(_values[i] <= balances[msg.sender]);

    //         // SafeMath.sub will throw if there is not enough balance.
    //         balances[msg.sender] = balances[msg.sender].sub(_values[i]);
    //         balances[_toMulti[i]] = balances[_toMulti[i]].add(_values[i]);
    //         Transfer(msg.sender, _toMulti[i], _values[i]);

    //         i = i.add(1);
    //     }

    //     return true;
    // }

    /**
     * @dev Transfer tokens from one address to another with checking the frozen status
     * @param _from address The address which you want to send tokens from
     * @param _toMulti address[] The addresses which you want to transfer to in boundle
     * @param _values uint256[] the array of amount of tokens to be transferred
     */
    // function transferMultiAddressFrom(address _from, address[] _toMulti, uint256[] _values) public whenNotPaused returns (bool) {
    //     require(!frozenAccount[_from]);
    //     assert(_toMulti.length == _values.length);
    
    //     uint256 i = 0;
    //     while ( i < _toMulti.length) {
    //         require(_toMulti[i] != address(0));
    //         require(_values[i] <= balances[_from]);
    //         require(_values[i] <= allowed[_from][msg.sender]);

    //         // SafeMath.sub will throw if there is not enough balance.
    //         balances[_from] = balances[_from].sub(_values[i]);
    //         balances[_toMulti[i]] = balances[_toMulti[i]].add(_values[i]);
    //         allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_values[i]);
    //         Transfer(_from, _toMulti[i], _values[i]);

    //         i = i.add(1);
    //     }

    //     return true;
    // }
  
    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) whenNotPaused public {
        super.burn(_value);
    }

    /**
     * @dev Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public whenNotPaused returns (bool success) {
        require(_from != address(0));
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] = balances[_from].sub(_value);                         // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
        totalSupply_ = totalSupply_.sub(_value);
        BurnFrom(msg.sender, _from, _value);
        return true;
    }

    /**
     * @dev Destroy tokens from other account by force, only a congress contract can call this function
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function forceBurnFrom(address _from, uint256 _value) onlyCongress whenNotPaused public returns (bool success) {
        require(_from != address(0));
        require(balances[_from] >= _value);                // Check if the targeted balance is enough        
        balances[_from] = balances[_from].sub(_value);                         // Subtract from the targeted balance
        totalSupply_ = totalSupply_.sub(_value);
        BurnFrom(msg.sender, _from, _value);
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint whenNotPaused public returns (bool) {
        require(_to != address(0));
        return super.mint(_to, _amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint whenNotPaused public returns (bool) {
        return super.finishMinting();
    }

    /**
     * @dev Function to restart minting functionality. Only congress contract can do this. 
     * @return True if the operation was successful.
     */
    function restartMint() onlyCongress whenNotPaused public returns (bool) {
        mintingFinished = false;
        return true;
    }
    
    /**
     * @dev Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public whenNotPaused returns (bool success) {
        require(_spender != address(0));

        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}