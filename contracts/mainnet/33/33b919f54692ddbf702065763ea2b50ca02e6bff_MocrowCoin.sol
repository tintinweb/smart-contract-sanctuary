pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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
        require(
            _wallet != address(0),
            "Address must be not empty"
        );
        frozenList[_wallet] = true;
        emit FrozenFunds(_wallet, true);
    }

    /**
    * @dev Owner can unfreeze the token balance for chosen token holder.
    * @param _wallet The address of token holder whose tokens to be unfrozen.
    */
    function unfreezeAccount(address _wallet) public onlyOwner {
        require(
            _wallet != address(0),
            "Address must be not empty"
        );
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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
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

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

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
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
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

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/MocrowCoin.sol

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes _extraData)
    external;
}


contract MocrowCoin is StandardToken, BurnableToken, FreezableToken, Pausable {
    string public constant name = "MOCROW";
    string public constant symbol = "MCW";
    uint8 public constant decimals = 18;

    uint256 public constant RESERVED_TOKENS_FOR_FOUNDERS_AND_FOUNDATION = 201700456 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_PLATFORM_OPERATIONS = 113010700 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_ROI_ON_CAPITAL = 9626337 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_FINANCIAL_INSTITUTION = 77010700 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_CYNOTRUST = 11551604 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_CRYPTO_EXCHANGES = 244936817 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_FURTHER_TECH_DEVELOPMENT = 11551604 * (10 ** uint256(decimals));

    uint256 public constant RESERVED_TOKENS_FOR_PRE_ICO = 59561520 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_ICO = 139999994 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_TOKENS_FOR_ICO_BONUSES = 15756152 * (10 ** uint256(decimals));

    uint256 public constant TOTAL_SUPPLY_VALUE = 884705884 * (10 ** uint256(decimals));

    address public addressIco;

    bool isIcoSet = false;

    modifier onlyIco() {
        require(
            msg.sender == addressIco,
            "Address must be the address of the ICO"
        );
        _;
    }

    /**
    * @dev Create MocrowCoin contract with reserves.
    * @param _foundersFoundationReserve The address of founders and foundation reserve.
    * @param _platformOperationsReserve The address of platform operations reserve.
    * @param _roiOnCapitalReserve The address of roi on capital reserve.
    * @param _financialInstitutionReserve The address of financial institution reserve.
    * @param _cynotrustReserve The address of Cynotrust reserve.
    * @param _cryptoExchangesReserve The address of crypto exchanges reserve.
    * @param _furtherTechDevelopmentReserve The address of further tech development reserve.
    */
    constructor(
        address _foundersFoundationReserve,
        address _platformOperationsReserve,
        address _roiOnCapitalReserve,
        address _financialInstitutionReserve,
        address _cynotrustReserve,
        address _cryptoExchangesReserve,
        address _furtherTechDevelopmentReserve) public
        {
        require(
            _foundersFoundationReserve != address(0) && 
            _platformOperationsReserve != address(0) && _roiOnCapitalReserve != address(0) && _financialInstitutionReserve != address(0),
            "Addresses must be not empty"
        );

        require(
            _cynotrustReserve != address(0) && 
            _cryptoExchangesReserve != address(0) && _furtherTechDevelopmentReserve != address(0),
            "Addresses must be not empty"
        );

        balances[_foundersFoundationReserve] = RESERVED_TOKENS_FOR_FOUNDERS_AND_FOUNDATION;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_FOUNDERS_AND_FOUNDATION);
        emit Transfer(address(0), _foundersFoundationReserve, RESERVED_TOKENS_FOR_FOUNDERS_AND_FOUNDATION);

        balances[_platformOperationsReserve] = RESERVED_TOKENS_FOR_PLATFORM_OPERATIONS;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_PLATFORM_OPERATIONS);
        emit Transfer(address(0), _platformOperationsReserve, RESERVED_TOKENS_FOR_PLATFORM_OPERATIONS);

        balances[_roiOnCapitalReserve] = RESERVED_TOKENS_FOR_ROI_ON_CAPITAL;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_ROI_ON_CAPITAL);
        emit Transfer(address(0), _roiOnCapitalReserve, RESERVED_TOKENS_FOR_ROI_ON_CAPITAL);

        balances[_financialInstitutionReserve] = RESERVED_TOKENS_FOR_FINANCIAL_INSTITUTION;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_FINANCIAL_INSTITUTION);
        emit Transfer(address(0), _financialInstitutionReserve, RESERVED_TOKENS_FOR_FINANCIAL_INSTITUTION);

        balances[_cynotrustReserve] = RESERVED_TOKENS_FOR_CYNOTRUST;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_CYNOTRUST);
        emit Transfer(address(0), _cynotrustReserve, RESERVED_TOKENS_FOR_CYNOTRUST);

        balances[_cryptoExchangesReserve] = RESERVED_TOKENS_FOR_CRYPTO_EXCHANGES;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_CRYPTO_EXCHANGES);
        emit Transfer(address(0), _cryptoExchangesReserve, RESERVED_TOKENS_FOR_CRYPTO_EXCHANGES);

        balances[_furtherTechDevelopmentReserve] = RESERVED_TOKENS_FOR_FURTHER_TECH_DEVELOPMENT;
        totalSupply_ = totalSupply_.add(RESERVED_TOKENS_FOR_FURTHER_TECH_DEVELOPMENT);
        emit Transfer(address(0), _furtherTechDevelopmentReserve, RESERVED_TOKENS_FOR_FURTHER_TECH_DEVELOPMENT);
    }

    /**
    * @dev Transfer token for a specified address with pause and freeze features for owner.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(
            !isFrozen(msg.sender),
            "Transfer possibility must be unfrozen for the address"
        );
        return super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another with pause and freeze features for owner.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(
            !isFrozen(msg.sender),
            "Transfer possibility must be unfrozen for the address"
        );
        require(
            !isFrozen(_from),
            "Transfer possibility must be unfrozen for the address"
        );
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Transfer tokens from ICO address to another address.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferFromIco(address _to, uint256 _value) public onlyIco returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Set ICO address.
    * @param _addressIco The address of ICO contract.
    */
    function setIco(address _addressIco) public onlyOwner {
        require(
            _addressIco != address(0),
            "Address must be not empty"
        );

        require(
            !isIcoSet,
            "ICO address is already set"
        );
        
        addressIco = _addressIco;

        uint256 amountToSell = RESERVED_TOKENS_FOR_PRE_ICO.add(RESERVED_TOKENS_FOR_ICO).add(RESERVED_TOKENS_FOR_ICO_BONUSES);
        balances[addressIco] = amountToSell;
        totalSupply_ = totalSupply_.add(amountToSell);
        emit Transfer(address(0), addressIco, amountToSell);

        isIcoSet = true;        
    }

    /**
    * Set allowance for other address and notify
    *
    * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
    *
    * @param _spender The address authorized to spend
    * @param _value the max amount they can spend
    * @param _extraData some extra information to send to the approved contract
    */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value, this,
                _extraData);
            return true;
        }
    }

}