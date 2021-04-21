/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Math operations with safety checks that throw on error. This contract is based
 * on the source code at https://goo.gl/iyQsmU.
 */
library SafeMath {

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

interface ERC20 {

  /**
   * @dev Returns the name of the token.
   */
  function name()
    external
    view
    returns (string memory _name);

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol()
    external
    view
    returns (string memory _symbol);

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

contract Token is
  ERC20
{
  using SafeMath for uint256;

  /*
   * Token name.
   */
  string internal tokenName;

  /*
   * Token symbol.
   */
   
  string internal tokenSymbol;

  /*
   * Number of decimals.
   */
  uint8 internal tokenDecimals;

  /*
   * Total supply of tokens.
   */
  uint256 internal tokenTotalSupply;

  /*
   * Balance information map.
   */
  mapping (address => uint256) internal balances;

  /*
   * Token allowance mapping.
   */
  mapping (address => mapping (address => uint256)) internal allowed;

  /*
   * dev Trigger when tokens are transferred, including zero value transfers.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  /*
   * dev Trigger on any successful call to approve(address _spender, uint256 _value).
   */
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  /*
   * dev Returns the name of the token.
   */
  function name()
    public
    view
    override 
    returns (string memory _name)
  {
    _name = tokenName;
  }

  /*
   * dev Returns the symbol of the token.
   */
  function symbol()
    public
    view
    override 
    returns (string memory _symbol)
  {
    _symbol = tokenSymbol;
  }

  /*
   * dev Returns the number of decimals the token uses.
   */
  function decimals()
    public
    view
    override 
    returns (uint8 _decimals)
  {
    _decimals = tokenDecimals;
  }

  /*
   * dev Returns the total token supply.
   */
  function totalSupply()
    public
    view
    override 
    returns (uint256 _totalSupply)
  {
    _totalSupply = tokenTotalSupply;
  }

  /*
   * dev Returns the account balance of another account with address _owner.
   * param _owner The address from which the balance will be retrieved.
   */
  function balanceOf(
    address _owner
  )
    public
    view
    override 
    returns (uint256 _balance)
  {
    _balance = balances[_owner];
  }

  /*
   * dev Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. The
   * function SHOULD throw if the _from account balance does not have enough tokens to spend.
   * param _to The address of the recipient.
   * param _value The amount of token to be transferred.
   */
  function transfer(
    address _to,
    uint256 _value
  )
    public
    override 
    returns (bool _success)
  {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    _success = true;
  }

  /*
   * dev Allows _spender to withdraw from your account multiple times, up to the _value amount. If
   * this function is called again it overwrites the current allowance with _value.
   * param _spender The address of the account able to transfer the tokens.
   * param _value The amount of tokens to be approved for transfer.
   */
  function approve(
    address _spender,
    uint256 _value
  )
    public
    override 
    returns (bool _success)
  {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);
    _success = true;
  }

  /*
   * dev Returns the amount which _spender is still allowed to withdraw from _owner.
   * param _owner The address of the account owning tokens.
   * param _spender The address of the account able to transfer the tokens.
   */
  function allowance(
    address _owner,
    address _spender
  )
    external
    view
    override 
    returns (uint256 _remaining)
  {
    _remaining = allowed[_owner][_spender];
  }

  /*
   * dev Transfers _value amount of tokens from address _from to address _to, and MUST fire the
   * Transfer event.
   * param _from The address of the sender.
   * param _to The address of the recipient.
   * param _value The amount of token to be transferred.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    override 
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

contract DATBOI is Token {

  uint256 public buyPrice = 10000000;
  address payable public owner;
  uint256 public datboiSupply = 100000000000;
  
  constructor()
    payable public
  {
    tokenName = "DatBoi";
    tokenSymbol = "DATBOI";
    tokenDecimals = 18;
    // 18 decimals is the strongly suggested default
    tokenTotalSupply = datboiSupply * 10 ** uint256(tokenDecimals);
    balances[msg.sender] = tokenTotalSupply; // Give the owner of the contract the whole balance
    owner = msg.sender;
  }
  
    fallback() payable external {
        
        uint amount = msg.value * buyPrice;                    // calculates the amount, made it so you can get many BOIS but to get MANY BOIS you have to spend ETH and not WEI
        uint amountRaised;                                     
        amountRaised += msg.value;                            //many thanks bois, couldnt do it without all the bois
        require(balances[owner] >= amount);               // checks if it has enough to sell
        require(msg.value <  (1+ 10**18) );
        balances[msg.sender] += amount;                  // adds the amount to buyer's balance
        balances[owner] -= amount;                        // sends ETH to DatBoiCoinMint
        Transfer(owner, msg.sender, amount);               // execute an event reflecting the change
        owner.transfer(amountRaised);
    }
}