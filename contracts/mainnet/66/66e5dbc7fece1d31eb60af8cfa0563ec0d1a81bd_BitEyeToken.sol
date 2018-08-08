pragma solidity ^0.4.19;

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint256) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint256) {
    uint c = a / b;
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint256) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  //transfer owner to another address
  function transferOwnership(address _newOwner) public onlyOwner {
    if (_newOwner != address(0)) {
      owner = _newOwner;
    }
  }
}

contract ERC20Token is SafeMath {
  string public name;
  string public symbol;
  uint256 public totalSupply;
  uint8 public decimals;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  modifier onlyPayloadSize(uint size) {   
    require(msg.data.length == size + 4);
    _;
  }

  /**
    @dev send coins
    throws on any error rather then return a false flag to minimize user errors

    @param _to      target address
    @param _value   transfer amount

    @return true if the transfer was successful, false if it wasn&#39;t
  */
  function transfer(address _to, uint256 _value)
      public
      onlyPayloadSize(2 * 32)
      returns (bool success)
  {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
    @dev an account/contract attempts to get the coins
    throws on any error rather then return a false flag to minimize user errors

    @param _from    source address
    @param _to      target address
    @param _value   transfer amount

    @return true if the transfer was successful, false if it wasn&#39;t
  */
  function transferFrom(address _from, address _to, uint256 _value)
    public
    onlyPayloadSize(3 * 32)
    returns (bool success)
  {
    allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(_from, _to, _value);
    return true;
  }
  
  function approve(address _spender, uint256 _value)
    public
    onlyPayloadSize(2 * 32)
    returns (bool success)
  {
    // if the allowance isn&#39;t 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
    require(_value == 0 || allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint) {
    return allowed[_owner][_spender];
  }

  function balanceOf(address _holder) public constant returns (uint) {
    return balances[_holder];
  }
}

contract BitEyeToken is ERC20Token, Ownable {

  bool public distributed = false;

  function BitEyeToken() public {
    name = "BitEye Token";
    symbol = "BEY";
    decimals = 18;
    totalSupply = 1000000000 * 1e18;
  }

  function distribute(address _bitEyeExAddr, address _operationAddr, address _airdropAddr) public onlyOwner {
    require(!distributed);
    distributed = true;

    balances[_bitEyeExAddr] = 900000000 * 1e18;
    Transfer(address(0), _bitEyeExAddr, 900000000 * 1e18);

    balances[_operationAddr] = 50000000 * 1e18;
    Transfer(address(0), _operationAddr, 50000000 * 1e18);

    balances[_airdropAddr] = 50000000 * 1e18;
    Transfer(address(0), _airdropAddr, 50000000 * 1e18);
  }
}