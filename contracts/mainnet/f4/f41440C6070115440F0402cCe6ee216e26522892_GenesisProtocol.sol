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

// File: contracts/controller/Reputation.sol

/**
 * @title Reputation system
 * @dev A DAO has Reputation System which allows peers to rate other peers in order to build trust .
 * A reputation is use to assign influence measure to a DAO&#39;S peers.
 * Reputation is similar to regular tokens but with one crucial difference: It is non-transferable.
 * The Reputation contract maintain a map of address to reputation value.
 * It provides an onlyOwner functions to mint and burn reputation _to (or _from) a specific address.
 */

contract Reputation is Ownable {
    using SafeMath for uint;

    mapping (address => uint256) public balances;
    uint256 public totalSupply;
    uint public decimals = 18;

    // Event indicating minting of reputation to an address.
    event Mint(address indexed _to, uint256 _amount);
    // Event indicating burning of reputation for an address.
    event Burn(address indexed _from, uint256 _amount);

    /**
    * @dev return the reputation amount of a given owner
    * @param _owner an address of the owner which we want to get his reputation
    */
    function reputationOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    * @dev Generates `_amount` of reputation that are assigned to `_to`
    * @param _to The address that will be assigned the new reputation
    * @param _amount The quantity of reputation to be generated
    * @return True if the reputation are generated correctly
    */
    function mint(address _to, uint _amount)
    public
    onlyOwner
    returns (bool)
    {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        return true;
    }

    /**
    * @dev Burns `_amount` of reputation from `_from`
    * if _amount tokens to burn > balances[_from] the balance of _from will turn to zero.
    * @param _from The address that will lose the reputation
    * @param _amount The quantity of reputation to burn
    * @return True if the reputation are burned correctly
    */
    function burn(address _from, uint _amount)
    public
    onlyOwner
    returns (bool)
    {
        uint amountMinted = _amount;
        if (balances[_from] < _amount) {
            amountMinted = balances[_from];
        }
        totalSupply = totalSupply.sub(amountMinted);
        balances[_from] = balances[_from].sub(amountMinted);
        emit Burn(_from, amountMinted);
        return true;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
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

// File: contracts/token/ERC827/ERC827.sol

/**
 * @title ERC827 interface, an extension of ERC20 token standard
 *
 * @dev Interface of a ERC827 token, following the ERC20 standard with extra
 * methods to transfer value and data and execute calls in transfers and
 * approvals.
 */
contract ERC827 is ERC20 {

    function approveAndCall(address _spender,uint256 _value,bytes _data) public payable returns(bool);

    function transferAndCall(address _to,uint256 _value,bytes _data) public payable returns(bool);

    function transferFromAndCall(address _from,address _to,uint256 _value,bytes _data) public payable returns(bool);

}

// File: contracts/token/ERC827/ERC827Token.sol

/* solium-disable security/no-low-level-calls */

pragma solidity ^0.4.24;




/**
 * @title ERC827, an extension of ERC20 token standard
 *
 * @dev Implementation the ERC827, following the ERC20 standard with extra
 * methods to transfer value and data and execute calls in transfers and
 * approvals. Uses OpenZeppelin StandardToken.
 */
contract ERC827Token is ERC827, StandardToken {

  /**
   * @dev Addition to ERC20 token methods. It allows to
   * approve the transfer of value and execute a call with the sent data.
   * Beware that changing an allowance with this method brings the risk that
   * someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race condition
   * is to first reduce the spender&#39;s allowance to 0 and set the desired value
   * afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address that will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @param _data ABI-encoded contract call to call `_spender` address.
   * @return true if the call function was executed successfully
   */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _data
    )
    public
    payable
    returns (bool)
    {
        require(_spender != address(this));

        super.approve(_spender, _value);

        // solium-disable-next-line security/no-call-value
        require(_spender.call.value(msg.value)(_data));

        return true;
    }

  /**
   * @dev Addition to ERC20 token methods. Transfer tokens to a specified
   * address and execute a call with the sent data on the same transaction
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   * @param _data ABI-encoded contract call to call `_to` address.
   * @return true if the call function was executed successfully
   */
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes _data
    )
    public
    payable
    returns (bool)
    {
        require(_to != address(this));

        super.transfer(_to, _value);

        // solium-disable-next-line security/no-call-value
        require(_to.call.value(msg.value)(_data));
        return true;
    }

  /**
   * @dev Addition to ERC20 token methods. Transfer tokens from one address to
   * another and make a contract call on the same transaction
   * @param _from The address which you want to send tokens from
   * @param _to The address which you want to transfer to
   * @param _value The amout of tokens to be transferred
   * @param _data ABI-encoded contract call to call `_to` address.
   * @return true if the call function was executed successfully
   */
    function transferFromAndCall(
        address _from,
        address _to,
        uint256 _value,
        bytes _data
    )
    public payable returns (bool)
    {
        require(_to != address(this));

        super.transferFrom(_from, _to, _value);

        // solium-disable-next-line security/no-call-value
        require(_to.call.value(msg.value)(_data));
        return true;
    }

  /**
   * @dev Addition to StandardToken methods. Increase the amount of tokens that
   * an owner allowed to a spender and execute a call with the sent data.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
    function increaseApprovalAndCall(
        address _spender,
        uint _addedValue,
        bytes _data
    )
    public
    payable
    returns (bool)
    {
        require(_spender != address(this));

        super.increaseApproval(_spender, _addedValue);

        // solium-disable-next-line security/no-call-value
        require(_spender.call.value(msg.value)(_data));

        return true;
    }

  /**
   * @dev Addition to StandardToken methods. Decrease the amount of tokens that
   * an owner allowed to a spender and execute a call with the sent data.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
    function decreaseApprovalAndCall(
        address _spender,
        uint _subtractedValue,
        bytes _data
    )
    public
    payable
    returns (bool)
    {
        require(_spender != address(this));

        super.decreaseApproval(_spender, _subtractedValue);

        // solium-disable-next-line security/no-call-value
        require(_spender.call.value(msg.value)(_data));

        return true;
    }

}

// File: contracts/controller/DAOToken.sol

/**
 * @title DAOToken, base on zeppelin contract.
 * @dev ERC20 compatible token. It is a mintable, destructible, burnable token.
 */

contract DAOToken is ERC827Token,MintableToken,BurnableToken {

    string public name;
    string public symbol;
    // solium-disable-next-line uppercase
    uint8 public constant decimals = 18;
    uint public cap;

    /**
    * @dev Constructor
    * @param _name - token name
    * @param _symbol - token symbol
    * @param _cap - token cap - 0 value means no cap
    */
    constructor(string _name, string _symbol,uint _cap) public {
        name = _name;
        symbol = _symbol;
        cap = _cap;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        if (cap > 0)
            require(totalSupply_.add(_amount) <= cap);
        return super.mint(_to, _amount);
    }
}

// File: contracts/controller/Avatar.sol

/**
 * @title An Avatar holds tokens, reputation and ether for a controller
 */
contract Avatar is Ownable {
    bytes32 public orgName;
    DAOToken public nativeToken;
    Reputation public nativeReputation;

    event GenericAction(address indexed _action, bytes32[] _params);
    event SendEther(uint _amountInWei, address indexed _to);
    event ExternalTokenTransfer(address indexed _externalToken, address indexed _to, uint _value);
    event ExternalTokenTransferFrom(address indexed _externalToken, address _from, address _to, uint _value);
    event ExternalTokenIncreaseApproval(StandardToken indexed _externalToken, address _spender, uint _addedValue);
    event ExternalTokenDecreaseApproval(StandardToken indexed _externalToken, address _spender, uint _subtractedValue);
    event ReceiveEther(address indexed _sender, uint _value);

    /**
    * @dev the constructor takes organization name, native token and reputation system
    and creates an avatar for a controller
    */
    constructor(bytes32 _orgName, DAOToken _nativeToken, Reputation _nativeReputation) public {
        orgName = _orgName;
        nativeToken = _nativeToken;
        nativeReputation = _nativeReputation;
    }

    /**
    * @dev enables an avatar to receive ethers
    */
    function() public payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

    /**
    * @dev perform a generic call to an arbitrary contract
    * @param _contract  the contract&#39;s address to call
    * @param _data ABI-encoded contract call to call `_contract` address.
    * @return the return bytes of the called contract&#39;s function.
    */
    function genericCall(address _contract,bytes _data) public onlyOwner {
        // solium-disable-next-line security/no-low-level-calls
        bool result = _contract.call(_data);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
        // Copy the returned data.
        returndatacopy(0, 0, returndatasize)

        switch result
        // call returns 0 on error.
        case 0 { revert(0, returndatasize) }
        default { return(0, returndatasize) }
        }
    }

    /**
    * @dev send ethers from the avatar&#39;s wallet
    * @param _amountInWei amount to send in Wei units
    * @param _to send the ethers to this address
    * @return bool which represents success
    */
    function sendEther(uint _amountInWei, address _to) public onlyOwner returns(bool) {
        _to.transfer(_amountInWei);
        emit SendEther(_amountInWei, _to);
        return true;
    }

    /**
    * @dev external token transfer
    * @param _externalToken the token contract
    * @param _to the destination address
    * @param _value the amount of tokens to transfer
    * @return bool which represents success
    */
    function externalTokenTransfer(StandardToken _externalToken, address _to, uint _value)
    public onlyOwner returns(bool)
    {
        _externalToken.transfer(_to, _value);
        emit ExternalTokenTransfer(_externalToken, _to, _value);
        return true;
    }

    /**
    * @dev external token transfer from a specific account
    * @param _externalToken the token contract
    * @param _from the account to spend token from
    * @param _to the destination address
    * @param _value the amount of tokens to transfer
    * @return bool which represents success
    */
    function externalTokenTransferFrom(
        StandardToken _externalToken,
        address _from,
        address _to,
        uint _value
    )
    public onlyOwner returns(bool)
    {
        _externalToken.transferFrom(_from, _to, _value);
        emit ExternalTokenTransferFrom(_externalToken, _from, _to, _value);
        return true;
    }

    /**
    * @dev increase approval for the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _addedValue the amount of ether (in Wei) which the approval is referring to.
    * @return bool which represents a success
    */
    function externalTokenIncreaseApproval(StandardToken _externalToken, address _spender, uint _addedValue)
    public onlyOwner returns(bool)
    {
        _externalToken.increaseApproval(_spender, _addedValue);
        emit ExternalTokenIncreaseApproval(_externalToken, _spender, _addedValue);
        return true;
    }

    /**
    * @dev decrease approval for the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _subtractedValue the amount of ether (in Wei) which the approval is referring to.
    * @return bool which represents a success
    */
    function externalTokenDecreaseApproval(StandardToken _externalToken, address _spender, uint _subtractedValue )
    public onlyOwner returns(bool)
    {
        _externalToken.decreaseApproval(_spender, _subtractedValue);
        emit ExternalTokenDecreaseApproval(_externalToken,_spender, _subtractedValue);
        return true;
    }

}

// File: contracts/globalConstraints/GlobalConstraintInterface.sol

contract GlobalConstraintInterface {

    enum CallPhase { Pre, Post,PreAndPost }

    function pre( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    function post( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    /**
     * @dev when return if this globalConstraints is pre, post or both.
     * @return CallPhase enum indication  Pre, Post or PreAndPost.
     */
    function when() public returns(CallPhase);
}

// File: contracts/controller/ControllerInterface.sol

/**
 * @title Controller contract
 * @dev A controller controls the organizations tokens ,reputation and avatar.
 * It is subject to a set of schemes and constraints that determine its behavior.
 * Each scheme has it own parameters and operation permissions.
 */
interface ControllerInterface {

    /**
     * @dev Mint `_amount` of reputation that are assigned to `_to` .
     * @param  _amount amount of reputation to mint
     * @param _to beneficiary address
     * @return bool which represents a success
    */
    function mintReputation(uint256 _amount, address _to,address _avatar)
    external
    returns(bool);

    /**
     * @dev Burns `_amount` of reputation from `_from`
     * @param _amount amount of reputation to burn
     * @param _from The address that will lose the reputation
     * @return bool which represents a success
     */
    function burnReputation(uint256 _amount, address _from,address _avatar)
    external
    returns(bool);

    /**
     * @dev mint tokens .
     * @param  _amount amount of token to mint
     * @param _beneficiary beneficiary address
     * @param _avatar address
     * @return bool which represents a success
     */
    function mintTokens(uint256 _amount, address _beneficiary,address _avatar)
    external
    returns(bool);

  /**
   * @dev register or update a scheme
   * @param _scheme the address of the scheme
   * @param _paramsHash a hashed configuration of the usage of the scheme
   * @param _permissions the permissions the new scheme will have
   * @param _avatar address
   * @return bool which represents a success
   */
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions,address _avatar)
    external
    returns(bool);

    /**
     * @dev unregister a scheme
     * @param _avatar address
     * @param _scheme the address of the scheme
     * @return bool which represents a success
     */
    function unregisterScheme(address _scheme,address _avatar)
    external
    returns(bool);
    /**
     * @dev unregister the caller&#39;s scheme
     * @param _avatar address
     * @return bool which represents a success
     */
    function unregisterSelf(address _avatar) external returns(bool);

    function isSchemeRegistered( address _scheme,address _avatar) external view returns(bool);

    function getSchemeParameters(address _scheme,address _avatar) external view returns(bytes32);

    function getGlobalConstraintParameters(address _globalConstraint,address _avatar) external view returns(bytes32);

    function getSchemePermissions(address _scheme,address _avatar) external view returns(bytes4);

    /**
     * @dev globalConstraintsCount return the global constraint pre and post count
     * @return uint globalConstraintsPre count.
     * @return uint globalConstraintsPost count.
     */
    function globalConstraintsCount(address _avatar) external view returns(uint,uint);

    function isGlobalConstraintRegistered(address _globalConstraint,address _avatar) external view returns(bool);

    /**
     * @dev add or update Global Constraint
     * @param _globalConstraint the address of the global constraint to be added.
     * @param _params the constraint parameters hash.
     * @param _avatar the avatar of the organization
     * @return bool which represents a success
     */
    function addGlobalConstraint(address _globalConstraint, bytes32 _params,address _avatar)
    external returns(bool);

    /**
     * @dev remove Global Constraint
     * @param _globalConstraint the address of the global constraint to be remove.
     * @param _avatar the organization avatar.
     * @return bool which represents a success
     */
    function removeGlobalConstraint (address _globalConstraint,address _avatar)
    external  returns(bool);

  /**
    * @dev upgrade the Controller
    *      The function will trigger an event &#39;UpgradeController&#39;.
    * @param  _newController the address of the new controller.
    * @param _avatar address
    * @return bool which represents a success
    */
    function upgradeController(address _newController,address _avatar)
    external returns(bool);

    /**
    * @dev perform a generic call to an arbitrary contract
    * @param _contract  the contract&#39;s address to call
    * @param _data ABI-encoded contract call to call `_contract` address.
    * @param _avatar the controller&#39;s avatar address
    * @return bytes32  - the return value of the called _contract&#39;s function.
    */
    function genericCall(address _contract,bytes _data,address _avatar)
    external
    returns(bytes32);

  /**
   * @dev send some ether
   * @param _amountInWei the amount of ether (in Wei) to send
   * @param _to address of the beneficiary
   * @param _avatar address
   * @return bool which represents a success
   */
    function sendEther(uint _amountInWei, address _to,address _avatar)
    external returns(bool);

    /**
    * @dev send some amount of arbitrary ERC20 Tokens
    * @param _externalToken the address of the Token Contract
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @param _avatar address
    * @return bool which represents a success
    */
    function externalTokenTransfer(StandardToken _externalToken, address _to, uint _value,address _avatar)
    external
    returns(bool);

    /**
    * @dev transfer token "from" address "to" address
    *      One must to approve the amount of tokens which can be spend from the
    *      "from" account.This can be done using externalTokenApprove.
    * @param _externalToken the address of the Token Contract
    * @param _from address of the account to send from
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @param _avatar address
    * @return bool which represents a success
    */
    function externalTokenTransferFrom(StandardToken _externalToken, address _from, address _to, uint _value,address _avatar)
    external
    returns(bool);

    /**
    * @dev increase approval for the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _addedValue the amount of ether (in Wei) which the approval is referring to.
    * @param _avatar address
    * @return bool which represents a success
    */
    function externalTokenIncreaseApproval(StandardToken _externalToken, address _spender, uint _addedValue,address _avatar)
    external
    returns(bool);

    /**
    * @dev decrease approval for the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _subtractedValue the amount of ether (in Wei) which the approval is referring to.
    * @param _avatar address
    * @return bool which represents a success
    */
    function externalTokenDecreaseApproval(StandardToken _externalToken, address _spender, uint _subtractedValue,address _avatar)
    external
    returns(bool);

    /**
     * @dev getNativeReputation
     * @param _avatar the organization avatar.
     * @return organization native reputation
     */
    function getNativeReputation(address _avatar)
    external
    view
    returns(address);
}

// File: contracts/controller/Controller.sol

/**
 * @title Controller contract
 * @dev A controller controls the organizations tokens,reputation and avatar.
 * It is subject to a set of schemes and constraints that determine its behavior.
 * Each scheme has it own parameters and operation permissions.
 */
contract Controller is ControllerInterface {

    struct Scheme {
        bytes32 paramsHash;  // a hash "configuration" of the scheme
        bytes4  permissions; // A bitwise flags of permissions,
                             // All 0: Not registered,
                             // 1st bit: Flag if the scheme is registered,
                             // 2nd bit: Scheme can register other schemes
                             // 3rd bit: Scheme can add/remove global constraints
                             // 4th bit: Scheme can upgrade the controller
                             // 5th bit: Scheme can call genericCall on behalf of
                             //          the organization avatar
    }

    struct GlobalConstraint {
        address gcAddress;
        bytes32 params;
    }

    struct GlobalConstraintRegister {
        bool isRegistered; //is registered
        uint index;    //index at globalConstraints
    }

    mapping(address=>Scheme) public schemes;

    Avatar public avatar;
    DAOToken public nativeToken;
    Reputation public nativeReputation;
  // newController will point to the new controller after the present controller is upgraded
    address public newController;
  // globalConstraintsPre that determine pre conditions for all actions on the controller

    GlobalConstraint[] public globalConstraintsPre;
  // globalConstraintsPost that determine post conditions for all actions on the controller
    GlobalConstraint[] public globalConstraintsPost;
  // globalConstraintsRegisterPre indicate if a globalConstraints is registered as a pre global constraint
    mapping(address=>GlobalConstraintRegister) public globalConstraintsRegisterPre;
  // globalConstraintsRegisterPost indicate if a globalConstraints is registered as a post global constraint
    mapping(address=>GlobalConstraintRegister) public globalConstraintsRegisterPost;

    event MintReputation (address indexed _sender, address indexed _to, uint256 _amount);
    event BurnReputation (address indexed _sender, address indexed _from, uint256 _amount);
    event MintTokens (address indexed _sender, address indexed _beneficiary, uint256 _amount);
    event RegisterScheme (address indexed _sender, address indexed _scheme);
    event UnregisterScheme (address indexed _sender, address indexed _scheme);
    event GenericAction (address indexed _sender, bytes32[] _params);
    event SendEther (address indexed _sender, uint _amountInWei, address indexed _to);
    event ExternalTokenTransfer (address indexed _sender, address indexed _externalToken, address indexed _to, uint _value);
    event ExternalTokenTransferFrom (address indexed _sender, address indexed _externalToken, address _from, address _to, uint _value);
    event ExternalTokenIncreaseApproval (address indexed _sender, StandardToken indexed _externalToken, address _spender, uint _value);
    event ExternalTokenDecreaseApproval (address indexed _sender, StandardToken indexed _externalToken, address _spender, uint _value);
    event UpgradeController(address indexed _oldController,address _newController);
    event AddGlobalConstraint(address indexed _globalConstraint, bytes32 _params,GlobalConstraintInterface.CallPhase _when);
    event RemoveGlobalConstraint(address indexed _globalConstraint ,uint256 _index,bool _isPre);
    event GenericCall(address indexed _contract,bytes _data);

    constructor( Avatar _avatar) public
    {
        avatar = _avatar;
        nativeToken = avatar.nativeToken();
        nativeReputation = avatar.nativeReputation();
        schemes[msg.sender] = Scheme({paramsHash: bytes32(0),permissions: bytes4(0x1F)});
    }

  // Do not allow mistaken calls:
    function() external {
        revert();
    }

  // Modifiers:
    modifier onlyRegisteredScheme() {
        require(schemes[msg.sender].permissions&bytes4(1) == bytes4(1));
        _;
    }

    modifier onlyRegisteringSchemes() {
        require(schemes[msg.sender].permissions&bytes4(2) == bytes4(2));
        _;
    }

    modifier onlyGlobalConstraintsScheme() {
        require(schemes[msg.sender].permissions&bytes4(4) == bytes4(4));
        _;
    }

    modifier onlyUpgradingScheme() {
        require(schemes[msg.sender].permissions&bytes4(8) == bytes4(8));
        _;
    }

    modifier onlyGenericCallScheme() {
        require(schemes[msg.sender].permissions&bytes4(16) == bytes4(16));
        _;
    }

    modifier onlySubjectToConstraint(bytes32 func) {
        uint idx;
        for (idx = 0;idx<globalConstraintsPre.length;idx++) {
            require((GlobalConstraintInterface(globalConstraintsPre[idx].gcAddress)).pre(msg.sender,globalConstraintsPre[idx].params,func));
        }
        _;
        for (idx = 0;idx<globalConstraintsPost.length;idx++) {
            require((GlobalConstraintInterface(globalConstraintsPost[idx].gcAddress)).post(msg.sender,globalConstraintsPost[idx].params,func));
        }
    }

    modifier isAvatarValid(address _avatar) {
        require(_avatar == address(avatar));
        _;
    }

    /**
     * @dev Mint `_amount` of reputation that are assigned to `_to` .
     * @param  _amount amount of reputation to mint
     * @param _to beneficiary address
     * @return bool which represents a success
     */
    function mintReputation(uint256 _amount, address _to,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("mintReputation")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit MintReputation(msg.sender, _to, _amount);
        return nativeReputation.mint(_to, _amount);
    }

    /**
     * @dev Burns `_amount` of reputation from `_from`
     * @param _amount amount of reputation to burn
     * @param _from The address that will lose the reputation
     * @return bool which represents a success
     */
    function burnReputation(uint256 _amount, address _from,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("burnReputation")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit BurnReputation(msg.sender, _from, _amount);
        return nativeReputation.burn(_from, _amount);
    }

    /**
     * @dev mint tokens .
     * @param  _amount amount of token to mint
     * @param _beneficiary beneficiary address
     * @return bool which represents a success
     */
    function mintTokens(uint256 _amount, address _beneficiary,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("mintTokens")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit MintTokens(msg.sender, _beneficiary, _amount);
        return nativeToken.mint(_beneficiary, _amount);
    }

  /**
   * @dev register a scheme
   * @param _scheme the address of the scheme
   * @param _paramsHash a hashed configuration of the usage of the scheme
   * @param _permissions the permissions the new scheme will have
   * @return bool which represents a success
   */
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions,address _avatar)
    external
    onlyRegisteringSchemes
    onlySubjectToConstraint("registerScheme")
    isAvatarValid(_avatar)
    returns(bool)
    {

        Scheme memory scheme = schemes[_scheme];

    // Check scheme has at least the permissions it is changing, and at least the current permissions:
    // Implementation is a bit messy. One must recall logic-circuits ^^

    // produces non-zero if sender does not have all of the perms that are changing between old and new
        require(bytes4(0x1F)&(_permissions^scheme.permissions)&(~schemes[msg.sender].permissions) == bytes4(0));

    // produces non-zero if sender does not have all of the perms in the old scheme
        require(bytes4(0x1F)&(scheme.permissions&(~schemes[msg.sender].permissions)) == bytes4(0));

    // Add or change the scheme:
        schemes[_scheme].paramsHash = _paramsHash;
        schemes[_scheme].permissions = _permissions|bytes4(1);
        emit RegisterScheme(msg.sender, _scheme);
        return true;
    }

    /**
     * @dev unregister a scheme
     * @param _scheme the address of the scheme
     * @return bool which represents a success
     */
    function unregisterScheme( address _scheme,address _avatar)
    external
    onlyRegisteringSchemes
    onlySubjectToConstraint("unregisterScheme")
    isAvatarValid(_avatar)
    returns(bool)
    {
    //check if the scheme is registered
        if (schemes[_scheme].permissions&bytes4(1) == bytes4(0)) {
            return false;
          }
    // Check the unregistering scheme has enough permissions:
        require(bytes4(0x1F)&(schemes[_scheme].permissions&(~schemes[msg.sender].permissions)) == bytes4(0));

    // Unregister:
        emit UnregisterScheme(msg.sender, _scheme);
        delete schemes[_scheme];
        return true;
    }

    /**
     * @dev unregister the caller&#39;s scheme
     * @return bool which represents a success
     */
    function unregisterSelf(address _avatar) external isAvatarValid(_avatar) returns(bool) {
        if (_isSchemeRegistered(msg.sender,_avatar) == false) {
            return false;
        }
        delete schemes[msg.sender];
        emit UnregisterScheme(msg.sender, msg.sender);
        return true;
    }

    function isSchemeRegistered(address _scheme,address _avatar) external isAvatarValid(_avatar) view returns(bool) {
        return _isSchemeRegistered(_scheme,_avatar);
    }

    function getSchemeParameters(address _scheme,address _avatar) external isAvatarValid(_avatar) view returns(bytes32) {
        return schemes[_scheme].paramsHash;
    }

    function getSchemePermissions(address _scheme,address _avatar) external isAvatarValid(_avatar) view returns(bytes4) {
        return schemes[_scheme].permissions;
    }

    function getGlobalConstraintParameters(address _globalConstraint,address) external view returns(bytes32) {

        GlobalConstraintRegister memory register = globalConstraintsRegisterPre[_globalConstraint];

        if (register.isRegistered) {
            return globalConstraintsPre[register.index].params;
        }

        register = globalConstraintsRegisterPost[_globalConstraint];

        if (register.isRegistered) {
            return globalConstraintsPost[register.index].params;
        }
    }

   /**
    * @dev globalConstraintsCount return the global constraint pre and post count
    * @return uint globalConstraintsPre count.
    * @return uint globalConstraintsPost count.
    */
    function globalConstraintsCount(address _avatar)
        external
        isAvatarValid(_avatar)
        view
        returns(uint,uint)
        {
        return (globalConstraintsPre.length,globalConstraintsPost.length);
    }

    function isGlobalConstraintRegistered(address _globalConstraint,address _avatar)
        external
        isAvatarValid(_avatar)
        view
        returns(bool)
        {
        return (globalConstraintsRegisterPre[_globalConstraint].isRegistered || globalConstraintsRegisterPost[_globalConstraint].isRegistered);
    }

    /**
     * @dev add or update Global Constraint
     * @param _globalConstraint the address of the global constraint to be added.
     * @param _params the constraint parameters hash.
     * @return bool which represents a success
     */
    function addGlobalConstraint(address _globalConstraint, bytes32 _params,address _avatar)
    external
    onlyGlobalConstraintsScheme
    isAvatarValid(_avatar)
    returns(bool)
    {
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        if ((when == GlobalConstraintInterface.CallPhase.Pre)||(when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!globalConstraintsRegisterPre[_globalConstraint].isRegistered) {
                globalConstraintsPre.push(GlobalConstraint(_globalConstraint,_params));
                globalConstraintsRegisterPre[_globalConstraint] = GlobalConstraintRegister(true,globalConstraintsPre.length-1);
            }else {
                globalConstraintsPre[globalConstraintsRegisterPre[_globalConstraint].index].params = _params;
            }
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||(when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!globalConstraintsRegisterPost[_globalConstraint].isRegistered) {
                globalConstraintsPost.push(GlobalConstraint(_globalConstraint,_params));
                globalConstraintsRegisterPost[_globalConstraint] = GlobalConstraintRegister(true,globalConstraintsPost.length-1);
            }else {
                globalConstraintsPost[globalConstraintsRegisterPost[_globalConstraint].index].params = _params;
            }
        }
        emit AddGlobalConstraint(_globalConstraint, _params,when);
        return true;
    }

    /**
     * @dev remove Global Constraint
     * @param _globalConstraint the address of the global constraint to be remove.
     * @return bool which represents a success
     */
    function removeGlobalConstraint (address _globalConstraint,address _avatar)
    external
    onlyGlobalConstraintsScheme
    isAvatarValid(_avatar)
    returns(bool)
    {
        GlobalConstraintRegister memory globalConstraintRegister;
        GlobalConstraint memory globalConstraint;
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        bool retVal = false;

        if ((when == GlobalConstraintInterface.CallPhase.Pre)||(when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            globalConstraintRegister = globalConstraintsRegisterPre[_globalConstraint];
            if (globalConstraintRegister.isRegistered) {
                if (globalConstraintRegister.index < globalConstraintsPre.length-1) {
                    globalConstraint = globalConstraintsPre[globalConstraintsPre.length-1];
                    globalConstraintsPre[globalConstraintRegister.index] = globalConstraint;
                    globalConstraintsRegisterPre[globalConstraint.gcAddress].index = globalConstraintRegister.index;
                }
                globalConstraintsPre.length--;
                delete globalConstraintsRegisterPre[_globalConstraint];
                retVal = true;
            }
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||(when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            globalConstraintRegister = globalConstraintsRegisterPost[_globalConstraint];
            if (globalConstraintRegister.isRegistered) {
                if (globalConstraintRegister.index < globalConstraintsPost.length-1) {
                    globalConstraint = globalConstraintsPost[globalConstraintsPost.length-1];
                    globalConstraintsPost[globalConstraintRegister.index] = globalConstraint;
                    globalConstraintsRegisterPost[globalConstraint.gcAddress].index = globalConstraintRegister.index;
                }
                globalConstraintsPost.length--;
                delete globalConstraintsRegisterPost[_globalConstraint];
                retVal = true;
            }
        }
        if (retVal) {
            emit RemoveGlobalConstraint(_globalConstraint,globalConstraintRegister.index,when == GlobalConstraintInterface.CallPhase.Pre);
        }
        return retVal;
    }

  /**
    * @dev upgrade the Controller
    *      The function will trigger an event &#39;UpgradeController&#39;.
    * @param  _newController the address of the new controller.
    * @return bool which represents a success
    */
    function upgradeController(address _newController,address _avatar)
    external
    onlyUpgradingScheme
    isAvatarValid(_avatar)
    returns(bool)
    {
        require(newController == address(0));   // so the upgrade could be done once for a contract.
        require(_newController != address(0));
        newController = _newController;
        avatar.transferOwnership(_newController);
        require(avatar.owner()==_newController);
        if (nativeToken.owner() == address(this)) {
            nativeToken.transferOwnership(_newController);
            require(nativeToken.owner()==_newController);
        }
        if (nativeReputation.owner() == address(this)) {
            nativeReputation.transferOwnership(_newController);
            require(nativeReputation.owner()==_newController);
        }
        emit UpgradeController(this,newController);
        return true;
    }

    /**
    * @dev perform a generic call to an arbitrary contract
    * @param _contract  the contract&#39;s address to call
    * @param _data ABI-encoded contract call to call `_contract` address.
    * @param _avatar the controller&#39;s avatar address
    * @return bytes32  - the return value of the called _contract&#39;s function.
    */
    function genericCall(address _contract,bytes _data,address _avatar)
    external
    onlyGenericCallScheme
    onlySubjectToConstraint("genericCall")
    isAvatarValid(_avatar)
    returns (bytes32)
    {
        emit GenericCall(_contract, _data);
        avatar.genericCall(_contract, _data);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
        // Copy the returned data.
        returndatacopy(0, 0, returndatasize)
        return(0, returndatasize)
        }
    }

  /**
   * @dev send some ether
   * @param _amountInWei the amount of ether (in Wei) to send
   * @param _to address of the beneficiary
   * @return bool which represents a success
   */
    function sendEther(uint _amountInWei, address _to,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("sendEther")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit SendEther(msg.sender, _amountInWei, _to);
        return avatar.sendEther(_amountInWei, _to);
    }

    /**
    * @dev send some amount of arbitrary ERC20 Tokens
    * @param _externalToken the address of the Token Contract
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @return bool which represents a success
    */
    function externalTokenTransfer(StandardToken _externalToken, address _to, uint _value,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenTransfer")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit ExternalTokenTransfer(msg.sender, _externalToken, _to, _value);
        return avatar.externalTokenTransfer(_externalToken, _to, _value);
    }

    /**
    * @dev transfer token "from" address "to" address
    *      One must to approve the amount of tokens which can be spend from the
    *      "from" account.This can be done using externalTokenApprove.
    * @param _externalToken the address of the Token Contract
    * @param _from address of the account to send from
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @return bool which represents a success
    */
    function externalTokenTransferFrom(StandardToken _externalToken, address _from, address _to, uint _value,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenTransferFrom")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit ExternalTokenTransferFrom(msg.sender, _externalToken, _from, _to, _value);
        return avatar.externalTokenTransferFrom(_externalToken, _from, _to, _value);
    }

    /**
    * @dev increase approval for the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _addedValue the amount of ether (in Wei) which the approval is referring to.
    * @return bool which represents a success
    */
    function externalTokenIncreaseApproval(StandardToken _externalToken, address _spender, uint _addedValue,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenIncreaseApproval")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit ExternalTokenIncreaseApproval(msg.sender,_externalToken,_spender,_addedValue);
        return avatar.externalTokenIncreaseApproval(_externalToken, _spender, _addedValue);
    }

    /**
    * @dev decrease approval for the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _subtractedValue the amount of ether (in Wei) which the approval is referring to.
    * @return bool which represents a success
    */
    function externalTokenDecreaseApproval(StandardToken _externalToken, address _spender, uint _subtractedValue,address _avatar)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenDecreaseApproval")
    isAvatarValid(_avatar)
    returns(bool)
    {
        emit ExternalTokenDecreaseApproval(msg.sender,_externalToken,_spender,_subtractedValue);
        return avatar.externalTokenDecreaseApproval(_externalToken, _spender, _subtractedValue);
    }

    /**
     * @dev getNativeReputation
     * @param _avatar the organization avatar.
     * @return organization native reputation
     */
    function getNativeReputation(address _avatar) external isAvatarValid(_avatar) view returns(address) {
        return address(nativeReputation);
    }

    function _isSchemeRegistered(address _scheme,address _avatar) private isAvatarValid(_avatar) view returns(bool) {
        return (schemes[_scheme].permissions&bytes4(1) != bytes4(0));
    }
}

// File: contracts/universalSchemes/ExecutableInterface.sol

contract ExecutableInterface {
    function execute(bytes32 _proposalId, address _avatar, int _param) public returns(bool);
}

// File: contracts/VotingMachines/IntVoteInterface.sol

interface IntVoteInterface {
    //When implementing this interface please do not only override function and modifier,
    //but also to keep the modifiers on the overridden functions.
    modifier onlyProposalOwner(bytes32 _proposalId) {revert(); _;}
    modifier votable(bytes32 _proposalId) {revert(); _;}

    event NewProposal(bytes32 indexed _proposalId, address indexed _avatar, uint _numOfChoices, address _proposer, bytes32 _paramsHash);
    event ExecuteProposal(bytes32 indexed _proposalId, address indexed _avatar, uint _decision, uint _totalReputation);
    event VoteProposal(bytes32 indexed _proposalId, address indexed _avatar, address indexed _voter, uint _vote, uint _reputation);
    event CancelProposal(bytes32 indexed _proposalId, address indexed _avatar );
    event CancelVoting(bytes32 indexed _proposalId, address indexed _avatar, address indexed _voter);

    /**
     * @dev register a new proposal with the given parameters. Every proposal has a unique ID which is being
     * generated by calculating keccak256 of a incremented counter.
     * @param _numOfChoices number of voting choices
     * @param _proposalParameters defines the parameters of the voting machine used for this proposal
     * @param _avatar an address to be sent as the payload to the _executable contract.
     * @param _executable This contract will be executed when vote is over.
     * @param _proposer address
     * @return proposal&#39;s id.
     */
    function propose(
        uint _numOfChoices,
        bytes32 _proposalParameters,
        address _avatar,
        ExecutableInterface _executable,
        address _proposer
        ) external returns(bytes32);

    // Only owned proposals and only the owner:
    function cancelProposal(bytes32 _proposalId) external returns(bool);

    // Only owned proposals and only the owner:
    function ownerVote(bytes32 _proposalId, uint _vote, address _voter) external returns(bool);

    function vote(bytes32 _proposalId, uint _vote) external returns(bool);

    function voteWithSpecifiedAmounts(
        bytes32 _proposalId,
        uint _vote,
        uint _rep,
        uint _token) external returns(bool);

    function cancelVote(bytes32 _proposalId) external;

    //@dev execute check if the proposal has been decided, and if so, execute the proposal
    //@param _proposalId the id of the proposal
    //@return bool true - the proposal has been executed
    //             false - otherwise.
    function execute(bytes32 _proposalId) external returns(bool);

    function getNumberOfChoices(bytes32 _proposalId) external view returns(uint);

    function isVotable(bytes32 _proposalId) external view returns(bool);

    /**
     * @dev voteStatus returns the reputation voted for a proposal for a specific voting choice.
     * @param _proposalId the ID of the proposal
     * @param _choice the index in the
     * @return voted reputation for the given choice
     */
    function voteStatus(bytes32 _proposalId,uint _choice) external view returns(uint);

    /**
     * @dev isAbstainAllow returns if the voting machine allow abstain (0)
     * @return bool true or false
     */
    function isAbstainAllow() external pure returns(bool);

    /**
     * @dev getAllowedRangeOfChoices returns the allowed range of choices for a voting machine.
     * @return min - minimum number of choices
               max - maximum number of choices
     */
    function getAllowedRangeOfChoices() external pure returns(uint min,uint max);
}

// File: contracts/universalSchemes/UniversalSchemeInterface.sol

contract UniversalSchemeInterface {

    function updateParameters(bytes32 _hashedParameters) public;

    function getParametersFromController(Avatar _avatar) internal view returns(bytes32);
}

// File: contracts/universalSchemes/UniversalScheme.sol

contract UniversalScheme is Ownable, UniversalSchemeInterface {
    bytes32 public hashedParameters; // For other parameters.

    function updateParameters(
        bytes32 _hashedParameters
    )
        public
        onlyOwner
    {
        hashedParameters = _hashedParameters;
    }

    /**
    *  @dev get the parameters for the current scheme from the controller
    */
    function getParametersFromController(Avatar _avatar) internal view returns(bytes32) {
        return ControllerInterface(_avatar.owner()).getSchemeParameters(this,address(_avatar));
    }
}

// File: contracts/libs/RealMath.sol

/**
 * RealMath: fixed-point math library, based on fractional and integer parts.
 * Using int256 as real216x40, which isn&#39;t in Solidity yet.
 * 40 fractional bits gets us down to 1E-12 precision, while still letting us
 * go up to galaxy scale counting in meters.
 * Internally uses the wider int256 for some math.
 *
 * Note that for addition, subtraction, and mod (%), you should just use the
 * built-in Solidity operators. Functions for these operations are not provided.
 *
 * Note that the fancy functions like sqrt, atan2, etc. aren&#39;t as accurate as
 * they should be. They are (hopefully) Good Enough for doing orbital mechanics
 * on block timescales in a game context, but they may not be good enough for
 * other applications.
 */


library RealMath {

    /**
     * How many total bits are there?
     */
    int256 constant REAL_BITS = 256;

    /**
     * How many fractional bits are there?
     */
    int256 constant REAL_FBITS = 40;

    /**
     * How many integer bits are there?
     */
    int256 constant REAL_IBITS = REAL_BITS - REAL_FBITS;

    /**
     * What&#39;s the first non-fractional bit
     */
    int256 constant REAL_ONE = int256(1) << REAL_FBITS;

    /**
     * What&#39;s the last fractional bit?
     */
    int256 constant REAL_HALF = REAL_ONE >> 1;

    /**
     * What&#39;s two? Two is pretty useful.
     */
    int256 constant REAL_TWO = REAL_ONE << 1;

    /**
     * And our logarithms are based on ln(2).
     */
    int256 constant REAL_LN_TWO = 762123384786;

    /**
     * It is also useful to have Pi around.
     */
    int256 constant REAL_PI = 3454217652358;

    /**
     * And half Pi, to save on divides.
     * TODO: That might not be how the compiler handles constants.
     */
    int256 constant REAL_HALF_PI = 1727108826179;

    /**
     * And two pi, which happens to be odd in its most accurate representation.
     */
    int256 constant REAL_TWO_PI = 6908435304715;

    /**
     * What&#39;s the sign bit?
     */
    int256 constant SIGN_MASK = int256(1) << 255;


    /**
     * Convert an integer to a real. Preserves sign.
     */
    function toReal(int216 ipart) internal pure returns (int256) {
        return int256(ipart) * REAL_ONE;
    }

    /**
     * Convert a real to an integer. Preserves sign.
     */
    function fromReal(int256 realValue) internal pure returns (int216) {
        return int216(realValue / REAL_ONE);
    }

    /**
     * Round a real to the nearest integral real value.
     */
    function round(int256 realValue) internal pure returns (int256) {
        // First, truncate.
        int216 ipart = fromReal(realValue);
        if ((fractionalBits(realValue) & (uint40(1) << (REAL_FBITS - 1))) > 0) {
            // High fractional bit is set. Round up.
            if (realValue < int256(0)) {
                // Rounding up for a negative number is rounding down.
                ipart -= 1;
            } else {
                ipart += 1;
            }
        }
        return toReal(ipart);
    }

    /**
     * Get the absolute value of a real. Just the same as abs on a normal int256.
     */
    function abs(int256 realValue) internal pure returns (int256) {
        if (realValue > 0) {
            return realValue;
        } else {
            return -realValue;
        }
    }

    /**
     * Returns the fractional bits of a real. Ignores the sign of the real.
     */
    function fractionalBits(int256 realValue) internal pure returns (uint40) {
        return uint40(abs(realValue) % REAL_ONE);
    }

    /**
     * Get the fractional part of a real, as a real. Ignores sign (so fpart(-0.5) is 0.5).
     */
    function fpart(int256 realValue) internal pure returns (int256) {
        // This gets the fractional part but strips the sign
        return abs(realValue) % REAL_ONE;
    }

    /**
     * Get the fractional part of a real, as a real. Respects sign (so fpartSigned(-0.5) is -0.5).
     */
    function fpartSigned(int256 realValue) internal pure returns (int256) {
        // This gets the fractional part but strips the sign
        int256 fractional = fpart(realValue);
        if (realValue < 0) {
            // Add the negative sign back in.
            return -fractional;
        } else {
            return fractional;
        }
    }

    /**
     * Get the integer part of a fixed point value.
     */
    function ipart(int256 realValue) internal pure returns (int256) {
        // Subtract out the fractional part to get the real part.
        return realValue - fpartSigned(realValue);
    }

    /**
     * Multiply one real by another. Truncates overflows.
     */
    function mul(int256 realA, int256 realB) internal pure returns (int256) {
        // When multiplying fixed point in x.y and z.w formats we get (x+z).(y+w) format.
        // So we just have to clip off the extra REAL_FBITS fractional bits.
        return int256((int256(realA) * int256(realB)) >> REAL_FBITS);
    }

    /**
     * Divide one real by another real. Truncates overflows.
     */
    function div(int256 realNumerator, int256 realDenominator) internal pure returns (int256) {
        // We use the reverse of the multiplication trick: convert numerator from
        // x.y to (x+z).(y+w) fixed point, then divide by denom in z.w fixed point.
        return int256((int256(realNumerator) * REAL_ONE) / int256(realDenominator));
    }

    /**
     * Create a real from a rational fraction.
     */
    function fraction(int216 numerator, int216 denominator) internal pure returns (int256) {
        return div(toReal(numerator), toReal(denominator));
    }

    // Now we have some fancy math things (like pow and trig stuff). This isn&#39;t
    // in the RealMath that was deployed with the original Macroverse
    // deployment, so it needs to be linked into your contract statically.

    /**
     * Raise a number to a positive integer power in O(log power) time.
     * See <https://stackoverflow.com/a/101613>
     */
    function ipow(int256 realBase, int216 exponent) internal pure returns (int256) {
        if (exponent < 0) {
            // Negative powers are not allowed here.
            revert();
        }

        int256 tempRealBase = realBase;
        int256 tempExponent = exponent;

        // Start with the 0th power
        int256 realResult = REAL_ONE;
        while (tempExponent != 0) {
            // While there are still bits set
            if ((tempExponent & 0x1) == 0x1) {
                // If the low bit is set, multiply in the (many-times-squared) base
                realResult = mul(realResult, tempRealBase);
            }
            // Shift off the low bit
            tempExponent = tempExponent >> 1;
            // Do the squaring
            tempRealBase = mul(tempRealBase, tempRealBase);
        }

        // Return the final result.
        return realResult;
    }

    /**
     * Zero all but the highest set bit of a number.
     * See <https://stackoverflow.com/a/53184>
     */
    function hibit(uint256 _val) internal pure returns (uint256) {
        // Set all the bits below the highest set bit
        uint256 val = _val;
        val |= (val >> 1);
        val |= (val >> 2);
        val |= (val >> 4);
        val |= (val >> 8);
        val |= (val >> 16);
        val |= (val >> 32);
        val |= (val >> 64);
        val |= (val >> 128);
        return val ^ (val >> 1);
    }

    /**
     * Given a number with one bit set, finds the index of that bit.
     */
    function findbit(uint256 val) internal pure returns (uint8 index) {
        index = 0;
        // We and the value with alternating bit patters of various pitches to find it.
        if (val & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA != 0) {
            // Picth 1
            index |= 1;
        }
        if (val & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC != 0) {
            // Pitch 2
            index |= 2;
        }
        if (val & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0 != 0) {
            // Pitch 4
            index |= 4;
        }
        if (val & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00 != 0) {
            // Pitch 8
            index |= 8;
        }
        if (val & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000 != 0) {
            // Pitch 16
            index |= 16;
        }
        if (val & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000 != 0) {
            // Pitch 32
            index |= 32;
        }
        if (val & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000 != 0) {
            // Pitch 64
            index |= 64;
        }
        if (val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 != 0) {
            // Pitch 128
            index |= 128;
        }
    }

    /**
     * Shift realArg left or right until it is between 1 and 2. Return the
     * rescaled value, and the number of bits of right shift applied. Shift may be negative.
     *
     * Expresses realArg as realScaled * 2^shift, setting shift to put realArg between [1 and 2).
     *
     * Rejects 0 or negative arguments.
     */
    function rescale(int256 realArg) internal pure returns (int256 realScaled, int216 shift) {
        if (realArg <= 0) {
            // Not in domain!
            revert();
        }

        // Find the high bit
        int216 highBit = findbit(hibit(uint256(realArg)));

        // We&#39;ll shift so the high bit is the lowest non-fractional bit.
        shift = highBit - int216(REAL_FBITS);

        if (shift < 0) {
            // Shift left
            realScaled = realArg << -shift;
        } else if (shift >= 0) {
            // Shift right
            realScaled = realArg >> shift;
        }
    }

    /**
     * Calculate the natural log of a number. Rescales the input value and uses
     * the algorithm outlined at <https://math.stackexchange.com/a/977836> and
     * the ipow implementation.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function lnLimited(int256 realArg, int maxIterations) internal pure returns (int256) {
        if (realArg <= 0) {
            // Outside of acceptable domain
            revert();
        }

        if (realArg == REAL_ONE) {
            // Handle this case specially because people will want exactly 0 and
            // not ~2^-39 ish.
            return 0;
        }

        // We know it&#39;s positive, so rescale it to be between [1 and 2)
        int256 realRescaled;
        int216 shift;
        (realRescaled, shift) = rescale(realArg);

        // Compute the argument to iterate on
        int256 realSeriesArg = div(realRescaled - REAL_ONE, realRescaled + REAL_ONE);

        // We will accumulate the result here
        int256 realSeriesResult = 0;

        for (int216 n = 0; n < maxIterations; n++) {
            // Compute term n of the series
            int256 realTerm = div(ipow(realSeriesArg, 2 * n + 1), toReal(2 * n + 1));
            // And add it in
            realSeriesResult += realTerm;
            if (realTerm == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }

        // Double it to account for the factor of 2 outside the sum
        realSeriesResult = mul(realSeriesResult, REAL_TWO);

        // Now compute and return the overall result
        return mul(toReal(shift), REAL_LN_TWO) + realSeriesResult;

    }

    /**
     * Calculate a natural logarithm with a sensible maximum iteration count to
     * wait until convergence. Note that it is potentially possible to get an
     * un-converged value; lack of convergence does not throw.
     */
    function ln(int256 realArg) internal pure returns (int256) {
        return lnLimited(realArg, 100);
    }

    /**
     * Calculate e^x. Uses the series given at
     * <http://pages.mtu.edu/~shene/COURSES/cs201/NOTES/chap04/exp.html>.
     *
     * Lets you artificially limit the number of iterations.
     *
     * Note that it is potentially possible to get an un-converged value; lack
     * of convergence does not throw.
     */
    function expLimited(int256 realArg, int maxIterations) internal pure returns (int256) {
        // We will accumulate the result here
        int256 realResult = 0;

        // We use this to save work computing terms
        int256 realTerm = REAL_ONE;

        for (int216 n = 0; n < maxIterations; n++) {
            // Add in the term
            realResult += realTerm;

            // Compute the next term
            realTerm = mul(realTerm, div(realArg, toReal(n + 1)));

            if (realTerm == 0) {
                // We must have converged. Next term is too small to represent.
                break;
            }
            // If we somehow never converge I guess we will run out of gas
        }

        // Return the result
        return realResult;

    }

    /**
     * Calculate e^x with a sensible maximum iteration count to wait until
     * convergence. Note that it is potentially possible to get an un-converged
     * value; lack of convergence does not throw.
     */
    function exp(int256 realArg) internal pure returns (int256) {
        return expLimited(realArg, 100);
    }

    /**
     * Raise any number to any power, except for negative bases to fractional powers.
     */
    function pow(int256 realBase, int256 realExponent) internal pure returns (int256) {
        if (realExponent == 0) {
            // Anything to the 0 is 1
            return REAL_ONE;
        }

        if (realBase == 0) {
            if (realExponent < 0) {
                // Outside of domain!
                revert();
            }
            // Otherwise it&#39;s 0
            return 0;
        }

        if (fpart(realExponent) == 0) {
            // Anything (even a negative base) is super easy to do to an integer power.

            if (realExponent > 0) {
                // Positive integer power is easy
                return ipow(realBase, fromReal(realExponent));
            } else {
                // Negative integer power is harder
                return div(REAL_ONE, ipow(realBase, fromReal(-realExponent)));
            }
        }

        if (realBase < 0) {
            // It&#39;s a negative base to a non-integer power.
            // In general pow(-x^y) is undefined, unless y is an int or some
            // weird rational-number-based relationship holds.
            revert();
        }

        // If it&#39;s not a special case, actually do it.
        return exp(mul(realExponent, ln(realBase)));
    }

    /**
     * Compute the square root of a number.
     */
    function sqrt(int256 realArg) internal pure returns (int256) {
        return pow(realArg, REAL_HALF);
    }

    /**
     * Compute the sin of a number to a certain number of Taylor series terms.
     */
    function sinLimited(int256 _realArg, int216 maxIterations) internal pure returns (int256) {
        // First bring the number into 0 to 2 pi
        // TODO: This will introduce an error for very large numbers, because the error in our Pi will compound.
        // But for actual reasonable angle values we should be fine.
        int256 realArg = _realArg;
        realArg = realArg % REAL_TWO_PI;

        int256 accumulator = REAL_ONE;

        // We sum from large to small iteration so that we can have higher powers in later terms
        for (int216 iteration = maxIterations - 1; iteration >= 0; iteration--) {
            accumulator = REAL_ONE - mul(div(mul(realArg, realArg), toReal((2 * iteration + 2) * (2 * iteration + 3))), accumulator);
            // We can&#39;t stop early; we need to make it to the first term.
        }

        return mul(realArg, accumulator);
    }

    /**
     * Calculate sin(x) with a sensible maximum iteration count to wait until
     * convergence.
     */
    function sin(int256 realArg) internal pure returns (int256) {
        return sinLimited(realArg, 15);
    }

    /**
     * Calculate cos(x).
     */
    function cos(int256 realArg) internal pure returns (int256) {
        return sin(realArg + REAL_HALF_PI);
    }

    /**
     * Calculate tan(x). May overflow for large results. May throw if tan(x)
     * would be infinite, or return an approximation, or overflow.
     */
    function tan(int256 realArg) internal pure returns (int256) {
        return div(sin(realArg), cos(realArg));
    }
}

// File: openzeppelin-solidity/contracts/ECRecovery.sol

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * @dev and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

// File: contracts/libs/OrderStatisticTree.sol

library OrderStatisticTree {

    struct Node {
        mapping (bool => uint) children; // a mapping of left(false) child and right(true) child nodes
        uint parent; // parent node
        bool side;   // side of the node on the tree (left or right)
        uint height; //Height of this node
        uint count; //Number of tree nodes below this node (including this one)
        uint dupes; //Number of duplicates values for this node
    }

    struct Tree {
        // a mapping between node value(uint) to Node
        // the tree&#39;s root is always at node 0 ,which points to the "real" tree
        // as its right child.this is done to eliminate the need to update the tree
        // root in the case of rotation.(saving gas).
        mapping(uint => Node) nodes;
    }
    /**
     * @dev rank - find the rank of a value in the tree,
     *      i.e. its index in the sorted list of elements of the tree
     * @param _tree the tree
     * @param _value the input value to find its rank.
     * @return smaller - the number of elements in the tree which their value is
     * less than the input value.
     */
    function rank(Tree storage _tree,uint _value) internal view returns (uint smaller) {
        if (_value != 0) {
            smaller = _tree.nodes[0].dupes;

            uint cur = _tree.nodes[0].children[true];
            Node storage currentNode = _tree.nodes[cur];

            while (true) {
                if (cur <= _value) {
                    if (cur<_value) {
                        smaller = smaller + 1+currentNode.dupes;
                    }
                    uint leftChild = currentNode.children[false];
                    if (leftChild!=0) {
                        smaller = smaller + _tree.nodes[leftChild].count;
                    }
                }
                if (cur == _value) {
                    break;
                }
                cur = currentNode.children[cur<_value];
                if (cur == 0) {
                    break;
                }
                currentNode = _tree.nodes[cur];
            }
        }
    }

    function count(Tree storage _tree) internal view returns (uint) {
        Node storage root = _tree.nodes[0];
        Node memory child = _tree.nodes[root.children[true]];
        return root.dupes+child.count;
    }

    function updateCount(Tree storage _tree,uint _value) private {
        Node storage n = _tree.nodes[_value];
        n.count = 1+_tree.nodes[n.children[false]].count+_tree.nodes[n.children[true]].count+n.dupes;
    }

    function updateCounts(Tree storage _tree,uint _value) private {
        uint parent = _tree.nodes[_value].parent;
        while (parent!=0) {
            updateCount(_tree,parent);
            parent = _tree.nodes[parent].parent;
        }
    }

    function updateHeight(Tree storage _tree,uint _value) private {
        Node storage n = _tree.nodes[_value];
        uint heightLeft = _tree.nodes[n.children[false]].height;
        uint heightRight = _tree.nodes[n.children[true]].height;
        if (heightLeft > heightRight)
            n.height = heightLeft+1;
        else
            n.height = heightRight+1;
    }

    function balanceFactor(Tree storage _tree,uint _value) private view returns (int bf) {
        Node storage n = _tree.nodes[_value];
        return int(_tree.nodes[n.children[false]].height)-int(_tree.nodes[n.children[true]].height);
    }

    function rotate(Tree storage _tree,uint _value,bool dir) private {
        bool otherDir = !dir;
        Node storage n = _tree.nodes[_value];
        bool side = n.side;
        uint parent = n.parent;
        uint valueNew = n.children[otherDir];
        Node storage nNew = _tree.nodes[valueNew];
        uint orphan = nNew.children[dir];
        Node storage p = _tree.nodes[parent];
        Node storage o = _tree.nodes[orphan];
        p.children[side] = valueNew;
        nNew.side = side;
        nNew.parent = parent;
        nNew.children[dir] = _value;
        n.parent = valueNew;
        n.side = dir;
        n.children[otherDir] = orphan;
        o.parent = _value;
        o.side = otherDir;
        updateHeight(_tree,_value);
        updateHeight(_tree,valueNew);
        updateCount(_tree,_value);
        updateCount(_tree,valueNew);
    }

    function rebalanceInsert(Tree storage _tree,uint _nValue) private {
        updateHeight(_tree,_nValue);
        Node storage n = _tree.nodes[_nValue];
        uint pValue = n.parent;
        if (pValue!=0) {
            int pBf = balanceFactor(_tree,pValue);
            bool side = n.side;
            int sign;
            if (side)
                sign = -1;
            else
                sign = 1;
            if (pBf == sign*2) {
                if (balanceFactor(_tree,_nValue) == (-1 * sign)) {
                    rotate(_tree,_nValue,side);
                }
                rotate(_tree,pValue,!side);
            } else if (pBf != 0) {
                rebalanceInsert(_tree,pValue);
            }
        }
    }

    function rebalanceDelete(Tree storage _tree,uint _pValue,bool side) private {
        if (_pValue!=0) {
            updateHeight(_tree,_pValue);
            int pBf = balanceFactor(_tree,_pValue);
            int sign;
            if (side)
                sign = 1;
            else
                sign = -1;
            int bf = balanceFactor(_tree,_pValue);
            if (bf==(2*sign)) {
                Node storage p = _tree.nodes[_pValue];
                uint sValue = p.children[!side];
                int sBf = balanceFactor(_tree,sValue);
                if (sBf == (-1 * sign)) {
                    rotate(_tree,sValue,!side);
                }
                rotate(_tree,_pValue,side);
                if (sBf!=0) {
                    p = _tree.nodes[_pValue];
                    rebalanceDelete(_tree,p.parent,p.side);
                }
            } else if (pBf != sign) {
                p = _tree.nodes[_pValue];
                rebalanceDelete(_tree,p.parent,p.side);
            }
        }
    }

    function fixParents(Tree storage _tree,uint parent,bool side) private {
        if (parent!=0) {
            updateCount(_tree,parent);
            updateCounts(_tree,parent);
            rebalanceDelete(_tree,parent,side);
        }
    }

    function insertHelper(Tree storage _tree,uint _pValue,bool _side,uint _value) private {
        Node storage root = _tree.nodes[_pValue];
        uint cValue = root.children[_side];
        if (cValue==0) {
            root.children[_side] = _value;
            Node storage child = _tree.nodes[_value];
            child.parent = _pValue;
            child.side = _side;
            child.height = 1;
            child.count = 1;
            updateCounts(_tree,_value);
            rebalanceInsert(_tree,_value);
        } else if (cValue==_value) {
            _tree.nodes[cValue].dupes++;
            updateCount(_tree,_value);
            updateCounts(_tree,_value);
        } else {
            insertHelper(_tree,cValue,(_value >= cValue),_value);
        }
    }

    function insert(Tree storage _tree,uint _value) internal {
        if (_value==0) {
            _tree.nodes[_value].dupes++;
        } else {
            insertHelper(_tree,0,true,_value);
        }
    }

    function rightmostLeaf(Tree storage _tree,uint _value) private view returns (uint leaf) {
        uint child = _tree.nodes[_value].children[true];
        if (child!=0) {
            return rightmostLeaf(_tree,child);
        } else {
            return _value;
        }
    }

    function zeroOut(Tree storage _tree,uint _value) private {
        Node storage n = _tree.nodes[_value];
        n.parent = 0;
        n.side = false;
        n.children[false] = 0;
        n.children[true] = 0;
        n.count = 0;
        n.height = 0;
        n.dupes = 0;
    }

    function removeBranch(Tree storage _tree,uint _value,uint _left) private {
        uint ipn = rightmostLeaf(_tree,_left);
        Node storage i = _tree.nodes[ipn];
        uint dupes = i.dupes;
        removeHelper(_tree,ipn);
        Node storage n = _tree.nodes[_value];
        uint parent = n.parent;
        Node storage p = _tree.nodes[parent];
        uint height = n.height;
        bool side = n.side;
        uint ncount = n.count;
        uint right = n.children[true];
        uint left = n.children[false];
        p.children[side] = ipn;
        i.parent = parent;
        i.side = side;
        i.count = ncount+dupes-n.dupes;
        i.height = height;
        i.dupes = dupes;
        if (left!=0) {
            i.children[false] = left;
            _tree.nodes[left].parent = ipn;
        }
        if (right!=0) {
            i.children[true] = right;
            _tree.nodes[right].parent = ipn;
        }
        zeroOut(_tree,_value);
        updateCounts(_tree,ipn);
    }

    function removeHelper(Tree storage _tree,uint _value) private {
        Node storage n = _tree.nodes[_value];
        uint parent = n.parent;
        bool side = n.side;
        Node storage p = _tree.nodes[parent];
        uint left = n.children[false];
        uint right = n.children[true];
        if ((left == 0) && (right == 0)) {
            p.children[side] = 0;
            zeroOut(_tree,_value);
            fixParents(_tree,parent,side);
        } else if ((left != 0) && (right != 0)) {
            removeBranch(_tree,_value,left);
        } else {
            uint child = left+right;
            Node storage c = _tree.nodes[child];
            p.children[side] = child;
            c.parent = parent;
            c.side = side;
            zeroOut(_tree,_value);
            fixParents(_tree,parent,side);
        }
    }

    function remove(Tree storage _tree,uint _value) internal {
        Node storage n = _tree.nodes[_value];
        if (_value==0) {
            if (n.dupes==0) {
                return;
            }
        } else {
            if (n.count==0) {
                return;
            }
        }
        if (n.dupes>0) {
            n.dupes--;
            if (_value!=0) {
                n.count--;
            }
            fixParents(_tree,n.parent,n.side);
        } else {
            removeHelper(_tree,_value);
        }
    }

}

// File: contracts/VotingMachines/GenesisProtocol.sol

/**
 * @title GenesisProtocol implementation -an organization&#39;s voting machine scheme.
 */


contract GenesisProtocol is IntVoteInterface,UniversalScheme {
    using SafeMath for uint;
    using RealMath for int216;
    using RealMath for int256;
    using ECRecovery for bytes32;
    using OrderStatisticTree for OrderStatisticTree.Tree;

    enum ProposalState { None ,Closed, Executed, PreBoosted,Boosted,QuietEndingPeriod }
    enum ExecutionState { None, PreBoostedTimeOut, PreBoostedBarCrossed, BoostedTimeOut,BoostedBarCrossed }

    //Organization&#39;s parameters
    struct Parameters {
        uint preBoostedVoteRequiredPercentage; // the absolute vote percentages bar.
        uint preBoostedVotePeriodLimit; //the time limit for a proposal to be in an absolute voting mode.
        uint boostedVotePeriodLimit; //the time limit for a proposal to be in an relative voting mode.
        uint thresholdConstA;//constant A for threshold calculation . threshold =A * (e ** (numberOfBoostedProposals/B))
        uint thresholdConstB;//constant B for threshold calculation . threshold =A * (e ** (numberOfBoostedProposals/B))
        uint minimumStakingFee; //minimum staking fee allowed.
        uint quietEndingPeriod; //quite ending period
        uint proposingRepRewardConstA;//constant A for calculate proposer reward. proposerReward =(A*(RTotal) +B*(R+ - R-))/1000
        uint proposingRepRewardConstB;//constant B for calculate proposing reward.proposerReward =(A*(RTotal) +B*(R+ - R-))/1000
        uint stakerFeeRatioForVoters; // The “ratio of stake” to be paid to voters.
                                      // All stakers pay a portion of their stake to all voters, stakerFeeRatioForVoters * (s+ + s-).
                                      //All voters (pre and during boosting period) divide this portion in proportion to their reputation.
        uint votersReputationLossRatio;//Unsuccessful pre booster voters lose votersReputationLossRatio% of their reputation.
        uint votersGainRepRatioFromLostRep; //the percentages of the lost reputation which is divided by the successful pre boosted voters,
                                            //in proportion to their reputation.
                                            //The rest (100-votersGainRepRatioFromLostRep)% of lost reputation is divided between the successful wagers,
                                            //in proportion to their stake.
        uint daoBountyConst;//The DAO adds up a bounty for successful staker.
                            //The bounty formula is: s * daoBountyConst, where s+ is the wager staked for the proposal,
                            //and  daoBountyConst is a constant factor that is configurable and changeable by the DAO given.
                            //  daoBountyConst should be greater than stakerFeeRatioForVoters and less than 2 * stakerFeeRatioForVoters.
        uint daoBountyLimit;//The daoBounty cannot be greater than daoBountyLimit.



    }
    struct Voter {
        uint vote; // YES(1) ,NO(2)
        uint reputation; // amount of voter&#39;s reputation
        bool preBoosted;
    }

    struct Staker {
        uint vote; // YES(1) ,NO(2)
        uint amount; // amount of staker&#39;s stake
        uint amountForBounty; // amount of staker&#39;s stake which will be use for bounty calculation
    }

    struct Proposal {
        address avatar; // the organization&#39;s avatar the proposal is target to.
        uint numOfChoices;
        ExecutableInterface executable; // will be executed if the proposal will pass
        uint votersStakes;
        uint submittedTime;
        uint boostedPhaseTime; //the time the proposal shift to relative mode.
        ProposalState state;
        uint winningVote; //the winning vote.
        address proposer;
        uint currentBoostedVotePeriodLimit;
        bytes32 paramsHash;
        uint daoBountyRemain;
        uint[2] totalStakes;// totalStakes[0] - (amount staked minus fee) - Total number of tokens staked which can be redeemable by stakers.
                            // totalStakes[1] - (amount staked) - Total number of redeemable tokens.
        //      vote      reputation
        mapping(uint    =>  uint     ) votes;
        //      vote      reputation
        mapping(uint    =>  uint     ) preBoostedVotes;
        //      address     voter
        mapping(address =>  Voter    ) voters;
        //      vote        stakes
        mapping(uint    =>  uint     ) stakes;
        //      address  staker
        mapping(address  => Staker   ) stakers;
    }

    event GPExecuteProposal(bytes32 indexed _proposalId, ExecutionState _executionState);
    event Stake(bytes32 indexed _proposalId, address indexed _avatar, address indexed _staker,uint _vote,uint _amount);
    event Redeem(bytes32 indexed _proposalId, address indexed _avatar, address indexed _beneficiary,uint _amount);
    event RedeemDaoBounty(bytes32 indexed _proposalId, address indexed _avatar, address indexed _beneficiary,uint _amount);
    event RedeemReputation(bytes32 indexed _proposalId, address indexed _avatar, address indexed _beneficiary,uint _amount);

    mapping(bytes32=>Parameters) public parameters;  // A mapping from hashes to parameters
    mapping(bytes32=>Proposal) public proposals; // Mapping from the ID of the proposal to the proposal itself.

    mapping(bytes=>bool) stakeSignatures; //stake signatures

    uint constant public NUM_OF_CHOICES = 2;
    uint constant public NO = 2;
    uint constant public YES = 1;
    uint public proposalsCnt; // Total number of proposals
    mapping(address=>uint) orgBoostedProposalsCnt;
    StandardToken public stakingToken;
    mapping(address=>OrderStatisticTree.Tree) proposalsExpiredTimes; //proposals expired times

    /**
     * @dev Constructor
     */
    constructor(StandardToken _stakingToken) public
    {
        stakingToken = _stakingToken;
    }

  /**
   * @dev Check that the proposal is votable (open and not executed yet)
   */
    modifier votable(bytes32 _proposalId) {
        require(_isVotable(_proposalId));
        _;
    }

    /**
     * @dev register a new proposal with the given parameters. Every proposal has a unique ID which is being
     * generated by calculating keccak256 of a incremented counter.
     * @param _numOfChoices number of voting choices
     * @param _avatar an address to be sent as the payload to the _executable contract.
     * @param _executable This contract will be executed when vote is over.
     * @param _proposer address
     * @return proposal&#39;s id.
     */
    function propose(uint _numOfChoices, bytes32 , address _avatar, ExecutableInterface _executable,address _proposer)
        external
        returns(bytes32)
    {
          // Check valid params and number of choices:
        require(_numOfChoices == NUM_OF_CHOICES);
        require(ExecutableInterface(_executable) != address(0));
        //Check parameters existence.
        bytes32 paramsHash = getParametersFromController(Avatar(_avatar));

        require(parameters[paramsHash].preBoostedVoteRequiredPercentage > 0);
        // Generate a unique ID:
        bytes32 proposalId = keccak256(abi.encodePacked(this, proposalsCnt));
        proposalsCnt++;
        // Open proposal:
        Proposal memory proposal;
        proposal.numOfChoices = _numOfChoices;
        proposal.avatar = _avatar;
        proposal.executable = _executable;
        proposal.state = ProposalState.PreBoosted;
        // solium-disable-next-line security/no-block-members
        proposal.submittedTime = now;
        proposal.currentBoostedVotePeriodLimit = parameters[paramsHash].boostedVotePeriodLimit;
        proposal.proposer = _proposer;
        proposal.winningVote = NO;
        proposal.paramsHash = paramsHash;
        proposals[proposalId] = proposal;
        emit NewProposal(proposalId, _avatar, _numOfChoices, _proposer, paramsHash);
        return proposalId;
    }

  /**
   * @dev Cancel a proposal, only the owner can call this function and only if allowOwner flag is true.
   */
    function cancelProposal(bytes32 ) external returns(bool) {
        //This is not allowed.
        return false;
    }

    /**
     * @dev staking function
     * @param _proposalId id of the proposal
     * @param _vote  NO(2) or YES(1).
     * @param _amount the betting amount
     * @return bool true - the proposal has been executed
     *              false - otherwise.
     */
    function stake(bytes32 _proposalId, uint _vote, uint _amount) external returns(bool) {
        return _stake(_proposalId,_vote,_amount,msg.sender);
    }

    // Digest describing the data the user signs according EIP 712.
    // Needs to match what is passed to Metamask.
    bytes32 public constant DELEGATION_HASH_EIP712 =
    keccak256(abi.encodePacked("address GenesisProtocolAddress","bytes32 ProposalId", "uint Vote","uint AmountToStake","uint Nonce"));
    // web3.eth.sign prefix
    string public constant ETH_SIGN_PREFIX= "\x19Ethereum Signed Message:\n32";

    /**
     * @dev stakeWithSignature function
     * @param _proposalId id of the proposal
     * @param _vote  NO(2) or YES(1).
     * @param _amount the betting amount
     * @param _nonce nonce value ,it is part of the signature to ensure that
              a signature can be received only once.
     * @param _signatureType signature type
              1 - for web3.eth.sign
              2 - for eth_signTypedData according to EIP #712.
     * @param _signature  - signed data by the staker
     * @return bool true - the proposal has been executed
     *              false - otherwise.
     */
    function stakeWithSignature(
        bytes32 _proposalId,
        uint _vote,
        uint _amount,
        uint _nonce,
        uint _signatureType,
        bytes _signature
        )
        external
        returns(bool)
        {
        require(stakeSignatures[_signature] == false);
        // Recreate the digest the user signed
        bytes32 delegationDigest;
        if (_signatureType == 2) {
            delegationDigest = keccak256(
                abi.encodePacked(
                    DELEGATION_HASH_EIP712, keccak256(
                        abi.encodePacked(
                           address(this),
                          _proposalId,
                          _vote,
                          _amount,
                          _nonce)))
            );
        } else {
            delegationDigest = keccak256(
                abi.encodePacked(
                    ETH_SIGN_PREFIX, keccak256(
                        abi.encodePacked(
                            address(this),
                           _proposalId,
                           _vote,
                           _amount,
                           _nonce)))
            );
        }
        address staker = delegationDigest.recover(_signature);
        //a garbage staker address due to wrong signature will revert due to lack of approval and funds.
        require(staker!=address(0));
        stakeSignatures[_signature] = true;
        return _stake(_proposalId,_vote,_amount,staker);
    }

  /**
   * @dev voting function
   * @param _proposalId id of the proposal
   * @param _vote NO(2) or YES(1).
   * @return bool true - the proposal has been executed
   *              false - otherwise.
   */
    function vote(bytes32 _proposalId, uint _vote) external votable(_proposalId) returns(bool) {
        return internalVote(_proposalId, msg.sender, _vote, 0);
    }

  /**
   * @dev voting function with owner functionality (can vote on behalf of someone else)
   * @return bool true - the proposal has been executed
   *              false - otherwise.
   */
    function ownerVote(bytes32 , uint , address ) external returns(bool) {
      //This is not allowed.
        return false;
    }

    function voteWithSpecifiedAmounts(bytes32 _proposalId,uint _vote,uint _rep,uint) external votable(_proposalId) returns(bool) {
        return internalVote(_proposalId,msg.sender,_vote,_rep);
    }

  /**
   * @dev Cancel the vote of the msg.sender.
   * cancel vote is not allow in genesisProtocol so this function doing nothing.
   * This function is here in order to comply to the IntVoteInterface .
   */
    function cancelVote(bytes32 _proposalId) external votable(_proposalId) {
       //this is not allowed
        return;
    }

  /**
    * @dev getNumberOfChoices returns the number of choices possible in this proposal
    * @param _proposalId the ID of the proposals
    * @return uint that contains number of choices
    */
    function getNumberOfChoices(bytes32 _proposalId) external view returns(uint) {
        return proposals[_proposalId].numOfChoices;
    }

    /**
     * @dev voteInfo returns the vote and the amount of reputation of the user committed to this proposal
     * @param _proposalId the ID of the proposal
     * @param _voter the address of the voter
     * @return uint vote - the voters vote
     *        uint reputation - amount of reputation committed by _voter to _proposalId
     */
    function voteInfo(bytes32 _proposalId, address _voter) external view returns(uint, uint) {
        Voter memory voter = proposals[_proposalId].voters[_voter];
        return (voter.vote, voter.reputation);
    }

    /**
    * @dev voteStatus returns the reputation voted for a proposal for a specific voting choice.
    * @param _proposalId the ID of the proposal
    * @param _choice the index in the
    * @return voted reputation for the given choice
    */
    function voteStatus(bytes32 _proposalId,uint _choice) external view returns(uint) {
        return proposals[_proposalId].votes[_choice];
    }

    /**
    * @dev isVotable check if the proposal is votable
    * @param _proposalId the ID of the proposal
    * @return bool true or false
    */
    function isVotable(bytes32 _proposalId) external view returns(bool) {
        return _isVotable(_proposalId);
    }

    /**
    * @dev proposalStatus return the total votes and stakes for a given proposal
    * @param _proposalId the ID of the proposal
    * @return uint preBoostedVotes YES
    * @return uint preBoostedVotes NO
    * @return uint stakersStakes
    * @return uint totalRedeemableStakes
    * @return uint total stakes YES
    * @return uint total stakes NO
    */
    function proposalStatus(bytes32 _proposalId) external view returns(uint, uint, uint ,uint, uint ,uint) {
        return (
                proposals[_proposalId].preBoostedVotes[YES],
                proposals[_proposalId].preBoostedVotes[NO],
                proposals[_proposalId].totalStakes[0],
                proposals[_proposalId].totalStakes[1],
                proposals[_proposalId].stakes[YES],
                proposals[_proposalId].stakes[NO]
        );
    }

  /**
    * @dev proposalAvatar return the avatar for a given proposal
    * @param _proposalId the ID of the proposal
    * @return uint total reputation supply
    */
    function proposalAvatar(bytes32 _proposalId) external view returns(address) {
        return (proposals[_proposalId].avatar);
    }

  /**
    * @dev scoreThresholdParams return the score threshold params for a given
    * organization.
    * @param _avatar the organization&#39;s avatar
    * @return uint thresholdConstA
    * @return uint thresholdConstB
    */
    function scoreThresholdParams(address _avatar) external view returns(uint,uint) {
        bytes32 paramsHash = getParametersFromController(Avatar(_avatar));
        Parameters memory params = parameters[paramsHash];
        return (params.thresholdConstA,params.thresholdConstB);
    }

    /**
      * @dev getStaker return the vote and stake amount for a given proposal and staker
      * @param _proposalId the ID of the proposal
      * @param _staker staker address
      * @return uint vote
      * @return uint amount
    */
    function getStaker(bytes32 _proposalId,address _staker) external view returns(uint,uint) {
        return (proposals[_proposalId].stakers[_staker].vote,proposals[_proposalId].stakers[_staker].amount);
    }

    /**
      * @dev state return the state for a given proposal
      * @param _proposalId the ID of the proposal
      * @return ProposalState proposal state
    */
    function state(bytes32 _proposalId) external view returns(ProposalState) {
        return proposals[_proposalId].state;
    }

    /**
    * @dev winningVote return the winningVote for a given proposal
    * @param _proposalId the ID of the proposal
    * @return uint winningVote
    */
    function winningVote(bytes32 _proposalId) external view returns(uint) {
        return proposals[_proposalId].winningVote;
    }

   /**
    * @dev isAbstainAllow returns if the voting machine allow abstain (0)
    * @return bool true or false
    */
    function isAbstainAllow() external pure returns(bool) {
        return false;
    }

    /**
     * @dev getAllowedRangeOfChoices returns the allowed range of choices for a voting machine.
     * @return min - minimum number of choices
               max - maximum number of choices
     */
    function getAllowedRangeOfChoices() external pure returns(uint min,uint max) {
        return (NUM_OF_CHOICES,NUM_OF_CHOICES);
    }

    /**
    * @dev execute check if the proposal has been decided, and if so, execute the proposal
    * @param _proposalId the id of the proposal
    * @return bool true - the proposal has been executed
    *              false - otherwise.
   */
    function execute(bytes32 _proposalId) external votable(_proposalId) returns(bool) {
        return _execute(_proposalId);
    }

    /**
     * @dev redeem a reward for a successful stake, vote or proposing.
     * The function use a beneficiary address as a parameter (and not msg.sender) to enable
     * users to redeem on behalf of someone else.
     * @param _proposalId the ID of the proposal
     * @param _beneficiary - the beneficiary address
     * @return rewards -
     *         rewards[0] - stakerTokenAmount
     *         rewards[1] - stakerReputationAmount
     *         rewards[2] - voterTokenAmount
     *         rewards[3] - voterReputationAmount
     *         rewards[4] - proposerReputationAmount
     * @return reputation - redeem reputation
     */
    function redeem(bytes32 _proposalId,address _beneficiary) public returns (uint[5] rewards) {
        Proposal storage proposal = proposals[_proposalId];
        require((proposal.state == ProposalState.Executed) || (proposal.state == ProposalState.Closed),"wrong proposal state");
        Parameters memory params = parameters[proposal.paramsHash];
        uint amount;
        uint reputation;
        uint lostReputation;
        if (proposal.winningVote == YES) {
            lostReputation = proposal.preBoostedVotes[NO];
        } else {
            lostReputation = proposal.preBoostedVotes[YES];
        }
        lostReputation = (lostReputation * params.votersReputationLossRatio)/100;
        //as staker
        Staker storage staker = proposal.stakers[_beneficiary];
        if ((staker.amount>0) &&
             (staker.vote == proposal.winningVote)) {
            uint totalWinningStakes = proposal.stakes[proposal.winningVote];
            if (totalWinningStakes != 0) {
                rewards[0] = (staker.amount * proposal.totalStakes[0]) / totalWinningStakes;
            }
            if (proposal.state != ProposalState.Closed) {
                rewards[1] = (staker.amount * ( lostReputation - ((lostReputation * params.votersGainRepRatioFromLostRep)/100)))/proposal.stakes[proposal.winningVote];
            }
            staker.amount = 0;
        }
        //as voter
        Voter storage voter = proposal.voters[_beneficiary];
        if ((voter.reputation != 0 ) && (voter.preBoosted)) {
            uint preBoostedVotes = proposal.preBoostedVotes[YES] + proposal.preBoostedVotes[NO];
            if (preBoostedVotes>0) {
                rewards[2] = ((proposal.votersStakes * voter.reputation) / preBoostedVotes);
            }
            if (proposal.state == ProposalState.Closed) {
              //give back reputation for the voter
                rewards[3] = ((voter.reputation * params.votersReputationLossRatio)/100);
            } else if (proposal.winningVote == voter.vote ) {
                rewards[3] = (((voter.reputation * params.votersReputationLossRatio)/100) +
                (((voter.reputation * lostReputation * params.votersGainRepRatioFromLostRep)/100)/preBoostedVotes));
            }
            voter.reputation = 0;
        }
        //as proposer
        if ((proposal.proposer == _beneficiary)&&(proposal.winningVote == YES)&&(proposal.proposer != address(0))) {
            rewards[4] = (params.proposingRepRewardConstA.mul(proposal.votes[YES]+proposal.votes[NO]) + params.proposingRepRewardConstB.mul(proposal.votes[YES]-proposal.votes[NO]))/1000;
            proposal.proposer = 0;
        }
        amount = rewards[0] + rewards[2];
        reputation = rewards[1] + rewards[3] + rewards[4];
        if (amount != 0) {
            proposal.totalStakes[1] = proposal.totalStakes[1].sub(amount);
            require(stakingToken.transfer(_beneficiary, amount));
            emit Redeem(_proposalId,proposal.avatar,_beneficiary,amount);
        }
        if (reputation != 0 ) {
            ControllerInterface(Avatar(proposal.avatar).owner()).mintReputation(reputation,_beneficiary,proposal.avatar);
            emit RedeemReputation(_proposalId,proposal.avatar,_beneficiary,reputation);
        }
    }

    /**
     * @dev redeemDaoBounty a reward for a successful stake, vote or proposing.
     * The function use a beneficiary address as a parameter (and not msg.sender) to enable
     * users to redeem on behalf of someone else.
     * @param _proposalId the ID of the proposal
     * @param _beneficiary - the beneficiary address
     * @return redeemedAmount - redeem token amount
     * @return potentialAmount - potential redeem token amount(if there is enough tokens bounty at the avatar )
     */
    function redeemDaoBounty(bytes32 _proposalId,address _beneficiary) public returns(uint redeemedAmount,uint potentialAmount) {
        Proposal storage proposal = proposals[_proposalId];
        require((proposal.state == ProposalState.Executed) || (proposal.state == ProposalState.Closed));
        uint totalWinningStakes = proposal.stakes[proposal.winningVote];
        if (
          // solium-disable-next-line operator-whitespace
            (proposal.stakers[_beneficiary].amountForBounty>0)&&
            (proposal.stakers[_beneficiary].vote == proposal.winningVote)&&
            (proposal.winningVote == YES)&&
            (totalWinningStakes != 0))
        {
            //as staker
            Parameters memory params = parameters[proposal.paramsHash];
            uint beneficiaryLimit = (proposal.stakers[_beneficiary].amountForBounty.mul(params.daoBountyLimit)) / totalWinningStakes;
            potentialAmount = (params.daoBountyConst.mul(proposal.stakers[_beneficiary].amountForBounty))/100;
            if (potentialAmount > beneficiaryLimit) {
                potentialAmount = beneficiaryLimit;
            }
        }
        if ((potentialAmount != 0)&&(stakingToken.balanceOf(proposal.avatar) >= potentialAmount)) {
            proposal.daoBountyRemain = proposal.daoBountyRemain.sub(potentialAmount);
            require(ControllerInterface(Avatar(proposal.avatar).owner()).externalTokenTransfer(stakingToken,_beneficiary,potentialAmount,proposal.avatar));
            proposal.stakers[_beneficiary].amountForBounty = 0;
            redeemedAmount = potentialAmount;
            emit RedeemDaoBounty(_proposalId,proposal.avatar,_beneficiary,redeemedAmount);
        }
    }

    /**
     * @dev shouldBoost check if a proposal should be shifted to boosted phase.
     * @param _proposalId the ID of the proposal
     * @return bool true or false.
     */
    function shouldBoost(bytes32 _proposalId) public view returns(bool) {
        Proposal memory proposal = proposals[_proposalId];
        return (_score(_proposalId) >= threshold(proposal.paramsHash,proposal.avatar));
    }

    /**
     * @dev score return the proposal score
     * @param _proposalId the ID of the proposal
     * @return uint proposal score.
     */
    function score(bytes32 _proposalId) public view returns(int) {
        return _score(_proposalId);
    }

    /**
     * @dev getBoostedProposalsCount return the number of boosted proposal for an organization
     * @param _avatar the organization avatar
     * @return uint number of boosted proposals
     */
    function getBoostedProposalsCount(address _avatar) public view returns(uint) {
        uint expiredProposals;
        if (proposalsExpiredTimes[_avatar].count() != 0) {
          // solium-disable-next-line security/no-block-members
            expiredProposals = proposalsExpiredTimes[_avatar].rank(now);
        }
        return orgBoostedProposalsCnt[_avatar].sub(expiredProposals);
    }

    /**
     * @dev threshold return the organization&#39;s score threshold which required by
     * a proposal to shift to boosted state.
     * This threshold is dynamically set and it depend on the number of boosted proposal.
     * @param _avatar the organization avatar
     * @param _paramsHash the organization parameters hash
     * @return int organization&#39;s score threshold.
     */
    function threshold(bytes32 _paramsHash,address _avatar) public view returns(int) {
        uint boostedProposals = getBoostedProposalsCount(_avatar);
        int216 e = 2;

        Parameters memory params = parameters[_paramsHash];
        require(params.thresholdConstB > 0,"should be a valid parameter hash");
        int256 power = int216(boostedProposals).toReal().div(int216(params.thresholdConstB).toReal());

        if (power.fromReal() > 100 ) {
            power = int216(100).toReal();
        }
        int256 res = int216(params.thresholdConstA).toReal().mul(e.toReal().pow(power));
        return res.fromReal();
    }

    /**
     * @dev hash the parameters, save them if necessary, and return the hash value
     * @param _params a parameters array
     *    _params[0] - _preBoostedVoteRequiredPercentage,
     *    _params[1] - _preBoostedVotePeriodLimit, //the time limit for a proposal to be in an absolute voting mode.
     *    _params[2] -_boostedVotePeriodLimit, //the time limit for a proposal to be in an relative voting mode.
     *    _params[3] -_thresholdConstA
     *    _params[4] -_thresholdConstB
     *    _params[5] -_minimumStakingFee
     *    _params[6] -_quietEndingPeriod
     *    _params[7] -_proposingRepRewardConstA
     *    _params[8] -_proposingRepRewardConstB
     *    _params[9] -_stakerFeeRatioForVoters
     *    _params[10] -_votersReputationLossRatio
     *    _params[11] -_votersGainRepRatioFromLostRep
     *    _params[12] - _daoBountyConst
     *    _params[13] - _daoBountyLimit
    */
    function setParameters(
        uint[14] _params //use array here due to stack too deep issue.
    )
    public
    returns(bytes32)
    {
        require(_params[0] <= 100 && _params[0] > 0,"0 < preBoostedVoteRequiredPercentage <= 100");
        require(_params[4] > 0 && _params[4] <= 100000000,"0 < thresholdConstB < 100000000 ");
        require(_params[3] <= 100000000 ether,"thresholdConstA <= 100000000 wei");
        require(_params[9] <= 100,"stakerFeeRatioForVoters <= 100");
        require(_params[10] <= 100,"votersReputationLossRatio <= 100");
        require(_params[11] <= 100,"votersGainRepRatioFromLostRep <= 100");
        require(_params[2] >= _params[6],"boostedVotePeriodLimit >= quietEndingPeriod");
        require(_params[7] <= 100000000,"proposingRepRewardConstA <= 100000000");
        require(_params[8] <= 100000000,"proposingRepRewardConstB <= 100000000");
        require(_params[12] <= (2 * _params[9]),"daoBountyConst <= 2 * stakerFeeRatioForVoters");
        require(_params[12] >= _params[9],"daoBountyConst >= stakerFeeRatioForVoters");


        bytes32 paramsHash = getParametersHash(_params);
        parameters[paramsHash] = Parameters({
            preBoostedVoteRequiredPercentage: _params[0],
            preBoostedVotePeriodLimit: _params[1],
            boostedVotePeriodLimit: _params[2],
            thresholdConstA:_params[3],
            thresholdConstB:_params[4],
            minimumStakingFee: _params[5],
            quietEndingPeriod: _params[6],
            proposingRepRewardConstA: _params[7],
            proposingRepRewardConstB:_params[8],
            stakerFeeRatioForVoters:_params[9],
            votersReputationLossRatio:_params[10],
            votersGainRepRatioFromLostRep:_params[11],
            daoBountyConst:_params[12],
            daoBountyLimit:_params[13]
        });
        return paramsHash;
    }

  /**
   * @dev hashParameters returns a hash of the given parameters
   */
    function getParametersHash(
        uint[14] _params) //use array here due to stack too deep issue.
        public
        pure
        returns(bytes32)
        {
        return keccak256(
            abi.encodePacked(
            _params[0],
            _params[1],
            _params[2],
            _params[3],
            _params[4],
            _params[5],
            _params[6],
            _params[7],
            _params[8],
            _params[9],
            _params[10],
            _params[11],
            _params[12],
            _params[13]));
    }

    /**
    * @dev execute check if the proposal has been decided, and if so, execute the proposal
    * @param _proposalId the id of the proposal
    * @return bool true - the proposal has been executed
    *              false - otherwise.
   */
    function _execute(bytes32 _proposalId) internal votable(_proposalId) returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        Proposal memory tmpProposal = proposal;
        uint totalReputation = Avatar(proposal.avatar).nativeReputation().totalSupply();
        uint executionBar = totalReputation * params.preBoostedVoteRequiredPercentage/100;
        ExecutionState executionState = ExecutionState.None;

        if (proposal.state == ProposalState.PreBoosted) {
            // solium-disable-next-line security/no-block-members
            if ((now - proposal.submittedTime) >= params.preBoostedVotePeriodLimit) {
                proposal.state = ProposalState.Closed;
                proposal.winningVote = NO;
                executionState = ExecutionState.PreBoostedTimeOut;
             } else if (proposal.votes[proposal.winningVote] > executionBar) {
              // someone crossed the absolute vote execution bar.
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.PreBoostedBarCrossed;
               } else if ( shouldBoost(_proposalId)) {
                //change proposal mode to boosted mode.
                proposal.state = ProposalState.Boosted;
                // solium-disable-next-line security/no-block-members
                proposal.boostedPhaseTime = now;
                proposalsExpiredTimes[proposal.avatar].insert(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
                orgBoostedProposalsCnt[proposal.avatar]++;
              }
           }

        if ((proposal.state == ProposalState.Boosted) ||
            (proposal.state == ProposalState.QuietEndingPeriod)) {
            // solium-disable-next-line security/no-block-members
            if ((now - proposal.boostedPhaseTime) >= proposal.currentBoostedVotePeriodLimit) {
                proposalsExpiredTimes[proposal.avatar].remove(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
                orgBoostedProposalsCnt[tmpProposal.avatar] = orgBoostedProposalsCnt[tmpProposal.avatar].sub(1);
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.BoostedTimeOut;
             } else if (proposal.votes[proposal.winningVote] > executionBar) {
               // someone crossed the absolute vote execution bar.
                orgBoostedProposalsCnt[tmpProposal.avatar] = orgBoostedProposalsCnt[tmpProposal.avatar].sub(1);
                proposalsExpiredTimes[proposal.avatar].remove(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.BoostedBarCrossed;
            }
       }
        if (executionState != ExecutionState.None) {
            if (proposal.winningVote == YES) {
                uint daoBountyRemain = (params.daoBountyConst.mul(proposal.stakes[proposal.winningVote]))/100;
                if (daoBountyRemain > params.daoBountyLimit) {
                    daoBountyRemain = params.daoBountyLimit;
                }
                proposal.daoBountyRemain = daoBountyRemain;
            }
            emit ExecuteProposal(_proposalId, proposal.avatar, proposal.winningVote, totalReputation);
            emit GPExecuteProposal(_proposalId, executionState);
            (tmpProposal.executable).execute(_proposalId, tmpProposal.avatar, int(proposal.winningVote));
        }
        return (executionState != ExecutionState.None);
    }

    /**
     * @dev staking function
     * @param _proposalId id of the proposal
     * @param _vote  NO(2) or YES(1).
     * @param _amount the betting amount
     * @param _staker the staker address
     * @return bool true - the proposal has been executed
     *              false - otherwise.
     */
    function _stake(bytes32 _proposalId, uint _vote, uint _amount,address _staker) internal returns(bool) {
        // 0 is not a valid vote.

        require(_vote <= NUM_OF_CHOICES && _vote > 0);
        require(_amount > 0);
        if (_execute(_proposalId)) {
            return true;
        }

        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.PreBoosted) {
            return false;
        }

        // enable to increase stake only on the previous stake vote
        Staker storage staker = proposal.stakers[_staker];
        if ((staker.amount > 0) && (staker.vote != _vote)) {
            return false;
        }

        uint amount = _amount;
        Parameters memory params = parameters[proposal.paramsHash];
        require(amount >= params.minimumStakingFee);
        require(stakingToken.transferFrom(_staker, address(this), amount));
        proposal.totalStakes[1] = proposal.totalStakes[1].add(amount); //update totalRedeemableStakes
        staker.amount += amount;
        staker.amountForBounty = staker.amount;
        staker.vote = _vote;

        proposal.votersStakes += (params.stakerFeeRatioForVoters * amount)/100;
        proposal.stakes[_vote] = amount.add(proposal.stakes[_vote]);
        amount = amount - ((params.stakerFeeRatioForVoters*amount)/100);

        proposal.totalStakes[0] = amount.add(proposal.totalStakes[0]);
      // Event:
        emit Stake(_proposalId, proposal.avatar, _staker, _vote, _amount);
      // execute the proposal if this vote was decisive:
        return _execute(_proposalId);
    }

    /**
     * @dev Vote for a proposal, if the voter already voted, cancel the last vote and set a new one instead
     * @param _proposalId id of the proposal
     * @param _voter used in case the vote is cast for someone else
     * @param _vote a value between 0 to and the proposal&#39;s number of choices.
     * @param _rep how many reputation the voter would like to stake for this vote.
     *         if  _rep==0 so the voter full reputation will be use.
     * @return true in case of proposal execution otherwise false
     * throws if proposal is not open or if it has been executed
     * NB: executes the proposal if a decision has been reached
     */
    function internalVote(bytes32 _proposalId, address _voter, uint _vote, uint _rep) internal returns(bool) {
        // 0 is not a valid vote.
        require(_vote <= NUM_OF_CHOICES && _vote > 0,"0 < _vote <= 2");
        if (_execute(_proposalId)) {
            return true;
        }

        Parameters memory params = parameters[proposals[_proposalId].paramsHash];
        Proposal storage proposal = proposals[_proposalId];

        // Check voter has enough reputation:
        uint reputation = Avatar(proposal.avatar).nativeReputation().reputationOf(_voter);
        require(reputation >= _rep);
        uint rep = _rep;
        if (rep == 0) {
            rep = reputation;
        }
        // If this voter has already voted, return false.
        if (proposal.voters[_voter].reputation != 0) {
            return false;
        }
        // The voting itself:
        proposal.votes[_vote] = rep.add(proposal.votes[_vote]);
        //check if the current winningVote changed or there is a tie.
        //for the case there is a tie the current winningVote set to NO.
        if ((proposal.votes[_vote] > proposal.votes[proposal.winningVote]) ||
           ((proposal.votes[NO] == proposal.votes[proposal.winningVote]) &&
             proposal.winningVote == YES))
        {
           // solium-disable-next-line security/no-block-members
            uint _now = now;
            if ((proposal.state == ProposalState.QuietEndingPeriod) ||
               ((proposal.state == ProposalState.Boosted) && ((_now - proposal.boostedPhaseTime) >= (params.boostedVotePeriodLimit - params.quietEndingPeriod)))) {
                //quietEndingPeriod
                proposalsExpiredTimes[proposal.avatar].remove(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
                if (proposal.state != ProposalState.QuietEndingPeriod) {
                    proposal.currentBoostedVotePeriodLimit = params.quietEndingPeriod;
                    proposal.state = ProposalState.QuietEndingPeriod;
                }
                proposal.boostedPhaseTime = _now;
                proposalsExpiredTimes[proposal.avatar].insert(proposal.boostedPhaseTime + proposal.currentBoostedVotePeriodLimit);
            }
            proposal.winningVote = _vote;
        }
        proposal.voters[_voter] = Voter({
            reputation: rep,
            vote: _vote,
            preBoosted:(proposal.state == ProposalState.PreBoosted)
        });
        if (proposal.state == ProposalState.PreBoosted) {
            proposal.preBoostedVotes[_vote] = rep.add(proposal.preBoostedVotes[_vote]);
            uint reputationDeposit = (params.votersReputationLossRatio * rep)/100;
            ControllerInterface(Avatar(proposal.avatar).owner()).burnReputation(reputationDeposit,_voter,proposal.avatar);
        }
        // Event:
        emit VoteProposal(_proposalId, proposal.avatar, _voter, _vote, rep);
        // execute the proposal if this vote was decisive:
        return _execute(_proposalId);
    }

    /**
     * @dev _score return the proposal score
     * For dual choice proposal S = (S+) - (S-)
     * @param _proposalId the ID of the proposal
     * @return int proposal score.
     */
    function _score(bytes32 _proposalId) private view returns(int) {
        Proposal storage proposal = proposals[_proposalId];
        return int(proposal.stakes[YES]) - int(proposal.stakes[NO]);
    }

    /**
      * @dev _isVotable check if the proposal is votable
      * @param _proposalId the ID of the proposal
      * @return bool true or false
    */
    function _isVotable(bytes32 _proposalId) private view returns(bool) {
        ProposalState pState = proposals[_proposalId].state;
        return ((pState == ProposalState.PreBoosted)||(pState == ProposalState.Boosted)||(pState == ProposalState.QuietEndingPeriod));
    }
}