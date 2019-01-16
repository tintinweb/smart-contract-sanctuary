pragma solidity 0.5.1;

/**
 * @dev Math operations with safety checks that throw on error. This contract is based on the 
 * source code at: 
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol.
 */
library SafeMath
{

  /**
   * @dev Error constants.
   */
  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";

  /**
   * @dev Multiplies two numbers, reverts on overflow.
   * @param _factor1 Factor number.
   * @param _factor2 Factor number.
   * @return The product of the two factors.
   */
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2, OVERFLOW);
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient, reverts on division by zero.
   * @param _dividend Dividend number.
   * @param _divisor Divisor number.
   * @return The quotient.
   */
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
    // Solidity automatically asserts when dividing by 0, using all gas.
    require(_divisor > 0, DIVISION_BY_ZERO);
    quotient = _dividend / _divisor;
    // assert(_dividend == _divisor * quotient + _dividend % _divisor); // There is no case in which this doesn&#39;t hold.
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _minuend Minuend number.
   * @param _subtrahend Subtrahend number.
   * @return Difference.
   */
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
    difference = _minuend - _subtrahend;
  }

  /**
   * @dev Adds two numbers, reverts on overflow.
   * @param _addend1 Number.
   * @param _addend2 Number.
   * @return Sum.
   */
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1, OVERFLOW);
  }

  /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when
    * dividing by zero.
    * @param _dividend Number.
    * @param _divisor Number.
    * @return Remainder.
    */
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder) 
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}

/**
 * @dev Contract for setting abilities.
 */
contract Abilitable
{

  using SafeMath for uint;

  /**
   * @dev Error constants.
   */
  string constant NOT_AUTHORIZED = "017001";
  string constant ONE_ZERO_ABILITY_HAS_TO_EXIST = "017002";

  /**
   * @dev Id 0 is a reserved ability. It is an ability to assign or revoke abilities. 
   * There can be minimum of 1 address with 0 id ability.
   * Other ability id are determined by implementing contract.
   */
  uint8 constant ABILITY_TO_MANAGE_ABILITIES = 0;

  /**
   * @dev Maps address to ability id.
   */
  mapping(address => mapping(uint8 => bool)) private addressToAbility;

  /**
   * @dev Count of zero ability addresses.
   */
  uint256 private zeroAbilityCount;

  /**
   * @dev Emits when an address is assigned an ability.
   * @param _target Address to which we are assigning ability.
   * @param _ability Id of ability.
   */
  event AssignAbility(
    address indexed _target,
    uint8 indexed _ability
  );

  /**
   * @dev Emits when an address gets an ability revoked.
   * @param _target Address of which we are revoking an ability.
   * @param _ability Id of ability.
   */
  event RevokeAbility(
    address indexed _target,
    uint8 indexed _ability
  );

  /**
   * @dev Guarantees that msg.sender has a certain ability.
   */
  modifier hasAbility(
    uint8 _ability
  ) 
  {
    require(addressToAbility[msg.sender][_ability], NOT_AUTHORIZED);
    _;
  }

  /**
   * @dev Contract constructor.
   * Sets zero ability to the sender account.
   */
  constructor()
    public
  {
    addressToAbility[msg.sender][0] = true;
    zeroAbilityCount = 1;
    emit AssignAbility(msg.sender, 0);
  }

  /**
   * @dev Assigns specific abilities to specified address.
   * @param _target Address to assign abilities to.
   * @param _abilities List of ability IDs.
   */
  function assignAbilities(
    address _target,
    uint8[] memory _abilities
  )
    public
    hasAbility(ABILITY_TO_MANAGE_ABILITIES)
  {
    for(uint8 i; i<_abilities.length; i++)
    {
      if(_abilities[i] == 0)
      {
        zeroAbilityCount = zeroAbilityCount.add(1);
      }

      addressToAbility[_target][_abilities[i]] = true;
      emit AssignAbility(_target, _abilities[i]);
    }
  }

  /**
   * @dev Assigns specific abilities to specified address.
   * @param _target Address of which we revoke abilites.
   * @param _abilities List of ability IDs.
   */
  function revokeAbilities(
    address _target,
    uint8[] memory _abilities
  )
    public
    hasAbility(ABILITY_TO_MANAGE_ABILITIES)
  {
    for(uint8 i; i<_abilities.length; i++)
    {
      if(_abilities[i] == 0 )
      {
        require(zeroAbilityCount > 1, ONE_ZERO_ABILITY_HAS_TO_EXIST);
        zeroAbilityCount--;
      }

      addressToAbility[_target][_abilities[i]] = false;
      emit RevokeAbility(_target, _abilities[i]);
    }
  }

  /**
   * @dev Check if an address has a specific ability.
   * @param _target Address for which we want to check if it has a specific ability.
   * @param _ability Id of ability.
   */
  function isAble(
    address _target,
    uint8 _ability
  )
    public
    view
    returns (bool)
  {
    return addressToAbility[_target][_ability];
  }
  
}

/**
 * @title A standard interface for tokens.
 */
interface ERC20
{

  /**
   * @dev Returns the name of the token.
   * @return Token name.
   */
  function name()
    external
    view
    returns (string memory _name);

  /**
   * @dev Returns the symbol of the token.
   * @return Token symbol.
   */
  function symbol()
    external
    view
    returns (string memory _symbol);

  /**
   * @dev Returns the number of decimals the token uses.
   * @return Number of decimals.
   */
  function decimals()
    external
    view
    returns (uint8 _decimals);

  /**
   * @dev Returns the total token supply.
   * @return Total supply.
   */
  function totalSupply()
    external
    view
    returns (uint256 _totalSupply);

  /**
   * @dev Returns the account balance of another account with address _owner.
   * @param _owner The address from which the balance will be retrieved.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256 _balance);

  /**
   * @dev Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. The
   * function SHOULD throw if the _from account balance does not have enough tokens to spend.
   * @param _to The address of the recipient.
   * @param _value The amount of token to be transferred.
   * @return Success of operation.
   */
  function transfer(
    address _to,
    uint256 _value
  )
    external
    returns (bool _success);

  /**
   * @dev Transfers _value amount of tokens from address _from to address _to, and MUST fire the
   * Transfer event.
   * @param _from The address of the sender.
   * @param _to The address of the recipient.
   * @param _value The amount of token to be transferred.
   * @return Success of operation.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    external
    returns (bool _success);

  /**
   * @dev Allows _spender to withdraw from your account multiple times, up to
   * the _value amount. If this function is called again it overwrites the current
   * allowance with _value.
   * @param _spender The address of the account able to transfer the tokens.
   * @param _value The amount of tokens to be approved for transfer.
   * @return Success of operation.
   */
  function approve(
    address _spender,
    uint256 _value
  )
    external
    returns (bool _success);

  /**
   * @dev Returns the amount which _spender is still allowed to withdraw from _owner.
   * @param _owner The address of the account owning tokens.
   * @param _spender The address of the account able to transfer the tokens.
   * @return Remaining allowance.
   */
  function allowance(
    address _owner,
    address _spender
  )
    external
    view
    returns (uint256 _remaining);

  /**
   * @dev Triggers when tokens are transferred, including zero value transfers.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  /**
   * @dev Triggers on any successful call to approve(address _spender, uint256 _value).
   */
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

}


/**
 * @dev Standard interface for a dex proxy contract.
 */
interface Proxy {

  /**
   * @dev Executes an action.
   * @param _target Target of execution.
   * @param _a Address usually represention from.
   * @param _b Address usually representing to.
   * @param _c Integer usually repersenting amount/value/id.
   */
  function execute(
    address _target,
    address _a,
    address _b,
    uint256 _c
  )
    external;
    
}

/**
 * @title TokenTransferProxy - Transfers tokens on behalf of contracts that have been approved via
 * decentralized governance.
 * @dev Based on:https://github.com/0xProject/contracts/blob/master/contracts/TokenTransferProxy.sol
 */
contract TokenTransferProxy is 
  Proxy,
  Abilitable 
{

  /**
   * @dev List of abilities:
   * 1 - Ability to execute transfer. 
   */
  uint8 constant ABILITY_TO_EXECUTE = 1;

  /**
   * @dev Error constants.
   */
  string constant TRANSFER_FAILED = "012001";

  /**
   * @dev Calls into ERC20 Token contract, invoking transferFrom.
   * @param _target Address of token to transfer.
   * @param _a Address to transfer token from.
   * @param _b Address to transfer token to.
   * @param _c Amount of token to transfer.
   */
  function execute(
    address _target,
    address _a,
    address _b,
    uint256 _c
  )
    public
    hasAbility(ABILITY_TO_EXECUTE)
  {
    require(
      ERC20(_target).transferFrom(_a, _b, _c),
      TRANSFER_FAILED
    );
  }
  
}