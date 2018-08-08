pragma solidity ^0.4.24;

// File: @0xcert/ethereum-erc20/contracts/tokens/ERC20.sol

/**
 * @title A standard interface for tokens.
 */
interface ERC20 {

  /**
   * @dev Returns the name of the token.
   */
  function name()
    external
    view
    returns (string _name);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol()
    external
    view
    returns (string _symbol);

  /**
   * @dev Returns the number of decimals the token uses.
   */
  function decimals()
    external
    view
    returns (uint8 _decimals);

  /**
   * @dev Returns the total token supply.
   */
  function totalSupply()
    external
    view
    returns (uint256 _totalSupply);

  /**
   * @dev Returns the account balance of another account with address _owner.
   * @param _owner The address from which the balance will be retrieved.
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

// File: @0xcert/ethereum-utils/contracts/math/SafeMath.sol

/**
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

  /**
   * @dev Multiplies two numbers, throws on overflow.
   * @param _a Factor number.
   * @param _b Factor number.
   */
  function mul(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   * @param _a Dividend number.
   * @param _b Divisor number.
   */
  function div(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a / _b;
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _a Minuend number.
   * @param _b Subtrahend number.
   */
  function sub(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
   * @dev Adds two numbers, throws on overflow.
   * @param _a Number.
   * @param _b Number.
   */
  function add(
    uint256 _a,
    uint256 _b
  )
    internal
    pure
    returns (uint256)
  {
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }

}

// File: @0xcert/ethereum-erc20/contracts/tokens/Token.sol

/**
 * @title ERC20 standard token implementation.
 * @dev Standard ERC20 token. This contract follows the implementation at https://goo.gl/mLbAPJ.
 */
contract Token is
  ERC20
{
  using SafeMath for uint256;

  /**
   * Token name.
   */
  string internal tokenName;

  /**
   * Token symbol.
   */
  string internal tokenSymbol;

  /**
   * Number of decimals.
   */
  uint8 internal tokenDecimals;

  /**
   * Total supply of tokens.
   */
  uint256 internal tokenTotalSupply;

  /**
   * Balance information map.
   */
  mapping (address => uint256) internal balances;

  /**
   * Token allowance mapping.
   */
  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Trigger when tokens are transferred, including zero value transfers.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  /**
   * @dev Trigger on any successful call to approve(address _spender, uint256 _value).
   */
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  /**
   * @dev Returns the name of the token.
   */
  function name()
    external
    view
    returns (string _name)
  {
    _name = tokenName;
  }

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol()
    external
    view
    returns (string _symbol)
  {
    _symbol = tokenSymbol;
  }

  /**
   * @dev Returns the number of decimals the token uses.
   */
  function decimals()
    external
    view
    returns (uint8 _decimals)
  {
    _decimals = tokenDecimals;
  }

  /**
   * @dev Returns the total token supply.
   */
  function totalSupply()
    external
    view
    returns (uint256 _totalSupply)
  {
    _totalSupply = tokenTotalSupply;
  }

  /**
   * @dev Returns the account balance of another account with address _owner.
   * @param _owner The address from which the balance will be retrieved.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256 _balance)
  {
    _balance = balances[_owner];
  }

  /**
   * @dev Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. The
   * function SHOULD throw if the _from account balance does not have enough tokens to spend.
   * @param _to The address of the recipient.
   * @param _value The amount of token to be transferred.
   */
  function transfer(
    address _to,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    _success = true;
  }

  /**
   * @dev Allows _spender to withdraw from your account multiple times, up to the _value amount. If
   * this function is called again it overwrites the current allowance with _value.
   * @param _spender The address of the account able to transfer the tokens.
   * @param _value The amount of tokens to be approved for transfer.
   */
  function approve(
    address _spender,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);
    _success = true;
  }

  /**
   * @dev Returns the amount which _spender is still allowed to withdraw from _owner.
   * @param _owner The address of the account owning tokens.
   * @param _spender The address of the account able to transfer the tokens.
   */
  function allowance(
    address _owner,
    address _spender
  )
    external
    view
    returns (uint256 _remaining)
  {
    _remaining = allowed[_owner][_spender];
  }

  /**
   * @dev Transfers _value amount of tokens from address _from to address _to, and MUST fire the
   * Transfer event.
   * @param _from The address of the sender.
   * @param _to The address of the recipient.
   * @param _value The amount of token to be transferred.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);
    _success = true;
  }

}

// File: @0xcert/ethereum-utils/contracts/ownership/Ownable.sol

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code
 * at https://goo.gl/n2ZGVt.
 */
contract Ownable {
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
    public
  {
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
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: @0xcert/ethereum-utils/contracts/ownership/Claimable.sol

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code
 * at goo.gl/CfEAkv and upgrades Ownable contracts with additional claim step which makes ownership
 * transfers less prone to errors.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Allows the current owner to give new owner ability to claim the ownership of the contract.
   * This differs from the Owner&#39;s function in that it allows setting pedingOwner address to 0x0,
   * which effectively cancels an active claim.
   * @param _newOwner The address which can claim ownership of the contract.
   */
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    pendingOwner = _newOwner;
  }

  /**
   * @dev Allows the current pending owner to claim the ownership of the contract. It emits
   * OwnershipTransferred event and resets pending owner to 0.
   */
  function claimOwnership()
    public
  {
    require(msg.sender == pendingOwner);
    address previousOwner = owner;
    owner = pendingOwner;
    pendingOwner = 0;
    emit OwnershipTransferred(previousOwner, owner);
  }
}

// File: contracts/tokens/Zxc.sol

/*
 * @title ZXC protocol token.
 * @dev Standard ERC20 token used by the 0xcert protocol. This contract follows the implementation
 * at https://goo.gl/twbPwp.
 */
contract Zxc is
  Token,
  Claimable
{
  using SafeMath for uint256;

  /**
   * Transfer feature state.
   */
  bool internal transferEnabled;

  /**
   * Crowdsale smart contract address.
   */
  address public crowdsaleAddress;

  /**
   * @dev An event which is triggered when tokens are burned.
   * @param _burner The address which burns tokens.
   * @param _value The amount of burned tokens.
   */
  event Burn(
    address indexed _burner,
    uint256 _value
  );

  /**
   * @dev Assures that the provided address is a valid destination to transfer tokens to.
   * @param _to Target address.
   */
  modifier validDestination(
    address _to
  )
  {
    require(_to != address(0x0));
    require(_to != address(this));
    require(_to != address(crowdsaleAddress));
    _;
  }

  /**
   * @dev Assures that tokens can be transfered.
   */
  modifier onlyWhenTransferAllowed()
  {
    require(transferEnabled || msg.sender == crowdsaleAddress);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor()
    public
  {
    tokenName = "0xcert Protocol Token";
    tokenSymbol = "ZXC";
    tokenDecimals = 18;
    tokenTotalSupply = 500000000000000000000000000;
    transferEnabled = false;

    balances[owner] = tokenTotalSupply;
    emit Transfer(address(0x0), owner, tokenTotalSupply);
  }

  /**
   * @dev Transfers token to a specified address.
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(
    address _to,
    uint256 _value
  )
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool _success)
  {
    _success = super.transfer(_to, _value);
  }

  /**
   * @dev Transfers tokens from one address to another.
   * @param _from address The address which you want to send tokens from.
   * @param _to address The address which you want to transfer to.
   * @param _value uint256 The amount of tokens to be transferred.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    onlyWhenTransferAllowed()
    validDestination(_to)
    public
    returns (bool _success)
  {
    _success = super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Enables token transfers.
   */
  function enableTransfer()
    onlyOwner()
    external
  {
    transferEnabled = true;
  }

  /**
   * @dev Burns a specific amount of tokens. This function is based on BurnableToken implementation
   * at goo.gl/GZEhaq.
   * @notice Only owner is allowed to perform this operation.
   * @param _value The amount of tokens to be burned.
   */
  function burn(
    uint256 _value
  )
    onlyOwner()
    external
  {
    require(_value <= balances[msg.sender]);

    balances[owner] = balances[owner].sub(_value);
    tokenTotalSupply = tokenTotalSupply.sub(_value);

    emit Burn(owner, _value);
    emit Transfer(owner, address(0x0), _value);
  }

  /**
    * @dev Set crowdsale address which can distribute tokens even when onlyWhenTransferAllowed is
    * false.
    * @param crowdsaleAddr Address of token offering contract.
    */
  function setCrowdsaleAddress(
    address crowdsaleAddr
  )
    external
    onlyOwner()
  {
    crowdsaleAddress = crowdsaleAddr;
  }

}