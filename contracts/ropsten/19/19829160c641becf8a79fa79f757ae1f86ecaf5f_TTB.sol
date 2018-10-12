pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20TokenInterface {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address _to, uint256 _value) external returns (bool);
  function totalSupply() external constant returns (uint256);
  function balanceOf(address _owner) external constant returns (uint256);

  function approve(address _spender, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint256);
}


contract ERC20Token is SafeMath, ERC20TokenInterface {

  /* Storage */

  mapping(address => uint256) __balances;
  mapping(address => mapping(address => uint256) ) __allowances;
  uint256 __totalSupply;

  string __tokenName = &#39;&#39;;
  string __tokenSymbol = &#39;&#39;;
  uint8 __tokenDecimals = 0;


  /* Constructor */

  constructor (string _name, string _symbol, uint8 _decimals) public {
    require(bytes(_name).length > 0);
    require(bytes(_symbol).length > 0);

    __tokenName = _name;
    __tokenSymbol = _symbol;
    __tokenDecimals = _decimals;
  }


  /* ERC20 Interface */

  function transfer(
    address _to,
    uint256 _value
  )
    external
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    __balances[msg.sender] = safeSub(__balances[msg.sender], _value);
    __balances[_to] = safeAdd(__balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function totalSupply() external constant returns (uint256) {
    return __totalSupply;
  }

  function balanceOf(address _owner) external constant onlyPayloadSize(1 * 32) returns (uint256) {
    return __balances[_owner];
  }


  function approve(
    address _spender,
    uint256 _value
  )
    external
    onlyPayloadSize(2 * 32)
    returns (bool)
  {
    __allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    external
    onlyPayloadSize(3 * 32)
    returns (bool)
  {
    __allowances[_from][msg.sender] = safeSub(__allowances[_from][msg.sender], _value);
    __balances[_from] = safeSub(__balances[_from], _value);
    __balances[_to] = safeAdd(__balances[_to], _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function allowance(
    address _owner,
    address _spender
  )
    external
    constant
    onlyPayloadSize(2 * 32)
    returns (uint256)
  {
    return __allowances[_owner][_spender];
  }


  /* ERC20 Named Interface */

  function name() external constant returns (string) {
    return __tokenName;
  }

  function symbol() external constant returns (string) {
    return __tokenSymbol;
  }

  function decimals() external constant returns (uint8) {
    return __tokenDecimals;
  }


  /* Mint / Burn */

  function mint(address _address, uint256 _value) external {
    __balances[_address] = safeAdd(__balances[_address], _value);
    __totalSupply = safeAdd(__totalSupply, _value);
  }

  function burn(address _address, uint256 _value) external {
    __balances[_address] = safeSub(__balances[_address], _value);
    __totalSupply = safeSub(__totalSupply, _value);
  }


  /* Helpers */

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
    require(msg.data.length == (size + 4));
    _;
  }
}


contract TTB is ERC20Token {

  /* Constructor */

  constructor () public ERC20Token("Test Token B", "TTB", 18) {}

}